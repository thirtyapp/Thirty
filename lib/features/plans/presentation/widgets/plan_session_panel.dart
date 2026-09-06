import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../../home/application/recommendation_provider.dart';
import '../../domain/plan_catalog.dart';
import '../../domain/plan_state.dart';

/// A Circle Session's Plan context — Batch 2A
/// (`docs/product/adr/ADR-014-v1-batch-2a-circle-plans.md`).
///
/// Renders nothing unless today's Circle was Plan-resolved
/// (`Recommendation.planId != null`) — a Free-selector-resolved Circle
/// looks exactly as it did before this batch. Deliberately not folded into
/// `circle_hero.dart`, the same separation `ActionReportPrompt` already
/// established (ADR-013 §10), so this batch's functional addition stays
/// independent of that file's own in-progress visual work.
///
/// Shows only what the frozen architecture calls for (§7): which Plan,
/// this stage's place and purpose, why it belongs here, and the one
/// standard/lighter treatment choice — never a second activity, never a
/// checklist, never a timer.
class PlanSessionPanel extends ConsumerWidget {
  const PlanSessionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendation = ref.watch(recommendationProvider).recommendation;
    final planId = recommendation?.planId;
    final stageId = recommendation?.stageId;
    if (recommendation == null || planId == null || stageId == null) {
      return const SizedBox.shrink();
    }

    // Fail-safe (§20): a stage reference that no longer resolves in the
    // current catalogue renders nothing here rather than a broken panel —
    // today's underlying Recommendation/activity remains fully intact and
    // usable through the ordinary Circle regardless.
    final stage = findStage(planId, stageId);
    if (stage == null) return const SizedBox.shrink();

    final plan = planDefinitionFor(planId);
    final stageIndex = plan.stages.indexWhere((s) => s.id == stageId);
    final treatment = recommendation.treatmentUsed ?? PlanTreatment.standard;
    final guidance = treatment == PlanTreatment.lighter
        ? stage.lighterGuidance
        : stage.standardGuidance;
    final textTheme = Theme.of(context).textTheme;
    final notifier = ref.read(recommendationProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.page,
      ),
      child: Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              plan.name,
              style: textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            if (stageIndex >= 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Stage ${stageIndex + 1} of ${plan.stages.length}',
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.s),
            Text(stage.purpose, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(
              stage.rationale,
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(guidance, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                Expanded(
                  child: ThirtyButton(
                    label: 'Standard',
                    variant: treatment == PlanTreatment.standard
                        ? ThirtyButtonVariant.primary
                        : ThirtyButtonVariant.secondary,
                    onPressed: () =>
                        notifier.setPlanTreatment(PlanTreatment.standard),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: ThirtyButton(
                    label: 'Lighter',
                    variant: treatment == PlanTreatment.lighter
                        ? ThirtyButtonVariant.primary
                        : ThirtyButtonVariant.secondary,
                    onPressed: () =>
                        notifier.setPlanTreatment(PlanTreatment.lighter),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
