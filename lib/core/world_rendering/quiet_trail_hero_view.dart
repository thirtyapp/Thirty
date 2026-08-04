import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../worlds/reference/quiet_trail_hero_scene.dart';

/// Renders a [QuietTrailHeroScene] as THIRTY's Circle Hero World
/// (WORLD_SYSTEM.md §5.A: "feels like a window rather than an icon").
///
/// The shapes drawn here follow
/// `docs/worlds/reference/QUIET_TRAIL_REFERENCE.md` — the approved,
/// frozen artistic reference for this World — read together with
/// `docs/illustration/ILLUSTRATION_LANGUAGE.md`'s line, colour and wash
/// vocabulary. This widget only interprets scene data it is given — it
/// does not read `recommendationProvider`, does not know what a
/// `Recommendation` is, and is not aware of Home. Whatever eventually
/// decides "today's recommendation is Quiet Trail" is responsible for
/// deriving a [QuietTrailHeroScene] (see `quietTrailHeroScene` in
/// `../worlds/reference/quiet_trail_hero_scene.dart`) and passing it here
/// — that wiring is a future, separate task (WORLD_SYSTEM.md §17: "The
/// Home screen must not hardcode Walking visuals").
///
/// Deliberately outside `lib/core/worlds`: that package stays Flutter-free
/// by design, and this widget exists only to paint one specific scene, not
/// to define how every future World renders.
///
/// The painted content fills its entire bounding rectangle edge to edge —
/// this widget does not clip itself — so a caller that later places it
/// inside a circular viewport (as the Circle Hero does today with
/// `HorizonIllustration`) gets a clean crop with no visible seam.
class QuietTrailHeroView extends StatelessWidget {
  const QuietTrailHeroView({required this.scene, super.key});

  final QuietTrailHeroScene scene;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    // Decorative only (WORLD_SYSTEM.md, Design Principles: "The World is a
    // place, not an illustration" that competes for a screen reader's
    // attention) — whatever the scene eventually accompanies already
    // describes itself in words; this view must never announce a second,
    // duplicate description.
    return ExcludeSemantics(
      child: CustomPaint(
        painter: _QuietTrailHeroPainter(scene: scene, colors: colors),
      ),
    );
  }
}

/// A fixed seed, not a random one: every irregularity below (the canopy's
/// uneven lobes, the path's worn edge, a leaning blade of grass) must stay
/// the same between repaints of an unchanged scene. A real, observed
/// drawing's imperfections don't reshuffle themselves each time it's
/// looked at — ILLUSTRATION_LANGUAGE.md's Nature Before Geometry names
/// irregularity "evidence that someone looked at a place before drawing
/// it," which only holds if the same look keeps producing the same
/// evidence.
const _seed = 30;

class _QuietTrailHeroPainter extends CustomPainter {
  const _QuietTrailHeroPainter({required this.scene, required this.colors});

  final QuietTrailHeroScene scene;
  final AppColors colors;

  // QUIET_TRAIL_REFERENCE.md §3: "the horizon sits low, noticeably below
  // the frame's centre," with the sky occupying "roughly the upper half
  // to two-thirds" of the frame.
  static const _horizonY = 0.62;

  @override
  void paint(Canvas canvas, Size size) {
    final canvasRect = Offset.zero & size;
    final rng = math.Random(_seed);

    _paintSky(canvas, canvasRect, size);
    _paintBirds(canvas, size);
    if (scene.showDistantHills) _paintDistantHills(canvas, size, rng);
    if (scene.showMiddleLandscape) _paintMiddleLandscape(canvas, size, rng);
    if (scene.showPath) _paintPath(canvas, size, rng);
    if (scene.vegetationDensity > 0) _paintVegetation(canvas, size, rng);
    if (scene.showTree) _paintTree(canvas, size, rng);
  }

  /// A light, warm neutral derived from the theme rather than hardcoded —
  /// used for the path and the light's glow, both of which must read as
  /// "light" in both light and dark mode. `colors.background` can't serve
  /// this role itself: it's warm cream in light mode but near-black in
  /// dark mode, so using it directly would turn a light trail into a dark
  /// smudge once dark mode is on.
  Color _lightNeutral(double alpha) {
    return Color.lerp(
      colors.secondary,
      Colors.white,
      0.6,
    )!.withValues(alpha: alpha.clamp(0.0, 1.0));
  }

