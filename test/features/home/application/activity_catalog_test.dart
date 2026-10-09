import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/activity_category.dart';
import 'package:thirty/core/worlds/registered_worlds.dart';
import 'package:thirty/core/worlds/world_scene_role.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';

/// Phrases THIRTY's activity copy must never use: hidden knowledge about
/// the user (recommendation-mvp-v0's "Why This Today?" rule), outcome
/// promises, or productivity-grind framing (PRODUCT_V2_CONTRACT — content
/// voice).
const _forbiddenPhrases = [
  'your body needs',
  'based on your energy',
  'this will reduce your stress',
  'this is what you need today',
  'boost',
  'guarantee',
  'proven',
  'scientifically',
  'productivity',
  'burn calories',
];

/// The founder-reviewed Phase A placements and classifications, pinned so a
/// change is always a deliberate, reviewed edit of this table.
const _reviewed =
    <
      ActivityId,
      (String, int, int, CircleMode, LearningCompatibility, ActivityStatus)
    >{
      // (fit More Energy / Clearer Head / Gentler Pace as P, S or -, minimum
      // minutes, typical minutes, mode, V1 learning class, status)
      ActivityId.thirtyMinuteWalk: (
        'PS-',
        15,
        25,
        CircleMode.open,
        LearningCompatibility.reset,
        ActivityStatus.live,
      ),
      ActivityId.moveToMusic: (
        'PS-',
        5,
        10,
        CircleMode.open,
        LearningCompatibility.compatible,
        ActivityStatus.live,
      ),
      ActivityId.phoneFreeWalk: (
        'SPS',
        15,
        20,
        CircleMode.open,
        LearningCompatibility.compatible,
        ActivityStatus.live,
      ),
      ActivityId.writeItDown: (
        '-PS',
        10,
        15,
        CircleMode.open,
        LearningCompatibility.compatible,
        ActivityStatus.live,
      ),
      ActivityId.quietReading: (
        '-PS',
        15,
        20,
        CircleMode.open,
        LearningCompatibility.compatible,
        ActivityStatus.live,
      ),
      ActivityId.easyWalk: (
        'SSP',
        15,
        20,
        CircleMode.open,
        LearningCompatibility.compatible,
        ActivityStatus.live,
      ),
      ActivityId.quietMusicBreak: (
        '-SP',
        10,
        15,
        CircleMode.open,
        LearningCompatibility.compatible,
        ActivityStatus.live,
      ),
      ActivityId.briskStepBurst: (
        'P--',
        5,
        10,
        CircleMode.guidedSteps,
        LearningCompatibility.reset,
        ActivityStatus.safetyReviewPending,
      ),
      ActivityId.energisingStretchFlow: (
        'PS-',
        5,
        5,
        CircleMode.guidedSteps,
        LearningCompatibility.reset,
        ActivityStatus.live,
      ),
      ActivityId.activeMovementSnack: (
        'P--',
        5,
        8,
        CircleMode.guidedSteps,
        LearningCompatibility.reset,
        ActivityStatus.safetyReviewPending,
      ),
      ActivityId.energisingBreathReset: (
        '---',
        0,
        0,
        CircleMode.paced,
        LearningCompatibility.reset,
        ActivityStatus.retired,
      ),
      ActivityId.activeHouseholdTask: (
        'PS-',
        10,
        15,
        CircleMode.open,
        LearningCompatibility.compatible,
        ActivityStatus.live,
      ),
      ActivityId.tidyOneSurface: (
        'SPS',
        10,
        15,
        CircleMode.open,
        LearningCompatibility.compatible,
        ActivityStatus.live,
      ),
      ActivityId.singleTaskFocus: (
        '-P-',
        20,
        25,
        CircleMode.open,
        LearningCompatibility.compatible,
        ActivityStatus.live,
      ),
      ActivityId.quietAudioFocus: (
        '-PS',
        15,
        20,
        CircleMode.open,
        LearningCompatibility.compatible,
        ActivityStatus.live,
      ),
      ActivityId.focusedBreathingCount: (
        '-PS',
        3,
        5,
        CircleMode.paced,
        LearningCompatibility.reset,
        ActivityStatus.safetyReviewPending,
      ),
      ActivityId.restfulBreathingPause: (
        '-SP',
        3,
        5,
        CircleMode.paced,
        LearningCompatibility.reset,
        ActivityStatus.safetyReviewPending,
      ),
      ActivityId.gentleStretchPause: (
        'SSP',
        8,
        10,
        CircleMode.guidedSteps,
        LearningCompatibility.reset,
        ActivityStatus.live,
      ),
      ActivityId.quietSittingOutside: (
        '-SP',
        10,
        15,
        CircleMode.open,
        LearningCompatibility.compatible,
        ActivityStatus.live,
      ),
      ActivityId.smallComfortRitual: (
        '-SP',
        10,
        10,
        CircleMode.open,
        LearningCompatibility.compatible,
        ActivityStatus.live,
      ),
      ActivityId.unhurriedTidyPause: (
        '-SP',
        10,
        15,
        CircleMode.open,
        LearningCompatibility.compatible,
        ActivityStatus.live,
      ),
    };

