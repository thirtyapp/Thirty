/// Circle Plans (ADR-024 §4–§7, B3): "Where am I going over several
/// Circles, and what is the right next step?"
///
/// A Plan is five stages counted in Circles on days the user chooses its
/// need — never in calendar days, never a streak, never a playlist. Each
/// stage is a B2 [StageBrief] on the ordinary composer; this file holds the
/// three launch Plans, what is kept about a user's place in them, and the
/// pure rules that move it. It infers nothing: a stage is *guided* when its
/// Circle was started and later closed in THIRTY — never "done".
library;

import '../../home/application/activity_catalog.dart';
import '../../home/domain/recommendation_engine.dart';
import '../../home/domain/recommendation_policy.dart';
import '../../personal_circle/domain/circle_composer.dart';
import '../../personal_circle/domain/circle_elements.dart';
import '../../personal_circle/domain/composer_policy.dart';
import '../../personal_circle/domain/stage_brief.dart';
import 'plan_stage_provenance.dart';

// ---------------------------------------------------------------------------
// The three launch Plans (ADR-024 §4).

/// A stage's role in its Plan's arc.
enum StageRole {
  begin,
  develop,
  apply,
  applyInNewSetting,
  protect,
  consolidate,
}

/// One of a Plan's five stages.
class PlanStage {
  const PlanStage(this.number, this.id, this.name, this.role);

  /// 1–5.
  final int number;

  /// Its StageBrief id, e.g. `getting_going.1`.
  final String id;
  final String name;
  final StageRole role;
}

/// One launch Plan.
class CirclePlanDefinition {
  const CirclePlanDefinition(this.id, this.name, this.need, this.stages);

  final String id;
  final String name;
  final Intention need;
  final List<PlanStage> stages;

  PlanStage stage(int number) => stages[number - 1];

  /// Stages 1–4's fixed brief — stage 5's is derived ([stageFive]).
  StageBrief? briefFor(int number) =>
      number < 5 ? stageBriefById[stage(number).id] : null;
}

const List<CirclePlanDefinition> launchCirclePlans = [
  CirclePlanDefinition('getting_going', 'Getting going', Intention.moreEnergy, [
    PlanStage(1, 'getting_going.1', 'Loosen up', StageRole.begin),
    PlanStage(2, 'getting_going.2', 'On your feet', StageRole.develop),
    PlanStage(3, 'getting_going.3', 'Two together', StageRole.apply),
    PlanStage(4, 'getting_going.4', 'Fresh air', StageRole.applyInNewSetting),
    PlanStage(5, 'getting_going.5', 'Your mix', StageRole.consolidate),
  ]),
  CirclePlanDefinition('making_room', 'Making room', Intention.clearerHead, [
    PlanStage(1, 'making_room.1', 'Out of your head', StageRole.begin),
    PlanStage(2, 'making_room.2', 'Room around you', StageRole.develop),
    PlanStage(3, 'making_room.3', 'Down to one', StageRole.apply),
    PlanStage(4, 'making_room.4', 'Less coming in', StageRole.protect),
    PlanStage(5, 'making_room.5', 'Your way', StageRole.consolidate),
  ]),
  CirclePlanDefinition('slowing_down', 'Slowing down', Intention.gentlerPace, [
    PlanStage(1, 'slowing_down.1', 'Slow hands', StageRole.begin),
    PlanStage(2, 'slowing_down.2', 'Ease the body', StageRole.develop),
    PlanStage(3, 'slowing_down.3', 'Something quiet', StageRole.apply),
    PlanStage(
      4,
      'slowing_down.4',
      'Somewhere slower',
      StageRole.applyInNewSetting,
    ),
    PlanStage(5, 'slowing_down.5', 'Your pace', StageRole.consolidate),
  ]),
];

final Map<String, CirclePlanDefinition> circlePlanById = {
  for (final plan in launchCirclePlans) plan.id: plan,
};

// ---------------------------------------------------------------------------
// What is kept about a user's place in a Plan.

/// Where a Plan stands for this user. "Never started" is the absence of a
/// [PlanProgress].
enum PlanLifecycle { neverStarted, active, paused, ended, left }

/// What happened to one stage in a cycle — never "completed".
enum StageOutcome { guided, setAside }

