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
import '../../features/settings/application/first_name_provider.dart';
import '../../features/toolkit/application/toolkit_provider.dart';
import '../../features/toolkit/domain/maintenance.dart';
import '../../features/toolkit/domain/path_catalog.dart';
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

  // V2 Phase D (Premium) — Paths, the Toolkit and maintenance, A–N.

  /// Two weeks of Free history, Move to music found very useful: the
  /// Toolkit's first Path is seeded from it.
  dFirstPath('d_first_path', 'D-A · First Path, seeded'),

  /// A lift at home, two Circles in; today's More Energy Circle is its
  /// Circle 3, which keeps the piece found useful.
  dPathUnderWay('d_path_under_way', 'D-C · Path under way'),

  /// A lift at home at Circle 5, after Circle 4 was "Not useful".
  dPathAdapted('d_path_adapted', 'D-D · Path adapted'),

  /// A lift at home, all seven Circles: its review is waiting.
  dPathReview('d_path_review', 'D-F · Path review'),

  /// The first routine, kept.
  dRoutineSaved('d_routine_saved', 'D-G · First routine saved'),

  /// The routine has evidence; a More Energy day picks it.
  dRoutineDailyPick('d_routine_daily_pick', 'D-H · Routine as today’s pick'),

  /// The same, but Move to music — a piece of the routine — was "Not
  /// useful" six days ago: it is resting, so today is not the routine.
  dRoutinePieceResting(
    'd_routine_piece_resting',
    'D-H2 · Routine piece resting',
  ),

  /// The same rest, lifted yesterday with "Suggest again": the routine is
  /// eligible again.
  dRoutineRestLifted('d_routine_rest_lifted', 'D-H3 · Routine rest lifted'),

  /// Week 7: a 30-minute reset built on days with up to 30 minutes (its
  /// shorter form turned down then), and about 20 minutes most Clearer Head
  /// days lately.
  dWeek7TimeMisfit('d_week7_time_misfit', 'D-I · Week 7, less time'),

  /// A routine that used to suit, suiting less well lately.
  dFading('d_fading', 'D-J · Fading routine'),

  /// Its tune-up, two Circles in.
  dTuneUpUnderWay('d_tune_up_under_way', 'D-J2 · Tune-up under way'),

  /// Its tune-up, finished: version 2 waits for review.
  dTuneUpReview('d_tune_up_review', 'D-J3 · Tune-up review'),

  /// Four weeks of steady answers: the Toolkit check says so.
  dStableCheck('d_stable_check', 'D-K · Stable check'),

  /// Premium ended with a routine and a second Path under way.
  dLapsed('d_lapsed', 'D-L · Lapsed, routine and Path kept'),

  /// Month two: two routines — one from a gap — a shorter version, and
  /// ordinary use.
  dMonthTwo('d_month_two', 'D-M · Month two'),

  /// Clearer Head chosen often, Free's picks for it rated weak, and no
  /// routine for it.
  dGap('d_gap', 'D-N · Gap'),

  /// Clearer Head chosen just as often, but Free's picks for it rated
  /// "Somewhat useful" every time: Free serves it — no gap offer.
  dServedWell('d_served_well', 'D-N2 · Served well, no gap');

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
      this == QaScenario.dLapsed ? QaEntitlement.inactive : null;
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
/// device. Never history, the Toolkit, reminder or analytics state.
const qaCarriedPreferenceKeys = {themeModeKey, firstNameKey};

