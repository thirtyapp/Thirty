import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/branding/thirty_wordmark_view.dart';
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

// Millisecond phase boundaries mirrored from circle_hero.dart's own
// cumulative-fraction arithmetic (wordmark fade-in 300ms, hold 700ms,
// fade-out 300ms, Circle breathe 2200ms, illustration 500ms, then the
// existing pause/heading/intent/activity-why/pause/button chain). Kept
// here as named constants, not re-derived, so the tests below sample the
// animation at its meaningful phase boundaries instead of arbitrary
// timestamps.
const _wordmarkFadeOutEndMs = 1300; // 300 + 700 + 300
const _breatheEndMs = 3500; // + 2200
const _headingEndMs = 4600; // + 500 (illustration) + 200 (pause) + 400
const _intentEndMs = 5150; // + 200 (pause) + 350
const _activityWhyEndMs = 5800; // + 200 (pause) + 450

Future<Widget> _wrap({
  Map<String, Object> storedPrefs = const {},
  bool disableAnimations = false,
}) async {
  SharedPreferences.setMockInitialValues(storedPrefs);
  final prefs = await SharedPreferences.getInstance();

  // Reduced motion is only wired up via an explicit MediaQuery override
  // placed directly above CircleHero, rather than by touching every
  // existing call site — MaterialApp/Scaffold's own ambient MediaQuery is
  // left untouched for every other test.
  final circleHero = disableAnimations
      ? Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: const CircleHero(),
          ),
        )
      : const CircleHero();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_today),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: circleHero),
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

/// Records every `HapticFeedback.vibrate` call THIRTY's Start Circle
/// button makes on [SystemChannels.platform] — the exact platform-channel
/// method/argument [HapticFeedback.lightImpact] invokes (see the Flutter
/// SDK's `haptic_feedback.dart`), read directly rather than through a new
/// haptic-abstraction layer that would exist only to make this mockable.
/// The mock handler is torn down after the test so it can't leak into
/// others.
List<String?> _recordHapticCalls(WidgetTester tester) {
  final calls = <String?>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String?);
      }
      return null;
    },
  );
  addTearDown(() {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });
  return calls;
}

/// The [FadeTransition] this task added directly around the Start Circle
/// button — reading its live `opacity.value` is how the tests below prove
/// they are inside a given reveal window, instead of assuming a
/// timestamp lands there. `.first` selects the nearest ancestor: farther
/// up the tree, `MaterialApp`'s own route machinery adds an unrelated
/// `FadeTransition` of its own, which `find.ancestor` also matches.
FadeTransition _buttonFadeTransition(WidgetTester tester) {
  return tester.widget<FadeTransition>(
    find
        .ancestor(
          of: find.byType(ThirtyButton),
          matching: find.byType(FadeTransition),
        )
        .first,
  );
}

/// The [FadeTransition] wrapping [ThirtyWordmarkView] — same nearest-
/// ancestor reasoning as [_buttonFadeTransition].
FadeTransition _wordmarkFadeTransition(WidgetTester tester) {
  return tester.widget<FadeTransition>(
    find
        .ancestor(
          of: find.byType(ThirtyWordmarkView),
          matching: find.byType(FadeTransition),
        )
        .first,
  );
}

/// The [FadeTransition] wrapping the World illustration — same nearest-
/// ancestor reasoning as [_buttonFadeTransition].
FadeTransition _illustrationFadeTransition(WidgetTester tester) {
  return tester.widget<FadeTransition>(
    find
        .ancestor(
          of: find.byType(QuietTrailHeroAssetView),
          matching: find.byType(FadeTransition),
        )
        .first,
  );
}

double _circleProgress(WidgetTester tester) {
  return tester
      .widget<ThirtyProgressCircle>(find.byType(ThirtyProgressCircle))
      .progress;
}

