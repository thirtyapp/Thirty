/// What the Plans pages say about a Plan (ADR-024 §4) — pure, from the
/// Plan's state, today's Circle and the journal. Nothing here changes a
/// Plan: every action is the Plan notifier's ([CirclePlansNotifier]).
library;

import '../../home/application/activity_catalog.dart';
import '../../home/application/circle_journal.dart';
import '../../home/application/recommendation_provider.dart';
import '../../home/domain/recommendation_engine.dart';
import '../../personal_circle/domain/circle_elements.dart';
import '../../personal_circle/domain/stage_brief.dart';
import '../domain/circle_plan.dart';
import '../domain/plan_copy.dart';
import '../domain/plan_stage_provenance.dart';

/// The one action a Plan's own card leads with.
enum PlanPrimary {
  startWithPremium,
  start,
  carryOn,
  continueWithPremium,
  goToToday,
  openToday,
  seeReview,
}

/// Today's Circle, as far as a Plan cares.
class PlanToday {
  const PlanToday({
    this.need,
    this.stage,
    this.kept = false,
    this.closed = false,
  });

  /// From today's recommendation.
  factory PlanToday.of(RecommendationState state) {
    final recommendation = state.recommendation;
    return PlanToday(
      need: recommendation?.intention,
      stage: recommendation?.composed?.stage,
      kept: recommendation?.composed?.isKept ?? false,
      closed: state.status == RecommendationStatus.closed,
    );
  }

  final Intention? need;
  final PlanStageProvenance? stage;
  final bool kept;
  final bool closed;
}

/// A Plan's status: where it stands and what comes next, in its own words.
class PlanStatusView {
  const PlanStatusView({
    required this.lines,
    required this.primary,
    this.heading,
    this.canPause = false,
    this.canLeave = false,
  });

  final String? heading;
  final List<String> lines;
  final PlanPrimary? primary;
  final bool canPause;
  final bool canLeave;
}

PlanStatusView planStatus(
  CirclePlanDefinition plan,
  CirclePlansState plans, {
  required bool premium,
  required PlanToday today,
  required String todayKey,
  required List<CircleJournalEntry> journal,
}) {
  final progress = plans.plans[plan.id];
  final lifecycle = plans.lifecycleOf(plan.id);
  final cycle = progress?.current;
  switch (lifecycle) {
    case PlanLifecycle.neverStarted:
    case PlanLifecycle.left:
      return PlanStatusView(
        lines: [PlanCopy.ready(plan.need)],
        primary: premium ? PlanPrimary.start : PlanPrimary.startWithPremium,
      );
    case PlanLifecycle.ended:
      return PlanStatusView(
        lines: [endLine(cycle!)],
        primary: cycle.hasReview ? PlanPrimary.seeReview : null,
      );
    case PlanLifecycle.paused:
      return PlanStatusView(
        heading: PlanCopy.stageHeading(
          cycle!.cursor,
          plan.stage(cycle.cursor).name,
        ),
        lines: [
          premium
              ? PlanCopy.paused(cycle.cursor)
              : PlanCopy.lapsed(cycle.cursor),
        ],
        primary: premium
            ? PlanPrimary.carryOn
            : PlanPrimary.continueWithPremium,
        canLeave: true,
      );
    case PlanLifecycle.active:
      if (!premium) {
        return PlanStatusView(
          heading: PlanCopy.stageHeading(
            cycle!.cursor,
            plan.stage(cycle.cursor).name,
          ),
          lines: [PlanCopy.lapsed(cycle.cursor)],
          primary: PlanPrimary.continueWithPremium,
          canLeave: true,
        );
      }
      final revisit = cycle!.pendingRevisit;
      final servedToday = today.stage?.planId == plan.id && !today.closed;
      final asideToday = [
        for (final r in cycle.records)
          if (r.outcome == StageOutcome.setAside && r.localDate == todayKey)
            setAsideLine(plan, r, journal),
      ];
      return PlanStatusView(
        heading: revisit != null
            ? PlanCopy.revisitPending(plan.stage(revisit).name)
            : PlanCopy.stageHeading(
                cycle.cursor,
                plan.stage(cycle.cursor).name,
              ),
        lines: [
          ...asideToday,
          if (servedToday)
            PlanCopy.today
          else if (today.need == plan.need &&
              !today.kept &&
              today.stage == null)
            PlanCopy.waitingFit
          else if (today.need != null && today.need != plan.need)
            PlanCopy.waitingOtherNeed(plan.need)
          else
            PlanCopy.next(plan.need),
        ],
        primary: servedToday ? PlanPrimary.openToday : PlanPrimary.goToToday,
        canPause: true,
        canLeave: true,
      );
  }
}

