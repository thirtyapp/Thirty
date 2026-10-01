import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/activity_category.dart';
import 'package:thirty/core/worlds/catalog/garden_window.dart';
import 'package:thirty/core/worlds/catalog/open_room.dart';
import 'package:thirty/core/worlds/catalog/quiet_trail.dart';
import 'package:thirty/core/worlds/catalog/reading_nook.dart';
import 'package:thirty/core/worlds/catalog/still_lake.dart';
import 'package:thirty/core/worlds/daypart.dart';
import 'package:thirty/core/worlds/place.dart';
import 'package:thirty/core/worlds/registered_worlds.dart';
import 'package:thirty/core/worlds/world.dart';
import 'package:thirty/core/worlds/world_art_manifest.dart';
import 'package:thirty/core/worlds/world_definition.dart';
import 'package:thirty/core/worlds/world_registry.dart';
import 'package:thirty/core/worlds/world_scene_policy.dart';
import 'package:thirty/core/worlds/world_scene_role.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/world_scene_resolution.dart';

final _morning = DateTime(2026, 9, 27, 8);
final _day = DateTime(2026, 9, 27, 14);
final _night = DateTime(2026, 9, 27, 2);

const _forestPathId = WorldId('forest_path');
const _forestPathWalk = WorldSceneId(_forestPathId, 'walk');

/// Test-only second walking World: proves a new World can serve an
/// existing role without any ActivityDefinition changing.
const _forestPathWorld = WorldDefinition(
  id: _forestPathId,
  place: Place(
    name: 'Forest Path',
    emotion: 'Shelter',
    primaryActivity: 'Walking',
    dominantShape: 'A path under a canopy',
    heroFocus: 'Tall trees',
    cardFocus: 'Tall trees',
    primaryLight: 'Dappled light',
    movement: 'Leaves drifting',
    growthElements: [],
  ),
  allowedCategories: {ActivityCategory.walking},
  scenes: [
    WorldSceneDescriptor(id: _forestPathWalk, role: WorldSceneRole.walk),
  ],
);

