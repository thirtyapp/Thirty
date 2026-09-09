import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/reminder/reminder_gateway.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/reminder/application/reminder_invitation_provider.dart';
import 'package:thirty/features/reminder/application/reminder_provider.dart';
import 'package:thirty/features/reminder/presentation/widgets/reminder_invitation_card.dart';

class _FakeReminderGateway implements ReminderGateway {
  bool permissionGranted = true;
  int scheduleCallCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<bool> hasPermission() async => permissionGranted;

  @override
  Future<ScheduleOutcome> scheduleDaily({
    required DateTime firstOccurrenceLocal,
    required int hour,
    required int minute,
  }) async {
    scheduleCallCount++;
    return ScheduleOutcome.scheduled;
  }

  @override
  Future<void> cancel() async {}
}

final _today = DateTime(2026, 9, 2, 9, 0);

Future<(Widget, ProviderContainer)> _wrap({
  required _FakeReminderGateway gateway,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      reminderGatewayProvider.overrideWithValue(gateway),
      nowProvider.overrideWithValue(_today),
      eventClockProvider.overrideWithValue(() => _today),
    ],
  );
  final widget = UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: ReminderInvitationCard()),
    ),
  );
  return (widget, container);
}

Future<void> _closeCircle(ProviderContainer container, String date) async {
  final journal = container.read(circleJournalRepositoryProvider);
  final circleId = 'circle_$date';
  await journal.recordShown(
    circleId: circleId,
    localDate: date,
    direction: Intention.moreEnergy,
    activityId: ActivityId.thirtyMinuteWalk,
    shownAt: DateTime.parse('${date}T08:00:00'),
  );
  await journal.recordClosed(
    circleId: circleId,
    localDate: date,
    direction: Intention.moreEnergy,
    activityId: ActivityId.thirtyMinuteWalk,
    closedAt: DateTime.parse('${date}T08:30:00'),
  );
}

void main() {
  testWidgets('renders nothing before any Circle has ever been closed', (
    tester,
  ) async {
    final (widget, container) = await _wrap(gateway: _FakeReminderGateway());
    addTearDown(container.dispose);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.byType(ReminderInvitationCard), findsOneWidget);
    expect(find.textContaining('remind you about tomorrow\'s Circle'), findsNothing);
  });

  testWidgets('renders the invitation after the first closed Circle', (
    tester,
  ) async {
    final (widget, container) = await _wrap(gateway: _FakeReminderGateway());
    addTearDown(container.dispose);
    await _closeCircle(container, '2026-09-01');

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.textContaining('remind you about tomorrow\'s Circle'), findsOneWidget);
    expect(find.text('Choose a time'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
  });

  testWidgets('marks itself shown once rendered', (tester) async {
    final (widget, container) = await _wrap(gateway: _FakeReminderGateway());
    addTearDown(container.dispose);
    await _closeCircle(container, '2026-09-01');

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getBool(reminderInvitationShownKey), isTrue);
  });

  testWidgets('tapping "Not now" dismisses it immediately without '
      'enabling reminders', (tester) async {
    final (widget, container) = await _wrap(gateway: _FakeReminderGateway());
    addTearDown(container.dispose);
    await _closeCircle(container, '2026-09-01');
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.textContaining('remind you about tomorrow\'s Circle'), findsNothing);
    expect(container.read(reminderProvider).enabled, isFalse);
  });

  testWidgets('choosing a time enables the reminder and dismisses the '
      'card', (tester) async {
    final gateway = _FakeReminderGateway();
    final (widget, container) = await _wrap(gateway: gateway);
    addTearDown(container.dispose);
    await _closeCircle(container, '2026-09-01');
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose a time'));
    await tester.pumpAndSettle();
    // Confirm the platform time picker's own OK/confirm action.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(container.read(reminderProvider).enabled, isTrue);
    expect(gateway.scheduleCallCount, greaterThan(0));
    expect(find.textContaining('remind you about tomorrow\'s Circle'), findsNothing);
  });

  testWidgets('never renders once reminders are already enabled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({reminderEnabledKey: true});
    final prefs = await SharedPreferences.getInstance();
    final gateway = _FakeReminderGateway();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        reminderGatewayProvider.overrideWithValue(gateway),
        nowProvider.overrideWithValue(_today),
        eventClockProvider.overrideWithValue(() => _today),
      ],
    );
    addTearDown(container.dispose);
    await _closeCircle(container, '2026-09-01');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ReminderInvitationCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('remind you about tomorrow\'s Circle'), findsNothing);
  });
}
