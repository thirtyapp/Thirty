import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Displays THIRTY's approved wordmark
/// (`assets/brand/thirty_wordmark.svg`) exactly as approved, scaled to fit
/// whatever size it is given.
///
/// This widget shows one specific, already-approved asset — nothing more.
/// It carries no First Breath sequencing, opacity, or motion of any kind
/// (`docs/brand/THIRTY_WORDMARK.md` §4 — the wordmark's appear/hold/fade is
/// a later, separate concern); whatever eventually drives that ritual is
/// responsible for animating this widget from the outside, the same
/// separation of concerns [QuietTrailHeroAssetView] already keeps between
/// showing an approved asset and deciding when/how it appears
/// (`quiet_trail_hero_asset_view.dart`).
class ThirtyWordmarkView extends StatelessWidget {
  const ThirtyWordmarkView({super.key});

  static const _assetPath = 'assets/brand/thirty_wordmark.svg';

  @override
  Widget build(BuildContext context) {
    // Decorative only (THIRTY_WORDMARK.md §8 — the Circle already owns the
    // only meaningful semantics for this moment) — this view must never
    // announce a second, duplicate description.
    return ExcludeSemantics(
      child: SvgPicture.asset(_assetPath, fit: BoxFit.contain),
    );
  }
}
