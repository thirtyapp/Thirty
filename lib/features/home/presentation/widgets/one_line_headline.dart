import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A headline that keeps to one line (S25 finding, 2026-10-12: "Good
/// evening, Amandine." wrapped, and the extra line pushed Start Circle
/// below the screen).
///
/// At [style]'s size, scaled by the system text size, when it fits — so a
/// short greeting looks exactly as designed. When it doesn't, the size
/// comes down just far enough to fit, but never below [minFontSize] nor
/// below the reader's own body text ([bodyFontSize], scaled): a headline
/// is never smaller than what the reader chose to read. Past that floor,
/// one line with an ellipsis. The line keeps the designed height either
/// way, so nothing below it moves with the length of a name. The whole
/// text stays the semantics label, so a screen reader hears all of it.
///
/// With [wrapPastMinimum] — enlarged system text, where Today already
/// scrolls — a text too long even at the floor wraps instead of being cut.
///
/// Sizes are worked out in on-screen pixels, after the system's (possibly
/// non-linear) text scaling, and drawn without scaling it again.
class OneLineHeadline extends StatelessWidget {
  const OneLineHeadline(
    this.text, {
    required this.style,
    required this.minFontSize,
    this.bodyFontSize = 16,
    this.textAlign = TextAlign.center,
    this.wrapPastMinimum = false,
    super.key,
  });

  final String text;
  final TextStyle style;
  final double minFontSize;
  final double bodyFontSize;
  final TextAlign textAlign;
  final bool wrapPastMinimum;

  /// The on-screen size [text] is drawn at within [maxWidth]: [designed]
  /// when it fits, otherwise the largest size down to [floor] that does;
  /// `null` when even [floor] doesn't.
  static double? fittingSize({
    required String text,
    required TextStyle style,
    required double designed,
    required double floor,
    required double maxWidth,
    required TextDirection textDirection,
  }) {
    double widthAt(double size) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: style.copyWith(fontSize: size),
        ),
        textDirection: textDirection,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final width = widthAt(designed);
    if (width <= maxWidth) return designed;
    // Width is close to proportional to size; step down from there for
    // kerning and rounding, half a point at a time.
    var size = math.max(floor, designed * maxWidth / width);
    while (widthAt(size) > maxWidth) {
      if (size <= floor) return null;
      size = math.max(floor, size - 0.5);
    }
    return size;
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final designed = scaler.scale(style.fontSize!);
    final floor = math.min(
      designed,
      math.max(minFontSize, scaler.scale(bodyFontSize)),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.hasBoundedWidth
            ? fittingSize(
                text: text,
                style: style,
                designed: designed,
                floor: floor,
                maxWidth: constraints.maxWidth,
                textDirection: Directionality.of(context),
              )
            : designed;
        final wrap = size == null && wrapPastMinimum;
        return Text(
          text,
          style: style.copyWith(fontSize: size ?? floor),
          // The line keeps the designed height whatever the size drawn.
          strutStyle: StrutStyle.fromTextStyle(
            style.copyWith(fontSize: designed),
            forceStrutHeight: true,
          ),
          textScaler: TextScaler.noScaling,
          textAlign: textAlign,
          maxLines: wrap ? null : 1,
          softWrap: wrap,
          overflow: wrap ? TextOverflow.clip : TextOverflow.ellipsis,
        );
      },
    );
  }
}
