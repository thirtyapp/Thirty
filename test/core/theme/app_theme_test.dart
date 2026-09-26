import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/theme/design_tokens.dart';

void main() {
  group('AppTheme', () {
    test('light theme is built with light brightness and AppColors.light', () {
      final theme = AppTheme.light;

      expect(theme.brightness, Brightness.light);
      expect(theme.extension<AppColors>(), AppColors.light);
    });

    test('dark theme is built with dark brightness and AppColors.dark', () {
      final theme = AppTheme.dark;

      expect(theme.brightness, Brightness.dark);
      expect(theme.extension<AppColors>(), AppColors.dark);
    });

    test('a TextTheme slot outside the THIRTY scale still uses Inter', () {
      // titleLarge and displayMedium aren't part of THIRTY's designed
      // scale, but Material components may still reach for them.
      expect(AppTheme.light.textTheme.titleLarge?.fontFamily, 'Inter');
      expect(AppTheme.light.textTheme.displayMedium?.fontFamily, 'Inter');
      expect(AppTheme.dark.textTheme.titleLarge?.fontFamily, 'Inter');
    });

    testWidgets('renders without errors under the light theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: Text('Light')),
        ),
      );

      expect(find.text('Light'), findsOneWidget);
    });

    testWidgets('renders without errors under the dark theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: Text('Dark')),
        ),
      );

      expect(find.text('Dark'), findsOneWidget);
    });
  });

  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final (hi, lo) = la > lb ? (la, lb) : (lb, la);
    return (hi + 0.05) / (lo + 0.05);
  }

  final palettes = [
    ('light', AppTheme.light, AppColors.light),
    ('dark', AppTheme.dark, AppColors.dark),
  ];

  group('AppTheme — Phase A3 component themes', () {
    for (final (mode, theme, colors) in palettes) {
      test('$mode: AppBar uses the page background with no tint or '
          'elevation', () {
        final appBar = theme.appBarTheme;
        expect(appBar.backgroundColor, colors.background);
        expect(appBar.surfaceTintColor, Colors.transparent);
        expect(appBar.elevation, 0);
        expect(appBar.scrolledUnderElevation, 0);
      });

      testWidgets('$mode: an AppBar paints the exact page background at '
          'rest and while content scrolls under it', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              appBar: AppBar(title: const Text('Title')),
              body: ListView(
                children: [
                  for (var i = 0; i < 60; i++)
                    SizedBox(height: 40, child: Text('Row $i')),
                ],
              ),
            ),
          ),
        );
        Color paintedAppBarColor() => tester
            .widget<Material>(
              find
                  .descendant(
                    of: find.byType(AppBar),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .color!;

        expect(paintedAppBarColor(), colors.background);
        expect(theme.scaffoldBackgroundColor, colors.background);

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        expect(paintedAppBarColor(), colors.background);
      });

      test('$mode: generated surface/container roles are pinned to THIRTY '
          'surfaces (dialogs, time pickers, nav, AppBar scroll state)', () {
        final scheme = theme.colorScheme;
        expect(scheme.surfaceContainerLowest, colors.surface);
        expect(scheme.surfaceContainerLow, colors.surface);
        expect(scheme.surfaceContainer, colors.surface);
        expect(scheme.surfaceContainerHigh, colors.surface);
        expect(scheme.surfaceContainerHighest, colors.secondary);
        expect(scheme.surfaceTint, Colors.transparent);
        expect(scheme.outlineVariant, colors.divider);
      });

      test('$mode: the nav bar paints no surface of its own (the floating '
          'container owns it) and, since Phase D1, no indicator pill', () {
        final nav = theme.navigationBarTheme;
        expect(nav.backgroundColor, Colors.transparent);
        expect(nav.elevation, 0);
        expect(nav.surfaceTintColor, Colors.transparent);
        expect(nav.indicatorColor, Colors.transparent);
      });

      test('$mode: an unselected switch clears 3:1 non-text contrast '
          'against the surface it sits on', () {
        final switchTheme = theme.switchTheme;
        final outline = switchTheme.trackOutlineColor!.resolve({})!;
        final thumb = switchTheme.thumbColor!.resolve({})!;
        expect(contrast(outline, colors.surface), greaterThanOrEqualTo(3));
        expect(contrast(thumb, colors.surface), greaterThanOrEqualTo(3));
        // Selected keeps the primary track THIRTY already uses.
        expect(
          switchTheme.trackColor!.resolve({WidgetState.selected}),
          colors.primary,
        );
      });

      test('$mode: dividers use the divider token, not the generated '
          'outlineVariant', () {
        expect(theme.dividerTheme.color, colors.divider);
      });
    }
  });
}
