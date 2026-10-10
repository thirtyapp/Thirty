/// A Paced Circle's pattern (PRODUCT_V2_CONTRACT — Paced, ADR-021): named
/// phases repeating in order for a bounded total. Only a separate
/// safety/content review may supply one for a catalogue activity; until then
/// every catalogue activity carries none.
library;

/// One phase of a [PacePattern] — a label and how long it lasts.
class PacePhase {
  const PacePhase(this.label, this.duration);

  final String label;
  final Duration duration;
}

class PacePattern {
  const PacePattern({required this.phases, required this.total});

  /// At least one phase.
  final List<PacePhase> phases;

  /// How long pacing runs in all.
  final Duration total;

  /// One pass through every phase.
  Duration get cycle =>
      phases.fold(Duration.zero, (sum, phase) => sum + phase.duration);
}
