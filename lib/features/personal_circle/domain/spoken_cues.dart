/// Spoken guidance for a composed Circle (V2 Phase D2, ADR-023 §6): fixed,
/// pre-recorded clips, looked up deterministically — never generated.
///
/// One short lead and the part's own words when a part begins, one line
/// after the last. Nothing between: the voice holds the structure so the
/// user needn't watch the screen, and is never chatty, therapeutic or
/// encouraging. Every clip says exactly the words on the screen.
///
/// **Founder decision (2026-10-11):** bundled, pre-generated, high-quality
/// recordings — no runtime generative AI, no voice API, no device speech
/// engine as the intended experience. [spokenGuidanceManifest] is the
/// complete recording list. A clip's file name carries a fingerprint of
/// its script, so a changed instruction never plays an outdated recording:
/// its new clip is simply missing, and the voice stays silent until the
/// whole set is recorded again.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/l10n/content_locale.dart';

import 'circle_elements.dart';
import 'composed_session.dart';

/// The You setting's words.
abstract final class SpokenGuidanceCopy {
  static const title = 'Spoken guidance';
  static const detail =
      'A voice tells you when each part of your Circle begins, so you '
      'needn’t watch the screen.';

  // The notification while a voiced Circle runs: functional, no score.
  static const sessionRunning = 'Circle running';
  static const sessionPaused = 'Circle paused';
  static const pause = 'Pause';
  static const resume = 'Resume';
  static const next = 'Next';

  /// The choice between THIRTY's voices.
  static const voice = 'Voice';

  /// Plays [voice]'s own introduction ([spokenPreviewFor]).
  static String preview(String voice) => 'Hear $voice';
}

/// Where the recordings are bundled: one folder per [ThirtyVoice].
const spokenGuidanceAssetDir = 'assets/audio/guidance';

/// THIRTY's own voices (founder lock, 2026-10-16): four named voices, all
/// part of Premium's spoken guidance. Each is a complete recording of the
/// same manifest in its own folder.
///
/// [id] is the voice's identity — the stored choice, the asset folder and
/// analytics — neutral and never gender-based. It stays the same for a
/// re-master, a re-generation or new scripts, and gets a new version only
/// when the underlying voice changes. [label] is display metadata.
enum ThirtyVoice {
  locke('voice_locke_v1', 'Locke'),
  heather('voice_heather_v1', 'Heather'),
  milo('voice_milo_v1', 'Milo'),
  brittney('voice_brittney_v1', 'Brittney');

  const ThirtyVoice(this.id, this.label);

  /// Stable: the stored choice and the asset folder.
  final String id;

  /// The voice's name, as the user sees it.
  final String label;

  String get assetDir => '$spokenGuidanceAssetDir/$id';

  static ThirtyVoice? fromId(Object? id) {
    for (final voice in values) {
      if (voice.id == id) return voice;
    }
    return null;
  }
}

/// What a clip is for.
enum SpokenClipRole {
  /// "First." / "Next." / "And last." — said before a part's own clip.
  lead,

  /// One element's name and instruction.
  part,

  /// The words after the last part.
  close,

  /// A voice introducing itself — `Hear <name>` only, never in a Circle.
  preview,

  /// "Your Circle for today." — once, at the user's Start, before "First."
  opening,

  /// "Your next Circle opens tomorrow." — once, after the user's Close.
  nextCircle,
}

/// One recording: what to say, and where it is bundled.
class SpokenClip {
  SpokenClip._(
    this.id,
    this.role,
    String script, [
    this.locale = ContentLocale.english,
  ]) // The screen keeps short words together with non-breaking spaces; a
    // speaker reads plain words.
    : script = script.replaceAll(' ', ' ');

  /// A clip in any [locale], for tests of the language rules only: no
  /// production path makes a clip without approved words.
  @visibleForTesting
  SpokenClip.forTesting(
    String id,
    SpokenClipRole role,
    String script,
    ContentLocale locale,
  ) : this._(id, role, script, locale);

  /// A stable name: `lead_next`, `part_getItOut`, `close`.
  final String id;
  final SpokenClipRole role;

  /// Exactly what the speaker says — the words on the screen.
  final String script;

