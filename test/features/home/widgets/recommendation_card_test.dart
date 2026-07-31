import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/widgets/recommendation_card.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

const _recommendation = Recommendation(
  intent: 'Meer energie',
  activity: '30 minuten wandelen',
  duration: '30 minuten',
  why:
      'Een rustige wandeling is vandaag een eenvoudige manier om energie '
      'op te bouwen.',
);

void main() {
  group('RecommendationCard', () {
    testWidgets('shows intent, activity, duration and why', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          RecommendationCard(
            recommendation: _recommendation,
            status: RecommendationStatus.notStarted,
            onStart: () {},
          ),
        ),
      );

      expect(find.text(_recommendation.intent), findsOneWidget);
      expect(find.text(_recommendation.activity), findsOneWidget);
      expect(find.text(_recommendation.duration), findsOneWidget);
      expect(find.text(_recommendation.why), findsOneWidget);
    });

    testWidgets('shows a Start button when not started', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          RecommendationCard(
            recommendation: _recommendation,
            status: RecommendationStatus.notStarted,
            onStart: () {},
          ),
        ),
      );

      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('calls onStart when the button is tapped', (
      WidgetTester tester,
    ) async {
      var started = false;
      await tester.pumpWidget(
        _wrap(
          RecommendationCard(
            recommendation: _recommendation,
            status: RecommendationStatus.notStarted,
            onStart: () => started = true,
          ),
        ),
      );

      await tester.tap(find.text('Start'));
      await tester.pump();

      expect(started, isTrue);
    });

    testWidgets('shows "Gestart" and disables the button once started', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          RecommendationCard(
            recommendation: _recommendation,
            status: RecommendationStatus.started,
            onStart: () {},
          ),
        ),
      );

      expect(find.text('Gestart'), findsOneWidget);
      expect(find.text('Start'), findsNothing);

      final button = tester.widget<ThirtyButton>(find.byType(ThirtyButton));
      expect(button.onPressed, isNull);
    });
  });
}
