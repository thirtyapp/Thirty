import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// One gap of Home's vertical rhythm: its usual height, and the tighter
/// height it may take in a near-fit layout.
typedef HomeRhythmGap = ({double normal, double compact});

/// Home's hero column — Circle, greeting, Today card, Start Circle —
/// stacked top to bottom and centred, in their normal order.
///
/// Near fit only: when the usual [gaps] would leave the last child (Start
/// Circle) less than [minClearance] above [fitHeight], but the compact
/// gaps would not, the compact gaps are used so the CTA sits fully on the
/// first screen. Any larger overflow (small phones, large text) keeps the
/// usual rhythm and simply scrolls; a layout that already fits is
/// untouched. Decided in one layout pass, so the rhythm never jumps.
class HomeRhythmColumn extends MultiChildRenderObjectWidget {
  const HomeRhythmColumn({
    required super.children,
    required this.gaps,
    required this.fitHeight,
    required this.minClearance,
    super.key,
  }) : assert(gaps.length == children.length - 1);

  final List<HomeRhythmGap> gaps;

  /// The height the column may fill before it runs past the fold.
  final double fitHeight;

  /// The least room kept below the last child when fitting it.
  final double minClearance;

  @override
  RenderHomeRhythmColumn createRenderObject(BuildContext context) =>
      RenderHomeRhythmColumn(gaps, fitHeight, minClearance);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderHomeRhythmColumn renderObject,
  ) {
    renderObject
      ..gaps = gaps
      ..fitHeight = fitHeight
      ..minClearance = minClearance;
  }
}

class _RhythmParentData extends ContainerBoxParentData<RenderBox> {}

class RenderHomeRhythmColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _RhythmParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _RhythmParentData> {
  RenderHomeRhythmColumn(this._gaps, this._fitHeight, this._minClearance);

  List<HomeRhythmGap> _gaps;
  set gaps(List<HomeRhythmGap> value) {
    _gaps = value;
    markNeedsLayout();
  }

  double _fitHeight;
  set fitHeight(double value) {
    if (value == _fitHeight) return;
    _fitHeight = value;
    markNeedsLayout();
  }

  double _minClearance;
  set minClearance(double value) {
    if (value == _minClearance) return;
    _minClearance = value;
    markNeedsLayout();
  }

  /// Whether the last layout used the compact gaps.
  bool get isCompact => _isCompact;
  bool _isCompact = false;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RhythmParentData) {
      child.parentData = _RhythmParentData();
    }
  }

  @override
  void performLayout() {
    final childConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
    var childrenHeight = 0.0;
    var widest = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      child.layout(childConstraints, parentUsesSize: true);
      childrenHeight += child.size.height;
      if (child.size.width > widest) widest = child.size.width;
    }
    final normal = childrenHeight + _gaps.fold(0.0, (sum, g) => sum + g.normal);
    final compact =
        childrenHeight + _gaps.fold(0.0, (sum, g) => sum + g.compact);
    final room = _fitHeight - _minClearance;
    _isCompact = normal > room && compact <= room;

    final width = constraints.hasBoundedWidth ? constraints.maxWidth : widest;
    var y = 0.0;
    var index = 0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final parentData = child.parentData! as _RhythmParentData;
      parentData.offset = Offset((width - child.size.width) / 2, y);
      y += child.size.height;
      if (index < _gaps.length) {
        final gap = _gaps[index];
        y += _isCompact ? gap.compact : gap.normal;
      }
      index++;
    }
    size = constraints.constrain(Size(width, y));
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    var widest = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final w = child.getMinIntrinsicWidth(double.infinity);
      if (w > widest) widest = w;
    }
    return widest;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    var widest = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final w = child.getMaxIntrinsicWidth(double.infinity);
      if (w > widest) widest = w;
    }
    return widest;
  }

  double _intrinsicHeight(double width, bool max) {
    var height = _gaps.fold(0.0, (sum, g) => sum + g.normal);
    for (var child = firstChild; child != null; child = childAfter(child)) {
      height += max
          ? child.getMaxIntrinsicHeight(width)
          : child.getMinIntrinsicHeight(width);
    }
    return height;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _intrinsicHeight(width, false);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _intrinsicHeight(width, true);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
