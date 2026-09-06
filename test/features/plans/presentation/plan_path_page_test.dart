import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/insights/application/insight_provider.dart';
import 'package:thirty/features/insights/presentation/widgets/insight_card.dart';
import 'package:thirty/features/plans/application/plan_provider.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/plans/domain/plan_state.dart';
import 'package:thirty/features/plans/presentation/plan_path_page.dart';

final _today = DateTime(2026, 8, 2);

Future<(Widget, ProviderContainer)> _wrap() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_today),
      eventClockProvider.overrideWithValue(() => _today),
    ],
  );
  final widget = UncontrolledProviderScope(
    container: container,
    child: MaterialApp(theme: AppTheme.light, home: const PlanPathPage()),
  );
  return (widget, container);
}

void main() {
  testWidgets('lists all three Plans by name', (tester) async {
    final (widget, container) = await _wrap();
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    expect(find.text('More Energy Path'), findsOneWidget);
    expect(find.text('Clearer Head Path'), findsOneWidget);
    expect(find.text('Gentler Pace Path'), findsOneWidget);
  });

  testWidgets('an inactive, never-started Plan shows Activate', (
    tester,
  ) async {
    final (widget, container) = await _wrap();
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    expect(find.text('Activate'), findsNWidgets(3));
  });

  testWidgets('tapping Activate makes that Plan active and shows an '
      '"Active" label', (tester) async {
    final (widget, container) = await _wrap();
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    await tester.tap(find.text('Activate').first);
    await tester.pump();

    expect(container.read(planProvider).activePlanId, isNotNull);
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets(
    'a completed cycle shows the plain finished-cycle state and a Repeat '
    'action, never an automatic restart',
    (tester) async {
      final (widget, container) = await _wrap();
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

      expect(find.text('This guided cycle is finished.'), findsOneWidget);
      expect(find.text('Repeat this cycle'), findsOneWidget);
      expect(
        notifier.progressFor(PlanId.moreEnergyPath).status,
        PlanCycleStatus.completed,
      );
    },
  );

  testWidgets('tapping Repeat this cycle starts a new cycle', (
    tester,
  ) async {
    final (widget, container) = await _wrap();
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

    await tester.tap(find.text('Repeat this cycle'));
    await tester.pump();

    expect(
      notifier.progressFor(PlanId.moreEnergyPath).status,
      PlanCycleStatus.inProgress,
    );
    expect(find.text('This guided cycle is finished.'), findsNothing);
  });

  testWidgets('an active, in-progress Plan with an encountered stage '
      'offers to queue a revisit', (tester) async {
    final (widget, container) = await _wrap();
    addTearDown(container.dispose);
    final notifier = container.read(planProvider.notifier);
    notifier.activatePlan(PlanId.moreEnergyPath);
    notifier.advanceCursorForCircle(
      PlanId.moreEnergyPath,
      'circle-0',
      isRevisit: false,
    );

    await tester.pumpWidget(widget);

    expect(find.text('Queue a revisit of the last stage'), findsOneWidget);

    await tester.tap(find.text('Queue a revisit of the last stage'));
    await tester.pump();

    expect(
      notifier.progressFor(PlanId.moreEnergyPath).pendingRevisit,
      isTrue,
    );
    expect(find.text('Clear queued revisit'), findsOneWidget);
  });

  testWidgets('Pause this plan deactivates without erasing progress', (
    tester,
  ) async {
    final (widget, container) = await _wrap();
    addTearDown(container.dispose);
    final notifier = container.read(planProvider.notifier);
    notifier.activatePlan(PlanId.moreEnergyPath);
    notifier.advanceCursorForCircle(
      PlanId.moreEnergyPath,
      'circle-0',
      isRevisit: false,
    );
    await tester.pumpWidget(widget);

    await tester.tap(find.text('Pause this plan'));
    await tester.pump();

    expect(container.read(planProvider).activePlanId, isNull);
    expect(notifier.progressFor(PlanId.moreEnergyPath).forwardCursor, 1);
    // Switching away leaves a "Resume" (not "Activate") affordance, since
    // this Plan has already been started.
    expect(find.text('Resume'), findsOneWidget);
  });

  group('Batch 2C — Insights integration', () {
    testWidgets('renders the InsightCard once, above the Plan list', (
      tester,
    ) async {
      final (widget, container) = await _wrap();
      addTearDown(container.dispose);

      await tester.pumpWidget(widget);

      // skipOffstage: false — with no eligible Insight yet, InsightCard
      // legitimately renders as a zero-size SizedBox.shrink(), which the
      // default finder treats as offstage; this test asserts the card is
      // wired into the page at all, regardless of its current content.
      expect(
        find.byType(InsightCard, skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets(
      'opening the page assesses a current Insight when eligible evidence '
      'already exists',
      (tester) async {
        final (widget, container) = await _wrap();
        addTearDown(container.dispose);
        final notifier = container.read(planProvider.notifier);
        notifier.activatePlan(PlanId.gentlerPacePath);
        notifier.advanceCursorForCircle(
          PlanId.gentlerPacePath,
          'circle-0',
          isRevisit: false,
        );
        notifier.activatePlan(PlanId.moreEnergyPath);
        expect(container.read(insightProvider).lastAssessedAt, isNull);

        await tester.pumpWidget(widget);
        await tester.pump();

        expect(container.read(insightProvider).lastAssessedAt, isNotNull);
        expect(find.textContaining('Gentler Pace'), findsOneWidget);
      },
    );
  });
}
