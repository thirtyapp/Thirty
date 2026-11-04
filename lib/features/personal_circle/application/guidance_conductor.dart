import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_provider.dart';
import '../../home/application/recommendation_provider.dart';
import '../domain/circle_elements.dart';
import '../domain/composed_session.dart';
import '../domain/spoken_cues.dart';
import 'guidance_session.dart';
import 'guidance_voice.dart';

/// Speaks a running composed Circle (V2 Phase D2, ADR-023 Â§6), in front
/// or out of sight.
///
/// It keeps no time of its own. The part on show is always derived from
/// the Circle's stored facts and the clock ([RecommendationState.partMomentAt]),
/// so a cue is due exactly when the part begins, however long THIRTY was
/// out of sight, and a return or a restart lands on the right part. Each
/// part is spoken once; never on a first look into a Circle already under
/// way; never while paused.
///
/// While a voiced Circle runs it keeps a [GuidanceSession] open, which
/// stops the platform freezing or sleeping THIRTY between cues and offers
/// Pause, Resume and Next â€” the Circle's own actions. Not Close: closing is
/// a confirmed, irreversible step taken in THIRTY itself. The session ends
/// with the Circle â€” after the ending is spoken, at Close, or when the
/// voice is turned off.
///
/// Two lines frame a voiced Circle (founder approval, 2026-10-26): its
/// opening, "Your Circle for today.", before "First." at the user's own
/// Start, with the same words on show ([spokenOpeningProvider]); and
/// "Your next Circle opens tomorrow." after the user's own Close — the
/// closed Circle's line — only when the Circle closed on its own day, and
/// after the ending if that is still being said. Each is said once: never
/// on a first look, a return, a restart, a resume or a reopened Circle.
class GuidanceConductor {
  GuidanceConductor(this._ref) {
    _session = _ref.read(guidanceSessionProvider)..listen(_onAction);
    _ref.listen(recommendationProvider, (_, _) => _conduct());
    _ref.listen(guidanceVoiceProvider, (_, _) => _conduct());
    _conduct();
  }

  final Ref _ref;
  late final GuidanceSession _session;

  /// How long the device is kept awake beyond the Circle's remaining time.
  static const awakeMargin = Duration(minutes: 1);

  /// How long the opening's words stay on show: the length of that voice's
  /// own recording (`opening_d1293026.m4a`, checked against the files by
  /// test), so they leave as it ends and "First." begins — never while the
  /// line is still being said. Each recording's speech ends 0.40–0.42 s
  /// before its end, room for the player's start-up; "First." is heard
  /// 0.15 s into its own clip.
  static const openingOnShow = {
    ThirtyVoice.locke: Duration(milliseconds: 1790),
    ThirtyVoice.heather: Duration(milliseconds: 2072),
    ThirtyVoice.milo: Duration(milliseconds: 1740),
    ThirtyVoice.brittney: Duration(milliseconds: 1800),
  };

  /// For a voice that isn't one of the bundled four: the longest.
  static final openingOnShowAtMost = openingOnShow.values.reduce(
    (a, b) => a > b ? a : b,
  );

  Timer? _ticker;
  Timer? _openingTimer;

  /// The part last seen while the Circle ran or was paused; `null` before
  /// Start, after Close, and on a first look.
  int? _spokenPart;
  GuidanceVoice? _playingVoice;
  GuidanceSessionStatus? _shown;

  /// The Circle and status last seen — so a Start or a Close is noticed only
  /// as it happens, never on a first look at a Circle already under way or
  /// closed.
  String? _seenCircle;
  RecommendationStatus? _seenStatus;

  /// The Circle whose ending was the last thing asked of the voice.
  String? _endingSpoken;

  /// The Circle whose closing line was asked for, while it may still be
  /// speaking.
  String? _closingSpoken;

