import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/insights/presentation/widgets/circle_history_calendar.dart';

/// The calendar's three date states (founder decision, 2026-10-02):
/// closed → the ring; recorded but not closed → a small neutral dot;
/// no record → nothing. Both recorded states stay tappable, and no record
/// is hidden, deleted or migrated.

final _today = DateTime(2026, 9, 15);

const _closed = '2026-09-05';
const _shownOnly = '2026-09-08';
const _startedOnly = '2026-09-10';
const _empty = '2026-09-06';

Map<String, Object?> _entry(
  String date, {
  bool started = false,
  bool closed = false,
}) => {
  'schemaVersion': circleJournalSchemaVersion,
  'circleId': date,
  'localDate': date,
  'direction': Intention.moreEnergy.name,
  'activityId': ActivityId.thirtyMinuteWalk.name,
  'catalogVersion': catalogVersion,
  'shownAt': '${date}T09:00:00.000',
  if (started || closed) 'startedAt': '${date}T09:05:00.000',
  if (closed) 'closedAt': '${date}T09:35:00.000',
};

String _journal() => jsonEncode({
  'schemaVersion': circleJournalSchemaVersion,
  'entries': [
    _entry(_closed, closed: true),
    _entry(_shownOnly),
    _entry(_startedOnly, started: true),
  ],
});

String _spoken(String key) =>
    const DefaultMaterialLocalizations().formatFullDate(DateTime.parse(key));

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  double width = 412,
}) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({circleJournalKey: _journal()});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_today),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: GoRouter(
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
    ),
  );
  await tester.pump();
  return container;
}

Finder _cell(String key, String state) =>
    find.bySemanticsLabel('${_spoken(key)}, $state');

/// The closed-Circle ring: a circle with a border.
Finder _ringIn(Finder cell) => find.descendant(
  of: cell,
  matching: find.byWidgetPredicate((widget) {
    final decoration = switch (widget) {
      DecoratedBox(:final decoration) => decoration,
      Container(:final decoration) => decoration,
      _ => null,
    };
    return decoration is BoxDecoration &&
        decoration.shape == BoxShape.circle &&
        decoration.border != null;
  }),
);

/// The recorded-not-closed dot: a small filled circle in the neutral
/// secondary text colour, never the primary.
Finder _dotIn(Finder cell, AppColors colors) => find.descendant(
  of: cell,
  matching: find.byWidgetPredicate((widget) {
    final decoration = widget is Container ? widget.decoration : null;
    return decoration is BoxDecoration &&
        decoration.shape == BoxShape.circle &&
        decoration.border == null &&
        decoration.color == colors.textSecondary;
  }),
);

void main() {
  testWidgets('each date announces its state: closed, recorded not '
      'closed, or no Circle recorded', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    expect(_cell(_closed, 'Circle closed'), findsOneWidget);
    expect(_cell(_shownOnly, 'Circle recorded, not closed'), findsOneWidget);
    // Started but never closed is still not closed.
    expect(_cell(_startedOnly, 'Circle recorded, not closed'), findsOneWidget);
    expect(_cell(_empty, 'no Circle recorded'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('closed → the ring only; recorded not closed → the dot only; '
      'no record → no marker', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    final colors = AppTheme.light.extension<AppColors>()!;

    final closed = _cell(_closed, 'Circle closed');
    expect(_ringIn(closed), findsOneWidget);
    expect(_dotIn(closed, colors), findsNothing);

    for (final key in [_shownOnly, _startedOnly]) {
      final unclosed = _cell(key, 'Circle recorded, not closed');
      expect(_ringIn(unclosed), findsNothing, reason: key);
      expect(_dotIn(unclosed, colors), findsOneWidget, reason: key);
    }

    final empty = _cell(_empty, 'no Circle recorded');
    expect(_ringIn(empty), findsNothing);
    expect(_dotIn(empty, colors), findsNothing);
    semantics.dispose();
  });

  for (final (key, state) in [
    (_closed, 'Circle closed'),
    (_shownOnly, 'Circle recorded, not closed'),
  ]) {
    testWidgets('a $state date opens its record detail', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);

      expect(
        tester.getSemantics(_cell(key, state)),
        isSemantics(isButton: true, hasTapAction: true),
      );
      await tester.tap(_cell(key, state));
      await tester.pumpAndSettle();
      expect(find.text('detail:$key'), findsOneWidget);
      semantics.dispose();
    });
  }

  testWidgets('a date with no record is not a button and opens nothing', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    expect(
      tester.getSemantics(_cell(_empty, 'no Circle recorded')),
      isSemantics(isButton: false, hasTapAction: false),
    );
    await tester.tap(_cell(_empty, 'no Circle recorded'));
    await tester.pumpAndSettle();
    expect(find.textContaining('detail:'), findsNothing);
    semantics.dispose();
  });

  testWidgets('the narrow list keeps both recorded states, each tappable '
      'with its own label', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, width: 320);

    expect(find.text('M'), findsNothing, reason: 'the list, not the grid');
    expect(_cell(_closed, 'Circle closed'), findsOneWidget);
    expect(_cell(_shownOnly, 'Circle recorded, not closed'), findsOneWidget);
    expect(_cell(_startedOnly, 'Circle recorded, not closed'), findsOneWidget);

    await tester.tap(_cell(_shownOnly, 'Circle recorded, not closed'));
    await tester.pumpAndSettle();
    expect(find.text('detail:$_shownOnly'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('closing a recorded Circle turns its dot into the ring', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final container = await _pump(tester);

    await container
        .read(circleJournalRepositoryProvider)
        .recordClosed(
          circleId: _shownOnly,
          localDate: _shownOnly,
          direction: Intention.moreEnergy,
          activityId: ActivityId.thirtyMinuteWalk,
          closedAt: DateTime(2026, 9, 8, 9, 40),
        );
    container.invalidate(circleJournalRepositoryProvider);
    await tester.pump();

    expect(_cell(_shownOnly, 'Circle closed'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('no record is hidden or changed: the journal still holds '
      'every entry, closed or not', (tester) async {
    final container = await _pump(tester);
    final entries = container.read(circleJournalRepositoryProvider).readAll();
    expect(entries.map((e) => e.localDate), [
      _closed,
      _shownOnly,
      _startedOnly,
    ]);
    expect(entries.map((e) => e.closedAt != null), [true, false, false]);
  });
}
