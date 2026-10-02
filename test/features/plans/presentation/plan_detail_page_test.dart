import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/features/coach/presentation/widgets/coach_cue_banner.dart';
import 'package:thirty/features/plans/application/plan_provider.dart';
import 'package:thirty/features/plans/domain/plan_catalog.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/plans/domain/plan_state.dart';
import 'package:thirty/features/plans/presentation/plan_detail_page.dart';

final _today = DateTime(2026, 8, 2, 14);

/// Your Path for [planId]. `entitled` defaults to `true`; every Plan action
/// below was previously asserted on the Plans list and moved here with the
/// Plans convergence (founder-approved contract, 2026-10-01) — the same
/// labels, conditions and notifier effects.
Future<ProviderContainer> _container({
  bool entitled = true,
  Map<String, Object> storedPrefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(storedPrefs);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_today),
      eventClockProvider.overrideWithValue(() => _today),
      premiumEntitlementProvider.overrideWithValue(entitled),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container, {
  PlanId planId = PlanId.moreEnergyPath,
}) async {
  tester.view.physicalSize = const Size(412, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: PlanDetailPage(planId: planId),
      ),
    ),
  );
  await tester.pump();
}

void _complete(PlanNotifier notifier, PlanId planId) {
  notifier.activatePlan(planId);
  for (var i = 0; i < 5; i++) {
    notifier.advanceCursorForCircle(planId, 'circle-$i', isRevisit: false);
  }
}

Map<String, Object> _savedGentlerPaceAtStage2() => {
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
};

