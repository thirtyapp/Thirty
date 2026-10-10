import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

import '../../features/home/application/activity_catalog.dart';
import '../../features/home/application/circle_journal.dart';
import '../../features/home/application/first_breath_provider.dart';
import '../../features/home/application/recommendation_provider.dart';
import '../../features/home/application/suggestion_preferences.dart';
import '../../features/home/domain/recommendation_engine.dart';
import '../../features/insights/application/insight_provider.dart';
import '../../features/plans/application/plan_provider.dart';
import '../../features/plans/domain/plan_ids.dart';
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

  /// More Energy Path three stages in, with reflections.
  planInProgress('plan_in_progress', 'Plan in progress'),

  /// Gentler Pace Path: one completed cycle, a second under way with one
  /// stage deliberately revisited — the R5 continuing-value case.
  monthTwo('month_two', 'Month two'),

  /// Weeks of closed Circles and a Plan in progress, with no reflection
  /// answer ever given.
  neverReflects('never_reflects', 'Never reflects'),

  /// Weeks of Premium use with retained Insight snapshots, then Free-only
  /// days after the subscription ended. Always [QaEntitlement.inactive].
  lapsedRetainedSnapshots(
    'lapsed_retained_snapshots',
    'Lapsed, retained snapshots',
  ),

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
  cResetPreferences('c_reset_preferences', 'C-R · Reset preferences');

  const QaScenario(this.wireName, this.label);

  final String wireName;
  final String label;

  /// Where the app opens for this scenario (V2 Phase C): the Paced bench
  /// for its internal QA, otherwise Today.
  String? get opensAt =>
      this == QaScenario.cPacedInternal ? PacedQaBenchPage.location : null;

  /// The entitlement this scenario is defined by, if any — a lapsed
  /// subscriber is inactive by definition.
  QaEntitlement? get fixedEntitlement =>
      this == QaScenario.lapsedRetainedSnapshots
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
/// device. Never history, Plans, Insights, reminder or analytics state.
const qaCarriedPreferenceKeys = {themeModeKey, firstNameKey};

/// Builds [scenario]'s isolated store.
///
/// [genuine] is only read. Synthetic history is written into the returned
/// [QaSharedPreferences] alone, by running the production Circle, Plan and
/// Insight notifiers through the scenario's scripted days, each relative
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
    await _simulateDay(store, referenceNow, day);
  }
  await _seedPreferences(store, referenceNow, qaPreferencesFor(scenario));
  if (qaTodayFor(scenario) case final today?) {
    await _seedToday(store, referenceNow, today);
  }
  return store;
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
  });

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
  final minutes =
      offeredMinutesFor(activity, today.window) ?? activity.typicalMinutes;
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
  await store.setString(
    recommendationReasonKey,
    RecommendationReason.bestFit.name,
  );
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
        reasonCode: RecommendationReason.bestFit.name,
        minutesAtClose: startedAt == null || closedAt == null
            ? null
            : closedAt.difference(startedAt).inMinutes,
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
/// on the day [offsetDays] from the reference date.
@immutable
class QaScenarioDay {
  const QaScenarioDay(
    this.offsetDays,
    this.direction, {
    this.entitled = true,
    this.activatePlan,
    this.repeatCycle,
    this.queueRevisit = false,
    this.attempt,
    this.usefulness,
    this.window,
    this.replace,
    this.seeded,
    this.catalogVersion = _currentCatalogVersion,
  });

  final int offsetDays;
  final Intention direction;

  /// Whether Premium was active that day.
  final bool entitled;

  /// A Plan the tester started that morning, before choosing a direction.
  final PlanId? activatePlan;

  /// A completed Plan the tester began again that morning.
  final PlanId? repeatCycle;

  /// Whether the tester asked to revisit the last stage that morning.
  final bool queueRevisit;

  final CircleAttemptResponse? attempt;
  final CircleUsefulnessResponse? usefulness;

  /// V2 Phase B: the time chosen that day (the provider's default if null).
  final TimeWindow? window;

  /// V2 Phase B: "Not this one today" before starting.
  final ReplacementReason? replace;

  /// V2 Phase B: a fixed activity recorded straight into the journal, for
  /// a history the engine would not produce on its own (V1-era entries).
  final ActivityId? seeded;

  /// The catalogue version a [seeded] entry was recorded under.
  final int catalogVersion;
}

