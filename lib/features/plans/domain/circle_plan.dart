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

import '../../../core/utils/date_key.dart';
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
    this.source,
  });

  final int stageNumber;
  final StageOutcome outcome;

  /// The record exactly as it was stored, when it was read from the store
  /// (R8.1 RL-3): a stage record never changes once written, so it is
  /// written back as stored — an item THIRTY can't read in one of its lists,
  /// or a field a newer THIRTY added, is never dropped by a later save. Its
  /// readable facts are what THIRTY uses; nothing is invented for the rest.
  final Map<String, Object?>? source;

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

  Map<String, Object?> toJson() => switch (source) {
    final stored? => {...stored},
    null => _fields(),
  };

  Map<String, Object?> _fields() => {
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
      source: raw,
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
    this.unreadableRecords = const [],
    this.unreadableRevisits = const [],
    this.extra = const {},
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

  /// Stage records stored in this cycle that THIRTY can't read (R8.1,
  /// Astra N07 / Claude AUD-3) — exactly as stored: never counted, shown or
  /// acted on, written back by every save, removed only by Delete Circle
  /// history (they may hold stage evidence).
  final List<Object?> unreadableRecords;

  /// Revisit entries stored that aren't stage numbers (R8.1 RL-3): written
  /// back as stored, never counted.
  final List<Object?> unreadableRevisits;

  /// Fields this build doesn't know, and known fields whose stored value it
  /// can't read, exactly as stored (R8.1 RL-3): written back until THIRTY
  /// itself sets that field again.
  final Map<String, Object?> extra;

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
    unreadableRevisits: unreadableRevisits,
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
    unreadableRecords: unreadableRecords,
    unreadableRevisits: unreadableRevisits,
    extra: {
      for (final MapEntry(:key, :value) in extra.entries)
        if (!(key == 'pendingRevisit' &&
                (clearRevisit || pendingRevisit != null)) &&
            !(key == 'revisitsUsed' && revisitsUsed != null) &&
            !(key == 'endedOn' && endedOn != null) &&
            !(key == 'gentlerSince' && (clearGentler || gentlerSince != null)))
          key: value,
    },
  );

  Map<String, Object?> toJson() => {
    ...extra,
    'id': id,
    'number': number,
    'startedOn': startedOn,
    'cursor': cursor,
    'pendingRevisit': ?pendingRevisit,
    if (revisitsUsed.isNotEmpty || unreadableRevisits.isNotEmpty)
      'revisitsUsed': [
        ...([...revisitsUsed]..sort()),
        ...unreadableRevisits,
      ],
    'records': [for (final r in records) r.toJson(), ...unreadableRecords],
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
    // An end THIRTY doesn't know (a newer THIRTY's) is never read as "not
    // ended": the cycle is unreadable, and its Plan kept as stored (R8.1
    // RL-3).
    final end = CycleEnd.values.asNameMap()[raw['end']];
    if (raw['end'] != null && end == null) return null;
    // A present records field that isn't a list can't be kept record by
    // record: the cycle is unreadable, and so its Plan (R8.1, Astra N07).
    final rawRecords = raw['records'];
    if (rawRecords != null && rawRecords is! List) return null;
    final validRevisit = revisit is int && revisit >= 1 && revisit < cursor;
    final rawRevisits = raw['revisitsUsed'];
    final revisits = <int>{};
    final unreadableRevisits = <Object?>[];
    if (rawRevisits is List) {
      for (final n in rawRevisits) {
        if (n is int) {
          revisits.add(n);
        } else {
          unreadableRevisits.add(n);
        }
      }
    }
    const known = {
      'id',
      'number',
      'startedOn',
      'cursor',
      'pendingRevisit',
      'revisitsUsed',
      'records',
      'endedOn',
      'end',
      'gentlerSince',
    };
    final extra = <String, Object?>{
      for (final MapEntry(:key, :value) in raw.entries)
        if (!known.contains(key)) key: value,
      if (revisit != null && !validRevisit) 'pendingRevisit': revisit,
      if (rawRevisits != null && rawRevisits is! List)
        'revisitsUsed': rawRevisits,
      if (endedOn != null && endedOn is! String) 'endedOn': endedOn,
      if (gentlerSince != null && gentlerSince is! String)
        'gentlerSince': gentlerSince,
    };
    final records = <StageRecord>[];
    final unreadable = <Object?>[];
    for (final r in (rawRecords as List?) ?? const <Object?>[]) {
      switch (StageRecord.fromJson(r)) {
        case final record?:
          records.add(record);
        case null:
          unreadable.add(r);
      }
    }
    return PlanCycle(
      id: id,
      number: number,
      startedOn: startedOn,
      cursor: cursor,
      pendingRevisit: validRevisit ? revisit : null,
      revisitsUsed: revisits,
      records: records,
      endedOn: endedOn is String ? endedOn : null,
      end: end,
      gentlerSince: gentlerSince is String ? gentlerSince : null,
      unreadableRecords: unreadable,
      unreadableRevisits: unreadableRevisits,
      extra: extra,
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
    this.lastServed,
    this.appliedInsight,
    this.startedWhilePaused,
    this.extra = const {},
  });

  final String planId;

  /// R8.3.1 (founder decision on R83-F1, 2026-11-07, Option B): the stage
  /// Circle whose valid Start was made while this Plan was paused. Plan
  /// credit follows the eligibility of that original Start: this Circle
  /// never earns any ([CirclePlansState.recordGuided]) — not at its Close,
  /// and not after the Plan is carried on, restarted or caught up, even
  /// once a later Circle has been served. Its History record stays. Kept
  /// on the Plan rather than on [lastServed], which the next serve
  /// replaces; one is enough, since only one day's Circle is ever still
  /// to be caught up. Stage evidence: Delete Circle history removes it.
  final String? startedWhilePaused;

  /// Fields this build doesn't know, and known fields whose stored value it
  /// can't read, exactly as stored (R8.1 RL-3): written back until THIRTY
  /// itself sets that field again.
  final Map<String, Object?> extra;
  final PlanLifecycle lifecycle;
  final List<PlanCycle> cycles;

  /// The last stage Circle that moved this Plan on — a Circle moves it
  /// once, however often it is closed or the app restarts.
  final String? lastAdvancedCircleId;

  /// The last stage Circle THIRTY served for this Plan, and its stage.
  /// Written only when a stage Circle is composed under Premium, so a Close
  /// after billing changed still credits the stage it was served for
  /// (audit remediation R2, founder decision D2).
  final ServedStageCircle? lastServed;

  /// The Insight whose own action last changed this Plan (R8.2, founder
  /// decision C): written in the same save as that change, so it is on
  /// disk exactly when the change is — what a retry reads to record the
  /// Insight as applied. A change the user made some other way never
  /// carries it.
  final AppliedInsight? appliedInsight;

  PlanCycle get current => cycles.last;
  CirclePlanDefinition get definition => circlePlanById[planId]!;

  PlanProgress copyWith({
    PlanLifecycle? lifecycle,
    List<PlanCycle>? cycles,
    String? lastAdvancedCircleId,
    ServedStageCircle? lastServed,
    AppliedInsight? appliedInsight,
    String? startedWhilePaused,
  }) => PlanProgress(
    planId: planId,
    lifecycle: lifecycle ?? this.lifecycle,
    cycles: cycles ?? this.cycles,
    lastAdvancedCircleId: lastAdvancedCircleId ?? this.lastAdvancedCircleId,
    lastServed: lastServed ?? this.lastServed,
    appliedInsight: appliedInsight ?? this.appliedInsight,
    startedWhilePaused: startedWhilePaused ?? this.startedWhilePaused,
    extra: {
      for (final MapEntry(:key, :value) in extra.entries)
        if (!(key == 'lastServed' && lastServed != null) &&
            !(key == 'lastAdvancedCircleId' && lastAdvancedCircleId != null) &&
            !(key == 'appliedInsight' && appliedInsight != null))
          key: value,
    },
  );

  /// With the current cycle replaced.
  PlanProgress withCurrent(PlanCycle cycle) =>
      copyWith(cycles: [...cycles.take(cycles.length - 1), cycle]);

  /// [cycle] in place of the cycle with its id — the current one or an
  /// earlier one (R8.2 Plan lifecycle policy: a left cycle credited later).
  PlanProgress withCycle(PlanCycle cycle) =>
      copyWith(cycles: [for (final c in cycles) c.id == cycle.id ? cycle : c]);

  Map<String, Object?> toJson() => {
    ...extra,
    'lifecycle': lifecycle.name,
    'cycles': [for (final c in cycles) c.toJson()],
    'lastAdvancedCircleId': ?lastAdvancedCircleId,
    'lastServed': ?lastServed?.toJson(),
    'appliedInsight': ?appliedInsight?.toJson(),
    'startedWhilePaused': ?startedWhilePaused,
  };

  static PlanProgress? fromJson(String planId, Object? raw) {
    if (!circlePlanById.containsKey(planId)) return null;
    if (raw is! Map<String, Object?>) return null;
    final lifecycle = PlanLifecycle.values.asNameMap()[raw['lifecycle']];
    if (lifecycle == null || lifecycle == PlanLifecycle.neverStarted) {
      return null;
    }
    // Every cycle must be read, or the Plan isn't (R8.1, Astra N07): a
    // damaged cycle is never dropped — which cycle is current depends on
    // all of them — so the whole Plan is kept as stored instead.
    final rawCycles = raw['cycles'];
    if (rawCycles is! List) return null;
    final cycles = <PlanCycle>[];
    for (final c in rawCycles) {
      final cycle = PlanCycle.fromJson(c);
      if (cycle == null) return null;
      cycles.add(cycle);
    }
    if (cycles.isEmpty) return null;
    final last = raw['lastAdvancedCircleId'];
    final served = ServedStageCircle.fromJson(raw['lastServed']);
    final insight = AppliedInsight.fromJson(raw['appliedInsight']);
    // R8.3.1: it decides credit, so present but not text makes the whole
    // Plan unreadable — kept as stored, never read as absent.
    final pausedStart = raw['startedWhilePaused'];
    if (pausedStart != null && pausedStart is! String) return null;
    const known = {
      'lifecycle',
      'cycles',
      'lastAdvancedCircleId',
      'lastServed',
      'appliedInsight',
      'startedWhilePaused',
    };
    return PlanProgress(
      planId: planId,
      lifecycle: lifecycle,
      cycles: cycles,
      lastAdvancedCircleId: last is String ? last : null,
      lastServed: served,
      appliedInsight: insight,
      startedWhilePaused: pausedStart as String?,
      extra: {
        for (final MapEntry(:key, :value) in raw.entries)
          if (!known.contains(key)) key: value,
        if (last != null && last is! String) 'lastAdvancedCircleId': last,
        if (raw['lastServed'] != null && served == null)
          'lastServed': raw['lastServed'],
        // A damaged record is kept as stored and attributes nothing.
        if (raw['appliedInsight'] != null && insight == null)
          'appliedInsight': raw['appliedInsight'],
      },
    );
  }
}

