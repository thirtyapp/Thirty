import 'package:flutter/material.dart';

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
class ThirtyAppBar extends StatefulWidget implements PreferredSizeWidget {
  const ThirtyAppBar({required this.title, super.key});

  final Widget title;

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
    return AppBar(
      title: widget.title,
      shape: Border(
        bottom: _scrolledUnder
            ? BorderSide(color: colors.divider)
            : BorderSide.none,
      ),
    );
  }
}
