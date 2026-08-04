import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/activity_category.dart';
import 'package:thirty/core/worlds/place.dart';
import 'package:thirty/core/worlds/world.dart';
import 'package:thirty/core/worlds/world_registry.dart';

const _quietTrail = Place(
  category: ActivityCategory.walking,
  name: 'Quiet Trail',
  emotion: 'Invitation',
  primaryActivity: 'Walking',
  dominantShape: 'Winding path through rolling hills',
  heroFocus: 'One organic tree on a distant hill',
  cardFocus: 'Same tree, same path, same horizon',
  primaryLight: 'Diffuse morning light',
  movement: 'Minimal — a few birds, subtle atmospheric drift',
  growthElements: ['Flowers appearing along the path'],
);

void main() {
  group('WorldRegistry', () {
    test('placesFor returns every Place registered for a category', () {
      final registry = WorldRegistry({
        ActivityCategory.walking: [_quietTrail],
      });

      expect(registry.placesFor(ActivityCategory.walking), [_quietTrail]);
    });

    test('placesFor returns an empty list for an unregistered category', () {
      const registry = WorldRegistry({});

      expect(registry.placesFor(ActivityCategory.walking), isEmpty);
    });

    test('primaryPlaceFor returns the first registered Place', () {
      final registry = WorldRegistry({
        ActivityCategory.walking: [_quietTrail],
      });

      expect(registry.primaryPlaceFor(ActivityCategory.walking), _quietTrail);
    });

    test('primaryPlaceFor throws for an unregistered category', () {
      const registry = WorldRegistry({});

      expect(
        () => registry.primaryPlaceFor(ActivityCategory.walking),
        throwsStateError,
      );
    });
  });

  group('WorldComposer', () {
    late WorldRegistry registry;
    late WorldComposer composer;

    setUp(() {
      registry = WorldRegistry({
        ActivityCategory.walking: [_quietTrail],
      });
      composer = WorldComposer(registry);
    });

    test('composes a World using the registry\'s primary Place', () {
      final world = composer.compose(
        category: ActivityCategory.walking,
        season: Season.autumn,
        daypart: Daypart.evening,
        weatherMood: WeatherMood.misty,
        personalGrowth: const PersonalGrowth(completedCircleCount: 3),
        premiumAtmosphere: PremiumAtmosphere.off,
      );

      expect(world.category, ActivityCategory.walking);
      expect(world.place, _quietTrail);
      expect(world.season, Season.autumn);
      expect(world.daypart, Daypart.evening);
      expect(world.weatherMood, WeatherMood.misty);
      expect(world.personalGrowth.completedCircleCount, 3);
      expect(world.premiumAtmosphere, PremiumAtmosphere.off);
    });

    test('an explicit place overrides the registry lookup', () {
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

      final world = composer.compose(
        category: ActivityCategory.walking,
        season: Season.summer,
        daypart: Daypart.afternoon,
        weatherMood: WeatherMood.clear,
        personalGrowth: PersonalGrowth.zero,
        premiumAtmosphere: PremiumAtmosphere.off,
        place: otherPlace,
      );

      expect(world.place, otherPlace);
    });
  });
}
