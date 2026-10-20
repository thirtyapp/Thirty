import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

import '../../features/home/application/activity_catalog.dart';
import '../../features/home/application/circle_journal.dart';
import '../../features/home/application/first_breath_provider.dart';
import '../../features/home/application/recommendation_provider.dart';
import '../../features/home/application/suggestion_preferences.dart';
import '../../features/personal_circle/domain/circle_composer.dart';
import '../../features/personal_circle/domain/circle_elements.dart';
import '../../features/personal_circle/domain/composed_session.dart';
import '../../features/home/domain/recommendation_engine.dart';
import '../../features/insights/application/insights_provider.dart';
import '../../features/insights/domain/insight.dart';
import '../../features/insights/domain/insight_engine.dart';
import '../../features/insights/presentation/insights_page.dart';
import '../../features/personal_circle/domain/kept_circle.dart';
import '../../features/personal_circle/application/kept_circles_provider.dart';
import '../../features/plans/application/circle_plans_provider.dart';
import '../../features/plans/domain/circle_plan.dart';
import '../../features/plans/domain/plan_stage_provenance.dart';
import '../../features/settings/application/first_name_provider.dart';
import '../analytics/analytics_service.dart';
import '../dev_preview/paced_qa_bench_page.dart';
import '../premium/premium_access.dart';
import '../providers/clock_provider.dart';
import '../providers/shared_preferences_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../utils/date_key.dart';
import 'qa_entitlement_gateway.dart';
import 'qa_inert_services.dart';
import 'qa_shared_preferences.dart';

/// QA-1 — the synthetic histories the harness can load. Each one is built
/// by [buildQaStore] into its own [QaSharedPreferences]; none ever touches
/// the device's genuine store.
enum QaScenario {
  /// No synthetic history: a sandboxed, in-memory copy of the genuine
  /// data, so an entitlement state can be tried against real history
  /// without anything written back.
  none('none', 'Real data (sandboxed copy)'),

  /// No Circle history at all — the low-data Premium walkthrough.
  newUser('new_user', 'New user'),

  /// V2 Phase B (Free): day 5, after one "Not useful" — that activity rests.
  freeNotUseful('free_not_useful', 'Free · one Not useful'),

  /// V2 Phase B (Free): a "Very useful" walk, ready to come back with its
  /// reason.
  freeUseful('free_useful', 'Free · useful before'),

  /// V2 Phase B (Free): a settled Clearer Head, due something new.
  freeExploration('free_exploration', 'Free · something new'),

  /// V2 Phase B (Free): tired Energy primaries and a secondary fit found
  /// very useful for Gentler Pace; ≈ 10 minutes preselected.
  freeSecondary('free_secondary', 'Free · secondary promoted'),

  /// V2 Phase B (Free): V1 answers — Write it down (compatible) counts, A
  /// brisk walk (LEARNING_RESET) does not.
  freeV1History('free_v1_history', 'Free · V1 history'),

  // V2 Phase C (Free) — the Circle experience and memory, A–R.

  /// Write it down offered, not started.
  cOpenFresh('c_open_fresh', 'C-A · Open, fresh'),

  /// Write it down started 16 minutes ago: its 15 have been reached.
  cOpenEnded('c_open_ended', 'C-B · Open, time reached'),

  /// Write it down 4 minutes in — to close early.
  cOpenRunning('c_open_running', 'C-C · Open, close early'),

  /// A quick standing stretch, just started, step 1.
  cGuidedFirst('c_guided_first', 'C-D · Guided, step 1'),

  /// A quick standing stretch, mid-sequence (step 3).
  cGuidedMiddle('c_guided_middle', 'C-E · Guided, middle'),

  /// A quick standing stretch, paused a minute ago on step 4.
  cGuidedPaused('c_guided_paused', 'C-F · Guided, paused'),

  /// A quick standing stretch past its 5 minutes, on the last step.
  cGuidedEnded('c_guided_ended', 'C-G · Guided, time reached'),

  /// The Paced runtime's internal QA bench (synthetic pattern).
  cPacedInternal('c_paced_internal', 'C-H · Paced, internal QA'),

  /// Today's Circle closed, not answered.
  cClosedNoAnswer('c_closed_no_answer', 'C-I · Closed, no answer'),

  /// Today's Circle closed: "Very useful".
  cClosedUseful('c_closed_useful', 'C-J · Closed, useful'),

  /// Today's Circle closed: "Not useful".
  cClosedNotUseful('c_closed_not_useful', 'C-K · Closed, not useful'),

  /// Memory with useful, resting and older answers across needs.
  cMemoryMixed('c_memory_mixed', 'C-L · Memory, mixed'),

  /// Memory: Easy walk resting for Gentler Pace.
  cMemoryResting('c_memory_resting', 'C-M · Memory, resting'),

  /// Memory: "Don't suggest" Move to music for More Energy.
  cMemoryNotSuggested('c_memory_not_suggested', 'C-N · Memory, don’t suggest'),

  /// Memory: Easy walk's rest lifted with "Suggest again".
  cMemoryRestLifted('c_memory_rest_lifted', 'C-O · Memory, rest lifted'),

  /// Every More Energy fit at ≈ 10 asked not to be suggested.
  cMemoryNothingFits('c_memory_nothing_fits', 'C-P · Memory, nothing fits'),

  /// History plus a "Don't suggest" — to Delete Circle history.
  cDeleteKeepsPreferences(
    'c_delete_keeps_preferences',
    'C-Q · Delete keeps preferences',
  ),

  /// History plus preferences — to reset the preferences.
  cResetPreferences('c_reset_preferences', 'C-R · Reset preferences'),

  /// V2 Phase D2 (ADR-023): two weeks of Free, and Premium today — the
  /// first Personal Guided Circle is one choice of need and time away.
  d2FirstPremium('d2_first_premium', 'D2-A · First Premium Today'),

  /// A month of Personal Guided Circles: answers, a skipped part, a part
  /// left out (Memory shows it), a kept Circle (Yours shows it).
  d2Month('d2_month', 'D2-B · A month of Circles'),

  /// Today's composed Circle, started a few minutes ago: its second part
  /// is on show — Skip, Pause, Next, and the parts moving on by
  /// themselves.
  d2Running('d2_running', 'D2-C · Composed Circle running'),

  /// Premium ended after a month of Circles and a kept Circle: Today is
  /// Free's, and what the user kept is theirs to use today.
  d2Lapsed('d2_lapsed', 'D2-D · Lapsed, kept Circle'),

  /// The same user, subscribed again: composition returns.
  d2Back('d2_back', 'D2-E · Back on Premium'),

  /// ADR-024 B3: the D2-E user with "Getting going" under way — stage 1
  /// guided, stage 2 next. More Energy steers today's Circle; another need
  /// doesn't. Walk it on INACTIVE for the lapse.
  d3PlanStage('d3_plan_stage', 'D3-A · Plan, stage 2'),

