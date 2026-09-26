import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/providers/theme_mode_provider.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/core/routing/app_shell.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';

/// Phase C5 — SnackBars float with the real app, router and fonts: 8pt
/// above the floating bottom nav on You and 8pt above the screen edge on
/// Circle history (no nav), inside the nav's 16pt side margins, 24pt
/// corners, no shadow, inverseSurface colours — at 320 / 360pt and 200%
/// text, light and dark. Copy, duration and live-region semantics are
/// unchanged.
///
/// `appRouter` is a process-wide singleton; every test navigates
/// explicitly.

const _copied = 'Copied your Circle history as text.';

class _SettledEntitlement extends EntitlementNotifier {
  @override
  EntitlementStatus build() => EntitlementStatus.inactive;
}

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(file).readAsBytesSync())),
    );
  }
  await loader.load();
}

/// Opens [location] and taps "Copy as text", leaving its SnackBar fully
/// shown.
Future<void> _showCopiedSnackBar(
  WidgetTester tester, {
  required String location,
  required Size size,
  double textScale = 1,
  bool dark = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async => null,
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await CircleJournalRepository(prefs).recordShown(
    circleId: '2026-09-01',
    localDate: '2026-09-01',
    direction: Intention.moreEnergy,
    activityId: ActivityId.thirtyMinuteWalk,
    shownAt: DateTime(2026, 9, 1, 9),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        premiumEntitlementProvider.overrideWithValue(false),
        entitlementStatusProvider.overrideWith(_SettledEntitlement.new),
      ],
      child: const ThirtyApp(),
    ),
  );
  await tester.pumpAndSettle();
  if (dark) {
    ProviderScope.containerOf(
      tester.element(find.byType(ThirtyApp)),
    ).read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();
  }
  appRouter.go(location);
  await tester.pumpAndSettle();

  await tester.scrollUntilVisible(find.text('Copy as text'), 200);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Copy as text'));
  await tester.pumpAndSettle();
  expect(find.text(_copied), findsOneWidget);
}

Rect _surface(WidgetTester tester) => tester.getRect(
  find
      .descendant(of: find.byType(SnackBar), matching: find.byType(Material))
      .first,
);

void main() {
  setUpAll(() async {
    await _loadFont('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ]);
  });

  tearDown(() => appRouter.go('/'));

  for (final (width, height) in [(320.0, 640.0), (360.0, 740.0)]) {
    for (final dark in [false, true]) {
      final label = '${width.toInt()}pt, 200%, ${dark ? 'dark' : 'light'}';

      testWidgets('$label: floats 8pt above the floating nav on You', (
        tester,
      ) async {
        await _showCopiedSnackBar(
          tester,
          location: '/settings',
          size: Size(width, height),
          textScale: 2,
          dark: dark,
        );
        expect(tester.takeException(), isNull);

        final snack = _surface(tester);
        final nav = tester.getRect(find.byType(FloatingNavSurface));
        expect(snack.left, AppSpacing.m);
        expect(snack.right, width - AppSpacing.m);
        expect(nav.top - snack.bottom, AppSpacing.s);
        expect(snack.overlaps(nav), isFalse);
        expect(
          tester.renderObject<RenderParagraph>(find.text(_copied))
              .didExceedMaxLines,
          isFalse,
        );
      });

      testWidgets('$label: floats 8pt above the screen edge on Circle '
          'history (no nav)', (tester) async {
        await _showCopiedSnackBar(
          tester,
          location: '/history',
          size: Size(width, height),
          textScale: 2,
          dark: dark,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(FloatingNavSurface), findsNothing);

        final snack = _surface(tester);
        expect(snack.left, AppSpacing.m);
        expect(snack.right, width - AppSpacing.m);
        expect(height - snack.bottom, AppSpacing.s);
        expect(
          tester.renderObject<RenderParagraph>(find.text(_copied))
              .didExceedMaxLines,
          isFalse,
        );
      });
    }
  }

  for (final dark in [false, true]) {
    testWidgets('${dark ? 'dark' : 'light'}: 24pt corners, no shadow, '
        'inverseSurface colours', (tester) async {
      await _showCopiedSnackBar(
        tester,
        location: '/settings',
        size: const Size(360, 740),
        dark: dark,
      );
      final colors = dark ? AppColors.dark : AppColors.light;
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(SnackBar),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.elevation, 0);
      expect(
        material.shape,
        const RoundedRectangleBorder(borderRadius: AppRadius.xl),
      );
      // inverseSurface = textPrimary, onInverseSurface = background.
      expect(material.color, colors.textPrimary);
      expect(
        tester.renderObject<RenderParagraph>(find.text(_copied)).text.style
            ?.color,
        colors.background,
      );
    });
  }

  testWidgets('copy, 4s duration, no action and live-region semantics are '
      'unchanged', (tester) async {
    await _showCopiedSnackBar(
      tester,
      location: '/settings',
      size: const Size(360, 740),
    );
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.duration, const Duration(seconds: 4));
    expect(snackBar.action, isNull);
    expect(
      find.ancestor(
        of: find.text(_copied),
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.liveRegion == true,
        ),
      ),
      findsWidgets,
    );

    await tester.pump(const Duration(milliseconds: 3500));
    expect(find.text(_copied), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text(_copied), findsNothing);
  });
}
