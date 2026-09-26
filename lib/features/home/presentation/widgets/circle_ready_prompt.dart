import 'package:flutter/material.dart';

import '../../../../core/branding/thirty_wordmark_view.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import 'daily_intention_prompt.dart';
import 'home_circle_metrics.dart';

/// The Circle-first Home state shown before today's direction has been
/// chosen — Golden Home Batch.
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
/// **Continuity correction:** physical verification of 1.7.0+13 found that
/// tapping `Begin today's Circle` made the entire Circle composition
/// disappear behind full-screen direction cards, then made it reappear once
/// a direction was chosen — a visible layout jump the founder rejected. The
/// Circle (and its wordmark) is now built exactly once, directly in this
/// widget's own [build], as a permanent sibling above the switching
/// content below it; only that content — the `Begin today's Circle` CTA
/// versus the existing [DailyIntentionPrompt] question — cross-fades via
/// [AnimatedSwitcher]. The Circle itself is never inside that switcher's
/// subtree, so it is never rebuilt, removed, or reinserted by this
/// transition; both the Circle's sizing and this shell's own outer padding
/// come from [HomeCircleMetrics], shared with `circle_hero.dart`, so the
/// Circle also does not visibly move or resize when this whole composition
/// later gives way to The First Breath once `CircleHero` mounts.
///
/// Tapping `Begin today's Circle` reveals the existing
/// [DailyIntentionPrompt] — the same three fixed options, the same
/// `chooseIntention()` call, unchanged — inline, beneath the still-mounted
/// Circle, rather than a new route or modal. This is presentation-only: no
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
    final colors = Theme.of(context).extension<AppColors>()!;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = HomeCircleMetrics.forWidth(constraints.maxWidth);

        return SingleChildScrollView(
          padding: HomeCircleMetrics.padding,
          // SingleChildScrollView gives its child loose (not full-width)
          // horizontal constraints, so without this the Column below would
          // shrink-wrap to its widest child (the Circle) and sit flush at
          // the scrollable area's leading edge instead of centered — on a
          // narrow phone this is nearly invisible (the Circle already
          // fills almost the whole width), but on a wide screen it visibly
          // does not line up with `circle_hero.dart`'s own centered
          // Circle, breaking this widget's whole reason for existing. This
          // mirrors `circle_hero.dart`'s own identical `SizedBox` for the
          // identical reason — see that file's matching comment.
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Closed (progress 1.0), solid sage circle — the exact
                // frame The First Breath itself starts from in
                // `circle_hero.dart`, held statically rather than played.
                // trackColor stays transparent since a fully-closed
                // progress circle already paints its own full ring in
                // progressColor; nothing is there to see behind it.
                // Mounted once, outside the AnimatedSwitcher below — see
                // this class's doc comment.
                HomeCircle(
                  metrics: metrics,
                  progress: 1.0,
                  trackColor: Colors.transparent,
                  progressColor: colors.primary,
                  semanticValue: 'Not started yet.',
                  // A closed Circle has no leading end to mark.
                  showThumb: false,
                  child: SizedBox(
                    width: metrics.wordmarkWidth,
                    child: const ThirtyWordmarkView(),
                  ),
                ),
                const SizedBox(height: HomeCircleMetrics.circleToContentGap),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: metrics.textMaxWidth),
                  child: AnimatedSwitcher(
                    duration: reducedMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeOut,
                    child: _showDirections
                        ? const DailyIntentionPrompt(
                            key: ValueKey('circleReady.directions'),
                          )
                        : Center(
                            key: const ValueKey('circleReady.cta'),
                            // Phase B2: fills the bounded content column,
                            // the same width as Circle Hero's CTA.
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: metrics.textMaxWidth,
                              ),
                              // Presentation-only — no trailing arrow; the
                              // arrow belongs to Start Circle, the actual
                              // lifecycle transition (Phase B decision).
                              child: ThirtyButton(
                                label: "Begin today's Circle",
                                size: ThirtyButtonSize.hero,
                                onPressed: _beginTodaysCircle,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
