import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/date_key.dart';
import '../../home/application/recommendation_provider.dart';
import '../application/circle_plans_provider.dart';
import '../domain/plan_copy.dart';
import 'plan_actions.dart';

/// After today's Circle closes, when a Plan reached its end today: one calm
/// line and a way to its review in Plans — never a celebration, never a
/// jump away from Today.
class PlanEndCard extends ConsumerWidget {
  const PlanEndCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recommendationProvider);
    if (state.recommendation == null ||
        state.status != RecommendationStatus.closed) {
      return const SizedBox.shrink();
    }
    final today = dateKey(ref.watch(nowProvider));
    final ended = ref
        .watch(circlePlansProvider)
        .plans
        .values
        .where((p) => p.current.hasReview && p.current.endedOn == today)
        .firstOrNull;
    if (ended == null) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page - AppSpacing.s,
        0,
        AppSpacing.page - AppSpacing.s,
        AppSpacing.page,
      ),
      child: Semantics(
        container: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.surfaceMuted,
                    ),
                    child: Icon(
                      Icons.signpost_outlined,
                      size: 22,
                      color: colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text(PlanCopy.endedToday, style: textTheme.bodyLarge),
                ),
                const SizedBox(width: AppSpacing.s),
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () => context.go(planLocation(ended.planId)),
                  child: const Text(PlanCopy.reviewInPlans),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
