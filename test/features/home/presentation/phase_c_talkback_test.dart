import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/core/widgets/thirty_confirm_dialog.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/presentation/widgets/activity_guide_sheet.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';
import 'package:thirty/features/home/presentation/widgets/circle_reflection_card.dart';
import 'package:thirty/features/home/presentation/widgets/circle_session_card.dart';
import 'package:thirty/features/home/presentation/widgets/not_this_one_sheet.dart';

/// V2 Phase C closure — the TalkBack findings from the live S25 pass
/// (ADR-021), each held by a regression test: one stop per Open moment,
/// backdrops named for what they do, dialogs announced by their question,
/// and focus kept on what the user's own action brought on.

final _morning = DateTime(2026, 11, 20, 9);
const _day = '2026-11-20';

Map<String, Object> _today({
  required Intention need,
  required ActivityId activity,
  int minutes = 15,
  String status = 'started',
  CircleAttemptResponse? attempt,
  int position = 0,
}) => {
  firstBreathLastPlayedDateKey: _day,
  recommendationDayKey: _day,
  recommendationIntentionKey: need.name,
  recommendationActivityIdKey: activity.name,
  recommendationTimeWindowKey: TimeWindow.about20.name,
  recommendationOfferedMinutesKey: minutes,
  recommendationReasonKey: RecommendationReason.bestFit.name,
  recommendationStatusKey: status,
  recommendationStartedAtKey: _morning.toIso8601String(),
  if (status == 'closed')
    recommendationClosedAtKey: _morning
        .add(const Duration(minutes: 10))
        .toIso8601String(),
  recommendationAttemptResponseKey: ?attempt?.name,
  recommendationGuidedPositionKey: ?(position == 0 ? null : position),
};

Future<(Widget, ProviderContainer)> _app(
  Widget home, {
  Map<String, Object> stored = const {},
}) async {
  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_morning),
      eventClockProvider.overrideWithValue(() => _morning),
      safetyPendingAllowedProvider.overrideWithValue(false),
    ],
  );
  return (
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: SingleChildScrollView(child: home)),
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

/// Whether input focus — which TalkBack follows — sits on [finder]: inside
/// it (a button's own node), or on the nearest [Focus] wrapping it. A
/// route's scope wrapping everything never counts.
bool _focusHolds(Finder finder) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  bool isFocused(Element e) => e == focused;
  final inside = find.descendant(
    of: finder,
    matching: find.byElementPredicate(isFocused),
    matchRoot: true,
  );
  if (inside.evaluate().isNotEmpty) return true;
  final wrapping = find.ancestor(of: finder, matching: find.byType(Focus));
  return wrapping.evaluate().isNotEmpty && isFocused(wrapping.evaluate().first);
}

Finder _barrierNamed(String label) => find.byWidgetPredicate(
  (w) => w is ModalBarrier && w.semanticsLabel == label,
);

