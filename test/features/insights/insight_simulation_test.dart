import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/insights/domain/insight_engine.dart';
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_stage_provenance.dart';

/// ADR-024 B5 — a bounded, deterministic 12-month structural simulation of
/// Insights on the real evaluator and Plan domain, with real gate-passing
/// parts. Seven profiles: a user who never answers, a moderate answerer, a
/// frequent skipper, an active Plan user, a user who lapses and returns,
/// one dominant need, and needs that change over the months.
///
/// It proves structure only — gates, cadence, the cap, wording, lapse —
/// never retention or market value. The trace is written to
/// `build/insight_simulations/`.
void main() {
  final start = DateTime(2026, 1, 5, 9);
  const energy = Intention.moreEnergy;
  const head = Intention.clearerHead;
  const gentle = Intention.gentlerPace;

  /// Real gate-passing Circles for each need at ≈20 — a deterministic
  /// spread of different main pieces.
  final palette = {
    for (final need in Intention.values)
      need: () {
        final allowed = [
          for (final e in elementLibrary.values)
            if (isElementOfferable(e) && e.fits(need)) e,
        ];
        final shapes = gatePassingShapes(allowed, window: 20).toList();
        final byMain = <ElementId, List<CirclePart>>{};
        for (final s in shapes) {
          byMain.putIfAbsent(CirclePlan(s).main.element, () => s);
        }
        return byMain.values.toList();
      }(),
  };

  final forbidden = RegExp(
    r'\b(because|caused?|improv\w*|boost\w*|anxiety|mood|focused|calmer|'
    r'healthier|works for you|helps|tired|recovering|stress|completed|'
    r'progress|streak)\b',
    caseSensitive: false,
  );

  final results = <String, Map<String, Object?>>{};

  void simulate(
    String name, {
    required Intention Function(int day) need,
    bool Function(int day) records = _always,
    PastUsefulness? Function(int day, List<CirclePart> parts)? answer,
    bool Function(int day, List<CirclePart> parts)? skipsFirst,
    String? plan,
    bool Function(int day)? tooMuch,
    bool Function(int day) premium = _always,
    int opensEvery = 3,
    bool notNow = false,
    bool applies = true,
    Map<String, Object?> Function(_Run run)? checks,
  }) {
    test('$name — 12 months, structurally sound', () {
      final run = _Run();
      var plans = CirclePlansState.empty;
      if (plan != null) {
        plans = plans.start(plan, today: _key(start))!;
      }
      final circles = <InsightCircle>[];
      var snapshots = <InsightSnapshot>[];
      final leftOut = <ElementId>{};
      final kept = <String>{};
      for (var day = 0; day < 365; day++) {
        final date = start.add(Duration(days: day));
        final today = _key(date);
        final paid = premium(day);
        if (records(day)) {
          final n = need(day);
          final choices = palette[n]!;
          var parts = choices[(day * 7 + n.index) % choices.length];
          parts = [
            for (final p in parts)
              if (!leftOut.contains(p.element)) p,
          ];
          if (parts.isEmpty ||
              !parts.any(
                (p) => p.definition.roles.contains(ElementRole.main),
              )) {
            parts = choices.first;
          }
          final active = plans.active;
          PlanStageProvenance? stage;
          if (paid && active != null && active.definition.need == n) {
            final cycle = active.current;
            stage = PlanStageProvenance(
              planId: active.planId,
              cycleId: cycle.id,
              stageNumber: cycle.cursor,
              stageId: active.definition.stage(cycle.cursor).id,
              gentler: cycle.isGentler,
            );
          }
          final asked = stage != null && (tooMuch?.call(day) ?? false);
          final skipped = (skipsFirst?.call(day, parts) ?? false)
              ? {parts.first.element}
              : const <ElementId>{};
          final circle = InsightCircle(
            circleId: today,
            localDate: today,
            need: n,
            parts: parts,
            skipped: skipped,
            answer: answer?.call(day, parts),
            stage: stage,
            replacedFromStage: asked ? stage : null,
            replacementReason: asked ? 'tooMuch' : null,
          );
          circles.add(circle);
          if (stage != null) {
            plans = plans.recordGuided(
              stage,
              circleId: today,
              today: today,
              parts: [for (final p in parts) p.wire],
              skipped: [for (final e in skipped) e.name],
            );
            // A cycle that ended: the Plan user goes through it again.
            if (plans.active == null && plan != null) {
              plans =
                  plans.goThroughAgain(plan, today: today) ??
                  plans.start(plan, today: today) ??
                  plans;
            }
          }
        }
        if (!paid) {
          // Readable, never generated.
          final read = assessInsights(
            _inputs(date, circles, plans, leftOut, kept),
            snapshots,
            generate: false,
          );
          expect(read.added, isEmpty);
          if (snapshots.isNotEmpty) run.lapsedReadable++;
          continue;
        }
        if (day % opensEvery != 0) continue;
        final i = _inputs(date, circles, plans, leftOut, kept);
        final result = assessInsights(i, snapshots, generate: true);
        snapshots = result.snapshots;
        for (final s in result.added) {
          run.generated.add((day, s));
          expect(forbidden.hasMatch(s.text), isFalse, reason: s.text);
          if (s.family.isOrdinary) {
            // Never a pattern before the Circles span two weeks.
            final dates = [for (final c in circles) c.localDate]..sort();
            expect(
              daysBetween(dates.first, dates.last) + 1,
              greaterThanOrEqualTo(14),
              reason: '${s.family.id} on day $day',
            );
          }
          // The user's choice, explicitly.
          InsightSnapshot? acted;
          if (notNow && s.family.isOrdinary) {
            acted = s.copyWith(notNowOn: today);
          } else if (applies) {
            switch (s.application) {
              case PlanDirection(:final planId, :final step):
                final next = switch (step) {
                  PlanStep.start => plans.start(planId, today: today),
                  PlanStep.carryOn => plans.resume(planId),
                  PlanStep.goThroughAgain => plans.goThroughAgain(
                    planId,
                    today: today,
                  ),
                };
                if (next != null) {
                  plans = next;
                  acted = s.copyWith(appliedOn: today);
                }
              case KeepGentler(:final planId):
                final next = plans.keepGentler(planId, today: today);
                if (next != null) {
                  plans = next;
                  acted = s.copyWith(appliedOn: today);
                }
              case LeaveOutPart(:final element):
                leftOut.add(ElementId.values.byName(element));
                acted = s.copyWith(appliedOn: today);
              case KeepCircleFromHistory(:final circleId):
                if (kept.length < 8 && kept.add(circleId)) {
                  acted = s.copyWith(appliedOn: today);
                }
              case OpenPlanReview() || NothingToChange():
                break;
            }
          }
          if (acted?.appliedOn != null) run.applied.add((day, acted!));
          if (acted != null) {
            snapshots = [
              for (final x in snapshots) x.id == acted.id ? acted : x,
            ];
          }
        }
        expect(snapshots.length, lessThanOrEqualTo(maxInsightSnapshots));
        // One observation is never shown twice at once.
        final current = [
          for (final s in snapshots)
            if (statusOf(s, i) == InsightStatus.current) s.subject,
        ];
        expect(current.toSet().length, current.length);
        run.maxStored = run.maxStored < snapshots.length
            ? snapshots.length
            : run.maxStored;
      }
      // At most one new ordinary Insight per 7 days.
      final ordinary = [
        for (final (day, s) in run.generated)
          if (s.family.isOrdinary) day,
      ];
      for (var k = 1; k < ordinary.length; k++) {
        expect(ordinary[k] - ordinary[k - 1], greaterThanOrEqualTo(7));
      }
      // The same claim — family and subject — at most once in 28 days.
      final lastShown = <String, int>{};
      for (final (day, s) in run.generated) {
        if (!s.family.isOrdinary) continue;
        final before = lastShown[s.subject];
        if (before != null) {
          expect(day - before, greaterThanOrEqualTo(28), reason: s.subject);
        }
        lastShown[s.subject] = day;
      }
      run.finalStored = snapshots.length;
      final report = {
        for (final (label, last) in [
          ('month 1', 29),
          ('month 3', 89),
          ('month 6', 179),
          ('month 12', 364),
        ])
          label: run.summary(last),
        'max stored': run.maxStored,
        'stored at day 365': run.finalStored,
        'most repeats of one I1 claim': run.mostRepeats(
          InsightFamily.planForNeed,
        ),
        'most repeats of one I2 claim': run.mostRepeats(
          InsightFamily.planPacing,
        ),
        'weeks with no new ordinary Insight': run.silentWeeks(),
        'days a lapsed user could read snapshots': run.lapsedReadable,
        ...?checks?.call(run),
      };
      results[name] = report;
    });
  }

  simulate(
    'no-answer user',
    need: (d) => d % 5 < 3 ? head : gentle,
    records: (d) => d % 7 != 6,
  );

  simulate(
    'moderate answerer',
    need: (d) => d % 4 == 0 ? energy : head,
    // Answers on 3 days in 5 — "useful" when writing led the Circle.
    answer: (d, parts) => d % 5 >= 3
        ? null
        : CirclePlan(parts).main.definition.kind == ElementKind.writing
        ? (d % 4 == 0
              ? PastUsefulness.veryUseful
              : PastUsefulness.somewhatUseful)
        : (d % 3 == 0 ? PastUsefulness.notUseful : null),
    checks: (run) {
      expect(run.firstDay(InsightFamily.usefulInCommon), lessThan(180));
      return {};
    },
  );

  simulate(
    'frequent skipper',
    need: (d) => d % 3 == 0 ? gentle : head,
    skipsFirst: (d, parts) => d % 4 != 0,
    checks: (run) {
      // Within the first two months: an earlier Insight may hold the
      // weekly slot first.
      expect(run.firstDay(InsightFamily.skippedPart), lessThan(60));
      return {};
    },
  );

  simulate(
    'active Plan user',
    need: (d) => d % 3 == 2 ? head : energy,
    plan: 'getting_going',
    tooMuch: (d) => d % 4 == 1,
    checks: (run) {
      // A genuine review may appear in month 1.
      expect(run.firstDay(InsightFamily.planReview), lessThan(30));
      // Cross-cycle reviews by month 6.
      final cycles = [
        for (final (day, s) in run.generated)
          if (s.family == InsightFamily.planReview && day < 180)
            s.facts['cycle'] as int,
      ];
      expect(cycles.any((c) => c >= 2), isTrue);
      expect(run.firstDay(InsightFamily.planPacing), lessThan(180));
      return {
        'cycles reviewed in 12 months': run.count(
          InsightFamily.planReview,
          364,
        ),
      };
    },
  );

  simulate(
    'lapsed user',
    need: (d) => d % 5 < 3 ? energy : gentle,
    answer: (d, _) => d % 3 == 0 ? PastUsefulness.somewhatUseful : null,
    premium: (d) => d < 120 || d >= 240,
    checks: (run) {
      expect(
        [
          for (final (day, _) in run.generated)
            if (day >= 120 && day < 240) day,
        ],
        isEmpty,
        reason: 'nothing new while lapsed',
      );
      expect(run.lapsedReadable, greaterThan(0));
      return {};
    },
  );

  simulate(
    'dominant single need',
    need: (d) => d % 10 == 9 ? energy : head,
    notNow: true,
  );

  // Starts every suggested Plan: I1 comes back after each cycle, but the
  // 28-day repeat rule leaves room for I6.
  simulate(
    'needs change over months',
    need: (d) => d < 90 ? gentle : (d < 180 ? energy : head),
    answer: (d, _) => d % 4 == 0 ? PastUsefulness.veryUseful : null,
    checks: (run) {
      final first = run.firstDay(InsightFamily.whatsChanged);
      expect(first, greaterThanOrEqualTo(84), reason: 'never before month 3');
      expect(first, lessThan(180));
      return {};
    },
  );

  tearDownAll(() {
    final dir = Directory('build/insight_simulations')
      ..createSync(recursive: true);
    File(
      '${dir.path}/b5_insights_12_months.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(results));
  });
}

bool _always(int _) => true;

String _key(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

InsightInputs _inputs(
  DateTime date,
  List<InsightCircle> circles,
  CirclePlansState plans,
  Set<ElementId> leftOut,
  Set<String> kept,
) => InsightInputs(
  today: date,
  circles: circles,
  plans: plans,
  leftOut: {...leftOut},
  keptFromCircles: {...kept},
  keptCount: kept.length,
);

class _Run {
  final generated = <(int, InsightSnapshot)>[];
  final applied = <(int, InsightSnapshot)>[];
  var maxStored = 0;
  var finalStored = 0;
  var lapsedReadable = 0;

  int count(InsightFamily family, int lastDay) =>
      generated.where((g) => g.$1 <= lastDay && g.$2.family == family).length;

  /// The most times one claim of [family] was shown in the year.
  int mostRepeats(InsightFamily family) {
    final counts = <String, int>{};
    for (final (_, s) in generated) {
      if (s.family == family) counts[s.subject] = (counts[s.subject] ?? 0) + 1;
    }
    return counts.values.fold(0, (a, b) => a > b ? a : b);
  }

  /// Of the 52 weeks, those in which nothing new and ordinary was shown —
  /// silence, when nothing else was due.
  int silentWeeks() =>
      52 -
      {
        for (final (day, s) in generated)
          if (s.family.isOrdinary && day < 364) day ~/ 7,
      }.length;

  int firstDay(InsightFamily family) {
    for (final (day, s) in generated) {
      if (s.family == family) return day;
    }
    return 1 << 30;
  }

  Map<String, Object?> summary(int lastDay) => {
    for (final f in InsightFamily.values) f.id: count(f, lastDay),
    'nothing to change': generated
        .where((g) => g.$1 <= lastDay && g.$2.application is NothingToChange)
        .length,
    'generated': generated.where((g) => g.$1 <= lastDay).length,
    'applied by the user': applied.where((g) => g.$1 <= lastDay).length,
  };
}
