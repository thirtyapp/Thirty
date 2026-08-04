import 'package:flutter/material.dart';

import '../world_rendering/quiet_trail_hero_asset_view.dart';

/// TEMPORARY, development-only visual review harness for the approved
/// Quiet Trail Hero master illustration
/// (`assets/worlds/quiet_trail/quiet_trail_hero_master_v1.png`).
///
/// This page exists so the approved asset can be judged on a real device
/// or emulator — at mobile Hero size, inside the circular crop, against
/// the real app background — before any decision is made about
/// integrating it into Home. It is not part of THIRTY's product surface —
/// it is only reachable through the debug-only
/// `/dev/quiet-trail-hero-preview` route (see `../routing/app_router.dart`)
/// — and should be deleted together with that route once the visual
/// review this task exists for is complete.
///
/// [QuietTrailHeroView] (`../world_rendering/quiet_trail_hero_view.dart`),
/// the procedural `CustomPainter` this asset is being reviewed against, is
/// deliberately left unchanged and unreferenced by this page rather than
/// deleted — it remains available as a fallback and as the architectural
/// reference (`docs/worlds/reference/QUIET_TRAIL_REFERENCE.md`) the
/// approved asset was checked against.
class QuietTrailHeroPreviewPage extends StatelessWidget {
  const QuietTrailHeroPreviewPage({super.key});

  // Mirrors the Circle Hero's own responsive sizing (see CircleHero:
  // `_circleWidthFraction`, `_circleMinSize`, `_circleMaxSize`) closely
  // enough for "approximately the same size" — this page does not import
  // or depend on CircleHero itself.
  static const _viewportWidthFraction = 0.88;
  static const _viewportMinSize = 260.0;
  static const _viewportMaxSize = 440.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiet Trail Hero — dev preview')),
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size =
                  (constraints.maxWidth * _viewportWidthFraction)
                      .clamp(_viewportMinSize, _viewportMaxSize)
                      .toDouble();
              return SizedBox(
                width: size,
                height: size,
                child: const QuietTrailHeroAssetView(),
              );
            },
          ),
        ),
      ),
    );
  }
}
