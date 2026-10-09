import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/qa/qa_container.dart';
import 'package:thirty/core/qa/qa_entitlement_gateway.dart';
import 'package:thirty/core/qa/qa_scenario.dart';
import 'package:thirty/core/qa/qa_shared_preferences.dart';
import 'package:thirty/features/coach/application/coach_provider.dart';
import 'package:thirty/features/coach/domain/coach_family.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/insights/application/insight_provider.dart';
import 'package:thirty/features/insights/domain/insight_family.dart';
import 'package:thirty/features/plans/application/plan_provider.dart';
import 'package:thirty/features/plans/domain/plan_catalog.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/plans/domain/plan_state.dart';

/// QA-1 — each synthetic scenario, built through the production Circle,
/// Plan and Insight notifiers, then opened on the reference day exactly as
/// the harness would open it.
void main() {
  final reference = DateTime(2026, 10, 8, 10);
  late SharedPreferences genuine;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    genuine = await SharedPreferences.getInstance();
  });

  Future<QaSharedPreferences> build(QaScenario scenario) => buildQaStore(
    scenario: scenario,
    genuine: genuine,
    referenceNow: reference,
  );

  /// The harness's app container for [scenario] on the reference day.
  Future<ProviderContainer> open(
    QaScenario scenario, {
    QaEntitlement entitlement = QaEntitlement.active,
  }) async {
    final container = ProviderContainer(
      overrides: [
        ...qaContainerOverrides(
          genuinePreferences: genuine,
          supabaseAvailable: false,
          session: QaSession(
            entitlement: scenario.fixedEntitlement ?? entitlement,
            scenario: scenario,
            store: await build(scenario),
          ),
        ),
        nowProvider.overrideWithValue(reference),
        eventClockProvider.overrideWithValue(() => reference),
      ],
    );
    await container.read(entitlementStatusProvider.notifier).initialize();
    return container;
  }

  List<CircleJournalEntry> journalOf(ProviderContainer container) =>
      container.read(circleJournalRepositoryProvider).readAll();

  test('only lapsed_retained_snapshots fixes its entitlement (inactive)', () {
    for (final scenario in QaScenario.values) {
      expect(
        scenario.fixedEntitlement,
        scenario == QaScenario.lapsedRetainedSnapshots
            ? QaEntitlement.inactive
            : isNull,
      );
    }
  });

  test('scenario wire names are the ones the walkthrough uses', () {
    expect(QaScenario.values.map((s) => s.wireName), [
      'none',
      'new_user',
      'plan_in_progress',
      'month_two',
      'never_reflects',
      'lapsed_retained_snapshots',
      'free_not_useful',
      'free_useful',
      'free_exploration',
      'free_secondary',
      'free_v1_history',
    ]);
  });

  test('synthetic history never includes the reference day itself, so '
      "today's Circle is still open to walk", () async {
    for (final scenario in QaScenario.values) {
      final container = await open(scenario);
      addTearDown(container.dispose);
      expect(
        journalOf(container).map((e) => e.localDate),
        isNot(contains('2026-10-08')),
      );
      expect(
        container.read(recommendationProvider).recommendation,
        isNull,
        reason: scenario.wireName,
      );
    }
  });

  test('the same scenario and reference date always build the same '
      'store', () async {
    for (final scenario in QaScenario.values) {
      final first = (await build(scenario)).snapshot();
      final second = (await build(scenario)).snapshot();
      expect(second, first, reason: scenario.wireName);
    }
  });

  group('new_user', () {
    test('Premium active with no history: no Plan, no Coach, and Insights '
        'claims nothing', () async {
      final container = await open(QaScenario.newUser);
      addTearDown(container.dispose);

      expect(container.read(premiumEntitlementProvider), isTrue);
      expect(journalOf(container), isEmpty);
      expect(container.read(planProvider).activePlanId, isNull);
      for (final planId in PlanId.values) {
        expect(container.read(coachCueProvider(planId)), isNull);
      }

      container.read(insightProvider.notifier).refreshIfDue();
      expect(container.read(insightProvider).snapshots, isEmpty);
      expect(container.read(displayedInsightProvider), isNull);
    });
  });

  group('plan_in_progress', () {
    test('More Energy Path three stages in; today resolves stage 4 and '
        'Coach speaks from the last reflection', () async {
      final container = await open(QaScenario.planInProgress);
      addTearDown(container.dispose);

      final journal = journalOf(container);
      expect(journal, hasLength(5));
      expect(journal.where((e) => e.planId != null).map((e) => e.stageId), [
        for (var i = 0; i < 3; i++) stageAt(PlanId.moreEnergyPath, i).id,
      ]);

      final plans = container.read(planProvider);
      expect(plans.activePlanId, PlanId.moreEnergyPath);
      final progress = plans.progress[PlanId.moreEnergyPath]!;
      expect(progress.forwardCursor, 3);
      expect(progress.status, PlanCycleStatus.inProgress);

      expect(
        container.read(coachCueProvider(PlanId.moreEnergyPath)),
        isNotNull,
      );

      container
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy);
      final today = container.read(recommendationProvider).recommendation!;
      expect(today.planId, PlanId.moreEnergyPath);
      expect(today.stageId, stageAt(PlanId.moreEnergyPath, 3).id);
    });

    test('ten days of history is too little for an Insight — none is '
        'invented', () async {
      final container = await open(QaScenario.planInProgress);
      addTearDown(container.dispose);

      container.read(insightProvider.notifier).refreshIfDue();
      expect(container.read(insightProvider).snapshots, isEmpty);
    });
  });

  group('month_two', () {
    test('one completed cycle retained, a second under way', () async {
      final container = await open(QaScenario.monthTwo);
      addTearDown(container.dispose);

      final plans = container.read(planProvider);
      expect(plans.activePlanId, PlanId.gentlerPacePath);
      final progress = plans.progress[PlanId.gentlerPacePath]!;
      expect(progress.cycleHistory, hasLength(1));
      expect(progress.cycleHistory.single.completedAt, isNotNull);
      expect(progress.cycleId, 'gentlerPacePath_cycle_2');
      expect(progress.status, PlanCycleStatus.inProgress);
      expect(progress.forwardCursor, 2);
      expect(
        container.read(coachCueProvider(PlanId.gentlerPacePath)),
        isNotNull,
      );
    });

    test('continuing value: opening Insights finds the deliberate revisits '
        'of cycle 2 and offers to queue the stage again', () async {
      final container = await open(QaScenario.monthTwo);
      addTearDown(container.dispose);

      final revisits = journalOf(
        container,
      ).where((e) => e.revisitUsed == true).toList();
      expect(revisits, hasLength(5));
      expect(revisits.map((e) => e.stageId).toSet(), {
        stageAt(PlanId.gentlerPacePath, 1).id,
      });

      container.read(insightProvider.notifier).refreshIfDue();
      final snapshot = container.read(insightProvider).snapshots.last;
      expect(snapshot.family, InsightFamily.deliberateRevisits);
      expect(snapshot.targetPlanId, PlanId.gentlerPacePath);
      expect(snapshot.evidenceCount, 5);
      expect(snapshot.usefulnessDenominator, 5);

      final displayed = container.read(displayedInsightProvider)!;
      expect(displayed.isCurrent, isTrue);
    });
  });

  group('never_reflects', () {
    test('weeks of closed Circles with no reflection answer at all', () async {
      final container = await open(QaScenario.neverReflects);
      addTearDown(container.dispose);

      final journal = journalOf(container);
      expect(journal, hasLength(10));
      expect(journal.every((e) => e.closedAt != null), isTrue);
      expect(journal.every((e) => e.attemptResponse == null), isTrue);
      expect(journal.every((e) => e.usefulnessResponse == null), isTrue);
    });

    test(
      'Coach and Insights stay truthful: no feedback-based cue, an '
      'Insight from closed Circles alone with no usefulness figure',
      () async {
        final container = await open(QaScenario.neverReflects);
        addTearDown(container.dispose);

        final plans = container.read(planProvider);
        expect(plans.activePlanId, PlanId.clearerHeadPath);
        expect(plans.progress[PlanId.clearerHeadPath]!.forwardCursor, 3);
        final cue = container.read(coachCueProvider(PlanId.clearerHeadPath));
        expect(cue?.family, isNot(CoachFamily.actionFeedback));

        final snapshot = container.read(insightProvider).snapshots.single;
        expect(snapshot.family, InsightFamily.directionPathContinuity);
        expect(snapshot.targetPlanId, PlanId.moreEnergyPath);
        expect(snapshot.usefulnessNumerator, isNull);
        expect(snapshot.usefulnessDenominator, isNull);
      },
    );
  });

  group('lapsed_retained_snapshots', () {
    test('inactive, with the Plan position and Insight snapshots earned '
        'while subscribed retained', () async {
      final container = await open(QaScenario.lapsedRetainedSnapshots);
      addTearDown(container.dispose);

      expect(container.read(premiumEntitlementProvider), isFalse);
      final plans = container.read(planProvider);
      expect(plans.activePlanId, PlanId.moreEnergyPath);
      expect(plans.progress[PlanId.moreEnergyPath]!.forwardCursor, 3);

      final snapshots = container.read(insightProvider).snapshots;
      expect(snapshots, isNotEmpty);
      expect(
        snapshots.every(
          (s) => s.family == InsightFamily.directionPathContinuity,
        ),
        isTrue,
      );
    });

    test('Free continued after the lapse: the last three Circles are '
        'Free-selector Circles, not Plan Sessions', () async {
      final container = await open(QaScenario.lapsedRetainedSnapshots);
      addTearDown(container.dispose);

      final journal = journalOf(container);
      expect(journal, hasLength(13));
      final afterLapse = journal.sublist(journal.length - 3);
      expect(afterLapse.map((e) => e.localDate), [
        '2026-10-02',
        '2026-10-05',
        '2026-10-07',
      ]);
      expect(afterLapse.every((e) => e.planId == null), isTrue);
      expect(afterLapse.every((e) => e.closedAt != null), isTrue);
    });

    test('no new paid computation: no Insight assessment, no Plan Session, '
        'no application — and today is a normal Free Circle', () async {
      final container = await open(QaScenario.lapsedRetainedSnapshots);
      addTearDown(container.dispose);
      final before = container.read(insightProvider);

      container.read(insightProvider.notifier).refreshIfDue();
      final after = container.read(insightProvider);
      expect(after.lastAssessedAt, before.lastAssessedAt);
      expect(after.snapshots, hasLength(before.snapshots.length));
      expect(container.read(insightProvider.notifier).applyCurrent(), isFalse);

      container
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy);
      final today = container.read(recommendationProvider).recommendation!;
      expect(today.planId, isNull);
      expect(
        container
            .read(planProvider)
            .progress[PlanId.moreEnergyPath]!
            .forwardCursor,
        3,
      );
    });
  });

  test('inactive and unavailable on a Premium history pause Plans the same '
      'way, keeping the saved position', () async {
    for (final entitlement in [
      QaEntitlement.inactive,
      QaEntitlement.unavailable,
    ]) {
      final container = await open(
        QaScenario.planInProgress,
        entitlement: entitlement,
      );
      addTearDown(container.dispose);

      expect(container.read(premiumEntitlementProvider), isFalse);
      container
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy);
      expect(
        container.read(recommendationProvider).recommendation!.planId,
        isNull,
        reason: entitlement.name,
      );
      expect(
        container
            .read(planProvider)
            .progress[PlanId.moreEnergyPath]!
            .forwardCursor,
        3,
      );
    }
  });
}