/// The current catalogue version, under a name [QaScenarioDay]'s default can
/// reach past its own `catalogVersion` field.
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
  QaScenario.planInProgress => const [
    QaScenarioDay(-12, _head, attempt: _yes, usefulness: _somewhat),
    QaScenarioDay(-9, _gentle, attempt: _yes, usefulness: _very),
    QaScenarioDay(
      -7,
      _energy,
      activatePlan: PlanId.moreEnergyPath,
      attempt: _yes,
      usefulness: _somewhat,
    ),
    QaScenarioDay(-5, _energy, attempt: _aLittle, usefulness: _somewhat),
    QaScenarioDay(-2, _energy, attempt: _yes, usefulness: _very),
  ],
  QaScenario.monthTwo => const [
    // Cycle 1 of the Gentler Pace Path, completed.
    QaScenarioDay(
      -48,
      _gentle,
      activatePlan: PlanId.gentlerPacePath,
      attempt: _yes,
      usefulness: _somewhat,
    ),
    QaScenarioDay(-46, _head, attempt: _yes, usefulness: _somewhat),
    QaScenarioDay(-44, _gentle, attempt: _yes, usefulness: _very),
    QaScenarioDay(-40, _gentle, attempt: _notToday),
    QaScenarioDay(-36, _gentle, attempt: _aLittle, usefulness: _somewhat),
    QaScenarioDay(-33, _energy, attempt: _yes, usefulness: _somewhat),
    QaScenarioDay(-30, _gentle, attempt: _yes, usefulness: _very),
    QaScenarioDay(-27, _head, attempt: _yes, usefulness: _somewhat),
    // Cycle 2, begun again; stage 2 then deliberately revisited.
    QaScenarioDay(
      -24,
      _gentle,
      repeatCycle: PlanId.gentlerPacePath,
      attempt: _yes,
      usefulness: _very,
    ),
    QaScenarioDay(-21, _gentle, attempt: _yes, usefulness: _somewhat),
    QaScenarioDay(
      -19,
      _gentle,
      queueRevisit: true,
      attempt: _yes,
      usefulness: _very,
    ),
    QaScenarioDay(-16, _energy, attempt: _aLittle, usefulness: _somewhat),
    QaScenarioDay(
      -15,
      _gentle,
      queueRevisit: true,
      attempt: _yes,
      usefulness: _very,
    ),
    QaScenarioDay(
      -12,
      _gentle,
      queueRevisit: true,
      attempt: _aLittle,
      usefulness: _somewhat,
    ),
    QaScenarioDay(
      -8,
      _gentle,
      queueRevisit: true,
      attempt: _yes,
      usefulness: _very,
    ),
    QaScenarioDay(-6, _head, attempt: _yes, usefulness: _very),
    QaScenarioDay(
      -4,
      _gentle,
      queueRevisit: true,
      attempt: _yes,
      usefulness: _somewhat,
    ),
    QaScenarioDay(-2, _energy, attempt: _yes, usefulness: _somewhat),
  ],
  QaScenario.neverReflects => const [
    QaScenarioDay(-25, _energy),
    QaScenarioDay(-21, _energy),
    QaScenarioDay(-18, _head, activatePlan: PlanId.clearerHeadPath),
    QaScenarioDay(-16, _energy),
    QaScenarioDay(-13, _energy),
    QaScenarioDay(-11, _head),
    QaScenarioDay(-9, _energy),
    QaScenarioDay(-6, _energy),
    QaScenarioDay(-4, _head),
    QaScenarioDay(-2, _energy),
  ],
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
  QaScenario.lapsedRetainedSnapshots => const [
    QaScenarioDay(-40, _head, attempt: _yes, usefulness: _very),
    QaScenarioDay(-36, _head, attempt: _yes, usefulness: _somewhat),
    QaScenarioDay(
      -33,
      _energy,
      activatePlan: PlanId.moreEnergyPath,
      attempt: _yes,
      usefulness: _somewhat,
    ),
    QaScenarioDay(-30, _head, attempt: _aLittle, usefulness: _somewhat),
    QaScenarioDay(-27, _head, attempt: _yes, usefulness: _very),
    QaScenarioDay(-24, _energy, attempt: _yes, usefulness: _very),
    QaScenarioDay(-20, _head, attempt: _yes, usefulness: _somewhat),
    QaScenarioDay(-17, _head, attempt: _yes, usefulness: _very),
    QaScenarioDay(-13, _energy, attempt: _aLittle, usefulness: _somewhat),
    QaScenarioDay(-10, _head, attempt: _yes, usefulness: _somewhat),
    // The subscription has ended: Free continues, nothing paid runs.
    QaScenarioDay(
      -6,
      _energy,
      entitled: false,
      attempt: _yes,
      usefulness: _somewhat,
    ),
    QaScenarioDay(-3, _head, entitled: false, attempt: _yes),
    QaScenarioDay(-1, _gentle, entitled: false),
  ],
};

/// Runs one scripted day through the production notifiers, in a throwaway
/// container over [store], with the clock fixed to that day.
Future<void> _simulateDay(
  QaSharedPreferences store,
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
    final plans = container.read(planProvider.notifier);
    final circle = container.read(recommendationProvider.notifier);

    if (day.repeatCycle case final planId?) plans.repeatCycle(planId);
    if (day.activatePlan case final planId?) plans.activatePlan(planId);
    if (day.queueRevisit) plans.queueRevisit();
    await _settle();

    circle.chooseIntention(day.direction, window: day.window);
    await _settle();
    if (day.replace case final reason?) {
      circle.replaceToday(reason);
      await _settle();
    }

    clock = morning.add(const Duration(minutes: 2));
    circle.start();
    await _settle();
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

    // The tester looks at Insights that day; the production cadence and
    // entitlement gate decide whether anything is assessed.
    container.read(insightProvider.notifier).refreshIfDue();
    await _settle();
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
  QaSharedPreferences store,
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
