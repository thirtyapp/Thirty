import 'world_definition.dart';
import 'world_registry.dart';
import 'world_scene_role.dart';

/// V1's Scene selection: one approved default Scene per [WorldSceneRole]
/// (WORLD_SYSTEM.md §3, "Scene Role"; ADR-018). Deterministic — no
/// rotation, randomness or user choice.
///
/// Defaults live here rather than on the Scenes so that changing which
/// World serves a role never edits a World definition. A role has at most
/// one default by construction (a map key); several registered Scenes may
/// still implement the same role.
///
/// Throws an [ArgumentError] if a default names an unregistered Scene or a
/// Scene implementing a different role.
class DefaultWorldScenePolicy {
  DefaultWorldScenePolicy(this.registry, this.defaults) {
    defaults.forEach((role, sceneId) {
      if (!registry.hasScene(sceneId)) {
        throw ArgumentError(
          'Default for "${role.name}" is unknown Scene '
          '"$sceneId".',
        );
      }
      final sceneRole = registry.scene(sceneId).role;
      if (sceneRole != role) {
        throw ArgumentError(
          'Default for "${role.name}" is Scene "$sceneId", '
          'which implements "${sceneRole.name}".',
        );
      }
    });
  }

  final WorldRegistry registry;
  final Map<WorldSceneRole, WorldSceneId> defaults;

  /// The Scene selected for [role]. Throws a [StateError] if [role] has no
  /// approved default.
  WorldSceneId sceneFor(WorldSceneRole role) =>
      defaults[role] ??
      (throw StateError('No default Scene for role "${role.name}".'));
}
