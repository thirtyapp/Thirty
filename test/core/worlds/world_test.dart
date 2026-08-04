import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/activity_category.dart';
import 'package:thirty/core/worlds/place.dart';
import 'package:thirty/core/worlds/world.dart';

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

World _world({
  Season season = Season.spring,
  Daypart daypart = Daypart.morning,
  WeatherMood weatherMood = WeatherMood.clear,
  PersonalGrowth personalGrowth = PersonalGrowth.zero,
  PremiumAtmosphere premiumAtmosphere = PremiumAtmosphere.off,
}) {
  return World(
    category: ActivityCategory.walking,
    place: _quietTrail,
    season: season,
    daypart: daypart,
    weatherMood: weatherMood,
    personalGrowth: personalGrowth,
    premiumAtmosphere: premiumAtmosphere,
  );
}

void main() {
  group('PersonalGrowth', () {
    test('zero starts at a completedCircleCount of 0', () {
      expect(PersonalGrowth.zero.completedCircleCount, 0);
    });

    test('rejects a negative completedCircleCount', () {
      expect(
        () => PersonalGrowth(completedCircleCount: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('two instances with the same count are equal', () {
      expect(
        const PersonalGrowth(completedCircleCount: 5),
        const PersonalGrowth(completedCircleCount: 5),
      );
    });
  });

  group('PremiumAtmosphere', () {
    test('off and on are distinct and equal to their own values', () {
      expect(PremiumAtmosphere.off, const PremiumAtmosphere(isEnabled: false));
      expect(PremiumAtmosphere.on, const PremiumAtmosphere(isEnabled: true));
      expect(PremiumAtmosphere.off, isNot(PremiumAtmosphere.on));
    });
  });

  group('World', () {
    test('two Worlds composed from the same dimensions are equal', () {
      expect(_world(), _world());
    });

    test('changing one dimension makes Worlds unequal', () {
      expect(_world(season: Season.spring), isNot(_world(season: Season.autumn)));
    });

    test('copyWith replaces only the given dimensions', () {
      final original = _world(season: Season.spring, daypart: Daypart.morning);

      final updated = original.copyWith(season: Season.winter);

      expect(updated.season, Season.winter);
      expect(updated.daypart, Daypart.morning);
      expect(updated.place, original.place);
      expect(updated.category, original.category);
    });

    test('copyWith with no arguments returns an equal World', () {
      final original = _world();

      expect(original.copyWith(), original);
    });

    test(
      'personalGrowth and premiumAtmosphere vary independently of the rest',
      () {
        final grown = _world(
          personalGrowth: const PersonalGrowth(completedCircleCount: 12),
        );
        final premium = _world(premiumAtmosphere: PremiumAtmosphere.on);

        expect(grown.season, premium.season);
        expect(grown.place, premium.place);
        expect(grown, isNot(premium));
      },
    );
  });
}