/// Advances the pump clock until the Start Circle button's own
/// [FadeTransition] reports an opacity strictly between 0 and 1, then
/// returns that observed value — proof the test landed inside the
/// button's partial fade-in, not a guess at a millisecond offset. The
/// initial jump is deliberately short of the button phase's documented
/// start (circle_hero.dart's own doc comment: wordmark + Circle-opening +
/// illustration + heading + intent + activity/why ≈ 5.8s, with the button
/// phase beginning at 6100ms); the loop that follows is what actually
/// proves the window, by inspecting the real animation value on every
/// step rather than trusting the jump alone.
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

        expect(_circleProgress(tester), 1.0);
      },
    );

    testWidgets('opens the Circle and reveals content once settled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(await _wrap());
      await tester.pumpAndSettle();

      expect(_circleProgress(tester), 0.0);
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

      expect(find.text('Close Circle'), findsOneWidget);
      expect(find.text('Start Circle'), findsNothing);
    });

    testWidgets('centers the Circle, illustration and text column on the same '
        'horizontal axis as the screen', (WidgetTester tester) async {
      await tester.pumpWidget(await _wrap());
      await tester.pumpAndSettle();

      final screenCenterX = tester.getSize(find.byType(MaterialApp)).width / 2;
      final circleCenterX = tester
          .getCenter(find.byType(ThirtyProgressCircle))
          .dx;
      final illustrationCenterX = tester
          .getCenter(find.byType(QuietTrailHeroAssetView))
          .dx;
      final headingCenterX = tester.getCenter(find.text("Today's Circle")).dx;
      final activityCenterX = tester.getCenter(find.text('30 minute walk')).dx;

      expect(circleCenterX, closeTo(screenCenterX, 0.5));
      expect(illustrationCenterX, closeTo(screenCenterX, 0.5));
      expect(headingCenterX, closeTo(screenCenterX, 0.5));
      expect(activityCenterX, closeTo(screenCenterX, 0.5));
    });

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

        expect(_circleProgress(tester), 0.0);
        expect(find.text("Today's Circle"), findsOneWidget);
        expect(find.text('Start Circle'), findsOneWidget);
      },
    );

    group('First Breath v2 — wordmark and Circle-opening sequencing', () {
      testWidgets(
        'shows the wordmark fully visible during its hold phase, before '
        'the Circle opens',
        (WidgetTester tester) async {
          await tester.pumpWidget(await _wrap());
          // Mid-hold: hold spans 300–1000ms.
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.byType(ThirtyWordmarkView), findsOneWidget);
          expect(_wordmarkFadeTransition(tester).opacity.value, 1.0);
          expect(_circleProgress(tester), 1.0);
        },
      );

      testWidgets(
        'keeps the Circle fully closed throughout the wordmark fade-in, '
        'hold and fade-out',
        (WidgetTester tester) async {
          await tester.pumpWidget(await _wrap());

          var elapsed = 0;
          for (final targetMs in [
            0,
            150,
            500,
            1000,
            1250,
            // One ms short of the fade-out's own end, not the exact
            // boundary: floating-point time-to-fraction conversion can
            // make an exact-boundary sample land a hair on either side of
            // an Interval's `end`, which is a real animation-timing
            // property (see the dedicated boundary test below), not
            // something this "still closed throughout" check needs to
            // resolve.
            _wordmarkFadeOutEndMs - 1,
          ]) {
            await tester.pump(Duration(milliseconds: targetMs - elapsed));
            elapsed = targetMs;

            expect(
              _circleProgress(tester),
              1.0,
              reason: 'Circle progress at ${targetMs}ms',
            );
          }
        },
      );

      testWidgets(
        'starts opening the Circle only once wordmark opacity has reached '
        '0',
        (WidgetTester tester) async {
          await tester.pumpWidget(await _wrap());

          // Just short of the wordmark's fade-out finishing: still fully
          // closed.
          await tester.pump(
            const Duration(milliseconds: _wordmarkFadeOutEndMs - 1),
          );
          expect(_circleProgress(tester), 1.0);

          // Comfortably after: the wordmark has fully gone, and only now
          // does the Circle have any progress.
          await tester.pump(const Duration(milliseconds: 51));
          expect(_wordmarkFadeTransition(tester).opacity.value, 0.0);
          expect(_circleProgress(tester), lessThan(1.0));
        },
      );

      testWidgets(
        'never renders a frame where the wordmark is visible while the '
        'Circle has already started opening',
        (WidgetTester tester) async {
          await tester.pumpWidget(await _wrap());

          var elapsed = 0;
          const step = 20;
          const sweepEnd = _wordmarkFadeOutEndMs + 500;
          var sawCircleOpen = false;

          while (elapsed <= sweepEnd) {
            final wordmarkOpacity = _wordmarkFadeTransition(
              tester,
            ).opacity.value;
            final circleProgress = _circleProgress(tester);

            if (circleProgress < 1.0) sawCircleOpen = true;

            // A tiny epsilon, not strict >0/<1.0: floating-point
            // time-to-fraction conversion can leave either quantity a
            // sub-microscopic distance from its ideal 0/1 value on any
            // single sampled frame — negligible next to the phases' real
            // durations (hundreds/thousands of ms), but enough to make a
            // bit-exact comparison flaky. A genuine overlap would show up
            // as values far outside this epsilon.
            const epsilon = 1e-4;
            expect(
              wordmarkOpacity > epsilon && circleProgress < 1.0 - epsilon,
              isFalse,
              reason:
                  'at ${elapsed}ms: wordmark opacity=$wordmarkOpacity, '
                  'circle progress=$circleProgress',
            );

            await tester.pump(const Duration(milliseconds: step));
            elapsed += step;
          }

          // Proves the sweep wasn't vacuously true (the Circle really did
          // start opening somewhere in this window).
          expect(sawCircleOpen, isTrue);
        },
      );

      testWidgets(
        'keeps the World illustration hidden until the Circle has fully '
        'opened',
        (WidgetTester tester) async {
          await tester.pumpWidget(await _wrap());

          // Partway through the Circle's own 2200ms opening: the
          // illustration must still be fully hidden.
          await tester.pump(
            const Duration(milliseconds: _wordmarkFadeOutEndMs + 1000),
          );
          expect(_circleProgress(tester), greaterThan(0.0));
          expect(_illustrationFadeTransition(tester).opacity.value, 0.0);

          // Comfortably after the Circle has fully finished opening: only
          // now has the illustration begun to appear.
          await tester.pump(
            const Duration(
              milliseconds:
                  _breatheEndMs - (_wordmarkFadeOutEndMs + 1000) + 100,
            ),
          );
          expect(_circleProgress(tester), 0.0);
          expect(
            _illustrationFadeTransition(tester).opacity.value,
            greaterThan(0.0),
          );
        },
      );

      testWidgets(
        'reveals heading before intent, and intent before activity/why, '
        'preserving the existing content order',
        (WidgetTester tester) async {
          await tester.pumpWidget(await _wrap());

          await tester.pump(const Duration(milliseconds: _headingEndMs));
          final headingOpacity = tester
              .widget<FadeTransition>(
                find
                    .ancestor(
                      of: find.text("Today's Circle"),
                      matching: find.byType(FadeTransition),
                    )
                    .first,
              )
              .opacity
              .value;
          final intentOpacityAtHeadingEnd = tester
              .widget<FadeTransition>(
                find
                    .ancestor(
                      of: find.text('More Energy'),
                      matching: find.byType(FadeTransition),
                    )
                    .first,
              )
              .opacity
              .value;
          // closeTo, not exact 1.0: sampling exactly at an Interval's own
          // `end` is subject to the same floating-point time-to-fraction
          // noise noted above.
          expect(headingOpacity, closeTo(1.0, 0.001));
          expect(intentOpacityAtHeadingEnd, 0.0);

          await tester.pump(
            const Duration(milliseconds: _intentEndMs - _headingEndMs),
          );
          final intentOpacity = tester
              .widget<FadeTransition>(
                find
                    .ancestor(
                      of: find.text('More Energy'),
                      matching: find.byType(FadeTransition),
                    )
                    .first,
              )
              .opacity
              .value;
          final activityOpacityAtIntentEnd = tester
              .widget<FadeTransition>(
                find
                    .ancestor(
                      of: find.text('30 minute walk'),
                      matching: find.byType(FadeTransition),
                    )
                    .first,
              )
              .opacity
              .value;
          expect(intentOpacity, closeTo(1.0, 0.001));
          expect(activityOpacityAtIntentEnd, 0.0);

          await tester.pump(
            const Duration(milliseconds: _activityWhyEndMs - _intentEndMs),
          );
          final activityOpacity = tester
              .widget<FadeTransition>(
                find
                    .ancestor(
                      of: find.text('30 minute walk'),
                      matching: find.byType(FadeTransition),
                    )
                    .first,
              )
              .opacity
              .value;
          expect(activityOpacity, closeTo(1.0, 0.001));
          expect(_buttonFadeTransition(tester).opacity.value, 0.0);

          await tester.pumpAndSettle();
          expect(find.text('Start Circle'), findsOneWidget);
        },
      );

      testWidgets(
        'skips the wordmark ritual entirely when First Breath already '
        'played today',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            await _wrap(
              storedPrefs: {firstBreathLastPlayedDateKey: '2026-08-02'},
            ),
          );
          await tester.pump();

          expect(_wordmarkFadeTransition(tester).opacity.value, 0.0);
          expect(_circleProgress(tester), 0.0);
          expect(find.text("Today's Circle"), findsOneWidget);
          expect(find.text('Start Circle'), findsOneWidget);
        },
      );

      testWidgets(
        'plays no ritual animation when reduced motion is requested, and '
        'lands directly on the settled end state',
        (WidgetTester tester) async {
          await tester.pumpWidget(await _wrap(disableAnimations: true));
          await tester.pump();

          expect(_wordmarkFadeTransition(tester).opacity.value, 0.0);
          expect(_circleProgress(tester), 0.0);
          expect(find.text("Today's Circle"), findsOneWidget);
          expect(find.text('Start Circle'), findsOneWidget);

          await tester.ensureVisible(find.text('Start Circle'));
          await tester.tap(find.text('Start Circle'));
          await tester.pump();

          expect(find.text('Close Circle'), findsOneWidget);
        },
      );

      testWidgets(
        'marks First Breath as played today even under reduced motion, on '
        'the first visit of the day',
        (WidgetTester tester) async {
          await tester.pumpWidget(await _wrap(disableAnimations: true));
          await tester.pump();

          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getString(firstBreathLastPlayedDateKey), '2026-08-02');
        },
      );
    });

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
          expect(find.text('Close Circle'), findsNothing);
          expect(find.text('Start Circle'), findsOneWidget);
        },
      );

      testWidgets('ignores taps while the button is only partially faded in', (
        WidgetTester tester,
      ) async {
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
        expect(find.text('Close Circle'), findsNothing);
      });

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
          expect(find.text('Close Circle'), findsOneWidget);
          expect(find.text('Start Circle'), findsNothing);

          // Same-Home: the CTA stays enabled after Start — it becomes the
          // user's way to Close Circle, not a terminal disabled state.
          final button = tester.widget<ThirtyButton>(find.byType(ThirtyButton));
          expect(button.onPressed, isNotNull);
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
          expect(find.text('Close Circle'), findsOneWidget);
        },
      );

      testWidgets('wraps the button in an IgnorePointer tied to its own reveal '
          'animation', (WidgetTester tester) async {
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
      });
    });

    group('Start Circle haptic', () {
      testWidgets(
        'fires exactly one lightImpact haptic on a valid Start Circle tap',
        (WidgetTester tester) async {
          final calls = _recordHapticCalls(tester);

          await tester.pumpWidget(await _wrap());
          await tester.pumpAndSettle();

          await tester.ensureVisible(find.byType(ThirtyButton));
          await tester.tap(find.byType(ThirtyButton));
          await tester.pump();

          expect(calls, ['HapticFeedbackType.lightImpact']);
        },
      );

      testWidgets(
        'does not fire a haptic when the now-enabled Close Circle CTA is '
        'tapped — Circle Closed reserves its own haptic for a later, '
        'separate pass',
        (WidgetTester tester) async {
          final calls = _recordHapticCalls(tester);
          final (widget, container) = await _wrapWithContainer();
          addTearDown(container.dispose);

          await tester.pumpWidget(widget);
          await tester.pumpAndSettle();

          await tester.ensureVisible(find.byType(ThirtyButton));
          await tester.tap(find.byType(ThirtyButton));
          await tester.pump();
          expect(calls, hasLength(1));
          expect(
            container.read(recommendationProvider).status,
            RecommendationStatus.started,
          );

          // Same-Home: the button is now the enabled "Close Circle" CTA,
          // not a disabled leftover — tapping it performs a real,
          // meaningful close() transition, which still must add no haptic.
          await tester.tap(find.byType(ThirtyButton));
          await tester.pump();

          expect(
            container.read(recommendationProvider).status,
            RecommendationStatus.closed,
          );
          expect(calls, hasLength(1));
        },
      );

      testWidgets(
        'does not fire a haptic for a tap blocked by First Breath gating, '
        'before the button has fully revealed',
        (WidgetTester tester) async {
          final calls = _recordHapticCalls(tester);

          await tester.pumpWidget(await _wrap());
          await tester.pump();

          // Same setup as the "ignores taps while hidden" interaction-gate
          // test above: the button is fully transparent/gated here.
          await tester.tap(find.byType(ThirtyButton), warnIfMissed: false);
          await tester.pump();

          expect(calls, isEmpty);
        },
      );
    });

    group('Same-Home Circle lifecycle (Premium Pass 02B Revised '
        'Experiment 1)', () {
      testWidgets(
        'closing preserves startedAt and records closedAt',
        (WidgetTester tester) async {
          final (widget, container) = await _wrapWithContainer();
          addTearDown(container.dispose);

          await tester.pumpWidget(widget);
          await tester.pumpAndSettle();

          await tester.ensureVisible(find.byType(ThirtyButton));
          await tester.tap(find.byType(ThirtyButton));
          await tester.pump();
          final startedAt = container.read(recommendationProvider).startedAt;
          expect(startedAt, isNotNull);
          expect(container.read(recommendationProvider).closedAt, isNull);

          await tester.tap(find.byType(ThirtyButton));
          await tester.pump();

          final state = container.read(recommendationProvider);
          expect(state.status, RecommendationStatus.closed);
          expect(state.startedAt, startedAt);
          expect(state.closedAt, isNotNull);
        },
      );

      testWidgets(
        'the closed CTA is disabled, and a further tap changes nothing',
        (WidgetTester tester) async {
          final (widget, container) = await _wrapWithContainer();
          addTearDown(container.dispose);

          await tester.pumpWidget(widget);
          await tester.pumpAndSettle();

          await tester.ensureVisible(find.byType(ThirtyButton));
          await tester.tap(find.byType(ThirtyButton)); // Start.
          await tester.pump();
          await tester.tap(find.byType(ThirtyButton)); // Close.
          await tester.pump();

          expect(find.text('Circle closed'), findsOneWidget);
          final button = tester.widget<ThirtyButton>(find.byType(ThirtyButton));
          expect(button.onPressed, isNull);

          final closedAt = container.read(recommendationProvider).closedAt;
          await tester.tap(find.byType(ThirtyButton), warnIfMissed: false);
          await tester.pump();

          final state = container.read(recommendationProvider);
          expect(state.status, RecommendationStatus.closed);
          expect(state.closedAt, closedAt);
          expect(find.text('Circle closed'), findsOneWidget);
        },
      );

      testWidgets('a same-day restored started state shows Close Circle', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          await _wrap(
            storedPrefs: {
              firstBreathLastPlayedDateKey: '2026-08-02',
              recommendationDayKey: '2026-08-02',
              recommendationStatusKey: 'started',
              recommendationStartedAtKey: _today.toIso8601String(),
            },
          ),
        );
        await tester.pump();

        expect(find.text('Close Circle'), findsOneWidget);
        expect(find.text('Start Circle'), findsNothing);
        final button = tester.widget<ThirtyButton>(find.byType(ThirtyButton));
        expect(button.onPressed, isNotNull);
      });

      testWidgets('a same-day restored closed state shows Circle closed', (
        WidgetTester tester,
      ) async {
        final closedAt = _today.add(const Duration(minutes: 30));
        await tester.pumpWidget(
          await _wrap(
            storedPrefs: {
              firstBreathLastPlayedDateKey: '2026-08-02',
              recommendationDayKey: '2026-08-02',
              recommendationStatusKey: 'closed',
              recommendationStartedAtKey: _today.toIso8601String(),
              recommendationClosedAtKey: closedAt.toIso8601String(),
            },
          ),
        );
        await tester.pump();

        expect(find.text('Circle closed'), findsOneWidget);
        final button = tester.widget<ThirtyButton>(find.byType(ThirtyButton));
        expect(button.onPressed, isNull);
      });
    });

    group(
      'Circle lifecycle semantics (Premium Pass 02B.1 / 02C Precheck)',
      () {
        testWidgets('notStarted announces "Ready to begin."', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(await _wrap());
          await tester.pumpAndSettle();

          final semantics = tester.getSemantics(
            find.byType(ThirtyProgressCircle),
          );
          expect(semantics.label, "Today's Circle");
          expect(semantics.value, 'Ready to begin.');
        });

        testWidgets('started announces "Circle in progress."', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            await _wrap(
              storedPrefs: {
                firstBreathLastPlayedDateKey: '2026-08-02',
                recommendationDayKey: '2026-08-02',
                recommendationStatusKey: 'started',
                recommendationStartedAtKey: _today.toIso8601String(),
              },
            ),
          );
          await tester.pump();

          final semantics = tester.getSemantics(
            find.byType(ThirtyProgressCircle),
          );
          expect(semantics.label, "Today's Circle");
          expect(semantics.value, 'Circle in progress.');
        });

        testWidgets('closed announces "Circle closed."', (
          WidgetTester tester,
        ) async {
          final closedAt = _today.add(const Duration(minutes: 30));
          await tester.pumpWidget(
            await _wrap(
              storedPrefs: {
                firstBreathLastPlayedDateKey: '2026-08-02',
                recommendationDayKey: '2026-08-02',
                recommendationStatusKey: 'closed',
                recommendationStartedAtKey: _today.toIso8601String(),
                recommendationClosedAtKey: closedAt.toIso8601String(),
              },
            ),
          );
          await tester.pump();

          final semantics = tester.getSemantics(
            find.byType(ThirtyProgressCircle),
          );
          expect(semantics.label, "Today's Circle");
          expect(semantics.value, 'Circle closed.');
        });

        testWidgets(
          'a same-day restored started->closed transition updates the '
          'existing semantics node rather than creating a new one',
          (WidgetTester tester) async {
            final (widget, container) = await _wrapWithContainer();
            addTearDown(container.dispose);

            await tester.pumpWidget(widget);
            await tester.pumpAndSettle();

            await tester.ensureVisible(find.byType(ThirtyButton));
            await tester.tap(find.byType(ThirtyButton)); // Start.
            await tester.pump();

            final startedSemantics = tester.getSemantics(
              find.byType(ThirtyProgressCircle),
            );
            expect(startedSemantics.value, 'Circle in progress.');
            final startedId = startedSemantics.id;

            await tester.tap(find.byType(ThirtyButton)); // Close.
            await tester.pump();

            final closedSemantics = tester.getSemantics(
              find.byType(ThirtyProgressCircle),
            );
            expect(closedSemantics.value, 'Circle closed.');
            expect(closedSemantics.id, startedId);
          },
        );
      },
    );
  });
}
