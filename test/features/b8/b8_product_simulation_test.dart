import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/personal_circle/application/guidance_voice.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/composed_session.dart';
import 'package:thirty/features/personal_circle/domain/spoken_cues.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_copy.dart';
import 'package:thirty/features/plans/domain/plan_stage_provenance.dart';
import 'package:thirty/features/plans/presentation/plan_view.dart';

/// ADR-024 B8 — the whole D2 product over twelve months, through the
/// production providers: Today (Engine V2 and the Personal Guided Circle),
/// Plans (steering, stage progression, Stage 5, reviews, repeat cycles),
/// Insights (assessment when opened, applications, "Not now"), kept Circles
/// and the Premium boundary, for five deterministic synthetic users:
///
/// - **A** a non-responder: no usefulness answer, ever;
/// - **B** a mixed answerer: Very / Somewhat / Not useful / none, Too much,
///   Not this one, skips, Plan switching and a revisit;
/// - **C** More Energy every day at ≈10 — the thin-content stress case;
/// - **D** an engaged subscriber who keeps eight Circles, truly lapses for
///   four months, then resubscribes;
/// - **E** (in the report) the twelve-month Insight record of all four.
///
/// **Structure only.** A pass shows the product stays coherent, honest and
/// within its rules over time. It says nothing about willingness to pay,
/// retention, conversion, health benefit or real usefulness. The trace is
/// written to `build/b8_simulations/`.
const _days = int.fromEnvironment('SIM_DAYS', defaultValue: 365);

final _start = DateTime(2026, 1, 5, 9);

const _energy = Intention.moreEnergy;
const _head = Intention.clearerHead;
const _gentle = Intention.gentlerPace;

/// A deterministic, well-spread number for [day] and [salt].
int _h(int day, int salt) =>
    ((day + 1) * 2654435761 ^ (salt + 7) * 40503) & 0x7fffffff;

/// What a user does with an Insight THIRTY shows.
enum InsightChoice { apply, notNow, ignore }

class B8Profile {
  const B8Profile({
    required this.name,
    required this.needOn,
    required this.windowOn,
    this.premiumOn,
    this.uses,
    this.closes,
    this.answerOn,
    this.replaceOn,
    this.skipOn,
    this.plan,
    this.repeats = true,
    this.planScript,
    this.onInsight,
    this.opensInsightsEvery = 4,
    this.keepsOn,
    this.usesKeptWhenLapsed = false,
  });

  final String name;
  final Intention Function(int day) needOn;
  final TimeWindow Function(int day) windowOn;
  final bool Function(int day)? premiumOn;

  /// Whether the user opens THIRTY at all that day.
  final bool Function(int day)? uses;

  /// Whether a started Circle is closed in THIRTY (else: recorded, not
  /// closed).
  final bool Function(int day)? closes;
  final CircleUsefulnessResponse? Function(int day, Recommendation r)? answerOn;
  final ReplacementReason? Function(int day)? replaceOn;

  /// Skip the first part (and whether to leave it out next time).
  final (bool, bool) Function(int day, Recommendation r)? skipOn;

  /// The Plan started on the first Premium day.
  final String? plan;

  /// Goes through an ended Plan again (repeat cycle).
  final bool repeats;
  final void Function(int day, CirclePlansNotifier plans)? planScript;
  final InsightChoice Function(InsightSnapshot s)? onInsight;
  final int opensInsightsEvery;
  final bool Function(int day, Recommendation r, CircleUsefulnessResponse? a)?
  keepsOn;
  final bool usesKeptWhenLapsed;

  bool premium(int day) => premiumOn?.call(day) ?? true;
}

/// One day as it happened.
class B8Day {
  B8Day({
    required this.day,
    required this.premium,
    required this.need,
    required this.window,
    required this.recommendation,
    required this.closed,
    required this.answer,
  });

  final int day;
  final bool premium;
  final Intention need;
  final TimeWindow window;
  final Recommendation recommendation;
  final bool closed;
  final CircleUsefulnessResponse? answer;

  ComposedSession? get composed => recommendation.composed;
  bool get newComposition => composed != null && !composed!.isKept;
}

class B8Run {
  B8Run(this.profile);

