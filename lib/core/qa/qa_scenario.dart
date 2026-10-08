import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/home/application/activity_catalog.dart' show Intention;
import '../../features/home/application/circle_journal.dart';
import '../../features/home/application/recommendation_provider.dart';
import '../../features/insights/application/insight_provider.dart';
import '../../features/plans/application/plan_provider.dart';
import '../../features/plans/domain/plan_ids.dart';
import '../../features/settings/application/first_name_provider.dart';
import '../analytics/analytics_service.dart';
import '../premium/premium_access.dart';
import '../providers/clock_provider.dart';
import '../providers/shared_preferences_provider.dart';
import '../providers/theme_mode_provider.dart';
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
  );

  const QaScenario(this.wireName, this.label);

  final String wireName;
  final String label;

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
  return store;
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
}

const _yes = CircleAttemptResponse.yes;
const _aLittle = CircleAttemptResponse.aLittle;
const _notToday = CircleAttemptResponse.notToday;
const _very = CircleUsefulnessResponse.veryUseful;
const _somewhat = CircleUsefulnessResponse.somewhatUseful;

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
  var clock = morning;
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(store),
      nowProvider.overrideWithValue(morning),
      eventClockProvider.overrideWithValue(() => clock),
      premiumEntitlementProvider.overrideWithValue(day.entitled),
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

    circle.chooseIntention(day.direction);
    await _settle();

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
