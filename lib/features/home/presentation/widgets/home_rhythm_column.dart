import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// One gap of Home's vertical rhythm: its usual height, and the tighter
/// height it may take in a near-fit layout.
typedef HomeRhythmGap = ({double normal, double compact});

/// One further tightening step for a running Circle: how much more each gap
/// (beyond its compact height) and each child (beyond its
/// [HomeRhythmColumn.compactReductions]) may give, and how much of
/// [HomeRhythmColumn.minClearance] may be given up. Steps are taken in
/// order, each only as far as still needed, and spread evenly within the
/// step.
typedef HomeRhythmStep = ({
  List<double> gaps,
  List<double> children,
  double clearance,
});

/// The one child Home may trim, as a last resort, to put the last child
/// fully on the first screen: the child at [index] is laid out at most
/// [maxFraction] shorter (it must scale down to fit, e.g. via a
/// `FittedBox`). [progress] (0 → 1) eases the trim in, so the child never
/// jumps from the size it had a moment earlier. With [hold], no new trim
/// is made once the column has been laid out, and the child keeps exactly
/// the trim it already has — so it never changes size while the rest of the
/// column changes around it.
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

  /// All of the above, and as many of [HomeRhythmColumn.tightSteps] as
  /// needed.
  tightened,

  /// All of the above, and the [HomeRhythmColumn.trim] child trimmed by
  /// exactly what was still missing.
  trimmed,
}

