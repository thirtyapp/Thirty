/// THIRTY's Circle Plan state model — Batch 2A
/// (`docs/product/adr/ADR-014-v1-batch-2a-circle-plans.md`,
/// `RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md` §3).
///
/// **Forward progress and one-off revisit are separate, independent
/// pieces of state on [PlanProgress]** — [PlanProgress.forwardCursor] and
/// [PlanProgress.pendingRevisit] are never derived from one another, and no
/// method in `../application/plan_provider.dart` ever writes one while
/// reading the other as if they were the same field. This is the exact
/// separation the frozen architecture requires: "a revisit must never
/// overwrite or corrupt the forward cursor."
library;

import 'plan_ids.dart';

/// Whether the current cycle is still being worked through, or has
/// finished stage 5 and is awaiting an explicit repeat/direction change.
enum PlanCycleStatus { inProgress, completed }

/// Which of a stage's two authored guidance texts
/// (`plan_catalog.dart`'s [StageDefinition.standardGuidance]/
/// [StageDefinition.lighterGuidance]) is currently selected for display —
/// never changes which [ActivityId] a Session recommends.
enum PlanTreatment { standard, lighter }

/// A finished (or abandoned-by-repeat) cycle, kept for historical record —
/// "keeps historical prior-cycle records" (frozen architecture §13).
/// Never rewritten once appended.
class PlanCycleRecord {
  const PlanCycleRecord({
    required this.cycleId,
    required this.contentVersion,
    required this.startedAt,
    this.completedAt,
  });

  final String cycleId;
  final int contentVersion;
  final DateTime startedAt;

  /// `null` if this cycle was ended by an explicit repeat before reaching
  /// stage 5 — still preserved as history, never discarded.
  final DateTime? completedAt;

  Map<String, Object?> toJson() => {
    'cycleId': cycleId,
    'contentVersion': contentVersion,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  static PlanCycleRecord? fromJson(Map<String, Object?> json) {
    final cycleId = json['cycleId'];
    final contentVersion = json['contentVersion'];
    final startedAt = DateTime.tryParse('${json['startedAt']}');
    if (cycleId is! String || contentVersion is! int || startedAt == null) {
      return null;
    }
    final completedAtRaw = json['completedAt'];
    final completedAt = completedAtRaw == null
        ? null
        : DateTime.tryParse('$completedAtRaw');
    return PlanCycleRecord(
      cycleId: cycleId,
      contentVersion: contentVersion,
      startedAt: startedAt,
      completedAt: completedAt,
    );
  }
}

/// One [PlanId]'s complete local progress. All three Plans always have one
/// of these in [PlansState.progress] — "preserve the saved state of all
/// three direction Plans locally" (frozen architecture §4).
class PlanProgress {
  const PlanProgress({
    required this.planId,
    required this.contentVersion,
    required this.cycleId,
    required this.cycleStartedAt,
    required this.forwardCursor,
    required this.status,
    this.lastEncounteredStageId,
    this.pendingRevisit = false,
    this.cycleHistory = const [],
    this.lastAdvancedCircleId,
    this.cycleCompletedAt,
  });

  /// A brand-new, never-started [planId] — stage index 0, no history, no
  /// queued revisit. [cycleId] is caller-supplied (a fresh, unique
  /// identity, e.g. clock-derived) so this stays a pure data constructor.
  /// [contentVersion] defaults to the current catalogue version
  /// (`../application/plan_provider.dart` mirrors
  /// `plan_catalog.dart`'s `planContentVersion` into
  /// [_currentContentVersion] so this domain file need not import the
  /// content catalogue directly).
  factory PlanProgress.fresh({
    required PlanId planId,
    required String cycleId,
    required DateTime startedAt,
  }) {
    return PlanProgress(
      planId: planId,
      contentVersion: _currentContentVersion,
      cycleId: cycleId,
      cycleStartedAt: startedAt,
      forwardCursor: 0,
      status: PlanCycleStatus.inProgress,
    );
  }

