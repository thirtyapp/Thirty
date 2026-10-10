import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/circle_history_page.dart';
import '../../features/home/presentation/circle_record_detail_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/home/application/activity_catalog.dart';
import '../../features/home/presentation/memory_page.dart';
import '../../features/premium/presentation/premium_offer_page.dart';
import '../../features/settings/application/first_name_provider.dart';
import '../../features/settings/presentation/first_name_question_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/toolkit/domain/path_catalog.dart';
import '../../features/toolkit/presentation/choose_path_page.dart';
import '../../features/toolkit/presentation/path_review_page.dart';
import '../../features/toolkit/presentation/path_start_page.dart';
import '../../features/toolkit/presentation/routine_detail_page.dart';
import '../../features/toolkit/presentation/toolkit_page.dart';
import '../dev_preview/paced_qa_bench_page.dart';
import '../dev_preview/quiet_trail_hero_preview_page.dart';
import '../providers/theme_mode_provider.dart';
import '../showcase/design_system_showcase_page.dart';
import 'app_shell.dart';

/// The [PathTemplateId] named by a `/toolkit/paths/:template` location, or
/// `null` for an unknown name.
PathTemplateId? _templateFrom(GoRouterState state) =>
    PathTemplateId.values.asNameMap()[state.pathParameters['template']];

/// The route list `appRouter` is built from. Extracted to a standalone,
/// `@visibleForTesting` function so the debug-only gating below can be
/// verified directly — `kDebugMode` is a compile-time constant that is
/// always `true` under `flutter test`, so a real release build can't be
/// exercised from a test; asserting on [includeDevPreview] instead lets
/// the gating logic itself be checked without one.
///
/// **V2 Phase D — Today | Toolkit | You.** The V1 Plans and Insights
/// branches are retired (PRODUCT_V2_CONTRACT: Coach and Insights retired
/// as pillars; Plans replaced by Paths). The Toolkit is the one Premium
/// destination: the Path under way, maintenance and the user's routines,
/// with its Paths and routines pushed inside its branch. History, which
/// Insights used to host, is reached from You. An old `/plans…` or
/// `/insights` location leads to the Toolkit, never to a dead page. Each
/// shell branch keeps its own independent Navigator, so switching tabs
/// never disposes another branch's state.
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
        // V2 Phase D: the Toolkit — reachable regardless of entitlement;
        // what each page offers depends on it, never whether it opens.
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: ToolkitPage.location,
              builder: (context, state) => const ToolkitPage(),
              routes: [
                GoRoute(
                  path: 'paths',
                  builder: (context, state) => const ChoosePathPage(),
                  routes: [
                    // An unknown Path returns to the Toolkit rather than
                    // guessing one.
                    GoRoute(
                      path: ':template',
                      redirect: (context, state) => _templateFrom(state) == null
                          ? ToolkitPage.location
                          : null,
                      builder: (context, state) =>
                          PathStartPage(template: _templateFrom(state)!),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'review',
                  builder: (context, state) => const PathReviewPage(),
                ),
                GoRoute(
                  path: 'routine/:id',
                  builder: (context, state) =>
                      RoutineDetailPage(routineId: state.pathParameters['id']!),
                ),
              ],
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
    // V2 Phase D: the retired V1 Plans and Insights locations lead to the
    // Toolkit, never to a page that no longer exists.
    GoRoute(path: '/plans', redirect: (context, state) => ToolkitPage.location),
    GoRoute(
      path: '/plans/:planId',
      redirect: (context, state) => ToolkitPage.location,
    ),
    GoRoute(
      path: '/insights',
      redirect: (context, state) => ToolkitPage.location,
    ),
    // History: every recorded Circle — reached from You (V2 Phase D; it
    // used to sit inside Insights).
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
      builder: (context, state) =>
          CircleRecordDetailPage(localDate: state.pathParameters['date']!),
    ),
    // "What THIRTY remembers" (V2 Phase C): the Free memory page, reached
    // from You, from a closed Circle's acknowledgement and from a need with
    // nothing left to suggest. Pushed over the shell, like a record.
    GoRoute(
      path: '/memory',
      builder: (context, state) => MemoryPage(
        need: Intention.values.asNameMap()[state.uri.queryParameters['need']],
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
    // Developer-only routes: registered in debug builds only, never in
    // profile or release ([includeDevPreview] is `kDebugMode` for
    // [appRouter]), so no link, deep link or typed location can reach them
    // there.
    if (includeDevPreview) ...[
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
      GoRoute(
        path: '/dev/quiet-trail-hero-preview',
        builder: (context, state) => const QuietTrailHeroPreviewPage(),
      ),
      // V2 Phase C — the Paced runtime's internal QA bench (synthetic,
      // neutral pattern; never in profile or release builds).
      GoRoute(
        path: PacedQaBenchPage.location,
        builder: (context, state) => const PacedQaBenchPage(),
      ),
    ],
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

/// THIRTY's single, shared router configuration ([createAppRouter]).
/// Created once at module load and reused for the app's lifetime — never
/// rebuilt from a widget's build method.
final GoRouter appRouter = createAppRouter();

/// Builds THIRTY's router configuration. Production builds exactly one —
/// [appRouter]; the debug-only QA-1 harness builds a fresh one per QA
/// session, so each session starts with no navigation or page state left
/// from the last.
///
/// `/showcase` (the design-system review page) and the TEMPORARY
/// `/dev/quiet-trail-hero-preview` are developer-only routes — see
/// [buildAppRoutes] — registered only when `kDebugMode` is true, so they
/// do not exist in release or profile builds.
GoRouter createAppRouter({String? initialLocation}) => GoRouter(
  initialLocation:
      initialLocation ??
      (kDebugMode && _debugInitialLocation.isNotEmpty
          ? _debugInitialLocation
          : '/'),
  routes: buildAppRoutes(includeDevPreview: kDebugMode),
  redirect: (context, state) => firstUseRedirect(
    promptSeen: ProviderScope.containerOf(
      context,
      listen: false,
    ).read(firstNamePromptSeenProvider),
    location: state.matchedLocation,
  ),
);
