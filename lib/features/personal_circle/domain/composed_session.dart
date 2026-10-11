/// Today's composed Circle (V2 Phase D2, ADR-023 §4–§5): a Personal Guided
/// Circle the composer made, or a Circle the user kept and chose to use
/// today. Persisted with today's Circle so a restart restores exactly what
/// was offered — never recomposed.
library;

import '../../home/application/activity_catalog.dart';
import '../../home/domain/recommendation_engine.dart';
import 'circle_composer.dart';
import 'circle_elements.dart';

/// The words a composed Circle uses, in one place (founder-reviewable in
/// the D2 content pack).
abstract final class ComposedCopy {
  /// The Today card's label, and the journal's title for a composed Circle.
  static const title = 'Your Circle';

  /// The greeting's line before Start, on a composed day.
  static const greetingSubline = 'Here’s your Circle for today.';

  /// The ending after the last part.
  static const ending = 'That’s your Circle. Take a moment before you move on.';

  /// The one line under a composed Circle — only what is true.
  static String basisLine(CompositionBasis basis, TimeWindow window) =>
      switch (basis) {
        CompositionBasis.foundUseful =>
          'Built from things you’ve found useful, to fit your '
              '${window.maxMinutes} minutes.',
        CompositionBasis.sized =>
          'Small parts, one after another, to fit your '
              '${window.maxMinutes} minutes.',
      };

  /// The line under a kept Circle the user chose for today.
  static const keptLine = 'A Circle you kept.';

  /// A Premium day when no honest composition existed (ADR-023 §4).
  static const fallbackLine = 'Today, one activity fits better than a mix.';

  /// How a composed Circle runs, said once in its how-to.
  static const howItRuns =
      'A few small parts, one after another. When a part’s time is up, the '
      'next one begins — or move on whenever you’re ready.';

  /// The running Circle's line under a part: where it sits, and what comes
  /// next — context, never a countdown.
  static String partDetail(int position, int count, String? next) =>
      next == null
      ? 'Part ${position + 1} of $count · the last part'
      : 'Part ${position + 1} of $count · next: $next';

  /// "Skip this step" — the running card's quiet control and its sheet.
  static const skip = 'Skip';
  static const skipTitle = 'Skip this part?';
  static const skipToday = 'Skip it for today';
  static const skipTodayDetail =
      'The next part begins. Nothing is recorded '
      'against this one.';
  static const leaveOut = 'Leave it out next time';
  static const leaveOutDetail =
      'THIRTY won’t put it in your Circles again. You can bring it back in '
      'What THIRTY remembers.';
  static const keepGoing = 'Keep going';

  /// How long a part takes, as its cue.
  static String partCue(int minutes) =>
      minutes == 1 ? 'About 1 minute' : 'About $minutes minutes';
}

/// Today's composed Circle.
class ComposedSession {
  const ComposedSession({
    required this.plan,
    this.basis,
    this.keptCircleId,
    this.keptName,
  });

  final CirclePlan plan;

  /// What the composer may say about it; `null` for a kept Circle.
  final CompositionBasis? basis;

  /// The kept Circle the user chose ("Use it today"), when it is one.
  final String? keptCircleId;
  final String? keptName;

  bool get isKept => keptCircleId != null;

  /// What it is called: "Your Circle", or the kept Circle's name.
  String get title => keptName ?? ComposedCopy.title;

  Map<String, Object?> toJson() => {
    'parts': plan.toWire(),
    'basis': basis?.name,
    'keptCircleId': keptCircleId,
    'keptName': keptName,
  };

  static ComposedSession? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final plan = CirclePlan.fromWire(raw['parts']);
    if (plan == null) return null;
    final keptCircleId = raw['keptCircleId'];
    final keptName = raw['keptName'];
    final basis = CompositionBasis.values.asNameMap()[raw['basis']];
    // A composed Circle is restored whole: one the composer made says what
    // it may claim; a kept one is named.
    if (keptCircleId is! String && basis == null) return null;
    return ComposedSession(
      plan: plan,
      basis: basis,
      keptCircleId: keptCircleId is String ? keptCircleId : null,
      keptName: keptName is String && keptName.trim().isNotEmpty
          ? keptName
          : null,
    );
  }
}