/// Which Insight's own action changed a Plan, for which cycle, and on which
/// day ([PlanProgress.appliedInsight], R8.2 founder decision C).
class AppliedInsight {
  const AppliedInsight({
    required this.insightId,
    required this.cycleId,
    required this.on,
    this.extra = const {},
  });

  final String insightId;

  /// The Plan's current cycle once the change was made.
  final String cycleId;

  /// The local date of the change (`YYYY-MM-DD`).
  final String on;

  /// R8.3 (Astra R82-N04): the fields of a stored record this build doesn't
  /// know, written back as stored. A new application is a new record, with
  /// none.
  final Map<String, Object?> extra;

  static const _known = {'insightId', 'cycleId', 'on'};

  Map<String, Object?> toJson() => {
    ...extra,
    'insightId': insightId,
    'cycleId': cycleId,
    'on': on,
  };

  /// `null` for anything that isn't a whole record.
  static AppliedInsight? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final id = raw['insightId'];
    final cycleId = raw['cycleId'];
    final on = raw['on'];
    if (id is! String || cycleId is! String || on is! String) return null;
    if (!isCanonicalDateKey(on)) return null;
    return AppliedInsight(
      insightId: id,
      cycleId: cycleId,
      on: on,
      extra: {
        for (final MapEntry(:key, :value) in raw.entries)
          if (!_known.contains(key)) key: value,
      },
    );
  }
}