  final B8Profile profile;
  late SharedPreferences prefs;
  final days = <B8Day>[];
  final lines = <String>[];
  final failures = <String>[];

  /// Every ordinary Insight and Plan review THIRTY generated, as generated.
  final shown = <InsightSnapshot>[];

  /// Each review seen when a cycle ended: its lines.
  final reviews = <Map<String, Object?>>[];

  /// Stage 5 as served: the basis the answers allowed, and what it drew on.
  final stageFives = <Map<String, Object?>>[];
  final stageDays = <int>[];
  var stalls = 0;
  var lapseSubstitutable = 0;
  var lapseUsedKept = 0;
  var lapseDays = 0;
  var duplicateProgress = 0;

  void fail(String what) => failures.add(what);

  Future<void> _settle() async {
    for (var i = 0; i < 6; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  ProviderContainer _open(
    DateTime morning,
    DateTime Function() clock,
    bool paid,
  ) => ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(morning),
      eventClockProvider.overrideWithValue(clock),
      premiumEntitlementProvider.overrideWithValue(paid),
      safetyPendingAllowedProvider.overrideWithValue(false),
    ],
  );

  Future<void> run() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    var planStarted = false;
    CirclePlansState? beforeLapse;
    var snapshotsBeforeLapse = 0;
    Set<ElementId>? leftOutBeforeLapse;
    var keptBeforeLapse = 0;
    for (var day = 1; day <= _days; day++) {
      if (!(profile.uses?.call(day) ?? true)) continue;
      final morning = _start.add(Duration(days: day - 1));
      var at = morning;
      final paid = profile.premium(day);
      final c = _open(morning, () => at, paid);
      try {
        final plans = c.read(circlePlansProvider.notifier);
        final insights = c.read(insightsProvider.notifier);
        final today = dateKey(morning);
        final wasPaid = day > 1 && profile.premium(day - 1);
        if (!paid && wasPaid) {
          beforeLapse = c.read(circlePlansProvider);
          snapshotsBeforeLapse = c.read(insightsProvider).snapshots.length;
          leftOutBeforeLapse = c.read(suggestionPreferencesProvider).leftOut;
          keptBeforeLapse = c.read(keptCirclesProvider).kept.length;
        }
        if (!paid && leftOutBeforeLapse != null) {
          final leftOut = c.read(suggestionPreferencesProvider).leftOut;
          if (leftOut.length != leftOutBeforeLapse.length ||
              !leftOut.containsAll(leftOutBeforeLapse)) {
            fail('D$day leave-outs changed while lapsed');
          }
          if (c.read(keptCirclesProvider).kept.length < keptBeforeLapse) {
            fail('D$day a kept Circle was lost while lapsed');
          }
        }

        // Plans: the first Premium day starts the profile's Plan; an ended
        // cycle is gone through again; the profile's own script runs.
        if (paid && profile.plan != null) {
          if (!planStarted) {
            expectDone(plans.start(profile.plan!), 'D$day start');
            planStarted = true;
          }
          for (final p in c.read(circlePlansProvider).plans.values) {
            if (profile.repeats &&
                p.lifecycle == PlanLifecycle.ended &&
                p.current.endedOn != today) {
              plans.goThroughAgain(p.planId);
            }
          }
          profile.planScript?.call(day, plans);
        }

        final need = profile.needOn(day);
        final window = profile.windowOn(day);
        final notifier = c.read(recommendationProvider.notifier);
        final cursorBefore = c.read(circlePlansProvider).active?.current.cursor;
        final cycleBefore = c.read(circlePlansProvider).active?.current.id;
        notifier.chooseIntention(need, window: window);
        var r = c.read(recommendationProvider).recommendation;

        // A lapsed user with Circles of their own may use one instead.
        if (!paid) {
          lapseDays++;
          final kept = c
              .read(keptCirclesProvider)
              .kept
              .where((k) => k.need == need && k.minutes <= window.maxMinutes)
              .toList();
          if (kept.isNotEmpty) lapseSubstitutable++;
          if (profile.usesKeptWhenLapsed && kept.isNotEmpty) {
            final pick = kept[_h(day, 3) % kept.length];
            if (notifier.useOwnedToday(keptCircleId: pick.id) ==
                UseTodayResult.used) {
              lapseUsedKept++;
              r = c.read(recommendationProvider).recommendation;
            }
          }
        }
        if (r == null) {
          stalls++;
          lines.add('D$day ${need.name} ≈${window.maxMinutes} → nothing');
          continue;
        }
        final reason = profile.replaceOn?.call(day);
        if (reason != null && notifier.replaceToday(reason)) {
          r = c.read(recommendationProvider).recommendation!;
        }
        final stage = r.composed?.stage;

        // The Circle itself.
        notifier.start();
        final plan = r.composed?.plan;
        if (plan != null && plan.parts.length > 1) {
          final (skip, leaveOut) =
              profile.skipOn?.call(day, r) ?? (false, false);
          if (skip) {
            at = morning.add(const Duration(seconds: 30));
            notifier.skipPart(leaveOut: leaveOut);
            await _settle();
          }
        }
        final closes = profile.closes?.call(day) ?? true;
        CircleUsefulnessResponse? answer;
        if (closes) {
          at = morning.add(Duration(minutes: r.offeredMinutes));
          notifier.close();
          answer = profile.answerOn?.call(day, r);
          if (answer != null) {
            notifier.reportAttempt(CircleAttemptResponse.yes);
            notifier.reportUsefulness(answer);
          }
        }
        await _settle();

        if (closes &&
            plan != null &&
            (profile.keepsOn?.call(day, r, answer) ?? false)) {
          c
              .read(keptCirclesProvider.notifier)
              .keepCircle(plan: plan, need: need, circleId: today);
        }

        // The Plan moved at most once, and only on a closed stage Circle.
        final after = c.read(circlePlansProvider);
        final active = after.plans[stage?.planId];
        if (stage != null) {
          stageDays.add(day);
          if (!paid) fail('D$day a stage Circle without Premium');
          if (active != null &&
              active.current.id == cycleBefore &&
              cursorBefore != null &&
              active.current.cursor > cursorBefore + 1 &&
              !(active.current.records.any(
                (x) =>
                    x.localDate == today && x.outcome == StageOutcome.setAside,
              ))) {
            duplicateProgress++;
          }
          if (stage.stageNumber == 5) _checkStageFive(day, c, stage);
        }
        if (!paid) {
          if (r.composed != null && !r.composed!.isKept) {
            fail('D$day composed without Premium');
          }
          if (beforeLapse != null) {
            for (final p in beforeLapse.plans.values) {
              final now = after.plans[p.planId]!;
              if (now.current.cursor != p.current.cursor ||
                  now.cycles.length != p.cycles.length ||
                  now.current.records.length != p.current.records.length) {
                fail('D$day a Plan moved while lapsed');
              }
            }
          }
        }

        // A cycle that ended today: its review, as the Plan page shows it.
        for (final p in after.plans.values) {
          if (p.current.endedOn == today &&
              p.lifecycle == PlanLifecycle.ended) {
            _review(day, c, p);
          }
        }

        // Insights, when the user opens them.
        if (day % profile.opensInsightsEvery == 0) {
          final before = c.read(insightsProvider).snapshots.length;
          final added = insights.assess().added;
          if (!paid && added.isNotEmpty) {
            fail('D$day a new Insight while lapsed');
          }
          if (!paid && c.read(insightsProvider).snapshots.length < before) {
            fail('D$day snapshots lost while lapsed');
          }
          for (final s in added) {
            shown.add(s);
            switch (profile.onInsight?.call(s) ?? InsightChoice.ignore) {
              case InsightChoice.apply:
                insights.apply(s.id);
              case InsightChoice.notNow:
                if (s.family.isOrdinary) insights.notNow(s.id);
              case InsightChoice.ignore:
                break;
            }
          }
          if (!paid) {
            for (final s in c.read(insightsProvider).snapshots) {
              if (insights.apply(s.id) != InsightActionResult.needsPremium) {
                fail('D$day an Insight applied while lapsed');
              }
            }
            if (c.read(insightsProvider).snapshots.length <
                snapshotsBeforeLapse) {
              fail('D$day earlier Insights unreadable while lapsed');
            }
          }
        }
        await _settle();
        days.add(
          B8Day(
            day: day,
            premium: paid,
            need: need,
            window: window,
            recommendation: r,
            closed: closes,
            answer: answer,
          ),
        );
        lines.add(_line(day, paid, need, window, r, closes, answer));
      } finally {
        c.dispose();
      }
    }
  }

  void expectDone(PlanActionResult result, String what) {
    if (result != PlanActionResult.done) fail('$what: $result');
  }

  StageAnswers _answers(ProviderContainer c) =>
      stageAnswersFrom(c.read(circleJournalRepositoryProvider).readAll());

  /// Stage 5 drew only on this cycle's stages that weren't rejected or set
  /// aside, on the basis the answers allow (§7).
  void _checkStageFive(
    int day,
    ProviderContainer c,
    PlanStageProvenance stage,
  ) {
    final plans = c.read(circlePlansProvider);
    final progress = plans.plans[stage.planId]!;
    final cycle = progress.cycles.firstWhere((x) => x.id == stage.cycleId);
    final earlier = earlierStages(progress.definition, cycle, _answers(c));
    final eligible = {
      for (final e in earlier)
        if (!e.setAside && e.answer != PastUsefulness.notUseful) e.stageId,
    };
    final positive = [
      for (final e in earlier)
        if (!e.setAside &&
            (e.answer == PastUsefulness.veryUseful ||
                e.answer == PastUsefulness.somewhatUseful))
          e.stageId,
    ];
    final drawsOn = stage.drawsOn;
    if (!eligible.containsAll(drawsOn)) {
      fail('D$day stage 5 drew on a rejected or set-aside stage: $drawsOn');
    }
    if (positive.isNotEmpty && !drawsOn.any(positive.contains)) {
      fail('D$day stage 5 ignored the positive stages $positive');
    }
    stageFives.add({
      'day': day,
      'case': positive.isEmpty
          ? 'A'
          : positive.length == 1
          ? 'B'
          : 'C',
      'eligible': eligible.length,
      'drawsOn': drawsOn,
    });
  }

  /// The review must say only what the user said: no answer is never an
  /// answer, and a stage is never "completed".
  void _review(int day, ProviderContainer c, PlanProgress p) {
    final answers = _answers(c);
    final view = reviewOf(p.definition, p, answers);
    if (view == null) return;
    final journal = c.read(circleJournalRepositoryProvider).readAll();
    final facts = [
      for (final f in view.facts) reviewFactLine(p.definition, f, journal),
    ];
    final said = [
      for (final f in view.facts)
        if (f.record?.outcome == StageOutcome.guided && f.answer != null) f,
    ];
    final text = [view.endLine, ...view.summary, ...facts, ...view.compared];
    for (final line in text) {
      if (RegExp(
        r'complet|finished|done\b',
        caseSensitive: false,
      ).hasMatch(line)) {
        fail('D$day review says completion: $line');
      }
    }
    if (said.isEmpty &&
        !view.caseD &&
        p.current.end != CycleEnd.allSetAside &&
        !view.summary.contains(PlanCopy.noAnswers)) {
      fail('D$day a review without answers doesn\'t say so: ${view.summary}');
    }
    for (final f in view.facts) {
      if (f.record?.outcome == StageOutcome.guided && f.answer == null) {
        final line = reviewFactLine(p.definition, f, journal);
        if (!line.contains(PlanCopy.answer(null))) {
          fail('D$day an unanswered stage reads otherwise: $line');
        }
      }
    }
    reviews.add({
      'day': day,
      'plan': p.planId,
      'cycle': p.current.number,
      'end': p.current.end?.name,
      'answered': said.length,
      'lines': text,
    });
  }

  String _line(
    int day,
    bool paid,
    Intention need,
    TimeWindow window,
    Recommendation r,
    bool closed,
    CircleUsefulnessResponse? answer,
  ) {
    final composed = r.composed;
    final what = composed == null
        ? '[${r.composerFellBack ? 'FALLBACK' : 'FREE'}] ${r.activity}'
        : composed.isKept
        ? '[KEPT] ${composed.plan}'
        : '[${composed.stage == null ? 'CIRCLE' : 'STAGE ${composed.stage!.stageNumber}'}'
              '${composed.stage?.revisit ?? false ? ' again' : ''}] ${composed.plan}';
    return 'D${day.toString().padLeft(3)} ${paid ? 'P' : 'F'} ${need.name} '
        '≈${window.maxMinutes} → $what ${r.offeredMinutes}m · '
        '${closed ? answer?.name ?? 'no answer' : 'not closed'}';
  }

  /// The Insight record: per family, the silent weeks, and the two frozen
  /// cadence rules checked on what was actually generated.
  Map<String, Object?> insightReport() {
    final perFamily = {for (final f in InsightFamily.values) f.name: 0};
    for (final s in shown) {
      perFamily[s.family.name] = perFamily[s.family.name]! + 1;
    }
    final weeks = <int>{
      for (final s in shown)
        if (s.family.isOrdinary)
          DateTime.parse(s.generatedOn).difference(_start).inDays ~/ 7,
    };
    final totalWeeks = (_days + 6) ~/ 7;
    final cadence = <String>[];
    final sameClaim = <String>[];
    final ordinary = [
      for (final s in shown)
        if (s.family.isOrdinary) s,
    ];
    for (var i = 1; i < ordinary.length; i++) {
      final gap = DateTime.parse(
        ordinary[i].generatedOn,
      ).difference(DateTime.parse(ordinary[i - 1].generatedOn)).inDays;
      if (gap < 7) cadence.add('${ordinary[i].generatedOn} after $gap days');
    }
    final lastByClaim = <String, String>{};
    for (final s in ordinary) {
      final claim = '${s.family.name}|${s.subject}';
      final last = lastByClaim[claim];
      if (last != null &&
          DateTime.parse(
                s.generatedOn,
              ).difference(DateTime.parse(last)).inDays <
              28) {
        sameClaim.add('$claim on ${s.generatedOn} after $last');
      }
      lastByClaim[claim] = s.generatedOn;
    }
    return {
      'perFamily': perFamily,
      'weeksWithANewInsight': weeks.length,
      'silentWeeks': totalWeeks - weeks.length,
      'cadenceViolations': cadence,
      'sameClaimViolations': sameClaim,
    };
  }

  /// Variety on composed days — counts, never a score.
  Map<String, Object?> varietyReport({Intention? need}) {
    final composed = [
      for (final d in days)
        if (d.newComposition && (need == null || d.need == need)) d,
    ];
    String session(B8Day d) =>
        ([for (final e in d.composed!.plan.elements) e.name]..sort()).join('+');
    String material(B8Day d) => ([
      for (final p in d.composed!.plan.parts)
        if (p.definition.roles.contains(ElementRole.main) ||
            p.definition.roles.contains(ElementRole.second))
          p.element.name,
    ]..sort()).join('+');
    final seen = <String, int>{};
    int? firstRepeat;
    var longestSame = 0;
    var run = 0;
    String? previous;
    final gaps = <int>[];
    for (final d in composed) {
      final s = session(d);
      final last = seen[s];
      if (last != null) {
        firstRepeat ??= d.day;
        gaps.add(d.day - last);
      }
      seen[s] = d.day;
      run = s == previous ? run + 1 : 1;
      if (run > longestSame) longestSame = run;
      previous = s;
    }
    gaps.sort();
    return {
      'composedDays': composed.length,
      'distinctSessions': seen.length,
      'distinctMaterial': {for (final d in composed) material(d)}.length,
      'distinctMains': {
        for (final d in composed) d.composed!.plan.main.element,
      }.length,
      'firstExactRepeatDay': firstRepeat,
      'medianDaysBetweenRepeats': gaps.isEmpty ? null : gaps[gaps.length ~/ 2],
      'shortestRepeatGap': gaps.isEmpty ? null : gaps.first,
      'longestRunOfSameSession': longestSame,
    };
  }

  Map<String, Object?> report() {
    final premiumDays = days.where((d) => d.premium).toList();
    return {
      'profile': profile.name,
      'days': days.length,
      'premiumDays': premiumDays.length,
      'composedPremiumDays': premiumDays.where((d) => d.newComposition).length,
      'freeFallbackOnPremium': premiumDays
          .where((d) => d.recommendation.composerFellBack)
          .length,
      'stalls': stalls,
      'stageDays': stageDays.length,
      'reviews': reviews.length,
      'stageFiveCases': {
        for (final k in ['A', 'B', 'C'])
          k: stageFives.where((s) => s['case'] == k).length,
      },
      'foundUsefulClaims': days
          .where((d) => d.composed?.basis == CompositionBasis.foundUseful)
          .length,
      'lapse': {
        'days': lapseDays,
        'aKeptCircleCouldStandIn': lapseSubstitutable,
        'usedAKeptCircle': lapseUsedKept,
      },
      'duplicateProgress': duplicateProgress,
      'insights': insightReport(),
      'variety': varietyReport(),
      'failures': failures,
    };
  }

  void write() {
    final dir = Directory('build/b8_simulations')..createSync(recursive: true);
    File(
      '${dir.path}/${profile.name}.txt',
    ).writeAsStringSync('${lines.join('\n')}\n');
    File('${dir.path}/${profile.name}.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        ...report(),
        'reviewLines': reviews,
        'stageFives': stageFives,
        'insightsShown': [
          for (final s in shown)
            {'on': s.generatedOn, 'family': s.family.name, 'text': s.text},
        ],
      }),
    );
  }
}

