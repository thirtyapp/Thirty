import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_event_type.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../../home/application/recommendation_provider.dart';
import '../../../plans/application/plan_provider.dart';
import '../../../plans/domain/plan_ids.dart';
import '../../../plans/domain/plan_state.dart';
import '../../domain/coach_cue.dart';
import '../../domain/coach_family.dart';
import '../../application/coach_provider.dart';

/// Renders [planId]'s current [CoachCue] (if any) — Batch 2B
/// (`docs/product/adr/ADR-015-v1-batch-2b-circle-coach.md` §6).
///
/// A quiet inline sentence plus, only where the resolved cue calls for it,
/// a bounded shortcut button to an *existing* Plan/Recommendation control —
/// never a new mechanism, never a second activity choice, never a chat
/// surface. Renders nothing when there is no relevant cue.
///
/// [suppressStageExplanation] hides [CoachFamily.stageExplanation]
/// specifically — used by `../../../plans/presentation/widgets/plan_session_panel.dart`,
/// which already shows the stage's own purpose/rationale, so repeating the
/// same "this is part of your path" fallback there would be redundant. The
/// "Your path" surface (`../../../plans/presentation/plan_path_page.dart`)
/// does not suppress it, since that surface shows no stage rationale of
/// its own.
class CoachCueBanner extends ConsumerWidget {
  const CoachCueBanner({
    required this.planId,
    this.suppressStageExplanation = false,
    super.key,
  });

  final PlanId planId;
  final bool suppressStageExplanation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cue = ref.watch(coachCueProvider(planId));

    // Exposure telemetry only — never evidence the user read, understood,
    // or acted on the cue (ADR-010 applies here exactly as it does to
    // recommendationShown/planSessionShown). Fired at most once per
    // distinct family transition for this plan, so freely re-watching this
    // provider elsewhere never produces duplicate events.
    ref.listen<CoachCue?>(coachCueProvider(planId), (previous, next) {
      if (next == null) return;
      if (next.family == previous?.family) return;
      ref
          .read(analyticsServiceProvider)
          .track(
            AnalyticsEventType.coachCueShown,
            metadata: {'plan_id': planId.name, 'family': next.family.name},
          );
    });

    if (cue == null) return const SizedBox.shrink();
    if (suppressStageExplanation &&
        cue.family == CoachFamily.stageExplanation) {
      return const SizedBox.shrink();
    }

    final recommendation = ref.watch(recommendationProvider).recommendation;
    final isTodayThisPlan = recommendation?.planId == planId;
    final showLighterButton =
        cue.offersLighterAction &&
        isTodayThisPlan &&
        recommendation!.treatmentUsed != PlanTreatment.lighter;

    final progress = ref.watch(planProvider).progress[planId];
    final showRevisitButton =
        cue.offersRevisitAction &&
        progress != null &&
        !progress.pendingRevisit &&
        progress.lastEncounteredStageId != null;

    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              cue.message,
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (showLighterButton || showRevisitButton) ...[
              const SizedBox(height: AppSpacing.xs),
              // Stacked, not side-by-side: both labels are full sentences,
              // and a shared-width Row overflows well before reaching the
              // large-text accessibility setting this control must still
              // support.
              if (showLighterButton)
                ThirtyButton(
                  label: 'Try lighter guidance today',
                  variant: ThirtyButtonVariant.secondary,
                  onPressed: () => ref
                      .read(recommendationProvider.notifier)
                      .setPlanTreatment(PlanTreatment.lighter),
                ),
              if (showLighterButton && showRevisitButton)
                const SizedBox(height: AppSpacing.xs),
              if (showRevisitButton)
                ThirtyButton(
                  label: 'Queue a one-off revisit',
                  variant: ThirtyButtonVariant.secondary,
                  onPressed: () =>
                      ref.read(planProvider.notifier).queueRevisit(),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