  void _conduct() {
    final state = _ref.read(recommendationProvider);
    final circle = state.recommendation?.circleId;
    final sameCircle = circle != null && circle == _seenCircle;
    final startedNow =
        sameCircle &&
        _seenStatus == RecommendationStatus.notStarted &&
        state.status == RecommendationStatus.started;
    final closedNow =
        sameCircle &&
        _seenStatus == RecommendationStatus.started &&
        state.status == RecommendationStatus.closed;
    _seenCircle = circle;
    _seenStatus = state.status;
    final composed = state.recommendation?.composed;
    final moment = state.partMomentAt(_ref.read(eventClockProvider)());
    final voice = _ref.read(guidanceVoiceProvider);
    final running = state.status == RecommendationStatus.started;
    // Audit remediation R6: a kept Circle any of whose saved words differ
    // from the recorded ones is never voiced — not one line of it.
    final speaks = voice.available && composed != null && composed.voiced;
    if (composed == null || moment == null || !running || !speaks) {
      // Nothing is checked while silent, so a voice that comes back — turned
      // on again, or Premium resumed — takes a first look: it speaks from
      // the next part, never one already under way.
      _spokenPart = null;
      _hideOpening();
      if (closedNow && speaks && _closedOnItsOwnDay(state)) {
        _speakNextCircle(voice, circle);
      } else if (!(speaks &&
          state.status == RecommendationStatus.closed &&
          circle == _closingSpoken)) {
        // The closing line, once asked for, is left to finish; anything
        // else stops — a lapse, the voice turned off, another day.
        _closingSpoken = null;
        _stopVoice();
      }
      _end();
      return;
    }
    if (state.isPaused) {
      // Resuming the same part says nothing new.
      _spokenPart = moment.position;
      _hideOpening();
      _stopVoice();
      _setTicking(false);
      _show(composed, moment, paused: true);
      return;
    }
    final before = _spokenPart;
    _spokenPart = moment.position;
    final firstLook = before == null;
    final begins =
        before != moment.position &&
        !(firstLook &&
            (moment.finished ||
                moment.partElapsed > const Duration(seconds: 2)));
    // Every part's words are the recorded ones here ([ComposedSession.voiced]).
    final cue = begins;
    // The opening, only at the user's own Start, as the first part begins.
    final opens =
        begins && startedNow && moment.position == 0 && !moment.finished;
    if (cue || opens) {
      _speak(voice, composed.plan, moment, opening: opens, cue: cue);
    }
    if (opens) _showOpening(circle, voice);
    if (moment.finished) {
      if (cue) _endingSpoken = circle;
      _end(afterSpeech: true);
      return;
    }
    _setTicking(true);
    _show(composed, moment, paused: false);
  }

