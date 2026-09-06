/// THIRTY's minimum Circle Insights orchestration — Batch 2C
/// (`docs/product/adr/ADR-016-v1-batch-2c-circle-insights.md`,
/// `RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md` §9).
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/analytics/analytics_event_type.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../home/application/circle_journal.dart';
import '../../plans/application/plan_provider.dart';
import '../../plans/domain/plan_state.dart';
import '../domain/insight.dart';
import '../domain/insight_engine.dart';
import '../domain/insight_family.dart';
import '../domain/insight_snapshot.dart';

/// How often a *new* Insight assessment may run — "at most once per
/// seven-day interval" (frozen architecture §9). This gates only when a
/// fresh evaluation may append new retained history; it never delays
/// withdrawing an already-invalid application (see [currentInsightProvider]).
const insightCadenceDays = 7;

/// All locally retained Insight state: when it was last assessed, and the
/// bounded, append-only history of every distinct observation assessed
/// since.
class InsightsState {
  const InsightsState({required this.lastAssessedAt, required this.snapshots});

  final DateTime? lastAssessedAt;
  final List<InsightSnapshot> snapshots;

  InsightsState copyWith({
    DateTime? lastAssessedAt,
    List<InsightSnapshot>? snapshots,
  }) {
    return InsightsState(
      lastAssessedAt: lastAssessedAt ?? this.lastAssessedAt,
      snapshots: snapshots ?? this.snapshots,
    );
  }
}

/// Manages THIRTY's local Insight snapshot history and the one current
/// Insight's application — Batch 2C.
///
/// Persisted as a single versioned JSON blob under [insightSnapshotsKey],
/// mirroring `../../plans/application/plan_provider.dart`'s and
/// `../../home/application/circle_journal.dart`'s own single-key pattern.
class InsightNotifier extends Notifier<InsightsState> {
  @override
  InsightsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return _restore(prefs) ?? const InsightsState(lastAssessedAt: null, snapshots: []);
  }

  /// Re-assesses THIRTY's current eligible Insight if due — a no-op unless
  /// [insightCadenceDays] have passed since the last assessment (or none
  /// has ever run). Only ever appends a *new* snapshot when the freshly
  /// evaluated observation actually differs from the latest retained one
  /// ("no invented novelty quota" — if nothing meaningfully changed,
  /// silence, i.e. no new snapshot, is acceptable); [lastAssessedAt]
  /// itself always advances so the cadence stays anchored to real
  /// assessment attempts.
  void refreshIfDue() {
    final now = ref.read(nowProvider);
    final last = state.lastAssessedAt;
    if (last != null && now.difference(last).inDays < insightCadenceDays) {
      return;
    }

    final journal = ref.read(circleJournalRepositoryProvider).readAll();
    final plansState = ref.read(planProvider);
    final candidate = evaluateInsight(
      journal: journal,
      plansState: plansState,
      now: now,
    );

    var snapshots = state.snapshots;
    if (candidate != null) {
      final latest = snapshots.isEmpty ? null : snapshots.last;
      final isSameObservation =
          latest != null && latest.describesSameObservationAs(candidate);
      if (!isSameObservation) {
        final snapshot = InsightSnapshot.fromInsight(candidate, generatedAt: now);
        snapshots = [...snapshots, snapshot];
        if (snapshots.length > insightSnapshotMaxCount) {
          snapshots = snapshots.sublist(
            snapshots.length - insightSnapshotMaxCount,
          );
        }
      }
    }

    state = InsightsState(lastAssessedAt: now, snapshots: snapshots);
    unawaited(_persist(state));
  }

  /// Applies the current Insight's one bounded application, only after
  /// rechecking it is still valid right now — "recheck applicability
  /// before applying a displayed card" (frozen architecture §9). A no-op,
  /// with no analytics and no Plan mutation, if there is no current
  /// snapshot or it is no longer valid (fires
  /// [AnalyticsEventType.insightApplicationInvalidated] in the latter case
  /// so a stale-command attempt is at least observable, never executed).
  void applyCurrent() {
    if (state.snapshots.isEmpty) return;
    final latest = state.snapshots.last;
    final plansState = ref.read(planProvider);
    final live = liveInsightView(latest, plansState);
    if (live == null) {
      ref
          .read(analyticsServiceProvider)
          .track(
            AnalyticsEventType.insightApplicationInvalidated,
            metadata: {
              'family': latest.family.name,
              'plan_id': latest.targetPlanId.name,
            },
          );
      return;
    }

    final notifier = ref.read(planProvider.notifier);
    switch (live.applicationType) {
      case InsightApplicationType.activateOrResumePlan:
        notifier.activatePlan(live.targetPlanId);
      case InsightApplicationType.setLighterDefault:
        notifier.setLighterDefaultForPlan(live.targetPlanId, true);
      case InsightApplicationType.queueRevisit:
        notifier.queueRevisit();
    }

    ref
        .read(analyticsServiceProvider)
        .track(
          AnalyticsEventType.insightApplicationAccepted,
          metadata: {
            'family': live.family.name,
            'plan_id': live.targetPlanId.name,
            'application_type': live.applicationType.name,
          },
        );
  }

  /// Permanently clears all retained Insight state — called when the user
  /// deletes their local Circle history
  /// (`../../home/presentation/circle_history_page.dart`), since a derived
  /// observation must not outlive the evidence it was drawn from ("stop
  /// derived personalization... remove its dependent snapshots").
  Future<void> clearAll() async {
    state = const InsightsState(lastAssessedAt: null, snapshots: []);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(insightSnapshotsKey);
  }

  Future<void> _persist(InsightsState state) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final json = jsonEncode({
      'schemaVersion': insightSnapshotsSchemaVersion,
      'lastAssessedAt': state.lastAssessedAt?.toIso8601String(),
      'snapshots': state.snapshots.map((s) => s.toJson()).toList(),
    });
    await prefs.setString(insightSnapshotsKey, json);
  }

  /// Reads and decodes persisted Insight state, failing safe to "never
  /// assessed, no history" for anything unreadable at the wrapper level —
  /// no stored value, a non-JSON string, a mismatched
  /// [insightSnapshotsSchemaVersion], or a malformed `snapshots` list.
  /// Individual malformed snapshots are dropped one at a time by
  /// [InsightSnapshot.fromJson] instead.
  InsightsState? _restore(SharedPreferences prefs) {
    final raw = prefs.getString(insightSnapshotsKey);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return null;
      if (decoded['schemaVersion'] != insightSnapshotsSchemaVersion) {
        return null;
      }

      final lastAssessedAtRaw = decoded['lastAssessedAt'];
      final lastAssessedAt = lastAssessedAtRaw == null
          ? null
          : DateTime.tryParse('$lastAssessedAtRaw');

      final rawSnapshots = decoded['snapshots'];
      if (rawSnapshots is! List) return null;
      final snapshots = <InsightSnapshot>[];
      for (final rawSnapshot in rawSnapshots) {
        if (rawSnapshot is! Map<String, Object?>) continue;
        final snapshot = InsightSnapshot.fromJson(rawSnapshot);
        if (snapshot != null) snapshots.add(snapshot);
      }

      return InsightsState(lastAssessedAt: lastAssessedAt, snapshots: snapshots);
    } catch (_) {
      return null;
    }
  }
}