  /// The language [script] is in (ADR-025 §7). A clip is played only in
  /// that language's rendition of a voice ([spokenAssetIn]).
  final ContentLocale locale;

  /// The recording's file name: its [id] and a fingerprint of its
  /// [script] — the same in each voice's folder.
  String get file => '${id}_${_fingerprint(script)}.m4a';

  /// This English clip as recorded in [voice]'s English rendition — the
  /// frozen layout. For a clip in any language, [spokenAssetIn].
  String assetFor(ThirtyVoice voice) {
    assert(locale == ContentLocale.english, 'use spokenAssetIn');
    return '${voice.assetDir}/$file';
  }

  @override
  bool operator ==(Object other) =>
      other is SpokenClip &&
      other.id == id &&
      other.script == script &&
      other.locale == locale;

  @override
  int get hashCode => Object.hash(id, script, locale);

  @override
  String toString() => '$id: $script';
}

/// A stable 32-bit FNV-1a fingerprint, as 8 hex digits.
String _fingerprint(String text) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(text)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

final leadFirst = SpokenClip._('lead_first', SpokenClipRole.lead, 'First.');
final leadNext = SpokenClip._('lead_next', SpokenClipRole.lead, 'Next.');
final leadLast = SpokenClip._('lead_last', SpokenClipRole.lead, 'And last.');

/// What the voice says after the last part.
final spokenEnding = SpokenClip._(
  'close',
  SpokenClipRole.close,
  ComposedCopy.ending,
);

/// What the voice says at the user's Start, before "First." (founder
/// approval, 2026-10-26: F02) — the heading on show while it is spoken.
final spokenOpening = SpokenClip._(
  'opening',
  SpokenClipRole.opening,
  ComposedCopy.opening,
);

/// What the voice says after the user's Close (founder approval,
/// 2026-10-26: F03) — the closed Circle's own line, said only when it is
/// true: the Circle closed on its own day.
final spokenNextCircle = SpokenClip._(
  'next_circle',
  SpokenClipRole.nextCircle,
  ComposedCopy.nextCircle,
);

/// The Circle's spoken opening and closing lines. Not part of
/// [spokenGuidanceManifest]: a voice without them still guides every part,
/// and a line that can't be played is skipped, never an error.
List<SpokenClip> get spokenFramingClips =>
    spokenFramingClipsIn(ContentLocale.english)!;

/// [element]'s own clip, in English: its name, then its instruction
/// ([partClipIn]).
SpokenClip partClip(CircleElement element) =>
    partClipIn(element, ContentLocale.english)!;

/// What the voice plays when part [position] of [plan] begins, in English
/// ([spokenCueIn]).
List<SpokenClip> spokenCueFor(CirclePlan plan, int position) =>
    spokenCueIn(plan, position, ContentLocale.english)!;

/// What [voice]'s preview plays: the voice saying its name and what it
/// does — its own recording, never one of a Circle's activities (founder,
/// 2026-10-17). Each voice's script differs only by its name.
SpokenClip spokenPreviewFor(ThirtyVoice voice) => SpokenClip._(
  'preview',
  SpokenClipRole.preview,
  'Hi, I’m ${voice.label}. I’ll tell you when each part of your Circle '
      'begins, so you can put the screen down.',
);

/// Every English clip a release can play — the complete recording list
/// ([spokenGuidanceManifestIn]).
List<SpokenClip> get spokenGuidanceManifest =>
    spokenGuidanceManifestIn(ContentLocale.english)!;

// The language-aware interface (ADR-025 §7; L-CONTENT-AUDIO). Each answer is
// for one content language and is `null` (or empty) where that language has
// no approved words or recordings — never another language's. English is
// the only content language with approved words and recordings.

/// THIRTY's voices with a founder-approved rendition in [locale]: all four
/// in English (founder approval 2026-10-17; the frozen pack). None in any
/// other language until one is approved (D-V-1…D-V-5).
Set<ThirtyVoice> approvedRenditionsIn(ContentLocale locale) =>
    locale == ContentLocale.english ? ThirtyVoice.values.toSet() : const {};

