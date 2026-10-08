import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/reminder/local_notifications_reminder_gateway.dart';
import 'package:thirty/core/reminder/reminder_gateway.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/reminder/application/reminder_provider.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';

/// REMINDER-1 — a reminder still ahead today must not fire once today's
/// Circle is resolved, and the reminder must keep coming every day after
/// that without THIRTY being opened. Drives the real
/// [LocalNotificationsReminderGateway] from [ReminderNotifier] — no
/// Settings screen, no widget at all — against [_Device], a model of
/// THIRTY's native scheduler (`android/.../DailyReminder.kt`) and of the
/// notification shade. The native code itself is proven on a device.

const _schedulerChannel = MethodChannel('com.thirty.app/daily_reminder');
const _pluginChannel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);

/// `DailyReminder.kt`, step for step: one stored schedule (first eligible
/// date, time, content), one armed alarm, re-armed every time it fires.
class _Device {
  _Device(this.now);

  DateTime now;

  /// What `DailyReminder` persists — `null` once cancelled.
  ({DateTime firstDate, int hour, int minute, String title, String body})?
  stored;
  DateTime? armedAt;
  bool exactAlarmAccess = true;

  /// Every reminder shown, in order.
  final delivered = <(DateTime, String)>[];

  /// The shade: notification id → title. THIRTY only ever posts 7301.
  final shade = <int, String>{};

  /// Calls reaching the plugin's own scheduling — must stay empty.
  final pluginSchedules = <String>[];
  int pluginCancels = 0;

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  /// `DailyReminder.nextTrigger`.
  static DateTime nextTrigger(
    DateTime firstDate,
    int hour,
    int minute,
    DateTime now,
  ) {
    var date = firstDate.isAfter(_day(now)) ? firstDate : _day(now);
    while (true) {
      final trigger = DateTime(date.year, date.month, date.day, hour, minute);
      if (trigger.isAfter(now)) return trigger;
      date = DateTime(date.year, date.month, date.day + 1);
    }
  }

  /// `DailyReminder.arm` — also what a reboot, clock/timezone change or
  /// regained exact access runs.
  bool arm() {
    final schedule = stored;
    armedAt = null;
    if (schedule == null || !exactAlarmAccess) return false;
    armedAt = nextTrigger(
      schedule.firstDate,
      schedule.hour,
      schedule.minute,
      now,
    );
    return true;
  }

  Future<Object?> scheduler(MethodCall call) async {
    switch (call.method) {
      case 'schedule':
        final args = call.arguments as Map;
        stored = (
          firstDate: DateTime.parse(args['firstDate'] as String),
          hour: args['hour'] as int,
          minute: args['minute'] as int,
          title: args['title'] as String,
          body: args['body'] as String,
        );
        return arm() ? 'scheduled' : 'exactAlarmAccessDenied';
      case 'cancel':
        stored = null;
        armedAt = null;
        return null;
    }
    return null;
  }

  Future<Object?> plugin(MethodCall call) async {
    switch (call.method) {
      case 'initialize':
      case 'requestNotificationsPermission':
      case 'areNotificationsEnabled':
        return true;
      case 'canScheduleExactNotifications':
        return exactAlarmAccess;
      case 'cancel':
        pluginCancels++;
        return null;
      case 'zonedSchedule':
      case 'periodicallyShow':
      case 'periodicallyShowWithDuration':
        pluginSchedules.add(call.method);
        return null;
    }
    return null;
  }

  /// The device clock runs to [until] with THIRTY closed; each alarm due
  /// on the way goes through `DailyReminder.onAlarm`.
  void runUntil(DateTime until) {
    while (armedAt != null && !armedAt!.isAfter(until)) {
      final firedAt = armedAt!;
      final schedule = stored!;
      now = firedAt;
      delivered.add((firedAt, schedule.title));
      shade[7301] = schedule.title;
      stored = (
        firstDate: DateTime(firedAt.year, firedAt.month, firedAt.day + 1),
        hour: schedule.hour,
        minute: schedule.minute,
        title: schedule.title,
        body: schedule.body,
      );
      arm();
    }
    now = until;
  }

  /// Android drops every alarm on reboot; the re-arm receiver restores it.
  void rebootAt(DateTime at) {
    armedAt = null;
    now = at;
    arm();
  }
}

