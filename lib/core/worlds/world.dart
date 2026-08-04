import '../activity_category.dart';
import 'place.dart';

/// Spring, summer, autumn or winter. Affects a World's detail, never its
/// identity (WORLD_SYSTEM.md §9, "Seasons") — the [Place] a World renders
/// stays the same [Place] in every Season.
enum Season { spring, summer, autumn, winter }

/// Morning, afternoon or evening. Affects light and atmosphere, never a
/// World's identity (WORLD_SYSTEM.md §10, "Daypart and Weather Mood").
enum Daypart { morning, afternoon, evening }

/// A restrained, secondary atmospheric layer (WORLD_SYSTEM.md §10,
/// "Daypart and Weather Mood"). WORLD_SYSTEM.md introduces this dimension
/// with "examples include," so this set may grow as new moods are
/// approved — it is not presented there as a closed, final list.
enum WeatherMood { clear, cloudy, misty, lightRain }

/// A World's permanent, cumulative growth (WORLD_SYSTEM.md §11, "Personal
/// Growth"). Deliberately modeled as a single, monotonically-increasing
/// count with no reset, decay, or "current streak" concept — the type
/// itself makes streak logic impossible to represent here, in line with
/// the Playbook's standing anti-streak rule (Ch.1 §7–8) and this being its
/// direct extension into the World System: "the world grows through
/// return, not perfection" (WORLD_SYSTEM.md §11).
///
/// Exact milestone thresholds — when a flower appears, when a tree fills
/// out — are explicitly deferred to future product configuration
/// (WORLD_SYSTEM.md §11, §18) and are not represented here.
class PersonalGrowth {
  const PersonalGrowth({required this.completedCircleCount})
    : assert(
        completedCircleCount >= 0,
        'completedCircleCount can only grow; it is never negative.',
      );

  /// The total number of Circles ever closed by this user. Cumulative and
  /// permanent — it never decreases, regardless of absence.
  final int completedCircleCount;

  static const zero = PersonalGrowth(completedCircleCount: 0);

  @override
  bool operator ==(Object other) =>
      other is PersonalGrowth &&
      other.completedCircleCount == completedCircleCount;

  @override
  int get hashCode => completedCircleCount.hashCode;
}

/// Whether a World's optional Premium Atmosphere is active (WORLD_SYSTEM.md
/// §3, §12). A World's identity, Seasons, and Personal Growth are
/// identical with or without it — Premium may only deepen the atmosphere
/// (motion, light, sound, detail) layered on top of the same World, never
/// replace or gate it: "Free Worlds grow. Premium Worlds breathe."
/// (WORLD_SYSTEM.md §12).
class PremiumAtmosphere {
  const PremiumAtmosphere({required this.isEnabled});

  final bool isEnabled;

  static const off = PremiumAtmosphere(isEnabled: false);
  static const on = PremiumAtmosphere(isEnabled: true);

  @override
  bool operator ==(Object other) =>
      other is PremiumAtmosphere && other.isEnabled == isEnabled;

  @override
  int get hashCode => isEnabled.hashCode;
}

/// THIRTY's illustrated environment for one recommendation, composed of
/// seven independent dimensions (WORLD_SYSTEM.md §3, "World Structure").
/// Each dimension varies on its own; together they describe the exact
/// scene a user sees at a given moment. A World is never one fixed image —
/// it is the product of composing all seven, which is exactly what keeps
/// THIRTY's illustrated worlds "infinitely varied while remaining,
/// underneath, a small and disciplined system" (WORLD_SYSTEM.md §3).
///
/// This class carries only the composed *identity* of a World. It renders
/// nothing itself — WORLD_SYSTEM.md §5 defines the four visual expressions
/// a World can conceptually be rendered through (Hero, Activity Card,
/// Session, Completion); no concrete presentation contract for them exists
/// yet. See `world_registry.dart` for how a World is composed.
class World {
  const World({
    required this.category,
    required this.place,
    required this.season,
    required this.daypart,
    required this.weatherMood,
    required this.personalGrowth,
    required this.premiumAtmosphere,
  });

  /// The recommendation family this World belongs to.
  final ActivityCategory category;

  /// The stable identity of this World — the one dimension that never
  /// changes regardless of the other six (WORLD_SYSTEM.md §3, §4).
  final Place place;

  final Season season;
  final Daypart daypart;
  final WeatherMood weatherMood;

  /// This user's permanent, cumulative history with this World.
  final PersonalGrowth personalGrowth;

  /// Whether this World's optional Premium Atmosphere is active.
  final PremiumAtmosphere premiumAtmosphere;

  /// Returns a copy with the given dimensions replaced. Every dimension
  /// can be varied independently of the others, per WORLD_SYSTEM.md §3:
  /// "These dimensions must remain independently composable."
  World copyWith({
    ActivityCategory? category,
    Place? place,
    Season? season,
    Daypart? daypart,
    WeatherMood? weatherMood,
    PersonalGrowth? personalGrowth,
    PremiumAtmosphere? premiumAtmosphere,
  }) {
    return World(
      category: category ?? this.category,
      place: place ?? this.place,
      season: season ?? this.season,
      daypart: daypart ?? this.daypart,
      weatherMood: weatherMood ?? this.weatherMood,
      personalGrowth: personalGrowth ?? this.personalGrowth,
      premiumAtmosphere: premiumAtmosphere ?? this.premiumAtmosphere,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is World &&
      other.category == category &&
      other.place == place &&
      other.season == season &&
      other.daypart == daypart &&
      other.weatherMood == weatherMood &&
      other.personalGrowth == personalGrowth &&
      other.premiumAtmosphere == premiumAtmosphere;

  @override
  int get hashCode => Object.hash(
    category,
    place,
    season,
    daypart,
    weatherMood,
    personalGrowth,
    premiumAtmosphere,
  );
}
