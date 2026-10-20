import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/stage_brief.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';

/// ADR-024 B5 — I2's "Keep this Plan's Circles gentler for now" on every
/// frozen stage: the 15 StageBriefs × ≈10 / ≈20 / up to 30, each brief
/// with every part low-effort and composed one size down (never below
/// ≈10). No stage stalls, and every gate still holds.
void main() {
  final today = DateTime(2026, 10, 12, 9);

  StageBrief stage(String id) {
    if (!stageFiveIds.containsKey(id)) return stageBriefById[id]!;
    final plan = id.substring(0, id.indexOf('.'));
    final five = stageFive(id, [
      for (var i = 1; i <= 4; i++) EarlierStage('$plan.$i'),
    ], today);
    return (five as StageFiveBriefs).briefs.first;
  }

  // Gate-passing low-effort shapes at the gentler size: ≈10 · ≈20 · up to
  // 30 (≈10 and ≈20 both compose at ≈10).
  const frozen = {
    'getting_going.1': [27, 27, 49],
    'getting_going.2': [48, 48, 35],
    'getting_going.3': [9, 9, 86],
    'getting_going.4': [11, 11, 98],
    'getting_going.5': [12, 12, 104],
    'making_room.1': [198, 198, 1658],
    'making_room.2': [262, 262, 2857],
    'making_room.3': [48, 48, 1246],
    'making_room.4': [47, 47, 1379],
    'making_room.5': [19, 19, 1147],
    'slowing_down.1': [57, 57, 348],
    'slowing_down.2': [104, 104, 887],
    'slowing_down.3': [106, 106, 1184],
    'slowing_down.4': [50, 50, 659],
    'slowing_down.5': [72, 72, 847],
  };

  test('one size down, never below ≈10', () {
    expect(gentlerWindow(TimeWindow.upTo30), TimeWindow.about20);
    expect(gentlerWindow(TimeWindow.about20), TimeWindow.about10);
    expect(gentlerWindow(TimeWindow.about10), TimeWindow.about10);
  });

  var cells = 0;
  for (final MapEntry(key: id, value: expected) in frozen.entries) {
    for (final (index, window) in TimeWindow.values.indexed) {
      cells++;
      test('$id at ${window.name}: PASS, ${expected[index]} shapes', () {
        final brief = stage(id);
        final gentler = brief.gentler();
        final size = gentler.sizeFor(gentlerWindow(window));
        final allowed = [
          for (final e in elementLibrary.values)
            if (isElementOfferable(e) &&
                e.fits(brief.need) &&
                e.effort == ActivityEffort.low)
              e,
        ];
        final shapes = [
          for (final parts in gatePassingShapes(allowed, window: size))
            if (gentler.accepts(parts, size: size)) parts,
        ];
        expect(shapes.length, expected[index]);
        // The production composer composes one, honestly, for a gentler
        // stage — the stage's own brief still holds (C1).
        final context = gentlerContext(
          ComposerContext(date: today, need: brief.need, window: window),
        );
        final result = composeStage(context, const [], [gentler]);
        expect(result, isA<StageComposed>());
        final plan = (result as StageComposed).circle.plan;
        expect(plan.minutes, lessThanOrEqualTo(size));
        expect(brief.accepts(plan.parts, size: size), isTrue);
        for (final p in plan.parts) {
          expect(p.definition.effort, ActivityEffort.low);
          expect(isElementOfferable(p.definition), isTrue);
          expect(p.definition.fits(brief.need), isTrue);
        }
      });
    }
  }
  test('45 cells', () => expect(cells, 45));

  test('a gentler brief only adds a condition: what it accepts, the brief '
      'accepts', () {
    for (final id in frozen.keys) {
      final brief = stage(id);
      final gentler = brief.gentler();
      expect(gentler.id, brief.id);
      expect(gentler.drawsOn, brief.drawsOn);
      expect(gentler.servesUpToTwenty, brief.servesUpToTwenty);
      for (final window in TimeWindow.values) {
        final size = brief.sizeFor(window);
        final allowed = [
          for (final e in elementLibrary.values)
            if (isElementOfferable(e) && e.fits(brief.need)) e,
        ];
        for (final parts in gatePassingShapes(allowed, window: size)) {
          if (gentler.accepts(parts, size: size)) {
            expect(brief.accepts(parts, size: size), isTrue);
          }
        }
      }
    }
  });

  test('with the user\'s own controls in the way, a gentler stage is set '
      'aside, never forced (C3)', () {
    // Every low-effort stretch left out: Getting going's first stage can't
    // pass gently, though it would with the controls ignored.
    final brief = stage('getting_going.1').gentler();
    final result = composeStage(
      gentlerContext(
        ComposerContext(
          date: today,
          need: Intention.moreEnergy,
          window: TimeWindow.upTo30,
        ),
      ),
      const [],
      [brief],
      leftOut: {ElementId.standingStretch, ElementId.gentleStretch},
    );
    expect(result, isA<StageSetAside>());
  });

  test('the plan runtime uses the setting only when it is on', () {
    final plans = CirclePlansState.empty.start(
      'slowing_down',
      today: '2026-10-01',
    )!;
    final context = ComposerContext(
      date: today,
      need: Intention.gentlerPace,
      window: TimeWindow.upTo30,
    );
    final plain = planToday(
      plans,
      premium: true,
      context: context,
      history: const [],
      answers: const {},
    );
    final gentle = planToday(
      plans.keepGentler('slowing_down', today: '2026-10-12')!,
      premium: true,
      context: context,
      history: const [],
      answers: const {},
    );
    expect(plain.stage!.gentler, isFalse);
    expect(gentle.stage!.gentler, isTrue);
    expect(gentle.circle!.plan.minutes, lessThanOrEqualTo(20));
    expect(
      gentle.circle!.plan.parts.every(
        (p) => p.definition.effort == ActivityEffort.low,
      ),
      isTrue,
    );
  });
}
