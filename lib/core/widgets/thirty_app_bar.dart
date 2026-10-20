import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/design_tokens.dart';

/// THIRTY's AppBar with a scrolled-under edge (Phase C5).
///
/// The AppBar sits on the page background (`AppTheme`'s `appBarTheme`),
/// so content scrolling under it used to be sliced along an invisible
/// line. This one draws a 1pt bottom edge in the divider colour while the
/// page's vertical scroll view is scrolled away from its top, and nothing
/// at the top. No elevation, surface tint or background change — only the
/// edge. Horizontal and nested scroll views never trigger it (the same
/// depth-0, vertical-only rule as Material's own scrolled-under state).
///
/// Home keeps its plain [AppBar] on purpose: its fading wordmark header is
/// part of the accepted Home composition.
///
/// [parentLocation] (B7): a page pushed over the shell can also be opened by
/// its own location, with nothing beneath it. Then Back — the arrow and the
/// system gesture alike — leads to this parent surface instead of out of
/// the app. A page opened from somewhere still returns there.
class ThirtyAppBar extends StatefulWidget implements PreferredSizeWidget {
  const ThirtyAppBar({required this.title, this.parentLocation, super.key});

  final Widget title;
  final String? parentLocation;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<ThirtyAppBar> createState() => _ThirtyAppBarState();
}

class _ThirtyAppBarState extends State<ThirtyAppBar> {
  ScrollNotificationObserverState? _observer;
  bool _scrolledUnder = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _observer?.removeListener(_handleScroll);
    _observer = ScrollNotificationObserver.maybeOf(context);
    _observer?.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _observer?.removeListener(_handleScroll);
    _observer = null;
    super.dispose();
  }

  void _handleScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification || notification.depth != 0) {
      return;
    }
    final metrics = notification.metrics;
    final scrolledUnder = switch (metrics.axisDirection) {
      AxisDirection.down => metrics.extentBefore > 0,
      AxisDirection.up => metrics.extentAfter > 0,
      AxisDirection.left || AxisDirection.right => _scrolledUnder,
    };
    if (scrolledUnder != _scrolledUnder) {
      setState(() => _scrolledUnder = scrolledUnder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final parent = widget.parentLocation;
    final router = GoRouter.maybeOf(context);
    final openedDirectly =
        parent != null &&
        router != null &&
        !(ModalRoute.of(context)?.canPop ?? true);
    void toParent() => router!.go(parent!);
    final bar = AppBar(
      title: widget.title,
      leading: openedDirectly ? BackButton(onPressed: toParent) : null,
      shape: Border(
        bottom: _scrolledUnder
            ? BorderSide(color: colors.divider)
            : BorderSide.none,
      ),
    );
    if (!openedDirectly) return bar;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) toParent();
      },
      child: bar,
    );
  }
}
