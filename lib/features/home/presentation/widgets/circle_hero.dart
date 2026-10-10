import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/branding/thirty_brand_lockup.dart';
import '../../../../core/providers/clock_provider.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../../../core/widgets/thirty_confirm_dialog.dart';
import '../../../../core/world_rendering/world_hero_art_view.dart';
import '../../../settings/application/first_name_provider.dart';
import '../../application/activity_catalog.dart';
import '../../application/first_breath_provider.dart';
import '../../application/recommendation_provider.dart';
import '../../application/world_scene_resolution.dart';
import '../../domain/circle_session.dart';
import 'activity_guide_sheet.dart';
import 'circle_reflection_card.dart';
import 'circle_session_card.dart';
import 'not_this_one_sheet.dart';
import 'home_circle_metrics.dart';
import 'home_rhythm_column.dart';
import 'today_card.dart';

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
  const CircleHero({
    this.footer = const [],
    this.header,
    this.topInset = 0,
    super.key,
  });

  /// Laid over the top of the scroll content (Home's header row), so it
  /// scrolls away with the Circle instead of being pinned over it.
  final Widget? header;

  /// Extra room above the Circle, inside the scroll view — so the space
  /// the Circle's halo shadow falls into scrolls with it and is never cut
  /// off by the scroll view's top edge.
  final double topInset;

  /// Home content that follows the hero in the same scroll (Phase B3):
  /// reflection, Plan session, reminder / Premium invitations. Each item
  /// owns its own padding and visibility; the hero never resizes for them.
  final List<Widget> footer;

  /// V2 Phase C: a closed Circle's heading pair — a calm close that claims
  /// nothing about the activity.
  static const closedHeading = 'Your Circle for today.';

  /// How long after the natural end its announcement waits — enough for
  /// TalkBack to have spoken the focus move to Close first.
  static const naturalEndAnnouncementDelay = Duration(milliseconds: 900);
  static const closedDetail = 'Your next Circle opens tomorrow.';

  @override
  ConsumerState<CircleHero> createState() => _CircleHeroState();
}

