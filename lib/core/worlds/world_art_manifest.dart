import 'world.dart';
import 'world_definition.dart';
import 'world_registry.dart';

/// The artwork suffix of a [Daypart] (WORLD_SYSTEM.md §10, "Daypart
/// boundaries"): [Daypart.afternoon]'s artwork is named `day`.
String daypartArtworkSuffix(Daypart daypart) => switch (daypart) {
  Daypart.morning => 'morning',
  Daypart.afternoon => 'day',
  Daypart.evening => 'evening',
};

/// One Scene's production artwork: a Hero and a Card for each Daypart
/// (ADR-018). Every combination is a required, explicit asset path, so a
/// Scene can never resolve to a missing or guessed file.
class WorldSceneArt {
  const WorldSceneArt({
    required this.heroMorning,
    required this.heroDay,
    required this.heroEvening,
    required this.cardMorning,
    required this.cardDay,
    required this.cardEvening,
    this.heroScale = 1.0,
  }) : assert(heroScale >= 1.0, 'A Hero may be enlarged, never shrunk.');

  final String heroMorning;
  final String heroDay;
  final String heroEvening;
  final String cardMorning;
  final String cardDay;
  final String cardEvening;

  /// Presentation-only enlargement of the Hero inside the Circle, for
  /// source art whose baked paper frame would otherwise show at the
  /// Circle's edge (asset-freeze reconciliation §1). The file itself is
  /// never cropped or re-exported.
  final double heroScale;

  String hero(Daypart daypart) => switch (daypart) {
    Daypart.morning => heroMorning,
    Daypart.afternoon => heroDay,
    Daypart.evening => heroEvening,
  };

  String card(Daypart daypart) => switch (daypart) {
    Daypart.morning => cardMorning,
    Daypart.afternoon => cardDay,
    Daypart.evening => cardEvening,
  };

  List<String> get assets => [
    heroMorning,
    heroDay,
    heroEvening,
    cardMorning,
    cardDay,
    cardEvening,
  ];
}

/// The production artwork of every registered Scene, validated once at
/// construction against [registry].
///
/// Throws an [ArgumentError] if a registered Scene has no artwork, if
/// artwork names an unregistered Scene, or if one asset path is used
/// twice — missing artwork fails here, never at render time with a
/// fallback (ADR-018, Consequences).
class WorldArtManifest {
  WorldArtManifest(
    WorldRegistry registry,
    Map<WorldSceneId, WorldSceneArt> scenes,
  ) : _scenes = Map.unmodifiable(scenes) {
    for (final scene in registry.scenes) {
      if (!_scenes.containsKey(scene.id)) {
        throw ArgumentError('Scene "${scene.id}" has no artwork.');
      }
    }
    final seen = <String>{};
    _scenes.forEach((sceneId, art) {
      if (!registry.hasScene(sceneId)) {
        throw ArgumentError('Artwork names unknown Scene "$sceneId".');
      }
      for (final asset in art.assets) {
        if (!seen.add(asset)) {
          throw ArgumentError('Asset "$asset" is mapped twice.');
        }
      }
    });
  }

  final Map<WorldSceneId, WorldSceneArt> _scenes;

  Iterable<WorldSceneId> get sceneIds => _scenes.keys;

  /// The artwork of [sceneId]. Throws a [StateError] if it has none.
  WorldSceneArt art(WorldSceneId sceneId) =>
      _scenes[sceneId] ??
      (throw StateError('Scene "$sceneId" has no artwork.'));
}
