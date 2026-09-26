import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/features/home/presentation/widgets/home_circle_metrics.dart';
import 'package:thirty/core/widgets/thirty_progress_circle.dart';
import 'package:thirty/core/branding/thirty_brand_lockup.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/core/routing/app_shell.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/home_page.dart';
import 'package:thirty/core/activity_category.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/features/home/presentation/widgets/home_header.dart';
import 'package:thirty/features/home/presentation/widgets/later_today_label.dart';
import 'package:thirty/features/home/presentation/widgets/today_card.dart';
import 'package:thirty/features/settings/presentation/settings_page.dart';

/// Phase D1 — Home visual pass (Design vision.png), with the app's real
/// fonts: the header lockup and profile button (D1a), and the greeting,
/// Today card and full-width CTA (D1c).

final _today = DateTime(2026, 8, 2);

/// Today's Circle assigned, First Breath already played.
const _assigned = <String, Object>{
  recommendationDayKey: '2026-08-02',
  recommendationIntentionKey: 'moreEnergy',
  recommendationActivityIdKey: 'thirtyMinuteWalk',
  firstBreathLastPlayedDateKey: '2026-08-02',
};

const _started = <String, Object>{
  ..._assigned,
  recommendationStatusKey: 'started',
  recommendationStartedAtKey: '2026-08-02T00:00:00.000',
};

const _closed = <String, Object>{
  ..._assigned,
  recommendationStatusKey: 'closed',
  recommendationStartedAtKey: '2026-08-02T00:00:00.000',
  recommendationClosedAtKey: '2026-08-02T00:25:00.000',
};

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(file).readAsBytesSync())),
    );
  }
  await loader.load();
}

