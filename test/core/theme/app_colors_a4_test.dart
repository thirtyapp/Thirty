import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_progress_circle.dart';

/// TimePickerThemeData types its state-dependent colors as plain [Color]s
/// that are [WidgetStateColor]s at runtime.
Color _resolve(Color? color, Set<WidgetState> states) =>
    color is WidgetStateColor ? color.resolve(states) : color!;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

/// The lime and teal `ColorScheme.fromSeed` generated for THIRTY's sage
/// seed before Phase A4 (probed from the pre-A4 theme).
const _generatedAccents = <Color>[
  Color(0xFFC9EEA7), // light primaryContainer (lime)
  Color(0xFFDAE7C9), // light secondaryContainer (pale lime)
  Color(0xFF386664), // light tertiary (teal)
  Color(0xFFBBECE9), // light tertiaryContainer (teal)
  Color(0xFF314E19), // dark primaryContainer
  Color(0xFF3F4A34), // dark secondaryContainer
  Color(0xFFA0CFCE), // dark tertiary (teal)
  Color(0xFF1E4E4D), // dark tertiaryContainer (teal)
];

void main() {
  final palettes = [
    ('light', AppTheme.light, AppColors.light),
    ('dark', AppTheme.dark, AppColors.dark),
  ];

  group('Phase A4 token values', () {
    test('light', () {
      const c = AppColors.light;
      expect(c.selection, const Color(0xFFDCE4D5));
      expect(c.surfaceMuted, const Color(0xFFF2F1EC));
      expect(c.divider, const Color(0xFFE6E4DE));
      expect(c.ringTrack, const Color(0xFFE4E3DC));
      expect(c.ringProgress, const Color(0xFF67735A));
      expect(c.errorText, const Color(0xFFB3403C));
    });

    test('dark', () {
      const c = AppColors.dark;
      expect(c.selection, const Color(0xFF525A49));
      expect(c.surfaceMuted, const Color(0xFF2B2E27));
      expect(c.divider, const Color(0xFF34372F));
      expect(c.ringTrack, const Color(0xFF33362F));
      expect(c.ringProgress, const Color(0xFF869676));
      expect(c.errorText, const Color(0xFFF07B74));
    });

    test('brand Mist Sage is unchanged (the illustration paints with it)', () {
      expect(AppColors.light.secondary, const Color(0xFFE9EEE6));
      expect(AppColors.dark.secondary, const Color(0xFF525A49));
    });

    test('lerp and copyWith carry the new roles', () {
      final mid = AppColors.light.lerp(AppColors.dark, 1);
      expect(mid.selection, AppColors.dark.selection);
      expect(mid.errorText, AppColors.dark.errorText);
      expect(
        AppColors.light.copyWith(divider: Colors.red).divider,
        Colors.red,
      );
    });
  });

  for (final (mode, theme, colors) in palettes) {
    group('Phase A4 — $mode', () {
      test('Material accent/container slots are THIRTY roles, never the '
          'generated lime/teal', () {
        final s = theme.colorScheme;
        expect(s.primaryContainer, colors.selection);
        expect(s.secondaryContainer, colors.selection);
        expect(s.tertiaryContainer, colors.selection);
        expect(s.onPrimaryContainer, colors.textPrimary);
        expect(s.onSecondaryContainer, colors.textPrimary);
        expect(s.onTertiaryContainer, colors.textPrimary);
        expect(s.tertiary, colors.primary);
        expect(s.onSurfaceVariant, colors.textSecondary);
        expect(s.inverseSurface, colors.textPrimary);
        expect(s.onInverseSurface, colors.background);
        expect(s.outlineVariant, colors.divider);
        for (final slot in [
          s.primaryContainer,
          s.secondaryContainer,
          s.tertiary,
          s.tertiaryContainer,
          s.inversePrimary,
        ]) {
          expect(_generatedAccents, isNot(contains(slot)));
        }
        expect(
          _contrast(s.inversePrimary, s.inverseSurface),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('nav pill and selected segment use the soft selection role, '
          'with AA text on it', () {
        expect(theme.navigationBarTheme.indicatorColor, colors.selection);
        expect(theme.colorScheme.secondaryContainer, colors.selection);
        final selectedLabel = theme.navigationBarTheme.labelTextStyle!
            .resolve({WidgetState.selected})!
            .color!;
        final unselectedLabel = theme.navigationBarTheme.labelTextStyle!
            .resolve({})!
            .color!;
        expect(
          _contrast(selectedLabel, colors.selection),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(unselectedLabel, colors.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(colors.textPrimary, colors.selection),
          greaterThanOrEqualTo(4.5),
          reason: 'selected segment label',
        );
      });

      test('time picker: selected vs unselected is >= 3:1 and every digit '
          'is AA', () {
        final tp = theme.timePickerTheme;
        const selected = {WidgetState.selected};
        const unselected = <WidgetState>{};
        final fieldOn = _resolve(tp.hourMinuteColor, selected);
        final fieldOff = _resolve(tp.hourMinuteColor, unselected);
        expect(fieldOn, colors.primary);
        expect(fieldOff, colors.surfaceMuted);
        expect(_contrast(fieldOn, fieldOff), greaterThanOrEqualTo(3));
        expect(
          _contrast(_resolve(tp.hourMinuteTextColor, selected), fieldOn),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(_resolve(tp.hourMinuteTextColor, unselected), fieldOff),
          greaterThanOrEqualTo(4.5),
        );

        final periodOn = _resolve(tp.dayPeriodColor, selected);
        expect(periodOn, colors.primary);
        expect(_contrast(periodOn, colors.surface), greaterThanOrEqualTo(3));
        expect(
          _contrast(_resolve(tp.dayPeriodTextColor, selected), periodOn),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(_resolve(tp.dayPeriodTextColor, unselected), colors.surface),
          greaterThanOrEqualTo(4.5),
        );

        expect(tp.dialBackgroundColor, colors.surfaceMuted);
        expect(
          _contrast(tp.dialHandColor!, tp.dialBackgroundColor!),
          greaterThanOrEqualTo(3),
        );
        expect(
          _contrast(_resolve(tp.dialTextColor, selected), tp.dialHandColor!),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(
            _resolve(tp.dialTextColor, unselected),
            tp.dialBackgroundColor!,
          ),
          greaterThanOrEqualTo(4.5),
        );
        expect(tp.backgroundColor, colors.surface);
      });

      test('destructive text clears AA on surface and page', () {
        expect(
          _contrast(colors.errorText, colors.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(colors.errorText, colors.background),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('Circle arc vs track is >= 3:1', () {
        expect(
          _contrast(colors.ringProgress, colors.ringTrack),
          greaterThanOrEqualTo(3),
        );
      });

      testWidgets('ThirtyProgressCircle defaults to the Circle roles', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: Center(child: ThirtyProgressCircle(progress: 0.25)),
            ),
          ),
        );

        expect(
          find.descendant(
            of: find.byType(ThirtyProgressCircle),
            matching: find.byType(CustomPaint),
          ),
          paints
            ..circle(color: colors.ringTrack)
            ..arc(color: colors.ringProgress),
        );
      });

      test('dividers use the divider role', () {
        expect(theme.dividerTheme.color, colors.divider);
      });
    });
  }
}
