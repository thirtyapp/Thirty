import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/core/widgets/thirty_progress_circle.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/widgets/circle_ready_prompt.dart';
import 'package:thirty/features/home/presentation/widgets/daily_intention_prompt.dart';

final _today = DateTime(2026, 8, 2);

Future<(Widget, ProviderContainer)> _wrap({
  bool disableAnimations = false,
  double? textScale,
  ThemeData? theme,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_today),
    ],
  );

  final child = const Scaffold(body: CircleReadyPrompt());
  final needsMediaQueryOverride = disableAnimations || textScale != null;
  final widget = UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: theme ?? AppTheme.light,
      // Reduced motion/text scale are only wired up via an explicit
      // MediaQuery override, matching circle_hero_test.dart's own
      // convention: there is no ambient MediaQuery override at this call
      // site otherwise.
      home: needsMediaQueryOverride
          ? Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: disableAnimations,
                  textScaler: textScale == null
                      ? null
                      : TextScaler.linear(textScale),
                ),
                child: child,
              ),
            )
          : child,
    ),
  );
  return (widget, container);
}

void main() {
  group('CircleReadyPrompt', () {
    testWidgets('shows the closed Circle and Begin today\'s Circle CTA, '
        'not the direction chooser', (tester) async {
      final (widget, container) = await _wrap();
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);

      expect(find.text("Begin today's Circle"), findsOneWidget);
      expect(find.byType(DailyIntentionPrompt), findsNothing);
    });

    testWidgets(
      'tapping Begin today\'s Circle reveals the three directions inline',
      (tester) async {
        final (widget, container) = await _wrap();
        addTearDown(container.dispose);
        await tester.pumpWidget(widget);

        await tester.ensureVisible(find.text("Begin today's Circle"));
        await tester.tap(find.text("Begin today's Circle"));
        await tester.pumpAndSettle();

        expect(find.byType(DailyIntentionPrompt), findsOneWidget);
        expect(find.text('What would help most today?'), findsOneWidget);
        expect(find.text('More Energy'), findsOneWidget);
        expect(find.text('Clearer Head'), findsOneWidget);
        expect(find.text('Gentler Pace'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Begin today\'s Circle does not mutate recommendation state',
      (tester) async {
        final (widget, container) = await _wrap();
        addTearDown(container.dispose);
        await tester.pumpWidget(widget);

        await tester.ensureVisible(find.text("Begin today's Circle"));
        await tester.tap(find.text("Begin today's Circle"));
        await tester.pumpAndSettle();

        final state = container.read(recommendationProvider);
        expect(state.recommendation, isNull);
        expect(state.status, RecommendationStatus.notStarted);
      },
    );

    testWidgets(
      'reduced motion swaps directly to the direction chooser with no '
      'animated transition',
      (tester) async {
        final (widget, container) = await _wrap(disableAnimations: true);
        addTearDown(container.dispose);
        await tester.pumpWidget(widget);

        await tester.ensureVisible(find.text("Begin today's Circle"));
        await tester.tap(find.text("Begin today's Circle"));
        await tester.pump();

        expect(find.byType(DailyIntentionPrompt), findsOneWidget);
      },
    );

    testWidgets(
      'the Circle stays mounted and geometrically stable while Begin '
      "today's Circle reveals the direction choices beneath it — the "
      'exact continuity correction this batch makes: physical '
      'verification of 1.7.0+13 found the whole Circle composition '
      'disappearing behind full-screen direction cards instead',
      (tester) async {
        final (widget, container) = await _wrap();
        addTearDown(container.dispose);
        await tester.pumpWidget(widget);

        expect(find.byType(ThirtyProgressCircle), findsOneWidget);
        final circleElement = tester.element(
          find.byType(ThirtyProgressCircle),
        );
        final rectBefore = tester.getRect(find.byType(ThirtyProgressCircle));

        await tester.ensureVisible(find.text("Begin today's Circle"));
        await tester.tap(find.text("Begin today's Circle"));
        await tester.pumpAndSettle();

        // Still exactly one Circle — the direction chooser was revealed
        // alongside it, not after removing and re-adding it — and it is
        // the very same Element, i.e. never unmounted/remounted, not just
        // a new one that happens to look the same.
        expect(find.byType(ThirtyProgressCircle), findsOneWidget);
        expect(
          tester.element(find.byType(ThirtyProgressCircle)),
          same(circleElement),
        );
        expect(
          tester.getRect(find.byType(ThirtyProgressCircle)),
          rectBefore,
          reason:
              'the Circle must not move or resize when the direction '
              'choices appear beneath it',
        );
      },
    );

    testWidgets('choosing a direction after Begin today\'s Circle still '
        'assigns exactly one recommendation via the existing mechanism', (
      tester,
    ) async {
      final (widget, container) = await _wrap();
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);

      await tester.ensureVisible(find.text("Begin today's Circle"));
      await tester.tap(find.text("Begin today's Circle"));
      await tester.pumpAndSettle();
      // The Circle now stays mounted above the direction choices (the
      // continuity correction itself), so — unlike before, when the
      // direction chooser had the whole viewport to itself — this option
      // can start below the fold and needs scrolling into view first.
      await tester.ensureVisible(find.text('Clearer Head'));
      await tester.tap(find.text('Clearer Head'));
      await tester.pump();

      final state = container.read(recommendationProvider);
      expect(state.recommendation, isNotNull);
      expect(state.recommendation!.intent, 'Clearer Head');
    });
  });

  // Golden Home Batch — bounded QA floor: 320x568 is a layout/visual test
  // fixture for this batch, not a new public device-support promise; 200%
  // is the accessibility text-scale target. Neither is a real device —
  // both simply prove the new Ready composition doesn't overflow or lose
  // reachability under these two independent stresses, together and
  // apart.
  group('Golden Home QA floor (320x568 / 200% text)', () {
    testWidgets('320x568 renders with no overflow and Begin today\'s '
        'Circle stays reachable', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;

      final (widget, container) = await _wrap();
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);

      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text("Begin today's Circle"));
      await tester.tap(find.text("Begin today's Circle"));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DailyIntentionPrompt), findsOneWidget);
    });

    testWidgets('200% text scale renders with no overflow and keeps '
        'Begin today\'s Circle reachable', (tester) async {
      final (widget, container) = await _wrap(textScale: 2.0);
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);

      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text("Begin today's Circle"));
      await tester.tap(find.text("Begin today's Circle"));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DailyIntentionPrompt), findsOneWidget);
    });

    testWidgets(
      '320x568 combined with 200% text renders with no overflow and '
      'keeps every action reachable',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;

        final (widget, container) = await _wrap(textScale: 2.0);
        addTearDown(container.dispose);
        await tester.pumpWidget(widget);

        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text("Begin today's Circle"));
        await tester.tap(find.text("Begin today's Circle"));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(DailyIntentionPrompt), findsOneWidget);
        await tester.ensureVisible(find.text('Clearer Head'));
        await tester.tap(find.text('Clearer Head'));
        await tester.pump();

        expect(tester.takeException(), isNull);
        final state = container.read(recommendationProvider);
        expect(state.recommendation, isNotNull);
      },
    );

    testWidgets('Dark mode renders the Ready state with no overflow', (
      tester,
    ) async {
      final (widget, container) = await _wrap(theme: AppTheme.dark);
      addTearDown(container.dispose);
      await tester.pumpWidget(widget);

      expect(tester.takeException(), isNull);
      expect(find.text("Begin today's Circle"), findsOneWidget);
    });
  });
}