  /// ADR-024 B3: "Getting going" at stage 4 (Fresh air), with "Some fresh
  /// air" left out: at ≈10 the stage is set aside and stage 5 is tried the
  /// same day.
  d3PlanSetAside('d3_plan_set_aside', 'D3-B · Plan, set aside'),

  /// ADR-024 B4: "Making room" guided twice through, with mixed answers —
  /// its review in Plans, compared with the first cycle, and a Circle to
  /// keep from it.
  d4PlanReview('d4_plan_review', 'D4-A · Plan review, two cycles'),

  /// ADR-024 B9: "Slowing down" guided through once with no answer at all —
  /// its review says so (case A), and its last stage was a mix of the
  /// earlier ones.
  d4PlanReviewUnanswered(
    'd4_plan_review_unanswered',
    'D4-B · Plan review, no answers',
  ),

  /// ADR-024 B9: "Making room" with every stage said Not useful — no last
  /// Circle was made, and the review says why (case D).
  d4PlanReviewNoneUseful(
    'd4_plan_review_none_useful',
    'D4-C · Plan review, none useful',
  ),

  /// ADR-024 B6: nothing yet — the empty calendar, opened on Insights.
  e6Empty('e6_empty', 'E6-0 · Insights, nothing yet'),

  /// ADR-024 B6: five weeks across the three needs — Circles closed in
  /// THIRTY, Circles only recorded, days with none — and nothing for an
  /// Insight to say: the calendar is the page. Free or Premium.
  e6Calendar('e6_calendar', 'E6-A · Calendar, mixed dates'),

  /// Five Circles in the last week and "Getting going" at stage 2: too soon
  /// for a pattern; the Plan's place shows.
  e6EarlyWeek('e6_early_week', 'E6-B · Week one, Plan under way'),

  /// "Open a window" skipped in 3 of its last 4 Circles: I3 on opening.
  e6SkippedPart('e6_skipped_part', 'E6-C · Insight: a part you skip'),

  /// "Too much for today" on 3 of 5 "Getting going" days: I2 on opening.
  e6Pacing('e6_pacing', 'E6-D · Insight: gentler Plan Circles'),

  /// Writing in every Clearer Head Circle called useful, and none of the
  /// others: I4 on opening, with a Circle to keep.
  e6UsefulInCommon(
    'e6_useful_in_common',
    'E6-E · Insight: useful Circles shared',
  ),

  /// The same, with that Circle already kept: "Nothing to change".
  e6NothingToChange(
    'e6_nothing_to_change',
    'E6-F · Insight: nothing to change',
  ),

  /// E6-C's history, an Insight shown yesterday and set aside — and Premium
  /// has ended: everything readable, nothing new.
  e6Lapsed('e6_lapsed', 'E6-G · Lapsed, earlier Insights'),

  /// D4-A's two cycles of "Making room", opened on Insights: both reviews
  /// as references to Plans.
  e6PlanReview('e6_plan_review', 'E6-H · Plan reviews in Insights');

  const QaScenario(this.wireName, this.label);

  final String wireName;
  final String label;

  /// Where the app opens for this scenario (V2 Phase C): the Paced bench
  /// for its internal QA; the Insights tab for B6's;
  /// otherwise Today.
  String? get opensAt => switch (this) {
    QaScenario.cPacedInternal => PacedQaBenchPage.location,
    QaScenario.e6Empty ||
    QaScenario.e6Calendar ||
    QaScenario.e6EarlyWeek ||
    QaScenario.e6SkippedPart ||
    QaScenario.e6Pacing ||
    QaScenario.e6UsefulInCommon ||
    QaScenario.e6NothingToChange ||
    QaScenario.e6Lapsed ||
    QaScenario.e6PlanReview => InsightsPage.location,
    _ => null,
  };

  /// The entitlement this scenario is defined by, if any — a lapsed
  /// subscriber is inactive by definition.
  QaEntitlement? get fixedEntitlement =>
      this == QaScenario.d2Lapsed || this == QaScenario.e6Lapsed
      ? QaEntitlement.inactive
      : null;
}

/// One applied QA session: the simulated entitlement and the isolated store
/// every repository reads and writes while it is active.
@immutable
class QaSession {
  const QaSession({
    required this.entitlement,
    required this.scenario,
    required this.store,
  });

  final QaEntitlement entitlement;
  final QaScenario scenario;
  final QaSharedPreferences store;
}

/// Preferences a synthetic scenario carries over from the genuine store —
/// appearance and name only, so screenshots look like the tester's own
/// device. Never history, kept Circles, reminder or analytics state.
const qaCarriedPreferenceKeys = {themeModeKey, firstNameKey};

/// Builds [scenario]'s isolated store.
///
/// [genuine] is only read. Synthetic history is written into the returned
/// [QaSharedPreferences] alone, by running the production Circle and
/// kept-Circle notifiers through the scenario's scripted days, each relative
/// to [referenceNow]'s local date (never on that date itself, so today's
/// Circle stays open to walk live). The same inputs always produce the
/// same store.
Future<QaSharedPreferences> buildQaStore({
  required QaScenario scenario,
  required SharedPreferences genuine,
  required DateTime referenceNow,
}) async {
  final store = scenario == QaScenario.none
      ? QaSharedPreferences.copyOf(genuine)
      : QaSharedPreferences.copyOf(genuine, keys: qaCarriedPreferenceKeys);
  await store.setBool(firstNamePromptSeenKey, true);

  for (final day in qaScenarioDays(scenario)) {
    await simulateQaDay(store, referenceNow, day);
  }
  await _seedPreferences(store, referenceNow, qaPreferencesFor(scenario));
  if (qaTodayFor(scenario) case final today?) {
    await _seedToday(store, referenceNow, today);
  }
  await _seedPlans(store, referenceNow, scenario);
  await _seedInsightsHistory(store, referenceNow, scenario);
  return store;
}

/// ADR-024 B3: the Circle Plan a scenario has under way — its earlier
/// stages guided on earlier days — and, for the set-aside proof, "Some
/// fresh air" left out.
Future<void> _seedPlans(
  QaSharedPreferences store,
  DateTime referenceNow,
  QaScenario scenario,
) async {
  final through = switch (scenario) {
    QaScenario.d3PlanStage => 1,
    QaScenario.d3PlanSetAside => 3,
    _ => null,
  };
  if (through == null) return;
  String daysAgo(int n) => dateKey(
    DateTime(referenceNow.year, referenceNow.month, referenceNow.day - n),
  );
  var plans = CirclePlansState.empty.start('getting_going', today: daysAgo(9))!;
  for (var n = 1; n <= through; n++) {
    plans = plans.recordGuided(
      PlanStageProvenance(
        planId: 'getting_going',
        cycleId: 'getting_going#1',
        stageNumber: n,
        stageId: 'getting_going.$n',
      ),
      circleId: 'qa-stage-$n',
      today: daysAgo(9 - 2 * n),
      parts: const [],
      skipped: const [],
    );
  }
  await store.setString(circlePlansKey, jsonEncode(plans.toJson()));
  if (scenario == QaScenario.d3PlanSetAside) {
    final preferences = SuggestionPreferences.fromRaw(
      store.getString(suggestionPreferencesKey),
    );
    await store.setString(
      suggestionPreferencesKey,
      jsonEncode(
        SuggestionPreferences(
          notSuggested: preferences.notSuggested,
          restsLifted: preferences.restsLifted,
          elementsLeftOut: [
            ...preferences.elementsLeftOut,
            ElementLeftOut(
              element: ElementId.daylight,
              since: DateTime(
                referenceNow.year,
                referenceNow.month,
                referenceNow.day - 1,
                18,
              ),
            ),
          ],
        ).toJson(),
      ),
    );
  }
}

