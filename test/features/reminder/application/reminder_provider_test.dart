import 'dart:async';

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
  bool exactAlarmAccessGranted = true;
  ScheduleOutcome scheduleOutcome = ScheduleOutcome.scheduled;
  int initializeCallCount = 0;
  int requestPermissionCallCount = 0;
  int requestExactAlarmAccessCallCount = 0;
  int scheduleCallCount = 0;
  int cancelCallCount = 0;
  DateTime? lastFirstOccurrence;
  int? lastHour;
  int? lastMinute;

  /// When set, [hasPermission] never resolves — simulating the app
  /// process dying (or simply never getting scheduled again) partway
  /// through `_rescheduleIfNeeded()`, strictly *after* its first `await`
  /// (the unconditional [cancel] call) but *before* anything past it can
  /// run. Lets a test observe exactly what a same-day-alarm-survives race
  /// would require: whether [cancel] already completed on its own,
  /// independent of every later step.
  Completer<bool>? _hangingPermissionCheck;

  void hangPermissionCheck() {
    _hangingPermissionCheck = Completer<bool>();
  }

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
  Future<bool> hasPermission() {
    final hanging = _hangingPermissionCheck;
    if (hanging != null) return hanging.future;
    return Future.value(permissionGranted);
  }

  @override
  Future<bool> hasExactAlarmAccess() async => exactAlarmAccessGranted;

  @override
  Future<void> requestExactAlarmAccess() async {
    requestExactAlarmAccessCallCount++;
  }

  @override
  Future<ScheduleOutcome> scheduleDaily({
    required DateTime firstOccurrenceLocal,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    // Mirrors the real gateway's own independent fail-closed check
    // (`local_notifications_reminder_gateway.dart`) — a fake that always
    // "succeeds" here would hide a provider-side bug that skips its own
    // live exact-access check.
    if (!exactAlarmAccessGranted) return ScheduleOutcome.exactAlarmAccessDenied;
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
// Deliberately before the 8:00 reminder time used below — the Day N+1
// test isolates suppression from the separate, already-correct "today's
// time already passed" rule `nextReminderOccurrence` applies regardless
// of suppression.
final _tomorrow = DateTime(2026, 9, 3, 7, 0);

Future<ProviderContainer> _containerWith({
  Map<String, Object> prefs = const {},
  required _FakeReminderGateway gateway,
  DateTime? now,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final resolved = await SharedPreferences.getInstance();
  final resolvedNow = now ?? _today;
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(resolved),
      reminderGatewayProvider.overrideWithValue(gateway),
      nowProvider.overrideWithValue(resolvedNow),
      eventClockProvider.overrideWithValue(() => resolvedNow),
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
      expect(state.exactAlarmAccessGranted, isFalse);
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
      'initialize() (called at cold launch) never requests notification '
      'permission or exact-alarm access — only checks them — matching "no '
      'permission request at cold launch" (parent §27, extended to '
      'exact-alarm special access)',
      () async {
        final gateway = _FakeReminderGateway();
        final container = await _containerWith(gateway: gateway);
        addTearDown(container.dispose);

        await container.read(reminderProvider.notifier).initialize();

        expect(gateway.requestPermissionCallCount, 0);
        expect(gateway.requestExactAlarmAccessCallCount, 0);
      },
    );

    test('enable() requests permission, persists, and schedules exactly '
        'once when notification permission and exact-alarm access are '
        'both granted', () async {
      final gateway = _FakeReminderGateway()
        ..permissionGranted = true
        ..exactAlarmAccessGranted = true;
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
      expect(state.exactAlarmAccessGranted, isTrue);
      expect(gateway.scheduleCallCount, 1);
      expect(gateway.lastHour, 8);
      expect(gateway.lastMinute, 15);

      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getBool(reminderEnabledKey), isTrue);
    });

    test('enable() with denied notification permission still records the '
        'user\'s choice truthfully, but schedules nothing', () async {
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

    test(
      'enable() with notification permission granted but exact-alarm '
      'access missing schedules nothing — never an inexact fallback',
      () async {
        final gateway = _FakeReminderGateway()
          ..permissionGranted = true
          ..exactAlarmAccessGranted = false;
        final container = await _containerWith(gateway: gateway);
        addTearDown(container.dispose);

        await container
            .read(reminderProvider.notifier)
            .enable(hour: 8, minute: 0);

        final state = container.read(reminderProvider);
        expect(state.enabled, isTrue);
        expect(state.permissionGranted, isTrue);
        expect(state.exactAlarmAccessGranted, isFalse);
        expect(gateway.scheduleCallCount, 0);
        expect(gateway.cancelCallCount, greaterThan(0));
      },
    );

    test(
      'requestExactAlarmAccess() invokes the platform request exactly '
      'once and, once access is actually granted, re-checks live and the '
      'reminder becomes active',
      () async {
        final gateway = _FakeReminderGateway()
          ..permissionGranted = true
          ..exactAlarmAccessGranted = false;
        final container = await _containerWith(gateway: gateway);
        addTearDown(container.dispose);
        await container
            .read(reminderProvider.notifier)
            .enable(hour: 8, minute: 0);
        expect(container.read(reminderProvider).exactAlarmAccessGranted, isFalse);
        expect(gateway.scheduleCallCount, 0);

        // Simulates the user granting access on the system screen and
        // returning to THIRTY.
        gateway.exactAlarmAccessGranted = true;
        await container
            .read(reminderProvider.notifier)
            .requestExactAlarmAccess();

        expect(gateway.requestExactAlarmAccessCallCount, 1);
        expect(container.read(reminderProvider).exactAlarmAccessGranted, isTrue);
        expect(gateway.scheduleCallCount, 1);
      },
    );

    test(
      'user returns from the exact-alarm access screen without granting '
      'it — the reminder remains inactive/needs access, not scheduled',
      () async {
        final gateway = _FakeReminderGateway()
          ..permissionGranted = true
          ..exactAlarmAccessGranted = false;
        final container = await _containerWith(gateway: gateway);
        addTearDown(container.dispose);
        await container
            .read(reminderProvider.notifier)
            .enable(hour: 8, minute: 0);

        await container
            .read(reminderProvider.notifier)
            .requestExactAlarmAccess();

        expect(gateway.requestExactAlarmAccessCallCount, 1);
        expect(container.read(reminderProvider).exactAlarmAccessGranted, isFalse);
        expect(gateway.scheduleCallCount, 0);
      },
    );

    test(
      'exact-alarm access revoked later (e.g. from system settings while '
      'backgrounded) is reconciled without crashing — schedules nothing '
      'and the state reflects it truthfully',
      () async {
        final gateway = _FakeReminderGateway()
          ..permissionGranted = true
          ..exactAlarmAccessGranted = true;
        final container = await _containerWith(gateway: gateway);
        addTearDown(container.dispose);
        await container
            .read(reminderProvider.notifier)
            .enable(hour: 8, minute: 0);
        expect(gateway.scheduleCallCount, 1);

        gateway.exactAlarmAccessGranted = false;
        await container.read(reminderProvider.notifier).refreshPermission();

        final state = container.read(reminderProvider);
        expect(state.enabled, isTrue);
        expect(state.exactAlarmAccessGranted, isFalse);
        // No additional schedule call beyond the original grant — the
        // revoked re-check returns early before ever reaching
        // scheduleDaily() again.
        expect(gateway.scheduleCallCount, 1);
      },
    );

    test(
      'repeatedly reconciling with exact-alarm access still denied never '
      'triggers the platform request itself — no permission nag loop; '
      'the request only ever happens from the dedicated explicit user '
      'action',
      () async {
        final gateway = _FakeReminderGateway()
          ..permissionGranted = true
          ..exactAlarmAccessGranted = false;
        final container = await _containerWith(
          gateway: gateway,
          prefs: {reminderEnabledKey: true, reminderHourKey: 8, reminderMinuteKey: 0},
        );
        addTearDown(container.dispose);
        final notifier = container.read(reminderProvider.notifier);

        await notifier.initialize();
        await notifier.refreshPermission();
        await notifier.refreshPermission();

        expect(gateway.requestExactAlarmAccessCallCount, 0);
        expect(gateway.scheduleCallCount, 0);
      },
    );

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
        // `ref.listen`'s callback fires `_rescheduleIfNeeded()`
        // `unawaited` — let its microtasks (including its own live
        // `gateway.hasPermission()` re-check) actually run before
        // asserting on their effect.
        await Future<void>.delayed(Duration.zero);

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

    test(
      'closing today\'s Circle (after starting it) suppresses the same '
      'day, targeting the same next occurrence as starting alone — '
      'never pushed further out by the second status change',
      () async {
        final gateway = _FakeReminderGateway();
        final container = await _containerWith(gateway: gateway);
        addTearDown(container.dispose);
        await container
            .read(reminderProvider.notifier)
            .enable(hour: 8, minute: 0);
        final notifier = container.read(recommendationProvider.notifier);
        notifier.chooseIntention(Intention.moreEnergy);
        notifier.start();
        await Future<void>.delayed(Duration.zero);
        final occurrenceAfterStart = gateway.lastFirstOccurrence;

        notifier.close();
        await Future<void>.delayed(Duration.zero);

        expect(gateway.lastFirstOccurrence, occurrenceAfterStart);
        expect(gateway.lastFirstOccurrence!.day, _today.day + 1);
      },
    );

    test(
      'Close cancels the same-day alarm before anything else runs — the '
      'alarm is already gone even if the process never gets past that '
      'first step (simulated by a permission check that never resolves)',
      () async {
        final gateway = _FakeReminderGateway();
        final container = await _containerWith(gateway: gateway);
        addTearDown(container.dispose);
        await container
            .read(reminderProvider.notifier)
            .enable(hour: 8, minute: 0);
        final notifier = container.read(recommendationProvider.notifier);
        notifier.chooseIntention(Intention.moreEnergy);
        notifier.start();
        final cancelledBefore = gateway.cancelCallCount;

        // From this point on, `_rescheduleIfNeeded()` can never progress
        // past its `hasPermission()` await — modelling the process dying
        // (or simply never running again) right after Close.
        gateway.hangPermissionCheck();
        notifier.close();
        await Future<void>.delayed(Duration.zero);

        expect(gateway.cancelCallCount, greaterThan(cancelledBefore));
        // The stuck permission check proves nothing past cancellation
        // could have run yet — scheduleDaily() was never reached.
        expect(gateway.scheduleCallCount, 1);
      },
    );

    test(
      'a failed re-arm after a successful cancel fails closed — '
      "today's alarm is not reintroduced merely because tomorrow's "
      'reschedule attempt failed',
      () async {
        final gateway = _FakeReminderGateway()
          ..scheduleOutcome = ScheduleOutcome.failed;
        final container = await _containerWith(gateway: gateway);
        addTearDown(container.dispose);
        await container
            .read(reminderProvider.notifier)
            .enable(hour: 8, minute: 0);
        final notifier = container.read(recommendationProvider.notifier);
        notifier.chooseIntention(Intention.moreEnergy);
        notifier.start();
        final cancelledBefore = gateway.cancelCallCount;

        notifier.close();
        await Future<void>.delayed(Duration.zero);

        // Cancellation happened regardless of the following schedule
        // attempt's outcome — there is no path that "un-cancels" today's
        // alarm because tomorrow's re-arm failed.
        expect(gateway.cancelCallCount, greaterThan(cancelledBefore));
        expect(gateway.scheduleCallCount, greaterThan(0));
      },
    );

    test(
      'Day N+1: a stale Day-N started/closed status cannot suppress the '
      'new day\'s reminder — eligibility is restored automatically, '
      'exactly the founder-approved "reminds again the next day '
      'automatically" behavior (rule 4/5 of the reminder contract '
      'amendment). This models a fresh app session on the new day — '
      'THIRTY\'s own Dart code has no way to run at midnight with no app '
      'open at all; that guarantee is provided entirely by '
      '`flutter_local_notifications`\' native Android '
      '`ScheduledNotificationReceiver`, which re-arms its own next '
      'occurrence purely in native code once a notification has actually '
      'fired (verified by reading that plugin\'s Java source directly) — '
      'a platform boundary no Flutter-side test can exercise. What THIS '
      'test proves is the one thing entirely within THIRTY\'s own control: '
      'if the Day-N session correctly targeted Day N+1 (already covered '
      'above) and the app happens to be reopened on Day N+1, it must '
      'never remain incorrectly suppressed by Day N\'s leftover status.',
      () async {
        final gateway = _FakeReminderGateway();
        final dayNContainer = await _containerWith(gateway: gateway);
        addTearDown(dayNContainer.dispose);
        await dayNContainer
            .read(reminderProvider.notifier)
            .enable(hour: 8, minute: 0);
        final dayNNotifier = dayNContainer.read(
          recommendationProvider.notifier,
        );
        dayNNotifier.chooseIntention(Intention.moreEnergy);
        dayNNotifier.start();
        dayNNotifier.close();
        // Let both the reminder's own reactive reschedule and
        // `RecommendationNotifier`'s fire-and-forget persistence actually
        // complete before reading persisted prefs back out below.
        await Future<void>.delayed(Duration.zero);
        final dayNPrefs = dayNContainer.read(sharedPreferencesProvider);

        // A fresh container/gateway — a new app process on Day N+1, never
        // having opened THIRTY on Day N+1 itself yet — inheriting exactly
        // what Day N actually persisted (reminder prefs, and Day N's own
        // closed recommendation under Day N's day-key).
        final dayNPlusOneGateway = _FakeReminderGateway();
        final dayNPlusOneContainer = await _containerWith(
          gateway: dayNPlusOneGateway,
          now: _tomorrow,
          prefs: {
            for (final key in [
              reminderEnabledKey,
              reminderHourKey,
              reminderMinuteKey,
            ])
              key: dayNPrefs.get(key)!,
            for (final key in [
              recommendationDayKey,
              recommendationIntentionKey,
              recommendationActivityIdKey,
              recommendationStatusKey,
              recommendationStartedAtKey,
              recommendationClosedAtKey,
            ])
              if (dayNPrefs.get(key) != null) key: dayNPrefs.get(key)!,
          },
        );
        addTearDown(dayNPlusOneContainer.dispose);

        // The day-key mismatch (Day N's date vs Day N+1's `now`) must
        // reset `RecommendationState.status` to `notStarted` on its own —
        // proving the stale `closed` status cannot leak across the day
        // boundary regardless of what the reminder feature does.
        expect(
          dayNPlusOneContainer.read(recommendationProvider).status,
          RecommendationStatus.notStarted,
        );

        await dayNPlusOneContainer.read(reminderProvider.notifier).initialize();

        expect(dayNPlusOneGateway.scheduleCallCount, 1);
        // Not suppressed — Day N+1 is a fresh, unresolved day, so the
        // reminder is eligible for *today* (Day N+1) at the configured
        // time, not pushed to Day N+2.
        expect(
          dayNPlusOneGateway.lastFirstOccurrence,
          DateTime(_tomorrow.year, _tomorrow.month, _tomorrow.day, 8, 0),
        );
      },
    );

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
