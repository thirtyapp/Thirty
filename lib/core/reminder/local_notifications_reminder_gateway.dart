import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_gateway.dart';

/// The real local-notification adapter — `flutter_local_notifications`,
/// `timezone` and `flutter_timezone` (the three packages approved for
/// THIRTY's optional local reminder — Step 5 local closure).
///
/// Every schedule call resolves the device's actual current IANA
/// timezone via [FlutterTimezone.getLocalTimezone] and schedules against
/// that named [tz.Location] — never against [tz.UTC] — so the user's
/// chosen wall-clock time (e.g. "8:00 PM") is preserved correctly across
/// a DST transition, not just the fixed instant it happened to be
/// computed at. Resolving fresh on every call (rather than caching a
/// location at [initialize] time) is also how a genuine timezone change
/// (the user travels, or changes their device clock) gets picked up —
/// `ReminderNotifier` already reschedules on every app resume.
///
/// If the device's timezone cannot be resolved, [scheduleDaily] returns
/// [ScheduleOutcome.timezoneUnavailable] and schedules nothing — it never
/// falls back to [tz.UTC] or any other assumed zone, because a reminder
/// silently scheduled against the wrong timezone is a truthfulness
/// defect, not an acceptable degradation.
///
/// Scheduling always uses [AndroidScheduleMode.exactAllowWhileIdle] (never
/// `inexactAllowWhileIdle`) — a physical Samsung SM-S931B reproduced a
/// correctly `inexactAllowWhileIdle`-scheduled 18:05 reminder twice
/// actually delivered ~03:48 the next local day, i.e. Doze deferring it
/// hours past its intended calendar day. [hasExactAlarmAccess] and
/// [requestExactAlarmAccess] gate this: without granted access,
/// [scheduleDaily] returns [ScheduleOutcome.exactAlarmAccessDenied] and
/// schedules nothing — never a silent inexact fallback.
class LocalNotificationsReminderGateway implements ReminderGateway {
  static const _notificationId = 7301;
  static const _channelId = 'thirty_reminder';
  static const _channelName = 'Daily reminder';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _timezoneDataLoaded = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
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
  }) async {
    final location = await _resolveLocalLocation();
    if (location == null) return ScheduleOutcome.timezoneUnavailable;

    // Independently fail closed here — never rely solely on the caller
    // having already checked this. The reproduced Samsung failure (a
    // correctly `inexactAllowWhileIdle`-scheduled 18:05 reminder twice
    // actually delivered ~03:48 the next local day) is exactly why this
    // gateway must never schedule with an inexact mode as a fallback: with
    // no exact-alarm access, nothing is scheduled at all.
    if (!await hasExactAlarmAccess()) {
      return ScheduleOutcome.exactAlarmAccessDenied;
    }

    try {
      await _plugin.cancel(id: _notificationId);
      await _plugin.zonedSchedule(
        id: _notificationId,
        title: 'THIRTY',
        body: 'A moment for your next Circle, if it fits today.',
        // The component constructor, not `.from` — this treats
        // year/month/day/hour/minute as wall-clock time *in* [location],
        // which is what makes the daily recurrence DST-correct.
        scheduledDate: tz.TZDateTime(
          location,
          firstOccurrenceLocal.year,
          firstOccurrenceLocal.month,
          firstOccurrenceLocal.day,
          firstOccurrenceLocal.hour,
          firstOccurrenceLocal.minute,
        ),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Your optional daily THIRTY reminder.',
            importance: Importance.low,
            priority: Priority.low,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return ScheduleOutcome.scheduled;
    } catch (_) {
      return ScheduleOutcome.failed;
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _plugin.cancel(id: _notificationId);
    } catch (_) {
      // Never throws.
    }
  }

  /// Resolves the device's actual current IANA timezone as a `timezone`
  /// package [tz.Location], or `null` if either the platform lookup or
  /// the subsequent `timezone` database lookup fails — never a guessed
  /// or default zone.
  Future<tz.Location?> _resolveLocalLocation() async {
    try {
      if (!_timezoneDataLoaded) {
        tzdata.initializeTimeZones();
        _timezoneDataLoaded = true;
      }
      final info = await FlutterTimezone.getLocalTimezone();
      return tz.getLocation(info.identifier);
    } catch (_) {
      return null;
    }
  }
}