/// How a cycle ended.
enum CycleEnd {
  /// Stage 5 was guided or set aside.
  reachedEnd,

  /// Case D: every earlier stage was "Not useful" — no last Circle.
  allRejected,

  /// Every earlier stage was set aside.
  allSetAside,

  /// The user left the Plan.
  left,

  /// The cycle ended, and why is no longer known: Circle history was
  /// deleted, and with it the evidence the end came from.
  historyDeleted,
}

/// One stage's record in a cycle: the facts, never an inference.
class StageRecord {
  const StageRecord({
    required this.stageNumber,
    required this.outcome,
    required this.localDate,
    this.circleId,
    this.parts = const [],
    this.skipped = const [],
    this.drawsOn = const [],
    this.revisit = false,
    this.setAsideBecause = const [],
  });

  final int stageNumber;
  final StageOutcome outcome;

  /// The day it was guided or set aside (`YYYY-MM-DD`).
  final String localDate;

  /// The stage Circle, when guided. Its answer, if the user gave one, is
  /// the journal's (read by [stageAnswers]), so "Remove this answer" and
  /// Delete history leave nothing behind here.
  final String? circleId;

  /// The parts shown and skipped (wire form), when guided.
  final List<String> parts;
  final List<String> skipped;

  /// Stage 5: the earlier stages its Circle combined.
  final List<String> drawsOn;

  /// Guided as "This stage again next time".
  final bool revisit;

  /// Set aside: the user's own controls on a Circle that would have passed
  /// — `leftOut`, `notSuggested` or `resting`, with the part.
  final List<StageBlock> setAsideBecause;

  Map<String, Object?> toJson() => {
    'stageNumber': stageNumber,
    'outcome': outcome.name,
    'localDate': localDate,
    'circleId': ?circleId,
    if (parts.isNotEmpty) 'parts': parts,
    if (skipped.isNotEmpty) 'skipped': skipped,
    if (drawsOn.isNotEmpty) 'drawsOn': drawsOn,
    if (revisit) 'revisit': true,
    if (setAsideBecause.isNotEmpty)
      'setAsideBecause': [
        for (final b in setAsideBecause)
          {
            'element': b.element.name,
            'role': b.role.name,
            'reason': b.reason.name,
          },
      ],
  };

  static StageRecord? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final number = raw['stageNumber'];
    final outcome = StageOutcome.values.asNameMap()[raw['outcome']];
    final date = raw['localDate'];
    if (number is! int || number < 1 || number > 5) return null;
    if (outcome == null || date is! String) return null;
    final circleId = raw['circleId'];
    return StageRecord(
      stageNumber: number,
      outcome: outcome,
      localDate: date,
      circleId: circleId is String ? circleId : null,
      parts: _strings(raw['parts']),
      skipped: _strings(raw['skipped']),
      drawsOn: _strings(raw['drawsOn']),
      revisit: raw['revisit'] == true,
      setAsideBecause: [
        if (raw['setAsideBecause'] case final List list)
          for (final b in list)
            if (b case {
              'element': final String e,
              'role': final String r,
              'reason': final String why,
            })
              if ((
                    ElementId.values.asNameMap()[e],
                    ElementRole.values.asNameMap()[r],
                    StageBlockReason.values.asNameMap()[why],
                  )
                  case (final element?, final role?, final reason?))
                StageBlock(element, role, reason),
      ],
    );
  }
}

List<String> _strings(Object? raw) => [
  if (raw case final List list)
    for (final item in list)
      if (item is String) item,
];

/// One pass through a Plan's five stages.
class PlanCycle {
  const PlanCycle({
    required this.id,
    required this.number,
    required this.startedOn,
    this.cursor = 1,
    this.pendingRevisit,
    this.revisitsUsed = const {},
    this.records = const [],
    this.endedOn,
    this.end,
    this.gentlerSince,
  });

  /// e.g. `getting_going#2`.
  final String id;
  final int number;
  final String startedOn;

  /// The Plan's place: the next stage, 1–5.
  final int cursor;

  /// "This stage again next time", waiting for the next matching day.
  final int? pendingRevisit;

  /// The stages revisited (or asked to be) this cycle — once each.
  final Set<int> revisitsUsed;

