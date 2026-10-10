import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';
import 'package:thirty/features/home/presentation/widgets/circle_session_card.dart';

/// V2 Phase D — a Path step and a routine on Today (ADR-022): the same
/// Circle, its own label line, its reason in plain words, and its pieces
/// run one after the other on Phase C's Guided runtime.

final _morning = DateTime(2026, 11, 20, 9);
const _day = '2026-11-20';

Map<String, Object> _today(
  Map<String, Object?> session, {
  String status = 'notStarted',
  int minutes = 15,
}) => {
  firstBreathLastPlayedDateKey: _day,
  recommendationDayKey: _day,
  recommendationIntentionKey: 'moreEnergy',
  recommendationActivityIdKey: 'energisingStretchFlow',
  recommendationTimeWindowKey: 'about20',
  recommendationOfferedMinutesKey: minutes,
  recommendationReasonKey: 'pathStep',
  recommendationStatusKey: status,
  if (status != 'notStarted')
    recommendationStartedAtKey: _morning.toIso8601String(),
  recommendationSessionKey: jsonEncode(session),
};

const _pathStep = {
  'modules': ['standingStretch:full', 'musicMove:full'],
  'title': 'Standing stretch + Move to music',
  'pathRunId': 'path-1',
  'pathKind': 'build',
  'pathName': 'A lift at home',
  'pathCircle': 4,
  'pathCircles': 7,
  'pathReason': 'together',
  'pathExplanation': 'Now the two together.',
};

const _routine = {
  'modules': ['standingStretch:full', 'musicMove:full'],
  'title': 'My pick-me-up',
  'routineId': 'routine-1',
  'routineVersionId': 'routine-1-v1',
  'routineVersionNumber': 1,
};

Future<void> _pump(
  WidgetTester tester,
  Map<String, Object> stored, {
  double width = 412,
}) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(_morning),
        eventClockProvider.overrideWithValue(() => _morning),
        safetyPendingAllowedProvider.overrideWithValue(false),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: CircleHero()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('a Path step: its place in the Path on the label line, read '
      'as words, and the step\'s own reason', (tester) async {
    final semantics = tester.ensureSemantics();
    // Wide enough for the whole label on one line (the test font is wide).
    await _pump(tester, _today(_pathStep), width: 900);
    expect(
      find.text('PATH\u00A0·\u00A04\u00A0OF\u00A07  ·  15\u00A0MIN'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Path · Circle 4 of 7, about 15 minutes'),
      findsOneWidget,
    );
    expect(find.text('Standing stretch + Move to music'), findsOneWidget);
    expect(find.text('Now the two together.'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('running, a Path step goes by its Path\'s name beneath the '
      'step — never the long joined title (S25 finding)', (tester) async {
    await _pump(tester, _today(_pathStep, status: 'started'));
    expect(find.textContaining('Step 1 of 6 · A lift at home'), findsOneWidget);
    expect(find.textContaining('+ Move to music'), findsNothing);
  });

  testWidgets('a label too long for its line takes two — its name, then '
      'its length — with no dangling "·" and never "MIN" on its own (S25 '
      'finding)', (tester) async {
    await _pump(tester, _today(_pathStep, minutes: 25));
    final label = tester.widget<Text>(find.textContaining('PATH'));
    expect(label.data, 'PATH · 4 OF 7\n25 MIN');
  });

  testWidgets('a routine: "Your routine", its name, its pieces', (
    tester,
  ) async {
    await _pump(tester, _today(_routine), width: 900);
    expect(find.text('YOUR\u00A0ROUTINE  ·  15\u00A0MIN'), findsOneWidget);
    expect(find.text('My pick-me-up'), findsOneWidget);
    expect(find.text('Standing stretch, then move to music.'), findsOneWidget);
  });

  testWidgets('running, a routine is one Circle of parts on the Guided '
      'runtime — one part at a time, never a checklist', (tester) async {
    await _pump(tester, _today(_routine, status: 'started'));
    final card = tester.widget<CircleSessionCard>(
      find.byType(CircleSessionCard),
    );
    expect(card.body, SessionBody.guided);
    expect(card.activity.title, 'My pick-me-up');
    // The stretch's five steps, then Move to music as one part.
    expect(card.activity.steps, hasLength(6));
    expect(find.text('Reach up'), findsOneWidget);
    expect(find.textContaining('Step 1 of 6'), findsOneWidget);
    for (final word in ['completed', 'done', '✓']) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
  });
}
