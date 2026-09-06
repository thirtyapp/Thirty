import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/insights/domain/insight_engine.dart';
import 'package:thirty/features/insights/domain/insight_family.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/plans/domain/plan_state.dart';

final _now = DateTime(2026, 9, 6);

CircleJournalEntry _entry({
  required String date,
  Intention direction = Intention.clearerHead,
  ActivityId activityId = ActivityId.phoneFreeWalk,
  String? planId,
  String? stageId,
  String? planCycleId,
  String? treatmentUsed,
  String? treatmentSource,
  bool? revisitUsed,
  CircleAttemptResponse? attemptResponse,
  CircleUsefulnessResponse? usefulnessResponse,
}) {
  return CircleJournalEntry(
    schemaVersion: circleJournalSchemaVersion,
    circleId: date,
    localDate: date,
    direction: direction,
    activityId: activityId,
    catalogVersion: catalogVersion,
    shownAt: DateTime.parse(date),
    planId: planId,
    planVersion: planId == null ? null : 1,
    stageId: stageId,
    planCycleId: planCycleId,
    treatmentUsed: treatmentUsed,
    revisitUsed: revisitUsed,
    treatmentSource: treatmentSource,
    attemptResponse: attemptResponse,
    usefulnessResponse: usefulnessResponse,
  );
}

PlanProgress _freshProgress(PlanId planId) => PlanProgress.fresh(
  planId: planId,
  cycleId: '${planId.name}_cycle_1',
  startedAt: DateTime(2026, 1, 1),
);

PlansState _plansState({
  PlanId? activePlanId,
  Map<PlanId, PlanProgress> overrides = const {},
}) {
  return PlansState(
    activePlanId: activePlanId,
    progress: {
      for (final planId in PlanId.values)
        planId: overrides[planId] ?? _freshProgress(planId),
    },
  );
}

