import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/stage_brief.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_stage_provenance.dart';

/// ADR-024 B3 — the Circle Plan domain, pure: the catalogue, the user's
/// actions, guided progression, set aside / wait, revisits, stage 5 and
/// what is kept.
void main() {
  final today = DateTime(2026, 10, 12, 9);
  const day = '2026-10-12';
  const energy = Intention.moreEnergy;
  const gentle = Intention.gentlerPace;

  /// [plans]' [planId] moved through stages up to [through], each guided by
  /// Circle `c<n>`.
  CirclePlansState guided(
    CirclePlansState plans,
    String planId, {
    required int through,
  }) {
    var state = plans;
    for (var n = state.plans[planId]!.current.cursor; n <= through; n++) {
      state = state.recordGuided(
        PlanStageProvenance(
          planId: planId,
          cycleId: state.plans[planId]!.current.id,
          stageNumber: n,
          stageId: '$planId.$n',
        ),
        circleId: 'c$n',
        today: day,
        parts: const ['getItOut:6'],
        skipped: const [],
      );
    }
    return state;
  }

  CirclePlansState started(String planId) =>
      CirclePlansState.empty.start(planId, today: day)!;

  PlanDay planDay(
    CirclePlansState plans,
    Intention need,
    TimeWindow window, {
    List<PastCircle> history = const [],
    StageAnswers answers = const {},
    Set<ElementId> leftOut = const {},
    SuggestionControls controls = SuggestionControls.none,
    bool premium = true,
  }) => planToday(
    plans,
    premium: premium,
    context: ComposerContext(date: today, need: need, window: window),
    history: history,
    answers: answers,
    leftOut: leftOut,
    controls: controls,
  );

  group('the catalogue (§4)', () {
    test('exactly three Plans, five stages each, on the B2 briefs', () {
      expect(launchCirclePlans.map((p) => (p.id, p.name, p.need)), [
        ('getting_going', 'Getting going', Intention.moreEnergy),
        ('making_room', 'Making room', Intention.clearerHead),
        ('slowing_down', 'Slowing down', Intention.gentlerPace),
      ]);
      expect(circlePlanById['getting_going']!.stages.map((s) => s.name), [
        'Loosen up',
        'On your feet',
        'Two together',
        'Fresh air',
        'Your mix',
      ]);
      expect(circlePlanById['making_room']!.stages.map((s) => s.name), [
        'Out of your head',
        'Room around you',
        'Down to one',
        'Less coming in',
        'Your way',
      ]);
      expect(circlePlanById['slowing_down']!.stages.map((s) => s.name), [
        'Slow hands',
        'Ease the body',
        'Something quiet',
        'Somewhere slower',
        'Your pace',
      ]);
      for (final plan in launchCirclePlans) {
        expect(plan.stages.map((s) => s.number), [1, 2, 3, 4, 5]);
        for (var n = 1; n <= 4; n++) {
          // The B2 brief itself — never a copy.
          expect(
            identical(plan.briefFor(n), stageBriefById['${plan.id}.$n']),
            isTrue,
          );
          expect(plan.briefFor(n)!.need, plan.need);
        }
        expect(plan.briefFor(5), isNull);
        expect(stageFiveIds[plan.stage(5).id], plan.need);
        expect(plan.stage(5).role, StageRole.consolidate);
      }
      // V2 ids never collide with V1's retired Plans.
      expect(
        circlePlanById.keys,
        isNot(anyOf(contains('moreEnergyPath'), contains('clearerHeadPath'))),
      );
    });
  });

  group('the user\'s actions (§6)', () {
    test('1. start: stage 1 of a new cycle; nothing composed or recorded', () {
      final s = started('getting_going');
      final plan = s.plans['getting_going']!;
      expect(s.activePlanId, 'getting_going');
      expect(plan.lifecycle, PlanLifecycle.active);
      expect(plan.cycles.single.cursor, 1);
      expect(plan.cycles.single.id, 'getting_going#1');
      expect(plan.cycles.single.records, isEmpty);
      expect(s.start('getting_going', today: day), isNull, reason: 'already');
      expect(s.start('no_such_plan', today: day), isNull);
    });

    test('2–3. pause keeps the place exactly; carry on resumes there', () {
      final at3 = guided(started('getting_going'), 'getting_going', through: 2);
      final paused = at3.pause('getting_going')!;
      expect(paused.activePlanId, isNull);
      expect(paused.plans['getting_going']!.lifecycle, PlanLifecycle.paused);
      expect(paused.plans['getting_going']!.current.cursor, 3);
      expect(paused.pause('getting_going'), isNull);
      // Paused: no steering, no progression.
      expect(planDay(paused, energy, TimeWindow.about20).circle, isNull);
      final resumed = paused.resume('getting_going')!;
      expect(resumed.activePlanId, 'getting_going');
      expect(resumed.plans['getting_going']!.current.cursor, 3);
      expect(
        resumed.plans['getting_going']!.current.toJson(),
        at3.plans['getting_going']!.current.toJson(),
      );
      // Starting a paused Plan is carrying on.
      expect(
        paused.start('getting_going', today: day)!.toJson(),
        resumed.toJson(),
      );
    });

    test('4. starting another Plan pauses the active one at its place', () {
      final at2 = guided(started('getting_going'), 'getting_going', through: 1);
      final both = at2.start('making_room', today: day)!;
      expect(both.activePlanId, 'making_room');
      expect(both.plans['getting_going']!.lifecycle, PlanLifecycle.paused);
      expect(both.plans['getting_going']!.current.cursor, 2);
      expect(
        both.plans.values.where((p) => p.lifecycle == PlanLifecycle.active),
        hasLength(1),
      );
      final back = both.resume('getting_going')!;
      expect(back.plans['making_room']!.lifecycle, PlanLifecycle.paused);
      expect(back.plans['getting_going']!.current.cursor, 2);
    });

    test('5. leave ends the cycle, keeps every record; a review only with '
        'three stages guided', () {
      final two = guided(started('slowing_down'), 'slowing_down', through: 2);
      final left = two.leave('slowing_down', today: day)!;
      final plan = left.plans['slowing_down']!;
      expect(left.activePlanId, isNull);
      expect(plan.lifecycle, PlanLifecycle.left);
      expect(plan.current.end, CycleEnd.left);
      expect(plan.current.records, hasLength(2));
      expect(plan.current.hasReview, isFalse);
      final three = guided(started('slowing_down'), 'slowing_down', through: 3);
      expect(
        three
            .leave('slowing_down', today: day)!
            .plans['slowing_down']!
            .current
            .hasReview,
        isTrue,
      );
      expect(CirclePlansState.empty.leave('slowing_down', today: day), isNull);
    });

    test('6. starting again after leaving: a new cycle at stage 1, the old '
        'one kept', () {
      final left = guided(
        started('making_room'),
        'making_room',
        through: 2,
      ).leave('making_room', today: day)!;
      final again = left.start('making_room', today: day)!;
      final plan = again.plans['making_room']!;
      expect(plan.cycles.map((c) => c.id), ['making_room#1', 'making_room#2']);
      expect(plan.current.cursor, 1);
      expect(plan.cycles.first.records, hasLength(2));
      expect(plan.cycles.first.end, CycleEnd.left);
    });

    test('7. the end, then "Go through it again": a new cycle at stage 1', () {
      final ended = guided(
        started('getting_going'),
        'getting_going',
        through: 5,
      );
      final plan = ended.plans['getting_going']!;
      expect(plan.lifecycle, PlanLifecycle.ended);
      expect(plan.current.end, CycleEnd.reachedEnd);
      expect(plan.current.hasReview, isTrue);
      expect(ended.activePlanId, isNull, reason: 'steering stops at the end');
      expect(planDay(ended, energy, TimeWindow.about20).circle, isNull);
      final again = ended.goThroughAgain('getting_going', today: day)!;
      expect(again.plans['getting_going']!.cycles, hasLength(2));
      expect(again.plans['getting_going']!.current.cursor, 1);
      expect(again.plans['getting_going']!.cycles.first.records, hasLength(5));
      expect(
        started('getting_going').goThroughAgain('getting_going', today: day),
        isNull,
      );
    });
  });

  group('guided, once (§6 GUIDED)', () {
    final provenance = PlanStageProvenance(
      planId: 'getting_going',
      cycleId: 'getting_going#1',
      stageNumber: 1,
      stageId: 'getting_going.1',
    );
    CirclePlansState guide(CirclePlansState s, String circleId) =>
        s.recordGuided(
          provenance,
          circleId: circleId,
          today: day,
          parts: const ['standingStretch:5'],
          skipped: const [],
        );

    test('18. the same Circle never moves the place twice', () {
      final once = guide(started('getting_going'), '2026-10-12');
      expect(once.plans['getting_going']!.current.cursor, 2);
      final twice = guide(once, '2026-10-12');
      expect(identical(twice, once), isTrue);
      expect(twice.plans['getting_going']!.current.records, hasLength(1));
    });

    test('a stale stage, a paused or left Plan, another cycle: nothing '
        'moves', () {
      final s = started('getting_going');
      final moved = guide(s, 'a');
      // Stage 1 again (not a revisit) is stale once the place is 2.
      expect(identical(guide(moved, 'b'), moved), isTrue);
      final paused = s.pause('getting_going')!;
      expect(identical(guide(paused, 'a'), paused), isTrue);
      final left = s.leave('getting_going', today: day)!;
      expect(identical(guide(left, 'a'), left), isTrue);
      final other = left.start('getting_going', today: day)!;
      expect(identical(guide(other, 'a'), other), isTrue, reason: 'cycle #2');
    });

    test('a guided record is facts only — never "completed"', () {
      final record = guide(
        started('getting_going'),
        'c1',
      ).plans['getting_going']!.current.records.single;
      expect(record.outcome, StageOutcome.guided);
      expect(record.toJson().keys, isNot(contains('completed')));
      expect(StageOutcome.values.map((o) => o.name), ['guided', 'setAside']);
      expect(
        record.toJson().toString(),
        isNot(matches(RegExp('complet|success|improv|fail'))),
      );
    });
  });

  group('Today (§6)', () {
    test('8. a matching need composes the stage; 9. another need and Free '
        'change nothing', () {
      final s = started('slowing_down');
      final match = planDay(s, gentle, TimeWindow.about20);
      expect(match.stage!.stageNumber, 1);
      expect(match.stage!.stageId, 'slowing_down.1');
      expect(match.stage!.cycleId, 'slowing_down#1');
      expect(
        stageBriefById['slowing_down.1']!.accepts(
          match.circle!.plan.parts,
          size: 20,
        ),
        isTrue,
      );
      final other = planDay(s, energy, TimeWindow.about20);
      expect(other.circle, isNull);
      expect(identical(other.state, s), isTrue);
      final free = planDay(s, gentle, TimeWindow.about20, premium: false);
      expect(free.circle, isNull);
      expect(identical(free.state, s), isTrue);
    });

    test('10. wait: the place stays, nothing is recorded', () {
      final s = started('slowing_down');
      final tend = planDay(s, gentle, TimeWindow.about10).circle!.plan;
      expect(tend.main.element, ElementId.tendOne);
      final yesterday = PastCircle(
        date: today.subtract(const Duration(days: 1)),
        need: gentle,
        activityId: tend.main.definition.art,
        catalogVersion: catalogVersion,
        components: tend.activities,
        parts: tend.toWire(),
      );
      final waits = planDay(
        s,
        gentle,
        TimeWindow.about10,
        history: [yesterday],
      );
      expect(waits.circle, isNull);
      expect(waits.state.plans['slowing_down']!.current.cursor, 1);
      expect(waits.state.plans['slowing_down']!.current.records, isEmpty);
    });

    test('11. set aside: recorded with its reason, and the next stage is '
        'tried the same day', () {
      final at4 = guided(started('getting_going'), 'getting_going', through: 3);
      final day4 = planDay(
        at4,
        energy,
        TimeWindow.about10,
        leftOut: {ElementId.daylight},
      );
      final cycle = day4.state.plans['getting_going']!.current;
      final aside = cycle.latest(4)!;
      expect(aside.outcome, StageOutcome.setAside);
      expect(aside.setAsideBecause.map((b) => (b.element, b.reason)), [
        (ElementId.daylight, StageBlockReason.leftOut),
      ]);
      expect(aside.circleId, isNull);
      expect(cycle.cursor, 5);
      expect(day4.stage!.stageNumber, 5, reason: 'tried the same day');
      expect(day4.stage!.drawsOn, isNot(contains('getting_going.4')));
    });

    test('12. every remaining stage set aside: the cycle ends, today is '
        'the ordinary Circle', () {
      // Stages 1–3 set aside on earlier days, stage 4 today.
      var s = started('getting_going');
      final p = s.plans['getting_going']!;
      s = CirclePlansState(
        activePlanId: 'getting_going',
        plans: {
          'getting_going': p.withCurrent(
            p.current.copyWith(
              cursor: 4,
              records: [
                for (var n = 1; n <= 3; n++)
                  StageRecord(
                    stageNumber: n,
                    outcome: StageOutcome.setAside,
                    localDate: day,
                  ),
              ],
            ),
          ),
        },
      );
      final result = planDay(
        s,
        energy,
        TimeWindow.about10,
        leftOut: {ElementId.daylight},
      );
      expect(result.circle, isNull);
      final plan = result.state.plans['getting_going']!;
      expect(plan.lifecycle, PlanLifecycle.ended);
      expect(plan.current.end, CycleEnd.allSetAside);
      expect(result.state.activePlanId, isNull);
      expect(plan.current.guidedStages, 0);
      expect(plan.current.setAsideStages, 4);
    });

    test('the loop is bounded and never re-tries a stage', () {
      // Everything the user can block, blocked: each stage is set aside
      // once, then the cycle ends — five stages at most.
      final s = started('making_room');
      final result = planDay(
        s,
        Intention.clearerHead,
        TimeWindow.about10,
        leftOut: {
          for (final id in ElementId.values)
            if (elementOf(id).fits(Intention.clearerHead)) id,
        },
      );
      expect(result.circle, isNull);
      final cycle = result.state.plans['making_room']!.current;
      expect(cycle.records.map((r) => r.stageNumber), [1, 2, 3, 4]);
      expect(cycle.end, CycleEnd.allSetAside);
    });
  });

  group('revisit (§6)', () {
    test('32–34. once per stage, served without moving the place', () {
      final at3 = guided(started('getting_going'), 'getting_going', through: 2);
      final asked = at3.requestRevisit('getting_going', 1)!;
      expect(asked.plans['getting_going']!.current.pendingRevisit, 1);
      expect(
        asked.requestRevisit('getting_going', 2),
        isNull,
        reason: 'one pending at a time',
      );
      expect(
        at3.requestRevisit('getting_going', 3),
        isNull,
        reason: 'not reached yet',
      );
      final served = planDay(asked, energy, TimeWindow.about20);
      expect(served.stage!.stageNumber, 1);
      expect(served.stage!.revisit, isTrue);
      final after = served.state.recordGuided(
        served.stage!,
        circleId: 'revisit-1',
        today: day,
        parts: served.circle!.plan.toWire(),
        skipped: const [],
      );
      final cycle = after.plans['getting_going']!.current;
      expect(cycle.cursor, 3, reason: 'the place never moved');
      expect(cycle.pendingRevisit, isNull);
      expect(cycle.records.last.revisit, isTrue);
      // 34: never a second revisit of stage 1 this cycle.
      expect(after.requestRevisit('getting_going', 1), isNull);
      expect(after.requestRevisit('getting_going', 2), isNotNull);
    });

    test('35. a revisit that would be set aside is cleared; the place is '
        'tried instead', () {
      final at5 = guided(started('getting_going'), 'getting_going', through: 4);
      final asked = at5.requestRevisit('getting_going', 4)!;
      final result = planDay(
        asked,
        energy,
        TimeWindow.about10,
        leftOut: {ElementId.daylight},
      );
      final cycle = result.state.plans['getting_going']!.current;
      expect(cycle.pendingRevisit, isNull);
      expect(
        cycle.records.where((r) => r.outcome == StageOutcome.setAside),
        isEmpty,
      );
      expect(result.stage!.stageNumber, 5);
      expect(result.stage!.revisit, isFalse);
    });
  });

  group('stage 5 (§7) from the cycle\'s records', () {
    CirclePlansState atFive() =>
        guided(started('making_room'), 'making_room', through: 4);
    const very = PastUsefulness.veryUseful;
    const not = PastUsefulness.notUseful;

    test('24. A — no answers: a mix of at least two earlier stages', () {
      final five = planDay(atFive(), Intention.clearerHead, TimeWindow.about20);
      expect(five.stage!.stageNumber, 5);
      expect(five.stage!.drawsOn, hasLength(4));
    });

    test('25. B — one positive stage leads', () {
      final five = planDay(
        atFive(),
        Intention.clearerHead,
        TimeWindow.about20,
        answers: {'c2': very, 'c3': not},
      );
      expect(five.stage!.drawsOn.first, 'making_room.2');
      expect(five.stage!.drawsOn, isNot(contains('making_room.3')));
    });

    test('26. C — two positive stages together', () {
      final five = planDay(
        atFive(),
        Intention.clearerHead,
        TimeWindow.about20,
        answers: {'c1': very, 'c4': PastUsefulness.somewhatUseful},
      );
      expect(five.stage!.drawsOn.toSet(), {'making_room.1', 'making_room.4'});
    });

    test('27. D — every stage "Not useful": no last Circle, the cycle ends '
        'at its review', () {
      final five = planDay(
        atFive(),
        Intention.clearerHead,
        TimeWindow.about20,
        answers: {for (var n = 1; n <= 4; n++) 'c$n': not},
      );
      expect(five.circle, isNull);
      final plan = five.state.plans['making_room']!;
      expect(plan.current.end, CycleEnd.allRejected);
      expect(plan.lifecycle, PlanLifecycle.ended);
      expect(plan.current.hasReview, isTrue);
    });

    test('22–23. set-aside and rejected stages are never drawn on', () {
      final s = atFive();
      final p = s.plans['making_room']!;
      final withAside = CirclePlansState(
        activePlanId: 'making_room',
        plans: {
          'making_room': p.withCurrent(
            p.current.copyWith(
              records: [
                for (final r in p.current.records)
                  r.stageNumber == 2
                      ? StageRecord(
                          stageNumber: 2,
                          outcome: StageOutcome.setAside,
                          localDate: day,
                        )
                      : r,
              ],
            ),
          ),
        },
      );
      final inputs = earlierStages(
        circlePlanById['making_room']!,
        withAside.plans['making_room']!.current,
        {'c3': not},
      );
      expect(inputs.map((e) => (e.stageId, e.setAside, e.answer)), [
        ('making_room.1', false, null),
        ('making_room.2', true, null),
        ('making_room.3', false, not),
        ('making_room.4', false, null),
      ]);
      final five = planDay(
        withAside,
        Intention.clearerHead,
        TimeWindow.about20,
        answers: {'c3': not},
      );
      expect(five.stage!.drawsOn, ['making_room.1', 'making_room.4']);
    });
  });

  group('what is kept', () {
    test('41. the whole state round-trips', () {
      var s = guided(started('getting_going'), 'getting_going', through: 3);
      s = planDay(
        s,
        energy,
        TimeWindow.about10,
        leftOut: {ElementId.daylight},
      ).state;
      s = s.start('making_room', today: day)!;
      s = s.requestRevisit('getting_going', 2)!;
      final back = CirclePlansState.fromJson(s.toJson())!;
      expect(back.toJson(), s.toJson());
      expect(back.activePlanId, 'making_room');
      expect(
        back.plans['getting_going']!.current
            .latest(4)!
            .setAsideBecause
            .single
            .reason,
        StageBlockReason.leftOut,
      );
    });

    test('unreadable or unknown records are refused, never guessed', () {
      expect(CirclePlansState.fromJson(null), isNull);
      expect(
        CirclePlansState.fromJson({'schemaVersion': 99, 'plans': {}}),
        isNull,
      );
      final s = CirclePlansState.fromJson({
        'schemaVersion': circlePlansSchemaVersion,
        'activePlanId': 'moreEnergyPath',
        'plans': {
          'moreEnergyPath': {'lifecycle': 'active', 'cycles': []},
          'clearTheDecks': {'lifecycle': 'active', 'cycles': []},
        },
      })!;
      expect(s.plans, isEmpty, reason: 'V1 Plans and Phase D Paths never');
      expect(s.activePlanId, isNull);
    });

    test('45. Delete history: the stage evidence goes; each place stays', () {
      final s = guided(
        started('getting_going'),
        'getting_going',
        through: 2,
      ).requestRevisit('getting_going', 1)!;
      final forgotten = s.forgetStageEvidence();
      final cycle = forgotten.plans['getting_going']!.current;
      expect(cycle.records, isEmpty);
      expect(cycle.cursor, 3);
      expect(cycle.pendingRevisit, 1);
      expect(forgotten.activePlanId, 'getting_going');
      // Stage 5 then treats every earlier stage as unanswered.
      expect(
        earlierStages(
          circlePlanById['getting_going']!,
          cycle,
          const {},
        ).every((e) => !e.setAside && e.answer == null),
        isTrue,
      );
    });
  });

  group('B3 closure — Delete history leaves a coherent Plan', () {
    test('case 1: active at stage 3 — the place stays, nothing is '
        'reconstructed, the next matching day carries on at stage 3', () {
      final at3 = guided(started('slowing_down'), 'slowing_down', through: 2);
      final forgotten = at3.forgetStageEvidence();
      final plan = forgotten.plans['slowing_down']!;
      expect(forgotten.activePlanId, 'slowing_down');
      expect(plan.lifecycle, PlanLifecycle.active);
      expect(plan.current.id, 'slowing_down#1');
      expect(plan.current.cursor, 3);
      expect(plan.current.records, isEmpty);
      expect(plan.lastAdvancedCircleId, isNull);
      expect(jsonEncode(forgotten.toJson()), isNot(contains('c1')));
      expect(jsonEncode(forgotten.toJson()), isNot(contains('c2')));
      final next = planDay(forgotten, gentle, TimeWindow.about20);
      expect(next.stage!.stageNumber, 3);
      expect(next.state.plans['slowing_down']!.current.records, isEmpty);
    });

    test('case 2: stage 5 after the evidence was deleted — every earlier '
        'stage unanswered, the zero-answer mix, nothing personal claimed', () {
      final at5 = guided(
        started('making_room'),
        'making_room',
        through: 4,
      ).forgetStageEvidence();
      final cycle = at5.plans['making_room']!.current;
      // Even answers still sitting in an (undeleted) map can't attach:
      // there is no record left to attach them to.
      final inputs = earlierStages(circlePlanById['making_room']!, cycle, {
        'c1': PastUsefulness.veryUseful,
      });
      expect(inputs.every((e) => !e.setAside && e.answer == null), isTrue);
      final five = stageFive('making_room.5', inputs, today) as StageFiveBriefs;
      expect(five.basis, StageFiveBasis.noAnswers);
      final day = planDay(at5, Intention.clearerHead, TimeWindow.about20);
      expect(day.stage!.stageNumber, 5);
      expect(day.stage!.drawsOn, hasLength(4));
    });

    test('case 3: ended and left cycles keep no review and no claim '
        'about evidence that is gone', () {
      const not = PastUsefulness.notUseful;
      // Cycle 1 ended at case D ("You said none of these stages was useful").
      var s = guided(started('making_room'), 'making_room', through: 4);
      s = planDay(
        s,
        Intention.clearerHead,
        TimeWindow.about20,
        answers: {for (var n = 1; n <= 4; n++) 'c$n': not},
      ).state;
      expect(s.plans['making_room']!.current.end, CycleEnd.allRejected);
      // Cycle 2 left after three guided stages: review-ready.
      s = s.goThroughAgain('making_room', today: day)!;
      s = guided(
        s,
        'making_room',
        through: 3,
      ).leave('making_room', today: day)!;
      final before = s.plans['making_room']!.cycles;
      expect(before.map((c) => c.hasReview), [true, true]);

      final forgotten = s.forgetStageEvidence();
      final cycles = forgotten.plans['making_room']!.cycles;
      expect(cycles.map((c) => c.id), ['making_room#1', 'making_room#2']);
      expect(cycles.map((c) => c.end), [
        CycleEnd.historyDeleted,
        CycleEnd.left,
      ]);
      expect(cycles.map((c) => c.hasReview), [false, false]);
      expect(cycles.map((c) => c.records), [isEmpty, isEmpty]);
      expect(
        cycles.first.endedOn,
        isNull,
        reason: 'when it ended was evidence',
      );
      expect(cycles.last.endedOn, day, reason: 'leaving was the user\'s act');
      expect(forgotten.plans['making_room']!.lifecycle, PlanLifecycle.left);
      final json = jsonEncode(forgotten.toJson());
      expect(json, isNot(contains('allRejected')));
      expect(json, isNot(contains('circleId')), reason: 'no Circle survives');
      expect(json, isNot(contains('lastAdvancedCircleId')));
      for (final c in cycles) {
        expect(
          cycleFacts(
            circlePlanById['making_room']!,
            c,
            const {},
          ).every((f) => f.record == null && f.answer == null),
          isTrue,
        );
      }
      // And it reads back the same.
      expect(
        CirclePlansState.fromJson(forgotten.toJson())!.toJson(),
        forgotten.toJson(),
      );
    });
  });

  group('B3 closure — review eligibility after leaving (§6)', () {
    test('only guided stages count: never set aside, waiting, shown or '
        'started-not-closed, and a revisit is still one stage', () {
      // Two guided, then stages 3 and 4 set aside.
      var s = guided(started('getting_going'), 'getting_going', through: 2);
      final p = s.plans['getting_going']!;
      s = CirclePlansState(
        activePlanId: 'getting_going',
        plans: {
          'getting_going': p.withCurrent(
            p.current.copyWith(
              cursor: 5,
              records: [
                ...p.current.records,
                for (final n in [3, 4])
                  StageRecord(
                    stageNumber: n,
                    outcome: StageOutcome.setAside,
                    localDate: day,
                  ),
              ],
            ),
          ),
        },
      );
      // Stage 1 revisited and guided again: still two stages.
      s = s.requestRevisit('getting_going', 1)!;
      s = s.recordGuided(
        PlanStageProvenance(
          planId: 'getting_going',
          cycleId: 'getting_going#1',
          stageNumber: 1,
          stageId: 'getting_going.1',
          revisit: true,
        ),
        circleId: 'revisit-1',
        today: day,
        parts: const [],
        skipped: const [],
      );
      // A wait records nothing; neither does a Circle only shown, or
      // started and never closed (no recordGuided call is ever made).
      final waited = planDay(s, energy, TimeWindow.about20).state;
      final cycle = waited
          .leave('getting_going', today: day)!
          .plans['getting_going']!
          .current;
      expect(cycle.guidedStages, 2);
      expect(cycle.setAsideStages, 2);
      expect(cycle.hasReview, isFalse);

      final three = guided(
        started('getting_going'),
        'getting_going',
        through: 3,
      ).leave('getting_going', today: day)!.plans['getting_going']!.current;
      expect(three.guidedStages, 3);
      expect(three.hasReview, isTrue);
    });
  });
}
