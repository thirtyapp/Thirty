import '../activity_category.dart';

/// A World's stable visual and emotional identity — "the one thing about a
/// World that never changes, regardless of season, time, weather, or the
/// user's history with it" (WORLD_SYSTEM.md §3, "Place").
///
/// Every field here is descriptive identity, not a rendering instruction —
/// this mirrors the "World DNA" reference profile WORLD_SYSTEM.md defines
/// for designers, developers and future content reviews (WORLD_SYSTEM.md,
/// "World DNA"). Colour is deliberately not one of these fields: a Place
/// never carries its own hex values, so it can never drift out of sync
/// with the design system's single source of truth for colour
/// (DESIGN_SYSTEM.md) — actual rendering reads colour from the active
/// THIRTY theme (`AppColors`) at render time instead.
class Place {
  const Place({
    required this.category,
    required this.name,
    required this.emotion,
    required this.primaryActivity,
    required this.dominantShape,
    required this.heroFocus,
    required this.cardFocus,
    required this.primaryLight,
    required this.movement,
    required this.growthElements,
  });

  /// The [ActivityCategory] this Place belongs to. WORLD_SYSTEM.md §3
  /// anticipates a single Category eventually offering more than one
  /// Place.
  final ActivityCategory category;

  /// Describes a place or a feeling — never a season, time of day, weather
  /// condition, progress state or subscription tier (WORLD_SYSTEM.md §4,
  /// "Naming Rules"). Stays identical across every Season and Daypart this
  /// Place is ever rendered in.
  final String name;

  /// The single emotional objective this Place is designed around
  /// (WORLD_SYSTEM.md, "Emotional Intent").
  final String emotion;

  final String primaryActivity;

  /// The Circle Hero World's dominant compositional shape
  /// (WORLD_SYSTEM.md §7, "Depth and Composition").
  final String dominantShape;

  /// What the Hero expression's composition centres on
  /// (WORLD_SYSTEM.md §5.A).
  final String heroFocus;

  /// What the Activity Card expression keeps, once the Hero scene is
  /// reduced to line art (WORLD_SYSTEM.md §5.B).
  final String cardFocus;

  final String primaryLight;

  /// A short description of this Place's restrained, ambient World Motion
  /// (Motion Language §9) — always secondary to the Circle, never
  /// game-like.
  final String movement;

  /// The permanent additions this Place can accumulate through Personal
  /// Growth (WORLD_SYSTEM.md §11), described qualitatively. Exact
  /// milestone thresholds are a future decision, not represented here.
  final List<String> growthElements;

  @override
  bool operator ==(Object other) =>
      other is Place && other.category == category && other.name == name;

  @override
  int get hashCode => Object.hash(category, name);
}