/// The folder of [voice]'s rendition in [locale], or `null` where there is
/// none. English keeps its frozen layout (`<spokenGuidanceAssetDir>/<id>`);
/// another language's layout is ADR-027's to decide.
String? renditionAssetDirIn(ThirtyVoice voice, ContentLocale locale) =>
    locale == ContentLocale.english &&
        approvedRenditionsIn(locale).contains(voice)
    ? voice.assetDir
    : null;

/// Where [clip] is recorded in [voice]: in the rendition of [clip]'s own
/// language — or `null` where [voice] has none in it. Never a recording in
/// another language.
String? spokenAssetIn(SpokenClip clip, ThirtyVoice voice) {
  final dir = renditionAssetDirIn(voice, clip.locale);
  return dir == null ? null : '$dir/${clip.file}';
}

/// Whether [clips] are all in one language: the only kind of sequence
/// THIRTY's voice plays. A session never mixes languages.
bool spokenInOneLanguage(Iterable<SpokenClip> clips) =>
    {for (final clip in clips) clip.locale}.length <= 1;

/// [element]'s clip in [locale]: its name, then its instruction, in that
/// language's approved words ([elementWordingIn]) — or `null` where there
/// are none.
SpokenClip? partClipIn(CircleElement element, ContentLocale locale) {
  final words = elementWordingIn(element, locale);
  if (words == null) return null;
  return SpokenClip._(
    'part_${element.id.name}',
    SpokenClipRole.part,
    _partScript(words),
    locale,
  );
}

/// A part's spoken words: the element's name, then its instruction — the
/// same template as before L-CONTENT-AUDIO, so every English script and
/// fingerprint is unchanged.
String _partScript(PartWording element) =>
    '${element.name}. ${element.instruction}';

/// The lines around a Circle's parts in [locale] — the three leads, the
/// ending, and the framing lines — or `null` where [locale] has no approved
/// spoken words.
({
  SpokenClip first,
  SpokenClip next,
  SpokenClip last,
  SpokenClip ending,
  SpokenClip opening,
  SpokenClip nextCircle,
})?
spokenFrameIn(ContentLocale locale) => locale == ContentLocale.english
    ? (
        first: leadFirst,
        next: leadNext,
        last: leadLast,
        ending: spokenEnding,
        opening: spokenOpening,
        nextCircle: spokenNextCircle,
      )
    : null;

/// What the voice plays when part [position] of [plan] begins, in [locale]:
/// where it sits — first, next, or last — then the part itself. `null` when
/// [locale] lacks any of it: never a sequence partly in another language.
List<SpokenClip>? spokenCueIn(
  CirclePlan plan,
  int position,
  ContentLocale locale,
) {
  final frame = spokenFrameIn(locale);
  final part = partClipIn(plan.parts[position].definition, locale);
  if (frame == null || part == null) return null;
  final lead = position == 0
      ? frame.first
      : position == plan.parts.length - 1
      ? frame.last
      : frame.next;
  return [lead, part];
}

/// [voice]'s preview in [locale], or `null` where [locale] has no approved
/// spoken words.
SpokenClip? spokenPreviewIn(ThirtyVoice voice, ContentLocale locale) =>
    locale == ContentLocale.english ? spokenPreviewFor(voice) : null;

/// The framing lines in [locale] ([spokenFramingClips]), or `null`.
List<SpokenClip>? spokenFramingClipsIn(ContentLocale locale) =>
    switch (spokenFrameIn(locale)) {
      final frame? => [frame.opening, frame.nextCircle],
      null => null,
    };

/// The complete recording list in [locale]: the three leads, one clip for
/// each offerable element, and the close. A voice is available only when
/// every one of them is bundled in its rendition. `null` when [locale] has
/// no approved words for any of them.
List<SpokenClip>? spokenGuidanceManifestIn(ContentLocale locale) {
  final frame = spokenFrameIn(locale);
  if (frame == null) return null;
  final parts = <SpokenClip>[];
  for (final element in elementLibrary.values) {
    if (!isElementOfferable(element)) continue;
    final clip = partClipIn(element, locale);
    if (clip == null) return null;
    parts.add(clip);
  }
  return [frame.first, frame.next, frame.last, ...parts, frame.ending];
}
