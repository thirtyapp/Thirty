import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../../../core/widgets/thirty_card.dart';
import '../../../../core/widgets/thirty_text_action.dart';
import '../../../personal_circle/presentation/widgets/yours_parts.dart';
import '../../domain/insight.dart';
import '../../domain/insight_copy.dart';

/// One Insight as THIRTY showed it (ADR-024 §11, B6): what the Circles
/// show, the Circles it rests on, and one bounded action — or a calm
/// "Nothing to change". Its words are the snapshot's own, never rewritten.
class InsightCard extends StatelessWidget {
  const InsightCard({
    required this.snapshot,
    this.actionLabel,
    this.onAction,
    this.onNotNow,
    this.outcome,
    this.onSeePlan,
    this.secondary = false,
    super.key,
  });

  final InsightSnapshot snapshot;

  /// The application's label, or `null`: nothing to apply.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// "Not now" — ordinary Insights only.
  final VoidCallback? onNotNow;

  /// What the action just did — shown in place of the action.
  final String? outcome;
  final VoidCallback? onSeePlan;

  /// Quieter, beside a current Insight.
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final dates = [...snapshot.evidence]..sort();
    final nothingToChange = switch (snapshot.application) {
      NothingToChange(:final text) => text,
      _ => null,
    };
    return ThirtyCard(
      padding: const EdgeInsets.all(AppSpacing.featuredCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // One stop: what it is, what it says, and what it rests on.
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                YoursEyebrow(InsightCopy.familyName(snapshot.family)),
                const SizedBox(height: AppSpacing.s),
                Text(
                  InsightCopy.keepDatesTogether(snapshot.text),
                  style: secondary
                      ? textTheme.bodyLarge
                      : AppTypography.editorialDisplay(
                          colors,
                        ).copyWith(fontSize: 22, height: 1.3),
                ),
                if (dates.isNotEmpty &&
                    snapshot.family != InsightFamily.planReview) ...[
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    InsightCopy.keepDatesTogether(
                      InsightCopy.basedOn(
                        dates.length,
                        dates.first,
                        dates.last,
                      ),
                    ),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (outcome case final said?) ...[
            const SizedBox(height: AppSpacing.m),
            YoursNote(said, liveRegion: true),
            if (onSeePlan != null)
              ThirtyTextAction(
                label: InsightCopy.seeThePlan,
                onPressed: onSeePlan,
              ),
          ] else ...[
            if (nothingToChange case final line?) ...[
              const SizedBox(height: AppSpacing.m),
              Text(line, style: textTheme.bodyMedium),
            ],
            if (actionLabel case final label?) ...[
              const SizedBox(height: AppSpacing.m),
              ThirtyButton(
                label: label,
                variant: secondary
                    ? ThirtyButtonVariant.secondary
                    : ThirtyButtonVariant.primary,
                onPressed: onAction,
              ),
            ],
            if (onNotNow != null)
              ThirtyTextAction(label: InsightCopy.notNow, onPressed: onNotNow),
          ],
        ],
      ),
    );
  }
}
