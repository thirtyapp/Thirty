/// THIRTY's minimum Circle Coach decision policy — Batch 2B
/// (`docs/product/adr/ADR-015-v1-batch-2b-circle-coach.md`,
/// `RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md` §7).
///
/// [selectCoachCue] is a pure, deterministic function: the same inputs
/// always produce the same [CoachCue] — no randomness, no clock reads
/// beyond the explicit [now] parameter, no runtime AI. It never mutates
/// any state and never itself decides today's [ActivityId] — it only ever
/// explains or exposes controls over how an already-resolved or
/// already-permitted Session is approached.
library;

import '../../home/application/circle_journal.dart'
    show CircleAttemptResponse, CircleUsefulnessResponse;
import '../../plans/domain/plan_catalog.dart';
import '../../plans/domain/plan_ids.dart';
import '../../plans/domain/plan_state.dart';
import 'coach_cue.dart';
import 'coach_family.dart';

/// Selects at most one [CoachCue] for [plan]/[progress], following the
/// frozen architecture's exact bounded priority order (§7):
///
/// 1. current explicit treatment/revisit context ([CoachFamily.deliberateRevisit]
///    or [CoachFamily.lighterPacing])
/// 2. cycle transition ([CoachFamily.cycleTransition])
/// 3. resumption after a qualifying gap ([CoachFamily.resumption])
/// 4. relevant recent explicit feedback ([CoachFamily.actionFeedback])
/// 5. ordinary stage explanation ([CoachFamily.stageExplanation])
///
/// Returns `null` only when no stage can be identified at all (an
/// unresolvable/stale [todayStageId] with the current catalogue) — Coach
/// always fails back to the ordinary stage explanation rather than showing
/// nothing, as long as a real stage exists to explain.
///
/// [todayStageId]/[todayTreatment]/[todayIsRevisit] describe *today's*
/// Plan-resolved Session, when one exists — pass `null`/`null`/`false` when
/// viewing this Plan outside of a resolved Session (e.g. the "Your path"
/// surface before today's Circle is chosen); [selectCoachCue] then falls
/// through to cycle/resumption/feedback/upcoming-stage reasoning using
/// [progress] alone.
///
/// [lastAttempt]/[lastUsefulness]/[lastEncounterAt] describe the most
/// recent *prior* (never today's own) matching Plan Circle's journal
/// record — `null` for any of these means UNKNOWN, never a negative or an
/// inferred non-action (§8, "no-feedback behavior").
CoachCue? selectCoachCue({
  required PlanDefinition plan,
  required PlanProgress progress,
  StageId? todayStageId,
  PlanTreatment? todayTreatment,
  PlanTreatmentSource? todayTreatmentSource,
  bool todayIsRevisit = false,
  CircleAttemptResponse? lastAttempt,
  CircleUsefulnessResponse? lastUsefulness,
  DateTime? lastEncounterAt,
  required DateTime now,
}) {
  // Priority 1: current explicit treatment/revisit context.
  if (todayIsRevisit) {
    return const CoachCue(
      family: CoachFamily.deliberateRevisit,
      message:
          'This is a deliberate revisit of a stage you\'ve already been '
          'through — not a mistake or a reset. Your forward progress in '
          'this Plan is preserved, and you\'ll continue from where you '
          'left off after this.',
    );
  }
  if (todayTreatment == PlanTreatment.lighter) {
    final isSavedDefault =
        todayTreatmentSource == PlanTreatmentSource.savedPreference;
    return CoachCue(
      family: CoachFamily.lighterPacing,
      message: isSavedDefault
          ? 'You\'re using lighter guidance today because that\'s your '
                'saved default for ${plan.name}. You can still choose '
                'standard for just today with the buttons below, without '
                'changing that default.'
          : 'You\'re using lighter guidance for today\'s session. If this '
                'suits you, you can save it as ${plan.name}\'s default '
                'below.',
    );
  }

  // Priority 2: cycle transition.
  if (progress.status == PlanCycleStatus.completed) {
    return CoachCue(
      family: CoachFamily.cycleTransition,
      message:
          'This guided cycle of ${plan.name} is finished. You can repeat '
          'it, or choose another direction whenever you\'re ready — '
          'nothing else happens automatically.',
    );
  }

  // Priority 3: resumption after a qualifying gap (a display rule only —
  // never a claim about fitness, health, or being "behind").
  if (lastEncounterAt != null) {
    final gapDays = _calendarDayGap(lastEncounterAt, now);
    if (gapDays >= 7) {
      return CoachCue(
        family: CoachFamily.resumption,
        message:
            'Welcome back to ${plan.name}. You\'re saved at stage '
            '${progress.forwardCursor + 1} of ${plan.stages.length} — '
            'continue whenever you\'re ready.',
      );
    }
  }

  // Priority 4: relevant recent explicit feedback. "Not today" means only
  // a reported non-action; "a little" means only a partial reported
  // attempt — neither is treated as motivation, exhaustion, or a need for
  // recovery (§8).
  if (lastAttempt == CircleAttemptResponse.notToday) {
    return const CoachCue(
      family: CoachFamily.actionFeedback,
      message:
          'You reported not getting to the last stage — that\'s fine, no '
          'explanation needed. A lighter version of it is available today, '
          'or you can queue a one-off revisit of that stage.',
      offersLighterAction: true,
      offersRevisitAction: true,
    );
  }
  if (lastAttempt == CircleAttemptResponse.aLittle) {
    return const CoachCue(
      family: CoachFamily.actionFeedback,
      message:
          'You reported only partly trying the last stage. Lighter '
          'guidance is available today if that helps.',
      offersLighterAction: true,
    );
  }
  if (lastUsefulness == CircleUsefulnessResponse.notUseful) {
    return const CoachCue(
      family: CoachFamily.actionFeedback,
      message:
          'You reported the last stage wasn\'t useful. That\'s noted — '
          'there\'s nothing else you need to do differently.',
    );
  }

  // Priority 5: ordinary stage explanation — the fallback when no stronger
  // contextual cue applies.
  final stageId = todayStageId ??
      (progress.forwardCursor <= 4
          ? plan.stages[progress.forwardCursor].id
          : progress.lastEncounteredStageId);
  if (stageId == null) return null;
  final stage = findStage(plan.id, stageId);
  if (stage == null) return null;

  return CoachCue(
    family: CoachFamily.stageExplanation,
    message:
        'This is part of your path — one of the ${plan.stages.length} '
        'stages that make up ${plan.name}.',
  );
}

/// The local-calendar-day gap between [from] and [to] — never a raw
/// [Duration] difference, so a same-day difference is always `0`
/// regardless of the specific times of day involved (frozen architecture
/// §7: "seven is a display rule only").
int _calendarDayGap(DateTime from, DateTime to) {
  final fromDate = DateTime(from.year, from.month, from.day);
  final toDate = DateTime(to.year, to.month, to.day);
  return toDate.difference(fromDate).inDays;
}
