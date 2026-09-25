import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/core/widgets/thirty_text_action.dart';
import 'package:thirty/features/coach/presentation/widgets/coach_cue_banner.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/plans/application/plan_provider.dart';
import 'package:thirty/features/plans/domain/plan_catalog.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/plans/domain/plan_state.dart';
import 'package:thirty/features/plans/presentation/plan_path_page.dart';

/// Phase C3 — Plans: in-list Free upsell, action hierarchy, quiet
/// management / Coach actions, no duplicate revisit, Coach alignment.
/// Plan lifecycle behaviour itself stays covered by
/// `plan_path_page_test.dart` and the Coach / Plans provider suites.

final _today = DateTime(2026, 8, 10, 9);

Future<ProviderContainer> _container({bool entitled = true}) async {
  SharedPreferences.setMockInitialValues({});
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
  Widget? child,
}) async {
  tester.view.physicalSize = const Size(412, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: child ?? const PlanPathPage(),
      ),
    ),
  );
  await tester.pump();
}

/// The Coach state with both shortcuts: More Energy active and started,
/// yesterday's matching Plan Circle reported "not today", today's Session
/// resolved to this Plan (standard treatment).
Future<void> _seedCoachShortcuts(ProviderContainer container) async {
  final priorStage = planDefinitionFor(PlanId.moreEnergyPath).stages[0];
  final plans = container.read(planProvider.notifier);
  plans.activatePlan(PlanId.moreEnergyPath);
  plans.advanceCursorForCircle(
    PlanId.moreEnergyPath,
    '2026-08-09',
    isRevisit: false,
  );
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
  container
      .read(recommendationProvider.notifier)
      .chooseIntention(Intention.moreEnergy);
}

Finder _button(String label) => find.widgetWithText(ThirtyButton, label);
Finder _textAction(String label) =>
    find.widgetWithText(ThirtyTextAction, label);

