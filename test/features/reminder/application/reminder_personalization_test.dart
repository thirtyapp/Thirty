import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/reminder/reminder_gateway.dart';
import 'package:thirty/features/reminder/application/reminder_provider.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';

/// The daily reminder's personal greeting: its daypart comes from the
/// reminder's own time, its name from the user's optional first name, and
/// a name change re-establishes an enabled reminder — never a disabled one,
/// and never by asking for permission again.

class _RecordingReminderGateway implements ReminderGateway {
  int requestPermissionCalls = 0;
  final List<({int hour, int minute, String title, String body})> schedules =
      [];

  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermission() async {
    requestPermissionCalls++;
    return true;
  }

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
  }) async {
    schedules.add((hour: hour, minute: minute, title: title, body: body));
    return ScheduleOutcome.scheduled;
  }

  @override
  Future<void> cancel() async {}
}

const _body = "Your Circle is here when you're ready.";
final _now = DateTime(2026, 10, 4, 9, 0);

Future<(ProviderContainer, SharedPreferences, _RecordingReminderGateway)>
_container([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final gateway = _RecordingReminderGateway();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      reminderGatewayProvider.overrideWithValue(gateway),
      nowProvider.overrideWithValue(_now),
      eventClockProvider.overrideWithValue(() => _now),
    ],
  );
  addTearDown(container.dispose);
  // Build the reminder notifier (and its name listener) up front.
  container.read(reminderProvider);
  return (container, prefs, gateway);
}

Map<String, Object> _enabledAt(int hour, int minute) => {
  reminderEnabledKey: true,
  reminderHourKey: hour,
  reminderMinuteKey: minute,
};

