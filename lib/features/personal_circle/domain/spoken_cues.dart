/// Spoken guidance for a composed Circle (V2 Phase D2, ADR-023 §6): what a
/// voice would say, derived from the authored elements — never generated.
///
/// One short line when a part begins, one at the end. Nothing between: the
/// voice holds the structure so the user needn't watch the screen, and is
/// never chatty, therapeutic or encouraging. No voice ships until one meets
/// THIRTY's quality bar ([GuidanceVoice] — a D2 blocking quality task).
library;

import 'circle_elements.dart';
import 'composed_session.dart';

/// What the voice says when part [position] of [plan] begins: where it
/// sits, its name, and what to do — the same words as the screen.
String spokenCueFor(CirclePlan plan, int position) {
  final part = plan.parts[position];
  final element = part.definition;
  final lead = position == 0 ? 'First' : 'Next';
  return '$lead: ${element.name}. ${element.instruction}';
}

/// What the voice says after the last part.
const spokenEnding = ComposedCopy.ending;
