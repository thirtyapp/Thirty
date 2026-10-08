import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Calls [onVisible] once, the first time [child] has been *meaningfully
/// visible*: at least [minVisibleFraction] of it inside the nearest
/// scrollable's viewport (or the screen, when there is none), continuously
/// for [dwell], while its route is the current one and its subtree is
/// active (not an offstage tab — go_router's indexed-stack branches disable
/// [TickerMode] for inactive tabs).
///
/// Built only on framework primitives — scroll-position listening plus a
/// post-frame geometry check — so it adds no dependency. It fires at most
/// once per State.
class ViewportVisibility extends StatefulWidget {
  const ViewportVisibility({
    required this.onVisible,
    required this.child,
    this.minVisibleFraction = 0.5,
    this.dwell = const Duration(seconds: 1),
    super.key,
  });

  final VoidCallback onVisible;
  final Widget child;

  /// Fraction of the child's height (or of the viewport's, for a child
  /// taller than the viewport) that must be inside the viewport.
  final double minVisibleFraction;

  /// How long the child must stay visible before it counts — a fling past
  /// it does not.
  final Duration dwell;

  @override
  State<ViewportVisibility> createState() => _ViewportVisibilityState();
}

class _ViewportVisibilityState extends State<ViewportVisibility> {
  ScrollPosition? _position;
  Timer? _dwellTimer;
  bool _fired = false;
  bool _active = true;
  bool _routeIsCurrent = true;
  ScrollableState? _scrollable;
  Rect _screen = Rect.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _active = TickerMode.valuesOf(context).enabled;
    _routeIsCurrent = ModalRoute.isCurrentOf(context) ?? true;
    _screen = Offset.zero & MediaQuery.sizeOf(context);
    _scrollable = Scrollable.maybeOf(context);

    final position = _scrollable?.position;
    if (position != _position) {
      _position?.removeListener(_scheduleCheck);
      _position = position?..addListener(_scheduleCheck);
    }
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(ViewportVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleCheck();
  }

  @override
  void dispose() {
    _position?.removeListener(_scheduleCheck);
    _dwellTimer?.cancel();
    super.dispose();
  }

  void _scheduleCheck() {
    if (_fired) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_fired || !mounted) return;
    if (!_isVisible()) {
      _dwellTimer?.cancel();
      _dwellTimer = null;
      return;
    }
    _dwellTimer ??= Timer(widget.dwell, () {
      _dwellTimer = null;
      if (_fired || !mounted || !_isVisible()) return;
      _fired = true;
      widget.onVisible();
    });
  }

  bool _isVisible() {
    if (!_active || !_routeIsCurrent) return false;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    final rect = _globalRect(box);

    final viewportBox = _scrollable?.context.findRenderObject();
    final viewport =
        viewportBox is RenderBox && viewportBox.attached && viewportBox.hasSize
        ? _globalRect(viewportBox)
        : _screen;

    final visible = rect.intersect(viewport);
    if (visible.width <= 0 || visible.height <= 0) return false;
    final required =
        math.min(rect.height, viewport.height) * widget.minVisibleFraction;
    return visible.height >= required;
  }

  static Rect _globalRect(RenderBox box) => MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );

  @override
  Widget build(BuildContext context) => widget.child;
}
