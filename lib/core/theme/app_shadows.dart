import 'package:flutter/material.dart';

/// Subtle elevation shadows for THIRTY. Light and dark mode are considered
/// separately rather than reusing one shadow with an inverted color.
///
/// Two layers: a soft, diffuse ambient shadow that lifts the surface off
/// the page, plus a tight contact shadow that anchors its edge. Both stay
/// deliberately short (blur <= 16, offset <= 4) — cards in the history list
/// sit only `AppSpacing.s` apart, and a wider spread would bleed between
/// neighbours.
class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> light = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x08000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  // Shadows barely read on a near-black page, so dark-mode separation is
  // carried mainly by ThirtyCard's hairline border; these only add depth.
  static const List<BoxShadow> dark = [
    BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 2, offset: Offset(0, 1)),
  ];
}