/// One stage Circle as THIRTY served it: today's Circle id and the stage it
/// was composed for ([PlanProgress.lastServed]).
class ServedStageCircle {
  const ServedStageCircle({
    required this.circleId,
    required this.stage,
    this.startedAfterExpiry = false,
    this.startedBeforePause,
    this.closedBeforeLeave,
    this.source,
  });

  /// The stored record this was read from (R8.2, Astra R81-A05): written
  /// back with every field it holds — a newer build's too — and only the
  /// fields THIRTY changes on it ([startedAfterExpiry], [startedBeforePause],
  /// [closedBeforeLeave]) as now.
  final Map<String, Object?>? source;

  /// R8.2 Plan lifecycle policy (founder directive, 2026-11-06): the instant
  /// (UTC, ISO 8601) this Circle was started, recorded when its Plan was
  /// paused after that Start — by Pause, or by starting another Plan. That
  /// Circle's Close, once durable, still earns its credit on the paused
  /// Plan. Never set for a Circle started only after the Pause.
  final String? startedBeforePause;

  /// The same policy: the instant (UTC) the user asked to close this Circle,
  /// recorded when the Plan was left after that request — even while the
  /// Close was still being saved. That Close, and no other, still earns its
  /// credit on the cycle that was left, once it is durable.
  final String? closedBeforeLeave;

