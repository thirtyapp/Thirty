import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/domain/memory_overview.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/domain/recommendation_policy.dart';
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/composer_policy.dart';

/// V2 Phase D2 (ADR-023 §3) — the Personal Guided Circle composer.
void main() {
  final today = DateTime(2026, 10, 11);
  const energy = Intention.moreEnergy;
  const head = Intention.clearerHead;
  const gentle = Intention.gentlerPace;

  DateTime daysAgo(int n) => today.subtract(Duration(days: n));

  ComposerContext ctx(
    Intention need,
    TimeWindow window, {
    DateTime? date,
    CompositionConstraint? constraint,
  }) => ComposerContext(
    date: date ?? today,
    need: need,
    window: window,
    constraint: constraint,
  );

  /// A Free Circle of one activity.
  PastCircle free(
    int ago,
    Intention need,
    ActivityId activity, [
    PastUsefulness? answer,
  ]) => PastCircle(
    date: daysAgo(ago),
    need: need,
    activityId: activity,
    catalogVersion: catalogVersion,
    usefulness: answer,
    answeredAt: daysAgo(ago),
  );

  /// A composed Circle.
  PastCircle composed(
    int ago,
    Intention need,
    CirclePlan plan, {
    PastUsefulness? answer,
    List<ElementId> skipped = const [],
  }) => PastCircle(
    date: daysAgo(ago),
    need: need,
    activityId: plan.main.definition.art,
    catalogVersion: catalogVersion,
    usefulness: answer,
    answeredAt: daysAgo(ago),
    components: plan.activities,
    parts: plan.toWire(),
    skipped: [for (final s in skipped) s.name],
  );

  group('quality gate', () {
    test('deterministic: same inputs, same Circle', () {
      for (final need in Intention.values) {
        for (final window in TimeWindow.values) {
          final a = composeCircle(ctx(need, window), const []);
          final b = composeCircle(ctx(need, window), const []);
          expect(a?.plan, b?.plan);
          expect(a?.plan, isNotNull);
        }
      }
    });

    test('never over time, never filler, always coherent', () {
      for (var day = 0; day < 60; day++) {
        final date = today.add(Duration(days: day));
        for (final need in Intention.values) {
          for (final window in TimeWindow.values) {
            final circle = composeCircle(
              ctx(need, window, date: date),
              const [],
            );
            final plan = circle!.plan;
            expect(plan.minutes, lessThanOrEqualTo(window.maxMinutes));
            expect(
              plan.minutes,
              greaterThanOrEqualTo(
                (ComposerPolicy.initial.minUtilization * window.maxMinutes)
                    .ceil(),
              ),
            );
            // No element twice; no kind twice; main holds its share.
            expect(plan.elements.length, plan.parts.length);
            expect(
              {for (final p in plan.parts) p.definition.kind}.length,
              plan.parts.length,
            );
            expect(
              plan.main.minutes,
              greaterThanOrEqualTo(
                ComposerPolicy.initial.minMainShare * plan.minutes,
              ),
            );
            expect(plan.parts.length, inInclusiveRange(2, 4));
            if (window == TimeWindow.about10) {
              expect(plan.parts.length, lessThanOrEqualTo(3));
            }
            // Every part fits the need and is an authored length.
            for (final part in plan.parts) {
              expect(part.definition.fits(need), isTrue);
              expect(part.definition.lengths, contains(part.minutes));
            }
            expect(
              coherentParts(
                plan.parts,
                mainIndex: plan.parts.indexOf(plan.main),
              ),
              isTrue,
            );
          }
        }
      }
    });

    test('roles keep their order: arrive, main, second, settle', () {
      for (final need in Intention.values) {
        for (final window in TimeWindow.values) {
          final plan = composeCircle(ctx(need, window), const [])!.plan;
          final mainIndex = plan.parts.indexOf(plan.main);
          for (final part in plan.parts.take(mainIndex)) {
            expect(part.definition.roles, contains(ElementRole.arrive));
          }
          for (final part in plan.parts.skip(mainIndex + 1)) {
            expect(
              part.definition.roles.intersection({
                ElementRole.second,
                ElementRole.settle,
              }),
              isNotEmpty,
            );
          }
        }
      }
    });

    test('mixing outside with inside-only is never composed', () {
      final parts = [
        const CirclePart(ElementId.openWindow, 1),
        const CirclePart(ElementId.easyWalk, 15),
      ];
      expect(coherentParts(parts, mainIndex: 1), isFalse);
    });

    test('a part that needs another never comes without it', () {
      expect(
        coherentParts(const [
          CirclePart(ElementId.clearCorner, 8),
          CirclePart(ElementId.chooseOne, 1),
        ], mainIndex: 0),
        isFalse,
      );
      expect(
        coherentParts(const [
          CirclePart(ElementId.getItOut, 6),
          CirclePart(ElementId.chooseOne, 1),
        ], mainIndex: 0),
        isTrue,
      );
    });

    test('falls back (null) when nothing honest can be composed', () {
      final everything = {for (final id in ElementId.values) id};
      expect(
        composeCircle(
          ctx(head, TimeWindow.about20),
          const [],
          leftOut: everything,
        ),
        isNull,
      );
      // Too little left for a coherent shape: one main and nothing else.
      final allButOne = {
        for (final id in ElementId.values)
          if (id != ElementId.getItOut) id,
      };
      expect(
        composeCircle(
          ctx(head, TimeWindow.about10),
          const [],
          leftOut: allButOne,
        ),
        isNull,
      );
    });
  });

  group('evidence', () {
    test('sparse evidence is neutral: nothing personal is claimed', () {
      for (final need in Intention.values) {
        final circle = composeCircle(ctx(need, TimeWindow.about20), const []);
        expect(circle!.basis, CompositionBasis.sized);
      }
    });

    test('a "Very useful" activity becomes a main piece, and says so', () {
      final history = [
        free(5, head, ActivityId.tidyOneSurface, PastUsefulness.veryUseful),
      ];
      final circle = composeCircle(ctx(head, TimeWindow.about20), history)!;
      expect(circle.plan.elements, contains(ElementId.clearCorner));
      expect(circle.basis, CompositionBasis.foundUseful);
    });

    test('relevant before varied: strong evidence keeps its place', () {
      // Clear one corner was very useful twice; it keeps coming back,
      // never on consecutive days.
      final history = [
        free(20, head, ActivityId.tidyOneSurface, PastUsefulness.veryUseful),
        free(10, head, ActivityId.tidyOneSurface, PastUsefulness.veryUseful),
      ];
      final withIt = composeCircle(ctx(head, TimeWindow.about20), history)!;
      expect(withIt.plan.main.element, ElementId.clearCorner);
    });

    test('a "Somewhat useful" answer alone claims nothing', () {
      final history = [
        free(5, head, ActivityId.tidyOneSurface, PastUsefulness.somewhatUseful),
      ];
      final circle = composeCircle(ctx(head, TimeWindow.about20), history)!;
      expect(circle.basis, CompositionBasis.sized);
    });

    test('evidence for one need never carries into another', () {
      final history = [
        free(
          5,
          energy,
          ActivityId.gentleStretchPause,
          PastUsefulness.veryUseful,
        ),
        free(
          6,
          energy,
          ActivityId.gentleStretchPause,
          PastUsefulness.veryUseful,
        ),
      ];
      final standing = elementStanding(
        elementOf(ElementId.gentleStretch),
        gentle,
        RecommendationMemory.of(today, history, _policy),
      );
      expect(standing.evidence, 0);
      expect(standing.provenUseful, isFalse);
    });

    test('a fragment never borrows its activity’s evidence', () {
      final history = [
        free(5, head, ActivityId.gentleStretchPause, PastUsefulness.veryUseful),
      ];
      final memory = RecommendationMemory.of(today, history, _policy);
      expect(
        elementStanding(
          elementOf(ElementId.neckAndShoulders),
          head,
          memory,
        ).evidence,
        0,
      );
      // One "Very useful" (2): a mean of 2 at a confidence of ½ (ADR-023 §3).
      expect(
        elementStanding(
          elementOf(ElementId.gentleStretch),
          head,
          memory,
        ).evidence,
        1.0,
      );
    });

    test(
      'a composed Circle’s answer counts for its unskipped substance only',
      () {
        final plan = CirclePlan(const [
          CirclePart(ElementId.nameWhatsOn, 1),
          CirclePart(ElementId.getItOut, 6),
          CirclePart(ElementId.chooseOne, 1),
        ]);
        final history = [
          composed(
            3,
            head,
            plan,
            answer: PastUsefulness.veryUseful,
            skipped: [ElementId.nameWhatsOn],
          ),
        ];
        final memory = RecommendationMemory.of(today, history, _policy);
        // Half weight (½), a mean of 2, at a confidence of ⅓.
        expect(
          elementStanding(elementOf(ElementId.getItOut), head, memory).evidence,
          closeTo(2 / 3, 1e-9),
        );
        // Skipped: no credit.
        expect(
          elementStanding(
            elementOf(ElementId.nameWhatsOn),
            head,
            memory,
          ).evidence,
          0,
        );
        // Not skipped, but a close: the day's answer is about the session's
        // substance, never its edges.
        expect(
          elementStanding(
            elementOf(ElementId.chooseOne),
            head,
            memory,
          ).evidence,
          0,
        );
      },
    );

    test(
      'a skip is never a "Not useful": a skipped part keeps its standing',
      () {
        final plan = CirclePlan(const [
          CirclePart(ElementId.getItOut, 6),
          CirclePart(ElementId.chooseOne, 1),
        ]);
        final history = [
          composed(3, head, plan, skipped: [ElementId.getItOut]),
        ];
        final memory = RecommendationMemory.of(today, history, _policy);
        final standing = elementStanding(
          elementOf(ElementId.getItOut),
          head,
          memory,
        );
        expect(standing.evidence, 0);
        expect(standing.allowed, isTrue);
      },
    );

    test('a composed answer is never evidence about an activity', () {
      final plan = CirclePlan(const [
        CirclePart(ElementId.clearCorner, 8),
        CirclePart(ElementId.putThingsBack, 2),
      ]);
      final memory = RecommendationMemory.of(today, [
        composed(3, head, plan, answer: PastUsefulness.notUseful),
      ], _policy);
      expect(memory.strengthFor(ActivityId.tidyOneSurface, head), 0);
      expect(
        memory.daysSinceNotUseful(ActivityId.tidyOneSurface, head),
        isNull,
      );
    });
  });

  test('Memory never shows a composed Circle’s answer as the user’s word '
      'about one activity (S25 finding, D2)', () {
    final plan = CirclePlan(const [
      CirclePart(ElementId.activeJob, 12),
      CirclePart(ElementId.shakeOut, 1),
    ]);
    final memory = needMemoryOf(
      today: today,
      need: energy,
      history: [composed(3, energy, plan, answer: PastUsefulness.notUseful)],
    );
    expect(memory.notUsefulBefore, isEmpty);
    expect(memory.resting, isEmpty);
    expect(memory.usefulBefore, isEmpty);
  });

  group('user control', () {
    test('Don’t suggest for an activity removes its elements, per need', () {
      const controls = SuggestionControls(
        notSuggested: {(ActivityId.writeItDown, Intention.clearerHead)},
      );
      for (var day = 0; day < 30; day++) {
        final circle = composeCircle(
          ctx(head, TimeWindow.about20, date: today.add(Duration(days: day))),
          const [],
          controls: controls,
        );
        expect(circle!.plan.elements, isNot(contains(ElementId.getItOut)));
      }
      final standing = elementStanding(
        elementOf(ElementId.getItOut),
        gentle,
        RecommendationMemory.of(today, const [], _policy),
        controls: controls,
      );
      expect(standing.allowed, isTrue, reason: 'another need is untouched');
    });

    test('Leave this out removes an element from every Circle', () {
      final leftOut = {ElementId.sitAMinute, ElementId.neckAndShoulders};
      for (var day = 0; day < 30; day++) {
        for (final need in Intention.values) {
          final circle = composeCircle(
            ctx(need, TimeWindow.about20, date: today.add(Duration(days: day))),
            const [],
            leftOut: leftOut,
          );
          expect(circle!.plan.elements.intersection(leftOut), isEmpty);
        }
      }
    });

    test('a rest after "Not useful" keeps its elements out, then ends', () {
      final history = [
        free(5, head, ActivityId.tidyOneSurface, PastUsefulness.notUseful),
      ];
      final memory = RecommendationMemory.of(today, history, _policy);
      expect(
        elementStanding(elementOf(ElementId.clearCorner), head, memory).allowed,
        isFalse,
      );
      final later = RecommendationMemory.of(
        today.add(const Duration(days: 15)),
        history,
        _policy,
      );
      expect(
        elementStanding(elementOf(ElementId.clearCorner), head, later).allowed,
        isTrue,
      );
    });

    test('Suggest again lifts the rest at once', () {
      final history = [
        free(5, head, ActivityId.tidyOneSurface, PastUsefulness.notUseful),
      ];
      final controls = SuggestionControls(
        restsLifted: {(ActivityId.tidyOneSurface, head): daysAgo(1)},
      );
      final memory = RecommendationMemory.of(
        today,
        history,
        _policy,
        restsLifted: controls.restsLifted,
      );
      expect(
        elementStanding(
          elementOf(ElementId.clearCorner),
          head,
          memory,
          controls: controls,
        ).allowed,
        isTrue,
      );
    });
  });

  group('recency and variety', () {
    test('yesterday’s main piece is never composed again today', () {
      for (final need in Intention.values) {
        for (final window in TimeWindow.values) {
          final first = composeCircle(
            ctx(need, window, date: daysAgo(1)),
            const [],
          )!;
          final next = composeCircle(ctx(need, window), [
            composed(1, need, first.plan),
          ]);
          if (next == null) continue;
          expect(next.plan.main.element, isNot(first.plan.main.element));
        }
      }
    });

    test('yesterday’s Free activity is not today’s main piece', () {
      final next = composeCircle(ctx(head, TimeWindow.about20), [
        free(1, head, ActivityId.tidyOneSurface, PastUsefulness.veryUseful),
        free(9, head, ActivityId.tidyOneSurface, PastUsefulness.veryUseful),
      ])!;
      expect(next.plan.main.element, isNot(ElementId.clearCorner));
    });

    test('three weeks of one need and time are not one session on repeat', () {
      final history = <PastCircle>[];
      final plans = <CirclePlan>[];
      for (var day = 21; day >= 1; day--) {
        final circle = composeCircle(
          ctx(head, TimeWindow.about20, date: daysAgo(day)),
          history,
        )!;
        plans.add(circle.plan);
        history.add(composed(day, head, circle.plan));
      }
      final distinct = {for (final p in plans) p};
      final mains = {for (final p in plans) p.main.element};
      expect(distinct.length, greaterThanOrEqualTo(14));
      expect(mains.length, greaterThanOrEqualTo(6));
      for (var i = 1; i < plans.length; i++) {
        expect(plans[i].main.element, isNot(plans[i - 1].main.element));
      }
    });
  });

  group('Not this one today', () {
    final replacing = CirclePlan(const [
      CirclePart(ElementId.neckAndShoulders, 2),
      CirclePart(ElementId.easyWalk, 15),
      CirclePart(ElementId.sitAMinute, 2),
    ]);

    test('can’t go outside: nothing outside', () {
      final circle = composeCircle(
        ctx(
          gentle,
          TimeWindow.about20,
          constraint: CompositionConstraint(
            reason: ReplacementReason.cantGoOutside,
            replacing: replacing,
          ),
        ),
        const [],
      )!;
      for (final part in circle.plan.parts) {
        expect(part.definition.setting, isNot(ActivitySetting.outdoor));
      }
    });

    test('too much: gentler and shorter', () {
      final circle = composeCircle(
        ctx(
          gentle,
          TimeWindow.about20,
          constraint: CompositionConstraint(
            reason: ReplacementReason.tooMuch,
            replacing: replacing,
          ),
        ),
        const [],
      )!;
      expect(circle.plan.minutes, lessThan(replacing.minutes));
      for (final part in circle.plan.parts) {
        expect(part.definition.effort, ActivityEffort.low);
      }
    });

    test('not feeling it: another main piece of another kind', () {
      final circle = composeCircle(
        ctx(
          gentle,
          TimeWindow.about20,
          constraint: CompositionConstraint(
            reason: ReplacementReason.notFeeling,
            replacing: replacing,
          ),
        ),
        const [],
      )!;
      expect(circle.plan.main.definition.kind, isNot(ElementKind.walking));
      expect(circle.plan, isNot(replacing));
    });
  });
}

const _policy = RecommendationPolicy.initial;
