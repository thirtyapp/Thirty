import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/core/routing/app_shell.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/widgets/home_circle_metrics.dart';
import 'package:thirty/features/home/presentation/widgets/home_rhythm_column.dart';
import 'package:thirty/features/home/presentation/widgets/today_card.dart';
import 'package:thirty/features/plans/domain/plan_catalog.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/plans/presentation/widgets/plan_session_panel.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';

/// Start Circle vs the floating bottom navigation, on the real app shell
/// with the real fonts.
///
/// Home is one scroll document ending at the nav's top edge. When the usual
/// rhythm would leave Start Circle just below the first screen (a two-line
/// Today card on Pixel 7), the hero's gaps tighten so it sits fully on it;
/// larger overflow (small phones, large text) keeps the usual rhythm and
/// scrolls. In every case Start Circle is reachable, fully clear of the
/// nav, before any secondary content.

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(file).readAsBytesSync())),
    );
  }
  await loader.load();
}

const _pixel7 = Size(1080, 2400);
const _smallPhone = Size(945, 1942.5); // 360×740 at 2.625

/// Galaxy S25 at its default display size (411 × 891 dp at 2.625), with its
/// real system insets: a 39dp status bar, and Android 3-button navigation
/// (48dp) or gesture navigation.
const _s25 = Size(1080, 2340);
const _s25StatusBar = 103.0;
const _s25ButtonNavigation = 126.0;
const _s25GestureNavigation = 63.0;

/// Every activity a release build can offer, with a need it is offered for.
final _liveActivities = {
  for (final need in Intention.values)
    for (final id in legacySelectorPool(need, allowSafetyPending: false))
      id: need,
};

Map<String, Object> _assigned(String intention, String activity) => {
  recommendationDayKey: '2026-09-30',
  recommendationIntentionKey: intention,
  recommendationActivityIdKey: activity,
  firstBreathLastPlayedDateKey: '2026-09-30',
};

Future<void> _pumpHome(
  WidgetTester tester, {
  required Map<String, Object> prefs,
  int hour = 8,
  Size screen = _pixel7,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  double topInset = 118,
  double bottomInset = 63,
  bool settle = true,
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 2.625;
  tester.view.padding = FakeViewPadding(top: topInset, bottom: bottomInset);
  tester.view.viewPadding = FakeViewPadding(top: topInset, bottom: bottomInset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  SharedPreferences.setMockInitialValues({
    ...prefs,
    firstNamePromptSeenKey: true,
  });
  final resolved = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(resolved),
        nowProvider.overrideWithValue(DateTime(2026, 9, 30, hour)),
      ],
      child: const ThirtyApp(),
    ),
  );
  appRouter.go('/');
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  addTearDown(() => appRouter.go('/'));
}

Finder get _cta => find.widgetWithText(ThirtyButton, 'Start Circle');

Finder get _homeScrollable =>
    find.ancestor(of: _cta, matching: find.byType(Scrollable)).first;

RenderHomeRhythmColumn _column(WidgetTester tester) =>
    tester.renderObject<RenderHomeRhythmColumn>(find.byType(HomeRhythmColumn));

bool _isCompact(WidgetTester tester) => _column(tester).isCompact;

/// The Circle's laid-out diameter, and its full size at this screen width.
double _circle(WidgetTester tester) =>
    tester.getRect(find.byType(HomeCircle)).width;
double _fullCircle(WidgetTester tester) => HomeCircleMetrics.forWidth(
  tester.view.physicalSize.width / tester.view.devicePixelRatio,
).circleSize;

/// The gap between the Today card and Start Circle as laid out.
double _cardToCta(WidgetTester tester) =>
    tester.getRect(_cta).top - tester.getRect(find.byType(TodayCard)).bottom;

/// Whether Start Circle is fully on the first screen, at least
/// [HomeCircleMetrics.compactGap] above the fold.
bool _ctaOnFirstScreen(WidgetTester tester) => _onFirstScreen(tester, _cta);

Finder get _closeCta => find.widgetWithText(ThirtyButton, 'Close Circle');

