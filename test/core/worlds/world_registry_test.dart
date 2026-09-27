import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/activity_category.dart';
import 'package:thirty/core/worlds/catalog/quiet_trail.dart';
import 'package:thirty/core/worlds/place.dart';
import 'package:thirty/core/worlds/world_definition.dart';
import 'package:thirty/core/worlds/world_registry.dart';
import 'package:thirty/core/worlds/world_scene_role.dart';

const _forestPathId = WorldId('forest_path');
const _forestPathWalk = WorldSceneId(_forestPathId, 'walk');

const _forestPath = Place(
  name: 'Forest Path',
  emotion: 'Shelter',
  primaryActivity: 'Walking',
  dominantShape: 'A path under a canopy',
  heroFocus: 'Tall trees',
  cardFocus: 'Tall trees',
  primaryLight: 'Dappled light',
  movement: 'Leaves drifting',
  growthElements: [],
);

/// Test-only second walking World, beside Quiet Trail.
const forestPathWorld = WorldDefinition(
  id: _forestPathId,
  place: _forestPath,
  allowedCategories: {ActivityCategory.walking},
  scenes: [
    WorldSceneDescriptor(id: _forestPathWalk, role: WorldSceneRole.walk),
  ],
);

WorldDefinition _world({
  String id = 'test_world',
  Set<ActivityCategory> categories = const {ActivityCategory.walking},
  List<WorldSceneDescriptor>? scenes,
}) {
  final worldId = WorldId(id);
  return WorldDefinition(
    id: worldId,
    place: _forestPath,
    allowedCategories: categories,
    scenes:
        scenes ??
        [
          WorldSceneDescriptor(
            id: WorldSceneId(worldId, 'walk'),
            role: WorldSceneRole.walk,
          ),
        ],
  );
}

void main() {
  group('WorldRegistry', () {
    test('exposes registered Worlds and Scenes by ID', () {
      final registry = WorldRegistry([quietTrailWorld]);

      expect(registry.world(quietTrailId), quietTrailWorld);
      expect(registry.scene(QuietTrailScenes.walk).role, WorldSceneRole.walk);
      expect(registry.hasScene(QuietTrailScenes.walk), isTrue);
    });

    test('throws a StateError for an unknown World or Scene', () {
      final registry = WorldRegistry([quietTrailWorld]);

      expect(() => registry.world(_forestPathId), throwsStateError);
      expect(() => registry.scene(_forestPathWalk), throwsStateError);
      expect(registry.hasScene(_forestPathWalk), isFalse);
    });

    group('rejects', () {
      test('a duplicate World ID', () {
        expect(
          () => WorldRegistry([_world(id: 'a'), _world(id: 'a')]),
          throwsArgumentError,
        );
      });

      test('a duplicate Scene ID within one World', () {
        const id = WorldSceneId(WorldId('a'), 'walk');
        expect(
          () => WorldRegistry([
            _world(
              id: 'a',
              scenes: const [
                WorldSceneDescriptor(id: id, role: WorldSceneRole.walk),
                WorldSceneDescriptor(id: id, role: WorldSceneRole.breathe),
              ],
            ),
          ]),
          throwsArgumentError,
        );
      });

      test('a Scene whose ID names a different World than its owner', () {
        expect(
          () => WorldRegistry([
            _world(
              id: 'a',
              scenes: const [
                WorldSceneDescriptor(
                  id: WorldSceneId(WorldId('b'), 'walk'),
                  role: WorldSceneRole.walk,
                ),
              ],
            ),
          ]),
          throwsArgumentError,
        );
      });

      test('the same Scene ID claimed by a second World', () {
        // A Scene ID can only be duplicated across Worlds if one of them
        // registers a foreign Scene, which is itself rejected first.
        expect(
          () => WorldRegistry([
            quietTrailWorld,
            _world(
              id: 'b',
              scenes: const [
                WorldSceneDescriptor(
                  id: QuietTrailScenes.walk,
                  role: WorldSceneRole.walk,
                ),
              ],
            ),
          ]),
          throwsArgumentError,
        );
      });

      for (final malformed in [
        '',
        'Quiet_trail',
        '1trail',
        'quiet-trail',
        'quiet.trail',
      ]) {
        test('a malformed World ID "$malformed"', () {
          expect(
            () => WorldRegistry([_world(id: malformed)]),
            throwsArgumentError,
          );
        });
      }

      test('a malformed Scene name', () {
        expect(
          () => WorldRegistry([
            _world(
              id: 'a',
              scenes: const [
                WorldSceneDescriptor(
                  id: WorldSceneId(WorldId('a'), 'Walk'),
                  role: WorldSceneRole.walk,
                ),
              ],
            ),
          ]),
          throwsArgumentError,
        );
      });

      test('a World with no categories', () {
        expect(
          () => WorldRegistry([_world(categories: const {})]),
          throwsArgumentError,
        );
      });

      test('a World with no Scenes', () {
        expect(
          () => WorldRegistry([_world(scenes: const [])]),
          throwsArgumentError,
        );
      });
    });

    test('allows a second World for the same category and role — '
        'forest_path.walk beside quiet_trail.walk', () {
      final registry = WorldRegistry([quietTrailWorld, forestPathWorld]);

      final walkScenes = registry.scenes
          .where((scene) => scene.role == WorldSceneRole.walk)
          .map((scene) => scene.id)
          .toSet();
      expect(walkScenes, {QuietTrailScenes.walk, _forestPathWalk});

      final walkingWorlds = registry.worlds
          .where((w) => w.allowedCategories.contains(ActivityCategory.walking))
          .map((w) => w.id)
          .toSet();
      expect(walkingWorlds, {quietTrailId, _forestPathId});
    });
  });
}
