import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/analytics/analytics_event_type.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/premium/premium_access.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../home/application/activity_catalog.dart' show ActivityId, Intention;
import '../domain/plan_catalog.dart';
import '../domain/plan_ids.dart';
import '../domain/plan_state.dart';

/// SharedPreferences key the entire Plan state is stored under, as one
/// JSON-encoded object — mirrors `circle_journal.dart`'s single-key,
/// versioned-blob pattern (ADR-013 §5) for the same reason: coherent,
/// atomic-enough replace semantics for state that must survive across many
/// days, rather than one preference key per field.
const plansStateKey = 'plans_state_v1';

/// The current Plan *state* record-shape version (distinct from
/// `plan_catalog.dart`'s [planContentVersion], which versions the authored
/// content, not this wrapper's shape). Bump only alongside a reviewed
/// schema-migration change to this file's read/write path.
const plansStateSchemaVersion = 1;

/// One resolved Plan Session assignment for today — returned by
/// [PlanNotifier.resolveSessionFor] and consumed by
/// `../../home/application/recommendation_provider.dart`'s
/// `chooseIntention`. Never persisted directly; the fields it carries are
/// folded into that day's `Recommendation` and journal entry instead.
class PlanSessionAssignment {
  const PlanSessionAssignment({
    required this.planId,
    required this.stageId,
    required this.activityId,
    required this.planCycleId,
    required this.planVersion,
    required this.isRevisit,
  });

  final PlanId planId;
  final StageId stageId;
  final ActivityId activityId;
  final String planCycleId;
  final int planVersion;

  /// Whether this assignment came from a queued one-off revisit
  /// (frozen architecture §9) rather than ordinary forward progression.
  /// `RecommendationNotifier.close()` reads this back (via
  /// `Recommendation.isPlanRevisit`) to decide whether closing this Circle
  /// should advance [PlanProgress.forwardCursor] — a revisit never does.
  final bool isRevisit;
}

