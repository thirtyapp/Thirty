import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_progress_circle.dart';

/// The Home Circle's shared geometry — the single source of truth for both
/// `circle_ready_prompt.dart` (Ready) and `circle_hero.dart` (assigned /
/// active / closed). Before Phase B1 each widget carried its own verbatim
/// copy of these values; the Golden Home continuity requirement (the Circle
/// never jumps across the daily flow) now depends on one definition
/// instead of two copies kept in lockstep by hand.
class HomeCircleMetrics {
  const HomeCircleMetrics._({
    required this.circleSize,
    required this.textMaxWidth,
  });

  /// Derives every size from the width actually available to the Home
  /// composition (a `LayoutBuilder`'s `constraints.maxWidth`).
  factory HomeCircleMetrics.forWidth(double maxWidth) {
    // The Circle must never be clipped: cap it below the width that's
    // actually left after the page's horizontal margins, regardless of how
    // large `_circleMaxSize` allows it to be on a wide screen.
    final safeMaxSize = math.max(
      _circleMinSize,
      math.min(_circleMaxSize, maxWidth - AppSpacing.page * 2),
    );
    final circleSize = (maxWidth * _circleWidthFraction)
        .clamp(_circleMinSize, safeMaxSize)
        .toDouble();
    return HomeCircleMetrics._(
      circleSize: circleSize,
      textMaxWidth: safeMaxSize * _textColumnWidthFraction,
    );
  }

  // The Circle is sized off the available width, not a fixed constant, so
  // it stays the screen's dominant object on both small and large phones.
  // 88% is an intentionally oversized, near-edge-to-edge scale — this is
  // the product's hero object, not a widget sized to sit comfortably in a
  // grid. Its top curve still rises beside Home's header lockup (see
  // [clearDepthBeside]), as in the Design vision. _circleMaxSize is a
  // ceiling for large screens; the safe-width check above is what actually
  // guarantees the Circle is never clipped.
  static const _circleWidthFraction = 0.88;
  static const _circleMinSize = 260.0;
  static const _circleMaxSize = 440.0;

  // The wordmark's own width, as a fraction of the Circle's usable
  // interior — reproduces the visually validated scale matrix from
  // `docs/brand/THIRTY_WORDMARK.md` §6 (236px interior → ~138px wordmark,
  // 416px interior → ~243px wordmark).
  static const _wordmarkWidthFraction = 0.585;

  // The text column beneath the Circle is a bounded share of the page's
  // content width (the largest the Circle may be), not of the Circle
  // itself, so the greeting's subline wraps the same way at any Circle
  // size.
  // Since Phase B2 the hero CTA fills this same column (never the screen).
  static const _textColumnWidthFraction = 0.85;

  // The Home content's vertical rhythm, shared so Ready and Circle Hero
  // place their first element at the same distance from the Circle.

  /// Circle → first element beneath it (Begin CTA / directions in Ready,
  /// the greeting in Circle Hero).
  static const circleToContentGap = AppSpacing.m;

  /// Phase D1 — greeting → its subline.
  static const greetingToSublineGap = AppSpacing.s;

  /// Phase D1 — greeting block → the Today card.
  static const greetingToCardGap = AppSpacing.m;

  /// Phase D1 — the Today card → the CTA (or the closed-state message).
  static const cardToCtaGap = AppSpacing.m;

  /// Near-fit compact rhythm (Circle Hero only): when the usual gaps would
  /// leave Start Circle just below the fold, circle → greeting, greeting →
  /// card and card → CTA each tighten to this, and the CTA keeps at least
  /// this much room above the fold. Larger overflow keeps the usual gaps
  /// and scrolls.
  static const compactGap = AppSpacing.s;

  /// Phase D1 ring (Design vision): a thin ring inset inside the halo
  /// disc, a sage dot marking the arc's leading end, and a small band of
  /// the halo's surface between the ring and the illustration.
  static const ringInset = 8.0;
  static const ringStrokeWidth = 6.0;
  static const thumbDiameter = 14.0;
  static const _illustrationGap = 4.0;

