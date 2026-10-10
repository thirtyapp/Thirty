import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../../../core/widgets/thirty_text_action.dart';
import '../../application/activity_catalog.dart';
import '../../domain/circle_session.dart';
import 'today_card.dart';

/// How today's Circle runs (V2 Phase C, ADR-021): one shared Circle shell —
/// the World and its ring, a heading pair, one card, Close — with the body
/// its activity's mode needs.
enum SessionBody { open, guided, paced }

/// The body [activity] runs with. A Paced activity paces only with a
/// reviewed [pace]; without one — every catalogue activity today — and a
/// Guided one without steps, it runs as Open.
SessionBody sessionBodyFor(ActivityDefinition activity, PacePattern? pace) =>
    switch (activity.mode) {
      CircleMode.guidedSteps when activity.steps.isNotEmpty =>
        SessionBody.guided,
      CircleMode.paced when pace != null => SessionBody.paced,
      _ => SessionBody.open,
    };

/// The words of a running Circle's heading pair — what replaces the
/// greeting once the Circle has started.
typedef SessionHeading = ({String title, String detail});

/// Open and Paced: the activity, then its time. Guided: the step on show,
/// then where it sits. Time is never a countdown: minutes so far, of the
/// time set aside, and at the natural end only that the time is here.
SessionHeading sessionHeadingFor({
  required ActivityDefinition activity,
  required SessionBody body,
  required int elapsedMinutes,
  required int offeredMinutes,
  required bool ended,
  required bool paused,
  required int guidedPosition,
}) {
  final time = ended
      ? 'That’s your $offeredMinutes minutes'
      : '$elapsedMinutes of $offeredMinutes minutes';
  switch (body) {
    case SessionBody.open:
      return (title: activity.title, detail: time);
    case SessionBody.paced:
      return (title: activity.title, detail: paused ? 'Paused · $time' : time);
    case SessionBody.guided:
      // Time reaching its end says nothing about the steps: the step on show
      // is never turned into "Step 5 of 5" — the end simply takes over.
      if (ended) return (title: activity.title, detail: time);
      final steps = activity.steps.length;
      if (guidedPosition >= steps) {
        return (
          title: SessionCopy.toFinishTitle,
          detail: paused ? 'Paused · ${activity.title}' : activity.title,
        );
      }
      final step = 'Step ${guidedPosition + 1} of $steps';
      return (
        title: activity.steps[guidedPosition].name,
        detail: paused ? 'Paused · $step' : '$step · ${activity.title}',
      );
  }
}

/// The session's fixed words, in one place.
abstract final class SessionCopy {
  static const first = 'First';
  static const whileYoureThere = 'While you’re there';
  static const toFinish = 'To finish';
  static const toFinishTitle = 'To finish';
  static const howTo = 'How to do it';
  static const back = 'Back';
  static const next = 'Next';
  static const pause = 'Pause';
  static const resume = 'Resume';

  /// What TalkBack hears once, at the natural end.
  static String naturalEndAnnouncement(int minutes, String ending) =>
      'That’s your $minutes minutes. $ending Close the Circle whenever '
      'you’re ready.';
}

/// The running Circle's card: the mode's body in the Today card's shell, so
/// Home's near-fit rhythm treats it exactly as it treats the Today card.
class CircleSessionCard extends StatelessWidget {
  const CircleSessionCard({
    required this.activity,
    required this.body,
    required this.elapsed,
    required this.offered,
    required this.guidedPosition,
    required this.paused,
    required this.ended,
    required this.onShowGuide,
    required this.onMoveTo,
    required this.onPause,
    required this.onResume,
    this.pace,
    this.cardAsset,
    this.artSwitchDuration = Duration.zero,
    super.key,
  });

  final ActivityDefinition activity;
  final SessionBody body;
  final Duration elapsed;
  final Duration offered;
  final int guidedPosition;
  final bool paused;

  /// The time set aside has been reached.
  final bool ended;

