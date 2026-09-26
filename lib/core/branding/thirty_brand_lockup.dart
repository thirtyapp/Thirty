import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'thirty_wordmark_view.dart';

/// The THIRTY wordmark with the tagline "A BRIGHTER YOU / IN SMALL STEPS"
/// beneath it (Phase D1) — Home's header, the Ready Circle and First
/// Breath's wordmark beat all use this one lockup.
///
/// The tagline scales with [wordmarkWidth], so the lockup keeps one
/// proportion at every size. It is a logotype: it keeps its size at every
/// text scale (WCAG 1.4.4's logotype exception). With [headerLabel] the
/// wordmark is announced as that header and the tagline as plain text
/// after it (Home's header); inside the Circle, which owns the moment's
/// semantics, the caller excludes the whole lockup instead.
class ThirtyBrandLockup extends StatelessWidget {
  const ThirtyBrandLockup({
    required this.wordmarkWidth,
    this.centered = false,
    this.headerLabel,
    super.key,
  });

  final double wordmarkWidth;

  /// Centred under the wordmark (inside the Circle) instead of
  /// start-aligned (the header).
  final bool centered;

  /// When set, the wordmark is a semantic header with this label.
  final String? headerLabel;

  static const tagline = 'A brighter you in small steps';

  /// The tagline grows with the wordmark but stays about as wide as it
  /// (Design vision), never below the header's legible 9.5pt; letter
  /// spacing and the gap follow the font size.
  static const _minFontSize = 9.5;
  static const _fontSizeRatio = 0.075;
  static const _letterSpacingRatio = 2.2 / 9.5;
  static const _gapRatio = 6 / 9.5;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final fontSize = math.max(_minFontSize, wordmarkWidth * _fontSizeRatio);
    return MediaQuery.withNoTextScaling(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: centered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          if (headerLabel case final label?)
            Semantics(
              header: true,
              label: label,
              child: SizedBox(
                width: wordmarkWidth,
                child: const ThirtyWordmarkView(),
              ),
            )
          else
            SizedBox(width: wordmarkWidth, child: const ThirtyWordmarkView()),
          SizedBox(height: fontSize * _gapRatio),
          Text(
            'A BRIGHTER YOU\nIN SMALL STEPS',
            semanticsLabel: tagline,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: fontSize,
              height: 1.5,
              fontWeight: FontWeight.w500,
              letterSpacing: fontSize * _letterSpacingRatio,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
