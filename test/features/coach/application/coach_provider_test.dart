import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/coach/application/coach_provider.dart';
import 'package:thirty/features/coach/domain/coach_family.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/plans/application/plan_provider.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/plans/domain/plan_state.dart';

Future<ProviderContainer> _containerWith({
  Map<String, Object> storedPrefs = const {},
  required DateTime now,
  bool entitled = true,
}) async {
  SharedPreferences.setMockInitialValues(storedPrefs);
  final prefs = await SharedPreferences.getInstance();

  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(now),
      eventClockProvider.overrideWithValue(() => now),
      premiumEntitlementProvider.overrideWithValue(entitled),
    ],
  );
}

/// Reads back every SharedPreferences key/value written during a
/// container's lifetime, so a fresh container (a new "day") can be seeded
/// from it — mirrors `recommendation_provider_test.dart`'s own multi-day
/// simulation pattern.
Map<String, Object> _snapshot(SharedPreferences prefs) {
  final map = <String, Object>{};
  for (final key in prefs.getKeys()) {
    final value = prefs.get(key);
    if (value != null) map[key] = value;
  }
  return map;
}

void main() {
  group('coachCueProvider — gating', () {
    test('no cue when no Plan is active', () async {
      final container = await _containerWith(now: DateTime(2026, 8, 10, 9));
      addTearDown(container.dispose);

      expect(container.read(coachCueProvider(PlanId.moreEnergyPath)), isNull);
    });

    test('no cue for a Plan that is not the active one', () async {
      final container = await _containerWith(now: DateTime(2026, 8, 10, 9));
      addTearDown(container.dispose);
      container.read(planProvider.notifier).activatePlan(PlanId.clearerHeadPath);

      expect(container.read(coachCueProvider(PlanId.moreEnergyPath)), isNull);
    });

    test('a freshly activated Plan with no resolved Session yet shows the '
        'ordinary stage explanation for its upcoming stage', () async {
      final container = await _containerWith(now: DateTime(2026, 8, 10, 9));
      addTearDown(container.dispose);
      container.read(planProvider.notifier).activatePlan(PlanId.moreEnergyPath);

      final cue = container.read(coachCueProvider(PlanId.moreEnergyPath));
      expect(cue, isNotNull);
      expect(cue!.family, CoachFamily.stageExplanation);
    });
  });

  group('coachCueProvider — lighter default respected on resolution', () {
    test('a saved lighter default makes a freshly resolved Session '
        'explain itself as the saved default, not a new choice', () async {
      final day1 = DateTime(2026, 8, 10, 9);
      final container = await _containerWith(now: day1);
      addTearDown(container.dispose);
      final planNotifier = container.read(planProvider.notifier);
      planNotifier.activatePlan(PlanId.moreEnergyPath);
      planNotifier.setLighterDefaultForPlan(PlanId.moreEnergyPath, true);

      container
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy);

      final recommendation =
          container.read(recommendationProvider).recommendation!;
      expect(recommendation.treatmentUsed, PlanTreatment.lighter);
      expect(recommendation.treatmentSource, PlanTreatmentSource.savedPreference);

      final cue = container.read(coachCueProvider(PlanId.moreEnergyPath));
      expect(cue!.family, CoachFamily.lighterPacing);
      expect(cue.message, contains('saved default'));
    });

    test('a direct current-Session choice is distinguished from a saved '
        'default in the resulting cue', () async {
      final container = await _containerWith(now: DateTime(2026, 8, 10, 9));
      addTearDown(container.dispose);
      final planNotifier = container.read(planProvider.notifier);
      planNotifier.activatePlan(PlanId.moreEnergyPath);
      container
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy);

      container
          .read(recommendationProvider.notifier)
          .setPlanTreatment(PlanTreatment.lighter);

      final recommendation =
          container.read(recommendationProvider).recommendation!;
      expect(recommendation.treatmentSource, PlanTreatmentSource.directChoice);
      // The saved Plan-level default is untouched by a same-Session choice.
      expect(
        planNotifier.progressFor(PlanId.moreEnergyPath).lighterDefault,
        isFalse,
      );

      final cue = container.read(coachCueProvider(PlanId.moreEnergyPath));
      expect(cue!.family, CoachFamily.lighterPacing);
      expect(cue.message, contains('save it as'));
    });
  });

  group('coachCueProvider — cycle transition', () {
    test('a completed cycle shows the cycle-transition cue', () async {
      final container = await _containerWith(now: DateTime(2026, 8, 10, 9));
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);
      for (var i = 0; i < 5; i++) {
        notifier.advanceCursorForCircle(
          PlanId.moreEnergyPath,
          'circle-$i',
          isRevisit: false,
        );
      }

      final cue = container.read(coachCueProvider(PlanId.moreEnergyPath));
      expect(cue!.family, CoachFamily.cycleTransition);
    });
  });

  group('coachCueProvider — resumption after a gap (multi-day)', () {
    test('resolving a Session 7+ days after the last one shows the '
        'resumption cue', () async {
      final day1 = DateTime(2026, 8, 1, 9);
      final container1 = await _containerWith(now: day1);
      container1.read(planProvider.notifier).activatePlan(PlanId.moreEnergyPath);
      container1
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy);
      container1.read(recommendationProvider.notifier).start();
      container1.read(recommendationProvider.notifier).close();
      // Let fire-and-forget persistence complete before reading prefs back.
      await Future<void>.delayed(Duration.zero);
      final prefs = container1.read(sharedPreferencesProvider);
      final seed = _snapshot(prefs);
      container1.dispose();

      final day2 = DateTime(2026, 8, 9, 9); // 8 days later
      final container2 = await _containerWith(storedPrefs: seed, now: day2);
      addTearDown(container2.dispose);
      // A new day with no recommendation resolved yet for today.
      expect(container2.read(recommendationProvider).recommendation, isNull);

      final cue = container2.read(coachCueProvider(PlanId.moreEnergyPath));
      expect(cue!.family, CoachFamily.resumption);
    });
  });

  group('coachCueProvider — recent explicit feedback (multi-day)', () {
    test('a "not today" report on the prior Circle surfaces actionFeedback '
        'the next time this Plan is viewed', () async {
      final day1 = DateTime(2026, 8, 1, 9);
      final container1 = await _containerWith(now: day1);
      container1.read(planProvider.notifier).activatePlan(PlanId.moreEnergyPath);
      container1
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy);
      container1.read(recommendationProvider.notifier).start();
      container1.read(recommendationProvider.notifier).close();
      container1
          .read(recommendationProvider.notifier)
          .reportAttempt(CircleAttemptResponse.notToday);
      await Future<void>.delayed(Duration.zero);
      final seed = _snapshot(container1.read(sharedPreferencesProvider));
      container1.dispose();

      final day2 = DateTime(2026, 8, 2, 9); // 1 day later — no gap cue
      final container2 = await _containerWith(storedPrefs: seed, now: day2);
      addTearDown(container2.dispose);

      final cue = container2.read(coachCueProvider(PlanId.moreEnergyPath));
      expect(cue!.family, CoachFamily.actionFeedback);
      expect(cue.offersLighterAction, isTrue);
      expect(cue.offersRevisitAction, isTrue);
    });

    test('no answer at all on the prior Circle never triggers '
        'actionFeedback (UNKNOWN, not a negative)', () async {
      final day1 = DateTime(2026, 8, 1, 9);
      final container1 = await _containerWith(now: day1);
      container1.read(planProvider.notifier).activatePlan(PlanId.moreEnergyPath);
      container1
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy);
      container1.read(recommendationProvider.notifier).start();
      container1.read(recommendationProvider.notifier).close();
      // No reportAttempt call at all.
      await Future<void>.delayed(Duration.zero);
      final seed = _snapshot(container1.read(sharedPreferencesProvider));
      container1.dispose();

      final day2 = DateTime(2026, 8, 2, 9);
      final container2 = await _containerWith(storedPrefs: seed, now: day2);
      addTearDown(container2.dispose);

      final cue = container2.read(coachCueProvider(PlanId.moreEnergyPath));
      expect(cue!.family, isNot(CoachFamily.actionFeedback));
    });
  });
}
