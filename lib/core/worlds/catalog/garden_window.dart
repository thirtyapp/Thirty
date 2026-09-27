import '../../activity_category.dart';
import '../place.dart';
import '../world_definition.dart';
import '../world_scene_role.dart';

/// Garden Window — tending, tidying and small comfort rituals at home
/// (WORLD_SYSTEM.md §16; `docs/worlds/reference/GARDEN_WINDOW_REFERENCE.md`).
const gardenWindowId = WorldId('garden_window');

abstract final class GardenWindowScenes {
  static const tend = WorldSceneId(gardenWindowId, 'tend');
  static const comfort = WorldSceneId(gardenWindowId, 'comfort');
}

/// Garden Window's World DNA (WORLD_SYSTEM.md §16).
const gardenWindow = Place(
  name: 'Garden Window',
  emotion: 'Care',
  primaryActivity: 'Tending, tidying and small comfort rituals',
  dominantShape: 'A window frame opening from a calm table onto a small garden',
  heroFocus: 'The terracotta potted plant on the sill, against the garden',
  cardFocus: 'Sill, plant and table edge, as a simplified watercolor companion',
  primaryLight: 'Daylight falling through the garden window across the table',
  movement: 'Leaves stirring outside, steam from a cup; never game-like',
  growthElements: [
    'A herb pot appearing on the sill',
    'The garden filling with flowers',
    'A climbing plant framing the window over time',
  ],
);

const gardenWindowWorld = WorldDefinition(
  id: gardenWindowId,
  place: gardenWindow,
  allowedCategories: {ActivityCategory.homeCare},
  scenes: [
    WorldSceneDescriptor(
      id: GardenWindowScenes.tend,
      role: WorldSceneRole.tend,
    ),
    WorldSceneDescriptor(
      id: GardenWindowScenes.comfort,
      role: WorldSceneRole.comfort,
    ),
  ],
);
