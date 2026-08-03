import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/core/widgets/thirty_progress_circle.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';
import 'package:thirty/features/home/presentation/widgets/horizon_illustration.dart';

final _today = DateTime(2026, 8, 2);

Future<Widget> _wrap({Map<String, Object> storedPrefs = const {}}) async {
  SharedPreferences.setMockInitialValues(storedPrefs);
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_today),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: CircleHero()),
    ),
  );
}

void main() {
  group('CircleHero', () {
    testWidgets(
      'starts with the Circle fully closed when The First Breath plays',
      (WidgetTester tester) async {
        await tester.pumpWidget(await _wrap());
        await tester.pump();

        final circle = tester.widget<ThirtyProgressCircle>(
          find.byType(ThirtyProgressCircle),
        );
        expect(circle.progress, 1.0);
      },
    );

    testWidgets('opens the Circle and reveals content once settled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(await _wrap());
      await tester.pumpAndSettle();

      final circle = tester.widget<ThirtyProgressCircle>(
        find.byType(ThirtyProgressCircle),
      );
      expect(circle.progress, 0.0);
      expect(find.text("Today's Circle"), findsOneWidget);
      expect(find.text('More Energy'), findsOneWidget);
      expect(find.text('30 minute walk'), findsOneWidget);
      expect(find.text('Start Circle'), findsOneWidget);
    });

    testWidgets(
      'announces a calm, non-numeric meaning for the Circle instead of a '
      'percentage',
      (WidgetTester tester) async {
        await tester.pumpWidget(await _wrap());
        await tester.pumpAndSettle();

        final semantics = tester.getSemantics(
          find.byType(ThirtyProgressCircle),
        );
        expect(semantics.value, 'Ready to begin.');
        expect(semantics.value, isNot(contains('%')));
        expect(semantics.value, isNot(contains('0')));
      },
    );

    testWidgets('tapping Start Circle marks the recommendation started', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(await _wrap());
      await tester.pumpAndSettle();

      // The larger Circle can push the button below the fold on the
      // default test viewport; scroll it into view before tapping, same
      // as a real user would.
      await tester.ensureVisible(find.text('Start Circle'));
      await tester.tap(find.text('Start Circle'));
      await tester.pump();

      expect(find.text('Circle started'), findsOneWidget);
      expect(find.text('Start Circle'), findsNothing);
    });

    testWidgets(
      'centers the Circle, illustration and text column on the same '
      'horizontal axis as the screen',
      (WidgetTester tester) async {
        await tester.pumpWidget(await _wrap());
        await tester.pumpAndSettle();

        final screenCenterX = tester.getSize(find.byType(MaterialApp)).width / 2;
        final circleCenterX = tester
            .getCenter(find.byType(ThirtyProgressCircle))
            .dx;
        final illustrationCenterX = tester
            .getCenter(find.byType(HorizonIllustration))
            .dx;
        final headingCenterX = tester
            .getCenter(find.text("Today's Circle"))
            .dx;
        final activityCenterX = tester
            .getCenter(find.text('30 minute walk'))
            .dx;

        expect(circleCenterX, closeTo(screenCenterX, 0.5));
        expect(illustrationCenterX, closeTo(screenCenterX, 0.5));
        expect(headingCenterX, closeTo(screenCenterX, 0.5));
        expect(activityCenterX, closeTo(screenCenterX, 0.5));
      },
    );

    testWidgets(
      'shows the fully-settled state instantly when already played today',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          await _wrap(
            storedPrefs: {firstBreathLastPlayedDateKey: '2026-08-02'},
          ),
        );
        await tester.pump();

        final circle = tester.widget<ThirtyProgressCircle>(
          find.byType(ThirtyProgressCircle),
        );
        expect(circle.progress, 0.0);
        expect(find.text("Today's Circle"), findsOneWidget);
        expect(find.text('Start Circle'), findsOneWidget);
      },
    );
  });
}
