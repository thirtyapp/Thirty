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
import 'package:thirty/features/home/presentation/widgets/circle_reflection_card.dart';

/// V2 Phase C — the closed Circle's inline reflection (ADR-021), carrying
/// over every guarantee of the V1 post-Close prompt (ADR-013 §4) it
/// replaces: optional, attempt first, usefulness only after "Yes" or "A
/// little", and now the acknowledgement and the way to memory.

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
      home: const Scaffold(body: CircleReflectionCard()),
    ),
  );
  return (widget, container);
}

void main() {
  testWidgets('shows the attempt question once closed, with all three '
      'answers', (tester) async {
    final (widget, container) = await _wrap(_closedToday());
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    expect(find.text('A brisk walk'), findsOneWidget);
    expect(find.text(CircleReflectionCard.attemptQuestion), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('A little'), findsOneWidget);
    expect(find.text('Not today'), findsOneWidget);
    // Optional: no answer has been recorded by showing it.
    expect(container.read(recommendationProvider).attemptResponse, isNull);
  });

  testWidgets('tapping Yes records the attempt and reveals the usefulness '
      'question', (tester) async {
    final (widget, container) = await _wrap(_closedToday());
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    await tester.tap(find.text('Yes'));
    await tester.pump();

    expect(
      container.read(recommendationProvider).attemptResponse,
      CircleAttemptResponse.yes,
    );
    expect(find.text(CircleReflectionCard.attemptQuestion), findsNothing);
    expect(find.text(CircleReflectionCard.usefulnessQuestion), findsOneWidget);
    expect(find.text('Very useful'), findsOneWidget);
    expect(find.text('Somewhat useful'), findsOneWidget);
    expect(find.text('Not useful'), findsOneWidget);
  });

  testWidgets('tapping Not today records the attempt, asks nothing more, and '
      'says it won’t count against the activity', (tester) async {
    final (widget, container) = await _wrap(_closedToday());
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    await tester.tap(find.text('Not today'));
    await tester.pump();

    expect(
      container.read(recommendationProvider).attemptResponse,
      CircleAttemptResponse.notToday,
    );
    expect(container.read(recommendationProvider).usefulnessResponse, isNull);
    expect(find.text(CircleReflectionCard.usefulnessQuestion), findsNothing);
    expect(
      find.text('No problem — that won’t count against it.'),
      findsOneWidget,
    );
    expect(find.text(CircleReflectionCard.memoryLink), findsOneWidget);
  });

  testWidgets('answering usefulness records it once and acknowledges what it '
      'changes', (tester) async {
    final (widget, container) = await _wrap(_closedToday());
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    await tester.tap(find.text('A little'));
    await tester.pump();
    await tester.tap(find.text('Not useful'));
    await tester.pump();

    final state = container.read(recommendationProvider);
    expect(state.attemptResponse, CircleAttemptResponse.aLittle);
    expect(state.usefulnessResponse, CircleUsefulnessResponse.notUseful);
    expect(find.text(CircleReflectionCard.attemptQuestion), findsNothing);
    expect(find.text(CircleReflectionCard.usefulnessQuestion), findsNothing);
    expect(
      find.text('Thanks — THIRTY will rest this one for a while.'),
      findsOneWidget,
    );
    expect(find.text(CircleReflectionCard.memoryLink), findsOneWidget);
  });

  testWidgets('the answers are full 48pt targets with their own labels', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final (widget, container) = await _wrap(_closedToday());
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    for (final answer in ['Yes', 'A little', 'Not today']) {
      final node = find.bySemanticsLabel(answer);
      expect(
        tester.getSemantics(node),
        matchesSemantics(label: answer, isButton: true, hasTapAction: true),
      );
      expect(tester.getSize(node).height, greaterThanOrEqualTo(48));
    }
    semantics.dispose();
  });

  testWidgets('at 200% text the answers stack at full width, never '
      'truncated', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final (widget, container) = await _wrap({
      ..._closedToday(),
      recommendationAttemptResponseKey: 'yes',
    });
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    expect(tester.takeException(), isNull);
    final very = tester.getRect(find.text('Very useful'));
    final not = tester.getRect(find.text('Not useful'));
    expect(not.top, greaterThan(very.bottom));
  });

  group(
    'reflectionPendingProvider (Step 5 prompt-priority reconciliation)',
    () {
      Future<ProviderContainer> containerWith(Map<String, Object> prefs) async {
        SharedPreferences.setMockInitialValues(prefs);
        final resolved = await SharedPreferences.getInstance();
        return ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(resolved),
            nowProvider.overrideWithValue(_today),
          ],
        );
      }

      test('false before today\'s Circle is closed', () async {
        final container = await containerWith({
          recommendationDayKey: '2026-08-02',
          recommendationIntentionKey: 'moreEnergy',
          recommendationActivityIdKey: 'thirtyMinuteWalk',
        });
        addTearDown(container.dispose);

        expect(container.read(reflectionPendingProvider), isFalse);
      });

      test('true once closed with the attempt question unanswered', () async {
        final container = await containerWith(_closedToday());
        addTearDown(container.dispose);

        expect(container.read(reflectionPendingProvider), isTrue);
      });

      test(
        'true after an affirmative attempt with usefulness unanswered',
        () async {
          final container = await containerWith(_closedToday());
          addTearDown(container.dispose);
          container
              .read(recommendationProvider.notifier)
              .reportAttempt(CircleAttemptResponse.aLittle);

          expect(container.read(reflectionPendingProvider), isTrue);
        },
      );

      test(
        'false once "Not today" is reported — no follow-up question',
        () async {
          final container = await containerWith(_closedToday());
          addTearDown(container.dispose);
          container
              .read(recommendationProvider.notifier)
              .reportAttempt(CircleAttemptResponse.notToday);

          expect(container.read(reflectionPendingProvider), isFalse);
        },
      );

      test('false once both questions are answered', () async {
        final container = await containerWith(_closedToday());
        addTearDown(container.dispose);
        final notifier = container.read(recommendationProvider.notifier);
        notifier.reportAttempt(CircleAttemptResponse.aLittle);
        notifier.reportUsefulness(CircleUsefulnessResponse.somewhatUseful);

        expect(container.read(reflectionPendingProvider), isFalse);
      });
    },
  );
}
