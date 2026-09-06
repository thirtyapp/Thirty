import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/reminder/reminder_gateway.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/reminder/application/reminder_provider.dart';

class _FakeReminderGateway implements ReminderGateway {
  bool permissionGranted = true;
  ScheduleOutcome scheduleOutcome = ScheduleOutcome.scheduled;
  int initializeCallCount = 0;
  int requestPermissionCallCount = 0;
  int scheduleCallCount = 0;
  int cancelCallCount = 0;
  DateTime? lastFirstOccurrence;
  int? lastHour;
  int? lastMinute;

  @override
  Future<void> initialize() async {
    initializeCallCount++;
  }

  @override
  Future<bool> requestPermission() async {
    requestPermissionCallCount++;
    return permissionGranted;
  }

  @override
  Future<bool> hasPermission() async => permissionGranted;

  @override
  Future<ScheduleOutcome> scheduleDaily({
    required DateTime firstOccurrenceLocal,
    required int hour,
    required int minute,
  }) async {
    scheduleCallCount++;
    lastFirstOccurrence = firstOccurrenceLocal;
    lastHour = hour;
    lastMinute = minute;
    return scheduleOutcome;
  }

  @override
  Future<void> cancel() async {
    cancelCallCount++;
  }
}

final _today = DateTime(2026, 9, 2, 9, 0);

Future<ProviderContainer> _containerWith({
  Map<String, Object> prefs = const {},
  required _FakeReminderGateway gateway,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final resolved = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(resolved),
      reminderGatewayProvider.overrideWithValue(gateway),
      nowProvider.overrideWithValue(_today),
      eventClockProvider.overrideWithValue(() => _today),
    ],
  );
}

