import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

/// Circle History calendar accessibility, with the app's real fonts:
/// 48×48pt targets in both presentations, numbers at the user's text size,
/// human-readable spoken dates — the 7-column grid from 360pt (its own
/// inset narrowing to 12pt there), the recorded-date list below that.

final _today = DateTime(2026, 9, 15);

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(file).readAsBytesSync())),
    );
  }
  await loader.load();
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
        // Closed: these tests cover the ring and its detail; the
        // recorded-but-not-closed state has its own tests.
        'closedAt': '${date}T09:30:00.000',
      },
  ],
});

String _spoken(String dateKey) => const DefaultMaterialLocalizations()
    .formatFullDate(DateTime.parse(dateKey));

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required double textScale,
  List<String> recorded = const ['2026-09-05', '2026-09-12'],
  ThemeData? theme,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({
    circleJournalKey: _journalWith(recorded),
  });
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
        theme: theme ?? AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Scaffold(
                body: SingleChildScrollView(child: CircleHistoryCalendar()),
              ),
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
}

Finder get _calendar => find.byType(CircleHistoryCalendar);

/// Every interactive date: the tappable surface (InkWell) inside the
/// calendar — excluding the two month-navigation buttons (checked
/// separately).
Iterable<Rect> _targets(WidgetTester tester) {
  final navigation = find
      .descendant(of: find.byType(IconButton), matching: find.byType(InkWell))
      .evaluate()
      .map((e) => e.widget)
      .toSet();
  return find
      .descendant(of: _calendar, matching: find.byType(InkWell))
      .evaluate()
      .where((e) => !navigation.contains(e.widget))
      .map((e) => tester.getRect(find.byWidget(e.widget)));
}

/// Month navigation keeps Material's padded 48pt tap target.
void _expectNavigationTargets(WidgetTester tester) {
  for (final element in find.byType(IconButton).evaluate()) {
    final size = tester.getSize(find.byWidget(element.widget));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  }
}

void _expectNoTruncationOrOverflow(WidgetTester tester) {
  expect(tester.takeException(), isNull);
  _expectNavigationTargets(tester);
  final truncated = [
    for (final element
        in find
            .descendant(of: _calendar, matching: find.byType(RichText))
            .evaluate())
      if ((element.renderObject! as RenderParagraph).didExceedMaxLines)
        (element.renderObject! as RenderParagraph).text.toPlainText(),
  ];
  expect(truncated, isEmpty);
}

void main() {
  setUpAll(() async {
    await _loadFont('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ]);
  });

  group('Grid mode (360pt and wider)', () {
    for (final (width, scale) in [(360.0, 1.0), (360.0, 2.0), (412.0, 1.0)]) {
      testWidgets(
        '${width.toInt()}pt at ${(scale * 100).toInt()}%: the 7-column '
        'grid, every interactive day at least 48×48',
        (tester) async {
          await _pump(tester, width: width, textScale: scale);

          // The grid, not the list.
          expect(find.text('M'), findsOneWidget);
          final targets = _targets(tester).toList();
          expect(targets, hasLength(2));
          for (final target in targets) {
            expect(target.width, greaterThanOrEqualTo(48));
            expect(target.height, greaterThanOrEqualTo(48));
          }
          if (width == 360) {
            // The calendar alone narrows its inset to 12pt: 336pt, seven 48s.
            expect(targets.first.width, closeTo(48, 0.01));
          }
          _expectNoTruncationOrOverflow(tester);
        },
      );
    }

    testWidgets('numbers follow the user\'s text size — never shrunk to fit', (
      tester,
    ) async {
      await _pump(tester, width: 360, textScale: 2.0);

      expect(
        find.descendant(of: _calendar, matching: find.byType(FittedBox)),
        findsNothing,
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: _calendar, matching: find.text('15')),
      );
      expect(paragraph.textScaler.scale(1), 2.0);
      // Rendered at full size: 14pt body text × 2.
      expect(tester.getSize(find.text('15')).height, greaterThanOrEqualTo(27));
    });

    testWidgets('spoken dates are human-readable, recorded and unrecorded', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, width: 360, textScale: 1.0);

      expect(
        find.bySemanticsLabel('${_spoken('2026-09-05')}, Circle closed'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('${_spoken('2026-09-06')}, no Circle recorded'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp(r'\d{4}-\d{2}-\d{2}')), findsNothing);
      semantics.dispose();
    });

    testWidgets('a recorded date still opens its read-only detail (200%)', (
      tester,
    ) async {
      await _pump(tester, width: 360, textScale: 2.0);
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();
      expect(find.text('detail:2026-09-12'), findsOneWidget);
    });

    testWidgets('dark mode: same geometry, nothing truncated', (tester) async {
      await _pump(tester, width: 360, textScale: 2.0, theme: AppTheme.dark);
      for (final target in _targets(tester)) {
        expect(target.width, greaterThanOrEqualTo(48));
        expect(target.height, greaterThanOrEqualTo(48));
      }
      _expectNoTruncationOrOverflow(tester);
    });
  });

  group('List fallback (below 336pt of calendar width)', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets('320pt at ${(scale * 100).toInt()}%: recorded dates as '
          'full-width rows, each at least 48pt tall', (tester) async {
        await _pump(tester, width: 320, textScale: scale);

        expect(find.text('M'), findsNothing, reason: 'no month grid');
        final targets = _targets(tester).toList();
        expect(targets, hasLength(2));
        for (final target in targets) {
          expect(target.height, greaterThanOrEqualTo(48));
          expect(target.width, greaterThanOrEqualTo(48));
          expect(target.width, 320 - AppSpacing.page * 2);
        }
        expect(find.text(_spoken('2026-09-05')), findsOneWidget);
        expect(find.text(_spoken('2026-09-12')), findsOneWidget);
        _expectNoTruncationOrOverflow(tester);
      });
    }

    testWidgets('a row opens the same detail; month navigation unchanged', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        width: 320,
        textScale: 2.0,
        recorded: const ['2026-08-20', '2026-09-12'],
      );

      expect(
        find.bySemanticsLabel('${_spoken('2026-09-12')}, Circle closed'),
        findsOneWidget,
      );
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();
      expect(find.text('August 2026'), findsOneWidget);
      expect(find.text(_spoken('2026-08-20')), findsOneWidget);
      expect(find.text(_spoken('2026-09-12')), findsNothing);

      await tester.tap(find.text(_spoken('2026-08-20')));
      await tester.pumpAndSettle();
      expect(find.text('detail:2026-08-20'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a month with nothing recorded says so, claiming no Circle', (
      tester,
    ) async {
      await _pump(tester, width: 320, textScale: 2.0, recorded: const []);
      expect(find.text('No Circles recorded this month.'), findsOneWidget);
      expect(_targets(tester), isEmpty);
      _expectNoTruncationOrOverflow(tester);
    });
  });
}
