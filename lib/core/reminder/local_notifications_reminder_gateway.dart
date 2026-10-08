import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'reminder_gateway.dart';

/// The real local-notification adapter. `flutter_local_notifications`
/// handles the notification permission and Android's exact-alarm special
/// access; the reminder itself is THIRTY's own native scheduler
/// (`DailyReminder.kt`, REMINDER-1).
///
/// The plugin's daily repeat (`DateTimeComponents.time`) always restarts
/// from the next matching time after *now* — it cannot begin on a later
/// day, so a reminder skipped because today's Circle is already resolved
/// came straight back. The native scheduler keeps one exact alarm armed
/// for the next eligible day and re-arms itself each time it fires, after
/// a reboot, and on a clock or timezone change — reminders continue daily
/// without THIRTY being opened, always at the chosen wall-clock time in
/// the device's current timezone.
///
/// Scheduling is always exact-while-idle, never inexact — a physical
/// Samsung SM-S931B reproduced a correctly `inexactAllowWhileIdle`-
/// scheduled 18:05 reminder twice actually delivered ~03:48 the next
/// local day. Without granted access, [scheduleDaily] returns
/// [ScheduleOutcome.exactAlarmAccessDenied] and nothing is armed — never
/// a silent inexact fallback.
class LocalNotificationsReminderGateway implements ReminderGateway {
  static const _notificationId = 7301;
  static const _scheduler = MethodChannel('com.thirty.app/daily_reminder');

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          // The one-colour THIRTY Circle — Android tints a notification's
          // small icon, so it must be a silhouette, not the launcher art.
          android: AndroidInitializationSettings('@drawable/ic_stat_thirty'),
        ),
        // Tapping the notification simply opens THIRTY to its current
        // canonical state (the OS's normal "launch app" behavior) — no
        // payload-driven navigation or state mutation happens here, so a
        // stale tap can never resolve or fabricate an activity.
        onDidReceiveNotificationResponse: (_) {},
      );
      _initialized = true;
    } catch (_) {
      // Never throws — a failed setup simply means reminders won't fire;
      // the rest of the app must be unaffected.
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasPermission() async {
    try {
      final enabled = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      return enabled ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasExactAlarmAccess() async {
    try {
      final canSchedule = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.canScheduleExactNotifications();
      return canSchedule ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> requestExactAlarmAccess() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestExactAlarmsPermission();
    } catch (_) {
      // Never throws — if the platform special-access screen can't be
      // reached, the caller's next hasExactAlarmAccess() check simply
      // stays false; nothing here is allowed to crash the app.
    }
  }

  @override
  Future<ScheduleOutcome> scheduleDaily({
    required DateTime firstOccurrenceLocal,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    // Independently fail closed here — never rely solely on the caller
    // having already checked this.
    if (!await hasExactAlarmAccess()) {
      return ScheduleOutcome.exactAlarmAccessDenied;
    }

    try {
      await _retirePluginAlarm();
      final outcome = await _scheduler.invokeMethod<String>('schedule', {
        'firstDate': _isoDate(firstOccurrenceLocal),
        'hour': hour,
        'minute': minute,
        'title': title,
        'body': body,
      });
      return switch (outcome) {
        'scheduled' => ScheduleOutcome.scheduled,
        'exactAlarmAccessDenied' => ScheduleOutcome.exactAlarmAccessDenied,
        _ => ScheduleOutcome.failed,
      };
    } catch (_) {
      return ScheduleOutcome.failed;
    }
  }

  @override
  Future<void> cancel() async {
    await _retirePluginAlarm();
    try {
      await _scheduler.invokeMethod<void>('cancel');
    } catch (_) {
      // Never throws.
    }
  }

  /// Earlier versions armed the reminder through the plugin's own daily
  /// repeat under this same id — it must never fire alongside the native
  /// schedule.
  Future<void> _retirePluginAlarm() async {
    try {
      await _plugin.cancel(id: _notificationId);
    } catch (_) {
      // Never throws.
    }
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
