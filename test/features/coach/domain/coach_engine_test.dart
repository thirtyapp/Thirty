import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/features/coach/domain/coach_engine.dart';
import 'package:thirty/features/coach/domain/coach_family.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/plans/domain/plan_catalog.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/plans/domain/plan_state.dart';

final _plan = planDefinitionFor(PlanId.moreEnergyPath);
final _now = DateTime(2026, 8, 10, 9);

PlanProgress _progress({
  int forwardCursor = 0,
  PlanCycleStatus status = PlanCycleStatus.inProgress,
  bool pendingRevisit = false,
  String? lastEncounteredStageId,
}) {
  return PlanProgress(
    planId: PlanId.moreEnergyPath,
    contentVersion: planContentVersion,
    cycleId: 'more_energy_cycle_1',
    cycleStartedAt: DateTime(2026, 8, 1),
    forwardCursor: forwardCursor,
    status: status,
    pendingRevisit: pendingRevisit,
    lastEncounteredStageId: lastEncounteredStageId,
  );
}

void main() {
  group('selectCoachCue — ordinary stage explanation fallback', () {
    test('with no other eligible context, falls back to stage explanation', () {
      final cue = selectCoachCue(
        plan: _plan,
        progress: _progress(),
        todayStageId: _plan.stages[0].id,
        todayTreatment: PlanTreatment.standard,
        now: _now,
      );

      expect(cue, isNotNull);
      expect(cue!.family, CoachFamily.stageExplanation);
    });

    test('uses the upcoming stage when no today-specific context is given',
        () {
      final cue = selectCoachCue(
        plan: _plan,
        progress: _progress(forwardCursor: 2),
        now: _now,
      );

      expect(cue, isNotNull);
      expect(cue!.family, CoachFamily.stageExplanation);
    });

    test('returns null when no stage can be identified at all', () {
      final cue = selectCoachCue(
        plan: _plan,
        progress: _progress(forwardCursor: 5),
        now: _now,
      );

      // forwardCursor 5 with inProgress status (no lastEncounteredStageId
      // either) is a defensive/unreachable combination in real Plan state,
      // but the engine must still fail safe rather than crash or fabricate
      // a stage.
      expect(cue, isNull);
    });

    test('deterministic: identical inputs produce an identical result', () {
      final a = selectCoachCue(
        plan: _plan,
        progress: _progress(),
        todayStageId: _plan.stages[0].id,
        todayTreatment: PlanTreatment.standard,
        now: _now,
      );
      final b = selectCoachCue(
        plan: _plan,
        progress: _progress(),
        todayStageId: _plan.stages[0].id,
        todayTreatment: PlanTreatment.standard,
        now: _now,
      );

      expect(a!.family, b!.family);
      expect(a.message, b.message);
    });
  });

  group('selectCoachCue — priority 1: explicit treatment/revisit context', () {
    test('a revisit-sourced Session takes top priority', () {
      final cue = selectCoachCue(
        plan: _plan,
        progress: _progress(status: PlanCycleStatus.completed),
        todayStageId: _plan.stages[0].id,
        todayIsRevisit: true,
        lastEncounterAt: _now.subtract(const Duration(days: 30)),
        lastAttempt: CircleAttemptResponse.notToday,
        now: _now,
      );

      expect(cue!.family, CoachFamily.deliberateRevisit);
    });

    test('lighter treatment from a direct choice explains it as a choice,'
        ' not a saved default', () {
      final cue = selectCoachCue(
        plan: _plan,
        progress: _progress(),
        todayStageId: _plan.stages[0].id,
        todayTreatment: PlanTreatment.lighter,
        todayTreatmentSource: PlanTreatmentSource.directChoice,
        now: _now,
      );

      expect(cue!.family, CoachFamily.lighterPacing);
      expect(cue.message, contains('for today\'s session'));
    });

    test('lighter treatment from a saved default explains it as the default,'
        ' never as a new choice', () {
      final cue = selectCoachCue(
        plan: _plan,
        progress: _progress(),
        todayStageId: _plan.stages[0].id,
        todayTreatment: PlanTreatment.lighter,
        todayTreatmentSource: PlanTreatmentSource.savedPreference,
        now: _now,
      );

      expect(cue!.family, CoachFamily.lighterPacing);
      expect(cue.message, contains('saved default'));
    });

    test('treatment/revisit context outranks a completed cycle', () {
      final cue = selectCoachCue(
        plan: _plan,
        progress: _progress(status: PlanCycleStatus.completed),
        todayStageId: _plan.stages[0].id,
        todayTreatment: PlanTreatment.lighter,
        todayTreatmentSource: PlanTreatmentSource.directChoice,
        now: _now,
      );

      expect(cue!.family, CoachFamily.lighterPacing);
    });
  });

  group('selectCoachCue — priority 2: cycle transition', () {
    test('a completed cycle produces the cycle-transition cue', () {
      final cue = selectCoachCue(
        plan: _plan,
        progress: _progress(forwardCursor: 5, status: PlanCycleStatus.completed),
        now: _now,
      );

      expect(cue!.family, CoachFamily.cycleTransition);
      expect(cue.message, isNot(contains('improve')));
    });

    test('cycle transition outranks resumption and feedback', () {
      final cue = selectCoachCue(
        plan: _plan,
        progress: _progress(forwardCursor: 5, status: PlanCycleStatus.completed),
        lastEncounterAt: _now.subtract(const Duration(days: 30)),
        lastAttempt: CircleAttemptResponse.notToday,
        now: _now,
      );

      expect(cue!.family, CoachFamily.cycleTransition);
    });
  });

  group('selectCoachCue — priority 3: resumption after a qualifying gap', () {
    test('a gap under 7 days does not trigger resumption', () {
      final cue = selectCoachCue(
        plan: _plan,
        progress: _progress(forwardCursor: 1),
        todayStageId: _plan.stages[1].id,
        todayTreatment: PlanTreatment.standard,
        lastEncounterAt: _now.subtract(const Duration(days: 6)),
        now: _now,
      );

      expect(cue!.family, isNot(CoachFamily.resumption));
    });

    test('a gap of exactly 7 days triggers resumption', () {
      final cue = selectCoachCue(
        plan: _plan,
        progress: _progress(forwardCursor: 1),
        lastEncounterAt: _now.subtract(const Duration(days: 7)),
        now: _now,
      );

      expect(cue!.family, CoachFamily.resumption);
      expect(cue.message, isNot(contains('behind')));
      expect(cue.message, isNot(contains('missed')));
    });

    test('resumption never counts days or claims inactivity/health state', () {
      final cue = selectCoachCue(
        plan: _plan,
        progress: _progress(forwardCursor: 1),
        lastEncounterAt: _now.subtract(const Duration(days: 40)),
        now: _now,
      );

      expect(cue!.family, CoachFamily.resumption);
      expect(cue.message, isNot(matches(RegExp(r'\d+ days'))));
    });

    test('resumption outranks recent feedback', () {
      final cue = selectCoachCue(
        plan: _plan,
        progress: _progress(forwardCursor: 1),
        lastEncounterAt: _now.subtract(const Duration(days: 10)),
        lastAttempt: CircleAttemptResponse.notToday,
        now: _now,
      );

      expect(cue!.family, CoachFamily.resumption);
    });

    test('no last-encounter date means no resumption cue (falls through)', () {
      final cue = selectCoachCue(
        plan: _plan,
        progress: _progress(forwardCursor: 1),
        todayStageId: _plan.stages[1].id,
        todayTreatment: PlanTreatment.standard,
        now: _now,
      );

      expect(cue!.family, CoachFamily.stageExplanation);
    });
  });

  group('selectCoachCue — priority 4: recent explicit feedback', () {
    test('"not today" offers lighter treatment and a revisit, with no '
        'health/motivation inference', () {
      final cue = selectCoachCue(
        plan: _plan,
        progress: _progress(forwardCursor: 1),
        lastAttempt: CircleAttemptResponse.notToday,
        now: _now,
      );

      expect(cue!.family, CoachFamily.actionFeedback);
      expect(cue.offersLighterAction, isTrue);
      expect(cue.offersRevisitAction, isTrue);
      expect(cue.message, isNot(contains('tired')));
      expect(cue.message, isNot(contains('recover')));
    });

    test('"a little" offers lighter treatment only', () {
      final cue = selectCoachCue(
        plan: _plan,
        progress: _progress(forwardCursor: 1),
        lastAttempt: CircleAttemptResponse.aLittle,
        now: _now,
      );

      expect(cue!.family, CoachFamily.actionFeedback);
      expect(cue.offersLighterAction, isTrue);
      expect(cue.offersRevisitAction, isFalse);
    });

    test('a "not useful" usefulness report is acknowledged without offering '
        'controls or inferring a cause', () {
      final cue = selectCoachCue(
        plan: _plan,
        progress: _progress(forwardCursor: 1),
        lastUsefulness: CircleUsefulnessResponse.notUseful,
        now: _now,
      );

      expect(cue!.family, CoachFamily.actionFeedback);
      expect(cue.offersLighterAction, isFalse);
      expect(cue.offersRevisitAction, isFalse);
    });

    test('no answer at all (UNKNOWN) never triggers actionFeedback', () {
      final cue = selectCoachCue(
        plan: _plan,
        progress: _progress(forwardCursor: 1),
        todayStageId: _plan.stages[1].id,
        todayTreatment: PlanTreatment.standard,
        now: _now,
      );

      expect(cue!.family, isNot(CoachFamily.actionFeedback));
    });

    test('feedback never automatically holds progression — the cue only '
        'ever informs, the caller decides forwardCursor separately', () {
      final progress = _progress(forwardCursor: 1);
      final cue = selectCoachCue(
        plan: _plan,
        progress: progress,
        lastAttempt: CircleAttemptResponse.notToday,
        now: _now,
      );

      expect(cue, isNotNull);
      // The engine is pure — it never mutates progress or advances it.
      expect(progress.forwardCursor, 1);
    });
  });

  group('selectCoachCue — priority order with multiple eligible contexts', () {
    test('exactly one cue results even when several contexts are eligible',
        () {
      final cue = selectCoachCue(
        plan: _plan,
        progress: _progress(forwardCursor: 1),
        todayStageId: _plan.stages[1].id,
        todayTreatment: PlanTreatment.lighter,
        todayTreatmentSource: PlanTreatmentSource.directChoice,
        lastEncounterAt: _now.subtract(const Duration(days: 20)),
        lastAttempt: CircleAttemptResponse.notToday,
        now: _now,
      );

      // Only one cue is ever returned — priority 1 (lighter treatment)
      // wins over resumption and feedback.
      expect(cue!.family, CoachFamily.lighterPacing);
    });
  });
}
