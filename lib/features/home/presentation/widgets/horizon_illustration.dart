import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

/// A temporary placeholder illustration for the Circle Hero: a quiet sun
/// over a soft hill.
///
/// Deliberately not a photograph, a person, or a silhouette — Playbook
/// Ch.3 §3 requires everything inside the Circle to support it, never
/// compete with it, so this stays a simple, low-saturation mark rather
/// than detailed artwork (Brand Book §18, Illustration Style: "simple
/// shapes, a narrow palette, ... circular and flowing lines"). It is a
/// stand-in for a commissioned illustration, not a final asset.
class HorizonIllustration extends StatelessWidget {
  const HorizonIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return SizedBox(
      width: 96,
      height: 96,
      child: CustomPaint(
        painter: _HorizonPainter(
          sunColor: colors.primary.withValues(alpha: 0.55),
          hillColor: colors.secondary,
        ),
      ),
    );
  }
}

class _HorizonPainter extends CustomPainter {
  const _HorizonPainter({required this.sunColor, required this.hillColor});

  final Color sunColor;
  final Color hillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.62;

    final sunPaint = Paint()
      ..color = sunColor
      ..style = PaintingStyle.fill;
    final sunCenter = Offset(size.width / 2, horizonY);
    final sunRadius = size.width * 0.22;

    // Only the part of the sun above the horizon is drawn, so it reads as
    // rising rather than as a floating circle.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, horizonY));
    canvas.drawCircle(sunCenter, sunRadius, sunPaint);
    canvas.restore();

    final hillPaint = Paint()
      ..color = hillColor
      ..style = PaintingStyle.fill;
    final hillPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, horizonY + size.height * 0.06)
      ..quadraticBezierTo(
        size.width / 2,
        horizonY - size.height * 0.10,
        size.width,
        horizonY + size.height * 0.06,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hillPath, hillPaint);
  }

  @override
  bool shouldRepaint(covariant _HorizonPainter oldDelegate) {
    return oldDelegate.sunColor != sunColor ||
        oldDelegate.hillColor != hillColor;
  }
}