/// V2 Phase C: today's Circle as a scenario needs it — offered, running
/// (minutes in, perhaps paused, on a Guided step) or closed and answered.
/// Written straight into the per-day keys and the journal, exactly as the
/// production notifier persists them.
@immutable
class QaToday {
  const QaToday(
    this.need,
    this.activity, {
    this.window = TimeWindow.about20,
    this.startedMinutesAgo,
    this.closedMinutesAgo,
    this.pausedMinutesAgo,
    this.guidedPosition = 0,
    this.attempt,
    this.usefulness,
    this.plan,
  });

  /// V2 Phase D2: today's composed Circle, when the scenario needs one —
  /// [activity] is then its main piece's art.
  QaToday.composed(
    this.need,
    CirclePlan this.plan, {
    this.window = TimeWindow.about20,
    this.startedMinutesAgo,
    this.closedMinutesAgo,
    this.pausedMinutesAgo,
    this.attempt,
    this.usefulness,
  }) : activity = plan.main.definition.art,
       guidedPosition = 0;

  final CirclePlan? plan;
  final Intention need;
  final ActivityId activity;
  final TimeWindow window;
  final int? startedMinutesAgo;
  final int? closedMinutesAgo;
  final int? pausedMinutesAgo;
  final int guidedPosition;
  final CircleAttemptResponse? attempt;
  final CircleUsefulnessResponse? usefulness;
}

/// V2 Phase C: one explicit suggestion preference a scenario starts with.
typedef QaPreference = ({
  ActivityId activity,
  Intention need,
  bool restLifted,
  int daysAgo,
});

QaToday? qaTodayFor(QaScenario scenario) => switch (scenario) {
  QaScenario.cOpenFresh => const QaToday(_head, ActivityId.writeItDown),
  QaScenario.cOpenEnded => const QaToday(
    _head,
    ActivityId.writeItDown,
    startedMinutesAgo: 16,
  ),
  QaScenario.cOpenRunning => const QaToday(
    _head,
    ActivityId.writeItDown,
    startedMinutesAgo: 4,
  ),
  QaScenario.cGuidedFirst => const QaToday(
    _energy,
    ActivityId.energisingStretchFlow,
    startedMinutesAgo: 0,
  ),
  QaScenario.cGuidedMiddle => const QaToday(
    _energy,
    ActivityId.energisingStretchFlow,
    startedMinutesAgo: 2,
    guidedPosition: 2,
  ),
  QaScenario.cGuidedPaused => const QaToday(
    _energy,
    ActivityId.energisingStretchFlow,
    startedMinutesAgo: 3,
    pausedMinutesAgo: 1,
    guidedPosition: 3,
  ),
  QaScenario.cGuidedEnded => const QaToday(
    _energy,
    ActivityId.energisingStretchFlow,
    startedMinutesAgo: 6,
    guidedPosition: 4,
  ),
  QaScenario.cClosedNoAnswer => const QaToday(
    _head,
    ActivityId.writeItDown,
    startedMinutesAgo: 20,
    closedMinutesAgo: 3,
  ),
  QaScenario.cClosedUseful => const QaToday(
    _head,
    ActivityId.writeItDown,
    startedMinutesAgo: 20,
    closedMinutesAgo: 3,
    attempt: _yes,
    usefulness: _very,
  ),
  QaScenario.cClosedNotUseful => const QaToday(
    _head,
    ActivityId.writeItDown,
    startedMinutesAgo: 20,
    closedMinutesAgo: 3,
    attempt: _yes,
    usefulness: _not,
  ),
  QaScenario.d2Running => QaToday.composed(
    _head,
    CirclePlan(const [
      CirclePart(ElementId.standAndReach, 1),
      CirclePart(ElementId.clearCorner, 8),
      CirclePart(ElementId.getItOut, 6),
      CirclePart(ElementId.chooseOne, 1),
    ]),
    startedMinutesAgo: 2,
  ),
  _ => null,
};

List<QaPreference> qaPreferencesFor(QaScenario scenario) => switch (scenario) {
  QaScenario.cMemoryNotSuggested || QaScenario.cDeleteKeepsPreferences => [
    (
      activity: ActivityId.moveToMusic,
      need: _energy,
      restLifted: false,
      daysAgo: 2,
    ),
  ],
  QaScenario.cMemoryRestLifted => [
    (
      activity: ActivityId.easyWalk,
      need: _gentle,
      restLifted: true,
      daysAgo: 1,
    ),
  ],
  QaScenario.cMemoryNothingFits => [
    for (final activity in const [
      ActivityId.moveToMusic,
      ActivityId.energisingStretchFlow,
      ActivityId.activeHouseholdTask,
      ActivityId.tidyOneSurface,
      ActivityId.gentleStretchPause,
    ])
      (activity: activity, need: _energy, restLifted: false, daysAgo: 1),
  ],
  QaScenario.cResetPreferences => [
    (
      activity: ActivityId.moveToMusic,
      need: _energy,
      restLifted: false,
      daysAgo: 3,
    ),
    (
      activity: ActivityId.easyWalk,
      need: _gentle,
      restLifted: true,
      daysAgo: 1,
    ),
  ],
  _ => const [],
};

Future<void> _seedPreferences(
  QaSharedPreferences store,
  DateTime referenceNow,
  List<QaPreference> seeds,
) async {
  if (seeds.isEmpty) return;
  DateTime at(int daysAgo) => DateTime(
    referenceNow.year,
    referenceNow.month,
    referenceNow.day - daysAgo,
    18,
  );
  final preferences = SuggestionPreferences(
    notSuggested: [
      for (final seed in seeds)
        if (!seed.restLifted)
          NotSuggested(
            activity: seed.activity,
            need: seed.need,
            since: at(seed.daysAgo),
          ),
    ],
    restsLifted: [
      for (final seed in seeds)
        if (seed.restLifted)
          RestLifted(
            activity: seed.activity,
            need: seed.need,
            at: at(seed.daysAgo),
          ),
    ],
  );
  await store.setString(
    suggestionPreferencesKey,
    jsonEncode(preferences.toJson()),
  );
}

