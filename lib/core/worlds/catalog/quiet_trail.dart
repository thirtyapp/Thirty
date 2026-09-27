import '../../activity_category.dart';
import '../place.dart';
import '../world_definition.dart';
import '../world_scene_role.dart';

/// Quiet Trail — THIRTY's first World (WORLD_SYSTEM.md §15, "Walking World
/// v1"; `docs/worlds/reference/QUIET_TRAIL_REFERENCE.md`).
const quietTrailId = WorldId('quiet_trail');

abstract final class QuietTrailScenes {
  static const walk = WorldSceneId(quietTrailId, 'walk');
}

/// Quiet Trail's World DNA (WORLD_SYSTEM.md, "World DNA").
const quietTrail = Place(
  name: 'Quiet Trail',
  emotion: 'Invitation',
  primaryActivity: 'Walking',
  dominantShape: 'Winding path through rolling hills',
  heroFocus: 'One organic tree on a distant hill, path winding toward it',
  cardFocus:
      'Same tree, same path, same horizon, as a simplified watercolor '
      'companion',
  primaryLight: 'Diffuse morning light, soft sunrise atmosphere',
  movement: 'Minimal — a few birds, subtle atmospheric drift; never game-like',
  growthElements: [
    'Flowers appearing along the path',
    'The tree becoming fuller',
    'A bench appearing over time',
  ],
);

const quietTrailWorld = WorldDefinition(
  id: quietTrailId,
  place: quietTrail,
  allowedCategories: {ActivityCategory.walking},
  scenes: [
    WorldSceneDescriptor(id: QuietTrailScenes.walk, role: WorldSceneRole.walk),
  ],
);
