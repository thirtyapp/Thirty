import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/presentation/circle_record_detail_page.dart';
import 'package:thirty/features/home/presentation/memory_page.dart';
import 'package:thirty/features/home/presentation/widgets/journal_data_controls.dart';
import 'package:thirty/features/settings/presentation/widgets/you_personal_card.dart';

/// V2 Phase C on screen (ADR-021): "What THIRTY remembers", its
/// corrections, History's "Remove this answer", the way in from You, and
/// Delete's truthful confirmation.

final _now = DateTime(2026, 11, 20, 18);

/// One past Circle, answered as given.
Map<String, Object?> _entry(
  String date,
  Intention need,
  ActivityId activity, {
  String? attempt,
  String? usefulness,
}) => CircleJournalEntry(
  schemaVersion: circleJournalSchemaVersion,
  circleId: date,
  localDate: date,
  direction: need,
  activityId: activity,
  catalogVersion: catalogVersion,
  shownAt: DateTime.parse('${date}T08:00:00'),
  startedAt: DateTime.parse('${date}T08:01:00'),
  closedAt: DateTime.parse('${date}T08:20:00'),
  attemptResponse: CircleAttemptResponse.values.asNameMap()[attempt],
  usefulnessResponse: CircleUsefulnessResponse.values.asNameMap()[usefulness],
  timeWindow: 'about20',
  offeredMinutes: 15,
).toJson();

final _journal = jsonEncode({
  'schemaVersion': circleJournalSchemaVersion,
  'entries': [
    _entry(
      '2026-11-08',
      Intention.clearerHead,
      ActivityId.quietReading,
      attempt: 'yes',
      usefulness: 'somewhatUseful',
    ),
    _entry(
      '2026-11-11',
      Intention.clearerHead,
      ActivityId.writeItDown,
      attempt: 'yes',
      usefulness: 'veryUseful',
    ),
    _entry(
      '2026-11-17',
      Intention.clearerHead,
      ActivityId.tidyOneSurface,
      attempt: 'aLittle',
      usefulness: 'notUseful',
    ),
    _entry(
      '2026-11-19',
      Intention.moreEnergy,
      ActivityId.thirtyMinuteWalk,
      attempt: 'yes',
      usefulness: 'veryUseful',
    ),
    // The latest Circle is Clearer Head, so memory opens on it.
    _entry('2026-11-20', Intention.clearerHead, ActivityId.singleTaskFocus),
  ],
});

Future<(Widget, ProviderContainer)> _app(
  Widget home, {
  Map<String, Object> stored = const {},
  double textScale = 1,
}) async {
  SharedPreferences.setMockInitialValues({
    circleJournalKey: _journal,
    ...stored,
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_now),
      eventClockProvider.overrideWithValue(() => _now),
      safetyPendingAllowedProvider.overrideWithValue(false),
    ],
  );
  return (
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home,
      ),
    ),
    container,
  );
}