void main() {
  group('Open: one stop per moment', () {
    testWidgets('the first action is read as "First. …", never a bare '
        'eyebrow', (tester) async {
      _useS25(tester);
      final semantics = tester.ensureSemantics();
      final write = activityDefinition(ActivityId.writeItDown);
      final (app, c) = await _app(
        const CircleHero(),
        stored: _today(
          need: Intention.clearerHead,
          activity: ActivityId.writeItDown,
        ),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();

      expect(
        find.bySemanticsLabel('${SessionCopy.first}. ${write.firstAction}'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('FIRST'), findsNothing);
      semantics.dispose();
    });
  });

  group('Guided: Pause keeps TalkBack where it was', () {
    testWidgets('Pause, then Resume, each leave focus on the toggle — now '
        'named for what it does next', (tester) async {
      _useS25(tester);
      final (app, c) = await _app(
        const CircleHero(),
        stored: _today(
          need: Intention.moreEnergy,
          activity: ActivityId.energisingStretchFlow,
          minutes: 5,
          position: 2,
        ),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();

      await tester.tap(find.byTooltip(SessionCopy.pause));
      await tester.pump();
      await tester.pump();
      expect(c.read(recommendationProvider).isPaused, isTrue);
      expect(_focusHolds(find.byTooltip(SessionCopy.resume)), isTrue);

      await tester.tap(find.byTooltip(SessionCopy.resume));
      await tester.pump();
      await tester.pump();
      expect(c.read(recommendationProvider).isPaused, isFalse);
      expect(_focusHolds(find.byTooltip(SessionCopy.pause)), isTrue);
    });
  });

  group('the reflection takes focus only when an answer brings it on', () {
    testWidgets('"Yes" moves focus to "Was it useful?"; an answer there '
        'moves it to the acknowledgement', (tester) async {
      final (app, c) = await _app(
        const CircleReflectionCard(),
        stored: _today(
          need: Intention.moreEnergy,
          activity: ActivityId.thirtyMinuteWalk,
          status: 'closed',
        ),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();
      // The first look takes nothing: TalkBack stays wherever it was.
      expect(
        _focusHolds(find.text(CircleReflectionCard.attemptQuestion)),
        isFalse,
      );

      await tester.tap(find.text('Yes'));
      await tester.pump();
      await tester.pump();
      expect(
        _focusHolds(find.text(CircleReflectionCard.usefulnessQuestion)),
        isTrue,
      );

      await tester.tap(find.text('Very useful'));
      await tester.pump();
      await tester.pump();
      expect(_focusHolds(find.text(CircleReflectionCard.memoryLink)), isFalse);
      final acknowledgement = find.descendant(
        of: find.byType(CircleReflectionCard),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.data ?? '').isNotEmpty &&
              w.data != CircleReflectionCard.memoryLink &&
              w.data != 'A brisk walk',
        ),
      );
      expect(acknowledgement, findsOneWidget);
      expect(_focusHolds(acknowledgement), isTrue);
    });

    testWidgets('arriving on "Was it useful?" (a return later in the day) '
        'leaves focus alone', (tester) async {
      final (app, c) = await _app(
        const CircleReflectionCard(),
        stored: _today(
          need: Intention.moreEnergy,
          activity: ActivityId.thirtyMinuteWalk,
          status: 'closed',
          attempt: CircleAttemptResponse.yes,
        ),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();
      await tester.pump();

      expect(
        find.text(CircleReflectionCard.usefulnessQuestion),
        findsOneWidget,
      );
      expect(
        _focusHolds(find.text(CircleReflectionCard.usefulnessQuestion)),
        isFalse,
      );
    });
  });

  group('backdrops are named for what they do', () {
    testWidgets('Close Circle\'s confirmation: the backdrop keeps the '
        'Circle open', (tester) async {
      _useS25(tester);
      final (app, c) = await _app(
        const CircleHero(),
        stored: _today(
          need: Intention.clearerHead,
          activity: ActivityId.writeItDown,
        ),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();

      await tester.ensureVisible(find.text('Close Circle'));
      await tester.tap(find.text('Close Circle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(_barrierNamed('Keep Circle open'), findsOneWidget);
    });

    for (final (name, open) in <(String, void Function(BuildContext))>[
      (
        'How to do it',
        (context) => showActivityGuide(
          context,
          activityId: ActivityId.writeItDown,
          intention: Intention.clearerHead,
        ),
      ),
      (
        'Not this one today',
        (context) =>
            showNotThisOneSheet(context, current: ActivityId.writeItDown),
      ),
    ]) {
      testWidgets('the "$name" sheet: its backdrop closes it', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.light,
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => open(context),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(_barrierNamed('Close'), findsOneWidget);
      });
    }

    test('every dialog and sheet the app opens names its backdrop', () {
      final opener = RegExp(
        r'show(Dialog|ModalBottomSheet|GeneralDialog)<[^>]*>\(',
      );
      final unnamed = <String>[];
      for (final file
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final source = file.readAsStringSync();
        for (final match in opener.allMatches(source)) {
          // The call's own arguments: up to its matching parenthesis.
          var depth = 1;
          var end = match.end;
          while (depth > 0 && end < source.length) {
            final ch = source[end++];
            if (ch == '(') depth++;
            if (ch == ')') depth--;
          }
          final args = source.substring(match.end, end);
          if (!args.contains('barrierLabel:')) {
            final line = '\n'.allMatches(source.substring(0, match.start));
            unnamed.add('${file.path}:${line.length + 1}');
          }
        }
      }
      expect(unnamed, isEmpty);
    });
  });

  testWidgets('a confirmation is announced by its question, not "Alert"', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                barrierLabel: 'Keep it',
                builder: (_) => const ThirtyConfirmDialog(
                  title: 'Remove this Circle?',
                  body: 'It will be gone from your history.',
                  cancelLabel: 'Keep it',
                  confirmLabel: 'Remove',
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.namesRoute == true &&
            w.properties.label == 'Remove this Circle?',
      ),
      findsOneWidget,
    );
  });
}
