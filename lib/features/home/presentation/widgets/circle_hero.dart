import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../../../core/widgets/thirty_progress_circle.dart';
import '../../application/first_breath_provider.dart';
import '../../application/recommendation_provider.dart';
import 'horizon_illustration.dart';

/// THIRTY's first true emotional experience: the Circle Hero.
///
/// The whole screen is one continuous ritual, not several independent
/// widget animations — Playbook Ch.2 §4 ("motion must mean something
/// before it may exist") and the brief's own instruction that this must
/// "feel like one sequence." A single [AnimationController] drives every
/// phase through [Interval]s on one timeline:
///
/// 1. Hold — yesterday's Circle sits fully closed, still, for ~700ms.
/// 2. The First Breath — the Circle releases from closed (1.0) to open
///    (0.0) over ~2200ms: one slow exhale, soft decelerating ease, no
///    bounce, no spring, no overshoot, no abrupt final stop.
/// 3+. Only once the Circle has finished opening: the illustration, then
///    four content groups fade in one at a time, never together — the
///    heading, the recommendation's intent, and finally its activity
///    together with its explanation (one semantic group, one animation,
///    since they belong to the same idea) — before the Start Circle
///    button. Each group is followed by its own still pause before the
///    next one begins, so every group has time to settle rather than
///    crowding the one before it. This is what makes the ritual read as
///    calm rather than as a sequence of UI animations.
///
/// The Circle is the screen's hero, not a decoration above a title: it is
/// sized to ~88% of the available width (capped so it's never clipped by
/// the page's own margins, and bounded for very small/large screens) — an
/// intentionally oversized product object the layout is built around, not a
/// widget sized to fit comfortably inside one. The composition is anchored
/// toward the top of the screen, not centered in the viewport, so the eye
/// meets the Circle first instead of settling in empty space above it. The
/// heading and recommendation share one readable text column, capped
/// narrower than the Circle itself, so they read as its caption rather than
/// stretching edge to edge; every text style in that column uses a smaller,
/// existing type-scale slot than the one before, so the reading order
/// (Circle → heading → recommendation → explanation → button) reads as a
/// caption under the Circle, never as a competing block beside it.
///
/// This ritual plays at most once per local calendar day (see
/// [firstBreathProvider]). On every later open the same day, the
/// [AnimationController] is set straight to its end value instead of
/// played — every [Interval]-derived animation below then resolves
/// directly to its final value with no visible motion, so the "already
/// played today" case reuses the exact same timeline definitions as the
/// "play it" case rather than branching the widget tree in two.
class CircleHero extends ConsumerStatefulWidget {
  const CircleHero({super.key});

  @override
  ConsumerState<CircleHero> createState() => _CircleHeroState();
}

