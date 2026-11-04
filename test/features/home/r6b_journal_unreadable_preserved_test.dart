import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';

/// Audit remediation R6b (Audit #2 A2-09, founder data-safety check): a
/// journal record THIRTY can't read — a malformed date, or any other invalid
/// field — is set aside on read, and every later save writes it back
/// exactly as stored. It is never erased by an ordinary write, never
/// counted as history, and it is exported as stored. Delete Circle history
/// removes it with everything else.
void main() {
  late SharedPreferences prefs;

  Map<String, Object?> valid(String date) => CircleJournalEntry(
    schemaVersion: circleJournalSchemaVersion,
    circleId: date,
    localDate: date,
    direction: Intention.clearerHead,
    activityId: ActivityId.values.first,
    catalogVersion: catalogVersion,
    shownAt: DateTime.parse('${date}T09:00:00'),
  ).toJson();

  final badDate = {...valid('2026-10-02'), 'localDate': '2026-02-30'};
  final noDirection = {...valid('2026-10-03')}..remove('direction');
  const notAMap = 'garbage';

  Future<CircleJournalRepository> seed(List<Object?> entries) async {
    SharedPreferences.setMockInitialValues({
      circleJournalKey: jsonEncode({
        'schemaVersion': circleJournalSchemaVersion,
        'entries': entries,
      }),
    });
    prefs = await SharedPreferences.getInstance();
    return CircleJournalRepository(prefs);
  }

  List<Object?> storedEntries() =>
      (jsonDecode(prefs.getString(circleJournalKey)!) as Map)['entries']
          as List;

  Future<void> writeOnce(CircleJournalRepository repo, String date) =>
      repo.recordShown(
        circleId: date,
        localDate: date,
        direction: Intention.moreEnergy,
        activityId: ActivityId.values.first,
        shownAt: DateTime.parse('${date}T09:00:00'),
      );

  test('an ordinary save keeps every unreadable record, verbatim', () async {
    final repo = await seed([
      valid('2026-10-01'),
      badDate,
      noDirection,
      notAMap,
      valid('2026-10-04'),
    ]);
    expect(repo.readAll(), hasLength(2));
    await writeOnce(repo, '2026-10-05');
    final stored = [for (final e in storedEntries()) jsonEncode(e)];
    expect(stored, contains(jsonEncode(badDate)));
    expect(stored, contains(jsonEncode(noDirection)));
    expect(stored, contains(jsonEncode(notAMap)));
    // History is the readable records only — the new one included.
    expect(repo.readAll().map((e) => e.circleId), [
      '2026-10-01',
      '2026-10-04',
      '2026-10-05',
    ]);
  });

  test('repeated saves never duplicate or drop them', () async {
    final repo = await seed([valid('2026-10-01'), badDate]);
    for (final d in ['2026-10-05', '2026-10-06', '2026-10-07']) {
      await writeOnce(repo, d);
    }
    final stored = storedEntries();
    expect(
      stored.where((e) => jsonEncode(e) == jsonEncode(badDate)),
      hasLength(1),
    );
    expect(repo.readAll(), hasLength(4));
  });

  test('export carries them as stored, beside the entries; a clean journal '
      'exports exactly as before', () async {
    final repo = await seed([valid('2026-10-01'), badDate]);
    final exported = jsonDecode(repo.exportAsJson()) as Map;
    expect(exported['entries'], hasLength(1));
    expect(exported['entriesUnreadable'], [jsonDecode(jsonEncode(badDate))]);

    final clean = await seed([valid('2026-10-01')]);
    final plain = jsonDecode(clean.exportAsJson()) as Map;
    expect(plain.containsKey('entriesUnreadable'), isFalse);
  });

  test('Delete Circle history removes them with everything else', () async {
    final repo = await seed([valid('2026-10-01'), badDate]);
    await repo.clearAll();
    expect(prefs.getString(circleJournalKey), isNull);
    expect(repo.readAll(), isEmpty);
  });
}
