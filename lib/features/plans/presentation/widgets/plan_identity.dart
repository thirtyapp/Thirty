import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../home/application/world_scene_resolution.dart';
import '../../domain/plan_catalog.dart';
import '../../domain/plan_ids.dart';

/// A Plan's visual identity on Plans and Your Path (founder decisions,
/// 2026-10-01): a quiet tint, a drawn mark and one fixed World scene.
///
/// The scene is always one of the Plan's *own* stages, so the artwork
/// shows a place the Plan genuinely leads to — never a World borrowed for
/// mood. It is resolved through the approved World art manifest at the
/// current daypart, exactly like Home's Today card.
class PlanIdentity {
  const PlanIdentity._({
    required this.sceneStageIndex,
    required this.light,
    required this.dark,
    required this.mark,
  });

  /// The stage whose World scene represents this Plan.
  final int sceneStageIndex;

  final PlanTone light;
  final PlanTone dark;
  final PlanMark mark;

  PlanTone toneFor(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// This Plan's Card artwork at [now]'s daypart.
  String cardAssetAt(PlanId planId, DateTime now) => resolveWorldArt(
    stageAt(planId, sceneStageIndex).activityId,
    now,
  ).cardAsset;

  static PlanIdentity of(PlanId planId) => switch (planId) {
    // Stage 3, the 30-minute walk → Quiet Trail.
    PlanId.moreEnergyPath => const PlanIdentity._(
      sceneStageIndex: 2,
      // Home's Today chip pair: Mist Sage behind Circle Sage.
      light: PlanTone(fill: Color(0xFFE9EEE6), mark: Color(0xFF67735A)),
      dark: PlanTone(fill: Color(0xFF525A49), mark: Color(0xFFB4C1A6)),
      mark: PlanMark.sprout,
    ),
    // Stages 1 and 4, tidy one surface → Garden Window tend.
    PlanId.clearerHeadPath => const PlanIdentity._(
      sceneStageIndex: 0,
      // Mist blue-grey, after Still Lake's restrained grey-blue wash.
      light: PlanTone(fill: Color(0xFFE6EBEE), mark: Color(0xFF5F7182)),
      dark: PlanTone(fill: Color(0xFF47515A), mark: Color(0xFFB3C2CE)),
      mark: PlanMark.aperture,
    ),
    // Stages 1, 3 and 4 are breathing pauses → Still Lake breathe.
    PlanId.gentlerPacePath => const PlanIdentity._(
      sceneStageIndex: 0,
      // Warm sand, between Cream and Warm Stone.
      light: PlanTone(fill: Color(0xFFF2EBDF), mark: Color(0xFF85694A)),
      dark: PlanTone(fill: Color(0xFF575043), mark: Color(0xFFD6C3A3)),
      mark: PlanMark.nestedArcs,
    ),
  };
}

/// A Plan's tint: [fill] behind its mark, [mark] for the mark and for
/// closed progress nodes.
class PlanTone {
  const PlanTone({required this.fill, required this.mark});

  final Color fill;
  final Color mark;
}

enum PlanMark { sprout, aperture, nestedArcs }

/// The Plan's mark in its tinted circle. Decorative: the Plan's name is
/// always beside it.
class PlanIdentityBadge extends StatelessWidget {
  const PlanIdentityBadge({required this.planId, this.size = 48, super.key});

  final PlanId planId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final identity = PlanIdentity.of(planId);
    final tone = identity.toneFor(Theme.of(context).brightness);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: tone.fill),
        alignment: Alignment.center,
        child: CustomPaint(
          size: Size.square(size * 0.5),
          painter: PlanMarkPainter(mark: identity.mark, color: tone.mark),
        ),
      ),
    );
  }
}

/// Draws a [PlanMark] as a single-weight line drawing, so the three marks
/// read as one family.
class PlanMarkPainter extends CustomPainter {
  const PlanMarkPainter({required this.mark, required this.color});

  final PlanMark mark;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Offset p(double x, double y) => Offset(x * s, y * s);

    switch (mark) {
      case PlanMark.sprout:
        // A stem rising from the ground, with two opening leaves.
        canvas.drawPath(
          Path()
            ..moveTo(p(0.5, 0.95).dx, p(0.5, 0.95).dy)
            ..quadraticBezierTo(
              p(0.5, 0.6).dx,
              p(0.5, 0.6).dy,
              p(0.5, 0.42).dx,
              p(0.5, 0.42).dy,
            ),
          paint,
        );
        canvas.drawPath(_leaf(p(0.5, 0.62), p(0.12, 0.38), s * 0.13), paint);
        canvas.drawPath(_leaf(p(0.5, 0.42), p(0.88, 0.1), s * 0.14), paint);
      case PlanMark.aperture:
        // An open frame with air moving through its gap.
        final frame = Path()
          ..moveTo(p(0.72, 0.1).dx, p(0.72, 0.1).dy)
          ..lineTo(p(0.22, 0.1).dx, p(0.22, 0.1).dy)
          ..quadraticBezierTo(
            p(0.08, 0.1).dx,
            p(0.08, 0.1).dy,
            p(0.08, 0.24).dx,
            p(0.08, 0.24).dy,
          )
          ..lineTo(p(0.08, 0.76).dx, p(0.08, 0.76).dy)
          ..quadraticBezierTo(
            p(0.08, 0.9).dx,
            p(0.08, 0.9).dy,
            p(0.22, 0.9).dx,
            p(0.22, 0.9).dy,
          )
          ..lineTo(p(0.78, 0.9).dx, p(0.78, 0.9).dy)
          ..quadraticBezierTo(
            p(0.92, 0.9).dx,
            p(0.92, 0.9).dy,
            p(0.92, 0.76).dx,
            p(0.92, 0.76).dy,
          )
          ..lineTo(p(0.92, 0.62).dx, p(0.92, 0.62).dy);
        canvas.drawPath(frame, paint);
        canvas.drawPath(
          Path()
            ..moveTo(p(0.26, 0.5).dx, p(0.26, 0.5).dy)
            ..cubicTo(
              p(0.42, 0.36).dx,
              p(0.42, 0.36).dy,
              p(0.56, 0.64).dx,
              p(0.56, 0.64).dy,
              p(0.72, 0.48).dx,
              p(0.72, 0.48).dy,
            )
            ..quadraticBezierTo(
              p(0.84, 0.36).dx,
              p(0.84, 0.36).dy,
              p(1.0, 0.36).dx,
              p(1.0, 0.36).dy,
            ),
          paint,
        );
      case PlanMark.nestedArcs:
        // Three nested arcs settling onto one ground line.
        final centre = p(0.5, 0.82);
        for (final r in [0.42, 0.28, 0.14]) {
          canvas.drawArc(
            Rect.fromCircle(center: centre, radius: r * s),
            math.pi,
            math.pi,
            false,
            paint,
          );
        }
    }
  }

  /// A pointed leaf from [base] to [tip], bowed by [bulge].
  Path _leaf(Offset base, Offset tip, double bulge) {
    final mid = Offset.lerp(base, tip, 0.5)!;
    final dir = tip - base;
    final normal = Offset(-dir.dy, dir.dx) / dir.distance * bulge;
    return Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        mid.dx + normal.dx,
        mid.dy + normal.dy,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        mid.dx - normal.dx,
        mid.dy - normal.dy,
        base.dx,
        base.dy,
      );
  }

  @override
  bool shouldRepaint(PlanMarkPainter oldDelegate) =>
      oldDelegate.mark != mark || oldDelegate.color != color;
}
