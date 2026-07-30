import 'package:flutter/material.dart';

/// Corner-radius tokens for THIRTY, exposed as ready-to-use [BorderRadius]
/// values so call sites don't need to call `BorderRadius.circular(...)`
/// themselves for standard, reusable shapes.
class AppRadius {
  const AppRadius._();

  static const BorderRadius small = BorderRadius.all(Radius.circular(8));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(12));
  static const BorderRadius large = BorderRadius.all(Radius.circular(16));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}