Future<void> _seedToday(
  QaSharedPreferences store,
  DateTime referenceNow,
  QaToday today,
) async {
  final date = dateKey(referenceNow);
  final activity = activityDefinition(today.activity);
  final plan = today.plan;
  final minutes =
      plan?.minutes ??
      offeredMinutesFor(activity, today.window) ??
      activity.typicalMinutes;
  final reason = plan == null
      ? RecommendationReason.bestFit
      : RecommendationReason.personalCircle;
  DateTime ago(int minutes) =>
      referenceNow.subtract(Duration(minutes: minutes));
  final startedAt = today.startedMinutesAgo == null
      ? null
      : ago(today.startedMinutesAgo!).subtract(const Duration(seconds: 5));
  final closedAt = today.closedMinutesAgo == null
      ? null
      : ago(today.closedMinutesAgo!);
  final pausedAt = today.pausedMinutesAgo == null
      ? null
      : ago(today.pausedMinutesAgo!);
  final shownAt = (startedAt ?? referenceNow).subtract(
    const Duration(minutes: 1),
  );

  await store.setString(firstBreathLastPlayedDateKey, date);
  await store.setString(recommendationDayKey, date);
  await store.setString(recommendationIntentionKey, today.need.name);
  await store.setString(recommendationActivityIdKey, today.activity.name);
  await store.setString(recommendationTimeWindowKey, today.window.name);
  await store.setInt(recommendationOfferedMinutesKey, minutes);
  await store.setString(recommendationReasonKey, reason.name);
  if (plan != null) {
    await store.setString(
      recommendationComposedKey,
      jsonEncode(
        ComposedSession(plan: plan, basis: CompositionBasis.sized).toJson(),
      ),
    );
  }
  await store.setString(
    recommendationStatusKey,
    closedAt != null
        ? RecommendationStatus.closed.name
        : startedAt != null
        ? RecommendationStatus.started.name
        : RecommendationStatus.notStarted.name,
  );
  if (startedAt != null) {
    await store.setString(
      recommendationStartedAtKey,
      startedAt.toIso8601String(),
    );
  }
  if (closedAt != null) {
    await store.setString(
      recommendationClosedAtKey,
      closedAt.toIso8601String(),
    );
  }
  if (pausedAt != null) {
    await store.setString(
      recommendationPausedAtKey,
      pausedAt.toIso8601String(),
    );
  }
  if (today.guidedPosition > 0) {
    await store.setInt(recommendationGuidedPositionKey, today.guidedPosition);
  }
  if (today.attempt case final attempt?) {
    await store.setString(recommendationAttemptResponseKey, attempt.name);
  }
  if (today.usefulness case final usefulness?) {
    await store.setString(recommendationUsefulnessResponseKey, usefulness.name);
  }

  final entries = CircleJournalRepository(store).readAll()
    ..add(
      CircleJournalEntry(
        schemaVersion: circleJournalSchemaVersion,
        circleId: date,
        localDate: date,
        direction: today.need,
        activityId: today.activity,
        catalogVersion: catalogVersion,
        shownAt: shownAt,
        startedAt: startedAt,
        closedAt: closedAt,
        attemptResponse: today.attempt,
        usefulnessResponse: today.usefulness,
        timeWindow: today.window.name,
        offeredMinutes: minutes,
        reasonCode: reason.name,
        minutesAtClose: startedAt == null || closedAt == null
            ? null
            : closedAt.difference(startedAt).inMinutes,
        session: plan == null
            ? null
            : CircleSessionRecord(
                title: ComposedCopy.title,
                parts: plan.toWire(),
              ),
      ),
    );
  await store.setString(
    circleJournalKey,
    jsonEncode({
      'schemaVersion': circleJournalSchemaVersion,
      'entries': [for (final e in entries) e.toJson()],
    }),
  );
}

/// One scripted day of synthetic history: what the tester would have done
/// on the day [offsetDays] from the reference date — the need chosen, the
/// time, the answers, and what they skipped, left out or kept.
@immutable
class QaScenarioDay {
  const QaScenarioDay(
    this.offsetDays,
    this.direction, {
    this.entitled = true,
    this.attempt,
    this.usefulness,
    this.window,
    this.replace,
    this.seeded,
    this.catalogVersion = _currentCatalogVersion,
    this.skipFirst = false,
    this.leaveOutFirst = false,
    this.keepCircle = false,
    this.startPlan,
    this.goThroughAgain,
  });

  /// Days relative to the reference date (negative: before it).
  final int offsetDays;
  final Intention direction;

  /// Whether Premium was active that day.
  final bool entitled;

  final CircleAttemptResponse? attempt;
  final CircleUsefulnessResponse? usefulness;

  /// V2 Phase B: the time window chosen that day (`null`: the default).
  final TimeWindow? window;

  /// V2 Phase B: "Not this one today" with this reason, before Start.
  final ReplacementReason? replace;

  /// V2 Phase B: write this activity straight into the journal instead of
  /// running the engine — a fixture for a specific history.
  final ActivityId? seeded;

  /// The catalogue version a [seeded] entry is recorded under.
  final int catalogVersion;

  /// V2 Phase D2: on a composed Circle, skip its first part — or skip it
  /// and leave it out of future Circles.
  final bool skipFirst;
  final bool leaveOutFirst;

  /// V2 Phase D2: after Close, keep the day's composed Circle.
  final bool keepCircle;

  /// ADR-024 B4: the Plan started (or gone through again) that morning,
  /// before today's need is chosen — through the Plan notifier, exactly as
  /// the Plans page does it.
  final String? startPlan;
  final String? goThroughAgain;
}

const _currentCatalogVersion = catalogVersion;

const _yes = CircleAttemptResponse.yes;
const _aLittle = CircleAttemptResponse.aLittle;
const _notToday = CircleAttemptResponse.notToday;
const _very = CircleUsefulnessResponse.veryUseful;
const _somewhat = CircleUsefulnessResponse.somewhatUseful;

const _not = CircleUsefulnessResponse.notUseful;
const _t10 = TimeWindow.about10;

const _energy = Intention.moreEnergy;
const _head = Intention.clearerHead;
const _gentle = Intention.gentlerPace;

