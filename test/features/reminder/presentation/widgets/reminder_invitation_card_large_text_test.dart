import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/reminder/reminder_gateway.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/home_invitation_slot.dart';
import 'package:thirty/features/reminder/application/reminder_provider.dart';
import 'package:thirty/features/reminder/presentation/widgets/reminder_invitation_card.dart';

/// The reminder invitation's two actions with the app's real fonts: side
/// by side whenever both labels fit, stacked (same order) when large text
/// would otherwise truncate one.

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
  }) async => ScheduleOutcome.scheduled;
  @override
  Future<void> cancel() async {}
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

final _today = DateTime(2026, 9, 2, 9);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required double width,
  required double textScale,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final journal = CircleJournalRepository(prefs);
  await journal.recordShown(
    circleId: '2026-09-01',
    localDate: '2026-09-01',
    direction: Intention.moreEnergy,
    activityId: ActivityId.thirtyMinuteWalk,
    shownAt: DateTime(2026, 9, 1, 8),
  );
  await journal.recordClosed(
    circleId: '2026-09-01',
    localDate: '2026-09-01',
    direction: Intention.moreEnergy,
    activityId: ActivityId.thirtyMinuteWalk,
    closedAt: DateTime(2026, 9, 1, 8, 30),
  );

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      reminderGatewayProvider.overrideWithValue(_FakeReminderGateway()),
      nowProvider.overrideWithValue(_today),
      eventClockProvider.overrideWithValue(() => _today),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 900),
            textScaler: TextScaler.linear(textScale),
          ),
          child: const Scaffold(
            body: SingleChildScrollView(child: ReminderInvitationCard()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

Finder get _choose => find.widgetWithText(ThirtyButton, 'Choose a time');
Finder get _notNow => find.widgetWithText(ThirtyButton, 'Not now');

void _expectNoTruncation(WidgetTester tester) {
  for (final (button, text) in [
    (_choose, 'Choose a time'),
    (_notNow, 'Not now'),
  ]) {
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: button, matching: find.text(text)),
    );
    expect(paragraph.didExceedMaxLines, isFalse, reason: text);
  }
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(() async {
    await _loadFont('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ]);
  });

  group('100% text: side by side, unchanged', () {
    for (final width in [320.0, 360.0, 412.0]) {
      testWidgets('${width.toInt()}pt', (tester) async {
        await _pump(tester, width: width, textScale: 1.0);

        final choose = tester.getRect(_choose);
        final notNow = tester.getRect(_notNow);
        expect(choose.top, notNow.top);
        expect(choose.right, lessThan(notNow.left));
        expect(choose.width, closeTo(notNow.width, 0.01));
        expect(choose.height, notNow.height);
        // At 412pt both labels fit on one line: exactly 48pt. At 320/360pt
        // the half-width "Choose a time" (~100pt of text in 88pt) takes two
        // lines even at 100% — side by side still, nothing cut off (before
        // the large-text foundation it was ellipsized here).
        if (width >= 412) expect(choose.height, 48);
        _expectNoTruncation(tester);
      });
    }
  });

  group('200% text: stacked when the pair would truncate', () {
    for (final width in [320.0, 360.0]) {
      testWidgets('${width.toInt()}pt: stacked, same order, full width, '
          'nothing cut off', (tester) async {
        await _pump(tester, width: width, textScale: 2.0);

        final choose = tester.getRect(_choose);
        final notNow = tester.getRect(_notNow);
        expect(choose.bottom, lessThan(notNow.top), reason: 'order kept');
        expect(choose.left, notNow.left);
        expect(choose.width, notNow.width);
        _expectNoTruncation(tester);

        expect(tester.getSemantics(_choose).label, 'Choose a time');
        expect(tester.getSemantics(_notNow).label, 'Not now');
      });

      testWidgets('${width.toInt()}pt: "Not now" still closes the '
          'invitation for the session', (tester) async {
        final container = await _pump(tester, width: width, textScale: 2.0);

        await tester.ensureVisible(_notNow);
        await tester.tap(_notNow);
        await tester.pump();

        expect(find.text('Not now'), findsNothing);
        expect(container.read(homeInvitationSlotProvider), (
          owner: HomeInvitation.reminder,
          closed: true,
        ));
      });

      testWidgets('${width.toInt()}pt: "Choose a time" still opens the time '
          'picker and enables the reminder', (tester) async {
        final container = await _pump(tester, width: width, textScale: 2.0);

        await tester.ensureVisible(_choose);
        await tester.tap(_choose);
        await tester.pumpAndSettle();
        expect(find.byType(TimePickerDialog), findsOneWidget);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(container.read(reminderProvider).enabled, isTrue);
        expect(find.text('Choose a time'), findsNothing);
      });
    }
  });
}