  final List<StageRecord> records;
  final String? endedOn;
  final CycleEnd? end;

  /// ADR-024 I2: the day the user chose "Keep this Plan's Circles gentler
  /// for now" for this cycle, or `null`. A setting of this cycle only, so it
  /// ends with it; the user may turn it off.
  final String? gentlerSince;

  bool get isOver => end != null;

  bool get isGentler => gentlerSince != null;

  int get guidedStages => {
    for (final r in records)
      if (r.outcome == StageOutcome.guided) r.stageNumber,
  }.length;

  int get setAsideStages =>
      {
        for (final r in records)
          if (r.outcome == StageOutcome.setAside) r.stageNumber,
      }.difference({
        for (final r in records)
          if (r.outcome == StageOutcome.guided) r.stageNumber,
      }).length;

  /// Whether this cycle has a review for B4 to show: every end does, and a
  /// Plan that was left only with at least three stages guided — never one
  /// whose evidence was deleted.
  bool get hasReview =>
      end != null &&
      end != CycleEnd.historyDeleted &&
      (end != CycleEnd.left || guidedStages >= 3);

  /// This cycle without its stage evidence (Delete history): its identity,
  /// place, revisits and whether it is over stay; its records, and why and
  /// when it ended, go — unless the user left it, which is their own act.
  /// A gentler setting is the user's Plan setting, and stays.
  PlanCycle withoutEvidence() => PlanCycle(
    id: id,
    number: number,
    startedOn: startedOn,
    cursor: cursor,
    pendingRevisit: pendingRevisit,
    revisitsUsed: revisitsUsed,
    endedOn: end == CycleEnd.left ? endedOn : null,
    end: switch (end) {
      null => null,
      CycleEnd.left => CycleEnd.left,
      _ => CycleEnd.historyDeleted,
    },
    gentlerSince: gentlerSince,
  );

  /// The latest record of [stageNumber], if any.
  StageRecord? latest(int stageNumber) {
    for (final r in records.reversed) {
      if (r.stageNumber == stageNumber) return r;
    }
    return null;
  }

  PlanCycle copyWith({
    int? cursor,
    int? pendingRevisit,
    bool clearRevisit = false,
    Set<int>? revisitsUsed,
    List<StageRecord>? records,
    String? endedOn,
    CycleEnd? end,
    String? gentlerSince,
    bool clearGentler = false,
  }) => PlanCycle(
    id: id,
    number: number,
    startedOn: startedOn,
    cursor: cursor ?? this.cursor,
    pendingRevisit: clearRevisit
        ? null
        : (pendingRevisit ?? this.pendingRevisit),
    revisitsUsed: revisitsUsed ?? this.revisitsUsed,
    records: records ?? this.records,
    endedOn: endedOn ?? this.endedOn,
    end: end ?? this.end,
    gentlerSince: clearGentler ? null : (gentlerSince ?? this.gentlerSince),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'number': number,
    'startedOn': startedOn,
    'cursor': cursor,
    'pendingRevisit': ?pendingRevisit,
    if (revisitsUsed.isNotEmpty) 'revisitsUsed': [...revisitsUsed]..sort(),
    'records': [for (final r in records) r.toJson()],
    'endedOn': ?endedOn,
    'end': ?end?.name,
    'gentlerSince': ?gentlerSince,
  };

  static PlanCycle? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final id = raw['id'];
    final number = raw['number'];
    final startedOn = raw['startedOn'];
    final cursor = raw['cursor'];
    if (id is! String || number is! int || startedOn is! String) return null;
    if (cursor is! int || cursor < 1 || cursor > 5) return null;
    final revisit = raw['pendingRevisit'];
    final endedOn = raw['endedOn'];
    final gentlerSince = raw['gentlerSince'];
    return PlanCycle(
      id: id,
      number: number,
      startedOn: startedOn,
      cursor: cursor,
      pendingRevisit: revisit is int && revisit >= 1 && revisit < cursor
          ? revisit
          : null,
      revisitsUsed: {
        if (raw['revisitsUsed'] case final List list)
          for (final n in list)
            if (n is int) n,
      },
      records: [
        if (raw['records'] case final List list)
          for (final r in list) ?StageRecord.fromJson(r),
      ],
      endedOn: endedOn is String ? endedOn : null,
      end: CycleEnd.values.asNameMap()[raw['end']],
      gentlerSince: gentlerSince is String ? gentlerSince : null,
    );
  }
}

