import '../analytics/analytics_event_type.dart';
import '../analytics/analytics_service.dart';
import '../reminder/reminder_gateway.dart';

/// QA-1 — analytics for a QA session: records nothing. Synthetic history
/// and simulated entitlement must never reach real telemetry.
class QaSilentAnalyticsService implements AnalyticsService {
  const QaSilentAnalyticsService();

  @override
  void track(AnalyticsEventType type, {Map<String, Object?>? metadata}) {}
}

/// QA-1 — reminders for a QA session: never touches the device's real
/// notification schedule, so the genuine daily reminder is exactly as the
/// user left it whatever is tried inside the harness.
class QaInertReminderGateway implements ReminderGateway {
  const QaInertReminderGateway();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<bool> hasExactAlarmAccess() async => false;

  @override
  Future<void> requestExactAlarmAccess() async {}

  @override
  Future<ScheduleOutcome> scheduleDaily({
    required DateTime firstOccurrenceLocal,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async => ScheduleOutcome.failed;

  @override
  Future<void> cancel() async {}
}
