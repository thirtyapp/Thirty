import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// One gap of Home's vertical rhythm: its usual height, and the tighter
/// height it may take in a near-fit layout.
typedef HomeRhythmGap = ({double normal, double compact});

/// The one child Home may trim, as a last resort, to put the last child
/// fully on the first screen: the child at [index] is laid out at most
/// [maxFraction] shorter (it must scale down to fit, e.g. via a
/// `FittedBox`). [progress] (0 → 1) eases the trim in, so the child never
/// jumps from the size it had a moment earlier. With [hold], no new trim
/// is made and the child keeps exactly the trim it already has — so it
/// never changes size while the rest of the column changes around it.
typedef HomeRhythmTrim = ({
  int index,
  double maxFraction,
  Animation<double> progress,
  bool hold,
});

/// How far [RenderHomeRhythmColumn] had to tighten to fit, in order.
enum HomeRhythmFit {
  /// The usual rhythm — it already fits, or overflow is too large and the
  /// page scrolls.
  usual,

  /// The compact gaps alone.
  compactGaps,

  /// The compact gaps, and each child's [HomeRhythmColumn.compactReductions].
  compactChildren,

  /// All of the above, and the [HomeRhythmColumn.trim] child trimmed by
  /// exactly what was still missing.
  trimmed,
}

/// Home's hero column — Circle, greeting, Today card, Start Circle —
/// stacked top to bottom and centred, in their normal order.
///
/// Near fit only: when the usual [gaps] would leave the last child (Start
/// Circle) less than [minClearance] above [fitHeight], the column tightens
/// step by step and stops at the first step that fits ([HomeRhythmFit]):
/// the compact gaps; then also each child's [compactReductions] (the child
/// is laid out that much shorter and must give the room up itself, e.g.
/// the Today card's padding); then, only if [trim] is given, the trim
/// child by exactly the remaining shortfall, never more than its
/// `maxFraction` (or, with `hold`, exactly the trim it already has). Any
/// larger overflow (small phones, large text) keeps the
/// usual rhythm and simply scrolls; a layout that already fits is
/// untouched. Decided in one layout pass, so the rhythm never jumps.
class HomeRhythmColumn extends MultiChildRenderObjectWidget {
  const HomeRhythmColumn({
    required super.children,
    required this.gaps,
    required this.fitHeight,
    required this.minClearance,
    this.compactReductions = const [],
    this.trim,
    super.key,
  }) : assert(gaps.length == children.length - 1),
       assert(
         compactReductions.length == 0 ||
             compactReductions.length == children.length,
       );

  final List<HomeRhythmGap> gaps;

  /// The height the column may fill before it runs past the fold.
  final double fitHeight;

  /// The least room kept below the last child when fitting it.
  final double minClearance;

  /// Per child, how much shorter it may be laid out once the compact gaps
  /// alone are not enough. Empty means none.
  final List<double> compactReductions;

  /// The last-resort trim, or null when the column may never trim.
  final HomeRhythmTrim? trim;

  @override
  RenderHomeRhythmColumn createRenderObject(BuildContext context) =>
      RenderHomeRhythmColumn(
        gaps,
        fitHeight,
        minClearance,
        compactReductions,
        trim,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderHomeRhythmColumn renderObject,
  ) {
    renderObject
      ..gaps = gaps
      ..fitHeight = fitHeight
      ..minClearance = minClearance
      ..compactReductions = compactReductions
      ..trim = trim;
  }
}

class _RhythmParentData extends ContainerBoxParentData<RenderBox> {}

class RenderHomeRhythmColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _RhythmParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _RhythmParentData> {
  RenderHomeRhythmColumn(
    this._gaps,
    this._fitHeight,
    this._minClearance,
    this._compactReductions,
    this._trim,
  );

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

  List<double> _compactReductions;
  set compactReductions(List<double> value) {
    _compactReductions = value;
    markNeedsLayout();
  }