class _CircleHeroState extends ConsumerState<CircleHero>
    with SingleTickerProviderStateMixin {
  static const _holdPhase = Duration(milliseconds: 700);
  static const _breathePhase = Duration(milliseconds: 2200);
  static const _illustrationPhase = Duration(milliseconds: 500);
  static const _headingPhase = Duration(milliseconds: 400);
  static const _intentPhase = Duration(milliseconds: 350);
  // Activity ("30 minute walk") and its explanation are one semantic
  // group, not two beats — they share this single phase/animation so they
  // always fade in together. Slightly longer than the other content
  // phases since it's carrying two lines.
  static const _activityWhyPhase = Duration(milliseconds: 450);
  static const _buttonPhase = Duration(milliseconds: 400);

  // Still, silent gaps inserted between reveals so each group has time to
  // settle before the next one appears, rather than the ritual reading as
  // one fade chasing the next. The button gets the longer pause — it's
  // the final beat, the one the user is asked to act on, so it earns a
  // touch more separation from the content before it.
  static const _pauseShort = Duration(milliseconds: 200);
  static const _pauseLong = Duration(milliseconds: 300);

  static const _totalDuration = Duration(
    milliseconds:
        700 + // _holdPhase
        2200 + // _breathePhase
        500 + // _illustrationPhase
        200 + // pause before heading
        400 + // _headingPhase
        200 + // pause before intent
        350 + // _intentPhase
        200 + // pause before activity + explanation
        450 + // _activityWhyPhase
        300 + // pause before button
        400, // _buttonPhase
  );

  // The Circle is sized off the available width, not a fixed constant, so
  // it stays the screen's dominant object on both small and large phones.
  // 88% is an intentionally oversized, near-edge-to-edge scale — this is
  // the product's hero object, not a widget sized to sit comfortably in a
  // grid. _circleMaxSize is a ceiling for large screens; the safe-width
  // check in build() is what actually guarantees the Circle is never
  // clipped, by capping it below the page's horizontal margins too.
  static const _circleWidthFraction = 0.88;
  static const _circleMinSize = 260.0;
  static const _circleMaxSize = 440.0;

  // The text column beneath the Circle reads as its caption, not as an
  // independent block — so its max width is derived from the Circle's own
  // size rather than from the screen, and stays narrower than the Circle.
  static const _textColumnWidthFraction = 0.85;

  late final AnimationController _controller;
  late final Animation<double> _circleProgress;
  late final Animation<double> _illustrationOpacity;
  late final Animation<double> _headingOpacity;
  late final Animation<double> _intentOpacity;
  late final Animation<double> _activityWhyOpacity;
  late final Animation<double> _buttonOpacity;

  @override
  void initState() {
    super.initState();

    // Read once: this ritual must not react to its own side effect of
    // marking itself played (see the `whenComplete` below).
    final shouldPlay = ref.read(firstBreathProvider);

    _controller = AnimationController(vsync: this, duration: _totalDuration);

    // Cumulative fractions of the total timeline, walked in playback order.
    // Pauses advance the clock without producing a boundary of their own —
    // they simply push the next element's start later — which is what
    // turns the gap between reveals into a still beat instead of empty
    // time inside an Interval that's already animating. The final
    // boundary is guaranteed to be exactly 1.0 (a value divided by
    // itself), so the last Interval never overshoots the [0, 1] range
    // Interval requires.
    final totalMs = _totalDuration.inMilliseconds;
    var elapsedMs = 0;
    double advance(Duration phase) {
      elapsedMs += phase.inMilliseconds;
      return elapsedMs / totalMs;
    }

    final holdEnd = advance(_holdPhase);
    final breatheEnd = advance(_breathePhase);
    final illustrationEnd = advance(_illustrationPhase);
    final headingStart = advance(_pauseShort);
    final headingEnd = advance(_headingPhase);
    final intentStart = advance(_pauseShort);
    final intentEnd = advance(_intentPhase);
    final activityWhyStart = advance(_pauseShort);
    final activityWhyEnd = advance(_activityWhyPhase);
    final buttonStart = advance(_pauseLong);
    final buttonEnd = advance(_buttonPhase);

    // The Circle releases from closed (1.0) to open (0.0) — the inverse of
    // a normal fill — because this ritual is yesterday's complete Circle
    // giving way to today's empty one (Playbook Ch.1 §8, "The Philosophy
    // of Starting Again"). Soft, decelerating ease; no bounce, no
    // elastic, no overshoot.
    _circleProgress = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(holdEnd, breatheEnd, curve: Curves.easeOutCubic),
      ),
    );

    _illustrationOpacity = CurvedAnimation(
      parent: _controller,
      curve: Interval(breatheEnd, illustrationEnd, curve: Curves.easeOut),
    );
    _headingOpacity = CurvedAnimation(
      parent: _controller,
      curve: Interval(headingStart, headingEnd, curve: Curves.easeOut),
    );
    _intentOpacity = CurvedAnimation(
      parent: _controller,
      curve: Interval(intentStart, intentEnd, curve: Curves.easeOut),
    );
    _activityWhyOpacity = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        activityWhyStart,
        activityWhyEnd,
        curve: Curves.easeOut,
      ),
    );
    _buttonOpacity = CurvedAnimation(
      parent: _controller,
      curve: Interval(buttonStart, buttonEnd, curve: Curves.easeOut),
    );

    if (shouldPlay) {
      _controller.forward().whenComplete(() {
        if (!mounted) return;
        ref.read(firstBreathProvider.notifier).markPlayedToday();
      });
    } else {
      // Already played today: land on the fully-settled end state with no
      // visible motion, rather than replaying the ritual.
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final recommendationState = ref.watch(recommendationProvider);
    final recommendation = recommendationState.recommendation;
    final isStarted =
        recommendationState.status == RecommendationStatus.started;

    return LayoutBuilder(
      builder: (context, constraints) {
        // The Circle must never be clipped: cap it below the width that's
        // actually left after the page's horizontal margins, regardless of
        // how large `_circleMaxSize` allows it to be on a wide screen.
        final safeMaxSize = math.max(
          _circleMinSize,
          math.min(_circleMaxSize, constraints.maxWidth - AppSpacing.page * 2),
        );
        final circleSize = (constraints.maxWidth * _circleWidthFraction)
            .clamp(_circleMinSize, safeMaxSize)
            .toDouble();
        final textMaxWidth = circleSize * _textColumnWidthFraction;

        return SingleChildScrollView(
          // SingleChildScrollView gives its child loose (not full-width)
          // horizontal constraints, so without this the Column below would
          // shrink-wrap to its widest child (the Circle) and the whole
          // block would render flush against the left edge of the screen
          // instead of centered — this SizedBox forces it back to the full
          // available width so the Column's own horizontal centering
          // (crossAxisAlignment.center, its default) actually has the full
          // width to center within. This affects only the horizontal axis;
          // it does not reintroduce the vertical viewport-centering that
          // was deliberately removed below.
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              // Anchored toward the top, not centered in the viewport: a
              // centered composition leaves equal empty space above and
              // below, which is exactly what makes the Circle read as
              // floating mid-page rather than defining the top of the
              // screen. Top spacing is deliberately small — SafeArea (in
              // HomePage) already keeps the Circle clear of the status bar
              // — and any leftover space on a short screen lands below the
              // button instead of being split above the Circle too.
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.m,
                AppSpacing.page,
                AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _circleProgress,
                    builder: (context, child) {
                      return ThirtyProgressCircle(
                        progress: _circleProgress.value,
                        size: circleSize,
                        semanticLabel: "Today's Circle",
                        // Today's Circle is always announced as open and
                        // ready here, never as a percentage — an empty
                        // Circle is potential, never a shortfall
                        // (Playbook Ch.2 §3). "0%" would frame it as the
                        // opposite of what it means.
                        semanticValue: 'Ready to begin.',
                        child: child,
                      );
                    },
                    child: FadeTransition(
                      opacity: _illustrationOpacity,
                      child: const ExcludeSemantics(
                        child: HorizonIllustration(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  // The heading and the recommendation share one readable
                  // column beneath the Circle — capped narrower than the
                  // Circle itself so the activity title and description
                  // never stretch wider than the object they're captioning.
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: textMaxWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeTransition(
                          opacity: _headingOpacity,
                          child: Text(
                            "Today's Circle",
                            style: textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.l),
                        // Intent fades in as its own beat; activity and its
                        // explanation are one semantic group and always
                        // fade in together under a single animation.
                        FadeTransition(
                          opacity: _intentOpacity,
                          child: Text(
                            recommendation.intent,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        FadeTransition(
                          opacity: _activityWhyOpacity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                recommendation.activity,
                                style: textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.s),
                              Text(
                                recommendation.why,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  FadeTransition(
                    opacity: _buttonOpacity,
                    child: ThirtyButton(
                      label: isStarted ? 'Circle started' : 'Start Circle',
                      onPressed: isStarted
                          ? null
                          : () => ref
                                .read(recommendationProvider.notifier)
                                .start(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
