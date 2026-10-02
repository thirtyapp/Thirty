import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_card.dart';
import '../../domain/plan_catalog.dart';
import '../../domain/plan_ids.dart';
import '../../domain/plan_state.dart';
import 'plan_identity.dart';
import 'plan_progress.dart';
import 'plan_scene_art.dart';

/// Which stage node a Plan card or Your Path marks as current: only a Plan
/// that is active or was ever started has one.
bool planShowsCurrentStage(PlanProgress progress, {required bool isActive}) =>
    isActive || progress.lastEncounteredStageId != null;

/// One Plan on the Plans list (founder-approved Plans convergence,
/// 2026-10-01): identity mark, name, purpose, its five stages and a
/// chevron, with the Plan's own World scene on the right. The whole card
/// opens Your Path; every action lives there.
///
/// The same card serves entitled and Free users — name, purpose and the
/// position nodes are not paid content (frozen architecture §38.5).
class PlanCard extends StatelessWidget {
  const PlanCard({
    required this.planId,
    required this.progress,
    required this.isActive,
    required this.cardAsset,
    required this.onTap,
    super.key,
  });

  final PlanId planId;
  final PlanProgress progress;
  final bool isActive;
  final String cardAsset;
  final VoidCallback onTap;

  static const _largeTextScale = 1.3;
  static const _minWidthForArt = 300.0;
  static const _textShareWithArt = 0.72;
  static const _titleFontSize = 21.0;

  @override
  Widget build(BuildContext context) {
    final plan = planDefinitionFor(planId);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final largeText =
        MediaQuery.textScalerOf(context).scale(1) >= _largeTextScale;
    final states = planStageStates(
      progress,
      stageCount: plan.stages.length,
      showCurrent: planShowsCurrentStage(progress, isActive: isActive),
    );

    return Semantics(
      button: true,
      hint: 'Opens this plan',
      child: ThirtyCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final showArt = !largeText && width >= _minWidthForArt;
            final text = Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.featuredCard,
                AppSpacing.featuredCard,
                AppSpacing.featuredCard,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Identity and name on one line; the purpose then runs the
                  // column's full width, so it is never squeezed beside the
                  // mark (and never truncated).
                  Row(
                    children: [
                      PlanIdentityBadge(
                        planId: planId,
                        size: largeText ? 40 : 44,
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Text(
                          plan.name,
                          style: AppTypography.editorialDisplay(
                            colors,
                          ).copyWith(fontSize: _titleFontSize),
                        ),
                      ),
                      // Room for the chevron when there is no art beside it.
                      if (!showArt) const SizedBox(width: AppSpacing.l),
                    ],
                  ),
                  if (isActive) ...[
                    const SizedBox(height: AppSpacing.s),
                    const PlanActiveTag(),
                  ],
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    plan.purpose,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  PlanProgressDots(planId: planId, states: states),
                ],
              ),
            );
            // On a small surface disc, so it reads over any daypart's art —
            // an evening scene would otherwise swallow it.
            final chevron = Positioned(
              top: AppSpacing.m,
              right: AppSpacing.m,
              child: ExcludeSemantics(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surface.withValues(alpha: 0.9),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            );
            if (!showArt) {
              return Stack(children: [text, chevron]);
            }
            return SizedBox(
              width: width,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    width: width * (1 - _textShareWithArt) + AppSpacing.l,
                    child: PlanSceneArt(asset: cardAsset),
                  ),
                  SizedBox(width: width * _textShareWithArt, child: text),
                  chevron,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The active Plan's marker: a small tinted tag, announced as "Active
/// plan".
class PlanActiveTag extends StatelessWidget {
  const PlanActiveTag({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Semantics(
      label: 'Active plan',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.selection,
            borderRadius: AppRadius.pill,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s,
              vertical: 2,
            ),
            child: Text(
              'Active',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: colors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
