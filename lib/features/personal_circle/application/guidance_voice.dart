import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/content_locale.dart';
import '../../../core/premium/premium_access.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../domain/spoken_cues.dart';

/// The voice that speaks a composed Circle's cues (V2 Phase D2, ADR-023
/// §6): bundled recordings, played offline — no runtime generative AI, no
/// voice API, no per-use cost.
///
/// THIRTY's voice is a Premium service layer (founder decision,
/// 2026-10-12). Accessibility is not: a screen reader's announcements of
/// the Circle come from its semantics, whatever the entitlement, and
/// never from here.
///
/// Spoken guidance is an addition, never a dependency: the Circle's
/// on-screen guidance and its TalkBack announcements are complete without
/// it, and when anything is missing — a recording, the platform player —
/// the voice is silent, never broken.
abstract interface class GuidanceVoice {
  /// Whether this voice can speak at all.
  bool get available;

  /// Plays [clips] in order, replacing anything still playing — or, with
  /// [afterCurrent], once what is playing has been said. With
  /// [deferToScreenReader], nothing plays while a screen reader is on: its
  /// own announcement of the part speaks instead.
  Future<void> play(
    List<SpokenClip> clips, {
    bool deferToScreenReader,
    bool afterCurrent,
  });

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
    bool afterCurrent = false,
  }) async {}

  @override
  Future<void> stop() async {}
}

/// Plays [voice]'s bundled recordings through [player].
class BundledGuidanceVoice implements GuidanceVoice {
  const BundledGuidanceVoice(this.player, this.voice);

  final GuidanceAudioPlayer player;
  final ThirtyVoice voice;

  @override
  bool get available => true;

  /// Plays [clips] only when they are all in one language and every one is
  /// recorded in [voice]'s rendition of it ([spokenAssetIn]); otherwise
  /// says nothing — never a mixed-language sequence, never a clip borrowed
  /// from another language (ADR-025 §7).
  @override
  Future<void> play(
    List<SpokenClip> clips, {
    bool deferToScreenReader = false,
    bool afterCurrent = false,
  }) async {
    final assets = [for (final clip in clips) spokenAssetIn(clip, voice)];
    if (!spokenInOneLanguage(clips) || assets.contains(null)) return;
    await player.play(
      [for (final asset in assets) asset!],
      deferToScreenReader: deferToScreenReader,
      afterCurrent: afterCurrent,
    );
  }

  @override
  Future<void> stop() => player.stop();
}

/// Plays bundled audio assets, one after another.
abstract interface class GuidanceAudioPlayer {
  /// Plays [assets] in order, replacing anything still playing — or, with
  /// [afterCurrent], once what is playing has been said. With
  /// [deferToScreenReader], nothing plays while the platform's screen reader
  /// is on (Android: touch exploration).
  Future<void> play(
    List<String> assets, {
    bool deferToScreenReader,
    bool afterCurrent,
  });
  Future<void> stop();
}

/// The platform's own player (Android: `GuidanceAudio.kt`), over a method
/// channel. Where there is none, it does nothing.
class PlatformGuidanceAudioPlayer implements GuidanceAudioPlayer {
  const PlatformGuidanceAudioPlayer();

  static const _channel = MethodChannel('com.thirty.app/guidance_audio');

