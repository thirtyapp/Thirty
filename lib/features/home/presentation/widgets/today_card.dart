import 'package:flutter/material.dart';

import '../../../../core/activity_category.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_card.dart';

/// Home's time-of-day greeting (Phase D1): morning from 05:00, afternoon
/// from 12:00, evening from 18:00 until 05:00.
String homeGreeting(DateTime now) {
  final hour = now.hour;
  if (hour >= 5 && hour < 12) return 'Good morning';
  if (hour >= 12 && hour < 18) return 'Good afternoon';
  return 'Good evening';
}

/// The line under the greeting while today's Circle is still open.
const homeGreetingSubline = "Ready to close today's Circle?";

/// The Today card (Phase D1, Design vision): TODAY, today's direction in
/// the editorial serif, the activity with its icon, a divider, and up to
/// two lines of why it was chosen — left-aligned in a card, with today's
/// World Card artwork ([cardAsset]) fading in at its right edge. Kept tight
/// so Start Circle stays above the fold beneath the full-size Circle.
///
/// [cardAsset] comes from the same resolved snapshot as the Circle's Hero
/// (`ResolvedWorldArt`), never resolved here; when it changes, the art
/// crossfades over [artSwitchDuration].
///
/// The slice is decorative and only appears while the text has room for
/// it (text scale below 130% and a card at least 300pt wide); at large
/// text the card is text only, so nothing is squeezed or truncated.
/// [intentOpacity] and [detailOpacity] keep First Breath's reveal order:
/// the card with its direction, then the activity and its reason.
class TodayCard extends StatelessWidget {
  const TodayCard({
    required this.intent,
    required this.activity,
    required this.why,
    required this.category,
    required this.cardAsset,
    required this.intentOpacity,
    required this.detailOpacity,
    this.artSwitchDuration = Duration.zero,
    super.key,
  });

  final String intent;
  final String activity;
  final String why;
  final ActivityCategory category;
  final String cardAsset;
  final Duration artSwitchDuration;
  final Animation<double> intentOpacity;
  final Animation<double> detailOpacity;

  static const _largeTextScale = 1.3;
  static const _minWidthForArt = 300.0;

  /// Share of the card's width the text column keeps beside the art.
  static const _textShareWithArt = 0.75;

  static const _chipSize = 28.0;
  static const _intentFontSize = 22.0;

  static IconData iconFor(ActivityCategory category) => switch (category) {
    ActivityCategory.walking => Icons.directions_walk_rounded,
    ActivityCategory.stillness ||
    ActivityCategory.movement ||
    ActivityCategory.quietFocus ||
    ActivityCategory.homeCare => Icons.spa_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final largeText =
        MediaQuery.textScalerOf(context).scale(1) >= _largeTextScale;
    final labelStyle = textTheme.labelSmall?.copyWith(
      color: colors.textSecondary,
      letterSpacing: 1.5,
    );
    final intentStyle = AppTypography.editorialDisplay(
      colors,
    ).copyWith(fontSize: _intentFontSize);

    return FadeTransition(
      opacity: intentOpacity,
      // The card always spans the page's content width.
      child: SizedBox(
        width: double.infinity,
        child: ThirtyCard(
          padding: EdgeInsets.zero,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showArt =
                  !largeText && constraints.maxWidth >= _minWidthForArt;
              final text = Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.featuredCard,
                  vertical: AppSpacing.m,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('TODAY', semanticsLabel: 'Today', style: labelStyle),
                    const SizedBox(height: 2),
                    Text(intent, style: intentStyle),
                    const SizedBox(height: AppSpacing.s),
                    FadeTransition(
                      opacity: detailOpacity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              ExcludeSemantics(
                                child: Container(
                                  width: _chipSize,
                                  height: _chipSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.secondary,
                                  ),
                                  child: Icon(
                                    iconFor(category),
                                    size: 18,
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s),
                              Expanded(
                                child: Text(
                                  activity,
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Divider(height: 1, color: colors.divider),
                          const SizedBox(height: AppSpacing.s),
                          // At most two lines: the card stays compact
                          // enough for Start Circle to sit above the fold
                          // beneath the full-size Circle. At large text
                          // nothing is truncated; the page scrolls instead.
                          Text(
                            why,
                            maxLines: largeText ? null : 2,
                            overflow: largeText ? null : TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
              if (!showArt) return text;

              final width = constraints.maxWidth;
              // Full width: the text column alone would otherwise size the
              // Stack and pull the art over it.
              return SizedBox(
                width: width,
                child: Stack(
                  children: [
                    // The art viewport: from where the text column's
                    // content ends to the card's right edge. Art never
                    // paints left of it.
                    Positioned(
                      top: 0,
                      right: 0,
                      bottom: 0,
                      width:
                          width * (1 - _textShareWithArt) +
                          AppSpacing.featuredCard,
                      child: AnimatedSwitcher(
                        duration: artSwitchDuration,
                        // Fill the viewport; never re-centre the art.
                        layoutBuilder: (current, previous) => Stack(
                          fit: StackFit.expand,
                          children: [...previous, ?current],
                        ),
                        child: _TodayArt(
                          key: ValueKey(cardAsset),
                          asset: cardAsset,
                        ),
                      ),
                    ),
                    SizedBox(width: width * _textShareWithArt, child: text),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Today's World Card companion, filling the art viewport on the card's
/// right. Decorative only.
///
/// The art is drawn slightly larger than the card's height and anchored
/// right, so its authored watercolor edges at the top, right and bottom
/// fall outside the card and are clipped by it; the card reads as the
/// art's frame rather than holding a floating cut-out. Its left side
/// dissolves over a short fade within the viewport.
///
/// On the dark card the art sits on the shared paper backing of
/// WORLD_SYSTEM.md §10a: its own silhouette in low-opacity Cream, so the
/// feathered edges dissolve into paper rather than near-black, and the art
/// stays slightly dimmed so it never reads as a bright panel.
class _TodayArt extends StatelessWidget {
  const _TodayArt({required this.asset, super.key});

  final String asset;

  static const _light = (opacity: 1.0, paperOpacity: 0.0);
  static const _dark = (opacity: 0.85, paperOpacity: 0.12);

  /// Where the fade from the card's surface ends, as a share of the art
  /// viewport's width — the same in both themes.
  static const _fadeEnd = 0.45;

  /// How much larger than the card's height the art is drawn; the excess
  /// is split past the top, bottom and right edges.
  static const _overscan = 1.12;

  @override
  Widget build(BuildContext context) {
    final treatment = Theme.of(context).brightness == Brightness.dark
        ? _dark
        : _light;
    // The Card companion is authored separately from the Hero
    // (WORLD_SYSTEM.md §5B): scaled whole at its own aspect ratio, never
    // stretched.
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
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0x00000000), Color(0xFF000000)],
          stops: [0.0, _fadeEnd],
        ).createShader(bounds),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bleed = constraints.maxHeight * (_overscan - 1) / 2;
            // The paper silhouette and the art share one box, so the
            // backing always lies under the same pixels.
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
