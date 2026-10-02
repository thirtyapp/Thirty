import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../domain/plan_ids.dart';
import '../../domain/plan_state.dart';
import 'plan_identity.dart';

/// Where one stage stands in a Plan's current cycle.
///
/// "Closed" means the cursor moved past the stage when a Plan Circle was
/// closed — a recorded closure, never a claim that the activity was done.
enum PlanStageState { closed, current, upcoming }

/// Each stage's state for [progress], read straight from its forward
/// cursor. [showCurrent] is false for a Plan that was never started and
/// is not active, so no stage is presented as "up next" for it.
List<PlanStageState> planStageStates(
  PlanProgress progress, {
  required int stageCount,
  required bool showCurrent,
}) {
  final completed = progress.status == PlanCycleStatus.completed;
  return [
    for (var i = 0; i < stageCount; i++)
      if (completed || i < progress.forwardCursor)
        PlanStageState.closed
      else if (showCurrent && i == progress.forwardCursor)
        PlanStageState.current
      else
        PlanStageState.upcoming,
  ];
}

/// The spoken summary of [states].
String planProgressLabel(List<PlanStageState> states) {
  final total = states.length;
  final closed = states.where((s) => s == PlanStageState.closed).length;
  if (closed == total) {
    return 'Guided cycle finished. All $total stages closed.';
  }
  final current = states.indexOf(PlanStageState.current);
  if (current == -1 && closed == 0) return '$total stages. Not started.';
  final position = current == -1 ? closed + 1 : current + 1;
  return 'Stage $position of $total, $closed closed.';
}

/// One stage node. The three states differ in shape as well as colour:
/// closed is a filled dot, current a ring around a dot, upcoming an empty
/// ring.
class PlanStageNode extends StatelessWidget {
  const PlanStageNode({
    required this.state,
    required this.tone,
    this.size = 14,
    super.key,
  });

  final PlanStageState state;
  final PlanTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final stroke = size * 0.13;
    return SizedBox.square(
      dimension: size,
      child: switch (state) {
        PlanStageState.closed => DecoratedBox(
          decoration: BoxDecoration(shape: BoxShape.circle, color: tone.mark),
        ),
        PlanStageState.current => DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.surface,
            border: Border.all(color: tone.mark, width: stroke),
          ),
          child: Center(
            child: SizedBox.square(
              dimension: size * 0.4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tone.mark,
                ),
              ),
            ),
          ),
        ),
        PlanStageState.upcoming => DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.border, width: stroke),
          ),
        ),
      },
    );
  }
}

/// A Plan's five stages as a row of nodes joined by a hairline — calm
/// position, not a score. One spoken label for the whole row.
class PlanProgressDots extends StatelessWidget {
  const PlanProgressDots({
    required this.planId,
    required this.states,
    super.key,
  });

  final PlanId planId;
  final List<PlanStageState> states;

  static const _node = 14.0;
  static const _link = 14.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final tone = PlanIdentity.of(planId).toneFor(Theme.of(context).brightness);
    // Its own node, so the position is read (and found) as one phrase
    // rather than folded into the card's label.
    return Semantics(
      container: true,
      label: planProgressLabel(states),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < states.length; i++) ...[
              if (i > 0)
                Container(width: _link, height: 1.5, color: colors.border),
              PlanStageNode(state: states[i], tone: tone, size: _node),
            ],
          ],
        ),
      ),
    );
  }
}