// Far enough ahead of the real clock that no check against it can trip.
final _morning = DateTime(2030, 9, 2, 9, 0);
final _todayAt8pm = DateTime(2030, 9, 2, 20, 0);
final _tomorrowAt8pm = DateTime(2030, 9, 3, 20, 0);
DateTime _sept(int day, [int hour = 20, int minute = 0]) =>
    DateTime(2030, 9, day, hour, minute);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Device device;
  late SharedPreferences prefs;

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    device = _Device(_morning);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_schedulerChannel, device.scheduler);
    messenger.setMockMethodCallHandler(_pluginChannel, device.plugin);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_schedulerChannel, null);
    messenger.setMockMethodCallHandler(_pluginChannel, null);
  });

  /// THIRTY launching at the device's current time — the same startup
  /// path as `main.dart` (`ReminderNotifier.initialize`). Disposing the
  /// container is the process dying: only the native schedule remains.
  Future<ProviderContainer> launch() async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        reminderGatewayProvider.overrideWithValue(
          LocalNotificationsReminderGateway(),
        ),
        nowProvider.overrideWithValue(device.now),
        eventClockProvider.overrideWithValue(() => device.now),
      ],
    );
    addTearDown(container.dispose);
    await container.read(reminderProvider.notifier).initialize();
    return container;
  }

  Future<void> startAndClose(ProviderContainer container) async {
    final circle = container.read(recommendationProvider.notifier);
    circle.chooseIntention(Intention.gentlerPace);
    circle.start();
    await pumpEventQueue();
    circle.close();
    await pumpEventQueue();
  }

  Future<ProviderContainer> closedWithReminderAt8pm() async {
    final container = await launch();
    await container.read(reminderProvider.notifier).enable(hour: 20, minute: 0);
    expect(device.armedAt, _todayAt8pm);
    await startAndClose(container);
    return container;
  }

  Iterable<DateTime> deliveredTimes() => device.delivered.map((d) => d.$1);

  test(
    'A — not started: today\'s reminder stays, then comes every day',
    () async {
      final container = await launch();
      await container
          .read(reminderProvider.notifier)
          .enable(hour: 20, minute: 0);
      expect(device.armedAt, _todayAt8pm);

      container.dispose();
      device.runUntil(_sept(4, 21));

      expect(deliveredTimes(), [_todayAt8pm, _tomorrowAt8pm, _sept(4)]);
    },
  );

  test('C — closing today\'s Circle moves a reminder still ahead today to '
      'tomorrow, with no Settings screen anywhere', () async {
    await closedWithReminderAt8pm();

    expect(device.armedAt, _tomorrowAt8pm);
  });

  test('B/E — starting alone already skips today, and reflecting after '
      'Close never brings today back', () async {
    final container = await launch();
    await container.read(reminderProvider.notifier).enable(hour: 20, minute: 0);
    final circle = container.read(recommendationProvider.notifier);
    circle.chooseIntention(Intention.gentlerPace);
    circle.start();
    await pumpEventQueue();
    expect(device.armedAt, _tomorrowAt8pm);

    circle.close();
    await pumpEventQueue();
    circle.reportAttempt(CircleAttemptResponse.aLittle);
    await pumpEventQueue();
    circle.reportUsefulness(CircleUsefulnessResponse.veryUseful);
    await pumpEventQueue();

    expect(device.armedAt, _tomorrowAt8pm);
  });

  test('the original time passes silently; tomorrow\'s reminder is '
      'delivered once', () async {
    await closedWithReminderAt8pm();

    device.runUntil(_sept(2, 23, 59));
    expect(device.delivered, isEmpty);

    device.runUntil(_sept(3, 20, 1));
    expect(deliveredTimes(), [_tomorrowAt8pm]);
  });

  test('no app reopen for several days: after Close, every following day '
      'still gets its reminder — none skipped, none twice', () async {
    final container = await closedWithReminderAt8pm();
    // Killed after Close and never opened again.
    container.dispose();

    device.runUntil(_sept(2, 23, 59));
    expect(device.delivered, isEmpty);
    device.runUntil(_sept(3, 23, 59));
    expect(deliveredTimes(), [_sept(3)]);
    device.runUntil(_sept(4, 23, 59));
    expect(deliveredTimes(), [_sept(3), _sept(4)]);
    device.runUntil(_sept(5, 23, 59));
    expect(deliveredTimes(), [_sept(3), _sept(4), _sept(5)]);
    expect(device.armedAt, _sept(6));
  });

  test(
    'ignored reminders never pile up: each day\'s replaces the last',
    () async {
      final container = await closedWithReminderAt8pm();
      container.dispose();

      device.runUntil(_sept(6, 21));

      expect(device.delivered, hasLength(4));
      expect(device.shade, hasLength(1));
    },
  );

  test('D — a time changed after Close still skips today, then repeats '
      'daily at the new time', () async {
    final container = await closedWithReminderAt8pm();

    await container
        .read(reminderProvider.notifier)
        .setTime(hour: 21, minute: 30);
    expect(device.armedAt, _sept(3, 21, 30));

    container.dispose();
    device.runUntil(_sept(4, 23));
    expect(deliveredTimes(), [_sept(3, 21, 30), _sept(4, 21, 30)]);
  });

  test('D — disabling leaves nothing scheduled; re-enabling after Close '
      'skips today', () async {
    final container = await closedWithReminderAt8pm();
    final reminder = container.read(reminderProvider.notifier);

    await reminder.disable();
    expect(device.armedAt, isNull);
    expect(device.stored, isNull);
    device.rebootAt(_sept(2, 12));
    expect(device.armedAt, isNull);

    await reminder.enable(hour: 20, minute: 0);
    expect(device.armedAt, _tomorrowAt8pm);
  });

  test('disabled, the reminder stays silent for days', () async {
    final container = await launch();
    final reminder = container.read(reminderProvider.notifier);
    await reminder.enable(hour: 20, minute: 0);
    await reminder.disable();
    container.dispose();

    device.runUntil(_sept(5, 23));

    expect(device.delivered, isEmpty);
  });

  test('a rename after Close updates the greeting and still skips '
      'today', () async {
    final container = await closedWithReminderAt8pm();

    await container.read(firstNameProvider.notifier).setFirstName('Thomas');
    await pumpEventQueue();

    expect(device.armedAt, _tomorrowAt8pm);
    container.dispose();
    device.runUntil(_sept(4, 21));
    expect(device.delivered.map((d) => d.$2), [
      'Good evening, Thomas.',
      'Good evening, Thomas.',
    ]);
  });

  test('F/G — killed after Close and relaunched later the same day: '
      'today stays skipped', () async {
    final container = await closedWithReminderAt8pm();
    container.dispose();

    device.now = _sept(2, 13);
    await launch();

    expect(device.armedAt, _tomorrowAt8pm);
  });

  test('H — a reboot after Close keeps today skipped and the days after '
      'covered, before THIRTY is ever opened again', () async {
    final container = await closedWithReminderAt8pm();
    container.dispose();

    device.rebootAt(_sept(2, 15));
    expect(device.armedAt, _tomorrowAt8pm);

    device.runUntil(_sept(4, 21));
    expect(deliveredTimes(), [_sept(3), _sept(4)]);
  });

  test('a phone off through reminder time never delivers it late; the '
      'next day\'s still comes', () async {
    final container = await closedWithReminderAt8pm();
    container.dispose();

    // Off from before 20:00 on the 3rd until the next morning.
    device.rebootAt(_sept(4, 8));

    expect(device.armedAt, _sept(4));
    device.runUntil(_sept(4, 21));
    expect(deliveredTimes(), [_sept(4)]);
  });

  test('the next day, opening THIRTY before reminder time keeps that '
      'day\'s reminder', () async {
    final container = await closedWithReminderAt8pm();
    container.dispose();

    device.now = _sept(3, 7);
    await launch();

    expect(device.armedAt, _tomorrowAt8pm);
  });

  test('a reminder time already past today stays daily after Close', () async {
    device.now = _sept(2, 21);
    final container = await launch();
    await container.read(reminderProvider.notifier).enable(hour: 20, minute: 0);
    await startAndClose(container);

    expect(device.armedAt, _tomorrowAt8pm);
    container.dispose();
    device.runUntil(_sept(4, 21));
    expect(deliveredTimes(), [_sept(3), _sept(4)]);
  });

  test('without exact-alarm access nothing is armed — never an inexact '
      'fallback', () async {
    device.exactAlarmAccess = false;
    final container = await launch();
    await container.read(reminderProvider.notifier).enable(hour: 20, minute: 0);

    expect(device.armedAt, isNull);
    expect(container.read(reminderProvider).exactAlarmAccessGranted, isFalse);
  });

  test('the plugin\'s own repeating schedule — the source of the stale '
      'reminder — is never used, and an alarm it armed in an earlier '
      'version is retired', () async {
    final container = await closedWithReminderAt8pm();
    await container.read(reminderProvider.notifier).disable();

    expect(device.pluginSchedules, isEmpty);
    expect(device.pluginCancels, greaterThan(0));
  });
}
