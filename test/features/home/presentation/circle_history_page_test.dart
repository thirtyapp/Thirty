import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_colors.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/toolkit/application/toolkit_provider.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/features/home/presentation/circle_history_page.dart';

Future<(Widget, SharedPreferences)> _wrap() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final widget = ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(theme: AppTheme.light, home: const CircleHistoryPage()),
  );
  return (widget, prefs);
}

void main() {
  testWidgets('shows an empty-state message when nothing is recorded yet', (
    tester,
  ) async {
    final (widget, _) = await _wrap();
    await tester.pumpWidget(widget);

    expect(find.textContaining('Nothing recorded yet'), findsOneWidget);
    // No destructive/export controls are usable with nothing to act on.
    final copyButton = tester.widget<ThirtyButton>(
      find.widgetWithText(ThirtyButton, 'Copy as text'),
    );
    expect(copyButton.onPressed, isNull);
    final deleteButton = tester.widget<ThirtyButton>(
      find.widgetWithText(ThirtyButton, 'Delete all'),
    );
    expect(deleteButton.onPressed, isNull);
  });

  testWidgets(
    'lists a recorded entry with a clear shown/started/closed/attempt/'
    'usefulness distinction',
    (tester) async {
      final (widget, prefs) = await _wrap();
      final journal = CircleJournalRepository(prefs);
      await journal.recordShown(
        circleId: '2026-08-02',
        localDate: '2026-08-02',
        direction: Intention.moreEnergy,
        activityId: ActivityId.thirtyMinuteWalk,
        shownAt: DateTime(2026, 8, 2, 9),
      );
      await journal.recordStarted(
        circleId: '2026-08-02',
        localDate: '2026-08-02',
        direction: Intention.moreEnergy,
        activityId: ActivityId.thirtyMinuteWalk,
        startedAt: DateTime(2026, 8, 2, 9, 5),
      );

      await tester.pumpWidget(widget);

      expect(find.text('Sunday 2 August 2026'), findsOneWidget);
      expect(find.text('More Energy'), findsOneWidget);
      expect(find.text('A brisk walk'), findsOneWidget);
      // Truthful, in plain words: it started, it never closed, and the user
      // said nothing about trying it.
      expect(find.text('Started at 09:05. Not closed.'), findsOneWidget);
      expect(
        find.textContaining('Not answered', findRichText: true),
        findsNWidgets(2),
      ); // attempt + usefulness
      expect(
        find.textContaining('Did you try it?', findRichText: true),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'an old V1 Plan entry keeps a truthful line — what it came from, never '
    'a V2 Path (V2 Phase D)',
    (tester) async {
      final (widget, prefs) = await _wrap();
      final journal = CircleJournalRepository(prefs);
      await journal.recordShown(
        circleId: '2026-08-02',
        localDate: '2026-08-02',
        direction: Intention.moreEnergy,
        activityId: ActivityId.energisingBreathReset,
        shownAt: DateTime(2026, 8, 2, 9),
        planId: 'moreEnergyPath',
        planVersion: 1,
        stageId: 'more_energy_1_establish',
        planCycleId: 'moreEnergyPath_cycle_1',
        treatmentUsed: 'standard',
        revisitUsed: false,
      );

      await tester.pumpWidget(widget);

      expect(
        find.text('From an earlier Plan: More Energy · stage 1 of 5'),
        findsOneWidget,
      );
      expect(find.textContaining('Path'), findsNothing);
    },
  );

  testWidgets(
    'a Path step and a routine read as what they were that day (V2 Phase D)',
    (tester) async {
      final (widget, prefs) = await _wrap();
      final journal = CircleJournalRepository(prefs);
      await journal.recordShown(
        circleId: '2026-08-02',
        localDate: '2026-08-02',
        direction: Intention.moreEnergy,
        activityId: ActivityId.energisingStretchFlow,
        shownAt: DateTime(2026, 8, 2, 9),
        offer: const CircleOffer(
          timeWindow: 'about20',
          offeredMinutes: 15,
          session: CircleSessionRecord(
            title: 'Standing stretch + Move to music',
            modules: ['standingStretch:full', 'musicMove:full'],
            pathRunId: 'path-1',
            pathKind: 'build',
            pathName: 'A lift at home',
            pathCircle: 4,
            pathCircles: 7,
            pathReason: 'together',
          ),
        ),
      );
      await journal.recordShown(
        circleId: '2026-08-03',
        localDate: '2026-08-03',
        direction: Intention.moreEnergy,
        activityId: ActivityId.energisingStretchFlow,
        shownAt: DateTime(2026, 8, 3, 9),
        offer: const CircleOffer(
          timeWindow: 'about20',
          offeredMinutes: 15,
          session: CircleSessionRecord(
            title: 'My pick-me-up',
            modules: ['standingStretch:full', 'musicMove:full'],
            routineId: 'routine-1',
            routineVersionId: 'routine-1-v2',
            routineVersionNumber: 2,
          ),
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.text('Standing stretch + Move to music'), findsOneWidget);
      expect(find.text('A lift at home · Circle 4 of 7'), findsOneWidget);
      expect(find.text('My pick-me-up'), findsOneWidget);
      expect(find.text('Your routine · version 2'), findsOneWidget);
    },
  );

  testWidgets(
    'a Free-selector entry (no Plan fields) shows no Plan context line',
    (tester) async {
      final (widget, prefs) = await _wrap();
      final journal = CircleJournalRepository(prefs);
      await journal.recordShown(
        circleId: '2026-08-02',
        localDate: '2026-08-02',
        direction: Intention.moreEnergy,
        activityId: ActivityId.thirtyMinuteWalk,
        shownAt: DateTime(2026, 8, 2, 9),
      );

      await tester.pumpWidget(widget);

      expect(find.textContaining('Plan:'), findsNothing);
    },
  );

  testWidgets(
    'Delete all clears the journal only after explicit confirmation',
    (tester) async {
      final (widget, prefs) = await _wrap();
      final journal = CircleJournalRepository(prefs);
      await journal.recordShown(
        circleId: '2026-08-02',
        localDate: '2026-08-02',
        direction: Intention.moreEnergy,
        activityId: ActivityId.thirtyMinuteWalk,
        shownAt: DateTime(2026, 8, 2, 9),
      );

      await tester.pumpWidget(widget);
      expect(find.text('Sunday 2 August 2026'), findsOneWidget);

      await tester.tap(find.text('Delete all'));
      await tester.pumpAndSettle();
      expect(find.text('Delete your Circle history?'), findsOneWidget);

      // Cancelling changes nothing.
      await tester.tap(find.text('Keep my history'));
      await tester.pumpAndSettle();
      expect(journal.readAll(), isNotEmpty);
      expect(find.text('Sunday 2 August 2026'), findsOneWidget);

      await tester.tap(find.text('Delete all'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();

      expect(journal.readAll(), isEmpty);
      expect(find.textContaining('Nothing recorded yet'), findsOneWidget);
    },
  );

  testWidgets(
    'Delete permanently uses the AA errorText role, matching the Close '
    'Circle destructive action (A5)',
    (tester) async {
      final (widget, prefs) = await _wrap();
      await CircleJournalRepository(prefs).recordShown(
        circleId: '2026-08-02',
        localDate: '2026-08-02',
        direction: Intention.moreEnergy,
        activityId: ActivityId.thirtyMinuteWalk,
        shownAt: DateTime(2026, 8, 2, 9),
      );

      await tester.pumpWidget(widget);
      await tester.tap(find.text('Delete all'));
      await tester.pumpAndSettle();

      final deleteAction = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Delete permanently'),
      );
      expect(
        deleteAction.style!.foregroundColor!.resolve({}),
        AppColors.light.errorText,
      );
      // The safe choice stays in the default, non-destructive color.
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Keep my history'),
            )
            .style,
        isNull,
      );
    },
  );

  testWidgets('Delete all keeps the Toolkit — routines have their own controls '
      '(V2 Phase D)', (tester) async {
    final (widget, prefs) = await _wrap();
    final journal = CircleJournalRepository(prefs);
    await journal.recordShown(
      circleId: '2026-08-02',
      localDate: '2026-08-02',
      direction: Intention.moreEnergy,
      activityId: ActivityId.thirtyMinuteWalk,
      shownAt: DateTime(2026, 8, 2, 9),
    );
    await prefs.setString(toolkitStateKey, jsonEncode({'kept': true}));

    await tester.pumpWidget(widget);
    await tester.tap(find.text('Delete all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete permanently'));
    await tester.pumpAndSettle();

    expect(journal.readAll(), isEmpty);
    expect(prefs.getString(toolkitStateKey), jsonEncode({'kept': true}));
  });

  testWidgets('Copy as text copies the exported journal to the clipboard', (
    tester,
  ) async {
    final copiedTexts = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedTexts.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final (widget, prefs) = await _wrap();
    final journal = CircleJournalRepository(prefs);
    await journal.recordShown(
      circleId: '2026-08-02',
      localDate: '2026-08-02',
      direction: Intention.moreEnergy,
      activityId: ActivityId.thirtyMinuteWalk,
      shownAt: DateTime(2026, 8, 2, 9),
    );

    await tester.pumpWidget(widget);
    await tester.tap(find.text('Copy as text'));
    await tester.pump();

    expect(copiedTexts, hasLength(1));
    expect(copiedTexts.single, contains('thirtyMinuteWalk'));
    expect(find.text('Copied your Circle history as text.'), findsOneWidget);
  });
}
