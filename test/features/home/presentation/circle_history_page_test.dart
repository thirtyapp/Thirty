import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/features/home/presentation/circle_history_page.dart';

Future<(Widget, SharedPreferences)> _wrap() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final widget = ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const CircleHistoryPage(),
    ),
  );
  return (widget, prefs);
}

void main() {
  testWidgets('shows an empty-state message when nothing is recorded yet', (
    tester,
  ) async {
    final (widget, _) = await _wrap();
    await tester.pumpWidget(widget);

    expect(
      find.textContaining('Nothing recorded yet'),
      findsOneWidget,
    );
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

      expect(find.text('2026-08-02'), findsOneWidget);
      expect(find.textContaining('More Energy'), findsOneWidget);
      expect(find.textContaining('30-minute walk'), findsOneWidget);
      expect(find.text('Not closed'), findsOneWidget);
      expect(find.text('No answer'), findsNWidgets(2)); // attempt + usefulness
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
      expect(find.text('2026-08-02'), findsOneWidget);

      await tester.tap(find.text('Delete all'));
      await tester.pumpAndSettle();
      expect(find.text('Delete your Circle history?'), findsOneWidget);

      // Cancelling changes nothing.
      await tester.tap(find.text('Keep my history'));
      await tester.pumpAndSettle();
      expect(journal.readAll(), isNotEmpty);
      expect(find.text('2026-08-02'), findsOneWidget);

      await tester.tap(find.text('Delete all'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();

      expect(journal.readAll(), isEmpty);
      expect(find.textContaining('Nothing recorded yet'), findsOneWidget);
    },
  );

  testWidgets('Copy as text copies the exported journal to the clipboard', (
    tester,
  ) async {
    final copiedTexts = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedTexts.add(
            (call.arguments as Map)['text'] as String,
          );
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
