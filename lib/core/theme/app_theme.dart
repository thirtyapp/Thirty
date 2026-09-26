import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
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
          outlineVariant: colors.divider,
          // Accent/selection slots pinned too (Phase A4). Left to
          // `fromSeed` they generated the lime (primaryContainer,
          // secondaryContainer) and teal (tertiary*) seen in the Appearance
          // selector and the time picker.
          primaryContainer: colors.selection,
          onPrimaryContainer: colors.textPrimary,
          secondaryContainer: colors.selection,
          onSecondaryContainer: colors.textPrimary,
          tertiary: colors.primary,
          onTertiary: onPrimary,
          tertiaryContainer: colors.selection,
          onTertiaryContainer: colors.textPrimary,
          onSurfaceVariant: colors.textSecondary,
          inverseSurface: colors.textPrimary,
          onInverseSurface: colors.background,
          inversePrimary: _inversePrimary(brightness),
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
      dividerTheme: DividerThemeData(color: colors.divider, thickness: 1),
      // Dialogs share the 24pt card/nav radius (Phase A5) instead of
      // Material 3's 28pt; typography, spacing and actions are untouched.
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xl),
      ),
      timePickerTheme: _timePickerTheme(colors, onPrimary),
      snackBarTheme: _snackBarTheme,
      extensions: [colors],
    );
  }

  /// SnackBar/tooltip accent on [ColorScheme.inverseSurface] (textPrimary):
  /// the opposite palette's sage, darkened in dark mode so it clears 4.5:1
  /// on the light inverse surface.
  static Color _inversePrimary(Brightness brightness) {
    return brightness == Brightness.light
        ? AppColors.dark.primary
        : const Color(0xFF56614A);
  }

  /// SnackBars float (Phase C5) instead of spanning the screen as a square
  /// band on top of the floating bottom nav: the nav's 16pt side margins,
  /// 8pt above whatever sits below (the nav, or the screen edge), and the
  /// same 24pt radius as cards and the nav. No Material shadow; colours
  /// stay Material's inverseSurface / onInverseSurface.
  static const _snackBarTheme = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.xl),
    insetPadding: EdgeInsets.fromLTRB(
      AppSpacing.m,
      0,
      AppSpacing.m,
      AppSpacing.s,
    ),
    elevation: 0,
  );

  /// The time picker signals which field is active by color alone, so —
  /// unlike the nav pill or a segment — its selected state uses the strong
  /// [AppColors.primary] fill, which clears 3:1 against the unselected
  /// [AppColors.surfaceMuted] fields (4.45:1 light, 4.36:1 dark).
  static TimePickerThemeData _timePickerTheme(
    AppColors colors,
    Color onPrimary,
  ) {
    Color selectedOr(Set<WidgetState> states, Color selected, Color other) =>
        states.contains(WidgetState.selected) ? selected : other;
    return TimePickerThemeData(
      backgroundColor: colors.surface,
      // The picker's own dialog shape ignores DialogThemeData; pin it to
      // the same 24pt radius as every other dialog (Phase A5).
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.xl),
      hourMinuteColor: WidgetStateColor.resolveWith(
        (states) => selectedOr(states, colors.primary, colors.surfaceMuted),
      ),
      hourMinuteTextColor: WidgetStateColor.resolveWith(
        (states) => selectedOr(states, onPrimary, colors.textPrimary),
      ),
      dayPeriodColor: WidgetStateColor.resolveWith(
        (states) => selectedOr(states, colors.primary, Colors.transparent),
      ),
      dayPeriodTextColor: WidgetStateColor.resolveWith(
        (states) => selectedOr(states, onPrimary, colors.textSecondary),
      ),
      dayPeriodBorderSide: BorderSide(color: colors.border),
      dialBackgroundColor: colors.surfaceMuted,
      dialHandColor: colors.primary,
      dialTextColor: WidgetStateColor.resolveWith(
        (states) => selectedOr(states, onPrimary, colors.textPrimary),
      ),
      entryModeIconColor: colors.textSecondary,
    );
  }

  /// Every AppBar sits on the page itself: the exact page background at
  /// rest and while content scrolls under it, with no surface tint and no
  /// scrolled-under elevation or tonal change. This removes the white
  /// (light) / lighter (dark) band all nine AppBars had. The scrolled-under
  /// separation is only a 1pt edge, drawn by `ThirtyAppBar` (Phase C5).
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
  /// must never paint its own rectangle. Phase D1 (Design vision): no
  /// indicator pill — selection is carried by the filled icon (or Today's
  /// thicker ring), the sage colour and the heavier label together, never
  /// by colour alone.
  static NavigationBarThemeData _navigationBarTheme(AppColors colors) {
    return NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? colors.primary
              : colors.textSecondary,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          height: 1.33,
          letterSpacing: 0,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? colors.primary
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