  @override
  Future<void> play(
    List<String> assets, {
    bool deferToScreenReader = false,
    bool afterCurrent = false,
  }) => _call('play', {
    'assets': assets,
    'deferToScreenReader': deferToScreenReader,
    'afterCurrent': afterCurrent,
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

/// The voices whose every clip in [spokenGuidanceManifest], and whose
/// preview, [bundle] holds.
/// A partial set is no set: a voice never speaks some parts and not
/// others. Read once at start-up (`main.dart`), so nothing waits on it
/// later.
Future<Set<ThirtyVoice>> bundledGuidanceVoices(AssetBundle bundle) async {
  final manifest = await AssetManifest.loadFromAssetBundle(bundle);
  return completeGuidanceVoicesIn(
    manifest.listAssets().toSet(),
    currentContentLocale,
  );
}

/// The voices with every clip of [spokenGuidanceManifest], and their own
/// preview, among [assets]. A clip recorded for an older script has another
/// file name, so it never counts.
Set<ThirtyVoice> completeGuidanceVoices(Set<String> assets) =>
    completeGuidanceVoicesIn(assets, ContentLocale.english);

/// The voices with a founder-approved rendition in [locale] whose every
/// clip of [locale]'s manifest, and its own preview, is among [assets]
/// (ADR-025 §7.3). Empty where [locale] has no approved words or no
/// approved rendition: a language without its own complete recordings has
/// no voice — it never borrows another language's.
Set<ThirtyVoice> completeGuidanceVoicesIn(
  Set<String> assets,
  ContentLocale locale,
) {
  final manifest = spokenGuidanceManifestIn(locale);
  if (manifest == null) return const {};
  bool recorded(SpokenClip? clip, ThirtyVoice voice) {
    final asset = clip == null ? null : spokenAssetIn(clip, voice);
    return asset != null && assets.contains(asset);
  }

  return {
    for (final voice in approvedRenditionsIn(locale))
      if ([
        ...manifest,
        spokenPreviewIn(voice, locale),
      ].every((clip) => recorded(clip, voice)))
        voice,
  };
}

/// The voices this build bundles. Overridden at start-up with
/// [bundledGuidanceVoices]; none wherever it isn't (S25 finding: an
/// asynchronous provider that was only read never settled, D2 correction
/// pass).
final bundledGuidanceVoicesProvider = Provider<Set<ThirtyVoice>>(
  (ref) => const {},
);

/// Whether spoken guidance exists in this build at all.
final spokenGuidanceAvailableProvider = Provider<bool>(
  (ref) => ref.watch(bundledGuidanceVoicesProvider).isNotEmpty,
);

/// Whether this user may hear THIRTY's voice now: Premium is active and
/// the build bundles a voice. On Free — a kept Circle included — the
/// Circle runs complete without it, on screen and through the screen
/// reader. Follows the entitlement: a lapse silences the voice, a
/// resubscription brings it back, with the user's choices as they were.
final spokenGuidanceOfferedProvider = Provider<bool>(
  (ref) =>
      ref.watch(spokenGuidanceAvailableProvider) &&
      ref.watch(premiumEntitlementProvider),
);

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

/// The SharedPreferences key for the user's choice of voice.
const thirtyVoiceKey = 'spoken_guidance_voice_v1';

/// The user's choice of voice — a local preference, never asked during
/// onboarding. Kept through a lapse and never erased by one, so a
/// resubscription speaks in the voice chosen before.
class ThirtyVoiceChoice extends Notifier<ThirtyVoice> {
  @override
  ThirtyVoice build() =>
      ThirtyVoice.fromId(
        ref.read(sharedPreferencesProvider).get(thirtyVoiceKey),
      ) ??
      ThirtyVoice.values.first;

  void set(ThirtyVoice voice) {
    state = voice;
    unawaited(
      ref.read(sharedPreferencesProvider).setString(thirtyVoiceKey, voice.id),
    );
  }
}

final thirtyVoiceChoiceProvider =
    NotifierProvider<ThirtyVoiceChoice, ThirtyVoice>(ThirtyVoiceChoice.new);

/// The voice that speaks: the user's choice when this build bundles it,
/// otherwise the first bundled one; none when nothing is bundled.
final thirtyVoiceProvider = Provider<ThirtyVoice?>((ref) {
  final bundled = ref.watch(bundledGuidanceVoicesProvider);
  if (bundled.isEmpty) return null;
  final chosen = ref.watch(thirtyVoiceChoiceProvider);
  if (bundled.contains(chosen)) return chosen;
  for (final voice in ThirtyVoice.values) {
    if (bundled.contains(voice)) return voice;
  }
  return null;
});

final guidanceAudioPlayerProvider = Provider<GuidanceAudioPlayer>(
  (ref) => const PlatformGuidanceAudioPlayer(),
);

/// The voice a composed Circle uses: the bundled recordings of the user's
/// voice while Premium is active and the user hasn't turned it off;
/// otherwise silent. Silent means no session either — the conductor opens
/// the background service only for a voice that is available.
final guidanceVoiceProvider = Provider<GuidanceVoice>((ref) {
  if (!ref.watch(spokenGuidanceOfferedProvider) ||
      !ref.watch(spokenGuidanceEnabledProvider)) {
    return const SilentGuidanceVoice();
  }
  final voice = ref.watch(thirtyVoiceProvider);
  if (voice == null) return const SilentGuidanceVoice();
  return BundledGuidanceVoice(ref.watch(guidanceAudioPlayerProvider), voice);
});
