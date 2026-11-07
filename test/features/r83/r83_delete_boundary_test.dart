import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/storage/store_save_failures.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_history_deletion.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';

import '../../support/r83_invariants.dart';
import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.3 — the Delete Circle history boundary (invariants I and VI).
///
/// - Claude AUD-N2: the deleted session's Start (or Close request) instant
///   is never written back to the Plans after the Delete.
/// - Claude AUD-N3 (founder decision D4): a Plan change reported as not
///   saved is never written by the Delete; the Plans it keeps are the last
///   confirmed ones, with the evidence removed.
/// - Founder decision D1 (Claude O-1): an Insight's attribution on a
///   left-out part goes with the History it came from; the part stays left
///   out, everything else about it is kept, and the Delete reports success
///   only once that is durable — across pending writes, a refused intent,
///   a failed step and a restart.
void main() {
  final day1 = DateTime(2026, 10, 12, 9);
  late R8Harness h;

  setUp(() async {
    h = R8Harness(day1);
    await h.boot();
  });

  RecommendationNotifier today(ProviderContainer c) =>
      c.read(recommendationProvider.notifier);
  CirclePlansNotifier plans(ProviderContainer c) =>
      c.read(circlePlansProvider.notifier);
  Future<void> delete(ProviderContainer c) =>
      c.read(circleHistoryDeletionProvider).delete();

  Future<Map<String, Object?>> json(String key) async {
    final raw = (await h.disk.stored())[key];
    return raw is String ? jsonDecode(raw) as Map<String, Object?> : {};
  }

  Future<Map<String, Object?>> planOnDisk([
    String planId = 'getting_going',
  ]) async =>
      (((await json(circlePlansKey))['plans'] as Map?)?[planId] as Map?)
          ?.cast<String, Object?>() ??
      {};

  Future<DurableState> disk() async => DurableState(await h.disk.stored());

  group('Claude AUD-N2 — no deleted action instant comes back', () {
    test('Start, Delete, the same stage Circle served again the same day, '
        'Plan paused before its Start: no Start instant is stamped', () async {
      final c = h.open();
      plans(c).start('getting_going');
      today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await R8Harness.settle();
      final id = c.read(recommendationProvider).recommendation!.circleId;
      today(c).start();
      await R8Harness.settle();
      h.clock.value = day1.add(const Duration(minutes: 40));
      await delete(c);
      await R8Harness.settle();
      today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await R8Harness.settle();
      expect(c.read(recommendationProvider).recommendation?.circleId, id);
      expect(plans(c).pause('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      expect(
        ((await planOnDisk())['lastServed'] as Map?)?['startedBeforePause'],
        isNull,
        reason: 'the deleted session\'s Start instant was written back',
      );
      expect((await disk()).always(), isEmpty);
    });

    test('Close requested, Delete, re-served the same day, Plan left: no '
        'Close instant is stamped', () async {
      final c = h.open();
      plans(c).start('getting_going');
      today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await R8Harness.settle();
      today(c).start();
      await R8Harness.settle();
      h.clock.value = day1.add(const Duration(minutes: 25));
      today(c).close();
      await R8Harness.settle();
      await delete(c);
      await R8Harness.settle();
      today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await R8Harness.settle();
      expect(plans(c).leave('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      expect(
        ((await planOnDisk())['lastServed'] as Map?)?['closedBeforeLeave'],
        isNull,
        reason: 'the deleted session\'s Close instant was written back',
      );
    });

    test('control — without a Delete, a Start before the Pause is stamped',
        () async {
      final c = h.open();
      plans(c).start('getting_going');
      today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await R8Harness.settle();
      today(c).start();
      await R8Harness.settle();
      plans(c).pause('getting_going');
      await R8Harness.settle();
      expect(
        ((await planOnDisk())['lastServed'] as Map?)?['startedBeforePause'],
        isNotNull,
      );
    });
  });

  group('Claude AUD-N3 — a change reported not saved is never saved by '
      'the Delete', () {
    test('a Pause being written when Delete begins, then refused: the user '
        'is told, and disk and screen both keep the Plan active', () async {
      final c = h.open();
      expect(plans(c).start('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      final held = h.disk.hold(circlePlansKey);
      expect(plans(c).pause('getting_going'), PlanActionResult.done);
      await held.reached;
      final deleted = delete(c);
      await R8Harness.settle();
      held.release(DiskFault.throws);
      await deleted;
      await R8Harness.settle();
      final failures = c.read(storeSaveFailuresProvider);
      expect(failures.last, UserStore.circlePlans, reason: 'user told');
      expect(
        (await planOnDisk())['lifecycle'],
        'active',
        reason: 'a change reported as not saved is on disk',
      );
      expect(
        c.read(circlePlansProvider).lifecycleOf('getting_going'),
        PlanLifecycle.active,
      );
      expect((await disk()).deletionResidue(), isEmpty);
      await h.restart();
      expect(
        h.open().read(circlePlansProvider).lifecycleOf('getting_going'),
        PlanLifecycle.active,
      );
      expect(h.disk.overlaps, isEmpty);
    });

    test('control — a Pause being written when Delete begins, then landing: '
        'paused on disk, nothing reported failed', () async {
      final c = h.open();
      plans(c).start('getting_going');
      await R8Harness.settle();
      final held = h.disk.hold(circlePlansKey);
      plans(c).pause('getting_going');
      await held.reached;
      final deleted = delete(c);
      await R8Harness.settle();
      held.release();
      await deleted;
      await R8Harness.settle();
      expect((await planOnDisk())['lifecycle'], 'paused');
      expect(c.read(storeSaveFailuresProvider).count, 0);
      expect(
        c.read(storeSaveFailuresProvider).unsaved,
        isNot(contains(UserStore.circlePlans)),
      );
      expect((await disk()).deletionResidue(), isEmpty);
    });

    test('control — the Delete intent refused while a Pause is pending: '
        'nothing is deleted, the Pause lands', () async {
      final c = h.open();
      plans(c).start('getting_going');
      today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await R8Harness.settle();
      final held = h.disk.hold(circlePlansKey);
      plans(c).pause('getting_going');
      await held.reached;
      h.disk.fail(historyDeletionPendingKey, DiskFault.returnsFalse);
      await expectLater(delete(c), throwsA(isA<HistoryDeletionNotStarted>()));
      held.release();
      await R8Harness.settle();
      h.disk.healAll();
      expect((await planOnDisk())['lifecycle'], 'paused');
      expect((await planOnDisk())['lastServed'], isNotNull);
      expect((await h.disk.stored())[recommendationDayKey], isNotNull);
    });
  });

  group('founder decision D1 — an Insight\'s attribution goes with History',
      () {
    CirclePart part(ElementId e) => CirclePart(e, elementOf(e).minutes);
    final window = [
      part(ElementId.openWindow),
      part(ElementId.standingStretch),
      part(ElementId.sitAMinute),
    ];
    final reading = [
      part(ElementId.phoneFaceDown),
      part(ElementId.readPages),
    ];
    final morning = DateTime(2026, 10, 30, 9);

    CircleJournalEntry entry(
      int ago,
      Intention need, {
      List<CirclePart> parts = const [],
      Set<ElementId> skipped = const {},
    }) {
      final date = morning.subtract(Duration(days: ago));
      return CircleJournalEntry(
        schemaVersion: circleJournalSchemaVersion,
        circleId: dateKey(date),
        localDate: dateKey(date),
        direction: need,
        activityId: ActivityId.values.first,
        catalogVersion: catalogVersion,
        shownAt: date,
        startedAt: date,
        closedAt: date,
        session: parts.isEmpty
            ? null
            : CircleSessionRecord(
                title: 'Circle',
                parts: CirclePlan(parts).toWire(),
                skipped: [for (final e in skipped) e.name],
              ),
      );
    }

    /// History that shows I3 for Open a window, a manual "Don't suggest"
    /// and an extension field on the stored preferences.
    Future<void> bootI3() async {
      h.clock.value = morning;
      await h.boot({
        circleJournalKey: jsonEncode({
          'schemaVersion': circleJournalSchemaVersion,
          'entries': [
            for (final ago in [2, 4, 6, 8, 10, 12, 15])
              entry(ago, Intention.clearerHead, parts: reading).toJson(),
            for (final (k, ago) in [1, 5, 9, 11].indexed)
              entry(
                ago,
                Intention.moreEnergy,
                parts: window,
                skipped: k == 1 ? const {} : {ElementId.openWindow},
              ).toJson(),
          ],
        }),
        suggestionPreferencesKey: jsonEncode({
          'schemaVersion': suggestionPreferencesSchemaVersion,
          'notSuggested': [
            {
              'activityId': ActivityId.values.first.name,
              'need': Intention.moreEnergy.name,
              'since': '2026-10-01T09:00:00.000',
            },
          ],
          'elementsLeftOut': [
            {
              'elementId': ElementId.readPages.name,
              'since': '2026-10-02T09:00:00.000',
              'futureItemField': 'kept',
            },
          ],
          'futureTopField': 1,
        }),
      });
    }

    /// I3 applied: Open a window left out, with the Insight's id on it.
    Future<(ProviderContainer, String)> appliedI3() async {
      await bootI3();
      final c = h.open();
      final shown = c.read(insightsProvider.notifier).assess().added.single;
      expect(shown.family, InsightFamily.skippedPart);
      await R8Harness.settle();
      expect(
        await c.read(insightsProvider.notifier).apply(shown.id),
        InsightActionResult.done,
      );
      await R8Harness.settle();
      return (c, shown.id);
    }

    Map<String, Object?>? leftOutOnDisk(DurableState s, ElementId e) =>
        ((s.preferencesJson?['elementsLeftOut'] as List?) ?? const [])
            .cast<Map>()
            .where((i) => i['elementId'] == e.name)
            .firstOrNull
            ?.cast<String, Object?>();

    test('after a Delete that succeeds, the left-out part no longer names '
        'the Insight; the part, its date and every other preference stay',
        () async {
      final (c, id) = await appliedI3();
      final before = await disk();
      expect(leftOutOnDisk(before, ElementId.openWindow)?['byInsight'], id);
      await delete(c);
      await R8Harness.settle();
      final after = await disk();
      final kept = leftOutOnDisk(after, ElementId.openWindow);
      expect(kept, isNotNull, reason: 'the user\'s preference was removed');
      expect(kept!.containsKey('byInsight'), isFalse);
      expect(
        kept['since'],
        leftOutOnDisk(before, ElementId.openWindow)!['since'],
      );
      expect(after.deletionResidue(before: before), isEmpty);
      expect(after.preferencesJson?['futureTopField'], 1);
      expect(
        leftOutOnDisk(after, ElementId.readPages)?['futureItemField'],
        'kept',
      );
      expect(
        c.read(suggestionPreferencesProvider).leftOut,
        contains(ElementId.openWindow),
      );
      await h.restart();
      final again = h.open();
      expect(
        again.read(suggestionPreferencesProvider).leftOut,
        containsAll([ElementId.openWindow, ElementId.readPages]),
      );
      expect((await disk()).deletionResidue(before: before), isEmpty);
    });

    test('the Insight\'s own "Leave this out" still being written when the '
        'Delete begins: it lands, and the Delete removes its attribution',
        () async {
      await bootI3();
      final c = h.open();
      final shown = c.read(insightsProvider.notifier).assess().added.single;
      await R8Harness.settle();
      final held = h.disk.hold(suggestionPreferencesKey);
      final applying = c.read(insightsProvider.notifier).apply(shown.id);
      await held.reached;
      final deleted = delete(c);
      await R8Harness.settle();
      held.release();
      await applying;
      await deleted;
      await R8Harness.settle();
      final after = await disk();
      final kept = leftOutOnDisk(after, ElementId.openWindow);
      expect(kept, isNotNull);
      expect(kept!.containsKey('byInsight'), isFalse);
      expect(after.deletionResidue(), isEmpty);
      await h.restart();
      expect((await disk()).deletionResidue(), isEmpty);
    });

    test('the attribution\'s removal refused: the Delete reports failure '
        'and stays pending; the next start finishes it', () async {
      final (c, _) = await appliedI3();
      final before = await disk();
      h.disk.fail(suggestionPreferencesKey, DiskFault.returnsFalse);
      await expectLater(delete(c), throwsA(anything));
      await R8Harness.settle();
      expect(
        (await h.disk.stored())[historyDeletionPendingKey],
        true,
        reason: 'a Delete reported done with the attribution still stored',
      );
      h.disk.healAll();
      await h.restart();
      final after = await disk();
      expect(after.deletionResidue(before: before), isEmpty);
      expect(
        leftOutOnDisk(after, ElementId.openWindow),
        isNotNull,
      );
    });

    test('the app stops right after the Delete intent lands: the next start '
        'removes the attribution and keeps the part', () async {
      final (c, _) = await appliedI3();
      final before = await disk();
      h.disk.stopAfter = h.disk.log.length + 1;
      delete(c).ignore();
      await R8Harness.settle();
      expect((await h.disk.stored())[historyDeletionPendingKey], true);
      await h.restart();
      final after = await disk();
      expect(after.deletionResidue(before: before), isEmpty);
      expect(leftOutOnDisk(after, ElementId.openWindow), isNotNull);
    });

    test('control — the Delete intent refused: the preferences are not '
        'touched, the attribution included', () async {
      final (c, id) = await appliedI3();
      final before = (await h.disk.stored())[suggestionPreferencesKey];
      h.disk.fail(historyDeletionPendingKey, DiskFault.returnsFalse);
      await expectLater(delete(c), throwsA(isA<HistoryDeletionNotStarted>()));
      await R8Harness.settle();
      expect((await h.disk.stored())[suggestionPreferencesKey], before);
      expect(
        leftOutOnDisk(await disk(), ElementId.openWindow)?['byInsight'],
        id,
      );
    });

    test('control — a preferences record THIRTY can\'t read is left exactly '
        'as stored by the Delete', () async {
      await h.boot({
        suggestionPreferencesKey: jsonEncode({
          'schemaVersion': suggestionPreferencesSchemaVersion + 1,
          'elementsLeftOut': [
            {'elementId': 'openWindow', 'byInsight': 'I3@x'},
          ],
        }),
      });
      final again = h.open();
      final stored = (await h.disk.stored())[suggestionPreferencesKey];
      await delete(again);
      await R8Harness.settle();
      expect((await h.disk.stored())[suggestionPreferencesKey], stored);
      expect((await h.disk.stored())[historyDeletionPendingKey], isNull);
    });
  });
}