/// The scripted days behind each [QaScenario], oldest first.
List<QaScenarioDay> qaScenarioDays(QaScenario scenario) => switch (scenario) {
  QaScenario.none || QaScenario.newUser => const [],
  // ADR-024 B6: exact records, written by [_seedInsightsHistory].
  QaScenario.e6Empty ||
  QaScenario.e6Calendar ||
  QaScenario.e6EarlyWeek ||
  QaScenario.e6SkippedPart ||
  QaScenario.e6Pacing ||
  QaScenario.e6UsefulInCommon ||
  QaScenario.e6NothingToChange ||
  QaScenario.e6Lapsed => const [],
  QaScenario.freeNotUseful => const [
    QaScenarioDay(
      -4,
      _energy,
      entitled: false,
      attempt: _yes,
      usefulness: _not,
    ),
    QaScenarioDay(
      -3,
      _head,
      entitled: false,
      attempt: _yes,
      usefulness: _somewhat,
    ),
    QaScenarioDay(
      -2,
      _gentle,
      entitled: false,
      attempt: _yes,
      usefulness: _somewhat,
    ),
    QaScenarioDay(-1, _head, entitled: false),
  ],
  QaScenario.freeUseful => const [
    QaScenarioDay(
      -9,
      _energy,
      entitled: false,
      attempt: _yes,
      usefulness: _very,
    ),
    QaScenarioDay(-7, _energy, entitled: false),
    QaScenarioDay(
      -5,
      _energy,
      entitled: false,
      attempt: _aLittle,
      usefulness: _somewhat,
    ),
    QaScenarioDay(-3, _gentle, entitled: false),
    QaScenarioDay(-1, _head, entitled: false),
  ],
  QaScenario.freeExploration => const [
    QaScenarioDay(
      -14,
      _head,
      entitled: false,
      attempt: _yes,
      usefulness: _somewhat,
    ),
    QaScenarioDay(
      -12,
      _head,
      entitled: false,
      attempt: _yes,
      usefulness: _very,
    ),
    QaScenarioDay(
      -10,
      _head,
      entitled: false,
      attempt: _yes,
      usefulness: _somewhat,
    ),
    QaScenarioDay(-8, _head, entitled: false, attempt: _yes, usefulness: _very),
    QaScenarioDay(
      -6,
      _head,
      entitled: false,
      attempt: _yes,
      usefulness: _somewhat,
    ),
    QaScenarioDay(-4, _head, entitled: false, attempt: _yes, usefulness: _very),
    QaScenarioDay(
      -2,
      _head,
      entitled: false,
      attempt: _yes,
      usefulness: _somewhat,
    ),
  ],
  QaScenario.freeSecondary => const [
    QaScenarioDay(
      -9,
      _gentle,
      entitled: false,
      seeded: ActivityId.gentleStretchPause,
      attempt: _yes,
      usefulness: _very,
    ),
    QaScenarioDay(
      -3,
      _energy,
      entitled: false,
      seeded: ActivityId.activeHouseholdTask,
      attempt: _yes,
      usefulness: _not,
    ),
    QaScenarioDay(
      -2,
      _energy,
      entitled: false,
      seeded: ActivityId.energisingStretchFlow,
    ),
    QaScenarioDay(
      -1,
      _energy,
      entitled: false,
      seeded: ActivityId.moveToMusic,
      window: _t10,
    ),
  ],
  QaScenario.freeV1History => const [
    QaScenarioDay(
      -20,
      _head,
      entitled: false,
      seeded: ActivityId.writeItDown,
      catalogVersion: v1CatalogVersion,
      attempt: _yes,
      usefulness: _very,
    ),
    QaScenarioDay(
      -18,
      _energy,
      entitled: false,
      seeded: ActivityId.thirtyMinuteWalk,
      catalogVersion: v1CatalogVersion,
      attempt: _yes,
      usefulness: _very,
    ),
    QaScenarioDay(
      -14,
      _head,
      entitled: false,
      seeded: ActivityId.writeItDown,
      catalogVersion: v1CatalogVersion,
      attempt: _yes,
      usefulness: _very,
    ),
    QaScenarioDay(
      -12,
      _energy,
      entitled: false,
      seeded: ActivityId.thirtyMinuteWalk,
      catalogVersion: v1CatalogVersion,
      attempt: _yes,
      usefulness: _very,
    ),
    QaScenarioDay(-6, _head, entitled: false),
    QaScenarioDay(-4, _head, entitled: false),
    QaScenarioDay(-2, _energy, entitled: false),
  ],
  QaScenario.cOpenFresh ||
  QaScenario.cOpenEnded ||
  QaScenario.cOpenRunning ||
  QaScenario.cGuidedFirst ||
  QaScenario.cGuidedMiddle ||
  QaScenario.cGuidedPaused ||
  QaScenario.cGuidedEnded ||
  QaScenario.cPacedInternal ||
  QaScenario.cClosedNoAnswer ||
  QaScenario.cClosedUseful ||
  QaScenario.cClosedNotUseful => const [
    QaScenarioDay(
      -3,
      _gentle,
      entitled: false,
      seeded: ActivityId.easyWalk,
      attempt: _yes,
      usefulness: _somewhat,
    ),
    QaScenarioDay(
      -1,
      _energy,
      entitled: false,
      seeded: ActivityId.moveToMusic,
      attempt: _yes,
      usefulness: _very,
    ),
  ],
  QaScenario.cMemoryMixed => const [
    QaScenarioDay(
      -40,
      _gentle,
      entitled: false,
      seeded: ActivityId.quietMusicBreak,
      attempt: _yes,
      usefulness: _not,
    ),
    QaScenarioDay(
      -20,
      _head,
      entitled: false,
      seeded: ActivityId.quietReading,
      attempt: _yes,
      usefulness: _somewhat,
    ),
    QaScenarioDay(
      -12,
      _energy,
      entitled: false,
      seeded: ActivityId.thirtyMinuteWalk,
      attempt: _yes,
      usefulness: _very,
    ),
    QaScenarioDay(
      -9,
      _head,
      entitled: false,
      seeded: ActivityId.writeItDown,
      attempt: _yes,
      usefulness: _very,
      window: TimeWindow.about20,
    ),
    QaScenarioDay(
      -7,
      _energy,
      entitled: false,
      seeded: ActivityId.activeHouseholdTask,
      attempt: _notToday,
    ),
    QaScenarioDay(
      -6,
      _head,
      entitled: false,
      seeded: ActivityId.tidyOneSurface,
      attempt: _aLittle,
      usefulness: _not,
      window: TimeWindow.about20,
    ),
    QaScenarioDay(
      -4,
      _gentle,
      entitled: false,
      seeded: ActivityId.easyWalk,
      attempt: _yes,
      usefulness: _not,
    ),
    QaScenarioDay(
      -2,
      _head,
      entitled: false,
      seeded: ActivityId.singleTaskFocus,
      attempt: _yes,
      usefulness: _somewhat,
      window: TimeWindow.about20,
    ),
    QaScenarioDay(-1, _energy, entitled: false, seeded: ActivityId.moveToMusic),
  ],
  QaScenario.cMemoryResting => const [
    QaScenarioDay(
      -8,
      _gentle,
      entitled: false,
      seeded: ActivityId.smallComfortRitual,
      attempt: _yes,
      usefulness: _very,
    ),
    QaScenarioDay(
      -3,
      _gentle,
      entitled: false,
      seeded: ActivityId.easyWalk,
      attempt: _yes,
      usefulness: _not,
    ),
  ],
  QaScenario.cMemoryNotSuggested ||
  QaScenario.cDeleteKeepsPreferences => const [
    QaScenarioDay(
      -5,
      _energy,
      entitled: false,
      seeded: ActivityId.thirtyMinuteWalk,
      attempt: _yes,
      usefulness: _very,
    ),
    QaScenarioDay(
      -3,
      _gentle,
      entitled: false,
      seeded: ActivityId.easyWalk,
      attempt: _yes,
      usefulness: _somewhat,
    ),
    QaScenarioDay(
      -2,
      _energy,
      entitled: false,
      seeded: ActivityId.moveToMusic,
      attempt: _aLittle,
      usefulness: _not,
    ),
  ],
  QaScenario.cMemoryRestLifted => const [
    QaScenarioDay(
      -3,
      _gentle,
      entitled: false,
      seeded: ActivityId.easyWalk,
      attempt: _yes,
      usefulness: _not,
    ),
  ],
  QaScenario.cMemoryNothingFits => const [
    QaScenarioDay(
      -2,
      _head,
      entitled: false,
      seeded: ActivityId.writeItDown,
      attempt: _yes,
      usefulness: _very,
      window: _t10,
    ),
  ],
  QaScenario.cResetPreferences => const [
    QaScenarioDay(
      -4,
      _gentle,
      entitled: false,
      seeded: ActivityId.easyWalk,
      attempt: _yes,
      usefulness: _not,
    ),
    QaScenarioDay(
      -2,
      _energy,
      entitled: false,
      seeded: ActivityId.thirtyMinuteWalk,
      attempt: _yes,
      usefulness: _very,
    ),
  ],
  QaScenario.d2FirstPremium => [
    for (final day in _freeHistory(-15))
      QaScenarioDay(
        day.offsetDays,
        day.direction,
        entitled: false,
        seeded: day.seeded,
        window: day.window,
        attempt: day.attempt,
        usefulness: day.usefulness,
      ),
  ],
  QaScenario.d2Month ||
  QaScenario.d2Running => [..._freeHistory(-45), ..._composedMonth(-29)],
  QaScenario.d4PlanReview || QaScenario.e6PlanReview => [
    ..._freeHistory(-72),
    // Cycle 1: every stage guided, some answered.
    const QaScenarioDay(
      -40,
      _head,
      startPlan: 'making_room',
      window: TimeWindow.about20,
      attempt: _yes,
      usefulness: _very,
    ),
    const QaScenarioDay(
      -38,
      _head,
      window: TimeWindow.about20,
      attempt: _yes,
      usefulness: _somewhat,
    ),
    const QaScenarioDay(-36, _head, window: TimeWindow.about20),
    const QaScenarioDay(
      -34,
      _head,
      window: TimeWindow.about20,
      attempt: _yes,
      usefulness: _very,
    ),
    const QaScenarioDay(
      -32,
      _head,
      window: TimeWindow.about20,
      attempt: _yes,
      usefulness: _somewhat,
    ),
    // Cycle 2: through again, answered differently.
    const QaScenarioDay(
      -20,
      _head,
      goThroughAgain: 'making_room',
      window: TimeWindow.about20,
      attempt: _yes,
      usefulness: _very,
    ),
    const QaScenarioDay(
      -18,
      _head,
      window: TimeWindow.about20,
      attempt: _yes,
      usefulness: _not,
    ),
    const QaScenarioDay(-16, _head, window: TimeWindow.about20),
    const QaScenarioDay(
      -14,
      _head,
      window: TimeWindow.about20,
      attempt: _yes,
      usefulness: _somewhat,
    ),
    const QaScenarioDay(
      -12,
      _head,
      window: TimeWindow.about20,
      attempt: _yes,
      usefulness: _very,
    ),
  ],
  QaScenario.d4PlanReviewUnanswered => [
    ..._freeHistory(-72),
    const QaScenarioDay(
      -30,
      _gentle,
      startPlan: 'slowing_down',
      window: TimeWindow.about20,
    ),
    for (final offset in const [-28, -26, -24, -22])
      QaScenarioDay(offset, _gentle, window: TimeWindow.about20),
  ],
  QaScenario.d4PlanReviewNoneUseful => [
    ..._freeHistory(-72),
    const QaScenarioDay(
      -30,
      _head,
      startPlan: 'making_room',
      window: TimeWindow.about20,
      attempt: _yes,
      usefulness: _not,
    ),
    for (final offset in const [-28, -26, -24])
      QaScenarioDay(
        offset,
        _head,
        window: TimeWindow.about20,
        attempt: _yes,
        usefulness: _not,
      ),
    // The next Clearer Head day: no last Circle can be made, so the cycle
    // ends at its review and today's Circle is the ordinary one.
    const QaScenarioDay(-22, _head, window: TimeWindow.about20),
  ],
  QaScenario.d2Lapsed ||
  QaScenario.d2Back ||
  QaScenario.d3PlanStage ||
  QaScenario.d3PlanSetAside => [
    ..._freeHistory(-72),
    ..._composedMonth(-34),
    // Premium ended: Free days since.
    const QaScenarioDay(-3, _head, entitled: false, attempt: _yes),
    const QaScenarioDay(
      -1,
      _energy,
      entitled: false,
      attempt: _yes,
      usefulness: _somewhat,
    ),
  ],
};