  /// Opens the full how-to; `null` hides it.
  final VoidCallback? onShowGuide;
  final ValueChanged<int> onMoveTo;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final PacePattern? pace;

  /// Today's World Card art — shown beside Open's card only; Guided and
  /// Paced need the card's full width.
  final String? cardAsset;
  final Duration artSwitchDuration;

  @override
  Widget build(BuildContext context) {
    return switch (body) {
      SessionBody.open => HomeCardShell(
        cardAsset: cardAsset,
        artSwitchDuration: artSwitchDuration,
        first: _OpenMomentText(
          activity: activity,
          moment: openMomentFor(activity, elapsed: elapsed, offered: offered),
        ),
        second: onShowGuide == null
            ? const SizedBox.shrink()
            : ThirtyTextAction(
                label: SessionCopy.howTo,
                onPressed: onShowGuide,
              ),
      ),
      // Once the time set aside is reached, the ending takes over from
      // whichever step was on show — without claiming the rest were done.
      // Not a live region: the natural-end announcement already says it.
      SessionBody.guided when ended => HomeCardShell(
        first: _OpenMomentText(
          activity: activity,
          moment: const OpenMoment(OpenPhase.ending),
        ),
        second: const SizedBox.shrink(),
      ),
      SessionBody.guided => HomeCardShell(
        first: _GuidedStepText(activity: activity, position: guidedPosition),
        second: _GuidedControls(
          position: guidedPosition,
          finish: guidedFinishPosition(activity),
          paused: paused,
          onMoveTo: onMoveTo,
          onPause: onPause,
          onResume: onResume,
        ),
      ),
      SessionBody.paced => HomeCardShell(
        first: PacedSessionBody(
          pattern: pace!,
          elapsed: elapsed,
          paused: paused,
        ),
        second: _PauseToggle(
          paused: paused,
          onPause: onPause,
          onResume: onResume,
        ),
      ),
    };
  }
}

TextStyle? _eyebrowStyle(BuildContext context) {
  final colors = Theme.of(context).extension<AppColors>()!;
  return Theme.of(context).textTheme.labelSmall?.copyWith(
    color: colors.textSecondary,
    letterSpacing: 1.5,
  );
}

/// A small spaced-capitals label, read as words.
class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    semanticsLabel: text,
    style: _eyebrowStyle(context),
  );
}

Duration _switchDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 450);

/// Open: the first action, then the activity's own ideas one at a time,
/// then its ending line — changing quietly as the Circle's time passes.
class _OpenMomentText extends StatelessWidget {
  const _OpenMomentText({required this.activity, required this.moment});

