import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/plans/application/plan_provider.dart';
import 'package:thirty/features/plans/domain/plan_catalog.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/plans/domain/plan_state.dart';
import 'package:thirty/features/plans/presentation/plan_path_page.dart';

final _today = DateTime(2026, 8, 2);

/// `entitled` defaults to `true` — every pre-existing test below exercises
/// the full Plan-management experience (activate, revisit, repeat, pause),
/// which is only ever reachable while entitled now that
/// `PlanNotifier`'s mutation methods and `PlanPathPage.build()` itself
/// branch on `premiumEntitlementProvider` (Batch A correction). The
/// `entitled: false` group below covers the unentitled preview branch this
/// same correction adds. This still hosts a plain `MaterialApp` (no
/// `GoRouter`), matching `settings_page_test.dart`'s own convention of
/// verifying a `context.push`-driven button's presence/label without
/// tapping it — real end-to-end `/plans` → `/premium` navigation is
/// covered separately in `app_router_test.dart` against the real app.
Future<(Widget, ProviderContainer)> _wrap({
  bool entitled = true,
  Map<String, Object> storedPrefs = const {},
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

  testWidgets(
    'no longer hosts InsightCard — it moved to its own Insights '
    'destination in Batch B (see insights_page_test.dart)',
    (tester) async {
      final (widget, container) = await _wrap();
      addTearDown(container.dispose);

      await tester.pumpWidget(widget);

      expect(find.text('Insight'), findsNothing);
    },
  );

  group('Batch A — unentitled Free preview', () {
    testWidgets(
      'shows each Plan\'s name and purpose, no interactive controls, and '
      'an Open Premium action',
      (tester) async {
        final (widget, container) = await _wrap(entitled: false);
        addTearDown(container.dispose);

        await tester.pumpWidget(widget);

        expect(find.text('More Energy Path'), findsOneWidget);
        expect(find.text('Clearer Head Path'), findsOneWidget);
        expect(find.text('Gentler Pace Path'), findsOneWidget);
        expect(find.text('Activate'), findsNothing);
        expect(find.text('Resume'), findsNothing);
        expect(find.text('Pause this plan'), findsNothing);
        expect(find.text('Queue a revisit of the last stage'), findsNothing);
        expect(find.text('Open Premium'), findsOneWidget);
      },
    );

    testWidgets(
      'a direct activatePlan() call while unentitled is a no-op — the '
      'preview never gains interactive controls',
      (tester) async {
        final (widget, container) = await _wrap(entitled: false);
        addTearDown(container.dispose);
        container
            .read(planProvider.notifier)
            .activatePlan(PlanId.moreEnergyPath);

        await tester.pumpWidget(widget);

        expect(container.read(planProvider).activePlanId, isNull);
        expect(find.text('Active'), findsNothing);
      },
    );

    testWidgets(
      'a saved position from before entitlement was lost stays visible, '
      'read-only, in the preview',
      (tester) async {
        final (widget, container) = await _wrap(
          entitled: false,
          storedPrefs: {
            plansStateKey: jsonEncode({
              'schemaVersion': plansStateSchemaVersion,
              'activePlanId': PlanId.gentlerPacePath.name,
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
          },
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(widget);

        expect(find.textContaining('Saved at stage 2 of 5'), findsOneWidget);
        expect(find.text('Resume'), findsNothing);
        expect(find.text('Pause this plan'), findsNothing);
      },
    );
  });
}