/// V2 Phase D2: a month of Personal Guided Circles from [start] — needs and
/// times varied as a real month would, most answered, a part skipped once,
/// a part left out once, and one Circle kept.
List<QaScenarioDay> _composedMonth(int start) => [
  for (var i = 0; i < 26; i++)
    if (i % 4 != 3)
      QaScenarioDay(
        start + i,
        const [_head, _energy, _head, _gentle][i % 4],
        window: const [
          TimeWindow.about20,
          TimeWindow.about10,
          TimeWindow.upTo30,
          TimeWindow.about20,
        ][(i ~/ 2) % 4],
        attempt: i % 5 == 4 ? null : _yes,
        usefulness: i % 5 == 4
            ? null
            : const [_very, _somewhat, _very, _not, _somewhat][i % 5],
        skipFirst: i == 6,
        leaveOutFirst: i == 13,
        keepCircle: i == 20,
      ),
];

/// Two weeks of Free history from [start]: More Energy most days, Move to
/// music found very useful twice.
List<QaScenarioDay> _freeHistory(int start) => [
  QaScenarioDay(
    start,
    _energy,
    entitled: false,
    seeded: ActivityId.moveToMusic,
    window: TimeWindow.about20,
    attempt: _yes,
    usefulness: _very,
  ),
  QaScenarioDay(
    start + 2,
    _head,
    entitled: false,
    seeded: ActivityId.writeItDown,
    window: TimeWindow.about20,
    attempt: _yes,
    usefulness: _somewhat,
  ),
  QaScenarioDay(
    start + 4,
    _energy,
    entitled: false,
    seeded: ActivityId.energisingStretchFlow,
    window: TimeWindow.about20,
    attempt: _yes,
    usefulness: _somewhat,
  ),
  QaScenarioDay(
    start + 6,
    _energy,
    entitled: false,
    seeded: ActivityId.moveToMusic,
    window: TimeWindow.about20,
    attempt: _yes,
    usefulness: _very,
  ),
  QaScenarioDay(
    start + 8,
    _gentle,
    entitled: false,
    seeded: ActivityId.easyWalk,
    window: TimeWindow.about20,
    attempt: _yes,
    usefulness: _somewhat,
  ),
  QaScenarioDay(
    start + 10,
    _energy,
    entitled: false,
    seeded: ActivityId.activeHouseholdTask,
    window: TimeWindow.about20,
    attempt: _aLittle,
    usefulness: _somewhat,
  ),
  QaScenarioDay(
    start + 12,
    _energy,
    entitled: false,
    seeded: ActivityId.energisingStretchFlow,
    window: TimeWindow.about20,
  ),
];