  double _warmthBlend() => switch (scene.lightWarmth) {
    LightWarmth.cool => 0.3,
    LightWarmth.neutral => 0.5,
    LightWarmth.warm => 0.75,
  };

  void _paintSky(Canvas canvas, Rect canvasRect, Size size) {
    final strength = scene.atmosphereIntensity.clamp(0.0, 1.0);
    final warmth = _warmthBlend();

    final skyPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.background,
              Color.lerp(colors.background, colors.secondary, 0.7 * strength)!,
              Color.lerp(
                colors.secondary,
                colors.primary,
                warmth * strength,
              )!.withValues(alpha: 0.4 + 0.3 * strength),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(canvasRect);
    canvas.drawRect(canvasRect, skyPaint);

    if (strength <= 0) return;

    // A soft glow low on the horizon rather than a defined sun disc — an
    // atmosphere, not an object (WORLD_SYSTEM.md §8, "Preferred light";
    // QUIET_TRAIL_REFERENCE.md §7: "without a single hard source").
    final glowCenter = Offset(size.width * 0.5, size.height * _horizonY);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [_lightNeutral(0.5 * strength), _lightNeutral(0.0)],
      ).createShader(
        Rect.fromCircle(center: glowCenter, radius: size.width * 0.58),
      );
    canvas.drawRect(canvasRect, glowPaint);
  }

  /// Two or three birds, each drawn from a different wing posture rather
  /// than one shape repeated at different scales
  /// (QUIET_TRAIL_REFERENCE.md §5, Birds: "each different... never
  /// identical silhouettes repeated across the sky").
  void _paintBirds(Canvas canvas, Size size) {
    final baseColor = colors.textSecondary;

    for (final (i, bird) in scene.birds.indexed) {
      final center = Offset(size.width * bird.x, size.height * bird.y);
      final span = size.width * 0.026 * bird.scale;
      final paint = Paint()
        ..color = baseColor.withValues(alpha: 0.36 + 0.05 * (i % 2))
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * (0.009 + 0.003 * (i % 2))
        ..strokeCap = StrokeCap.round;

      final wing = switch (i % 3) {
        0 => _wingGliding(center, span),
        1 => _wingBanking(center, span),
        _ => _wingUpstroke(center, span),
      };
      canvas.drawPath(wing, paint);
    }
  }

  /// Wings level, a shallow glide.
  Path _wingGliding(Offset center, double span) {
    return Path()
      ..moveTo(center.dx - span, center.dy)
      ..quadraticBezierTo(
        center.dx - span * 0.32,
        center.dy - span * 0.55,
        center.dx,
        center.dy - span * 0.05,
      )
      ..quadraticBezierTo(
        center.dx + span * 0.34,
        center.dy - span * 0.58,
        center.dx + span,
        center.dy - span * 0.02,
      );
  }

  /// Asymmetric — one wing higher than the other, implying a turn.
  Path _wingBanking(Offset center, double span) {
    return Path()
      ..moveTo(center.dx - span * 0.85, center.dy + span * 0.15)
      ..quadraticBezierTo(
        center.dx - span * 0.25,
        center.dy - span * 0.75,
        center.dx,
        center.dy - span * 0.1,
      )
      ..quadraticBezierTo(
        center.dx + span * 0.4,
        center.dy - span * 0.35,
        center.dx + span * 0.95,
        center.dy - span * 0.5,
      );
  }

  /// A narrower, steeper mid-flap.
  Path _wingUpstroke(Offset center, double span) {
    return Path()
      ..moveTo(center.dx - span * 0.7, center.dy - span * 0.55)
      ..quadraticBezierTo(
        center.dx - span * 0.2,
        center.dy + span * 0.1,
        center.dx,
        center.dy - span * 0.05,
      )
      ..quadraticBezierTo(
        center.dx + span * 0.2,
        center.dy + span * 0.1,
        center.dx + span * 0.7,
        center.dy - span * 0.55,
      );
  }

  /// The farthest layer: an irregular, two-lobed silhouette rather than
  /// one smooth arc (Nature Before Geometry: hills "should not mirror
  /// each other"), softened at its own edge so it recedes behind the
  /// middle landscape (atmospheric perspective). Only this layer is
  /// blurred — composition must stay legible before wash is allowed to
  /// soften anything further (QUIET_TRAIL_REFERENCE.md §9, Renderer
  /// Guidance: atmosphere and composition outrank wash).
  void _paintDistantHills(Canvas canvas, Size size, math.Random rng) {
    final horizon = size.height * _horizonY;
    final wobble = size.height * 0.015;
    final path = Path()
      ..moveTo(0, horizon + size.height * 0.02)
      ..cubicTo(
        size.width * 0.16,
        horizon - size.height * 0.05 - rng.nextDouble() * wobble,
        size.width * 0.32,
        horizon - size.height * 0.15,
        size.width * 0.47,
        horizon - size.height * 0.11 + rng.nextDouble() * wobble,
      )
      ..cubicTo(
        size.width * 0.64,
        horizon - size.height * 0.08 - rng.nextDouble() * wobble,
        size.width * 0.82,
        horizon - size.height * 0.02,
        size.width,
        horizon - size.height * 0.05,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Color.lerp(colors.secondary, colors.background, 0.35)!
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.012),
    );
  }

  /// The nearer layer: a second, differently-rhythmed irregular
  /// silhouette overlapping the distant hills, kept crisper than that
  /// layer so the composition's depth stays easy to read.
  void _paintMiddleLandscape(Canvas canvas, Size size, math.Random rng) {
    final horizon = size.height * _horizonY;
    final wobble = size.height * 0.012;
    final path = Path()
      ..moveTo(0, horizon + size.height * 0.05)
      ..cubicTo(
        size.width * 0.14,
        horizon - size.height * 0.03 - rng.nextDouble() * wobble,
        size.width * 0.28,
        horizon - size.height * 0.09,
        size.width * 0.42,
        horizon - size.height * 0.02 + rng.nextDouble() * wobble,
      )
      ..cubicTo(
        size.width * 0.58,
        horizon + size.height * 0.03,
        size.width * 0.78,
        horizon + size.height * 0.07 - rng.nextDouble() * wobble,
        size.width,
        horizon - size.height * 0.02,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = Color.lerp(colors.secondary, colors.primary, 0.35)!,
    );
  }

  /// A worn path, not a flat-filled ribbon: a soft, wider dissolve layer
  /// sits beneath a narrower, only slightly clearer one, and both edges
  /// are nudged by a small random jitter rather than following one
  /// perfectly smooth taper (QUIET_TRAIL_REFERENCE.md §5, Path:
  /// "edges are uneven and slightly irregular — a path that has been worn
  /// into the land, not a ribbon laid on top of it"; §8: "never resembles
  /// a white ribbon").
  void _paintPath(Canvas canvas, Size size, math.Random rng) {
    final horizon = size.height * _horizonY;
    final centerLine = Path()
      ..moveTo(size.width * 0.42, size.height)
      ..cubicTo(
        size.width * 0.27,
        size.height * 0.87,
        size.width * 0.55,
        size.height * 0.78,
        size.width * 0.45,
        size.height * 0.70,
      )
      ..cubicTo(
        size.width * 0.39,
        size.height * 0.66,
        size.width * 0.47,
        horizon + size.height * 0.05,
        size.width * 0.47,
        horizon + size.height * 0.03,
      );

    final outer = _taperedRibbonPath(
      centerLine,
      (t) => size.width * 0.062 * (1 - t * 0.78),
      edgeJitter: size.width * 0.006,
      rng: rng,
    );
    canvas.drawPath(
      outer,
      Paint()
        ..color = _lightNeutral(0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.018),
    );

    final inner = _taperedRibbonPath(
      centerLine,
      (t) => size.width * 0.036 * (1 - t * 0.78),
      edgeJitter: size.width * 0.004,
      rng: rng,
    );
    canvas.drawPath(
      inner,
      Paint()
        ..color = _lightNeutral(0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.004),
    );
  }

  /// Small, irregular clusters of two or three blades rather than one
  /// blade repeated along a line (Nature Before Geometry: "vegetation
  /// should grow in small clusters rather than evenly").
  void _paintVegetation(Canvas canvas, Size size, math.Random rng) {
    const maxTufts = 5;
    const positions = [0.08, 0.18, 0.62, 0.90, 0.97];
    final count = (scene.vegetationDensity * maxTufts).round().clamp(
      0,
      maxTufts,
    );
    if (count == 0) return;

    final baseY = size.height * 0.97;
    final tuftHeight = size.height * 0.05;

    for (var i = 0; i < count; i++) {
      final x = size.width * positions[i];
      final bladeCount = rng.nextDouble() < 0.5 ? 2 : 3;
      for (var b = 0; b < bladeCount; b++) {
        final lean = (rng.nextDouble() * 2 - 1) * size.width * 0.012;
        final heightJitter = 0.7 + rng.nextDouble() * 0.5;
        final startX = x + (rng.nextDouble() * 2 - 1) * size.width * 0.006;
        final paint = Paint()
          ..color = Color.lerp(
            colors.secondary,
            colors.primary,
            0.4,
          )!.withValues(alpha: 0.4 + rng.nextDouble() * 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * (0.007 + rng.nextDouble() * 0.005)
          ..strokeCap = StrokeCap.round;
        final blade = Path()
          ..moveTo(startX, baseY)
          ..quadraticBezierTo(
            startX + lean,
            baseY - tuftHeight * heightJitter * 0.6,
            startX + lean * 1.4,
            baseY - tuftHeight * heightJitter,
          );
        canvas.drawPath(blade, paint);
      }
    }
  }

  void _paintTree(Canvas canvas, Size size, math.Random rng) {
    const baseXFraction = 0.76;
    const baseYFraction = 0.61;
    const trunkHeightFraction = 0.21;
    const canopyRadiusFraction = 0.082;

    final baseX = size.width * baseXFraction;
    final baseY = size.height * baseYFraction;
    final trunkHeight = size.height * trunkHeightFraction;
    final canopyRadius = size.width * canopyRadiusFraction;
    final canopyAnchor = Offset(
      baseX - size.width * 0.012,
      baseY - trunkHeight,
    );

    _paintTrunk(canvas, size, baseX, baseY, canopyAnchor, rng);
    _paintCanopy(canvas, canopyAnchor, canopyRadius, rng);
  }

  /// A tapered, gently curved ribbon rather than a uniform stroke — the
  /// trunk's own width does the work Fine Line Language asks of every
  /// line here: it thickens toward the root and thins toward the canopy,
  /// never holding one width along its length. The base is left wide
  /// enough to flare into the hillside instead of meeting it at a hard
  /// edge (QUIET_TRAIL_REFERENCE.md §5, Tree: "settles into the slope...
  /// never like an object placed on top of the hill afterward").
  void _paintTrunk(
    Canvas canvas,
    Size size,
    double baseX,
    double baseY,
    Offset canopyAnchor,
    math.Random rng,
  ) {
    final rise = baseY - canopyAnchor.dy;
    final centerLine = Path()
      ..moveTo(baseX, baseY)
      ..cubicTo(
        baseX + size.width * 0.014,
        baseY - rise * 0.4,
        baseX - size.width * 0.010,
        baseY - rise * 0.72,
        canopyAnchor.dx,
        canopyAnchor.dy,
      );

    final ribbon = _taperedRibbonPath(
      centerLine,
      (t) => size.width * (0.017 - 0.011 * t),
      edgeJitter: size.width * 0.0015,
      rng: rng,
      samples: 16,
    );
    canvas.drawPath(ribbon, Paint()..color = colors.primary);
  }

  /// Several irregular, overlapping wash-masses rather than perfect
  /// circles (Nature Before Geometry: trees "should not have perfectly
  /// circular crowns"). No lobe is outlined — volume is suggested by
  /// soft, overlapping colour rather than by a drawn boundary (Wash
  /// Language: "suggest volume... without outlining every edge").
  void _paintCanopy(
    Canvas canvas,
    Offset anchor,
    double radius,
    math.Random rng,
  ) {
    const lobes = [
      (offset: Offset(0.05, 0.0), radiusFactor: 1.0, tone: 0.0),
      (offset: Offset(-0.62, 0.20), radiusFactor: 0.66, tone: 0.22),
      (offset: Offset(0.55, 0.30), radiusFactor: 0.56, tone: 0.3),
    ];

    for (final lobe in lobes) {
      final center = anchor.translate(
        lobe.offset.dx * radius,
        lobe.offset.dy * radius,
      );
      final blob = _organicBlob(
        center,
        radius * lobe.radiusFactor,
        rng,
        points: 7,
        irregularity: 0.4,
      );
      canvas.drawPath(
        blob,
        Paint()
          ..color = Color.lerp(colors.primary, colors.secondary, lobe.tone)!,
      );
    }

    // A soft, small highlight mass toward the light side — a suggestion
    // of volume, not a hard rendered gloss.
    final highlight = _organicBlob(
      anchor.translate(-radius * 0.32, -radius * 0.28),
      radius * 0.4,
      rng,
      points: 6,
      irregularity: 0.3,
    );
    canvas.drawPath(
      highlight,
      Paint()
        ..color = _lightNeutral(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.25),
    );
  }

  @override
  bool shouldRepaint(covariant _QuietTrailHeroPainter oldDelegate) {
    return oldDelegate.scene != scene || oldDelegate.colors != colors;
  }
}

