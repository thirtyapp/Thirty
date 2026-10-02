import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

/// A Plan's World Card artwork, filling a viewport on a card's right edge.
/// Decorative only.
///
/// The same treatment as Home's Today card (`today_card.dart`), kept as a
/// separate copy so Plans never changes Home: drawn slightly larger than
/// its viewport and anchored right, so the authored watercolor edges fall
/// outside the card; the left side dissolves into the card surface. On
/// the dark card the art sits on the shared paper backing of
/// WORLD_SYSTEM.md §10a and stays slightly dimmed.
class PlanSceneArt extends StatelessWidget {
  const PlanSceneArt({required this.asset, this.fadeEnd = 0.45, super.key});

  final String asset;

  /// Where the fade from the card's surface ends, as a share of the
  /// viewport's width.
  final double fadeEnd;

  static const _light = (opacity: 1.0, paperOpacity: 0.0);
  static const _dark = (opacity: 0.85, paperOpacity: 0.12);
  static const _overscan = 1.12;

  @override
  Widget build(BuildContext context) {
    final treatment = Theme.of(context).brightness == Brightness.dark
        ? _dark
        : _light;
    Widget image({Color? paper}) => Image.asset(
      asset,
      fit: BoxFit.cover,
      alignment: Alignment.centerRight,
      color: paper,
      colorBlendMode: paper == null ? null : BlendMode.srcIn,
    );
    return ExcludeSemantics(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => LinearGradient(
          colors: const [Color(0x00000000), Color(0xFF000000)],
          stops: [0.0, fadeEnd],
        ).createShader(bounds),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bleed = constraints.maxHeight * (_overscan - 1) / 2;
            Widget overscanned(Widget child) => Positioned(
              left: 0,
              top: -bleed,
              right: -bleed,
              bottom: -bleed,
              child: child,
            );
            return Stack(
              children: [
                if (treatment.paperOpacity > 0)
                  overscanned(
                    image(
                      paper: AppColors.light.background.withValues(
                        alpha: treatment.paperOpacity,
                      ),
                    ),
                  ),
                overscanned(
                  Opacity(opacity: treatment.opacity, child: image()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
