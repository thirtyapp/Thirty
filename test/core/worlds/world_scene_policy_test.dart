import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/worlds/catalog/open_room.dart';
import 'package:thirty/core/worlds/catalog/quiet_trail.dart';
import 'package:thirty/core/worlds/world_definition.dart';
import 'package:thirty/core/worlds/world_registry.dart';
import 'package:thirty/core/worlds/world_scene_policy.dart';
import 'package:thirty/core/worlds/world_scene_role.dart';

void main() {
  final registry = WorldRegistry([quietTrailWorld, openRoomWorld]);

  group('DefaultWorldScenePolicy', () {
    test('returns the default Scene for a role', () {
      final policy = DefaultWorldScenePolicy(registry, const {
        WorldSceneRole.walk: QuietTrailScenes.walk,
      });

      expect(policy.sceneFor(WorldSceneRole.walk), QuietTrailScenes.walk);
    });

    test('throws a StateError for a role without a default', () {
      final policy = DefaultWorldScenePolicy(registry, const {
        WorldSceneRole.walk: QuietTrailScenes.walk,
      });

      expect(() => policy.sceneFor(WorldSceneRole.read), throwsStateError);
    });

    test('rejects a default that references an unknown Scene', () {
      expect(
        () => DefaultWorldScenePolicy(registry, const {
          WorldSceneRole.walk: WorldSceneId(WorldId('forest_path'), 'walk'),
        }),
        throwsArgumentError,
      );
    });

    test('rejects a default whose Scene implements a different role', () {
      expect(
        () => DefaultWorldScenePolicy(registry, const {
          WorldSceneRole.stretch: OpenRoomScenes.move,
        }),
        throwsArgumentError,
      );
    });
  });
}