/// A month index (0-based) for [day].
int _month(int day) => (day - 1) ~/ 30;

final _results = <String, Map<String, Object?>>{};

Future<B8Run> _simulate(B8Profile profile) async {
  final run = B8Run(profile);
  await run.run();
  run.write();
  _results[profile.name] = run.report();
  return run;
}

Intention _weightedNeed(int day) => switch (_h(day, 1) % 10) {
  < 4 => _energy,
  < 8 => _head,
  _ => _gentle,
};

TimeWindow _window(int day) => switch (_h(day, 2) % 3) {
  0 => TimeWindow.about10,
  1 => TimeWindow.about20,
  _ => TimeWindow.upTo30,
};

/// A realistic answer from the main piece: some kinds suit this user, some
/// don't, many get "Somewhat", and 40 % of days get no answer at all.
CircleUsefulnessResponse? _mixedAnswer(int day, Recommendation r) {
  if (_h(day, 4) % 10 < 4) return null;
  final kind = r.composed?.plan.main.definition.kind;
  return switch ((kind, _h(day, 5) % 6)) {
    (ElementKind.walking || ElementKind.writing, _) =>
      CircleUsefulnessResponse.veryUseful,
    (ElementKind.screens, < 4) => CircleUsefulnessResponse.notUseful,
    (_, 0) => CircleUsefulnessResponse.notUseful,
    (_, < 3) => CircleUsefulnessResponse.veryUseful,
    _ => CircleUsefulnessResponse.somewhatUseful,
  };
}

