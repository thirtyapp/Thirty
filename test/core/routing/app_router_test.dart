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
import 'package:thirty/features/home/presentation/widgets/circle_ready_prompt.dart';
import 'package:thirty/features/home/presentation/widgets/daily_intention_prompt.dart';
import 'package:thirty/core/routing/app_shell.dart';
import 'package:thirty/features/home/presentation/home_page.dart';
import 'package:thirty/features/personal_circle/presentation/kept_circle_page.dart';
import 'package:thirty/features/personal_circle/presentation/yours_page.dart';
import 'package:thirty/features/insights/presentation/insights_page.dart';
import 'package:thirty/features/plans/presentation/plan_detail_page.dart';
import 'package:thirty/features/plans/presentation/plans_page.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';

void main() {
  testWidgets(
    'the root route shows HomePage, starting with the Circle-first Ready '
    'state, then the Daily Context Question, and moving to the Circle '
    'Hero once an intention is chosen',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({firstNamePromptSeenKey: true});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const ThirtyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircleReadyPrompt), findsOneWidget);
      expect(find.byType(DailyIntentionPrompt), findsNothing);
      expect(find.byType(CircleHero), findsNothing);
      expect(find.text('THIRTY — Design System'), findsNothing);

      await tester.ensureVisible(find.text("Begin today's Circle"));
      await tester.tap(find.text("Begin today's Circle"));
      await tester.pumpAndSettle();

      expect(find.byType(DailyIntentionPrompt), findsOneWidget);

      await tester.ensureVisible(find.text('More Energy'));
      await tester.tap(find.text('More Energy'));
      await tester.pumpAndSettle();

      expect(find.byType(CircleHero), findsOneWidget);
      expect(find.byType(DailyIntentionPrompt), findsNothing);
    },
  );

  testWidgets(
    '/history remains reachable as a secondary/compatibility route — no '
    'longer linked from any primary-nav element since the founder IA '
    'correction retired Journal as a bottom-nav destination',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({firstNamePromptSeenKey: true});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const ThirtyApp(),
        ),
      );
      await tester.pumpAndSettle();

      appRouter.go('/history');
      await tester.pumpAndSettle();

      expect(find.byType(CircleHistoryPage), findsOneWidget);
    },
  );

  testWidgets('ADR-024 B1/B4/B6: a retired location never opens a retired page '
      '— the Toolkit and its kept Circles lead to Yours (inside You), Paths '
      'and routines lead to Today, a V1 Plan to the Circle Plans page — and '
      '/insights is the Insights tab (B7)', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({firstNamePromptSeenKey: true});
    final prefs = await SharedPreferences.getInstance();
    addTearDown(() => appRouter.go('/'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const ThirtyApp(),
      ),
    );
    await tester.pumpAndSettle();

    appRouter.go('/toolkit');
    await tester.pumpAndSettle();
    expect(find.byType(YoursPage), findsOneWidget);
    expect(find.byType(AppShell), findsOneWidget);

    appRouter.go('/toolkit/kept/kept-1');
    await tester.pumpAndSettle();
    expect(
      tester.widget<KeptCirclePage>(find.byType(KeptCirclePage)).keptId,
      'kept-1',
    );
    expect(find.text('This Circle is no longer in Yours.'), findsOneWidget);

    for (final retired in const [
      '/toolkit/paths',
      '/toolkit/paths/clearTheDecks',
      '/toolkit/paths/notAPath',
      '/toolkit/review',
      '/toolkit/routine/routine-1',
    ]) {
      appRouter.go(retired);
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget, reason: retired);
      expect(find.textContaining('routine'), findsNothing, reason: retired);
      expect(find.textContaining('Path'), findsNothing, reason: retired);
      expect(find.textContaining('Toolkit'), findsNothing, reason: retired);
    }

    // B7: `/insights` is the Insights tab, inside the four-tab shell.
    appRouter.go('/insights');
    await tester.pumpAndSettle();
    expect(find.byType(InsightsPage), findsOneWidget);
    expect(find.byType(AppShell), findsOneWidget);

    // B4: `/plans` is the Circle Plans page; a V1 Plan id opens it, never a
    // V1 Plan.
    for (final location in const ['/plans', '/plans/moreEnergyPath']) {
      appRouter.go(location);
      await tester.pumpAndSettle();
      expect(find.byType(PlansPage), findsOneWidget, reason: location);
      expect(find.byType(PlanDetailPage), findsNothing, reason: location);
      expect(find.textContaining('Path'), findsNothing, reason: location);
    }
  });

  testWidgets('the /showcase route shows the design system showcase', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({firstNamePromptSeenKey: true});
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

  testWidgets('the dev-only Quiet Trail Hero preview route shows '
      'QuietTrailHeroAssetView', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({firstNamePromptSeenKey: true});
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
  });

  group('buildAppRoutes debug gating', () {
    // kDebugMode is a compile-time constant that is always true under
    // `flutter test`, so a release build's routing can't be exercised
    // directly here — asserting on the same includeDevPreview parameter
    // appRouter is built from is what makes this gating testable at all.
    test('omits the dev preview route when includeDevPreview is false', () {
      final paths = buildAppRoutes(
        includeDevPreview: false,
      ).whereType<GoRoute>().map((route) => route.path);

      expect(paths, isNot(contains('/dev/quiet-trail-hero-preview')));
    });

    test('includes the dev preview route when includeDevPreview is true', () {
      final paths = buildAppRoutes(
        includeDevPreview: true,
      ).whereType<GoRoute>().map((route) => route.path);

      expect(paths, contains('/dev/quiet-trail-hero-preview'));
    });

    test('profile and release (includeDevPreview false) never register '
        '/showcase', () {
      final paths = buildAppRoutes(
        includeDevPreview: false,
      ).whereType<GoRoute>().map((route) => route.path);

      expect(paths, isNot(contains('/showcase')));
    });

    test('debug (includeDevPreview true) registers /showcase', () {
      final paths = buildAppRoutes(
        includeDevPreview: true,
      ).whereType<GoRoute>().map((route) => route.path);

      expect(paths, contains('/showcase'));
    });

    test('the developer-only routes are the only difference between debug '
        'and release routing', () {
      List<String> pathsOf(bool includeDevPreview) => buildAppRoutes(
        includeDevPreview: includeDevPreview,
      ).whereType<GoRoute>().map((route) => route.path).toList();

      expect(
        pathsOf(true).where((path) => !pathsOf(false).contains(path)),
        unorderedEquals([
          '/showcase',
          '/dev/quiet-trail-hero-preview',
          // V2 Phase C: the Paced runtime's internal QA bench — its
          // synthetic pattern never reaches a profile or release build.
          '/dev/paced-qa',
        ]),
      );
      expect(pathsOf(false).every(pathsOf(true).contains), isTrue);
      // V2 Phase C: the memory page is Free and in every build.
      expect(pathsOf(false), contains('/memory'));
    });
  });
}
