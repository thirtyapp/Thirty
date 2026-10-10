import 'package:flutter/material.dart';

import '../../../../core/worlds/daypart.dart';
import '../../../../core/worlds/world.dart' show Daypart;

/// One daypart's Toolkit header artwork and the pixel size of its master
/// (checked against the bundled file in `toolkit_page_test.dart`). The art
/// is the one painted for the V1 Plans page, kept for the Toolkit.
class ToolkitHeaderArtImage {
  const ToolkitHeaderArtImage(
    this.asset, {
    required this.width,
    required this.height,
  });

  final String asset;
  final int width;
  final int height;
}

/// The Toolkit's header artwork: one wide watercolor landscape band
/// per daypart. Not a World or a Scene, and never registered in the World
/// art manifest.
class ToolkitHeaderArtSet {
  const ToolkitHeaderArtSet({
    required this.morning,
    required this.day,
    required this.evening,
  });

  final ToolkitHeaderArtImage morning;
  final ToolkitHeaderArtImage day;
  final ToolkitHeaderArtImage evening;

  ToolkitHeaderArtImage at(Daypart daypart) => switch (daypart) {
    Daypart.morning => morning,
    Daypart.afternoon => day,
    Daypart.evening => evening,
  };
}

/// The approved Plans header artwork (founder-approved, 2026-10-01),
/// converted from `artwork/plans/` with the World pack's settings; each
/// size is its master's.
const toolkitHeaderArt = ToolkitHeaderArtSet(
  morning: ToolkitHeaderArtImage(
    'assets/plans/plans_header_morning_v1.webp',
    width: 1870,
    height: 285,
  ),
  day: ToolkitHeaderArtImage(
    'assets/plans/plans_header_day_v1.webp',
    width: 1870,
    height: 266,
  ),
  evening: ToolkitHeaderArtImage(
    'assets/plans/plans_header_evening_v1.webp',
    width: 1870,
    height: 278,
  ),
);

/// The header band for [art] at [now]'s daypart (THIRTY's own
/// [daypartAt]), or nothing when [art] is `null`. Decorative only.
///
/// A plain rectangular band across the page's full width at
/// [bandAspectRatio], close to the North Star's band (founder review,
/// 2026-10-02): the panorama is scaled up to fill it and centred on the
/// valley, so its outer reaches are cropped — never stretched. No rounded
/// card; only a subtle bottom blend into the page. In dark mode it is
/// dimmed slightly, like the dark Card art, so it never reads as a bright
/// panel.
class ToolkitHeaderArt extends StatelessWidget {
  const ToolkitHeaderArt({required this.art, required this.now, super.key});

  final ToolkitHeaderArtSet? art;
  final DateTime now;

  /// Width ÷ height of the band, the same for every daypart — about
  /// 158dp tall on a 412dp-wide phone.
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
        // A subtle bottom blend into the page: without it the band ends
        // in a hard line on the dark surface (and under the evening art in
        // light mode). The top and sides stay square.
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
