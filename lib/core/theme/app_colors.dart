import 'package:flutter/material.dart';

/// Semantic color tokens for THIRTY, exposed as a [ThemeExtension] so both
/// [ColorScheme]-aware Material widgets and THIRTY's own widgets can read
/// from a single source of truth via `Theme.of(context)`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.disabled,
    required this.success,
    required this.warning,
    required this.error,
  });

  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color disabled;
  final Color success;
  final Color warning;
  final Color error;

  // Circle Sage, deepened ~17% from the reference brand value (#7C8B6D) so
  // it clears WCAG AA 4.5:1 when THIRTY's outline button reuses this token
  // as text color, not just as a fill. See docs/DESIGN_SYSTEM.md.
  static const light = AppColors(
    primary: Color(0xFF67735A),
    secondary: Color(0xFFE9EEE6),
    background: Color(0xFFFAF8F3),
    surface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1F2320),
    textSecondary: Color(0xFF5F655D),
    border: Color(0xFFD8D8D6),
    disabled: Color(0xFFE6E6E5),
    success: Color(0xFF48C774),
    warning: Color(0xFFF4B740),
    error: Color(0xFFE55A5A),
  );

  // Circle Sage, lightened ~8% from the reference brand value so it clears
  // WCAG AA 4.5:1 as text/fill against the dark surface. Background, surface
  // and text are a deliberately warm-toned dark palette (same sage hue
  // family, pushed near-black) rather than an inversion of light mode.
  // See docs/DESIGN_SYSTEM.md.
  static const dark = AppColors(
    primary: Color(0xFF869676),
    secondary: Color(0xFF525A49),
    background: Color(0xFF141612),
    surface: Color(0xFF21241E),
    textPrimary: Color(0xFFF0F2ED),
    textSecondary: Color(0xFFADB4A7),
    border: Color(0xFF6E6F6A),
    disabled: Color(0xFF53544F),
    success: Color(0xFF48C774),
    warning: Color(0xFFF4B740),
    error: Color(0xFFE55A5A),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? secondary,
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? disabled,
    Color? success,
    Color? warning,
    Color? error,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      disabled: disabled ?? this.disabled,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}
