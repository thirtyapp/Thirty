import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/shared_preferences_provider.dart';
import '../domain/spoken_cues.dart';

/// The voice that speaks a composed Circle's cues (V2 Phase D2, ADR-023
/// §6): bundled recordings, played offline — no runtime generative AI, no
/// voice API, no per-use cost.
///
/// Spoken guidance is an addition, never a dependency: the Circle's
/// on-screen guidance and its TalkBack announcements are complete without
/// it, and when anything is missing — a recording, the platform player —
/// the voice is silent, never broken.
abstract interface class GuidanceVoice {
  /// Whether this voice can speak at all.
  bool get available;

  /// Plays [clips] in order, replacing anything still playing. With
  /// [deferToScreenReader], nothing plays while a screen reader is on: its
  /// own announcement of the part speaks instead.
  Future<void> play(List<SpokenClip> clips, {bool deferToScreenReader});

  /// Stops — at Pause, Close or leaving the Circle.
  Future<void> stop();
}

/// Says nothing.
class SilentGuidanceVoice implements GuidanceVoice {
  const SilentGuidanceVoice();

  @override
  bool get available => false;

  @override
  Future<void> play(
    List<SpokenClip> clips, {
    bool deferToScreenReader = false,
  }) async {}

  @override
  Future<void> stop() async {}
}

/// Plays bundled recordings through [player].
class BundledGuidanceVoice implements GuidanceVoice {
  const BundledGuidanceVoice(this.player);

  final GuidanceAudioPlayer player;

  @override
  bool get available => true;

  @override
  Future<void> play(
    List<SpokenClip> clips, {
    bool deferToScreenReader = false,
  }) => player.play([
    for (final clip in clips) clip.asset,
  ], deferToScreenReader: deferToScreenReader);

  @override
  Future<void> stop() => player.stop();
}

/// Plays bundled audio assets, one after another.
abstract interface class GuidanceAudioPlayer {
  /// Plays [assets] in order. With [deferToScreenReader], nothing plays
  /// while the platform's screen reader is on (Android: touch exploration).
  Future<void> play(List<String> assets, {bool deferToScreenReader});
  Future<void> stop();
}

/// The platform's own player (Android: `GuidanceAudio.kt`), over a method
/// channel. Where there is none, it does nothing.
class PlatformGuidanceAudioPlayer implements GuidanceAudioPlayer {
  const PlatformGuidanceAudioPlayer();

  static const _channel = MethodChannel('com.thirty.app/guidance_audio');

  @override
  Future<void> play(List<String> assets, {bool deferToScreenReader = false}) =>
      _call('play', {
        'assets': assets,
        'deferToScreenReader': deferToScreenReader,
      });

  @override
  Future<void> stop() => _call('stop');

  Future<void> _call(String method, [Object? arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // No player on this platform: silent.
    } on PlatformException {
      // A clip that can't be played is skipped, never an error.
    }
  }
}

/// Whether [bundle] holds every clip in [spokenGuidanceManifest]. A partial
/// set is no set: the voice never speaks some parts and not others. Read
/// once at start-up (`main.dart`), so nothing waits on it later.
Future<bool> spokenGuidanceBundled(AssetBundle bundle) async {
  final manifest = await AssetManifest.loadFromAssetBundle(bundle);
  final bundled = manifest.listAssets().toSet();
  return spokenGuidanceManifest.every((clip) => bundled.contains(clip.asset));
}

/// Whether spoken guidance exists in this build — the You setting shows
/// only then. Overridden at start-up with [spokenGuidanceBundled]; `false`
/// wherever it isn't (S25 finding: an asynchronous provider that was only
/// read never settled, D2 correction pass).
final spokenGuidanceAvailableProvider = Provider<bool>((ref) => false);

/// The SharedPreferences key for the user's choice.
const spokenGuidanceEnabledKey = 'spoken_guidance_enabled_v1';

/// The user's choice: spoken guidance on (the default) or off.
class SpokenGuidanceEnabled extends Notifier<bool> {
  @override
  bool build() {
    final stored = ref
        .read(sharedPreferencesProvider)
        .get(spokenGuidanceEnabledKey);
    return stored is bool ? stored : true;
  }

  void set(bool enabled) {
    state = enabled;
    unawaited(
      ref
          .read(sharedPreferencesProvider)
          .setBool(spokenGuidanceEnabledKey, enabled),
    );
  }
}

final spokenGuidanceEnabledProvider =
    NotifierProvider<SpokenGuidanceEnabled, bool>(SpokenGuidanceEnabled.new);

final guidanceAudioPlayerProvider = Provider<GuidanceAudioPlayer>(
  (ref) => const PlatformGuidanceAudioPlayer(),
);

/// The voice a composed Circle uses: the bundled recordings when every
/// clip is present and the user hasn't turned it off; otherwise silent.
final guidanceVoiceProvider = Provider<GuidanceVoice>((ref) {
  if (!ref.watch(spokenGuidanceAvailableProvider) ||
      !ref.watch(spokenGuidanceEnabledProvider)) {
    return const SilentGuidanceVoice();
  }
  return BundledGuidanceVoice(ref.watch(guidanceAudioPlayerProvider));
});
