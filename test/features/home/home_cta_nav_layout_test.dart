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
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/widgets/home_circle_metrics.dart';
import 'package:thirty/features/home/presentation/widgets/home_rhythm_column.dart';
import 'package:thirty/features/home/presentation/widgets/today_card.dart';
import 'package:thirty/features/plans/domain/plan_catalog.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/plans/presentation/widgets/plan_session_panel.dart';

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
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 2.625;
  tester.view.padding = const FakeViewPadding(top: 118, bottom: 63);
  tester.view.viewPadding = const FakeViewPadding(top: 118, bottom: 63);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  SharedPreferences.setMockInitialValues(prefs);
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
  await tester.pumpAndSettle();
  addTearDown(() => appRouter.go('/'));
}

Finder get _cta => find.widgetWithText(ThirtyButton, 'Start Circle');

Finder get _homeScrollable =>
    find.ancestor(of: _cta, matching: find.byType(Scrollable)).first;

bool _isCompact(WidgetTester tester) => tester
    .renderObject<RenderHomeRhythmColumn>(find.byType(HomeRhythmColumn))
    .isCompact;

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
}
