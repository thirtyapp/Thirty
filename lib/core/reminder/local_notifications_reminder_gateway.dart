import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_gateway.dart';

/// The real local-notification adapter — `flutter_local_notifications`,
/// the one package approved for THIRTY's optional local reminder (Step 5
/// local closure).
///
/// **Deliberately schedules against [tz.UTC], not a device-specific named
/// IANA zone.** The `timezone` package cannot itself determine the
/// device's local zone (its own README says so — a `flutter_timezone`
/// dependency or a hand-written platform channel would be needed for
/// that, and this batch's dependency approval covers only
/// `flutter_local_notifications` + `timezone`). Instead,
/// [scheduleDaily]'s caller (`reminder_provider.dart`'s
/// `ReminderNotifier`) always computes [firstOccurrenceLocal] fresh from
/// Dart's own always-locally-correct `DateTime` arithmetic — which
/// already reflects the OS's current timezone/DST — and this gateway
/// converts that one instant to UTC before scheduling.
///
/// **Known limitation, documented rather than hidden:** the underlying
/// `matchDateTimeComponents: DateTimeComponents.time` recurrence then
/// repeats at that fixed *UTC* clock time daily, which will not
/// automatically follow a later DST transition until the app is next
/// resumed (`thirty_app.dart`'s lifecycle hook recomputes and
/// reschedules on every foreground resume, which corrects it within one
/// app open). Given "no minute-perfect delivery promise" is already
/// required (frozen architecture / parent §27), a reminder that may
/// drift by one hour until the next app open — rather than silently
/// dropping a fourth dependency into the app — is the accepted tradeoff.
class LocalNotificationsReminderGateway implements ReminderGateway {
  static const _notificationId = 7301;
  static const _channelId = 'thirty_reminder';
  static const _channelName = 'Daily reminder';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
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
  Future<void> scheduleDaily({
    required DateTime firstOccurrenceLocal,
    required int hour,
    required int minute,
  }) async {
    try {
      await _plugin.cancel(id: _notificationId);
      await _plugin.zonedSchedule(
        id: _notificationId,
        title: 'THIRTY',
        body: 'A moment for your next Circle, if it fits today.',
        scheduledDate: tz.TZDateTime.from(firstOccurrenceLocal.toUtc(), tz.UTC),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Your optional daily THIRTY reminder.',
            importance: Importance.low,
            priority: Priority.low,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Never throws — see class doc comment.
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
}