/// Offsets [centerline] into a filled ribbon whose half-width at each
/// point along its length is given by [halfWidthAt] (0.0 at the start of
/// the line, 1.0 at its end) — the shared technique behind every tapered
/// line in this scene (the path, the trunk), because Flutter's [Paint]
/// only strokes at one fixed width and Fine Line Language requires a line
/// that thickens and thins along its own length
/// (ILLUSTRATION_LANGUAGE.md §3). When [rng] and [edgeJitter] are given,
/// each sampled edge point is nudged by a small random amount so the
/// ribbon's boundary reads as worn rather than drafted.
Path _taperedRibbonPath(
  Path centerline,
  double Function(double t) halfWidthAt, {
  int samples = 24,
  double edgeJitter = 0,
  math.Random? rng,
}) {
  final metrics = centerline.computeMetrics().toList();
  if (metrics.isEmpty) return Path();
  final metric = metrics.first;
  final length = metric.length;
  if (length <= 0) return Path();

  final left = <Offset>[];
  final right = <Offset>[];
  for (var i = 0; i <= samples; i++) {
    final t = i / samples;
    final tangent = metric.getTangentForOffset(length * t);
    if (tangent == null) continue;
    final vector = tangent.vector;
    final vectorLength = vector.distance;
    final unitNormal = vectorLength == 0
        ? const Offset(1, 0)
        : Offset(-vector.dy, vector.dx) / vectorLength;
    final halfWidth = halfWidthAt(t);
    final jitter = (edgeJitter == 0 || rng == null)
        ? 0.0
        : (rng.nextDouble() * 2 - 1) * edgeJitter;
    left.add(tangent.position + unitNormal * (halfWidth + jitter));
    right.add(tangent.position - unitNormal * (halfWidth + jitter));
  }
  if (left.isEmpty) return Path();

  final ribbon = Path()..moveTo(left.first.dx, left.first.dy);
  for (final point in left.skip(1)) {
    ribbon.lineTo(point.dx, point.dy);
  }
  for (final point in right.reversed) {
    ribbon.lineTo(point.dx, point.dy);
  }
  ribbon.close();
  return ribbon;
}