void main() {
  group('evaluateInsight — direction & path continuity', () {
    test('returns null with no journal and no Plan history', () {
      final insight = evaluateInsight(
        journal: [],
        plansState: _plansState(),
        now: _now,
      );
      expect(insight, isNull);
    });

    test(
      'a pattern claim requires 5 records across 3 dates spanning 14 days',
      () {
        // Only 4 records — below the count gate.
        final journal = [
          _entry(date: '2026-08-24'),
          _entry(date: '2026-08-26'),
          _entry(date: '2026-08-28'),
          _entry(date: '2026-09-01'),
        ];
        final insight = evaluateInsight(
          journal: journal,
          plansState: _plansState(),
          now: _now,
        );
        expect(insight, isNull);
      },
    );

    test('insufficient date spread (less than 14 days) is not eligible', () {
      final journal = [
        for (final d in ['2026-09-01', '2026-09-02', '2026-09-03', '2026-09-04', '2026-09-05'])
          _entry(date: d),
      ];
      final insight = evaluateInsight(
        journal: journal,
        plansState: _plansState(),
        now: _now,
      );
      expect(insight, isNull);
    });

    test(
      'an eligible pattern claim names the top direction with correct count '
      'and offers to activate its Plan',
      () {
        final journal = [
          for (final d in ['2026-08-20', '2026-08-23', '2026-08-27', '2026-09-01', '2026-09-05'])
            _entry(date: d, direction: Intention.clearerHead),
        ];
        final insight = evaluateInsight(
          journal: journal,
          plansState: _plansState(),
          now: _now,
        );
        expect(insight, isNotNull);
        expect(insight!.family, InsightFamily.directionPathContinuity);
        expect(insight.isPatternClaim, isTrue);
        expect(insight.targetPlanId, PlanId.clearerHeadPath);
        expect(insight.evidenceCount, 5);
        expect(insight.applicationType, InsightApplicationType.activateOrResumePlan);
      },
    );

    test('a tied top direction produces no pattern claim', () {
      final journal = [
        for (final d in ['2026-08-20', '2026-08-23', '2026-09-05'])
          _entry(date: d, direction: Intention.clearerHead),
        for (final d in ['2026-08-21', '2026-08-24', '2026-09-06'])
          _entry(
            date: d,
            direction: Intention.moreEnergy,
            activityId: ActivityId.thirtyMinuteWalk,
          ),
      ];
      final insight = evaluateInsight(
        journal: journal,
        plansState: _plansState(),
        now: _now,
      );
      expect(insight, isNull);
    });

    test(
      'no pattern claim is offered for a direction whose Plan is already '
      'active — falls through to no insight when no other Plan has a '
      'saved place',
      () {
        final journal = [
          for (final d in ['2026-08-20', '2026-08-23', '2026-08-27', '2026-09-01', '2026-09-05'])
            _entry(date: d, direction: Intention.clearerHead),
        ];
        final insight = evaluateInsight(
          journal: journal,
          plansState: _plansState(activePlanId: PlanId.clearerHeadPath),
          now: _now,
        );
        expect(insight, isNull);
      },
    );

    test(
      'a plain current-place fact is offered for an inactive, previously '
      'engaged Plan even with no pattern evidence at all',
      () {
        final progress = _freshProgress(
          PlanId.gentlerPacePath,
        ).copyWith(forwardCursor: 2, lastEncounteredStageId: 'gentler_pace_2_develop');
        final insight = evaluateInsight(
          journal: [],
          plansState: _plansState(
            activePlanId: PlanId.moreEnergyPath,
            overrides: {PlanId.gentlerPacePath: progress},
          ),
          now: _now,
        );
        expect(insight, isNotNull);
        expect(insight!.family, InsightFamily.directionPathContinuity);
        expect(insight.isPatternClaim, isFalse);
        expect(insight.evidenceCount, 0);
        expect(insight.targetPlanId, PlanId.gentlerPacePath);
      },
    );

    test('no current-place fact for a Plan that has never been engaged', () {
      final insight = evaluateInsight(
        journal: [],
        plansState: _plansState(activePlanId: PlanId.moreEnergyPath),
        now: _now,
      );
      expect(insight, isNull);
    });
  });

  group('evaluateInsight — chosen pacing', () {
    test('requires an active Plan', () {
      // Deliberately below Family A's own pattern gate (only 2 records/2
      // dates) so this isolates "no active Plan" as the reason chosen
      // pacing itself is ineligible, rather than Family A pre-empting it.
      final journal = [
        for (final d in ['2026-08-20', '2026-09-05'])
          _entry(
            date: d,
            planId: PlanId.clearerHeadPath.name,
            treatmentUsed: PlanTreatment.lighter.name,
            treatmentSource: PlanTreatmentSource.directChoice.name,
          ),
      ];
      final insight = evaluateInsight(
        journal: journal,
        plansState: _plansState(),
        now: _now,
      );
      expect(insight, isNull);
    });

    test('exactly 5 direct lighter choices across 3 dates/14 days is eligible', () {
      final journal = [
        for (final d in ['2026-08-20', '2026-08-23', '2026-08-27', '2026-09-01', '2026-09-05'])
          _entry(
            date: d,
            planId: PlanId.clearerHeadPath.name,
            treatmentUsed: PlanTreatment.lighter.name,
            treatmentSource: PlanTreatmentSource.directChoice.name,
          ),
      ];
      final insight = evaluateInsight(
        journal: journal,
        plansState: _plansState(activePlanId: PlanId.clearerHeadPath),
        now: _now,
      );
      expect(insight, isNotNull);
      expect(insight!.family, InsightFamily.chosenPacing);
      expect(insight.evidenceCount, 5);
      expect(insight.targetPlanId, PlanId.clearerHeadPath);
      expect(insight.applicationType, InsightApplicationType.setLighterDefault);
    });

    test('fewer than 5 direct choices is not eligible', () {
      final journal = [
        for (final d in ['2026-08-20', '2026-08-23', '2026-08-27', '2026-09-01'])
          _entry(
            date: d,
            planId: PlanId.clearerHeadPath.name,
            treatmentUsed: PlanTreatment.lighter.name,
            treatmentSource: PlanTreatmentSource.directChoice.name,
          ),
      ];
      final insight = evaluateInsight(
        journal: journal,
        plansState: _plansState(activePlanId: PlanId.clearerHeadPath),
        now: _now,
      );
      expect(insight, isNull);
    });

    test(
      'automatic application of an already-saved default never counts as a '
      'fresh choice — load-bearing distinction between directChoice and '
      'savedPreference',
      () {
        final journal = [
          for (final d in ['2026-08-20', '2026-08-23', '2026-08-27', '2026-09-01', '2026-09-05'])
            _entry(
              date: d,
              planId: PlanId.clearerHeadPath.name,
              treatmentUsed: PlanTreatment.lighter.name,
              treatmentSource: PlanTreatmentSource.savedPreference.name,
            ),
        ];
        final insight = evaluateInsight(
          journal: journal,
          plansState: _plansState(activePlanId: PlanId.clearerHeadPath),
          now: _now,
        );
        expect(insight, isNull);
      },
    );

    test('never offered again once the lighter default is already active', () {
      final journal = [
        for (final d in ['2026-08-20', '2026-08-23', '2026-08-27', '2026-09-01', '2026-09-05'])
          _entry(
            date: d,
            planId: PlanId.clearerHeadPath.name,
            treatmentUsed: PlanTreatment.lighter.name,
            treatmentSource: PlanTreatmentSource.directChoice.name,
          ),
      ];
      final progress = _freshProgress(
        PlanId.clearerHeadPath,
      ).copyWith(lighterDefault: true);
      final insight = evaluateInsight(
        journal: journal,
        plansState: _plansState(
          activePlanId: PlanId.clearerHeadPath,
          overrides: {PlanId.clearerHeadPath: progress},
        ),
        now: _now,
      );
      expect(insight, isNull);
    });

    test(
      'a usefulness statement requires at least 3 relevant affirmative-'
      'attempt responses; below that the denominator stays null',
      () {
        final journal = [
          _entry(
            date: '2026-08-20',
            planId: PlanId.clearerHeadPath.name,
            treatmentUsed: PlanTreatment.lighter.name,
            treatmentSource: PlanTreatmentSource.directChoice.name,
            attemptResponse: CircleAttemptResponse.yes,
            usefulnessResponse: CircleUsefulnessResponse.veryUseful,
          ),
          _entry(
            date: '2026-08-23',
            planId: PlanId.clearerHeadPath.name,
            treatmentUsed: PlanTreatment.lighter.name,
            treatmentSource: PlanTreatmentSource.directChoice.name,
            attemptResponse: CircleAttemptResponse.notToday,
          ),
          _entry(
            date: '2026-08-27',
            planId: PlanId.clearerHeadPath.name,
            treatmentUsed: PlanTreatment.lighter.name,
            treatmentSource: PlanTreatmentSource.directChoice.name,
          ),
          _entry(
            date: '2026-09-01',
            planId: PlanId.clearerHeadPath.name,
            treatmentUsed: PlanTreatment.lighter.name,
            treatmentSource: PlanTreatmentSource.directChoice.name,
          ),
          _entry(
            date: '2026-09-05',
            planId: PlanId.clearerHeadPath.name,
            treatmentUsed: PlanTreatment.lighter.name,
            treatmentSource: PlanTreatmentSource.directChoice.name,
          ),
        ];
        final insight = evaluateInsight(
          journal: journal,
          plansState: _plansState(activePlanId: PlanId.clearerHeadPath),
          now: _now,
        );
        expect(insight, isNotNull);
        // Only 1 relevant (affirmative + rated) response — "Not today" is
        // never counted as a usefulness result, and a missing response
        // stays unknown.
        expect(insight!.usefulnessDenominator, isNull);
        expect(insight.usefulnessNumerator, isNull);
      },
    );

    test(
      'a usefulness statement with 3+ relevant responses reports a truthful '
      'numerator/denominator',
      () {
        final journal = [
          _entry(
            date: '2026-08-20',
            planId: PlanId.clearerHeadPath.name,
            treatmentUsed: PlanTreatment.lighter.name,
            treatmentSource: PlanTreatmentSource.directChoice.name,
            attemptResponse: CircleAttemptResponse.yes,
            usefulnessResponse: CircleUsefulnessResponse.veryUseful,
          ),
          _entry(
            date: '2026-08-23',
            planId: PlanId.clearerHeadPath.name,
            treatmentUsed: PlanTreatment.lighter.name,
            treatmentSource: PlanTreatmentSource.directChoice.name,
            attemptResponse: CircleAttemptResponse.aLittle,
            usefulnessResponse: CircleUsefulnessResponse.notUseful,
          ),
          _entry(
            date: '2026-08-27',
            planId: PlanId.clearerHeadPath.name,
            treatmentUsed: PlanTreatment.lighter.name,
            treatmentSource: PlanTreatmentSource.directChoice.name,
            attemptResponse: CircleAttemptResponse.yes,
            usefulnessResponse: CircleUsefulnessResponse.somewhatUseful,
          ),
          _entry(
            date: '2026-09-01',
            planId: PlanId.clearerHeadPath.name,
            treatmentUsed: PlanTreatment.lighter.name,
            treatmentSource: PlanTreatmentSource.directChoice.name,
          ),
          _entry(
            date: '2026-09-05',
            planId: PlanId.clearerHeadPath.name,
            treatmentUsed: PlanTreatment.lighter.name,
            treatmentSource: PlanTreatmentSource.directChoice.name,
          ),
        ];
        final insight = evaluateInsight(
          journal: journal,
          plansState: _plansState(activePlanId: PlanId.clearerHeadPath),
          now: _now,
        );
        expect(insight, isNotNull);
        expect(insight!.usefulnessDenominator, 3);
        expect(insight.usefulnessNumerator, 2);
      },
    );
  });

  group('evaluateInsight — deliberate revisits', () {
    test('accidental duplication (revisitUsed not true) is never counted', () {
      final journal = [
        for (final d in ['2026-08-20', '2026-08-23', '2026-08-27', '2026-09-01', '2026-09-05'])
          _entry(
            date: d,
            planId: PlanId.clearerHeadPath.name,
            stageId: 'clearer_head_1_establish',
            revisitUsed: false,
          ),
      ];
      final progress = _freshProgress(PlanId.clearerHeadPath).copyWith(
        lastEncounteredStageId: 'clearer_head_1_establish',
      );
      final insight = evaluateInsight(
        journal: journal,
        plansState: _plansState(
          activePlanId: PlanId.clearerHeadPath,
          overrides: {PlanId.clearerHeadPath: progress},
        ),
        now: _now,
      );
      expect(insight, isNull);
    });

    test('5 deliberate revisits of the current last-encountered stage is eligible', () {
      final journal = [
        for (final d in ['2026-08-20', '2026-08-23', '2026-08-27', '2026-09-01', '2026-09-05'])
          _entry(
            date: d,
            planId: PlanId.clearerHeadPath.name,
            stageId: 'clearer_head_1_establish',
            revisitUsed: true,
          ),
      ];
      final progress = _freshProgress(PlanId.clearerHeadPath).copyWith(
        lastEncounteredStageId: 'clearer_head_1_establish',
      );
      final insight = evaluateInsight(
        journal: journal,
        plansState: _plansState(
          activePlanId: PlanId.clearerHeadPath,
          overrides: {PlanId.clearerHeadPath: progress},
        ),
        now: _now,
      );
      expect(insight, isNotNull);
      expect(insight!.family, InsightFamily.deliberateRevisits);
      expect(insight.evidenceCount, 5);
      expect(insight.targetStageId, 'clearer_head_1_establish');
      expect(insight.applicationType, InsightApplicationType.queueRevisit);
    });

    test('revisits of a stage other than the current one do not count', () {
      final journal = [
        for (final d in ['2026-08-20', '2026-08-23', '2026-08-27', '2026-09-01', '2026-09-05'])
          _entry(
            date: d,
            planId: PlanId.clearerHeadPath.name,
            stageId: 'clearer_head_2_develop',
            revisitUsed: true,
          ),
      ];
      final progress = _freshProgress(PlanId.clearerHeadPath).copyWith(
        lastEncounteredStageId: 'clearer_head_1_establish',
      );
      final insight = evaluateInsight(
        journal: journal,
        plansState: _plansState(
          activePlanId: PlanId.clearerHeadPath,
          overrides: {PlanId.clearerHeadPath: progress},
        ),
        now: _now,
      );
      expect(insight, isNull);
    });

    test('never offered when a revisit is already queued', () {
      final journal = [
        for (final d in ['2026-08-20', '2026-08-23', '2026-08-27', '2026-09-01', '2026-09-05'])
          _entry(
            date: d,
            planId: PlanId.clearerHeadPath.name,
            stageId: 'clearer_head_1_establish',
            revisitUsed: true,
          ),
      ];
      final progress = _freshProgress(PlanId.clearerHeadPath).copyWith(
        lastEncounteredStageId: 'clearer_head_1_establish',
        pendingRevisit: true,
      );
      final insight = evaluateInsight(
        journal: journal,
        plansState: _plansState(
          activePlanId: PlanId.clearerHeadPath,
          overrides: {PlanId.clearerHeadPath: progress},
        ),
        now: _now,
      );
      expect(insight, isNull);
    });
  });

  group('evaluateInsight — evaluation window / staleness', () {
    test('records older than 28 days are excluded from the pattern gate', () {
      final journal = [
        for (final d in ['2026-07-01', '2026-07-04', '2026-07-08', '2026-07-12', '2026-07-16'])
          _entry(date: d, direction: Intention.clearerHead),
      ];
      final insight = evaluateInsight(
        journal: journal,
        plansState: _plansState(),
        now: _now,
      );
      expect(insight, isNull);
    });

    test('is deterministic for identical inputs', () {
      final journal = [
        for (final d in ['2026-08-20', '2026-08-23', '2026-08-27', '2026-09-01', '2026-09-05'])
          _entry(date: d, direction: Intention.clearerHead),
      ];
      final a = evaluateInsight(
        journal: journal,
        plansState: _plansState(),
        now: _now,
      );
      final b = evaluateInsight(
        journal: journal,
        plansState: _plansState(),
        now: _now,
      );
      expect(a!.family, b!.family);
      expect(a.targetPlanId, b.targetPlanId);
      expect(a.evidenceCount, b.evidenceCount);
    });
  });
}
