import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/reminder/reminder_gateway.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/home_invitation_slot.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/home_page.dart';
import 'package:thirty/features/premium/application/premium_offer_provider.dart';
import 'package:thirty/features/reminder/application/reminder_invitation_provider.dart';
import 'package:thirty/features/reminder/application/reminder_provider.dart';

/// Invitation semantics (founder decision after B3), on the real HomePage:
/// eligible → presented for the session (slot) → persisted shown only once
/// meaningfully visible. One ProviderContainer = one app session.

class _FakeReminderGateway implements ReminderGateway {
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermission() async => true;
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
  }) async => ScheduleOutcome.scheduled;
  @override
  Future<void> cancel() async {}
}

final _today = DateTime(2026, 8, 2, 9);

const _reminderCopy =
    "When would you like THIRTY to remind you about tomorrow's Circle?";
const _premiumCopy = 'THIRTY Premium adds guided Plans, Coach and Insights.';

const _chosen = <String, Object>{
  recommendationDayKey: '2026-08-02',
  recommendationIntentionKey: 'moreEnergy',
  recommendationActivityIdKey: 'thirtyMinuteWalk',
};

final _closedPendingReflection = <String, Object>{
  ..._chosen,
  recommendationStatusKey: 'closed',
  recommendationStartedAtKey: DateTime(2026, 8, 2, 8).toIso8601String(),
  recommendationClosedAtKey: DateTime(2026, 8, 2, 8, 30).toIso8601String(),
};

Future<void> _closedCircleOn(SharedPreferences prefs, String date) async {
  final journal = CircleJournalRepository(prefs);
  final at = DateTime.parse('${date}T08:00:00');
  await journal.recordShown(
    circleId: date,
    localDate: date,
    direction: Intention.moreEnergy,
    activityId: ActivityId.thirtyMinuteWalk,
    shownAt: at,
  );
  await journal.recordClosed(
    circleId: date,
    localDate: date,
    direction: Intention.moreEnergy,
    activityId: ActivityId.thirtyMinuteWalk,
    closedAt: at.add(const Duration(minutes: 30)),
  );
}

Future<SharedPreferences> _prefs(
  Map<String, Object> values, {
  List<String> closedDays = const ['2026-08-01'],
}) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  for (final day in closedDays) {
    await _closedCircleOn(prefs, day);
  }
  return prefs;
}