/// Manages all local Circle Plan state — Batch 2A
/// (`docs/product/adr/ADR-014-v1-batch-2a-circle-plans.md`).
///
/// Holds one [PlanProgress] per [PlanId] at all times (never fewer), plus
/// which Plan (if any) is currently active. Persisted as a single
/// versioned JSON blob under [plansStateKey], read once in [build] and
/// rewritten wholesale on every mutation — the same fail-safe,
/// never-throws-on-corruption discipline `circle_journal.dart` already
/// established for this codebase.
class PlanNotifier extends Notifier<PlansState> {
  @override
  PlansState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return _restore(prefs) ?? _freshState();
  }

  /// Activates [planId] — the one Plan the daily loop will resolve a
  /// Session from. Never mutates any [PlanProgress]; the previously active
  /// Plan's own saved position is untouched (frozen architecture §4). A
  /// no-op if [planId] is already active. Never itself produces a new
  /// day's activity — see `recommendation_provider.dart`'s `chooseIntention`
  /// guard, which this method never calls.
  void activatePlan(PlanId planId) {
    if (state.activePlanId == planId) return;
    state = state.copyWith(activePlanId: planId);
    unawaited(_persist(state));
    ref
        .read(analyticsServiceProvider)
        .track(AnalyticsEventType.planStarted, metadata: {'plan_id': planId.name});
  }

  /// Clears the active Plan — daily resolution then always uses the
  /// complete Free selector, exactly as if no Plan existed, while every
  /// Plan's own saved position is preserved untouched.
  void deactivatePlan() {
    if (state.activePlanId == null) return;
    state = state.copyWith(clearActivePlanId: true);
    unawaited(_persist(state));
  }

  /// Queues a one-off revisit of the active Plan's
  /// [PlanProgress.lastEncounteredStageId] for the next eligible
  /// unresolved matching Circle (frozen architecture §9). A no-op if no
  /// Plan is active, if it has never encountered a stage yet, or if a
  /// revisit is already queued.
  void queueRevisit() {
    final planId = state.activePlanId;
    if (planId == null) return;
    final progress = state.progress[planId]!;
    if (progress.lastEncounteredStageId == null) return;
    if (progress.pendingRevisit) return;

    _updateProgress(planId, progress.copyWith(pendingRevisit: true));
    ref
        .read(analyticsServiceProvider)
        .track(
          AnalyticsEventType.planRevisitQueued,
          metadata: {
            'plan_id': planId.name,
            'stage_id': progress.lastEncounteredStageId!,
          },
        );
  }

  /// Clears a queued revisit before it applies to any Circle — the user
  /// may always change their mind (frozen architecture §9).
  void clearQueuedRevisit() {
    final planId = state.activePlanId;
    if (planId == null) return;
    final progress = state.progress[planId]!;
    if (!progress.pendingRevisit) return;
    _updateProgress(planId, progress.copyWith(pendingRevisit: false));
  }

  /// Starts a new cycle for [planId], only once its current cycle is
  /// [PlanCycleStatus.completed] (frozen architecture §13). Appends the
  /// finished cycle to [PlanProgress.cycleHistory] (never discarded),
  /// generates a new `cycleId`, and resets [PlanProgress.forwardCursor] to
  /// 0. A no-op while the current cycle is still in progress.
  void repeatCycle(PlanId planId) {
    final progress = state.progress[planId]!;
    if (progress.status != PlanCycleStatus.completed) return;

    final now = ref.read(eventClockProvider)();
    final finishedRecord = PlanCycleRecord(
      cycleId: progress.cycleId,
      contentVersion: progress.contentVersion,
      startedAt: progress.cycleStartedAt,
      completedAt: progress.cycleCompletedAt,
    );

    final fresh = PlanProgress(
      planId: planId,
      contentVersion: planContentVersion,
      cycleId: _nextCycleId(planId, progress),
      cycleStartedAt: now,
      forwardCursor: 0,
      status: PlanCycleStatus.inProgress,
      cycleHistory: [...progress.cycleHistory, finishedRecord],
    );
    _updateProgress(planId, fresh);
  }

  /// Resolves today's Plan Session for [intention], or `null` if the
  /// complete Free selector should be used instead
  /// (`recommendation_provider.dart`'s `chooseIntention` is the sole
  /// caller, and only ever calls this once per local day — see that
  /// method's own no-op guard).
  ///
  /// Returns `null` unless every one of these holds: the user is entitled
  /// ([premiumEntitlementProvider]), a Plan is active, that Plan's
  /// direction matches [intention], and its current cycle is still
  /// [PlanCycleStatus.inProgress] — a completed cycle with no repeat
  /// chosen falls through to Free (frozen architecture §12), never
  /// auto-enrolling another cycle.
  ///
  /// A queued revisit ([PlanProgress.pendingRevisit]) takes priority over
  /// ordinary forward progression and is consumed (cleared) by this call —
  /// [PlanProgress.forwardCursor] is never touched by that path. If the
  /// revisited [StageId] no longer exists in the current catalogue (a
  /// stale/incompatible reference), the revisit is silently skipped in
  /// favor of ordinary forward progression, never a crash or a fabricated
  /// stage.
  PlanSessionAssignment? resolveSessionFor(Intention intention) {
    if (!ref.read(premiumEntitlementProvider)) return null;

    final planId = state.activePlanId;
    if (planId == null) return null;
    if (planDirection(planId) != intention) return null;

    final progress = state.progress[planId]!;
    if (progress.status != PlanCycleStatus.inProgress) return null;
    if (progress.contentVersion != planContentVersion) return null;

    StageDefinition? stage;
    var isRevisit = false;
    final revisitTarget = progress.lastEncounteredStageId;
    if (progress.pendingRevisit && revisitTarget != null) {
      stage = findStage(planId, revisitTarget);
      isRevisit = stage != null;
    }

    stage ??= progress.forwardCursor <= 4
        ? stageAt(planId, progress.forwardCursor)
        : null;
    if (stage == null) return null;

    if (isRevisit) {
      _updateProgress(planId, progress.copyWith(pendingRevisit: false));
      ref
          .read(analyticsServiceProvider)
          .track(
            AnalyticsEventType.planRevisitUsed,
            metadata: {'plan_id': planId.name, 'stage_id': stage.id},
          );
    }

    ref
        .read(analyticsServiceProvider)
        .track(
          AnalyticsEventType.planSessionShown,
          metadata: {'plan_id': planId.name, 'stage_id': stage.id},
        );

    return PlanSessionAssignment(
      planId: planId,
      stageId: stage.id,
      activityId: stage.activityId,
      planCycleId: progress.cycleId,
      planVersion: progress.contentVersion,
      isRevisit: isRevisit,
    );
  }

  /// Advances [planId]'s forward cursor once, for [circleId]'s real Close
  /// transition — called only from `recommendation_provider.dart`'s
  /// `close()`, only when that Circle's `Recommendation.planId != null`.
  ///
  /// **Idempotent:** if [circleId] already matches
  /// [PlanProgress.lastAdvancedCircleId], this is a no-op — a duplicate or
  /// replayed call (including from a corrupted restore) can never advance
  /// the cursor twice for the same Circle.
  ///
  /// [isRevisit] must be [PlanSessionAssignment.isRevisit] from the
  /// resolution that produced this Circle — a revisit-sourced Circle never
  /// advances [PlanProgress.forwardCursor] (frozen architecture §9: "after
  /// the revisit, forward progression resumes from the previously saved
  /// cursor"), it only records [circleId] to keep this method idempotent.
  void advanceCursorForCircle(
    PlanId planId,
    String circleId, {
    required bool isRevisit,
  }) {
    final progress = state.progress[planId]!;
    if (progress.lastAdvancedCircleId == circleId) return;

    if (isRevisit) {
      _updateProgress(planId, progress.copyWith(lastAdvancedCircleId: circleId));
      return;
    }

    if (progress.forwardCursor > 4) {
      // Defensive: a completed plan should never reach here (resolution
      // already refuses to assign anything once completed), but never
      // advance past the catalogue either way.
      _updateProgress(planId, progress.copyWith(lastAdvancedCircleId: circleId));
      return;
    }

    final completedStage = stageAt(planId, progress.forwardCursor);
    final nextCursor = progress.forwardCursor + 1;

    if (nextCursor >= 5) {
      final now = ref.read(eventClockProvider)();
      _updateProgress(
        planId,
        progress.copyWith(
          forwardCursor: nextCursor,
          lastEncounteredStageId: completedStage.id,
          status: PlanCycleStatus.completed,
          lastAdvancedCircleId: circleId,
          cycleCompletedAt: now,
        ),
      );
      ref
          .read(analyticsServiceProvider)
          .track(
            AnalyticsEventType.planCycleCompleted,
            metadata: {'plan_id': planId.name},
          );
    } else {
      _updateProgress(
        planId,
        progress.copyWith(
          forwardCursor: nextCursor,
          lastEncounteredStageId: completedStage.id,
          lastAdvancedCircleId: circleId,
        ),
      );
    }
  }

  /// [planId]'s stage index (0-based) if [state.activePlanId] equals
  /// [planId] and a matching Circle is in progress today, for display
  /// purposes only (`../presentation/`). Not used by any resolution logic.
  PlanProgress progressFor(PlanId planId) => state.progress[planId]!;

  void _updateProgress(PlanId planId, PlanProgress updated) {
    state = state.copyWith(progress: {...state.progress, planId: updated});
    unawaited(_persist(state));
  }

  /// The next cycle id for [planId] when repeating — stable and
  /// human-legible (`'<planName>_cycle_<n>'`), never reused, so a stored
  /// `planCycleId` on an old journal entry always resolves to exactly one
  /// cycle's history.
  String _nextCycleId(PlanId planId, PlanProgress progress) {
    final ordinal = progress.cycleHistory.length + 2;
    return '${planId.name}_cycle_$ordinal';
  }

  PlansState _freshState() {
    final now = ref.read(nowProvider);
    return PlansState(
      activePlanId: null,
      progress: {
        for (final planId in PlanId.values)
          planId: PlanProgress.fresh(
            planId: planId,
            cycleId: '${planId.name}_cycle_1',
            startedAt: now,
          ),
      },
    );
  }

  Future<void> _persist(PlansState state) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final json = jsonEncode({
      'schemaVersion': plansStateSchemaVersion,
      'activePlanId': state.activePlanId?.name,
      'progress': {
        for (final entry in state.progress.entries)
          entry.key.name: entry.value.toJson(),
      },
    });
    await prefs.setString(plansStateKey, json);
  }

  /// Reads and decodes persisted Plan state, failing safe — never
  /// throwing — for anything unreadable at the wrapper level: no stored
  /// value, a non-JSON string, a mismatched [plansStateSchemaVersion], or a
  /// malformed `progress` map (all fall through to `null`, and [build]
  /// then starts every Plan fresh). Below that, each [PlanId]'s own
  /// [PlanProgress] fails safe **individually**: a missing, corrupt, or
  /// content-version-incompatible entry resets only that one Plan to a
  /// fresh [PlanProgress] rather than losing every Plan's state, or
  /// resolving an unknown stage.
  PlansState? _restore(SharedPreferences prefs) {
    final raw = prefs.getString(plansStateKey);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return null;
      if (decoded['schemaVersion'] != plansStateSchemaVersion) return null;

      final rawProgress = decoded['progress'];
      if (rawProgress is! Map) return null;

      final now = ref.read(nowProvider);
      final progress = <PlanId, PlanProgress>{};
      for (final planId in PlanId.values) {
        final rawEntry = rawProgress[planId.name];
        PlanProgress? parsed;
        if (rawEntry is Map<String, Object?>) {
          parsed = PlanProgress.fromJson(rawEntry);
        }
        // Fail safe per-Plan: missing, corrupt, incompatible content
        // version, or a lastEncounteredStageId/forwardCursor that no
        // longer resolves in the current catalogue all reset only this
        // one Plan — never the other two, and never a fabricated stage.
        if (parsed == null ||
            parsed.contentVersion != planContentVersion ||
            !_isCompatible(planId, parsed)) {
          progress[planId] = PlanProgress.fresh(
            planId: planId,
            cycleId: '${planId.name}_cycle_1',
            startedAt: now,
          );
        } else {
          progress[planId] = parsed;
        }
      }

      final activePlanIdRaw = decoded['activePlanId'];
      final activePlanId = PlanId.values.asNameMap()[activePlanIdRaw];

      return PlansState(activePlanId: activePlanId, progress: progress);
    } catch (_) {
      return null;
    }
  }

  /// Whether [progress]'s stage references still resolve in the current
  /// catalogue — a [forwardCursor] within `0..5` is already checked by
  /// [PlanProgress.fromJson]; this additionally confirms a non-null
  /// [PlanProgress.lastEncounteredStageId] still names a real stage of
  /// [planId], so a stale reference (e.g. after a hypothetical future
  /// content revision removed a stage) cannot be revisited or displayed as
  /// if it still existed.
  bool _isCompatible(PlanId planId, PlanProgress progress) {
    final lastEncountered = progress.lastEncounteredStageId;
    if (lastEncountered != null && findStage(planId, lastEncountered) == null) {
      return false;
    }
    return true;
  }
}

final planProvider = NotifierProvider<PlanNotifier, PlansState>(
  PlanNotifier.new,
);