void main() {
  group('resolveWorldScene — V1', () {
    test('every activity resolves at every daypart, to a World that allows '
        'its category', () {
      for (final activityId in ActivityId.values) {
        for (final now in [_morning, _day, _night]) {
          final resolved = resolveWorldScene(activityId, now);
          final world = worldRegistry.world(resolved.worldId);

          expect(
            world.allowedCategories,
            contains(activityCategory(activityId)),
            reason: activityId.name,
          );
          expect(resolved.sceneId.world, resolved.worldId);
          expect(resolved.role, activityWorldRole(activityId));
          expect(resolved.place, world.place);
        }
      }
    });

    test('the same activity keeps its World and Scene; only the Daypart '
        'changes', () {
      final morning = resolveWorldScene(ActivityId.quietReading, _morning);
      final day = resolveWorldScene(ActivityId.quietReading, _day);
      final night = resolveWorldScene(ActivityId.quietReading, _night);

      for (final resolved in [morning, day, night]) {
        expect(resolved.worldId, readingNookId);
        expect(resolved.sceneId, ReadingNookScenes.read);
      }
      expect(morning.daypart, Daypart.morning);
      expect(day.daypart, Daypart.afternoon);
      expect(night.daypart, Daypart.evening);
    });

    test('activities with different roles resolve to their own Scenes', () {
      expect(
        resolveWorldScene(ActivityId.easyWalk, _morning).sceneId,
        QuietTrailScenes.walk,
      );
      expect(
        resolveWorldScene(ActivityId.restfulBreathingPause, _morning).sceneId,
        StillLakeScenes.breathe,
      );
      expect(
        resolveWorldScene(ActivityId.moveToMusic, _morning).sceneId,
        OpenRoomScenes.move,
      );
      expect(
        resolveWorldScene(ActivityId.smallComfortRitual, _morning).sceneId,
        GardenWindowScenes.comfort,
      );
    });

    test('equal inputs give equal snapshots', () {
      expect(
        resolveWorldScene(ActivityId.easyWalk, _morning),
        resolveWorldScene(ActivityId.easyWalk, _morning),
      );
    });
  });

  group('resolveWorldScene — expandability', () {
    test('a second walking World plugs in with only a registration and a '
        'policy change — easyWalk now resolves to forest_path.walk', () {
      final registry = WorldRegistry([quietTrailWorld, _forestPathWorld]);
      final policy = DefaultWorldScenePolicy(registry, const {
        WorldSceneRole.walk: _forestPathWalk,
      });

      final resolved = resolveWorldScene(
        ActivityId.easyWalk,
        _morning,
        policy: policy,
      );

      expect(resolved.worldId, _forestPathId);
      expect(resolved.sceneId, _forestPathWalk);
      // The activity's own definition is untouched.
      expect(activityWorldRole(ActivityId.easyWalk), WorldSceneRole.walk);
      expect(activityCategory(ActivityId.easyWalk), ActivityCategory.walking);
    });

    test('Quiet Trail keeps resolving while Forest Path is merely '
        'registered', () {
      final registry = WorldRegistry([quietTrailWorld, _forestPathWorld]);
      final policy = DefaultWorldScenePolicy(registry, const {
        WorldSceneRole.walk: QuietTrailScenes.walk,
      });

      expect(
        resolveWorldScene(
          ActivityId.easyWalk,
          _morning,
          policy: policy,
        ).worldId,
        quietTrailId,
      );
    });
  });

  group('resolveWorldScene — failures', () {
    test('a role with no default throws', () {
      final policy = DefaultWorldScenePolicy(
        WorldRegistry([quietTrailWorld]),
        const {WorldSceneRole.walk: QuietTrailScenes.walk},
      );

      expect(
        () => resolveWorldScene(
          ActivityId.quietReading,
          _morning,
          policy: policy,
        ),
        throwsStateError,
      );
    });

    test('a World that does not allow the activity\'s category throws', () {
      // A walk Scene in a World serving only stillness: easyWalk (walking)
      // must not be shown there.
      const stillWalkId = WorldId('still_walk');
      const stillWalk = WorldSceneId(stillWalkId, 'walk');
      final registry = WorldRegistry([
        const WorldDefinition(
          id: stillWalkId,
          place: stillLake,
          allowedCategories: {ActivityCategory.stillness},
          scenes: [
            WorldSceneDescriptor(id: stillWalk, role: WorldSceneRole.walk),
          ],
        ),
      ]);
      final policy = DefaultWorldScenePolicy(registry, const {
        WorldSceneRole.walk: stillWalk,
      });

      expect(
        () => resolveWorldScene(ActivityId.easyWalk, _morning, policy: policy),
        throwsStateError,
      );
    });
  });

  group('resolveWorldArt — V1', () {
    // One representative activity per registered role.
    const representatives = {
      WorldSceneRole.walk: (ActivityId.easyWalk, QuietTrailScenes.walk),
      WorldSceneRole.breathe: (
        ActivityId.restfulBreathingPause,
        StillLakeScenes.breathe,
      ),
      WorldSceneRole.move: (ActivityId.moveToMusic, OpenRoomScenes.move),
      WorldSceneRole.stretch: (
        ActivityId.gentleStretchPause,
        OpenRoomScenes.stretch,
      ),
      WorldSceneRole.read: (ActivityId.quietReading, ReadingNookScenes.read),
      WorldSceneRole.write: (ActivityId.writeItDown, ReadingNookScenes.write),
      WorldSceneRole.listen: (
        ActivityId.quietMusicBreak,
        ReadingNookScenes.listen,
      ),
      WorldSceneRole.tend: (ActivityId.tidyOneSurface, GardenWindowScenes.tend),
      WorldSceneRole.comfort: (
        ActivityId.smallComfortRitual,
        GardenWindowScenes.comfort,
      ),
    };

    test('covers every registered role', () {
      expect(representatives.keys.toSet(), WorldSceneRole.values.toSet());
    });

    representatives.forEach((role, expected) {
      final (activity, sceneId) = expected;
      test('${activity.name} → ${role.name} → $sceneId → matching Hero and '
          'Card for each Daypart', () {
        expect(activityWorldRole(activity), role);
        final folder = 'assets/worlds/${sceneId.world}/${sceneId.name}';
        for (final (now, suffix) in [
          (_morning, 'morning'),
          (_day, 'day'),
          (_night, 'evening'),
        ]) {
          final art = resolveWorldArt(activity, now);
          expect(art.scene.role, role);
          expect(art.scene.sceneId, sceneId);
          expect(art.scene.daypart, daypartAt(now));
          expect(art.heroAsset, '$folder/hero_$suffix.webp');
          expect(art.cardAsset, '$folder/card_$suffix.webp');
        }
      });
    });

    test('every activity resolves to art at the Daypart boundaries', () {
      for (final activityId in ActivityId.values) {
        for (final (hour, minute, suffix) in [
          (4, 59, 'evening'),
          (5, 0, 'morning'),
          (11, 59, 'morning'),
          (12, 0, 'day'),
          (17, 59, 'day'),
          (18, 0, 'evening'),
        ]) {
          final art = resolveWorldArt(
            activityId,
            DateTime(2026, 9, 27, hour, minute),
          );
          expect(art.heroAsset, endsWith('/hero_$suffix.webp'));
          expect(art.cardAsset, endsWith('/card_$suffix.webp'));
        }
      }
    });

    test('equal inputs give equal snapshots', () {
      expect(
        resolveWorldArt(ActivityId.tidyOneSurface, _day),
        resolveWorldArt(ActivityId.tidyOneSurface, _day),
      );
    });
  });

  group('resolveWorldArt — expandability and failures', () {
    WorldSceneArt artIn(String folder) => WorldSceneArt(
      heroMorning: '$folder/hero_morning.webp',
      heroDay: '$folder/hero_day.webp',
      heroEvening: '$folder/hero_evening.webp',
      cardMorning: '$folder/card_morning.webp',
      cardDay: '$folder/card_day.webp',
      cardEvening: '$folder/card_evening.webp',
    );

    test('a forest_path.walk Scene serves easyWalk with its own art, with no '
        'activity change', () {
      final registry = WorldRegistry([quietTrailWorld, _forestPathWorld]);
      final policy = DefaultWorldScenePolicy(registry, const {
        WorldSceneRole.walk: _forestPathWalk,
      });
      final manifest = WorldArtManifest(registry, {
        QuietTrailScenes.walk: artIn('assets/worlds/quiet_trail/walk'),
        _forestPathWalk: artIn('assets/worlds/forest_path/walk'),
      });

      final art = resolveWorldArt(
        ActivityId.easyWalk,
        _day,
        policy: policy,
        manifest: manifest,
      );

      expect(art.scene.sceneId, _forestPathWalk);
      expect(art.heroAsset, 'assets/worlds/forest_path/walk/hero_day.webp');
      expect(art.cardAsset, 'assets/worlds/forest_path/walk/card_day.webp');
      expect(activityWorldRole(ActivityId.easyWalk), WorldSceneRole.walk);
    });

    test(
      'a resolved Scene without art throws — never another Scene\'s art',
      () {
        final registry = WorldRegistry([quietTrailWorld, _forestPathWorld]);
        final policy = DefaultWorldScenePolicy(registry, const {
          WorldSceneRole.walk: _forestPathWalk,
        });
        final manifestWithoutForest = WorldArtManifest(
          WorldRegistry([quietTrailWorld]),
          {QuietTrailScenes.walk: artIn('assets/worlds/quiet_trail/walk')},
        );

        expect(
          () => resolveWorldArt(
            ActivityId.easyWalk,
            _day,
            policy: policy,
            manifest: manifestWithoutForest,
          ),
          throwsStateError,
        );
      },
    );
  });
}