/// A user's place in one Plan: its cycles, oldest first, the last current.
class PlanProgress {
  const PlanProgress({
    required this.planId,
    required this.lifecycle,
    required this.cycles,
    this.lastAdvancedCircleId,
  });

  final String planId;
  final PlanLifecycle lifecycle;
  final List<PlanCycle> cycles;

  /// The last stage Circle that moved this Plan on — a Circle moves it
  /// once, however often it is closed or the app restarts.
  final String? lastAdvancedCircleId;

  PlanCycle get current => cycles.last;
  CirclePlanDefinition get definition => circlePlanById[planId]!;

  PlanProgress copyWith({
    PlanLifecycle? lifecycle,
    List<PlanCycle>? cycles,
    String? lastAdvancedCircleId,
  }) => PlanProgress(
    planId: planId,
    lifecycle: lifecycle ?? this.lifecycle,
    cycles: cycles ?? this.cycles,
    lastAdvancedCircleId: lastAdvancedCircleId ?? this.lastAdvancedCircleId,
  );

  /// With the current cycle replaced.
  PlanProgress withCurrent(PlanCycle cycle) =>
      copyWith(cycles: [...cycles.take(cycles.length - 1), cycle]);

  Map<String, Object?> toJson() => {
    'lifecycle': lifecycle.name,
    'cycles': [for (final c in cycles) c.toJson()],
    'lastAdvancedCircleId': ?lastAdvancedCircleId,
  };

  static PlanProgress? fromJson(String planId, Object? raw) {
    if (!circlePlanById.containsKey(planId)) return null;
    if (raw is! Map<String, Object?>) return null;
    final lifecycle = PlanLifecycle.values.asNameMap()[raw['lifecycle']];
    if (lifecycle == null || lifecycle == PlanLifecycle.neverStarted) {
      return null;
    }
    final cycles = [
      if (raw['cycles'] case final List list)
        for (final c in list) ?PlanCycle.fromJson(c),
    ];
    if (cycles.isEmpty) return null;
    final last = raw['lastAdvancedCircleId'];
    return PlanProgress(
      planId: planId,
      lifecycle: lifecycle,
      cycles: cycles,
      lastAdvancedCircleId: last is String ? last : null,
    );
  }
}

/// Every Plan the user has started, and the one active — at most one.
class CirclePlansState {
  const CirclePlansState({this.activePlanId, this.plans = const {}});

  static const empty = CirclePlansState();

  final String? activePlanId;
  final Map<String, PlanProgress> plans;

  PlanProgress? get active => activePlanId == null ? null : plans[activePlanId];

  PlanLifecycle lifecycleOf(String planId) =>
      plans[planId]?.lifecycle ?? PlanLifecycle.neverStarted;

  CirclePlansState _with(PlanProgress plan, {String? activePlanId}) =>
      CirclePlansState(
        activePlanId: activePlanId,
        plans: {...plans, plan.planId: plan},
      );

  Map<String, Object?> toJson() => {
    'schemaVersion': circlePlansSchemaVersion,
    'activePlanId': ?activePlanId,
    'plans': {for (final e in plans.entries) e.key: e.value.toJson()},
  };

  /// `null` when [raw] isn't a readable record. Unknown Plans are dropped;
  /// an active id must name an active Plan.
  static CirclePlansState? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    if (raw['schemaVersion'] != circlePlansSchemaVersion) return null;
    final rawPlans = raw['plans'];
    if (rawPlans is! Map<String, Object?>) return null;
    final plans = <String, PlanProgress>{
      for (final e in rawPlans.entries)
        e.key: ?PlanProgress.fromJson(e.key, e.value),
    };
    final active = raw['activePlanId'];
    return CirclePlansState(
      activePlanId:
          active is String && plans[active]?.lifecycle == PlanLifecycle.active
          ? active
          : null,
      plans: plans,
    );
  }
}

const circlePlansSchemaVersion = 1;

// ---------------------------------------------------------------------------
// The user's actions (§6). Each returns the new state, or `null` when it
// doesn't apply — never a partial change. Premium is the caller's check.