/// Starts one app "session" on [prefs] at [size] and returns its container.
Future<ProviderContainer> _session(
  WidgetTester tester,
  SharedPreferences prefs, {
  Size size = const Size(412, 2400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      reminderGatewayProvider.overrideWithValue(_FakeReminderGateway()),
      nowProvider.overrideWithValue(_today),
      eventClockProvider.overrideWithValue(() => _today),
      premiumEntitlementProvider.overrideWithValue(false),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      key: UniqueKey(),
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: const HomePage(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

/// Ends the current session: unmount the app and drop its container.
Future<void> _endSession(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

Finder get _homeScroll => find.descendant(
  of: find.byType(HomePage),
  matching: find.byType(Scrollable),
);

Future<void> _answerNotToday(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Not today'),
    200,
    scrollable: _homeScroll,
  );
  await tester.tap(find.text('Not today'));
  await tester.pump();
  await tester.pump();
}

void main() {
  group('Persisted shown = meaningfully visible, not rendered', () {
    testWidgets('rendered below the fold: shown stays false', (tester) async {
      final prefs = await _prefs(_chosen);
      await _session(tester, prefs, size: const Size(320, 568));

      expect(find.text(_reminderCopy), findsOneWidget);
      final viewport = tester.getRect(_homeScroll);
      expect(tester.getRect(find.text(_reminderCopy)).top,
          greaterThan(viewport.bottom));

      await tester.pump(const Duration(seconds: 5));
      expect(prefs.getBool(reminderInvitationShownKey), isNull);
    });

    testWidgets('scrolled until meaningfully visible: shown becomes true '
        'after the dwell, and stays written once', (tester) async {
      final prefs = await _prefs(_chosen);
      await _session(tester, prefs, size: const Size(320, 568));

      await tester.scrollUntilVisible(
        find.text('Not now'),
        150,
        scrollable: _homeScroll,
      );
      await tester.pump();
      expect(prefs.getBool(reminderInvitationShownKey), isNull);

      await tester.pump(const Duration(seconds: 1));
      expect(prefs.getBool(reminderInvitationShownKey), isTrue);

      // Scrolling away and back neither removes the card nor re-fires.
      await tester.drag(_homeScroll, const Offset(0, 2000));
      await tester.pump(const Duration(seconds: 2));
      await tester.drag(_homeScroll, const Offset(0, -2000));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text(_reminderCopy), findsOneWidget);
      expect(prefs.getBool(reminderInvitationShownKey), isTrue);
    });
  });

  group('Session stability', () {
    testWidgets('journal and reminder-state refreshes neither remove nor '
        'replace the session\'s invitation', (tester) async {
      final prefs = await _prefs(
        _chosen,
        closedDays: const ['2026-07-31', '2026-08-01'],
      );
      final container = await _session(tester, prefs);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(_reminderCopy), findsOneWidget);
      expect(prefs.getBool(reminderInvitationShownKey), isTrue);

      // The two refreshes that used to erase it: a journal write's
      // invalidation, and a reminder-state change unrelated to `enabled`
      // (what every startup / resume `initialize()` produces).
      container.invalidate(circleJournalRepositoryProvider);
      await tester.pump();
      await container.read(reminderProvider.notifier).setTime(
        hour: 7,
        minute: 30,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(_reminderCopy), findsOneWidget);
      expect(find.text(_premiumCopy), findsNothing);
      expect(prefs.getBool(premiumOfferInvitationShownKey), isNull);
      expect(
        container.read(homeInvitationSlotProvider).owner,
        HomeInvitation.reminder,
      );
    });

    testWidgets('the production repro: answering the reflection shows the '
        'reminder, and it is still there — not replaced by Premium — once '
        'the answer\'s journal write lands', (tester) async {
      final prefs = await _prefs(
        _closedPendingReflection,
        closedDays: const ['2026-07-31', '2026-08-01'],
      );
      final container = await _session(tester, prefs);
      expect(find.text(_reminderCopy), findsNothing);

      await _answerNotToday(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text(_reminderCopy), findsOneWidget);

      // On a device the answer's background journal write lands *after*
      // the card's first frame (in tests it lands before). Replay that
      // order explicitly: this is the refresh that used to erase the
      // reminder and hand its place to Premium.
      container.invalidate(circleJournalRepositoryProvider);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(_reminderCopy), findsOneWidget);
      expect(find.text(_premiumCopy), findsNothing);
      expect(prefs.getBool(premiumOfferInvitationShownKey), isNull);
    });

    testWidgets('Not now closes it for the session, and Premium does not take '
        'its place in the same session', (tester) async {
      final prefs = await _prefs(
        _chosen,
        closedDays: const ['2026-07-31', '2026-08-01'],
      );
      final container = await _session(tester, prefs);
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Not now'));
      await tester.pump();
      container.invalidate(circleJournalRepositoryProvider);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(_reminderCopy), findsNothing);
      expect(find.text(_premiumCopy), findsNothing);
      expect(reminderInvitationShownKey, 'reminder_invitation_shown_v1');
      expect(prefs.getBool(reminderInvitationShownKey), isTrue);

      // Next session: the reminder has had its turn, so Premium may show.
      await _endSession(tester, container);
      await _session(tester, prefs);
      expect(find.text(_reminderCopy), findsNothing);
      expect(find.text(_premiumCopy), findsOneWidget);
    });

    testWidgets('enabling reminders hides it immediately', (tester) async {
      final prefs = await _prefs(_chosen);
      final container = await _session(tester, prefs);
      expect(find.text(_reminderCopy), findsOneWidget);

      await container.read(reminderProvider.notifier).enable(
        hour: 8,
        minute: 0,
      );
      await tester.pump();
      expect(find.text(_reminderCopy), findsNothing);
    });
  });

  group('Reminders enabled mid-session', () {
    testWidgets('active invitation → reminders enabled → closed → reminders '
        'disabled → stays closed for the rest of the session, and Premium '
        'does not take the slot', (tester) async {
      final prefs = await _prefs(
        _chosen,
        // Two closed days: Premium would otherwise be eligible.
        closedDays: const ['2026-07-31', '2026-08-01'],
      );
      final container = await _session(tester, prefs, size: const Size(320, 568));
      expect(find.text(_reminderCopy), findsOneWidget);
      // Still below the fold: never persisted as shown.
      expect(prefs.getBool(reminderInvitationShownKey), isNull);

      final reminders = container.read(reminderProvider.notifier);
      await reminders.enable(hour: 8, minute: 0);
      await tester.pump();
      expect(find.text(_reminderCopy), findsNothing);

      await reminders.disable();
      await tester.pump();
      container.invalidate(circleJournalRepositoryProvider);
      await tester.pump(const Duration(seconds: 2));

      expect(find.text(_reminderCopy), findsNothing);
      expect(find.text(_premiumCopy), findsNothing);
      expect(container.read(homeInvitationSlotProvider), (
        owner: HomeInvitation.reminder,
        closed: true,
      ));
      // Session-only: the persisted flag keeps its meaning (never visible).
      expect(prefs.getBool(reminderInvitationShownKey), isNull);
      expect(prefs.getBool(premiumOfferInvitationShownKey), isNull);

      // A later session evaluates the normal rules again.
      await _endSession(tester, container);
      await _session(tester, prefs);
      expect(find.text(_reminderCopy), findsOneWidget);
    });

    testWidgets('enabled before any invitation was presented: disabling later '
        'in the session does not bring the reminder invitation up', (
      tester,
    ) async {
      final prefs = await _prefs(
        _closedPendingReflection,
        closedDays: const ['2026-07-31', '2026-08-01'],
      );
      final container = await _session(tester, prefs);
      expect(container.read(homeInvitationSlotProvider).owner, isNull);

      final reminders = container.read(reminderProvider.notifier);
      await reminders.enable(hour: 8, minute: 0);
      await reminders.disable();
      await _answerNotToday(tester);
      await tester.pump(const Duration(seconds: 2));

      expect(find.text(_reminderCopy), findsNothing);
      expect(find.text(_premiumCopy), findsNothing);
    });
  });

  group('Across sessions', () {
    testWidgets('app closed before it was ever visible: the next session may '
        'show it again', (tester) async {
      final prefs = await _prefs(_chosen);
      final first = await _session(tester, prefs, size: const Size(320, 568));
      expect(find.text(_reminderCopy), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(prefs.getBool(reminderInvitationShownKey), isNull);

      await _endSession(tester, first);
      await _session(tester, prefs);
      expect(find.text(_reminderCopy), findsOneWidget);
    });

    testWidgets('visible in a prior session: the next session never shows it, '
        'even though it was never tapped', (tester) async {
      final prefs = await _prefs(_chosen);
      final first = await _session(tester, prefs);
      await tester.pump(const Duration(seconds: 1));
      expect(prefs.getBool(reminderInvitationShownKey), isTrue);

      await _endSession(tester, first);
      await _session(tester, prefs);
      expect(find.text(_reminderCopy), findsNothing);
    });

    testWidgets('Premium follows the same rule', (tester) async {
      final prefs = await _prefs(
        {..._chosen, reminderInvitationShownKey: true},
        closedDays: const ['2026-07-31', '2026-08-01'],
      );
      final first = await _session(tester, prefs, size: const Size(320, 568));
      expect(find.text(_premiumCopy), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(prefs.getBool(premiumOfferInvitationShownKey), isNull);

      await _endSession(tester, first);
      final second = await _session(tester, prefs);
      expect(find.text(_premiumCopy), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(prefs.getBool(premiumOfferInvitationShownKey), isTrue);
      expect(premiumOfferInvitationShownKey, 'premium_offer_invitation_shown_v1');

      await _endSession(tester, second);
      await _session(tester, prefs);
      expect(find.text(_premiumCopy), findsNothing);
    });
  });

  group('Priority', () {
    testWidgets('reflection first: no invitation renders or claims the slot '
        'while it is pending', (tester) async {
      final prefs = await _prefs(
        _closedPendingReflection,
        closedDays: const ['2026-07-31', '2026-08-01'],
      );
      final container = await _session(tester, prefs);
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Did you try this activity?'), findsOneWidget);
      expect(find.text(_reminderCopy), findsNothing);
      expect(find.text(_premiumCopy), findsNothing);
      expect(container.read(homeInvitationSlotProvider).owner, isNull);
      expect(prefs.getBool(reminderInvitationShownKey), isNull);
    });
  });
}
