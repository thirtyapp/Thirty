import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics_event_type.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/premium/premium_access.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../../../core/widgets/thirty_card.dart';
import '../../../../core/widgets/thirty_text_action.dart';
import '../../../home/application/activity_catalog.dart'
    show Intention, intentionLabel;
import '../../../plans/application/plan_provider.dart';
import '../../../plans/domain/plan_catalog.dart';
import '../../../plans/domain/plan_ids.dart';
import '../../../plans/domain/plan_state.dart';
import '../../application/insight_provider.dart';
import '../../domain/insight.dart';
import '../../domain/insight_family.dart';

/// THIRTY's minimum Circle Insights surface — Batch 2C
/// (`docs/product/adr/ADR-016-v1-batch-2c-circle-insights.md` §9).
///
/// Renders **at most one observation and one application** — never a
/// dashboard, chart, streak, or activity ranking. Renders nothing when
/// [currentInsightProvider] is `null` (no eligible evidence, or the
/// previously shown application is no longer valid) — silence is the
/// correct behavior in that case, not an empty-state placeholder.
///
/// Placed once, at the top of `../../../plans/presentation/plan_path_page.dart`
/// ("Your path") — never a separate top-level destination.
class InsightCard extends ConsumerWidget {
  const InsightCard({this.onApplied, super.key});

  /// Called after the application was actually made (never for a no-op
  /// against [InsightNotifier.applyCurrent]'s own recheck), so the page can
  /// confirm it once this card withdraws.
  final VoidCallback? onApplied;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Exposure/invalidation telemetry only — never evidence the user read,
    // understood, or acted on it (ADR-010 applies here exactly as it does
    // to `coachCueShown`). Fired at most once per distinct observation
    // transition, matching `coach_cue_banner.dart`'s own pattern.
    ref.listen<Insight?>(currentInsightProvider, (previous, next) {
      if (next != null && !_sameObservation(previous, next)) {
        ref
            .read(analyticsServiceProvider)
            .track(
              AnalyticsEventType.insightShown,
              metadata: {
                'family': next.family.name,
                'plan_id': next.targetPlanId.name,
              },
            );
      } else if (previous != null &&
          next == null &&
          ref.read(insightProvider).snapshots.isNotEmpty) {
        ref
            .read(analyticsServiceProvider)
            .track(
              AnalyticsEventType.insightApplicationInvalidated,
              metadata: {
                'family': previous.family.name,
                'plan_id': previous.targetPlanId.name,
              },
            );
      }
    });

    // What to show: the current Insight or — once a pattern's evidence has
    // aged out of the 28-day window — the same observation as a dated,
    // read-only earlier Insight (never "recent", never actionable).
    final displayed = ref.watch(displayedInsightProvider);
    if (displayed == null) return const SizedBox.shrink();
    final insight = displayed.insight;
    final isCurrent = displayed.isCurrent;

    final plansState = ref.watch(planProvider);
    final progress = plansState.progress[insight.targetPlanId];
    if (progress == null) return const SizedBox.shrink();

    final plan = planDefinitionFor(insight.targetPlanId);
    final direction = planDirection(insight.targetPlanId);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;

    final observation = _observationText(
      insight,
      plan,
      progress,
      direction,
      isCurrent: isCurrent,
    );
    final localizations = MaterialLocalizations.of(context);
    final observedAt = insight.observedAt;
    final observedOn = observedAt == null
        ? null
        : _keepTogether(localizations.formatShortDate(observedAt));
    final dateLine = observedOn == null
        ? null
        : isCurrent
        ? 'Observed on $observedOn'
        : 'An earlier Insight from $observedOn';
    final evidence = _evidenceText(insight, localizations);
    final applicationLabel = _applicationLabel(insight, progress);

    // Frozen architecture §18/§38.3: a retained observation stays readable
    // after entitlement ends — [insight] above is only ever a live recheck
    // of an *already-generated* snapshot ([currentInsightProvider] never
    // computes a new one), so it renders unconditionally either way. Only
    // the *application* — new paid orchestration — is gated: an unentitled
    // viewer sees the same truthful observation/evidence text, with the
    // action button replaced by a deliberate route to the existing Premium
    // offer instead of a button that would silently no-op against
    // `InsightNotifier.applyCurrent()`'s own matching entitlement guard.
    final isEntitled = ref.watch(premiumEntitlementProvider);

