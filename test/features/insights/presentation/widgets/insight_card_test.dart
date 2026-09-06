import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/insights/application/insight_provider.dart';
import 'package:thirty/features/insights/presentation/widgets/insight_card.dart';
import 'package:thirty/features/plans/application/plan_provider.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';

final _today = DateTime(2026, 9, 6);

Future<(Widget, ProviderContainer)> _wrap({
  Map<String, Object> storedPrefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(storedPrefs);
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_today),
      eventClockProvider.overrideWithValue(() => _today),
      premiumEntitlementProvider.overrideWithValue(true),
    ],
  );
  final widget = UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: InsightCard()),
    ),
  );
  return (widget, container);
}

void main() {
  testWidgets('renders nothing when there is no eligible Insight', (
    tester,
  ) async {
    final (widget, container) = await _wrap();
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    expect(find.byType(InsightCard), findsOneWidget);
    expect(find.text('Insight'), findsNothing);
  });

  testWidgets(
    'shows a plain current-place fact for an inactive, previously engaged '
    'Plan, and Resume activates it',
    (tester) async {
      final (widget, container) = await _wrap();
      addTearDown(container.dispose);
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.gentlerPacePath);
      for (var i = 0; i < 2; i++) {
        notifier.advanceCursorForCircle(
          PlanId.gentlerPacePath,
          'circle-$i',
          isRevisit: false,
        );
      }
      notifier.activatePlan(PlanId.moreEnergyPath); // switch away
      container.read(insightProvider.notifier).refreshIfDue();

      await tester.pumpWidget(widget);

      expect(find.textContaining('Gentler Pace'), findsOneWidget);
      expect(find.textContaining('stage 3 of 5'), findsOneWidget);
      expect(find.text('Resume this Plan'), findsOneWidget);

      await tester.tap(find.text('Resume this Plan'));
      await tester.pump();

      expect(container.read(planProvider).activePlanId, PlanId.gentlerPacePath);
      // The application is now already in effect — the card withdraws
      // itself rather than offering the same "discovery" again.
      expect(find.text('Resume this Plan'), findsNothing);
    },
  );

  testWidgets(
    'shows the chosen-pacing observation with a truthful usefulness '
    'sentence, and applying sets the Plan default',
    (tester) async {
      final (widget, container) = await _wrap();
      addTearDown(container.dispose);
      container.read(planProvider.notifier).activatePlan(PlanId.clearerHeadPath);
      final journal = container.read(circleJournalRepositoryProvider);
      final dates = [
        '2026-08-20',
        '2026-08-23',
        '2026-08-27',
        '2026-09-01',
        '2026-09-05',
      ];
      for (var i = 0; i < dates.length; i++) {
        await journal.recordShown(
          circleId: dates[i],
          localDate: dates[i],
          direction: Intention.clearerHead,
          activityId: ActivityId.phoneFreeWalk,
          shownAt: DateTime.parse(dates[i]),
          planId: PlanId.clearerHeadPath.name,
          planVersion: 1,
          stageId: 'stage',
          planCycleId: 'cycle',
          treatmentUsed: 'lighter',
          treatmentSource: 'directChoice',
        );
        // Only 3 of the 5 carry a rating — the truthful denominator.
        if (i < 3) {
          await journal.recordAttempt(
            circleId: dates[i],
            localDate: dates[i],
            direction: Intention.clearerHead,
            activityId: ActivityId.phoneFreeWalk,
            response: CircleAttemptResponse.yes,
            respondedAt: DateTime.parse(dates[i]),
          );
          await journal.recordUsefulness(
            circleId: dates[i],
            localDate: dates[i],
            direction: Intention.clearerHead,
            activityId: ActivityId.phoneFreeWalk,
            response: i == 0
                ? CircleUsefulnessResponse.veryUseful
                : CircleUsefulnessResponse.notUseful,
            respondedAt: DateTime.parse(dates[i]),
          );
        }
      }
      container.read(insightProvider.notifier).refreshIfDue();

      await tester.pumpWidget(widget);

      expect(
        find.textContaining('chose lighter guidance on 5 recent Plan Circles'),
        findsOneWidget,
      );
      expect(
        find.textContaining('On the 3 you rated, you reported it useful 1 time.'),
        findsOneWidget,
      );
      // Never a causal or health claim.
      expect(find.textContaining('works better'), findsNothing);
      expect(find.textContaining('caused'), findsNothing);

      await tester.tap(find.text('Use lighter guidance as this Plan\'s default'));
      await tester.pump();

      expect(
        container.read(planProvider).progress[PlanId.clearerHeadPath]!.lighterDefault,
        isTrue,
      );
      expect(find.text('Insight'), findsNothing);
    },
  );

  testWidgets('the observation is wrapped in a semantics container', (
    tester,
  ) async {
    final (widget, container) = await _wrap();
    addTearDown(container.dispose);
    final notifier = container.read(planProvider.notifier);
    notifier.activatePlan(PlanId.gentlerPacePath);
    notifier.advanceCursorForCircle(PlanId.gentlerPacePath, 'c1', isRevisit: false);
    notifier.activatePlan(PlanId.moreEnergyPath);
    container.read(insightProvider.notifier).refreshIfDue();

    await tester.pumpWidget(widget);

    final semantics = tester.getSemantics(find.byType(InsightCard));
    expect(semantics, isNotNull);
  });
}
