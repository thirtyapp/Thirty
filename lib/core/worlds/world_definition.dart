import '../activity_category.dart';
import 'place.dart';
import 'world_scene_role.dart';

/// A World's identity (WORLD_SYSTEM.md §3, "Identity") — e.g.
/// `quiet_trail`. Never derived from a display name; [Place] equality is
/// never used as World identity either.
class WorldId {
  const WorldId(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is WorldId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// A Scene's identity, owned by exactly one World: `<world>.<scene>`, e.g.
/// `still_lake.breathe`.
class WorldSceneId {
  const WorldSceneId(this.world, this.name);

  final WorldId world;
  final String name;

  String get value => '${world.value}.$name';

  @override
  bool operator ==(Object other) =>
      other is WorldSceneId && other.world == world && other.name == name;

  @override
  int get hashCode => Object.hash(world, name);

  @override
  String toString() => value;
}

/// One authored Scene within a World (WORLD_SYSTEM.md §3, "Scene"). It
/// implements exactly one [WorldSceneRole].
class WorldSceneDescriptor {
  const WorldSceneDescriptor({required this.id, required this.role});

  final WorldSceneId id;
  final WorldSceneRole role;
}

/// A self-contained World: its identity, its descriptive DNA, the
/// categories it may show, and its Scenes (WORLD_SYSTEM.md §17, "Modular
/// ownership"). Adding a World means adding one of these and registering
/// it — never editing another World.
class WorldDefinition {
  const WorldDefinition({
    required this.id,
    required this.place,
    required this.allowedCategories,
    required this.scenes,
  });

  final WorldId id;
  final Place place;

  /// The compatibility authority: an activity may only be shown in this
  /// World if its category is listed here.
  final Set<ActivityCategory> allowedCategories;

  final List<WorldSceneDescriptor> scenes;
}
