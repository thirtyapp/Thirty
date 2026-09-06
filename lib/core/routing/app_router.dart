import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/circle_history_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/plans/presentation/plan_path_page.dart';
import '../dev_preview/quiet_trail_hero_preview_page.dart';
import '../providers/theme_mode_provider.dart';
import '../showcase/design_system_showcase_page.dart';

/// The route list `appRouter` is built from. Extracted to a standalone,
/// `@visibleForTesting` function so the debug-only gating below can be
/// verified directly — `kDebugMode` is a compile-time constant that is
/// always `true` under `flutter test`, so a real release build can't be
/// exercised from a test; asserting on [includeDevPreview] instead lets
/// the gating logic itself be checked without one.
@visibleForTesting
List<RouteBase> buildAppRoutes({required bool includeDevPreview}) {
  return [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/history',
      builder: (context, state) => const CircleHistoryPage(),
    ),
    // Reachable by direct navigation always (tests/DI overrides use this
    // freely); `home_page.dart`'s AppBar only links to it when
    // `premiumEntitlementProvider` is true — see that provider's own doc
    // comment (`../premium/premium_access.dart`) for why visibility, not
    // this route's registration, is the actual access seam.
    GoRoute(
      path: '/plans',
      builder: (context, state) => const PlanPathPage(),
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
