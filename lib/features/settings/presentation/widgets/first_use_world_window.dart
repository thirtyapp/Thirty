import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/worlds/daypart.dart';
import 'you_header_art.dart';

/// The first-use question's window into THIRTY: the approved You landscape
/// ([youHeaderArt], at [now]'s daypart via [daypartAt]) seen through a
/// round window framed in the page's surface tone.
///
/// It echoes the Circle's shape but none of its function — no ring, no
/// progress dot, no state, no semantics. Flat: no shadow or halo, so it
/// sits in the composition rather than floating above it. Decorative only.
class FirstUseWorldWindow extends StatelessWidget {
  const FirstUseWorldWindow({
    required this.now,
    required this.diameter,
    super.key,
  });

  final DateTime now;
  final double diameter;

  /// Where the cover crop's square window sits along the ~8:1 panorama:
  /// right of centre, so the oak's trunk stands just right of the window's
  /// middle with the ridge and valley behind it.
  static const cropAlignment = Alignment(0.5, 0);

  /// The band of surface framing the art, like the Circle's own.
  static const frameWidth = AppSpacing.s;

  static const _darkOpacity = 0.9;

  static const _maxDiameter = 280.0;
  static const _minDiameter = 120.0;
  static const _widthFraction = 0.76;

  /// The screen height the wordmark, question, field and actions claim
  /// before the window takes its [_heightFraction] of what is left — so a
  /// shorter phone gives up proportionally more of the window than of its
  /// text (about 270 on a Pixel 7, about 203 at 360×740).
  static const _reservedHeight = 205.0;
  static const _heightFraction = 0.38;

  /// The window's diameter for a content [width] and a screen [height]:
  /// a share of whichever is tighter, eased down as text grows
  /// ([textScale]) so the question and its actions always come first.
  /// Sized off the screen, not the space left above the keyboard, so it
  /// never shrinks when the keyboard opens.
  static double diameterFor({
    required double width,
    required double height,
    required double textScale,
  }) {
    final size = math.min(
      width * _widthFraction,
      (height - _reservedHeight) * _heightFraction,
    );
    return (size / math.sqrt(math.max(1, textScale)))
        .clamp(_minDiameter, _maxDiameter)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final dark = theme.brightness == Brightness.dark;
    final image = youHeaderArt.at(daypartAt(now));
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.surface,
        ),
        child: SizedBox.square(
          dimension: diameter,
          child: Padding(
            padding: const EdgeInsets.all(frameWidth),
            child: ClipOval(
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
        ),
      ),
    );
  }
}
