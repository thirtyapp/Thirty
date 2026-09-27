import 'world_definition.dart';

/// Every registered [WorldDefinition], validated once at construction
/// (WORLD_SYSTEM.md §17, "Modular ownership").
///
/// The registry knows Worlds and their Scenes only — it never maps a
/// category to a Place. Which Scene serves an activity is decided by a
/// selection policy (`world_scene_policy.dart`); whether that Scene's World
/// may show the activity is checked against
/// [WorldDefinition.allowedCategories].
///
/// Throws an [ArgumentError] for duplicate World IDs, duplicate Scene IDs
/// (within or across Worlds), malformed IDs, a Scene whose ID names a
/// different World than its owner, or a World with no categories or no
/// Scenes.
class WorldRegistry {
  WorldRegistry(List<WorldDefinition> worlds) {
    for (final world in worlds) {
      _checkIdPart(world.id.value, 'World ID');
      if (_worlds.containsKey(world.id)) {
        throw ArgumentError('Duplicate World ID "${world.id}".');
      }
      if (world.allowedCategories.isEmpty) {
        throw ArgumentError('World "${world.id}" allows no category.');
      }
      if (world.scenes.isEmpty) {
        throw ArgumentError('World "${world.id}" has no Scene.');
      }
      _worlds[world.id] = world;

      for (final scene in world.scenes) {
        _checkIdPart(scene.id.world.value, 'World part of Scene ID');
        _checkIdPart(scene.id.name, 'Scene name');
        if (scene.id.world != world.id) {
          throw ArgumentError(
            'Scene "${scene.id}" is registered under World "${world.id}".',
          );
        }
        if (_scenes.containsKey(scene.id)) {
          throw ArgumentError('Duplicate Scene ID "${scene.id}".');
        }
        _scenes[scene.id] = scene;
      }
    }
  }

  final Map<WorldId, WorldDefinition> _worlds = {};
  final Map<WorldSceneId, WorldSceneDescriptor> _scenes = {};

  static final _idPart = RegExp(r'^[a-z][a-z0-9_]*$');

  static void _checkIdPart(String value, String label) {
    if (!_idPart.hasMatch(value)) {
      throw ArgumentError('Malformed $label "$value".');
    }
  }

  Iterable<WorldDefinition> get worlds => _worlds.values;

  Iterable<WorldSceneDescriptor> get scenes => _scenes.values;

  /// Whether [id] is a registered Scene.
  bool hasScene(WorldSceneId id) => _scenes.containsKey(id);

  /// The registered World for [id]. Throws a [StateError] if unknown.
  WorldDefinition world(WorldId id) =>
      _worlds[id] ?? (throw StateError('Unknown World "$id".'));

  /// The registered Scene for [id]. Throws a [StateError] if unknown.
  WorldSceneDescriptor scene(WorldSceneId id) =>
      _scenes[id] ?? (throw StateError('Unknown Scene "$id".'));
}
