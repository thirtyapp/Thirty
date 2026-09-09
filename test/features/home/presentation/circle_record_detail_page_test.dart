import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/presentation/circle_record_detail_page.dart';

Future<Widget> _wrap({
  Map<String, Object> storedPrefs = const {},
  required String localDate,
}) async {
  SharedPreferences.setMockInitialValues(storedPrefs);
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      theme: AppTheme.light,
      home: CircleRecordDetailPage(localDate: localDate),
    ),
  );
}

void main() {
  testWidgets(
    'shows the recorded entry\'s truthful shown/started/closed detail for '
    'an existing local date',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final journal = CircleJournalRepository(prefs);
      await journal.recordShown(
        circleId: '2026-09-05',
        localDate: '2026-09-05',
        direction: Intention.moreEnergy,
        activityId: ActivityId.thirtyMinuteWalk,
        shownAt: DateTime(2026, 9, 5, 9),
      );
      await journal.recordStarted(
        circleId: '2026-09-05',
        localDate: '2026-09-05',
        direction: Intention.moreEnergy,
        activityId: ActivityId.thirtyMinuteWalk,
        startedAt: DateTime(2026, 9, 5, 9, 5),
      );

      await tester.pumpWidget(
        await _wrap(
          storedPrefs: {
            circleJournalKey: jsonEncode({
              'schemaVersion': circleJournalSchemaVersion,
              'entries': journal.readAll().map((e) => e.toJson()).toList(),
            }),
          },
          localDate: '2026-09-05',
        ),
      );

      expect(find.text('2026-09-05'), findsWidgets);
      expect(find.textContaining('More Energy'), findsOneWidget);
      expect(find.text('Not closed'), findsOneWidget);
      expect(
        find.textContaining('never confirms the activity was actually done'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows a safe, truthful message for a local date with no retained '
    'record — a stale or deleted link never crashes or fabricates a '
    'record',
    (tester) async {
      await tester.pumpWidget(
        await _wrap(storedPrefs: const {}, localDate: '2026-09-05'),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('No record for 2026-09-05 is available'),
        findsOneWidget,
      );
    },
  );
}
