import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_app_bar.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/presentation/widgets/home_header.dart';

/// Phase C5 — the AppBar's scrolled-under edge: none at the top, a 1pt
/// divider-coloured bottom edge while the page's vertical scroll view is
/// scrolled, gone again back at the top; never from horizontal or nested
/// scrolling; no elevation, tint or background change. Used on exactly
/// the six audited screens — never Home.

Material _appBarMaterial(WidgetTester tester) => tester.widget<Material>(
  find
      .descendant(of: find.byType(AppBar), matching: find.byType(Material))
      .first,
);

BorderSide _edge(WidgetTester tester) =>
    (_appBarMaterial(tester).shape! as Border).bottom;

Future<void> _pumpPage(
  WidgetTester tester, {
  required Widget body,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Scaffold(
        appBar: const ThirtyAppBar(title: Text('Plans')),
        body: body,
      ),
    ),
  );
}

Widget _rows(Axis axis) => ListView(
  scrollDirection: axis,
  children: [
    for (var i = 0; i < 30; i++)
      SizedBox(width: 120, height: 120, child: Text('Row $i')),
  ],
);

class _SettledEntitlement extends EntitlementNotifier {
  @override
  EntitlementStatus build() => EntitlementStatus.inactive;
}

void main() {
  group('scrolled-under edge', () {
    for (final (themeName, theme, colors) in [
      ('light', AppTheme.light, AppColors.light),
      ('dark', AppTheme.dark, AppColors.dark),
    ]) {
      testWidgets('$themeName: none at the top, 1pt divider edge while '
          'scrolled, gone back at the top; nothing else changes', (
        tester,
      ) async {
        await _pumpPage(tester, body: _rows(Axis.vertical), theme: theme);

        void expectPlainSurface() {
          final material = _appBarMaterial(tester);
          expect(material.color, colors.background);
          expect(material.elevation, 0);
          expect(material.surfaceTintColor, Colors.transparent);
        }

        expect(_edge(tester), BorderSide.none);
        expectPlainSurface();

        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(_edge(tester), BorderSide(color: colors.divider));
        expect(_edge(tester).width, 1);
        expectPlainSurface();

        await tester.drag(find.byType(ListView), const Offset(0, 400));
        await tester.pumpAndSettle();
        expect(_edge(tester), BorderSide.none);
        expectPlainSurface();
      });
    }

    testWidgets('the edge never changes the AppBar height', (tester) async {
      await _pumpPage(tester, body: _rows(Axis.vertical));
      final atTop = tester.getRect(find.byType(AppBar));
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(AppBar)), atTop);
      expect(atTop.height, kToolbarHeight);
    });

    testWidgets('horizontal scrolling never shows the edge', (tester) async {
      await _pumpPage(tester, body: _rows(Axis.horizontal));
      await tester.drag(find.byType(ListView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(_edge(tester), BorderSide.none);
    });

    testWidgets('a nested scroll view never shows the edge', (tester) async {
      await _pumpPage(
        tester,
        body: Column(
          children: [
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 150, child: _rows(Axis.vertical)),
                    const SizedBox(height: 600),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
      // The inner list sits one scroll view deep.
      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(_edge(tester), BorderSide.none);
    });

    testWidgets('horizontal scrolling while scrolled keeps the edge', (
      tester,
    ) async {
      await _pumpPage(
        tester,
        body: ListView(
          children: [
            SizedBox(height: 120, child: _rows(Axis.horizontal)),
            for (var i = 0; i < 20; i++) const SizedBox(height: 120),
          ],
        ),
      );
      await tester.drag(find.byType(ListView).first, const Offset(0, -60));
      await tester.pumpAndSettle();
      expect(_edge(tester), isNot(BorderSide.none));
      await tester.drag(find.byType(ListView).last, const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(_edge(tester), isNot(BorderSide.none));
    });
  });

  group('screens', () {
    Future<void> pumpApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await CircleJournalRepository(prefs).recordShown(
        circleId: '2026-09-01',
        localDate: '2026-09-01',
        direction: Intention.moreEnergy,
        activityId: ActivityId.thirtyMinuteWalk,
        shownAt: DateTime(2026, 9, 1, 9),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            premiumEntitlementProvider.overrideWithValue(false),
            entitlementStatusProvider.overrideWith(_SettledEntitlement.new),
          ],
          child: const ThirtyApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    tearDown(() => appRouter.go('/'));

    for (final location in [
      '/settings',
      '/plans/moreEnergyPath',
      '/premium',
      '/history',
      '/history/2026-09-01',
    ]) {
      testWidgets('$location uses ThirtyAppBar', (tester) async {
        await pumpApp(tester);
        appRouter.go(location);
        await tester.pumpAndSettle();
        expect(find.byType(ThirtyAppBar), findsOneWidget);
      });
    }

    testWidgets('Home has no pinned bar: its header scrolls with the '
        'Circle', (tester) async {
      await pumpApp(tester);
      appRouter.go('/');
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(ThirtyAppBar), findsNothing);
      expect(find.byType(HomeHeader), findsOneWidget);
    });

    testWidgets('Plans has no pinned bar either: like Home, its header '
        'scrolls with the page (Plans convergence)', (tester) async {
      await pumpApp(tester);
      appRouter.go('/plans');
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(ThirtyAppBar), findsNothing);
      expect(find.text('Your Plans'), findsOneWidget);
    });

    testWidgets('Insights has no pinned bar either: its header scrolls with '
        'the page (Insights convergence)', (tester) async {
      await pumpApp(tester);
      appRouter.go('/insights');
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(ThirtyAppBar), findsNothing);
      expect(find.text('Your Insights'), findsOneWidget);
    });

    testWidgets('on You, scrolling shows the edge and returning to the top '
        'hides it', (tester) async {
      await pumpApp(tester);
      appRouter.go('/settings');
      await tester.pumpAndSettle();
      expect(_edge(tester), BorderSide.none);

      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(_edge(tester), BorderSide(color: AppColors.light.divider));

      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(_edge(tester), BorderSide.none);
    });
  });
}
