import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The platform store is the controlled "disk" here; it ships with
// shared_preferences, so no dependency is added.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';

/// The platform store, where one key's writes can be made to fail.
class _Disk extends InMemorySharedPreferencesStore {
  _Disk(super.data) : super.withData();

  String? failing;
  int writes = 0;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    writes++;
    if (key == failing) throw StateError('disk write failed');
    return super.setValue(valueType, key, value);
  }
}

/// Audit remediation R6c — a journal THIRTY can't read as a whole is never
/// written over without first being kept, byte for byte, and verified on
/// disk; one written by a newer THIRTY is never written over at all. A
/// failed preservation fails closed: the original stays, and nothing new is
/// written in its place. Delete Circle history still deletes everything.
void main() {
  late _Disk disk;
  late SharedPreferences prefs;

  Future<CircleJournalRepository> boot(String? stored) async {
    disk = _Disk({'flutter.$circleJournalKey': ?stored});
    SharedPreferencesStorePlatform.instance = disk;
    SharedPreferences.resetStatic();
    prefs = await SharedPreferences.getInstance();
    return CircleJournalRepository(prefs);
  }

  /// The next start, on what is on disk.
  Future<CircleJournalRepository> restart() async {
    SharedPreferences.resetStatic();
    prefs = await SharedPreferences.getInstance();
    return CircleJournalRepository(prefs);
  }

  Future<void> writeOnce(CircleJournalRepository repo, String date) =>
      repo.recordShown(
        circleId: date,
        localDate: date,
        direction: Intention.moreEnergy,
        activityId: ActivityId.values.first,
        shownAt: DateTime.parse('${date}T09:00:00'),
      );

  Future<Object?> onDisk(String key) async =>
      (await disk.getAll())['flutter.$key'];

  String validJournal() => jsonEncode({
    'schemaVersion': circleJournalSchemaVersion,
    'entries': [
      CircleJournalEntry(
        schemaVersion: circleJournalSchemaVersion,
        circleId: '2026-10-01',
        localDate: '2026-10-01',
        direction: Intention.clearerHead,
        activityId: ActivityId.values.first,
        catalogVersion: catalogVersion,
        shownAt: DateTime(2026, 10, 1, 9),
      ).toJson(),
    ],
  });

  group('a journal THIRTY can\'t read as a whole', () {
    for (final (what, stored) in [
      ('not JSON', '{"schemaVersion": 2, "entries": [ {"circleId"'),
      ('not an object', '["2026-10-01"]'),
      ('no entries list', '{"schemaVersion": 2, "entries": "lost"}'),
      ('an unknown version', '{"schemaVersion": "two", "entries": []}'),
    ]) {
      test('$what: kept byte for byte before the first save writes over '
          'it; the save then goes ahead', () async {
        final repo = await boot(stored);
        expect(repo.readAll(), isEmpty);
        await writeOnce(repo, '2026-10-05');
        expect(await onDisk(circleJournalPreservedKey), [stored]);
        expect(repo.readAll().single.circleId, '2026-10-05');
      });
    }

    test('kept once across restarts and later saves — and an earlier kept '
        'copy is never replaced by a later one', () async {
      const first = '{"broken": ';
      var repo = await boot(first);
      await writeOnce(repo, '2026-10-05');
      repo = await restart();
      await writeOnce(repo, '2026-10-06');
      expect(await onDisk(circleJournalPreservedKey), [first]);
      // Later, the journal is damaged again in another way.
      await disk.setValue(
        'String',
        'flutter.$circleJournalKey',
        'second damage',
      );
      repo = await restart();
      await writeOnce(repo, '2026-10-07');
      expect(await onDisk(circleJournalPreservedKey), [first, 'second damage']);
    });

    test('the copy can\'t be written: nothing is written over the original '
        '— and the next save tries to keep it again first', () async {
      const stored = 'damaged journal';
      var repo = await boot(stored);
      disk.failing = 'flutter.$circleJournalPreservedKey';
      await expectLater(
        writeOnce(repo, '2026-10-05'),
        throwsA(isA<JournalWriteRefused>()),
      );
      expect(await onDisk(circleJournalKey), stored);
      expect(await onDisk(circleJournalPreservedKey), isNull);
      // The same session saves again: still refused, still untouched.
      await expectLater(
        writeOnce(repo, '2026-10-06'),
        throwsA(isA<JournalWriteRefused>()),
      );
      expect(await onDisk(circleJournalKey), stored);
      // The disk recovers: the next save keeps the original, then writes.
      disk.failing = null;
      repo = await restart();
      await writeOnce(repo, '2026-10-07');
      expect(await onDisk(circleJournalPreservedKey), [stored]);
      expect(repo.readAll().single.circleId, '2026-10-07');
    });
  });

  group('a journal written by a newer THIRTY', () {
    final newer = jsonEncode({
      'schemaVersion': circleJournalSchemaVersion + 1,
      'entries': [
        {'circleId': '2026-10-01', 'somethingNew': true},
      ],
    });

    test('is never written over: every save is refused, across restarts, '
        'and the stored bytes never change', () async {
      var repo = await boot(newer);
      expect(repo.readAll(), isEmpty);
      for (final day in ['2026-10-05', '2026-10-06']) {
        await expectLater(
          writeOnce(repo, day),
          throwsA(isA<JournalWriteRefused>()),
        );
        expect(await onDisk(circleJournalKey), newer);
        repo = await restart();
      }
      expect(await onDisk(circleJournalPreservedKey), isNull);
    });

    test('export shows it as stored; Delete Circle history still deletes '
        'it, at the user\'s request', () async {
      final repo = await boot(newer);
      final exported = jsonDecode(repo.exportAsJson()) as Map;
      expect(exported['journalStored'], newer);
      await repo.clearAll();
      expect(await onDisk(circleJournalKey), isNull);
    });
  });

  group('a readable journal is unchanged', () {
    test('ordinary saves keep no copy and write as before', () async {
      final repo = await boot(validJournal());
      await writeOnce(repo, '2026-10-05');
      expect(await onDisk(circleJournalPreservedKey), isNull);
      expect(repo.readAll().map((e) => e.circleId), [
        '2026-10-01',
        '2026-10-05',
      ]);
      final plain = jsonDecode(repo.exportAsJson()) as Map;
      expect(plain.containsKey('journalStored'), isFalse);
      expect(plain.containsKey('journalPreserved'), isFalse);
    });

    test('no journal yet: the first save writes it, keeps no copy', () async {
      final repo = await boot(null);
      await writeOnce(repo, '2026-10-05');
      expect(await onDisk(circleJournalPreservedKey), isNull);
      expect(repo.readAll(), hasLength(1));
    });
  });

  test('Delete Circle history removes the kept copies too; export shows '
      'them until then', () async {
    final repo = await boot('damaged');
    await writeOnce(repo, '2026-10-05');
    final exported = jsonDecode(repo.exportAsJson()) as Map;
    expect(exported['journalPreserved'], ['damaged']);
    await repo.clearAll();
    expect(await onDisk(circleJournalKey), isNull);
    expect(await onDisk(circleJournalPreservedKey), isNull);
  });
}
