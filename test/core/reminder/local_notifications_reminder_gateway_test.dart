import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:thirty/core/reminder/local_notifications_reminder_gateway.dart';
import 'package:thirty/core/reminder/reminder_gateway.dart';

const _timezoneChannel = MethodChannel('flutter_timezone');
const _notificationsChannel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);

/// Mocks the `flutter_timezone` platform channel to return [identifier],
/// or to fail entirely if [identifier] is null — deterministic, no real
/// device required (Flutter's own supported platform-channel mocking).
void _mockTimezoneChannel(String? identifier) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_timezoneChannel, (call) async {
        if (identifier == null) {
          throw PlatformException(code: 'UNAVAILABLE');
        }
        return {'identifier': identifier};
      });
}

/// Mocks the `flutter_local_notifications` platform channel with generic
/// successful responses — this test targets timezone *resolution*
/// correctness, not the notification plugin's own native behavior (real
/// delivery/permission-dialog/boot-survival proof requires a real
/// device — see REAL DEVICE TEST REQUIRED items in the reconciliation
/// report).
void _mockNotificationsChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_notificationsChannel, (call) async {
        switch (call.method) {
          case 'initialize':
          case 'requestNotificationsPermission':
          case 'areNotificationsEnabled':
            return true;
          default:
            return null;
        }
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // The plugin branches internally on `defaultTargetPlatform` to decide
    // which platform channel implementation to resolve — without this,
    // it resolves none on the host OS this test suite actually runs on.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_timezoneChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, null);
  });

  group('timezone package DST correctness (no platform channel needed) — '
      'DETERMINISTIC TEST', () {
    setUpAll(tzdata.initializeTimeZones);

    test(
      'the component TZDateTime constructor preserves the same local '
      'wall-clock hour across a US spring-forward transition '
      '(America/New_York, 2026-03-08)',
      () {
        final newYork = tz.getLocation('America/New_York');
        final before = tz.TZDateTime(newYork, 2026, 3, 7, 8, 0);
        final after = tz.TZDateTime(newYork, 2026, 3, 9, 8, 0);

        expect(before.hour, 8);
        expect(after.hour, 8);
        // The wall-clock hour is identical, but the UTC offset changed —
        // proof this is genuinely DST-aware, not a fixed-offset shortcut.
        expect(before.timeZoneOffset, isNot(after.timeZoneOffset));
      },
    );

    test(
      'preserves the same local wall-clock hour across a US fall-back '
      'transition (America/New_York, 2026-11-01)',
      () {
        final newYork = tz.getLocation('America/New_York');
        final before = tz.TZDateTime(newYork, 2026, 10, 31, 20, 0);
        final after = tz.TZDateTime(newYork, 2026, 11, 2, 20, 0);

        expect(before.hour, 20);
        expect(after.hour, 20);
        expect(before.timeZoneOffset, isNot(after.timeZoneOffset));
      },
    );

    test(
      'the same wall-clock reminder time resolves to a different '
      'absolute instant in a different timezone — proof scheduling is '
      'genuinely location-sensitive, not anchored to a fixed zone',
      () {
        final berlin = tz.getLocation('Europe/Berlin');
        final losAngeles = tz.getLocation('America/Los_Angeles');
        final inBerlin = tz.TZDateTime(berlin, 2026, 6, 1, 8, 0);
        final inLosAngeles = tz.TZDateTime(losAngeles, 2026, 6, 1, 8, 0);

        expect(inBerlin.hour, 8);
        expect(inLosAngeles.hour, 8);
        expect(
          inBerlin.millisecondsSinceEpoch,
          isNot(inLosAngeles.millisecondsSinceEpoch),
        );
      },
    );
  });

  group('LocalNotificationsReminderGateway (mocked platform channels) — '
      'DETERMINISTIC TEST for resolution logic; REAL DEVICE TEST '
      'REQUIRED for actual delivery', () {
    test(
      'resolving a named timezone lets scheduling proceed past timezone '
      'resolution — never throws even though this environment cannot '
      'fully emulate the notification plugin\'s native serialization '
      '(REAL DEVICE TEST REQUIRED to confirm the resulting outcome is '
      'exactly `scheduled`)',
      () async {
        _mockTimezoneChannel('Europe/Berlin');
        _mockNotificationsChannel();
        final gateway = LocalNotificationsReminderGateway();
        await gateway.initialize();

        final outcome = await gateway.scheduleDaily(
          firstOccurrenceLocal: DateTime(2026, 9, 2, 20, 0),
          hour: 20,
          minute: 0,
        );

        // Timezone resolution succeeded — the outcome is never
        // `timezoneUnavailable` here, whatever the mocked notification
        // plugin's own response resolves to.
        expect(outcome, isNot(ScheduleOutcome.timezoneUnavailable));
      },
    );

    test(
      'never falls back to a wrong timezone — returns '
      'timezoneUnavailable and schedules nothing when the device '
      'timezone cannot be resolved',
      () async {
        _mockTimezoneChannel(null);
        _mockNotificationsChannel();
        final gateway = LocalNotificationsReminderGateway();
        await gateway.initialize();

        final outcome = await gateway.scheduleDaily(
          firstOccurrenceLocal: DateTime(2026, 9, 2, 20, 0),
          hour: 20,
          minute: 0,
        );

        expect(outcome, ScheduleOutcome.timezoneUnavailable);
      },
    );

    test('cancel() never throws even without a prior schedule', () async {
      _mockNotificationsChannel();
      final gateway = LocalNotificationsReminderGateway();

      await expectLater(gateway.cancel(), completes);
    });

    test(
      'requestPermission()/hasPermission() never throw even when the '
      'platform-specific implementation cannot be resolved in this '
      'environment (REAL DEVICE TEST REQUIRED to confirm the actual '
      'Android 13+ permission dialog and its true/false result)',
      () async {
        _mockNotificationsChannel();
        final gateway = LocalNotificationsReminderGateway();
        await gateway.initialize();

        await expectLater(gateway.requestPermission(), completes);
        await expectLater(gateway.hasPermission(), completes);
      },
    );
  });
}
