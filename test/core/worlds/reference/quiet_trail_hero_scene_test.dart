import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/activity_category.dart';
import 'package:thirty/core/worlds/place.dart';
import 'package:thirty/core/worlds/reference/quiet_trail_hero_scene.dart';
import 'package:thirty/core/worlds/reference/quiet_trail_world.dart';
import 'package:thirty/core/worlds/world.dart';

World _worldWith({
  Season season = Season.spring,
  Daypart daypart = Daypart.morning,
  WeatherMood weatherMood = WeatherMood.clear,
  PersonalGrowth personalGrowth = PersonalGrowth.zero,
  PremiumAtmosphere premiumAtmosphere = PremiumAtmosphere.off,
}) {
  return World(
    category: ActivityCategory.walking,
    place: quietTrail,
    season: season,
    daypart: daypart,
    weatherMood: weatherMood,
    personalGrowth: personalGrowth,
    premiumAtmosphere: premiumAtmosphere,
  );
}

QuietTrailHeroScene _sceneWithBirds(List<BirdPlacement> birds) {
  return QuietTrailHeroScene(
    atmosphereIntensity: 0.5,
    lightWarmth: LightWarmth.warm,
    showDistantHills: true,
    showMiddleLandscape: true,
    showTree: true,
    showPath: true,
    vegetationDensity: 0.3,
    birds: birds,
  );
}

void main() {
  group('quietTrailHeroScene', () {
    final scene = quietTrailHeroScene(_worldWith());

    test('contains every approved Quiet Trail Hero layer', () {
      expect(scene.showDistantHills, isTrue);
      expect(scene.showMiddleLandscape, isTrue);
      expect(scene.showTree, isTrue);
      expect(scene.showPath, isTrue);
      expect(scene.vegetationDensity, greaterThan(0));
      expect(scene.atmosphereIntensity, greaterThan(0));
      expect(scene.depthLayerCount, 5);
    });

    test('keeps the bird count within the approved small range', () {
      expect(scene.birds.length, inInclusiveRange(2, 3));
    });

    test('is deterministic regardless of unimplemented World modifiers', () {
      final a = quietTrailHeroScene(
        _worldWith(
          season: Season.winter,
          daypart: Daypart.evening,
          weatherMood: WeatherMood.misty,
          personalGrowth: const PersonalGrowth(completedCircleCount: 40),
          premiumAtmosphere: PremiumAtmosphere.on,
        ),
      );
      final b = quietTrailHeroScene(_worldWith());

      expect(a, b);
      expect(identical(a, b), isTrue);
    });

    test('rejects a World for a different Place', () {
      const otherPlace = Place(
        category: ActivityCategory.walking,
        name: 'Forest Path',
        emotion: 'Invitation',
        primaryActivity: 'Walking',
        dominantShape: 'A forest clearing',
        heroFocus: 'Tall trees',
        cardFocus: 'Tall trees',
        primaryLight: 'Dappled light',
        movement: 'Leaves drifting',
        growthElements: [],
      );

      expect(
        () => quietTrailHeroScene(
          World(
            category: ActivityCategory.walking,
            place: otherPlace,
            season: Season.spring,
            daypart: Daypart.morning,
            weatherMood: WeatherMood.clear,
            personalGrowth: PersonalGrowth.zero,
            premiumAtmosphere: PremiumAtmosphere.off,
          ),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('QuietTrailHeroScene invariants', () {
    test('rejects fewer than two birds', () {
      expect(
        () => _sceneWithBirds(const [BirdPlacement(x: 0.2, y: 0.2)]),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects more than three birds', () {
      expect(
        () => _sceneWithBirds(const [
          BirdPlacement(x: 0.1, y: 0.1),
          BirdPlacement(x: 0.2, y: 0.2),
          BirdPlacement(x: 0.3, y: 0.3),
          BirdPlacement(x: 0.4, y: 0.4),
        ]),
        throwsA(isA<AssertionError>()),
      );
    });

    test('accepts exactly two or three birds', () {
      expect(
        () => _sceneWithBirds(const [
          BirdPlacement(x: 0.1, y: 0.1),
          BirdPlacement(x: 0.2, y: 0.2),
        ]),
        returnsNormally,
      );
      expect(
        () => _sceneWithBirds(const [
          BirdPlacement(x: 0.1, y: 0.1),
          BirdPlacement(x: 0.2, y: 0.2),
          BirdPlacement(x: 0.3, y: 0.3),
        ]),
        returnsNormally,
      );
    });

    test('rejects an out-of-range atmosphereIntensity', () {
      expect(
        () => QuietTrailHeroScene(
          atmosphereIntensity: 1.5,
          lightWarmth: LightWarmth.warm,
          showDistantHills: true,
          showMiddleLandscape: true,
          showTree: true,
          showPath: true,
          vegetationDensity: 0.3,
          birds: const [
            BirdPlacement(x: 0.2, y: 0.2),
            BirdPlacement(x: 0.3, y: 0.3),
          ],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects an out-of-range vegetationDensity', () {
      expect(
        () => QuietTrailHeroScene(
          atmosphereIntensity: 0.5,
          lightWarmth: LightWarmth.warm,
          showDistantHills: true,
          showMiddleLandscape: true,
          showTree: true,
          showPath: true,
          vegetationDensity: -0.1,
          birds: const [
            BirdPlacement(x: 0.2, y: 0.2),
            BirdPlacement(x: 0.3, y: 0.3),
          ],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects an out-of-range bird position', () {
      expect(
        // Not const: an invalid const BirdPlacement would fail at compile
        // time (const expressions are assert-checked by the analyzer),
        // not at the runtime this test wants to exercise.
        () => BirdPlacement(x: 1.2, y: 0.2),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a non-positive bird scale', () {
      expect(
        () => BirdPlacement(x: 0.2, y: 0.2, scale: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('depthLayerCount ignores hidden layers', () {
      final scene = QuietTrailHeroScene(
        atmosphereIntensity: 0.5,
        lightWarmth: LightWarmth.warm,
        showDistantHills: false,
        showMiddleLandscape: false,
        showTree: false,
        showPath: false,
        vegetationDensity: 0,
        birds: const [
          BirdPlacement(x: 0.2, y: 0.2),
          BirdPlacement(x: 0.3, y: 0.3),
        ],
      );

      expect(scene.depthLayerCount, 0);
    });
  });

  test('quiet_trail_hero_scene.dart has no Flutter dependency', () {
    final source = File(
      'lib/core/worlds/reference/quiet_trail_hero_scene.dart',
    ).readAsStringSync();

    expect(source.contains('package:flutter'), isFalse);
  });
}