String _fitCode(ActivityId id) => [
  for (final intention in Intention.values)
    switch (activityDefinition(id).fitFor(intention)) {
      NeedFit.primary => 'P',
      NeedFit.secondary => 'S',
      NeedFit.none => '-',
    },
].join();

/// Every user-facing string an activity carries.
Iterable<String> _allCopy(ActivityDefinition a) => [
  a.title,
  ...a.reasons.values,
  a.firstAction,
  ?a.preparation,
  ...a.whileYoureThere,
  for (final step in a.steps) ...[step.name, step.instruction, step.cue],
  ?a.lighter,
  ?a.safetyNote,
  a.ending,
];

Iterable<MapEntry<ActivityId, ActivityDefinition>> get _nonRetired =>
    activityCatalog.entries.where(
      (e) => e.value.status != ActivityStatus.retired,
    );

void main() {
  group('V2 activity model (PRODUCT_V2_CONTRACT — Activity model)', () {
    test('every ActivityId has exactly one catalogue entry', () {
      expect(activityCatalog.keys.toSet(), ActivityId.values.toSet());
    });

    test('the catalogue matches the founder-reviewed Phase A table: fit, '
        'minutes, mode, V1 learning class and status', () {
      expect(_reviewed.keys.toSet(), ActivityId.values.toSet());
      for (final MapEntry(key: id, value: row) in _reviewed.entries) {
        final a = activityDefinition(id);
        expect(
          (
            _fitCode(id),
            a.minMinutes,
            a.typicalMinutes,
            a.mode,
            a.v1Learning,
            a.status,
          ),
          (row.$1, row.$2, row.$3, row.$4, row.$5, row.$6),
          reason: id.name,
        );
      }
    });

    test('every non-retired activity has at least one PRIMARY need', () {
      for (final MapEntry(key: id, value: a) in _nonRetired) {
        expect(
          Intention.values.any((i) => a.fitFor(i) == NeedFit.primary),
          isTrue,
          reason: id.name,
        );
      }
    });

    test('natural duration: 0 < minimum ≤ typical ≤ 30, never padded to the '
        'half hour', () {
      for (final MapEntry(key: id, value: a) in _nonRetired) {
        expect(a.minMinutes, greaterThan(0), reason: id.name);
        expect(
          a.minMinutes,
          lessThanOrEqualTo(a.typicalMinutes),
          reason: id.name,
        );
        expect(a.typicalMinutes, lessThanOrEqualTo(30), reason: id.name);
      }
    });

    test('no activity copy still frames itself as a half hour unless 30 '
        'minutes is its natural length', () {
      final halfHour = RegExp(
        r'half an hour|half-hour|30 minutes|30-minute',
        caseSensitive: false,
      );
      for (final MapEntry(key: id, value: a) in _nonRetired) {
        if (a.typicalMinutes == 30) continue;
        for (final copy in _allCopy(a)) {
          expect(halfHour.hasMatch(copy), isFalse, reason: '$id: "$copy"');
        }
      }
    });

    test('a reason exists for every PRIMARY need, and none uses the V1 '
        '"For more energy:" formula', () {
      for (final MapEntry(key: id, value: a) in _nonRetired) {
        for (final intention in Intention.values) {
          if (a.fitFor(intention) != NeedFit.primary) continue;
          final reason = a.reasons[intention];
          expect(reason, isNotNull, reason: '$id / $intention');
          expect(reason, isNotEmpty, reason: '$id / $intention');
          expect(reason!.startsWith('For '), isFalse, reason: '$id: $reason');
        }
      }
    });

    test('mode content: Open has 2–3 "while you\'re there" ideas and no '
        'steps; Guided has 3–6 complete steps and a lighter version', () {
      for (final MapEntry(key: id, value: a) in _nonRetired) {
        expect(a.firstAction, isNotEmpty, reason: id.name);
        expect(a.ending, isNotEmpty, reason: id.name);
        switch (a.mode) {
          case CircleMode.open:
            expect(
              a.whileYoureThere.length,
              inInclusiveRange(2, 3),
              reason: id.name,
            );
            expect(a.steps, isEmpty, reason: id.name);
          case CircleMode.guidedSteps:
            expect(a.steps.length, inInclusiveRange(3, 6), reason: id.name);
            for (final step in a.steps) {
              expect(step.name, isNotEmpty, reason: id.name);
              expect(step.instruction, isNotEmpty, reason: id.name);
              expect(step.cue, isNotEmpty, reason: id.name);
            }
            expect(a.lighter, isNotNull, reason: id.name);
          case CircleMode.paced:
            // Pace parameters only arrive with the safety review.
            expect(a.safetyNote, isNotNull, reason: id.name);
        }
      }
    });

    test('every reason fits the two lines of the Today card beside the World '
        'art (at most 60 characters), so it is never cut off', () {
      for (final MapEntry(key: id, value: a) in _nonRetired) {
        for (final reason in a.reasons.values) {
          expect(reason.length, lessThanOrEqualTo(60), reason: '$id: $reason');
        }
      }
    });

    test('no activity copy contains a forbidden claim or framing', () {
      for (final MapEntry(key: id, value: a) in activityCatalog.entries) {
        for (final copy in _allCopy(a)) {
          for (final phrase in _forbiddenPhrases) {
            expect(
              copy.toLowerCase().contains(phrase),
              isFalse,
              reason: '$id: "$copy" contains "$phrase"',
            );
          }
        }
      }
    });
  });

  group('retired activity — energisingBreathReset (founder decision 1)', () {
    test('it is retired: no need fit, never offerable, never in any '
        'selector pool, in any build', () {
      final a = activityDefinition(ActivityId.energisingBreathReset);
      expect(a.status, ActivityStatus.retired);
      for (final intention in Intention.values) {
        expect(a.fitFor(intention), NeedFit.none);
        for (final allow in [true, false]) {
          expect(
            legacySelectorPool(intention, allowSafetyPending: allow),
            isNot(contains(ActivityId.energisingBreathReset)),
          );
        }
      }
      expect(
        isActivityOfferable(
          ActivityId.energisingBreathReset,
          allowSafetyPending: true,
        ),
        isFalse,
      );
    });

    test('it never seeds V2 learning, from any catalogue version', () {
      for (final version in [v1CatalogVersion, catalogVersion]) {
        expect(
          historicalEvidenceEligible(ActivityId.energisingBreathReset, version),
          isFalse,
        );
      }
    });

    test('its history still resolves: label, category and World role', () {
      expect(
        activityLabel(ActivityId.energisingBreathReset),
        'Standing breath reset',
      );
      expect(
        activityWorldRole(ActivityId.energisingBreathReset),
        WorldSceneRole.breathe,
      );
    });

    test('it is never selected on any day, for any need', () {
      for (final intention in Intention.values) {
        for (var day = 0; day < 60; day++) {
          expect(
            selectActivityId(intention: intention, dayIndex: day),
            isNot(ActivityId.energisingBreathReset),
          );
        }
      }
    });
  });

  group('safety gate (PRODUCT_V2_CONTRACT — Safety gate)', () {
    const gated = {
      ActivityId.briskStepBurst,
      ActivityId.activeMovementSnack,
      ActivityId.focusedBreathingCount,
      ActivityId.restfulBreathingPause,
    };

    test('exactly the breathing and exertion activities await review', () {
      expect({
        for (final e in activityCatalog.entries)
          if (e.value.status == ActivityStatus.safetyReviewPending) e.key,
      }, gated);
    });

    test('every breathing activity and every Paced activity is held back '
        'from release until reviewed', () {
      for (final MapEntry(key: id, value: a) in activityCatalog.entries) {
        final breathing =
            a.family == ActivitySemanticFamily.breathingStillness ||
            a.family == ActivitySemanticFamily.breathingEnergizer;
        if (breathing || a.mode == CircleMode.paced) {
          expect(a.status, isNot(ActivityStatus.live), reason: id.name);
        }
      }
    });

    test('only internal debug builds may offer gated content — profile and '
        'release builds never can', () {
      expect(safetyPendingContentAllowed, kDebugMode);
      expect(kReleaseMode && safetyPendingContentAllowed, isFalse);
      expect(kProfileMode && safetyPendingContentAllowed, isFalse);
    });

    test('with the gate closed (a release build), no gated activity is '
        'offerable, in any pool, on any day', () {
      for (final id in gated) {
        expect(isActivityOfferable(id, allowSafetyPending: false), isFalse);
        expect(isActivityOfferable(id, allowSafetyPending: true), isTrue);
      }
      for (final intention in Intention.values) {
        final pool = legacySelectorPool(intention, allowSafetyPending: false);
        expect(pool.toSet().intersection(gated), isEmpty);
        for (var day = 0; day < 60; day++) {
          expect(
            gated.contains(
              selectActivityId(
                intention: intention,
                dayIndex: day,
                allowSafetyPending: false,
              ),
            ),
            isFalse,
          );
        }
      }
    });
  });

  group('V1 → V2 learning compatibility (PRODUCT_V2_CONTRACT — '
      'Historical-learning compatibility)', () {
    test('every V1 activity carries an explicit classification', () {
      for (final id in ActivityId.values) {
        expect(
          LearningCompatibility.values,
          contains(activityDefinition(id).v1Learning),
          reason: id.name,
        );
      }
    });

    test('V1 answers count only for LEARNING_COMPATIBLE activities; V2 '
        'answers count for every non-retired activity', () {
      for (final MapEntry(key: id, value: a) in _nonRetired) {
        expect(
          historicalEvidenceEligible(id, v1CatalogVersion),
          a.v1Learning == LearningCompatibility.compatible,
          reason: id.name,
        );
        expect(
          historicalEvidenceEligible(id, catalogVersion),
          isTrue,
          reason: id.name,
        );
      }
    });

    test('A brisk walk: V1 natural-pace walk answers never seed V2 '
        'learning; its V2 answers do', () {
      expect(
        historicalEvidenceEligible(
          ActivityId.thirtyMinuteWalk,
          v1CatalogVersion,
        ),
        isFalse,
      );
      expect(
        historicalEvidenceEligible(ActivityId.thirtyMinuteWalk, catalogVersion),
        isTrue,
      );
    });

    test('the catalogue version advanced with the V2 catalogue', () {
      expect(catalogVersion, greaterThan(v1CatalogVersion));
    });
  });

  group('coverage without the optional additions (Phase A review)', () {
    test('every need keeps at least four releasable PRIMARY activities, and '
        'at least three releasable options that fit about ten minutes', () {
      for (final intention in Intention.values) {
        final releasable = [
          for (final MapEntry(key: id, value: a) in activityCatalog.entries)
            if (isActivityOfferable(id, allowSafetyPending: false) &&
                a.fitFor(intention) != NeedFit.none)
              a,
        ];
        expect(
          releasable
              .where((a) => a.fitFor(intention) == NeedFit.primary)
              .length,
          greaterThanOrEqualTo(4),
          reason: intention.name,
        );
        expect(
          releasable.where((a) => a.minMinutes <= 10).length,
          greaterThanOrEqualTo(3),
          reason: intention.name,
        );
      }
    });

    test('every need has at least one releasable indoor-friendly option '
        'that is not a walk', () {
      for (final intention in Intention.values) {
        expect(
          activityCatalog.entries.any(
            (e) =>
                isActivityOfferable(e.key, allowSafetyPending: false) &&
                e.value.fitFor(intention) != NeedFit.none &&
                e.value.category != ActivityCategory.walking,
          ),
          isTrue,
          reason: intention.name,
        );
      }
    });
  });

  group('activityLabel / activityCategory / World roles', () {
    test('every ActivityId has a label and a category', () {
      for (final activityId in ActivityId.values) {
        expect(activityLabel(activityId), isNotEmpty);
        expect(activityCategory(activityId), isNotNull);
      }
    });

    test('every activity has its approved World category and Scene role '
        '(WORLD_SYSTEM.md §16; ADR-018)', () {
      const expected = {
        ActivityId.thirtyMinuteWalk: (
          ActivityCategory.walking,
          WorldSceneRole.walk,
        ),
        ActivityId.moveToMusic: (
          ActivityCategory.movement,
          WorldSceneRole.move,
        ),
        ActivityId.phoneFreeWalk: (
          ActivityCategory.walking,
          WorldSceneRole.walk,
        ),
        ActivityId.writeItDown: (
          ActivityCategory.quietFocus,
          WorldSceneRole.write,
        ),
        ActivityId.quietReading: (
          ActivityCategory.quietFocus,
          WorldSceneRole.read,
        ),
        ActivityId.easyWalk: (ActivityCategory.walking, WorldSceneRole.walk),
        ActivityId.quietMusicBreak: (
          ActivityCategory.quietFocus,
          WorldSceneRole.listen,
        ),
        ActivityId.briskStepBurst: (
          ActivityCategory.walking,
          WorldSceneRole.walk,
        ),
        ActivityId.energisingStretchFlow: (
          ActivityCategory.movement,
          WorldSceneRole.stretch,
        ),
        ActivityId.activeMovementSnack: (
          ActivityCategory.movement,
          WorldSceneRole.move,
        ),
        ActivityId.energisingBreathReset: (
          ActivityCategory.stillness,
          WorldSceneRole.breathe,
        ),
        ActivityId.activeHouseholdTask: (
          ActivityCategory.homeCare,
          WorldSceneRole.tend,
        ),
        ActivityId.tidyOneSurface: (
          ActivityCategory.homeCare,
          WorldSceneRole.tend,
        ),
        ActivityId.singleTaskFocus: (
          ActivityCategory.quietFocus,
          WorldSceneRole.write,
        ),
        ActivityId.quietAudioFocus: (
          ActivityCategory.quietFocus,
          WorldSceneRole.listen,
        ),
        ActivityId.focusedBreathingCount: (
          ActivityCategory.stillness,
          WorldSceneRole.breathe,
        ),
        ActivityId.restfulBreathingPause: (
          ActivityCategory.stillness,
          WorldSceneRole.breathe,
        ),
        ActivityId.gentleStretchPause: (
          ActivityCategory.movement,
          WorldSceneRole.stretch,
        ),
        ActivityId.quietSittingOutside: (
          ActivityCategory.stillness,
          WorldSceneRole.breathe,
        ),
        ActivityId.smallComfortRitual: (
          ActivityCategory.homeCare,
          WorldSceneRole.comfort,
        ),
        ActivityId.unhurriedTidyPause: (
          ActivityCategory.homeCare,
          WorldSceneRole.tend,
        ),
      };

      expect(expected.keys.toSet(), ActivityId.values.toSet());
      for (final activityId in ActivityId.values) {
        expect(
          (activityCategory(activityId), activityWorldRole(activityId)),
          expected[activityId],
          reason: activityId.name,
        );
      }
    });

    test('every role an activity uses has a V1 default Scene', () {
      for (final activityId in ActivityId.values) {
        expect(
          () => v1ScenePolicy.sceneFor(activityWorldRole(activityId)),
          returnsNormally,
          reason: activityId.name,
        );
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
          expect(legacySelectorPool(intention), contains(activityId));
        }
      }
    });

    test('with no previous activity, uses the plain rotation candidate', () {
      final pool = legacySelectorPool(Intention.moreEnergy);
      for (var dayIndex = 0; dayIndex < pool.length; dayIndex++) {
        expect(
          selectActivityId(intention: Intention.moreEnergy, dayIndex: dayIndex),
          pool[dayIndex % pool.length],
        );
      }
    });

    test('anti-repetition: excluding the normal candidate picks a different '
        'pool member instead', () {
      final pool = legacySelectorPool(Intention.moreEnergy);
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
      final pool = legacySelectorPool(Intention.moreEnergy);
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
      final pool = legacySelectorPool(Intention.moreEnergy);
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
      final pool = legacySelectorPool(Intention.clearerHead);
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
      final pool = legacySelectorPool(Intention.moreEnergy);
      const dayIndex = 5;
      final normalCandidate = pool[dayIndex % pool.length];
      final unrelatedActivity = legacySelectorPool(Intention.clearerHead).first;

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
        final pool = legacySelectorPool(intention);
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

    test('excludes candidates sharing the immediately prior family when a '
        'different-family alternative exists', () {
      final pool = legacySelectorPool(Intention.moreEnergy);
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
    });

    test('falls back to the history-filtered pool (ignoring the family guard) '
        'when every remaining candidate shares the prior family', () {
      final pool = legacySelectorPool(Intention.moreEnergy);
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
    });

    test('the per-intention history filter still applies first, independently '
        'of the family guard', () {
      final pool = legacySelectorPool(Intention.clearerHead);
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
    });
  });
}
