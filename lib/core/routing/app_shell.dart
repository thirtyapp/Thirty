import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/design_tokens.dart';

/// THIRTY's primary four-destination navigation shell.
///
/// Founder IA correction: **Today | Plans | Insights | You** supersedes
/// Batch B's original Today | Plans | Insights | Journal. Journal is no
/// longer a primary destination — its shared history now presents inside
/// Insights as a date-Circle calendar
/// (`../../features/insights/presentation/widgets/circle_history_calendar.dart`)
/// — and "You" (the existing `SettingsPage`, retitled) takes the fourth
/// slot. "You" is a calm personal-control hub ("my THIRTY experience and
/// data"), never an account/profile/social-identity system — no login,
/// avatar, or user-created identity is introduced here or anywhere else
/// by this change.
///
/// [navigationShell] gives each of the four branches its own independent
/// `Navigator`, preserved across tab switches
/// (`StatefulShellRoute.indexedStack`'s own guarantee) — switching tabs
/// never disposes another branch's state, scroll position or pushed
/// sub-route. Premium is deliberately not a branch here — it stays a
/// top-level pushed route reachable from "You" (and from the existing
/// Free-preview CTAs on Plans/Insights), so switching tabs never touches
/// it, and it pops back to whichever tab opened it, unchanged from
/// before this correction.
///
/// Re-tapping the already-active destination pops that branch back to its
/// root — the one back-navigation detail the contract left to
/// implementation discretion, matching standard Material bottom-nav
/// convention.
///
/// Phase A3: the bar floats inside a [FloatingNavSurface] inset from the
/// screen edges, rather than as a full-width band. Only its container
/// changed — it is still the same [NavigationBar], with the same four
/// destinations, labels, icons and `goBranch` behavior. The side margin is
/// deliberately `AppSpacing.m`, not the page gutter: at 200% text on a
/// 360pt screen every label must still fit, and the rule is to give up
/// margin before ever hiding or shrinking a label.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            0,
            AppSpacing.m,
            AppSpacing.s,
          ),
          child: FloatingNavSurface(
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onDestinationSelected,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Today',
                ),
                NavigationDestination(
                  icon: Icon(Icons.route_outlined),
                  selectedIcon: Icon(Icons.route),
                  label: 'Plans',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights),
                  label: 'Insights',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'You',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The floating bottom nav's single visual surface.
///
/// This container alone owns the bar's background color, its
/// [AppRadius.xl] corners and its shadow. The [NavigationBar] inside is
/// transparent (`navigationBarTheme.backgroundColor` in `app_theme.dart`)
/// and clipped to the same rounded shape, so no rectangular Material
/// surface can paint into the corners. An earlier version reused
/// `ThirtyCard`, whose dark-mode border sat *underneath* the bar's own
/// rectangular surface and so vanished at the corners, reading as flattened
/// or notched. There is deliberately no border here in either mode: in
/// dark mode the surface/background tone step alone separates the bar.
class FloatingNavSurface extends StatelessWidget {
  const FloatingNavSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final shadow = theme.brightness == Brightness.light
        ? AppShadows.light
        : AppShadows.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.xl,
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.xl,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
