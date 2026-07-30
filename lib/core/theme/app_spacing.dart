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

  /// Internal padding of a card-like surface.
  static const double card = m;
}