  final ActivityDefinition activity;
  final OpenMoment moment;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final (label, text, emphasis) = switch (moment.phase) {
      OpenPhase.firstAction => (SessionCopy.first, activity.firstAction, true),
      OpenPhase.idea => (
        SessionCopy.whileYoureThere,
        activity.whileYoureThere[moment.ideaIndex],
        false,
      ),
      OpenPhase.ending => (SessionCopy.toFinish, activity.ending, true),
    };
    // One stop for TalkBack — "First. Grab paper…" — never a bare eyebrow.
    // Not a live region: it changes as time passes, unasked.
    return Semantics(
      container: true,
      label: '$label. $text',
      child: ExcludeSemantics(
        child: AnimatedSwitcher(
          duration: _switchDuration(context),
          layoutBuilder: (current, previous) => Stack(
            alignment: AlignmentDirectional.topStart,
            children: [...previous, ?current],
          ),
          child: Column(
            key: ValueKey(moment),
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Eyebrow(label),
              const SizedBox(height: AppSpacing.xs),
              Text(
                text,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: emphasis ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Guided: the instruction and cue of the step on show — its name is the
/// heading above the card — or the ending line after the last step. Read
/// out once whenever it changes.
class _GuidedStepText extends StatelessWidget {
  const _GuidedStepText({required this.activity, required this.position});

  final ActivityDefinition activity;
  final int position;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final steps = activity.steps;
    final finish = position >= steps.length;
    final step = finish ? null : steps[position];
    return Semantics(
      container: true,
      liveRegion: true,
      label: finish
          ? '${SessionCopy.toFinish}. ${activity.ending}'
          : 'Step ${position + 1} of ${steps.length}. ${step!.name}. '
                '${step.instruction} ${step.cue}.',
      child: ExcludeSemantics(
        child: AnimatedSwitcher(
          duration: _switchDuration(context),
          layoutBuilder: (current, previous) => Stack(
            alignment: AlignmentDirectional.topStart,
            children: [...previous, ?current],
          ),
          child: Column(
            key: ValueKey(position),
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: finish
                ? [
                    Text(
                      activity.ending,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]
                : [
                    Text(
                      step!.instruction,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            step.cue,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

/// Guided's controls: Back, Pause or Resume, and Next — orientation only.
/// Next is the one filled control; the others are quiet text.
class _GuidedControls extends StatelessWidget {
  const _GuidedControls({
    required this.position,
    required this.finish,
    required this.paused,
    required this.onMoveTo,
    required this.onPause,
    required this.onResume,
  });

  final int position;
  final int finish;
  final bool paused;
  final ValueChanged<int> onMoveTo;
  final VoidCallback onPause;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final canGoBack = position > 0;
    final canGoOn = position < finish;
    final back = _QuietControl(
      label: SessionCopy.back,
      icon: Icons.chevron_left_rounded,
      onPressed: canGoBack ? () => onMoveTo(position - 1) : null,
    );
    final pause = _PauseToggle(
      paused: paused,
      onPause: onPause,
      onResume: onResume,
      labelled: false,
    );
    final next = canGoOn
        ? ThirtyButton(
            label: SessionCopy.next,
            // The one thing to do while the steps run; Close below stays
            // quiet. Once the time is reached the ending replaces these
            // controls and Close leads.
            variant: ThirtyButtonVariant.primary,
            trailingIcon: Icons.chevron_right_rounded,
            onPressed: () => onMoveTo(position + 1),
          )
        : const SizedBox.shrink();
    // One row whenever the three truly fit — measured, never guessed —
    // and otherwise stacked, Next first; nothing ever overflows.
    return OverflowBar(
      alignment: MainAxisAlignment.spaceBetween,
      overflowAlignment: OverflowBarAlignment.center,
      overflowDirection: VerticalDirection.up,
      children: [
        // Keeps its place on step 1, so nothing shifts as you go.
        Visibility(
          visible: canGoBack,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: back,
        ),
        pause,
        next,
      ],
    );
  }
}

/// Pause or Resume, as a quiet text control.
class _PauseToggle extends StatefulWidget {
  const _PauseToggle({
    required this.paused,
    required this.onPause,
    required this.onResume,
    this.labelled = true,
  });

  final bool paused;
  final VoidCallback onPause;
  final VoidCallback onResume;

  /// With words beside the icon. Guided's row shows the icon alone — one
  /// width in both states, so pausing never reflows the card (S25 device
  /// finding); the heading above says "Paused" in words, and TalkBack hears
  /// the action's name.
  final bool labelled;

  @override
  State<_PauseToggle> createState() => _PauseToggleState();
}

class _PauseToggleState extends State<_PauseToggle> {
  // Pausing changes the screen around the toggle; on the S25 TalkBack then
  // left it for the step text. Taking focus back keeps TalkBack on the
  // control just used, now named for what it does next.
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paused = widget.paused;
    final label = paused ? SessionCopy.resume : SessionCopy.pause;
    final icon = paused ? Icons.play_arrow_rounded : Icons.pause_rounded;
    final action = paused ? widget.onResume : widget.onPause;
    void onPressed() {
      action();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }

    if (widget.labelled) {
      return _QuietControl(
        label: label,
        icon: icon,
        onPressed: onPressed,
        focusNode: _focus,
      );
    }
    final colors = Theme.of(context).extension<AppColors>()!;
    return IconButton(
      focusNode: _focus,
      onPressed: onPressed,
      tooltip: label,
      icon: Icon(icon, color: colors.primary),
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    );
  }
}

/// A quiet text control with a small leading icon and a full 48pt target.
class _QuietControl extends StatelessWidget {
  const _QuietControl({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.focusNode,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      focusNode: focusNode,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
      ),
    );
  }
}

/// Paced (ADR-021): the phase on show, a quiet sense of its pace, and how
/// long it has left. Only ever given a reviewed pattern — or, in internal
/// QA, a synthetic one. With reduced motion the pace is words and numbers
/// only: nothing grows, shrinks or pulses.
class PacedSessionBody extends StatefulWidget {
  const PacedSessionBody({
    required this.pattern,
    required this.elapsed,
    required this.paused,
    this.elapsedNow,
    super.key,
  });

  final PacePattern pattern;

  /// Active time at the last rebuild.
  final Duration elapsed;
  final bool paused;

  /// Active time right now, for the body's own finer repaint while
  /// running; [elapsed] when `null`.
  final Duration Function()? elapsedNow;

  @override
  State<PacedSessionBody> createState() => _PacedSessionBodyState();
}

class _PacedSessionBodyState extends State<PacedSessionBody>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration? _live;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      final now = widget.elapsedNow;
      if (now == null || widget.paused) return;
      setState(() => _live = now());
    });
    _sync();
  }

  @override
  void didUpdateWidget(PacedSessionBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    _live = null;
    _sync();
  }

  void _sync() {
    final running = !widget.paused && widget.elapsedNow != null;
    if (running && !_ticker.isActive) unawaited(_ticker.start());
    if (!running && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final moment = paceMomentFor(widget.pattern, _live ?? widget.elapsed);
    final phase = widget.pattern.phases[moment.phaseIndex];
    final seconds = (moment.phaseRemaining.inMilliseconds / 1000).ceil();
    final phaseLine = moment.finished
        ? 'Pacing has ended'
        : widget.paused
        ? '${phase.label} · paused'
        : '${phase.label} · $seconds s';

    return Semantics(
      container: true,
      liveRegion: true,
      // Read once per phase, never per second.
      label: moment.finished ? 'Pacing has ended.' : phase.label,
      child: ExcludeSemantics(
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Center(
                child: _PaceMark(
                  progress: moment.phaseProgress,
                  phaseIndex: moment.phaseIndex,
                  still: reducedMotion || widget.paused || moment.finished,
                  color: colors.primary,
                  track: colors.ringTrack,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text(
                phaseLine,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The pace's mark: a disc that grows through even phases and settles
/// through odd ones — or, kept still, a ring that only fills.
class _PaceMark extends StatelessWidget {
  const _PaceMark({
    required this.progress,
    required this.phaseIndex,
    required this.still,
    required this.color,
    required this.track,
  });

  final double progress;
  final int phaseIndex;
  final bool still;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    if (still) {
      return SizedBox.square(
        dimension: 40,
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 3,
          color: color,
          backgroundColor: track,
        ),
      );
    }
    final eased = Curves.easeInOut.transform(progress);
    final grow = phaseIndex.isEven ? eased : 1 - eased;
    final size = 20 + 28 * grow;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.35 + 0.4 * grow),
      ),
    );
  }
}

/// Pauses a Paced Circle whenever the app leaves the foreground: its pacing
/// depends on being watched, so it never runs on — or skips ahead — unseen.
/// On return it stays paused until the user resumes.
class PauseWhenHidden extends StatefulWidget {
  const PauseWhenHidden({
    required this.onHidden,
    required this.child,
    super.key,
  });

  final VoidCallback onHidden;
  final Widget child;

  @override
  State<PauseWhenHidden> createState() => _PauseWhenHiddenState();
}

class _PauseWhenHiddenState extends State<PauseWhenHidden> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onInactive: () => widget.onHidden(),
      onHide: () => widget.onHidden(),
      onPause: () => widget.onHidden(),
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
