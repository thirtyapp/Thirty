import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/stage_brief.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';

/// ADR-024 B8 — attacking Circle Plans beyond the named cases B3 and B4
/// test one by one:
///
/// - **Stage 5, exhaustively:** every combination of what the four earlier
///   stages can be (set aside, no answer, Very, Somewhat, Not useful) for
///   each Plan — 625 × 3 — against an independent statement of §7's cases,
///   and composed for real at every time choice.
/// - **Many cycles, adversarially:** forty cycles of each Plan with random
///   answers, leave-outs that set stages aside, revisits and pauses, on the
///   real composer, checking that the place only ever moves as the contract
///   says, Stage 5 only uses this cycle's eligible stages, a cycle always
///   ends the right way, and nothing loops or stalls.
void main() {
  const states = ['aside', 'none', 'very', 'somewhat', 'not'];

  PastUsefulness? answerOf(String s) => switch (s) {
    'very' => PastUsefulness.veryUseful,
    'somewhat' => PastUsefulness.somewhatUseful,
    'not' => PastUsefulness.notUseful,
    _ => null,
  };

  group('Stage 5 — every combination of the earlier stages (§7)', () {
    for (final plan in launchCirclePlans) {
      test('${plan.name}: 625 combinations, the case the answers allow, '
          'drawing only on what may be drawn on, and composed at every '
          'time', () {
        final fiveId = plan.stage(5).id;
        final ids = [for (final s in plan.stages.take(4)) s.id];
        final date = DateTime(2026, 3, 2, 9);
        var composed = 0;
        var notMade = 0;
        final bases = <StageFiveBasis, int>{};
        for (var code = 0; code < 625; code++) {
          final picks = [
            for (var k = 0, c = code; k < 4; k++, c ~/= 5) states[c % 5],
          ];
          final earlier = [
            for (final (k, s) in picks.indexed)
              EarlierStage(ids[k], setAside: s == 'aside', answer: answerOf(s)),
          ];
          final eligible = {
            for (final (k, s) in picks.indexed)
              if (s != 'aside' && s != 'not') ids[k],
          };
          final very = {
            for (final (k, s) in picks.indexed)
              if (s == 'very') ids[k],
          };
          final positive = {
            for (final (k, s) in picks.indexed)
              if (s == 'very' || s == 'somewhat') ids[k],
          };
          final five = stageFive(fiveId, earlier, date);
          final why = '$picks';
          switch (five) {
            case NoStageFive(:final reason):
              notMade++;
              // D: no last Circle only when nothing may be drawn on.
              expect(eligible, isEmpty, reason: why);
              expect(
                reason,
                picks.every((s) => s == 'aside')
                    ? NoStageFiveReason.allSetAside
                    : NoStageFiveReason.allRejected,
                reason: why,
              );
            case StageFiveBriefs(:final basis, :final briefs):
              bases[basis] = (bases[basis] ?? 0) + 1;
              expect(eligible, isNotEmpty, reason: why);
              expect(briefs, isNotEmpty, reason: why);
              for (final b in briefs) {
                // Never a rejected or set-aside stage; never another Plan's.
                expect(eligible.containsAll(b.drawsOn), isTrue, reason: why);
                expect(b.id, fiveId, reason: why);
              }
              switch (positive.length) {
                case 0:
                  // A (and D with some unanswered): a mix of two first.
                  expect(basis, StageFiveBasis.noAnswers, reason: why);
                  // First: a Circle that suits at least two of the
                  // eligible stages (when there are two).
                  if (eligible.length > 1) {
                    expect(briefs.first.drawsOn.toSet(), eligible, reason: why);
                    expect(briefs.length, greaterThan(1), reason: why);
                  }
                  // …falling back to a Circle that suits at least one of
                  // them — all eligible, any one satisfied.
                  expect(briefs.last.drawsOn.toSet(), eligible, reason: why);
                case 1:
                  // B: led by the positive stage, else it alone.
                  expect(basis, StageFiveBasis.onePositive, reason: why);
                  for (final b in briefs) {
                    expect(b.drawsOn.first, positive.single, reason: why);
                  }
                  expect(briefs.last.drawsOn, [positive.single], reason: why);
                default:
                  // C: positive stages only, the most positive pair first.
                  expect(basis, StageFiveBasis.severalPositive, reason: why);
                  for (final b in briefs) {
                    expect(
                      positive.containsAll(b.drawsOn),
                      isTrue,
                      reason: why,
                    );
                  }
                  final first = briefs.first.drawsOn;
                  expect(first, hasLength(2), reason: why);
                  if (very.length >= 2) {
                    expect(very.containsAll(first), isTrue, reason: why);
                  } else if (very.length == 1) {
                    expect(first, contains(very.single), reason: why);
                  }
              }
              // Deterministic: the same day gives the same Stage 5.
              final again = stageFive(fiveId, earlier, date) as StageFiveBriefs;
              expect(
                [for (final b in again.briefs) b.drawsOn.join('+')],
                [for (final b in briefs) b.drawsOn.join('+')],
                reason: why,
              );
              // Composed for real: never a wait in a clean library.
              for (final window in TimeWindow.values) {
                final result = composeStage(
                  ComposerContext(date: date, need: plan.need, window: window),
                  const [],
                  briefs,
                );
                expect(
                  result,
                  isA<StageComposed>(),
                  reason: '$why at ${window.name}',
                );
                composed++;
              }
          }
        }
        // Every case occurs, and D exactly when nothing is eligible.
        expect(bases.keys, containsAll(StageFiveBasis.values));
        expect(notMade, 2 * 2 * 2 * 2); // each stage aside or not useful
        expect(composed, (625 - notMade) * TimeWindow.values.length);
        final out = Directory('build/b8_simulations')
          ..createSync(recursive: true);
        File('${out.path}/stage5_${plan.id}.json').writeAsStringSync(
          jsonEncode({
            'combinations': 625,
            'notMade': notMade,
            'composedAcrossTimes': composed,
            'bases': {for (final e in bases.entries) e.key.name: e.value},
          }),
        );
      });
    }
  });

  group('forty cycles of each Plan, adversarially (§6)', () {
    for (final plan in launchCirclePlans) {
      test('${plan.name}: the place moves only as the contract says; Stage 5 '
          'only uses eligible stages; every cycle ends correctly; nothing '
          'loops or stalls', () {
        final need = plan.need;
        final pool = [
          for (final e in elementLibrary.values)
            if (isElementOfferable(e) && e.fits(need)) e.id,
        ];
        var state = CirclePlansState.empty.start(plan.id, today: '2026-01-01')!;
        final answers = <String, PastUsefulness>{};
        var date = DateTime(2026, 1, 1, 9);
        var cycles = 0;
        var days = 0;
        final ends = <CycleEnd, int>{};
        var revisitsServed = 0;
        String key(DateTime d) =>
            '${d.year}-${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';
        int rnd(int a, int b) =>
            ((a + 3) * 2654435761 ^ (b + 11) * 40503) & 0x7fffffff;

        while (cycles < 40) {
          days++;
          expect(days, lessThan(40 * 40), reason: 'a Plan that never ends');
          date = date.add(const Duration(days: 1));
          final today = key(date);
          final active = state.active!;
          final cycle = active.current;
          final seed = rnd(cycles, days);
          // Phases: random (0–24), every stage "Not useful" (25–29), every
          // live part left out (30–34), half left out and no answers
          // (35–39).
          final phase = switch (cycles) {
            < 25 => 'random',
            < 30 => 'rejected',
            < 35 => 'aside',
            _ => 'mixed',
          };
          // This cycle's leave-outs, which can set stages aside — the user's
          // own controls.
          final leftOut = switch (phase) {
            'aside' => pool.toSet(),
            'mixed' => {
              for (final (k, e) in pool.indexed)
                if (k.isEven) e,
            },
            _ => {
              for (var k = 0; k < rnd(cycles, 1) % 4; k++)
                pool[rnd(cycles, k + 2) % pool.length],
            },
          };
          // Occasionally: a revisit of a guided stage, or a pause and back.
          if (seed % 11 == 0 && cycle.cursor > 1) {
            final asked = state.requestRevisit(
              plan.id,
              1 + seed % (cycle.cursor - 1),
            );
            if (asked != null) state = asked;
          }
          if (seed % 17 == 0) {
            state = state.pause(plan.id)!.resume(plan.id)!;
            expect(state.active!.current.cursor, cycle.cursor);
          }
          final before = state.active!.current;
          final day = planToday(
            state,
            premium: true,
            context: ComposerContext(
              date: date,
              need: need,
              window: TimeWindow.values[seed % 3],
            ),
            history: const [],
            answers: answers,
            leftOut: leftOut,
          );
          state = day.state;
          final now = state.plans[plan.id]!;
          if (day.circle == null) {
            // Not composed: either stages were set aside or the cycle
            // ended — never a silent stall in a clean history.
            final moved =
                now.current.records.length > before.records.length ||
                now.current.isOver ||
                now.current.pendingRevisit != before.pendingRevisit;
            expect(moved, isTrue, reason: 'D$days stalled at ${before.cursor}');
          } else {
            final stage = day.stage!;
            if (stage.revisit) {
              expect(stage.stageNumber, before.pendingRevisit);
            } else {
              // The place, or a later stage when the ones between were set
              // aside today (a revisit that would be set aside is cleared).
              expect(stage.stageNumber, greaterThanOrEqualTo(before.cursor));
              for (var n = before.cursor; n < stage.stageNumber; n++) {
                final r = now.current.latest(n);
                expect(r?.outcome, StageOutcome.setAside, reason: 'stage $n');
                expect(r?.localDate, today, reason: 'stage $n');
              }
            }
            expect(stage.cycleId, now.current.id);
            if (stage.revisit) revisitsServed++;
            if (stage.stageNumber == 5) {
              final earlier = earlierStages(plan, now.current, answers);
              final eligible = {
                for (final e in earlier)
                  if (!e.setAside && e.answer != PastUsefulness.notUseful)
                    e.stageId,
              };
              expect(eligible.containsAll(stage.drawsOn), isTrue);
            }
            // The Circle is closed: the stage is guided — once.
            final circleId = 'c$days';
            final cursorBefore = now.current.cursor;
            state = state.recordGuided(
              stage,
              circleId: circleId,
              today: today,
              parts: [for (final p in day.circle!.plan.parts) p.wire],
              skipped: const [],
            );
            final again = state.recordGuided(
              stage,
              circleId: circleId,
              today: today,
              parts: const [],
              skipped: const [],
            );
            expect(identical(again, state), isTrue, reason: 'moved twice');
            final after = state.plans[plan.id]!.current;
            expect(
              after.cursor,
              stage.revisit || after.isOver ? cursorBefore : cursorBefore + 1,
            );
            // An answer, or none.
            switch (phase == 'rejected'
                ? 2
                : phase == 'mixed'
                ? 4
                : seed % 5) {
              case 0:
                answers[circleId] = PastUsefulness.veryUseful;
              case 1:
                answers[circleId] = PastUsefulness.somewhatUseful;
              case 2:
                answers[circleId] = PastUsefulness.notUseful;
              default:
                break;
            }
          }
          final current = state.plans[plan.id]!;
          expect(current.current.cursor, inInclusiveRange(1, 5));
          expect(current.current.records.length, lessThanOrEqualTo(5 + 5));
          if (current.current.isOver) {
            final end = current.current.end!;
            ends[end] = (ends[end] ?? 0) + 1;
            final earlier = earlierStages(plan, current.current, answers);
            switch (end) {
              case CycleEnd.allRejected:
                expect(
                  earlier.every(
                    (e) => e.setAside || e.answer == PastUsefulness.notUseful,
                  ),
                  isTrue,
                );
                expect(earlier.any((e) => !e.setAside), isTrue);
              case CycleEnd.allSetAside:
                expect(earlier.every((e) => e.setAside), isTrue);
              case _:
                break;
            }
            // "Go through it again": a new cycle at stage 1.
            final number = current.current.number;
            state = state.goThroughAgain(plan.id, today: today)!;
            expect(state.active!.current.number, number + 1);
            expect(state.active!.current.cursor, 1);
            cycles++;
          }
        }
        // The cycles ended in more than one honest way, revisits were
        // served, and every cycle id is distinct.
        expect(ends[CycleEnd.reachedEnd] ?? 0, greaterThan(0));
        expect(ends[CycleEnd.allRejected] ?? 0, greaterThan(0));
        expect(ends[CycleEnd.allSetAside] ?? 0, greaterThan(0));
        expect(revisitsServed, greaterThan(0));
        final progress = state.plans[plan.id]!;
        expect(
          {for (final c in progress.cycles) c.id}.length,
          progress.cycles.length,
        );
        final out = Directory('build/b8_simulations')
          ..createSync(recursive: true);
        File('${out.path}/plan_attack_${plan.id}.json').writeAsStringSync(
          jsonEncode({
            'days': days,
            'cycles': cycles,
            'ends': {for (final e in ends.entries) e.key.name: e.value},
            'revisitsServed': revisitsServed,
          }),
        );
      });
    }
  });
}
