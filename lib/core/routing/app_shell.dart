import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// THIRTY's primary four-destination navigation shell — Batch B
/// (`THIRTY_STEP1_FINAL_IA_AND_IMPLEMENTATION_CONTRACT_2026-09-09.md`
/// §2/§3: Today | Plans | Insights | Journal).
///
/// [navigationShell] gives each of the four branches its own independent
/// `Navigator`, preserved across tab switches
/// (`StatefulShellRoute.indexedStack`'s own guarantee) — switching tabs
/// never disposes another branch's state, scroll position or pushed
/// sub-route. Settings and Premium are deliberately not branches here —
/// they stay top-level pushed routes reachable from every branch's own
/// AppBar/content (§2), so switching tabs never touches them, and they
/// pop back to whichever tab opened them, unchanged from today.
///
/// Re-tapping the already-active destination pops that branch back to its
/// root — the one back-navigation detail the contract left to
/// implementation discretion (§3), matching standard Material bottom-nav
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
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Journal',
          ),
        ],
      ),
    );
  }
}
