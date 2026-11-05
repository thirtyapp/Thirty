import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/storage/store_save_failures.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/insights/domain/insight_engine.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.1 RL-1 / Claude AUD-6 (founder decision, 2026-11-05): a Plan or
/// Insight change the store hasn't confirmed is pending, never confirmed
/// state. While it is in flight it may be shown; once its save fails the
/// screen goes back to what is on disk, and nothing that depends on it — a
/// stage Circle, its served-stage record, a credit, an Insight — is saved
/// on the strength of it. A restart reads only the disk.
void main() {
  final morning = DateTime(2026, 10, 12, 9);
  late R8Harness h;

  setUp(() async {
    h = R8Harness(morning);
    await h.boot();
  });

  RecommendationNotifier today(ProviderContainer c) =>
      c.read(recommendationProvider.notifier);
  CirclePlansNotifier plans(ProviderContainer c) =>
      c.read(circlePlansProvider.notifier);
  void lapse(ProviderContainer c) =>
      (c.read(entitlementStatusProvider.notifier) as SettableEntitlement).set(
        EntitlementStatus.inactive,
      );
  Future<Map<String, Object>> disk() => h.disk.stored();

  for (final fault in DiskFault.values) {
    group('${fault.name}:', () {
      test('a Plan start still being saved, then today\'s choice: the stage '
          'Circle may show while pending; once the save fails the Plan is '
          'off the screen and the Circle is never saved on it — on disk and '
          'after a restart', () async {
        final c = h.open();
        final held = h.disk.hold(circlePlansKey);
        expect(plans(c).start('getting_going'), PlanActionResult.done);
        await held.reached;
        today(
          c,
        ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
        final id = c.read(recommendationProvider).recommendation!.circleId;
        expect(
          c.read(recommendationProvider).recommendation!.composed?.stage,
          isNotNull,
          reason: 'pending: composed while the start is in flight',
        );
        h.disk.fail(circlePlansKey, fault);
        held.release(fault);
        await R8Harness.settle();

        expect(c.read(circlePlansProvider).active, isNull);
        expect(plans(c).hasUnsavedChanges, isFalse);
        expect(c.read(journalSaveStatusProvider)[id], isFalse);
        final stored = await disk();
        expect(stored.containsKey(circlePlansKey), isFalse);
        expect(
          stored[recommendationComposedKey],
          isNull,
          reason: 'a stage Circle saved on an unsaved Plan',
        );

        h.disk.healAll();
        await h.restart();
        final again = h.open();
        expect(again.read(circlePlansProvider).active, isNull);
        expect(again.read(recommendationProvider).recommendation, isNull);
      });

      test('a Plan start still being saved, then today\'s choice; the save '
          'lands: Plan, served stage and Circle are all saved', () async {
        final c = h.open();
        final held = h.disk.hold(circlePlansKey);
        plans(c).start('getting_going');
        await held.reached;
        today(
          c,
        ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
        final id = c.read(recommendationProvider).recommendation!.circleId;
        held.release();
        await R8Harness.settle();
        final stored = await disk();
        expect(stored[recommendationDayKey], id);
        expect(stored[recommendationComposedKey], contains('"stage"'));
        expect(stored[circlePlansKey], contains('"lastServed"'));
        expect(c.read(journalSaveStatusProvider)[id], isNot(false));
      });

      test('a failed Plan save, then a new user action: the failed change is '
          'not on screen, so the user\'s retry is a real change and lands '
          'once the store heals', () async {
        final c = h.open();
        h.disk.fail(circlePlansKey, fault, times: 1);
        plans(c).start('getting_going');
        await R8Harness.settle();
        expect(c.read(circlePlansProvider).active, isNull);
        expect(c.read(storeSaveFailuresProvider).count, greaterThan(0));

        expect(plans(c).start('getting_going'), PlanActionResult.done);
        await R8Harness.settle();
        expect(c.read(circlePlansProvider).active?.planId, 'getting_going');
        expect(await disk(), contains(circlePlansKey));
        expect(c.read(storeSaveFailuresProvider).unsaved, isEmpty);
      });

      test('a failed pause is undone on screen: the Plan still steers today '
          'as the disk says', () async {
        final c = h.open();
        plans(c).start('getting_going');
        await R8Harness.settle();
        h.disk.fail(circlePlansKey, fault, times: 1);
        plans(c).pause('getting_going');
        await R8Harness.settle();
        expect(c.read(circlePlansProvider).active?.planId, 'getting_going');
        today(
          c,
        ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
        await R8Harness.settle();
        expect(
          c.read(recommendationProvider).recommendation!.composed?.stage,
          isNotNull,
        );
        expect((await disk())[recommendationComposedKey], contains('"stage"'));
      });

      test(
        'Premium lapses while a Plan start is pending, and its save '
        'fails: no stage Circle, nothing served, the Plan is off the screen',
        () async {
          final c = h.open();
          final held = h.disk.hold(circlePlansKey);
          plans(c).start('getting_going');
          await held.reached;
          lapse(c);
          expect(c.read(premiumEntitlementProvider), isFalse);
          today(c).chooseIntention(Intention.moreEnergy);
          expect(
            c.read(recommendationProvider).recommendation!.composed,
            isNull,
          );
          h.disk.fail(circlePlansKey, fault);
          held.release(fault);
          await R8Harness.settle();
          expect(c.read(circlePlansProvider).active, isNull);
          expect(
            '${(await disk())[circlePlansKey]}',
            isNot(contains('served')),
          );
        },
      );

      test('a new Insight whose save fails is not kept on screen; a later '
          'assessment generates and saves it', () async {
        await h.boot({circleJournalKey: _i4Journal(morning)});
        final c = h.open();
        h.disk.fail(insightsKey, fault, times: 1);
        final added = c.read(insightsProvider.notifier).assess().added;
        expect(added, isNotEmpty, reason: 'pending: shown while saving');
        await R8Harness.settle();
        expect(c.read(insightsProvider).snapshots, isEmpty);
        expect((await disk()).containsKey(insightsKey), isFalse);
        expect(c.read(storeSaveFailuresProvider).count, greaterThan(0));

        final again = c.read(insightsProvider.notifier).assess().added;
        expect(again, isNotEmpty);
        await R8Harness.settle();
        expect(c.read(insightsProvider).snapshots, isNotEmpty);
        expect((await disk())[insightsKey], contains(again.single.id));
      });

      test('"Not now" whose save fails: the Insight is current again on '
          'screen and on disk; a restart agrees; a retry lands', () async {
        await h.boot({circleJournalKey: _i4Journal(morning)});
        final c = h.open();
        final shown = c.read(insightsProvider.notifier).assess().added.single;
        await R8Harness.settle();
        final held = h.disk.hold(insightsKey);
        expect(
          c.read(insightsProvider.notifier).notNow(shown.id),
          InsightActionResult.done,
        );
        await held.reached;
        expect(c.read(insightsProvider).byId(shown.id)!.notNowOn, isNotNull);
        held.release(fault);
        await R8Harness.settle();
        expect(c.read(insightsProvider).byId(shown.id)!.notNowOn, isNull);
        expect(
          c
              .read(insightsProvider.notifier)
              .status(c.read(insightsProvider).byId(shown.id)!),
          InsightStatus.current,
        );

        await h.restart();
        final again = h.open();
        expect(again.read(insightsProvider).byId(shown.id)!.notNowOn, isNull);
        again.read(insightsProvider.notifier).notNow(shown.id);
        await R8Harness.settle();
        expect((await disk())[insightsKey], contains('"notNowOn"'));
      });

      test(
        'a restart while a Plan start is pending reads only the disk',
        () async {
          final c = h.open();
          final held = h.disk.hold(circlePlansKey);
          plans(c).start('getting_going');
          await held.reached;
          await h.restart();
          expect(h.open().read(circlePlansProvider).active, isNull);
          held.release();
        },
      );
    });
  }

  test('Insights decide from the confirmed Plans: a Plan start that fails '
      'never withdraws, or is counted by, an Insight', () async {
    await h.boot({
      circleJournalKey: jsonEncode({
        'schemaVersion': circleJournalSchemaVersion,
        'entries': [
          for (final ago in [1, 5, 9, 13, 14])
            _entry(morning, ago, Intention.clearerHead).toJson(),
        ],
      }),
    });
    final c = h.open();
    final shown = c.read(insightsProvider.notifier).assess().added.single;
    expect(shown.family, InsightFamily.planForNeed);
    await R8Harness.settle();
    final held = h.disk.hold(circlePlansKey);
    plans(c).start('making_room');
    await held.reached;
    expect(
      c.read(insightsProvider.notifier).status(shown),
      InsightStatus.current,
      reason: 'judged by a Plan start that is only pending',
    );
    h.disk.fail(circlePlansKey, DiskFault.returnsFalse);
    held.release(DiskFault.returnsFalse);
    await R8Harness.settle();
    expect(
      c.read(insightsProvider.notifier).status(shown),
      InsightStatus.current,
    );
  });
}

CircleJournalEntry _entry(DateTime morning, int ago, Intention need) {
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
  );
}

/// A journal from which, with Premium, Insights generate an Insight 4.
String _i4Journal(DateTime morning) {
  CirclePart part(ElementId e) => CirclePart(e, elementOf(e).minutes);
  final writing = [
    part(ElementId.closeWhatsOpen),
    part(ElementId.getItOut),
    part(ElementId.chooseOne),
    part(ElementId.firstStep),
  ];
  final reading = [part(ElementId.phoneFaceDown), part(ElementId.readPages)];
  CircleJournalEntry entry(int ago, List<CirclePart> parts, bool useful) {
    final date = morning.subtract(Duration(days: ago));
    return CircleJournalEntry(
      schemaVersion: circleJournalSchemaVersion,
      circleId: dateKey(date),
      localDate: dateKey(date),
      direction: Intention.clearerHead,
      activityId: ActivityId.values.first,
      catalogVersion: catalogVersion,
      shownAt: date,
      startedAt: date,
      closedAt: date,
      attemptResponse: useful ? CircleAttemptResponse.yes : null,
      usefulnessResponse: useful ? CircleUsefulnessResponse.veryUseful : null,
      session: CircleSessionRecord(
        title: 'Circle',
        parts: CirclePlan(parts).toWire(),
      ),
    );
  }

  return jsonEncode({
    'schemaVersion': circleJournalSchemaVersion,
    'entries': [
      for (final ago in [1, 7, 13, 20]) entry(ago, writing, true).toJson(),
      for (final ago in [3, 9, 16]) entry(ago, reading, false).toJson(),
    ],
  });
}
