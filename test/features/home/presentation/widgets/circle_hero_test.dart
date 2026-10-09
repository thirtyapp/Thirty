import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/branding/thirty_wordmark_view.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_colors.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/core/widgets/thirty_progress_circle.dart';
import 'package:thirty/core/worlds/world_scene_role.dart';
import 'package:thirty/core/world_rendering/world_hero_art_view.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/world_scene_resolution.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';
import 'package:thirty/features/home/presentation/widgets/horizon_illustration.dart';
import 'package:thirty/features/home/presentation/widgets/today_card.dart';

final _today = DateTime(2026, 8, 2);

/// The event clock every test runs on (Phase D1 timer ring): 12 minutes
/// after [_today], so a Circle restored as started at [_today] has run 12
/// of its 30 minutes, and one started by a tap starts at exactly 0.
final _clockNow = _today.add(const Duration(minutes: 12));

/// The default activity's natural length — the ring's full extent in
/// these tests (V2 Phase A: the ring follows the activity, never a fixed
/// half hour).
final _walkMinutes = activityTypicalMinutes(ActivityId.thirtyMinuteWalk);

/// Phase D1: the heading beat is the time-of-day greeting ([_today] is
/// midnight, so "Good evening").
final _greeting = homeGreeting(_today);

/// Today's recommendation already chosen — the shape almost every test
/// below needs, since CircleHero itself assumes a non-null recommendation
/// (it's `HomePage`'s job, not CircleHero's, to gate on the Daily Context
/// Question — see `daily_intention_prompt_test.dart` and
/// `home_page_test.dart`). Merged underneath each test's own `storedPrefs`
/// in [_wrap]/[_wrapWithContainer] below, so a test that supplies its own
/// `recommendationStatusKey`/timestamps for the same day still gets a
/// valid recommendation to restore them onto.
const _defaultChosenPrefs = <String, Object>{
  recommendationDayKey: '2026-08-02',
  recommendationIntentionKey: 'moreEnergy',
  recommendationActivityIdKey: 'thirtyMinuteWalk',
};

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
  SharedPreferences.setMockInitialValues({
    ..._defaultChosenPrefs,
    ...storedPrefs,
  });
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
      eventClockProvider.overrideWithValue(() => _clockNow),
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
  SharedPreferences.setMockInitialValues({
    ..._defaultChosenPrefs,
    ...storedPrefs,
  });
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_today),
      eventClockProvider.overrideWithValue(() => _clockNow),
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

