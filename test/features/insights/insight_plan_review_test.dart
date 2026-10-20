import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/insights/domain/insight_engine.dart';
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_copy.dart';
import 'package:thirty/features/plans/domain/plan_stage_provenance.dart';
import 'package:thirty/features/plans/presentation/plan_view.dart';

/// ADR-024 B5 — I5, the Plan review, as an Insight: a reference to the cycle
/// B3 keeps and B4 shows — never a second review engine. What it reads is
/// the review's own truth: dates, answers or no answer, set-asides, and
/// from cycle 2 a factual comparison — never improvement or completion.
void main() {
  final today = DateTime(2026, 10, 30, 9);
  const plan = 'making_room';

  PlanStageProvenance stage(int n, int cycle) => PlanStageProvenance(
    planId: plan,
    cycleId: '$plan#$cycle',
    stageNumber: n,
    stageId: '$plan.$n',
  );

  /// One cycle guided through stage 5 by Circles `<cycle>-<n>`.
  CirclePlansState throughCycle(CirclePlansState s, int cycle) {
    for (var n = 1; n <= 5; n++) {
      s = s.recordGuided(
        stage(n, cycle),
        circleId: '$cycle-$n',
        today: '2026-0${cycle + 6}-1$n',
        parts: const ['getItOut:6'],
        skipped: const [],
      );
    }
    return s;
  }

  final one = throughCycle(
    CirclePlansState.empty.start(plan, today: '2026-07-01')!,
    1,
  );

  ReviewView review(CirclePlansState s, StageAnswers answers) {
    final references = planReviews(
      InsightInputs(today: today, circles: const [], plans: s),
    );
    final ref = references.last.application as OpenPlanReview;
    final progress = s.plans[ref.planId]!;
    expect(progress.current.id, ref.cycleId);
    return reviewOf(progress.definition, progress, answers)!;
  }

  final forbidden = RegExp(
    r'\b(improv\w*|progress|completed?|calmer|better|score|streak|'
    r'learned|favourite)\b',
    caseSensitive: false,
  );

  void truthful(ReviewView v) {
    for (final line in [v.endLine, ...v.summary, ...v.compared]) {
      expect(forbidden.hasMatch(line), isFalse, reason: line);
    }
  }

  test('the reference names the cycle, and carries no copy of the review', () {
    final refs = planReviews(
      InsightInputs(today: today, circles: const [], plans: one),
    );
    final r = refs.single;
    expect(r.family, InsightFamily.planReview);
    expect(r.facts.keys.toSet(), {'planId', 'cycleId', 'cycle', 'endedOn'});
    expect(r.text, 'Making room: what you told THIRTY, 15 July.');
  });

  test('no answers: said plainly', () {
    final v = review(one, const {});
    expect(v.summary, [PlanCopy.noAnswers]);
    truthful(v);
  });

  test('one positive answer', () {
    final v = review(one, const {'1-2': PastUsefulness.veryUseful});
    expect(v.summary, [
      PlanCopy.onePositive('Room around you'),
      PlanCopy.othersUnanswered,
    ]);
    truthful(v);
  });

  test('several positive answers', () {
    final v = review(one, const {
      '1-1': PastUsefulness.somewhatUseful,
      '1-3': PastUsefulness.veryUseful,
    });
    expect(v.summary.single, startsWith('You said these stages were useful'));
    truthful(v);
  });

  test('every earlier stage rejected: case D, no last Circle', () {
    var s = CirclePlansState.empty.start(plan, today: '2026-07-01')!;
    for (var n = 1; n <= 4; n++) {
      s = s.recordGuided(
        stage(n, 1),
        circleId: '1-$n',
        today: '2026-07-1$n',
        parts: const ['getItOut:6'],
        skipped: const [],
      );
    }
    final answers = {
      for (var n = 1; n <= 4; n++) '1-$n': PastUsefulness.notUseful,
    };
    final day = planToday(
      s,
      premium: true,
      context: ComposerContext(
        date: today,
        need: Intention.clearerHead,
        window: TimeWindow.about20,
      ),
      history: const [],
      answers: answers,
    );
    final v = review(day.state, answers);
    expect(v.caseD, isTrue);
    truthful(v);
  });

  test('cycle 2: a factual line per stage the user answered both times', () {
    final again = throughCycle(
      one.goThroughAgain(plan, today: '2026-08-01')!,
      2,
    );
    final refs = planReviews(
      InsightInputs(today: today, circles: const [], plans: again),
    );
    expect(refs, hasLength(2), reason: 'each cycle its own dated record');
    final v = review(again, const {
      '1-1': PastUsefulness.somewhatUseful,
      '2-1': PastUsefulness.veryUseful,
      '1-2': PastUsefulness.veryUseful,
      '2-2': PastUsefulness.veryUseful,
      '2-3': PastUsefulness.notUseful,
    });
    expect(v.compared, hasLength(2), reason: 'stage 3 was answered once');
    truthful(v);
  });

  test('never stale while Plans has it; gone with Delete history', () {
    final i = InsightInputs(today: today, circles: const [], plans: one);
    final shown = planReviews(i).single.snapshot('2026-07-15');
    expect(statusOf(shown, i), InsightStatus.current);
    expect(
      statusOf(
        shown,
        InsightInputs(
          today: today.add(const Duration(days: 400)),
          circles: const [],
          plans: one,
        ),
      ),
      InsightStatus.current,
    );
    final deleted = InsightInputs(
      today: today,
      circles: const [],
      plans: one.forgetStageEvidence(),
    );
    expect(statusOf(shown, deleted), InsightStatus.stale);
  });
}