extension CirclePlanActions on CirclePlansState {
  /// The current active Plan, paused at its place — for starting another.
  Map<String, PlanProgress> _pausingActive(String except) => {
    for (final e in plans.entries)
      e.key: e.key != except && e.value.lifecycle == PlanLifecycle.active
          ? e.value.copyWith(lifecycle: PlanLifecycle.paused)
          : e.value,
  };

  CirclePlansState _activate(PlanProgress plan) => CirclePlansState(
    activePlanId: plan.planId,
    plans: {..._pausingActive(plan.planId), plan.planId: plan},
  );

  PlanProgress _newCycle(PlanProgress? plan, String planId, String today) {
    final number = (plan?.cycles.length ?? 0) + 1;
    final cycle = PlanCycle(
      id: '$planId#$number',
      number: number,
      startedOn: today,
    );
    return PlanProgress(
      planId: planId,
      lifecycle: PlanLifecycle.active,
      cycles: [...?plan?.cycles, cycle],
      lastAdvancedCircleId: plan?.lastAdvancedCircleId,
    );
  }

  /// Start [planId]: a paused Plan carries on at its place; one never
  /// started, left or ended begins a new cycle at stage 1. Any other active
  /// Plan is paused at its place. Nothing is composed or recorded.
  CirclePlansState? start(String planId, {required String today}) {
    if (!circlePlanById.containsKey(planId)) return null;
    final plan = plans[planId];
    return switch (plan?.lifecycle) {
      PlanLifecycle.active => null,
      PlanLifecycle.paused => resume(planId),
      _ => _activate(_newCycle(plan, planId, today)),
    };
  }

  /// Pause the active [planId]: steering stops; its place, revisit and
  /// records are kept exactly.
  CirclePlansState? pause(String planId) {
    final plan = plans[planId];
    if (plan == null || plan.lifecycle != PlanLifecycle.active) return null;
    return _with(plan.copyWith(lifecycle: PlanLifecycle.paused));
  }

  /// "Carry on" a paused [planId] at its place.
  CirclePlansState? resume(String planId) {
    final plan = plans[planId];
    if (plan == null || plan.lifecycle != PlanLifecycle.paused) return null;
    return _activate(plan.copyWith(lifecycle: PlanLifecycle.active));
  }

  /// Leave [planId]: its cycle ends; every record stays.
  CirclePlansState? leave(String planId, {required String today}) {
    final plan = plans[planId];
    if (plan == null) return null;
    if (plan.lifecycle != PlanLifecycle.active &&
        plan.lifecycle != PlanLifecycle.paused) {
      return null;
    }
    final left = plan
        .withCurrent(plan.current.copyWith(endedOn: today, end: CycleEnd.left))
        .copyWith(lifecycle: PlanLifecycle.left);
    return _with(
      left,
      activePlanId: activePlanId == planId ? null : activePlanId,
    );
  }

  /// "Go through it again" after an ended or left cycle: a new cycle at
  /// stage 1; earlier cycles stay.
  CirclePlansState? goThroughAgain(String planId, {required String today}) {
    final plan = plans[planId];
    if (plan == null) return null;
    if (plan.lifecycle != PlanLifecycle.ended &&
        plan.lifecycle != PlanLifecycle.left) {
      return null;
    }
    return _activate(_newCycle(plan, planId, today));
  }

  /// "This stage again next time" (or "Try this stage" after a set-aside
  /// was reversed): once per stage per cycle, one at a time, for a stage
  /// the place has already passed.
  CirclePlansState? requestRevisit(String planId, int stageNumber) {
    final plan = plans[planId];
    if (plan == null) return null;
    if (plan.lifecycle != PlanLifecycle.active &&
        plan.lifecycle != PlanLifecycle.paused) {
      return null;
    }
    final cycle = plan.current;
    if (cycle.isOver || cycle.pendingRevisit != null) return null;
    if (stageNumber < 1 || stageNumber >= cycle.cursor) return null;
    if (cycle.revisitsUsed.contains(stageNumber)) return null;
    if (cycle.latest(stageNumber) == null) return null;
    return _with(
      plan.withCurrent(
        cycle.copyWith(
          pendingRevisit: stageNumber,
          revisitsUsed: {...cycle.revisitsUsed, stageNumber},
        ),
      ),
      activePlanId: activePlanId,
    );
  }