  final String circleId;
  final PlanStageProvenance stage;

  /// Started only once billing had verifiably ended Premium: still what
  /// THIRTY served, but it earns no guided credit of its own (R2, founder
  /// decision on the expiry before Start).
  final bool startedAfterExpiry;

  /// Whether [stage] on [circleId] is this served stage — the same Plan,
  /// cycle, stage and revisit.
  bool matches(PlanStageProvenance stage, {required String circleId}) =>
      circleId == this.circleId &&
      stage.planId == this.stage.planId &&
      stage.cycleId == this.stage.cycleId &&
      stage.stageNumber == this.stage.stageNumber &&
      stage.stageId == this.stage.stageId &&
      stage.revisit == this.stage.revisit;

  /// Whether [stamp] names the same instant as [at].
  static bool sameInstant(String? stamp, DateTime? at) {
    if (stamp == null || at == null) return false;
    return DateTime.tryParse(stamp)?.isAtSameMomentAs(at) ?? false;
  }

  /// The instant [at] as stored in a stamp.
  static String instant(DateTime at) => at.toUtc().toIso8601String();

  ServedStageCircle copyWith({
    bool? startedAfterExpiry,
    String? startedBeforePause,
    String? closedBeforeLeave,
  }) => ServedStageCircle(
    circleId: circleId,
    stage: stage,
    startedAfterExpiry: startedAfterExpiry ?? this.startedAfterExpiry,
    startedBeforePause: startedBeforePause ?? this.startedBeforePause,
    closedBeforeLeave: closedBeforeLeave ?? this.closedBeforeLeave,
    source: source,
  );

  /// The fields this build reads and writes itself.
  static const _known = {
    'circleId',
    'stage',
    'startedAfterExpiry',
    'startedBeforePause',
    'closedBeforeLeave',
  };

  /// R8.3 (Astra R82-N03, Claude AUD-N1): every known field is written as
  /// the model now holds it — a flag set back to false, or a stamp absent,
  /// is written absent, never inherited from [source]; only the fields this
  /// build doesn't know are kept from it. The stage is still written back
  /// as stored (R8.2, Astra R81-A05).
  Map<String, Object?> toJson() => {
    for (final MapEntry(:key, :value) in (source ?? const {}).entries)
      if (!_known.contains(key)) key: value,
    'circleId': circleId,
    'stage': source?['stage'] ?? stage.toJson(),
    if (startedAfterExpiry) 'startedAfterExpiry': true,
    'startedBeforePause': ?startedBeforePause,
    'closedBeforeLeave': ?closedBeforeLeave,
  };