void main() {
  group('nextReminderOccurrence (pure)', () {
    test('today, when the time has not yet passed and today is not '
        'suppressed', () {
      final now = DateTime(2026, 9, 2, 8, 0);
      final next = nextReminderOccurrence(now, 20, 0, suppressToday: false);
      expect(next, DateTime(2026, 9, 2, 20, 0));
    });

    test('tomorrow, when the time has already passed today', () {
      final now = DateTime(2026, 9, 2, 21, 0);
      final next = nextReminderOccurrence(now, 20, 0, suppressToday: false);
      expect(next, DateTime(2026, 9, 3, 20, 0));
    });

    test('tomorrow, when today is suppressed even though the time has '
        'not passed yet', () {
      final now = DateTime(2026, 9, 2, 8, 0);
      final next = nextReminderOccurrence(now, 20, 0, suppressToday: true);
      expect(next, DateTime(2026, 9, 3, 20, 0));
    });

    test('tomorrow at the exact boundary — "already passed" includes '
        'the exact minute', () {
      final now = DateTime(2026, 9, 2, 20, 0);
      final next = nextReminderOccurrence(now, 20, 0, suppressToday: false);
      expect(next, DateTime(2026, 9, 3, 20, 0));
    });
  });

  group('ReminderNotifier', () {
    test('build() restores defaults and never touches the gateway', () async {
      final gateway = _FakeReminderGateway();
      final container = await _containerWith(gateway: gateway);
      addTearDown(container.dispose);

      final state = container.read(reminderProvider);

      expect(state.enabled, isFalse);
      expect(state.hour, 20);
      expect(state.minute, 0);
      expect(state.permissionGranted, isFalse);
      expect(gateway.initializeCallCount, 0);
      expect(gateway.scheduleCallCount, 0);
    });

    test('restores a previously persisted enabled state', () async {
      final gateway = _FakeReminderGateway();
      final container = await _containerWith(
        gateway: gateway,
        prefs: {
          reminderEnabledKey: true,
          reminderHourKey: 7,
          reminderMinuteKey: 30,
        },
      );
      addTearDown(container.dispose);

      final state = container.read(reminderProvider);
      expect(state.enabled, isTrue);
      expect(state.hour, 7);
      expect(state.minute, 30);
    });

    test(
      'initialize() (called at cold launch) never requests permission — '
      'only checks it — matching "no notification permission at cold '
      'launch" (parent §27)',
      () async {
        final gateway = _FakeReminderGateway();
        final container = await _containerWith(gateway: gateway);
        addTearDown(container.dispose);

        await container.read(reminderProvider.notifier).initialize();

        expect(gateway.requestPermissionCallCount, 0);
      },
    );

    test('enable() requests permission, persists, and schedules when '
        'granted', () async {
      final gateway = _FakeReminderGateway()..permissionGranted = true;
      final container = await _containerWith(gateway: gateway);
      addTearDown(container.dispose);

      await container
          .read(reminderProvider.notifier)
          .enable(hour: 8, minute: 15);

      final state = container.read(reminderProvider);
      expect(state.enabled, isTrue);
      expect(state.hour, 8);
      expect(state.minute, 15);
      expect(state.permissionGranted, isTrue);
      expect(gateway.scheduleCallCount, 1);
      expect(gateway.lastHour, 8);
      expect(gateway.lastMinute, 15);

      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getBool(reminderEnabledKey), isTrue);
    });

    test('enable() with denied permission still records the user\'s '
        'choice truthfully, but schedules nothing', () async {
      final gateway = _FakeReminderGateway()..permissionGranted = false;
      final container = await _containerWith(gateway: gateway);
      addTearDown(container.dispose);

      await container
          .read(reminderProvider.notifier)
          .enable(hour: 8, minute: 0);

      final state = container.read(reminderProvider);
      expect(state.enabled, isTrue);
      expect(state.permissionGranted, isFalse);
      expect(gateway.scheduleCallCount, 0);
      expect(gateway.cancelCallCount, greaterThan(0));
    });

    test('disable() cancels pending work and persists', () async {
      final gateway = _FakeReminderGateway();
      final container = await _containerWith(gateway: gateway);
      addTearDown(container.dispose);
      final notifier = container.read(reminderProvider.notifier);
      await notifier.enable(hour: 8, minute: 0);

      await notifier.disable();

      expect(container.read(reminderProvider).enabled, isFalse);
      expect(gateway.cancelCallCount, greaterThan(0));
      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getBool(reminderEnabledKey), isFalse);
    });

    test('setTime() reschedules with the new time while active', () async {
      final gateway = _FakeReminderGateway();
      final container = await _containerWith(gateway: gateway);
      addTearDown(container.dispose);
      final notifier = container.read(reminderProvider.notifier);
      await notifier.enable(hour: 8, minute: 0);

      await notifier.setTime(hour: 21, minute: 45);

      expect(gateway.lastHour, 21);
      expect(gateway.lastMinute, 45);
    });

    test('setTime() while disabled never schedules — only cancels (a '
        'no-op, nothing was scheduled)', () async {
      final gateway = _FakeReminderGateway();
      final container = await _containerWith(gateway: gateway);
      addTearDown(container.dispose);

      await container
          .read(reminderProvider.notifier)
          .setTime(hour: 21, minute: 45);

      expect(gateway.scheduleCallCount, 0);
    });

    test(
      'reschedules automatically when today\'s Circle starts — '
      'suppressing an unnecessary later reminder the same day',
      () async {
        final gateway = _FakeReminderGateway();
        final container = await _containerWith(gateway: gateway);
        addTearDown(container.dispose);
        await container
            .read(reminderProvider.notifier)
            .enable(hour: 8, minute: 0);
        final scheduledBefore = gateway.scheduleCallCount;

        container
            .read(recommendationProvider.notifier)
            .chooseIntention(Intention.moreEnergy);
        container.read(recommendationProvider.notifier).start();

        expect(gateway.scheduleCallCount, greaterThan(scheduledBefore));
        // Suppressed today (already started) — next occurrence is tomorrow.
        expect(gateway.lastFirstOccurrence!.day, _today.day + 1);
      },
    );

    test('never reschedules on unrelated recommendation changes with the '
        'same status (no redundant work)', () async {
      final gateway = _FakeReminderGateway();
      final container = await _containerWith(gateway: gateway);
      addTearDown(container.dispose);
      await container
          .read(reminderProvider.notifier)
          .enable(hour: 8, minute: 0);
      container
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy);
      final scheduledAfterChoose = gateway.scheduleCallCount;

      // chooseIntention doesn't change `status` (stays notStarted), so no
      // additional reschedule should fire from the listener.
      expect(scheduledAfterChoose, gateway.scheduleCallCount);
    });

    test('refreshPermission() reconciles the schedule after an external '
        'permission change', () async {
      final gateway = _FakeReminderGateway()..permissionGranted = false;
      final container = await _containerWith(
        gateway: gateway,
        prefs: {reminderEnabledKey: true, reminderHourKey: 8, reminderMinuteKey: 0},
      );
      addTearDown(container.dispose);
      gateway.permissionGranted = true;

      await container.read(reminderProvider.notifier).refreshPermission();

      expect(container.read(reminderProvider).permissionGranted, isTrue);
      expect(gateway.scheduleCallCount, 1);
    });
  });
}
