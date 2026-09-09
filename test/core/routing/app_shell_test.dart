import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/features/home/presentation/circle_history_page.dart';
import 'package:thirty/features/home/presentation/home_page.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';
import 'package:thirty/features/home/presentation/widgets/daily_intention_prompt.dart';
import 'package:thirty/features/insights/presentation/insights_page.dart';
import 'package:thirty/features/plans/presentation/plan_path_page.dart';
import 'package:thirty/features/settings/presentation/settings_page.dart';

/// Batch B navigation shell coverage
/// (`THIRTY_STEP1_FINAL_IA_AND_IMPLEMENTATION_CONTRACT_2026-09-09.md`
/// §2/§3/§6.B) — the four-destination `StatefulShellRoute.indexedStack`
/// added around the existing routes. Follows `app_router_test.dart`'s own
/// established pattern: the real `appRouter`/`ThirtyApp`, no fakes.
///
/// `appRouter` is a shared singleton across every `testWidgets` in this
/// process (matching `premium_billing_navigation_test.dart`'s own noted
/// gotcha) — every test below explicitly returns to `/` first rather than
/// assuming a previous test left it there.
void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    Map<String, Object> storedPrefs = const {},
    bool entitled = true,
  }) async {
    SharedPreferences.setMockInitialValues(storedPrefs);
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          premiumEntitlementProvider.overrideWithValue(entitled),
        ],
        child: const ThirtyApp(),
      ),
    );
    await tester.pumpAndSettle();
    appRouter.go('/');
    await tester.pumpAndSettle();
  }

  Finder navDestination(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  testWidgets('all four destinations are reachable from the bottom nav, '
      'each with its own page', (tester) async {
    await pumpApp(tester);

    expect(find.byType(HomePage), findsOneWidget);
    expect(navDestination('Today'), findsOneWidget);
    expect(navDestination('Plans'), findsOneWidget);
    expect(navDestination('Insights'), findsOneWidget);
    expect(navDestination('Journal'), findsOneWidget);

    await tester.tap(navDestination('Plans'));
    await tester.pumpAndSettle();
    expect(find.byType(PlanPathPage), findsOneWidget);

    await tester.tap(navDestination('Insights'));
    await tester.pumpAndSettle();
    expect(find.byType(InsightsPage), findsOneWidget);

    await tester.tap(navDestination('Journal'));
    await tester.pumpAndSettle();
    expect(find.byType(CircleHistoryPage), findsOneWidget);

    await tester.tap(navDestination('Today'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('direct navigation to /insights shows InsightsPage with the '
      'Insights tab selected', (tester) async {
    await pumpApp(tester);

    appRouter.go('/insights');
    await tester.pumpAndSettle();

    expect(find.byType(InsightsPage), findsOneWidget);
    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 2);
  });

  testWidgets(
    'Settings is reachable via a matching AppBar icon on Plans, Insights '
    'and Journal — not a 5th bottom-nav tab',
    (tester) async {
      await pumpApp(tester);

      for (final label in ['Plans', 'Insights', 'Journal']) {
        await tester.tap(navDestination(label));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsPage), findsOneWidget);

        // Pop back to the branch that opened it (standard push/pop) before
        // moving to the next destination.
        final navigatorContext = tester.element(find.byType(SettingsPage));
        Navigator.of(navigatorContext).pop();
        await tester.pumpAndSettle();
      }

      expect(navDestination('Today'), findsOneWidget);
    },
  );

  testWidgets(
    'switching tabs preserves Today\'s already-chosen daily intention — no '
    'duplicate activity is resolved by leaving and returning to Today',
    (tester) async {
      await pumpApp(tester);

      expect(find.byType(DailyIntentionPrompt), findsOneWidget);
      await tester.tap(find.text('More Energy'));
      await tester.pumpAndSettle();
      expect(find.byType(CircleHero), findsOneWidget);

      await tester.tap(navDestination('Plans'));
      await tester.pumpAndSettle();
      expect(find.byType(PlanPathPage), findsOneWidget);

      await tester.tap(navDestination('Today'));
      await tester.pumpAndSettle();

      // Still showing today's already-resolved Circle, not a fresh Daily
      // Context Question — switching tabs never re-resolves an activity.
      expect(find.byType(CircleHero), findsOneWidget);
      expect(find.byType(DailyIntentionPrompt), findsNothing);
    },
  );

  testWidgets(
    'a Free (unentitled) user still finds Plans and Insights via the '
    'bottom nav — Batch A\'s content-level preview, not a hidden '
    'destination, is what gates paid content',
    (tester) async {
      await pumpApp(tester, entitled: false);

      await tester.tap(navDestination('Plans'));
      await tester.pumpAndSettle();
      expect(find.byType(PlanPathPage), findsOneWidget);
      expect(find.text('Open Premium'), findsOneWidget);
      expect(find.text('Activate'), findsNothing);

      await tester.tap(navDestination('Insights'));
      await tester.pumpAndSettle();
      expect(find.byType(InsightsPage), findsOneWidget);
      expect(find.text('Open Premium'), findsOneWidget);
    },
  );

  testWidgets(
    'Journal is unaffected by entitlement, reached via the bottom nav',
    (tester) async {
      await pumpApp(tester, entitled: false);

      await tester.tap(navDestination('Journal'));
      await tester.pumpAndSettle();

      expect(find.byType(CircleHistoryPage), findsOneWidget);
    },
  );

  testWidgets(
    'popping Settings returns to the exact tab that opened it, not Today '
    '— standard push/pop, unchanged from before the shell (§3)',
    (tester) async {
      await pumpApp(tester);

      await tester.tap(navDestination('Insights'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      Navigator.of(tester.element(find.byType(SettingsPage))).pop();
      await tester.pumpAndSettle();

      expect(find.byType(InsightsPage), findsOneWidget);
      expect(find.byType(SettingsPage), findsNothing);
    },
  );

  testWidgets(
    'no destination overflows on a small-screen device width, across all '
    'four tabs (§3 — functional small-screen requirement)',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;

      await pumpApp(tester);
      expect(tester.takeException(), isNull);

      for (final label in ['Today', 'Plans', 'Insights', 'Journal']) {
        await tester.tap(navDestination(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$label overflowed');
      }
    },
  );

  testWidgets(
    'no destination overflows at a large accessibility text scale, across '
    'all four tabs (§3 — text-scaling discipline)',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpApp(tester);
      expect(tester.takeException(), isNull);

      for (final label in ['Today', 'Plans', 'Insights', 'Journal']) {
        await tester.tap(navDestination(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$label overflowed');
      }
    },
  );

  test('the shell branches map to exactly the contracted four paths, in '
      'order', () {
    final routes = buildAppRoutes(includeDevPreview: false);
    final shell = routes.whereType<StatefulShellRoute>().single;
    final branchRootPaths = shell.branches
        .map((branch) => (branch.routes.single as GoRoute).path)
        .toList();

    expect(branchRootPaths, ['/', '/plans', '/insights', '/history']);
  });
}
