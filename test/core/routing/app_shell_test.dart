import 'dart:convert';

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
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/presentation/circle_record_detail_page.dart';
import 'package:thirty/features/home/presentation/home_page.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';
import 'package:thirty/features/home/presentation/widgets/circle_ready_prompt.dart';
import 'package:thirty/features/home/presentation/widgets/daily_intention_prompt.dart';
import 'package:thirty/features/insights/presentation/insights_page.dart';
import 'package:thirty/features/insights/presentation/widgets/circle_history_calendar.dart';
import 'package:thirty/features/plans/presentation/plan_path_page.dart';
import 'package:thirty/features/premium/presentation/premium_offer_page.dart';
import 'package:thirty/features/settings/presentation/settings_page.dart';

/// Navigation shell coverage for the founder-approved primary IA:
/// **Today | Plans | Insights | You** (supersedes the earlier Batch B
/// "...| Journal"). Follows `app_router_test.dart`'s own established
/// pattern: the real `appRouter`/`ThirtyApp`, no fakes.
///
/// `appRouter` is a shared singleton across every `testWidgets` in this
/// process (matching `premium_billing_navigation_test.dart`'s own noted
/// gotcha) — every test below explicitly returns to `/` first rather than
/// assuming a previous test left it there.
/// A settled entitlement status (as `main.dart`'s startup `initialize()`
/// would leave it). Since Phase C1, You shows no acquisition CTA while the
/// status is still being checked, so tests that follow the "Become
/// Premium" path need a known free state.
class _SettledEntitlement extends EntitlementNotifier {
  _SettledEntitlement(this._status);

  final EntitlementStatus _status;

