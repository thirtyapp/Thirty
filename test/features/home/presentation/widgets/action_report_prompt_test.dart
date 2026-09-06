import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/widgets/action_report_prompt.dart';

final _today = DateTime(2026, 8, 2);

Map<String, Object> _closedToday() => {
  recommendationDayKey: '2026-08-02',
  recommendationIntentionKey: 'moreEnergy',
  recommendationActivityIdKey: 'thirtyMinuteWalk',
  recommendationStatusKey: 'closed',
  recommendationStartedAtKey: _today.toIso8601String(),
  recommendationClosedAtKey: _today.toIso8601String(),
};

Future<(Widget, ProviderContainer)> _wrap(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final resolved = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(resolved),
      nowProvider.overrideWithValue(_today),
    ],
  );
  final widget = UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: ActionReportPrompt()),
    ),
  );
  return (widget, container);
}

void main() {
  testWidgets('renders nothing before today\'s Circle is closed', (
    tester,
  ) async {
    final (widget, container) = await _wrap({
      recommendationDayKey: '2026-08-02',
      recommendationIntentionKey: 'moreEnergy',
      recommendationActivityIdKey: 'thirtyMinuteWalk',
    });
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    expect(find.text('Did you try this activity?'), findsNothing);
  });

  testWidgets(
    'shows the attempt question once closed, with all three answers',
    (tester) async {
      final (widget, container) = await _wrap(_closedToday());
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);

      expect(find.text('Did you try this activity?'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('A little'), findsOneWidget);
      expect(find.text('Not today'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping Yes records the attempt and reveals the usefulness question',
    (tester) async {
      final (widget, container) = await _wrap(_closedToday());
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);

      await tester.tap(find.text('Yes'));
      await tester.pump();

      expect(
        container.read(recommendationProvider).attemptResponse,
        CircleAttemptResponse.yes,
      );
      expect(find.text('Did you try this activity?'), findsNothing);
      expect(find.text('Was it useful?'), findsOneWidget);
      expect(find.text('Very useful'), findsOneWidget);
      expect(find.text('Somewhat useful'), findsOneWidget);
      expect(find.text('Not useful'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping Not today records the attempt and shows no usefulness '
    'follow-up at all',
    (tester) async {
      final (widget, container) = await _wrap(_closedToday());
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);

      await tester.tap(find.text('Not today'));
      await tester.pump();

      expect(
        container.read(recommendationProvider).attemptResponse,
        CircleAttemptResponse.notToday,
      );
      expect(find.text('Was it useful?'), findsNothing);
      expect(find.byType(ActionReportPrompt), findsOneWidget);
      // Nothing left to show — the widget itself renders empty.
      expect(find.text('Did you try this activity?'), findsNothing);
    },
  );

  testWidgets(
    'answering the usefulness question leaves nothing further to show',
    (tester) async {
      final (widget, container) = await _wrap(_closedToday());
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);

      await tester.tap(find.text('A little'));
      await tester.pump();
      await tester.tap(find.text('Somewhat useful'));
      await tester.pump();

      final state = container.read(recommendationProvider);
      expect(state.attemptResponse, CircleAttemptResponse.aLittle);
      expect(state.usefulnessResponse, CircleUsefulnessResponse.somewhatUseful);
      expect(find.text('Did you try this activity?'), findsNothing);
      expect(find.text('Was it useful?'), findsNothing);
    },
  );
}
