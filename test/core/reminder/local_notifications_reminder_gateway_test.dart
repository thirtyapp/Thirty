import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/reminder/local_notifications_reminder_gateway.dart';
import 'package:thirty/core/reminder/reminder_gateway.dart';

const _schedulerChannel = MethodChannel('com.thirty.app/daily_reminder');
const _notificationsChannel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);

/// Every call reaching THIRTY's native scheduler (`DailyReminder.kt`).
final List<MethodCall> _schedulerCalls = [];

/// Every call reaching the plugin's own scheduling or cancellation.
final List<MethodCall> _pluginCalls = [];

/// Mocks THIRTY's native scheduler, answering `schedule` with
/// [scheduleResult] (thrown, if it is an exception).
void _mockScheduler({Object? scheduleResult = 'scheduled'}) {
  _schedulerCalls.clear();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_schedulerChannel, (call) async {
        _schedulerCalls.add(call);
        if (call.method == 'schedule') {
          if (scheduleResult is Exception) throw scheduleResult;
          return scheduleResult;
        }
        return null;
      });
}

/// Mocks the `flutter_local_notifications` platform channel with generic
/// successful responses. [exactAlarmAccess] controls the mocked response
/// for `canScheduleExactNotifications` (default: granted).
void _mockNotificationsChannel({bool exactAlarmAccess = true}) {
  _pluginCalls.clear();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_notificationsChannel, (call) async {
        switch (call.method) {
          case 'initialize':
          case 'requestNotificationsPermission':
          case 'areNotificationsEnabled':
          case 'requestExactAlarmsPermission':
            return true;
          case 'canScheduleExactNotifications':
            return exactAlarmAccess;
          case 'cancel':
          case 'zonedSchedule':
          case 'periodicallyShow':
          case 'periodicallyShowWithDuration':
            _pluginCalls.add(call);
            return null;
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
    // `resolvePlatformSpecificImplementation` also requires
    // `FlutterLocalNotificationsPlatform.instance` to actually be an
    // `AndroidFlutterLocalNotificationsPlugin` — normally wired by the
    // real Android embedding's generated plugin registrant at app
    // startup, which never runs in a plain `flutter test` (Dart VM, no
    // platform embedding). Registering it explicitly here is exactly
    // what that startup path does, and is what lets the mocked method
    // channel responses above actually reach the gateway under test.
    AndroidFlutterLocalNotificationsPlugin.registerWith();
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_schedulerChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, null);
  });

  group('LocalNotificationsReminderGateway (mocked platform channels) — '
      'REAL DEVICE TEST REQUIRED for actual delivery', () {
    Future<ScheduleOutcome> scheduleEightPm(
      LocalNotificationsReminderGateway gateway, {
      String title = 'Good evening.',
    }) => gateway.scheduleDaily(
      firstOccurrenceLocal: DateTime(2026, 9, 3, 20, 0),
      hour: 20,
      minute: 0,
      title: title,
      body: "Your Circle is here when you're ready.",
    );

    test('hands the whole schedule to THIRTY\'s native scheduler: first '
        'eligible date, time and the caller\'s exact title and body', () async {
      _mockScheduler();
      _mockNotificationsChannel();
      final gateway = LocalNotificationsReminderGateway();
      await gateway.initialize();

      final outcome = await scheduleEightPm(
        gateway,
        title: 'Good evening, Thomas.',
      );

      expect(outcome, ScheduleOutcome.scheduled);
      final schedule = _schedulerCalls.single;
      expect(schedule.method, 'schedule');
      expect(schedule.arguments, {
        'firstDate': '2026-09-03',
        'hour': 20,
        'minute': 0,
        'title': 'Good evening, Thomas.',
        'body': "Your Circle is here when you're ready.",
      });
    });

    test('never schedules through the plugin\'s own repeat, and retires '
        'the alarm earlier versions armed with it', () async {
      _mockScheduler();
      _mockNotificationsChannel();
      final gateway = LocalNotificationsReminderGateway();
      await gateway.initialize();

      await scheduleEightPm(gateway);

      expect(_pluginCalls.map((call) => call.method), ['cancel']);
      expect((_pluginCalls.single.arguments as Map)['id'], 7301);
    });

    test('schedules nothing — never a silent inexact fallback — when '
        'exact-alarm access is not granted', () async {
      _mockScheduler();
      _mockNotificationsChannel(exactAlarmAccess: false);
      final gateway = LocalNotificationsReminderGateway();
      await gateway.initialize();

      final outcome = await scheduleEightPm(gateway);

      expect(outcome, ScheduleOutcome.exactAlarmAccessDenied);
      expect(_schedulerCalls, isEmpty);
    });

    test('reports the native scheduler\'s own refusal truthfully, and a '
        'failure as failed — never throws', () async {
      _mockNotificationsChannel();
      final gateway = LocalNotificationsReminderGateway();
      await gateway.initialize();

      _mockScheduler(scheduleResult: 'exactAlarmAccessDenied');
      expect(
        await scheduleEightPm(gateway),
        ScheduleOutcome.exactAlarmAccessDenied,
      );

      _mockScheduler(scheduleResult: PlatformException(code: 'boom'));
      expect(await scheduleEightPm(gateway), ScheduleOutcome.failed);
    });

    test('cancel() clears the native schedule and the plugin\'s legacy '
        'alarm, and never throws', () async {
      _mockScheduler();
      _mockNotificationsChannel();
      final gateway = LocalNotificationsReminderGateway();

      await expectLater(gateway.cancel(), completes);

      expect(_schedulerCalls.map((call) => call.method), ['cancel']);
      expect(_pluginCalls.map((call) => call.method), ['cancel']);
    });

    test(
      'requestPermission()/hasPermission() never throw (REAL DEVICE TEST '
      'REQUIRED to confirm the actual Android 13+ permission dialog)',
      () async {
        _mockNotificationsChannel();
        final gateway = LocalNotificationsReminderGateway();
        await gateway.initialize();

        await expectLater(gateway.requestPermission(), completes);
        await expectLater(gateway.hasPermission(), completes);
      },
    );

    test('hasExactAlarmAccess() reflects canScheduleExactNotifications() '
        'truthfully in both directions', () async {
      _mockNotificationsChannel(exactAlarmAccess: true);
      final grantedGateway = LocalNotificationsReminderGateway();
      await grantedGateway.initialize();
      expect(await grantedGateway.hasExactAlarmAccess(), isTrue);

      _mockNotificationsChannel(exactAlarmAccess: false);
      final deniedGateway = LocalNotificationsReminderGateway();
      await deniedGateway.initialize();
      expect(await deniedGateway.hasExactAlarmAccess(), isFalse);
      await expectLater(deniedGateway.requestExactAlarmAccess(), completes);
    });
  });
}
