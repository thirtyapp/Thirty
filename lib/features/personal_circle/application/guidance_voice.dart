import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A voice that speaks a composed Circle's cues (V2 Phase D2, ADR-023 §6):
/// local, with no runtime generative AI and no per-use cost.
///
/// **No voice is wired in yet.** Pre-recorded authored cues (the quality
/// path) or the device's own speech engine (needs a platform bridge and a
/// founder audition) are both open founder decisions. Until one meets
/// THIRTY's quality bar, [SilentGuidanceVoice] is the only implementation:
/// the Circle's on-screen guidance and its live TalkBack announcements are
/// complete without it, and nothing cheap-sounding ships to tick a box.
abstract interface class GuidanceVoice {
  /// Whether this voice can speak at all.
  bool get available;

  /// Says [text] once, replacing anything still being said.
  Future<void> say(String text);

  /// Stops speaking — at Pause, Close or leaving the Circle.
  Future<void> stop();
}

/// Says nothing.
class SilentGuidanceVoice implements GuidanceVoice {
  const SilentGuidanceVoice();

  @override
  bool get available => false;

  @override
  Future<void> say(String text) async {}

  @override
  Future<void> stop() async {}
}

/// The voice a composed Circle uses. Silent until a voice is approved.
final guidanceVoiceProvider = Provider<GuidanceVoice>(
  (ref) => const SilentGuidanceVoice(),
);
