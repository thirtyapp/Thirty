import '../activity_category.dart';
import 'place.dart';
import 'world.dart';

/// The lookup between a [ActivityCategory] and the [Place]s available for it
/// (WORLD_SYSTEM.md §3: "A recommendation Category is not itself a World —
/// it is the axis that determines which Place options are available").
///
/// This mechanism is generic over any Category → Places mapping; it never
/// hardcodes which Places exist for which Category. Category-specific data
/// (for example, Walking → Quiet Trail) is supplied by whoever constructs
/// a [WorldRegistry], not by this class — see
/// `reference/quiet_trail_world.dart` for THIRTY's first, Walking-only
/// registry.
class WorldRegistry {
  const WorldRegistry(this._placesByCategory);

  final Map<ActivityCategory, List<Place>> _placesByCategory;

  /// Every [Place] registered for [category], in no particular order.
  /// Empty if no Place has been registered for it yet.
  List<Place> placesFor(ActivityCategory category) =>
      List.unmodifiable(_placesByCategory[category] ?? const []);

  /// The Place a recommendation in [category] resolves to when none is
  /// explicitly chosen. WORLD_SYSTEM.md §3 anticipates a Category
  /// eventually offering more than one Place; until that is designed, the
  /// first registered Place is the only — and therefore the primary —
  /// choice.
  ///
  /// Throws a [StateError] if no Place is registered for [category].
  Place primaryPlaceFor(ActivityCategory category) {
    final places = placesFor(category);
    if (places.isEmpty) {
      throw StateError('No Place is registered for $category.');
    }
    return places.first;
  }
}

/// Composes a [World] from its seven independent dimensions
/// (WORLD_SYSTEM.md, "World Lifecycle"). That diagram describes a
/// conceptual order of composition — Category, then Season, then Daypart,
/// then Weather Mood, then Personal Growth, then Premium Atmosphere — not
/// an implementation pipeline; this composer exists only to give that
/// conceptual order one canonical entry point, so nothing constructing a
/// [World] has to re-decide which dimension resolves before another.
class WorldComposer {
  const WorldComposer(this.registry);

  final WorldRegistry registry;

  /// Builds the [World] for [category] at the given moment. [place]
  /// overrides [WorldRegistry.primaryPlaceFor] for the future case where a
  /// Category offers more than one Place.
  World compose({
    required ActivityCategory category,
    required Season season,
    required Daypart daypart,
    required WeatherMood weatherMood,
    required PersonalGrowth personalGrowth,
    required PremiumAtmosphere premiumAtmosphere,
    Place? place,
  }) {
    return World(
      category: category,
      place: place ?? registry.primaryPlaceFor(category),
      season: season,
      daypart: daypart,
      weatherMood: weatherMood,
      personalGrowth: personalGrowth,
      premiumAtmosphere: premiumAtmosphere,
    );
  }
}
