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

  Timer? _ticker;

  /// The part last seen while the Circle ran or was paused; `null` before
  /// Start, after Close, and on a first look.
  int? _spokenPart;
  GuidanceVoice? _playingVoice;
  GuidanceSessionStatus? _shown;

  void _conduct() {
    final state = _ref.read(recommendationProvider);
    final composed = state.recommendation?.composed;
    final moment = state.partMomentAt(_ref.read(eventClockProvider)());
    final voice = _ref.read(guidanceVoiceProvider);
    final running = state.status == RecommendationStatus.started;
    if (composed == null || moment == null || !running || !voice.available) {
      // Nothing is checked while silent, so a voice that comes back — turned
      // on again, or Premium resumed — takes a first look: it speaks from
      // the next part, never one already under way.
      _spokenPart = null;
      _stopVoice();
      _end();
      return;
    }
    if (state.isPaused) {
      // Resuming the same part says nothing new.
      _spokenPart = moment.position;
      _stopVoice();
      _setTicking(false);
      _show(composed.plan, moment, paused: true);
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
    if (begins) _speak(voice, composed.plan, moment);
    if (moment.finished) {
      _end(afterSpeech: true);
      return;
    }
    _setTicking(true);
    _show(composed.plan, moment, paused: false);
  }

  void _speak(GuidanceVoice voice, CirclePlan plan, PartMoment moment) {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    // Unknown (before any lifecycle event) counts as in front. In front,
    // a screen reader's live announcement speaks instead; out of sight the
    // voice is the only guidance.
    final foreground =
        lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _playingVoice = voice;
    unawaited(
      voice.play(
        moment.finished ? [spokenEnding] : spokenCueFor(plan, moment.position),
        deferToScreenReader: foreground,
      ),
    );
  }

  void _show(CirclePlan plan, PartMoment moment, {required bool paused}) {
    final status = GuidanceSessionStatus(
      part: plan.parts[moment.position].definition.name,
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
    _stopVoice();
    _end();
  }
}

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
