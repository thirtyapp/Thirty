import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/premium/premium_access.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_app_bar.dart';
import '../../../core/widgets/thirty_button.dart';
import '../../../core/widgets/thirty_card.dart';
import '../../../core/widgets/thirty_text_action.dart';
import '../../coach/presentation/widgets/coach_cue_banner.dart';
import '../application/plan_provider.dart';
import '../domain/plan_catalog.dart';
import '../domain/plan_ids.dart';
import '../domain/plan_state.dart';
import 'widgets/plan_card.dart';
import 'widgets/plan_identity.dart';
import 'widgets/plan_progress.dart';
import 'widgets/plan_scene_art.dart';

/// Your Path — one Plan's own surface (`/plans/:planId`), opened from its
/// card on Plans (founder-approved contract, 2026-10-01).
///
/// Entitled: the Plan's identity and position, its five stages in order —
/// each stage's purpose, its state (closed, up next, upcoming, revisit
/// queued), and the current stage's rationale — then the existing Coach
/// cue and the existing Plan actions with their existing conditions.
/// Activity names and guidance never appear here: this is a path
/// overview, never an activity browser.
///
/// Free, including direct navigation: identity, purpose, artwork, the five
/// stages as structure only, a truthful saved position and one calm
/// Become Premium action. No stage purpose, control or Coach — the same
/// boundary as `PlanNotifier`'s guarded methods (frozen architecture
/// §38.5).
class PlanDetailPage extends ConsumerWidget {
  const PlanDetailPage({required this.planId, super.key});

  final PlanId planId;

  static const appBarTitle = 'Your Path';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = planDefinitionFor(planId);
    final plansState = ref.watch(planProvider);
    final progress = plansState.progress[planId]!;
    final isEntitled = ref.watch(premiumEntitlementProvider);
    final now = ref.watch(nowProvider);
    // A Plan only runs while entitled: a lapsed active Plan is presented
    // by its saved position, never as active.
    final isActive = isEntitled && plansState.activePlanId == planId;
    final states = planStageStates(
      progress,
      stageCount: plan.stages.length,
      showCurrent: planShowsCurrentStage(progress, isActive: isActive),
    );

    return Scaffold(
      appBar: const ThirtyAppBar(title: Text(appBarTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            _PathHeaderCard(
              planId: planId,
              progress: progress,
              isActive: isActive,
              isEntitled: isEntitled,
              states: states,
              cardAsset: PlanIdentity.of(planId).cardAssetAt(planId, now),
            ),
            const SizedBox(height: AppSpacing.l),
            if (isEntitled)
              _EntitledPath(
                planId: planId,
                progress: progress,
                states: states,
                isActive: isActive,
                anotherPlanIsActive:
                    plansState.activePlanId != null && !isActive,
              )
            else
              _FreePathPreview(planId: planId, states: states),
          ],
        ),
      ),
    );
  }
}

/// The Plan's identity, position and World scene.
class _PathHeaderCard extends StatelessWidget {
  const _PathHeaderCard({
    required this.planId,
    required this.progress,
    required this.isActive,
    required this.isEntitled,
    required this.states,
    required this.cardAsset,
  });

  final PlanId planId;
  final PlanProgress progress;
  final bool isActive;
  final bool isEntitled;
  final List<PlanStageState> states;
  final String cardAsset;

  static const _largeTextScale = 1.3;
  static const _minWidthForArt = 300.0;
  static const _textShareWithArt = 0.66;

  /// The position line — the same copy Plans has always used.
  String? _positionLine() {
    final plan = planDefinitionFor(planId);
    final isCompleted = progress.status == PlanCycleStatus.completed;
    final hasEverStarted = progress.lastEncounteredStageId != null;
    if (isEntitled) {
      return isCompleted
          ? 'This guided cycle is finished.'
          : 'Stage ${progress.forwardCursor + 1} of ${plan.stages.length}';
    }
    if (!hasEverStarted) return null;
    return isCompleted
        ? 'Saved: this guided cycle was finished.'
        : 'Saved at stage ${progress.forwardCursor + 1} of '
              '${plan.stages.length}.';
  }

