import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/activity_category.dart';
import 'package:thirty/core/worlds/reference/quiet_trail_world.dart';
import 'package:thirty/core/worlds/world.dart';
import 'package:thirty/core/worlds/world_registry.dart';

void main() {
  group('quietTrail', () {
    test('matches WORLD_SYSTEM.md\'s Walking World v1 identity', () {
      expect(quietTrail.category, ActivityCategory.walking);
      expect(quietTrail.name, 'Quiet Trail');
      expect(quietTrail.emotion, 'Invitation');
      expect(quietTrail.primaryActivity, 'Walking');
    });
  });

  group('defaultWorldRegistry', () {
    test('resolves Walking to Quiet Trail', () {
      expect(
        defaultWorldRegistry.primaryPlaceFor(ActivityCategory.walking),
        quietTrail,
      );
    });

    test('composes a full World for Walking end to end', () {
      final composer = WorldComposer(defaultWorldRegistry);

      final world = composer.compose(
        category: ActivityCategory.walking,
        season: Season.summer,
        daypart: Daypart.morning,
        weatherMood: WeatherMood.clear,
        personalGrowth: PersonalGrowth.zero,
        premiumAtmosphere: PremiumAtmosphere.off,
      );

      expect(world.place, quietTrail);
    });
  });
}
