import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/design_tokens.dart';

/// THIRTY's primary navigation shell — **Today | Plans | Insights | You**
/// (ADR-024 §2, B7), the frozen IA.
///
/// One job per tab: Today, what to do now; Plans, where several Circles are
/// going; Insights, what the user's own record shows and one useful change;
/// You, what is theirs and how THIRTY behaves. Phase D's Toolkit is retired
/// before release; the Circles the user kept live in Yours, under You.
/// Every tab opens on Free too: a tab never opens the Premium offer and
/// carries no badge or lock. "You" is a calm personal-control hub ("my
/// THIRTY experience and data"), never an account/profile/social-identity
/// system.
///
/// [navigationShell] gives each branch its own independent `Navigator`,
/// preserved across tab switches (`StatefulShellRoute.indexedStack`'s own
/// guarantee) — switching tabs never disposes another branch's state,
/// scroll position or pushed sub-route. The Premium offer is deliberately
/// not a branch — it stays a top-level pushed route, so switching tabs never
/// touches it, and it pops back to whichever tab opened it.
///
/// Re-tapping the already-active destination pops that branch back to its
/// root — the one back-navigation detail the contract left to
/// implementation discretion, matching standard Material bottom-nav
/// convention.
///
/// Phase A3: the bar floats inside a [FloatingNavSurface] inset from the
/// screen edges, rather than as a full-width band. Only its container
/// changed — it is still the same [NavigationBar], with the same
/// labels, icons and `goBranch` behavior. The side margin is
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
                // Phase D1: Today is the Circle itself — a ring, thicker
                // when selected.
                NavigationDestination(
                  icon: TodayRingIcon(),
                  selectedIcon: TodayRingIcon(selected: true),
                  label: 'Today',
                ),
                // ADR-024 B4: a direction over several Circles — a
                // signpost, never a progress ring.
                NavigationDestination(
                  icon: Icon(Icons.signpost_outlined),
                  selectedIcon: Icon(Icons.signpost),
                  label: 'Plans',
                ),
                // The Phase D1 Insights icon (founder-approved shell).
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

/// Today's nav icon (Phase D1, Design vision): a ring — the Circle — in
/// the nav's own icon colour, with a thicker stroke when selected, so
/// selection never rests on colour alone.
class TodayRingIcon extends StatelessWidget {
  const TodayRingIcon({this.selected = false, super.key});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final size = iconTheme.size ?? 24;
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: Container(
          width: size - 4,
          height: size - 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: iconTheme.color ?? const Color(0xFF000000),
              width: selected ? 3.5 : 2,
            ),
          ),
        ),
      ),
    );
  }
}