/// How a cycle that is over reads at its top.
String endLine(PlanCycle cycle) => switch (cycle.end) {
  CycleEnd.allSetAside => PlanCopy.allSetAside,
  CycleEnd.allRejected => PlanCopy.allRejected,
  CycleEnd.historyDeleted || null => PlanCopy.endedWithoutRecord,
  _ => PlanCopy.reachedEnd(cycle.guidedStages, cycle.setAsideStages),
};

/// Why [record] was set aside, naming the part it was built around.
String setAsideLine(
  CirclePlanDefinition plan,
  StageRecord record,
  List<CircleJournalEntry> journal,
) {
  final blocks = record.setAsideBecause;
  if (blocks.isEmpty) return PlanCopy.setAside;
  final block = blocks.firstWhere(
    (b) => b.role == ElementRole.main || b.role == ElementRole.second,
    orElse: () => blocks.first,
  );
  final part = elementOf(block.element).name;
  return switch (block.reason) {
    StageBlockReason.leftOut => PlanCopy.setAsideLeftOut(part),
    StageBlockReason.notSuggested => PlanCopy.setAsideNotSuggested(part),
    StageBlockReason.resting => PlanCopy.setAsideResting(
      part,
      _restingSince(plan, block.element, record.localDate, journal),
    ),
  };
}

/// The day the user said a single-activity Circle of [element]'s activity
/// wasn't useful for this Plan's need — the answer that rests it.
String? _restingSince(
  CirclePlanDefinition plan,
  ElementId element,
  String onOrBefore,
  List<CircleJournalEntry> journal,
) {
  final activity = elementOf(element).from;
  if (activity == null) return null;
  for (final entry in journal.reversed) {
    if (entry.localDate.compareTo(onOrBefore) > 0) continue;
    if (entry.activityId == activity &&
        entry.direction == plan.need &&
        entry.usefulnessResponse == CircleUsefulnessResponse.notUseful &&
        (entry.session?.parts.isEmpty ?? true)) {
      return planShortDate(entry.localDate);
    }
  }
  return null;
}

/// One stage in the arc: its name, what it is, and where it stands —
/// "Guided 12 Oct", "Set aside", "Next", "Again next time", or nothing yet.
class StageRowView {
  const StageRowView({
    required this.stage,
    required this.line,
    required this.status,
    this.reason,
    this.canRevisit = false,
  });

  final PlanStage stage;
  final String line;
  final List<String> status;
  final String? reason;
  final bool canRevisit;

  /// What TalkBack reads: the same words, never "complete".
  String get semantics => [
    'Stage ${stage.number}, ${stage.name}',
    ...status,
    line,
    ?reason,
  ].join('. ');
}

List<StageRowView> stageRows(
  CirclePlanDefinition plan,
  CirclePlansState plans, {
  required bool premium,
  required List<CircleJournalEntry> journal,
}) {
  final progress = plans.plans[plan.id];
  final cycle = progress?.current;
  final running =
      progress != null &&
      !cycle!.isOver &&
      (progress.lifecycle == PlanLifecycle.active ||
          progress.lifecycle == PlanLifecycle.paused);
  return [
    for (final stage in plan.stages)
      () {
        final record = running || progress?.lifecycle == PlanLifecycle.ended
            ? cycle?.latest(stage.number)
            : null;
        return StageRowView(
          stage: stage,
          line: stage.number < 5
              ? PlanCopy.todayLine[stage.id]!
              : PlanCopy.stageFiveMix,
          status: [
            if (record?.outcome == StageOutcome.guided)
              PlanCopy.guidedOn(planShortDate(record!.localDate)),
            if (record?.outcome == StageOutcome.setAside) PlanCopy.setAside,
            if (running && cycle.pendingRevisit == stage.number)
              PlanCopy.againNext
            else if (running &&
                cycle.cursor == stage.number &&
                cycle.pendingRevisit == null)
              PlanCopy.nextStage,
          ],
          reason: record?.outcome == StageOutcome.setAside
              ? setAsideLine(plan, record!, journal)
              : null,
          canRevisit:
              premium &&
              running &&
              plans.requestRevisit(plan.id, stage.number) != null,
        );
      }(),
  ];
}

