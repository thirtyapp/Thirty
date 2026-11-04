import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/home/application/circle_history_deletion.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/widgets/journal_data_controls.dart';
import 'package:thirty/features/settings/presentation/widgets/you_data_card.dart';

/// Audit remediation R8 — Astra R7-A06 (MEDIUM): History THIRTY can't read
/// — damaged, written by a newer THIRTY, or only kept as a preserved copy —
/// is still the user's. "Copy as text" exports it as stored and "Delete"
/// deletes it, with the usual confirmation, from both places the controls
/// live (History and You). Empty History still has nothing to act on.
void main() {
  final morning = DateTime(2026, 10, 12, 9);

  const damaged = '{"schemaVersion": 2, "entries": "not a list"';
  final newer = jsonEncode({'schemaVersion': 9, 'entries': <Object>[]});
  final validWithOneUnreadable = jsonEncode({
    'schemaVersion': circleJournalSchemaVersion,
    'entries': [
      {'circleId': 'x', 'localDate': 'not a date'},
    ],
  });

  late List<String> copied;

  setUp(() => copied = []);

  Future<(ProviderContainer, SharedPreferences)> pump(
    WidgetTester tester,
    Map<String, Object> stored,
    Widget controls,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
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
    SharedPreferences.setMockInitialValues(stored);
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(morning),
        eventClockProvider.overrideWithValue(() => morning),
        entitlementStatusProvider.overrideWith(_Inactive.new),
        safetyPendingAllowedProvider.overrideWithValue(false),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: SingleChildScrollView(child: controls)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (c, prefs);
  }

  for (final (label, stored) in [
    ('damaged', {circleJournalKey: damaged}),
    ('written by a newer THIRTY', {circleJournalKey: newer}),
    (
      'only kept as a preserved copy',
      {
        circleJournalPreservedKey: [damaged],
      },
    ),
    (
      'readable, but its one record isn\'t',
      {circleJournalKey: validWithOneUnreadable},
    ),
  ]) {
    for (final (where, controls, deleteLabel) in [
      ('History', const JournalDataControls(), 'Delete all'),
      ('You', const YouDataCard(), 'Delete Circle history'),
    ]) {
      testWidgets('$where — History $label: Copy exports it as stored, and '
          'Delete deletes it after confirmation', (tester) async {
        final (c, prefs) = await pump(tester, stored, controls);
        await tester.tap(find.text('Copy as text'));
        await tester.pumpAndSettle();
        expect(copied, hasLength(1));
        final exported = jsonDecode(copied.single) as Map<String, Object?>;
        final raw = stored.values.single;
        if (raw is List) {
          expect(exported['journalPreserved'], raw);
        } else if (raw == validWithOneUnreadable) {
          expect(exported['entriesUnreadable'], hasLength(1));
        } else {
          expect(exported['journalStored'], raw);
        }

        await tester.tap(find.text(deleteLabel));
        await tester.pumpAndSettle();
        expect(find.text('Delete your Circle history?'), findsOneWidget);
        await tester.tap(find.text('Delete permanently'));
        await tester.pumpAndSettle();
        expect(prefs.get(circleJournalKey), isNull);
        expect(prefs.get(circleJournalPreservedKey), isNull);
        expect(prefs.getBool(historyDeletionPendingKey), isNull);
      });
    }
  }

  testWidgets('History empty, nothing stored: nothing to copy or delete', (
    tester,
  ) async {
    await pump(tester, const {}, const JournalDataControls());
    await tester.tap(find.text('Copy as text'));
    await tester.pumpAndSettle();
    expect(copied, isEmpty);
    await tester.tap(find.text('Delete all'));
    await tester.pumpAndSettle();
    expect(find.text('Delete your Circle history?'), findsNothing);
  });
}

class _Inactive extends EntitlementNotifier {
  @override
  EntitlementStatus build() => EntitlementStatus.inactive;
}
