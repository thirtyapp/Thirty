import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/storage/confirmed_write.dart';
import 'package:thirty/features/home/application/circle_history_deletion.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';
import 'l1_fixture.dart';

/// L-1 Option B (founder decision, 2026-11-11) — L-1A, the Delete engine.
///
/// The Delete engine is unchanged by Option B: these tests hold it to that.
/// A Suggestion Preferences record THIRTY can't read as a whole is kept
/// exactly as stored — never interpreted, never written — while every known
/// History store is deleted with its full guarantees: intent first, every
/// step confirmed, the marker last, finished at the next start. A record
/// THIRTY can't read never fails or blocks the Delete on its own, so no
/// pending Delete can be left waiting on it; a readable one still has its
/// Insight attribution removed, or the Delete fails and stays pending.
void main() {
  late L1Fixture f;
  late R8Harness h;

  setUpAll(() async => f = await L1Fixture.seed());

  Future<ProviderContainer> boot(
    String name, {
    Map<String, Object> extra = const {},
  }) async {
    h = R8Harness(L1Fixture.morning);
    await h.boot({...f.withPreferences(name), ...extra});
    return h.open();
  }

  Future<Map<String, Object>> disk() => h.disk.stored();

  Map<String, Object?>? planOnDisk(Map<String, Object> s) =>
      ((jsonDecode(s[circlePlansKey]! as String) as Map)['plans']
              as Map)['getting_going']
          as Map<String, Object?>?;

  int keptOnDisk(Map<String, Object> s) =>
      ((jsonDecode(s[keptCirclesKey]! as String) as Map)['kept'] as List)
          .length;

  /// History, today's session and the Insights are gone; the Plan keeps its
  /// place without its stage evidence; the kept Circle stays; the marker is
  /// gone.
  void expectHistoryDeleted(Map<String, Object> s) {
    expect(s.containsKey(historyDeletionPendingKey), isFalse);
    expect(s.containsKey(circleJournalKey), isFalse);
    expect(s.containsKey(insightsKey), isFalse);
    final plan = planOnDisk(s)!;
    expect(plan['lifecycle'], 'active');
    expect(keptOnDisk(s), 1);
    for (final MapEntry(:key, :value) in s.entries) {
      if (key == suggestionPreferencesKey) continue;
      expect('$value', isNot(contains(f.insightId)), reason: key);
    }
  }

  /// The preferences record after a Delete: one THIRTY can't read exactly as
  /// stored — same type, same value; a readable one without the Insight's
  /// id, every other field kept.
  void expectPreferencesAfterDelete(String name, Map<String, Object> s) {
    final before = f.variants[name]!;
    final after = s[suggestionPreferencesKey];
    if (L1Fixture.unreadableCases.contains(name)) {
      expect(sameStoredValue(after, before), isTrue, reason: '$after');
    } else {
      expect('$after', isNot(contains(f.insightId)));
      final json = jsonDecode(after! as String) as Map<String, Object?>;
      expect(json['futureTopField'], 1);
      expect(jsonEncode(json['notSuggested']), contains('thirtyMinuteWalk'));
      final leftOut = [
        for (final e in json['elementsLeftOut']! as List)
          (e as Map)['elementId'],
      ];
      expect(leftOut, containsAll(['readPages', 'openWindow']));
    }
  }

  group('L-1A — a Delete that succeeds', () {
    for (final name in L1Fixture.allCases) {
      test('$name: the known History is deleted; the preferences record is '
          'kept as stored (or loses only the Insight id), live and after a '
          'restart', () async {
        final c = await boot(name);
        await c.read(circleHistoryDeletionProvider).delete();
        await R8Harness.settle();
        final live = await disk();
        expectHistoryDeleted(live);
        expectPreferencesAfterDelete(name, live);
        expect(c.read(insightsProvider).isEmpty, isTrue);
        expect(c.read(circleHistoryDeletionProvider).isPending, isFalse);
        // A record THIRTY can't read is never applied.
        if (L1Fixture.unreadableCases.contains(name)) {
          expect(c.read(suggestionPreferencesProvider).leftOut, isEmpty);
          expect(
            c.read(suggestionPreferencesProvider).controls.notSuggested,
            isEmpty,
          );
        }
        await h.restart();
        final again = h.open();
        final restarted = await disk();
        expectHistoryDeleted(restarted);
        expectPreferencesAfterDelete(name, restarted);
        expect(again.read(insightsProvider).isEmpty, isTrue);
        expect(again.read(circleHistoryDeletionProvider).isPending, isFalse);
      });
    }

    test(
      'an unreadable record is never written by the Delete — even a store '
      'that refuses every preferences write leaves it complete; a readable '
      'one in the same store fails the Delete, which stays pending',
      () async {
        for (final name in [L1Fixture.newerSchema, L1Fixture.readable]) {
          final c = await boot(name);
          h.disk.fail(suggestionPreferencesKey, DiskFault.returnsFalse);
          final before = h.disk.attempts.length;
          Object? error;
          try {
            await c.read(circleHistoryDeletionProvider).delete();
          } catch (e) {
            error = e;
          }
          await R8Harness.settle();
          final writes = [
            for (final a in h.disk.attempts.skip(before))
              if (a.endsWith(' $suggestionPreferencesKey')) a,
          ];
          final s = await disk();
          if (name == L1Fixture.newerSchema) {
            expect(error, isNull);
            expect(writes, isEmpty);
            expectHistoryDeleted(s);
            expectPreferencesAfterDelete(name, s);
          } else {
            expect(error, isA<Exception>());
            expect(writes, isNotEmpty);
            expect(s[historyDeletionPendingKey], true);
            expect(c.read(circleHistoryDeletionProvider).isPending, isTrue);
          }
        }
      },
    );
  });

  group('L-1A — a Delete that fails or is interrupted (unreadable record)', () {
    test('the app stops right after the intent lands: the next start '
        'finishes the known History, keeps the record, and a new Circle can '
        'begin', () async {
      final c = await boot(L1Fixture.newerSchema);
      h.disk.stopAfter = h.disk.log.length + 1;
      c.read(circleHistoryDeletionProvider).delete().ignore();
      await R8Harness.settle();
      expect((await disk())[historyDeletionPendingKey], true);
      await h.restart();
      final again = h.open();
      final s = await disk();
      expectHistoryDeleted(s);
      expectPreferencesAfterDelete(L1Fixture.newerSchema, s);
      final deletion = again.read(circleHistoryDeletionProvider);
      expect(deletion.isPending, isFalse);
      expect(await deletion.resolvePending(), isTrue);
      again
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await R8Harness.settle();
      expect(again.read(recommendationProvider).recommendation, isNotNull);
    });

    test('a required History removal refused: the Delete fails and stays '
        'pending — never complete; the next start finishes it', () async {
      final c = await boot(L1Fixture.newerSchema);
      h.disk.fail(circleJournalKey, DiskFault.returnsFalse);
      await expectLater(
        c.read(circleHistoryDeletionProvider).delete(),
        throwsA(isA<StorageWriteFailed>()),
      );
      await R8Harness.settle();
      expect((await disk())[historyDeletionPendingKey], true);
      expect(c.read(circleHistoryDeletionProvider).isPending, isTrue);
      expectPreferencesAfterDelete(L1Fixture.newerSchema, await disk());
      h.disk.healAll();
      await h.restart();
      expectHistoryDeleted(await disk());
      expectPreferencesAfterDelete(L1Fixture.newerSchema, await disk());
    });

    test(
      'a required History removal lands but its answer is lost: the '
      'Delete fails, stays pending, and the next start finishes it',
      () async {
        final c = await boot(L1Fixture.newerSchema);
        h.disk.ackLost(circleJournalKey);
        await expectLater(
          c.read(circleHistoryDeletionProvider).delete(),
          throwsA(isA<StorageWriteFailed>()),
        );
        await R8Harness.settle();
        expect((await disk())[historyDeletionPendingKey], true);
        await h.restart();
        expectHistoryDeleted(await disk());
        expectPreferencesAfterDelete(L1Fixture.newerSchema, await disk());
      },
    );

    test('the intent refused: nothing is deleted and the record is '
        'untouched', () async {
      final c = await boot(L1Fixture.newerSchema);
      h.disk.fail(historyDeletionPendingKey, DiskFault.returnsFalse);
      await expectLater(
        c.read(circleHistoryDeletionProvider).delete(),
        throwsA(isA<HistoryDeletionNotStarted>()),
      );
      await R8Harness.settle();
      final s = await disk();
      expect(s.containsKey(circleJournalKey), isTrue);
      expect(s.containsKey(insightsKey), isTrue);
      expectPreferencesAfterDelete(L1Fixture.newerSchema, s);
    });

    for (final name in L1Fixture.unreadableCases) {
      test('$name: start-up completion over the record, three starts in a '
          'row — finished on the first, never an error, never pending '
          'again, the record kept each time', () async {
        h = R8Harness(L1Fixture.morning);
        await h.boot({
          ...f.withPreferences(name),
          historyDeletionPendingKey: true,
        });
        for (var start = 1; start <= 3; start++) {
          await completeInterruptedHistoryDeletion(h.prefs);
          final s = await disk();
          expectHistoryDeleted(s);
          expectPreferencesAfterDelete(name, s);
          await h.restart();
          final c = h.open();
          expect(c.read(circleHistoryDeletionProvider).isPending, isFalse);
          expect(
            await c.read(circleHistoryDeletionProvider).resolvePending(),
            isTrue,
          );
        }
      });
    }
  });
}
