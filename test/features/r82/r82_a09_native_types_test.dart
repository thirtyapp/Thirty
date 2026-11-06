import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/storage/store_save_failures.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_history_deletion.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';

import '../../support/r8_harness.dart';

/// R8.2 — Astra R81-A09 (MEDIUM): a value of the wrong native type under
/// one of the user's JSON-text stores — an integer, a Boolean, a list where
/// text is expected — never stops that store from opening. It is read as a
/// record THIRTY can't read, before any JSON decoding, and handled exactly
/// as one: kept as stored (aside, or by refusing to write over it), never
/// read as an empty record that is then saved over it. Repeated restarts
/// open it the same way.
void main() {
  final morning = DateTime(2026, 10, 30, 9);
  late R8Harness h;

  setUp(() async {
    h = R8Harness(morning);
    await h.boot();
  });

  Future<ProviderContainer> restart() async {
    await h.restart();
    return h.open();
  }

  final natives = <String, Object>{
    'an integer': 42,
    'a Boolean': true,
    'a list of text': <String>['a', 'b'],
  };

  for (final MapEntry(key: kind, value: native) in natives.entries) {
    group('$kind stored where text is expected —', () {
      test('Plans: opens unreadable, the value is kept aside exactly before '
          'anything is written over it; restarts open the same', () async {
        await h.boot({circlePlansKey: native});
        final c = h.open();
        expect(c.read(circlePlansProvider).plans, isEmpty);
        await R8Harness.settle();
        expect(
          c.read(circlePlansProvider.notifier).start('getting_going'),
          PlanActionResult.done,
        );
        await R8Harness.settle();
        final stored = await h.disk.stored();
        expect(stored[circlePlansUnreadableKey], native, reason: 'not kept');
        expect(stored[circlePlansKey], contains('getting_going'));
        final again = await restart();
        expect(again.read(circlePlansProvider).active?.planId, 'getting_going');
        expect((await h.disk.stored())[circlePlansUnreadableKey], native);
      });

      test('Insights: opens unreadable, kept aside exactly; assessing and '
          'restarts never fail', () async {
        await h.boot({insightsKey: native});
        final c = h.open();
        expect(c.read(insightsProvider).snapshots, isEmpty);
        c.read(insightsProvider.notifier).assess();
        await R8Harness.settle();
        await restart();
        final again = await restart();
        expect(again.read(insightsProvider).snapshots, isEmpty);
        final stored = await h.disk.stored();
        expect(
          stored[insightsKey] == native ||
              stored[insightsUnreadableKey] == native,
          isTrue,
          reason: 'the stored value was lost',
        );
      });

      test('Suggestion Preferences: opens as a record THIRTY can\'t read — '
          'changes are refused and the value stays, until Reset', () async {
        await h.boot({suggestionPreferencesKey: native});
        final c = h.open();
        expect(c.read(suggestionPreferencesProvider).leftOut, isEmpty);
        expect(
          await c
              .read(suggestionPreferencesProvider.notifier)
              .leaveOut(ElementId.readPages),
          isFalse,
        );
        expect(
          c.read(storeSaveFailuresProvider).unsaved,
          contains(UserStore.suggestionPreferences),
        );
        expect((await h.disk.stored())[suggestionPreferencesKey], native);
        final again = await restart();
        expect(again.read(suggestionPreferencesProvider).leftOut, isEmpty);
        expect(
          await again.read(suggestionPreferencesProvider.notifier).reset(),
          isTrue,
        );
        expect(
          (await h.disk.stored()).containsKey(suggestionPreferencesKey),
          isFalse,
        );
      });

      test('History: opens as a journal THIRTY can\'t read; today\'s Circle '
          'still opens and is saved, the stored value kept first', () async {
        await h.boot({circleJournalKey: native});
        final c = h.open();
        expect(c.read(circleJournalRepositoryProvider).readAll(), isEmpty);
        expect(
          c.read(circleJournalRepositoryProvider).storedHistoryUnopened,
          isTrue,
        );
        c.read(recommendationProvider);
        c
            .read(recommendationProvider.notifier)
            .chooseIntention(Intention.clearerHead);
        await R8Harness.settle();
        final stored = await h.disk.stored();
        expect(stored[recommendationDayKey], '2026-10-30');
        expect(
          stored[circleJournalPreservedKey],
          contains(jsonEncode(native)),
          reason: 'the stored value was written over without being kept',
        );
        final again = await restart();
        expect(again.read(circleJournalRepositoryProvider).readAll(), hasLength(1));
      });
    });
  }

  test('start-up: a deletion marker of the wrong type, and a Plans record of '
      'the wrong type, never stop the app from starting', () async {
    await h.boot({historyDeletionPendingKey: 'yes', circlePlansKey: 7});
    await completeInterruptedHistoryDeletion(h.prefs);
    final c = h.open();
    expect(c.read(circleHistoryDeletionProvider).isPending, isFalse);
    expect(c.read(circlePlansProvider).plans, isEmpty);
  });

  test('start-up: a pending deletion with a Plans record of the wrong type '
      'finishes', () async {
    await h.boot({historyDeletionPendingKey: true, circlePlansKey: 7});
    await completeInterruptedHistoryDeletion(h.prefs);
    final stored = await h.disk.stored();
    expect(stored.containsKey(historyDeletionPendingKey), isFalse);
  });
}