final _nonResponder = B8Profile(
  name: 'a_non_responder',
  needOn: _weightedNeed,
  windowOn: _window,
  uses: (day) => _h(day, 6) % 7 != 0,
  closes: (day) => _h(day, 7) % 5 != 0,
  plan: 'making_room',
);

final _mixed = B8Profile(
  name: 'b_mixed_answerer',
  needOn: _weightedNeed,
  windowOn: _window,
  uses: (day) => _h(day, 6) % 9 != 0,
  closes: (day) => _h(day, 7) % 8 != 0,
  answerOn: _mixedAnswer,
  replaceOn: (day) => switch (_h(day, 8) % 30) {
    0 || 1 => ReplacementReason.tooMuch,
    2 => ReplacementReason.notFeeling,
    _ => null,
  },
  skipOn: (day, r) => (_h(day, 9) % 10 == 0, day == 40),
  plan: 'getting_going',
  planScript: (day, plans) {
    if (day == 30) plans.requestRevisit('getting_going', 1);
    if (day == 120) plans.start('slowing_down');
    if (day == 200) plans.resume('getting_going');
    if (day == 260) plans.stopGentler('getting_going');
  },
  onInsight: (s) => switch (s.family) {
    InsightFamily.skippedPart ||
    InsightFamily.planPacing ||
    InsightFamily.usefulInCommon => InsightChoice.apply,
    InsightFamily.planReview => InsightChoice.ignore,
    _ => InsightChoice.notNow,
  },
  opensInsightsEvery: 3,
  keepsOn: (day, r, a) =>
      a == CircleUsefulnessResponse.veryUseful && day % 11 == 0,
);

