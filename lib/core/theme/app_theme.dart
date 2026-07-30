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

  // THIRTY's primary and secondary brand colors are both light/mid-tone teals,
  // so dark text keeps accessible contrast on top of them in both themes.
  static const Color _onAccent = Colors.black;

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: _onAccent,
          secondary: colors.secondary,
          onSecondary: _onAccent,
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
