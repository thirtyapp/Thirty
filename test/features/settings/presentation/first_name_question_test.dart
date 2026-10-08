import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/branding/thirty_brand_lockup.dart';
import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/reminder/reminder_gateway.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/core/routing/app_shell.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/core/widgets/thirty_progress_circle.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/presentation/home_page.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';
import 'package:thirty/features/settings/presentation/first_name_question_page.dart';
import 'package:thirty/features/settings/presentation/widgets/first_use_world_window.dart';

/// The one first-use question, "What should we call you?": asked once
/// before THIRTY is first used, resolved by Continue (a name) or Skip for
/// now (none), and never asked again — not after skipping, saving, or
/// removing the name later in You.

class _FakeReminderGateway implements ReminderGateway {
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<bool> hasExactAlarmAccess() async => true;
  @override
  Future<void> requestExactAlarmAccess() async {}
  @override
  Future<ScheduleOutcome> scheduleDaily({
    required DateTime firstOccurrenceLocal,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async => ScheduleOutcome.scheduled;
  @override
  Future<void> cancel() async {}
}

class _FakeEntitlementGateway implements EntitlementGateway {
  @override
  Stream<EntitlementStatus> get statusUpdates => const Stream.empty();
  @override
  Future<EntitlementStatus> initialize() async => EntitlementStatus.inactive;
  @override
  Future<MonthlyOffer?> monthlyOffer() async => null;
  @override
  Future<PurchaseOutcome> purchaseMonthly() async => PurchaseOutcome.error;
  @override
  Future<RestoreOutcome> restore() async => RestoreOutcome.notFound;
  @override
  Future<String?> managementUrl() async => null;
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

/// Launches THIRTY over [values] — a cold start — and settles on wherever
/// the startup gate leads.
Future<(ProviderContainer, SharedPreferences)> _launch(
  WidgetTester tester, {
  Map<String, Object> values = const {},
  Size size = const Size(412, 915),
  double textScale = 1,
  ThemeData? theme,
  DateTime? now,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      entitlementGatewayProvider.overrideWithValue(_FakeEntitlementGateway()),
      reminderGatewayProvider.overrideWithValue(_FakeReminderGateway()),
      if (now != null) nowProvider.overrideWithValue(now),
    ],
  );
  addTearDown(container.dispose);
  if (theme != null && theme.brightness == Brightness.dark) {
    await prefs.setString('theme_mode_v1', 'dark');
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const ThirtyApp()),
  );
  await tester.pumpAndSettle();
  // `appRouter` is one app-wide instance shared by every test in this file:
  // navigate once so its redirect runs against this launch's own state.
  appRouter.go('/');
  await tester.pumpAndSettle();
  return (container, prefs);
}

Finder get _question => find.byType(FirstNameQuestionPage);
Finder get _field =>
    find.descendant(of: _question, matching: find.byType(TextField));
Finder get _window => find.byType(FirstUseWorldWindow);
Image _windowImage(WidgetTester tester) => tester.widget<Image>(
  find.descendant(of: _window, matching: find.byType(Image)),
);
String _windowAsset(WidgetTester tester) =>
    (_windowImage(tester).image as AssetImage).assetName;
ThirtyButton _continue(WidgetTester tester) =>
    tester.widget<ThirtyButton>(find.widgetWithText(ThirtyButton, 'Continue'));

void _expectToday(WidgetTester tester) {
  expect(_question, findsNothing);
  expect(find.byType(HomePage), findsOneWidget);
  expect(find.byType(AppShell), findsOneWidget);
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

  group('firstUseRedirect (pure)', () {
    test('unresolved: everything leads to the question', () {
      for (final location in ['/', '/plans', '/settings', '/premium']) {
        expect(
          firstUseRedirect(promptSeen: false, location: location),
          firstNameQuestionLocation,
        );
      }
      expect(
        firstUseRedirect(
          promptSeen: false,
          location: firstNameQuestionLocation,
        ),
        isNull,
      );
    });

    test('resolved: the question leads to Today; nothing else moves', () {
      expect(
        firstUseRedirect(promptSeen: true, location: firstNameQuestionLocation),
        '/',
      );
      for (final location in ['/', '/plans', '/settings', '/premium']) {
        expect(firstUseRedirect(promptSeen: true, location: location), isNull);
      }
    });
  });

  group('When it is asked', () {
    for (final (label, values) in [
      ('no stored flag', <String, Object>{}),
      ('the flag false', <String, Object>{firstNamePromptSeenKey: false}),
      ('a malformed flag', <String, Object>{firstNamePromptSeenKey: 'yes'}),
    ]) {
      testWidgets('$label: the question comes first, with nothing else '
          'reachable', (tester) async {
        await _launch(tester, values: values);
        expect(_question, findsOneWidget);
        expect(find.text('What should we call you?'), findsOneWidget);
        expect(
          find.text(
            'Your first name stays on this device and helps THIRTY feel a '
            'little more personal.',
          ),
          findsOneWidget,
        );
        expect(find.text('First name'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
        expect(find.text('Skip for now'), findsOneWidget);
        expect(find.byType(HomePage), findsNothing);
        expect(find.byType(NavigationBar), findsNothing);
      });
    }

    testWidgets('an existing user who already has a name but no flag is '
        'asked once, prefilled-free (the field starts empty)', (tester) async {
      await _launch(tester, values: {firstNameKey: 'Thomas'});
      expect(_question, findsOneWidget);
      expect(tester.widget<TextField>(_field).controller!.text, isEmpty);
    });

    testWidgets('a deep location while unresolved still leads to the '
        'question', (tester) async {
      await _launch(tester);
      appRouter.go('/settings');
      await tester.pumpAndSettle();
      expect(_question, findsOneWidget);
    });

    testWidgets('Back on the question never slips past it', (tester) async {
      final (container, prefs) = await _launch(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_question, findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
      expect(container.read(firstNamePromptSeenProvider), isFalse);
      expect(prefs.containsKey(firstNameKey), isFalse);
    });
  });

  group('Resolving it', () {
    testWidgets('a valid name + Continue: saved, resolved, on to Today', (
      tester,
    ) async {
      final (container, prefs) = await _launch(tester);
      await tester.enterText(_field, '  Thomas ');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(prefs.getString(firstNameKey), 'Thomas');
      expect(prefs.getBool(firstNamePromptSeenKey), isTrue);
      expect(container.read(firstNameProvider), 'Thomas');
      _expectToday(tester);
    });

    testWidgets('the keyboard Done action continues too', (tester) async {
      final (_, prefs) = await _launch(tester);
      await tester.enterText(_field, 'Anna');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(prefs.getString(firstNameKey), 'Anna');
      _expectToday(tester);
    });

    testWidgets('Skip for now: no name, resolved, on to Today', (tester) async {
      final (container, prefs) = await _launch(tester);
      await tester.enterText(_field, 'Typed then skipped');
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();

      expect(prefs.containsKey(firstNameKey), isFalse);
      expect(container.read(firstNameProvider), isNull);
      expect(prefs.getBool(firstNamePromptSeenKey), isTrue);
      _expectToday(tester);
    });

    testWidgets('blank input never becomes a name: Continue stays disabled '
        'and Done does nothing', (tester) async {
      final (_, prefs) = await _launch(tester);
      expect(_continue(tester).onPressed, isNull);
      await tester.enterText(_field, '    ');
      await tester.pump();
      expect(_continue(tester).onPressed, isNull);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(_question, findsOneWidget);
      expect(prefs.containsKey(firstNameKey), isFalse);
      expect(prefs.containsKey(firstNamePromptSeenKey), isFalse);
    });

    testWidgets('over 40 code points: explained, Continue disabled, nothing '
        'saved', (tester) async {
      final (_, prefs) = await _launch(tester);
      await tester.enterText(_field, 'a' * 41);
      await tester.pump();
      expect(find.text('Use 40 characters or fewer.'), findsOneWidget);
      expect(_continue(tester).onPressed, isNull);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(_question, findsOneWidget);
      expect(prefs.containsKey(firstNameKey), isFalse);

      await tester.enterText(_field, 'a' * 40);
      await tester.pump();
      expect(find.text('Use 40 characters or fewer.'), findsNothing);
      expect(_continue(tester).onPressed, isNotNull);
    });

    for (final name in ['José María', 'Zoë', 'さくら', 'Ngọc']) {
      testWidgets('Unicode "$name" is saved exactly', (tester) async {
        final (_, prefs) = await _launch(tester);
        await tester.enterText(_field, name);
        await tester.pump();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(prefs.getString(firstNameKey), name);
      });
    }
  });

  group('Never asked again', () {
    testWidgets('after skipping: the next launch opens Today', (tester) async {
      await _launch(tester, values: {firstNamePromptSeenKey: true});
      _expectToday(tester);
    });

    testWidgets('after saving a name: the next launch opens Today', (
      tester,
    ) async {
      await _launch(
        tester,
        values: {firstNamePromptSeenKey: true, firstNameKey: 'Thomas'},
      );
      _expectToday(tester);
    });

    testWidgets('the question\'s own location leads to Today once resolved', (
      tester,
    ) async {
      await _launch(tester, values: {firstNamePromptSeenKey: true});
      appRouter.go(firstNameQuestionLocation);
      await tester.pumpAndSettle();
      _expectToday(tester);
    });

    testWidgets('removing the name later in You keeps it resolved — no '
        'question on the next launch', (tester) async {
      final (container, prefs) = await _launch(
        tester,
        values: {firstNamePromptSeenKey: true, firstNameKey: 'Thomas'},
      );
      await container.read(firstNameProvider.notifier).clear();
      expect(prefs.containsKey(firstNameKey), isFalse);
      expect(prefs.getBool(firstNamePromptSeenKey), isTrue);
      expect(container.read(firstNamePromptSeenProvider), isTrue);

      await _launch(tester, values: {firstNamePromptSeenKey: true});
      _expectToday(tester);
    });

    testWidgets('"Delete Circle history" keeps the name and the resolved '
        'question', (tester) async {
      tester.view.physicalSize = const Size(412, 3000);
      final (_, prefs) = await _launch(
        tester,
        values: {firstNamePromptSeenKey: true, firstNameKey: 'Thomas'},
        size: const Size(412, 3000),
      );
      await CircleJournalRepository(prefs).recordShown(
        circleId: '2026-10-01',
        localDate: '2026-10-01',
        direction: Intention.moreEnergy,
        activityId: ActivityId.thirtyMinuteWalk,
        shownAt: DateTime(2026, 10, 1, 9),
      );
      appRouter.go('/settings');
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppShell)),
      );
      container.invalidate(circleJournalRepositoryProvider);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete Circle history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();

      expect(prefs.getString(circleJournalKey), isNull);
      expect(prefs.getString(firstNameKey), 'Thomas');
      expect(prefs.getBool(firstNamePromptSeenKey), isTrue);
    });
  });

  group('THIRTY identity', () {
    const slogan = 'A BRIGHTER YOU\nIN SMALL STEPS';
    Finder lockup() => find.descendant(
      of: _question,
      matching: find.byType(ThirtyBrandLockup),
    );

    testWidgets('the wordmark with Home\'s slogan, exactly once, top-left '
        'above the world window', (tester) async {
      await _launch(tester);
      expect(tester.takeException(), isNull);
      expect(lockup(), findsOneWidget);
      expect(find.text(slogan), findsOneWidget);
      final lockupWidget = tester.widget<ThirtyBrandLockup>(lockup());
      expect(lockupWidget.centered, isFalse);
      expect(lockupWidget.wordmarkWidth, 96);
      expect(lockupWidget.taglineFontSize, 8);
      final sloganRect = tester.getRect(find.text(slogan));
      expect(sloganRect.left, AppSpacing.page);
      expect(sloganRect.bottom, lessThan(tester.getRect(_window).top));
      // Two lines, both laid out in full.
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text(slogan), matching: find.byType(RichText)),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(
        paragraph
            .getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: slogan.length),
            )
            .map((box) => box.top)
            .toSet(),
        hasLength(2),
      );
    });

