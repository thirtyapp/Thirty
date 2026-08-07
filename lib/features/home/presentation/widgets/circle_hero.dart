import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/activity_category.dart';
import '../../../../core/branding/thirty_wordmark_view.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../../../core/widgets/thirty_progress_circle.dart';
import '../../../../core/world_rendering/quiet_trail_hero_asset_view.dart';
import '../../application/first_breath_provider.dart';
import '../../application/recommendation_provider.dart';

/// THIRTY's first true emotional experience: the Circle Hero.
///
/// The whole screen is one continuous ritual, not several independent
/// widget animations — Playbook Ch.2 §4 ("motion must mean something
/// before it may exist") and the brief's own instruction that this must
/// "feel like one sequence." A single [AnimationController] drives every
/// phase through [Interval]s (and, for the wordmark's non-monotonic
/// appear-hold-fade shape, a [TweenSequence]) on one timeline:
///
/// 1. The wordmark — the closed Circle is already present and still. The
///    THIRTY wordmark fades in (300ms), holds fully visible and
///    motionless (700ms), then fades fully out (300ms). Opacity only: no
///    scale, no translation, no heartbeat
///    (`docs/brand/THIRTY_WORDMARK.md` §4 — "The Circle is not the logo.
///    The Circle is the product.").
/// 2. The First Breath — only once the wordmark has fully faded out (its
///    own opacity is exactly 0), the Circle releases from closed (1.0) to
///    open (0.0) over 2200ms: one slow exhale, soft decelerating ease, no
///    bounce, no spring, no overshoot, no abrupt final stop. There is no
///    frame in which the wordmark still has any opacity and the Circle
///    already has progress.
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
/// stretching edge to edge; within that column, activity — the concrete
/// recommendation — carries the most visual weight, "Today's Circle" is
/// reduced to a small eyebrow above it, and intent/why stay quieter still,
/// so the column reads as one composed daily moment under the Circle rather
/// than a heading followed by decreasing captions. The wordmark that
/// appears inside the Circle before it opens is sized off
/// that same interior region (`circleSize - strokeWidth * 2`), never off
/// the Circle's outer size — a small mark resting inside a large, unchanged
/// space, exactly as the World illustration that later occupies the same
/// region already is.
///
/// This ritual plays at most once per local calendar day (see
/// [firstBreathProvider]), and never plays with visible motion when the
/// platform/user has requested reduced motion
/// ([MediaQuery.disableAnimationsOf]). In either case the
/// [AnimationController] is set straight to its end value instead of
/// played — every [Interval]/[TweenSequence]-derived animation below then
/// resolves directly to its final value (Circle open, wordmark invisible,
/// all content settled) with no visible motion, so both the "already
/// played today" case and the "reduced motion" case reuse the exact same
/// timeline definitions as the "play it" case rather than branching the
/// widget tree in two. Reduced motion still marks the ritual played for
/// today on the first open of the day — it removes movement and waiting,
/// never meaning or access (`docs/motion/MOTION_LANGUAGE.md` §11).
class CircleHero extends ConsumerStatefulWidget {
  const CircleHero({super.key});

  @override
  ConsumerState<CircleHero> createState() => _CircleHeroState();
}