  /// The wordmark's reference interior (the pre-D1 ring's inner edge): the
  /// validated wordmark scale in `docs/brand/THIRTY_WORDMARK.md` §6 is
  /// kept exactly, independent of the D1 ring.
  static const _wordmarkInset = 10.0;

  /// The Home composition's outer padding, shared by both widgets so the
  /// Circle's top edge sits at the same place in every state. Anchored
  /// toward the top rather than centered: SafeArea already clears the
  /// status bar, and leftover space on a short screen lands below the CTA.
  static const padding = EdgeInsets.fromLTRB(
    AppSpacing.page,
    0,
    AppSpacing.page,
    AppSpacing.xl,
  );

  final double circleSize;

  /// The bounded Home content column: the text and the hero CTA share it.
  final double textMaxWidth;

  /// The ring's own outer size, inset inside the halo disc.
  double get ringSize => circleSize - ringInset * 2;

  /// The World illustration's size: inside the ring, with a small band of
  /// the halo's surface around it.
  double get illustrationSize =>
      circleSize - (ringInset + ringStrokeWidth + _illustrationGap) * 2;

  /// The wordmark's reference interior, never the Circle's outer size.
  double get interiorSize => circleSize - _wordmarkInset * 2;

  double get wordmarkWidth => interiorSize * _wordmarkWidthFraction;

  /// How far below its top edge the Circle, centered in [maxWidth], stays
  /// entirely right of [x] — i.e. how deep the Circle's top may overlap
  /// something that ends at [x] on its left. Infinite when the Circle
  /// never reaches that far left.
  double clearDepthBeside(double x, double maxWidth) {
    final radius = circleSize / 2;
    final reach = maxWidth / 2 - x;
    if (reach >= radius) return double.infinity;
    if (reach <= 0) return 0;
    return radius - math.sqrt(radius * radius - reach * reach);
  }
}

/// The Home Circle (Phase D1), shared by Ready and the assigned states so
/// it never jumps: the [HomeCircleHalo] disc with a thin ring inset inside
/// it and, when [showThumb], a sage dot at the arc's leading end.
class HomeCircle extends StatelessWidget {
  const HomeCircle({
    required this.metrics,
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.semanticValue,
    this.showThumb = true,
    this.child,
    super.key,
  });

  final HomeCircleMetrics metrics;
  final double progress;
  final Color progressColor;
  final Color trackColor;
  final String semanticValue;
  final bool showThumb;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return HomeCircleHalo(
      size: metrics.circleSize,
      child: Center(
        child: ThirtyProgressCircle(
          progress: progress,
          size: metrics.ringSize,
          strokeWidth: HomeCircleMetrics.ringStrokeWidth,
          progressColor: progressColor,
          trackColor: trackColor,
          thumbDiameter: showThumb ? HomeCircleMetrics.thumbDiameter : null,
          semanticLabel: "Today's Circle",
          semanticValue: semanticValue,
          child: child,
        ),
      ),
    );
  }
}

/// The Circle's halo (Phase B1): a `surface`-toned disc exactly the
/// Circle's own size, lifted off the page by [AppShadows.haloLight] /
/// [AppShadows.haloDark]. It paints behind the ring and never changes the
/// Circle's geometry, ring colors or track — the steady not-started track
/// stays transparent; the halo alone gives the Circle its presence there.
/// Static in every state, so it has no part in The First Breath's
/// timeline.
class HomeCircleHalo extends StatelessWidget {
  const HomeCircleHalo({required this.size, required this.child, super.key});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface,
        boxShadow: theme.brightness == Brightness.light
            ? AppShadows.haloLight
            : AppShadows.haloDark,
      ),
      child: SizedBox.square(dimension: size, child: child),
    );
  }
}
