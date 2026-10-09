import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/qa/qa_entitlement_gateway.dart';
import 'package:thirty/core/qa/qa_premium_harness.dart';
import 'package:thirty/core/qa/qa_scenario.dart';
import 'package:thirty/core/qa/qa_shared_preferences.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';

/// QA-1 — the harness root: the marker is always there, nothing changes
/// until a selection is explicitly applied, and reset returns to the
/// genuine state.
void main() {
  test('marker lines tell real, sandboxed and synthetic states apart', () {
    expect(qaMarkerLines(null), (
      'QA PREMIUM · OFF',
      'REAL DATA · tap to set up',
    ));
    QaSession session(QaEntitlement e, QaScenario s) =>
        QaSession(entitlement: e, scenario: s, store: QaSharedPreferences());
    expect(qaMarkerLines(session(QaEntitlement.active, QaScenario.monthTwo)), (
      'QA PREMIUM · ACTIVE',
      'QA DATA · month_two',
    ));
    expect(qaMarkerLines(session(QaEntitlement.unavailable, QaScenario.none)), (
      'QA PREMIUM · UNAVAILABLE',
      'QA SANDBOX · copy of real data',
    ));
  });

  /// Pumps the harness over a genuine store holding nothing but the
  /// answered first-use question.
  Future<SharedPreferences> pumpHarness(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({firstNamePromptSeenKey: true});
    final genuine = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      QaPremiumHarnessApp(
        genuinePreferences: genuine,
        supabaseAvailable: false,
        clock: () => DateTime(2026, 10, 8, 10),
      ),
    );
    await tester.pumpAndSettle();
    return genuine;
  }

  Future<void> openPanel(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('qa-marker')));
    await tester.pumpAndSettle();
  }

  /// Applies [scenario] through the QA panel and waits for the new session.
  Future<void> applyScenario(WidgetTester tester, QaScenario scenario) async {
    await openPanel(tester);
    // The panel scrolls once it lists more scenarios than fit.
    final chip = find.byKey(Key('qa-scenario-${scenario.wireName}'));
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    final apply = find.byKey(const Key('qa-apply'));
    await tester.ensureVisible(apply);
    await tester.pumpAndSettle();
    await tester.tap(apply);
    final marker = find.text('QA DATA · ${scenario.wireName}');
    for (var i = 0; i < 2000 && marker.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    await tester.pumpAndSettle();
    expect(marker, findsOneWidget);
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  /// Leaves state behind in a month_two session that a fresh app start
  /// would never show: a pushed Plan page, and Insights' one-off
  /// "Applied" confirmation after applying the revisit Insight.
  Future<void> leaveMonthTwoState(WidgetTester tester) async {
    await openTab(tester, 'Insights');
    final apply = find.text('Queue a one-off revisit of this stage');
    await tester.ensureVisible(apply);
    await tester.pumpAndSettle();
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(find.text('Applied. Your Plan is updated.'), findsOneWidget);

    await openTab(tester, 'Plans');
    await tester.tap(find.text('More Energy Path'));
    await tester.pumpAndSettle();
    expect(find.text('Your Path'), findsOneWidget);
  }

  /// What a fresh app start shows: Today at the root, the Plans list (not a
  /// pushed Plan page), and no Insights confirmation.
  Future<void> expectFreshSession(WidgetTester tester) async {
    expect(find.text("Begin today's Circle"), findsOneWidget);
    await openTab(tester, 'Plans');
    expect(find.text('Your Plans'), findsOneWidget);
    expect(find.text('Your Path'), findsNothing);
    await openTab(tester, 'Insights');
    expect(find.text('Applied. Your Plan is updated.'), findsNothing);
  }

  testWidgets('starts on the genuine state, applies a scenario only when '
      'asked, and resets back', (tester) async {
    final genuine = await pumpHarness(tester);
    final genuineKeys = genuine.getKeys();

    expect(find.text('QA PREMIUM · OFF'), findsOneWidget);
    expect(find.text('REAL DATA · tap to set up'), findsOneWidget);
    expect(find.byKey(const Key('qa-panel')), findsNothing);

    await applyScenario(tester, QaScenario.planInProgress);
    expect(find.text('QA PREMIUM · ACTIVE'), findsOneWidget);
    expect(genuine.getKeys(), genuineKeys);

    // The marker stays over another tab.
    await openTab(tester, 'Plans');
    expect(find.text('QA DATA · plan_in_progress'), findsOneWidget);

    await openPanel(tester);
    await tester.ensureVisible(find.byKey(const Key('qa-reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('qa-reset')));
    await tester.pumpAndSettle();

    expect(find.text('QA PREMIUM · OFF'), findsOneWidget);
    expect(genuine.getKeys(), genuineKeys);
  });

  testWidgets('applying another scenario is a fresh app start: no pushed '
      'route, page state or message from the previous session', (tester) async {
    await pumpHarness(tester);
    await applyScenario(tester, QaScenario.monthTwo);
    await leaveMonthTwoState(tester);

    await applyScenario(tester, QaScenario.neverReflects);

    await expectFreshSession(tester);
    // Insights shows the new session's own Insight.
    expect(
      find.textContaining('More Energy was your direction'),
      findsOneWidget,
    );
  });

  testWidgets('Reset to real is a fresh app start on the genuine data, with '
      'nothing left from the QA session but the OFF marker', (tester) async {
    final genuine = await pumpHarness(tester);
    final genuineValues = {
      for (final key in genuine.getKeys()) key: genuine.get(key),
    };
    await applyScenario(tester, QaScenario.monthTwo);
    await leaveMonthTwoState(tester);

    await openPanel(tester);
    await tester.ensureVisible(find.byKey(const Key('qa-reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('qa-reset')));
    await tester.pumpAndSettle();

    expect(find.text('QA PREMIUM · OFF'), findsOneWidget);
    expect(find.text('REAL DATA · tap to set up'), findsOneWidget);
    await expectFreshSession(tester);
    expect(find.textContaining('Gentler Pace Path'), findsNothing);
    expect({
      for (final key in genuine.getKeys()) key: genuine.get(key),
    }, genuineValues);
  });

  test('production keeps one shared router; only the harness builds fresh '
      'ones', () {
    expect(appRouter, same(appRouter));
    final fresh = createAppRouter();
    addTearDown(fresh.dispose);
    expect(fresh, isNot(same(appRouter)));
    expect(const ThirtyApp().router, isNull);
  });

  testWidgets('ThirtyApp without a router uses the shared appRouter', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({firstNamePromptSeenKey: true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const ThirtyApp(),
      ),
    );
    await tester.pump();
    addTearDown(() => appRouter.go('/'));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.routerConfig, same(appRouter));
    expect(app.builder, isNull);
  });
}