/// The Guided-shaped session [plan] runs as in the Circle: one part a time,
/// each a step with its authored instruction and length, then the composed
/// ending. Phase C's shell runs it; the composed body times the parts.
ActivityDefinition sessionForPlan(CirclePlan plan, {required String title}) {
  final main = plan.main.definition;
  final settings = {for (final p in plan.parts) p.definition.setting};
  final efforts = {for (final p in plan.parts) p.definition.effort};
  final sources = [
    for (final p in plan.parts)
      if (p.definition.from case final from?) activityDefinition(from),
  ];
  return ActivityDefinition(
    title: title,
    fit: {
      for (final need in Intention.values)
        need: plan.parts.every((p) => p.definition.fits(need))
            ? NeedFit.primary
            : NeedFit.none,
    },
    minMinutes: plan.minutes,
    typicalMinutes: plan.minutes,
    mode: CircleMode.guidedSteps,
    status: ActivityStatus.live,
    v1Learning: LearningCompatibility.reset,
    reasons: {
      for (final need in Intention.values) need: ComposedCopy.howItRuns,
    },
    firstAction: plan.parts.first.definition.instruction,
    preparation: main.from == null
        ? null
        : activityDefinition(main.from!).preparation,
    steps: [
      for (final part in plan.parts)
        GuidedStep(
          name: part.definition.name,
          instruction: part.definition.instruction,
          cue: ComposedCopy.partCue(part.minutes),
        ),
    ],
    // The pieces' own comfort and stop guidance, where they have it.
    safetyNote: sources
        .map((source) => source.safetyNote)
        .whereType<String>()
        .firstOrNull,
    ending: ComposedCopy.ending,
    family: activityFamily(main.art),
    category: activityCategory(main.art),
    worldRole: activityWorldRole(main.art),
    setting: settings.contains(ActivitySetting.outdoor)
        ? ActivitySetting.outdoor
        : settings.contains(ActivitySetting.indoor)
        ? ActivitySetting.indoor
        : ActivitySetting.either,
    effort: efforts.contains(ActivityEffort.moderate)
        ? ActivityEffort.moderate
        : ActivityEffort.low,
  );
}

/// Where a composed Circle is: the part on show and how far into it.
class PartMoment {
  const PartMoment({
    required this.position,
    required this.partElapsed,
    required this.partLength,
    required this.parts,
  });

  /// `0 … parts - 1`: a part; [parts]: past the last one ("To finish").
  final int position;
  final Duration partElapsed;
  final Duration partLength;
  final int parts;

  bool get finished => position >= parts;
}

/// The part on show [elapsed] into a composed Circle (ADR-023 §5). THIRTY
/// holds the structure: when a part's authored time is up the next one
/// takes over by itself, counted from the last place the user put the
/// Circle — [anchorPosition], [anchorElapsed] into it (Start, Next, Back
/// or Skip). Pure, from stored facts, like every Phase C runtime value: a
/// resume or a restart lands exactly here. Moving on is orientation only;
/// it never records that a part was done.
PartMoment partMomentFor(
  CirclePlan plan, {
  required int anchorPosition,
  required Duration anchorElapsed,
  required Duration elapsed,
}) {
  final count = plan.parts.length;
  var position = anchorPosition.clamp(0, count);
  var start = anchorElapsed > elapsed ? elapsed : anchorElapsed;
  while (position < count) {
    final length = Duration(minutes: plan.parts[position].minutes);
    final into = elapsed - start;
    if (into < length) {
      return PartMoment(
        position: position,
        partElapsed: into,
        partLength: length,
        parts: count,
      );
    }
    start += length;
    position++;
  }
  return PartMoment(
    position: count,
    partElapsed: Duration.zero,
    partLength: Duration.zero,
    parts: count,
  );
}