void _useS25(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('What THIRTY remembers', () {
    testWidgets('per need, in the user\'s own words: useful before, resting '
        'for now — and nothing for an unanswered Circle', (tester) async {
      _useS25(tester);
      final semantics = tester.ensureSemantics();
      final (app, c) = await _app(const MemoryPage());
      addTearDown(c.dispose);
      await tester.pumpWidget(app);

      expect(find.text(MemoryPage.title), findsOneWidget);
      expect(find.text('USEFUL BEFORE'), findsOneWidget);
      expect(find.text('Write it down'), findsOneWidget);
      expect(
        find.text('You said very useful · 11\u00A0November'),
        findsOneWidget,
      );
      expect(
        find.text('You said somewhat useful · 8\u00A0November'),
        findsOneWidget,
      );
      expect(find.text('RESTING FOR NOW'), findsOneWidget);
      expect(
        find.text('You said not useful · resting until 1\u00A0December'),
        findsOneWidget,
      );
      // Started and closed but not answered: never "not tried", never
      // anything.
      expect(find.text('One task, full attention'), findsNothing);
      expect(find.textContaining('Not tried'), findsNothing);
      // The brisk walk was useful for More Energy — not shown for this need.
      expect(find.text('A brisk walk'), findsNothing);
      // Headings are headings; items say what they are.
      expect(
        tester.getSemantics(find.bySemanticsLabel('Useful before')),
        matchesSemantics(label: 'Useful before', isHeader: true),
      );
      expect(
        tester.getSemantics(
          find.bySemanticsLabel(
            'Write it down. You said very useful · 11\u00A0November',
          ),
        ),
        matchesSemantics(
          label: 'Write it down. You said very useful · 11\u00A0November',
          isButton: true,
          hasTapAction: true,
        ),
      );
      // No scores, counts, charts or profile words.
      for (final word in ['%', 'score', 'profile', 'detected', 'behaviour']) {
        expect(find.textContaining(word), findsNothing, reason: word);
      }

      await tester.tap(find.text('More Energy'));
      await tester.pump();
      expect(find.text('A brisk walk'), findsOneWidget);
      expect(find.text('Write it down'), findsNothing);

      await tester.tap(find.text('Gentler Pace'));
      await tester.pump();
      expect(
        find.textContaining('Nothing yet for Gentler Pace'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('with nothing to reset, there is no reset control at all', (
      tester,
    ) async {
      _useS25(tester);
      final (app, c) = await _app(const MemoryPage());
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.scrollUntilVisible(
        find.textContaining('Some activities'),
        200,
      );
      expect(find.text('Reset suggestion preferences'), findsNothing);
    });

    testWidgets('"Suggest again" on a rest lifts it — the answer stays', (
      tester,
    ) async {
      _useS25(tester);
      final (app, c) = await _app(const MemoryPage());
      addTearDown(c.dispose);
      await tester.pumpWidget(app);

      await tester.tap(find.text('Tidy one surface'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('It’s resting until 1\u00A0December'),
        findsOneWidget,
      );
      expect(find.text('WHAT YOU SAID'), findsOneWidget);
      await tester.tap(find.text('Suggest again'));
      await tester.pumpAndSettle();

      expect(find.text('RESTING FOR NOW'), findsNothing);
      expect(find.text('NOT USEFUL BEFORE'), findsOneWidget);
      final lifted = c.read(suggestionPreferencesProvider).restsLifted.single;
      expect(lifted.activity, ActivityId.tidyOneSurface);
      expect(lifted.need, Intention.clearerHead);
      // History is not rewritten.
      expect(
        c
            .read(circleJournalRepositoryProvider)
            .readAll()
            .firstWhere((e) => e.activityId == ActivityId.tidyOneSurface)
            .usefulnessResponse,
        CircleUsefulnessResponse.notUseful,
      );
    });

    testWidgets('"Don\'t suggest" is the user\'s own choice, shown as such; '
        '"Suggest again" reverses it — and nothing else', (tester) async {
      _useS25(tester);
      final (app, c) = await _app(const MemoryPage());
      addTearDown(c.dispose);
      await tester.pumpWidget(app);

      await tester.tap(find.text('Write it down'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Don’t suggest it for Clearer Head'));
      await tester.pumpAndSettle();

      expect(find.text('NOT SUGGESTED, AS YOU ASKED'), findsOneWidget);
      expect(
        find.text('You asked THIRTY not to suggest it for Clearer Head'),
        findsOneWidget,
      );
      expect(
        c
            .read(suggestionPreferencesProvider)
            .isNotSuggested(ActivityId.writeItDown, Intention.clearerHead),
        isTrue,
      );
      // Per need: More Energy is untouched.
      expect(
        c
            .read(suggestionPreferencesProvider)
            .isNotSuggested(ActivityId.writeItDown, Intention.moreEnergy),
        isFalse,
      );

      await tester.tap(find.text('Write it down'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suggest again'));
      await tester.pumpAndSettle();
      expect(c.read(suggestionPreferencesProvider).isEmpty, isTrue);
      expect(find.text('USEFUL BEFORE'), findsOneWidget);
    });

    testWidgets('an answer can be removed from its detail; memory follows', (
      tester,
    ) async {
      _useS25(tester);
      final (app, c) = await _app(const MemoryPage());
      addTearDown(c.dispose);
      await tester.pumpWidget(app);

      await tester.tap(find.text('Quiet reading'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.text('Remove this answer?'), findsOneWidget);
      await tester.tap(find.text('Remove answer'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 50));

      final reading = c
          .read(circleJournalRepositoryProvider)
          .readAll()
          .firstWhere((e) => e.activityId == ActivityId.quietReading);
      expect(reading.usefulnessResponse, isNull);
      expect(reading.closedAt, isNotNull);
      // Closing the sheet: Quiet reading is no longer remembered.
      await tester.tapAt(const Offset(200, 40));
      await tester.pumpAndSettle();
      expect(find.text('Quiet reading'), findsNothing);
    });

    testWidgets('Reset suggestion preferences: its own control, its own '
        'truthful confirmation; history stays', (tester) async {
      _useS25(tester);
      final (app, c) = await _app(
        const MemoryPage(),
        stored: {
          suggestionPreferencesKey: jsonEncode(
            SuggestionPreferences(
              notSuggested: [
                NotSuggested(
                  activity: ActivityId.moveToMusic,
                  need: Intention.moreEnergy,
                  since: _now,
                ),
              ],
            ).toJson(),
          ),
        },
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);

      await tester.scrollUntilVisible(
        find.text('Reset suggestion preferences'),
        200,
      );
      await tester.tap(find.text('Reset suggestion preferences'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Your Circle history and your answers stay.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(c.read(suggestionPreferencesProvider).isEmpty, isTrue);
      expect(c.read(circleJournalRepositoryProvider).readAll(), hasLength(5));
    });

    testWidgets('at 130% and 200% text nothing overflows or is cut off', (
      tester,
    ) async {
      _useS25(tester);
      for (final scale in [1.3, 2.0]) {
        final (app, c) = await _app(const MemoryPage(), textScale: scale);
        addTearDown(c.dispose);
        await tester.pumpWidget(app);
        expect(tester.takeException(), isNull, reason: '$scale');
        await tester.scrollUntilVisible(find.text('Tidy one surface'), 200);
        await tester.tap(find.text('Tidy one surface'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$scale sheet');
        await tester.tapAt(const Offset(200, 40));
        await tester.pumpAndSettle();
      }
    });
  });

  group('History: "Remove this answer"', () {
    testWidgets('removes one answer — or the attempt and its usefulness — '
        'and keeps the Circle\'s record', (tester) async {
      _useS25(tester);
      final (app, c) = await _app(
        const CircleRecordDetailPage(localDate: '2026-11-11'),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);

      expect(find.text('Remove'), findsNWidgets(2));
      await tester.tap(find.text('Remove').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove answer'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 50));
      var entry = c
          .read(circleJournalRepositoryProvider)
          .readAll()
          .firstWhere((e) => e.circleId == '2026-11-11');
      expect(entry.usefulnessResponse, isNull);
      expect(entry.attemptResponse, CircleAttemptResponse.yes);

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove answer'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 50));
      entry = c
          .read(circleJournalRepositoryProvider)
          .readAll()
          .firstWhere((e) => e.circleId == '2026-11-11');
      expect(entry.attemptResponse, isNull);
      // The record itself: still there, still truthful.
      expect(find.text('Write it down'), findsOneWidget);
      expect(find.text('Started at 08:01, closed at 08:20.'), findsOneWidget);
      expect(
        find.textContaining('Not answered', findRichText: true),
        findsNWidgets(2),
      );
    });
  });

  group('the way in, and Delete\'s truthful confirmation', () {
    for (final (location, shown, hidden) in [
      // No need asked for: the latest Circle's, Clearer Head.
      (MemoryPage.location(), 'Write it down', 'A brisk walk'),
      // From "nothing fits More Energy": More Energy, where those choices
      // are — whatever the latest Circle was (S25 TalkBack finding).
      (
        MemoryPage.location(Intention.moreEnergy),
        'A brisk walk',
        'Write it down',
      ),
    ]) {
      testWidgets('$location opens on its need', (tester) async {
        _useS25(tester);
        SharedPreferences.setMockInitialValues({circleJournalKey: _journal});
        final prefs = await SharedPreferences.getInstance();
        final router = GoRouter(
          initialLocation: location,
          routes: buildAppRoutes(includeDevPreview: false),
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              nowProvider.overrideWithValue(_now),
              eventClockProvider.overrideWithValue(() => _now),
              safetyPendingAllowedProvider.overrideWithValue(false),
            ],
            child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(MemoryPage.title), findsOneWidget);
        expect(find.text(shown), findsOneWidget);
        expect(find.text(hidden), findsNothing);
      });
    }

    testWidgets('You → "What THIRTY remembers"', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: YouPersonalCard()),
          ),
          GoRoute(
            path: '/memory',
            builder: (_, _) => const Text('memory page'),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      final semantics = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byKey(const ValueKey('you.memory'))),
        matchesSemantics(
          label:
              '${YouPersonalCard.memoryTitle}, '
              '${YouPersonalCard.memoryDetail}',
          isButton: true,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.text(YouPersonalCard.memoryTitle));
      await tester.pumpAndSettle();
      expect(find.text('memory page'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('Delete Circle history says the suggestion preferences are '
        'kept — and keeps them', (tester) async {
      final (app, c) = await _app(
        Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => JournalDataControls.confirmAndClear(
              context,
              ref.read(circleJournalRepositoryProvider),
              ref,
            ),
            child: const Text('Delete'),
          ),
        ),
      );
      addTearDown(c.dispose);
      await c
          .read(suggestionPreferencesProvider.notifier)
          .dontSuggest(ActivityId.moveToMusic, Intention.moreEnergy);
      await tester.pumpWidget(app);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Your suggestion preferences are kept'),
        findsOneWidget,
      );
      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();

      expect(c.read(circleJournalRepositoryProvider).readAll(), isEmpty);
      expect(
        c
            .read(suggestionPreferencesProvider)
            .isNotSuggested(ActivityId.moveToMusic, Intention.moreEnergy),
        isTrue,
      );
    });
  });
}