void main() {
  group('reminderNotificationTitle (pure)', () {
    for (final (hour, minute, withName, without) in [
      (8, 0, 'Good morning, Thomas.', 'Good morning.'),
      (14, 0, 'Good afternoon, Thomas.', 'Good afternoon.'),
      (20, 0, 'Good evening, Thomas.', 'Good evening.'),
      (4, 30, 'Good evening, Thomas.', 'Good evening.'),
      (4, 59, 'Good evening, Thomas.', 'Good evening.'),
      (5, 0, 'Good morning, Thomas.', 'Good morning.'),
      (11, 59, 'Good morning, Thomas.', 'Good morning.'),
      (12, 0, 'Good afternoon, Thomas.', 'Good afternoon.'),
      (17, 59, 'Good afternoon, Thomas.', 'Good afternoon.'),
      (18, 0, 'Good evening, Thomas.', 'Good evening.'),
    ]) {
      test('$hour:${minute.toString().padLeft(2, '0')} → "$withName" / '
          '"$without"', () {
        expect(
          reminderNotificationTitle(
            hour: hour,
            minute: minute,
            firstName: 'Thomas',
          ),
          withName,
        );
        expect(reminderNotificationTitle(hour: hour, minute: minute), without);
      });
    }

    test('the body is fixed and carries nothing personal', () {
      expect(reminderNotificationBody, _body);
    });
  });

  group('Scheduled notification content', () {
    for (final (hour, minute, name, title) in [
      (8, 0, 'Thomas', 'Good morning, Thomas.'),
      (14, 0, 'Thomas', 'Good afternoon, Thomas.'),
      (20, 0, 'Thomas', 'Good evening, Thomas.'),
      (4, 30, 'Thomas', 'Good evening, Thomas.'),
      (8, 0, null, 'Good morning.'),
      (14, 0, null, 'Good afternoon.'),
      (20, 0, null, 'Good evening.'),
    ]) {
      test(
        'reminder at $hour:$minute, ${name ?? 'no name'} → "$title"',
        () async {
          final (container, _, gateway) = await _container({
            ..._enabledAt(hour, minute),
            firstNameKey: ?name,
          });
          await container.read(reminderProvider.notifier).initialize();

          expect(gateway.schedules, isNotEmpty);
          expect(gateway.schedules.last.title, title);
          expect(gateway.schedules.last.body, _body);
        },
      );
    }

    test('the title follows the reminder time, not the moment it is '
        'scheduled: scheduled at 09:00 for 20:00 → evening', () async {
      final (container, _, gateway) = await _container({
        ..._enabledAt(20, 0),
        firstNameKey: 'Thomas',
      });
      await container.read(reminderProvider.notifier).initialize();
      expect(_now.hour, 9);
      expect(gateway.schedules.last.title, 'Good evening, Thomas.');
    });
  });

  group('Name lifecycle', () {
    test('enabled + add a name → the future notification is re-established '
        'with it', () async {
      final (container, _, gateway) = await _container(_enabledAt(8, 0));
      await container.read(reminderProvider.notifier).initialize();
      expect(gateway.schedules.last.title, 'Good morning.');

      await container.read(firstNameProvider.notifier).setFirstName('Thomas');
      await pumpEventQueue();

      expect(gateway.schedules.last.title, 'Good morning, Thomas.');
      expect(gateway.schedules.last.body, _body);
    });

    test('enabled + change the name → updated', () async {
      final (container, _, gateway) = await _container({
        ..._enabledAt(20, 0),
        firstNameKey: 'Thomas',
      });
      await container.read(reminderProvider.notifier).initialize();

      await container.read(firstNameProvider.notifier).setFirstName('Anna');
      await pumpEventQueue();

      expect(gateway.schedules.last.title, 'Good evening, Anna.');
    });

    test('enabled + remove the name → neutral greeting', () async {
      final (container, _, gateway) = await _container({
        ..._enabledAt(14, 0),
        firstNameKey: 'Thomas',
      });
      await container.read(reminderProvider.notifier).initialize();
      expect(gateway.schedules.last.title, 'Good afternoon, Thomas.');

      await container.read(firstNameProvider.notifier).clear();
      await pumpEventQueue();

      expect(gateway.schedules.last.title, 'Good afternoon.');
    });

    test('disabled + change the name → nothing is scheduled', () async {
      final (container, _, gateway) = await _container({
        reminderEnabledKey: false,
        reminderHourKey: 8,
        reminderMinuteKey: 0,
      });
      await container.read(reminderProvider.notifier).initialize();

      await container.read(firstNameProvider.notifier).setFirstName('Thomas');
      await pumpEventQueue();
      await container.read(firstNameProvider.notifier).setFirstName('Anna');
      await pumpEventQueue();
      await container.read(firstNameProvider.notifier).clear();
      await pumpEventQueue();

      expect(gateway.schedules, isEmpty);
      expect(container.read(reminderProvider).enabled, isFalse);
    });

    test('a name edit never asks for notification permission again, and '
        'keeps the reminder time and state', () async {
      final (container, prefs, gateway) = await _container(_enabledAt(7, 45));
      await container.read(reminderProvider.notifier).initialize();
      final before = gateway.requestPermissionCalls;

      await container.read(firstNameProvider.notifier).setFirstName('Thomas');
      await pumpEventQueue();
      await container.read(firstNameProvider.notifier).clear();
      await pumpEventQueue();

      expect(gateway.requestPermissionCalls, before);
      final state = container.read(reminderProvider);
      expect(state.enabled, isTrue);
      expect((state.hour, state.minute), (7, 45));
      expect(prefs.getBool(reminderEnabledKey), isTrue);
      expect(prefs.getInt(reminderHourKey), 7);
      expect(prefs.getInt(reminderMinuteKey), 45);
      expect(gateway.schedules.map((s) => (s.hour, s.minute)).toSet(), {
        (7, 45),
      });
    });

    test('saving the same name again changes nothing', () async {
      final (container, _, gateway) = await _container({
        ..._enabledAt(8, 0),
        firstNameKey: 'Thomas',
      });
      await container.read(reminderProvider.notifier).initialize();
      final count = gateway.schedules.length;

      await container.read(firstNameProvider.notifier).setFirstName('Thomas');
      await pumpEventQueue();

      expect(gateway.schedules.length, count);
    });
  });

  group('Reminder time lifecycle', () {
    test(
      'changing the reminder time changes the greeting\'s daypart',
      () async {
        final (container, _, gateway) = await _container({
          ..._enabledAt(8, 0),
          firstNameKey: 'Thomas',
        });
        final notifier = container.read(reminderProvider.notifier);
        await notifier.initialize();
        expect(gateway.schedules.last.title, 'Good morning, Thomas.');

        for (final (hour, minute, title) in [
          (14, 0, 'Good afternoon, Thomas.'),
          (20, 0, 'Good evening, Thomas.'),
          (4, 30, 'Good evening, Thomas.'),
          (8, 0, 'Good morning, Thomas.'),
        ]) {
          await notifier.setTime(hour: hour, minute: minute);
          expect(gateway.schedules.last.title, title, reason: '$hour:$minute');
          expect(
            (gateway.schedules.last.hour, gateway.schedules.last.minute),
            (hour, minute),
          );
        }
      },
    );

    test('enabling picks the greeting for the chosen time', () async {
      final (container, _, gateway) = await _container({firstNameKey: 'Zoë'});
      await container
          .read(reminderProvider.notifier)
          .enable(hour: 19, minute: 15);
      expect(gateway.schedules.last.title, 'Good evening, Zoë.');
    });
  });
}
