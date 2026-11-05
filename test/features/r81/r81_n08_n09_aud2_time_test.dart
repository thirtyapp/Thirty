import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';

import '../../support/r8_harness.dart';

/// R8.1 — time and day semantics:
/// - Astra N08 (MEDIUM): a choice made after midnight with no touch (a
///   screen reader, keyboard or switch) dates the Plan's served stage under
///   the same day and Circle as the choice;
/// - Astra N09 (MEDIUM) / Claude AUD-5 (LOW): Start, Close and pause are
///   stored as unambiguous instants, so the six-hour carry-over is real
///   elapsed time even across the repeated 02:30 of 25 October 2026
///   (Europe/Brussels); older offset-free values still read as before;
/// - Claude AUD-2 (MEDIUM): a carried-over Circle, once finished and its
///   reflection answered, lets today's Circle be chosen without another
///   resume.
void main() {
  RecommendationNotifier today(ProviderContainer c) =>
      c.read(recommendationProvider.notifier);
  void set(ProviderContainer c, EntitlementStatus s) =>
      (c.read(entitlementStatusProvider.notifier) as SettableEntitlement).set(
        s,
      );

  // ---------------------------------------------------------------- N08
  test('N08 — a no-touch choice after midnight: the served stage is dated '
      'with the Circle\'s own day, so a lapse before Close keeps the '
      'legitimate credit', () async {
    final evening = DateTime(2026, 10, 12, 23, 50);
    final h = R8Harness(evening);
    await h.boot();
    final c = h.open();
    c.read(circlePlansProvider.notifier).start('getting_going');
    expect(c.read(recommendationProvider).recommendation, isNull);
    await R8Harness.settle();
    // 00:10 — the cached day is still yesterday's; no touch reaches the app.
    h.clock.value = DateTime(2026, 10, 13, 0, 10);
    today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
    await R8Harness.settle();
    final rec = c.read(recommendationProvider).recommendation!;
    expect(rec.circleId, '2026-10-13');
    expect(rec.composed?.stage, isNotNull);
    final served = c.read(circlePlansProvider).active!.lastServed!;
    expect(served.circleId, rec.circleId, reason: 'served under yesterday');

    today(c).start();
    await R8Harness.settle();
    set(c, EntitlementStatus.inactive);
    h.clock.value = DateTime(2026, 10, 13, 0, 35);
    today(c).close();
    await R8Harness.settle();
    final plan = c.read(circlePlansProvider).plans['getting_going']!;
    expect(
      plan.cycles
          .expand((cy) => cy.records)
          .where((r) => r.circleId == rec.circleId),
      hasLength(1),
      reason: 'the legitimately served and started Circle lost its credit',
    );
  });

  // ---------------------------------------------------------------- N09
  // 25 October 2026, Europe/Brussels: 03:00 CEST becomes 02:00 CET, so
  // 02:30 happens twice — first at 00:30Z (+02:00), then at 01:30Z (+01:00).
  final firstHalfPastTwo = DateTime.utc(2026, 10, 25, 0, 30).toLocal();
  final secondHalfPastTwo = DateTime.utc(2026, 10, 25, 1, 30).toLocal();
  final brussels =
      firstHalfPastTwo.hour == 2 &&
      firstHalfPastTwo.minute == 30 &&
      secondHalfPastTwo.hour == 2 &&
      secondHalfPastTwo.minute == 30 &&
      firstHalfPastTwo.day == 25;
  final dstSkip = brussels
      ? false
      : 'needs the Europe/Brussels (Romance) local time zone';

  for (final (which, closedAt, elapsed, carries) in [
    ('first', firstHalfPastTwo, '6h30', false),
    ('second', secondHalfPastTwo, '5h30', true),
  ]) {
    test('N09 — closed at the $which 02:30 of 25 October 2026, reflection '
        'open, restart at 08:00: $elapsed really elapsed, so it '
        '${carries ? 'is' : 'is not'} carried over', () async {
      final start = DateTime.utc(2026, 10, 24, 21, 30).toLocal(); // 23:30
      final restartAt = DateTime.utc(2026, 10, 25, 7).toLocal(); // 08:00
      expect(
        restartAt.difference(closedAt),
        carries
            ? const Duration(hours: 5, minutes: 30)
            : const Duration(hours: 6, minutes: 30),
      );
      final h = R8Harness(start.subtract(const Duration(minutes: 1)));
      await h.boot();
      final c = h.open(status: EntitlementStatus.inactive);
      today(c).chooseIntention(Intention.moreEnergy);
      await R8Harness.settle();
      h.clock.value = start;
      today(c).start();
      await R8Harness.settle();
      h.clock.value = closedAt;
      today(c).close();
      await R8Harness.settle();
      final stored = (await h.disk.stored())[recommendationClosedAtKey];
      expect(
        DateTime.parse(stored! as String).isAtSameMomentAs(closedAt),
        isTrue,
        reason: 'the stored Close is not the instant it happened',
      );

      h.clock.value = restartAt;
      await h.restart();
      final again = h.open(status: EntitlementStatus.inactive);
      final state = again.read(recommendationProvider);
      expect(state.recommendation?.circleId, carries ? dateKey(start) : null);
      if (carries) {
        expect(state.closedAt!.isAtSameMomentAs(closedAt), isTrue);
        expect(state.closedAt!.isUtc, isFalse, reason: 'read back as local');
      }
    }, skip: dstSkip);
  }

  test('N09 — the two 02:30 Closes are stored differently: an instant, not '
      'a wall-clock time', () async {
    final stored = <Object?>[];
    for (final closedAt in [firstHalfPastTwo, secondHalfPastTwo]) {
      final start = closedAt.subtract(const Duration(hours: 3));
      final h = R8Harness(start);
      await h.boot();
      final c = h.open(status: EntitlementStatus.inactive);
      today(c).chooseIntention(Intention.moreEnergy);
      await R8Harness.settle();
      today(c).start();
      await R8Harness.settle();
      h.clock.value = closedAt;
      today(c).close();
      await R8Harness.settle();
      stored.add((await h.disk.stored())[recommendationClosedAtKey]);
    }
    expect(stored[0], isNot(stored[1]));
  });

  test('N09 — an older offset-free Start still reads as before (local), and '
      'the six-hour rule holds for it', () async {
    final h = R8Harness(DateTime(2026, 8, 2, 5, 9));
    await h.boot({
      recommendationDayKey: '2026-08-01',
      recommendationIntentionKey: 'moreEnergy',
      recommendationActivityIdKey: 'thirtyMinuteWalk',
      recommendationStatusKey: 'started',
      recommendationStartedAtKey: '2026-08-01T23:10:00.000',
    });
    final c = h.open(status: EntitlementStatus.inactive);
    final state = c.read(recommendationProvider);
    expect(state.recommendation?.circleId, '2026-08-01');
    expect(state.startedAt, DateTime(2026, 8, 1, 23, 10));
    await h.restart();
    h.clock.value = DateTime(2026, 8, 2, 5, 11);
    expect(
      h
          .open(status: EntitlementStatus.inactive)
          .read(recommendationProvider)
          .recommendation,
      isNull,
      reason: '6h01 after its Start',
    );
  });

  // ---------------------------------------------------------------- AUD-2
  Future<(ProviderContainer, void Function(DateTime))> carried(
    WidgetTester tester,
  ) async {
    var now = DateTime(2026, 8, 1, 23, 45);
    SharedPreferences.setMockInitialValues({
      firstNamePromptSeenKey: true,
      recommendationDayKey: '2026-08-01',
      recommendationIntentionKey: 'moreEnergy',
      recommendationActivityIdKey: 'thirtyMinuteWalk',
      recommendationStatusKey: 'started',
      recommendationStartedAtKey: DateTime(
        2026,
        8,
        1,
        23,
        40,
      ).toIso8601String(),
    });
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWith((ref) => now),
        eventClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const ThirtyApp()),
    );
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _settle(tester);
    now = DateTime(2026, 8, 2, 0, 10);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _settle(tester);
    expect(
      c.read(recommendationProvider).recommendation?.circleId,
      '2026-08-01',
      reason: 'yesterday\'s running Circle is carried over',
    );
    return (c, (DateTime t) => now = t);
  }

  for (final touch in [true, false]) {
    testWidgets('AUD-2 — the carried-over Circle finished and its reflection '
        'answered after midnight: today\'s Circle can be chosen without '
        'another resume (${touch ? 'with a touch' : 'no touch — screen '
                  'reader or switch'})', (tester) async {
      final (c, _) = await carried(tester);
      final n = c.read(recommendationProvider.notifier);
      n.close();
      await _settle(tester);
      n.reportAttempt(CircleAttemptResponse.yes);
      n.reportUsefulness(CircleUsefulnessResponse.veryUseful);
      await _settle(tester);
      if (touch) {
        await tester.tapAt(const Offset(5, 5));
        await _settle(tester);
      }
      n.chooseIntention(Intention.gentlerPace);
      await _settle(tester);
      expect(
        c.read(recommendationProvider).recommendation?.circleId,
        '2026-08-02',
      );
      // Yesterday stays recorded under its own day, with its answers.
      final yesterday = c
          .read(circleJournalRepositoryProvider)
          .readAll()
          .where((e) => e.circleId == '2026-08-01')
          .single;
      expect(yesterday.closedAt, isNotNull);
      expect(yesterday.usefulnessResponse, CircleUsefulnessResponse.veryUseful);
    });
  }

  testWidgets('AUD-2 regression — the carried-over Circle closed but its '
      'reflection still open stays on show (contract: until answered)', (
    tester,
  ) async {
    final (c, _) = await carried(tester);
    final n = c.read(recommendationProvider.notifier);
    n.close();
    await _settle(tester);
    await tester.tapAt(const Offset(5, 5));
    await _settle(tester);
    n.chooseIntention(Intention.gentlerPace);
    await _settle(tester);
    expect(
      c.read(recommendationProvider).recommendation?.circleId,
      '2026-08-01',
    );
    expect(c.read(recommendationProvider).status, RecommendationStatus.closed);
  });
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump();
  }
}
