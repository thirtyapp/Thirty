import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/domain/recommendation_policy.dart';
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/stage_brief.dart';

/// ADR-024 B2 — StageBriefs on the production composer: the frozen 15 × 3
/// feasibility matrix (§8–§9), set aside or wait (C3), "Not this one today"
/// (C4), stage 5's four cases (§7), the Not-useful rules (§6) and the More
/// Energy attack (§10).
void main() {
  final today = DateTime(2026, 10, 12, 9);
  const energy = Intention.moreEnergy;
  const head = Intention.clearerHead;
  const gentle = Intention.gentlerPace;
  const ten = TimeWindow.about10;
  const twenty = TimeWindow.about20;
  const thirty = TimeWindow.upTo30;

  StageBrief brief(String id) => stageBriefById[id]!;

  ComposerContext ctx(
    Intention need,
    TimeWindow window, {
    CompositionConstraint? constraint,
  }) => ComposerContext(
    date: today,
    need: need,
    window: window,
    constraint: constraint,
  );

  PastCircle freeAgo(
    int ago,
    Intention need,
    ActivityId activity,
    PastUsefulness answer,
  ) {
    final date = today.subtract(Duration(days: ago));
    return PastCircle(
      date: date,
      need: need,
      activityId: activity,
      catalogVersion: catalogVersion,
      usefulness: answer,
      answeredAt: date,
    );
  }

  PastCircle composedAgo(
    int ago,
    Intention need,
    CirclePlan plan, [
    PastUsefulness? answer,
  ]) {
    final date = today.subtract(Duration(days: ago));
    return PastCircle(
      date: date,
      need: need,
      activityId: plan.main.definition.art,
      catalogVersion: catalogVersion,
      usefulness: answer,
      answeredAt: answer == null ? null : date,
      components: plan.activities,
      parts: plan.toWire(),
    );
  }

  /// Every gate-passing shape [brief] accepts on a [window] day, from the
  /// live library for its need, optionally narrowed by [keep].
  List<List<CirclePart>> shapes(
    StageBrief brief,
    TimeWindow window, {
    bool Function(CircleElement element)? keep,
  }) {
    final size = brief.sizeFor(window);
    final allowed = [
      for (final e in elementLibrary.values)
        if (isElementOfferable(e) &&
            e.fits(brief.need) &&
            (keep?.call(e) ?? true))
          e,
    ];
    return [
      for (final parts in gatePassingShapes(allowed, window: size))
        if (brief.accepts(parts, size: size)) parts,
    ];
  }

  ElementId mainOf(List<CirclePart> parts) => CirclePlan(parts).main.element;

  /// shapes / distinct main pieces / materially distinct sessions — the
  /// counts ADR-024 §8 is frozen with.
  String counts(List<List<CirclePart>> all) {
    final material = {
      for (final parts in all)
        ([
          for (final p in parts)
            if (p.definition.roles.contains(ElementRole.main) ||
                p.definition.roles.contains(ElementRole.second))
              p.element.name,
        ]..sort()).join('+'),
    };
    return '${all.length}/${{for (final s in all) mainOf(s)}.length}/'
        '${material.length}';
  }

  StageBrief stageFiveCaseA(String id) {
    final plan = id.substring(0, id.indexOf('.'));
    final five = stageFive(id, [
      for (var i = 1; i <= 4; i++) EarlierStage('$plan.$i'),
    ], today);
    return (five as StageFiveBriefs).briefs.first;
  }

  /// The Circle a stage composes on a fresh day, checked against the
  /// composer's own invariants.
  StageComposed composedFor(List<StageBrief> briefs, TimeWindow window) {
    final need = briefs.first.need;
    final result = composeStage(ctx(need, window), const [], briefs);
    expect(result, isA<StageComposed>());
    final composed = result as StageComposed;
    final parts = composed.circle.plan.parts;
    final size = composed.brief.sizeFor(window);
    expect(composed.brief.accepts(parts, size: size), isTrue);
    expect(composed.circle.plan.minutes, lessThanOrEqualTo(size));
    final mainIndex = parts.indexOf(composed.circle.plan.main);
    expect(coherentParts(parts, mainIndex: mainIndex), isTrue);
    for (final p in parts) {
      expect(isElementOfferable(p.definition), isTrue);
      expect(p.definition.fits(need), isTrue);
    }
    return composed;
  }

  group('the frozen feasibility matrix (§8–§9)', () {
    // ≈10 · ≈20 · up to 30 — at ≈20 size where a brief serves up to ≈20.
    const frozen = {
      'getting_going.1': ['29/2/6', '89/2/8', '89/2/8'],
      'getting_going.2': ['138/4/11', '155/4/12', '155/4/12'],
      'getting_going.3': ['31/5/9', '409/9/25', '173/7/15'],
      'getting_going.4': ['24/4/4', '202/9/21', '66/4/11'],
      'getting_going.5': ['27/4/7', '238/9/24', '31/3/7'],
      'making_room.1': ['206/8/14', '1719/15/59', '656/11/40'],
      'making_room.2': ['357/4/26', '3583/11/114', '1911/8/72'],
      'making_room.3': ['49/6/8', '1315/14/66', '2053/9/58'],
      'making_room.4': ['47/4/11', '1462/5/101', '1338/5/91'],
      'making_room.5': ['28/4/7', '1360/10/69', '1229/8/56'],
      'slowing_down.1': ['57/1/6', '348/2/47', '166/2/28'],
      'slowing_down.2': ['104/7/14', '887/11/112', '648/10/89'],
      'slowing_down.3': ['106/3/15', '1184/3/74', '625/3/59'],
      'slowing_down.4': ['50/5/11', '659/10/88', '518/7/64'],
      'slowing_down.5': ['72/6/13', '847/10/106', '535/8/79'],
    };

    test('fifteen stages: twelve fixed briefs and three stage 5s', () {
      expect(launchStageBriefs.map((b) => b.id), [
        for (final plan in ['getting_going', 'making_room', 'slowing_down'])
          for (var i = 1; i <= 4; i++) '$plan.$i',
      ]);
      expect(stageFiveIds.keys, [
        'getting_going.5',
        'making_room.5',
        'slowing_down.5',
      ]);
      expect(frozen.length, 15);
      expect(
        [
          for (final b in launchStageBriefs)
            if (b.servesUpToTwenty) b.id,
        ],
        ['getting_going.1', 'getting_going.2'],
      );
    });

    var cells = 0;
    for (final MapEntry(key: id, value: expected) in frozen.entries) {
      for (final (index, window) in TimeWindow.values.indexed) {
        cells++;
        test('$id at ${window.name}: PASS, ${expected[index]}', () {
          final stage = stageFiveIds.containsKey(id)
              ? stageFiveCaseA(id)
              : brief(id);
          expect(counts(shapes(stage, window)), expected[index]);
          // And the production composer composes one, honestly.
          composedFor([stage], window);
        });
      }
    }
    test('45 cells', () => expect(cells, 45));

    test('a brief serving up to ≈20 composes at ≈20 size on an up-to-30 '
        'day; the others compose for the day', () {
      for (final b in launchStageBriefs) {
        expect(b.sizeFor(ten), 10);
        expect(b.sizeFor(twenty), 20);
        expect(b.sizeFor(thirty), b.servesUpToTwenty ? 20 : 30);
      }
      final circle = composedFor([brief('getting_going.1')], thirty);
      expect(circle.circle.plan.minutes, lessThanOrEqualTo(20));
    });

    test('nothing a brief rejects is broadened back in', () {
      for (final b in launchStageBriefs) {
        for (final window in TimeWindow.values) {
          for (var day = 0; day < 7; day++) {
            final circle = composeCircle(
              ComposerContext(
                date: today.add(Duration(days: day)),
                need: b.need,
                window: window,
              ),
              const [],
              brief: b,
            )!;
            expect(
              b.accepts(circle.plan.parts, size: b.sizeFor(window)),
              isTrue,
            );
            expect(circle.trace, startsWith('brief=${b.id}'));
          }
        }
      }
    });

    test('a brief for another need is refused, never composed', () {
      expect(
        () => composeCircle(
          ctx(head, twenty),
          const [],
          brief: brief('getting_going.3'),
        ),
        throwsArgumentError,
      );
    });

    test('within a brief, the ranking is the composer\'s own', () {
      // The best Circle the brief accepts is the best-ranked of the
      // shapes it accepts: the same Circle the composer picks when the
      // library holds only what those shapes use.
      for (final b in launchStageBriefs) {
        final withBrief = composeCircle(
          ctx(b.need, twenty),
          const [],
          brief: b,
        )!;
        final plain = composeCircle(ctx(b.need, twenty), const []);
        if (plain != null && b.accepts(plain.plan.parts, size: 20)) {
          expect(withBrief.plan, plain.plan, reason: b.id);
          expect(withBrief.score, plain.score, reason: b.id);
        }
        expect(withBrief.score, lessThanOrEqualTo(plain!.score), reason: b.id);
      }
    });
  });

  group('set aside or wait (C3)', () {
    StageComposition stage(
      String id,
      TimeWindow window, {
      List<PastCircle> history = const [],
      SuggestionControls controls = SuggestionControls.none,
      Set<ElementId> leftOut = const {},
      CompositionConstraint? constraint,
    }) {
      final b = brief(id);
      return composeStage(
        ctx(b.need, window, constraint: constraint),
        history,
        [b],
        controls: controls,
        leftOut: leftOut,
      );
    }

    void expectSetAside(
      StageComposition result,
      Map<ElementId, StageBlockReason> blocked,
    ) {
      expect(result, isA<StageSetAside>());
      final blocks = (result as StageSetAside).blocks;
      expect(blocks, isNotEmpty);
      for (final block in blocks) {
        expect(isElementOfferable(elementOf(block.element)), isTrue);
      }
      for (final MapEntry(key: element, value: reason) in blocked.entries) {
        expect(
          blocks.where((b) => b.element == element).map((b) => b.reason),
          [reason],
          reason: '$element',
        );
      }
    }

    test('E4 at ≈10 with "Some fresh air" left out: set aside', () {
      expectSetAside(
        stage('getting_going.4', ten, leftOut: {ElementId.daylight}),
        {ElementId.daylight: StageBlockReason.leftOut},
      );
      // At ≈20 a walk still fits: the stage composes.
      expect(
        stage('getting_going.4', twenty, leftOut: {ElementId.daylight}),
        isA<StageComposed>(),
      );
    });

    test('H3 at ≈10 with Get it out or Choose one thing blocked: set '
        'aside', () {
      expectSetAside(
        stage(
          'making_room.3',
          ten,
          controls: const SuggestionControls(
            notSuggested: {(ActivityId.writeItDown, Intention.clearerHead)},
          ),
        ),
        {ElementId.getItOut: StageBlockReason.notSuggested},
      );
      expectSetAside(
        stage('making_room.3', ten, leftOut: {ElementId.chooseOne}),
        {ElementId.chooseOne: StageBlockReason.leftOut},
      );
      // At ≈20, One task, no switching still follows the stage.
      expect(
        stage('making_room.3', twenty, leftOut: {ElementId.chooseOne}),
        isA<StageComposed>(),
      );
    });

    test('G1 at ≈10 with Tend to one thing left out: set aside', () {
      expectSetAside(
        stage('slowing_down.1', ten, leftOut: {ElementId.tendOne}),
        {ElementId.tendOne: StageBlockReason.leftOut},
      );
    });

    test('G2 while Gentle stretch rests after a single-activity "Not '
        'useful": set aside, at every time', () {
      final history = [
        freeAgo(
          3,
          gentle,
          ActivityId.gentleStretchPause,
          PastUsefulness.notUseful,
        ),
      ];
      for (final window in TimeWindow.values) {
        final result = stage('slowing_down.2', window, history: history);
        expect(result, isA<StageSetAside>(), reason: window.name);
        expect((result as StageSetAside).blocks.map((b) => b.reason).toSet(), {
          StageBlockReason.resting,
        });
      }
      // "Suggest again" lifts the rest: the stage composes again.
      expect(
        stage(
          'slowing_down.2',
          twenty,
          history: history,
          controls: SuggestionControls(
            restsLifted: {
              (ActivityId.gentleStretchPause, gentle): today.subtract(
                const Duration(days: 1),
              ),
            },
          ),
        ),
        isA<StageComposed>(),
      );
    });

    test('E1 with both stretches blocked by the user\'s controls: set '
        'aside; with one blocked it still composes', () {
      expect(
        stage('getting_going.1', ten, leftOut: {ElementId.standingStretch}),
        isA<StageComposed>(),
      );
      for (final window in TimeWindow.values) {
        expectSetAside(
          stage(
            'getting_going.1',
            window,
            leftOut: {ElementId.standingStretch},
            history: [
              freeAgo(
                2,
                energy,
                ActivityId.gentleStretchPause,
                PastUsefulness.notUseful,
              ),
            ],
          ),
          {},
        );
        expectSetAside(
          stage(
            'getting_going.1',
            window,
            leftOut: {ElementId.gentleStretch},
            controls: const SuggestionControls(
              notSuggested: {
                (ActivityId.energisingStretchFlow, Intention.moreEnergy),
              },
            ),
          ),
          {ElementId.gentleStretch: StageBlockReason.leftOut},
        );
      }
    });

    test('yesterday\'s main piece is temporary: G1 at ≈10 after a Tend to '
        'one thing day waits — even with Tend to one thing also left out', () {
      final tend = composedFor([brief('slowing_down.1')], ten).circle.plan;
      expect(tend.main.element, ElementId.tendOne);
      final yesterday = [composedAgo(1, gentle, tend)];
      expect(
        stage('slowing_down.1', ten, history: yesterday),
        isA<StageWaits>(),
      );
      expect(
        stage(
          'slowing_down.1',
          ten,
          history: yesterday,
          leftOut: {ElementId.tendOne},
        ),
        isA<StageWaits>(),
      );
      // The day after, it composes again.
      expect(
        composeStage(
          ComposerContext(
            date: today.add(const Duration(days: 1)),
            need: gentle,
            window: ten,
          ),
          yesterday,
          [brief('slowing_down.1')],
        ),
        isA<StageComposed>(),
      );
    });

    test('"Not feeling this one" inside E1 has no other kind of main '
        'piece: it waits (C4 step 2 is the caller\'s)', () {
      final first = composedFor([brief('getting_going.1')], twenty);
      final result = stage(
        'getting_going.1',
        twenty,
        constraint: CompositionConstraint(
          reason: ReplacementReason.notFeeling,
          replacing: first.circle.plan,
        ),
      );
      expect(result, isA<StageWaits>());
    });

    test('"Not this one today" recomposes once inside the brief, and '
        'reports truthfully', () {
      for (final b in launchStageBriefs) {
        final first = composedFor([b], twenty).circle.plan;
        for (final reason in ReplacementReason.values) {
          final result = composeStage(
            ctx(
              b.need,
              twenty,
              constraint: CompositionConstraint(
                reason: reason,
                replacing: first,
              ),
            ),
            const [],
            [b],
          );
          if (result is StageComposed) {
            final plan = result.circle.plan;
            expect(plan, isNot(first));
            expect(b.accepts(plan.parts, size: 20), isTrue);
            switch (reason) {
              case ReplacementReason.tooMuch:
                expect(plan.minutes, lessThan(first.minutes));
              case ReplacementReason.cantGoOutside:
                expect(
                  plan.parts.map((p) => p.definition.setting),
                  isNot(contains(ActivitySetting.outdoor)),
                );
              case ReplacementReason.notFeeling:
                expect(
                  plan.main.definition.kind,
                  isNot(first.main.definition.kind),
                );
            }
          } else {
            expect(result, isA<StageWaits>(), reason: '${b.id} $reason');
          }
        }
      }
    });

    test('"Too much for today" on the shortest Circle leaves nothing '
        'shorter: it waits', () {
      final shortest = CirclePlan(const [
        CirclePart(ElementId.standAndReach, 1),
        CirclePart(ElementId.standingStretch, 5),
      ]);
      expect(
        stage(
          'getting_going.2',
          ten,
          constraint: CompositionConstraint(
            reason: ReplacementReason.tooMuch,
            replacing: shortest,
          ),
          leftOut: {ElementId.clearCorner},
        ),
        isA<StageWaits>(),
      );
    });

    test('safety and need fit are never ignored: what no live part for '
        'the need can satisfy waits, never set aside', () {
      final elsewhere = StageBrief.of(
        'test.elsewhere',
        energy,
        (parts) => parts.any((p) => p.element == ElementId.warmDrink),
      );
      expect(
        composeStage(ctx(energy, twenty), const [], [elsewhere]),
        isA<StageWaits>(),
      );
    });

    test('the probe is pure: nothing passed in changes, and the answer '
        'repeats', () {
      final history = List<PastCircle>.unmodifiable([
        freeAgo(
          3,
          gentle,
          ActivityId.gentleStretchPause,
          PastUsefulness.notUseful,
        ),
      ]);
      final leftOut = Set<ElementId>.unmodifiable({ElementId.daylight});
      const controls = SuggestionControls(
        notSuggested: {(ActivityId.writeItDown, Intention.clearerHead)},
      );
      for (final id in ['slowing_down.2', 'getting_going.4', 'making_room.3']) {
        final b = brief(id);
        final a = composeStage(
          ctx(b.need, ten),
          history,
          [b],
          controls: controls,
          leftOut: leftOut,
        );
        final again = composeStage(
          ctx(b.need, ten),
          history,
          [b],
          controls: controls,
          leftOut: leftOut,
        );
        expect(a, isA<StageSetAside>(), reason: id);
        expect(
          (again as StageSetAside).blocks.map((x) => (x.element, x.reason)),
          (a as StageSetAside).blocks.map((x) => (x.element, x.reason)),
        );
      }
      expect(leftOut, {ElementId.daylight});
      expect(controls.restsLifted, isEmpty);
    });
  });

  group('stage 5 (§7)', () {
    List<EarlierStage> stages(
      String plan,
      List<(PastUsefulness?, bool)> outcomes,
    ) => [
      for (final (i, (answer, setAside)) in outcomes.indexed)
        EarlierStage('$plan.${i + 1}', answer: answer, setAside: setAside),
    ];
    const very = PastUsefulness.veryUseful;
    const somewhat = PastUsefulness.somewhatUseful;
    const not = PastUsefulness.notUseful;

    int briefsFollowed(List<CirclePart> parts, int size, List<String> ids) =>
        ids.where((id) => brief(id).accepts(parts, size: size)).length;

    test('A — no answers: a mix of at least two earlier stages, at every '
        'need and time', () {
      for (final plan in ['getting_going', 'making_room', 'slowing_down']) {
        final five = stageFive('$plan.5', [
          for (var i = 1; i <= 4; i++) EarlierStage('$plan.$i'),
        ], today);
        expect((five as StageFiveBriefs).basis, StageFiveBasis.noAnswers);
        for (final window in TimeWindow.values) {
          final composed = composedFor(five.briefs, window);
          expect(composed.brief.drawsOn.length, 4);
          final size = composed.brief.sizeFor(window);
          expect(
            briefsFollowed(
              composed.circle.plan.parts,
              size,
              composed.brief.drawsOn,
            ),
            greaterThanOrEqualTo(2),
            reason: '$plan ${window.name}',
          );
        }
      }
    });

    test('A falls back to one earlier stage when no two fit together', () {
      // E1 and E2 never compose together; E3 and E4 were set aside.
      final five = stageFive(
        'getting_going.5',
        stages('getting_going', [
          (null, false),
          (null, false),
          (null, true),
          (null, true),
        ]),
        today,
      );
      for (final window in TimeWindow.values) {
        final composed = composedFor((five as StageFiveBriefs).briefs, window);
        final size = composed.brief.sizeFor(window);
        expect(size, lessThanOrEqualTo(20), reason: 'E1 and E2 serve ≤ ≈20');
        expect(
          briefsFollowed(composed.circle.plan.parts, size, [
            'getting_going.1',
            'getting_going.2',
          ]),
          1,
        );
      }
    });

    test('B — one positive stage leads, with another that wasn\'t '
        'rejected', () {
      final five = stageFive(
        'making_room.5',
        stages('making_room', [
          (null, false),
          (very, false),
          (not, false),
          (null, false),
        ]),
        today,
      );
      expect((five as StageFiveBriefs).basis, StageFiveBasis.onePositive);
      for (final window in TimeWindow.values) {
        final composed = composedFor(five.briefs, window);
        final parts = composed.circle.plan.parts;
        final size = composed.brief.sizeFor(window);
        expect(brief('making_room.2').accepts(parts, size: size), isTrue);
        expect(
          briefsFollowed(parts, size, ['making_room.1', 'making_room.4']),
          greaterThanOrEqualTo(1),
        );
        expect(composed.brief.drawsOn, isNot(contains('making_room.3')));
      }
    });

    test('B — else the positive stage alone, as a deliberate return', () {
      // E1 + E2 never compose together, and nothing else is left.
      final five = stageFive(
        'getting_going.5',
        stages('getting_going', [
          (somewhat, false),
          (null, false),
          (not, false),
          (null, true),
        ]),
        today,
      );
      for (final window in TimeWindow.values) {
        final composed = composedFor((five as StageFiveBriefs).briefs, window);
        expect(composed.brief.drawsOn, ['getting_going.1']);
      }
    });

    test('C — the two most positive together: Very before Somewhat', () {
      final five = stageFive(
        'slowing_down.5',
        stages('slowing_down', [
          (somewhat, false),
          (very, false),
          (null, false),
          (very, false),
        ]),
        today,
      );
      expect((five as StageFiveBriefs).basis, StageFiveBasis.severalPositive);
      final first = five.briefs.first.drawsOn;
      expect(first.toSet(), {'slowing_down.2', 'slowing_down.4'});
      // Ties on the composer's date-seeded hash.
      final hash2 = dateSeededHash(today, 'slowing_down.2');
      final hash4 = dateSeededHash(today, 'slowing_down.4');
      expect(first.first, hash2 > hash4 ? 'slowing_down.2' : 'slowing_down.4');
      for (final window in TimeWindow.values) {
        final composed = composedFor(five.briefs, window);
        final size = composed.brief.sizeFor(window);
        expect(
          briefsFollowed(
            composed.circle.plan.parts,
            size,
            composed.brief.drawsOn,
          ),
          composed.brief.drawsOn.length,
        );
        expect(composed.brief.drawsOn, isNot(contains('slowing_down.3')));
      }
    });

    test('C — a pair that can never be composed gives way to the next, '
        'else the single most positive stage', () {
      // G1 + G3 can never be composed together.
      final five = stageFive(
        'slowing_down.5',
        stages('slowing_down', [
          (very, false),
          (not, false),
          (somewhat, false),
          (not, false),
        ]),
        today,
      );
      for (final window in TimeWindow.values) {
        final composed = composedFor((five as StageFiveBriefs).briefs, window);
        expect(composed.brief.drawsOn, ['slowing_down.1']);
      }
    });

    test('D — every earlier stage rejected: no last Circle is made', () {
      expect(
        stageFive(
          'getting_going.5',
          stages('getting_going', [
            (not, false),
            (not, false),
            (null, true),
            (not, false),
          ]),
          today,
        ),
        isA<NoStageFive>().having(
          (n) => n.reason,
          'reason',
          NoStageFiveReason.allRejected,
        ),
      );
      expect(
        stageFive(
          'making_room.5',
          stages('making_room', [for (var i = 0; i < 4; i++) (null, true)]),
          today,
        ),
        isA<NoStageFive>().having(
          (n) => n.reason,
          'reason',
          NoStageFiveReason.allSetAside,
        ),
      );
    });

    test('D — with some unanswered: case A over the unanswered only', () {
      final five = stageFive(
        'making_room.5',
        stages('making_room', [
          (not, false),
          (null, false),
          (not, false),
          (null, false),
        ]),
        today,
      );
      expect((five as StageFiveBriefs).basis, StageFiveBasis.noAnswers);
      for (final b in five.briefs) {
        expect(b.drawsOn, ['making_room.2', 'making_room.4']);
      }
    });

    test('nothing is fabricated: stage 5 only ever draws on what the '
        'user didn\'t reject or set aside', () {
      const answers = [very, somewhat, not, null];
      for (final plan in ['getting_going', 'making_room', 'slowing_down']) {
        for (var mask = 0; mask < 256; mask++) {
          final outcomes = [
            for (var i = 0; i < 4; i++) (answers[(mask >> (2 * i)) & 3], false),
          ];
          final five = stageFive('$plan.5', stages(plan, outcomes), today);
          final rejected = {
            for (final (i, (answer, _)) in outcomes.indexed)
              if (answer == not) '$plan.${i + 1}',
          };
          if (five is NoStageFive) {
            expect(rejected.length, 4);
            continue;
          }
          for (final b in (five as StageFiveBriefs).briefs) {
            expect(b.drawsOn.toSet().intersection(rejected), isEmpty);
            expect(b.id, '$plan.5');
          }
        }
      }
    });

    test('earlier stages of another Plan are refused', () {
      expect(
        () => stageFive('getting_going.5', const [
          EarlierStage('making_room.1'),
        ], today),
        throwsArgumentError,
      );
    });
  });

  group('Not useful (§6) — a brief never changes it', () {
    test('on a composed stage Circle: no rest, the stage composes again', () {
      final b = brief('slowing_down.2');
      final plan = composedFor([b], twenty).circle.plan;
      final history = [composedAgo(2, gentle, plan, PastUsefulness.notUseful)];
      final memory = RecommendationMemory.of(today, history, _policy);
      for (final part in plan.substance) {
        final standing = elementStanding(part.definition, gentle, memory);
        expect(standing.allowed, isTrue, reason: '${part.element}');
        expect(standing.evidence, lessThan(0));
      }
      expect(
        composeStage(ctx(gentle, twenty), history, [b]),
        isA<StageComposed>(),
      );
    });

    test('on a single-activity Circle: the 14-day rest, which can set the '
        'stage aside', () {
      final history = [
        freeAgo(
          2,
          gentle,
          ActivityId.gentleStretchPause,
          PastUsefulness.notUseful,
        ),
      ];
      final memory = RecommendationMemory.of(today, history, _policy);
      expect(
        elementStanding(
          elementOf(ElementId.gentleStretch),
          gentle,
          memory,
        ).excludedBecause,
        'resting',
      );
      expect(
        composeStage(ctx(gentle, twenty), history, [brief('slowing_down.2')]),
        isA<StageSetAside>(),
      );
    });
  });

  group('More Energy, honestly thin (§10)', () {
    // Shapes at ≈10 / ≈20 / up to 30 for E1–E4.
    String row(bool Function(CircleElement e) keep) => [
      for (var i = 1; i <= 4; i++)
        [
          for (final w in TimeWindow.values)
            shapes(brief('getting_going.$i'), w, keep: keep).length,
        ].join('/'),
    ].join(' | ');

    test('the attack, on the production gate', () {
      expect(
        row((_) => true),
        '29/89/89 | 138/155/155 | 31/409/173 | 24/202/66',
      );
      expect(
        row((e) => e.id != ElementId.standingStretch),
        '8/71/71 | 138/155/155 | 25/331/153 | 20/188/57',
      );
      expect(
        row((e) => e.from != ActivityId.energisingStretchFlow),
        '8/71/71 | 97/113/113 | 25/275/129 | 14/141/46',
      );
      expect(
        row((e) => e.from != ActivityId.moveToMusic),
        '20/43/43 | 74/93/93 | 16/121/61 | 15/141/61',
      );
      expect(
        row((e) => e.effort == ActivityEffort.low),
        '27/49/49 | 48/35/35 | 9/86/30 | 11/98/17',
      );
      expect(
        row((e) => e.setting != ActivitySetting.outdoor),
        '29/89/89 | 138/155/155 | 31/383/142 | 24/144/19',
      );
      expect(
        row((e) => e.id != ElementId.daylight),
        '25/68/68 | 118/32/32 | 31/409/173 | 0/58/47',
      );
    });

    test('every stage has at least two main pieces at ≈10, so yesterday\'s '
        'main never empties one', () {
      for (final b in launchStageBriefs.where((b) => b.need == energy)) {
        expect(
          {for (final s in shapes(b, ten)) mainOf(s)}.length,
          greaterThanOrEqualTo(2),
          reason: b.id,
        );
      }
    });

    test('More Energy every day at ≈10: a cycle in five days, no waits', () {
      final history = <PastCircle>[];
      for (var day = 0; day < 5; day++) {
        final date = today.add(Duration(days: day));
        final briefs = day < 4
            ? [brief('getting_going.${day + 1}')]
            : (stageFive('getting_going.5', [
                        for (var i = 1; i <= 4; i++)
                          EarlierStage('getting_going.$i'),
                      ], date)
                      as StageFiveBriefs)
                  .briefs;
        final result = composeStage(
          ComposerContext(date: date, need: energy, window: ten),
          history,
          briefs,
        );
        expect(result, isA<StageComposed>(), reason: 'day $day');
        final plan = (result as StageComposed).circle.plan;
        history.add(
          PastCircle(
            date: date,
            need: energy,
            activityId: plan.main.definition.art,
            catalogVersion: catalogVersion,
            components: plan.activities,
            parts: plan.toWire(),
          ),
        );
      }
    });
  });

  // B3: the seam is live only through the Circle Plan runtime — nothing
  // else in the app composes with a brief.
  test('only the Circle Plan runtime composes with a brief', () {
    const seam = {
      'personal_circle/domain/stage_brief.dart',
      'personal_circle/domain/circle_composer.dart',
      'plans/domain/circle_plan.dart',
    };
    final live = [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            !seam.any((s) => f.path.replaceAll(r'\', '/').endsWith(s)))
          f,
    ];
    expect(live, isNotEmpty);
    for (final file in live) {
      final source = file.readAsStringSync();
      // B4: the Plans pages read a set-aside's reasons (StageBlock), and
      // compose nothing.
      if (!file.path.replaceAll(r'\', '/').contains('lib/features/plans/')) {
        expect(source, isNot(contains('stage_brief.dart')), reason: file.path);
      }
      expect(source, isNot(contains('brief:')), reason: file.path);
      expect(source, isNot(contains('composeStage')), reason: file.path);
    }
  });
}

const _policy = RecommendationPolicy.initial;
