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

/// The Today card (Phase D1, Design vision): today's direction in the
/// editorial serif, the activity with its icon, a divider, and why it was
/// chosen — left-aligned in a card, with a quiet slice of today's World
/// fading in at its right edge.
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
    required this.intentOpacity,
    required this.detailOpacity,
    super.key,
  });

  final String intent;
  final String activity;
  final String why;
  final ActivityCategory category;
  final Animation<double> intentOpacity;
  final Animation<double> detailOpacity;

  static const _largeTextScale = 1.3;
  static const _minWidthForArt = 300.0;

  /// Share of the card's width the text column keeps beside the art.
  static const _textShareWithArt = 0.6;

  static const _chipSize = 40.0;

  static IconData iconFor(ActivityCategory category) => switch (category) {
    ActivityCategory.walking => Icons.directions_walk_rounded,
    ActivityCategory.generalWellness => Icons.spa_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final largeText =
        MediaQuery.textScalerOf(context).scale(1) >= _largeTextScale;

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
                padding: const EdgeInsets.all(AppSpacing.featuredCard),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TODAY',
                      semanticsLabel: 'Today',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(intent, style: AppTypography.editorialDisplay(colors)),
                    const SizedBox(height: AppSpacing.m),
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
                                    size: 22,
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.m - 4),
                              Expanded(
                                child: Text(
                                  activity,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.m),
                          Divider(height: 1, color: colors.divider),
                          const SizedBox(height: AppSpacing.m - 4),
                          Text(
                            why,
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
                    Positioned(
                      top: 0,
                      right: 0,
                      bottom: 0,
                      width: width * (1 - _textShareWithArt) + AppSpacing.xl,
                      child: const _TodayArt(),
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

/// A slice of the Quiet Trail World (the tree on its hill), fading in from
/// the card's surface on its left. Decorative only. The painting is on
/// light paper, so on the dark card it fades in over a longer distance and
/// stays dimmed, never reading as a bright panel.
class _TodayArt extends StatelessWidget {
  const _TodayArt();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: Opacity(
        opacity: dark ? 0.45 : 1,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: const [Color(0x00000000), Color(0xFF000000)],
            stops: dark ? const [0.0, 0.9] : const [0.0, 0.45],
          ).createShader(bounds),
          child: Image.asset(
            'assets/worlds/quiet_trail/quiet_trail_hero_master_v1.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0.55, 0.35),
          ),
        ),
      ),
    );
  }
}
