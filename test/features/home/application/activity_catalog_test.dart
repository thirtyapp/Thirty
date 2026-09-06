import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/activity_category.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';

// Forbidden phrase patterns from docs/product/recommendation-mvp-v0.md's
// "Why This Today?" copy rule — a recommendation's why-copy must never
// imply hidden knowledge about the user.
const _forbiddenPhrases = [
  'your body needs',
  'based on your energy',
  'this will reduce your stress',
  'this is what you need today',
];

void main() {
  group('V1 launch catalogue (ADR-013)', () {
    test('exactly 3 directions, each with exactly 7 reviewed placements '
        '(21 total)', () {
      expect(activityPools.keys.toSet(), Intention.values.toSet());
      for (final entry in activityPools.entries) {
        expect(
          entry.value.length,
          7,
          reason: '${entry.key} does not have exactly 7 placements',
        );
      }
      final total = activityPools.values.fold(0, (sum, p) => sum + p.length);
      expect(total, 21);
    });

    test('every placement across every direction is a distinct ActivityId '
        '(no renamed duplicates padding out the count)', () {
      final allPlacements = activityPools.values.expand((pool) => pool);
      expect(allPlacements.toSet(), hasLength(21));
    });

    test('every direction covers at least 4 genuinely different semantic '
        'activity families — walking variants alone never satisfy this', () {
      for (final entry in activityPools.entries) {
        final families = entry.value.map(activityFamily).toSet();
        expect(
          families.length,
          greaterThanOrEqualTo(4),
          reason:
              '${entry.key} only covers ${families.length} distinct '
              'families: $families',
        );
      }
    });

    test('every ActivityId used by a pool has a complete catalogue entry '
        '(title, first action, instructions, preparation, pacing note)', () {
      for (final activityId in activityPools.values.expand((p) => p)) {
        final definition = activityCatalog[activityId];
        expect(definition, isNotNull, reason: '$activityId has no entry');
        expect(activityFirstAction(activityId), isNotEmpty);
        expect(activityInstructions(activityId), isNotEmpty);
        expect(activityPreparation(activityId), isNotEmpty);
        expect(activityPacingNote(activityId), isNotEmpty);
      }
    });

    test('every pacing note reads as explicitly self-paced/stoppable, never '
        'a duration or count to hit', () {
      const forbiddenPacingPhrases = [
        'must',
        'have to',
        'required',
        'timer',
      ];
      for (final activityId in activityPools.values.expand((p) => p)) {
        final note = activityPacingNote(activityId).toLowerCase();
        for (final phrase in forbiddenPacingPhrases) {
          expect(
            note.contains(phrase),
            isFalse,
            reason: '"$phrase" found in pacing note for $activityId',
          );
        }
      }
    });

    test('catalogVersion is a positive, frozen integer', () {
      expect(catalogVersion, greaterThan(0));
    });
  });

  group('activityPools', () {
    test('every pool has at least two activities', () {
      for (final pool in activityPools.values) {
        expect(pool.length, greaterThanOrEqualTo(2));
      }
    });

    test('no ActivityId is currently shared across more than one pool', () {
      final poolsContaining = <ActivityId, int>{};
      for (final pool in activityPools.values) {
        for (final activityId in pool) {
          poolsContaining[activityId] = (poolsContaining[activityId] ?? 0) + 1;
        }
      }

      final sharedIds = poolsContaining.entries
          .where((entry) => entry.value > 1)
          .map((entry) => entry.key);

      expect(sharedIds, isEmpty);
    });

    test('30-minute walk, phone-free walk and easy walk are three distinct '
        'ActivityIds, not a shared canonical identity', () {
      expect({
        ActivityId.thirtyMinuteWalk,
        ActivityId.phoneFreeWalk,
        ActivityId.easyWalk,
      }, hasLength(3));
    });
  });

  group('activityLabel / activityCategory / whyCopyFor', () {
    test('every ActivityId has a label', () {
      for (final activityId in ActivityId.values) {
        expect(activityLabel(activityId), isNotEmpty);
      }
    });

    test('every ActivityId has a category', () {
      for (final activityId in ActivityId.values) {
        expect(activityCategory(activityId), isNotNull);
      }
    });

    test(
      'only genuinely walking activities resolve to ActivityCategory.walking',
      () {
        const walkingActivities = {
          ActivityId.thirtyMinuteWalk,
          ActivityId.phoneFreeWalk,
          ActivityId.easyWalk,
        };
        for (final activityId in ActivityId.values) {
          final expected = walkingActivities.contains(activityId)
              ? ActivityCategory.walking
              : ActivityCategory.generalWellness;
          expect(activityCategory(activityId), expected);
        }
      },
    );

    test(
      'every (intention, activityId) pair reachable from a pool has why-copy',
      () {
        for (final entry in activityPools.entries) {
          for (final activityId in entry.value) {
            expect(whyCopyFor(entry.key, activityId), isNotEmpty);
          }
        }
      },
    );

    test('no why-copy contains a forbidden claim pattern', () {
      for (final entry in activityPools.entries) {
        for (final activityId in entry.value) {
          final why = whyCopyFor(entry.key, activityId).toLowerCase();
          for (final phrase in _forbiddenPhrases) {
            expect(
              why.contains(phrase),
              isFalse,
              reason:
                  '"$phrase" found in why-copy for '
                  '(${entry.key}, $activityId)',
            );
          }
        }
      }
    });
  });

  group('epochDay', () {
    test('is the same for every time of day on the same local date', () {
      final morning = epochDay(DateTime(2026, 8, 2, 0, 1));
      final night = epochDay(DateTime(2026, 8, 2, 23, 59));
      expect(morning, night);
    });

    test('increases by exactly one from one calendar day to the next', () {
      final day1 = epochDay(DateTime(2026, 8, 2));
      final day2 = epochDay(DateTime(2026, 8, 3));
      expect(day2 - day1, 1);
    });

    test('is stable across a local daylight-saving transition', () {
      // 2026-03-29 is a DST spring-forward date in much of Europe; a
      // local-time-based difference could be perturbed by the missing
      // hour. epochDay is built from DateTime.utc, so it isn't.
      final beforeDst = epochDay(DateTime(2026, 3, 28));
      final afterDst = epochDay(DateTime(2026, 3, 29));
      expect(afterDst - beforeDst, 1);
    });
  });

  group('selectActivityId', () {
    test(
      'is deterministic: same (dayIndex, intention) always resolves the same way',
      () {
        final first = selectActivityId(
          intention: Intention.moreEnergy,
          dayIndex: 42,
        );
        final second = selectActivityId(
          intention: Intention.moreEnergy,
          dayIndex: 42,
        );
        expect(first, second);
      },
    );

    test('resolves to a member of the intention\'s own pool', () {
      for (final intention in Intention.values) {
        for (var dayIndex = 0; dayIndex < 10; dayIndex++) {
          final activityId = selectActivityId(
            intention: intention,
            dayIndex: dayIndex,
          );
          expect(activityPools[intention], contains(activityId));
        }
      }
    });

    test('with no previous activity, uses the plain rotation candidate', () {
      final pool = activityPools[Intention.moreEnergy]!;
      for (var dayIndex = 0; dayIndex < pool.length; dayIndex++) {
        expect(
          selectActivityId(intention: Intention.moreEnergy, dayIndex: dayIndex),
          pool[dayIndex % pool.length],
        );
      }
    });

    test('anti-repetition: excluding the normal candidate picks a different '
        'pool member instead', () {
      final pool = activityPools[Intention.moreEnergy]!;
      const dayIndex = 5;
      final normalCandidate = pool[dayIndex % pool.length];

      final result = selectActivityId(
        intention: Intention.moreEnergy,
        dayIndex: dayIndex,
        recentActivityIds: {normalCandidate},
      );

      expect(result, isNot(normalCandidate));
      expect(pool, contains(result));
    });

    test('excluding the pool\'s last member never disturbs dayIndex 0\'s '
        'own candidate', () {
      // Excluding an item from the *end* of the pool never renumbers the
      // index-0 position — this holds for any pool size, unlike excluding
      // an arbitrary other member (which can legitimately shift later
      // indices once the pool is reduced; see the "N-1 excluded" test
      // below for that generalization instead).
      final pool = activityPools[Intention.moreEnergy]!;
      final normalCandidate = pool[0];
      final excluded = pool.last;
      expect(excluded, isNot(normalCandidate));

      final result = selectActivityId(
        intention: Intention.moreEnergy,
        dayIndex: 0,
        recentActivityIds: {excluded},
      );

      expect(result, normalCandidate);
    });

    test('exhausted pool (every candidate excluded) falls back to the full, '
        'unfiltered pool rather than deadlocking', () {
      final pool = activityPools[Intention.moreEnergy]!;
      const dayIndex = 5;

      final result = selectActivityId(
        intention: Intention.moreEnergy,
        dayIndex: dayIndex,
        recentActivityIds: pool.toSet(),
      );

      expect(pool, contains(result));
      expect(result, pool[dayIndex % pool.length]);
    });

    test('with every candidate but one excluded, the one remaining candidate '
        'is returned deterministically, regardless of dayIndex', () {
      final pool = activityPools[Intention.clearerHead]!;
      final remaining = pool[3];
      final excluded = pool.where((id) => id != remaining).toSet();

      for (var dayIndex = 0; dayIndex < 5; dayIndex++) {
        final result = selectActivityId(
          intention: Intention.clearerHead,
          dayIndex: dayIndex,
          recentActivityIds: excluded,
        );
        expect(result, remaining);
      }
    });

    test('recentActivityIds from another intention\'s pool never affect this '
        'intention\'s selection', () {
      final pool = activityPools[Intention.moreEnergy]!;
      const dayIndex = 5;
      final normalCandidate = pool[dayIndex % pool.length];
      final unrelatedActivity = activityPools[Intention.clearerHead]!.first;

      final result = selectActivityId(
        intention: Intention.moreEnergy,
        dayIndex: dayIndex,
        recentActivityIds: {unrelatedActivity},
      );

      expect(result, normalCandidate);
    });
  });

  group('selectActivityId — cross-direction family avoidance (ADR-013 §2)', () {
    test('a null lastShownFamily filters nothing, matching the default', () {
      for (final intention in Intention.values) {
        final pool = activityPools[intention]!;
        for (var dayIndex = 0; dayIndex < pool.length; dayIndex++) {
          final withDefault = selectActivityId(
            intention: intention,
            dayIndex: dayIndex,
          );
          final withExplicitNull = selectActivityId(
            intention: intention,
            dayIndex: dayIndex,
            lastShownFamily: null,
          );
          expect(withExplicitNull, withDefault);
        }
      }
    });

    test(
      'excludes candidates sharing the immediately prior family when a '
      'different-family alternative exists',
      () {
        final pool = activityPools[Intention.moreEnergy]!;
        const dayIndex = 0;
        final normalCandidate = pool[dayIndex % pool.length];
        final lastShownFamily = activityFamily(normalCandidate);

        final result = selectActivityId(
          intention: Intention.moreEnergy,
          dayIndex: dayIndex,
          lastShownFamily: lastShownFamily,
        );

        expect(result, isNot(normalCandidate));
        expect(activityFamily(result), isNot(lastShownFamily));
      },
    );

    test(
      'falls back to the history-filtered pool (ignoring the family guard) '
      'when every remaining candidate shares the prior family',
      () {
        final pool = activityPools[Intention.moreEnergy]!;
        final onlySurvivor = pool.first;
        final excludeEverythingElse = pool
            .where((id) => id != onlySurvivor)
            .toSet();
        final lastShownFamily = activityFamily(onlySurvivor);

        for (var dayIndex = 0; dayIndex < 5; dayIndex++) {
          final result = selectActivityId(
            intention: Intention.moreEnergy,
            dayIndex: dayIndex,
            recentActivityIds: excludeEverythingElse,
            lastShownFamily: lastShownFamily,
          );
          expect(result, onlySurvivor);
        }
      },
    );

    test(
      'the per-intention history filter still applies first, independently '
      'of the family guard',
      () {
        final pool = activityPools[Intention.clearerHead]!;
        const dayIndex = 0;
        final normalCandidate = pool[dayIndex % pool.length];

        final result = selectActivityId(
          intention: Intention.clearerHead,
          dayIndex: dayIndex,
          recentActivityIds: {normalCandidate},
          // A family that matches nothing in this pool, so only the
          // history filter is actually exercised by this case.
          lastShownFamily: null,
        );

        expect(result, isNot(normalCandidate));
        expect(pool, contains(result));
      },
    );
  });
}
