import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Builds THIRTY's first-class light and dark [ThemeData]. Dark mode is a
/// deliberately designed palette ([AppColors.dark]), not an automatic
/// inversion of light mode.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(AppColors.light, Brightness.light);

  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    // Circle Sage is deepened for light mode and lightened for dark mode
    // (see AppColors) so it passes WCAG AA 4.5:1 as text on its own
    // background, not just as a fill — which flips which on-color reads
    // accessibly on top of it. Mist Sage (light) and its dark-mode
    // counterpart stay light/soft respectively, so textPrimary always
    // reads accessibly on secondary regardless of brightness.
    final onPrimary = brightness == Brightness.light
        ? Colors.white
        : Colors.black;
    final onSecondary = colors.textPrimary;

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: onPrimary,
          secondary: colors.secondary,
          onSecondary: onSecondary,
          surface: colors.surface,
          onSurface: colors.textPrimary,
          error: colors.error,
          onError: Colors.white,
          outline: colors.border,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      fontFamily: AppTypography.fontFamily,
      textTheme: AppTypography.textTheme(colors, brightness),
      dividerColor: colors.border,
      disabledColor: colors.disabled,
      splashFactory: InkRipple.splashFactory,
      extensions: [colors],
    );
  }
}
