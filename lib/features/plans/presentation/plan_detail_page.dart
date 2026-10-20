import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/premium/premium_access.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/date_key.dart';
import '../../../core/widgets/thirty_app_bar.dart';
import '../../../core/widgets/thirty_button.dart';
import '../../../core/widgets/thirty_card.dart';
import '../../../core/widgets/thirty_text_action.dart';
import '../../home/application/activity_catalog.dart';
import '../../home/application/circle_journal.dart';
import '../../home/application/recommendation_provider.dart';
import '../../personal_circle/application/kept_circles_provider.dart';
import '../../personal_circle/domain/circle_elements.dart';
import '../../personal_circle/presentation/keep_circle_card.dart';
import '../../personal_circle/presentation/widgets/yours_parts.dart';
import '../application/circle_plans_provider.dart';
import '../domain/circle_plan.dart';
import '../domain/plan_copy.dart';
import 'plan_actions.dart';
import 'plan_view.dart';
import 'plans_page.dart';

/// One Plan (ADR-024 §4, B4): what it is for, where it stands, its five
/// stages, and — once a cycle is over — what the user told THIRTY. Every
/// action is the Plan notifier's; Free and lapsed users read everything and
/// are offered Premium's own page to run it.
class PlanDetailPage extends ConsumerWidget {
  const PlanDetailPage({required this.planId, this.cycleId, super.key});

  final String planId;

  /// B6: an earlier cycle whose review to show (from Insights) — `null`, or
  /// the current cycle, for the page as usual.
  final String? cycleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = circlePlanById[planId]!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final plans = ref.watch(circlePlansProvider);
    final premium = ref.watch(premiumEntitlementProvider);
    final now = ref.watch(nowProvider);
    final journal = ref.watch(circleJournalRepositoryProvider).readAll();
    final answers = stageAnswersFrom(journal);
    final status = planStatus(
      plan,
      plans,
      premium: premium,
      today: PlanToday.of(ref.watch(recommendationProvider)),
      todayKey: dateKey(now),
      journal: journal,
    );
    final progress = plans.plans[plan.id];
    final review = progress == null ? null : reviewOf(plan, progress, answers);
    // An earlier cycle's review, read the same way as of its own end.
    final earlierIndex = progress == null || cycleId == null
        ? -1
        : progress.cycles.indexWhere((c) => c.id == cycleId);
    final earlier =
        earlierIndex < 0 || earlierIndex == progress!.cycles.length - 1
        ? null
        : progress.cycles[earlierIndex];
    final earlierReview = earlier == null
        ? null
        : reviewOf(
            plan,
            progress!.copyWith(
              cycles: progress.cycles.sublist(0, earlierIndex + 1),
            ),
            answers,
          );
    final gentler =
        progress != null &&
        progress.current.isGentler &&
        (progress.lifecycle == PlanLifecycle.active ||
            progress.lifecycle == PlanLifecycle.paused);
    final rows = stageRows(plan, plans, premium: premium, journal: journal);
    final primary = status.primary;

    return Scaffold(
      appBar: const ThirtyAppBar(title: Text('Plan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.s,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          children: [
            YoursEyebrow(intentionLabel(plan.need)),
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              header: true,
              child: Text(
                plan.name,
                style: AppTypography.editorialDisplay(
                  colors,
                ).copyWith(fontSize: 30, height: 1.1),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              PlanCopy.purpose[plan.id]!,
              style: textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.l),
            ThirtyCard(
              padding: const EdgeInsets.all(AppSpacing.featuredCard),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MergeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (status.heading case final heading?) ...[
                          Text(heading, style: textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                        for (final (i, line) in status.lines.indexed) ...[
                          if (i > 0) const SizedBox(height: AppSpacing.xs),
                          Text(line, style: textTheme.bodyLarge),
                        ],
                      ],
                    ),
                  ),
                  // I2's setting, applied by the user from Insights: said
                  // plainly, and theirs to undo — never gated.
                  if (gentler) ...[
                    const SizedBox(height: AppSpacing.m),
                    const YoursNote(PlanCopy.gentlerNote),
                    ThirtyTextAction(
                      label: PlanCopy.usualPacing,
                      onPressed: () => ref
                          .read(circlePlansProvider.notifier)
                          .stopGentler(plan.id),
                    ),
                  ],
                  if (primary != null && primary != PlanPrimary.seeReview) ...[
                    const SizedBox(height: AppSpacing.m),
                    ThirtyButton(
                      label: planPrimaryLabel(primary),
                      onPressed: () =>
                          runPlanPrimary(context, ref, plan, primary),
                    ),
                  ],
                  if (status.canPause && premium)
                    ThirtyTextAction(
                      label: PlanCopy.pause,
                      onPressed: () =>
                          ref.read(circlePlansProvider.notifier).pause(plan.id),
                    ),
                  if (status.canLeave)
                    ThirtyTextAction(
                      label: PlanCopy.leave,
                      onPressed: () => confirmLeave(context, ref, plan),
                    ),
                ],
              ),
            ),
            if (!premium &&
                plans.lifecycleOf(plan.id) != PlanLifecycle.active &&
                plans.lifecycleOf(plan.id) != PlanLifecycle.paused) ...[
              const SizedBox(height: AppSpacing.m),
              const YoursNote(PlanCopy.free),
            ],
            if (earlier != null && earlierReview != null) ...[
              const SizedBox(height: AppSpacing.section),
              YoursSection(
                title: PlanCopy.earlierReviewHeading(earlier.number),
                child: _Review(
                  plan: plan,
                  review: earlierReview,
                  premium: premium,
                  showEndLine: true,
                  earlier: true,
                ),
              ),
            ],
            if (review != null) ...[
              const SizedBox(height: AppSpacing.section),
              YoursSection(
                title: PlanCopy.reviewHeading,
                child: _Review(
                  plan: plan,
                  review: review,
                  premium: premium,
                  showEndLine:
                      plans.lifecycleOf(plan.id) != PlanLifecycle.ended,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.section),
            YoursSection(
              title: PlanCopy.stagesHeading,
              child: ThirtyCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.featuredCard,
                  vertical: AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, row) in rows.indexed) ...[
                      if (i > 0) Divider(height: 1, color: colors.divider),
                      _StageRow(plan: plan, row: row),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One stage: number and name, its line, where it stands — and, where the
/// Plan allows it, "This stage again next time".
class _StageRow extends ConsumerWidget {
  const _StageRow({required this.plan, required this.row});

  final CirclePlanDefinition plan;
  final StageRowView row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            label: row.semantics,
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${row.stage.number} · ${row.stage.name}',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                if (row.status.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    row.status.join(' · '),
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  row.line,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                if (row.reason case final reason?) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(reason, style: textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (row.canRevisit)
            ThirtyTextAction(
              label: PlanCopy.revisit,
              onPressed: () => ref
                  .read(circlePlansProvider.notifier)
                  .requestRevisit(plan.id, row.stage.number),
            ),
        ],
      ),
    );
  }
}

