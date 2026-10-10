/// Circle Experience V2 (ADR-021): the time and shape of today's Circle as
/// pure functions of a few stored facts — when it started, when (and for
/// how long) it was paused, and the guided step on show. Nothing here ticks
/// or is snapshotted: every value is recomputed from the wall clock, so a
/// Circle restored after the app was backgrounded or killed is exactly where
/// time says it is.
library;

import '../application/activity_catalog.dart';
import 'pace_pattern.dart';

export 'pace_pattern.dart';

/// The Circle's active time at [at]: the wall clock since Start, less every
/// paused stretch — [pausedTotal] already behind it, and the current pause
/// since [pausedAt], if any. Never negative.
Duration activeElapsed({
  required DateTime startedAt,
  required DateTime at,
  DateTime? pausedAt,
  Duration pausedTotal = Duration.zero,
}) {
  final end = pausedAt != null && pausedAt.isBefore(at) ? pausedAt : at;
  final elapsed = end.difference(startedAt) - pausedTotal;
  return elapsed.isNegative ? Duration.zero : elapsed;
}

/// What an Open Circle's card offers at a moment of the session: the first
/// action to begin with, then — one at a time across the middle — the
/// activity's own ideas for while you're there, and at the end its ending
/// line. Authored content only; nothing is generated.
enum OpenPhase { firstAction, idea, ending }

class OpenMoment {
  const OpenMoment(this.phase, [this.ideaIndex = 0]);

  final OpenPhase phase;

  /// Which of the activity's ideas, while [phase] is [OpenPhase.idea].
  final int ideaIndex;

  @override
  bool operator ==(Object other) =>
      other is OpenMoment &&
      other.phase == phase &&
      other.ideaIndex == ideaIndex;

  @override
  int get hashCode => Object.hash(phase, ideaIndex);

  @override
  String toString() => 'OpenMoment($phase, $ideaIndex)';
}

/// How long the first action stays before the first idea: a fifth of the
/// Circle, at least two minutes, never more than half of it.
Duration openFirstActionSpan(Duration offered) {
  final fifth = offered * 0.2;
  const least = Duration(minutes: 2);
  final span = fifth < least ? least : fifth;
  final half = offered * 0.5;
  return span > half ? half : span;
}

/// The Open card's moment [elapsed] into a Circle of [offered] length. The
/// ending line arrives with the natural end and stays.
OpenMoment openMomentFor(
  ActivityDefinition activity, {
  required Duration elapsed,
  required Duration offered,
}) {
  if (elapsed >= offered) return const OpenMoment(OpenPhase.ending);
  final ideas = activity.whileYoureThere;
  final firstSpan = openFirstActionSpan(offered);
  if (ideas.isEmpty || elapsed < firstSpan) {
    return const OpenMoment(OpenPhase.firstAction);
  }
  final ideaSpan = (offered - firstSpan) ~/ ideas.length;
  if (ideaSpan <= Duration.zero) return const OpenMoment(OpenPhase.idea);
  final index = (elapsed - firstSpan).inMicroseconds ~/ ideaSpan.inMicroseconds;
  return OpenMoment(OpenPhase.idea, index.clamp(0, ideas.length - 1));
}

/// A Guided Circle's position: `0 … steps.length - 1` are the authored
/// steps; [guidedFinishPosition] is the "To finish" page after them. Moving
/// on is orientation only — it never records that a step was done.
int guidedFinishPosition(ActivityDefinition activity) => activity.steps.length;

int clampGuidedPosition(ActivityDefinition activity, int position) =>
    position.clamp(0, guidedFinishPosition(activity));

/// Where a paced session is [elapsed] in.
class PaceMoment {
  const PaceMoment({
    required this.cycle,
    required this.phaseIndex,
    required this.phaseElapsed,
    required this.phaseDuration,
    required this.finished,
  });

  /// Zero-based count of completed cycles.
  final int cycle;
  final int phaseIndex;
  final Duration phaseElapsed;
  final Duration phaseDuration;

  /// The pattern's total has been reached; pacing stops.
  final bool finished;

  Duration get phaseRemaining => phaseDuration - phaseElapsed;

  /// 0 → 1 across the current phase.
  double get phaseProgress => phaseDuration <= Duration.zero
      ? 1
      : (phaseElapsed.inMicroseconds / phaseDuration.inMicroseconds).clamp(
          0.0,
          1.0,
        );
}

/// The phase of [pattern] at [elapsed] active time — deterministic, so
/// pacing resumes exactly where it paused.
PaceMoment paceMomentFor(PacePattern pattern, Duration elapsed) {
  final cycle = pattern.cycle;
  final last = pattern.phases.length - 1;
  if (elapsed >= pattern.total || cycle <= Duration.zero) {
    return PaceMoment(
      cycle: cycle <= Duration.zero
          ? 0
          : pattern.total.inMicroseconds ~/ cycle.inMicroseconds,
      phaseIndex: last,
      phaseElapsed: pattern.phases[last].duration,
      phaseDuration: pattern.phases[last].duration,
      finished: true,
    );
  }
  final cycles = elapsed.inMicroseconds ~/ cycle.inMicroseconds;
  var within = Duration(
    microseconds: elapsed.inMicroseconds % cycle.inMicroseconds,
  );
  for (final (index, phase) in pattern.phases.indexed) {
    if (within < phase.duration) {
      return PaceMoment(
        cycle: cycles,
        phaseIndex: index,
        phaseElapsed: within,
        phaseDuration: phase.duration,
        finished: false,
      );
    }
    within -= phase.duration;
  }
  return PaceMoment(
    cycle: cycles,
    phaseIndex: last,
    phaseElapsed: pattern.phases[last].duration,
    phaseDuration: pattern.phases[last].duration,
    finished: false,
  );
}

/// Whether the Circle's natural end — the time the user set aside — has
/// been reached. Time only: it never means the activity was done.
bool naturalEndReached(Duration elapsed, Duration offered) =>
    offered > Duration.zero && elapsed >= offered;
