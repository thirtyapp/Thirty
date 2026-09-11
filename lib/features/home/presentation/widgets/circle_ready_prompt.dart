import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/branding/thirty_wordmark_view.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../../../core/widgets/thirty_progress_circle.dart';
import 'daily_intention_prompt.dart';

/// The Circle-first Home state shown before today's direction has been
/// chosen — Golden Home Batch, replacing the old immediate
/// [DailyIntentionPrompt] entry point with a closed Circle first.
///
/// This is deliberately *not* The First Breath (`circle_hero.dart`): no
/// ritual animation plays here, no wordmark appear/hold/fade, no Circle
/// release. It is a static frame — the closed Circle with THIRTY's
/// wordmark resting inside it, at rest — because no World exists yet to
/// open into: the assigned activity (and therefore the World The First
/// Breath reveals) doesn't exist until a direction is chosen. The First
/// Breath ritual itself is untouched and still plays, exactly as before,
/// the first time `CircleHero` mounts once an activity is assigned
/// (`home_page.dart`).
///
/// Tapping `Begin today's Circle` reveals the existing
/// [DailyIntentionPrompt] — the same three fixed options, the same
/// `chooseIntention()` call, unchanged — inline, via a cross-fade, rather
/// than a new route or modal. This is presentation-only: no
/// SharedPreferences key is written by this reveal, since which of the
/// two sub-states to show is fully determined by this widget's own
/// ephemeral state and needs no persistence — a returning-later user who
/// hasn't chosen a direction yet simply sees the closed Circle again and
/// taps through, which is the intended daily entry, not a regression.
class CircleReadyPrompt extends StatefulWidget {
  const CircleReadyPrompt({super.key});

  @override
  State<CircleReadyPrompt> createState() => _CircleReadyPromptState();
}

class _CircleReadyPromptState extends State<CircleReadyPrompt> {
  bool _showDirections = false;

  void _beginTodaysCircle() {
    setState(() => _showDirections = true);
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedSwitcher(
      duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      child: _showDirections
          ? const DailyIntentionPrompt(key: ValueKey('circleReady.directions'))
          : _ReadyCircle(
              key: const ValueKey('circleReady.cta'),
              onBegin: _beginTodaysCircle,
            ),
    );
  }
}

/// The closed-Circle-and-CTA half of [CircleReadyPrompt].
///
/// Sizing mirrors `circle_hero.dart`'s own Circle/wordmark fractions
/// (`_circleWidthFraction`, `_wordmarkWidthFraction`, etc.) so the Circle
/// does not visibly resize when this frame gives way to The First Breath
/// after a direction is chosen and `CircleHero` mounts — the two are
/// deliberately kept in visual lockstep even though they're separate
/// widgets with no shared base class.
class _ReadyCircle extends StatelessWidget {
  const _ReadyCircle({required this.onBegin, super.key});

  final VoidCallback onBegin;

  static const _circleWidthFraction = 0.88;
  static const _circleMinSize = 260.0;
  static const _circleMaxSize = 440.0;
  static const _circleStrokeWidth = 10.0;
  static const _wordmarkWidthFraction = 0.585;
  static const _textColumnWidthFraction = 0.85;
  static const _buttonWidthFraction = 0.70;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final safeMaxSize = math.max(
          _circleMinSize,
          math.min(_circleMaxSize, constraints.maxWidth - AppSpacing.page * 2),
        );
        final circleSize = (constraints.maxWidth * _circleWidthFraction)
            .clamp(_circleMinSize, safeMaxSize)
            .toDouble();
        final circleInteriorSize = circleSize - (_circleStrokeWidth * 2);
        final wordmarkWidth = circleInteriorSize * _wordmarkWidthFraction;
        final textMaxWidth = circleSize * _textColumnWidthFraction;
        final buttonWidth = textMaxWidth * _buttonWidthFraction;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.m,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Closed (progress 1.0), solid sage circle — the exact frame
              // The First Breath itself starts from in `circle_hero.dart`,
              // held statically rather than played. trackColor stays
              // transparent since a fully-closed progress circle already
              // paints its own full ring in progressColor; nothing is
              // there to see behind it.
              ThirtyProgressCircle(
                progress: 1.0,
                size: circleSize,
                strokeWidth: _circleStrokeWidth,
                trackColor: Colors.transparent,
                progressColor: colors.primary,
                semanticLabel: "Today's Circle",
                semanticValue: 'Not started yet.',
                child: SizedBox(
                  width: wordmarkWidth,
                  child: const ThirtyWordmarkView(),
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: buttonWidth),
                child: ThirtyButton(
                  label: "Begin today's Circle",
                  onPressed: onBegin,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