  /// `null` for anything that isn't a whole served stage.
  ///
  /// R8.2 (Astra R81-A05): a flag that decides credit — the Start after an
  /// expiry, the stage's revisit or gentler — that is present but isn't a
  /// Boolean, or stage 5's sources that aren't text, make the record
  /// unreadable: never read as the default. It is then kept as stored
  /// ([PlanProgress.extra]) and credits nothing after a lapse.
  static ServedStageCircle? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final circleId = raw['circleId'];
    final rawStage = raw['stage'];
    final stage = PlanStageProvenance.fromJson(rawStage);
    if (circleId is! String || stage == null) return null;
    bool damaged(Object? flag) => flag != null && flag is! bool;
    final flag = raw['startedAfterExpiry'];
    if (damaged(flag)) return null;
    // The lifecycle-policy stamps decide credit too: present but not an
    // instant makes the record unreadable, never read as absent.
    String? stamp(Object? value) =>
        value is String && DateTime.tryParse(value) != null ? value : null;
    final paused = raw['startedBeforePause'];
    final left = raw['closedBeforeLeave'];
    if ((paused != null && stamp(paused) == null) ||
        (left != null && stamp(left) == null)) {
      return null;
    }
    if (rawStage is Map<String, Object?>) {
      final drawsOn = rawStage['drawsOn'];
      if (damaged(rawStage['revisit']) ||
          damaged(rawStage['gentler']) ||
          (drawsOn != null &&
              (drawsOn is! List || drawsOn.any((id) => id is! String)))) {
        return null;
      }
    }
    return ServedStageCircle(
      circleId: circleId,
      stage: stage,
      startedAfterExpiry: flag == true,
      startedBeforePause: stamp(paused),
      closedBeforeLeave: stamp(left),
      source: raw,
    );
  }
}

/// Every Plan the user has started, and the one active — at most one.
class CirclePlansState {
  const CirclePlansState({
    this.activePlanId,
    this.plans = const {},
    this.unreadablePlans = const {},
    this.extra = const {},
    this.retainedActivePlanId,
  });

  static const empty = CirclePlansState();

  final String? activePlanId;
  final Map<String, PlanProgress> plans;

  /// Plans stored in a readable record that THIRTY can't read (R8.1, Astra
  /// N07 / Claude AUD-3) — one this build doesn't know (a newer build's),
  /// or one with a damaged part — by id, exactly as stored: never shown,
  /// run or started over, written back by every save, removed only by
  /// Delete Circle history (they may hold stage evidence).
  final Map<String, Object?> unreadablePlans;

  /// Fields of the stored record this build doesn't know, written back as
  /// stored (R8.1, Astra N07).
  final Map<String, Object?> extra;

  /// The stored active Plan, when it is one of [unreadablePlans]: written
  /// back while no other Plan is made active (R8.1).
  final String? retainedActivePlanId;

  PlanProgress? get active => activePlanId == null ? null : plans[activePlanId];

  PlanLifecycle lifecycleOf(String planId) =>
      plans[planId]?.lifecycle ?? PlanLifecycle.neverStarted;

  CirclePlansState _with(PlanProgress plan, {String? activePlanId}) =>
      withPlans({...plans, plan.planId: plan}, activePlanId: activePlanId);

  /// These Plans as [next], [activePlanId] active — what THIRTY can't read
  /// still kept.
  CirclePlansState withPlans(
    Map<String, PlanProgress> next, {
    required String? activePlanId,
  }) => CirclePlansState(
    activePlanId: activePlanId,
    plans: next,
    unreadablePlans: unreadablePlans,
    extra: extra,
    retainedActivePlanId: activePlanId == null ? retainedActivePlanId : null,
  );

  /// Whether [planId]'s stored Plan is one THIRTY can't read: it is never
  /// started over, so nothing replaces it.
  bool isUnreadable(String planId) =>
      !plans.containsKey(planId) && unreadablePlans.containsKey(planId);