  /// ADR-024 I2, applied by the user: "Keep this Plan's Circles gentler for
  /// now" for the active [planId]'s current cycle. `null` if it doesn't
  /// apply — including when it is already on (never stacked).
  CirclePlansState? keepGentler(String planId, {required String today}) {
    final plan = plans[planId];
    if (plan == null || plan.lifecycle != PlanLifecycle.active) return null;
    final cycle = plan.current;
    if (cycle.isOver || cycle.isGentler) return null;
    return _with(
      plan.withCurrent(cycle.copyWith(gentlerSince: today)),
      activePlanId: activePlanId,
    );
  }

  /// Turns the gentler setting off for [planId]'s current cycle. Giving a
  /// setting up is never gated.
  CirclePlansState? stopGentler(String planId) {
    final plan = plans[planId];
    if (plan == null || !plan.current.isGentler) return null;
    return _with(
      plan.withCurrent(plan.current.copyWith(clearGentler: true)),
      activePlanId: activePlanId,
    );
  }

  /// A stage Circle was started and later closed in THIRTY: the stage is
  /// guided, and the place moves on once — never twice for one Circle,
  /// never for a Plan that is paused, left or in another cycle.
  CirclePlansState recordGuided(
    PlanStageProvenance stage, {
    required String circleId,
    required String today,
    required List<String> parts,
    required List<String> skipped,
  }) {
    final plan = plans[stage.planId];
    if (plan == null || plan.lifecycle != PlanLifecycle.active) return this;
    if (plan.lastAdvancedCircleId == circleId) return this;
    final cycle = plan.current;
    if (cycle.id != stage.cycleId || cycle.isOver) return this;
    if (cycle.records.any((r) => r.circleId == circleId)) return this;
    final expected = stage.revisit ? cycle.pendingRevisit : cycle.cursor;
    if (expected != stage.stageNumber) return this;
    final record = StageRecord(
      stageNumber: stage.stageNumber,
      outcome: StageOutcome.guided,
      localDate: today,
      circleId: circleId,
      parts: parts,
      skipped: skipped,
      drawsOn: stage.drawsOn,
      revisit: stage.revisit,
    );
    final records = [...cycle.records, record];
    final PlanProgress moved;
    if (stage.revisit) {
      moved = plan.withCurrent(
        cycle.copyWith(records: records, clearRevisit: true),
      );
    } else if (stage.stageNumber == 5) {
      moved = plan
          .withCurrent(
            cycle.copyWith(
              records: records,
              endedOn: today,
              end: CycleEnd.reachedEnd,
            ),
          )
          .copyWith(lifecycle: PlanLifecycle.ended);
    } else {
      moved = plan.withCurrent(
        cycle.copyWith(records: records, cursor: stage.stageNumber + 1),
      );
    }
    return _with(
      moved.copyWith(lastAdvancedCircleId: circleId),
      activePlanId: moved.lifecycle == PlanLifecycle.active
          ? activePlanId
          : null,
    );
  }

  /// Delete history (contract, Delete / Export): the stage evidence of
  /// every cycle goes with the journal ([PlanCycle.withoutEvidence]), and so
  /// does the last Circle that moved each Plan; each Plan's place — its
  /// lifecycle, cycles and where each one stands — stays.
  CirclePlansState forgetStageEvidence() => CirclePlansState(
    activePlanId: activePlanId,
    plans: {
      for (final e in plans.entries)
        e.key: PlanProgress(
          planId: e.value.planId,
          lifecycle: e.value.lifecycle,
          cycles: [for (final c in e.value.cycles) c.withoutEvidence()],
        ),
    },
  );
}

// ---------------------------------------------------------------------------
// Today (§6, C1–C4).

/// What the active Plan means for today's Circle.
class PlanDay {
  const PlanDay(this.state, {this.circle, this.stage, this.briefs});

  /// The Plans after today's set-asides and any end — what to persist.
  final CirclePlansState state;

  /// Today's stage Circle, or `null`: the ordinary Personal Guided Circle.
  final ComposedCircle? circle;
  final PlanStageProvenance? stage;

  /// The briefs [circle] was composed from — for one "Not this one today"
  /// inside the stage.
  final List<StageBrief>? briefs;
}

