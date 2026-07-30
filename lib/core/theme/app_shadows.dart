import 'package:flutter/material.dart';

/// Subtle elevation shadows for THIRTY. Light and dark mode are considered
/// separately rather than reusing one shadow with an inverted color.
class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> light = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> dark = [
    BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
}
