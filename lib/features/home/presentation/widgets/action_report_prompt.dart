import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../application/circle_journal.dart';
import '../../application/recommendation_provider.dart';

/// THIRTY's optional post-Close action-report foundation (ADR-013 §4):
/// "Did you try this activity?", and — only after an affirmative answer —
/// an optional "Was it useful?" follow-up.
///
/// Renders nothing at all unless today's Circle is currently
/// [RecommendationStatus.closed] — this question exists only in the closed
/// state, is never shown before Close, and is never required to Close or
/// to receive tomorrow's Circle. Once every question this widget can show
/// has either been answered or has no further question to ask, it renders
/// nothing again — there is no repeat prompting, no reminder, and no
/// visual pressure to answer.
class ActionReportPrompt extends ConsumerWidget {
  const ActionReportPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recommendationProvider);
    if (state.status != RecommendationStatus.closed) {
      return const SizedBox.shrink();
    }

    final attempt = state.attemptResponse;
    final isAffirmative =
        attempt == CircleAttemptResponse.yes ||
        attempt == CircleAttemptResponse.aLittle;

    if (attempt == null) {
      return _AttemptQuestion();
    }
    if (isAffirmative && state.usefulnessResponse == null) {
      return _UsefulnessQuestion();
    }
    return const SizedBox.shrink();
  }
}

class _AttemptQuestion extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final notifier = ref.read(recommendationProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.page,
      ),
      child: Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Did you try this activity?',
              style: textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s),
            ThirtyButton(
              label: 'Yes',
              variant: ThirtyButtonVariant.secondary,
              onPressed: () => notifier.reportAttempt(CircleAttemptResponse.yes),
            ),
            const SizedBox(height: AppSpacing.xs),
            ThirtyButton(
              label: 'A little',
              variant: ThirtyButtonVariant.secondary,
              onPressed: () =>
                  notifier.reportAttempt(CircleAttemptResponse.aLittle),
            ),
            const SizedBox(height: AppSpacing.xs),
            ThirtyButton(
              label: 'Not today',
              variant: ThirtyButtonVariant.secondary,
              onPressed: () =>
                  notifier.reportAttempt(CircleAttemptResponse.notToday),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsefulnessQuestion extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final notifier = ref.read(recommendationProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.page,
      ),
      child: Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Was it useful?',
              style: textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s),
            ThirtyButton(
              label: 'Very useful',
              variant: ThirtyButtonVariant.secondary,
              onPressed: () => notifier.reportUsefulness(
                CircleUsefulnessResponse.veryUseful,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ThirtyButton(
              label: 'Somewhat useful',
              variant: ThirtyButtonVariant.secondary,
              onPressed: () => notifier.reportUsefulness(
                CircleUsefulnessResponse.somewhatUseful,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ThirtyButton(
              label: 'Not useful',
              variant: ThirtyButtonVariant.secondary,
              onPressed: () => notifier.reportUsefulness(
                CircleUsefulnessResponse.notUseful,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
