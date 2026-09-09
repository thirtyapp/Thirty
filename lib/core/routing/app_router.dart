import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/circle_history_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/insights/presentation/insights_page.dart';
import '../../features/plans/presentation/plan_path_page.dart';
import '../../features/premium/presentation/premium_offer_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../dev_preview/quiet_trail_hero_preview_page.dart';
import '../providers/theme_mode_provider.dart';
import '../showcase/design_system_showcase_page.dart';
import 'app_shell.dart';

/// The route list `appRouter` is built from. Extracted to a standalone,
/// `@visibleForTesting` function so the debug-only gating below can be
/// verified directly — `kDebugMode` is a compile-time constant that is
/// always `true` under `flutter test`, so a real release build can't be
/// exercised from a test; asserting on [includeDevPreview] instead lets
/// the gating logic itself be checked without one.
///
/// Batch B (`THIRTY_STEP1_FINAL_IA_AND_IMPLEMENTATION_CONTRACT_2026-09-09.md`
/// §2) replaces the previous flat route list with a
/// `StatefulShellRoute.indexedStack` of 4 branches — Today | Plans |
/// Insights | Journal — wrapped by [AppShell]'s bottom `NavigationBar`.
/// `/settings` and `/premium` stay top-level siblings, pushed from any
/// branch, exactly as before. Each branch keeps its own independent
/// Navigator, so switching tabs never disposes another branch's state.
@visibleForTesting
List<RouteBase> buildAppRoutes({required bool includeDevPreview}) {
  return [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomePage()),
          ],
        ),
        // Reachable regardless of entitlement, as a primary bottom-nav
        // destination — `PlanPathPage.build()` itself branches on
        // `premiumEntitlementProvider` (Batch A) to decide what content to
        // show; the route/branch is never gated.
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/plans',
              builder: (context, state) => const PlanPathPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/insights',
              builder: (context, state) => const InsightsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const CircleHistoryPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/premium',
      builder: (context, state) => const PremiumOfferPage(),
    ),
    GoRoute(
      path: '/showcase',
      builder: (context, state) {
        return Consumer(
          builder: (context, ref, _) {
            return DesignSystemShowcasePage(
              themeMode: ref.watch(themeModeProvider),
              onThemeModeChanged: (mode) =>
                  ref.read(themeModeProvider.notifier).setThemeMode(mode),
            );
          },
        );
      },
    ),
    // TEMPORARY — see quiet_trail_hero_preview_page.dart. Remove this
    // route and that file together once the Quiet Trail Hero visual
    // review is complete.
    if (includeDevPreview)
      GoRoute(
        path: '/dev/quiet-trail-hero-preview',
        builder: (context, state) => const QuietTrailHeroPreviewPage(),
      ),
  ];
}

/// Set via `--dart-define=THIRTY_DEBUG_ROUTE=/some/route` to have the app
/// open directly on a debug-only route on launch — the only practical way
/// to reach one on a mobile emulator, since this app has no deep-link
/// scheme configured. Has no effect outside debug mode or when unset, so
/// it never changes what a normal `flutter run` or any release build
/// shows.
const _debugInitialLocation = String.fromEnvironment('THIRTY_DEBUG_ROUTE');

/// THIRTY's single, shared router configuration. Created once at module
/// load and reused for the app's lifetime — never rebuilt from a widget's
/// build method.
///
/// `/showcase` is an internal developer route for reviewing the design
/// system; it is reachable only by navigating to it directly, not linked
/// from any product screen.
///
/// `/dev/quiet-trail-hero-preview` is a TEMPORARY, debug-only route — see
/// [buildAppRoutes] — present only when `kDebugMode` is true, so it does
/// not exist in release or profile builds.
final GoRouter appRouter = GoRouter(
  initialLocation: kDebugMode && _debugInitialLocation.isNotEmpty
      ? _debugInitialLocation
      : '/',
  routes: buildAppRoutes(includeDevPreview: kDebugMode),
);
