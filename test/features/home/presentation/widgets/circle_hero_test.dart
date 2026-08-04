import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/core/widgets/thirty_progress_circle.dart';
import 'package:thirty/core/world_rendering/quiet_trail_hero_asset_view.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
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

/// Same setup as [_wrap], but backed by a [ProviderContainer] the caller
/// keeps a handle to — needed only by the interaction-gate tests below,
/// which assert on [RecommendationStatus] directly rather than inferring
/// it solely from the button's label.
Future<(Widget, ProviderContainer)> _wrapWithContainer({
  Map<String, Object> storedPrefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(storedPrefs);
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
      home: const Scaffold(body: CircleHero()),
    ),
  );
  return (widget, container);
}

/// The [FadeTransition] this task added directly around the Start Circle
/// button — reading its live `opacity.value` is how the tests below prove
/// they are inside a given reveal window, instead of assuming a
/// timestamp lands there. `.first` selects the nearest ancestor: farther
/// up the tree, `MaterialApp`'s own route machinery adds an unrelated
/// `FadeTransition` of its own, which `find.ancestor` also matches.
FadeTransition _buttonFadeTransition(WidgetTester tester) {
  return tester.widget<FadeTransition>(
    find.ancestor(
      of: find.byType(ThirtyButton),
      matching: find.byType(FadeTransition),
    ).first,
  );
}

/// Advances the pump clock until the Start Circle button's own
/// [FadeTransition] reports an opacity strictly between 0 and 1, then
/// returns that observed value — proof the test landed inside the
/// button's partial fade-in, not a guess at a millisecond offset. The
/// initial jump is deliberately short of the button phase's documented
/// start (circle_hero.dart's own doc comment: hold + Circle-opening +
/// illustration + heading + intent + activity/why ≈ 5.2s, with the
/// button phase beginning shortly after); the loop that follows is what
/// actually proves the window, by inspecting the real animation value on
/// every step rather than trusting the jump alone.
Future<double> _pumpUntilButtonPartiallyFaded(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 5000));

  const step = Duration(milliseconds: 20);
  for (var i = 0; i < 100; i++) {
    final opacity = _buttonFadeTransition(tester).opacity.value;
    if (opacity > 0 && opacity < 1) {
      return opacity;
    }
    if (opacity >= 1) {
      fail(
        'The button reveal reached full opacity before a partial-fade '
        'frame could be observed — the test window is no longer valid.',
      );
    }
    await tester.pump(step);
  }
  fail('The button reveal never produced a partial-fade frame.');
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
            .getCenter(find.byType(QuietTrailHeroAssetView))
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
      'renders the approved Quiet Trail illustration, inset inside the '
      'ring',
      (WidgetTester tester) async {
        await tester.pumpWidget(await _wrap());
        await tester.pumpAndSettle();

        expect(find.byType(QuietTrailHeroAssetView), findsOneWidget);
        expect(find.byType(HorizonIllustration), findsNothing);

        final illustrationSize = tester.getSize(
          find.byType(QuietTrailHeroAssetView),
        );
        final circleSize = tester.getSize(find.byType(ThirtyProgressCircle));

        expect(illustrationSize.width, illustrationSize.height);
        expect(illustrationSize.width, lessThan(circleSize.width));
        expect(illustrationSize.height, lessThan(circleSize.height));
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

    group('Start Circle interaction gate', () {
      testWidgets(
        'ignores taps while the button is still fully hidden during The '
        'First Breath',
        (WidgetTester tester) async {
          final (widget, container) = await _wrapWithContainer();
          addTearDown(container.dispose);

          await tester.pumpWidget(widget);
          await tester.pump();

          // The button is fully transparent here, so a tap at its
          // location is expected to land on nothing rather than on the
          // button — that is the behaviour under test, not a test
          // failure in itself; the decisive proof is the business
          // result asserted below.
          await tester.tap(find.byType(ThirtyButton), warnIfMissed: false);
          await tester.pump();

          expect(
            container.read(recommendationProvider).status,
            RecommendationStatus.notStarted,
          );
          expect(find.text('Circle started'), findsNothing);
          expect(find.text('Start Circle'), findsOneWidget);
        },
      );

      testWidgets(
        'ignores taps while the button is only partially faded in',
        (WidgetTester tester) async {
          final (widget, container) = await _wrapWithContainer();
          addTearDown(container.dispose);

          await tester.pumpWidget(widget);
          final opacity = await _pumpUntilButtonPartiallyFaded(tester);
          expect(opacity, greaterThan(0.0));
          expect(opacity, lessThan(1.0));

          await tester.tap(find.byType(ThirtyButton), warnIfMissed: false);
          await tester.pump();

          expect(
            container.read(recommendationProvider).status,
            RecommendationStatus.notStarted,
          );
          expect(find.text('Circle started'), findsNothing);
        },
      );

      testWidgets(
        'accepts the tap once the button has fully finished revealing',
        (WidgetTester tester) async {
          final (widget, container) = await _wrapWithContainer();
          addTearDown(container.dispose);

          await tester.pumpWidget(widget);
          await tester.pumpAndSettle();

          await tester.ensureVisible(find.byType(ThirtyButton));
          await tester.tap(find.byType(ThirtyButton));
          await tester.pump();

          expect(
            container.read(recommendationProvider).status,
            RecommendationStatus.started,
          );
          expect(find.text('Circle started'), findsOneWidget);
          expect(find.text('Start Circle'), findsNothing);

          final button = tester.widget<ThirtyButton>(
            find.byType(ThirtyButton),
          );
          expect(button.onPressed, isNull);
        },
      );

      testWidgets(
        'is immediately interactive on repeat opening the same local day',
        (WidgetTester tester) async {
          final (widget, container) = await _wrapWithContainer(
            storedPrefs: {firstBreathLastPlayedDateKey: '2026-08-02'},
          );
          addTearDown(container.dispose);

          await tester.pumpWidget(widget);
          await tester.pump();

          await tester.ensureVisible(find.byType(ThirtyButton));
          await tester.tap(find.byType(ThirtyButton));
          await tester.pump();

          expect(
            container.read(recommendationProvider).status,
            RecommendationStatus.started,
          );
          expect(find.text('Circle started'), findsOneWidget);
        },
      );

      testWidgets(
        'wraps the button in an IgnorePointer tied to its own reveal '
        'animation',
        (WidgetTester tester) async {
          await tester.pumpWidget(await _wrap());
          await tester.pump();

          // `.first` selects the nearest ancestor — the one this task
          // added — since other framework internals (e.g. MaterialApp's
          // own route machinery) also place an IgnorePointer somewhere
          // higher up the same ancestor chain.
          IgnorePointer buttonGate() => tester.widget<IgnorePointer>(
            find
                .ancestor(
                  of: find.byType(ThirtyButton),
                  matching: find.byType(IgnorePointer),
                )
                .first,
          );

          expect(buttonGate().ignoring, isTrue);

          await tester.pumpAndSettle();

          expect(buttonGate().ignoring, isFalse);
        },
      );
    });
  });
}
