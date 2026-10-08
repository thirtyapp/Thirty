import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/circle_history_page.dart';
import '../../features/home/presentation/circle_record_detail_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/insights/presentation/insights_page.dart';
import '../../features/plans/domain/plan_ids.dart';
import '../../features/plans/presentation/plan_detail_page.dart';
import '../../features/plans/presentation/plan_path_page.dart';
import '../../features/premium/presentation/premium_offer_page.dart';
import '../../features/settings/application/first_name_provider.dart';
import '../../features/settings/presentation/first_name_question_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../dev_preview/quiet_trail_hero_preview_page.dart';
import '../providers/theme_mode_provider.dart';
import '../showcase/design_system_showcase_page.dart';
import 'app_shell.dart';

/// The [PlanId] named by a `/plans/:planId` location, or `null` for an
/// unknown name.
PlanId? _planIdFrom(GoRouterState state) =>
    PlanId.values.asNameMap()[state.pathParameters['planId']];

/// The route list `appRouter` is built from. Extracted to a standalone,
/// `@visibleForTesting` function so the debug-only gating below can be
/// verified directly — `kDebugMode` is a compile-time constant that is
/// always `true` under `flutter test`, so a real release build can't be
/// exercised from a test; asserting on [includeDevPreview] instead lets
/// the gating logic itself be checked without one.
///
/// Batch B introduced a `StatefulShellRoute.indexedStack` of 4 branches —
/// originally Today | Plans | Insights | Journal. The founder's IA
/// correction ("Today | Plans | Insights | You" supersedes that) replaces
/// the `/history` branch with `/settings` (presented as "You" —
/// `../../features/settings/presentation/settings_page.dart`): Journal
/// is no longer a primary destination, its shared history now presents
/// inside Insights as a date-Circle calendar
/// (`../../features/insights/presentation/widgets/circle_history_calendar.dart`),
/// and `/settings` moves from a top-level pushed route into the shell
/// itself. `/history` and the new `/history/:date` record-detail route
/// stay registered as top-level, unlinked-from-primary-nav routes —
/// "may remain... for compatibility, export/delete, or record detail"
/// — never a second bottom-nav-equivalent destination. `/premium` stays
/// a top-level sibling, pushed from "You" exactly as it was pushed from
/// Settings before. Each shell branch keeps its own independent
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
              routes: [
                // One Plan's Your Path, inside the Plans branch so the
                // navigation bar stays and back returns to Plans. Like
                // `/plans` it is never gated: `PlanDetailPage` itself
                // shows the Free preview without entitlement. An unknown
                // id returns to `/plans` rather than guessing a Plan.
                GoRoute(
                  path: ':planId',
                  redirect: (context, state) =>
                      _planIdFrom(state) == null ? '/plans' : null,
                  builder: (context, state) =>
                      PlanDetailPage(planId: _planIdFrom(state)!),
                ),
              ],
            ),
          ],
        ),
        // Hosts the Free/shared history calendar unconditionally, plus
        // the existing Premium Insight interpretation surface — see
        // `InsightsPage`'s own doc comment for the exact split.
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/insights',
              builder: (context, state) => const InsightsPage(),
            ),
          ],
        ),
        // "You" — a calm personal-control hub, not an account. Reuses
        // the existing `SettingsPage` verbatim (its own AppBar title is
        // "You"); no new settings system, no login, no profile.
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
    // Compatibility/secondary surface only, since the founder IA
    // correction: no longer linked from any primary-nav element (Today's
    // old history icon and Settings' old history link are both gone —
    // see `home_page.dart` and `settings_page.dart`'s own doc comments).
    // Still the one place local export/delete/full-list access lives for
    // anything that needs it directly.
    GoRoute(
      path: '/history',
      builder: (context, state) => const CircleHistoryPage(),
    ),
    // One recorded local date's read-only detail — reached by tapping a
    // marked date on `CircleHistoryCalendar`. `:date` is a plain
    // `YYYY-MM-DD` local-date string (`core/utils/date_key.dart`'s
    // `dateKey` format), never containing a `/`, so it is always exactly
    // one path segment.
    GoRoute(
      path: '/history/:date',
      builder: (context, state) => CircleRecordDetailPage(
        localDate: state.pathParameters['date']!,
      ),
    ),
    // The one first-use question ("What should we call you?") — outside the
    // shell, so nothing else is reachable until it is resolved; see
    // [firstUseRedirect].
    GoRoute(
      path: firstNameQuestionLocation,
      builder: (context, state) => const FirstNameQuestionPage(),
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

/// Where the first-use name question lives.
const firstNameQuestionLocation = '/welcome/name';

/// THIRTY's one startup gate: until the first-use name question has been
/// resolved (a name saved or skipped — [firstNamePromptSeenProvider]),
/// every location leads to it; once resolved, it is never shown again and
/// its own location leads to Today. The question replaces the stack rather
/// than sitting under it, so Back can never return into it.
@visibleForTesting
String? firstUseRedirect({required bool promptSeen, required String location}) {
  final atQuestion = location == firstNameQuestionLocation;
  if (!promptSeen) return atQuestion ? null : firstNameQuestionLocation;
  return atQuestion ? '/' : null;
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
  redirect: (context, state) => firstUseRedirect(
    promptSeen: ProviderScope.containerOf(
      context,
      listen: false,
    ).read(firstNamePromptSeenProvider),
    location: state.matchedLocation,
  ),
);
