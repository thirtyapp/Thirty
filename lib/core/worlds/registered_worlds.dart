import 'catalog/garden_window.dart';
import 'catalog/open_room.dart';
import 'catalog/quiet_trail.dart';
import 'catalog/reading_nook.dart';
import 'catalog/still_lake.dart';
import 'world_registry.dart';
import 'world_scene_policy.dart';
import 'world_scene_role.dart';

/// THIRTY's registered Worlds — the V1 content pack (WORLD_SYSTEM.md
/// §15–§16). Adding a World means adding its catalog file and one entry
/// here; no existing World changes.
final worldRegistry = WorldRegistry([
  quietTrailWorld,
  stillLakeWorld,
  openRoomWorld,
  readingNookWorld,
  gardenWindowWorld,
]);

/// V1's approved default Scene per role (WORLD_SYSTEM.md §16; ADR-018).
final v1ScenePolicy = DefaultWorldScenePolicy(worldRegistry, const {
  WorldSceneRole.walk: QuietTrailScenes.walk,
  WorldSceneRole.breathe: StillLakeScenes.breathe,
  WorldSceneRole.move: OpenRoomScenes.move,
  WorldSceneRole.stretch: OpenRoomScenes.stretch,
  WorldSceneRole.read: ReadingNookScenes.read,
  WorldSceneRole.write: ReadingNookScenes.write,
  WorldSceneRole.listen: ReadingNookScenes.listen,
  WorldSceneRole.tend: GardenWindowScenes.tend,
  WorldSceneRole.comfort: GardenWindowScenes.comfort,
});
