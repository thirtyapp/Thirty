import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_card.dart';
import '../../application/activity_catalog.dart';
import '../../application/recommendation_provider.dart';

/// THIRTY's Daily Context Question — Recommendation MVP v0
/// (`docs/product/recommendation-mvp-v0.md`): "What would help most
/// today?", shown instead of the Circle Hero whenever today's recommendation
/// doesn't exist yet (`home_page.dart` decides between the two on
/// `recommendationProvider`'s [RecommendationState.recommendation]).
///
/// Exactly the three [Intention] values, in the same fixed order every day —
/// no inference, no additional questions. Tapping one calls
/// [RecommendationNotifier.chooseIntention], which fixes today's
/// recommendation; this widget has nothing left to do afterward; `HomePage`
/// swaps it out for `CircleHero` (circle_hero.dart) on the next build.
class DailyIntentionPrompt extends ConsumerWidget {
  const DailyIntentionPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What would help most today?',
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.section),
          for (final intention in Intention.values) ...[
            _IntentionOption(intention: intention, colors: colors),
            if (intention != Intention.values.last)
              const SizedBox(height: AppSpacing.m),
          ],
        ],
      ),
    );
  }
}

class _IntentionOption extends ConsumerWidget {
  const _IntentionOption({required this.intention, required this.colors});

  final Intention intention;
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final label = intentionLabel(intention);
    final meaning = intentionMeaning(intention);

    return Semantics(
      button: true,
      label: '$label. $meaning',
      child: ExcludeSemantics(
        child: ThirtyCard(
          onTap: () =>
              ref.read(recommendationProvider.notifier).chooseIntention(
                intention,
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                meaning,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
