import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';

class _Clock {
  _Clock(this.value);
  DateTime value;
}

/// Audit remediation R8 — midnight without a touch:
/// - Astra R7-A08 / Claude F-1 (MEDIUM): a Circle started before midnight
///   stays the user's to Close and reflect on when THIRTY is resumed — or
///   restarted — after midnight; recorded once, under its own day;
/// - Claude F-2 (LOW): a choice made after midnight without a touch (screen
///   reader, keyboard, switch access) is today's, shown at its real time.
///
/// The touch-driven path is R6b's (`r6b_day_rollover_test.dart`); these
/// cases bring no pointer event at all.
void main() {
  final started = DateTime(2026, 8, 1, 23, 40);

  Future<({ProviderContainer c, _Clock clock})> open(
    WidgetTester tester,
    Map<String, Object> stored,
    DateTime at,
  ) async {
    final clock = _Clock(at);
    SharedPreferences.setMockInitialValues({
      firstNamePromptSeenKey: true,
      ...stored,
    });
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWith((ref) => clock.value),
        eventClockProvider.overrideWithValue(() => clock.value),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const ThirtyApp()),
    );
    await tester.pumpAndSettle();
    return (c: c, clock: clock);
  }

  Map<String, Object> session(
    String day,
    String status, {
    DateTime? startedAt,
    DateTime? closedAt,
    String? attempt,
  }) => {
    recommendationDayKey: day,
    recommendationIntentionKey: 'moreEnergy',
    recommendationActivityIdKey: 'thirtyMinuteWalk',
    recommendationStatusKey: status,
    if (startedAt != null)
      recommendationStartedAtKey: startedAt.toIso8601String(),
    if (closedAt != null) recommendationClosedAtKey: closedAt.toIso8601String(),
    recommendationAttemptResponseKey: ?attempt,
  };

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump();
    }
  }

  Future<void> background(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await settle(tester);
  }

  Future<void> resume(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester);
  }

  Future<Map<String, Object>> storedNow() async {
    final prefs = await SharedPreferences.getInstance();
    return {for (final k in prefs.getKeys()) k: prefs.get(k)!};
  }

  group('Astra R7-A08 / Claude F-1 — a Circle started before midnight', () {
    testWidgets('backgrounded, resumed after midnight: still running, its own '
        'day; Close and the reflection work; recorded once, under that day; '
        'no new Circle starts by itself', (tester) async {
      final o = await open(
        tester,
        session('2026-08-01', 'started', startedAt: started),
        DateTime(2026, 8, 1, 23, 45),
      );
      await background(tester);
      o.clock.value = DateTime(2026, 8, 2, 0, 10);
      await resume(tester);

      final state = o.c.read(recommendationProvider);
      expect(state.status, RecommendationStatus.started);
      expect(state.recommendation?.circleId, '2026-08-01');
      expect(state.startedAt, started);

      final today = o.c.read(recommendationProvider.notifier);
      today.close();
      await settle(tester);
      expect(
        o.c.read(recommendationProvider).status,
        RecommendationStatus.closed,
      );
      // Resumed again before the reflection is answered: it stays.
      await background(tester);
      o.clock.value = DateTime(2026, 8, 2, 0, 15);
      await resume(tester);
      expect(
        o.c.read(recommendationProvider).status,
        RecommendationStatus.closed,
      );
      today.reportAttempt(CircleAttemptResponse.yes);
      today.reportUsefulness(CircleUsefulnessResponse.veryUseful);
      await settle(tester);

      final journal = o.c.read(circleJournalRepositoryProvider).readAll();
      expect(journal, hasLength(1));
      expect(journal.single.localDate, '2026-08-01');
      expect(journal.single.startedAt, started);
      expect(journal.single.closedAt, isNotNull);
      expect(journal.single.usefulnessResponse, isNotNull);

      // Answered: the next resume opens the new day — nothing started.
      await background(tester);
      o.clock.value = DateTime(2026, 8, 2, 0, 30);
      await resume(tester);
      final next = o.c.read(recommendationProvider);
      expect(next.recommendation, isNull);
      expect(next.status, RecommendationStatus.notStarted);
    });

    testWidgets('restarted after midnight: still running, its own day', (
      tester,
    ) async {
      final o = await open(
        tester,
        session('2026-08-01', 'started', startedAt: started),
        DateTime(2026, 8, 2, 0, 10),
      );
      final state = o.c.read(recommendationProvider);
      expect(state.status, RecommendationStatus.started);
      expect(state.recommendation?.circleId, '2026-08-01');
      o.c.read(recommendationProvider.notifier).close();
      await settle(tester);
      final again = await open(
        tester,
        await storedNow(),
        DateTime(2026, 8, 2, 0, 20),
      );
      expect(
        again.c.read(recommendationProvider).status,
        RecommendationStatus.closed,
      );
      expect(
        again.c
            .read(circleJournalRepositoryProvider)
            .readAll()
            .single
            .localDate,
        '2026-08-01',
      );
    });

    testWidgets('closed after midnight, its reflection not answered: a resume '
        'keeps the reflection on show', (tester) async {
      final o = await open(
        tester,
        session(
          '2026-08-01',
          'closed',
          startedAt: started,
          closedAt: DateTime(2026, 8, 2, 0, 5),
        ),
        DateTime(2026, 8, 2, 0, 6),
      );
      await background(tester);
      o.clock.value = DateTime(2026, 8, 2, 0, 20);
      await resume(tester);
      final state = o.c.read(recommendationProvider);
      expect(state.status, RecommendationStatus.closed);
      expect(state.recommendation?.circleId, '2026-08-01');
    });

    testWidgets('closed on its own day: a resume after midnight opens the new '
        'day (unchanged)', (tester) async {
      final o = await open(
        tester,
        session(
          '2026-08-01',
          'closed',
          startedAt: started,
          closedAt: DateTime(2026, 8, 1, 23, 55),
        ),
        DateTime(2026, 8, 1, 23, 58),
      );
      o.clock.value = DateTime(2026, 8, 2, 0, 10);
      await resume(tester);
      expect(o.c.read(recommendationProvider).recommendation, isNull);
    });

    testWidgets('an offer never started: a resume after midnight opens the new '
        'day, and it can\'t be started (founder rule, unchanged)', (
      tester,
    ) async {
      final o = await open(
        tester,
        session('2026-08-01', 'notStarted'),
        DateTime(2026, 8, 1, 23, 58),
      );
      o.clock.value = DateTime(2026, 8, 2, 0, 10);
      await resume(tester);
      expect(o.c.read(recommendationProvider).recommendation, isNull);
    });

    testWidgets('started yesterday morning, never closed: opened the next '
        'morning, it is not brought back as running — beyond the carry-over '
        'limit, the new day opens', (tester) async {
      final o = await open(
        tester,
        session('2026-08-01', 'started', startedAt: DateTime(2026, 8, 1, 9)),
        DateTime(2026, 8, 2, 8),
      );
      expect(o.c.read(recommendationProvider).recommendation, isNull);
    });

    testWidgets('a Circle started two days before and never closed is not '
        'brought back as running', (tester) async {
      final o = await open(
        tester,
        session(
          '2026-07-31',
          'started',
          startedAt: DateTime(2026, 7, 31, 23, 40),
        ),
        DateTime(2026, 8, 2, 9),
      );
      expect(o.c.read(recommendationProvider).recommendation, isNull);
    });
  });

  group('Claude F-2 — a choice after midnight with no touch', () {
    testWidgets('screen reader, keyboard or switch: the Circle chosen is '
        'today\'s, and History says when it was really shown', (tester) async {
      final o = await open(tester, const {}, DateTime(2026, 8, 1, 23, 50));
      o.clock.value = DateTime(2026, 8, 2, 0, 10);
      o.c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy, window: TimeWindow.about10);
      await settle(tester);
      final offer = o.c.read(recommendationProvider).recommendation!;
      expect(offer.circleId, '2026-08-02');
      final journal = o.c.read(circleJournalRepositoryProvider).readAll();
      expect(journal.single.localDate, '2026-08-02');
      expect(journal.single.shownAt, DateTime(2026, 8, 2, 0, 10));
      // And it starts: it is today's.
      o.c.read(recommendationProvider.notifier).start();
      await settle(tester);
      expect(
        o.c.read(recommendationProvider).status,
        RecommendationStatus.started,
      );
    });

    testWidgets('on an ordinary day, the time shown is the choice\'s own, not '
        'when the app came to the foreground', (tester) async {
      final o = await open(tester, const {}, DateTime(2026, 8, 1, 9));
      o.clock.value = DateTime(2026, 8, 1, 9, 40);
      o.c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy, window: TimeWindow.about10);
      await settle(tester);
      final journal = o.c.read(circleJournalRepositoryProvider).readAll();
      expect(journal.single.shownAt, DateTime(2026, 8, 1, 9, 40));
    });
  });
}
