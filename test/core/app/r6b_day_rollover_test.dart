import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/plans/presentation/plans_page.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';

class _Clock {
  _Clock(this.value);
  DateTime value;
}

/// Audit remediation R6b (Audit #2 A2-11): THIRTY kept in the foreground
/// across local midnight. The first touch after midnight opens the new day
/// without a resume — and never swallows what it was for:
/// - nothing of the old day on show: the day is re-read as the touch begins;
/// - otherwise the touch acts first (Start, a tab, a reflection answer),
///   then the new day opens;
/// - never while a Circle runs (it keeps its own day until Close, recorded
///   once), nor while a Circle closed after midnight waits for its
///   reflection.
void main() {
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

  Map<String, Object> day1(String status, {DateTime? closedAt}) => {
    recommendationDayKey: '2026-08-01',
    recommendationIntentionKey: 'moreEnergy',
    recommendationActivityIdKey: 'thirtyMinuteWalk',
    recommendationStatusKey: status,
    if (status != 'notStarted')
      recommendationStartedAtKey: DateTime(
        2026,
        8,
        1,
        23,
        40,
      ).toIso8601String(),
    if (closedAt != null) recommendationClosedAtKey: closedAt.toIso8601String(),
  };

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump();
    }
  }

  testWidgets('yesterday\'s closed Circle on show: the first touch opens the '
      'new day, without a resume; a same-day touch changes nothing', (
    tester,
  ) async {
    final o = await open(
      tester,
      day1('closed', closedAt: DateTime(2026, 8, 1, 23, 55)),
      DateTime(2026, 8, 1, 23, 58),
    );
    await tester.tapAt(const Offset(5, 5));
    await settle(tester);
    expect(
      o.c.read(recommendationProvider).status,
      RecommendationStatus.closed,
    );
    o.clock.value = DateTime(2026, 8, 2, 0, 3);
    await tester.tapAt(const Offset(5, 5));
    await settle(tester);
    final today = o.c.read(recommendationProvider);
    expect(today.recommendation, isNull);
    expect(today.status, RecommendationStatus.notStarted);
  });

  testWidgets('the first touch is a tab: it still changes tab, and the new '
      'day opens', (tester) async {
    final o = await open(
      tester,
      day1('closed', closedAt: DateTime(2026, 8, 1, 23, 55)),
      DateTime(2026, 8, 1, 23, 58),
    );
    o.clock.value = DateTime(2026, 8, 2, 0, 3);
    await tester.tap(find.text('Plans').last);
    await tester.pumpAndSettle();
    expect(find.byType(PlansPage), findsOneWidget);
    expect(o.c.read(recommendationProvider).recommendation, isNull);
  });

  testWidgets('Start on yesterday\'s unstarted offer after midnight: nothing '
      'starts — the new day opens; today\'s Circle is then started '
      'deliberately (founder rule, R6 final)', (tester) async {
    // A bare page with a Start button, under the real ThirtyApp and its
    // touch listener: the Today screen's own entry ritual isn't under test.
    final clock = _Clock(DateTime(2026, 8, 1, 23, 50));
    SharedPreferences.setMockInitialValues({firstNamePromptSeenKey: true});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWith((ref) => clock.value),
        eventClockProvider.overrideWithValue(() => clock.value),
      ],
    );
    addTearDown(c.dispose);
    c
        .read(recommendationProvider.notifier)
        .chooseIntention(Intention.moreEnergy, window: TimeWindow.about10);
    expect(c.read(recommendationProvider).recommendation, isNotNull);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: ThirtyApp(
          router: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => Consumer(
                  builder: (context, ref, _) => Scaffold(
                    body: Center(
                      child: TextButton(
                        onPressed: () =>
                            ref.read(recommendationProvider.notifier).start(),
                        child: const Text('Start'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    clock.value = DateTime(2026, 8, 2, 0, 2);
    await tester.tap(find.text('Start'));
    await settle(tester);
    // Yesterday's offer didn't start, and today's didn't start either.
    final opened = c.read(recommendationProvider);
    expect(opened.status, RecommendationStatus.notStarted);
    expect(opened.recommendation, isNull);
    final journal = c.read(circleJournalRepositoryProvider).readAll();
    expect(journal.single.localDate, '2026-08-01');
    expect(journal.single.startedAt, isNull);
    // The user chooses today's Circle and starts it: today's day.
    c
        .read(recommendationProvider.notifier)
        .chooseIntention(Intention.moreEnergy, window: TimeWindow.about10);
    await settle(tester);
    await tester.tap(find.text('Start'));
    await settle(tester);
    final today = c.read(recommendationProvider);
    expect(today.status, RecommendationStatus.started);
    expect(today.recommendation!.circleId, '2026-08-02');
    final after = c.read(circleJournalRepositoryProvider).readAll();
    expect(after.map((e) => e.localDate), ['2026-08-01', '2026-08-02']);
    expect(after.first.startedAt, isNull);
  });

  testWidgets('a screen reader\'s Start (no touch) on yesterday\'s offer '
      'after midnight: nothing starts either', (tester) async {
    final o = await open(tester, const {}, DateTime(2026, 8, 1, 23, 50));
    final today = o.c.read(recommendationProvider.notifier);
    today.chooseIntention(Intention.moreEnergy, window: TimeWindow.about10);
    await settle(tester);
    o.clock.value = DateTime(2026, 8, 2, 0, 2);
    today.start();
    await settle(tester);
    expect(
      o.c.read(recommendationProvider).status,
      RecommendationStatus.notStarted,
    );
    expect(o.c.read(recommendationProvider).recommendation, isNull);
  });

  testWidgets('a restart after midnight with yesterday\'s unstarted offer '
      'stored: the new day, nothing started', (tester) async {
    final o = await open(tester, const {}, DateTime(2026, 8, 1, 23, 50));
    o.c
        .read(recommendationProvider.notifier)
        .chooseIntention(Intention.moreEnergy, window: TimeWindow.about10);
    await settle(tester);
    final prefs = await SharedPreferences.getInstance();
    final stored = <String, Object>{
      for (final k in prefs.getKeys()) k: prefs.get(k)!,
    };
    final again = await open(tester, stored, DateTime(2026, 8, 2, 0, 5));
    expect(again.c.read(recommendationProvider).recommendation, isNull);
    expect(
      again.c.read(recommendationProvider).status,
      RecommendationStatus.notStarted,
    );
  });

  testWidgets('nothing offered yet: the day is re-read as the touch begins, '
      'so the choice it makes is today\'s', (tester) async {
    final o = await open(tester, const {}, DateTime(2026, 8, 1, 23, 58));
    expect(o.c.read(recommendationProvider).recommendation, isNull);
    o.clock.value = DateTime(2026, 8, 2, 0, 2);
    final gesture = await tester.startGesture(const Offset(5, 5));
    expect(dateKey(o.c.read(nowProvider)), '2026-08-02');
    await gesture.up();
    await settle(tester);
  });

  testWidgets('a Circle running across midnight keeps its own day; closed '
      'after midnight, its reflection stays until answered; then the new '
      'day opens, and the Circle is recorded once, under its own day', (
    tester,
  ) async {
    final o = await open(tester, day1('started'), DateTime(2026, 8, 1, 23, 50));
    o.clock.value = DateTime(2026, 8, 2, 0, 10);
    await tester.tapAt(const Offset(5, 5));
    await settle(tester);
    expect(
      o.c.read(recommendationProvider).status,
      RecommendationStatus.started,
    );
    expect(
      o.c.read(recommendationProvider).recommendation!.circleId,
      '2026-08-01',
    );

    final today = o.c.read(recommendationProvider.notifier);
    today.close();
    await settle(tester);
    await tester.tapAt(const Offset(5, 5));
    await settle(tester);
    expect(
      o.c.read(recommendationProvider).status,
      RecommendationStatus.closed,
    );

    today.reportAttempt(CircleAttemptResponse.notToday);
    await settle(tester);
    await tester.tapAt(const Offset(5, 5));
    await settle(tester);
    expect(o.c.read(recommendationProvider).recommendation, isNull);

    final journal = o.c.read(circleJournalRepositoryProvider).readAll();
    expect(journal.where((e) => e.localDate == '2026-08-01'), hasLength(1));
    expect(journal.single.closedAt, isNotNull);
    expect(journal.single.attemptResponse, CircleAttemptResponse.notToday);
    expect(journal.where((e) => e.localDate == '2026-08-02'), isEmpty);
  });
}
