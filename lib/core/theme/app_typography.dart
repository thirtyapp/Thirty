import 'package:flutter/material.dart';

import 'app_colors.dart';

/// THIRTY's typographic scale, built on Inter with three weights
/// (Regular, Medium, SemiBold) and mapped onto Flutter's [TextTheme].
///
/// Every slot a THIRTY screen reads is defined here explicitly — Phase A
/// (`docs/design/PHASE_A_PLAN.md`, A1) found `titleLarge`, `titleSmall`,
/// `bodySmall` and `labelSmall` in use but undesigned, silently rendering
/// Material 3's defaults. Each defined slot also sets its own
/// `letterSpacing`: left null, Material's type geometry is merged in
/// underneath at `Theme.of` time (e.g. +0.5 on `bodyLarge`, +0.4 on
/// `bodySmall`), which is what made body text read loose and generic.
///
/// Slots outside THIRTY's scale still use Inter and THIRTY's text colors,
/// so Material components that reach for a style we haven't designed (e.g.
/// a slot used internally by [SegmentedButton]) render with the correct
/// typeface and palette instead of the default seed scheme's.
class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'Inter';

  static TextTheme textTheme(AppColors colors, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true)
        .textTheme
        .apply(
          fontFamily: fontFamily,
          bodyColor: colors.textPrimary,
          displayColor: colors.textPrimary,
        );

    TextStyle style(
      double size,
      FontWeight weight,
      double height, {
      Color? color,
      double letterSpacing = 0,
    }) {
      return TextStyle(
        fontFamily: fontFamily,
        fontWeight: weight,
        fontSize: size,
        height: height,
        letterSpacing: letterSpacing,
        color: color ?? colors.textPrimary,
      );
    }

    return base.copyWith(
      displayLarge: style(40, FontWeight.w600, 1.2),
      headlineSmall: style(24, FontWeight.w600, 1.3),
      // Screen titles (every AppBar reads this slot) and the rare in-page
      // page heading. Medium rather than SemiBold: a title that only names
      // where the user is should stay quieter than the content below it.
      titleLarge: style(22, FontWeight.w500, 1.27),
      titleMedium: style(18, FontWeight.w500, 1.4),
      // Small headings inside a surface: a prompt's question, a card's
      // date, the calendar's month.
      titleSmall: style(15, FontWeight.w500, 1.4),
      bodyLarge: style(16, FontWeight.w400, 1.5),
      bodyMedium: style(14, FontWeight.w400, 1.5, color: colors.textSecondary),
      // Supporting detail. Stays textPrimary by default: most call sites
      // already opt into textSecondary explicitly, and the ones that don't
      // (e.g. a journal entry's value beside its secondary label) rely on
      // that contrast.
      bodySmall: style(13, FontWeight.w400, 1.45),
      labelLarge: style(15, FontWeight.w500, 1.2),
      // The eyebrow: a quiet label placed above the thing it names (e.g.
      // "Today's Circle", "Insight"). The one slot with positive tracking,
      // since it is small, medium-weight, and read as a label, not a line.
      labelSmall: style(
        13,
        FontWeight.w500,
        1.25,
        color: colors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  /// The one warm, editorial-serif moment a screen is permitted (Newsreader,
  /// bundled OFL asset — see `pubspec.yaml`), reserved for that screen's
  /// single most meaningful daily moment — never for functional information,
  /// metadata, or interaction, which stay on [textTheme]'s Inter. Which
  /// piece of content earns this role is a per-screen composition decision
  /// (currently the recommendation's intent in `circle_hero.dart`), so this
  /// is named for the role, not for today's content. Deliberately not a
  /// [TextTheme] slot: unlike [textTheme]'s entries, this style has no
  /// Material-widget fallback to protect, and giving it a second full
  /// TextTheme would suggest a parallel type system where none is needed
  /// for a single, deliberate accent.
  static TextStyle editorialDisplay(AppColors colors) {
    return TextStyle(
      fontFamily: 'Newsreader',
      fontWeight: FontWeight.w400,
      fontSize: 28,
      height: 1.21,
      letterSpacing: 0,
      color: colors.textPrimary,
    );
  }
}
