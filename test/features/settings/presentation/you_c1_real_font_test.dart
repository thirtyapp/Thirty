import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/providers/theme_mode_provider.dart';
import 'package:thirty/core/reminder/reminder_gateway.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/settings/presentation/settings_page.dart';

/// Phase C1 — You with the app's real fonts loaded: every billing state at
/// 320 / 360pt and 200% text, light and dark, with nothing truncated and
/// nothing overflowing; and the adaptive theme control.

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
  _FakeEntitlementGateway(this.status);

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

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required double textScale,
  EntitlementStatus status = EntitlementStatus.inactive,
  ThemeData? theme,
  bool initialize = true,
}) async {
  tester.view.physicalSize = Size(width, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await CircleJournalRepository(prefs).recordShown(
    circleId: '2026-08-01',
    localDate: '2026-08-01',
    direction: Intention.moreEnergy,
    activityId: ActivityId.thirtyMinuteWalk,
    shownAt: DateTime(2026, 8, 1, 9),
  );
  final container = ProviderContainer(
    overrides: [
      entitlementGatewayProvider.overrideWithValue(
        _FakeEntitlementGateway(status),
      ),
      sharedPreferencesProvider.overrideWithValue(prefs),
      reminderGatewayProvider.overrideWithValue(_FakeReminderGateway()),
    ],
  );
  addTearDown(container.dispose);
  if (initialize) {
    await container.read(entitlementStatusProvider.notifier).initialize();
  }
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
}

/// Every paragraph on You that was cut short (ellipsized / over its line
/// limit), by text.
List<String> _truncated(WidgetTester tester) => [
  for (final element in find.byType(RichText).evaluate())
    if ((element.renderObject! as RenderParagraph).didExceedMaxLines)
      (element.renderObject! as RenderParagraph).text.toPlainText(),
];

int _lines(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  return paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: text.length),
      )
      .map((box) => box.top)
      .toSet()
      .length;
}

void main() {
  setUpAll(() async {
    await _loadFont('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ]);
  });

  group('200% text, every billing state', () {
    for (final width in [320.0, 360.0]) {
      for (final (label, status, initialize) in [
        ('checking', EntitlementStatus.inactive, false),
        ('free', EntitlementStatus.inactive, true),
        ('active', EntitlementStatus.active, true),
        ('unavailable', EntitlementStatus.unavailable, true),
      ]) {
        for (final (themeName, theme) in [
          ('light', AppTheme.light),
          ('dark', AppTheme.dark),
        ]) {
          testWidgets('${width.toInt()}pt, $label, $themeName: nothing '
              'truncated, nothing overflows', (tester) async {
            await _pump(
              tester,
              width: width,
              textScale: 2.0,
              status: status,
              theme: theme,
              initialize: initialize,
            );
            expect(tester.takeException(), isNull);
            expect(_truncated(tester), isEmpty);
            for (final button in tester.widgetList<ThirtyButton>(
              find.byType(ThirtyButton),
            )) {
              expect(_lines(tester, button.label), lessThanOrEqualTo(2));
            }
            // The theme choice is stacked, one line per option.
            expect(find.byType(SegmentedButton<ThemeMode>), findsNothing);
            for (final option in ['System', 'Light', 'Dark']) {
              expect(_lines(tester, option), 1, reason: option);
            }
          });
        }
      }
    }
  });

  group('Theme choice at 100% text', () {
    // Measured with the real SegmentedButton inside the Preferences card
    // (24pt inset): "System" wraps at every phone width from 360 to 412pt
    // (segments 88-105pt), so phones get the stacked rows.
    for (final width in [360.0, 412.0]) {
      testWidgets('${width.toInt()}pt: stacked rows, where the segmented '
          'control would split "System" across two lines', (tester) async {
        await _pump(tester, width: width, textScale: 1.0);
        expect(find.byType(SegmentedButton<ThemeMode>), findsNothing);
        for (final option in ['System', 'Light', 'Dark']) {
          expect(_lines(tester, option), 1, reason: option);
        }
        expect(_truncated(tester), isEmpty);
      });
    }

    testWidgets('a wide screen keeps the segmented control, every label on '
        'one line', (tester) async {
      await _pump(tester, width: 600, textScale: 1.0);
      expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
      for (final option in ['System', 'Light', 'Dark']) {
        expect(_lines(tester, option), 1, reason: option);
      }
      expect(_truncated(tester), isEmpty);
    });

    testWidgets('stacked rows keep single-choice semantics and still set the '
        'theme', (tester) async {
      await _pump(tester, width: 320, textScale: 2.0);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsPage)),
      );

      final dark = tester.getSemantics(find.text('Dark'));
      expect(dark.flagsCollection.isInMutuallyExclusiveGroup, isTrue);

      await tester.ensureVisible(find.text('Dark'));
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(
        find.descendant(
          of: find.ancestor(of: find.text('Dark'), matching: find.byType(Row)),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
    });
  });
}