  @override
  Widget build(BuildContext context) {
    final plan = planDefinitionFor(planId);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final largeText =
        MediaQuery.textScalerOf(context).scale(1) >= _largeTextScale;
    final position = _positionLine();
    final isCompleted = progress.status == PlanCycleStatus.completed;

    return ThirtyCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final showArt = !largeText && width >= _minWidthForArt;
          final text = Padding(
            padding: const EdgeInsets.all(AppSpacing.featuredCard),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlanIdentityBadge(planId: planId, size: 56),
                const SizedBox(height: AppSpacing.m),
                Semantics(
                  header: true,
                  child: Text(
                    plan.name,
                    style: AppTypography.editorialDisplay(colors),
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(height: AppSpacing.xs),
                  const PlanActiveTag(),
                ],
                const SizedBox(height: AppSpacing.s),
                Text(
                  plan.purpose,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                if (position != null) ...[
                  const SizedBox(height: AppSpacing.m),
                  Text(position, style: textTheme.bodyLarge),
                ],
                const SizedBox(height: AppSpacing.s),
                PlanProgressDots(planId: planId, states: states),
                if (isEntitled && progress.lighterDefault && !isCompleted) ...[
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    'Lighter guidance is this Plan\'s default.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          );
          if (!showArt) return text;
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
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The entitled path: five stages, the Coach cue and the Plan actions.
class _EntitledPath extends ConsumerWidget {
  const _EntitledPath({
    required this.planId,
    required this.progress,
    required this.states,
    required this.isActive,
    required this.anotherPlanIsActive,
  });

  final PlanId planId;
  final PlanProgress progress;
  final List<PlanStageState> states;
  final bool isActive;

  /// While one Plan is active, switching to another is a secondary choice.
  final bool anotherPlanIsActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = planDefinitionFor(planId);
    final notifier = ref.read(planProvider.notifier);
    final isCompleted = progress.status == PlanCycleStatus.completed;
    final hasEverStarted = progress.lastEncounteredStageId != null;
    // The page's own revisit action (queue / clear): an active, started,
    // unfinished cycle. The Coach banner's identical shortcut is then
    // suppressed, so the same action is never offered twice.
    final offersRevisit = isActive && hasEverStarted && !isCompleted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StageList(
          planId: planId,
          states: states,
          // A queued revisit comes first; the cursor's stage follows it.
          currentLabel: progress.pendingRevisit
              ? 'After the revisit'
              : 'Up next',
          children: [
            for (var i = 0; i < plan.stages.length; i++)
              _StageText(
                stage: plan.stages[i],
                state: states[i],
                revisitQueued:
                    progress.pendingRevisit &&
                    plan.stages[i].id == progress.lastEncounteredStageId,
              ),
          ],
        ),
        if (isActive) ...[
          const SizedBox(height: AppSpacing.m),
          CoachCueBanner(
            planId: planId,
            centered: false,
            suppressRevisitShortcut: offersRevisit,
          ),
        ],
        const SizedBox(height: AppSpacing.l),
        if (!isActive)
          ThirtyButton(
            label: hasEverStarted ? 'Resume' : 'Activate',
            variant: anotherPlanIsActive
                ? ThirtyButtonVariant.secondary
                : ThirtyButtonVariant.primary,
            onPressed: () => notifier.activatePlan(planId),
          )
        else ...[
          if (isCompleted)
            ThirtyButton(
              label: 'Repeat this cycle',
              onPressed: () => notifier.repeatCycle(planId),
            ),
          // Management: quiet text actions.
          if (offersRevisit)
            ThirtyTextAction(
              label: progress.pendingRevisit
                  ? 'Clear queued revisit'
                  : 'Queue a revisit of the last stage',
              onPressed: progress.pendingRevisit
                  ? notifier.clearQueuedRevisit
                  : notifier.queueRevisit,
            ),
          ThirtyTextAction(
            label: 'Pause this plan',
            onPressed: notifier.deactivatePlan,
          ),
        ],
      ],
    );
  }
}

/// One stage's text on the entitled path.
class _StageText extends StatelessWidget {
  const _StageText({
    required this.stage,
    required this.state,
    required this.revisitQueued,
  });

  final StageDefinition stage;
  final PlanStageState state;
  final bool revisitQueued;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final isCurrent = state == PlanStageState.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stage.purpose,
          style: textTheme.bodyMedium?.copyWith(
            color: isCurrent ? colors.textPrimary : colors.textSecondary,
          ),
        ),
        if (revisitQueued) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Revisit queued',
            style: textTheme.labelLarge?.copyWith(color: colors.textPrimary),
          ),
        ],
        if (isCurrent) ...[
          const SizedBox(height: AppSpacing.s),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceMuted,
              borderRadius: AppRadius.large,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Text(
                stage.rationale,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The five stages as a vertical path: a node per stage joined by a
/// hairline, each with its number, state and [children]'s content (or
/// nothing beyond the number, for the Free structure).
class _StageList extends StatelessWidget {
  const _StageList({
    required this.planId,
    required this.states,
    required this.currentLabel,
    this.children,
  });

  final PlanId planId;
  final List<PlanStageState> states;

  /// What the current stage is called: "Up next" on an entitled path,
  /// "Saved here" on the Free preview, where nothing runs next.
  final String currentLabel;
  final List<Widget>? children;

  static const _node = 20.0;

  String stateLabel(PlanStageState state) => switch (state) {
    PlanStageState.closed => 'Closed',
    PlanStageState.current => currentLabel,
    PlanStageState.upcoming => 'Upcoming',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final tone = PlanIdentity.of(planId).toneFor(Theme.of(context).brightness);
    final labelStyle = textTheme.labelSmall?.copyWith(
      color: colors.textSecondary,
      letterSpacing: 1.5,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('THE PATH', semanticsLabel: 'The path', style: labelStyle),
        const SizedBox(height: AppSpacing.s),
        ThirtyCard(
          padding: const EdgeInsets.all(AppSpacing.featuredCard),
          child: Column(
            children: [
              for (var i = 0; i < states.length; i++)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 2),
                          PlanStageNode(
                            state: states[i],
                            tone: tone,
                            size: _node,
                          ),
                          if (i < states.length - 1)
                            Expanded(
                              child: Container(
                                width: 1.5,
                                margin: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xs,
                                ),
                                color: colors.border,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: i < states.length - 1 ? AppSpacing.l : 0,
                          ),
                          child: MergeSemantics(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stage ${i + 1} · ${stateLabel(states[i])}',
                                  semanticsLabel:
                                      'Stage ${i + 1}, '
                                      '${stateLabel(states[i]).toLowerCase()}.',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: states[i] == PlanStageState.upcoming
                                        ? colors.textSecondary
                                        : colors.textPrimary,
                                  ),
                                ),
                                if (children case final content?) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  content[i],
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The Free path: structure and saved position only, then one calm offer.
class _FreePathPreview extends StatelessWidget {
  const _FreePathPreview({required this.planId, required this.states});

  final PlanId planId;
  final List<PlanStageState> states;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StageList(planId: planId, states: states, currentLabel: 'Saved here'),
        const SizedBox(height: AppSpacing.l),
        Text(
          'Each stage\'s guidance is part of THIRTY Premium.',
          style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.m),
        ThirtyButton(
          label: 'Become Premium',
          variant: ThirtyButtonVariant.secondary,
          onPressed: () => context.push('/premium'),
        ),
      ],
    );
  }
}