class _CircleHeroState extends ConsumerState<CircleHero>
    with TickerProviderStateMixin {
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

  // Circle sizing, stroke width and outer padding live in
  // HomeCircleMetrics (home_circle_metrics.dart), shared with
  // circle_ready_prompt.dart so the Circle never jumps across the daily
  // flow.

  late final AnimationController _controller;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<double> _circleProgress;
  late final Animation<double> _nearFitTrimProgress;
  late final Animation<double> _illustrationOpacity;
  late final Animation<double> _headingOpacity;
  late final Animation<double> _intentOpacity;
  late final Animation<double> _activityWhyOpacity;
  late final Animation<double> _buttonOpacity;

  // The ring is a real timer (Phase D1). V2 Phase A: it runs to the
  // offered activity's natural length — today's offer, within the time the
  // user said they have ([circleDurationFor]) — never a fixed
  // half hour. While today's Circle is started, the sage arc shows the time
  // since Start Circle, full at that length; once closed it keeps the time
  // the Circle actually ran. A once-a-second ticker repaints it while
  // started — slow enough that reduced motion needs no special case.
  static Duration circleDurationFor(Recommendation recommendation) =>
      Duration(minutes: recommendation.offeredMinutes);
  Timer? _ticker;
  RecommendationStatus? _tickerStatus;

  // V2 Phase C — the natural end's quiet beat (ADR-021): when the time set
  // aside is reached while the user is here, the World warms over a moment
  // and TalkBack hears it once. Seen on arrival instead — a restore, a
  // return from the background — it is simply there, never replayed.
  static const _endBeatDuration = Duration(milliseconds: 1600);
  late final AnimationController _endBeat;
  bool? _endSeen;

  // Out of sight, nothing is seen: the next look after the app comes back
  // only records where things stand, whatever frame the resume lands on.
  late final _OutOfSight _sightObserver = _OutOfSight(() {
    _endSeen = null;
    _closeLed = null;
  });

  // When Close takes the lead mid-session — the time is reached, or Guided
  // reaches "To finish" — the step controls TalkBack may be on are gone:
  // focus goes to Close, the one thing left to do, instead of falling to
  // the top of the page.
  final _closeFocus = FocusNode(skipTraversal: true);
  Timer? _endAnnouncement;
  bool? _closeLed;

  // Guards the play-vs-skip decision (and the MediaQuery read it needs) so
  // it runs exactly once per widget lifetime, not again on a later,
  // unrelated dependency change (e.g. a theme change) while the ritual is
  // already under way or already settled.
  bool _ritualStarted = false;

  // Today's World artwork, shared by the Circle and the Today card: one
  // snapshot, so the two can never disagree. It is held through First
  // Breath — a re-resolution arriving mid-ritual (a resume across a
  // Daypart boundary) waits in [_pendingArt] until the ritual has settled
  // (WORLD_SYSTEM.md §10, "Stability").
  late ResolvedWorldArt _art;
  ResolvedWorldArt? _pendingArt;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: _totalDuration);
    _endBeat = AnimationController(vsync: this, duration: _endBeatDuration);
    WidgetsBinding.instance.addObserver(_sightObserver);

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

    // The near-fit Circle trim (if any) follows the Circle's opening: none
    // while it is still Ready's closed Circle, all of it once open.
    _nearFitTrimProgress = ReverseAnimation(_circleProgress);

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

  /// Starts/stops  }

  /// Runs the once-a-second repaint only while today's Circle is started.
  void _syncTicker(RecommendationStatus status) {
    if (status == _tickerStatus) return;
    _tickerStatus = status;
    _ticker?.cancel();
    _ticker = status == RecommendationStatus.started
        ? Timer.periodic(const Duration(seconds: 1), (_) {
            if (mounted) setState(() {});
          })
        : null;
  }

  /// The share of the time set aside that today's Circle has run — its
  /// active time (pauses set aside), until now while started, until Close
  /// once closed.
  double _timerProgress(Duration elapsed, Duration offered) =>
      offered <= Duration.zero
      ? 0
      : (elapsed.inMilliseconds / offered.inMilliseconds).clamp(0.0, 1.0);

  /// Moves focus to Close the moment it takes the lead in a running Circle
  /// seen live — never on a first look, a return or a restart.
  void _noticeCloseLead(bool leads, {required bool running}) {
    final before = _closeLed;
    _closeLed = leads;
    if (before != false || !leads || !running) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _closeFocus.requestFocus();
    });
  }

  /// Notices the natural end. The first look only records where things
  /// stand; a crossing seen live plays the beat and is announced once.
  void _noticeNaturalEnd(bool ended, {required bool running}) {
    final seen = _endSeen;
    if (seen == null) {
      _endSeen = ended;
      _endBeat.value = ended ? 1 : 0;
      return;
    }
    if (!ended || seen) return;
    _endSeen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Unknown (before any lifecycle event) counts as here.
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      final foreground =
          lifecycle == null || lifecycle == AppLifecycleState.resumed;
      if (foreground && !MediaQuery.disableAnimationsOf(context)) {
        _endBeat.forward(from: 0);
      } else {
        _endBeat.value = 1;
      }
      final recommendation = ref.read(recommendationProvider).recommendation;
      if (foreground && running && recommendation != null) {
        // Close — the one thing left — takes focus now (whatever step
        // control TalkBack was on may be gone), and the end is spoken just
        // after it: on the S25 an announcement sent in the same frame was
        // cut off by TalkBack's reaction to the changed screen.
        _closeFocus.requestFocus();
        final view = View.of(context);
        final direction = Directionality.of(context);
        final message = SessionCopy.naturalEndAnnouncement(
          recommendation.offeredMinutes,
          recommendation.sessionDefinition.ending,
        );
        _endAnnouncement?.cancel();
        _endAnnouncement = Timer(CircleHero.naturalEndAnnouncementDelay, () {
          if (mounted) {
            SemanticsService.sendAnnouncement(view, message, direction);
          }
        });
      }
    });
  }

  /// Batch 1, Phase B — the irreversible Close Circle confirmation.
  ///
  /// Closing today's Circle cannot be undone until the next daily reset
  /// (`recommendation_provider.dart`'s local-calendar-day scoping), and
  /// testers had no warning before that transition — this dialog is the
  /// fix. `showDialog`'s own modal barrier already blocks a second tap on
  /// the Close Circle button underneath while it is open, and
  /// [RecommendationNotifier.close] is already a no-op outside
  /// [RecommendationStatus.started] — together those make a double-confirm
  /// or a race between two taps impossible to turn into an inconsistent
  /// state.
  ///
  /// Tapping outside the dialog or the system back button resolves exactly
  /// like tapping "Keep Circle open": `showDialog` pops `null`, not `true`,
  /// so only an explicit "Close Circle" tap inside the dialog ever proceeds
  /// to [RecommendationNotifier.close] — an accidental dismiss can never
  /// silently close the Circle.
  Future<void> _confirmCloseCircle(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierLabel: 'Keep Circle open',
      builder: (_) => const ThirtyConfirmDialog(
        title: "Close today's Circle?",
        body: "You won't be able to reopen it until tomorrow.",
        cancelLabel: 'Keep Circle open',
        confirmLabel: 'Close Circle',
        destructive: true,
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    ref.read(recommendationProvider.notifier).close();
    // Circle Closed — the second of the two moments THIRTY spends a haptic
    // on (MOTION_LANGUAGE.md §10): soft, once, for the Circle's ending —
    // never for the activity, which Close does not claim.
    HapticFeedback.lightImpact();
    SemanticsService.sendAnnouncement(
      View.of(this.context),
      'Circle closed.',
      Directionality.of(this.context),
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

    _art = ref.read(resolvedWorldArtProvider)!;

    // Read once: this ritual must not react to its own side effect of
    // marking itself played (see the `whenComplete`/direct call below).
    final shouldPlay = ref.read(firstBreathProvider);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    if (shouldPlay && !reducedMotion) {
      _controller.forward().whenComplete(() {
        if (!mounted) return;
        if (_pendingArt case final pending?) {
          setState(() => _art = pending);
          _pendingArt = null;
        }
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
    _endBeat.dispose();
    WidgetsBinding.instance.removeObserver(_sightObserver);
    _closeFocus.dispose();
    _endAnnouncement?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  /// "Not this one today": asks why, then replaces today's Circle once.
  Future<void> _notThisOne(Recommendation recommendation) async {
    final reason = await showNotThisOneSheet(
      context,
      current: recommendation.activityId,
      outdoor:
          recommendation.sessionDefinition.setting == ActivitySetting.outdoor,
    );
    if (reason == null || !mounted) return;
    final replaced = ref
        .read(recommendationProvider.notifier)
        .replaceToday(reason);
    if (!replaced && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing else fits today — this stays.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final recommendationState = ref.watch(recommendationProvider);
    // Non-null by construction: `HomePage` only ever mounts CircleHero once
    // recommendationState.recommendation is non-null (home_page.dart), and
    // it can only become null again by this widget being unmounted first
    // (a new local day resets to no-recommendation — see
    // recommendation_provider.dart), never while CircleHero itself is still
    // on screen.
    final recommendation = recommendationState.recommendation!;

    ref.listen(resolvedWorldArtProvider, (_, next) {
      if (next == null || next == _art) return;
      if (_controller.isAnimating) {
        _pendingArt = next;
      } else {
        setState(() => _art = next);
      }
    });
    // A later re-resolution while Home is present crossfades, never cuts
    // (WORLD_SYSTEM.md §10); reduced motion swaps without movement.
    final artSwitchDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _illustrationPhase;

    _syncTicker(recommendationState.status);
    final status = recommendationState.status;
    // V2 Phase D: a routine or a joined Path step runs its pieces on the
    // same Guided runtime; a single activity runs as authored.
    final activity = recommendation.sessionDefinition;
    final offered = circleDurationFor(recommendation);
    final elapsed = recommendationState.activeElapsedAt(
      ref.read(eventClockProvider)(),
    );
    final timerProgress = _timerProgress(elapsed, offered);
    final ended =
        status != RecommendationStatus.notStarted &&
        naturalEndReached(elapsed, offered);
    _noticeNaturalEnd(ended, running: status == RecommendationStatus.started);
    final paused = recommendationState.isPaused;
    final body = sessionBodyFor(activity, activity.pace);
    // One filled action at a time: Start before the Circle; while it runs,
    // Close stays quiet — the session's own action leads — until the time
    // set aside is reached or a Guided Circle reaches "To finish".
    final closeLeads =
        status != RecommendationStatus.started ||
        ended ||
        (body == SessionBody.guided &&
            recommendationState.guidedPosition >=
                guidedFinishPosition(activity));
    _noticeCloseLead(
      closeLeads,
      running: status == RecommendationStatus.started,
    );
    final notifier = ref.read(recommendationProvider.notifier);

    // Same Home throughout the whole daily lifecycle (READY/ACTIVE/CLOSED)
    // — no route, no page transition, no second screen: the Circle stays
    // at exactly the same place and size across all three, only this CTA
    // changes. An exhaustive switch over the three technical
    // RecommendationStatus values, rather than a scattered
    // isStarted/isClosed/canClose set of booleans, since each status maps
    // to exactly one label/action pair and nothing else varies between
    // them here.
    // Null once closed — see `bottomContent` below, which replaces the
    // button entirely with an explanatory "Done for today" message rather
    // than a disabled, ambiguous dead end (Batch 1, Phase C).
    final String? ctaLabel;
    final VoidCallback? onCtaPressed;
    // Phase B-D4: only Start Circle — the actual lifecycle transition —
    // carries a forward arrow; Close Circle is not a step forward.
    final IconData? ctaTrailingIcon;
    // The Circle's own semantics.value shares this same switch — one
    // status maps to exactly one CTA state *and* one announced meaning,
    // so both are decided in the same place rather than duplicating the
    // status check.
    final String circleSemanticValue;
    switch (recommendationState.status) {
      case RecommendationStatus.notStarted:
        ctaLabel = 'Start Circle';
        ctaTrailingIcon = Icons.arrow_forward_rounded;
        circleSemanticValue = 'Ready to begin.';
        // A single, soft haptic confirms the one moment THIRTY's product
        // principles reserve it for — "a decision has been made"
        // (Playbook Ch.2 §5) — fired here, not inside ThirtyButton or
        // RecommendationNotifier, so it stays tied to this exact physical
        // Start Circle tap: it can only ever fire once per valid press
        // (onPressed is already null while disabled/still gated by First
        // Breath's IgnorePointer above), never on a rebuild or a state
        // restore. Close Circle deliberately gets no haptic in this pass
        // — Circle Closed's own haptic is reserved product-level, but is
        // designed as its own later, physical experiment, not assumed
        // here.
        onCtaPressed = () {
          HapticFeedback.lightImpact();
          ref.read(recommendationProvider.notifier).start();
        };
      case RecommendationStatus.started:
        ctaLabel = 'Close Circle';
        ctaTrailingIcon = null;
        final total = offered.inMinutes;
        final minutes = elapsed.inMinutes.clamp(0, total);
        circleSemanticValue = ended
            ? 'That’s your $total minutes. The Circle is still open.'
            : paused
            ? 'Circle paused. $minutes of $total minutes.'
            : 'Circle in progress. $minutes of $total minutes.';
        // Batch 1, Phase B: no longer closes directly on tap — see
        // _confirmCloseCircle's own doc comment for the confirmation this
        // now requires before the irreversible transition.
        onCtaPressed = () => _confirmCloseCircle(context);
      case RecommendationStatus.closed:
        ctaLabel = null;
        ctaTrailingIcon = null;
        circleSemanticValue = 'Circle closed.';
        onCtaPressed = null;
    }

    // The greeting is this screen's display-serif moment; the Today card
    // carries the direction in the editorial serif itself.
    final greetingStyle = AppTypography.editorialDisplay(
      colors,
    ).copyWith(fontSize: 34, height: 1.15);

    // The near-fit trim is for the user's normal text size only; enlarged
    // text keeps the full Circle and scrolls.
    final normalTextSize = MediaQuery.textScalerOf(context).scale(16) <= 16;

    // V2 Phase C: the heading pair belongs to the Circle's moment — the
    // greeting before Start, the session while it runs (the activity and
    // its time; for Guided, the step on show), and a quiet close after.
    final SessionHeading heading = switch (status) {
      RecommendationStatus.notStarted => (
        title: homeGreeting(
          ref.watch(nowProvider),
          firstName: ref.watch(firstNameProvider),
        ),
        detail: homeGreetingSubline(started: false),
      ),
      RecommendationStatus.started => sessionHeadingFor(
        activity: activity,
        body: body,
        elapsedMinutes: elapsed.inMinutes.clamp(0, offered.inMinutes),
        offeredMinutes: offered.inMinutes,
        ended: ended,
        paused: paused,
        guidedPosition: recommendationState.guidedPosition,
      ),
      RecommendationStatus.closed => (
        title: CircleHero.closedHeading,
        detail: CircleHero.closedDetail,
      ),
    };
    final headingStyle = status == RecommendationStatus.notStarted
        ? greetingStyle
        // A session's title can be an activity name or a step: a touch
        // smaller than the greeting, so a long name keeps to one line.
        : greetingStyle.copyWith(fontSize: 30);
    final greeting = Semantics(
      header: true,
      child: AnimatedSwitcher(
        duration: artSwitchDuration,
        child: Text(
          heading.title,
          key: ValueKey(heading.title),
          style: headingStyle,
          textAlign: TextAlign.center,
        ),
      ),
    );

    // A running Circle's action must sit fully on the first screen too. When
    // the compact rhythm is not enough, these give up room in order, each
    // only as far as needed: the running gaps (Circle → greeting, greeting →
    // subline, greeting → card — never card → action); then the Today
    // card's padding; then the space above its first action; and last, a
    // little of the room between the action and the tab bar.
    const gapRelief =
        HomeCircleMetrics.compactGap - HomeCircleMetrics.runningTightGap;
    final runningTightSteps =
        recommendationState.status == RecommendationStatus.started
        ? const <HomeRhythmStep>[
            (
              gaps: [gapRelief, gapRelief, 0],
              children: [
                0,
                HomeCircleMetrics.greetingToSublineGap -
                    HomeCircleMetrics.runningTightGap,
                0,
                0,
              ],
              clearance: 0,
            ),
            (
              gaps: [0, 0, 0],
              children: [0, 0, TodayCard.runningPaddingReduction, 0],
              clearance: 0,
            ),
            (
              gaps: [0, 0, 0],
              children: [0, 0, TodayCard.runningInnerReduction, 0],
              clearance: 0,
            ),
            (
              gaps: [0, 0, 0],
              children: [0, 0, 0, 0],
              clearance:
                  HomeCircleMetrics.compactGap -
                  HomeCircleMetrics.runningLeastClearance,
            ),
          ]
        : const <HomeRhythmStep>[];

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = HomeCircleMetrics.forWidth(constraints.maxWidth);
        final textMaxWidth = metrics.textMaxWidth;
        // Inset so the illustration's circular edge sits at the ring's
        // inner edge, never under the stroke itself — the ring keeps
        // painting after the illustration (ThirtyProgressCircle's Stack
        // order is unchanged), so staying inside its inner boundary is
        // what keeps the two from visually overlapping. The wordmark
        // shares this same interior region, never the Circle's outer size.
        final illustrationSize = metrics.illustrationSize;
        final wordmarkWidth = metrics.wordmarkWidth;
        // SingleChildScrollView gives its child loose (not full-width)
        // horizontal constraints, so without this the Column below would
        // shrink-wrap to its widest child (the Circle) and the whole block
        // would render flush against the left edge of the screen instead of
        // centered — this SizedBox forces it back to the full available
        // width so the Column's own horizontal centering
        // (crossAxisAlignment.center, its default) actually has the full
        // width to center within. This affects only the horizontal axis; it
        // does not reintroduce the vertical viewport-centering that was
        // deliberately removed below.
        final hero = SizedBox(
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
            padding: HomeCircleMetrics.padding.add(
              EdgeInsets.only(top: widget.topInset),
            ),
            // The hero's own rhythm: normal gaps, tightened only when
            // Start Circle would otherwise just miss the first screen
            // (home_rhythm_column.dart). Order is unchanged.
            //
            // When the compact gaps are not enough (a short screen, e.g.
            // the Galaxy S25 with 3-button navigation), the Today card's
            // padding tightens too; and only if Start Circle still misses
            // — a two-line activity there — the Circle gives up exactly
            // the remaining shortfall, never more than
            // [HomeCircleMetrics.nearFitMaxTrim], at the user's normal
            // text size only, and only before Start. The trim eases in with
            // the Circle's opening ([_nearFitTrimProgress]) so it never
            // jumps from Ready, and is then held through Start and Close.
            child: HomeRhythmColumn(
              fitHeight: constraints.maxHeight - widget.topInset,
              minClearance: HomeCircleMetrics.compactGap,
              compactReductions: const [0, 0, TodayCard.nearFitReduction, 0],
              tightSteps: runningTightSteps,
              trim: normalTextSize
                  ? (
                      index: 0,
                      maxFraction: HomeCircleMetrics.nearFitMaxTrim,
                      progress: _nearFitTrimProgress,
                      // Decided for Start Circle only: once started or
                      // closed, the Circle keeps the size it has.
                      hold:
                          recommendationState.status !=
                          RecommendationStatus.notStarted,
                    )
                  : null,
              gaps: const [
                (
                  normal: HomeCircleMetrics.circleToContentGap,
                  compact: HomeCircleMetrics.compactGap,
                ),
                (
                  normal: HomeCircleMetrics.greetingToCardGap,
                  compact: HomeCircleMetrics.compactGap,
                ),
                (
                  normal: HomeCircleMetrics.cardToCtaGap,
                  compact: HomeCircleMetrics.compactGap,
                ),
              ],
              children: [
                // Phase D1 ring: a soft track with a sage dot at the
                // arc's leading end. Before Start Circle the arc is First
                // Breath's own opening sweep (1.0 → 0.0, then settled at
                // 0 with the dot at the top); from Start Circle on it is
                // the 30-minute timer.
                // Scales down only when the near-fit rhythm trims it.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedBuilder(
                    animation: _circleProgress,
                    builder: (context, child) {
                      return HomeCircle(
                        metrics: metrics,
                        progress:
                            recommendationState.status ==
                                RecommendationStatus.notStarted
                            ? _circleProgress.value
                            : timerProgress,
                        trackColor: colors.ringTrack,
                        progressColor: colors.primary,
                        // Announced by its lifecycle meaning, never as a
                        // bare percentage (Playbook Ch.2 §3).
                        semanticValue: circleSemanticValue,
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
                          // Phase D1: the wordmark with the tagline
                          // beneath it, fading as one lockup.
                          child: ExcludeSemantics(
                            child: ThirtyBrandLockup(
                              wordmarkWidth: wordmarkWidth,
                              centered: true,
                            ),
                          ),
                        ),
                        FadeTransition(
                          opacity: _illustrationOpacity,
                          child: AnimatedSwitcher(
                            duration: artSwitchDuration,
                            child: SizedBox(
                              key: ValueKey(_art.heroAsset),
                              width: illustrationSize,
                              height: illustrationSize,
                              child: WorldHeroArtView(
                                asset: _art.heroAsset,
                                scale: _art.heroScale,
                              ),
                            ),
                          ),
                        ),
                        // V2 Phase C: the natural end's quiet light — the
                        // same World, a little warmer (WORLD_SYSTEM.md §5D).
                        // Never a celebration; held, not replayed.
                        FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _endBeat,
                            curve: Curves.easeInOut,
                          ),
                          child: CircleEndWarmth(size: illustrationSize),
                        ),
                      ],
                    ),
                  ),
                ),
                // Phase D1 (Design vision): a centred greeting, then the
                // left-aligned Today card and a full-width CTA across the
                // page's content width.
                FadeTransition(
                  opacity: _headingOpacity,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: textMaxWidth),
                    // The space between the heading and its detail gives up
                    // room only for a running Circle that still misses the
                    // first screen (tightSteps).
                    child: HomeSqueezePair(
                      spacing: (
                        top: 0,
                        middle: HomeCircleMetrics.greetingToSublineGap,
                        bottom: 0,
                      ),
                      steps: const [
                        (
                          top: 0,
                          middle: HomeCircleMetrics.runningTightGap,
                          bottom: 0,
                        ),
                      ],
                      first: greeting,
                      second: Text(
                        heading.detail,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                switch (status) {
                  RecommendationStatus.notStarted => TodayCard(
                    intent: recommendation.intent,
                    activity: recommendation.activity,
                    // V2 Phase B: a truthful personal reason, when there is
                    // one, takes the line; the activity's own reason stays in
                    // its how-to.
                    why: recommendation.personalReason ?? recommendation.why,
                    category: recommendation.category,
                    minutes: recommendation.offeredMinutes,
                    firstAction: activity.firstAction,
                    label: switch (recommendation.session) {
                      TodaySession(:final pathCircle?, :final pathCircles?) =>
                        'Path · $pathCircle of $pathCircles',
                      TodaySession(isRoutine: true) => 'Your routine',
                      _ => 'Today',
                    },
                    spokenLabel: switch (recommendation.session) {
                      TodaySession(:final pathCircle?, :final pathCircles?) =>
                        'Path · Circle $pathCircle of $pathCircles',
                      _ => null,
                    },
                    showFirstAction:
                        recommendationState.status ==
                        RecommendationStatus.started,
                    // A retired activity restored from history has no V2
                    // guide to show.
                    onShowGuide: activity.status == ActivityStatus.retired
                        ? null
                        : () => showActivityGuide(
                            context,
                            activityId: recommendation.activityId,
                            intention: recommendation.intention,
                            offeredMinutes: recommendation.offeredMinutes,
                            definition: activity,
                            onNotThisOne:
                                recommendation.canReplace &&
                                    recommendationState.status ==
                                        RecommendationStatus.notStarted
                                ? () => _notThisOne(recommendation)
                                : null,
                          ),
                    // Before Start, the row says what it opens — and, while
                    // today's activity can still be swapped, that it can be.
                    guideCue:
                        recommendationState.status !=
                            RecommendationStatus.notStarted
                        ? ActivityRowCue.none
                        : recommendation.canReplace
                        ? ActivityRowCue.howToOrNotThisOne
                        : ActivityRowCue.howTo,
                    cardAsset: _art.cardAsset,
                    artSwitchDuration: artSwitchDuration,
                    intentOpacity: _intentOpacity,
                    detailOpacity: _activityWhyOpacity,
                  ),
                  // V2 Phase C: the running Circle's session — Open, Guided
                  // or Paced — in the same card shell.
                  RecommendationStatus.started => _pausedWhenHidden(
                    paced: body == SessionBody.paced,
                    onHidden: notifier.pause,
                    child: CircleSessionCard(
                      activity: activity,
                      body: body,
                      elapsed: elapsed,
                      offered: offered,
                      guidedPosition: recommendationState.guidedPosition,
                      paused: paused,
                      ended: ended,
                      pace: activity.pace,
                      onShowGuide: activity.status == ActivityStatus.retired
                          ? null
                          : () => showActivityGuide(
                              context,
                              activityId: recommendation.activityId,
                              intention: recommendation.intention,
                              offeredMinutes: recommendation.offeredMinutes,
                              definition: activity,
                            ),
                      onMoveTo: notifier.moveTo,
                      onPause: notifier.pause,
                      onResume: notifier.resume,
                      cardAsset: _art.cardAsset,
                      artSwitchDuration: artSwitchDuration,
                    ),
                  ),
                  // V2 Phase C: the reflection, inline — no hunting for it.
                  RecommendationStatus.closed => const CircleReflectionCard(),
                },
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
                    // Batch 1, Phase C: once closed there is no CTA at
                    // all — an explanatory "Done for today" message
                    // replaces the old disabled "Circle closed" button,
                    // which testers read as a stuck/broken dead end
                    // rather than an intentional daily boundary. The
                    // next-open date is never invented here: "tomorrow"
                    // is exactly the existing authoritative reset rule
                    // (recommendation_provider.dart's local-calendar-day
                    // scoping), not a guessed time of day.
                    // Once closed the reflection above is the moment: no
                    // action here at all (the heading says when the next
                    // Circle opens).
                    child: ctaLabel == null
                        ? const SizedBox.shrink()
                        // Phase D1: the full content width, like the
                        // Today card above it. V2 Phase C: while the
                        // Circle runs, Close stays quiet — it is always
                        // there, never the thing to do — and becomes the
                        // filled action once the time set aside is here.
                        : SizedBox(
                            width: double.infinity,
                            child: ThirtyButton(
                              label: ctaLabel,
                              size: ThirtyButtonSize.hero,
                              variant: closeLeads
                                  ? ThirtyButtonVariant.primary
                                  : ThirtyButtonVariant.secondary,
                              trailingIcon: ctaTrailingIcon,
                              onPressed: onCtaPressed,
                              focusNode: _closeFocus,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );

        // Phase B3 — the one vertical scroll owner for Home's body once a
        // recommendation exists: the hero and every card below it
        // ([footer]) are one document. A card never shrinks the hero; it
        // extends the page and is reached by scrolling. Non-lazy on
        // purpose: the invitation cards persist their "shown" flags from
        // their first build, exactly as before.
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  hero,
                  if (widget.header case final header?)
                    Positioned(top: 0, left: 0, right: 0, child: header),
                ],
              ),
              ...widget.footer,
            ],
          ),
        );
      },
    );
  }
}

/// Calls [onHidden] whenever the app is no longer visible. A plain binding
/// observer: it takes the lifecycle exactly as reported, in any order.
class _OutOfSight with WidgetsBindingObserver {
  _OutOfSight(this.onHidden);

  final VoidCallback onHidden;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      onHidden();
    }
  }
}

/// Pauses a Paced session whenever the app leaves the foreground.
Widget _pausedWhenHidden({
  required bool paced,
  required VoidCallback onHidden,
  required Widget child,
}) => paced ? PauseWhenHidden(onHidden: onHidden, child: child) : child;

/// The natural end's light over the World: a soft warm wash from above,
/// clipped to the World's circle. Decorative.
class CircleEndWarmth extends StatelessWidget {
  const CircleEndWarmth({required this.size, super.key});

  final double size;

  static const _warm = Color(0xFFFFD9A3);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final strength = dark ? 0.30 : 0.38;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(0, -0.55),
                radius: 1.05,
                colors: [
                  _warm.withValues(alpha: strength),
                  _warm.withValues(alpha: strength * 0.45),
                  _warm.withValues(alpha: 0),
                ],
                stops: const [0, 0.55, 1],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