/// Runs one scripted day through the production notifiers, in a throwaway
/// container over [store], with the clock fixed to that day: the day's
/// Circle (chosen by the real engine, or composed), its answers, and then
/// keeping it. A [QaScenarioDay.seeded] day writes its Circle straight into
/// the journal instead.
Future<void> simulateQaDay(
  SharedPreferences store,
  DateTime referenceNow,
  QaScenarioDay day,
) async {
  final morning = DateTime(
    referenceNow.year,
    referenceNow.month,
    referenceNow.day + day.offsetDays,
    9,
  );
  if (day.seeded case final activity?) {
    await _seedJournalEntry(store, morning, day, activity);
    return;
  }
  var clock = morning;
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(store),
      nowProvider.overrideWithValue(morning),
      eventClockProvider.overrideWithValue(() => clock),
      premiumEntitlementProvider.overrideWithValue(day.entitled),
      safetyPendingAllowedProvider.overrideWithValue(false),
      analyticsServiceProvider.overrideWithValue(
        const QaSilentAnalyticsService(),
      ),
    ],
  );
  try {
    final kept = container.read(keptCirclesProvider.notifier);
    final circle = container.read(recommendationProvider.notifier);
    final plans = container.read(circlePlansProvider.notifier);
    if (day.startPlan case final id?) plans.start(id);
    if (day.goThroughAgain case final id?) plans.goThroughAgain(id);

    circle.chooseIntention(day.direction, window: day.window);
    await _settle();
    if (day.replace case final reason?) {
      circle.replaceToday(reason);
      await _settle();
    }

    clock = morning.add(const Duration(minutes: 2));
    circle.start();
    await _settle();
    if (day.skipFirst || day.leaveOutFirst) {
      circle.skipPart(leaveOut: day.leaveOutFirst);
      await _settle();
    }
    clock = morning.add(const Duration(minutes: 32));
    circle.close();
    await _settle();

    if (day.attempt case final attempt?) {
      circle.reportAttempt(attempt);
      await _settle();
    }
    if (day.usefulness case final usefulness?) {
      circle.reportUsefulness(usefulness);
      await _settle();
    }

    final composed = container
        .read(recommendationProvider)
        .recommendation
        ?.composed;
    if (day.keepCircle && composed != null && !composed.isKept) {
      kept.keepCircle(
        plan: composed.plan,
        need: day.direction,
        circleId: dateKey(morning),
      );
      await _settle();
    }
  } finally {
    container.dispose();
  }
}

/// Lets the notifiers' fire-and-forget writes (all in-memory here) finish
/// before the next step reads them back.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

/// Records [activity] for [day] straight into [store]'s Circle journal, as
/// the catalogue version [QaScenarioDay.catalogVersion] would have.
Future<void> _seedJournalEntry(
  SharedPreferences store,
  DateTime morning,
  QaScenarioDay day,
  ActivityId activity,
) async {
  final date = dateKey(morning);
  final entries = CircleJournalRepository(store).readAll()
    ..add(
      CircleJournalEntry(
        schemaVersion: circleJournalSchemaVersion,
        circleId: date,
        localDate: date,
        direction: day.direction,
        activityId: activity,
        catalogVersion: day.catalogVersion,
        shownAt: morning,
        startedAt: morning.add(const Duration(minutes: 2)),
        closedAt: morning.add(const Duration(minutes: 22)),
        attemptResponse: day.attempt,
        usefulnessResponse: day.usefulness,
        timeWindow: day.window?.name,
      ),
    );
  await store.setString(
    circleJournalKey,
    jsonEncode({
      'schemaVersion': circleJournalSchemaVersion,
      'entries': [for (final e in entries) e.toJson()],
    }),
  );
}

// ---------------------------------------------------------------------------
// ADR-024 B6: the Insights surface's scenarios — exact records, so each
// state (and each Insight family's evidence) is the same on every device.

/// One B6 day: what was recorded, and whether it was closed in THIRTY.
@immutable
class _InsightsDay {
  const _InsightsDay(
    this.offsetDays,
    this.need, {
    this.parts = const [],
    this.skipped = const [],
    this.answer,
    this.closed = true,
    this.stage,
    this.tooMuch = false,
  });

  final int offsetDays;
  final Intention need;

  /// A composed Circle's parts (wire form); empty: one activity.
  final List<String> parts;
  final List<String> skipped;
  final CircleUsefulnessResponse? answer;

  /// Closed in THIRTY — or only recorded.
  final bool closed;

  /// "Getting going" (cycle 1) stage the day's Circle was composed for — or,
  /// with [tooMuch], the stage "Not this one today" replaced.
  final int? stage;
  final bool tooMuch;
}

const _windowParts = ['openWindow:1', 'standingStretch:5', 'sitAMinute:2'];
const _musicParts = ['songOn:1', 'moveToMusic:8', 'shakeOut:1'];
const _readingParts = ['phoneFaceDown:1', 'readPages:10'];
const _writingParts = [
  'closeWhatsOpen:3',
  'getItOut:6',
  'chooseOne:1',
  'firstStep:2',
];
const _quietParts = ['comfortableSpot:1', 'quietMusic:10', 'sitAMinute:2'];

List<String> _partsFor(Intention need, int i) => switch (need) {
  Intention.moreEnergy => i.isEven ? _windowParts : _musicParts,
  Intention.clearerHead => i.isEven ? _readingParts : _writingParts,
  Intention.gentlerPace => _quietParts,
};

