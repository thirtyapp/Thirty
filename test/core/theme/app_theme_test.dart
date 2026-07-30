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
}
