import 'package:flutter/material.dart';

import '../../../../core/worlds/daypart.dart';
import '../../../../core/worlds/world.dart' show Daypart;

/// One daypart's You header artwork and the pixel size of its master.
class YouHeaderArtImage {
  const YouHeaderArtImage(
    this.asset, {
    required this.width,
    required this.height,
  });

  final String asset;
  final int width;
  final int height;
}

/// The dedicated You header artwork: one wide watercolor hillside band per
/// daypart. Not a World or a Scene, never registered in the World art
/// manifest, and never the Plans or Insights band.
class YouHeaderArtSet {
  const YouHeaderArtSet({
    required this.morning,
    required this.day,
    required this.evening,
  });

  final YouHeaderArtImage morning;
  final YouHeaderArtImage day;
  final YouHeaderArtImage evening;

  YouHeaderArtImage at(Daypart daypart) => switch (daypart) {
    Daypart.morning => morning,
    Daypart.afternoon => day,
    Daypart.evening => evening,
  };
}

/// The approved You header artwork (founder-approved), converted from
/// `artwork/you/` with the World pack's settings; each size is its master's.
const youHeaderArt = YouHeaderArtSet(
  morning: YouHeaderArtImage(
    'assets/you/you_header_morning_v1.webp',
    width: 2022,
    height: 253,
  ),
  day: YouHeaderArtImage(
    'assets/you/you_header_day_v1.webp',
    width: 2022,
    height: 253,
  ),
  evening: YouHeaderArtImage(
    'assets/you/you_header_evening_v1.webp',
    width: 2019,
    height: 253,
  ),
);

/// The header band for [art] at [now]'s daypart (THIRTY's own
/// [daypartAt]), or nothing when [art] is `null`. Decorative only.
///
/// The same presentation as the frozen Plans and Insights bands, kept as
/// You's own copy so neither of those ever changes: a plain rectangle across
/// the page's full width at [bandAspectRatio], the panorama scaled up to
/// fill it, so its outer reaches are cropped — never stretched. A subtle
/// bottom blend into the page; slightly dimmed in dark mode.
///
/// One deliberate difference: the crop is composition-aware rather than
/// centred ([cropAlignment]). The You panorama (about 8:1) shows only a
/// third of its width in the band, and its subject — the oak — stands at
/// about 73% across; a centred crop would cut the tree out entirely.
class YouHeaderArt extends StatelessWidget {
  const YouHeaderArt({required this.art, required this.now, super.key});

  final YouHeaderArtSet? art;
  final DateTime now;

  /// Width ÷ height of the band — the Plans and Insights bands', so all
  /// three destinations' headers share one height.
  static const bandAspectRatio = 2.6;

  /// Where the cover crop's window sits along the panorama: right of
  /// centre, so the oak stands about two-thirds across the band with the
  /// open hillside and ridge to its left — the same window on every phone,
  /// since the band's and the panorama's proportions are both fixed.
  static const cropAlignment = Alignment(0.55, 0);

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
            child: Image.asset(
              image.asset,
              fit: BoxFit.cover,
              alignment: cropAlignment,
            ),
          ),
        ),
      ),
    );
  }
}