void main() {
  group('Free', () {
    testWidgets('the Premium card comes after the three previews, inside '
        'the scroll — no pinned bar', (tester) async {
      await _pump(tester, await _container(entitled: false));

      final premiumTitle = find.text('THIRTY Premium');
      expect(premiumTitle, findsOneWidget);
      expect(
        find.text('Guided Plans are part of THIRTY Premium.'),
        findsOneWidget,
      );
      for (final plan in [
        'More Energy Path',
        'Clearer Head Path',
        'Gentler Pace Path',
      ]) {
        expect(
          tester.getTopLeft(premiumTitle).dy,
          greaterThan(tester.getTopLeft(find.text(plan)).dy),
        );
      }
      // Inside the one scrollable, not pinned beneath it.
      expect(
        find.descendant(
          of: find.byType(Scrollable),
          matching: _button('Become Premium'),
        ),
        findsOneWidget,
      );
      expect(find.text('Open Premium'), findsNothing);
      // Full width inside its card (page 24 + card 24 on each side).
      expect(tester.getSize(_button('Become Premium')).width, 412 - 96);
    });
  });

  group('Action hierarchy', () {
    testWidgets('no Plan active: every Activate is primary and full width', (
      tester,
    ) async {
      await _pump(tester, await _container());

      final buttons = tester.widgetList<ThirtyButton>(_button('Activate'));
      expect(buttons, hasLength(3));
      for (final button in buttons) {
        expect(button.variant, ThirtyButtonVariant.primary);
      }
      for (final element in _button('Activate').evaluate()) {
        expect(
          (element.renderObject! as RenderBox).size.width,
          412 - 96,
        );
      }
    });

    testWidgets('one Plan active: the others\' Activate is secondary; the '
        'active card has the tinted tag and quiet management actions', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final container = await _container();
      final plans = container.read(planProvider.notifier);
      plans.activatePlan(PlanId.moreEnergyPath);
      plans.advanceCursorForCircle(
        PlanId.moreEnergyPath,
        'c0',
        isRevisit: false,
      );
      await _pump(tester, container);

      for (final button in tester.widgetList<ThirtyButton>(
        _button('Activate'),
      )) {
        expect(button.variant, ThirtyButtonVariant.secondary);
      }
      expect(find.text('Active'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Active plan')), findsOneWidget);
      expect(
        _textAction('Queue a revisit of the last stage'),
        findsOneWidget,
      );
      expect(_textAction('Pause this plan'), findsOneWidget);
      expect(_button('Pause this plan'), findsNothing);
      expect(_button('Queue a revisit of the last stage'), findsNothing);
      semantics.dispose();
    });

    testWidgets('revisit queue / clear and pause still work as text '
        'actions', (tester) async {
      final container = await _container();
      final plans = container.read(planProvider.notifier);
      plans.activatePlan(PlanId.moreEnergyPath);
      plans.advanceCursorForCircle(
        PlanId.moreEnergyPath,
        'c0',
        isRevisit: false,
      );
      await _pump(tester, container);

      await tester.tap(find.text('Queue a revisit of the last stage'));
      await tester.pump();
      expect(plans.progressFor(PlanId.moreEnergyPath).pendingRevisit, isTrue);

      await tester.tap(find.text('Clear queued revisit'));
      await tester.pump();
      expect(plans.progressFor(PlanId.moreEnergyPath).pendingRevisit, isFalse);

      await tester.tap(find.text('Pause this plan'));
      await tester.pump();
      expect(container.read(planProvider).activePlanId, isNull);
      expect(
        plans.progressFor(PlanId.moreEnergyPath).forwardCursor,
        1,
        reason: 'pausing never erases progress',
      );
    });

    testWidgets('completed cycle: Repeat is the primary full-width action, '
        'Pause stays quiet, no revisit', (tester) async {
      final container = await _container();
      final plans = container.read(planProvider.notifier);
      plans.activatePlan(PlanId.moreEnergyPath);
      for (var i = 0; i < 5; i++) {
        plans.advanceCursorForCircle(
          PlanId.moreEnergyPath,
          'c$i',
          isRevisit: false,
        );
      }
      await _pump(tester, container);

      final repeat = tester.widget<ThirtyButton>(_button('Repeat this cycle'));
      expect(repeat.variant, ThirtyButtonVariant.primary);
      expect(tester.getSize(_button('Repeat this cycle')).width, 412 - 96);
      expect(_textAction('Pause this plan'), findsOneWidget);
      expect(find.text('Queue a revisit of the last stage'), findsNothing);
    });
  });

  group('Coach on Plans vs Home', () {
    testWidgets('Plans: left-aligned sentence, quiet lighter shortcut, and '
        'no duplicate revisit — the card\'s own revisit action stays', (
      tester,
    ) async {
      final container = await _container();
      await _seedCoachShortcuts(container);
      await _pump(tester, container);

      expect(_textAction('Try lighter guidance today'), findsOneWidget);
      expect(find.text('Queue a one-off revisit'), findsNothing);
      expect(
        _textAction('Queue a revisit of the last stage'),
        findsOneWidget,
      );
      final banner = find.byType(CoachCueBanner);
      final sentence = tester.widget<Text>(
        find.descendant(of: banner, matching: find.byType(Text)).first,
      );
      expect(sentence.textAlign, TextAlign.start);

      await tester.tap(find.text('Try lighter guidance today'));
      await tester.pump();
      expect(
        container.read(recommendationProvider).recommendation!.treatmentUsed,
        PlanTreatment.lighter,
      );
    });

    testWidgets('Home (default banner): centred sentence, both shortcuts as '
        'centred quiet actions — semantics and state unchanged', (
      tester,
    ) async {
      final container = await _container();
      await _seedCoachShortcuts(container);
      await _pump(
        tester,
        container,
        child: const Scaffold(
          body: CoachCueBanner(planId: PlanId.moreEnergyPath),
        ),
      );

      final sentence = tester.widget<Text>(
        find
            .descendant(
              of: find.byType(CoachCueBanner),
              matching: find.byType(Text),
            )
            .first,
      );
      expect(sentence.textAlign, TextAlign.center);
      for (final label in [
        'Try lighter guidance today',
        'Queue a one-off revisit',
      ]) {
        expect(_textAction(label), findsOneWidget);
        expect(tester.widget<ThirtyTextAction>(_textAction(label)).centered,
            isTrue);
      }

      await tester.tap(find.text('Queue a one-off revisit'));
      await tester.pump();
      expect(
        container
            .read(planProvider.notifier)
            .progressFor(PlanId.moreEnergyPath)
            .pendingRevisit,
        isTrue,
      );
    });
  });
}
