import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/activity_category.dart';
import 'package:thirty/core/worlds/catalog/quiet_trail.dart';
import 'package:thirty/core/worlds/world_definition.dart';
import 'package:thirty/core/worlds/world_scene_role.dart';

void main() {
  group('quietTrail', () {
    test('matches WORLD_SYSTEM.md\'s Walking World v1 identity', () {
      expect(quietTrail.name, 'Quiet Trail');
      expect(quietTrail.emotion, 'Invitation');
      expect(quietTrail.primaryActivity, 'Walking');
    });
  });

  group('quietTrailWorld', () {
    test('is identified by its World ID and serves walking', () {
      expect(quietTrailWorld.id, const WorldId('quiet_trail'));
      expect(quietTrailWorld.place, quietTrail);
      expect(quietTrailWorld.allowedCategories, {ActivityCategory.walking});
    });

    test('owns quiet_trail.walk, implementing the walk role', () {
      expect(quietTrailWorld.scenes, hasLength(1));
      final scene = quietTrailWorld.scenes.single;
      expect(scene.id, QuietTrailScenes.walk);
      expect(scene.id.value, 'quiet_trail.walk');
      expect(scene.role, WorldSceneRole.walk);
    });
  });
}
