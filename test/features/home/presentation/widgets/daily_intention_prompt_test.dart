import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/widgets/daily_intention_prompt.dart';

final _today = DateTime(2026, 8, 2);

const _introText =
    'Choose a direction. THIRTY gives you one activity to do '
    'offline, in about thirty minutes. Tomorrow brings a new '
    'Circle.';

Future<(Widget, ProviderContainer)> _wrap({
  Map<String, Object> prefs = const {},
}) async {
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

  testWidgets(
    'a real assistive-technology tap action (SemanticsAction.tap), not '
    'just the button/label flags, actually chooses the intention '
    '(ADR-013 §9)',
    (tester) async {
      final (widget, container) = await _wrap();
      addTearDown(container.dispose);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(widget);

      // find.bySemanticsLabel resolves via the runtime SemanticsNode tree
      // itself (unlike find.text, which walks up from the render object
      // and can land on an unrelated ancestor node) — the precise way to
      // target the exact node an assistive technology would activate.
      final semantics = tester.getSemantics(
        find.bySemanticsLabel(
          'Clearer Head. ${intentionMeaning(Intention.clearerHead)}',
        ),
      );
      expect(
        semantics.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason:
            'the node TalkBack would activate must itself carry a tap '
            'action — a label/button flag alone is not enough',
      );

      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        semantics.id,
        SemanticsAction.tap,
      );
      await tester.pump();

      final state = container.read(recommendationProvider);
      expect(state.recommendation, isNotNull);
      expect(state.recommendation!.intent, 'Clearer Head');

      handle.dispose();
    },
  );

  group('first-use onboarding explanation (Step 5 reconciliation)', () {
    testWidgets(
      'shows the explanation above the daily question on a genuinely '
      'first use, with all three directions still immediately reachable',
      (tester) async {
        final (widget, container) = await _wrap();
        addTearDown(container.dispose);
        await tester.pumpWidget(widget);

        expect(find.text(_introText), findsOneWidget);
        expect(find.text('What would help most today?'), findsOneWidget);
        expect(find.text('More Energy'), findsOneWidget);
        expect(find.text('Clearer Head'), findsOneWidget);
        expect(find.text('Gentler Pace'), findsOneWidget);
      },
    );

    testWidgets('never shows again once a direction has actually been '
        'chosen', (tester) async {
      final (widget, container) = await _wrap();
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);
      expect(find.text(_introText), findsOneWidget);

      await tester.tap(find.text('More Energy'));
      await tester.pump();

      expect(
        container
            .read(sharedPreferencesProvider)
            .getBool(onboardingIntroShownKey),
        isTrue,
      );
    });

    testWidgets('never shows once already marked shown', (tester) async {
      final (widget, container) = await _wrap(
        prefs: {onboardingIntroShownKey: true},
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);

      expect(find.text(_introText), findsNothing);
      expect(find.text('What would help most today?'), findsOneWidget);
    });

    testWidgets(
      'never shows for an install that already has prior journal history '
      '— an upgraded pre-onboarding user is never told this is their '
      'first use',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            nowProvider.overrideWithValue(_today),
          ],
        );
        addTearDown(container.dispose);
        await container
            .read(circleJournalRepositoryProvider)
            .recordShown(
              circleId: 'circle_2026-07-01',
              localDate: '2026-07-01',
              direction: Intention.moreEnergy,
              activityId: ActivityId.thirtyMinuteWalk,
              shownAt: DateTime(2026, 7, 1),
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(body: DailyIntentionPrompt()),
            ),
          ),
        );

        expect(find.text(_introText), findsNothing);
      },
    );
  });
}
