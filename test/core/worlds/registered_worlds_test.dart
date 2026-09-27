import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/worlds/registered_worlds.dart';
import 'package:thirty/core/worlds/world_scene_role.dart';

void main() {
  group('V1 registered Worlds', () {
    test('the registry and policy construct without validation errors', () {
      expect(worldRegistry.worlds, isNotEmpty);
      expect(v1ScenePolicy.defaults, isNotEmpty);
    });

    test('every V1 role has its approved default Scene', () {
      // Content lock for the approved V1 pack (WORLD_SYSTEM.md §16) — the
      // data, not a structural rule: more Scenes may implement a role.
      final defaults = {
        for (final role in WorldSceneRole.values)
          role: v1ScenePolicy.sceneFor(role).value,
      };
      expect(defaults, {
        WorldSceneRole.walk: 'quiet_trail.walk',
        WorldSceneRole.breathe: 'still_lake.breathe',
        WorldSceneRole.move: 'open_room.move',
        WorldSceneRole.stretch: 'open_room.stretch',
        WorldSceneRole.read: 'reading_nook.read',
        WorldSceneRole.write: 'reading_nook.write',
        WorldSceneRole.listen: 'reading_nook.listen',
        WorldSceneRole.tend: 'garden_window.tend',
        WorldSceneRole.comfort: 'garden_window.comfort',
      });
    });

    test('every default Scene implements its role', () {
      v1ScenePolicy.defaults.forEach((role, sceneId) {
        expect(worldRegistry.scene(sceneId).role, role);
      });
    });

    test('every registered World declares at least one category and Scene', () {
      for (final world in worldRegistry.worlds) {
        expect(world.allowedCategories, isNotEmpty, reason: '${world.id}');
        expect(world.scenes, isNotEmpty, reason: '${world.id}');
      }
    });
  });
}
