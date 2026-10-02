import 'package:flutter/material.dart';

import '../../../../core/worlds/daypart.dart';
import '../../../../core/worlds/world.dart' show Daypart;

/// One daypart's Insights header artwork and the pixel size of its master
/// (checked against the bundled file in `insights_header_art_test.dart`).
class InsightsHeaderArtImage {
  const InsightsHeaderArtImage(
    this.asset, {
    required this.width,
    required this.height,
  });

  final String asset;
  final int width;
  final int height;
}

/// The dedicated Insights header artwork: one wide watercolor landscape
/// band per daypart. Not a World or a Scene, never registered in the World
/// art manifest, and never the Plans band.
class InsightsHeaderArtSet {
  const InsightsHeaderArtSet({
    required this.morning,
    required this.day,
    required this.evening,
  });

  final InsightsHeaderArtImage morning;
  final InsightsHeaderArtImage day;
  final InsightsHeaderArtImage evening;

  InsightsHeaderArtImage at(Daypart daypart) => switch (daypart) {
    Daypart.morning => morning,
    Daypart.afternoon => day,
    Daypart.evening => evening,
  };
}

/// The approved Insights header artwork (founder-approved, 2026-10-02),
/// converted from `artwork/insights/` with the World pack's settings; each
/// size is its master's.
const insightsHeaderArt = InsightsHeaderArtSet(
  morning: InsightsHeaderArtImage(
    'assets/insights/insights_header_morning_v1.webp',
    width: 2020,
    height: 258,
  ),
  day: InsightsHeaderArtImage(
    'assets/insights/insights_header_day_v1.webp',
    width: 2020,
    height: 254,
  ),
  evening: InsightsHeaderArtImage(
    'assets/insights/insights_header_evening_v1.webp',
    width: 2020,
    height: 253,
  ),
);

/// The header band for [art] at [now]'s daypart (THIRTY's own
/// [daypartAt]), or nothing when [art] is `null`. Decorative only.
///
/// The same presentation as the frozen Plans band
/// (`../../../plans/presentation/widgets/plans_header_art.dart`), kept as a
/// separate copy so Insights never changes Plans: a plain rectangle across
/// the page's full width at [bandAspectRatio], the panorama scaled up to
/// fill it and centred, so its outer reaches are cropped — never
/// stretched. A subtle bottom blend into the page; slightly dimmed in dark
/// mode.
class InsightsHeaderArt extends StatelessWidget {
  const InsightsHeaderArt({required this.art, required this.now, super.key});

  final InsightsHeaderArtSet? art;
  final DateTime now;

  /// Width ÷ height of the band — the Plans band's, so both destinations'
  /// headers share one height.
  static const bandAspectRatio = 2.6;

  static const _darkOpacity = 0.85;

  /// Where the bottom blend begins, as a share of the band's height.
  static const _blendStart = 0.82;

  @override
  Widget build(BuildContext context) {
    final set = art;
    if (set == null) return const SizedBox.shrink();
    final image = set.at(daypartAt(now));
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: bandAspectRatio,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000000), Color(0x00000000)],
            stops: [_blendStart, 1],
          ).createShader(bounds),
          child: Opacity(
            opacity: dark ? _darkOpacity : 1,
            child: Image.asset(image.asset, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}
