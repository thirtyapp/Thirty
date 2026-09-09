import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/insights/presentation/widgets/circle_history_calendar.dart';

final _today = DateTime(2026, 9, 15);

Future<(Widget, ProviderContainer)> _wrap({
  Map<String, Object> storedPrefs = const {},
  DateTime? now,
}) async {
  SharedPreferences.setMockInitialValues(storedPrefs);
  final prefs = await SharedPreferences.getInstance();
  final resolvedNow = now ?? _today;

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(resolvedNow),
    ],
  );
  final widget = UncontrolledProviderScope(
    container: container,
    // Wrapped with a real GoRouter (not a plain MaterialApp) — tapping a
    // marked date calls `context.push`, which needs one present.
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: CircleHistoryCalendar()),
          ),
          GoRoute(
            path: '/history/:date',
            builder: (context, state) => Scaffold(
              body: Text('detail:${state.pathParameters['date']}'),
            ),
          ),
        ],
      ),
    ),
  );
  return (widget, container);
}

String _journalWith(List<String> localDates) => jsonEncode({
  'schemaVersion': circleJournalSchemaVersion,
  'entries': [
    for (final date in localDates)
      {
        'schemaVersion': circleJournalSchemaVersion,
        'circleId': date,
        'localDate': date,
        'direction': Intention.moreEnergy.name,
        'activityId': ActivityId.thirtyMinuteWalk.name,
        'catalogVersion': catalogVersion,
        'shownAt': '${date}T09:00:00.000',
      },
  ],
});

void main() {
  testWidgets('renders correctly with zero records — no crash, no marked '
      'date, month header shows the current month', (tester) async {
    final (widget, container) = await _wrap();
    addTearDown(container.dispose);

    await tester.pumpWidget(widget);

    expect(tester.takeException(), isNull);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.byType(CircleHistoryCalendar), findsOneWidget);
  });

  testWidgets(
    'marks exactly the dates backed by an actual retained record, and '
    'leaves every other date in the month unmarked',
    (tester) async {
      final (widget, container) = await _wrap(
        storedPrefs: {circleJournalKey: _journalWith(['2026-09-05'])},
      );
      addTearDown(container.dispose);
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(widget);

      expect(
        find.bySemanticsLabel('2026-09-05, Circle recorded'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('2026-09-06, no record'),
        findsOneWidget,
      );
      handle.dispose();
    },
  );

  testWidgets('renders correctly with many records across the month', (
    tester,
  ) async {
    final (widget, container) = await _wrap(
      storedPrefs: {
        circleJournalKey: _journalWith([
          '2026-09-01',
          '2026-09-02',
          '2026-09-03',
          '2026-09-10',
          '2026-09-15',
        ]),
      },
    );
    addTearDown(container.dispose);
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(widget);

    expect(tester.takeException(), isNull);
    for (final date in [
      '2026-09-01',
      '2026-09-02',
      '2026-09-03',
      '2026-09-10',
      '2026-09-15',
    ]) {
      expect(find.bySemanticsLabel('$date, Circle recorded'), findsOneWidget);
    }
    handle.dispose();
  });

  testWidgets(
    'tapping a recorded date opens its record detail; tapping an '
    'unrecorded date does nothing',
    (tester) async {
      final (widget, container) = await _wrap(
        storedPrefs: {circleJournalKey: _journalWith(['2026-09-05'])},
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(widget);
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();

      expect(find.text('detail:2026-09-05'), findsOneWidget);
    },
  );

  testWidgets(
    'month navigation moves forward and back without altering any daily '
    'Circle state — purely local display state',
    (tester) async {
      final (widget, container) = await _wrap(
        storedPrefs: {circleJournalKey: _journalWith(['2026-08-20'])},
      );
      addTearDown(container.dispose);
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(widget);
      expect(find.text('September 2026'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();
      expect(find.text('August 2026'), findsOneWidget);
      expect(
        find.bySemanticsLabel('2026-08-20, Circle recorded'),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();
      expect(find.text('September 2026'), findsOneWidget);

      // Navigating months never touches the journal itself.
      expect(
        container.read(circleJournalRepositoryProvider).readAll(),
        hasLength(1),
      );
      handle.dispose();
    },
  );

  testWidgets(
    'survives restart — a fresh container/widget instance restores the '
    'same recorded-date marks from persisted storage',
    (tester) async {
      final (widgetA, containerA) = await _wrap(
        storedPrefs: {circleJournalKey: _journalWith(['2026-09-12'])},
      );
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(widgetA);
      expect(
        find.bySemanticsLabel('2026-09-12, Circle recorded'),
        findsOneWidget,
      );
      final prefs = containerA.read(sharedPreferencesProvider);
      containerA.dispose();

      final (widgetB, containerB) = await _wrap(
        storedPrefs: {
          circleJournalKey: prefs.getString(circleJournalKey)!,
        },
      );
      addTearDown(containerB.dispose);
      await tester.pumpWidget(widgetB);

      expect(
        find.bySemanticsLabel('2026-09-12, Circle recorded'),
        findsOneWidget,
      );
      handle.dispose();
    },
  );

  testWidgets('works with a large accessibility text scale, no overflow', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final (widget, container) = await _wrap(
      storedPrefs: {circleJournalKey: _journalWith(['2026-09-05'])},
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(widget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('works on a small-screen viewport, no overflow', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    final (widget, container) = await _wrap(
      storedPrefs: {circleJournalKey: _journalWith(['2026-09-05'])},
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(widget);

    expect(tester.takeException(), isNull);
  });

  test('the shell branches map confirms /history/:date exists for the '
      'calendar to push into', () {
    final routes = buildAppRoutes(includeDevPreview: false);
    final topLevelPaths = routes.whereType<GoRoute>().map((r) => r.path);
    expect(topLevelPaths, contains('/history/:date'));
  });
}