final _energyTen = B8Profile(
  name: 'c_more_energy_10',
  needOn: (_) => _energy,
  windowOn: (_) => TimeWindow.about10,
  answerOn: (day, r) =>
      day % 4 == 0 ? CircleUsefulnessResponse.somewhatUseful : null,
  skipOn: (day, r) => (day == 30, day == 30),
  plan: 'getting_going',
  onInsight: (_) => InsightChoice.ignore,
);

final _lapse = B8Profile(
  name: 'd_lapse_and_return',
  needOn: _weightedNeed,
  windowOn: _window,
  premiumOn: (day) => day <= 150 || day > 270,
  answerOn: (day, r) => day.isEven
      ? _mixedAnswer(day, r) ?? CircleUsefulnessResponse.somewhatUseful
      : null,
  skipOn: (day, r) => (day == 20, day == 20),
  plan: 'making_room',
  onInsight: (s) => s.family == InsightFamily.planReview
      ? InsightChoice.ignore
      : InsightChoice.apply,
  opensInsightsEvery: 3,
  keepsOn: (day, r, a) =>
      a == CircleUsefulnessResponse.veryUseful ||
      a == CircleUsefulnessResponse.somewhatUseful,
  usesKeptWhenLapsed: true,
);

void main() {
  group('B8 — the whole product over twelve months (structure only)', () {
    test(
      'A — a user who never answers still gets the whole service, and '
      'nothing claims what they never said',
      () async {
        final run = await _simulate(_nonResponder);
        final r = run.report();
        expect(run.failures, isEmpty, reason: run.failures.join('\n'));
        expect(r['stalls'], 0);
        // Daily Premium composition, every Premium day it can honestly be made.
        expect(r['composedPremiumDays'] as int, greaterThan(250));
        // Plans run: many stage days, repeated cycles, every Stage 5 case A.
        expect(r['stageDays'] as int, greaterThan(50));
        expect(r['reviews'] as int, greaterThanOrEqualTo(4));
        expect((r['stageFiveCases'] as Map)['B'], 0);
        expect((r['stageFiveCases'] as Map)['C'], 0);
        expect((r['stageFiveCases'] as Map)['A'] as int, greaterThan(0));
        // Never "built from things you found useful", never I4.
        expect(r['foundUsefulClaims'], 0);
        final insights = r['insights'] as Map;
        expect((insights['perFamily'] as Map)['usefulInCommon'], 0);
        for (final s in run.shown) {
          expect(
            s.text.toLowerCase(),
            isNot(contains('useful')),
            reason: 'a non-responder never said anything was useful: ${s.text}',
          );
        }
        // Service continues after month 6: stage days and Insights both late.
        expect(run.stageDays.where((d) => d > 180), isNotEmpty);
        expect(
          run.shown.where(
            (s) =>
                DateTime.parse(s.generatedOn).difference(_start).inDays > 180,
          ),
          isNotEmpty,
        );
      },
      timeout: const Timeout(Duration(minutes: 10)),
      tags: 'long',
    );

    test(
      'B — a mixed answerer: answers move what is composed, Stage 5 uses '
      'only what this cycle allows, reviews say what was said',
      () async {
        final run = await _simulate(_mixed);
        final r = run.report();
        expect(run.failures, isEmpty, reason: run.failures.join('\n'));
        expect(r['stalls'], 0);
        expect(r['duplicateProgress'], 0);
        expect(r['reviews'] as int, greaterThanOrEqualTo(3));
        // Evidence is visible: some Circles are built from things found useful.
        expect(r['foundUsefulClaims'] as int, greaterThan(0));
        // Positive answers make B or C reachable.
        final cases = r['stageFiveCases'] as Map;
        expect((cases['B'] as int) + (cases['C'] as int), greaterThan(0));
        expect((r['insights'] as Map)['cadenceViolations'], isEmpty);
        expect((r['insights'] as Map)['sameClaimViolations'], isEmpty);
      },
      timeout: const Timeout(Duration(minutes: 10)),
      tags: 'long',
    );

    test(
      'C — More Energy every day at ≈10: no stall, the safety gate holds, '
      'repetition measured honestly',
      () async {
        final run = await _simulate(_energyTen);
        final r = run.report();
        expect(run.failures, isEmpty, reason: run.failures.join('\n'));
        expect(r['stalls'], 0);
        expect(r['freeFallbackOnPremium'], 0);
        expect(r['duplicateProgress'], 0);
        for (final d in run.days) {
          final plan = d.composed?.plan;
          if (plan == null) continue;
          for (final p in plan.parts) {
            expect(
              isElementOfferable(p.definition),
              isTrue,
              reason: 'D${d.day} ${p.element.name} is not a live, safe part',
            );
          }
          expect(plan.minutes, lessThanOrEqualTo(10));
        }
        // Plans keep cycling at ≈10.
        expect(r['reviews'] as int, greaterThanOrEqualTo(10));
        final variety = r['variety'] as Map;
        // The known finding (ADR-024 §10): usable but thin — never immediate.
        expect(variety['longestRunOfSameSession'] as int, lessThanOrEqualTo(2));
        expect(variety['distinctMains'] as int, greaterThanOrEqualTo(4));
      },
      timeout: const Timeout(Duration(minutes: 10)),
      tags: 'long',
    );

    test(
      'D — lapse is fair: everything owned stays, new Premium work stops, '
      'resubscribing resumes where it was',
      () async {
        final run = await _simulate(_lapse);
        final r = run.report();
        expect(run.failures, isEmpty, reason: run.failures.join('\n'));
        final lapse = r['lapse'] as Map;
        expect(lapse['days'], 120);
        // Owned Circles stand in on some lapsed days — not all of them.
        expect(lapse['usedAKeptCircle'] as int, greaterThan(0));
        expect(lapse['usedAKeptCircle'] as int, lessThan(120));
        final lapsed = run.days.where((d) => !d.premium);
        expect(lapsed.where((d) => d.newComposition), isEmpty);
        expect(lapsed.where((d) => d.composed?.stage != null), isEmpty);
        // Back on Premium: composition and the Plan resume.
        final back = run.days.where((d) => d.day > 270 && d.premium);
        expect(back.where((d) => d.newComposition), isNotEmpty);
        expect(run.stageDays.where((d) => d > 270), isNotEmpty);
        expect(
          run.shown.where(
            (s) =>
                DateTime.parse(s.generatedOn).difference(_start).inDays + 1 >
                    150 &&
                DateTime.parse(s.generatedOn).difference(_start).inDays + 1 <=
                    270,
          ),
          isEmpty,
        );
      },
      timeout: const Timeout(Duration(minutes: 10)),
      tags: 'long',
    );

    test('voice follows the entitlement: a lapse silences it, the choice is '
        'kept', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      for (final paid in [true, false, true]) {
        final c = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            premiumEntitlementProvider.overrideWithValue(paid),
            bundledGuidanceVoicesProvider.overrideWithValue(
              ThirtyVoice.values.toSet(),
            ),
          ],
        );
        addTearDown(c.dispose);
        if (paid) {
          c
              .read(thirtyVoiceChoiceProvider.notifier)
              .set(ThirtyVoice.values.last);
        }
        expect(c.read(spokenGuidanceOfferedProvider), paid);
        expect(c.read(thirtyVoiceProvider), ThirtyVoice.values.last);
      }
    });

    test('E — the twelve-month record of all four, and the report', () {
      expect(_results.keys, hasLength(4), reason: 'run the profiles first');
      for (final entry in _results.entries) {
        final insights = entry.value['insights'] as Map;
        // Each ended cycle's review is shown once — the 52-snapshot cap
        // never brings an old one back as new (fixed in B8).
        expect(
          (insights['perFamily'] as Map)['planReview'],
          entry.value['reviews'],
          reason: entry.key,
        );
        expect(insights['cadenceViolations'], isEmpty, reason: entry.key);
        expect(insights['sameClaimViolations'], isEmpty, reason: entry.key);
        expect(
          insights['silentWeeks'] as int,
          greaterThan(10),
          reason: entry.key,
        );
      }
      File(
        'build/b8_simulations/summary.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(_results));
      // Month buckets are only reported, never scored.
      expect(_month(365), 12);
    });
  });
}
