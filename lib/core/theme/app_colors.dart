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

  static const light = AppColors(
    primary: Color(0xFF22B8A8),
    secondary: Color(0xFF8FD9CF),
    background: Color(0xFFF8FAF9),
    surface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF14181B),
    textSecondary: Color(0xFF4F5B63),
    border: Color(0xFFE1E6E5),
    disabled: Color(0xFFC9D0CE),
    success: Color(0xFF48C774),
    warning: Color(0xFFF4B740),
    error: Color(0xFFE55A5A),
  );

  static const dark = AppColors(
    primary: Color(0xFF22B8A8),
    secondary: Color(0xFF8FD9CF),
    background: Color(0xFF111417),
    surface: Color(0xFF1C2126),
    textPrimary: Color(0xFFF3F5F4),
    textSecondary: Color(0xFF9CA6AC),
    border: Color(0xFF2C333A),
    disabled: Color(0xFF3B434A),
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