class _CircleHeroState extends ConsumerState<CircleHero>
    with SingleTickerProviderStateMixin {
  // The wordmark's own appear-hold-fade beat, played before the Circle
  // begins to open (docs/brand/THIRTY_WORDMARK.md §4, §12 — First Breath
  // v2). Opacity only; no scale, translate, or heartbeat.
  static const _wordmarkFadeInPhase = Duration(milliseconds: 300);
  static const _wordmarkHoldPhase = Duration(milliseconds: 700);
  static const _wordmarkFadeOutPhase = Duration(milliseconds: 300);

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
        300 + // _wordmarkFadeInPhase
        700 + // _wordmarkHoldPhase
        300 + // _wordmarkFadeOutPhase
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

  // The one source of truth for the Home Circle's ring thickness — passed
  // explicitly to [ThirtyProgressCircle] below rather than left to its
  // default, because the illustration's and wordmark's inset sizes
  // (build()) are both derived from this same value. Relying on the
  // default in one place while duplicating the number elsewhere would let
  // them silently drift apart.
  static const _circleStrokeWidth = 10.0;

  // The wordmark's own width, as a fraction of the Circle's usable
  // interior (`circleSize - strokeWidth * 2`) — reproduces the visually
  // validated scale matrix from `docs/brand/THIRTY_WORDMARK.md` §6 (236px
  // interior → ~138px wordmark, 416px interior → ~243px wordmark).
  // [ThirtyWordmarkView] guards its own aspect ratio internally, so only
  // the width needs to be given here.
  static const _wordmarkWidthFraction = 0.585;

  // The text column beneath the Circle reads as its caption, not as an
  // independent block — so its max width is derived from the Circle's own
  // size rather than from the screen, and stays narrower than the Circle.
  static const _textColumnWidthFraction = 0.85;

  // The CTA is a bound compositional choice for this one screen, not a
  // property of ThirtyButton itself: deliberately narrower than the text
  // column above it (intermediate/intentional width) — wider than
  // content-sized so it reads as the recommendation's compositional
  // close, but clearly short of the column's own width so it never
  // becomes a banner competing with the Circle.
  static const _buttonWidthFraction = 0.70;

  late final AnimationController _controller;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<double> _circleProgress;
  late final Animation<double> _illustrationOpacity;
  late final Animation<double> _headingOpacity;
  late final Animation<double> _intentOpacity;
  late final Animation<double> _activityWhyOpacity;
  late final Animation<double> _buttonOpacity;

  // Guards the play-vs-skip decision (and the MediaQuery read it needs) so
  // it runs exactly once per widget lifetime, not again on a later,
  // unrelated dependency change (e.g. a theme change) while the ritual is
  // already under way or already settled.
  bool _ritualStarted = false;

  @override
  void initState() {
    super.initState();

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

    // The wordmark's own three sub-boundaries are expressed as
    // TweenSequence weights below, not as Intervals, so only their
    // cumulative effect on the shared clock (elapsedMs) is needed here —
    // advance() is still called for each phase, in order, so
    // wordmarkFadeOutEnd (used by _circleProgress below) lands on the
    // correct fraction.
    advance(_wordmarkFadeInPhase);
    advance(_wordmarkHoldPhase);
    final wordmarkFadeOutEnd = advance(_wordmarkFadeOutPhase);
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

    // The wordmark's appear-hold-fade shape is not monotonic (up, then
    // flat, then down), so a single Interval can't express it — a
    // TweenSequence can. Its items are weighted in the same milliseconds
    // as the phases above, so its internal boundaries use the same
    // wordmarkFadeInEnd/wordmarkHoldEnd/wordmarkFadeOutEnd fractions as
    // below, to floating-point precision. The trailing ConstantTween(0.0)
    // covers the rest of the timeline, so opacity is 0 for the whole time
    // the Circle is opening and afterwards — no frame renders the
    // wordmark visible while the Circle already has progress
    // (docs/brand/THIRTY_WORDMARK.md §4).
    _wordmarkOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: _wordmarkFadeInPhase.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: _wordmarkHoldPhase.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: _wordmarkFadeOutPhase.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight:
            (totalMs -
                    _wordmarkFadeInPhase.inMilliseconds -
                    _wordmarkHoldPhase.inMilliseconds -
                    _wordmarkFadeOutPhase.inMilliseconds)
                .toDouble(),
      ),
    ]).animate(_controller);

    // The Circle releases from closed (1.0) to open (0.0) — the inverse of
    // a normal fill — because this ritual is yesterday's complete Circle
    // giving way to today's empty one (Playbook Ch.1 §8, "The Philosophy
    // of Starting Again"). Soft, decelerating ease; no bounce, no
    // elastic, no overshoot. Starts at wordmarkFadeOutEnd — the same
    // timeline boundary _wordmarkOpacity's fade-out segment ends on, to
    // floating-point precision — so the Circle never begins opening while
    // the wordmark still has any opacity.
    _circleProgress = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          wordmarkFadeOutEnd,
          breatheEnd,
          curve: Curves.easeOutCubic,
        ),
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
      curve: Interval(activityWhyStart, activityWhyEnd, curve: Curves.easeOut),
    );
    _buttonOpacity = CurvedAnimation(
      parent: _controller,
      curve: Interval(buttonStart, buttonEnd, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Runs exactly once: the play-vs-skip decision (and the MediaQuery
    // read it depends on) must not repeat on a later, unrelated
    // dependency change while the ritual is already playing or settled.
    if (_ritualStarted) return;
    _ritualStarted = true;

    // Read once: this ritual must not react to its own side effect of
    // marking itself played (see the `whenComplete`/direct call below).
    final shouldPlay = ref.read(firstBreathProvider);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    if (shouldPlay && !reducedMotion) {
      _controller.forward().whenComplete(() {
        if (!mounted) return;
        ref.read(firstBreathProvider.notifier).markPlayedToday();
      });
    } else {
      // Already played today, or reduced motion is requested: land on the
      // fully-settled end state with no visible motion, rather than
      // playing (any part of) the ritual. Reduced motion still preserves
      // every step's meaning — the wordmark still "happened", the Circle
      // is still open, content is still present — only the movement and
      // the wait are removed (docs/motion/MOTION_LANGUAGE.md §11). If
      // this is the first open of the day, the ritual is still marked
      // played even though nothing visibly animated.
      _controller.value = 1.0;
      if (shouldPlay) {
        ref.read(firstBreathProvider.notifier).markPlayedToday();
      }
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

    // The recommendation column's three text moments read as one composed
    // block, not three independent widgets. "Why" and activity need no
    // entry here: bodyMedium and titleMedium already are their targets
    // (see their call sites below). Intent alone carries this screen's one
    // editorial-serif moment (AppTypography.editorialDisplay) — see that
    // method's own doc comment for why the role, not this content, owns
    // the name.
    final eyebrowStyle = textTheme.labelLarge?.copyWith(
      fontSize: 13,
      height: 1.25,
      letterSpacing: 0.5,
    );
    final intentStyle = AppTypography.editorialDisplay(colors);

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
        final buttonWidth = textMaxWidth * _buttonWidthFraction;
        // Inset so the illustration's circular edge sits at the ring's
        // inner edge, never under the stroke itself — the ring keeps
        // painting after the illustration (ThirtyProgressCircle's Stack
        // order is unchanged), so staying inside its inner boundary is
        // what keeps the two from visually overlapping. The wordmark
        // shares this same interior region, never the Circle's outer size.
        final circleInteriorSize = circleSize - (_circleStrokeWidth * 2);
        final illustrationSize = circleInteriorSize;
        final wordmarkWidth = circleInteriorSize * _wordmarkWidthFraction;

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
                        strokeWidth: _circleStrokeWidth,
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
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // The wordmark is decorative only
                        // (ThirtyWordmarkView already wraps itself in
                        // ExcludeSemantics) — the Circle above is the
                        // ritual's only semantics owner.
                        FadeTransition(
                          opacity: _wordmarkOpacity,
                          child: SizedBox(
                            width: wordmarkWidth,
                            child: const ThirtyWordmarkView(),
                          ),
                        ),
                        FadeTransition(
                          opacity: _illustrationOpacity,
                          child: ExcludeSemantics(
                            child: _worldIllustrationFor(
                              recommendation.category,
                              illustrationSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
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
                            style: eyebrowStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        // Intent fades in as its own beat; activity and its
                        // explanation are one semantic group and always
                        // fade in together under a single animation.
                        FadeTransition(
                          opacity: _intentOpacity,
                          child: Text(
                            recommendation.intent,
                            style: intentStyle,
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
                  // FadeTransition alone only controls painting and
                  // semantics inclusion — it never gates hit-testing, so
                  // without this wrapper the button could already be
                  // tapped mid-reveal, before the ritual has actually
                  // offered it. IgnorePointer is rebuilt from
                  // _buttonOpacity's own value on every animation tick
                  // (AnimatedBuilder), so it tracks the existing reveal
                  // exactly rather than a second, separately-timed guess
                  // at when the button is "ready." The button subtree is
                  // supplied as `child` so it isn't rebuilt every frame.
                  AnimatedBuilder(
                    animation: _buttonOpacity,
                    builder: (context, child) {
                      return IgnorePointer(
                        ignoring: _buttonOpacity.value < 1.0,
                        child: child,
                      );
                    },
                    child: FadeTransition(
                      opacity: _buttonOpacity,
                      // minWidth, not a fixed width: at the smallest
                      // screens the intentional 0.70 width is narrower
                      // than "Start Circle"/"Circle started" need, which
                      // overflows under a fixed SizedBox — minWidth keeps
                      // the intentional width whenever content fits it,
                      // and only yields to the label when it doesn't.
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: buttonWidth),
                        child: ThirtyButton(
                          label: isStarted ? 'Circle started' : 'Start Circle',
                          // A single, soft haptic confirms the one moment
                          // THIRTY's product principles reserve it for —
                          // "a decision has been made" (Playbook Ch.2 §5)
                          // — fired here, not inside ThirtyButton or
                          // RecommendationNotifier, so it stays tied to
                          // this exact physical Start Circle tap: it can
                          // only ever fire once per valid press (onPressed
                          // is already null while disabled/already
                          // started/still gated by First Breath's
                          // IgnorePointer above), never on a rebuild, a
                          // state restore, or a future unrelated button.
                          onPressed: isStarted
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  ref
                                      .read(recommendationProvider.notifier)
                                      .start();
                                },
                        ),
                      ),
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

/// The approved World illustration for [category], sized to fill [size] ×
/// [size] — the one place `circle_hero.dart` maps a recommendation's
/// [ActivityCategory] to a World's illustration widget.
///
/// An exhaustive switch, not a registry: [ActivityCategory] has exactly
/// one shipped value today (WORLD_SYSTEM.md §16 names every other category
/// only as a placeholder), so this stays the smallest mapping that
/// compiles safely — a future category left unhandled here fails to
/// compile instead of silently falling through to the wrong illustration.
Widget _worldIllustrationFor(ActivityCategory category, double size) {
  return switch (category) {
    ActivityCategory.walking => SizedBox(
      width: size,
      height: size,
      child: const QuietTrailHeroAssetView(),
    ),
  };
}