  /// Unknown (before any lifecycle event) counts as in front. In front, a
  /// screen reader's live announcement speaks instead; out of sight the
  /// voice is the only guidance.
  static bool get _inFront {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  void _speak(
    GuidanceVoice voice,
    CirclePlan plan,
    PartMoment moment, {
    required bool opening,
    required bool cue,
  }) {
    _playingVoice = voice;
    _endingSpoken = null;
    unawaited(
      voice.play([
        if (opening) spokenOpening,
        if (cue)
          ...moment.finished
              ? [spokenEnding]
              : spokenCueFor(plan, moment.position),
      ], deferToScreenReader: _inFront),
    );
  }

  /// "Your next Circle opens tomorrow." — after the ending, if that is
  /// still being said; otherwise at once, in place of a part's cue the
  /// Close cut short.
  void _speakNextCircle(GuidanceVoice voice, String circle) {
    _playingVoice = voice;
    _closingSpoken = circle;
    unawaited(
      voice.play(
        [spokenNextCircle],
        deferToScreenReader: _inFront,
        afterCurrent: _endingSpoken == circle,
      ),
    );
    _endingSpoken = null;
  }

  /// "Tomorrow" is true only for a Circle closed on its own day: one kept
  /// open past midnight is closed on the next day, whose Circle is already
  /// there to begin.
  static bool _closedOnItsOwnDay(RecommendationState state) {
    final closedAt = state.closedAt;
    return closedAt != null && state.nextCircleIsTomorrowAt(closedAt);
  }

  void _showOpening(String circle, GuidanceVoice voice) {
    _openingTimer?.cancel();
    _ref.read(spokenOpeningProvider.notifier)._show(circle);
    final onShow = voice is BundledGuidanceVoice
        ? openingOnShow[voice.voice]!
        : openingOnShowAtMost;
    _openingTimer = Timer(onShow, _hideOpening);
  }

  void _hideOpening() {
    _openingTimer?.cancel();
    _openingTimer = null;
    _ref.read(spokenOpeningProvider.notifier)._show(null);
  }

  void _show(
    ComposedSession composed,
    PartMoment moment, {
    required bool paused,
  }) {
    final plan = composed.plan;
    final status = GuidanceSessionStatus(
      part: composed.wordingAt(moment.position).name,
      paused: paused,
      keepAwakeFor: paused
          ? Duration.zero
          : _remaining(plan, moment) + awakeMargin,
    );
    final shown = _shown;
    if (shown != null && shown.showsAs(status)) return;
    _shown = status;
    unawaited(_session.show(status));
  }

  static Duration _remaining(CirclePlan plan, PartMoment moment) {
    var remaining = moment.partLength - moment.partElapsed;
    for (final part in plan.parts.skip(moment.position + 1)) {
      remaining += Duration(minutes: part.minutes);
    }
    return remaining;
  }

  void _end({bool afterSpeech = false}) {
    _setTicking(false);
    if (_shown == null) return;
    _shown = null;
    unawaited(_session.end(afterSpeech: afterSpeech));
  }

  /// Checks once a second whether a part has begun, while a voiced Circle
  /// runs. The session keeps the device awake for it.
  void _setTicking(bool ticking) {
    if (!ticking) {
      _ticker?.cancel();
      _ticker = null;
    } else {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _conduct());
    }
  }

  void _stopVoice() {
    final voice = _playingVoice;
    _playingVoice = null;
    if (voice != null) unawaited(voice.stop());
  }

  /// The notification's controls: exactly what the Circle's own Pause,
  /// Resume and Next do.
  void _onAction(GuidanceAction action) {
    final notifier = _ref.read(recommendationProvider.notifier);
    switch (action) {
      case GuidanceAction.pause:
        notifier.pause();
      case GuidanceAction.resume:
        notifier.resume();
      case GuidanceAction.next:
        final moment = _ref
            .read(recommendationProvider)
            .partMomentAt(_ref.read(eventClockProvider)());
        if (moment != null && !moment.finished) {
          notifier.movePart(moment.position + 1);
        }
    }
  }

  void dispose() {
    _session.listen(null);
    _openingTimer?.cancel();
    _stopVoice();
    _end();
  }
}

/// The Circle whose spoken opening is being said now (its circle id), so
/// its words are on show with it; `null` otherwise. Set only by
/// [GuidanceConductor].
class SpokenOpening extends Notifier<String?> {
  @override
  String? build() => null;

  void _show(String? circle) {
    if (state != circle) state = circle;
  }
}

final spokenOpeningProvider = NotifierProvider<SpokenOpening, String?>(
  SpokenOpening.new,
);

/// The conductor: one per container, alive for as long as the container —
/// created at start-up by `main.dart` ([keepGuidanceConducting]), and by
/// Today wherever a Circle runs.
final guidanceConductorProvider = Provider<GuidanceConductor>((ref) {
  final conductor = GuidanceConductor(ref);
  ref.onDispose(conductor.dispose);
  return conductor;
});

/// Creates [container]'s conductor now, so the voice never depends on which
/// screen is built.
void keepGuidanceConducting(ProviderContainer container) =>
    container.read(guidanceConductorProvider);
