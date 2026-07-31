import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../../../core/widgets/thirty_card.dart';
import '../../application/recommendation_provider.dart';

/// Shows today's single recommendation and lets the user start it.
class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    required this.recommendation,
    required this.status,
    required this.onStart,
    super.key,
  });

  final Recommendation recommendation;
  final RecommendationStatus status;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final isStarted = status == RecommendationStatus.started;

    return ThirtyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(recommendation.intent, style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(recommendation.activity, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            recommendation.duration,
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.section),
          Text('Waarom deze aanbeveling?', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(recommendation.why, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.section),
          ThirtyButton(
            label: isStarted ? 'Gestart' : 'Start',
            onPressed: isStarted ? null : onStart,
          ),
        ],
      ),
    );
  }
}
