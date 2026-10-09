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
bool _ctaOnFirstScreen(WidgetTester tester) =>
    tester.getRect(_cta).bottom + HomeCircleMetrics.compactGap <=
    tester.getRect(_homeScrollable).bottom + 0.5;

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

    testWidgets('Start and Close never resize the Circle: a two-line '
        'activity keeps its trim, a one-line activity stays full size', (
      tester,
    ) async {
      for (final (activity, trimmed) in [
        (ActivityId.energisingStretchFlow, true),
        (ActivityId.writeItDown, false),
      ]) {
        await pumpS25(tester, activity);
        final ready = _circle(tester);
        expect(ready < _fullCircle(tester) - 0.01, trimmed);

        await tester.tap(_cta);
        await tester.pumpAndSettle();
        expect(find.widgetWithText(ThirtyButton, 'Close Circle'), findsOne);
        expect(_circle(tester), closeTo(ready, 0.01), reason: activity.name);

        await tester.tap(find.widgetWithText(ThirtyButton, 'Close Circle'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Close Circle').last);
        await tester.pumpAndSettle();
        expect(find.text('Done for today'), findsOneWidget);
        expect(_circle(tester), closeTo(ready, 0.01), reason: activity.name);
      }
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