  HomeRhythmTrim? _trim;
  set trim(HomeRhythmTrim? value) {
    if (value == _trim) return;
    if (attached) _trim?.progress.removeListener(markNeedsLayout);
    _trim = value;
    if (attached) _trim?.progress.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  /// How far the last layout had to tighten.
  HomeRhythmFit get fit => _fit;
  HomeRhythmFit _fit = HomeRhythmFit.usual;

  /// Whether the last layout used the compact gaps.
  bool get isCompact => _fit != HomeRhythmFit.usual;

  /// How much the last layout trimmed the [HomeRhythmColumn.trim] child.
  double get trimmed => _trimmed;
  double _trimmed = 0;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _trim?.progress.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _trim?.progress.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RhythmParentData) {
      child.parentData = _RhythmParentData();
    }
  }

  double _reductionAt(int index) =>
      _compactReductions.isEmpty ? 0 : _compactReductions[index];

  @override
  void performLayout() {
    final loose = BoxConstraints(maxWidth: constraints.maxWidth);
    final heights = <double>[];
    var widest = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      child.layout(loose, parentUsesSize: true);
      heights.add(child.size.height);
      if (child.size.width > widest) widest = child.size.width;
    }
    final held = _trim?.hold == true ? _trimmed : 0.0;
    if (held > 0) heights[_trim!.index] -= held;
    final childrenHeight = heights.fold(0.0, (sum, h) => sum + h);
    final normal = childrenHeight + _gaps.fold(0.0, (sum, g) => sum + g.normal);
    final compactGaps =
        childrenHeight + _gaps.fold(0.0, (sum, g) => sum + g.compact);
    final reductions = [
      for (var i = 0; i < heights.length; i++) _reductionAt(i),
    ];
    final compactChildren =
        compactGaps - reductions.fold(0.0, (sum, r) => sum + r);
    final room = _fitHeight - _minClearance;

    final previousFit = _fit;
    _trimmed = held;
    if (normal <= room) {
      _fit = HomeRhythmFit.usual;
    } else if (compactGaps <= room) {
      _fit = HomeRhythmFit.compactGaps;
    } else if (compactChildren <= room) {
      _fit = HomeRhythmFit.compactChildren;
    } else if (_trim case final trim?
        when !trim.hold &&
            compactChildren - room <= heights[trim.index] * trim.maxFraction) {
      _fit = HomeRhythmFit.trimmed;
      _trimmed = (compactChildren - room) * trim.progress.value;
    } else {
      _fit = HomeRhythmFit.usual;
      // Held: still too tall, so keep the compaction it already had rather
      // than relaxing into the usual rhythm (no reflow on Start).
      if (_trim?.hold == true && previousFit != HomeRhythmFit.usual) {
        _fit = previousFit == HomeRhythmFit.trimmed
            ? HomeRhythmFit.compactChildren
            : previousFit;
      }
    }

    final reduceChildren =
        _fit == HomeRhythmFit.compactChildren || _fit == HomeRhythmFit.trimmed;
    if (reduceChildren || _trimmed > 0) {
      var index = 0;
      for (var child = firstChild; child != null; child = childAfter(child)) {
        final isTrimmed = _trimmed > 0 && index == _trim!.index;
        // A held trim is already taken out of heights[index].
        final reduction =
            (reduceChildren ? reductions[index] : 0) +
            (isTrimmed && held == 0 ? _trimmed : 0);
        if (reduction > 0 || isTrimmed) {
          child.layout(
            loose.copyWith(maxHeight: heights[index] - reduction),
            parentUsesSize: true,
          );
        }
        index++;
      }
    }

    final width = constraints.hasBoundedWidth ? constraints.maxWidth : widest;
    var y = 0.0;
    var index = 0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final parentData = child.parentData! as _RhythmParentData;
      parentData.offset = Offset((width - child.size.width) / 2, y);
      y += child.size.height;
      if (index < _gaps.length) {
        final gap = _gaps[index];
        y += _fit == HomeRhythmFit.usual ? gap.normal : gap.compact;
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