  @override
  EntitlementStatus build() => _status;
}

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

  testWidgets('all four destinations are reachable from the bottom nav, '
      'each with its own page', (tester) async {
    await pumpApp(tester);

    expect(find.byType(HomePage), findsOneWidget);
    expect(navDestination('Today'), findsOneWidget);
    expect(navDestination('Plans'), findsOneWidget);
    expect(navDestination('Insights'), findsOneWidget);
    expect(navDestination('You'), findsOneWidget);
    // Journal is no longer a primary destination (founder IA correction).
    expect(navDestination('Journal'), findsNothing);

    await tester.tap(navDestination('Plans'));
    await tester.pumpAndSettle();
    expect(find.byType(PlanPathPage), findsOneWidget);

    await tester.tap(navDestination('Insights'));
    await tester.pumpAndSettle();
    expect(find.byType(InsightsPage), findsOneWidget);

    await tester.tap(navDestination('You'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);

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
    'direct navigation to /settings shows the "You" destination with '
    'its own tab selected',
    (tester) async {
      await pumpApp(tester);

      appRouter.go('/settings');
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('You'), findsWidgets);
      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 3);
    },
  );

  testWidgets(
    'no branch keeps a redundant Settings AppBar shortcut now that "You" '
    'is a persistent primary destination',
    (tester) async {
      await pumpApp(tester);

      for (final label in ['Today', 'Plans', 'Insights']) {
        await tester.tap(navDestination(label));
        await tester.pumpAndSettle();
        expect(
          find.byIcon(Icons.settings_outlined),
          findsNothing,
          reason: '$label still shows a Settings icon',
        );
      }
    },
  );

  testWidgets(
    'switching tabs preserves Today\'s already-chosen daily intention — no '
    'duplicate activity is resolved by leaving and returning to Today',
    (tester) async {
      await pumpApp(tester);

      expect(find.byType(CircleReadyPrompt), findsOneWidget);
      await tester.ensureVisible(find.text("Begin today's Circle"));
      await tester.tap(find.text("Begin today's Circle"));
      await tester.pumpAndSettle();
      expect(find.byType(DailyIntentionPrompt), findsOneWidget);
      await tester.ensureVisible(find.text('More Energy'));
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
    'a Free (unentitled) user still finds Plans and the Insights '
    'interpretation preview via the bottom nav — Batch A\'s content-level '
    'preview, not a hidden destination, is what gates paid content',
    (tester) async {
      await pumpApp(tester, entitled: false);

      await tester.tap(navDestination('Plans'));
      await tester.pumpAndSettle();
      expect(find.byType(PlanPathPage), findsOneWidget);
      // Phase C3: the in-list Premium card after the three previews.
      await tester.scrollUntilVisible(find.text('Become Premium'), 200);
      expect(find.text('Become Premium'), findsOneWidget);
      expect(find.text('Activate'), findsNothing);

      await tester.tap(navDestination('Insights'));
      await tester.pumpAndSettle();
      expect(find.byType(InsightsPage), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Become Premium'), 200);
      expect(find.text('Become Premium'), findsOneWidget);
    },
  );

  testWidgets(
    'Insights\' shared history calendar is unaffected by entitlement, '
    'reached via the bottom nav',
    (tester) async {
      await pumpApp(tester, entitled: false);

      await tester.tap(navDestination('Insights'));
      await tester.pumpAndSettle();

      expect(find.byType(CircleHistoryCalendar), findsOneWidget);
    },
  );

  testWidgets(
    'You is reachable and shows Premium/reminder/data controls '
    'regardless of entitlement',
    (tester) async {
      await pumpApp(tester, entitled: false);

      await tester.tap(navDestination('You'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('Become Premium'), findsOneWidget);
    },
  );

  testWidgets(
    'You → Premium → Back → You — standard push/pop, matching the '
    'contract\'s unchanged Settings/Premium return behavior',
    (tester) async {
      await pumpApp(tester, entitled: false);

      await tester.tap(navDestination('You'));
      await tester.pumpAndSettle();

      // Below You's header band in the 800×600 test view.
      await tester.ensureVisible(find.text('Become Premium'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Become Premium'));
      await tester.pumpAndSettle();
      expect(find.byType(PremiumOfferPage), findsOneWidget);

      Navigator.of(tester.element(find.byType(PremiumOfferPage))).pop();
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.byType(PremiumOfferPage), findsNothing);
    },
  );

  testWidgets(
    'tapping a recorded date on the calendar opens that record\'s detail, '
    'and Back returns to the same Insights state',
    (tester) async {
      final today = DateTime.now();
      final localDate =
          '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';

      await pumpApp(
        tester,
        storedPrefs: {
          circleJournalKey: jsonEncode({
            'schemaVersion': circleJournalSchemaVersion,
            'entries': [
              {
                'schemaVersion': circleJournalSchemaVersion,
                'circleId': localDate,
                'localDate': localDate,
                'direction': Intention.moreEnergy.name,
                'activityId': ActivityId.thirtyMinuteWalk.name,
                'catalogVersion': catalogVersion,
                'shownAt': today.toIso8601String(),
              },
            ],
          }),
        },
      );

      await tester.tap(navDestination('Insights'));
      await tester.pumpAndSettle();
      expect(find.byType(CircleHistoryCalendar), findsOneWidget);

      // The calendar sits below the Insights header and card: bring the
      // date into view first.
      final recordedDate = find
          .descendant(
            of: find.byType(CircleHistoryCalendar),
            matching: find.text(today.day.toString()),
          )
          .first;
      await tester.ensureVisible(recordedDate);
      await tester.pumpAndSettle();
      await tester.tap(recordedDate);
      await tester.pumpAndSettle();

      expect(find.byType(CircleRecordDetailPage), findsOneWidget);
      expect(find.textContaining(localDate), findsWidgets);

      Navigator.of(tester.element(find.byType(CircleRecordDetailPage))).pop();
      await tester.pumpAndSettle();

      expect(find.byType(InsightsPage), findsOneWidget);
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

      for (final label in ['Today', 'Plans', 'Insights', 'You']) {
        await tester.tap(navDestination(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$label overflowed');
      }
    },
  );

  testWidgets(
    'Phase A3 floating nav: at 360pt width and 200% text no tab overflows, '
    'and all four labels stay visible and unchanged',
    (tester) async {
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
        navBar.destinations
            .cast<NavigationDestination>()
            .map((destination) => destination.label),
        ['Today', 'Plans', 'Insights', 'You'],
      );
      expect(navBar.labelBehavior, isNot(NavigationDestinationLabelBehavior.alwaysHide));

      for (final (index, label) in ['Today', 'Plans', 'Insights', 'You'].indexed) {
        await tester.tap(navDestination(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$label overflowed');
        expect(
          tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
          index,
        );
        for (final other in ['Today', 'Plans', 'Insights', 'You']) {
          expect(navDestination(other).hitTestable(), findsOneWidget,
              reason: '$other label hidden while on $label');
        }
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

      for (final label in ['Today', 'Plans', 'Insights', 'You']) {
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

    expect(branchRootPaths, ['/', '/plans', '/insights', '/settings']);
  });

  test(
    '/history and /history/:date remain registered as top-level routes, '
    'outside the shell — secondary/compatibility surfaces, not a fifth '
    'destination',
    () {
      final routes = buildAppRoutes(includeDevPreview: false);
      final topLevelPaths = routes.whereType<GoRoute>().map((r) => r.path);

      expect(topLevelPaths, contains('/history'));
      expect(topLevelPaths, contains('/history/:date'));
    },
  );
}
