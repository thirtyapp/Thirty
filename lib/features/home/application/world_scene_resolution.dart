import '../../../core/worlds/daypart.dart';
import '../../../core/worlds/place.dart';
import '../../../core/worlds/registered_worlds.dart';
import '../../../core/worlds/world.dart';
import '../../../core/worlds/world_definition.dart';
import '../../../core/worlds/world_scene_policy.dart';
import '../../../core/worlds/world_scene_role.dart';
import 'activity_catalog.dart';

/// The World, Scene and Daypart one activity is shown in at one moment —
/// the single snapshot every visual expression of it must share
/// (WORLD_SYSTEM.md §10, "Stability").
class ResolvedWorldScene {
  const ResolvedWorldScene({
    required this.worldId,
    required this.place,
    required this.sceneId,
    required this.role,
    required this.daypart,
  });

  final WorldId worldId;
  final Place place;
  final WorldSceneId sceneId;
  final WorldSceneRole role;
  final Daypart daypart;

  @override
  bool operator ==(Object other) =>
      other is ResolvedWorldScene &&
      other.worldId == worldId &&
      other.place == place &&
      other.sceneId == sceneId &&
      other.role == role &&
      other.daypart == daypart;

  @override
  int get hashCode => Object.hash(worldId, place, sceneId, role, daypart);
}

/// Resolves [activityId] at device-local [now]: its role selects a Scene
/// through [policy] (V1's [v1ScenePolicy] by default), the Scene's World
/// must allow the activity's category, and [now] sets the Daypart.
///
/// Throws a [StateError] if the role has no default, the Scene is unknown
/// or implements another role, or its World does not allow the activity's
/// category — never silently falls back to another World.
ResolvedWorldScene resolveWorldScene(
  ActivityId activityId,
  DateTime now, {
  DefaultWorldScenePolicy? policy,
}) {
  final selection = policy ?? v1ScenePolicy;
  final role = activityWorldRole(activityId);
  final sceneId = selection.sceneFor(role);
  final scene = selection.registry.scene(sceneId);
  if (scene.role != role) {
    throw StateError(
      'Scene "$sceneId" implements "${scene.role.name}", not "${role.name}".',
    );
  }
  final world = selection.registry.world(sceneId.world);
  final category = activityCategory(activityId);
  if (!world.allowedCategories.contains(category)) {
    throw StateError(
      'World "${world.id}" does not allow "${category.name}" '
      '(${activityId.name}).',
    );
  }
  return ResolvedWorldScene(
    worldId: world.id,
    place: world.place,
    sceneId: sceneId,
    role: role,
    daypart: daypartAt(now),
  );
}