  Map<String, Object?> toJson() => {
    ...extra,
    'schemaVersion': circlePlansSchemaVersion,
    'activePlanId': ?(activePlanId ?? retainedActivePlanId),
    'plans': {
      ...unreadablePlans,
      for (final e in plans.entries) e.key: e.value.toJson(),
    },
  };

  /// `null` when [raw] isn't a readable record — a version this build
  /// doesn't know, or a present `plans` field that isn't a map. Inside a
  /// readable record, a Plan THIRTY can't read is kept as stored
  /// ([unreadablePlans]), never dropped (R8.1, Astra N07); an active id
  /// must name an active Plan.
  static CirclePlansState? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    if (raw['schemaVersion'] != circlePlansSchemaVersion) return null;
    final rawPlans = raw['plans'];
    if (rawPlans is! Map<String, Object?>) return null;
    final plans = <String, PlanProgress>{};
    final unreadable = <String, Object?>{};
    for (final e in rawPlans.entries) {
      switch (PlanProgress.fromJson(e.key, e.value)) {
        case final plan?:
          plans[e.key] = plan;
        case null:
          unreadable[e.key] = e.value;
      }
    }
    final active = raw['activePlanId'];
    return CirclePlansState(
      activePlanId:
          active is String && plans[active]?.lifecycle == PlanLifecycle.active
          ? active
          : null,
      plans: plans,
      unreadablePlans: unreadable,
      extra: {
        for (final e in raw.entries)
          if (e.key != 'schemaVersion' &&
              e.key != 'activePlanId' &&
              e.key != 'plans')
            e.key: e.value,
      },
      retainedActivePlanId: active is String && unreadable.containsKey(active)
          ? active
          : null,
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

  CirclePlansState _activate(PlanProgress plan) => withPlans({
    ..._pausingActive(plan.planId),
    plan.planId: plan,
  }, activePlanId: plan.planId);

  PlanProgress _newCycle(PlanProgress? plan, String planId, String today) {
    final number = (plan?.cycles.length ?? 0) + 1;
    final cycle = PlanCycle(
      id: '$planId#$number',
      number: number,
      startedOn: today,
    );
    // R8.2 Plan lifecycle policy: a Circle the user asked to close before
    // leaving keeps its served record into the new cycle, so its Close can
    // still credit the cycle that was left once it is durable. It names
    // that earlier cycle, so it never moves the new one on.
    final carried = plan?.lastServed;
    return PlanProgress(
      planId: planId,
      lifecycle: PlanLifecycle.active,
      cycles: [...?plan?.cycles, cycle],
      lastAdvancedCircleId: plan?.lastAdvancedCircleId,
      lastServed: carried?.closedBeforeLeave != null ? carried : null,
      appliedInsight: plan?.appliedInsight,
      extra: plan?.extra ?? const {},
    );
  }

  /// Start [planId]: a paused Plan carries on at its place; one never
  /// started, left or ended begins a new cycle at stage 1. Any other active
  /// Plan is paused at its place. Nothing is composed or recorded.
  CirclePlansState? start(String planId, {required String today}) {
    if (!circlePlanById.containsKey(planId)) return null;
    if (isUnreadable(planId)) return null;
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
  ///
  /// With [cycleId] (R8.2, Astra R81-A04), `null` too unless that cycle is
  /// the current one: I2 never changes a cycle it wasn't shown for.
  CirclePlansState? keepGentler(
    String planId, {
    required String today,
    String? cycleId,
  }) {
    final plan = plans[planId];
    if (plan == null || plan.lifecycle != PlanLifecycle.active) return null;
    final cycle = plan.current;
    if (cycleId != null && cycle.id != cycleId) return null;
    if (cycle.isOver || cycle.isGentler) return null;
    return _with(
      plan.withCurrent(cycle.copyWith(gentlerSince: today)),
      activePlanId: activePlanId,
    );
  }

  /// [planId] as changed by Insight [insightId]'s own action on [today]
  /// (R8.2, founder decision C): its current cycle named with it. `this`
  /// when there is no such Plan.
  CirclePlansState withAppliedInsight(
    String planId,
    String insightId, {
    required String today,
  }) {
    final plan = plans[planId];
    if (plan == null) return this;
    return _with(
      plan.copyWith(
        appliedInsight: AppliedInsight(
          insightId: insightId,
          cycleId: plan.current.id,
          on: today,
        ),
      ),
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
  /// never for another cycle.
  ///
  /// R8.2 Plan lifecycle policy (founder directive, 2026-11-06), for the
  /// Circle THIRTY served ([PlanProgress.lastServed]) and the very Start
  /// ([startedAt]) and Close ([closedAt]) being credited:
  /// - an active Plan's current cycle: credited, as before;
  /// - a paused Plan's current cycle: credited only when that Start came
  ///   before the Pause ([ServedStageCircle.startedBeforePause]); the Plan
  ///   stays paused (stage 5 ends its cycle, as it would have);
  /// - a cycle that was left: credited only when that Close was asked for
  ///   before the Leave ([ServedStageCircle.closedBeforeLeave]) — the left
  ///   cycle, not a later one; it stays left;
  /// - anything else — a Plan paused before the Start, left before the
  ///   Close — never.
  /// No other Plan is touched, and nothing is reactivated.
  ///
  /// R8.3.1 (founder decision on R83-F1, Option B): a Circle whose valid
  /// Start was made while its Plan was paused ([PlanProgress
  /// .startedWhilePaused]) is never credited — whatever the Plan's
  /// lifecycle when this runs: at its Close, in a later lifecycle change's
  /// fold, or in a restart's or the next day's catch-up.
  CirclePlansState recordGuided(
    PlanStageProvenance stage, {
    required String circleId,
    required String today,
    required List<String> parts,
    required List<String> skipped,
    DateTime? startedAt,
    DateTime? closedAt,
  }) {
    final plan = plans[stage.planId];
    if (plan == null) return this;
    if (plan.lastAdvancedCircleId == circleId) return this;
    if (plan.startedWhilePaused == circleId) return this;
    final cycle = plan.cycles.where((c) => c.id == stage.cycleId).firstOrNull;
    if (cycle == null) return this;
    if (cycle.records.any((r) => r.circleId == circleId)) return this;
    final served = plan.lastServed;
    final isServed =
        served != null && served.matches(stage, circleId: circleId);
    final startedFirst =
        isServed &&
        ServedStageCircle.sameInstant(served.startedBeforePause, startedAt);
    final closedFirst =
        isServed &&
        ServedStageCircle.sameInstant(served.closedBeforeLeave, closedAt) &&
        (served.startedBeforePause == null || startedFirst);
    final left = cycle.end == CycleEnd.left;
    final eligible = left
        ? closedFirst
        : identical(cycle, plan.current) &&
              !cycle.isOver &&
              switch (plan.lifecycle) {
                PlanLifecycle.active => true,
                PlanLifecycle.paused => startedFirst,
                _ => false,
              };
    if (!eligible) return this;
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
      moved = plan.withCycle(
        cycle.copyWith(records: records, clearRevisit: true),
      );
    } else if (left) {
      // The cycle that was left keeps its end; only its place is recorded.
      moved = plan.withCycle(
        cycle.copyWith(
          records: records,
          cursor: stage.stageNumber < 5 ? stage.stageNumber + 1 : null,
        ),
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
    // Another Plan that is active stays active (a paused Plan credited
    // while the user runs another one).
    return _with(
      moved.copyWith(lastAdvancedCircleId: circleId),
      activePlanId:
          moved.lifecycle == PlanLifecycle.active ||
              activePlanId != plan.planId
          ? activePlanId
          : null,
    );
  }

  /// [stage]'s Circle [circleId] was served — composed for the stage under
  /// Premium ([PlanProgress.lastServed]).
  CirclePlansState served(
    PlanStageProvenance stage, {
    required String circleId,
  }) {
    final plan = plans[stage.planId];
    if (plan == null) return this;
    return _with(
      plan.copyWith(
        lastServed: ServedStageCircle(circleId: circleId, stage: stage),
      ),
      activePlanId: activePlanId,
    );
  }

  /// Whether [stage]'s Circle [circleId] is the one THIRTY last served for
  /// its Plan.
  bool wasServed(PlanStageProvenance stage, {required String circleId}) =>
      plans[stage.planId]?.lastServed?.matches(stage, circleId: circleId) ??
      false;

  /// Whether the served stage Circle [circleId] earns its guided credit
  /// whatever billing says at Close: served under Premium ([wasServed]) and
  /// not started after a verified expiry.
  bool creditsServed(PlanStageProvenance stage, {required String circleId}) =>
      wasServed(stage, circleId: circleId) &&
      !plans[stage.planId]!.lastServed!.startedAfterExpiry;

  /// The served stage Circle [circleId] was started — with Premium verified
  /// [active], or verifiably ended. Records which on its served evidence,
  /// never removing it; anything other than that served Circle is
  /// unchanged, as is a Circle already recorded the same way.
  CirclePlansState noteStart(
    PlanStageProvenance stage, {
    required String circleId,
    required bool active,
  }) {
    final plan = plans[stage.planId];
    final served = plan?.lastServed;
    if (plan == null ||
        served == null ||
        !served.matches(stage, circleId: circleId) ||
        served.startedAfterExpiry == !active) {
      return this;
    }
    return _with(
      plan.copyWith(lastServed: served.copyWith(startedAfterExpiry: !active)),
      activePlanId: activePlanId,
    );
  }

  /// R8.3.1 (founder decision on R83-F1, Option B): [stage]'s served Circle
  /// [circleId] is being validly started now. If its Plan is paused, that
  /// Start is not eligible for Plan credit, and this says so on the Plan
  /// ([PlanProgress.startedWhilePaused]); `this` otherwise — an active Plan,
  /// a Circle that isn't the one served, or one already recorded.
  CirclePlansState noteStartedWhilePaused(
    PlanStageProvenance stage, {
    required String circleId,
  }) {
    final plan = plans[stage.planId];
    final served = plan?.lastServed;
    if (plan == null ||
        plan.lifecycle != PlanLifecycle.paused ||
        served == null ||
        !served.matches(stage, circleId: circleId) ||
        plan.startedWhilePaused == circleId) {
      return this;
    }
    return _with(
      plan.copyWith(startedWhilePaused: circleId),
      activePlanId: activePlanId,
    );
  }

  /// R8.2 Plan lifecycle policy: [planId]'s served Circle [circleId] with
  /// the order of the user's own actions recorded on it — started before
  /// its Plan was paused ([startedBeforePause]), asked to close before the
  /// Plan was left ([closedBeforeLeave]). `this` when that Circle isn't the
  /// one served for the Plan.
  CirclePlansState stampServed(
    String planId, {
    required String circleId,
    DateTime? startedBeforePause,
    DateTime? closedBeforeLeave,
  }) {
    final plan = plans[planId];
    final served = plan?.lastServed;
    if (plan == null || served == null || served.circleId != circleId) {
      return this;
    }
    return _with(
      plan.copyWith(
        lastServed: served.copyWith(
          startedBeforePause: startedBeforePause == null
              ? null
              : ServedStageCircle.instant(startedBeforePause),
          closedBeforeLeave: closedBeforeLeave == null
              ? null
              : ServedStageCircle.instant(closedBeforeLeave),
        ),
      ),
      activePlanId: activePlanId,
    );
  }

  /// Delete history (contract, Delete / Export): the stage evidence of
  /// every cycle goes with the journal ([PlanCycle.withoutEvidence]), and so
  /// does the last Circle that moved each Plan; each Plan's place — its
  /// lifecycle, cycles and where each one stands — stays.
  ///
  /// What THIRTY can't read may hold stage evidence and can't be told apart
  /// from it, so it goes too (R8.1) — as a whole record set aside does.
  CirclePlansState forgetStageEvidence() => CirclePlansState(
    activePlanId: activePlanId,
    extra: extra,
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