    // Phase C4: the page's "Insights" heading names this section, so the
    // card no longer repeats an "Insight" eyebrow.
    return ThirtyCard(
      padding: const EdgeInsets.all(AppSpacing.featuredCard),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The observation leads in the primary body colour; evidence and
            // date stay muted metadata.
            Text(
              observation,
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (evidence != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                evidence,
                semanticsLabel: _spokenForm(evidence),
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            if (dateLine != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                dateLine,
                semanticsLabel: _spokenForm(dateLine),
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            // Only a current Insight is actionable; an earlier one is
            // read-only history. Premium: the one bounded application is
            // the card's full-width main action. Free: the observation is
            // the user's own and stays fully readable — only applying it
            // is paid, offered as a quiet route, never a second button.
            if (isCurrent && isEntitled) ...[
              const SizedBox(height: AppSpacing.m),
              SizedBox(
                width: double.infinity,
                child: ThirtyButton(
                  label: applicationLabel,
                  // Never ellipsized: at large text the label that names
                  // the exact change wraps to as many lines as it needs.
                  maxLabelLines: null,
                  onPressed: () {
                    if (ref.read(insightProvider.notifier).applyCurrent()) {
                      onApplied?.call();
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ] else if (isCurrent) ...[
              const SizedBox(height: AppSpacing.xs),
              ThirtyTextAction(
                label: 'Become Premium to apply this',
                onPressed: () => context.push('/premium'),
              ),
            ],
            // Hides this exact observation without changing any Plan or
            // Coach state; only a genuinely new observation shows again.
            ThirtyTextAction(
              label: 'Dismiss',
              onPressed: () =>
                  ref.read(insightProvider.notifier).dismissLatest(),
            ),
          ],
        ),
      ),
    );
  }

  static bool _sameObservation(Insight? previous, Insight next) {
    return previous != null &&
        previous.family == next.family &&
        previous.targetPlanId == next.targetPlanId &&
        previous.targetStageId == next.targetStageId &&
        previous.evidenceCount == next.evidenceCount;
  }

  /// [isCurrent] `false` (an earlier Insight whose evidence has aged out)
  /// drops "recent" / "recently" — those records are no longer recent.
  static String _observationText(
    Insight insight,
    PlanDefinition plan,
    PlanProgress progress,
    Intention direction, {
    required bool isCurrent,
  }) {
    final recent = isCurrent ? 'recent ' : '';
    final recently = isCurrent ? ' recently' : '';
    final directionName = intentionLabel(direction);
    final isCompleted = progress.status == PlanCycleStatus.completed;
    final placeClause = isCompleted
        ? 'has finished this guided cycle'
        : 'is saved at stage ${progress.forwardCursor + 1} of '
              '${plan.stages.length}';

    switch (insight.family) {
      case InsightFamily.directionPathContinuity:
        if (insight.isPatternClaim) {
          return '$directionName was your direction on '
              '${insight.evidenceCount} ${recent}visits. Its Plan $placeClause.';
        }
        return '$directionName\'s Plan $placeClause.';

      case InsightFamily.chosenPacing:
        return 'You chose lighter guidance on ${insight.evidenceCount} '
            '${recent}Plan Circles.'
            '${_usefulnessSentence(insight)}';

      case InsightFamily.deliberateRevisits:
        final stageIndex = plan.stages.indexWhere(
          (s) => s.id == insight.targetStageId,
        );
        final stageLabel = stageIndex >= 0
            ? 'stage ${stageIndex + 1} of ${plan.stages.length}'
            : 'a stage';
        return 'You deliberately revisited $stageLabel of ${plan.name} '
            '${insight.evidenceCount} times$recently.'
            '${_usefulnessSentence(insight)}';
    }
  }

  static String _usefulnessSentence(Insight insight) {
    final denominator = insight.usefulnessDenominator;
    final numerator = insight.usefulnessNumerator;
    if (denominator == null || numerator == null) return '';
    return ' On the $denominator you rated, you reported it useful '
        '$numerator time${numerator == 1 ? '' : 's'}.';
  }

  static String? _evidenceText(
    Insight insight,
    MaterialLocalizations localizations,
  ) {
    if (!insight.isPatternClaim || insight.evidenceDateKeys.isEmpty) {
      return null;
    }
    final noun = insight.family == InsightFamily.deliberateRevisits
        ? 'revisits'
        : insight.family == InsightFamily.chosenPacing
        ? 'choices'
        : 'visits';
    // Localized dates, never the stored `YYYY-MM-DD` keys.
    String spoken(String key) {
      final date = DateTime.tryParse(key);
      return date == null
          ? key
          : _keepTogether(localizations.formatShortDate(date));
    }

    final first = spoken(insight.evidenceDateKeys.first);
    final last = spoken(insight.evidenceDateKeys.last);
    return 'Based on ${insight.evidenceCount} recorded $noun between '
        '$first and $last.';
  }

  /// A localized date that never splits across lines: its spaces become
  /// non-breaking, so the line wraps before or after the whole date.
  static String _keepTogether(String date) => date.replaceAll(' ', ' ');

  /// [text] as spoken — ordinary spaces, exactly as before the dates were
  /// kept together.
  static String _spokenForm(String text) => text.replaceAll(' ', ' ');

  static String _applicationLabel(Insight insight, PlanProgress progress) {
    switch (insight.applicationType) {
      case InsightApplicationType.activateOrResumePlan:
        return progress.lastEncounteredStageId != null
            ? 'Resume this Plan'
            : 'Activate this Plan';
      case InsightApplicationType.setLighterDefault:
        return 'Use lighter guidance as this Plan\'s default';
      case InsightApplicationType.queueRevisit:
        return 'Queue a one-off revisit of this stage';
    }
  }
}