Future<void> _pumpHome(
  WidgetTester tester, {
  Map<String, Object> storedPrefs = _assigned,
  double width = 360,
  double height = 740,
  double textScale = 1,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(storedPrefs);
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(_today),
        eventClockProvider.overrideWithValue(
          () => _today.add(const Duration(minutes: 10)),
        ),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: const HomePage(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> _truncated(WidgetTester tester) => [
  for (final element in find.byType(RichText).evaluate())
    if ((element.renderObject! as RenderParagraph).didExceedMaxLines)
      (element.renderObject! as RenderParagraph).text.toPlainText(),
];

void main() {
  setUpAll(() async {
    await _loadFont('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ]);
  });

  group('Header', () {
    testWidgets('the lockup is the header "THIRTY" with the tagline read '
        'after it', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpHome(tester);
      expect(find.bySemanticsLabel('THIRTY'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('THIRTY')),
        matchesSemantics(label: 'THIRTY', isHeader: true),
      );
      expect(find.bySemanticsLabel(HomeBrandLockup.tagline), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('the lockup sits on the page gutter, the profile button on '
        'the opposite gutter', (tester) async {
      await _pumpHome(tester);
      final lockup = tester.getRect(find.byType(HomeBrandLockup));
      final button = tester.getRect(find.byType(HomeProfileButton));
      expect(lockup.left, AppSpacing.page);
      expect(button.right, 360 - AppSpacing.page);
      expect(button.size, const Size.square(48));
      expect(lockup.center.dy, closeTo(button.center.dy, 1));
    });

    testWidgets('the profile button is a 48pt "Open You" button in Ready '
        'too', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpHome(tester, storedPrefs: const {});
      expect(
        tester.getSemantics(find.byType(HomeProfileButton)),
        matchesSemantics(
          label: 'Open You',
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(tester.getSize(find.byType(HomeProfileButton)).height, 48);
      semantics.dispose();
    });

    for (final (width, height) in [(320.0, 640.0), (360.0, 740.0)]) {
      for (final dark in [false, true]) {
        testWidgets('${width.toInt()}pt, 200%, ${dark ? 'dark' : 'light'}: '
            'the lockup keeps its fixed size and fits the header', (
          tester,
        ) async {
          await _pumpHome(
            tester,
            width: width,
            height: height,
            textScale: 2,
            theme: dark ? AppTheme.dark : AppTheme.light,
          );
          expect(tester.takeException(), isNull);
          expect(_truncated(tester), isEmpty);
          final lockup = tester.getRect(find.byType(HomeBrandLockup));
          final appBar = tester.getRect(find.byType(AppBar));
          final button = tester.getRect(find.byType(HomeProfileButton));
          expect(lockup.width, lessThan(width / 2));
          expect(lockup.top, greaterThanOrEqualTo(appBar.top));
          expect(lockup.bottom, lessThanOrEqualTo(appBar.bottom));
          expect(lockup.overlaps(button), isFalse);
        });
      }
    }
  });

  testWidgets('the profile button opens You', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(_assigned);
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          nowProvider.overrideWithValue(_today),
        ],
        child: const ThirtyApp(),
      ),
    );
    appRouter.go('/');
    await tester.pumpAndSettle();
    addTearDown(() => appRouter.go('/'));

    await tester.tap(find.byType(HomeProfileButton));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
  });

  group('Greeting', () {
    test('changes with the time of day', () {
      for (final (hour, greeting) in [
        (0, 'Good evening'),
        (4, 'Good evening'),
        (5, 'Good morning'),
        (11, 'Good morning'),
        (12, 'Good afternoon'),
        (17, 'Good afternoon'),
        (18, 'Good evening'),
        (23, 'Good evening'),
      ]) {
        expect(
          homeGreeting(DateTime(2026, 8, 2, hour, 30)),
          greeting,
          reason: '$hour:30',
        );
      }
    });

    testWidgets('is a header; the subline shows until the Circle is '
        'closed', (tester) async {
      final semantics = tester.ensureSemantics();
      for (final (prefs, subline) in [
        (_assigned, true),
        (_started, true),
        (_closed, false),
      ]) {
        await _pumpHome(tester, storedPrefs: prefs);
        expect(
          tester.getSemantics(find.text(homeGreeting(_today))),
          matchesSemantics(label: homeGreeting(_today), isHeader: true),
        );
        expect(
          find.text(homeGreetingSubline),
          subline ? findsOneWidget : findsNothing,
        );
      }
      semantics.dispose();
    });
  });

  group('Today card', () {
    testWidgets('left-aligned: TODAY, the direction, the activity with its '
        'icon, a divider and the reason', (tester) async {
      await _pumpHome(tester);
      final card = tester.getRect(find.byType(TodayCard));
      expect(card.left, AppSpacing.page);
      expect(card.right, 360 - AppSpacing.page);
      for (final text in ['TODAY', 'More Energy', '30-minute walk']) {
        expect(
          tester.getTopLeft(find.text(text)).dx,
          greaterThanOrEqualTo(card.left + AppSpacing.featuredCard - 0.5),
          reason: text,
        );
      }
      expect(
        tester.getTopLeft(find.text('TODAY')).dx,
        card.left + AppSpacing.featuredCard,
      );
      expect(
        find.descendant(
          of: find.byType(TodayCard),
          matching: find.byIcon(TodayCard.iconFor(ActivityCategory.walking)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(TodayCard),
          matching: find.byType(Divider),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the World slice shows at ordinary text and never overlaps '
        'the text', (tester) async {
      await _pumpHome(tester);
      final art = find.descendant(
        of: find.byType(TodayCard),
        matching: find.byType(Image),
      );
      expect(art, findsOneWidget);
      final artLeft = tester.getRect(art).left;
      final why = tester.getRect(
        find.textContaining('For more energy'),
      );
      // The art fades in from its left edge; the text column ends where
      // the fade has barely begun.
      expect(why.right, lessThanOrEqualTo(artLeft + AppSpacing.xl + 0.5));
    });

    for (final (width, height) in [(320.0, 640.0), (360.0, 740.0)]) {
      for (final dark in [false, true]) {
        for (final (state, prefs) in [
          ('assigned', _assigned),
          ('started', _started),
          ('closed', _closed),
        ]) {
          testWidgets('${width.toInt()}pt, 200%, ${dark ? 'dark' : 'light'}, '
              '$state: text only, nothing truncated, full-width CTA', (
            tester,
          ) async {
            await _pumpHome(
              tester,
              storedPrefs: prefs,
              width: width,
              height: height,
              textScale: 2,
              theme: dark ? AppTheme.dark : AppTheme.light,
            );
            expect(tester.takeException(), isNull);
            expect(_truncated(tester), isEmpty);
            expect(
              find.descendant(
                of: find.byType(TodayCard),
                matching: find.byType(Image),
              ),
              findsNothing,
            );
            final card = tester.getRect(find.byType(TodayCard));
            expect(card.width, width - AppSpacing.page * 2);
            if (state != 'closed') {
              final cta = tester.getRect(find.byType(ThirtyButton));
              expect(cta.width, width - AppSpacing.page * 2);
              expect(cta.height, greaterThanOrEqualTo(56));
            }
          });
        }
      }
    }
  });

  group('Later today', () {
    testWidgets("hidden while nothing follows today's Circle", (tester) async {
      await _pumpHome(tester);
      expect(find.byType(LaterTodayLabel), findsOneWidget);
      expect(find.text('LATER TODAY'), findsNothing);
    });

    testWidgets('once closed, heads the reflection as a "Later today" '
        'header, below the CTA area', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpHome(tester, storedPrefs: _closed);
      await tester.scrollUntilVisible(
        find.text('Did you try this activity?'),
        200,
      );
      await tester.pumpAndSettle();
      final label = find.text('LATER TODAY');
      expect(label, findsOneWidget);
      expect(
        tester.getSemantics(label),
        matchesSemantics(label: 'Later today', isHeader: true),
      );
      expect(
        tester.getTopLeft(label).dy,
        lessThan(tester.getTopLeft(find.text('Did you try this activity?')).dy),
      );
      expect(
        tester.getTopLeft(label).dy,
        greaterThan(tester.getBottomLeft(find.text('Done for today')).dy),
      );
      expect(tester.getTopLeft(label).dx, AppSpacing.page);
      semantics.dispose();
    });
  });

  group('Bottom nav', () {
    testWidgets('Today is a ring, thicker when selected; selection is sage '
        'with no pill', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues(_assigned);
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            nowProvider.overrideWithValue(_today),
          ],
          child: const ThirtyApp(),
        ),
      );
      appRouter.go('/');
      await tester.pumpAndSettle();
      addTearDown(() => appRouter.go('/'));

      double ringWidth() {
        final ring = tester.widget<Container>(
          find.descendant(
            of: find.byType(TodayRingIcon),
            matching: find.byType(Container),
          ),
        );
        final border = (ring.decoration! as BoxDecoration).border! as Border;
        return border.top.width;
      }

      expect(find.byType(TodayRingIcon), findsOneWidget);
      expect(ringWidth(), 3.5);
      final todayRing = tester.widget<Container>(
        find.descendant(
          of: find.byType(TodayRingIcon),
          matching: find.byType(Container),
        ),
      );
      expect(
        ((todayRing.decoration! as BoxDecoration).border! as Border).top.color,
        AppColors.light.primary,
      );

      await tester.tap(find.text('Plans'));
      await tester.pumpAndSettle();
      expect(ringWidth(), 2);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
    });
  });

  group('Tagline inside the Circle', () {
    Finder circleLockup() => find.descendant(
      of: find.byType(ThirtyProgressCircle),
      matching: find.byType(ThirtyBrandLockup),
    );

    testWidgets('Ready: the wordmark with the tagline, centred, decorative '
        '(the Circle owns the semantics)', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpHome(tester, storedPrefs: const {});
      expect(circleLockup(), findsOneWidget);
      expect(tester.widget<ThirtyBrandLockup>(circleLockup()).centered, isTrue);
      expect(
        find.descendant(
          of: circleLockup(),
          matching: find.text('A BRIGHTER YOU\nIN SMALL STEPS'),
        ),
        findsOneWidget,
      );
      // Only the Circle's own "Today's Circle" node — the lockup inside it
      // adds no semantics of its own.
      expect(find.bySemanticsLabel(ThirtyBrandLockup.tagline), findsNothing);
      expect(find.bySemanticsLabel('THIRTY'), findsNothing);
      final lockup = tester.getRect(circleLockup());
      final circle = tester.getRect(find.byType(ThirtyProgressCircle));
      expect(lockup.center.dx, closeTo(circle.center.dx, 0.5));
      expect(lockup.center.dy, closeTo(circle.center.dy, 0.5));
      semantics.dispose();
    });

    testWidgets('First Breath: the tagline fades in and out with the '
        'wordmark as one lockup', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({
        recommendationDayKey: '2026-08-02',
        recommendationIntentionKey: 'moreEnergy',
        recommendationActivityIdKey: 'thirtyMinuteWalk',
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            nowProvider.overrideWithValue(_today),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const HomePage(),
          ),
        ),
      );
      double lockupOpacity() => tester
          .widget<FadeTransition>(
            find
                .ancestor(
                  of: circleLockup(),
                  matching: find.byType(FadeTransition),
                )
                .first,
          )
          .opacity
          .value;

      expect(circleLockup(), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
      expect(lockupOpacity(), 1);
      await tester.pump(const Duration(milliseconds: 700));
      expect(lockupOpacity(), 0);
      await tester.pumpAndSettle();
    });

    for (final width in [320.0, 360.0, 412.0]) {
      testWidgets('${width.toInt()}pt: the lockup fits inside the ring', (
        tester,
      ) async {
        await _pumpHome(
          tester,
          storedPrefs: const {},
          width: width,
          height: 800,
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
        final lockup = tester.getRect(circleLockup());
        final circle = tester.getRect(find.byType(ThirtyProgressCircle));
        // Every corner of the lockup lies inside the ring's inner edge.
        final inner =
            circle.width / 2 - HomeCircleMetrics.ringStrokeWidth;
        for (final corner in [
          lockup.topLeft,
          lockup.topRight,
          lockup.bottomLeft,
          lockup.bottomRight,
        ]) {
          expect((corner - circle.center).distance, lessThan(inner));
        }
      });
    }
  });
}