List<_InsightsDay>? _insightsDays(QaScenario scenario) => switch (scenario) {
  // Five weeks, the three needs in turn; a day in five without a Circle,
  // a Circle in four only recorded.
  QaScenario.e6Calendar => [
    for (var i = 0; i < 34; i++)
      if (i % 5 != 3)
        _InsightsDay(
          -34 + i,
          Intention.values[i % 3],
          parts: _partsFor(Intention.values[i % 3], i),
          closed: i % 4 != 1,
        ),
  ],
  QaScenario.e6EarlyWeek => [
    const _InsightsDay(-6, _energy, parts: _musicParts, answer: _somewhat),
    const _InsightsDay(-5, _energy, parts: _windowParts, stage: 1),
    const _InsightsDay(-3, _head, parts: _readingParts, answer: _very),
    const _InsightsDay(-2, _energy, parts: _musicParts, closed: false),
    const _InsightsDay(-1, _gentle, parts: _quietParts, answer: _somewhat),
  ],
  QaScenario.e6SkippedPart || QaScenario.e6Lapsed => [
    for (final o in [-16, -14, -12, -10, -8, -6])
      _InsightsDay(o, _head, parts: _readingParts),
    for (final o in [-15, -11, -7, -3])
      _InsightsDay(
        o,
        _energy,
        parts: _windowParts,
        skipped: o == -11 ? const [] : const ['openWindow'],
      ),
    const _InsightsDay(-2, _head, parts: _readingParts, closed: false),
  ],
  QaScenario.e6Pacing => [
    const _InsightsDay(-17, _energy, stage: 1, tooMuch: true),
    const _InsightsDay(-14, _energy, parts: _windowParts, stage: 1),
    const _InsightsDay(-11, _energy, stage: 2, tooMuch: true),
    const _InsightsDay(-8, _energy, parts: _musicParts, stage: 2),
    const _InsightsDay(-4, _energy, stage: 3, tooMuch: true),
    const _InsightsDay(-2, _head, parts: _readingParts),
  ],
  QaScenario.e6UsefulInCommon || QaScenario.e6NothingToChange => [
    for (final (k, o) in [-20, -15, -10, -5].indexed)
      _InsightsDay(
        o,
        _head,
        parts: _writingParts,
        answer: k.isEven ? _very : _somewhat,
      ),
    for (final o in [-18, -12, -7])
      _InsightsDay(o, _head, parts: _readingParts),
  ],
  _ => null,
};

PlanStageProvenance _gettingGoing(int stage) => PlanStageProvenance(
  planId: 'getting_going',
  cycleId: 'getting_going#1',
  stageNumber: stage,
  stageId: 'getting_going.$stage',
);

CircleJournalEntry _insightsEntry(_InsightsDay day, DateTime morning) {
  final date = dateKey(morning);
  final plan = day.parts.isEmpty ? null : CirclePlan.fromWire(day.parts)!;
  final stage = day.stage == null ? null : _gettingGoing(day.stage!);
  return CircleJournalEntry(
    schemaVersion: circleJournalSchemaVersion,
    circleId: date,
    localDate: date,
    direction: day.need,
    activityId: plan?.main.definition.art ?? ActivityId.moveToMusic,
    catalogVersion: catalogVersion,
    shownAt: morning,
    startedAt: day.closed ? morning.add(const Duration(minutes: 2)) : null,
    closedAt: day.closed ? morning.add(const Duration(minutes: 32)) : null,
    attemptResponse: day.answer == null ? null : _yes,
    usefulnessResponse: day.answer,
    timeWindow: TimeWindow.about20.name,
    offeredMinutes: plan?.minutes ?? 20,
    reasonCode: plan == null
        ? RecommendationReason.bestFit.name
        : RecommendationReason.personalCircle.name,
    replacedFrom: day.tooMuch ? ActivityId.energisingStretchFlow : null,
    replacementReason: day.tooMuch ? ReplacementReason.tooMuch.name : null,
    replacedFromStage: day.tooMuch ? stage : null,
    minutesAtClose: day.closed ? 30 : null,
    session: plan == null
        ? null
        : CircleSessionRecord(
            title: ComposedCopy.title,
            parts: day.parts,
            skipped: day.skipped,
            planStage: day.tooMuch ? null : stage,
          ),
  );
}

/// ADR-024 B6: writes [scenario]'s exact records, its Plan, kept Circle and
/// earlier Insight — each relative to [referenceNow], never on that day.
Future<void> _seedInsightsHistory(
  QaSharedPreferences store,
  DateTime referenceNow,
  QaScenario scenario,
) async {
  final days = _insightsDays(scenario);
  if (days == null) return;
  DateTime morning(int offset) => DateTime(
    referenceNow.year,
    referenceNow.month,
    referenceNow.day + offset,
    9,
  );
  String on(int offset) => dateKey(morning(offset));
  final entries = [
    for (final d in days) _insightsEntry(d, morning(d.offsetDays)),
  ];
  await store.setString(
    circleJournalKey,
    jsonEncode({
      'schemaVersion': circleJournalSchemaVersion,
      'entries': [for (final e in entries) e.toJson()],
    }),
  );

  // "Getting going" under way: stage 1 guided (E6-B), or stages 1–2 (E6-D).
  final guided = switch (scenario) {
    QaScenario.e6EarlyWeek => const [(1, -5)],
    QaScenario.e6Pacing => const [(1, -14), (2, -8)],
    _ => null,
  };
  if (guided != null) {
    var plans = CirclePlansState.empty.start(
      'getting_going',
      today: on(guided.first.$2 - 3),
    )!;
    for (final (stage, offset) in guided) {
      plans = plans.recordGuided(
        _gettingGoing(stage),
        circleId: on(offset),
        today: on(offset),
        parts: [
          for (final d in days)
            if (d.offsetDays == offset) ...d.parts,
        ],
        skipped: const [],
      );
    }
    await store.setString(circlePlansKey, jsonEncode(plans.toJson()));
  }

  // E6-F: the Circle I4 would offer to keep is kept already.
  if (scenario == QaScenario.e6NothingToChange) {
    await store.setString(
      keptCirclesKey,
      jsonEncode(
        keptCirclesRecord([
          KeptCircle(
            id: 'qa-kept-writing',
            name: keptCircleDefaultName(_head),
            need: _head,
            plan: CirclePlan.fromWire(_writingParts)!,
            createdAt: morning(-5).add(const Duration(minutes: 40)),
            fromCircleId: on(-5),
          ),
        ]),
      ),
    );
  }

  // E6-G: yesterday THIRTY showed an Insight, and the user set it aside.
  if (scenario == QaScenario.e6Lapsed) {
    final yesterday = morning(-1);
    final shown = assessInsights(
      InsightInputs(
        today: yesterday,
        circles: [for (final e in entries) InsightCircle.fromJournal(e)],
      ),
      const [],
      generate: true,
    ).added;
    await store.setString(
      insightsKey,
      jsonEncode(
        InsightsState([
          for (final s in shown) s.copyWith(notNowOn: on(-1)),
        ]).toJson(),
      ),
    );
  }
}
