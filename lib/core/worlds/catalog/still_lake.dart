import '../../activity_category.dart';
import '../place.dart';
import '../world_definition.dart';
import '../world_scene_role.dart';

/// Still Lake — breathing and still pause (WORLD_SYSTEM.md §16;
/// `docs/worlds/reference/STILL_LAKE_REFERENCE.md`).
const stillLakeId = WorldId('still_lake');

abstract final class StillLakeScenes {
  static const breathe = WorldSceneId(stillLakeId, 'breathe');
}

/// Still Lake's World DNA (WORLD_SYSTEM.md §16).
const stillLake = Place(
  name: 'Still Lake',
  emotion: 'Stillness',
  primaryActivity: 'Breathing and still pause',
  dominantShape:
      'A long, level horizontal: still water meeting a low, flat far shore',
  heroFocus:
      'One flat shore rock at the water\'s edge, off-centre, with the still '
      'surface stretching past it',
  cardFocus:
      'The shore rock and a band of still water, as a simplified watercolor '
      'companion',
  primaryLight: 'Soft, even light reflected off the water, mist lifting',
  movement:
      'Almost none — a single slow ripple ring, a drifting band of mist; '
      'never game-like',
  growthElements: [
    'Water lilies appearing near the shore',
    'The reed cluster filling out',
    'A small wooden jetty appearing over time',
  ],
);

const stillLakeWorld = WorldDefinition(
  id: stillLakeId,
  place: stillLake,
  allowedCategories: {ActivityCategory.stillness},
  scenes: [
    WorldSceneDescriptor(
      id: StillLakeScenes.breathe,
      role: WorldSceneRole.breathe,
    ),
  ],
);
