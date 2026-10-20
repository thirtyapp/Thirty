import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/phase_d_retirement.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/application/v1_premium_retirement.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/domain/recommendation_policy.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/kept_circle.dart';

/// The pre-release retirements (V2 Phase D, ADR-022; ADR-024 B1): V1
/// Premium, then Phase D's Paths, routines and maintenance — each run once,
/// before anything reads the store, and neither ever migrating a retired
/// object into something it wasn't. Kept Circles, the only owned object
/// left, come through exactly as kept.

/// A kept Circle as the Phase D2 build stored it.
const _keptJson = {
  'id': 'kept-1',
  'name': 'My desk Circle',
  'need': 'clearerHead',
  'parts': ['getItOut:6', 'chooseOne:1', 'clearCorner:8'],
  'createdAt': '2026-10-01T09:00:00.000',
  'fromCircleId': '2026-10-01',
};

/// The whole Phase D Toolkit record a development install may hold: a
/// routine, a Path under way, a finished Path, maintenance memory — and the
/// kept Circle.
String _legacyToolkitRecord() => jsonEncode({
  'schemaVersion': 1,
  'routines': [
    {
      'id': 'routine-1',
      'name': 'My reset',
      'need': 'clearerHead',
      'versions': [
        {
          'id': 'routine-1-v1',
          'number': 1,
          'modules': ['writeDown:full', 'clearSurface:full'],
          'createdAt': '2026-09-20T09:00:00.000',
          'origin': 'path',
        },
      ],
      'activeVersionId': 'routine-1-v1',
      'createdAt': '2026-09-20T09:00:00.000',
      'enabled': true,
    },
  ],
  'path': {
    'id': 'path-2',
    'kind': 'build',
    'need': 'moreEnergy',
    'startedAt': '2026-10-05T09:00:00.000',
    'pool': ['standingStretch', 'musicMove', 'activeTask'],
    'seed': 'sparseStart',
    'template': 'wakeUpIndoors',
    'circles': [],
  },
  'finished': [
    {
      'runId': 'path-1',
      'kind': 'build',
      'need': 'clearerHead',
      'finishedAt': '2026-09-20T09:00:00.000',
      'kept': true,
    },
  ],
  'declined': {'gap:clearTheDecks': '2026-10-02T09:00:00.000'},
  'lastCheckAt': '2026-10-03T09:00:00.000',
  'kept': [_keptJson],
});

Future<SharedPreferences> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