/// "What you told THIRTY": the end, the user's answers in their own terms,
/// each stage as recorded, and the frozen options. Reflective, never a
/// verdict.
class _Review extends ConsumerWidget {
  const _Review({
    required this.plan,
    required this.review,
    required this.premium,
    required this.showEndLine,
    this.earlier = false,
  });

  final CirclePlanDefinition plan;
  final ReviewView review;
  final bool premium;
  final bool showEndLine;

  /// An earlier cycle's review: a record, with only "Keep one of these
  /// Circles" — the other options are about the Plan as it stands.
  final bool earlier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final journal = ref.watch(circleJournalRepositoryProvider).readAll();
    final quiet = textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    return ThirtyCard(
      padding: const EdgeInsets.all(AppSpacing.featuredCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The end is already the status card's line, except for a Plan
          // the user left (its status card offers a new start).
          if (showEndLine)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Text(review.endLine, style: textTheme.titleMedium),
            ),
          for (final (i, line) in review.summary.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.s),
            Text(line, style: textTheme.bodyLarge),
          ],
          const SizedBox(height: AppSpacing.m),
          for (final facts in review.facts)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(facts.stage.name, style: textTheme.bodyLarge),
                    Text(reviewFactLine(plan, facts, journal), style: quiet),
                  ],
                ),
              ),
            ),
          if (review.compared.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            YoursEyebrow(PlanCopy.comparedHeading),
            const SizedBox(height: AppSpacing.xs),
            for (final line in review.compared)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(line, style: textTheme.bodyMedium),
              ),
          ],
          const SizedBox(height: AppSpacing.m),
          if (!review.caseD && review.keepable.isNotEmpty)
            ThirtyButton(
              label: PlanCopy.keepOne,
              variant: ThirtyButtonVariant.secondary,
              onPressed: () => _keepSheet(context, ref),
            ),
          if (!review.caseD && !earlier)
            ThirtyTextAction(
              label: PlanCopy.goThroughAgain,
              onPressed: () {
                if (!premium) {
                  context.push('/premium');
                  return;
                }
                ref.read(circlePlansProvider.notifier).goThroughAgain(plan.id);
              },
            ),
          if (!earlier) ...[
            ThirtyTextAction(
              label: PlanCopy.chooseAnother,
              onPressed: () => context.go(PlansPage.location),
            ),
            ThirtyTextAction(
              label: PlanCopy.enough,
              onPressed: () => context.go(PlansPage.location),
            ),
          ],
        ],
      ),
    );
  }

  /// The guided stage Circles to choose from — the user picks; THIRTY
  /// never decides which.
  Future<void> _keepSheet(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await showModalBottomSheet<StageRecord>(
      context: context,
      barrierLabel: 'Close',
      // Over the whole app, the floating nav included.
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final kept = ref.watch(keptCirclesProvider).kept;
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                AppSpacing.l,
              ),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    PlanCopy.keepTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                const YoursNote(PlanCopy.keepNote),
                const SizedBox(height: AppSpacing.m),
                YoursRows(
                  rows: [
                    for (final record in review.keepable)
                      () {
                        final already = kept.any(
                          (k) => k.fromCircleId == record.circleId,
                        );
                        final parts = CirclePlan.fromWire(record.parts);
                        return YoursRow(
                          title: plan.stage(record.stageNumber).name,
                          detail: [
                            planShortDate(record.localDate),
                            ?parts?.substanceLine,
                            if (already) PlanCopy.inYours,
                          ].join(' · '),
                          onTap: already
                              ? null
                              : () => Navigator.of(sheetContext).pop(record),
                        );
                      }(),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    if (picked == null) return;
    final parts = CirclePlan.fromWire(picked.parts);
    if (parts == null) return;
    final kept = ref
        .read(keptCirclesProvider.notifier)
        .keepCircle(plan: parts, need: plan.need, circleId: picked.circleId!);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          kept != null ? KeepCircleCopy.kept(kept.name) : KeepCircleCopy.full,
        ),
      ),
    );
  }
}