/// Whether [action] is fully on the first screen — unscrolled, at least
/// [clearance] above the fold.
bool _onFirstScreen(
  WidgetTester tester,
  Finder action, {
  double clearance = HomeCircleMetrics.compactGap,
}) {
  final viewport = find
      .ancestor(of: action, matching: find.byType(Scrollable))
      .first;
  return tester.state<ScrollableState>(viewport).position.pixels == 0 &&
      tester.getRect(action).bottom + clearance <=
          tester.getRect(viewport).bottom + 0.5;
}

/// A running Circle's Close Circle: fully on the first screen, at least
/// [HomeCircleMetrics.runningLeastClearance] above the fold — and the usual
/// [HomeCircleMetrics.compactGap] for every one-line activity.
void _expectCloseOnFirstScreen(
  WidgetTester tester,
  ActivityId activity,
  String reason,
) {
  expect(
    _onFirstScreen(
      tester,
      _closeCta,
      clearance: HomeCircleMetrics.runningLeastClearance,
    ),
    isTrue,
    reason: reason,
  );
  final oneLine =
      tester.getSize(find.text(activityLabel(activity))).height <= 30;
  if (oneLine) {
    expect(_onFirstScreen(tester, _closeCta), isTrue, reason: reason);
  }
  // The Today card's padding never crowds its content.
  final card = tester.getRect(find.byType(TodayCard));
  final label = tester.getRect(find.textContaining('TODAY'));
  expect(label.top - card.top, greaterThanOrEqualTo(6 - 0.01), reason: reason);
}

/// Taps Close Circle and confirms.
Future<void> _closeCircle(WidgetTester tester) async {
  await tester.tap(_closeCta);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Close Circle').last);
  await tester.pumpAndSettle();
}

/// Home never reaches behind the nav; scrolled to its end, Start Circle is
/// fully visible with the composition's bottom spacing above the nav, and
/// tapping it starts the Circle.
Future<void> _expectCtaReachableClearOfNav(WidgetTester tester) async {
  Rect nav() => tester.getRect(find.byType(FloatingNavSurface));
  final viewport = tester.getRect(_homeScrollable);
  expect(viewport.bottom, lessThanOrEqualTo(nav().top + 0.5));

  final position = tester.state<ScrollableState>(_homeScrollable).position;
  position.jumpTo(position.maxScrollExtent);
  await tester.pumpAndSettle();

  final cta = tester.getRect(_cta);
  expect(cta.top, greaterThanOrEqualTo(viewport.top));
  expect(cta.bottom, lessThanOrEqualTo(viewport.bottom));
  expect(nav().top - cta.bottom, greaterThanOrEqualTo(AppSpacing.xl - 0.5));

  await tester.tap(_cta);
  await tester.pumpAndSettle();
  expect(find.widgetWithText(ThirtyButton, 'Close Circle'), findsOneWidget);
}