    testWidgets('read once, as one identity: "THIRTY" then the slogan; the '
        'question stays the only header', (tester) async {
      final handle = tester.ensureSemantics();
      await _launch(tester);
      final node = tester.getSemantics(lockup());
      expect(node.label, contains('THIRTY'));
      expect(node.label, contains(ThirtyBrandLockup.tagline));
      expect(node, isSemantics(isHeader: false));
      expect(
        find.bySemanticsLabel(RegExp(ThirtyBrandLockup.tagline)),
        findsOneWidget,
      );
      handle.dispose();
    });

    for (final (label, size, theme) in [
      ('360×740 at 200%', const Size(360, 740), AppTheme.light),
      ('Pixel 7 dark at 200%', const Size(412, 915), AppTheme.dark),
    ]) {
      testWidgets('$label: the slogan stays, at its logotype size', (
        tester,
      ) async {
        await _launch(tester, size: size, textScale: 2, theme: theme);
        expect(tester.takeException(), isNull);
        // The autofocused field may scroll the page to itself; the slogan
        // is still there, at the top.
        await tester.scrollUntilVisible(
          find.text(slogan),
          -100,
          scrollable: find
              .descendant(of: _question, matching: find.byType(Scrollable))
              .first,
        );
        await tester.pumpAndSettle();
        expect(find.text(slogan).hitTestable(), findsOneWidget);
        expect(tester.getSize(find.text(slogan)).height, lessThan(32));
      });
    }
  });

  group('World window', () {
    testWidgets('sits between the wordmark and the question, centred', (
      tester,
    ) async {
      await _launch(tester);
      expect(_window, findsOneWidget);
      final window = tester.getRect(_window);
      final question = tester.getRect(find.text('What should we call you?'));
      expect(window.bottom, lessThan(question.top));
      expect(window.center.dx, closeTo(412 / 2, 0.5));
      expect(window.width, closeTo(window.height, 0.001));
    });

    for (final (hour, asset) in [
      (5, 'assets/you/you_header_morning_v1.webp'),
      (8, 'assets/you/you_header_morning_v1.webp'),
      (11, 'assets/you/you_header_morning_v1.webp'),
      (12, 'assets/you/you_header_day_v1.webp'),
      (14, 'assets/you/you_header_day_v1.webp'),
      (17, 'assets/you/you_header_day_v1.webp'),
      (18, 'assets/you/you_header_evening_v1.webp'),
      (21, 'assets/you/you_header_evening_v1.webp'),
      (4, 'assets/you/you_header_evening_v1.webp'),
    ]) {
      testWidgets('at $hour:00 it shows $asset', (tester) async {
        await _launch(tester, now: DateTime(2026, 10, 4, hour));
        expect(_windowAsset(tester), asset);
      });
    }

    testWidgets('the art is cover-cropped round, never stretched', (
      tester,
    ) async {
      await _launch(tester, now: DateTime(2026, 10, 4, 14));
      final image = _windowImage(tester);
      expect(image.fit, BoxFit.cover);
      expect(image.alignment, FirstUseWorldWindow.cropAlignment);
      expect(
        find.ancestor(
          of: find.descendant(of: _window, matching: find.byType(Image)),
          matching: find.byType(ClipOval),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a window, not a Circle: no ring, no progress, no semantics', (
      tester,
    ) async {
      await _launch(tester);
      expect(find.byType(ThirtyProgressCircle), findsNothing);
      expect(find.bySemanticsLabel("Today's Circle"), findsNothing);
      expect(find.text('Start Circle'), findsNothing);
      final exclude = tester.widget<ExcludeSemantics>(
        find.descendant(of: _window, matching: find.byType(ExcludeSemantics)),
      );
      expect(exclude.excluding, isTrue);
    });

    // `previous`: the window's diameter before the founder-requested
    // enlargement; every size is now larger, the 200% ones least.
    for (final (label, size, scale, min, max, previous) in [
      ('Pixel 7', const Size(412, 915), 1.0, 262.0, 280.0, 241.6),
      ('360×740', const Size(360, 740), 1.0, 196.0, 212.0, 185.6),
      ('Pixel 7 at 200%', const Size(412, 915), 2.0, 180.0, 195.0, 170.8),
      ('360×740 at 200%', const Size(360, 740), 2.0, 135.0, 150.0, 131.2),
    ]) {
      testWidgets('$label: the window stays present at a fitting size, '
          'round', (tester) async {
        await _launch(tester, size: size, textScale: scale);
        expect(tester.takeException(), isNull);
        final window = tester.getSize(_window);
        expect(window.width, inInclusiveRange(min, max));
        expect(window.width, greaterThan(previous));
        expect(window.height, closeTo(window.width, 0.001));
      });
    }

    testWidgets('Pixel 7 at 200%: the larger window still leaves the '
        'question and both actions on the first screen', (tester) async {
      await _launch(tester, textScale: 2);
      // The autofocused field may scroll the page; judge it from the top.
      tester
          .state<ScrollableState>(
            find
                .descendant(of: _question, matching: find.byType(Scrollable))
                .first,
          )
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      for (final text in [
        'What should we call you?',
        'Continue',
        'Skip for now',
      ]) {
        expect(
          tester.getRect(find.text(text)).bottom,
          lessThanOrEqualTo(915),
          reason: text,
        );
      }
    });

    testWidgets('the keyboard opening never resizes the window', (
      tester,
    ) async {
      await _launch(tester);
      final before = tester.getSize(_window);
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.getSize(_window), before);
    });

    testWidgets('dark mode: the evening art in a dark-surface frame', (
      tester,
    ) async {
      await _launch(
        tester,
        theme: AppTheme.dark,
        now: DateTime(2026, 10, 4, 21),
      );
      expect(_windowAsset(tester), 'assets/you/you_header_evening_v1.webp');
      final context = tester.element(_window);
      final colors = Theme.of(context).extension<AppColors>()!;
      expect(Theme.of(context).brightness, Brightness.dark);
      final disc = tester.widget<DecoratedBox>(
        find.descendant(of: _window, matching: find.byType(DecoratedBox)).first,
      );
      final decoration = disc.decoration as BoxDecoration;
      expect(decoration.color, colors.surface);
      expect(decoration.boxShadow, isNull);
    });

    for (final (label, theme) in [
      ('light', AppTheme.light),
      ('dark', AppTheme.dark),
    ]) {
      testWidgets('$label: flat — no shadow, halo or glow anywhere in the '
          'window', (tester) async {
        await _launch(tester, theme: theme);
        expect(tester.takeException(), isNull);
        final decorations = [
          for (final box in tester.widgetList<DecoratedBox>(
            find.descendant(of: _window, matching: find.byType(DecoratedBox)),
          ))
            box.decoration,
        ];
        expect(decorations, isNotEmpty);
        for (final decoration in decorations) {
          if (decoration is BoxDecoration) {
            expect(decoration.boxShadow, isNull);
          }
        }
        expect(
          find.descendant(of: _window, matching: find.byType(PhysicalModel)),
          findsNothing,
        );
        expect(
          find.descendant(of: _window, matching: find.byType(Material)),
          findsNothing,
        );
      });
    }
  });

  group('Accessibility and layout', () {
    testWidgets('the question is a header; the field is labelled; Continue '
        'and Skip for now are buttons', (tester) async {
      await _launch(tester);
      expect(
        tester.getSemantics(find.text('What should we call you?')),
        isSemantics(isHeader: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('First name')),
        isSemantics(label: 'First name', isTextField: true),
      );
      expect(find.bySemanticsLabel('First name'), findsOneWidget);
      for (final label in ['Continue', 'Skip for now']) {
        expect(
          tester.getSemantics(find.text(label)),
          isSemantics(isButton: true),
          reason: label,
        );
      }
      expect(find.byType(CircleAvatar), findsNothing);
    });

    for (final (label, size, scale, theme) in [
      ('Pixel 7 at 200%', const Size(412, 915), 2.0, AppTheme.light),
      ('360×740', const Size(360, 740), 1.0, AppTheme.light),
      ('360×740 at 200%', const Size(360, 740), 2.0, AppTheme.light),
      ('Pixel 7 dark', const Size(412, 915), 1.0, AppTheme.dark),
      ('360×740 dark at 200%', const Size(360, 740), 2.0, AppTheme.dark),
    ]) {
      testWidgets('$label: fits with the keyboard up; both actions reachable', (
        tester,
      ) async {
        await _launch(tester, size: size, textScale: scale, theme: theme);
        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final cut = find
            .byType(RichText)
            .evaluate()
            .map((e) => e.renderObject! as RenderParagraph)
            .where((p) => p.didExceedMaxLines);
        expect(cut, isEmpty);
        for (final action in ['Continue', 'Skip for now']) {
          // Reached by scrolling the question's own page.
          await tester.scrollUntilVisible(
            find.text(action),
            100,
            scrollable: find
                .descendant(of: _question, matching: find.byType(Scrollable))
                .first,
          );
          await tester.ensureVisible(find.text(action));
          await tester.pumpAndSettle();
          expect(find.text(action).hitTestable(), findsOneWidget);
        }
      });
    }
  });
}
