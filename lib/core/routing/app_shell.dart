import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      bottomNavigationBar: NavigationBar(
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
    );
  }
}
