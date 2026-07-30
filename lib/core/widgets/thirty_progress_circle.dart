import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// THIRTY's signature component: a calm, static circular progress
/// indicator for the daily 0–30 minute journey (expressed as 0.0–1.0).
///
/// This component only renders a given [progress] value. Animation, timer
/// logic, haptics and "The THIRTY Moment" are deliberately out of scope
/// here and layered on top by callers later.
class ThirtyProgressCircle extends StatelessWidget {
  const ThirtyProgressCircle({
    required this.progress,
    this.size = 160,
    this.strokeWidth = 12,
    this.child,
    this.semanticLabel,
    this.progressColor,
    this.trackColor,
    super.key,
  }) : assert(size > 0, 'size must be greater than 0'),
       assert(strokeWidth > 0, 'strokeWidth must be greater than 0'),
       assert(strokeWidth < size, 'strokeWidth must be smaller than size');

  /// Progress between 0.0 and 1.0. Values outside that range are clamped.
  final double progress;
  final double size;
  final double strokeWidth;

  /// Optional content centered inside the circle (e.g. a minutes label).
  final Widget? child;
  final String? semanticLabel;

  /// Defaults to the theme's primary color.
  final Color? progressColor;

  /// Defaults to a subtle, low-opacity variant of the theme's border color.
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final clampedProgress = progress.clamp(0.0, 1.0);
    final resolvedProgressColor = progressColor ?? colors.primary;
    final resolvedTrackColor =
        trackColor ?? colors.border.withValues(alpha: 0.6);

    return Semantics(
      label: semanticLabel ?? 'Voortgang',
      value: '${(clampedProgress * 100).round()}%',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _ProgressCirclePainter(
                progress: clampedProgress,
                strokeWidth: strokeWidth,
                progressColor: resolvedProgressColor,
                trackColor: resolvedTrackColor,
              ),
            ),
            ?child,
          ],
        ),
      ),
    );
  }
}

class _ProgressCirclePainter extends CustomPainter {
  const _ProgressCirclePainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.trackColor,
  });

  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) {
      return;
    }

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (progress >= 1) {
      // A round-capped arc swept through a full 2π overlaps its own start
      // and end caps, producing a visible seam/thickened spot. A plain
      // circle avoids that entirely once progress is complete.
      canvas.drawCircle(center, radius, progressPaint);
      return;
    }

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
