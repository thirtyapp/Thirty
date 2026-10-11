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

import 'circle_elements.dart';
import 'composed_session.dart';

/// The You setting's words.
abstract final class SpokenGuidanceCopy {
  static const title = 'Spoken guidance';
  static const detail =
      'A voice tells you when each part of your Circle begins, so you '
      'needn’t watch the screen.';
}

/// Where the recordings are bundled.
const spokenGuidanceAssetDir = 'assets/audio/guidance';

/// What a clip is for.
enum SpokenClipRole {
  /// "First." / "Next." / "And last." — said before a part's own clip.
  lead,

  /// One element's name and instruction.
  part,

  /// The words after the last part.
  close,
}

/// One recording: what to say, and where it is bundled.
class SpokenClip {
  SpokenClip._(this.id, this.role, String script)
    // The screen keeps short words together with non-breaking spaces; a
    // speaker reads plain words.
    : script = script.replaceAll(' ', ' ');

  /// A stable name: `lead_next`, `part_getItOut`, `close`.
  final String id;
  final SpokenClipRole role;

  /// Exactly what the speaker says — the words on the screen.
  final String script;

  /// The bundled file: its [id] and a fingerprint of its [script].
  String get asset =>
      '$spokenGuidanceAssetDir/${id}_${_fingerprint(script)}.m4a';

  @override
  bool operator ==(Object other) =>
      other is SpokenClip && other.id == id && other.script == script;

  @override
  int get hashCode => Object.hash(id, script);

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

/// [element]'s own clip: its name, then its instruction.
SpokenClip partClip(CircleElement element) => SpokenClip._(
  'part_${element.id.name}',
  SpokenClipRole.part,
  '${element.name}. ${element.instruction}',
);

/// What the voice plays when part [position] of [plan] begins: where it
/// sits — first, next, or last — then the part itself.
List<SpokenClip> spokenCueFor(CirclePlan plan, int position) {
  final lead = position == 0
      ? leadFirst
      : position == plan.parts.length - 1
      ? leadLast
      : leadNext;
  return [lead, partClip(plan.parts[position].definition)];
}

/// Every clip a release can play — the complete recording list: the three
/// leads, one clip for each offerable element, and the close. Spoken
/// guidance is available only when every one of them is bundled.
List<SpokenClip> get spokenGuidanceManifest => [
  leadFirst,
  leadNext,
  leadLast,
  for (final element in elementLibrary.values)
    if (isElementOfferable(element)) partClip(element),
  spokenEnding,
];