/// The user's explicit usefulness answers, by Circle id — from the journal.
typedef StageAnswers = Map<String, PastUsefulness>;

/// Stage 5's inputs: each earlier stage of [cycle] as its latest record
/// says — set aside, or guided with the latest answer the user gave. A
/// stage with no record (its evidence deleted) is unanswered.
List<EarlierStage> earlierStages(
  CirclePlanDefinition plan,
  PlanCycle cycle,
  StageAnswers answers,
) => [
  for (final stage in plan.stages.take(4))
    switch (cycle.latest(stage.number)) {
      StageRecord(outcome: StageOutcome.setAside) => EarlierStage(
        stage.id,
        setAside: true,
      ),
      _ => EarlierStage(stage.id, answer: _latestAnswer(cycle, stage, answers)),
    },
];

PastUsefulness? _latestAnswer(
  PlanCycle cycle,
  PlanStage stage,
  StageAnswers answers,
) {
  for (final r in cycle.records.reversed) {
    if (r.stageNumber != stage.number || r.outcome != StageOutcome.guided) {
      continue;
    }
    final answer = answers[r.circleId];
    if (answer != null) return answer;
  }
  return null;
}

/// The briefs today's stage [number] of [plan] is composed from, or `null`
/// for a stage 5 that isn't made (case D, or everything set aside) — with
/// the reason.
(List<StageBrief>?, CycleEnd?) _briefsFor(
  CirclePlanDefinition plan,
  PlanCycle cycle,
  int number,
  StageAnswers answers,
  DateTime date,
) {
  if (number < 5) return ([plan.briefFor(number)!], null);
  final five = stageFive(
    plan.stage(5).id,
    earlierStages(plan, cycle, answers),
    date,
  );
  return switch (five) {
    StageFiveBriefs(:final briefs) => (briefs, null),
    NoStageFive(reason: NoStageFiveReason.allRejected) => (
      null,
      CycleEnd.allRejected,
    ),
    NoStageFive(reason: NoStageFiveReason.allSetAside) => (
      null,
      CycleEnd.allSetAside,
    ),
  };
}

/// Today's Circle for the active Plan, if any applies (§6):
///
/// - only with [premium], an active Plan whose need is today's, and a
///   cycle that hasn't ended — otherwise nothing changes;
/// - a pending revisit first, without moving the place; else the place;
/// - **composed** → today's stage Circle;
/// - **wait** → the ordinary Personal Guided Circle; the place stays;
/// - **set aside** → recorded, the place moves past it (a revisit is only
///   cleared), and the next stage is tried the same day;
/// - stage 5 not made (case D) or set aside → the cycle reaches its end.
///
/// Bounded: five stages and one revisit.
PlanDay planToday(
  CirclePlansState plans, {
  required bool premium,
  required ComposerContext context,
  required Iterable<PastCircle> history,
  required StageAnswers answers,
  SuggestionControls controls = SuggestionControls.none,
  Set<ElementId> leftOut = const {},
  RecommendationPolicy policy = RecommendationPolicy.initial,
  ComposerPolicy composerPolicy = ComposerPolicy.initial,
}) {
  final active = plans.active;
  if (!premium || active == null) return PlanDay(plans);
  final definition = active.definition;
  if (definition.need != context.need || active.current.isOver) {
    return PlanDay(plans);
  }
  final today = _dateKey(context.date);
  var plan = active;
  CirclePlansState state() => plans._with(
    plan,
    activePlanId: plan.lifecycle == PlanLifecycle.active ? plan.planId : null,
  );

  // I2: a gentler cycle composes its stages with low-effort parts, one
  // size below today's time; every other rule is unchanged.
  final gentler = active.current.isGentler;
  final stageContext = gentler ? gentlerContext(context) : context;

  for (var attempt = 0; attempt < 6; attempt++) {
    final cycle = plan.current;
    final revisit = cycle.pendingRevisit;
    final number = revisit ?? cycle.cursor;
    final (authored, end) = _briefsFor(
      definition,
      cycle,
      number,
      answers,
      context.date,
    );
    final briefs = gentler && authored != null
        ? [for (final b in authored) b.gentler()]
        : authored;
    if (briefs == null) {
      plan = plan
          .withCurrent(cycle.copyWith(endedOn: today, end: end))
          .copyWith(lifecycle: PlanLifecycle.ended);
      return PlanDay(state());
    }
    switch (composeStage(
      stageContext,
      history,
      briefs,
      controls: controls,
      leftOut: leftOut,
      policy: policy,
      composerPolicy: composerPolicy,
    )) {
      case StageComposed(:final circle, :final brief):
        return PlanDay(
          state(),
          circle: circle,
          briefs: briefs,
          stage: PlanStageProvenance(
            planId: plan.planId,
            cycleId: cycle.id,
            stageNumber: number,
            stageId: definition.stage(number).id,
            drawsOn: number == 5 ? brief.drawsOn : const [],
            revisit: revisit != null,
            gentler: gentler,
          ),
        );
      case StageWaits():
        return PlanDay(state());
      case StageSetAside(:final blocks):
        if (revisit != null) {
          // A set-aside revisit is cleared; the place doesn't move.
          plan = plan.withCurrent(cycle.copyWith(clearRevisit: true));
          continue;
        }
        final records = [
          ...cycle.records,
          StageRecord(
            stageNumber: number,
            outcome: StageOutcome.setAside,
            localDate: today,
            setAsideBecause: blocks,
          ),
        ];
        if (number == 5) {
          plan = plan
              .withCurrent(
                cycle.copyWith(
                  records: records,
                  endedOn: today,
                  end: CycleEnd.reachedEnd,
                ),
              )
              .copyWith(lifecycle: PlanLifecycle.ended);
          return PlanDay(state());
        }
        plan = plan.withCurrent(
          cycle.copyWith(records: records, cursor: number + 1),
        );
    }
  }
  return PlanDay(state());
}

