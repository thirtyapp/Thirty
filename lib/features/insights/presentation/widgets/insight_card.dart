import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_event_type.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../../../core/widgets/thirty_card.dart';
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
  const InsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insight = ref.watch(currentInsightProvider);

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

    if (insight == null) return const SizedBox.shrink();

    final plansState = ref.watch(planProvider);
    final progress = plansState.progress[insight.targetPlanId];
    if (progress == null) return const SizedBox.shrink();

    final plan = planDefinitionFor(insight.targetPlanId);
    final direction = planDirection(insight.targetPlanId);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;

    final observation = _observationText(insight, plan, progress, direction);
    final evidence = _evidenceText(insight);
    final applicationLabel = _applicationLabel(insight, progress);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: ThirtyCard(
        child: Semantics(
          container: true,
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Insight', style: textTheme.labelSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(observation, style: textTheme.bodyMedium),
              if (evidence != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  evidence,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.s),
              ThirtyButton(
                label: applicationLabel,
                variant: ThirtyButtonVariant.secondary,
                onPressed: () => ref.read(insightProvider.notifier).applyCurrent(),
              ),
            ],
          ),
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

  static String _observationText(
    Insight insight,
    PlanDefinition plan,
    PlanProgress progress,
    Intention direction,
  ) {
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
              '${insight.evidenceCount} recent visits. Its Plan $placeClause.';
        }
        return '$directionName\'s Plan $placeClause.';

      case InsightFamily.chosenPacing:
        return 'You chose lighter guidance on ${insight.evidenceCount} '
            'recent Plan Circles.'
            '${_usefulnessSentence(insight)}';

      case InsightFamily.deliberateRevisits:
        final stageIndex = plan.stages.indexWhere(
          (s) => s.id == insight.targetStageId,
        );
        final stageLabel = stageIndex >= 0
            ? 'stage ${stageIndex + 1} of ${plan.stages.length}'
            : 'a stage';
        return 'You deliberately revisited $stageLabel of ${plan.name} '
            '${insight.evidenceCount} times recently.'
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

  static String? _evidenceText(Insight insight) {
    if (!insight.isPatternClaim || insight.evidenceDateKeys.isEmpty) {
      return null;
    }
    final noun = insight.family == InsightFamily.deliberateRevisits
        ? 'revisits'
        : insight.family == InsightFamily.chosenPacing
        ? 'choices'
        : 'visits';
    final first = insight.evidenceDateKeys.first;
    final last = insight.evidenceDateKeys.last;
    return 'Based on ${insight.evidenceCount} recorded $noun between '
        '$first and $last.';
  }

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
