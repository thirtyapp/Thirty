import 'package:flutter/material.dart';

import '../../../../core/activity_category.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/daypart_greeting.dart';
import '../../../../core/widgets/thirty_card.dart';
import 'home_rhythm_column.dart';

/// The greeting that opens every Circle (Phase D1): THIRTY's daypart
/// greeting, with the user's first name when they have given one —
/// "Good morning, Thomas." or "Good morning." ([daypartGreeting]).
String homeGreeting(DateTime now, {String? firstName}) =>
    daypartGreeting(now, firstName: firstName);

/// The line under the greeting while today's Circle is still open: an
/// invitation to begin before Start Circle, then a calm note that closing
/// is the user's call once it is running.
String homeGreetingSubline({required bool started}) =>
    started ? 'Close it whenever you’re ready.' : 'Here’s one thing for today.';

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
    required this.minutes,
    required this.firstAction,
    required this.showFirstAction,
    required this.onShowGuide,
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

  /// The activity's natural length, shown beside its name.
  final int minutes;

  /// What to do first; replaces [why] once the Circle has started.
  final String firstAction;
  final bool showFirstAction;

  /// Opens the full how-to; `null` hides the link.
  final VoidCallback? onShowGuide;
  final String cardAsset;
  final Duration artSwitchDuration;
  final Animation<double> intentOpacity;
  final Animation<double> detailOpacity;

  static const _largeTextScale = 1.3;
  static const _minWidthForArt = 300.0;

  /// Share of the card's width the text column keeps beside the art.
  static const _textShareWithArt = 0.75;

  static const _intentFontSize = 22.0;

  /// How much shorter Home's near-fit rhythm may lay the card out: its top
  /// and bottom padding tighten from [AppSpacing.m] to [AppSpacing.s]
  /// (home_rhythm_column.dart). Otherwise the card never changes.
  static const nearFitReduction = 2 * (AppSpacing.m - AppSpacing.s);

  /// Running Circle only, once the compact rhythm is not enough: the top
  /// and bottom padding may tighten further, to [_leastPadding]…
  static const runningPaddingReduction = 2 * (AppSpacing.s - _leastPadding);

  /// The card's tightest top and bottom padding: below this the label and
  /// the last line crowd the card's edges (S25 founder review).
  static const _leastPadding = 6.0;

  /// …and then the space between the divider and the first action, from
  /// [AppSpacing.s] to [AppSpacing.xs].
  static const runningInnerReduction = AppSpacing.s - AppSpacing.xs;

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
                ),
                // The card's padding, and the space between the divider and
                // the line beneath it, are all that give up room in Home's
                // near-fit rhythm ([nearFitReduction], then
                // [runningPaddingReduction] and [runningInnerReduction]);
                // the content never does.
                child: HomeSqueezePair(
                  spacing: (
                    top: AppSpacing.m,
                    middle: AppSpacing.s,
                    bottom: AppSpacing.m,
                  ),
                  steps: const [
                    (
                      top: AppSpacing.s,
                      middle: AppSpacing.s,
                      bottom: AppSpacing.s,
                    ),
                    (
                      top: _leastPadding,
                      middle: AppSpacing.s,
                      bottom: _leastPadding,
                    ),
                    (
                      top: _leastPadding,
                      middle: AppSpacing.xs,
                      bottom: _leastPadding,
                    ),
                  ],
                  crossAxisAlignment: CrossAxisAlignment.start,
                  first: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // The activity's natural length rides on the label line, which
                      // has room to spare, so the activity name keeps its width.
                      Text(
                        'TODAY  ·  $minutes MIN',
                        semanticsLabel: 'Today, about $minutes minutes',
                        style: labelStyle,
                      ),
                      const SizedBox(height: 2),
                      Text(intent, style: intentStyle),
                      FadeTransition(
                        opacity: detailOpacity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // The activity row is also the way into its full
                            // how-to (V2 Phase A): its tap padding takes the
                            // place of the gaps above and below it, so the
                            // card is no taller than before and Start Circle
                            // keeps its place beneath the full-size Circle.
                            _ActivityRow(
                              activity: activity,
                              icon: iconFor(category),
                              onTap: onShowGuide,
                            ),
                            Divider(height: 1, color: colors.divider),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Before Start: why this might fit. Once running: the one
                  // thing to do first, which is what matters now. Never cut
                  // off (S25 device finding): at normal text the copy itself
                  // is kept to two lines for the reason and three for the
                  // first action (today_card_test.dart), so the card stays
                  // compact enough for the Circle's action to sit beneath
                  // the full-size Circle; enlarged text grows the card and
                  // the page scrolls instead.
                  second: FadeTransition(
                    opacity: detailOpacity,
                    child: showFirstAction
                        ? Text(
                            firstAction,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Text(
                            why,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                  ),
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

/// Today's activity — its icon, name and natural length — with a chevron
/// that opens the full how-to. The row's own vertical padding is its touch
/// target, so it adds no height to the card.
class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.activity,
    required this.icon,
    required this.onTap,
  });

  final String activity;
  final IconData icon;
  final VoidCallback? onTap;

  static const _chipSize = 28.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: _chipSize,
              height: _chipSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.secondary,
              ),
              child: Icon(icon, size: 18, color: colors.primary),
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
          if (onTap != null)
            ExcludeSemantics(
              child: Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: colors.primary,
              ),
            ),
        ],
      ),
    );
    final label = activity;
    if (onTap == null) {
      return Semantics(label: label, excludeSemantics: true, child: row);
    }
    return Semantics(
      button: true,
      label: label,
      hint: 'How to do it',
      // The merged node carries the tap itself: excluding the children's
      // semantics would otherwise drop the InkWell's tap action.
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(onTap: onTap, borderRadius: AppRadius.small, child: row),
    );
  }
}
