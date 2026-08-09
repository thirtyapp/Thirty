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
  group('activityPools', () {
    test('every pool has at least two activities', () {
      for (final pool in activityPools.values) {
        expect(pool.length, greaterThanOrEqualTo(2));
      }
    });

    test('gentleMobility is the only ActivityId shared across pools', () {
      final poolsContaining = <ActivityId, int>{};
      for (final pool in activityPools.values) {
        for (final activityId in pool) {
          poolsContaining[activityId] = (poolsContaining[activityId] ?? 0) + 1;
        }
      }

      final sharedIds = poolsContaining.entries
          .where((entry) => entry.value > 1)
          .map((entry) => entry.key);

      expect(sharedIds, [ActivityId.gentleMobility]);
    });

    test(
      '30-minute walk, phone-free walk and easy walk are three distinct '
      'ActivityIds, not a shared canonical identity',
      () {
        expect(
          {
            ActivityId.thirtyMinuteWalk,
            ActivityId.phoneFreeWalk,
            ActivityId.easyWalk,
          },
          hasLength(3),
        );
      },
    );
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

    test('every (intention, activityId) pair reachable from a pool has why-copy', () {
      for (final entry in activityPools.entries) {
        for (final activityId in entry.value) {
          expect(whyCopyFor(entry.key, activityId), isNotEmpty);
        }
      }
    });

    test(
      'gentleMobility has the same label under both intentions but '
      'different why-copy',
      () {
        expect(
          activityLabel(ActivityId.gentleMobility),
          'Gentle mobility',
        );
        expect(
          whyCopyFor(Intention.moreEnergy, ActivityId.gentleMobility),
          isNot(
            whyCopyFor(Intention.gentlerPace, ActivityId.gentleMobility),
          ),
        );
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
              reason: '"$phrase" found in why-copy for '
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
    test('is deterministic: same (dayIndex, intention) always resolves the same way', () {
      final first = selectActivityId(
        intention: Intention.moreEnergy,
        dayIndex: 42,
      );
      final second = selectActivityId(
        intention: Intention.moreEnergy,
        dayIndex: 42,
      );
      expect(first, second);
    });

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

    test(
      'anti-repetition: when the normal candidate matches the previous '
      'activity, the next pool candidate is chosen instead',
      () {
        final pool = activityPools[Intention.moreEnergy]!;
        const dayIndex = 5;
        final normalCandidate = pool[dayIndex % pool.length];

        final result = selectActivityId(
          intention: Intention.moreEnergy,
          dayIndex: dayIndex,
          previousActivityId: normalCandidate,
        );

        expect(result, isNot(normalCandidate));
        expect(pool, contains(result));
      },
    );

    test(
      'anti-repetition never triggers when the previous activity differs '
      'from the normal candidate',
      () {
        final pool = activityPools[Intention.moreEnergy]!;
        const dayIndex = 5;
        final normalCandidate = pool[dayIndex % pool.length];
        final otherActivity = pool.firstWhere((a) => a != normalCandidate);

        final result = selectActivityId(
          intention: Intention.moreEnergy,
          dayIndex: dayIndex,
          previousActivityId: otherActivity,
        );

        expect(result, normalCandidate);
      },
    );
  });
}
