/// THIRTY's minimum Circle Insights evaluation result — Batch 2C.
///
/// [Insight] is the pure, ephemeral output of
/// `insight_engine.dart`'s [evaluateInsight] — a truthful observation
/// paired with exactly one bounded application, both grounded in actual
/// local records (`RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md`
/// §9). It is never persisted directly; `insight_snapshot.dart`'s
/// [InsightSnapshot] captures the identity of an [Insight] (family, target,
/// evidence count/dates) for the bounded local history, while the actual
/// *current* displayed wording and application eligibility are always
/// recomputed live from current Plan state
/// (`../application/insight_provider.dart`) — so a stage number or
/// already-applied status is never stale (frozen architecture §9, "the
/// current Plan position updates immediately").
library;

import '../../plans/domain/plan_ids.dart';
import 'insight_family.dart';

/// Which existing bounded Plan/Coach control an [Insight]'s application
/// executes — never a new control system (frozen architecture §12: "An
/// Insight's application calls the same small set of Plan/Coach controls a
/// user can already understand").
enum InsightApplicationType {
  /// `PlanNotifier.activatePlan` — makes [Insight.targetPlanId] the active
  /// Plan, or resumes its already-saved position if it was previously
  /// engaged. The same primitive either way; only the button label differs.
  activateOrResumePlan,

  /// `PlanNotifier.setLighterDefaultForPlan(targetPlanId, true)`.
  setLighterDefault,

  /// `PlanNotifier.queueRevisit()` for the currently active Plan.
  queueRevisit,
}

/// One evaluated Insight — an observation grounded in actual records, plus
/// the one bounded application it makes available.
class Insight {
  const Insight({
    required this.family,
    required this.applicationType,
    required this.targetPlanId,
    this.targetStageId,
    this.isPatternClaim = false,
    this.evidenceCount = 0,
    this.evidenceDateKeys = const [],
    this.usefulnessNumerator,
    this.usefulnessDenominator,
  }) : assert(
         family != InsightFamily.deliberateRevisits || targetStageId != null,
         'A deliberate-revisits Insight must name the revisited stage.',
       );

  final InsightFamily family;
  final InsightApplicationType applicationType;

  /// The Plan this Insight's application acts on.
  final PlanId targetPlanId;

  /// The stage this Insight refers to — only set for
  /// [InsightFamily.deliberateRevisits], where the application must refer
  /// to the currently permitted last-encountered stage (frozen architecture
  /// §9's "application eligibility").
  final String? targetStageId;

  /// Whether this is a pattern-based claim (subject to the design gate —
  /// see `insight_engine.dart`'s `evidenceGateMet`) or a plain current-place
  /// fact that needs no count ([InsightFamily.directionPathContinuity]
  /// only — "a current-place observation is useful from the first saved
  /// Plan transition").
  final bool isPatternClaim;

  /// How many relevant records supported this observation at assessment
  /// time — `0` for a plain current-place fact.
  final int evidenceCount;

  /// The distinct local dates (`date_key.dart` format) of the records
  /// supporting this observation, sorted ascending — bounded, transparent
  /// evidence (frozen architecture §9's "shows the actual dates/counts").
  final List<String> evidenceDateKeys;

  /// How many of [evidenceCount]'s relevant affirmative-attempt records
  /// also carried a usefulness report — `null` when a usefulness-specific
  /// statement's own three-response gate is not met (never shown as `0`).
  final int? usefulnessDenominator;

  /// Of [usefulnessDenominator], how many were reported useful (very or
  /// somewhat) — `null` exactly when [usefulnessDenominator] is `null`.
  final int? usefulnessNumerator;
}