/// An irregular, closed blob path around [center] — the technique behind
/// every canopy mass in this scene. [points] vertices are placed around
/// the centre at an angle and radius both nudged by [rng] within
/// [irregularity], then joined with a smooth closed spline (quadratic
/// curves through each vertex to the midpoint of the next), so the result
/// reads as an organic mass rather than a faceted polygon or, at the
/// other extreme, a perfect circle (Nature Before Geometry: "nature is
/// irregular by default").
Path _organicBlob(
  Offset center,
  double radius,
  math.Random rng, {
  int points = 7,
  double irregularity = 0.38,
}) {
  final vertices = <Offset>[
    for (var i = 0; i < points; i++)
      center +
          Offset.fromDirection(
            2 * math.pi * i / points + (rng.nextDouble() - 0.5) * 0.35,
            radius * (1 + (rng.nextDouble() * 2 - 1) * irregularity),
          ),
  ];

  final path = Path()
    ..moveTo(
      (vertices.first.dx + vertices.last.dx) / 2,
      (vertices.first.dy + vertices.last.dy) / 2,
    );
  for (var i = 0; i < points; i++) {
    final next = vertices[(i + 1) % points];
    final mid = Offset(
      (vertices[i].dx + next.dx) / 2,
      (vertices[i].dy + next.dy) / 2,
    );
    path.quadraticBezierTo(vertices[i].dx, vertices[i].dy, mid.dx, mid.dy);
  }
  path.close();
  return path;
}