  final PlanId planId;

  /// The `plan_catalog.dart` `planContentVersion` this progress was created
  /// under — compared against the catalogue's current version before this
  /// progress is trusted (see `../application/plan_provider.dart`'s
  /// restore path). A stale/incompatible version fails safe rather than
  /// resolving an unknown stage.
  final int contentVersion;

  /// This cycle's stable identity — new on every fresh start or explicit
  /// repeat (frozen architecture §13).
  final String cycleId;

  /// When the current cycle began — recorded into [PlanCycleRecord] once
  /// this cycle finishes or is repeated over.
  final DateTime cycleStartedAt;

  /// The index (0-4) of the stage currently being worked on; `5` means
  /// stage 5 has already been advanced past — i.e. [status] is
  /// [PlanCycleStatus.completed]. Never mutated by a revisit — see this
  /// library's own doc comment.
  final int forwardCursor;

  /// The [StageId] of the most recent stage this Plan actually assigned to
  /// a Circle (forward or revisit) — the target of a queued
  /// [pendingRevisit].
  final StageId? lastEncounteredStageId;

  /// Whether a one-off revisit of [lastEncounteredStageId] is queued for
  /// the next eligible unresolved matching Circle. Cleared once consumed,
  /// or explicitly by the user before it applies — never implied by
  /// [forwardCursor] or vice versa.
  final bool pendingRevisit;

  final PlanCycleStatus status;

  /// Previously finished/repeated-over cycles, oldest first. Never
  /// rewritten, only appended to.
  final List<PlanCycleRecord> cycleHistory;

  /// The `circleId` [forwardCursor] was last advanced for, if any — makes
  /// `../application/plan_provider.dart`'s `advanceCursorForCircle`
  /// idempotent even under a corrupted or duplicated restore: the same
  /// `circleId` is never allowed to advance the cursor twice.
  final String? lastAdvancedCircleId;

  /// When [status] became [PlanCycleStatus.completed] — `null` while
  /// [status] is [PlanCycleStatus.inProgress]. Carried into this cycle's
  /// [PlanCycleRecord] once an explicit repeat starts a new cycle.
  final DateTime? cycleCompletedAt;

  PlanProgress copyWith({
    int? forwardCursor,
    StageId? lastEncounteredStageId,
    bool? pendingRevisit,
    PlanCycleStatus? status,
    String? cycleId,
    DateTime? cycleStartedAt,
    List<PlanCycleRecord>? cycleHistory,
    String? lastAdvancedCircleId,
    DateTime? cycleCompletedAt,
    bool clearLastEncounteredStageId = false,
    bool clearCycleCompletedAt = false,
  }) {
    return PlanProgress(
      planId: planId,
      contentVersion: contentVersion,
      cycleId: cycleId ?? this.cycleId,
      cycleStartedAt: cycleStartedAt ?? this.cycleStartedAt,
      forwardCursor: forwardCursor ?? this.forwardCursor,
      lastEncounteredStageId: clearLastEncounteredStageId
          ? null
          : (lastEncounteredStageId ?? this.lastEncounteredStageId),
      pendingRevisit: pendingRevisit ?? this.pendingRevisit,
      status: status ?? this.status,
      cycleHistory: cycleHistory ?? this.cycleHistory,
      lastAdvancedCircleId: lastAdvancedCircleId ?? this.lastAdvancedCircleId,
      cycleCompletedAt: clearCycleCompletedAt
          ? null
          : (cycleCompletedAt ?? this.cycleCompletedAt),
    );
  }

  Map<String, Object?> toJson() => {
    'planId': planId.name,
    'contentVersion': contentVersion,
    'cycleId': cycleId,
    'cycleStartedAt': cycleStartedAt.toIso8601String(),
    'forwardCursor': forwardCursor,
    'lastEncounteredStageId': lastEncounteredStageId,
    'pendingRevisit': pendingRevisit,
    'status': status.name,
    'cycleHistory': cycleHistory.map((c) => c.toJson()).toList(),
    'lastAdvancedCircleId': lastAdvancedCircleId,
    'cycleCompletedAt': cycleCompletedAt?.toIso8601String(),
  };