/// "Not this one today" on a stage Circle (C4 step 1): one recomposition
/// inside the same stage under the constraint in [context]. `null` when
/// none follows the stage — the caller then composes without it, and the
/// stage waits.
ComposedCircle? replaceStageCircle(
  List<StageBrief> briefs, {
  required ComposerContext context,
  required Iterable<PastCircle> history,
  SuggestionControls controls = SuggestionControls.none,
  Set<ElementId> leftOut = const {},
}) => switch (composeStage(
  context,
  history,
  briefs,
  controls: controls,
  leftOut: leftOut,
)) {
  StageComposed(:final circle) => circle,
  _ => null,
};

/// The briefs a served stage Circle was composed from, for [replaceStageCircle]
/// after a restart: stage 1–4's own, or stage 5's derived again from the
/// same records — gentler if it was composed gentler (I2).
List<StageBrief>? briefsForServedStage(
  CirclePlansState plans,
  PlanStageProvenance stage, {
  required StageAnswers answers,
  required DateTime date,
}) {
  final plan = plans.plans[stage.planId];
  if (plan == null || plan.current.id != stage.cycleId) return null;
  final (briefs, _) = _briefsFor(
    plan.definition,
    plan.current,
    stage.stageNumber,
    answers,
    date,
  );
  if (briefs == null || !stage.gentler) return briefs;
  return [for (final b in briefs) b.gentler()];
}

/// I2: [context] one size down ([gentlerWindow]), for a gentler stage.
ComposerContext gentlerContext(ComposerContext context) => ComposerContext(
  date: context.date,
  need: context.need,
  window: gentlerWindow(context.window),
  constraint: context.constraint,
);

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

// ---------------------------------------------------------------------------
// The review's facts (C7) — what B4 shows. Only what was recorded.

/// One stage as a review may state it.
class StageFacts {
  const StageFacts(this.stage, this.record, this.answer);

  final PlanStage stage;

  /// Its latest record this cycle, or `null`: not reached (or its evidence
  /// was deleted).
  final StageRecord? record;

  /// The user's answer, or `null`: no answer.
  final PastUsefulness? answer;
}

/// [cycle]'s stages, as the review may state them.
List<StageFacts> cycleFacts(
  CirclePlanDefinition plan,
  PlanCycle cycle,
  StageAnswers answers,
) => [
  for (final stage in plan.stages)
    StageFacts(
      stage,
      cycle.latest(stage.number),
      _latestAnswer(cycle, stage, answers),
    ),
];
