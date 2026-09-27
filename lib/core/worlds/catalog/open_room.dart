import '../../activity_category.dart';
import '../place.dart';
import '../world_definition.dart';
import '../world_scene_role.dart';

/// Open Room — stretching and free movement; THIRTY's V1 movement World
/// (WORLD_SYSTEM.md §16; `docs/worlds/reference/OPEN_ROOM_REFERENCE.md`).
const openRoomId = WorldId('open_room');

abstract final class OpenRoomScenes {
  static const move = WorldSceneId(openRoomId, 'move');
  static const stretch = WorldSceneId(openRoomId, 'stretch');
}

/// Open Room's World DNA (WORLD_SYSTEM.md §16).
const openRoom = Place(
  name: 'Open Room',
  emotion: 'Freedom — room to move',
  primaryActivity: 'Stretching and free movement',
  dominantShape: 'A large, open rectangle of bare floor under tall windows',
  heroFocus: 'The pool of light lying on the empty floor',
  cardFocus:
      'A pane of light on the floorboards, as a simplified watercolor '
      'companion',
  primaryLight: 'Broad daylight through tall windows',
  movement:
      'A curtain edge barely lifting, dust drifting in the light; never '
      'game-like',
  growthElements: [
    'The corner plant growing taller',
    'A second rug',
    'A low shelf gaining a few objects over time',
  ],
);

const openRoomWorld = WorldDefinition(
  id: openRoomId,
  place: openRoom,
  allowedCategories: {ActivityCategory.movement},
  scenes: [
    WorldSceneDescriptor(id: OpenRoomScenes.move, role: WorldSceneRole.move),
    WorldSceneDescriptor(
      id: OpenRoomScenes.stretch,
      role: WorldSceneRole.stretch,
    ),
  ],
);
