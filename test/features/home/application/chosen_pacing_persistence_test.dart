import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/analytics/analytics_event_type.dart';
import 'package:thirty/core/analytics/analytics_service.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/insights/application/insight_provider.dart';
import 'package:thirty/features/insights/domain/insight_family.dart';
import 'package:thirty/features/plans/application/plan_provider.dart';
import 'package:thirty/features/plans/domain/plan_catalog.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/plans/domain/plan_state.dart';

/// PACING-1 — the Circle history records the guidance the user actually
/// chose. A lighter choice made after the Circle was shown must reach the
/// journal (and stay through Start, Close and reflection), so the
/// chosen-pacing Insight can see genuine choices.
class _SilentAnalytics implements AnalyticsService {
  @override
  void track(AnalyticsEventType type, {Map<String, Object?>? metadata}) {}
}

void main() {
  group('CircleJournalRepository treatment ownership', () {
    late CircleJournalRepository journal;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      journal = CircleJournalRepository(await SharedPreferences.getInstance());
    });

    final shownAt = DateTime(2026, 8, 2, 9);

    Future<void> showPlanCircle({
      String treatmentUsed = 'standard',
      String treatmentSource = 'ordinaryDefault',
    }) => journal.recordShown(
      circleId: '2026-08-02',
      localDate: '2026-08-02',
      direction: Intention.moreEnergy,
      activityId: ActivityId.energisingBreathReset,
      shownAt: shownAt,
      planId: 'moreEnergyPath',
      planVersion: 1,
      stageId: 'more_energy_1_establish',
      planCycleId: 'moreEnergyPath_cycle_1',
      treatmentUsed: treatmentUsed,
      revisitUsed: false,
      treatmentSource: treatmentSource,
    );

    test('a later lifecycle write carries the current treatment onto an '
        'existing entry, leaving its Plan identity untouched', () async {
      await showPlanCircle();
      await journal.recordStarted(
        circleId: '2026-08-02',
        localDate: '2026-08-02',
        direction: Intention.moreEnergy,
        activityId: ActivityId.energisingBreathReset,
        startedAt: shownAt.add(const Duration(minutes: 2)),
        // A later call's Plan identity fields are ignored for an existing
        // entry; only the treatment follows the session.
        planId: 'gentlerPacePath',
        planVersion: 9,
        stageId: 'other',
        planCycleId: 'other',
        treatmentUsed: 'lighter',
        revisitUsed: true,
        treatmentSource: 'directChoice',
      );

      final entry = journal.readAll().single;
      expect(entry.treatmentUsed, 'lighter');
      expect(entry.treatmentSource, 'directChoice');
      expect(entry.planId, 'moreEnergyPath');
      expect(entry.planVersion, 1);
      expect(entry.stageId, 'more_energy_1_establish');
      expect(entry.planCycleId, 'moreEnergyPath_cycle_1');
      expect(entry.revisitUsed, isFalse);
      expect(entry.shownAt, shownAt);
      expect(entry.startedAt, isNotNull);
    });

    test('a late "shown" write never overwrites a choice already '
        'recorded', () async {
      await showPlanCircle(
        treatmentUsed: 'lighter',
        treatmentSource: 'directChoice',
      );
      await showPlanCircle();

      final entry = journal.readAll().single;
      expect(entry.treatmentUsed, 'lighter');
      expect(entry.treatmentSource, 'directChoice');
    });

    test('a write without a treatment never clears a recorded one, and a '
        'Free Circle stays without one', () async {
      await showPlanCircle(
        treatmentUsed: 'lighter',
        treatmentSource: 'directChoice',
      );
      await journal.recordUsefulness(
        circleId: '2026-08-02',
        localDate: '2026-08-02',
        direction: Intention.moreEnergy,
        activityId: ActivityId.energisingBreathReset,
        response: CircleUsefulnessResponse.veryUseful,
        respondedAt: shownAt,
      );
      expect(journal.readAll().single.treatmentUsed, 'lighter');

      await journal.recordClosed(
        circleId: '2026-08-03',
        localDate: '2026-08-03',
        direction: Intention.clearerHead,
        activityId: activityPools[Intention.clearerHead]!.first,
        closedAt: DateTime(2026, 8, 3, 9),
      );
      final free = journal.readAll().last;
      expect(free.planId, isNull);
      expect(free.treatmentUsed, isNull);
      expect(free.treatmentSource, isNull);
    });
  });

  group('RecommendationNotifier → journal', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    /// One day of the real app over the same store, Premium active, with
    /// More Energy Path active.
    ProviderContainer dayAt(DateTime morning, {DateTime Function()? clock}) {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          nowProvider.overrideWithValue(morning),
          eventClockProvider.overrideWithValue(clock ?? () => morning),
          premiumEntitlementProvider.overrideWithValue(true),
          analyticsServiceProvider.overrideWithValue(_SilentAnalytics()),
        ],
      );
      container.read(planProvider.notifier).activatePlan(PlanId.moreEnergyPath);
      return container;
    }

    CircleJournalEntry today(ProviderContainer container) => container
        .read(circleJournalRepositoryProvider)
        .readAll()
        .singleWhere((e) => e.circleId == '2026-08-02');

    final morning = DateTime(2026, 8, 2, 9);

    test('no change of guidance: the history stays standard / '
        'ordinaryDefault through the whole Circle', () async {
      final container = dayAt(morning);
      addTearDown(container.dispose);
      final circle = container.read(recommendationProvider.notifier);

      circle.chooseIntention(Intention.moreEnergy);
      await pumpEventQueue();
      circle.start();
      circle.close();
      circle.reportAttempt(CircleAttemptResponse.yes);
      await pumpEventQueue();

      final entry = today(container);
      expect(entry.treatmentUsed, PlanTreatment.standard.name);
      expect(entry.treatmentSource, PlanTreatmentSource.ordinaryDefault.name);
    });

    test('lighter chosen after the Circle is already in the history is '
        'recorded at once, and stays through Start, Close and '
        'reflection', () async {
      final container = dayAt(morning);
      addTearDown(container.dispose);
      final circle = container.read(recommendationProvider.notifier);
      const lighter = 'lighter';
      const direct = 'directChoice';

      circle.chooseIntention(Intention.moreEnergy);
      await pumpEventQueue();
      expect(today(container).treatmentUsed, PlanTreatment.standard.name);

      circle.setPlanTreatment(PlanTreatment.lighter);
      await pumpEventQueue();
      expect(today(container).treatmentUsed, lighter);
      expect(today(container).treatmentSource, direct);

      circle.start();
      await pumpEventQueue();
      expect(today(container).treatmentUsed, lighter);

      circle.close();
      await pumpEventQueue();
      expect(today(container).treatmentUsed, lighter);

      circle.reportAttempt(CircleAttemptResponse.yes);
      await pumpEventQueue();
      circle.reportUsefulness(CircleUsefulnessResponse.veryUseful);
      await pumpEventQueue();

      final entry = today(container);
      expect(entry.treatmentUsed, lighter);
      expect(entry.treatmentSource, direct);
      expect(entry.planId, PlanId.moreEnergyPath.name);
      expect(entry.stageId, stageAt(PlanId.moreEnergyPath, 0).id);
      expect(entry.planCycleId, 'moreEnergyPath_cycle_1');
      expect(entry.planVersion, planContentVersion);
      expect(entry.revisitUsed, isFalse);
      expect(entry.startedAt, isNotNull);
      expect(entry.closedAt, isNotNull);
      expect(entry.attemptResponse, CircleAttemptResponse.yes);
      expect(entry.usefulnessResponse, CircleUsefulnessResponse.veryUseful);
    });

    test('lighter chosen before the "shown" write lands is not reverted by '
        'it', () async {
      final container = dayAt(morning);
      addTearDown(container.dispose);
      final circle = container.read(recommendationProvider.notifier);

      circle.chooseIntention(Intention.moreEnergy);
      circle.setPlanTreatment(PlanTreatment.lighter);
      await pumpEventQueue();
      circle.start();
      await pumpEventQueue();

      expect(today(container).treatmentUsed, PlanTreatment.lighter.name);
    });

    test('changing back to standard records the final choice', () async {
      final container = dayAt(morning);
      addTearDown(container.dispose);
      final circle = container.read(recommendationProvider.notifier);

      circle.chooseIntention(Intention.moreEnergy);
      await pumpEventQueue();
      circle.setPlanTreatment(PlanTreatment.lighter);
      await pumpEventQueue();
      circle.setPlanTreatment(PlanTreatment.standard);
      await pumpEventQueue();
      circle.start();
      circle.close();
      await pumpEventQueue();

      final entry = today(container);
      expect(entry.treatmentUsed, PlanTreatment.standard.name);
      expect(entry.treatmentSource, PlanTreatmentSource.directChoice.name);
    });

    test('a Free Circle has no treatment to record', () async {
      final container = dayAt(morning);
      addTearDown(container.dispose);
      final circle = container.read(recommendationProvider.notifier);

      circle.chooseIntention(Intention.gentlerPace);
      await pumpEventQueue();
      circle.setPlanTreatment(PlanTreatment.lighter);
      circle.start();
      circle.close();
      await pumpEventQueue();

      final entry = today(container);
      expect(entry.planId, isNull);
      expect(entry.treatmentUsed, isNull);
      expect(entry.treatmentSource, isNull);
      expect(entry.closedAt, isNotNull);
    });

    /// Five Plan Circles across 15 days, each walked through the real
    /// notifiers; [chooseLighter] picks the lighter guidance after the
    /// Circle was shown, exactly as on Today.
    Future<void> walkFiveDays({required bool chooseLighter}) async {
      for (final offset in [0, 4, 8, 11, 15]) {
        final day = DateTime(2026, 8, 2 + offset, 9);
        var now = day;
        final container = dayAt(day, clock: () => now);
        final circle = container.read(recommendationProvider.notifier);
        circle.chooseIntention(Intention.moreEnergy);
        await pumpEventQueue();
        if (chooseLighter) {
          circle.setPlanTreatment(PlanTreatment.lighter);
          await pumpEventQueue();
        }
        now = day.add(const Duration(minutes: 2));
        circle.start();
        await pumpEventQueue();
        now = day.add(const Duration(minutes: 32));
        circle.close();
        await pumpEventQueue();
        circle.reportAttempt(CircleAttemptResponse.yes);
        await pumpEventQueue();
        circle.reportUsefulness(CircleUsefulnessResponse.somewhatUseful);
        await pumpEventQueue();
        container.dispose();
      }
    }

    ProviderContainer insightsOn(DateTime day) {
      final container = dayAt(day);
      container.read(insightProvider.notifier).refreshIfDue();
      return container;
    }

    test('genuine lighter choices make the chosen-pacing Insight reachable '
        'under its unchanged rules', () async {
      await walkFiveDays(chooseLighter: true);

      final container = insightsOn(DateTime(2026, 8, 18, 9));
      addTearDown(container.dispose);

      final snapshot = container.read(insightProvider).snapshots.single;
      expect(snapshot.family, InsightFamily.chosenPacing);
      expect(snapshot.targetPlanId, PlanId.moreEnergyPath);
      expect(snapshot.evidenceCount, 5);
      expect(snapshot.usefulnessNumerator, 5);
      expect(snapshot.usefulnessDenominator, 5);
    });

    test('without lighter choices the same history produces no '
        'chosen-pacing Insight', () async {
      await walkFiveDays(chooseLighter: false);

      final container = insightsOn(DateTime(2026, 8, 18, 9));
      addTearDown(container.dispose);

      expect(
        container
            .read(insightProvider)
            .snapshots
            .where((s) => s.family == InsightFamily.chosenPacing),
        isEmpty,
      );
    });
  });
}