final insightProvider = NotifierProvider<InsightNotifier, InsightsState>(
  InsightNotifier.new,
);

/// The current, live-rechecked Insight to display, or `null` when there is
/// none, or the latest retained snapshot's application is no longer valid.
///
/// A pure re-derivation of [insightProvider]'s latest snapshot against the
/// current [planProvider] state — this is what keeps a stage number or an
/// already-applied status from ever going stale between weekly
/// assessments ("the current Plan position updates immediately... a
/// factually invalid or deleted-data Insight is withdrawn immediately").
final currentInsightProvider = Provider<Insight?>((ref) {
  final snapshots = ref.watch(insightProvider).snapshots;
  if (snapshots.isEmpty) return null;
  final latest = snapshots.last;
  final plansState = ref.watch(planProvider);
  return liveInsightView(latest, plansState);
});

/// Reconstructs [snapshot] as a live [Insight] against [plansState], or
/// `null` if its application is no longer valid right now.
///
/// Withdrawal conditions, one per family:
/// - [InsightFamily.directionPathContinuity]: the target Plan has since
///   become the active Plan (no longer a new discovery to offer).
/// - [InsightFamily.chosenPacing]: the target Plan is no longer active, or
///   its lighter default is already set (no duplicate application).
/// - [InsightFamily.deliberateRevisits]: the target Plan is no longer
///   active, a revisit is already queued, or the Plan's
///   `lastEncounteredStageId` no longer matches the snapshot's stage (the
///   application must refer to the *currently* permitted last-encountered
///   stage).
///
/// A snapshot recorded under an old [InsightSnapshot.ruleVersion] is
/// treated as no-longer-current (never displayed, never applied) — it
/// remains readable, retained history, but only a fresh assessment under
/// the current rules may become the displayed Insight again.
Insight? liveInsightView(InsightSnapshot snapshot, PlansState plansState) {
  if (snapshot.ruleVersion != insightRuleVersion) return null;

  final progress = plansState.progress[snapshot.targetPlanId];
  if (progress == null) return null;

  switch (snapshot.family) {
    case InsightFamily.directionPathContinuity:
      if (plansState.activePlanId == snapshot.targetPlanId) return null;
    case InsightFamily.chosenPacing:
      if (plansState.activePlanId != snapshot.targetPlanId) return null;
      if (progress.lighterDefault) return null;
    case InsightFamily.deliberateRevisits:
      if (plansState.activePlanId != snapshot.targetPlanId) return null;
      if (progress.pendingRevisit) return null;
      if (progress.lastEncounteredStageId != snapshot.targetStageId) {
        return null;
      }
  }

  return Insight(
    family: snapshot.family,
    applicationType: snapshot.applicationType,
    targetPlanId: snapshot.targetPlanId,
    targetStageId: snapshot.targetStageId,
    isPatternClaim: snapshot.isPatternClaim,
    evidenceCount: snapshot.evidenceCount,
    evidenceDateKeys: snapshot.evidenceDateKeys,
    usefulnessNumerator: snapshot.usefulnessNumerator,
    usefulnessDenominator: snapshot.usefulnessDenominator,
  );
}
