import 'package:flutter/material.dart';

/// Displays one World Hero asset filling a circle — the Circle's shape is
/// always the app's, never baked into the art (WORLD_SYSTEM.md §10a).
///
/// Sources are not all square (e.g. the 1536×1024 `garden_window.tend`
/// Heroes): [BoxFit.cover] fills the circle without stretching, centred.
/// [scale] enlarges the cover-crop further for art with a baked paper
/// frame; the asset itself is never altered.
///
/// It shows one asset and knows nothing about which World applies — the
/// caller passes the path of a resolved snapshot.
class WorldHeroArtView extends StatelessWidget {
  const WorldHeroArtView({required this.asset, this.scale = 1.0, super.key});

  final String asset;
  final double scale;

  @override
  Widget build(BuildContext context) {
    // Decorative only: the Circle and the Today card already say, in
    // words, what today is — scenery never announces itself.
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipOval(
          child: Transform.scale(
            scale: scale,
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
