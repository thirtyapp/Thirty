import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/utils/daypart_greeting.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/home_page.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';

/// The greeting that opens every Circle: THIRTY's daypart greeting with the
/// user's first name when there is one, from one shared path
/// (`CircleHero` → `homeGreeting` → `daypartGreeting`) for every direction,
/// activity, World and Path step.

Map<String, Object> _assigned(
  DateTime day,
  String intention,
  String activity,
) => {
  recommendationDayKey:
      '${day.year}-${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}',
  recommendationIntentionKey: intention,
  recommendationActivityIdKey: activity,
  firstBreathLastPlayedDateKey:
      '${day.year}-${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}',
};

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(file).readAsBytesSync())),
    );
  }
  await loader.load();
}

Future<SharedPreferences> _pumpHome(
  WidgetTester tester, {
  required DateTime now,
  Map<String, Object> prefsValues = const {},
  Size size = const Size(412, 915),
  double textScale = 1,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(now),
        eventClockProvider.overrideWithValue(() => now),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: const HomePage(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return prefs;
}

/// Every on-screen text that is a daypart greeting.
List<String> _greetings(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(find.byType(Text)))
    if (text.data != null && text.data!.startsWith('Good ')) text.data!,
];

void main() {
  setUpAll(() async {
    await _loadFont('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ]);
    await _loadFont('Newsreader', ['assets/fonts/Newsreader[opsz,wght].ttf']);
  });

  group('daypartGreeting (pure)', () {
    for (final (hour, minute, withName, without) in [
      (8, 0, 'Good morning, Thomas.', 'Good morning.'),
      (14, 0, 'Good afternoon, Thomas.', 'Good afternoon.'),
      (21, 0, 'Good evening, Thomas.', 'Good evening.'),
      (4, 59, 'Good evening, Thomas.', 'Good evening.'),
      (5, 0, 'Good morning, Thomas.', 'Good morning.'),
      (11, 59, 'Good morning, Thomas.', 'Good morning.'),
      (12, 0, 'Good afternoon, Thomas.', 'Good afternoon.'),
      (17, 59, 'Good afternoon, Thomas.', 'Good afternoon.'),
      (18, 0, 'Good evening, Thomas.', 'Good evening.'),
    ]) {
      test('$hour:${minute.toString().padLeft(2, '0')}', () {
        final at = DateTime(2026, 10, 4, hour, minute);
        expect(daypartGreeting(at, firstName: 'Thomas'), withName);
        expect(daypartGreeting(at), without);
      });
    }

    test('no stand-in, no stray punctuation without a name', () {
      final at = DateTime(2026, 10, 4, 9);
      for (final absent in [null, '', '   ']) {
        final greeting = daypartGreeting(at, firstName: absent);
        expect(greeting, 'Good morning.');
        expect(greeting, isNot(contains(',')));
        for (final standIn in ['Friend', 'there', 'User', 'Guest']) {
          expect(greeting, isNot(contains(standIn)));
        }
      }
    });

    test('Unicode names are used exactly', () {
      expect(
        daypartGreeting(DateTime(2026, 10, 4, 19), firstName: 'Zoë'),
        'Good evening, Zoë.',
      );
    });
  });

  group('Circle opening', () {
    for (final (label, hour) in [
      ('morning', 8),
      ('afternoon', 14),
      ('evening', 21),
    ]) {
      final now = DateTime(2026, 10, 4, hour);
      final expected = daypartGreeting(now, firstName: 'Thomas');
      final neutral = daypartGreeting(now);

      testWidgets('$label, with a name: "$expected", once, as the header', (
        tester,
      ) async {
        await _pumpHome(
          tester,
          now: now,
          prefsValues: {
            ..._assigned(now, 'moreEnergy', 'thirtyMinuteWalk'),
            firstNameKey: 'Thomas',
          },
        );
        expect(find.text(expected), findsOneWidget);
        expect(_greetings(tester), [expected]);
        expect(
          tester.getSemantics(find.text(expected)),
          isSemantics(isHeader: true),
        );
      });

      testWidgets('$label, without a name: "$neutral"', (tester) async {
        await _pumpHome(
          tester,
          now: now,
          prefsValues: _assigned(now, 'moreEnergy', 'thirtyMinuteWalk'),
        );
        expect(find.text(neutral), findsOneWidget);
        expect(_greetings(tester), [neutral]);
        expect(find.textContaining(', .'), findsNothing);
      });
    }

    testWidgets('a Path step opens with the same greeting', (tester) async {
      final now = DateTime(2026, 10, 4, 8);
      await _pumpHome(
        tester,
        now: now,
        prefsValues: {
          ..._assigned(now, 'moreEnergy', 'moveToMusic'),
          recommendationSessionKey: jsonEncode({
            'modules': ['musicMove:short'],
            'title': 'Move to music',
            'pathRunId': 'path-1',
            'pathKind': 'build',
            'pathName': 'A lift at home',
            'pathCircle': 1,
            'pathCircles': 7,
            'pathReason': 'firstTry',
            'pathExplanation': 'A short first try.',
          }),
          firstNameKey: 'Thomas',
        },
        size: const Size(412, 2400),
      );
      expect(find.textContaining('PATH'), findsOneWidget);
      expect(_greetings(tester), ['Good morning, Thomas.']);
    });

    // One activity per scene type, across all three directions and every
    // World — all through the one shared greeting path.
    for (final (intention, activity) in [
      ('moreEnergy', 'thirtyMinuteWalk'), // walk
      ('moreEnergy', 'moveToMusic'), // move
      ('moreEnergy', 'energisingStretchFlow'), // stretch
      ('moreEnergy', 'activeHouseholdTask'), // tend
      ('clearerHead', 'writeItDown'), // write
      ('clearerHead', 'quietReading'), // read
      ('clearerHead', 'quietAudioFocus'), // listen
      ('gentlerPace', 'restfulBreathingPause'), // breathe
      ('gentlerPace', 'smallComfortRitual'), // comfort
    ]) {
      testWidgets('$intention / $activity: the same greeting, once', (
        tester,
      ) async {
        final now = DateTime(2026, 10, 4, 19);
        await _pumpHome(
          tester,
          now: now,
          prefsValues: {
            ..._assigned(now, intention, activity),
            firstNameKey: 'Thomas',
          },
        );
        expect(find.byType(CircleHero), findsOneWidget);
        expect(_greetings(tester), ['Good evening, Thomas.']);
      });
    }

    testWidgets('the name appears nowhere else in the Circle', (tester) async {
      final now = DateTime(2026, 10, 4, 8);
      await _pumpHome(
        tester,
        now: now,
        prefsValues: {
          ..._assigned(now, 'moreEnergy', 'thirtyMinuteWalk'),
          firstNameKey: 'Thomas',
        },
        size: const Size(412, 2400),
      );
      expect(find.textContaining('Thomas'), findsOneWidget);
    });

    testWidgets('editing the name updates the open Circle\'s greeting', (
      tester,
    ) async {
      final now = DateTime(2026, 10, 4, 14);
      await _pumpHome(
        tester,
        now: now,
        prefsValues: _assigned(now, 'moreEnergy', 'thirtyMinuteWalk'),
      );
      expect(find.text('Good afternoon.'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomePage)),
      );
      await container.read(firstNameProvider.notifier).setFirstName('Anna');
      await tester.pumpAndSettle();
      expect(find.text('Good afternoon, Anna.'), findsOneWidget);
    });
  });

  group('Behaviour unchanged', () {
    testWidgets('Begin → direction → the Circle opens with the greeting; '
        'today\'s journal entry is recorded as before and holds no name', (
      tester,
    ) async {
      final now = DateTime(2026, 10, 4, 8);
      final prefs = await _pumpHome(
        tester,
        now: now,
        prefsValues: {firstNameKey: 'Thomas'},
        size: const Size(412, 2400),
      );
      // The Ready state carries no greeting of its own.
      expect(_greetings(tester), isEmpty);

      await tester.tap(find.text("Begin today's Circle"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('More Energy'));
      await tester.pumpAndSettle();

      expect(find.byType(CircleHero), findsOneWidget);
      expect(_greetings(tester), ['Good morning, Thomas.']);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomePage)),
      );
      final state = container.read(recommendationProvider);
      expect(state.status, RecommendationStatus.notStarted);
      expect(state.recommendation, isNotNull);

      final entries = CircleJournalRepository(prefs).readAll();
      expect(entries, hasLength(1));
      expect(entries.single.localDate, '2026-10-04');
      final raw = prefs.getString(circleJournalKey)!;
      expect(raw, isNot(contains('Thomas')));
      expect(
        CircleJournalRepository(prefs).exportAsJson(),
        isNot(contains('Thomas')),
      );
    });

    testWidgets('Start Circle still starts the Circle; the greeting stays '
        'single', (tester) async {
      final now = DateTime(2026, 10, 4, 8);
      await _pumpHome(
        tester,
        now: now,
        prefsValues: {
          ..._assigned(now, 'moreEnergy', 'thirtyMinuteWalk'),
          firstNameKey: 'Thomas',
        },
        size: const Size(412, 2400),
      );
      await tester.tap(find.text('Start Circle'));
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomePage)),
      );
      expect(
        container.read(recommendationProvider).status,
        RecommendationStatus.started,
      );
      expect(_greetings(tester), ['Good morning, Thomas.']);
    });
  });

  group('Responsive', () {
    for (final (label, size, scale, theme) in [
      ('360×740', const Size(360, 740), 1.0, AppTheme.light),
      ('360×740 at 200%', const Size(360, 740), 2.0, AppTheme.light),
      ('Pixel 7 dark', const Size(412, 915), 1.0, AppTheme.dark),
    ]) {
      testWidgets('$label: a 40-character name wraps; nothing overflows or '
          'is cut', (tester) async {
        final now = DateTime(2026, 10, 4, 14);
        final long = 'Alexandra-Konstantina Wilhelmina-Rosaria';
        expect(long.runes.length, lessThanOrEqualTo(maxFirstNameLength));
        await _pumpHome(
          tester,
          now: now,
          prefsValues: {
            ..._assigned(now, 'moreEnergy', 'thirtyMinuteWalk'),
            firstNameKey: long,
          },
          size: size,
          textScale: scale,
          theme: theme,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Good afternoon, $long.'), findsOneWidget);
        // The greeting itself wraps in full (the Today card's own two-line
        // "why" limit is its existing design, unrelated to the name).
        final greeting = tester.renderObject<RenderParagraph>(
          find.text('Good afternoon, $long.'),
        );
        expect(greeting.didExceedMaxLines, isFalse);
      });
    }
  });
}
