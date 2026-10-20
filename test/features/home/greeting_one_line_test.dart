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
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/home_page.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';

/// S25 finding (2026-10-12): "Good evening, Amandine." wrapped onto two
/// lines, and the extra line pushed Start Circle below the screen. The
/// greeting now keeps to one line: the designed 34 pt when it fits, smaller
/// when it must (never below 24 pt), and an ellipsis only past that — with
/// the whole greeting always in its semantics.

/// The S25's viewport in logical pixels (1080 × 2340 at 2.625).
const _s25 = Size(411, 891);

const _veryLong = 'Maximiliana-Josephine';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(file).readAsBytesSync())),
    );
  }
  await loader.load();
}

Future<void> _pumpToday(
  WidgetTester tester, {
  required DateTime now,
  String? name,
  double textScale = 1,
}) async {
  tester.view.physicalSize = _s25;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final day =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
  SharedPreferences.setMockInitialValues({
    recommendationDayKey: day,
    recommendationIntentionKey: 'moreEnergy',
    recommendationActivityIdKey: 'thirtyMinuteWalk',
    firstBreathLastPlayedDateKey: day,
    firstNameKey: ?name,
  });
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(now),
        eventClockProvider.overrideWithValue(() => now),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
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
}

/// How the greeting was laid out.
typedef _Laid = ({
  double fontSize,
  int lines,
  bool ellipsized,
  Rect rect,
  String label,
});

_Laid _laid(WidgetTester tester, String greeting) {
  final finder = find.text(greeting);
  expect(finder, findsOneWidget);
  final text = tester.widget<Text>(finder);
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final scaler = TextScaler.linear(
    MediaQuery.textScalerOf(tester.element(finder)).scale(1),
  );
  final style = text.style!;
  // Every line keeps the designed 34 pt height (a forced strut).
  final oneLine = scaler.scale(34) * style.height!;
  return (
    fontSize: style.fontSize!,
    lines: (paragraph.size.height / oneLine).round(),
    ellipsized: paragraph.didExceedMaxLines,
    rect: tester.getRect(finder),
    label: tester.getSemantics(finder).label,
  );
}

double _startCircleTop(WidgetTester tester) =>
    tester.getTopLeft(find.text('Start Circle')).dy;

void main() {
  setUpAll(() async {
    await _loadFont('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ]);
    await _loadFont('Newsreader', ['assets/fonts/Newsreader[opsz,wght].ttf']);
  });

  for (final (daypart, hour) in [
    ('morning', 8),
    ('afternoon', 14),
    ('evening', 21),
  ]) {
    final now = DateTime(2026, 10, 12, hour);

    group('$daypart, S25 width, normal text', () {
      late double startWithoutName;

      testWidgets('no name: the designed 34 pt, one line', (tester) async {
        await _pumpToday(tester, now: now);
        final laid = _laid(tester, daypartGreeting(now));
        expect(laid.fontSize, 34);
        expect(laid.lines, 1);
        startWithoutName = _startCircleTop(tester);
      });

      for (final name in ['Mia', 'Amandine', 'Alexandra', 'Christopher']) {
        testWidgets('"$name": one line, inside the screen, legible, whole '
            'in semantics — and Start Circle where it is without a name', (
          tester,
        ) async {
          await _pumpToday(tester, now: now, name: name);
          final greeting = daypartGreeting(now, firstName: name);
          final laid = _laid(tester, greeting);
          expect(laid.lines, 1, reason: greeting);
          expect(laid.ellipsized, isFalse, reason: greeting);
          expect(laid.fontSize, greaterThanOrEqualTo(24));
          expect(laid.fontSize, lessThanOrEqualTo(34));
          expect(laid.rect.left, greaterThanOrEqualTo(0));
          expect(laid.rect.right, lessThanOrEqualTo(_s25.width));
          expect(laid.label, greeting);
          expect(_startCircleTop(tester), startWithoutName);
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('a short name keeps the designed size', (tester) async {
        await _pumpToday(tester, now: now, name: 'Mia');
        expect(
          _laid(tester, daypartGreeting(now, firstName: 'Mia')).fontSize,
          34,
        );
      });

      testWidgets('an extreme name: the 24 pt minimum, one line with an '
          'ellipsis, the whole greeting in semantics', (tester) async {
        await _pumpToday(tester, now: now, name: _veryLong);
        final greeting = daypartGreeting(now, firstName: _veryLong);
        final laid = _laid(tester, greeting);
        expect(laid.fontSize, CircleHero.greetingMinFontSize);
        expect(laid.lines, 1);
        expect(laid.ellipsized, isTrue);
        expect(laid.rect.right, lessThanOrEqualTo(_s25.width));
        expect(laid.label, greeting);
        expect(_startCircleTop(tester), startWithoutName);
        expect(tester.takeException(), isNull);
      });
    });
  }

  group('enlarged system text (130 %) — where Today already scrolls', () {
    final now = DateTime(2026, 10, 12, 14);

    testWidgets('a name that fits at the scaled minimum stays on one line, '
        'never below the reader’s text size', (tester) async {
      await _pumpToday(tester, now: now, name: 'Amandine', textScale: 1.3);
      final laid = _laid(tester, daypartGreeting(now, firstName: 'Amandine'));
      expect(laid.lines, 1);
      expect(laid.ellipsized, isFalse);
      expect(laid.fontSize, greaterThanOrEqualTo(24));
      expect(tester.takeException(), isNull);
    });

    testWidgets('an extreme name wraps at the scaled minimum rather than '
        'shrinking further or truncating the name', (tester) async {
      await _pumpToday(tester, now: now, name: _veryLong, textScale: 1.3);
      final greeting = daypartGreeting(now, firstName: _veryLong);
      final laid = _laid(tester, greeting);
      expect(laid.fontSize, CircleHero.greetingMinFontSize);
      expect(laid.ellipsized, isFalse);
      expect(laid.lines, greaterThan(1));
      expect(laid.label, greeting);
      expect(tester.takeException(), isNull);
    });
  });

  group('accessibility text (200 %)', () {
    final now = DateTime(2026, 10, 12, 14);

    testWidgets('a short name: one line, never smaller than the reader’s '
        'own enlarged body text', (tester) async {
      await _pumpToday(tester, now: now, name: 'Mia', textScale: 2);
      final laid = _laid(tester, daypartGreeting(now, firstName: 'Mia'));
      expect(laid.lines, 1);
      expect(laid.ellipsized, isFalse);
      expect(laid.fontSize, greaterThanOrEqualTo(32));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a name too long at that size wraps — whole, never cut, '
        'never below the reader’s body text', (tester) async {
      await _pumpToday(tester, now: now, name: _veryLong, textScale: 2);
      final greeting = daypartGreeting(now, firstName: _veryLong);
      final laid = _laid(tester, greeting);
      expect(laid.fontSize, 32);
      expect(laid.ellipsized, isFalse);
      expect(laid.lines, greaterThan(1));
      expect(laid.label, greeting);
      expect(tester.takeException(), isNull);
    });
  });
}
