import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/home_page.dart';
import 'package:thirty/features/home/presentation/widgets/home_header.dart';
import 'package:thirty/features/settings/presentation/settings_page.dart';

/// Phase D1 — Home visual pass (Design vision.png), with the app's real
/// fonts: the header lockup and profile button.

final _today = DateTime(2026, 8, 2);

/// Today's Circle assigned, First Breath already played.
const _assigned = <String, Object>{
  recommendationDayKey: '2026-08-02',
  recommendationIntentionKey: 'moreEnergy',
  recommendationActivityIdKey: 'thirtyMinuteWalk',
  firstBreathLastPlayedDateKey: '2026-08-02',
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
}
