import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/core/world_rendering/quiet_trail_hero_asset_view.dart';
import 'package:thirty/features/home/presentation/circle_history_page.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';
import 'package:thirty/features/home/presentation/widgets/daily_intention_prompt.dart';
import 'package:thirty/features/plans/presentation/plan_path_page.dart';

void main() {
  testWidgets(
    'the root route shows HomePage, starting with the Daily Context '
    'Question and moving to the Circle Hero once an intention is chosen',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const ThirtyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DailyIntentionPrompt), findsOneWidget);
      expect(find.byType(CircleHero), findsNothing);
      expect(find.text('THIRTY — Design System'), findsNothing);

      await tester.tap(find.text('More Energy'));
      await tester.pumpAndSettle();

      expect(find.byType(CircleHero), findsOneWidget);
      expect(find.byType(DailyIntentionPrompt), findsNothing);
    },
  );

  testWidgets(
    'tapping the history icon on the root route opens /history '
    '(CircleHistoryPage) — ADR-013 §6',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const ThirtyApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      expect(find.byType(CircleHistoryPage), findsOneWidget);
    },
  );

  testWidgets(
    'the /plans route shows PlanPathPage, reachable regardless of the '
    'AppBar icon\'s own entitlement gating (Batch 2A)',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const ThirtyApp(),
        ),
      );
      await tester.pumpAndSettle();

      appRouter.go('/plans');
      await tester.pumpAndSettle();

      expect(find.byType(PlanPathPage), findsOneWidget);
    },
  );

  testWidgets('the /showcase route shows the design system showcase', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const ThirtyApp(),
      ),
    );
    await tester.pumpAndSettle();

    appRouter.go('/showcase');
    await tester.pumpAndSettle();

    expect(find.text('THIRTY — Design System'), findsOneWidget);
  });

  testWidgets(
    'the dev-only Quiet Trail Hero preview route shows '
    'QuietTrailHeroAssetView',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const ThirtyApp(),
        ),
      );
      await tester.pumpAndSettle();

      appRouter.go('/dev/quiet-trail-hero-preview');
      await tester.pumpAndSettle();

      expect(find.byType(QuietTrailHeroAssetView), findsOneWidget);
    },
  );

  group('buildAppRoutes debug gating', () {
    // kDebugMode is a compile-time constant that is always true under
    // `flutter test`, so a release build's routing can't be exercised
    // directly here — asserting on the same includeDevPreview parameter
    // appRouter is built from is what makes this gating testable at all.
    test('omits the dev preview route when includeDevPreview is false', () {
      final paths = buildAppRoutes(includeDevPreview: false)
          .whereType<GoRoute>()
          .map((route) => route.path);

      expect(paths, isNot(contains('/dev/quiet-trail-hero-preview')));
    });

    test('includes the dev preview route when includeDevPreview is true', () {
      final paths = buildAppRoutes(includeDevPreview: true)
          .whereType<GoRoute>()
          .map((route) => route.path);

      expect(paths, contains('/dev/quiet-trail-hero-preview'));
    });
  });
}