/// The [FadeTransition] revealing the World illustration — the nearest one
/// above the illustration's crossfade [AnimatedSwitcher], whose own
/// per-child fades sit below it.
FadeTransition _illustrationFadeTransition(WidgetTester tester) {
  return tester.widget<FadeTransition>(
    find
        .ancestor(
          of: find.ancestor(
            of: find.byType(WorldHeroArtView),
            matching: find.byType(AnimatedSwitcher),
          ),
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

/// Taps the Close Circle button, then confirms the Batch 1 confirmation
/// dialog it now opens ("Close today's Circle?" / "You won't be able to
/// reopen it until tomorrow.") — the drop-in replacement for what used to
/// be a single direct-close tap, everywhere a test needs the Circle to
/// actually end up closed. Uses discrete `pump()` calls to step through
/// the dialog's own transitions explicitly.
///
/// `find.text('Close Circle')` alone would be ambiguous once the dialog is
/// open — the underlying (now-obscured) Close Circle button still carries
/// that exact label too — so this scopes the second tap to inside the
/// [AlertDialog].
Future<void> _tapAndConfirmClose(WidgetTester tester) async {
  await tester.tap(find.byType(ThirtyButton));
  await tester.pump();
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Close Circle'),
    ),
  );
  await tester.pump();
  // Lets the dialog's own exit transition finish, so it's fully gone from
  // the tree afterward rather than lingering mid-animation.
  await tester.pump(const Duration(milliseconds: 200));
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
      expect(find.text(_greeting), findsOneWidget);
      expect(find.text('More Energy'), findsOneWidget);
      expect(find.text('A brisk walk'), findsOneWidget);
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

    testWidgets('the destructive action in the Close Circle confirmation uses '
        'the AA errorText role, not the brand error fill color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(await _wrap());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start Circle'));
      await tester.tap(find.text('Start Circle'));
      await tester.pump();

      await tester.tap(find.byType(ThirtyButton));
      await tester.pump();

      final closeAction = tester.widget<TextButton>(
        find.ancestor(
          of: find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Close Circle'),
          ),
          matching: find.byType(TextButton),
        ),
      );
      expect(
        closeAction.style!.foregroundColor!.resolve({}),
        AppColors.light.errorText,
      );
    });

    testWidgets('centers the Circle, illustration, greeting and Today card '
        'on the same horizontal axis as the screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(await _wrap());
      await tester.pumpAndSettle();

      final screenCenterX = tester.getSize(find.byType(MaterialApp)).width / 2;
      final circleCenterX = tester
          .getCenter(find.byType(ThirtyProgressCircle))
          .dx;
      final illustrationCenterX = tester
          .getCenter(find.byType(WorldHeroArtView))
          .dx;
      final headingCenterX = tester.getCenter(find.text(_greeting)).dx;
      final cardCenterX = tester.getCenter(find.byType(TodayCard)).dx;

      expect(circleCenterX, closeTo(screenCenterX, 0.5));
      expect(illustrationCenterX, closeTo(screenCenterX, 0.5));
      expect(headingCenterX, closeTo(screenCenterX, 0.5));
      expect(cardCenterX, closeTo(screenCenterX, 0.5));
    });

    testWidgets(
      'renders the resolved World Hero — Quiet Trail for a walk — inset '
      'inside the ring',
      (WidgetTester tester) async {
        await tester.pumpWidget(await _wrap());
        await tester.pumpAndSettle();

        expect(find.byType(WorldHeroArtView), findsOneWidget);
        expect(
          _heroAsset(tester),
          'assets/worlds/quiet_trail/walk/hero_evening.webp',
        );
        expect(find.byType(HorizonIllustration), findsNothing);

        final illustrationSize = tester.getSize(find.byType(WorldHeroArtView));
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
        expect(find.text(_greeting), findsOneWidget);
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
                      of: find.text(_greeting),
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
                      of: find.text('A brisk walk'),
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
                      of: find.text('A brisk walk'),
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
          expect(find.text(_greeting), findsOneWidget);
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
          expect(find.text(_greeting), findsOneWidget);
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
          // not a disabled leftover — confirming it performs a real,
          // meaningful close() transition, which still must add no haptic.
          await _tapAndConfirmClose(tester);

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
      testWidgets('closing preserves startedAt and records closedAt', (
        WidgetTester tester,
      ) async {
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

        await _tapAndConfirmClose(tester);

        final state = container.read(recommendationProvider);
        expect(state.status, RecommendationStatus.closed);
        expect(state.startedAt, startedAt);
        expect(state.closedAt, isNotNull);
      });

      testWidgets(
        'once closed there is no CTA at all — only the explanatory closed '
        'message, and no ThirtyButton survives to accidentally reopen it',
        (WidgetTester tester) async {
          final (widget, container) = await _wrapWithContainer();
          addTearDown(container.dispose);

          await tester.pumpWidget(widget);
          await tester.pumpAndSettle();

          await tester.ensureVisible(find.byType(ThirtyButton));
          await tester.tap(find.byType(ThirtyButton)); // Start.
          await tester.pump();
          await _tapAndConfirmClose(tester); // Close.

          expect(find.text('Done for today'), findsOneWidget);
          expect(find.text('Your next Circle opens tomorrow.'), findsOneWidget);
          expect(find.byType(ThirtyButton), findsNothing);
          expect(find.text('Circle closed'), findsNothing);

          final state = container.read(recommendationProvider);
          expect(state.status, RecommendationStatus.closed);
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

      testWidgets(
        'a same-day restored closed state shows the explanatory closed '
        'message, with no CTA',
        (WidgetTester tester) async {
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

          expect(find.text('Done for today'), findsOneWidget);
          expect(find.text('Your next Circle opens tomorrow.'), findsOneWidget);
          expect(find.byType(ThirtyButton), findsNothing);
          expect(find.text('Circle closed'), findsNothing);
        },
      );
    });

    group('Circle lifecycle semantics (Premium Pass 02B.1 / 02C Precheck)', () {
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

      testWidgets('started announces "Circle in progress." with the '
          'minutes run', (WidgetTester tester) async {
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
        expect(
          semantics.value,
          'Circle in progress. 12 of $_walkMinutes minutes.',
        );
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

      testWidgets('a same-day restored started->closed transition updates the '
          'existing semantics node rather than creating a new one', (
        WidgetTester tester,
      ) async {
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
        expect(
          startedSemantics.value,
          'Circle in progress. 0 of $_walkMinutes minutes.',
        );
        final startedId = startedSemantics.id;

        await _tapAndConfirmClose(tester); // Close.

        final closedSemantics = tester.getSemantics(
          find.byType(ThirtyProgressCircle),
        );
        expect(closedSemantics.value, 'Circle closed.');
        expect(closedSemantics.id, startedId);
      });
    });

    group('Phase D1 ring — soft track, sage dot, activity-length timer', () {
      ThirtyProgressCircle circleWidget(WidgetTester tester) => tester
          .widget<ThirtyProgressCircle>(find.byType(ThirtyProgressCircle));

      Map<String, Object> restored(String status, {Duration? ranFor}) => {
        firstBreathLastPlayedDateKey: '2026-08-02',
        recommendationStatusKey: status,
        recommendationStartedAtKey: _today.toIso8601String(),
        if (ranFor != null)
          recommendationClosedAtKey: _today.add(ranFor).toIso8601String(),
      };

      testWidgets('every assigned state paints the soft track, a sage arc '
          'and the sage dot', (tester) async {
        for (final prefs in [
          const <String, Object>{firstBreathLastPlayedDateKey: '2026-08-02'},
          restored('started'),
          restored('closed', ranFor: const Duration(minutes: 20)),
        ]) {
          await tester.pumpWidget(await _wrap(storedPrefs: prefs));
          await tester.pump();
          final circle = circleWidget(tester);
          expect(circle.trackColor, AppColors.light.ringTrack);
          expect(circle.progressColor, AppColors.light.primary);
          expect(circle.thumbDiameter, 14);
        }
      });

      testWidgets('not started: empty arc, dot at the top', (tester) async {
        await tester.pumpWidget(
          await _wrap(
            storedPrefs: {firstBreathLastPlayedDateKey: '2026-08-02'},
          ),
        );
        await tester.pump();
        expect(circleWidget(tester).progress, 0);
      });

      testWidgets('First Breath still opens the Circle from closed to empty', (
        tester,
      ) async {
        await tester.pumpWidget(await _wrap());
        await tester.pump();
        expect(circleWidget(tester).progress, 1);
        await tester.pump(const Duration(milliseconds: _breatheEndMs));
        expect(circleWidget(tester).progress, 0);
        await tester.pumpAndSettle();
      });

      testWidgets('started: the arc is the time since Start Circle out of '
          'the activity\'s own length, never a fixed 30 minutes', (
        tester,
      ) async {
        expect(_walkMinutes, isNot(30));
        await tester.pumpWidget(await _wrap(storedPrefs: restored('started')));
        await tester.pump();
        expect(circleWidget(tester).progress, closeTo(12 / _walkMinutes, 1e-9));
      });

      testWidgets('representative ~10 and ~20 minute activities each run the '
          'ring to their own length', (tester) async {
        for (final (intention, activity) in [
          (Intention.moreEnergy, ActivityId.moveToMusic),
          (Intention.clearerHead, ActivityId.quietReading),
        ]) {
          final minutes = activityTypicalMinutes(activity);
          await tester.pumpWidget(
            await _wrap(
              storedPrefs: {
                ...restored('started'),
                recommendationIntentionKey: intention.name,
                recommendationActivityIdKey: activity.name,
              },
            ),
          );
          await tester.pump();
          expect(
            circleWidget(tester).progress,
            closeTo((12 / minutes).clamp(0.0, 1.0), 1e-9),
            reason: activity.name,
          );
          expect(
            tester.getSemantics(find.byType(ThirtyProgressCircle)).value,
            'Circle in progress. ${12.clamp(0, minutes)} of $minutes '
            'minutes.',
            reason: activity.name,
          );
        }
        expect(activityTypicalMinutes(ActivityId.moveToMusic), 10);
        expect(activityTypicalMinutes(ActivityId.quietReading), 20);
      });

      testWidgets('started: the arc advances as time passes and is full '
          'from the activity\'s length on', (tester) async {
        var now = _today.add(const Duration(minutes: 12));
        SharedPreferences.setMockInitialValues({
          ..._defaultChosenPrefs,
          ...restored('started'),
        });
        final prefs = await SharedPreferences.getInstance();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              nowProvider.overrideWithValue(_today),
              eventClockProvider.overrideWithValue(() => now),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(body: CircleHero()),
            ),
          ),
        );
        await tester.pump();
        expect(circleWidget(tester).progress, closeTo(12 / _walkMinutes, 1e-9));

        now = _today.add(const Duration(minutes: 15));
        await tester.pump(const Duration(seconds: 1));
        expect(circleWidget(tester).progress, closeTo(15 / _walkMinutes, 1e-9));
        expect(
          tester.getSemantics(find.byType(ThirtyProgressCircle)).value,
          'Circle in progress. 15 of $_walkMinutes minutes.',
        );

        now = _today.add(const Duration(minutes: 45));
        await tester.pump(const Duration(seconds: 1));
        expect(circleWidget(tester).progress, 1);
        expect(
          tester.getSemantics(find.byType(ThirtyProgressCircle)).value,
          'Circle in progress. $_walkMinutes of $_walkMinutes minutes.',
        );
      });

      testWidgets('closed: the arc keeps the time the Circle actually ran', (
        tester,
      ) async {
        await tester.pumpWidget(
          await _wrap(
            storedPrefs: restored(
              'closed',
              ranFor: const Duration(minutes: 20),
            ),
          ),
        );
        await tester.pump();
        expect(circleWidget(tester).progress, closeTo(20 / _walkMinutes, 1e-9));
      });

      testWidgets('Start Circle starts the timer at 0; its ticker never '
          'blocks pumpAndSettle', (tester) async {
        await tester.pumpWidget(
          await _wrap(
            storedPrefs: {firstBreathLastPlayedDateKey: '2026-08-02'},
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(ThirtyButton));
        await tester.tap(find.byType(ThirtyButton));
        await tester.pumpAndSettle();
        expect(circleWidget(tester).progress, 0);
        expect(find.text('Close Circle'), findsOneWidget);
      });
    });

    group('Batch 1 — Close Circle confirmation (Phase B)', () {
      testWidgets('tapping Close Circle shows the confirmation dialog before '
          'changing any state', (WidgetTester tester) async {
        final (widget, container) = await _wrapWithContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(ThirtyButton));
        await tester.tap(find.byType(ThirtyButton)); // Start.
        await tester.pump();

        await tester.tap(find.byType(ThirtyButton)); // Opens confirmation.
        await tester.pump();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text("Close today's Circle?"), findsOneWidget);
        expect(
          find.text("You won't be able to reopen it until tomorrow."),
          findsOneWidget,
        );
        expect(find.text('Keep Circle open'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Close Circle'),
          ),
          findsOneWidget,
        );
        // Opening the dialog alone must not have touched canonical state.
        final state = container.read(recommendationProvider);
        expect(state.status, RecommendationStatus.started);
        expect(state.closedAt, isNull);
      });

      testWidgets(
        '"Keep Circle open" leaves the active Circle completely unchanged',
        (WidgetTester tester) async {
          final (widget, container) = await _wrapWithContainer();
          addTearDown(container.dispose);

          await tester.pumpWidget(widget);
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byType(ThirtyButton));
          await tester.tap(find.byType(ThirtyButton)); // Start.
          await tester.pump();
          final startedAt = container.read(recommendationProvider).startedAt;

          await tester.tap(find.byType(ThirtyButton)); // Opens confirmation.
          await tester.pump();
          await tester.tap(find.text('Keep Circle open'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));

          expect(find.byType(AlertDialog), findsNothing);
          final state = container.read(recommendationProvider);
          expect(state.status, RecommendationStatus.started);
          expect(state.startedAt, startedAt);
          expect(state.closedAt, isNull);
          expect(find.text('Close Circle'), findsOneWidget);
        },
      );

      testWidgets(
        'dismissing the dialog by tapping outside it resolves the same as '
        'an explicit cancel — the Circle stays open. showDialog resolves a '
        'dismiss (tap-outside or the system back button) the same way: '
        'anything other than an explicit confirm leaves the Circle '
        'untouched, so this also stands in for the back-button case.',
        (WidgetTester tester) async {
          final (widget, container) = await _wrapWithContainer();
          addTearDown(container.dispose);

          await tester.pumpWidget(widget);
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byType(ThirtyButton));
          await tester.tap(find.byType(ThirtyButton)); // Start.
          await tester.pump();

          await tester.tap(find.byType(ThirtyButton)); // Opens confirmation.
          await tester.pump();

          // The dialog's own barrier, well away from its centered content.
          await tester.tapAt(const Offset(5, 5));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));

          expect(find.byType(AlertDialog), findsNothing);
          expect(
            container.read(recommendationProvider).status,
            RecommendationStatus.started,
          );
        },
      );
    });
  });

  group('World art snapshot', () {
    Future<(Widget, ProviderContainer)> wrapAt(
      DateTime Function() now, {
      ActivityId activity = ActivityId.thirtyMinuteWalk,
      bool firstBreathPlayed = true,
    }) async {
      final intention = Intention.values.firstWhere(
        (i) => activityPools[i]!.contains(activity),
      );
      SharedPreferences.setMockInitialValues({
        recommendationDayKey: '2026-08-02',
        recommendationIntentionKey: intention.name,
        recommendationActivityIdKey: activity.name,
        if (firstBreathPlayed) firstBreathLastPlayedDateKey: '2026-08-02',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          nowProvider.overrideWith((ref) => now()),
          eventClockProvider.overrideWithValue(now),
        ],
      );
      addTearDown(container.dispose);
      return (
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: CircleHero()),
          ),
        ),
        container,
      );
    }

    final afternoon = DateTime(2026, 8, 2, 17, 59);
    final evening = DateTime(2026, 8, 2, 18);

    for (final role in WorldSceneRole.values) {
      final activity = ActivityId.values.firstWhere(
        (a) => activityWorldRole(a) == role,
      );
      testWidgets('${role.name}: ${activity.name} shows the Hero and Card of '
          'one resolved snapshot', (WidgetTester tester) async {
        final (widget, _) = await wrapAt(() => afternoon, activity: activity);
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final expected = resolveWorldArt(activity, afternoon);
        expect(_heroAsset(tester), expected.heroAsset);
        expect(_cardAsset(tester), expected.cardAsset);
        expect(
          expected.heroAsset,
          startsWith(
            'assets/worlds/${expected.scene.sceneId.world}/'
            '${expected.scene.sceneId.name}/',
          ),
        );
        expect(expected.heroAsset, endsWith('/hero_day.webp'));
        expect(expected.cardAsset, endsWith('/card_day.webp'));
      });
    }

    testWidgets('holds its Daypart through First Breath, then settles on the '
        're-resolved one', (WidgetTester tester) async {
      var now = afternoon;
      final (widget, container) = await wrapAt(
        () => now,
        firstBreathPlayed: false,
      );
      await tester.pumpWidget(widget);
      await tester.pump(const Duration(milliseconds: _breatheEndMs));

      // A resume across 18:00, mid-ritual.
      now = evening;
      container.invalidate(nowProvider);
      await tester.pump(const Duration(milliseconds: 500));

      expect(_heroAsset(tester), endsWith('walk/hero_day.webp'));
      expect(_cardAsset(tester), endsWith('walk/card_day.webp'));

      await tester.pumpAndSettle();

      expect(_heroAsset(tester), endsWith('walk/hero_evening.webp'));
      expect(_cardAsset(tester), endsWith('walk/card_evening.webp'));
    });

    testWidgets('a re-resolution once settled switches Hero and Card '
        'together', (WidgetTester tester) async {
      var now = afternoon;
      final (widget, container) = await wrapAt(() => now);
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      expect(_heroAsset(tester), endsWith('walk/hero_day.webp'));

      now = evening;
      container.invalidate(nowProvider);
      await tester.pumpAndSettle();

      expect(_heroAsset(tester), endsWith('walk/hero_evening.webp'));
      expect(_cardAsset(tester), endsWith('walk/card_evening.webp'));
    });

    testWidgets('World art never reaches the semantics tree', (
      WidgetTester tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final (widget, _) = await wrapAt(
        () => afternoon,
        activity: ActivityId.smallComfortRitual,
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'assets/|\.webp')), findsNothing);
      semantics.dispose();
    });
  });
}

/// The single asset the Circle's Hero shows (the settled child of its
/// crossfade).
String _heroAsset(WidgetTester tester) => _assetOf(
  tester,
  find.descendant(
    of: find.byType(WorldHeroArtView),
    matching: find.byType(Image),
  ),
);

/// The single asset the Today card shows.
String _cardAsset(WidgetTester tester) => _assetOf(
  tester,
  find.descendant(of: find.byType(TodayCard), matching: find.byType(Image)),
);

String _assetOf(WidgetTester tester, Finder images) {
  final assets = tester
      .widgetList<Image>(images)
      .map((image) => (image.image as AssetImage).assetName)
      .toSet();
  expect(assets, hasLength(1));
  return assets.single;
}