void main() {
  group('V1 Premium retirement', () {
    test('removes V1 Plans and Insights, keeps the journal and every Free '
        'preference, and runs once', () async {
      final prefs = await _prefs({
        'plans_state_v1': '{"schemaVersion":1}',
        'insight_snapshots_v1': '{"schemaVersion":1}',
        recommendationPlanIdKey: 'moreEnergyPath',
        circleJournalKey: '{"schemaVersion":1,"entries":[]}',
        suggestionPreferencesKey: '{"schemaVersion":1}',
        'theme_mode': 'dark',
      });
      await retireV1Premium(prefs);
      expect(prefs.containsKey('plans_state_v1'), isFalse);
      expect(prefs.containsKey('insight_snapshots_v1'), isFalse);
      expect(prefs.containsKey(recommendationPlanIdKey), isFalse);
      expect(prefs.getString(circleJournalKey), isNotNull);
      expect(prefs.getString(suggestionPreferencesKey), isNotNull);
      expect(prefs.getString('theme_mode'), 'dark');
      expect(prefs.getBool(v1PremiumRetiredKey), isTrue);
      // Nothing is made from V1 progress.
      expect(prefs.containsKey(keptCirclesKey), isFalse);

      // Idempotent: a later stray key (an old backup) isn't touched again.
      await prefs.setString('plans_state_v1', 'restored-by-hand');
      await retireV1Premium(prefs);
      expect(prefs.getString('plans_state_v1'), 'restored-by-hand');
    });

    test(
      'an interrupted retirement (no marker yet) simply runs again',
      () async {
        final prefs = await _prefs({'insight_snapshots_v1': 'x'});
        await retireV1Premium(prefs);
        expect(prefs.containsKey('insight_snapshots_v1'), isFalse);
      },
    );
  });

  group('Phase D retirement (B1)', () {
    test('drops Paths, routines and maintenance; every kept Circle stays '
        'exactly as kept, under the same key', () async {
      final prefs = await _prefs({keptCirclesKey: _legacyToolkitRecord()});
      await retirePhaseDPremium(prefs);

      final record =
          jsonDecode(prefs.getString(keptCirclesKey)!) as Map<String, Object?>;
      expect(record.keys, unorderedEquals(['schemaVersion', 'kept']));
      expect(record['kept'], [_keptJson]);
      for (final field in retiredToolkitFields) {
        expect(record.containsKey(field), isFalse, reason: field);
      }
      expect(prefs.getBool(phaseDPremiumRetiredKey), isTrue);

      final kept = KeptCirclesRepository(prefs).read().kept.single;
      expect(kept.id, 'kept-1');
      expect(kept.name, 'My desk Circle');
      expect(kept.need, Intention.clearerHead);
      expect(kept.plan.toWire(), _keptJson['parts']);
      expect(kept.fromCircleId, '2026-10-01');
    });

    test('drops the routine "Don\'t suggest" items and nothing else from '
        'suggestion preferences', () async {
      final prefs = await _prefs({
        suggestionPreferencesKey: jsonEncode({
          'schemaVersion': 1,
          'notSuggested': [
            {
              'activityId': 'moveToMusic',
              'need': 'moreEnergy',
              'since': '2026-10-01T09:00:00.000',
            },
          ],
          'restsLifted': [],
          retiredRoutinesNotSuggestedField: [
            {
              'routineId': 'routine-1',
              'need': 'clearerHead',
              'since': '2026-10-01T09:00:00.000',
            },
          ],
          'elementsLeftOut': [
            {'elementId': 'openWindow', 'since': '2026-10-02T09:00:00.000'},
          ],
        }),
      });
      await retirePhaseDPremium(prefs);

      final stored =
          jsonDecode(prefs.getString(suggestionPreferencesKey)!)
              as Map<String, Object?>;
      expect(stored.containsKey(retiredRoutinesNotSuggestedField), isFalse);
      final read = SuggestionPreferences.fromRaw(
        prefs.getString(suggestionPreferencesKey),
      );
      expect(
        read.isNotSuggested(ActivityId.moveToMusic, Intention.moreEnergy),
        isTrue,
      );
      expect(read.leftOut.single.name, 'openWindow');
    });

    test(
      'touches no journal entry: a routine day stays a routine day',
      () async {
        final journal = jsonEncode({
          'schemaVersion': circleJournalSchemaVersion,
          'entries': [
            {
              'schemaVersion': circleJournalSchemaVersion,
              'circleId': '2026-10-04',
              'localDate': '2026-10-04',
              'direction': 'clearerHead',
              'activityId': 'writeItDown',
              'catalogVersion': catalogVersion,
              'shownAt': '2026-10-04T09:00:00.000',
              'startedAt': '2026-10-04T09:02:00.000',
              'closedAt': '2026-10-04T09:32:00.000',
              'session': {
                'title': 'My reset',
                'modules': ['writeDown:full', 'clearSurface:full'],
                'routineId': 'routine-1',
                'routineVersionId': 'routine-1-v1',
                'routineVersionNumber': 1,
              },
            },
          ],
        });
        final prefs = await _prefs({
          keptCirclesKey: _legacyToolkitRecord(),
          circleJournalKey: journal,
        });
        await retirePhaseDPremium(prefs);
        expect(prefs.getString(circleJournalKey), journal);
      },
    );

    test('runs once, leaves an unreadable record untouched, and changes '
        'nothing when there is nothing to retire', () async {
      final prefs = await _prefs({keptCirclesKey: '{not json'});
      await retirePhaseDPremium(prefs);
      expect(prefs.getString(keptCirclesKey), '{not json');
      expect(prefs.getBool(phaseDPremiumRetiredKey), isTrue);

      // A later legacy record (a restored backup) isn't rewritten again.
      await prefs.setString(keptCirclesKey, _legacyToolkitRecord());
      await retirePhaseDPremium(prefs);
      expect(prefs.getString(keptCirclesKey), _legacyToolkitRecord());

      final empty = await _prefs({});
      await retirePhaseDPremium(empty);
      expect(empty.containsKey(keptCirclesKey), isFalse);
      expect(empty.containsKey(suggestionPreferencesKey), isFalse);
    });

    test('nothing in it makes a Plan, a routine or a kept Circle', () async {
      final prefs = await _prefs({keptCirclesKey: _legacyToolkitRecord()});
      await retirePhaseDPremium(prefs);
      final keys = prefs.getKeys();
      expect(keys.where((k) => k.contains('plan')), isEmpty);
      expect(KeptCirclesRepository(prefs).read().kept, hasLength(1));
    });
  });

  group('the kept-Circle store', () {
    test('an unreadable record is set aside untouched, and nothing kept is '
        'guessed at', () async {
      final prefs = await _prefs({keptCirclesKey: '{not json'});
      final state = KeptCirclesRepository(prefs).read();
      await Future<void>.delayed(Duration.zero);
      expect(state.isEmpty, isTrue);
      expect(prefs.getString(keptCirclesUnreadableKey), '{not json');
    });

    test('a legacy record still reads its kept Circles before the migration '
        'has run', () async {
      final prefs = await _prefs({keptCirclesKey: _legacyToolkitRecord()});
      expect(KeptCirclesRepository(prefs).read().kept.single.id, 'kept-1');
    });

    test('the next write keeps only the kept Circles', () async {
      final prefs = await _prefs({keptCirclesKey: _legacyToolkitRecord()});
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          eventClockProvider.overrideWithValue(() => DateTime(2026, 10, 20, 9)),
        ],
      );
      addTearDown(container.dispose);
      container.read(keptCirclesProvider.notifier).renameKept('kept-1', 'Mine');
      await Future<void>.delayed(Duration.zero);
      final record =
          jsonDecode(prefs.getString(keptCirclesKey)!) as Map<String, Object?>;
      expect(record.keys, unorderedEquals(['schemaVersion', 'kept']));
      expect(keptCirclesFromRecord(record)!.single.name, 'Mine');
    });
  });

  test('export carries the kept Circles — and no routine, Path or derived '
      'score as a current object', () async {
    final prefs = await _prefs({keptCirclesKey: _legacyToolkitRecord()});
    final kept = KeptCirclesRepository(prefs).read();
    final exported =
        jsonDecode(
              CircleJournalRepository(prefs).exportAsJson(
                keptCircles: [for (final k in kept.kept) k.toJson()],
              ),
            )
            as Map<String, Object?>;
    expect(exported['keptCircles'], [_keptJson]);
    expect(exported.containsKey('toolkit'), isFalse);
    final text = jsonEncode(exported);
    for (final retired in ['routines', '"path"', 'finished', 'lastCheckAt']) {
      expect(text, isNot(contains(retired)), reason: retired);
    }
    expect(text, isNot(contains('score')));
    expect(maxKeptCircles, 8);
  });

  test('a historical routine or joined Path Circle stays composite: never '
      'evidence about one activity', () {
    CircleJournalEntry entry(String date, CircleSessionRecord session) =>
        CircleJournalEntry(
          schemaVersion: circleJournalSchemaVersion,
          circleId: date,
          localDate: date,
          direction: Intention.clearerHead,
          activityId: ActivityId.writeItDown,
          catalogVersion: catalogVersion,
          shownAt: DateTime.parse('${date}T09:00:00'),
          closedAt: DateTime.parse('${date}T09:30:00'),
          attemptResponse: CircleAttemptResponse.yes,
          usefulnessResponse: CircleUsefulnessResponse.notUseful,
          session: session,
        );
    final past = pastCirclesFrom([
      entry(
        '2026-10-04',
        const CircleSessionRecord(
          title: 'My reset',
          modules: ['writeDown:full', 'clearSurface:full'],
          routineId: 'routine-1',
        ),
      ),
      entry(
        '2026-10-05',
        const CircleSessionRecord(
          title: 'Write it down, then clear one surface',
          modules: ['writeDown:short', 'clearSurface:short'],
          pathRunId: 'path-1',
          pathName: 'Clear the decks',
        ),
      ),
    ]);
    expect(past.every((c) => c.composite), isTrue);
    expect(past[1].components, [
      ActivityId.writeItDown,
      ActivityId.tidyOneSurface,
    ]);
    final memory = RecommendationMemory.of(
      DateTime(2026, 10, 8),
      past,
      RecommendationPolicy.initial,
    );
    // Neither "Not useful" rests Write it down: they were about the pair.
    expect(
      memory.daysSinceNotUseful(ActivityId.writeItDown, Intention.clearerHead),
      isNull,
    );
  });
}
