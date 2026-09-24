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
          // Surface/container roles pinned to THIRTY's own surfaces (Phase
          // A3). Left to `fromSeed`, they generated green-grey tones that
          // leaked into dialogs, time pickers, the nav bar and an AppBar's
          // scrolled-under state. Accent containers (secondaryContainer,
          // primaryContainer, tertiaryContainer) are deliberately still
          // seed-derived: they're selection/accent colors whose contrast
          // is an A4 palette decision.
          surfaceContainerLowest: colors.surface,
          surfaceContainerLow: colors.surface,
          surfaceContainer: colors.surface,
          surfaceContainerHigh: colors.surface,
          surfaceContainerHighest: colors.secondary,
          surfaceTint: Colors.transparent,
          outlineVariant: colors.border,
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
      appBarTheme: _appBarTheme(colors),
      navigationBarTheme: _navigationBarTheme(colors),
      switchTheme: _switchTheme(colors, onPrimary),
      // Material 3's Divider ignores ThemeData.dividerColor and reads
      // outlineVariant by default; set it explicitly.
      dividerTheme: DividerThemeData(color: colors.border, thickness: 1),
      extensions: [colors],
    );
  }

  /// Every AppBar sits on the page itself: the exact page background at
  /// rest and while content scrolls under it, with no surface tint and no
  /// scrolled-under elevation or tonal change. This removes the white
  /// (light) / lighter (dark) band all nine AppBars had. A deliberate
  /// scrolled-state separation, if any, is an A4/Phase C decision.
  static AppBarTheme _appBarTheme(AppColors colors) {
    return AppBarTheme(
      backgroundColor: colors.background,
      foregroundColor: colors.textPrimary,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    );
  }

  /// The bar inside the floating bottom nav. Transparent on purpose: the
  /// surrounding `FloatingNavSurface` (in `app_shell.dart`) is the single
  /// owner of the bar's color, rounded shape and shadow, so the bar itself
  /// must never paint its own rectangle. Selection is carried by the
  /// filled icon, the label color and the quiet Mist Sage indicator
  /// together — never by the indicator alone.
  static NavigationBarThemeData _navigationBarTheme(AppColors colors) {
    return NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: colors.secondary,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? colors.textPrimary
              : colors.textSecondary,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          height: 1.33,
          letterSpacing: 0,
          fontWeight: FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? colors.textPrimary
              : colors.textSecondary,
        ),
      ),
    );
  }

  /// Off-state thumb and outline use textSecondary so the unselected
  /// switch's boundary clears WCAG 1.4.11's 3:1 non-text contrast against
  /// the surface it sits on — the default outline role (`border`) is only
  /// ~1.4:1. Disabled states fall through to Material's defaults.
  static SwitchThemeData _switchTheme(AppColors colors, Color onPrimary) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return null;
        return states.contains(WidgetState.selected)
            ? onPrimary
            : colors.textSecondary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return null;
        return states.contains(WidgetState.selected)
            ? colors.primary
            : colors.surface;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return null;
        return states.contains(WidgetState.selected)
            ? Colors.transparent
            : colors.textSecondary;
      }),
    );
  }
}
