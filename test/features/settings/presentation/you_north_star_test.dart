import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/analytics/analytics_consent.dart';
import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/branding/thirty_wordmark_view.dart';
import 'package:thirty/core/config/release_info.dart';
import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/providers/theme_mode_provider.dart';
import 'package:thirty/core/reminder/reminder_gateway.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/core/routing/app_shell.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/worlds/daypart.dart';
import 'package:thirty/core/worlds/world.dart' show Daypart;
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/presentation/widgets/home_header.dart'
    show HomeProfileButton;
import 'package:thirty/features/toolkit/application/toolkit_provider.dart';
import 'package:thirty/features/reminder/application/reminder_provider.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';
import 'package:thirty/features/settings/presentation/settings_page.dart';
import 'package:thirty/features/settings/presentation/widgets/you_about_card.dart';
import 'package:thirty/features/settings/presentation/widgets/you_header_art.dart';
import 'package:thirty/features/settings/presentation/widgets/you_premium_card.dart';

/// You — Visual North Star convergence: the scrolling header, the Premium
/// card's approved copy, Data & privacy, About, Restore last, accessibility
/// and the bottom-nav clearance of the page's last content.

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
  _FakeEntitlementGateway({this.status = EntitlementStatus.inactive});

  final EntitlementStatus status;

  @override
  Stream<EntitlementStatus> get statusUpdates => const Stream.empty();
  @override
  Future<EntitlementStatus> initialize() async => status;
  @override
  Future<MonthlyOffer?> monthlyOffer() async =>
      const MonthlyOffer(localizedPrice: '€4.99');
  @override
  Future<PurchaseOutcome> purchaseMonthly() async => PurchaseOutcome.error;
  @override
  Future<RestoreOutcome> restore() async => RestoreOutcome.notFound;
  @override
  Future<String?> managementUrl() async =>
      'https://play.google.com/store/account/subscriptions';
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

Future<(ProviderContainer, SharedPreferences)> _pump(
  WidgetTester tester, {
  EntitlementStatus status = EntitlementStatus.inactive,
  Size size = const Size(412, 915),
  double textScale = 1.0,
  ThemeData? theme,
  bool withJournal = false,
  Map<String, Object> prefsValues = const {},
  DateTime? now,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  if (withJournal) {
    await CircleJournalRepository(prefs).recordShown(
      circleId: '2026-08-01',
      localDate: '2026-08-01',
      direction: Intention.moreEnergy,
      activityId: ActivityId.thirtyMinuteWalk,
      shownAt: DateTime(2026, 8, 1, 9),
    );
  }
  final container = ProviderContainer(
    overrides: [
      entitlementGatewayProvider.overrideWithValue(
        _FakeEntitlementGateway(status: status),
      ),
      sharedPreferencesProvider.overrideWithValue(prefs),
      reminderGatewayProvider.overrideWithValue(_FakeReminderGateway()),
      if (now != null) nowProvider.overrideWithValue(now),
    ],
  );
  addTearDown(container.dispose);
  await container.read(entitlementStatusProvider.notifier).initialize();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: const SettingsPage(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (container, prefs);
}

/// Scrolls You to its very end.
Future<void> _scrollToEnd(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -6000));
  await tester.pumpAndSettle();
}

Finder get _bandImage => find.descendant(
  of: find.byType(YouHeaderArt),
  matching: find.byType(Image),
);

