import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/theme/design_tokens.dart';

/// Every TextTheme slot a THIRTY screen reads, with its designed
/// size / weight / height / resolved letterSpacing.
const _designedSlots = <String, (double, FontWeight, double, double)>{
  'displayLarge': (40, FontWeight.w600, 1.2, 0),
  'headlineSmall': (24, FontWeight.w600, 1.3, 0),
  'titleLarge': (22, FontWeight.w500, 1.27, 0),
  'titleMedium': (18, FontWeight.w500, 1.4, 0),
  'titleSmall': (15, FontWeight.w500, 1.4, 0),
  'bodyLarge': (16, FontWeight.w400, 1.5, 0),
  'bodyMedium': (14, FontWeight.w400, 1.5, 0),
  'bodySmall': (13, FontWeight.w400, 1.45, 0),
  'labelLarge': (15, FontWeight.w500, 1.2, 0),
  'labelSmall': (13, FontWeight.w500, 1.25, 0.5),
};

TextStyle _slot(TextTheme theme, String name) => switch (name) {
  'displayLarge' => theme.displayLarge!,
  'headlineSmall' => theme.headlineSmall!,
  'titleLarge' => theme.titleLarge!,
  'titleMedium' => theme.titleMedium!,
  'titleSmall' => theme.titleSmall!,
  'bodyLarge' => theme.bodyLarge!,
  'bodyMedium' => theme.bodyMedium!,
  'bodySmall' => theme.bodySmall!,
  'labelLarge' => theme.labelLarge!,
  'labelSmall' => theme.labelSmall!,
  _ => throw ArgumentError(name),
};

/// The TextTheme as a widget actually receives it — after `Theme.of` has
/// merged Material's localized type geometry underneath THIRTY's styles,
/// which is exactly where undesigned letterSpacing used to leak in.
Future<TextTheme> _resolvedTextTheme(WidgetTester tester, ThemeData theme) async {
  late TextTheme resolved;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) {
          resolved = Theme.of(context).textTheme;
          return const SizedBox();
        },
      ),
    ),
  );
  return resolved;
}

void main() {
  group('AppTypography.textTheme — every slot screens read is designed', () {
    for (final (mode, theme) in [
      ('light', AppTheme.light),
      ('dark', AppTheme.dark),
    ]) {
      testWidgets('$mode: size, weight, height and letterSpacing as resolved '
          'through Theme.of', (tester) async {
        final textTheme = await _resolvedTextTheme(tester, theme);
        for (final MapEntry(key: name, value: spec) in _designedSlots.entries) {
          final style = _slot(textTheme, name);
          final (size, weight, height, letterSpacing) = spec;
          expect(style.fontFamily, 'Inter', reason: name);
          expect(style.fontSize, size, reason: name);
          expect(style.fontWeight, weight, reason: name);
          expect(style.height, height, reason: name);
          expect(style.letterSpacing, letterSpacing, reason: name);
        }
      });
    }

    test('colors follow the palette, secondary only for supporting roles', () {
      for (final colors in [AppColors.light, AppColors.dark]) {
        final brightness = colors == AppColors.light
            ? Brightness.light
            : Brightness.dark;
        final textTheme = AppTypography.textTheme(colors, brightness);
        for (final name in _designedSlots.keys) {
          final expected = name == 'bodyMedium' || name == 'labelSmall'
              ? colors.textSecondary
              : colors.textPrimary;
          expect(_slot(textTheme, name).color, expected, reason: name);
        }
      }
    });

    test('undesigned fallback slots keep Inter and the palette text color, '
        'not the default seed scheme', () {
      final textTheme = AppTypography.textTheme(
        AppColors.dark,
        Brightness.dark,
      );
      for (final style in [
        textTheme.displayMedium!,
        textTheme.headlineMedium!,
        textTheme.labelMedium!,
      ]) {
        expect(style.fontFamily, 'Inter');
        expect(style.color, AppColors.dark.textPrimary);
      }
    });
  });

  group('AppTypography.editorialDisplay', () {
    test('is Newsreader Regular at the approved size/height/spacing', () {
      final style = AppTypography.editorialDisplay(AppColors.light);

      expect(style.fontFamily, 'Newsreader');
      expect(style.fontWeight, FontWeight.w400);
      expect(style.fontSize, 28);
      expect(style.height, 1.21);
      expect(style.letterSpacing, 0);
    });

    test('follows textPrimary per palette, not a hardcoded color', () {
      expect(
        AppTypography.editorialDisplay(AppColors.light).color,
        AppColors.light.textPrimary,
      );
      expect(
        AppTypography.editorialDisplay(AppColors.dark).color,
        AppColors.dark.textPrimary,
      );
    });
  });
}
