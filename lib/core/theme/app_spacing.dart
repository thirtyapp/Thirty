/// Fixed spacing scale for THIRTY. Use these tokens instead of magic numbers
/// anywhere layout spacing is needed.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Outer padding of a screen/page.
  static const double page = l;

  /// Vertical spacing between distinct sections on a screen.
  static const double section = xl;

  /// Internal padding of a card-like surface. The compact default: list
  /// entries, control rows, and cards that share height with the Home hero.
  static const double card = m;

  /// Internal padding of a featured, standalone card — one that is the
  /// subject of its section rather than an entry in a list (a Plan, an
  /// Insight, a Premium offer). Opt-in via `ThirtyCard(padding: ...)`, never
  /// a new default: Phase A2 (`docs/design/PHASE_A_PLAN.md`) found a global
  /// increase of [card] would also enlarge compact surfaces.
  static const double featuredCard = l;
}