List<String> _truncated(WidgetTester tester) => [
  for (final element in find.byType(RichText, skipOffstage: false).evaluate())
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
    await _loadFont('Newsreader', ['assets/fonts/Newsreader[opsz,wght].ttf']);
  });

  group('Header', () {
    testWidgets('THIRTY wordmark, "You" and the exact subtitle — scrolling '
        'with the page, no pinned AppBar, no profile button', (tester) async {
      await _pump(tester);

      expect(find.byType(ThirtyWordmarkView), findsOneWidget);
      expect(find.bySemanticsLabel('THIRTY'), findsOneWidget);
      expect(find.text(SettingsPage.title), findsOneWidget);
      expect(SettingsPage.title, 'You');
      expect(find.text('Your space in THIRTY.'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(HomeProfileButton), findsNothing);
      expect(find.bySemanticsLabel('Open You'), findsNothing);

      final titleTop = tester.getTopLeft(find.text('You')).dy;
      await tester.drag(find.byType(ListView), const Offset(0, -40));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('You')).dy, lessThan(titleTop));
    });

    testWidgets('the title and every section heading are semantic headers', (
      tester,
    ) async {
      await _pump(tester, size: const Size(412, 3000));
      for (final heading in [
        'You',
        'THIRTY Premium',
        'Preferences',
        'Data & privacy',
        'About',
      ]) {
        expect(
          tester.getSemantics(find.text(heading)),
          isSemantics(isHeader: true),
          reason: heading,
        );
      }
    });

    testWidgets('the band sits edge to edge between the subtitle and the '
        'Premium card: the art for the daypart, cover-fit (never stretched) at '
        '2.6:1, and decorative only', (tester) async {
      await _pump(tester, now: DateTime(2026, 10, 4, 14));

      final band = find.byType(YouHeaderArt);
      final image = tester.widget<Image>(_bandImage);
      expect(
        (image.image as AssetImage).assetName,
        'assets/you/you_header_day_v1.webp',
      );
      expect(image.fit, BoxFit.cover);
      expect(image.alignment, YouHeaderArt.cropAlignment);
      final size = tester.getSize(band);
      expect(size.width, 412, reason: 'edge to edge, outside the page inset');
      expect(size.width / size.height, closeTo(2.6, 0.01));
      expect(
        tester.getTopLeft(band).dy,
        greaterThan(tester.getBottomLeft(find.text(SettingsPage.subtitle)).dy),
      );
      expect(
        tester.getBottomLeft(band).dy,
        lessThan(tester.getTopLeft(find.text('THIRTY Premium')).dy),
      );
      expect(
        find.ancestor(of: _bandImage, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
    });
  });

  group('You header art', () {
    test("resolves each daypart through THIRTY's own daypart boundaries", () {
      String at(int hour, [int minute = 0]) =>
          youHeaderArt.at(daypartAt(DateTime(2026, 10, 4, hour, minute))).asset;
      const morning = 'assets/you/you_header_morning_v1.webp';
      const day = 'assets/you/you_header_day_v1.webp';
      const evening = 'assets/you/you_header_evening_v1.webp';
      expect(at(5), morning);
      expect(at(11, 59), morning);
      expect(at(12), day);
      expect(at(17, 59), day);
      expect(at(18), evening);
      expect(at(2), evening);
      expect(at(4, 59), evening);
    });

    test('every asset is a bundled WebP of the declared size, and its own — '
        'never the Toolkit band or a World scene', () {
      final assets = <String>{};
      for (final daypart in Daypart.values) {
        final image = youHeaderArt.at(daypart);
        expect(image.asset, startsWith('assets/you/'));
        assets.add(image.asset);
        final file = File(image.asset);
        expect(file.existsSync(), isTrue, reason: image.asset);
        // WebP VP8 lossy: width and height are 14-bit fields at byte 26.
        final bytes = file.readAsBytesSync();
        expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WEBP');
        final data = ByteData.sublistView(bytes);
        expect(data.getUint16(26, Endian.little) & 0x3fff, image.width);
        expect(data.getUint16(28, Endian.little) & 0x3fff, image.height);
      }
      expect(assets, hasLength(3));
    });

    test('the composition-aware crop keeps the oak (about 73% across each '
        'panorama) inside the visible window', () {
      for (final daypart in Daypart.values) {
        final image = youHeaderArt.at(daypart);
        // Cover-fit to the band's height: the visible share of the width is
        // fixed by the two aspect ratios, whatever the phone's width.
        final visible =
            YouHeaderArt.bandAspectRatio / (image.width / image.height);
        final start = (1 - visible) * (YouHeaderArt.cropAlignment.x + 1) / 2;
        final end = start + visible;
        expect(0.73, inInclusiveRange(start + 0.1, end - 0.1));
      }
    });

    for (final (hour, asset) in [
      (8, 'assets/you/you_header_morning_v1.webp'),
      (14, 'assets/you/you_header_day_v1.webp'),
      (21, 'assets/you/you_header_evening_v1.webp'),
    ]) {
      testWidgets('at $hour:00 You shows $asset', (tester) async {
        await _pump(tester, now: DateTime(2026, 10, 4, hour));
        expect(
          (tester.widget<Image>(_bandImage).image as AssetImage).assetName,
          asset,
        );
      });
    }

    testWidgets('renders nothing without art', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: YouHeaderArt(art: null, now: DateTime(2026, 10, 4, 14)),
        ),
      );
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('dimmed slightly in dark mode, full strength in light', (
      tester,
    ) async {
      for (final (dark, opacity) in [(false, 1.0), (true, 0.85)]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: YouHeaderArt(
              art: youHeaderArt,
              now: DateTime(2026, 10, 4, 21),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final fade = tester.widget<Opacity>(
          find.descendant(
            of: find.byType(YouHeaderArt),
            matching: find.byType(Opacity),
          ),
        );
        expect(fade.opacity, opacity);
      }
    });
  });

  group('Premium card', () {
    for (final status in [
      EntitlementStatus.inactive,
      EntitlementStatus.active,
      EntitlementStatus.unavailable,
    ]) {
      testWidgets('${status.name}: the founder-approved body line', (
        tester,
      ) async {
        await _pump(tester, status: status);
        expect(find.text(YouPremiumCard.body), findsOneWidget);
        // V2 Phase D: no retired pillar is sold.
        for (final retired in ['Plans', 'Coach', 'Insights']) {
          expect(find.textContaining(retired), findsNothing, reason: retired);
        }
        expect(find.textContaining('Unlock'), findsNothing);
      });
    }

    testWidgets('initializing also keeps the body line, with no CTA', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({firstNamePromptSeenKey: true});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          entitlementGatewayProvider.overrideWithValue(
            _FakeEntitlementGateway(),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
          reminderGatewayProvider.overrideWithValue(_FakeReminderGateway()),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: AppTheme.light, home: const SettingsPage()),
        ),
      );
      await tester.pump();

      expect(find.text(YouPremiumCard.body), findsOneWidget);
      expect(find.text('Checking your Premium status…'), findsOneWidget);
      expect(find.text('Become Premium'), findsNothing);
    });
  });

  group('Preferences semantics', () {
    testWidgets('the reminder row is one control: its label with its switch '
        'state, announced once', (tester) async {
      await _pump(tester);
      expect(
        tester.getSemantics(find.text('Daily reminder')),
        isSemantics(
          label: 'Daily reminder',
          hasToggledState: true,
          isToggled: false,
          hasTapAction: true,
        ),
      );
      expect(find.bySemanticsLabel('Daily reminder'), findsOneWidget);
    });

    testWidgets('the analytics row is one control: title, explanation and '
        'switch state together; still opt-in and Free', (tester) async {
      final (container, _) = await _pump(tester);
      final node = tester.getSemantics(find.text('Share anonymous usage data'));
      expect(
        node,
        isSemantics(
          hasToggledState: true,
          isToggled: false,
          hasTapAction: true,
        ),
      );
      expect(node.label, contains('Share anonymous usage data'));
      expect(node.label, contains('Your Circle history is never included.'));
      expect(container.read(analyticsConsentProvider), isFalse);
    });

    testWidgets('the selected theme is exposed as selected, in a '
        'single-choice group, with a check — never colour alone', (
      tester,
    ) async {
      final (container, _) = await _pump(tester, size: const Size(412, 3000));
      expect(
        tester.getSemantics(find.text('System')),
        isSemantics(isSelected: true, isInMutuallyExclusiveGroup: true),
      );
      expect(
        tester.getSemantics(find.text('Dark')),
        isSemantics(isSelected: false, isInMutuallyExclusiveGroup: true),
      );

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(
        tester.getSemantics(find.text('Dark')),
        isSemantics(isSelected: true),
      );
    });

    testWidgets('choosing Appearance on You persists it', (tester) async {
      final (_, prefs) = await _pump(tester, size: const Size(412, 3000));
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(prefs.getString(themeModeKey), 'light');
    });
  });

  group('Data & privacy', () {
    testWidgets('"Delete Circle history" deletes the journal only — the '
        'Toolkit, reminder, appearance, analytics consent and other '
        'preferences are kept', (tester) async {
      final (container, prefs) = await _pump(
        tester,
        size: const Size(412, 3000),
        withJournal: true,
        prefsValues: {
          toolkitStateKey: 'toolkit-sentinel',
          reminderEnabledKey: true,
          reminderHourKey: 18,
          reminderMinuteKey: 5,
          themeModeKey: 'dark',
          analyticsConsentKey: true,
          'premium_offer_invitation_shown_v1': true,
        },
      );
      expect(prefs.getString(circleJournalKey), isNotNull);

      expect(
        tester.getSemantics(find.text('Delete Circle history')),
        isSemantics(
          label: 'Delete Circle history',
          isButton: true,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.text('Delete Circle history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();

      expect(prefs.getString(circleJournalKey), isNull);
      expect(prefs.getString(toolkitStateKey), 'toolkit-sentinel');
      expect(prefs.getBool(reminderEnabledKey), isTrue);
      expect(prefs.getInt(reminderHourKey), 18);
      expect(prefs.getInt(reminderMinuteKey), 5);
      expect(prefs.getString(themeModeKey), 'dark');
      expect(prefs.getBool(analyticsConsentKey), isTrue);
      expect(prefs.getBool('premium_offer_invitation_shown_v1'), isTrue);
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(container.read(analyticsConsentProvider), isTrue);
    });
  });

  group('About', () {
    testWidgets('THIRTY and the real ReleaseInfo version, one quiet node, '
        'no link or chevron', (tester) async {
      await _pump(tester, size: const Size(412, 3000));

      expect(find.text('About'), findsOneWidget);
      expect(find.text('Version ${ReleaseInfo.appVersion}'), findsOneWidget);
      final node = tester.getSemantics(find.text(YouAboutCard.versionLabel));
      expect(node.label, contains('THIRTY'));
      expect(node.label, contains(ReleaseInfo.appVersion));
      expect(node, isNot(isSemantics(hasTapAction: true)));
      expect(
        find.descendant(
          of: find.byType(YouAboutCard),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.textContaining('Privacy'), findsNothing);
      expect(find.textContaining('Support'), findsNothing);
    });
  });

  group('Restore purchases', () {
    testWidgets('a full-height (48dp) action, and its result is announced '
        'as a live region and brought on screen', (tester) async {
      await _pump(tester);
      await _scrollToEnd(tester);

      final restore = find.widgetWithText(TextButton, 'Restore purchases');
      expect(tester.getSize(restore).height, greaterThanOrEqualTo(48));
      await tester.tap(restore);
      await tester.pumpAndSettle();

      final message = find.text('No previous purchase was found to restore.');
      expect(message, findsOneWidget);
      expect(tester.getSemantics(message), isSemantics(isLiveRegion: true));
      expect(
        tester.getBottomLeft(message).dy,
        lessThanOrEqualTo(tester.view.physicalSize.height),
      );
    });
  });

  group('Responsive', () {
    for (final (label, size, scale) in [
      ('Pixel 7', const Size(412, 915), 1.0),
      ('Pixel 7 at 200%', const Size(412, 915), 2.0),
      ('360×740', const Size(360, 740), 1.0),
      ('360×740 at 200%', const Size(360, 740), 2.0),
    ]) {
      for (final (themeName, theme) in [
        ('light', AppTheme.light),
        ('dark', AppTheme.dark),
      ]) {
        for (final status in [
          EntitlementStatus.inactive,
          EntitlementStatus.active,
          EntitlementStatus.unavailable,
        ]) {
          testWidgets('$label, $themeName, ${status.name}: no overflow, '
              'nothing truncated, Restore reachable at the end', (
            tester,
          ) async {
            await _pump(
              tester,
              size: size,
              textScale: scale,
              theme: theme,
              status: status,
            );
            expect(tester.takeException(), isNull);
            expect(_truncated(tester), isEmpty);

            await _scrollToEnd(tester);
            expect(tester.takeException(), isNull);
            expect(_truncated(tester), isEmpty);
            final restore = find.text('Restore purchases');
            expect(restore, findsOneWidget);
            expect(
              tester.getBottomLeft(restore).dy,
              lessThanOrEqualTo(size.height),
            );
          });
        }
      }
    }

    testWidgets('dark mode: the destructive row keeps the dark AA errorText '
        'role', (tester) async {
      await _pump(
        tester,
        theme: AppTheme.dark,
        withJournal: true,
        size: const Size(412, 3000),
      );
      expect(
        tester.widget<Text>(find.text('Delete Circle history')).style!.color,
        AppColors.dark.errorText,
      );
    });
  });

  group('In the app shell', () {
    tearDown(() => appRouter.go('/'));

    for (final (label, size, scale) in [
      ('Pixel 7', const Size(412, 915), 1.0),
      ('360×740', const Size(360, 740), 1.0),
      ('360×740 at 200%', const Size(360, 740), 2.0),
    ]) {
      testWidgets('$label: scrolled to the end, Restore and its explanation '
          'sit fully above the floating nav', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        SharedPreferences.setMockInitialValues({firstNamePromptSeenKey: true});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            entitlementGatewayProvider.overrideWithValue(
              _FakeEntitlementGateway(),
            ),
            reminderGatewayProvider.overrideWithValue(_FakeReminderGateway()),
          ],
        );
        addTearDown(container.dispose);
        // As `main.dart` does at startup: Restore is hidden only while the
        // entitlement is still being checked.
        await container.read(entitlementStatusProvider.notifier).initialize();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const ThirtyApp(),
          ),
        );
        await tester.pumpAndSettle();
        appRouter.go('/settings');
        await tester.pumpAndSettle();

        await tester.drag(
          find.descendant(
            of: find.byType(SettingsPage),
            matching: find.byType(ListView),
          ),
          const Offset(0, -8000),
        );
        await tester.pumpAndSettle();

        final navTop = tester.getTopLeft(find.byType(FloatingNavSurface)).dy;
        final explanation = find.text(
          'Restores Premium access only. Your Circle history stays on this '
          'device.',
        );
        expect(
          tester.getBottomLeft(find.text('Restore purchases')).dy,
          lessThan(navTop),
        );
        expect(tester.getBottomLeft(explanation).dy, lessThan(navTop));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
