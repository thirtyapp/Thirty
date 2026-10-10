import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/features/home/presentation/circle_history_page.dart';
import 'package:thirty/features/home/presentation/home_page.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';
import 'package:thirty/features/settings/presentation/settings_page.dart';
import 'package:thirty/features/settings/presentation/widgets/you_personal_card.dart';
import 'package:thirty/features/toolkit/presentation/toolkit_page.dart';

/// Navigation shell coverage for the V2 Phase D IA: **Today | Toolkit |
/// You** (ADR-022). The V1 Plans and Insights pillars are retired; the
/// Toolkit is the one Premium destination, and history — once inside
/// Insights — is reached from You. The real `appRouter` / `ThirtyApp`, no
/// fakes.
///
/// `appRouter` is a shared singleton across every `testWidgets` in this
/// process — every test below explicitly returns to `/` first rather than
/// assuming a previous test left it there.
class _SettledEntitlement extends EntitlementNotifier {
  _SettledEntitlement(this._status);

  final EntitlementStatus _status;

  @override
  EntitlementStatus build() => _status;
}

const _labels = ['Today', 'Toolkit', 'You'];

void main() {
  Future<void> pumpApp(WidgetTester tester, {bool entitled = true}) async {
    SharedPreferences.setMockInitialValues({firstNamePromptSeenKey: true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          premiumEntitlementProvider.overrideWithValue(entitled),
          entitlementStatusProvider.overrideWith(
            () => _SettledEntitlement(
              entitled ? EntitlementStatus.active : EntitlementStatus.inactive,
            ),
          ),
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

  int selectedIndex(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

  testWidgets('three destinations — Today, Toolkit, You — each with its own '
      'page; no Plans, no Insights', (tester) async {
    await pumpApp(tester);

    for (final label in _labels) {
      expect(navDestination(label), findsOneWidget);
    }
    expect(navDestination('Plans'), findsNothing);
    expect(navDestination('Insights'), findsNothing);

    expect(find.byType(HomePage), findsOneWidget);
    await tester.tap(navDestination('Toolkit'));
    await tester.pumpAndSettle();
    expect(find.byType(ToolkitPage), findsOneWidget);
    expect(selectedIndex(tester), 1);
    await tester.tap(navDestination('You'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(selectedIndex(tester), 2);
  });

  testWidgets('a Free user finds the Toolkit too — what it offers depends '
      'on Premium, never whether it opens', (tester) async {
    await pumpApp(tester, entitled: false);
    await tester.tap(navDestination('Toolkit'));
    await tester.pumpAndSettle();
    expect(find.byType(ToolkitPage), findsOneWidget);
    expect(find.text('A few routines of your own'), findsOneWidget);
  });

  for (final old in ['/plans', '/plans/moreEnergyPath', '/insights']) {
    testWidgets('the retired $old leads to the Toolkit, never a dead page', (
      tester,
    ) async {
      await pumpApp(tester);
      appRouter.go(old);
      await tester.pumpAndSettle();
      expect(find.byType(ToolkitPage), findsOneWidget);
      expect(selectedIndex(tester), 1);
    });
  }

  testWidgets('history is one tap from You (it used to sit in Insights)', (
    tester,
  ) async {
    // Tall enough that the row sits above the floating nav, not under it.
    tester.view.physicalSize = const Size(412, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    await tester.tap(navDestination('You'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(YouPersonalCard.historyTitle));
    await tester.tap(find.text(YouPersonalCard.historyTitle));
    await tester.pumpAndSettle();
    expect(find.byType(CircleHistoryPage), findsOneWidget);
  });

  testWidgets('at 360pt width and 200% text no tab overflows, and every '
      'label stays visible', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpApp(tester);
    expect(tester.takeException(), isNull);

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(
      navBar.destinations.cast<NavigationDestination>().map((d) => d.label),
      _labels,
    );
    for (final (index, label) in _labels.indexed) {
      await tester.tap(navDestination(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$label overflowed');
      expect(selectedIndex(tester), index);
      for (final other in _labels) {
        expect(
          navDestination(other).hitTestable(),
          findsOneWidget,
          reason: '$other label hidden while on $label',
        );
      }
    }
  });

  testWidgets('a very small screen (320×568) never overflows', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    await pumpApp(tester);
    for (final label in _labels) {
      await tester.tap(navDestination(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$label overflowed');
    }
  });

  test('the shell branches are exactly Today, Toolkit and You, in order', () {
    final routes = buildAppRoutes(includeDevPreview: false);
    final shell = routes.whereType<StatefulShellRoute>().single;
    final branchRootPaths = shell.branches
        .map((branch) => (branch.routes.single as GoRoute).path)
        .toList();
    expect(branchRootPaths, ['/', '/toolkit', '/settings']);
  });

  test('/history and /history/:date stay top-level routes, outside the '
      'shell', () {
    final routes = buildAppRoutes(includeDevPreview: false);
    final topLevelPaths = routes.whereType<GoRoute>().map((r) => r.path);
    expect(topLevelPaths, contains('/history'));
    expect(topLevelPaths, contains('/history/:date'));
  });
}
