import '../../activity_category.dart';
import '../place.dart';
import '../world_definition.dart';
import '../world_scene_role.dart';

/// Reading Nook — reading, writing, single-task focus and quiet listening
/// (WORLD_SYSTEM.md §16; `docs/worlds/reference/READING_NOOK_REFERENCE.md`).
const readingNookId = WorldId('reading_nook');

abstract final class ReadingNookScenes {
  static const read = WorldSceneId(readingNookId, 'read');
  static const write = WorldSceneId(readingNookId, 'write');
  static const listen = WorldSceneId(readingNookId, 'listen');
}

/// Reading Nook's World DNA (WORLD_SYSTEM.md §16).
const readingNook = Place(
  name: 'Reading Nook',
  emotion: 'Absorption',
  primaryActivity: 'Reading, writing, single-task focus and quiet listening',
  dominantShape:
      'An enclosed alcove: a rounded chair back framed by a shelf and a '
      'small window',
  heroFocus: 'The armchair beneath the lamp',
  cardFocus:
      'The chair arm or side surface, lit by the scene\'s current light, as a '
      'simplified watercolor companion',
  primaryLight:
      'Soft side light from a small window, with a warm lamp as secondary '
      'light',
  movement:
      'Almost none — a curtain edge, the lamp\'s faint warmth; never '
      'game-like',
  growthElements: [
    'A second stack of books',
    'A trailing shelf plant growing longer',
    'A knitted throw appearing on the chair',
  ],
);

const readingNookWorld = WorldDefinition(
  id: readingNookId,
  place: readingNook,
  allowedCategories: {ActivityCategory.quietFocus},
  scenes: [
    WorldSceneDescriptor(id: ReadingNookScenes.read, role: WorldSceneRole.read),
    WorldSceneDescriptor(
      id: ReadingNookScenes.write,
      role: WorldSceneRole.write,
    ),
    WorldSceneDescriptor(
      id: ReadingNookScenes.listen,
      role: WorldSceneRole.listen,
    ),
  ],
);
