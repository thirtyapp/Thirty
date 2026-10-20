import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/branding/thirty_wordmark_view.dart';
import '../../../core/premium/premium_access.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/date_key.dart';
import '../../../core/widgets/thirty_button.dart';
import '../../../core/widgets/thirty_card.dart';
import '../../../core/widgets/thirty_text_action.dart';
import '../../home/application/activity_catalog.dart';
import '../../home/application/circle_journal.dart';
import '../../home/application/recommendation_provider.dart';
import '../../personal_circle/presentation/widgets/yours_parts.dart';
import '../../settings/presentation/widgets/you_header_art.dart';
import '../application/circle_plans_provider.dart';
import '../domain/circle_plan.dart';
import '../domain/plan_copy.dart';
import 'plan_actions.dart';
import 'plan_view.dart';

/// The Plans header band (ADR-024 B4): the approved watercolour valley, by
/// time of day.
const plansHeaderArt = YouHeaderArtSet(
  morning: YouHeaderArtImage(
    'assets/plans/plans_header_morning_v1.webp',
    width: 1870,
    height: 285,
  ),
  day: YouHeaderArtImage(
    'assets/plans/plans_header_day_v1.webp',
    width: 1870,
    height: 266,
  ),
  evening: YouHeaderArtImage(
    'assets/plans/plans_header_evening_v1.webp',
    width: 1870,
    height: 278,
  ),
);

/// Plans (ADR-024 §4, B4): the three launch Plans — readable on Free, run
/// with Premium. When the user has a Plan under way, it comes first; the
/// others follow, quieter. Never a streak, a checklist or a score.
class PlansPage extends ConsumerWidget {
  const PlansPage({super.key});

  static const location = '/plans';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final now = ref.watch(nowProvider);
    final plans = ref.watch(circlePlansProvider);
    final premium = ref.watch(premiumEntitlementProvider);
    final today = PlanToday.of(ref.watch(recommendationProvider));
    final journal = ref.watch(circleJournalRepositoryProvider).readAll();
    final featured = featuredPlan(plans);

    PlanStatusView statusOf(CirclePlanDefinition plan) => planStatus(
      plan,
      plans,
      premium: premium,
      today: today,
      todayKey: dateKey(now),
      journal: journal,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            const _PlansTopBar(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      PlanCopy.title,
                      style: AppTypography.editorialDisplay(
                        colors,
                      ).copyWith(fontSize: 34, height: 1.05),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    PlanCopy.subtitle,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            YouHeaderArt(art: plansHeaderArt, now: now),
            const SizedBox(height: AppSpacing.l),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const YoursNote(PlanCopy.intro),
                  const SizedBox(height: AppSpacing.l),
                  if (featured != null) ...[
                    YoursSection(
                      title: PlanCopy.yourPlan,
                      child: YourPlanCard(
                        plan: featured.definition,
                        status: statusOf(featured.definition),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    YoursSection(
                      title: PlanCopy.otherPlans,
                      child: YoursRows(
                        rows: [
                          for (final plan in launchCirclePlans)
                            if (plan.id != featured.planId)
                              YoursRow(
                                title: plan.name,
                                detail: _otherLine(plan, plans, statusOf(plan)),
                                onTap: () =>
                                    context.push(planLocation(plan.id)),
                              ),
                        ],
                      ),
                    ),
                  ] else
                    YoursSection(
                      title: PlanCopy.allPlans,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, plan)
                              in launchCirclePlans.indexed) ...[
                            if (i > 0) const SizedBox(height: AppSpacing.m),
                            PlanCatalogueCard(plan: plan),
                          ],
                        ],
                      ),
                    ),
                  if (!premium) ...[
                    const SizedBox(height: AppSpacing.l),
                    const YoursNote(PlanCopy.free),
                    ThirtyTextAction(
                      label: PlanCopy.startWithPremium,
                      onPressed: () => context.push('/premium'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Another Plan's one line: its own place when it has one, else its card.
  static String _otherLine(
    CirclePlanDefinition plan,
    CirclePlansState plans,
    PlanStatusView status,
  ) => switch (plans.lifecycleOf(plan.id)) {
    PlanLifecycle.paused || PlanLifecycle.ended => status.lines.first,
    _ => '${intentionLabel(plan.need)} · ${PlanCopy.card[plan.id]}',
  };
}

/// The Plan the page leads with: the active one; else a paused one; else
/// the latest whose cycle ended with a review.
PlanProgress? featuredPlan(CirclePlansState plans) {
  if (plans.active case final active?) return active;
  for (final plan in plans.plans.values) {
    if (plan.lifecycle == PlanLifecycle.paused) return plan;
  }
  PlanProgress? latest;
  for (final plan in plans.plans.values) {
    final cycle = plan.current;
    if (!cycle.hasReview) continue;
    if (latest == null ||
        (cycle.endedOn ?? '').compareTo(latest.current.endedOn ?? '') > 0) {
      latest = plan;
    }
  }
  return latest;
}

class _PlansTopBar extends StatelessWidget {
  const _PlansTopBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Semantics(
            label: 'THIRTY',
            child: const ExcludeSemantics(
              child: SizedBox(width: 96, child: ThirtyWordmarkView()),
            ),
          ),
        ),
      ),
    );
  }
}

/// A launch Plan before it has a place: its need, name, card line and the
/// five stages — readable whatever Premium's state.
class PlanCatalogueCard extends StatelessWidget {
  const PlanCatalogueCard({required this.plan, super.key});

  final CirclePlanDefinition plan;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    // Each stage name stays whole, and each "·" stays with the name before
    // it: a line never starts with a separator.
    final stages = plan.stages
        .map((s) => s.name.replaceAll(' ', '\u00A0'))
        .join('\u00A0· ');
    return Semantics(
      container: true,
      button: true,
      label:
          '${plan.name}. ${intentionLabel(plan.need)}. '
          '${PlanCopy.card[plan.id]} Stages: '
          '${plan.stages.map((s) => s.name).join(', ')}.',
      excludeSemantics: true,
      child: ThirtyCard(
        onTap: () => context.push(planLocation(plan.id)),
        padding: const EdgeInsets.all(AppSpacing.featuredCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YoursEyebrow(intentionLabel(plan.need)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              plan.name,
              style: AppTypography.editorialDisplay(
                colors,
              ).copyWith(fontSize: 26, height: 1.15),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(PlanCopy.card[plan.id]!, style: textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.s),
            Text(
              stages,
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// The user's own Plan, first on the page: where it stands, and its one
/// next action.
class YourPlanCard extends ConsumerWidget {
  const YourPlanCard({required this.plan, required this.status, super.key});

  final CirclePlanDefinition plan;
  final PlanStatusView status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final primary = status.primary;
    return ThirtyCard(
      onTap: () => context.push(planLocation(plan.id)),
      padding: const EdgeInsets.all(AppSpacing.featuredCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                YoursEyebrow(intentionLabel(plan.need)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  plan.name,
                  style: AppTypography.editorialDisplay(
                    colors,
                  ).copyWith(fontSize: 26, height: 1.15),
                ),
                if (status.heading case final heading?) ...[
                  const SizedBox(height: AppSpacing.s),
                  Text(heading, style: textTheme.titleMedium),
                ],
                for (final line in status.lines) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    line,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (primary != null) ...[
            const SizedBox(height: AppSpacing.m),
            ThirtyButton(
              label: planPrimaryLabel(primary),
              onPressed: () => runPlanPrimary(context, ref, plan, primary),
            ),
          ],
        ],
      ),
    );
  }
}
