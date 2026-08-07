import 'package:flutter/material.dart';

/// Displays THIRTY's approved Quiet Trail Hero master illustration
/// (`assets/worlds/quiet_trail/quiet_trail_hero_master_v1.png`) exactly as
/// approved: filling the width it is given, cropped to a clean circle.
///
/// This widget shows one specific, already-approved asset — nothing more.
/// It carries no World selection, recommendation, or product logic of any
/// kind; whatever eventually decides "today's illustration is Quiet
/// Trail" is responsible for choosing to show this widget in the first
/// place, the same separation of concerns [QuietTrailHeroScene] and
/// [QuietTrailHeroView] already keep for the procedurally painted version
/// of this World (`quiet_trail_hero_view.dart`) — that widget is left
/// unchanged and available as a fallback, not replaced by this one.
///
/// The source illustration is a square, designed around a central
/// circular safe area (`docs/worlds/reference/QUIET_TRAIL_REFERENCE.md`)
/// — [AspectRatio] keeps this widget square regardless of the width it is
/// given, so [ClipOval] always carves the same circle the illustration
/// was approved against, never an ellipse.
class QuietTrailHeroAssetView extends StatelessWidget {
  const QuietTrailHeroAssetView({super.key});

  static const _assetPath =
      'assets/worlds/quiet_trail/quiet_trail_hero_master_v1.png';

  /// Nudges the cover-crop toward the illustration's subject (the
  /// tree/path), which sits right/below center in the source art —
  /// centered alignment left too much quiet empty space top/left.
  static const _imageAlignment = Alignment(0.18, 0.16);

  @override
  Widget build(BuildContext context) {
    // Decorative only (WORLD_SYSTEM.md, Design Principles: "The World is a
    // place, not an illustration" that competes for a screen reader's
    // attention) — whatever this illustration accompanies already
    // describes itself in words; this view must never announce a second,
    // duplicate description.
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipOval(
          child: Image.asset(
            _assetPath,
            fit: BoxFit.cover,
            alignment: _imageAlignment,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
