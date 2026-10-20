import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';

/// The composer's answers for a fixed set of representative days, one line
/// each — what the baseline-equivalence test compares against
/// `fixtures/composer_b1_baseline.txt` (ADR-024 B2: without a StageBrief the
/// Personal Guided Circle composer behaves exactly as it did in B1).
///
/// Covers every need × time window, positive and negative evidence (composed
/// and single-activity), rests, Leave it out, Don't suggest, yesterday's main
/// piece, the weekly caps, each "Not this one today" constraint, and a
/// sparse library.
List<String> composerBaselineLines() {
  final lines = <String>[];
  final start = DateTime(2026, 10, 1, 9);

  String describe(ComposedCircle? circle) => circle == null
      ? 'null'
      : '${circle.plan.toWire().join(',')} ${circle.basis.name} '
            '${circle.trace}';

  ComposedCircle? run(
    String label,
    ComposerContext context,
    List<PastCircle> history, {
    SuggestionControls controls = SuggestionControls.none,
    Set<ElementId> leftOut = const {},
  }) {
    final circle = composeCircle(
      context,
      history,
      controls: controls,
      leftOut: leftOut,
    );
    lines.add('$label => ${describe(circle)}');
    return circle;
  }

  PastCircle composedDay(
    DateTime date,
    Intention need,
    CirclePlan plan, {
    PastUsefulness? answer,
    List<ElementId> skipped = const [],
  }) => PastCircle(
    date: date,
    need: need,
    activityId: plan.main.definition.art,
    catalogVersion: catalogVersion,
    usefulness: answer,
    answeredAt: answer == null ? null : date,
    components: plan.activities,
    parts: plan.toWire(),
    skipped: [for (final s in skipped) s.name],
  );

  PastCircle freeDay(
    DateTime date,
    Intention need,
    ActivityId activity,
    PastUsefulness answer,
  ) => PastCircle(
    date: date,
    need: need,
    activityId: activity,
    catalogVersion: catalogVersion,
    usefulness: answer,
    answeredAt: date,
  );

  // 1. No history: every need × window on a fortnight of dates.
  for (final need in Intention.values) {
    for (final window in TimeWindow.values) {
      for (var day = 0; day < 14; day++) {
        run(
          'fresh ${need.name} ${window.name} d$day',
          ComposerContext(
            date: start.add(Duration(days: day)),
            need: need,
            window: window,
          ),
          const [],
        );
      }
    }
  }

  // 2. Thirty days of one need and time, with answers, single-activity
  //    days, and each "Not this one today" constraint along the way. Run
  //    plainly, and again under the user's own controls.
  const answers = [
    PastUsefulness.veryUseful,
    null,
    PastUsefulness.somewhatUseful,
    PastUsefulness.notUseful,
    null,
  ];
  const freeActivities = {
    Intention.moreEnergy: ActivityId.energisingStretchFlow,
    Intention.clearerHead: ActivityId.tidyOneSurface,
    Intention.gentlerPace: ActivityId.gentleStretchPause,
  };
  final variants = <String, (SuggestionControls, Set<ElementId>)>{
    'plain': (SuggestionControls.none, const {}),
    'controlled': (
      const SuggestionControls(
        notSuggested: {
          (ActivityId.moveToMusic, Intention.moreEnergy),
          (ActivityId.writeItDown, Intention.clearerHead),
          (ActivityId.quietReading, Intention.gentlerPace),
        },
      ),
      {ElementId.sitAMinute, ElementId.standingStretch, ElementId.daylight},
    ),
  };
  for (final MapEntry(key: variant, value: (controls, leftOut))
      in variants.entries) {
    for (final need in Intention.values) {
      for (final window in TimeWindow.values) {
        final history = <PastCircle>[];
        for (var day = 0; day < 30; day++) {
          final date = start.add(Duration(days: day));
          final label = '$variant ${need.name} ${window.name} d$day';
          final context = ComposerContext(
            date: date,
            need: need,
            window: window,
          );
          if (day % 9 == 4) {
            // A Free day with a single-activity answer — a rest when
            // "Not useful".
            history.add(
              freeDay(
                date,
                need,
                freeActivities[need]!,
                day.isEven
                    ? PastUsefulness.notUseful
                    : PastUsefulness.veryUseful,
              ),
            );
            lines.add('$label => free');
            continue;
          }
          var circle = run(
            label,
            context,
            history,
            controls: controls,
            leftOut: leftOut,
          );
          if (circle == null) continue;
          final reason = switch (day % 6) {
            1 => ReplacementReason.tooMuch,
            3 => ReplacementReason.notFeeling,
            5 => ReplacementReason.cantGoOutside,
            _ => null,
          };
          if (reason != null) {
            final replaced = run(
              '$label ${reason.name}',
              ComposerContext(
                date: date,
                need: need,
                window: window,
                constraint: CompositionConstraint(
                  reason: reason,
                  replacing: circle.plan,
                ),
              ),
              history,
              controls: controls,
              leftOut: leftOut,
            );
            if (replaced != null) circle = replaced;
          }
          history.add(
            composedDay(
              date,
              need,
              circle.plan,
              answer: answers[day % answers.length],
              skipped: day % 7 == 6 ? [circle.plan.parts.last.element] : [],
            ),
          );
        }
      }
    }
  }

  // 3. Needs in turn, so recency and evidence cross needs and windows.
  final mixed = <PastCircle>[];
  for (var day = 0; day < 30; day++) {
    final date = start.add(Duration(days: day));
    final need = Intention.values[day % 3];
    final window = TimeWindow.values[(day ~/ 3) % 3];
    final circle = run(
      'mixed ${need.name} ${window.name} d$day',
      ComposerContext(date: date, need: need, window: window),
      mixed,
    );
    if (circle == null) continue;
    mixed.add(composedDay(date, need, circle.plan, answer: answers[day % 5]));
  }

  // 4. A sparse library: almost everything left out.
  final keep = {
    ElementId.getItOut,
    ElementId.standingStretch,
    ElementId.gentleStretch,
    ElementId.sitAMinute,
    ElementId.phoneFaceDown,
  };
  final sparse = {
    for (final id in ElementId.values)
      if (!keep.contains(id)) id,
  };
  for (final need in Intention.values) {
    for (final window in TimeWindow.values) {
      run(
        'sparse ${need.name} ${window.name}',
        ComposerContext(date: start, need: need, window: window),
        const [],
        leftOut: sparse,
      );
    }
  }
  return lines;
}
