import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/premium/premium_access.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_button.dart';
import '../../../core/widgets/thirty_card.dart';
import '../../coach/presentation/widgets/coach_cue_banner.dart';
import '../../insights/application/insight_provider.dart';
import '../../insights/presentation/widgets/insight_card.dart';
import '../application/plan_provider.dart';
import '../domain/plan_catalog.dart';
import '../domain/plan_ids.dart';
import '../domain/plan_state.dart';

/// THIRTY's Circle Plan management surface — Batch 2A
/// (`docs/product/adr/ADR-014-v1-batch-2a-circle-plans.md`).
///
/// Lists all three Plans and their independently preserved progress
/// (frozen architecture §4), and exposes only the bounded controls that
/// architecture actually calls for: activate/resume a Plan, queue or clear
/// a one-off revisit, and — once a cycle is finished — repeat it or choose
/// another direction (which is simply activating a different Plan; no
/// separate code path exists for that choice). This is Plan *management*,
/// never an activity browser: nothing here lets the user pick a specific
/// activity — only a broad direction Plan.
///
/// **Reachable regardless of entitlement** (`../../../core/routing/app_router.dart`
/// registers `/plans` unconditionally; `home_page.dart`'s AppBar icon only
/// controls *visibility* of one entry point, never access). What actually
/// protects paid content is [build] branching on [premiumEntitlementProvider]
/// itself: entitled renders the full list below via [_PlanCard]; unentitled
/// renders [_PlanPreviewCard] instead — each Plan's name/purpose (not
/// secret) plus a truthful read-only saved-position line where one exists,
/// with no interactive control and no [CoachCueBanner] (frozen architecture
/// §38.5's "reported content-level entitlement gap" — Coach/Insights
/// providers and widgets computing or showing paid content when reached
/// directly). This preserves the approved UX exactly: a calm, informative
/// Free preview at the destination itself, never a route-level redirect to
/// `/premium` and never an automatic paywall on open.
class PlanPathPage extends ConsumerStatefulWidget {
  const PlanPathPage({super.key});

  @override
  ConsumerState<PlanPathPage> createState() => _PlanPathPageState();
}

class _PlanPathPageState extends ConsumerState<PlanPathPage> {
  @override
  void initState() {
    super.initState();
    // Batch 2C: "assess a new current Insight at most once per seven-day
    // interval when the user opens the relevant surface" — scheduled for
    // after the first frame, never during build, since it may write
    // persisted state (`InsightNotifier.refreshIfDue`). A no-op unless the
    // cadence interval has actually elapsed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(insightProvider.notifier).refreshIfDue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final plansState = ref.watch(planProvider);
    final isEntitled = ref.watch(premiumEntitlementProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your path')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.page),
                itemCount: PlanId.values.length + 1,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.s),
                itemBuilder: (context, index) {
                  // InsightCard stays first regardless of entitlement — it
                  // already branches its own action area on
                  // [premiumEntitlementProvider] (see its own doc comment),
                  // so a retained observation from before entitlement ended
                  // stays exactly as readable here as it always was.
                  if (index == 0) return const InsightCard();
                  final planId = PlanId.values[index - 1];
                  final progress = plansState.progress[planId]!;
                  return isEntitled
                      ? _PlanCard(
                          planId: planId,
                          isActive: plansState.activePlanId == planId,
                          progress: progress,
                        )
                      : _PlanPreviewCard(planId: planId, progress: progress);
                },
              ),
            ),
            if (!isEntitled)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  0,
                  AppSpacing.page,
                  AppSpacing.page,
                ),
                child: ThirtyButton(
                  label: 'Open Premium',
                  onPressed: () => context.push('/premium'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({
    required this.planId,
    required this.isActive,
    required this.progress,
  });

  final PlanId planId;
  final bool isActive;
  final PlanProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = planDefinitionFor(planId);
    final notifier = ref.read(planProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final isCompleted = progress.status == PlanCycleStatus.completed;
    final hasEverStarted = progress.lastEncounteredStageId != null;

    return ThirtyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(plan.name, style: textTheme.titleMedium)),
              if (isActive)
                Semantics(
                  label: 'Active plan',
                  child: Text(
                    'Active',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            plan.purpose,
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            isCompleted
                ? 'This guided cycle is finished.'
                : 'Stage ${progress.forwardCursor + 1} of '
                      '${plan.stages.length}',
            style: textTheme.bodyMedium,
          ),
          if (progress.lighterDefault) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Lighter guidance is this Plan\'s default.',
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          if (isActive) ...[
            const SizedBox(height: AppSpacing.xs),
            CoachCueBanner(planId: planId),
          ],
          const SizedBox(height: AppSpacing.s),
          if (!isActive)
            ThirtyButton(
              label: hasEverStarted ? 'Resume' : 'Activate',
              onPressed: () => notifier.activatePlan(planId),
            )
          else ...[
            if (isCompleted)
              ThirtyButton(
                label: 'Repeat this cycle',
                onPressed: () => notifier.repeatCycle(planId),
              )
            else if (hasEverStarted)
              ThirtyButton(
                label: progress.pendingRevisit
                    ? 'Clear queued revisit'
                    : 'Queue a revisit of the last stage',
                variant: ThirtyButtonVariant.secondary,
                onPressed: progress.pendingRevisit
                    ? notifier.clearQueuedRevisit
                    : notifier.queueRevisit,
              ),
            const SizedBox(height: AppSpacing.xs),
            ThirtyButton(
              label: 'Pause this plan',
              variant: ThirtyButtonVariant.secondary,
              onPressed: notifier.deactivatePlan,
            ),
          ],
        ],
      ),
    );
  }
}

/// The unentitled counterpart to [_PlanCard] — a calm, informative Free
/// preview (frozen architecture §38.5: "a Free user may open a calm
/// informative preview of the paid destination"), never the interactive
/// management surface itself.
///
/// Shows only [planId]'s name and one-line purpose — already public,
/// descriptive text, not paid content — plus, when [progress] shows the
/// Plan was ever engaged, a truthful *read-only* saved-position line
/// (frozen architecture §18: "do not erase saved positions"; §38.5:
/// "preserve... saved positions"). No activate/resume/pause/revisit
/// control and no [CoachCueBanner] — those become reachable again only
/// once [premiumEntitlementProvider] is `true`, exactly mirroring
/// [PlanNotifier]'s own now-guarded mutation methods.
class _PlanPreviewCard extends StatelessWidget {
  const _PlanPreviewCard({required this.planId, required this.progress});

  final PlanId planId;
  final PlanProgress progress;

  @override
  Widget build(BuildContext context) {
    final plan = planDefinitionFor(planId);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final hasEverStarted = progress.lastEncounteredStageId != null;
    final isCompleted = progress.status == PlanCycleStatus.completed;

    return ThirtyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plan.name, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            plan.purpose,
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          if (hasEverStarted) ...[
            const SizedBox(height: AppSpacing.s),
            Text(
              isCompleted
                  ? 'Saved: this guided cycle was finished.'
                  : 'Saved at stage ${progress.forwardCursor + 1} of '
                        '${plan.stages.length}.',
              style: textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
