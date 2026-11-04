import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';

/// Audit remediation R8 (Claude recommendation, forward-schema journal
/// records): a record a newer THIRTY wrote — its own `schemaVersion` above
/// this build's — inside a wrapper this build reads is never read and
/// rewritten with only the fields this build knows. It is kept exactly as
/// stored: written back by every save, exported beside the entries, and
/// removed only by Delete Circle history.
void main() {
  final newer = {
    'schemaVersion': circleJournalSchemaVersion + 1,
    'circleId': '2026-10-01',
    'localDate': '2026-10-01',
    'direction': 'moreEnergy',
    'activityId': ActivityId.values.first.name,
    'catalogVersion': 1,
    'shownAt': '2026-10-01T09:00:00.000',
    'laterField': {'kept': 'as stored'},
  };

  Future<CircleJournalRepository> repo() async {
    SharedPreferences.setMockInitialValues({
      circleJournalKey: jsonEncode({
        'schemaVersion': circleJournalSchemaVersion,
        'entries': [newer],
      }),
    });
    return CircleJournalRepository(await SharedPreferences.getInstance());
  }

  test('a save keeps it byte for byte, beside the new record', () async {
    final journal = await repo();
    await journal.recordShown(
      circleId: '2026-10-02',
      localDate: '2026-10-02',
      direction: Intention.gentlerPace,
      activityId: ActivityId.values.first,
      shownAt: DateTime(2026, 10, 2, 9),
    );
    final prefs = await SharedPreferences.getInstance();
    final stored =
        jsonDecode(prefs.getString(circleJournalKey)!) as Map<String, Object?>;
    final entries = stored['entries']! as List;
    expect([
      for (final e in entries) jsonEncode(e),
    ], contains(jsonEncode(newer)));
    expect(entries, hasLength(2));
  });

  test('it is exported as stored', () async {
    final journal = await repo();
    final exported = jsonDecode(journal.exportAsJson()) as Map<String, Object?>;
    expect(exported['entriesUnreadable'], [newer]);
  });
}
