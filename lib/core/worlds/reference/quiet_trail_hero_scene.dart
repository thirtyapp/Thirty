import '../world.dart';
import 'quiet_trail_world.dart';

/// The semantic warmth of a Hero scene's light — not a colour value.
/// Actual colour is resolved by a renderer from the active THIRTY theme at
/// paint time (DESIGN_SYSTEM.md) — the same separation [Place] already
/// keeps (`../place.dart`): scene data never carries its own hex values.
enum LightWarmth { cool, neutral, warm }

/// One bird's relative position and size within a Hero scene's sky layer.
///
/// `x`/`y` are normalized (0.0–1.0) positions within the scene's bounds,
/// not pixel coordinates, shapes, or path commands — a renderer maps them
/// to whatever size it is given. `scale` varies each bird slightly so a
/// flock reads as several distinct birds, not one shape repeated
/// (WORLD_SYSTEM.md §15: "two or three varied birds").
class BirdPlacement {
  const BirdPlacement({required this.x, required this.y, this.scale = 1.0})
    : assert(x >= 0 && x <= 1, 'x is a normalized position (0.0-1.0).'),
      assert(y >= 0 && y <= 1, 'y is a normalized position (0.0-1.0).'),
      assert(scale > 0, 'scale must be positive.');

  final double x;
  final double y;
  final double scale;

  @override
  bool operator ==(Object other) =>
      other is BirdPlacement &&
      other.x == x &&
      other.y == y &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(x, y, scale);
}

/// What should be rendered for Quiet Trail's Circle Hero World
/// (WORLD_SYSTEM.md §5.A, §15) — described semantically, not as shapes,
/// paths, Bézier commands, pixels or Canvas operations. A renderer
/// interprets this data; this class has no opinion on how anything is
/// drawn.
///
/// Deliberately scoped to exactly what Quiet Trail's approved composition
/// needs (WORLD_SYSTEM.md §15: sky, distant hills, one tree, a winding
/// path, restrained vegetation, two or three birds) — not a generic scene
/// graph other Worlds are assumed to reuse. A second World's scene needs
/// are unknown until one is actually built; generalizing this ahead of
/// that evidence would be guessing, not architecture.
class QuietTrailHeroScene {
  // Not a const constructor: the birds.length invariant below is not a
  // constant expression Dart's const evaluator accepts, even though the
  // check itself is simple and deterministic.
  QuietTrailHeroScene({
    required this.atmosphereIntensity,
    required this.lightWarmth,
    required this.showDistantHills,
    required this.showMiddleLandscape,
    required this.showTree,
    required this.showPath,
    required this.vegetationDensity,
    required this.birds,
  }) : assert(
         atmosphereIntensity >= 0 && atmosphereIntensity <= 1,
         'atmosphereIntensity is normalized (0.0-1.0).',
       ),
       assert(
         vegetationDensity >= 0 && vegetationDensity <= 1,
         'vegetationDensity is normalized (0.0-1.0).',
       ),
       assert(
         birds.length >= 2 && birds.length <= 3,
         'WORLD_SYSTEM.md §15 calls for two or three varied birds.',
       );

  /// How present the sky's soft atmospheric glow is, 0.0 (flat) to 1.0
  /// (full soft-sunrise atmosphere) — WORLD_SYSTEM.md §15's "light
  /// atmospheric depth."
  final double atmosphereIntensity;

  /// The light's semantic warmth (WORLD_SYSTEM.md §8: diffuse morning
  /// light, golden-hour warmth).
  final LightWarmth lightWarmth;

  /// Layer visibility — WORLD_SYSTEM.md §7's depth composition (distant
  /// layer, middle layer, focal element).
  final bool showDistantHills;
  final bool showMiddleLandscape;
  final bool showTree;
  final bool showPath;

  /// How much restrained foreground vegetation is present, 0.0 (none) to
  /// 1.0 (full restrained density) — WORLD_SYSTEM.md §15's "restrained
  /// vegetation."
  final double vegetationDensity;

  /// Two or three varied birds, far off in the sky.
  final List<BirdPlacement> birds;

  /// How many depth layers this scene currently renders — a readable
  /// summary of the booleans above, not a separate input
  /// (WORLD_SYSTEM.md §7, "layered depth"). Sky and light are not counted
  /// here: they are the atmosphere the other layers sit inside, not a
  /// layer among them.
  int get depthLayerCount =>
      (showDistantHills ? 1 : 0) +
      (showMiddleLandscape ? 1 : 0) +
      (showTree ? 1 : 0) +
      (showPath ? 1 : 0) +
      (vegetationDensity > 0 ? 1 : 0);

  @override
  bool operator ==(Object other) {
    if (other is! QuietTrailHeroScene) return false;
    if (other.atmosphereIntensity != atmosphereIntensity ||
        other.lightWarmth != lightWarmth ||
        other.showDistantHills != showDistantHills ||
        other.showMiddleLandscape != showMiddleLandscape ||
        other.showTree != showTree ||
        other.showPath != showPath ||
        other.vegetationDensity != vegetationDensity ||
        other.birds.length != birds.length) {
      return false;
    }
    for (var i = 0; i < birds.length; i++) {
      if (other.birds[i] != birds[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    atmosphereIntensity,
    lightWarmth,
    showDistantHills,
    showMiddleLandscape,
    showTree,
    showPath,
    vegetationDensity,
    Object.hashAll(birds),
  );
}

/// Quiet Trail's one reference base Hero scene (WORLD_SYSTEM.md §15,
/// "Walking World v1"). This is the scene every future modifier — a
/// seasonal palette, a weather-mood haze, a growth milestone, a Premium
/// atmosphere layer — will vary starting from, not a placeholder to be
/// thrown away once those exist.
final _baseQuietTrailHeroScene = QuietTrailHeroScene(
  atmosphereIntensity: 0.6,
  lightWarmth: LightWarmth.warm,
  showDistantHills: true,
  showMiddleLandscape: true,
  showTree: true,
  showPath: true,
  vegetationDensity: 0.35,
  birds: [
    BirdPlacement(x: 0.20, y: 0.22),
    BirdPlacement(x: 0.32, y: 0.16, scale: 0.85),
    BirdPlacement(x: 0.62, y: 0.24, scale: 1.1),
  ],
);

/// Derives the Circle Hero scene for Quiet Trail from [world].
///
/// [world] — not just a [Place] — is accepted because a Hero scene is
/// ultimately a function of the full World: WORLD_SYSTEM.md's "World
/// Lifecycle" layers Season, Daypart, Weather Mood, Personal Growth and
/// Premium Atmosphere onto a selected World, in that order. None of those
/// five modifiers is implemented yet: for v1.0, every Quiet Trail [World]
/// resolves to the same stable base scene below, regardless of its
/// season, daypart, weather mood, growth, or Premium Atmosphere. This is
/// deliberate, not an oversight — WORLD_SYSTEM.md §9 states "the
/// composition and place identity remain stable," and implementing five
/// unapproved visual variants ahead of any of them being designed would
/// be inventing behaviour nobody has signed off on.
QuietTrailHeroScene quietTrailHeroScene(World world) {
  assert(
    world.place == quietTrail,
    'quietTrailHeroScene only describes the Quiet Trail Place; got '
    "'${world.place.name}'.",
  );
  return _baseQuietTrailHeroScene;
}
