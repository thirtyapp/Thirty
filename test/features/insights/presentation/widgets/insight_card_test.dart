import 'dart:convert';

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
import 'package:thirty/features/insights/domain/insight_snapshot.dart';
import 'package:thirty/features/insights/presentation/widgets/insight_card.dart';
import 'package:thirty/features/plans/application/plan_provider.dart';
import 'package:thirty/features/plans/domain/plan_catalog.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/plans/domain/plan_state.dart';

final _today = DateTime(2026, 9, 6);

/// Hosts a plain `MaterialApp` (no `GoRouter`) — matching
/// `settings_page_test.dart`'s and `plan_path_page_test.dart`'s own
/// convention of verifying a `context.push`-driven button's
/// presence/label without tapping it. Real end-to-end navigation to
/// `/premium` is covered separately in `app_router_test.dart` against the
/// real app; a local `GoRouter` here previously caused `pumpAndSettle` to
/// hang indefinitely and was removed.
Future<(Widget, ProviderContainer)> _wrap({
  Map<String, Object> storedPrefs = const {},
  bool entitled = true,
}) async {
  SharedPreferences.setMockInitialValues(storedPrefs);
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_today),
      eventClockProvider.overrideWithValue(() => _today),
      premiumEntitlementProvider.overrideWithValue(entitled),
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
    expect(find.text('Dismiss'), findsNothing);
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

      expect(find.textContaining("Gentler Pace's Plan"), findsOneWidget);
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

  testWidgets('shows the chosen-pacing observation with a truthful usefulness '
      'sentence, and applying sets the Plan default', (tester) async {
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
      container
          .read(planProvider)
          .progress[PlanId.clearerHeadPath]!
          .lighterDefault,
      isTrue,
    );
    expect(find.text('Dismiss'), findsNothing);
  });

  testWidgets('the observation is wrapped in a semantics container', (
    tester,
  ) async {
    final (widget, container) = await _wrap();
    addTearDown(container.dispose);
    final notifier = container.read(planProvider.notifier);
    notifier.activatePlan(PlanId.gentlerPacePath);
    notifier.advanceCursorForCircle(
      PlanId.gentlerPacePath,
      'c1',
      isRevisit: false,
    );
    notifier.activatePlan(PlanId.moreEnergyPath);
    container.read(insightProvider.notifier).refreshIfDue();

    await tester.pumpWidget(widget);

    final semantics = tester.getSemantics(find.byType(InsightCard));
    expect(semantics, isNotNull);
  });

  group('Batch A — entitlement boundary', () {
    testWidgets(
      'a never-subscribed unentitled user with no retained snapshot sees '
      'nothing (no Insight was ever computed to read)',
      (tester) async {
        final (widget, container) = await _wrap(entitled: false);
        addTearDown(container.dispose);

        await tester.pumpWidget(widget);

        expect(find.byType(InsightCard), findsOneWidget);
        expect(find.text('Dismiss'), findsNothing);
      },
    );

    testWidgets('a retained snapshot (as if generated while entitled, before '
        'entitlement was lost) stays fully readable, but Apply is replaced '
        'with a route to the existing Premium offer instead of silently '
        'applying — state seeded directly rather than round-tripped through '
        'a live entitled container, since building two separate widget '
        'trees/ProviderContainers within one testWidgets test was found to '
        'hang tester.pumpWidget indefinitely', (tester) async {
      final (widget, container) = await _wrap(
        entitled: false,
        storedPrefs: {
          plansStateKey: jsonEncode({
            'schemaVersion': plansStateSchemaVersion,
            'activePlanId': PlanId.moreEnergyPath.name,
            'progress': {
              for (final id in PlanId.values)
                id.name: {
                  'planId': id.name,
                  'contentVersion': planContentVersion,
                  'cycleId': '${id.name}_cycle_1',
                  'cycleStartedAt': _today.toIso8601String(),
                  'forwardCursor': id == PlanId.gentlerPacePath ? 1 : 0,
                  'lastEncounteredStageId': id == PlanId.gentlerPacePath
                      ? stageAt(PlanId.gentlerPacePath, 0).id
                      : null,
                  'pendingRevisit': false,
                  'status': PlanCycleStatus.inProgress.name,
                  'cycleHistory': <Object?>[],
                  'lastAdvancedCircleId': null,
                },
            },
          }),
          insightSnapshotsKey: jsonEncode({
            'schemaVersion': insightSnapshotsSchemaVersion,
            'lastAssessedAt': _today.toIso8601String(),
            'snapshots': [
              {
                'id': 'a',
                'family': 'directionPathContinuity',
                'applicationType': 'activateOrResumePlan',
                'targetPlanId': 'gentlerPacePath',
                'targetStageId': null,
                'isPatternClaim': false,
                'evidenceCount': 1,
                'evidenceDateKeys': <String>[],
                'usefulnessNumerator': null,
                'usefulnessDenominator': null,
                'generatedAt': _today.toIso8601String(),
                'ruleVersion': insightRuleVersion,
                'templateVersion': insightTemplateVersion,
              },
            ],
          }),
        },
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(widget);

      // The observation itself is still readable — this is retained
      // history, not new computation.
      expect(find.textContaining("Gentler Pace's Plan"), findsOneWidget);
      // But the applying action is gone — replaced with a route to the
      // existing Premium offer, never a button that would silently
      // no-op against `InsightNotifier.applyCurrent()`'s own guard.
      expect(find.text('Resume this Plan'), findsNothing);
      expect(find.text('Become Premium to apply this'), findsOneWidget);
    });
  });
}
