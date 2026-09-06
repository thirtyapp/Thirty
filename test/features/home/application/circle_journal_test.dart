import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';

Future<SharedPreferences> _prefsWith(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  return SharedPreferences.getInstance();
}

void main() {
  group('CircleJournalRepository', () {
    test('readAll() is empty when nothing has ever been recorded', () async {
      final repo = CircleJournalRepository(await _prefsWith({}));
      expect(repo.readAll(), isEmpty);
    });

    test('recordShown() creates exactly one entry with no lifecycle '
        'timestamps yet', () async {
      final repo = CircleJournalRepository(await _prefsWith({}));
      final shownAt = DateTime(2026, 8, 2, 9);

      await repo.recordShown(
        circleId: '2026-08-02',
        localDate: '2026-08-02',
        direction: Intention.moreEnergy,
        activityId: ActivityId.thirtyMinuteWalk,
        shownAt: shownAt,
      );

      final entries = repo.readAll();
      expect(entries, hasLength(1));
      final entry = entries.single;
      expect(entry.schemaVersion, circleJournalSchemaVersion);
      expect(entry.circleId, '2026-08-02');
      expect(entry.localDate, '2026-08-02');
      expect(entry.direction, Intention.moreEnergy);
      expect(entry.activityId, ActivityId.thirtyMinuteWalk);
      expect(entry.catalogVersion, catalogVersion);
      expect(entry.shownAt, shownAt);
      expect(entry.startedAt, isNull);
      expect(entry.closedAt, isNull);
      expect(entry.attemptResponse, isNull);
      expect(entry.usefulnessResponse, isNull);
    });

    test('one entry per local date: recordShown() twice for the same '
        'circleId never creates a second entry', () async {
      final repo = CircleJournalRepository(await _prefsWith({}));

      await repo.recordShown(
        circleId: '2026-08-02',
        localDate: '2026-08-02',
        direction: Intention.moreEnergy,
        activityId: ActivityId.thirtyMinuteWalk,
        shownAt: DateTime(2026, 8, 2, 9),
      );
      await repo.recordShown(
        circleId: '2026-08-02',
        localDate: '2026-08-02',
        direction: Intention.moreEnergy,
        activityId: ActivityId.thirtyMinuteWalk,
        shownAt: DateTime(2026, 8, 2, 9, 30),
      );

      expect(repo.readAll(), hasLength(1));
    });

    test(
      'recordStarted() then recordClosed() update the same entry in place',
      () async {
        final repo = CircleJournalRepository(await _prefsWith({}));
        await repo.recordShown(
          circleId: '2026-08-02',
          localDate: '2026-08-02',
          direction: Intention.clearerHead,
          activityId: ActivityId.quietReading,
          shownAt: DateTime(2026, 8, 2, 9),
        );

        final startedAt = DateTime(2026, 8, 2, 9, 5);
        await repo.recordStarted(
          circleId: '2026-08-02',
          localDate: '2026-08-02',
          direction: Intention.clearerHead,
          activityId: ActivityId.quietReading,
          startedAt: startedAt,
        );
        final closedAt = DateTime(2026, 8, 2, 9, 40);
        await repo.recordClosed(
          circleId: '2026-08-02',
          localDate: '2026-08-02',
          direction: Intention.clearerHead,
          activityId: ActivityId.quietReading,
          closedAt: closedAt,
        );

        final entries = repo.readAll();
        expect(entries, hasLength(1));
        expect(entries.single.startedAt, startedAt);
        expect(entries.single.closedAt, closedAt);
      },
    );

    test(
      'recordStarted() is self-healing: it synthesizes an entry if '
      '"shown" was never recorded, using startedAt as the fallback shownAt',
      () async {
        final repo = CircleJournalRepository(await _prefsWith({}));
        final startedAt = DateTime(2026, 8, 2, 9);

        await repo.recordStarted(
          circleId: '2026-08-02',
          localDate: '2026-08-02',
          direction: Intention.gentlerPace,
          activityId: ActivityId.easyWalk,
          startedAt: startedAt,
        );

        final entry = repo.readAll().single;
        expect(entry.direction, Intention.gentlerPace);
        expect(entry.activityId, ActivityId.easyWalk);
        expect(entry.shownAt, startedAt);
        expect(entry.startedAt, startedAt);
      },
    );

    test('recordAttempt(notToday) clears any previously recorded '
        'usefulness response on the same entry', () async {
      final repo = CircleJournalRepository(await _prefsWith({}));
      await repo.recordShown(
        circleId: '2026-08-02',
        localDate: '2026-08-02',
        direction: Intention.moreEnergy,
        activityId: ActivityId.moveToMusic,
        shownAt: DateTime(2026, 8, 2, 9),
      );
      await repo.recordAttempt(
        circleId: '2026-08-02',
        localDate: '2026-08-02',
        direction: Intention.moreEnergy,
        activityId: ActivityId.moveToMusic,
        response: CircleAttemptResponse.yes,
        respondedAt: DateTime(2026, 8, 2, 9, 40),
      );
      await repo.recordUsefulness(
        circleId: '2026-08-02',
        localDate: '2026-08-02',
        direction: Intention.moreEnergy,
        activityId: ActivityId.moveToMusic,
        response: CircleUsefulnessResponse.veryUseful,
        respondedAt: DateTime(2026, 8, 2, 9, 41),
      );
      expect(repo.readAll().single.usefulnessResponse, isNotNull);

      await repo.recordAttempt(
        circleId: '2026-08-02',
        localDate: '2026-08-02',
        direction: Intention.moreEnergy,
        activityId: ActivityId.moveToMusic,
        response: CircleAttemptResponse.notToday,
        respondedAt: DateTime(2026, 8, 2, 9, 42),
      );

      final entry = repo.readAll().single;
      expect(entry.attemptResponse, CircleAttemptResponse.notToday);
      expect(entry.usefulnessResponse, isNull);
    });

    test('readAll() returns entries ordered oldest local date first', () async {
      final repo = CircleJournalRepository(await _prefsWith({}));
      for (final date in ['2026-08-03', '2026-08-01', '2026-08-02']) {
        await repo.recordShown(
          circleId: date,
          localDate: date,
          direction: Intention.moreEnergy,
          activityId: ActivityId.thirtyMinuteWalk,
          shownAt: DateTime.parse(date),
        );
      }

      final dates = repo.readAll().map((e) => e.localDate).toList();
      expect(dates, ['2026-08-01', '2026-08-02', '2026-08-03']);
    });

    test(
      'retention cap: never keeps more than circleJournalRetentionDays '
      'entries, dropping the oldest first',
      () async {
        final repo = CircleJournalRepository(await _prefsWith({}));
        final totalDays = circleJournalRetentionDays + 5;
        final base = DateTime(2025, 1, 1);

        for (var i = 0; i < totalDays; i++) {
          final date = base.add(Duration(days: i));
          final dateStr =
              '${date.year.toString().padLeft(4, '0')}-'
              '${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}';
          await repo.recordShown(
            circleId: dateStr,
            localDate: dateStr,
            direction: Intention.moreEnergy,
            activityId: ActivityId.thirtyMinuteWalk,
            shownAt: date,
          );
        }

        final entries = repo.readAll();
        expect(entries.length, circleJournalRetentionDays);
        // The oldest 5 days were dropped — the earliest surviving entry is
        // day index 5 (base + 5 days).
        final expectedOldest = base.add(const Duration(days: 5));
        expect(
          entries.first.localDate,
          '${expectedOldest.year}-'
          '${expectedOldest.month.toString().padLeft(2, '0')}-'
          '${expectedOldest.day.toString().padLeft(2, '0')}',
        );
      },
    );

    test('clearAll() permanently removes every entry', () async {
      final prefs = await _prefsWith({});
      final repo = CircleJournalRepository(prefs);
      await repo.recordShown(
        circleId: '2026-08-02',
        localDate: '2026-08-02',
        direction: Intention.moreEnergy,
        activityId: ActivityId.thirtyMinuteWalk,
        shownAt: DateTime(2026, 8, 2),
      );
      expect(repo.readAll(), isNotEmpty);

      await repo.clearAll();

      expect(repo.readAll(), isEmpty);
      expect(prefs.containsKey(circleJournalKey), isFalse);
    });

    test('exportAsJson() round-trips through a fresh repository reading '
        'the same underlying key', () async {
      final prefs = await _prefsWith({});
      final repo = CircleJournalRepository(prefs);
      await repo.recordShown(
        circleId: '2026-08-02',
        localDate: '2026-08-02',
        direction: Intention.gentlerPace,
        activityId: ActivityId.quietMusicBreak,
        shownAt: DateTime(2026, 8, 2, 9),
      );

      final exported = repo.exportAsJson();
      final decoded = jsonDecode(exported) as Map<String, Object?>;
      expect(decoded['schemaVersion'], circleJournalSchemaVersion);
      final entries = decoded['entries'] as List;
      expect(entries, hasLength(1));
      expect(
        (entries.single as Map<String, Object?>)['activityId'],
        'quietMusicBreak',
      );
    });

    group('fail-safe reads (schema versioning / corruption)', () {
      test('a missing stored value reads as an empty journal', () async {
        final repo = CircleJournalRepository(await _prefsWith({}));
        expect(repo.readAll(), isEmpty);
      });

      test('a non-JSON stored string reads as an empty journal, never '
          'throws', () async {
        final prefs = await _prefsWith({circleJournalKey: 'not json at all'});
        final repo = CircleJournalRepository(prefs);
        expect(repo.readAll(), isEmpty);
      });

      test('an unrecognized/future schemaVersion reads as an empty journal '
          '— this build has no safe way to interpret it', () async {
        final prefs = await _prefsWith({
          circleJournalKey: jsonEncode({
            'schemaVersion': circleJournalSchemaVersion + 1,
            'entries': [],
          }),
        });
        final repo = CircleJournalRepository(prefs);
        expect(repo.readAll(), isEmpty);
      });

      test('a malformed entries list reads as an empty journal', () async {
        final prefs = await _prefsWith({
          circleJournalKey: jsonEncode({
            'schemaVersion': circleJournalSchemaVersion,
            'entries': 'not a list',
          }),
        });
        final repo = CircleJournalRepository(prefs);
        expect(repo.readAll(), isEmpty);
      });

      test('one corrupt entry inside an otherwise valid wrapper is dropped '
          'without discarding the rest of the journal', () async {
        final validEntry = {
          'schemaVersion': circleJournalSchemaVersion,
          'circleId': '2026-08-02',
          'localDate': '2026-08-02',
          'direction': Intention.moreEnergy.name,
          'activityId': ActivityId.thirtyMinuteWalk.name,
          'catalogVersion': catalogVersion,
          'shownAt': DateTime(2026, 8, 2, 9).toIso8601String(),
        };
        final corruptEntry = {
          'schemaVersion': circleJournalSchemaVersion,
          'circleId': '2026-08-01',
          // Missing localDate/direction/activityId/shownAt entirely.
        };
        final prefs = await _prefsWith({
          circleJournalKey: jsonEncode({
            'schemaVersion': circleJournalSchemaVersion,
            'entries': [validEntry, corruptEntry],
          }),
        });
        final repo = CircleJournalRepository(prefs);

        final entries = repo.readAll();
        expect(entries, hasLength(1));
        expect(entries.single.circleId, '2026-08-02');
      });

      test('an entry whose activityId no longer belongs to its recorded '
          'direction\'s pool is dropped — compatibility must hold '
          'historically too', () async {
        final incompatibleEntry = {
          'schemaVersion': circleJournalSchemaVersion,
          'circleId': '2026-08-02',
          'localDate': '2026-08-02',
          'direction': Intention.moreEnergy.name,
          // quietReading only ever belonged to clearerHead's pool.
          'activityId': ActivityId.quietReading.name,
          'catalogVersion': catalogVersion,
          'shownAt': DateTime(2026, 8, 2, 9).toIso8601String(),
        };
        final prefs = await _prefsWith({
          circleJournalKey: jsonEncode({
            'schemaVersion': circleJournalSchemaVersion,
            'entries': [incompatibleEntry],
          }),
        });
        final repo = CircleJournalRepository(prefs);

        expect(repo.readAll(), isEmpty);
      });

      test('recordStarted() after a corrupt stored journal self-heals '
          'rather than throwing', () async {
        final prefs = await _prefsWith({
          circleJournalKey: 'not json at all',
        });
        final repo = CircleJournalRepository(prefs);

        await repo.recordStarted(
          circleId: '2026-08-02',
          localDate: '2026-08-02',
          direction: Intention.moreEnergy,
          activityId: ActivityId.thirtyMinuteWalk,
          startedAt: DateTime(2026, 8, 2, 9),
        );

        expect(repo.readAll(), hasLength(1));
      });
    });
  });
}