/// Builds [scenario]'s isolated store.
///
/// [genuine] is only read. Synthetic history is written into the returned
/// [QaSharedPreferences] alone, by running the production Circle and
/// Toolkit notifiers through the scenario's scripted days, each relative
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
  QaScenario.dRoutineRestLifted => [
    (
      activity: ActivityId.moveToMusic,
      need: _energy,
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
/// One scripted local day: the need chosen, the time, the answers — and,
/// V2 Phase D, what the user did in the Toolkit that day.
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
    this.startPath,
    this.acceptOffer = false,
    this.declineOffer = false,
    this.keepProposal = false,
    this.keepName,
    this.seeCheck = false,
    this.routine,
    this.shortVersion = false,
    this.noCircle = false,
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

  /// V2 Phase D: start this Path before the day's Circle.
  final PathTemplateId? startPath;

  /// V2 Phase D: accept — or decline — the Toolkit's one maintenance offer
  /// before the day's Circle.
  final bool acceptOffer;
  final bool declineOffer;

  /// V2 Phase D: after the day's Circle, keep what a finished Path proposes
  /// (named [keepName]).
  final bool keepProposal;
  final String? keepName;

  /// V2 Phase D: see the Toolkit check.
  final bool seeCheck;

  /// V2 Phase D: write a Circle of the user's routine number [routine]
  /// (oldest first) straight into the journal — its [shortVersion] if
  /// asked — instead of running the engine.
  final int? routine;
  final bool shortVersion;

  /// V2 Phase D: Toolkit actions only — no Circle that day.
  final bool noCircle;
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
  QaScenario.dFirstPath => _freeHistory(-14),
  QaScenario.dPathUnderWay => [
    ..._freeHistory(-20),
    ..._wakeUpBuild(-6, const [_very, _somewhat], window: _t10),
    const QaScenarioDay(-2, _head, attempt: _yes, usefulness: _somewhat),
  ],
  QaScenario.dPathAdapted => [
    ..._freeHistory(-26),
    ..._wakeUpBuild(-12, const [_very, _somewhat, _very, _not]),
    const QaScenarioDay(-2, _head, attempt: _yes, usefulness: _somewhat),
  ],
  QaScenario.dPathReview => [
    ..._freeHistory(-30),
    ..._wakeUpBuild(-16, _buildAnswers),
  ],
  QaScenario.dRoutineSaved => [
    ..._freeHistory(-30),
    ..._wakeUpBuild(-16, _buildAnswers, keep: true),
  ],
  QaScenario.dRoutineDailyPick => _routineDays(musicAnswer: _somewhat),
  QaScenario.dRoutinePieceResting ||
  QaScenario.dRoutineRestLifted => _routineDays(musicAnswer: _not),
  QaScenario.dWeek7TimeMisfit => [
    ..._freeHistory(-70),
    // Weeks 1–2: Clear the decks on days with up to 30 minutes builds a
    // 30-minute reset. Its shorter form (Circle 6) was "Not useful" then —
    // there was time enough — so the routine has no shorter version.
    ..._build(
      PathTemplateId.clearTheDecks,
      _head,
      -56,
      const [_very, _somewhat, _very, _very, _very, _not, _very],
      window: TimeWindow.upTo30,
      keep: true,
    ),
    // Weeks 3–5: used on Clearer Head days with up to 30 minutes.
    for (final (offset, answer) in const [
      (-38, _very),
      (-34, _somewhat),
      (-30, _very),
      (-26, _somewhat),
      (-22, _very),
    ])
      QaScenarioDay(
        offset,
        _head,
        routine: 0,
        window: TimeWindow.upTo30,
        attempt: _yes,
        usefulness: answer,
      ),
    // Weeks 6–7: about 20 minutes, most Clearer Head days.
    for (final offset in const [-12, -9, -6, -4, -2])
      QaScenarioDay(
        offset,
        _head,
        window: TimeWindow.about20,
        attempt: _yes,
        usefulness: _somewhat,
      ),
  ],
  QaScenario.dFading => [..._fadingHistory()],
  QaScenario.dTuneUpUnderWay => [
    ..._fadingHistory(),
    const QaScenarioDay(-8, _energy, noCircle: true, acceptOffer: true),
    const QaScenarioDay(
      -6,
      _energy,
      window: TimeWindow.upTo30,
      attempt: _yes,
      usefulness: _very,
    ),
    const QaScenarioDay(
      -4,
      _energy,
      window: TimeWindow.upTo30,
      attempt: _yes,
      usefulness: _somewhat,
    ),
  ],
  QaScenario.dTuneUpReview => [
    ..._fadingHistory(),
    const QaScenarioDay(-8, _energy, noCircle: true, acceptOffer: true),
    for (final (offset, answer) in const [
      (-6, _very),
      (-4, _somewhat),
      (-2, _very),
    ])
      QaScenarioDay(
        offset,
        _energy,
        window: TimeWindow.upTo30,
        attempt: _yes,
        usefulness: answer,
      ),
  ],
  QaScenario.dStableCheck => [
    ..._freeHistory(-74),
    ..._wakeUpBuild(-60, _buildAnswers, keep: true),
    for (var offset = -44; offset <= -4; offset += 4)
      QaScenarioDay(
        offset,
        _energy,
        routine: 0,
        window: TimeWindow.about20,
        attempt: _yes,
        usefulness: offset % 8 == 0 ? _very : _somewhat,
      ),
  ],
  QaScenario.dLapsed => [
    ..._freeHistory(-60),
    ..._wakeUpBuild(-46, _buildAnswers, keep: true),
    const QaScenarioDay(
      -20,
      _head,
      startPath: PathTemplateId.clearTheDecks,
      window: TimeWindow.upTo30,
      attempt: _yes,
      usefulness: _very,
    ),
    const QaScenarioDay(
      -18,
      _head,
      window: TimeWindow.upTo30,
      attempt: _yes,
      usefulness: _somewhat,
    ),
    // Premium ends: Free goes on, the Path waits.
    const QaScenarioDay(
      -10,
      _head,
      entitled: false,
      attempt: _yes,
      usefulness: _somewhat,
    ),
    const QaScenarioDay(
      -6,
      _energy,
      entitled: false,
      routine: 0,
      window: TimeWindow.about20,
      attempt: _yes,
      usefulness: _very,
    ),
    const QaScenarioDay(-3, _gentle, entitled: false),
  ],
  QaScenario.dMonthTwo => _monthTwo(),
  // Free's Clearer Head picks rated mostly "Not useful": a real gap.
  QaScenario.dGap => _gapHistory(const [
    _not,
    _somewhat,
    _not,
    _not,
    _somewhat,
    _not,
  ]),
  // The same days, every pick "Somewhat useful": Free serves it.
  QaScenario.dServedWell => _gapHistory(const [
    _somewhat,
    _somewhat,
    _somewhat,
    _somewhat,
    _somewhat,
    _somewhat,
  ]),
};

/// A pick-me-up built and kept, then ordinary More Energy days: something
/// new, then Move to music (answered [musicAnswer]), then the stretch — so
/// today, on any date, the routine (found useful as it was built) is the
/// one pick that is ready again, and nothing new is due.
List<QaScenarioDay> _routineDays({
  required CircleUsefulnessResponse musicAnswer,
}) => [
  ..._freeHistory(-38),
  ..._wakeUpBuild(-24, _buildAnswers, keep: true),
  const QaScenarioDay(
    -9,
    _energy,
    seeded: ActivityId.thirtyMinuteWalk,
    window: TimeWindow.about20,
  ),
  QaScenarioDay(
    -6,
    _energy,
    seeded: ActivityId.moveToMusic,
    window: TimeWindow.about20,
    attempt: _yes,
    usefulness: musicAnswer,
  ),
  const QaScenarioDay(
    -3,
    _energy,
    seeded: ActivityId.energisingStretchFlow,
    window: TimeWindow.about20,
    attempt: _yes,
    usefulness: _somewhat,
  ),
  const QaScenarioDay(-2, _head, attempt: _yes, usefulness: _somewhat),
];

/// A pick-me-up built and kept, then Clearer Head chosen six times in four
/// weeks with about 20 minutes, Free's picks answered [answers].
List<QaScenarioDay> _gapHistory(List<CircleUsefulnessResponse> answers) => [
  ..._freeHistory(-60),
  ..._wakeUpBuild(-46, _buildAnswers, keep: true),
  for (final (index, offset) in const [-26, -21, -16, -12, -8, -4].indexed)
    QaScenarioDay(
      offset,
      _head,
      // Free's own picks for Clearer Head, outside the Paths' pieces.
      seeded: index.isEven
          ? ActivityId.quietReading
          : ActivityId.singleTaskFocus,
      window: TimeWindow.about20,
      attempt: _yes,
      usefulness: answers[index],
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

/// The answers a whole A lift at home build gets in these scenarios.
const _buildAnswers = [_very, _somewhat, _very, _very, _very, _somewhat, _very];

/// A lift at home from [start] (see [_build]).
List<QaScenarioDay> _wakeUpBuild(
  int start,
  List<CircleUsefulnessResponse?> answers, {
  TimeWindow window = TimeWindow.about20,
  bool keep = false,
}) => _build(
  PathTemplateId.wakeUpIndoors,
  _energy,
  start,
  answers,
  window: window,
  keep: keep,
);

/// A wake-up routine that used to suit and lately suits less well.
List<QaScenarioDay> _fadingHistory() => [
  ..._freeHistory(-70),
  ..._wakeUpBuild(-56, _buildAnswers, keep: true),
  for (final (offset, answer) in const [
    (-40, _very),
    (-36, _very),
    (-30, _somewhat),
    (-24, _somewhat),
    (-18, _not),
    (-12, _somewhat),
  ])
    QaScenarioDay(
      offset,
      _energy,
      routine: 0,
      window: TimeWindow.about20,
      attempt: _yes,
      usefulness: answer,
    ),
];

/// Month two: a wake-up routine built in weeks one and two; a Clearer Head
/// reset built from a gap in weeks four and five; a 10-minute version of
/// the reset for busier days in week seven; ordinary use since — and no new
/// content anywhere.
List<QaScenarioDay> _monthTwo() => [
  ..._freeHistory(-84),
  ..._wakeUpBuild(-70, _buildAnswers, keep: true),
  // Weeks 3–4: Clearer Head often, with about 20 minutes, Free's picks
  // for it mostly "Not useful" — and the pick-me-up in use.
  for (final (offset, activity, answer) in const [
    (-55, ActivityId.quietReading, _not),
    (-50, ActivityId.singleTaskFocus, _somewhat),
    (-46, ActivityId.singleTaskFocus, _not),
    (-42, ActivityId.quietReading, _not),
    (-38, ActivityId.singleTaskFocus, _somewhat),
  ])
    QaScenarioDay(
      offset,
      _head,
      seeded: activity,
      window: TimeWindow.about20,
      attempt: _yes,
      usefulness: answer,
    ),
  for (final (offset, answer) in const [(-53, _very), (-48, _somewhat)])
    QaScenarioDay(
      offset,
      _energy,
      routine: 0,
      window: TimeWindow.about20,
      attempt: _yes,
      usefulness: answer,
    ),
  // The gap offer — Clear the decks — accepted, and built.
  const QaScenarioDay(-36, _head, noCircle: true, acceptOffer: true),
  for (final (index, answer) in const [
    _very,
    _somewhat,
    _very,
    _very,
    _somewhat,
    _not,
    _very,
  ].indexed)
    QaScenarioDay(
      -35 + index * 2,
      _head,
      window: TimeWindow.upTo30,
      attempt: _yes,
      usefulness: answer,
      keepProposal: index == 6,
      keepName: 'My desk reset',
    ),
  // Weeks 6–7: Clearer Head days with about 20 minutes.
  for (final offset in const [-20, -18, -16, -14])
    QaScenarioDay(
      offset,
      _head,
      window: TimeWindow.about20,
      attempt: _yes,
      usefulness: _somewhat,
    ),
  // The time-misfit offer accepted: three Circles of a 20-minute version —
  // both pieces, each short.
  const QaScenarioDay(-13, _head, noCircle: true, acceptOffer: true),
  for (final (index, answer) in const [_very, _somewhat, _very].indexed)
    QaScenarioDay(
      -12 + index * 2,
      _head,
      window: TimeWindow.about20,
      attempt: _yes,
      usefulness: answer,
      keepProposal: index == 2,
    ),
  // Since then: ordinary days, both routines in use.
  for (final (offset, need, routine, short, window) in const [
    (-5, _energy, 0, false, TimeWindow.about20),
    (-4, _head, 1, true, TimeWindow.about20),
    (-2, _energy, 0, true, _t10),
  ])
    QaScenarioDay(
      offset,
      need,
      routine: routine,
      shortVersion: short,
      window: window,
      attempt: _yes,
      usefulness: _somewhat,
    ),
];

/// A whole build of [template] from [start], every other day — each a
/// [need] Circle the Path claims. [keep] keeps the routine after the last.
List<QaScenarioDay> _build(
  PathTemplateId template,
  Intention need,
  int start,
  List<CircleUsefulnessResponse?> answers, {
  TimeWindow window = TimeWindow.about20,
  bool keep = false,
}) => [
  for (final (index, answer) in answers.indexed)
    QaScenarioDay(
      start + index * 2,
      need,
      startPath: index == 0 ? template : null,
      window: window,
      attempt: answer == null ? null : _yes,
      usefulness: answer,
      keepProposal: keep && index == answers.length - 1,
    ),
];

/// Runs one scripted day through the production notifiers, in a throwaway
/// container over [store], with the clock fixed to that day: the Toolkit
/// actions first, then the day's Circle (chosen by the real engine — or a
/// Path step, which claims it on its own), its answers, and then keeping a
/// finished Path. A [QaScenarioDay.seeded] or [QaScenarioDay.routine] day
/// writes its Circle straight into the journal instead.
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
  if (day.routine case final index?) {
    await _seedRoutineEntry(store, morning, day, index);
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
    final toolkit = container.read(toolkitProvider.notifier);
    final circle = container.read(recommendationProvider.notifier);

    if (day.startPath case final template?) toolkit.startBuild(template);
    final offer = container.read(primaryOfferProvider);
    if (day.acceptOffer && offer != null) {
      switch (offer.kind) {
        case OfferKind.gap:
          toolkit.startBuild(offer.template!);
        case OfferKind.timeMisfit:
          toolkit.startShorter(offer.routine!.id, offer.targetMinutes!);
        case OfferKind.fading:
          toolkit.startTuneUp(offer.routine!.id);
      }
    }
    if (day.declineOffer && offer != null) toolkit.declineOffer(offer.key);
    if (day.seeCheck) toolkit.seeCheck();
    await _settle();

    if (!day.noCircle) {
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
    }

    if (day.keepProposal &&
        (container.read(toolkitProvider).path?.finished ?? false)) {
      toolkit.keepProposal(name: day.keepName);
      await _settle();
    }
  } finally {
    container.dispose();
  }
}

/// A Circle of the user's routine number [index] — its active version, or
/// its shorter one — written straight into [store]'s journal for [day], as
/// the production notifier would have recorded it.
Future<void> _seedRoutineEntry(
  SharedPreferences store,
  DateTime morning,
  QaScenarioDay day,
  int index,
) async {
  final routines = ToolkitRepository(store).read().routines;
  if (index >= routines.length) return;
  final routine = routines[index];
  final version = day.shortVersion
      ? (routine.shortVersion ?? routine.active)
      : routine.active;
  final date = dateKey(morning);
  final entries = CircleJournalRepository(store).readAll()
    ..add(
      CircleJournalEntry(
        schemaVersion: circleJournalSchemaVersion,
        circleId: date,
        localDate: date,
        direction: day.direction,
        activityId: version.composition.anchor,
        catalogVersion: catalogVersion,
        shownAt: morning,
        startedAt: morning.add(const Duration(minutes: 2)),
        closedAt: morning.add(Duration(minutes: 2 + version.minutes)),
        attemptResponse: day.attempt,
        usefulnessResponse: day.usefulness,
        timeWindow: day.window?.name,
        offeredMinutes: version.minutes,
        reasonCode: RecommendationReason.bestFit.name,
        minutesAtClose: version.minutes,
        session: CircleSessionRecord(
          title: routine.name,
          modules: version.composition.toWire(),
          routineId: routine.id,
          routineVersionId: version.id,
          routineVersionNumber: version.number,
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
