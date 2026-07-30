import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_progress_circle.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  group('ThirtyProgressCircle', () {
    testWidgets('renders for progress values across the valid range', (
      WidgetTester tester,
    ) async {
      for (final value in [0.0, 0.5, 1.0]) {
        await tester.pumpWidget(_wrap(ThirtyProgressCircle(progress: value)));
        expect(find.byType(ThirtyProgressCircle), findsOneWidget);
      }
    });

    testWidgets('renders progress 1.0 without throwing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const ThirtyProgressCircle(progress: 1.0)));

      expect(tester.takeException(), isNull);
      expect(find.byType(ThirtyProgressCircle), findsOneWidget);
    });

    testWidgets('clamps out-of-range progress values', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const ThirtyProgressCircle(progress: 1.4, semanticLabel: 'Voortgang'),
        ),
      );

      final semantics = tester.getSemantics(find.byType(ThirtyProgressCircle));
      expect(semantics.label, 'Voortgang');
      expect(semantics.value, '100%');
    });

    testWidgets('exposes progress via semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          const ThirtyProgressCircle(
            progress: 0.5,
            semanticLabel: 'Dagelijkse voortgang',
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(ThirtyProgressCircle));
      expect(semantics.label, 'Dagelijkse voortgang');
      expect(semantics.value, '50%');
    });

    testWidgets('renders optional center content', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(const ThirtyProgressCircle(progress: 0.5, child: Text('15 min'))),
      );

      expect(find.text('15 min'), findsOneWidget);
    });

    test('accepts valid size/strokeWidth combinations', () {
      expect(
        () => const ThirtyProgressCircle(
          progress: 0.5,
          size: 100,
          strokeWidth: 8,
        ),
        returnsNormally,
      );
    });

    test('asserts size must be greater than 0', () {
      expect(
        () => ThirtyProgressCircle(progress: 0.5, size: 0),
        throwsAssertionError,
      );
    });

    test('asserts strokeWidth must be greater than 0', () {
      expect(
        () => ThirtyProgressCircle(progress: 0.5, strokeWidth: 0),
        throwsAssertionError,
      );
    });

    test('asserts strokeWidth must be smaller than size', () {
      expect(
        () => ThirtyProgressCircle(progress: 0.5, size: 40, strokeWidth: 40),
        throwsAssertionError,
      );
    });
  });
}
