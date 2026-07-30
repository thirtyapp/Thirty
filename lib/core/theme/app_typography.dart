import 'package:flutter/material.dart';

import 'app_colors.dart';

/// THIRTY's typographic scale, built on Inter with three weights
/// (Regular, Medium, SemiBold) and mapped onto Flutter's [TextTheme].
///
/// Every [TextTheme] slot uses Inter, including the ones outside THIRTY's
/// deliberately small scale, so Material components that reach for a style
/// we haven't designed (e.g. a slot used internally by [SegmentedButton])
/// still render with the correct typeface instead of falling back silently.
class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'Inter';

  static TextTheme textTheme(AppColors colors, Brightness brightness) {
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
    ).textTheme.apply(fontFamily: fontFamily);

    return base.copyWith(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 40,
        height: 1.2,
        color: colors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 24,
        height: 1.3,
        color: colors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 18,
        height: 1.4,
        color: colors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.5,
        color: colors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.5,
        color: colors.textSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 15,
        height: 1.2,
        color: colors.textPrimary,
      ),
    );
  }
}