void main() {
  group('Entitled — the path', () {
    testWidgets('shows the Plan, its purpose and all five stage purposes', (
      tester,
    ) async {
      final container = await _container();
      await _pump(tester, container);
      final plan = planDefinitionFor(PlanId.moreEnergyPath);

      expect(find.text(PlanDetailPage.appBarTitle), findsOneWidget);
      expect(find.text(plan.name), findsOneWidget);
      expect(find.text(plan.purpose), findsOneWidget);
      for (final stage in plan.stages) {
        expect(find.text(stage.purpose), findsOneWidget);
      }
    });

    testWidgets('rationale only for the current stage; never an activity '
        'name or guidance', (tester) async {
      final container = await _container();
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);
      notifier.advanceCursorForCircle(
        PlanId.moreEnergyPath,
        'circle-0',
        isRevisit: false,
      );
      await _pump(tester, container);
      final stages = planDefinitionFor(PlanId.moreEnergyPath).stages;

      for (var i = 0; i < stages.length; i++) {
        expect(
          find.text(stages[i].rationale),
          i == 1 ? findsOneWidget : findsNothing,
          reason: 'stage ${i + 1} rationale',
        );
        expect(find.text(stages[i].standardGuidance), findsNothing);
        expect(find.text(stages[i].lighterGuidance), findsNothing);
      }
      expect(find.text('Stage 1 · Closed'), findsOneWidget);
      expect(find.text('Stage 2 · Up next'), findsOneWidget);
      expect(find.text('Stage 3 · Upcoming'), findsOneWidget);
    });

    testWidgets('a never-started, inactive Plan marks no stage as up next', (
      tester,
    ) async {
      final container = await _container();
      await _pump(tester, container);

      expect(find.textContaining('Up next'), findsNothing);
      expect(find.text('Stage 1 · Upcoming'), findsOneWidget);
      expect(find.bySemanticsLabel('5 stages. Not started.'), findsOneWidget);
    });

    testWidgets('a queued revisit is marked on its stage, and the cursor\'s '
        'stage follows it', (tester) async {
      final container = await _container();
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);
      notifier.advanceCursorForCircle(
        PlanId.moreEnergyPath,
        'circle-0',
        isRevisit: false,
      );
      notifier.queueRevisit();
      await _pump(tester, container);

      expect(find.text('Revisit queued'), findsOneWidget);
      expect(find.text('Stage 2 · After the revisit'), findsOneWidget);
      expect(find.textContaining('Up next'), findsNothing);
    });

    testWidgets('the lighter default shows as state only — no toggle', (
      tester,
    ) async {
      final container = await _container();
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);
      notifier.setLighterDefaultForPlan(PlanId.moreEnergyPath, true);
      await _pump(tester, container);

      expect(
        find.text('Lighter guidance is this Plan\'s default.'),
        findsOneWidget,
      );
      expect(find.byType(Switch), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
    });
  });

  group('Entitled — actions (moved from the Plans list)', () {
    testWidgets('an inactive, never-started Plan shows Activate', (
      tester,
    ) async {
      final container = await _container();
      await _pump(tester, container);

      expect(find.text('Activate'), findsOneWidget);
    });

    testWidgets('tapping Activate makes the Plan active and shows an '
        '"Active" label', (tester) async {
      final container = await _container();
      await _pump(tester, container);

      await tester.tap(find.text('Activate'));
      await tester.pump();

      expect(container.read(planProvider).activePlanId, PlanId.moreEnergyPath);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('while another Plan is active, Activate is a secondary '
        'choice', (tester) async {
      final container = await _container();
      container
          .read(planProvider.notifier)
          .activatePlan(PlanId.gentlerPacePath);
      await _pump(tester, container);

      expect(
        tester.widget<ThirtyButton>(find.byType(ThirtyButton)).variant,
        ThirtyButtonVariant.secondary,
      );
      expect(find.text('Pause this plan'), findsNothing);
    });

    testWidgets('a completed cycle shows the plain finished-cycle state and a '
        'Repeat action, never an automatic restart', (tester) async {
      final container = await _container();
      final notifier = container.read(planProvider.notifier);
      _complete(notifier, PlanId.moreEnergyPath);
      await _pump(tester, container);

      expect(find.text('This guided cycle is finished.'), findsOneWidget);
      expect(find.text('Repeat this cycle'), findsOneWidget);
      expect(find.text('Queue a revisit of the last stage'), findsNothing);
      expect(
        find.bySemanticsLabel('Guided cycle finished. All 5 stages closed.'),
        findsOneWidget,
      );
      expect(
        notifier.progressFor(PlanId.moreEnergyPath).status,
        PlanCycleStatus.completed,
      );
    });

    testWidgets('tapping Repeat this cycle starts a new cycle', (tester) async {
      final container = await _container();
      final notifier = container.read(planProvider.notifier);
      _complete(notifier, PlanId.moreEnergyPath);
      await _pump(tester, container);

      await tester.tap(find.text('Repeat this cycle'));
      await tester.pump();

      expect(
        notifier.progressFor(PlanId.moreEnergyPath).status,
        PlanCycleStatus.inProgress,
      );
      expect(find.text('This guided cycle is finished.'), findsNothing);
    });

    testWidgets('an active, in-progress Plan with an encountered stage '
        'offers to queue a revisit, then to clear it', (tester) async {
      final container = await _container();
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);
      notifier.advanceCursorForCircle(
        PlanId.moreEnergyPath,
        'circle-0',
        isRevisit: false,
      );
      await _pump(tester, container);

      await tester.tap(find.text('Queue a revisit of the last stage'));
      await tester.pump();
      expect(
        notifier.progressFor(PlanId.moreEnergyPath).pendingRevisit,
        isTrue,
      );

      await tester.tap(find.text('Clear queued revisit'));
      await tester.pump();
      expect(
        notifier.progressFor(PlanId.moreEnergyPath).pendingRevisit,
        isFalse,
      );
    });

    testWidgets('Pause this plan deactivates without erasing progress', (
      tester,
    ) async {
      final container = await _container();
      final notifier = container.read(planProvider.notifier);
      notifier.activatePlan(PlanId.moreEnergyPath);
      notifier.advanceCursorForCircle(
        PlanId.moreEnergyPath,
        'circle-0',
        isRevisit: false,
      );
      await _pump(tester, container);

      await tester.tap(find.text('Pause this plan'));
      await tester.pump();

      expect(container.read(planProvider).activePlanId, isNull);
      expect(notifier.progressFor(PlanId.moreEnergyPath).forwardCursor, 1);
      // An already-started Plan offers Resume, not Activate.
      expect(find.text('Resume'), findsOneWidget);
    });

    testWidgets('the active Plan shows its Coach cue; an inactive one does '
        'not', (tester) async {
      final container = await _container();
      container.read(planProvider.notifier).activatePlan(PlanId.moreEnergyPath);
      await _pump(tester, container);
      expect(find.byType(CoachCueBanner), findsOneWidget);
    });
  });

  group('Free — the preview, including direct navigation', () {
    testWidgets('identity, purpose and structure only: no stage purpose, '
        'control or Coach, and one Become Premium action', (tester) async {
      final container = await _container(entitled: false);
      await _pump(tester, container);
      final plan = planDefinitionFor(PlanId.moreEnergyPath);

      expect(find.text(plan.name), findsOneWidget);
      expect(find.text(plan.purpose), findsOneWidget);
      for (final stage in plan.stages) {
        expect(find.text(stage.purpose), findsNothing);
        expect(find.text(stage.rationale), findsNothing);
      }
      for (var i = 1; i <= 5; i++) {
        expect(find.text('Stage $i · Upcoming'), findsOneWidget);
      }
      for (final label in [
        'Activate',
        'Resume',
        'Repeat this cycle',
        'Queue a revisit of the last stage',
        'Pause this plan',
      ]) {
        expect(find.text(label), findsNothing, reason: label);
      }
      expect(find.byType(CoachCueBanner), findsNothing);
      expect(find.text('Become Premium'), findsOneWidget);
    });

    testWidgets('a direct activatePlan() call while unentitled is a no-op — '
        'the preview never gains controls', (tester) async {
      final container = await _container(entitled: false);
      container.read(planProvider.notifier).activatePlan(PlanId.moreEnergyPath);
      await _pump(tester, container);

      expect(container.read(planProvider).activePlanId, isNull);
      expect(find.text('Active'), findsNothing);
    });

    testWidgets('a saved position from before entitlement was lost stays '
        'visible, read-only', (tester) async {
      final container = await _container(
        entitled: false,
        storedPrefs: _savedGentlerPaceAtStage2(),
      );
      await _pump(tester, container, planId: PlanId.gentlerPacePath);

      expect(find.text('Saved at stage 2 of 5.'), findsOneWidget);
      expect(find.text('Stage 1 · Closed'), findsOneWidget);
      expect(find.text('Stage 2 · Saved here'), findsOneWidget);
      expect(find.text('Resume'), findsNothing);
      expect(find.text('Pause this plan'), findsNothing);
      // Its stored active marker is not presented: no Plan runs while Free.
      expect(find.text('Active'), findsNothing);
    });
  });
}