void main() {
  setUpAll(() async {
    await _loadFont('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ]);
    await _loadFont('Newsreader', ['assets/fonts/Newsreader[opsz,wght].ttf']);
  });

  group('Home near-fit rhythm and Start Circle vs the nav', () {
    testWidgets('Pixel 7, Garden Window tend (two-line activity): near fit, '
        'so the compact rhythm puts Start Circle fully on the first '
        'screen', (tester) async {
      await _pumpHome(
        tester,
        prefs: _assigned('moreEnergy', 'activeHouseholdTask'),
      );
      expect(find.text('One active household task'), findsOneWidget);

      expect(_isCompact(tester), isTrue);
      // The compact gaps alone: the Today card and the Circle are untouched.
      expect(_column(tester).fit, HomeRhythmFit.compactGaps);
      expect(_circle(tester), closeTo(_fullCircle(tester), 0.01));
      expect(_cardToCta(tester), closeTo(HomeCircleMetrics.compactGap, 0.5));
      expect(tester.state<ScrollableState>(_homeScrollable).position.pixels, 0);
      expect(_ctaOnFirstScreen(tester), isTrue);
      await _expectCtaReachableClearOfNav(tester);
    });

    testWidgets('Pixel 7, Quiet Trail day: already fits, usual rhythm '
        'unchanged', (tester) async {
      await _pumpHome(
        tester,
        prefs: _assigned('moreEnergy', 'thirtyMinuteWalk'),
        hour: 14,
      );
      expect(_isCompact(tester), isFalse);
      expect(_circle(tester), closeTo(_fullCircle(tester), 0.01));
      expect(_cardToCta(tester), closeTo(HomeCircleMetrics.cardToCtaGap, 0.5));
      expect(_ctaOnFirstScreen(tester), isTrue);
      await _expectCtaReachableClearOfNav(tester);
    });

    testWidgets('Pixel 7, Reading Nook evening, dark: Start Circle on the '
        'first screen', (tester) async {
      await _pumpHome(
        tester,
        prefs: _assigned('clearerHead', 'quietReading'),
        hour: 21,
        brightness: Brightness.dark,
      );
      expect(_ctaOnFirstScreen(tester), isTrue);
      await _expectCtaReachableClearOfNav(tester);
    });

    testWidgets('Plan day: Start Circle still comes after the Today card and '
        'before the Plan session panel', (tester) async {
      final stage = planDefinitionFor(PlanId.moreEnergyPath).stages.first;
      await _pumpHome(
        tester,
        prefs: {
          ..._assigned('moreEnergy', stage.activityId.name),
          recommendationPlanIdKey: PlanId.moreEnergyPath.name,
          recommendationStageIdKey: stage.id,
          recommendationPlanCycleIdKey: 'moreEnergyPath_cycle_1',
          recommendationPlanVersionKey: planContentVersion,
          recommendationIsPlanRevisitKey: false,
          recommendationTreatmentKey: 'standard',
        },
      );
      final panel = find.byType(PlanSessionPanel);
      expect(panel, findsOneWidget);
      expect(
        tester.getRect(panel).top,
        greaterThan(tester.getRect(_cta).bottom),
      );
      expect(
        tester.getRect(_cta).top,
        greaterThan(tester.getRect(find.byType(TodayCard)).bottom),
      );
      await _expectCtaReachableClearOfNav(tester);
    });

    testWidgets('small phone (360×740), tend: large overflow keeps the usual '
        'rhythm and scrolls naturally', (tester) async {
      await _pumpHome(
        tester,
        prefs: _assigned('moreEnergy', 'activeHouseholdTask'),
        screen: _smallPhone,
      );
      expect(_isCompact(tester), isFalse);
      // Beyond the 4% cap: nothing is trimmed; the page scrolls.
      expect(_circle(tester), closeTo(_fullCircle(tester), 0.01));
      expect(_cardToCta(tester), closeTo(HomeCircleMetrics.cardToCtaGap, 0.5));
      expect(_ctaOnFirstScreen(tester), isFalse);
      await _expectCtaReachableClearOfNav(tester);
    });

    testWidgets('200% text, tend: usual rhythm, scrolls, no overflow', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        prefs: _assigned('moreEnergy', 'activeHouseholdTask'),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(_isCompact(tester), isFalse);
      await _expectCtaReachableClearOfNav(tester);
    });
  });
  group('Galaxy S25 (founder decision, V2 Phase A): Start Circle fully on '
      'the first screen', () {
    Future<void> pumpS25(
      WidgetTester tester,
      ActivityId activity, {
      double bottomInset = _s25ButtonNavigation,
      double textScale = 1,
      Brightness brightness = Brightness.light,
      bool firstBreath = false,
    }) async {
      final prefs = _assigned(_liveActivities[activity]!.name, activity.name);
      if (firstBreath) prefs.remove(firstBreathLastPlayedDateKey);
      await _pumpHome(
        tester,
        prefs: prefs,
        screen: _s25,
        topInset: _s25StatusBar,
        bottomInset: bottomInset,
        textScale: textScale,
        brightness: brightness,
        settle: !firstBreath,
      );
    }

    testWidgets('3-button navigation: every live activity, without '
        'scrolling — the full Circle for one-line activities, at most a 4% '
        'trim only for two-line ones', (tester) async {
      for (final activity in _liveActivities.keys) {
        await pumpS25(tester, activity);
        final reason = activity.name;
        final column = _column(tester);

        expect(_ctaOnFirstScreen(tester), isTrue, reason: reason);
        expect(
          tester.state<ScrollableState>(_homeScrollable).position.pixels,
          0,
          reason: reason,
        );
        final twoLine =
            tester.getSize(find.text(activityLabel(activity))).height > 30;
        if (twoLine) {
          expect(column.fit, HomeRhythmFit.trimmed, reason: reason);
          expect(
            _circle(tester),
            greaterThanOrEqualTo(
              _fullCircle(tester) * (1 - HomeCircleMetrics.nearFitMaxTrim),
            ),
            reason: reason,
          );
        } else {
          expect(column.fit, HomeRhythmFit.compactChildren, reason: reason);
          expect(
            _circle(tester),
            closeTo(_fullCircle(tester), 0.01),
            reason: reason,
          );
        }
      }
      await _expectCtaReachableClearOfNav(tester);
    });

    testWidgets('gesture navigation: every live activity fits with the full '
        'Circle', (tester) async {
      for (final activity in _liveActivities.keys) {
        await pumpS25(tester, activity, bottomInset: _s25GestureNavigation);
        expect(_ctaOnFirstScreen(tester), isTrue, reason: activity.name);
        expect(_column(tester).trimmed, 0, reason: activity.name);
        expect(
          _circle(tester),
          closeTo(_fullCircle(tester), 0.01),
          reason: activity.name,
        );
      }
    });

    testWidgets('dark, 3-button navigation, A quick standing stretch: the '
        'same fit', (tester) async {
      await pumpS25(
        tester,
        ActivityId.energisingStretchFlow,
        brightness: Brightness.dark,
      );
      expect(_ctaOnFirstScreen(tester), isTrue);
      expect(_column(tester).fit, HomeRhythmFit.trimmed);
      await _expectCtaReachableClearOfNav(tester);
    });

    testWidgets('130% text: the full Circle is kept and the page scrolls to '
        'Start Circle, clear of the nav', (tester) async {
      for (final activity in [
        ActivityId.thirtyMinuteWalk,
        ActivityId.energisingStretchFlow,
      ]) {
        await pumpS25(tester, activity, textScale: 1.3);
        expect(tester.takeException(), isNull, reason: activity.name);
        expect(_column(tester).trimmed, 0, reason: activity.name);
        expect(
          _circle(tester),
          closeTo(_fullCircle(tester), 0.01),
          reason: activity.name,
        );
      }
      await _expectCtaReachableClearOfNav(tester);
    });

    testWidgets('3-button navigation, a whole session for every live '
        'activity: Start Circle and then Close Circle fully on the first '
        'screen, and the Circle exactly the same size before Start, running '
        'and closed', (tester) async {
      for (final activity in _liveActivities.keys) {
        final reason = activity.name;
        await pumpS25(tester, activity);
        final circle = _circle(tester);
        expect(_ctaOnFirstScreen(tester), isTrue, reason: reason);

        await tester.tap(_cta);
        await tester.pumpAndSettle();
        _expectCloseOnFirstScreen(tester, activity, reason);
        expect(_circle(tester), closeTo(circle, 0.01), reason: reason);

        await _closeCircle(tester);
        expect(find.text('Done for today'), findsOneWidget, reason: reason);
        expect(_circle(tester), closeTo(circle, 0.01), reason: reason);
      }
    });

    testWidgets('gesture navigation, a whole session for every live '
        'activity: both actions fully on the first screen, with the full '
        'Circle throughout', (tester) async {
      for (final activity in _liveActivities.keys) {
        final reason = activity.name;
        await pumpS25(tester, activity, bottomInset: _s25GestureNavigation);
        expect(_ctaOnFirstScreen(tester), isTrue, reason: reason);

        await tester.tap(_cta);
        await tester.pumpAndSettle();
        _expectCloseOnFirstScreen(tester, activity, reason);
        expect(_circle(tester), closeTo(_fullCircle(tester), 0.01));

        await _closeCircle(tester);
        expect(_circle(tester), closeTo(_fullCircle(tester), 0.01));
      }
    });

    testWidgets('reopened while running (a fresh launch, nothing on screen '
        'to jump from): Close Circle fully on the first screen for every '
        'live activity — the full Circle for one-line activities, at most a '
        '4% trim otherwise', (tester) async {
      for (final inset in [_s25ButtonNavigation, _s25GestureNavigation]) {
        for (final activity in _liveActivities.keys) {
          final reason = '${activity.name}, inset $inset';
          // A fresh widget tree, as after the app process was restarted.
          await tester.pumpWidget(const SizedBox());
          await _pumpHome(
            tester,
            prefs: {
              ..._assigned(_liveActivities[activity]!.name, activity.name),
              recommendationStatusKey: 'started',
              recommendationStartedAtKey: DateTime(
                2026,
                9,
                30,
                7,
              ).toIso8601String(),
            },
            screen: _s25,
            topInset: _s25StatusBar,
            bottomInset: inset,
          );
          _expectCloseOnFirstScreen(tester, activity, reason);
          // A fresh launch may trim, so it keeps the full clearance.
          expect(_onFirstScreen(tester, _closeCta), isTrue, reason: reason);
          expect(
            _circle(tester),
            greaterThanOrEqualTo(
              _fullCircle(tester) * (1 - HomeCircleMetrics.nearFitMaxTrim) -
                  0.01,
            ),
            reason: reason,
          );
          final twoLine =
              tester.getSize(find.text(activityLabel(activity))).height > 30;
          if (!twoLine || inset == _s25GestureNavigation) {
            expect(
              _circle(tester),
              closeTo(_fullCircle(tester), 0.01),
              reason: reason,
            );
          }
        }
      }
    });

    testWidgets('a running Circle tightens only as far as needed: one-line '
        'activities with a short first action keep the compact rhythm, and '
        'Pixel 7 keeps its own', (tester) async {
      for (final activity in [
        ActivityId.thirtyMinuteWalk,
        ActivityId.easyWalk,
      ]) {
        await pumpS25(tester, activity);
        await tester.tap(_cta);
        await tester.pumpAndSettle();
        expect(
          _column(tester).fit,
          HomeRhythmFit.compactChildren,
          reason: activity.name,
        );
      }

      await _pumpHome(
        tester,
        prefs: _assigned('moreEnergy', 'thirtyMinuteWalk'),
        hour: 14,
      );
      await tester.tap(_cta);
      await tester.pumpAndSettle();
      expect(_column(tester).fit, HomeRhythmFit.usual);
      expect(_circle(tester), closeTo(_fullCircle(tester), 0.01));
      expect(_onFirstScreen(tester, _closeCta), isTrue);
    });

    testWidgets('dark, 3-button navigation, a two-line activity with a '
        'three-line first action: Close Circle fully on the first screen', (
      tester,
    ) async {
      await pumpS25(
        tester,
        ActivityId.activeHouseholdTask,
        brightness: Brightness.dark,
      );
      await tester.tap(_cta);
      await tester.pumpAndSettle();
      _expectCloseOnFirstScreen(tester, ActivityId.activeHouseholdTask, 'dark');
      expect(_column(tester).fit, HomeRhythmFit.tightened);
    });

    testWidgets('130% text, running: the full Circle, no tightening, and '
        'the page scrolls to Close Circle without overflow', (tester) async {
      await pumpS25(tester, ActivityId.activeHouseholdTask, textScale: 1.3);
      await tester.ensureVisible(_cta);
      await tester.pumpAndSettle();
      await tester.tap(_cta);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_column(tester).trimmed, 0);
      expect(_column(tester).fit, isNot(HomeRhythmFit.tightened));
      expect(_circle(tester), closeTo(_fullCircle(tester), 0.01));
      final viewport = tester.getRect(
        find.ancestor(of: _closeCta, matching: find.byType(Scrollable)).first,
      );
      await tester.ensureVisible(_closeCta);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(_closeCta).bottom,
        lessThanOrEqualTo(viewport.bottom),
      );
    });

    testWidgets('First Breath: a trimmed Circle starts at its full Ready size '
        'and eases down only as it opens — it never jumps', (tester) async {
      await pumpS25(
        tester,
        ActivityId.energisingStretchFlow,
        firstBreath: true,
      );
      final full = _fullCircle(tester);
      expect(_circle(tester), closeTo(full, 0.01));

      var previous = full;
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        final now = _circle(tester);
        expect(now, lessThanOrEqualTo(previous + 0.01));
        // Never more than a frame's worth of easing at once.
        expect(previous - now, lessThan(full * 0.01));
        previous = now;
      }
      await tester.pumpAndSettle();
      expect(_column(tester).fit, HomeRhythmFit.trimmed);
      expect(_circle(tester), lessThan(full));
      expect(_ctaOnFirstScreen(tester), isTrue);
    });
  });
}
