import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/widgets/daily_intention_prompt.dart';

final _today = DateTime(2026, 8, 2);

Future<(Widget, ProviderContainer)> _wrap() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_today),
    ],
  );
  final widget = UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: DailyIntentionPrompt()),
    ),
  );
  return (widget, container);
}

void main() {
  testWidgets('shows the Daily Context Question and exactly three options', (
    tester,
  ) async {
    final (widget, container) = await _wrap();
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    expect(find.text('What would help most today?'), findsOneWidget);
    expect(find.text('More Energy'), findsOneWidget);
    expect(find.text('Clearer Head'), findsOneWidget);
    expect(find.text('Gentler Pace'), findsOneWidget);
  });

  testWidgets('tapping an option chooses that intention', (tester) async {
    final (widget, container) = await _wrap();
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    await tester.tap(find.text('Clearer Head'));
    await tester.pump();

    final state = container.read(recommendationProvider);
    expect(state.recommendation, isNotNull);
    expect(state.recommendation!.intent, 'Clearer Head');
  });

  testWidgets(
    'each option is exposed as a semantic button with its label and meaning',
    (tester) async {
      final (widget, container) = await _wrap();
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);

      // Several Semantics ancestors sit above the Text (this widget's own
      // explicit node, ExcludeSemantics's internal one, and ambient ones
      // from MaterialApp/Scaffold) — find the one that actually carries
      // `button: true`, this widget's own.
      final semantics = tester
          .widgetList<Semantics>(
            find.ancestor(
              of: find.text('More Energy'),
              matching: find.byType(Semantics),
            ),
          )
          .firstWhere((widget) => widget.properties.button == true);

      expect(semantics.properties.button, isTrue);
      expect(
        semantics.properties.label,
        'More Energy. ${intentionMeaning(Intention.moreEnergy)}',
      );
    },
  );
}