/// The review of [cycle] (C7): only what the user said and what was
/// recorded — never an outcome.
class ReviewView {
  const ReviewView({
    required this.endLine,
    required this.summary,
    required this.facts,
    required this.compared,
    required this.keepable,
    required this.caseD,
  });

  final String endLine;
  final List<String> summary;
  final List<StageFacts> facts;
  final List<String> compared;

  /// The guided stage Circles with their parts — what "Keep one of these
  /// Circles" may offer.
  final List<StageRecord> keepable;

  /// Every stage rejected: no last Circle, fewer options (§7 D).
  final bool caseD;
}

ReviewView? reviewOf(
  CirclePlanDefinition plan,
  PlanProgress progress,
  StageAnswers answers,
) {
  final cycle = progress.current;
  if (!cycle.hasReview) return null;
  final facts = [
    for (final f in cycleFacts(plan, cycle, answers))
      if (f.record != null) f,
  ];
  final guided = [
    for (final f in facts)
      if (f.record!.outcome == StageOutcome.guided) f,
  ];
  final positive = [
    for (final f in guided)
      if (f.answer == PastUsefulness.veryUseful ||
          f.answer == PastUsefulness.somewhatUseful)
        f.stage.name,
  ];
  final rejected = [
    for (final f in guided)
      if (f.answer == PastUsefulness.notUseful) f.stage.name,
  ];
  final unanswered = guided.where((f) => f.answer == null).length;
  final caseD = cycle.end == CycleEnd.allRejected;
  final summary = caseD
      ? <String>[]
      : cycle.end == CycleEnd.allSetAside
      ? <String>[]
      : positive.isEmpty && rejected.isEmpty
      ? [PlanCopy.noAnswers]
      : positive.length >= 2
      ? [PlanCopy.severalPositive(positive)]
      : [
          if (positive.length == 1) PlanCopy.onePositive(positive.single),
          if (unanswered > 0 && positive.length == 1) PlanCopy.othersUnanswered,
          for (final stage in rejected) PlanCopy.wasNot(stage),
        ];
  // Against the cycle before, only where the user answered both times.
  final compared = <String>[];
  final index = progress.cycles.length - 1;
  if (index > 0) {
    final previous = cycleFacts(plan, progress.cycles[index - 1], answers);
    for (final now in guided) {
      final then = previous.firstWhere(
        (p) => p.stage.number == now.stage.number,
      );
      final a = then.answer;
      final b = now.answer;
      if (then.record?.outcome != StageOutcome.guided ||
          a == null ||
          b == null) {
        continue;
      }
      compared.add(
        a == b
            ? PlanCopy.bothTimes(now.stage.name, b)
            : PlanCopy.lastTimeThisTime(now.stage.name, a, b),
      );
    }
  }
  return ReviewView(
    endLine: cycle.end == CycleEnd.left
        ? PlanCopy.left(cycle.guidedStages, cycle.setAsideStages)
        : endLine(cycle),
    summary: summary,
    facts: facts,
    compared: compared,
    keepable: [
      for (final f in guided)
        if (f.record!.parts.isNotEmpty && f.record!.circleId != null) f.record!,
    ],
    caseD: caseD,
  );
}

/// One stage as the review states it: date, parts, skipped parts, and the
/// user's answer — or "No answer", or why it was set aside.
String reviewFactLine(
  CirclePlanDefinition plan,
  StageFacts facts,
  List<CircleJournalEntry> journal,
) {
  final record = facts.record!;
  if (record.outcome == StageOutcome.setAside) {
    return setAsideLine(plan, record, journal);
  }
  final parts = [
    for (final wire in record.parts)
      ?CirclePart.fromWire(wire)?.definition.name,
  ];
  final skipped = [
    for (final wire in record.skipped)
      if (ElementId.values.asNameMap()[wire] case final id?) elementOf(id).name,
  ];
  return [
    planShortDate(record.localDate),
    if (parts.isNotEmpty) parts.join(' · '),
    if (skipped.isNotEmpty) PlanCopy.skipped(skipped),
    if (facts.answer != null)
      PlanCopy.youSaid(facts.answer!)
    else
      PlanCopy.answer(null),
  ].join(' — ');
}
