import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/insights/domain/insight_copy.dart';
import 'package:thirty/features/insights/domain/insight_engine.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_stage_provenance.dart';

/// ADR-024 B5 — the six Insight families on the pure evaluator: each gate
/// and its edges, the windows, priority, cadence, "Not now", retention, the
/// readiness states and the wording guards.
void main() {
  // Day 1 is 30 October 2026.
  final today = DateTime(2026, 10, 30, 9);
  const energy = Intention.moreEnergy;
  const head = Intention.clearerHead;
  const gentle = Intention.gentlerPace;

  String day(int n) => dayOf(today, n);

  CirclePart part(ElementId e) => CirclePart(e, elementOf(e).minutes);

  /// Clearer Head with writing as the main piece; chooseOne and firstStep
  /// build on it.
  final writing = [
    part(ElementId.closeWhatsOpen),
    part(ElementId.getItOut),
    part(ElementId.chooseOne),
    part(ElementId.firstStep),
  ];

  /// Clearer Head with reading as the main piece.
  final reading = [part(ElementId.phoneFaceDown), part(ElementId.readPages)];

  /// More Energy opening a window first.
  final window = [
    part(ElementId.openWindow),
    part(ElementId.standingStretch),
    part(ElementId.sitAMinute),
  ];

  var serial = 0;
  InsightCircle at(
    int n,
    Intention need, {
    List<CirclePart> parts = const [],
    Set<ElementId> skipped = const {},
    PastUsefulness? answer,
    PlanStageProvenance? stage,
    PlanStageProvenance? replacedFromStage,
    String? reason,
    bool kept = false,
  }) => InsightCircle(
    circleId: '${day(n)}#${serial++}',
    localDate: day(n),
    need: need,
    parts: parts,
    skipped: skipped,
    kept: kept,
    answer: answer,
    stage: stage,
    replacedFromStage: replacedFromStage,
    replacementReason: reason,
  );

  InsightInputs inputs(
    List<InsightCircle> circles, {
    CirclePlansState plans = CirclePlansState.empty,
    Set<ElementId> leftOut = const {},
    Set<String> kept = const {},
    int keptCount = 0,
    DateTime? on,
  }) => InsightInputs(
    today: on ?? today,
    circles: circles,
    plans: plans,
    leftOut: leftOut,
    keptFromCircles: kept,
    keptCount: keptCount,
  );

  group('the pattern gate', () {
    test('5 records on 3 dates spanning 14 days, both ends counted', () {
      expect(
        patternGate([at(1, head), at(5, head), at(14, head), at(2, head)]),
        isFalse,
        reason: '4 records',
      );
      expect(
        patternGate([
          for (final n in [1, 1, 1, 14, 14]) at(n, head),
        ]),
        isFalse,
        reason: '2 dates',
      );
      expect(
        patternGate([
          for (final n in [1, 2, 5, 9, 13]) at(n, head),
        ]),
        isFalse,
        reason: 'days 1–13 span 13 days',
      );
      expect(
        patternGate([
          for (final n in [1, 2, 5, 9, 14]) at(n, head),
        ]),
        isTrue,
        reason: 'days 1–14 span 14 days',
      );
    });
  });

  group('I1 — the Plan for your need', () {
    List<InsightCircle> head5(List<int> days) => [
      for (final n in days) at(n, head),
    ];

    test('4 records → nothing', () {
      expect(planForNeed(inputs(head5([1, 5, 10, 20]))), isNull);
    });

    test('5 records but 2 dates → nothing', () {
      expect(planForNeed(inputs(head5([1, 1, 1, 20, 20]))), isNull);
    });

    test('5 records on 3 dates within 13 days → nothing', () {
      expect(planForNeed(inputs(head5([1, 3, 3, 8, 13]))), isNull);
    });

    test('the gate met → Start Making room, with the real counts', () {
      final c = planForNeed(
        inputs([
          ...head5([2, 6, 10, 14, 15]),
          at(4, energy),
          at(9, gentle),
        ]),
      )!;
      expect(c.family, InsightFamily.planForNeed);
      expect(
        c.text,
        'You chose Clearer Head on 5 of your last 7 Circles, between '
        '16 and 29 October.',
      );
      expect(c.facts['count'], 5);
      expect(c.facts['of'], 7);
      final app = c.application as PlanDirection;
      expect((app.planId, app.step), ('making_room', PlanStep.start));
    });

    test('a tie for the most-chosen need → nothing', () {
      expect(
        planForNeed(
          inputs([
            ...head5([2, 6, 10, 14, 15]),
            for (final n in [3, 7, 11, 16, 20]) at(n, energy),
          ]),
        ),
        isNull,
      );
    });

    test('its Plan already active → withdrawn; paused → carry on; left → '
        'again', () {
      final circles = head5([2, 6, 10, 14, 15]);
      final active = CirclePlansState.empty.start(
        'making_room',
        today: '2026-10-01',
      )!;
      expect(planForNeed(inputs(circles, plans: active)), isNull);
      final paused = active.pause('making_room')!;
      expect(
        (planForNeed(inputs(circles, plans: paused))!.application
                as PlanDirection)
            .step,
        PlanStep.carryOn,
      );
      final left = active.leave('making_room', today: '2026-10-05')!;
      expect(
        (planForNeed(inputs(circles, plans: left))!.application
                as PlanDirection)
            .step,
        PlanStep.goThroughAgain,
      );
    });

    test('day 28 is inside the window, day 29 outside', () {
      expect(planForNeed(inputs(head5([1, 5, 9, 14, 28]))), isNotNull);
      final outside = planForNeed(inputs(head5([1, 5, 9, 14, 29])));
      expect(outside, isNull, reason: 'only 4 inside, spanning 14 days');
    });

    test('a stale snapshot stays readable, and is no longer current', () {
      final circles = head5([2, 6, 10, 14, 15]);
      final shown = planForNeed(inputs(circles))!.snapshot(day(1));
      expect(statusOf(shown, inputs(circles)), InsightStatus.current);
      // A fortnight later the choices have left the 28-day window.
      final later = inputs(circles, on: today.add(const Duration(days: 20)));
      expect(statusOf(shown, later), InsightStatus.stale);
      expect(shown.text, contains('Clearer Head'));
    });
  });

  group('I2 — gentler Plan Circles', () {
    final plans = CirclePlansState.empty.start(
      'getting_going',
      today: '2026-10-01',
    )!;
    PlanStageProvenance stage({bool gentler = false}) => PlanStageProvenance(
      planId: 'getting_going',
      cycleId: 'getting_going#1',
      stageNumber: 1,
      stageId: 'getting_going.1',
      gentler: gentler,
    );
    InsightCircle offer(int n, {bool tooMuch = false, bool gentler = false}) =>
        tooMuch
        ? at(
            n,
            energy,
            replacedFromStage: stage(gentler: gentler),
            reason: 'tooMuch',
          )
        : at(
            n,
            energy,
            stage: stage(gentler: gentler),
            parts: window,
          );

    test('fewer than 5 offers → nothing', () {
      expect(
        planPacing(
          inputs([
            offer(1, tooMuch: true),
            offer(6, tooMuch: true),
            offer(12, tooMuch: true),
            offer(16),
          ], plans: plans),
        ),
        isNull,
      );
    });

    test('fewer than 3 "Too much for today" → nothing', () {
      expect(
        planPacing(
          inputs([
            offer(1, tooMuch: true),
            offer(4),
            offer(8, tooMuch: true),
            offer(12),
            offer(16),
          ], plans: plans),
        ),
        isNull,
      );
    });

    test('3 "Too much" on 2 dates → nothing', () {
      // Two journal records can't share a day in the app; the gate still
      // counts dates, not records.
      expect(
        planPacing(
          inputs([
            offer(1, tooMuch: true),
            offer(1, tooMuch: true),
            offer(8, tooMuch: true),
            offer(12),
            offer(16),
          ], plans: plans),
        ),
        isNull,
      );
    });

    final qualifying = [
      offer(1, tooMuch: true),
      offer(4),
      offer(8, tooMuch: true),
      offer(12),
      offer(16, tooMuch: true),
    ];

    test('the gate met → keep this Plan gentler for now', () {
      final c = planPacing(inputs(qualifying, plans: plans))!;
      expect(
        c.text,
        'On 3 of your last 5 Getting going days, you chose “Too much for '
        'today”.',
      );
      expect(c.application, isA<KeepGentler>());
    });

    test('offers composed gentler never count', () {
      expect(
        planPacing(
          inputs([
            offer(1, tooMuch: true),
            offer(4),
            offer(8, tooMuch: true),
            offer(12, gentler: true),
            offer(16, tooMuch: true, gentler: true),
          ], plans: plans),
        ),
        isNull,
      );
    });

    test('already applied → never offered', () {
      final gentler = plans.keepGentler('getting_going', today: day(2))!;
      expect(planPacing(inputs(qualifying, plans: gentler)), isNull);
    });

    test('no active Plan → nothing', () {
      expect(
        planPacing(inputs(qualifying, plans: plans.pause('getting_going')!)),
        isNull,
      );
    });
  });

  group('I3 — a part you skip', () {
    // Seven composed Circles across 14 days satisfy the pattern gate.
    List<InsightCircle> base() => [
      for (final n in [3, 5, 7, 9, 11, 13, 16]) at(n, head, parts: reading),
    ];
    InsightCircle win(int n, {bool skip = false}) => at(
      n,
      energy,
      parts: window,
      skipped: skip ? {ElementId.openWindow} : const {},
    );

    test('2 of 4 skipped → nothing', () {
      expect(
        skippedPart(
          inputs([
            ...base(),
            win(2, skip: true),
            win(6),
            win(10, skip: true),
            win(12),
          ]),
        ),
        isNull,
      );
    });

    test('3 of 4 but on 2 dates → nothing', () {
      expect(
        skippedPart(
          inputs([
            ...base(),
            win(2, skip: true),
            win(2, skip: true),
            win(10, skip: true),
            win(12),
          ]),
        ),
        isNull,
      );
    });

    final qualifying = [
      win(2, skip: true),
      win(6),
      win(10, skip: true),
      win(12, skip: true),
    ];

    test('3 of 4 on 3 dates → leave it out next time', () {
      final c = skippedPart(inputs([...base(), ...qualifying]))!;
      expect(
        c.text,
        'You skipped “Open a window” in 3 of the 4 Circles it was part of, '
        'most recently on 29 October.',
      );
      expect((c.application as LeaveOutPart).element, 'openWindow');
    });

    test('already left out → nothing', () {
      expect(
        skippedPart(
          inputs([...base(), ...qualifying], leftOut: {ElementId.openWindow}),
        ),
        isNull,
      );
    });

    test('a part skipped with the one it builds on is not a direct skip', () {
      // getItOut skipped: chooseOne and firstStep go with it.
      final circles = [
        ...base(),
        for (final n in [2, 6, 10, 12])
          at(
            n,
            head,
            parts: writing,
            skipped: {
              ElementId.getItOut,
              ElementId.chooseOne,
              ElementId.firstStep,
            },
          ),
      ];
      expect(circles.last.directSkips, {ElementId.getItOut});
      final c = skippedPart(inputs(circles))!;
      expect(c.facts['element'], 'getItOut');
    });

    test('of the last 4 when it appeared more often', () {
      final c = skippedPart(inputs([...base(), win(20), ...qualifying]))!;
      expect(c.text, contains('in 3 of the last 4 Circles'));
    });

    test('withdrawn after 2 unskipped appearances in a row', () {
      final shown = skippedPart(
        inputs([...base(), ...qualifying]),
      )!.snapshot(day(1));
      final later = today.add(const Duration(days: 3));
      InsightCircle afterwards(int daysLater, {bool skip = false}) =>
          InsightCircle(
            circleId: 'later$daysLater',
            localDate: dayOf(today.add(Duration(days: daysLater)), 1),
            need: energy,
            parts: window,
            skipped: skip ? {ElementId.openWindow} : const {},
          );
      final one = inputs([...base(), ...qualifying, afterwards(1)], on: later);
      expect(statusOf(shown, one), InsightStatus.current);
      final two = inputs([
        ...base(),
        ...qualifying,
        afterwards(1),
        afterwards(2),
      ], on: later);
      expect(statusOf(shown, two), InsightStatus.stale);
      final broken = inputs([
        ...base(),
        ...qualifying,
        afterwards(1),
        afterwards(2, skip: true),
      ], on: later);
      expect(statusOf(shown, broken), InsightStatus.current);
    });
  });

  group('I4 — what your useful Circles shared', () {
    const very = PastUsefulness.veryUseful;
    const somewhat = PastUsefulness.somewhatUseful;
    const no = PastUsefulness.notUseful;

    List<InsightCircle> useful(List<int> days, {List<CirclePart>? parts}) => [
      for (final (k, n) in days.indexed)
        at(
          n,
          head,
          parts: parts ?? writing,
          answer: k.isEven ? very : somewhat,
        ),
    ];
    List<InsightCircle> others(int count, {int writingCount = 0}) => [
      for (var k = 0; k < count; k++)
        at(
          30 + k * 5,
          head,
          parts: k < writingCount ? writing : reading,
          answer: k.isEven ? null : no,
        ),
    ];

    test('fewer than 4 useful → nothing', () {
      expect(
        usefulInCommon(
          inputs([
            ...useful([2, 9, 20]),
            ...others(3),
          ]),
        ),
        isNull,
      );
    });

    test('useful Circles on fewer than 3 dates → nothing', () {
      expect(
        usefulInCommon(
          inputs([
            ...useful([2, 2, 20, 20]),
            ...others(3),
          ]),
        ),
        isNull,
      );
    });

    test('useful Circles spanning less than 14 days → nothing', () {
      expect(
        usefulInCommon(
          inputs([
            ...useful([2, 5, 9, 14]),
            ...others(3),
          ]),
        ),
        isNull,
      );
    });

    test('fewer than 3 other Circles → nothing', () {
      expect(
        usefulInCommon(
          inputs([
            ...useful([2, 8, 14, 15]),
            ...others(2),
          ]),
        ),
        isNull,
      );
    });

    test('the kind in fewer than ⌈2/3⌉ of the useful set → nothing', () {
      // 3 of 6 useful Circles had writing.
      final mixed = [
        ...useful([2, 8, 14]),
        ...useful([16, 18, 20], parts: reading),
      ];
      expect(usefulInCommon(inputs([...mixed, ...others(3)])), isNull);
    });

    test('the kind in fewer than 3 useful Circles → nothing', () {
      // 2 of 3 is ⌈2/3⌉, but under 3.
      final circles = [
        ...useful([2, 15], parts: writing),
        ...useful([8], parts: reading),
        ...useful([20], parts: [part(ElementId.lookAround)]),
        ...others(3),
      ];
      expect(usefulInCommon(inputs(circles)), isNull);
    });

    test('under 25 points above its share of the others → nothing', () {
      // 4/4 useful vs 3/4 others: 25 points short of the guard? 100 − 75 =
      // 25 meets it; 3 of 3 others (100 %) doesn't.
      expect(
        usefulInCommon(
          inputs([
            ...useful([2, 8, 14, 15]),
            ...others(3, writingCount: 3),
          ]),
        ),
        isNull,
      );
    });

    test('exactly 25 points → eligible', () {
      final c = usefulInCommon(
        inputs([
          ...useful([2, 8, 14, 15]),
          ...others(4, writingCount: 3),
        ]),
      );
      expect(c, isNotNull);
      expect(c!.facts['inUseful'], 4);
      expect(c.facts['inOther'], 3);
    });

    test('the wording shows both fractions; unanswered stays "other"', () {
      final circles = [
        ...useful([2, 8, 14, 15, 20, 22]),
        ...others(9, writingCount: 2),
      ];
      final c = usefulInCommon(inputs(circles))!;
      expect(
        c.text,
        'Writing was part of 6 of the 6 Clearer Head Circles you called '
        'useful, and 2 of the 9 other Clearer Head Circles in that time.',
      );
      expect(c.text, isNot(contains('not useful')));
      expect(c.text, isNot(contains('weren’t')));
      final keep = c.application as KeepCircleFromHistory;
      expect(keep.circleId, circles[0].circleId, reason: 'the most recent');
    });

    test('already kept, or 8 kept → Nothing to change', () {
      final circles = [
        ...useful([2, 8, 14, 15]),
        ...others(3),
      ];
      final kept = usefulInCommon(
        inputs(circles, kept: {circles[0].circleId}),
      )!;
      expect(kept.application, isA<NothingToChange>());
      expect(
        (kept.application as NothingToChange).text,
        InsightCopy.usefulAlreadyWeighted,
      );
      final full = usefulInCommon(inputs(circles, keptCount: 8))!;
      expect(full.application, isA<NothingToChange>());
    });

    test('day 90 inside, day 91 outside', () {
      expect(
        usefulInCommon(
          inputs([
            ...useful([2, 8, 14, 90]),
            ...others(3),
          ]),
        ),
        isNotNull,
      );
      expect(
        usefulInCommon(
          inputs([
            ...useful([2, 8, 14, 91]),
            ...others(3),
          ]),
        ),
        isNull,
      );
    });
  });

  group('I6 — what\'s changed', () {
    /// [of] Circles across days [from]…[from] + 27: [topCount] of [top],
    /// the rest split between the other two needs.
    List<InsightCircle> window(int from, Intention top, int topCount, int of) {
      final rest = [
        for (final n in Intention.values)
          if (n != top) n,
      ];
      return [
        for (var k = 0; k < of; k++)
          at(from + (k * 27 ~/ (of - 1)), k < topCount ? top : rest[k % 2]),
      ];
    }

    test('an earlier window short of the gate → nothing', () {
      expect(
        whatsChanged(
          inputs([...window(1, energy, 6, 9), ...window(57, gentle, 3, 4)]),
        ),
        isNull,
      );
    });

    test('a recent window short of the gate → nothing', () {
      expect(
        whatsChanged(
          inputs([...window(1, energy, 3, 4), ...window(57, gentle, 6, 9)]),
        ),
        isNull,
      );
    });

    test('the same top need → nothing', () {
      expect(
        whatsChanged(
          inputs([...window(1, head, 6, 9), ...window(57, head, 6, 9)]),
        ),
        isNull,
      );
    });

    test('a top need under 40 % → nothing; exactly 40 % → eligible', () {
      // 5 of 13: the unique top, at 38 %.
      final low = [
        for (var k = 0; k < 13; k++)
          at(1 + k * 2, k < 5 ? head : (k.isEven ? energy : gentle)),
      ];
      expect(
        whatsChanged(inputs([...low, ...window(57, gentle, 6, 9)])),
        isNull,
      );
      // 4 of 10: exactly 40 %.
      final forty = [
        for (var k = 0; k < 10; k++)
          at(1 + k * 3, k < 4 ? head : (k.isEven ? energy : gentle)),
      ];
      expect(
        whatsChanged(inputs([...forty, ...window(57, gentle, 6, 9)])),
        isNotNull,
      );
    });

    test('different unique top needs → the Plan for the recent one', () {
      final c = whatsChanged(
        inputs([...window(1, energy, 11, 18), ...window(57, gentle, 9, 16)]),
      )!;
      expect(
        c.text,
        'From 8 August to 4 September you chose Gentler Pace most (9 of 16). '
        'In the last four weeks it’s been More Energy (11 of 18).',
      );
      expect((c.application as PlanDirection).planId, 'getting_going');
    });

    test('days 57 and 84 inside the earlier window, 56 and 85 outside', () {
      expect(day(84), '2026-08-08');
      expect(day(57), '2026-09-04');
      final edges = [
        for (final n in [57, 60, 66, 75, 84]) at(n, gentle),
        at(70, energy),
      ];
      final recent = window(1, energy, 6, 9);
      expect(whatsChanged(inputs([...recent, ...edges])), isNotNull);
      final outside = [
        for (final n in [56, 60, 66, 75, 85]) at(n, gentle),
        at(70, energy),
      ];
      expect(whatsChanged(inputs([...recent, ...outside])), isNull);
    });

    test('the recent need\'s Plan already active → Nothing to change', () {
      final active = CirclePlansState.empty.start(
        'getting_going',
        today: '2026-10-01',
      )!;
      final c = whatsChanged(
        inputs([
          ...window(1, energy, 11, 18),
          ...window(57, gentle, 9, 16),
        ], plans: active),
      )!;
      expect(
        (c.application as NothingToChange).text,
        'Nothing to change — Getting going is already your Plan.',
      );
    });
  });

  group('I5 — the Plan review, by reference', () {
    PlanStageProvenance stage(int n, {String cycle = 'making_room#1'}) =>
        PlanStageProvenance(
          planId: 'making_room',
          cycleId: cycle,
          stageNumber: n,
          stageId: 'making_room.$n',
        );
    CirclePlansState guided(int through) {
      var s = CirclePlansState.empty.start('making_room', today: '2026-10-01')!;
      for (var n = 1; n <= through; n++) {
        s = s.recordGuided(
          stage(n),
          circleId: 'c$n',
          today: '2026-10-1$n',
          parts: const [],
          skipped: const [],
        );
      }
      return s;
    }

    test('stage 5 guided → a review at once, with no evidence delay', () {
      final ended = guided(5);
      final reviews = planReviews(inputs(const [], plans: ended));
      expect(reviews, hasLength(1));
      expect(reviews.single.application, isA<OpenPlanReview>());
      expect(reviews.single.evidence, ['c1', 'c2', 'c3', 'c4', 'c5']);
    });

    test('left with 2 guided → none; with 3 → a review', () {
      expect(
        planReviews(
          inputs(
            const [],
            plans: guided(2).leave('making_room', today: day(1))!,
          ),
        ),
        isEmpty,
      );
      expect(
        planReviews(
          inputs(
            const [],
            plans: guided(3).leave('making_room', today: day(1))!,
          ),
        ),
        hasLength(1),
      );
    });

    test('a revisit never makes up the third guided stage', () {
      var s = guided(2).requestRevisit('making_room', 1)!;
      s = s.recordGuided(
        PlanStageProvenance(
          planId: 'making_room',
          cycleId: 'making_room#1',
          stageNumber: 1,
          stageId: 'making_room.1',
          revisit: true,
        ),
        circleId: 'again',
        today: '2026-10-20',
        parts: const [],
        skipped: const [],
      );
      s = s.leave('making_room', today: day(1))!;
      expect(planReviews(inputs(const [], plans: s)), isEmpty);
    });

    test('Delete history: the review goes with its evidence', () {
      final forgotten = guided(5).forgetStageEvidence();
      expect(planReviews(inputs(const [], plans: forgotten)), isEmpty);
    });

    test('a review is generated once, and bypasses the 7-day cadence', () {
      final plans = guided(5);
      final i = inputs([at(3, head)], plans: plans);
      final ordinary = planForNeed(
        inputs([
          for (final n in [2, 6, 10, 14, 15]) at(n, gentle),
        ]),
      )!.snapshot(day(2));
      final first = assessInsights(i, [ordinary], generate: true);
      expect(first.added.map((s) => s.family), [InsightFamily.planReview]);
      final again = assessInsights(i, first.snapshots, generate: true);
      expect(again.added, isEmpty);
    });
  });

  group('priority, cadence and "Not now"', () {
    // I3, I1 and I6 all qualify at once.
    List<InsightCircle> everything() => [
      for (final n in [3, 5, 7, 9, 11, 13, 16]) at(n, head, parts: reading),
      for (final (k, n) in [2, 6, 10, 12].indexed)
        at(
          n,
          energy,
          parts: window,
          skipped: k == 1 ? const {} : {ElementId.openWindow},
        ),
      for (final n in [60, 62, 66, 70, 75, 80]) at(n, gentle),
    ];

    test('I3 > I2 > I4 > I1 > I6, deterministically', () {
      final i = inputs(everything());
      final families = ordinaryCandidates(i).map((c) => c.family).toList();
      expect(families.first, InsightFamily.skippedPart);
      expect(
        families,
        containsAllInOrder([
          InsightFamily.skippedPart,
          InsightFamily.planForNeed,
          InsightFamily.whatsChanged,
        ]),
      );
      final a = assessInsights(i, const [], generate: true);
      final b = assessInsights(i, const [], generate: true);
      expect(a.added.single.family, InsightFamily.skippedPart);
      expect(a.added.single.id, b.added.single.id);
    });

    test('ordinaryInsightPriority is the frozen order', () {
      expect(ordinaryInsightPriority.map((f) => f.id), [
        'insight.skipped_part',
        'insight.plan_pacing',
        'insight.useful_in_common',
        'insight.plan_for_need',
        'insight.whats_changed',
      ]);
    });

    test('I2 beats I4, and I4 beats I1', () {
      final plans = CirclePlansState.empty.start(
        'getting_going',
        today: '2026-09-01',
      )!;
      PlanStageProvenance stage() => const PlanStageProvenance(
        planId: 'getting_going',
        cycleId: 'getting_going#1',
        stageNumber: 1,
        stageId: 'getting_going.1',
      );
      final circles = [
        // I2: 5 offers, 3 "Too much".
        for (final (k, n) in [1, 4, 8, 12, 16].indexed)
          k.isEven
              ? at(n, energy, replacedFromStage: stage(), reason: 'tooMuch')
              : at(n, energy, stage: stage(), parts: window),
        // I4 and I1: Clearer Head, useful with writing.
        for (final (k, n) in [2, 9, 15, 20, 26].indexed)
          at(
            n,
            head,
            parts: writing,
            answer: k.isEven
                ? PastUsefulness.veryUseful
                : PastUsefulness.somewhatUseful,
          ),
        for (final n in [3, 6, 10, 14, 17, 21, 25]) at(n, head, parts: reading),
      ];
      final families = ordinaryCandidates(
        inputs(circles, plans: plans),
      ).map((c) => c.family).toList();
      expect(families.take(3), [
        InsightFamily.planPacing,
        InsightFamily.usefulInCommon,
        InsightFamily.planForNeed,
      ]);
    });

    test('a second new Insight waits 7 days; day 7 is allowed', () {
      final circles = everything();
      final first = assessInsights(inputs(circles), const [], generate: true);
      for (final d in [1, 6]) {
        final soon = assessInsights(
          inputs(circles, on: today.add(Duration(days: d))),
          first.snapshots,
          generate: true,
        );
        expect(soon.added, isEmpty, reason: 'day $d');
        expect(soon.readiness, InsightReadiness.insightAvailable);
      }
      // The current one said "Not now": on day 6 THIRTY still waits.
      final quiet = [
        for (final s in first.snapshots) s.copyWith(notNowOn: day(1)),
      ];
      final waiting = assessInsights(
        inputs(circles, on: today.add(const Duration(days: 6))),
        quiet,
        generate: true,
      );
      expect(waiting.added, isEmpty);
      expect(waiting.readiness, InsightReadiness.cadenceWaiting);
      final week = assessInsights(
        inputs(circles, on: today.add(const Duration(days: 7))),
        quiet,
        generate: true,
      );
      expect(week.added, hasLength(1));
      expect(
        week.added.single.family,
        isNot(InsightFamily.skippedPart),
        reason: 'the same observation stays quiet for 28 days',
      );
    });

    test('the History a "Not now" rests on is untouched', () {
      final circles = everything();
      final shown = assessInsights(
        inputs(circles),
        const [],
        generate: true,
      ).added.single;
      final quiet = [shown.copyWith(notNowOn: day(1))];
      expect(isQuiet(skippedPart(inputs(circles))!, quiet, today), isTrue);
      expect(circles.where((c) => c.skipped.isNotEmpty), hasLength(3));
    });

    test('a stale snapshot never blocks a new valid one forever', () {
      final circles = [
        for (final n in [2, 6, 10, 14, 15]) at(n, head),
      ];
      final shown = assessInsights(
        inputs(circles),
        const [],
        generate: true,
      ).snapshots;
      expect(shown.single.family, InsightFamily.planForNeed);
      // Two months later the old choices are out of the window, and the
      // same pattern has formed again.
      final later = today.add(const Duration(days: 60));
      expect(
        statusOf(shown.single, inputs(circles, on: later)),
        InsightStatus.stale,
      );
      final fresh = [
        for (final n in [2, 6, 10, 14, 15])
          InsightCircle(
            circleId: 'new$n',
            localDate: dayOf(later, n),
            need: head,
          ),
      ];
      final next = assessInsights(
        inputs([...circles, ...fresh], on: later),
        shown,
        generate: true,
      );
      expect(next.added.single.family, InsightFamily.planForNeed);
      expect(next.added.single.subject, shown.single.subject);
    });
  });

  group('"Not now" hides the evidence set (§11) — not the subject', () {
    final week = today.add(const Duration(days: 7));
    final soon = today.add(const Duration(days: 3));
    // New Circles are dated three days after the Insight was shown: day 5
    // a week on, day 1 three days on.
    var fresh = 0;
    InsightCircle onDay3(
      Intention need, {
      List<CirclePart> parts = const [],
      Set<ElementId> skipped = const {},
      PastUsefulness? answer,
      PlanStageProvenance? stage,
    }) => InsightCircle(
      circleId: 'new${fresh++}',
      localDate: dayOf(soon, 1),
      need: need,
      parts: parts,
      skipped: skipped,
      answer: answer,
      stage: stage,
    );

    /// Shown on day 1 and set aside with "Not now"; then, a week on, the
    /// same evidence (with [irrelevant] Circles added) stays hidden, and
    /// [relevant] new Circles make it new evidence as far as "Not now" goes
    /// — while the 28-day repeat cooldown still holds the claim back.
    void evidenceSet(
      InsightFamily family,
      InsightCandidate? Function(InsightInputs) evaluate,
      List<InsightCircle> base, {
      List<InsightCircle> irrelevant = const [],
      required List<InsightCircle> relevant,
      CirclePlansState plans = CirclePlansState.empty,
    }) {
      final first = evaluate(inputs(base, plans: plans))!;
      final shown = first.snapshot(day(1)).copyWith(notNowOn: day(1));
      expect(shown.evidenceFingerprint, startsWith('${first.subject}#'));

      // The same evidence a week on: still true, still hidden.
      final same = inputs([...base, ...irrelevant], plans: plans, on: week);
      final again = evaluate(same)!;
      expect(again.subject, first.subject);
      expect(again.evidence.every(first.evidence.contains), isTrue);
      expect(isQuiet(again, [shown], week), isTrue);
      expect(
        assessInsights(same, [
          shown,
        ], generate: true).added.where((s) => s.family == family),
        isEmpty,
      );
      // For 28 days, not longer.
      expect(
        isQuiet(again, [shown], today.add(const Duration(days: 27))),
        isTrue,
      );
      expect(
        isQuiet(again, [shown], today.add(const Duration(days: 28))),
        isFalse,
      );

      // Materially new evidence for the same claim may qualify…
      final grown = inputs([...base, ...relevant], plans: plans, on: week);
      final next = evaluate(grown)!;
      expect(next.subject, first.subject);
      expect(
        next.evidence.toSet().difference(first.evidence.toSet()),
        isNotEmpty,
      );
      expect(
        insightFingerprint(next.subject, next.evidence),
        isNot(shown.evidenceFingerprint),
      );
      expect(isQuiet(next, [shown], week), isFalse);
      // …yet the same claim, shown 7 days ago, isn't eligible again inside
      // its 28 days (the repeat cooldown, a separate rule).
      expect(claimCooling(next.subject, [shown], week), isTrue);
      expect(
        assessInsights(grown, [
          shown,
        ], generate: true).added.where((s) => s.family == family),
        isEmpty,
      );
      final early = inputs([...base, ...relevant], plans: plans, on: soon);
      expect(isQuiet(evaluate(early)!, [shown], soon), isFalse);
      expect(assessInsights(early, [shown], generate: true).added, isEmpty);
    }

    test('the fingerprint: the same Circles in any order are the same set', () {
      expect(
        insightFingerprint('s', ['b', 'a', 'c']),
        insightFingerprint('s', ['c', 'b', 'a', 'a']),
      );
      expect(
        insightFingerprint('s', ['a', 'b']),
        isNot(insightFingerprint('s', ['a', 'b', 'c'])),
      );
      expect(
        insightFingerprint('s', ['a']),
        isNot(insightFingerprint('t', ['a'])),
      );
    });

    test('I1: the same chosen-need days hidden; a new Clearer Head day is '
        'new evidence; another need’s day changes nothing', () {
      evidenceSet(
        InsightFamily.planForNeed,
        planForNeed,
        [
          for (final n in [2, 6, 10, 14, 15]) at(n, head),
        ],
        irrelevant: [onDay3(energy)],
        relevant: [onDay3(head)],
      );
    });

    test('I2: the same offers hidden; a new untreated offer is new '
        'evidence; an ordinary Circle changes nothing', () {
      const stage = PlanStageProvenance(
        planId: 'getting_going',
        cycleId: 'getting_going#1',
        stageNumber: 1,
        stageId: 'getting_going.1',
      );
      evidenceSet(
        InsightFamily.planPacing,
        planPacing,
        [
          for (final (k, n) in [1, 4, 8, 12, 16].indexed)
            k.isEven
                ? at(n, energy, replacedFromStage: stage, reason: 'tooMuch')
                : at(n, energy, stage: stage, parts: window),
        ],
        irrelevant: [onDay3(head, parts: reading)],
        relevant: [onDay3(energy, parts: window, stage: stage)],
        plans: CirclePlansState.empty.start(
          'getting_going',
          today: '2026-09-01',
        )!,
      );
    });

    test('I3: the same last four hidden; a new skipped appearance changes '
        'the last four; a Circle without the part changes nothing', () {
      evidenceSet(
        InsightFamily.skippedPart,
        skippedPart,
        [
          for (final n in [3, 5, 7, 9, 11, 13, 16]) at(n, head, parts: reading),
          at(2, energy, parts: window, skipped: {ElementId.openWindow}),
          at(6, energy, parts: window),
          at(10, energy, parts: window, skipped: {ElementId.openWindow}),
          at(12, energy, parts: window, skipped: {ElementId.openWindow}),
        ],
        irrelevant: [onDay3(head, parts: reading)],
        relevant: [
          onDay3(energy, parts: window, skipped: {ElementId.openWindow}),
        ],
      );
    });

    test('I4: the same useful and other Circles hidden; a new Clearer Head '
        'Circle changes the fractions; another need changes nothing', () {
      evidenceSet(
        InsightFamily.usefulInCommon,
        usefulInCommon,
        [
          for (final (k, n) in [1, 7, 13, 20].indexed)
            at(
              n,
              head,
              parts: writing,
              answer: k.isEven
                  ? PastUsefulness.veryUseful
                  : PastUsefulness.somewhatUseful,
            ),
          for (final n in [3, 9, 16]) at(n, head, parts: reading),
        ],
        irrelevant: [onDay3(energy, parts: window)],
        relevant: [onDay3(head, parts: reading)],
      );
    });

    test('I6: the same two windows hidden, even as older Circles leave '
        'them; a new recent Circle is new evidence', () {
      List<InsightCircle> spread(
        int from,
        Intention top,
        int topCount,
        int of,
      ) {
        final rest = [
          for (final n in Intention.values)
            if (n != top) n,
        ];
        return [
          for (var k = 0; k < of; k++)
            at(from + (k * 27 ~/ (of - 1)), k < topCount ? top : rest[k % 2]),
        ];
      }

      evidenceSet(
        InsightFamily.whatsChanged,
        whatsChanged,
        [...spread(1, energy, 11, 18), ...spread(57, gentle, 9, 16)],
        relevant: [onDay3(energy)],
        // Getting going is already the Plan: I1 stays out of the way, and
        // I6 says "Nothing to change".
        plans: CirclePlansState.empty.start(
          'getting_going',
          today: '2026-06-01',
        )!,
      );
    });

    test('I5: a Plan review is never hidden by "Not now"', () {
      var plans = CirclePlansState.empty.start(
        'making_room',
        today: '2026-10-01',
      )!;
      for (var n = 1; n <= 5; n++) {
        plans = plans.recordGuided(
          PlanStageProvenance(
            planId: 'making_room',
            cycleId: 'making_room#1',
            stageNumber: n,
            stageId: 'making_room.$n',
          ),
          circleId: 'c$n',
          today: '2026-10-1$n',
          parts: const [],
          skipped: const [],
        );
      }
      final review = planReviews(inputs(const [], plans: plans)).single;
      final quieted = review.snapshot(day(1)).copyWith(notNowOn: day(1));
      expect(isQuiet(review, [quieted], today), isFalse);
    });

    group('I2 and the gentler setting', () {
      PlanStageProvenance stage(String cycle) => PlanStageProvenance(
        planId: 'getting_going',
        cycleId: cycle,
        stageNumber: 1,
        stageId: 'getting_going.1',
      );
      final offers = [
        for (final (k, n) in [1, 4, 8, 12, 16].indexed)
          k.isEven
              ? at(
                  n,
                  energy,
                  replacedFromStage: stage('getting_going#1'),
                  reason: 'tooMuch',
                )
              : at(n, energy, stage: stage('getting_going#1'), parts: window),
      ];
      final cycle1 = CirclePlansState.empty.start(
        'getting_going',
        today: '2026-09-01',
      )!;

      test('while gentler is on in the cycle, I2 is not offered', () {
        final on = cycle1.keepGentler('getting_going', today: day(1))!;
        expect(planPacing(inputs(offers, plans: on)), isNull);
      });

      test('after the cycle ends: the same evidence is never offered again '
          'at once; a new untreated offer may support it; nothing is '
          'hidden for good', () {
        final shown = planPacing(inputs(offers, plans: cycle1))!;
        final applied = shown.snapshot(day(1)).copyWith(appliedOn: day(1));
        final cycle2 = cycle1
            .keepGentler('getting_going', today: day(1))!
            .leave('getting_going', today: day(1))!
            .goThroughAgain('getting_going', today: day(1))!;
        expect(
          cycle2.active!.current.isGentler,
          isFalse,
          reason: 'the setting ended with its cycle',
        );
        // The new cycle with no new offers: the same evidence, hidden.
        final same = planPacing(inputs(offers, plans: cycle2, on: week))!;
        expect(isQuiet(same, [applied], week), isTrue);
        // A new untreated offer in the new cycle is new evidence.
        final grown = planPacing(
          inputs(
            [
              ...offers,
              onDay3(energy, parts: window, stage: stage('getting_going#2')),
            ],
            plans: cycle2,
            on: week,
          ),
        )!;
        expect(isQuiet(grown, [applied], week), isFalse);
        expect(grown.facts['cycleId'], 'getting_going#2');
        // No lasting "this Plan had gentler once": after 28 days even the
        // same set may return, if it still qualified.
        expect(
          isQuiet(same, [applied], today.add(const Duration(days: 28))),
          isFalse,
        );
      });

      test('offers composed gentler never become new evidence', () {
        final shown = planPacing(inputs(offers, plans: cycle1))!;
        final quieted = shown.snapshot(day(1)).copyWith(notNowOn: day(1));
        final treated = planPacing(
          inputs(
            [
              ...offers,
              InsightCircle(
                circleId: 'treated',
                localDate: dayOf(soon, 1),
                need: energy,
                parts: window,
                stage: const PlanStageProvenance(
                  planId: 'getting_going',
                  cycleId: 'getting_going#1',
                  stageNumber: 2,
                  stageId: 'getting_going.2',
                  gentler: true,
                ),
              ),
            ],
            plans: cycle1,
            on: week,
          ),
        )!;
        expect(treated.evidence, isNot(contains('treated')));
        expect(isQuiet(treated, [quieted], week), isTrue);
      });
    });
  });

  group('the same claim at most once in 28 days (founder, 2026-10-18)', () {
    var made = 0;

    /// A Circle [offset] days after today (negative: before).
    InsightCircle on(
      int offset,
      Intention need, {
      List<CirclePart> parts = const [],
      Set<ElementId> skipped = const {},
      PastUsefulness? answer,
      PlanStageProvenance? stage,
      PlanStageProvenance? replacedFromStage,
      String? reason,
    }) => InsightCircle(
      circleId: 'r${made++}@$offset',
      localDate: dayOf(today.add(Duration(days: offset)), 1),
      need: need,
      parts: parts,
      skipped: skipped,
      answer: answer,
      stage: stage,
      replacedFromStage: replacedFromStage,
      replacementReason: reason,
    );

    DateTime dayAfter(int offset) => today.add(Duration(days: offset));

    /// Shown on day 0 and set aside with "Not now". Evidence keeps arriving:
    /// on days 7–27 the claim still qualifies and isn't hidden by "Not now"
    /// (its evidence is new), yet it isn't shown; on day 28 it may be.
    void repeats(
      InsightFamily family,
      InsightCandidate? Function(InsightInputs) evaluate,
      List<InsightCircle> Function(int upTo) history, {
      CirclePlansState plans = CirclePlansState.empty,
    }) {
      final first = assessInsights(
        inputs(history(0), plans: plans),
        const [],
        generate: true,
      ).added.single;
      expect(first.family, family);
      final shown = [first.copyWith(notNowOn: day(1))];
      for (final d in [7, 14, 21, 27]) {
        final i = inputs(history(d), plans: plans, on: dayAfter(d));
        final now = evaluate(i)!;
        expect(now.subject, first.subject);
        expect(isQuiet(now, shown, dayAfter(d)), isFalse, reason: 'day $d');
        expect(claimCooling(now.subject, shown, dayAfter(d)), isTrue);
        expect(
          assessInsights(
            i,
            shown,
            generate: true,
          ).added.where((s) => s.subject == first.subject),
          isEmpty,
          reason: 'day $d',
        );
      }
      final i28 = inputs(history(28), plans: plans, on: dayAfter(28));
      expect(claimCooling(first.subject, shown, dayAfter(28)), isFalse);
      final again = assessInsights(i28, shown, generate: true).added;
      expect(again.map((s) => s.subject), contains(first.subject));
    }

    test(
      'I1: blocked on days 7–27 despite new choices; may return on day 28',
      () {
        repeats(
          InsightFamily.planForNeed,
          planForNeed,
          (upTo) => [for (var o = -27; o <= upTo; o += 3) on(o, head)],
        );
      },
    );

    test('I2: the same Plan claim waits 28 days', () {
      const stage = PlanStageProvenance(
        planId: 'getting_going',
        cycleId: 'getting_going#1',
        stageNumber: 1,
        stageId: 'getting_going.1',
      );
      repeats(
        InsightFamily.planPacing,
        planPacing,
        (upTo) => [
          for (var o = -27, k = 0; o <= upTo; o += 3, k++)
            k.isEven
                ? on(o, energy, replacedFromStage: stage, reason: 'tooMuch')
                : on(o, energy, stage: stage, parts: window),
        ],
        plans: CirclePlansState.empty.start(
          'getting_going',
          today: '2026-09-01',
        )!,
      );
    });

    test('I2 across cycles: applied, the setting ends with its cycle, new '
        'untreated offers arrive — still not before day 28', () {
      PlanStageProvenance stage(String cycle) => PlanStageProvenance(
        planId: 'getting_going',
        cycleId: cycle,
        stageNumber: 1,
        stageId: 'getting_going.1',
      );
      List<InsightCircle> offers(int from, int upTo, String cycle) => [
        for (var o = from, k = 0; o <= upTo; o += 3, k++)
          k.isEven
              ? on(
                  o,
                  energy,
                  replacedFromStage: stage(cycle),
                  reason: 'tooMuch',
                )
              : on(o, energy, stage: stage(cycle), parts: window),
      ];
      final before = offers(-27, 0, 'getting_going#1');
      final cycle1 = CirclePlansState.empty.start(
        'getting_going',
        today: '2026-09-01',
      )!;
      final shown = planPacing(inputs(before, plans: cycle1))!;
      final applied = [shown.snapshot(day(1)).copyWith(appliedOn: day(1))];
      final cycle2 = cycle1
          .keepGentler('getting_going', today: day(1))!
          .leave('getting_going', today: day(1))!
          .goThroughAgain('getting_going', today: day(1))!;
      expect(cycle2.active!.current.isGentler, isFalse);
      for (final d in [7, 27]) {
        final i = inputs(
          [...before, ...offers(1, d, 'getting_going#2')],
          plans: cycle2,
          on: dayAfter(d),
        );
        final now = planPacing(i)!;
        expect(
          isQuiet(now, applied, dayAfter(d)),
          isFalse,
          reason: 'new offers',
        );
        expect(
          assessInsights(
            i,
            applied,
            generate: true,
          ).added.where((s) => s.family == InsightFamily.planPacing),
          isEmpty,
          reason: 'day $d',
        );
      }
      final i28 = inputs(
        [...before, ...offers(1, 28, 'getting_going#2')],
        plans: cycle2,
        on: dayAfter(28),
      );
      final again = assessInsights(i28, applied, generate: true).added.single;
      expect(again.family, InsightFamily.planPacing);
      expect(again.facts['cycleId'], 'getting_going#2');
    });

    test('I3: the part keeps being skipped — not again inside 28 days', () {
      repeats(
        InsightFamily.skippedPart,
        skippedPart,
        (upTo) => [
          for (var o = -27; o <= upTo; o += 2) on(o, head, parts: reading),
          for (var o = -26, k = 0; o <= upTo; o += 4, k++)
            on(
              o,
              energy,
              parts: window,
              skipped: k % 4 == 1 ? const {} : {ElementId.openWindow},
            ),
        ],
      );
    });

    test('I4: the fractions change with new Circles — the same need and '
        'kind wait 28 days', () {
      repeats(
        InsightFamily.usefulInCommon,
        usefulInCommon,
        (upTo) => [
          for (var o = -80; o <= upTo; o += 5)
            on(o, head, parts: writing, answer: PastUsefulness.veryUseful),
          for (var o = -78; o <= upTo; o += 5) on(o, head, parts: reading),
        ],
      );
    });

    test('I6: the same change of need waits 28 days; another change is a '
        'different claim', () {
      repeats(
        InsightFamily.whatsChanged,
        whatsChanged,
        (upTo) => [
          for (var o = -90; o <= upTo; o += 2) on(o, o < -20 ? gentle : energy),
        ],
        plans: CirclePlansState.empty.start(
          'getting_going',
          today: '2026-06-01',
        )!,
      );
      final shown = whatsChanged(
        inputs([
          for (var o = -90; o <= 0; o += 2) on(o, o < -20 ? gentle : energy),
        ]),
      )!.snapshot(day(1));
      expect(
        claimCooling('insight.whats_changed:gentlerPace>moreEnergy', [
          shown,
        ], dayAfter(7)),
        isTrue,
      );
      expect(
        claimCooling('insight.whats_changed:moreEnergy>clearerHead', [
          shown,
        ], dayAfter(7)),
        isFalse,
      );
    });

    test('I5: two cycles\' reviews appear at once; no cooldown applies', () {
      var plans = CirclePlansState.empty.start(
        'making_room',
        today: '2026-09-01',
      )!;
      for (final cycle in [1, 2]) {
        for (var n = 1; n <= 5; n++) {
          plans = plans.recordGuided(
            PlanStageProvenance(
              planId: 'making_room',
              cycleId: 'making_room#$cycle',
              stageNumber: n,
              stageId: 'making_room.$n',
            ),
            circleId: 'c$cycle-$n',
            today: '2026-10-$cycle$n',
            parts: const [],
            skipped: const [],
          );
        }
        if (cycle == 1) {
          plans = plans.goThroughAgain('making_room', today: '2026-10-16')!;
        }
      }
      final ordinary = planForNeed(
        inputs([
          for (final n in [2, 6, 10, 14, 15]) at(n, gentle),
        ]),
      )!.snapshot(day(2));
      final result = assessInsights(inputs([at(3, head)], plans: plans), [
        ordinary,
      ], generate: true);
      expect(result.added.map((s) => s.family), [
        InsightFamily.planReview,
        InsightFamily.planReview,
      ]);
      for (final review in result.added) {
        expect(claimCooling(review.subject, result.snapshots, today), isFalse);
      }
    });

    test('no starvation: I1 cooling down lets I6 surface a week on', () {
      List<InsightCircle> history(int upTo) => [
        for (var o = -90; o < -30; o += 2) on(o, gentle),
        for (var o = -27; o <= upTo; o += 2) on(o, head),
      ];
      final first = assessInsights(
        inputs(history(0)),
        const [],
        generate: true,
      ).added.single;
      expect(first.family, InsightFamily.planForNeed);
      expect(
        ordinaryCandidates(inputs(history(0))).map((c) => c.family),
        contains(InsightFamily.whatsChanged),
      );
      final shown = [first.copyWith(notNowOn: day(1))];
      final week = inputs(history(7), on: dayAfter(7));
      // I1 still qualifies from new choices, and isn't hidden by "Not now".
      expect(isQuiet(planForNeed(week)!, shown, dayAfter(7)), isFalse);
      final next = assessInsights(week, shown, generate: true).added.single;
      expect(next.family, InsightFamily.whatsChanged);
    });

    test('priority among the eligible only: I3 > I2 > I4 > I1 > I6, each '
        'stepping aside while it cools down', () {
      void progression(InsightInputs i, List<InsightFamily> expected) {
        final candidates = ordinaryCandidates(i);
        expect(candidates.map((c) => c.family).toList(), expected);
        for (var k = 0; k < expected.length; k++) {
          // The first k claims were shown a week ago.
          final cooling = [
            for (final c in candidates.take(k)) c.snapshot(day(8)),
          ];
          final added = assessInsights(i, cooling, generate: true).added;
          expect(added.single.family, expected[k], reason: 'k=$k');
        }
      }

      final plans = CirclePlansState.empty.start(
        'getting_going',
        today: '2026-09-01',
      )!;
      const stage = PlanStageProvenance(
        planId: 'getting_going',
        cycleId: 'getting_going#1',
        stageNumber: 1,
        stageId: 'getting_going.1',
      );
      progression(
        inputs([
          for (final (k, n) in [1, 4, 8, 12, 16].indexed)
            k.isEven
                ? at(n, energy, replacedFromStage: stage, reason: 'tooMuch')
                : at(n, energy, stage: stage, parts: window),
          for (final (k, n) in [2, 9, 15, 20, 26].indexed)
            at(
              n,
              head,
              parts: writing,
              answer: k.isEven
                  ? PastUsefulness.veryUseful
                  : PastUsefulness.somewhatUseful,
            ),
          for (final n in [3, 6, 10, 14, 17, 21, 25])
            at(n, head, parts: reading),
        ], plans: plans),
        [
          InsightFamily.planPacing,
          InsightFamily.usefulInCommon,
          InsightFamily.planForNeed,
        ],
      );
      progression(
        inputs([
          for (final n in [3, 5, 7, 9, 11, 13, 16]) at(n, head, parts: reading),
          for (final (k, n) in [2, 6, 10, 12].indexed)
            at(
              n,
              energy,
              parts: window,
              skipped: k == 1 ? const {} : {ElementId.openWindow},
            ),
          for (final n in [60, 62, 66, 70, 75, 80]) at(n, gentle),
        ]),
        [
          InsightFamily.skippedPart,
          InsightFamily.planForNeed,
          InsightFamily.whatsChanged,
        ],
      );
    });

    test('the cap never lets a claim repeat early: ordinary snapshots under '
        '28 days old are kept', () {
      final recentClaim = planForNeed(
        inputs([
          for (final n in [2, 6, 10, 14, 15]) at(n, head),
        ]),
      )!.snapshot(day(20)).copyWith(notNowOn: day(20));
      final oldClaim = planForNeed(
        inputs([
          for (final n in [2, 6, 10, 14, 15]) at(n, gentle),
        ]),
      )!.snapshot(day(40));
      final reviews = [
        for (var k = 0; k < 55; k++)
          InsightSnapshot(
            id: 'review$k',
            family: InsightFamily.planReview,
            generatedOn: day(10 - (k % 9)),
            wordingVersion: 1,
            text: 'x',
            facts: const {},
            evidence: const [],
            subject: 'insight.plan_review:making_room:making_room#$k',
            application: OpenPlanReview('making_room', 'making_room#$k'),
          ),
      ];
      final pruned = pruneSnapshots([
        oldClaim,
        recentClaim,
        ...reviews,
      ], inputs(const []));
      expect(pruned, hasLength(maxInsightSnapshots));
      expect(pruned, contains(recentClaim));
      expect(pruned, isNot(contains(oldClaim)));
      expect(claimCooling(recentClaim.subject, pruned, today), isTrue);
    });
  });

  group('readiness (§12) — never a made-up Insight', () {
    test('no History', () {
      final a = assessInsights(inputs(const []), const [], generate: true);
      expect(a.readiness, InsightReadiness.noHistory);
      expect(a.added, isEmpty);
    });

    test('a week in: too short, with the status counts', () {
      final a = assessInsights(
        inputs([
          for (final n in [1, 2, 3, 5, 6, 7])
            at(n, head, answer: n.isOdd ? PastUsefulness.veryUseful : null),
        ]),
        const [],
        generate: true,
      );
      expect(a.readiness, InsightReadiness.tooShort);
      expect((a.circles, a.answers), (6, 4));
      expect(a.added, isEmpty);
    });

    test('enough History, nothing qualifies', () {
      final a = assessInsights(
        inputs([
          for (final (k, n) in [1, 4, 8, 12, 16, 20].indexed)
            at(n, Intention.values[k % 3]),
        ]),
        const [],
        generate: true,
      );
      expect(a.readiness, InsightReadiness.nothingQualifies);
      expect(a.added, isEmpty);
    });
  });

  group('retention', () {
    test('at most 52, oldest first — never the current Insight', () {
      final circles = [
        for (final n in [2, 6, 10, 14, 15]) at(n, head),
      ];
      // The current Insight is also the oldest snapshot.
      final current = planForNeed(inputs(circles))!.snapshot('2024-01-01');
      final old = [
        for (var k = 0; k < 60; k++)
          InsightSnapshot(
            id: 'old$k',
            family: InsightFamily.whatsChanged,
            generatedOn: dayOf(today.subtract(const Duration(days: 400)), -k),
            wordingVersion: 1,
            text: 'x',
            facts: const {},
            evidence: const [],
            subject: 'insight.whats_changed:old$k',
            application: const NothingToChange('x'),
            notNowOn: '2025-01-01',
          ),
      ];
      final pruned = pruneSnapshots([current, ...old], inputs(circles));
      expect(pruned, hasLength(maxInsightSnapshots));
      expect(pruned, contains(current));
      expect(pruned.map((s) => s.id), isNot(contains('old0')));
      expect(pruned.map((s) => s.id), contains('old59'));
    });
  });

  group('snapshots', () {
    test('round-trip through JSON with structured facts and evidence', () {
      final circles = [
        for (final n in [2, 6, 10, 14, 15]) at(n, head),
      ];
      final s = planForNeed(
        inputs(circles),
      )!.snapshot(day(1)).copyWith(appliedOn: day(1));
      final back = InsightSnapshot.fromJson(s.toJson())!;
      expect(back.toJson(), s.toJson());
      expect(back.wordingVersion, insightWordingVersion);
      expect(back.evidence, hasLength(5));
      expect(
        InsightsState.fromJson(InsightsState([s]).toJson())!.snapshots,
        hasLength(1),
      );
    });

    test('a snapshot holds no profile: only shown text, facts, dates and '
        'the evidence ids', () {
      final circles = [
        for (final n in [2, 6, 10, 14, 15]) at(n, head),
      ];
      final json = planForNeed(inputs(circles))!.snapshot(day(1)).toJson();
      expect(json.keys.toSet(), {
        'id',
        'family',
        'generatedOn',
        'wordingVersion',
        'text',
        'facts',
        'evidence',
        'subject',
        'application',
      });
    });
  });

  group('wording guards', () {
    final forbidden = RegExp(
      r'\b(because|caused?|improv\w*|boost\w*|anxiety|mood|more focused|'
      r'calmer|healthier|works for you|helps your|you need|tired|low energy|'
      r'recovering|stress|completed|progress|streak|you did it)\b',
      caseSensitive: false,
    );

    test('every template, every kind and every Plan', () {
      final lines = [
        InsightCopy.planForNeed(head, 9, 14, '2026-10-02', '2026-10-27'),
        for (final step in PlanStep.values)
          for (final p in launchCirclePlans) InsightCopy.planStep(step, p.name),
        InsightCopy.planPacing('Getting going', 3, 5),
        InsightCopy.keepGentler,
        InsightCopy.skippedPart(
          'Open a window',
          3,
          4,
          '2026-10-14',
          ofMore: false,
        ),
        InsightCopy.leaveOut,
        InsightCopy.keepIt,
        for (final kind in ElementKind.values)
          InsightCopy.usefulInCommon(kind, head, 5, 6, 2, 9),
        InsightCopy.keepCircle,
        InsightCopy.usefulAlreadyWeighted,
        InsightCopy.planReview('Making room', '2026-10-20'),
        InsightCopy.whatsChanged(
          '2026-07-01',
          '2026-07-28',
          gentle,
          9,
          16,
          energy,
          11,
          18,
        ),
        for (final p in launchCirclePlans) InsightCopy.alreadyYourPlan(p.name),
      ];
      for (final line in lines) {
        expect(forbidden.hasMatch(line), isFalse, reason: line);
      }
    });

    test('the frozen examples read as ADR-024 writes them', () {
      expect(
        InsightCopy.planForNeed(head, 9, 14, '2026-10-02', '2026-10-27'),
        'You chose Clearer Head on 9 of your last 14 Circles, between 2 and '
        '27 October.',
      );
      expect(
        InsightCopy.skippedPart(
          'Open a window',
          3,
          4,
          '2026-10-14',
          ofMore: false,
        ),
        'You skipped “Open a window” in 3 of the 4 Circles it was part of, '
        'most recently on 14 October.',
      );
      expect(
        InsightCopy.usefulInCommon(ElementKind.writing, head, 5, 6, 2, 9),
        'Writing was part of 5 of the 6 Clearer Head Circles you called '
        'useful, and 2 of the 9 other Clearer Head Circles in that time.',
      );
      expect(
        InsightCopy.whatsChanged(
          '2026-07-01',
          '2026-07-28',
          gentle,
          9,
          16,
          energy,
          11,
          18,
        ),
        'From 1 to 28 July you chose Gentler Pace most (9 of 16). In the last '
        'four weeks it’s been More Energy (11 of 18).',
      );
      expect(
        InsightCopy.dayRange('2026-09-28', '2026-10-12'),
        '28 September and 12 October',
      );
      expect(
        InsightCopy.dayRange('2026-12-28', '2027-01-03'),
        '28 December 2026 and 3 January 2027',
      );
    });
  });
}
