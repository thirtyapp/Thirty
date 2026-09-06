import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/coach/presentation/widgets/coach_cue_banner.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/plans/application/plan_provider.dart';
import 'package:thirty/features/plans/domain/plan_catalog.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/plans/domain/plan_state.dart';

final _today = DateTime(2026, 8, 10, 9);

Future<(Widget, ProviderContainer)> _wrap({
  required Widget Function(ProviderContainer container) childBuilder,
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
      home: Scaffold(body: childBuilder(container)),
    ),
  );
  return (widget, container);
}

void main() {
  testWidgets('renders nothing when no Plan is active', (tester) async {
    final (widget, container) = await _wrap(
      childBuilder: (_) => const CoachCueBanner(planId: PlanId.moreEnergyPath),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    expect(find.byType(CoachCueBanner), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('shows the ordinary stage explanation for a freshly '
      'activated Plan', (tester) async {
    final (widget, container) = await _wrap(
      childBuilder: (_) => const CoachCueBanner(planId: PlanId.moreEnergyPath),
    );
    addTearDown(container.dispose);
    container.read(planProvider.notifier).activatePlan(PlanId.moreEnergyPath);
    await tester.pumpWidget(widget);

    expect(find.textContaining('part of your path'), findsOneWidget);
  });

  testWidgets('suppressStageExplanation hides the stage-explanation cue '
      'but not other families', (tester) async {
    final (widget, container) = await _wrap(
      childBuilder: (_) => const CoachCueBanner(
        planId: PlanId.moreEnergyPath,
        suppressStageExplanation: true,
      ),
    );
    addTearDown(container.dispose);
    container.read(planProvider.notifier).activatePlan(PlanId.moreEnergyPath);
    await tester.pumpWidget(widget);

    expect(find.textContaining('part of your path'), findsNothing);
  });

  testWidgets('a completed cycle is never suppressed by '
      'suppressStageExplanation', (tester) async {
    final (widget, container) = await _wrap(
      childBuilder: (_) => const CoachCueBanner(
        planId: PlanId.moreEnergyPath,
        suppressStageExplanation: true,
      ),
    );
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
    await tester.pumpWidget(widget);

    expect(find.textContaining('finished'), findsOneWidget);
  });

  testWidgets('offers a bounded "try lighter guidance" and "queue a '
      'revisit" shortcut after a "not today" report on the prior matching '
      'Circle, and tapping the lighter shortcut applies the existing '
      'setPlanTreatment control without changing the activity',
      (tester) async {
    final priorStage = planDefinitionFor(PlanId.moreEnergyPath).stages[0];
    final (widget, container) = await _wrap(
      childBuilder: (_) => const CoachCueBanner(planId: PlanId.moreEnergyPath),
    );
    addTearDown(container.dispose);

    container.read(planProvider.notifier).activatePlan(PlanId.moreEnergyPath);
    // Advance the real forward cursor so lastEncounteredStageId is set,
    // matching the seeded journal entry below.
    container.read(planProvider.notifier).advanceCursorForCircle(
          PlanId.moreEnergyPath,
          '2026-08-09',
          isRevisit: false,
        );

    // Seed yesterday's journal record directly (1-day gap — no resumption
    // cue), reporting "not today" for the stage just advanced past.
    final journal = container.read(circleJournalRepositoryProvider);
    await journal.recordShown(
      circleId: '2026-08-09',
      localDate: '2026-08-09',
      direction: Intention.moreEnergy,
      activityId: priorStage.activityId,
      shownAt: DateTime(2026, 8, 9, 9),
      planId: PlanId.moreEnergyPath.name,
      planVersion: planContentVersion,
      stageId: priorStage.id,
      planCycleId: 'moreEnergyPath_cycle_1',
      treatmentUsed: 'standard',
      revisitUsed: false,
    );
    await journal.recordAttempt(
      circleId: '2026-08-09',
      localDate: '2026-08-09',
      direction: Intention.moreEnergy,
      activityId: priorStage.activityId,
      response: CircleAttemptResponse.notToday,
      respondedAt: DateTime(2026, 8, 9, 10),
      planId: PlanId.moreEnergyPath.name,
      planVersion: planContentVersion,
      stageId: priorStage.id,
      planCycleId: 'moreEnergyPath_cycle_1',
      treatmentUsed: 'standard',
      revisitUsed: false,
    );

    // Resolve today's (_today's) Session normally.
    container
        .read(recommendationProvider.notifier)
        .chooseIntention(Intention.moreEnergy);
    final activityIdBefore =
        container.read(recommendationProvider).recommendation!.activityId;

    await tester.pumpWidget(widget);

    expect(find.text('Try lighter guidance today'), findsOneWidget);
    expect(find.text('Queue a one-off revisit'), findsOneWidget);

    await tester.tap(find.text('Try lighter guidance today'));
    await tester.pump();

    expect(
      container.read(recommendationProvider).recommendation!.activityId,
      activityIdBefore,
    );
    expect(
      container.read(recommendationProvider).recommendation!.treatmentUsed,
      PlanTreatment.lighter,
    );
  });

  testWidgets('the lighter-pacing cue is announced through a Semantics '
      'container, not color/icon alone', (tester) async {
    final (widget, container) = await _wrap(
      childBuilder: (_) => const CoachCueBanner(planId: PlanId.moreEnergyPath),
    );
    addTearDown(container.dispose);
    container.read(planProvider.notifier).activatePlan(PlanId.moreEnergyPath);
    container
        .read(recommendationProvider.notifier)
        .chooseIntention(Intention.moreEnergy);
    container
        .read(recommendationProvider.notifier)
        .setPlanTreatment(PlanTreatment.lighter);
    await tester.pumpWidget(widget);

    expect(
      find.descendant(
        of: find.byType(CoachCueBanner),
        matching: find.byType(Semantics),
      ),
      findsWidgets,
    );
    expect(find.textContaining('lighter guidance'), findsWidgets);
  });
}