/// Home's hero column — Circle, greeting, Today card, Start Circle —
/// stacked top to bottom and centred, in their normal order.
///
/// Near fit only: when the usual [gaps] would leave the last child (the
/// Circle's action) less than [minClearance] above [fitHeight], the column
/// tightens step by step and stops at the first step that fits
/// ([HomeRhythmFit]): the compact gaps; then also each child's
/// [compactReductions] (the child is laid out that much shorter and must
/// give the room up itself, e.g. the Today card's padding); then the
/// [tightSteps]' spacing, in order and only as far as needed; then, only if
/// [trim] allows it, the trim child by exactly the remaining shortfall,
/// never more than its `maxFraction`; and only last any clearance the
/// steps may give up. Any larger overflow (small phones, large text)
/// keeps the usual rhythm and simply scrolls; a layout that already fits is
/// untouched. Decided in one layout pass, so the rhythm never jumps.
class HomeRhythmColumn extends MultiChildRenderObjectWidget {
  const HomeRhythmColumn({
    required super.children,
    required this.gaps,
    required this.fitHeight,
    required this.minClearance,
    this.compactReductions = const [],
    this.tightSteps = const [],
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

  /// Further tightening once the compact children are not enough either.
  final List<HomeRhythmStep> tightSteps;

  /// The last-resort trim, or null when the column may never trim.
  final HomeRhythmTrim? trim;

  @override
  RenderHomeRhythmColumn createRenderObject(BuildContext context) =>
      RenderHomeRhythmColumn(
        gaps,
        fitHeight,
        minClearance,
        compactReductions,
        tightSteps,
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
      ..tightSteps = tightSteps
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
    this._tightSteps,
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

  List<HomeRhythmStep> _tightSteps;
  set tightSteps(List<HomeRhythmStep> value) {
    _tightSteps = value;
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

  /// Whether a layout has already been shown: until then there is no
  /// earlier size to hold.
  bool _laidOut = false;

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

  static double _sum(Iterable<double> values) =>
      values.fold(0.0, (sum, v) => sum + v);

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
    final holding = _trim?.hold == true && _laidOut;
    final held = holding ? _trimmed : 0.0;
    if (held > 0) heights[_trim!.index] -= held;
    final childrenHeight = _sum(heights);
    final normal = childrenHeight + _sum(_gaps.map((g) => g.normal));
    final compactGaps = childrenHeight + _sum(_gaps.map((g) => g.compact));
    final reductions = [
      for (var i = 0; i < heights.length; i++) _reductionAt(i),
    ];
    final compactChildren = compactGaps - _sum(reductions);
    final room = _fitHeight - _minClearance;

    final previousFit = _fit;
    final extraGaps = List.filled(_gaps.length, 0.0);
    final extraChildren = List.filled(heights.length, 0.0);
    _trimmed = held;
    if (normal <= room) {
      _fit = HomeRhythmFit.usual;
    } else if (compactGaps <= room) {
      _fit = HomeRhythmFit.compactGaps;
    } else if (compactChildren <= room) {
      _fit = HomeRhythmFit.compactChildren;
    } else {
      // Spacing first (the steps' gaps and children, in order); then the
      // trim, where allowed, so the action keeps its full clearance; and
      // only last the clearance the steps may give up.
      var deficit = compactChildren - room;
      for (final step in _tightSteps) {
        final capacity = _sum(step.gaps) + _sum(step.children);
        if (capacity <= 0 || deficit <= 0) continue;
        final share = math.min(deficit, capacity) / capacity;
        for (var i = 0; i < extraGaps.length; i++) {
          extraGaps[i] += step.gaps[i] * share;
        }
        for (var i = 0; i < extraChildren.length; i++) {
          extraChildren[i] += step.children[i] * share;
        }
        deficit -= math.min(deficit, capacity);
      }
      final clearance = _sum(_tightSteps.map((s) => s.clearance));
      final trim = _trim;
      final trimRoom = trim == null || holding
          ? 0.0
          : heights[trim.index] * trim.maxFraction;
      if (deficit <= 0) {
        _fit = HomeRhythmFit.tightened;
      } else if (deficit <= trimRoom) {
        _fit = HomeRhythmFit.trimmed;
        _trimmed = deficit * trim!.progress.value;
      } else if (deficit <= clearance) {
        _fit = HomeRhythmFit.tightened;
      } else if (deficit - clearance <= trimRoom) {
        _fit = HomeRhythmFit.trimmed;
        _trimmed = (deficit - clearance) * trim!.progress.value;
      } else {
        extraGaps.fillRange(0, extraGaps.length, 0);
        extraChildren.fillRange(0, extraChildren.length, 0);
        _fit = HomeRhythmFit.usual;
        // Held: still too tall, so keep the compaction it already had rather
        // than relaxing into the usual rhythm (no reflow on Start).
        if (holding && previousFit != HomeRhythmFit.usual) {
          _fit = previousFit == HomeRhythmFit.compactGaps
              ? HomeRhythmFit.compactGaps
              : HomeRhythmFit.compactChildren;
        }
      }
    }

    final reduceChildren = _fit.index >= HomeRhythmFit.compactChildren.index;
    if (reduceChildren || _trimmed > 0) {
      var index = 0;
      for (var child = firstChild; child != null; child = childAfter(child)) {
        final isTrimmed = _trimmed > 0 && index == _trim!.index;
        // A held trim is already taken out of heights[index].
        final reduction =
            (reduceChildren ? reductions[index] + extraChildren[index] : 0) +
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
        y += _fit == HomeRhythmFit.usual
            ? gap.normal
            : gap.compact - extraGaps[index];
      }
      index++;
    }
    size = constraints.constrain(Size(width, y));
    _laidOut = true;
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
    var height = _sum(_gaps.map((g) => g.normal));
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

/// The space above, between and below a [HomeSqueezePair]'s two children.
typedef HomeSqueezeSpacing = ({double top, double middle, double bottom});

/// Two children stacked with [spacing] above, between and below them — and
/// that spacing only, never the children, gives up room when the pair is
/// laid out shorter than it would like (Home's near-fit rhythm,
/// [HomeRhythmColumn]): towards each of [steps] in turn, each only as far as
/// needed. Otherwise exactly [spacing].
class HomeSqueezePair extends MultiChildRenderObjectWidget {
  HomeSqueezePair({
    required Widget first,
    required Widget second,
    required this.spacing,
    this.steps = const [],
    this.crossAxisAlignment = CrossAxisAlignment.center,
    super.key,
  }) : super(children: [first, second]);

  final HomeSqueezeSpacing spacing;
  final List<HomeSqueezeSpacing> steps;

  /// [CrossAxisAlignment.start] or [CrossAxisAlignment.center].
  final CrossAxisAlignment crossAxisAlignment;

  @override
  RenderHomeSqueezePair createRenderObject(BuildContext context) =>
      RenderHomeSqueezePair(spacing, steps, crossAxisAlignment);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderHomeSqueezePair renderObject,
  ) {
    renderObject
      ..spacing = spacing
      ..steps = steps
      ..crossAxisAlignment = crossAxisAlignment;
  }
}

class _SqueezeParentData extends ContainerBoxParentData<RenderBox> {}

class RenderHomeSqueezePair extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SqueezeParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SqueezeParentData> {
  RenderHomeSqueezePair(this._spacing, this._steps, this._crossAxisAlignment);

  HomeSqueezeSpacing _spacing;
  set spacing(HomeSqueezeSpacing value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  List<HomeSqueezeSpacing> _steps;
  set steps(List<HomeSqueezeSpacing> value) {
    _steps = value;
    markNeedsLayout();
  }

  CrossAxisAlignment _crossAxisAlignment;
  set crossAxisAlignment(CrossAxisAlignment value) {
    if (value == _crossAxisAlignment) return;
    _crossAxisAlignment = value;
    markNeedsLayout();
  }

  /// The spacing the last layout used.
  HomeSqueezeSpacing get usedSpacing => _used;
  late HomeSqueezeSpacing _used = _spacing;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SqueezeParentData) {
      child.parentData = _SqueezeParentData();
    }
  }

  static double _total(HomeSqueezeSpacing s) => s.top + s.middle + s.bottom;

  HomeSqueezeSpacing _spacingFor(double contentHeight, BoxConstraints c) {
    var current = _spacing;
    if (!c.hasBoundedHeight) return current;
    var excess = contentHeight + _total(current) - c.maxHeight;
    for (final step in _steps) {
      if (excess <= 0) break;
      final room = _total(current) - _total(step);
      if (room <= 0) continue;
      final t = math.min(excess, room) / room;
      current = (
        top: current.top - (current.top - step.top) * t,
        middle: current.middle - (current.middle - step.middle) * t,
        bottom: current.bottom - (current.bottom - step.bottom) * t,
      );
      excess -= math.min(excess, room);
    }
    return current;
  }

  @override
  void performLayout() {
    final first = firstChild!;
    final second = childAfter(first)!;
    final loose = BoxConstraints(maxWidth: constraints.maxWidth);
    first.layout(loose, parentUsesSize: true);
    second.layout(loose, parentUsesSize: true);
    _used = _spacingFor(first.size.height + second.size.height, constraints);
    final width = constraints.constrainWidth(
      math.max(first.size.width, second.size.width),
    );
    double x(RenderBox child) =>
        _crossAxisAlignment == CrossAxisAlignment.center
        ? (width - child.size.width) / 2
        : 0;
    (first.parentData! as _SqueezeParentData).offset = Offset(
      x(first),
      _used.top,
    );
    (second.parentData! as _SqueezeParentData).offset = Offset(
      x(second),
      _used.top + first.size.height + _used.middle,
    );
    size = constraints.constrain(
      Size(width, first.size.height + second.size.height + _total(_used)),
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    firstChild!.getMinIntrinsicWidth(double.infinity),
    childAfter(firstChild!)!.getMinIntrinsicWidth(double.infinity),
  );

  @override
  double computeMaxIntrinsicWidth(double height) => math.max(
    firstChild!.getMaxIntrinsicWidth(double.infinity),
    childAfter(firstChild!)!.getMaxIntrinsicWidth(double.infinity),
  );

  @override
  double computeMinIntrinsicHeight(double width) =>
      firstChild!.getMinIntrinsicHeight(width) +
      childAfter(firstChild!)!.getMinIntrinsicHeight(width) +
      _total(_spacing);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      firstChild!.getMaxIntrinsicHeight(width) +
      childAfter(firstChild!)!.getMaxIntrinsicHeight(width) +
      _total(_spacing);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