  /// Parses one Plan's persisted progress, or `null` if any required field
  /// is missing/invalid — the caller (`../application/plan_provider.dart`)
  /// treats a `null` result exactly like "never started," never as an
  /// error to surface to the user.
  static PlanProgress? fromJson(Map<String, Object?> json) {
    final planIdName = json['planId'];
    final planId = PlanId.values.asNameMap()[planIdName];
    final contentVersion = json['contentVersion'];
    final cycleId = json['cycleId'];
    final cycleStartedAt = DateTime.tryParse('${json['cycleStartedAt']}');
    final forwardCursor = json['forwardCursor'];
    final status = PlanCycleStatus.values.asNameMap()[json['status']];

    if (planId == null ||
        contentVersion is! int ||
        cycleId is! String ||
        cycleStartedAt == null ||
        forwardCursor is! int ||
        forwardCursor < 0 ||
        forwardCursor > 5 ||
        status == null) {
      return null;
    }

    final lastEncounteredStageIdRaw = json['lastEncounteredStageId'];
    final lastEncounteredStageId = lastEncounteredStageIdRaw is String
        ? lastEncounteredStageIdRaw
        : null;
    final pendingRevisit = json['pendingRevisit'] == true;
    final lastAdvancedCircleIdRaw = json['lastAdvancedCircleId'];
    final lastAdvancedCircleId = lastAdvancedCircleIdRaw is String
        ? lastAdvancedCircleIdRaw
        : null;

    final rawHistory = json['cycleHistory'];
    final history = <PlanCycleRecord>[];
    if (rawHistory is List) {
      for (final rawRecord in rawHistory) {
        if (rawRecord is! Map<String, Object?>) continue;
        final record = PlanCycleRecord.fromJson(rawRecord);
        if (record != null) history.add(record);
      }
    }

    final cycleCompletedAtRaw = json['cycleCompletedAt'];
    final cycleCompletedAt = cycleCompletedAtRaw == null
        ? null
        : DateTime.tryParse('$cycleCompletedAtRaw');

    return PlanProgress(
      planId: planId,
      contentVersion: contentVersion,
      cycleId: cycleId,
      cycleStartedAt: cycleStartedAt,
      forwardCursor: forwardCursor,
      lastEncounteredStageId: lastEncounteredStageId,
      pendingRevisit: pendingRevisit,
      status: status,
      cycleHistory: history,
      lastAdvancedCircleId: lastAdvancedCircleId,
      cycleCompletedAt: cycleCompletedAt,
    );
  }
}

/// The content-schema version new [PlanProgress] is created under — kept
/// private and mirrored from `plan_catalog.dart`'s `planContentVersion` by
/// `../application/plan_provider.dart` (this domain file intentionally does
/// not import the catalogue, to keep pure state separate from content).
const int _currentContentVersion = 1;

/// All local Circle Plan state: which Plan (if any) is currently active,
/// and every Plan's independently preserved [PlanProgress].
class PlansState {
  const PlansState({required this.activePlanId, required this.progress})
    : assert(
        progress.length == 3,
        'All three Plans always have a PlanProgress entry, active or not.',
      );

  /// `null` until the user has ever activated a Plan — "V1 supports one
  /// active Plan" (frozen architecture §4).
  final PlanId? activePlanId;

  /// Every [PlanId]'s own progress — activating a different Plan never
  /// mutates the entries this map holds for the other two.
  final Map<PlanId, PlanProgress> progress;

  PlansState copyWith({
    PlanId? activePlanId,
    Map<PlanId, PlanProgress>? progress,
    bool clearActivePlanId = false,
  }) {
    return PlansState(
      activePlanId: clearActivePlanId
          ? null
          : (activePlanId ?? this.activePlanId),
      progress: progress ?? this.progress,
    );
  }
}
