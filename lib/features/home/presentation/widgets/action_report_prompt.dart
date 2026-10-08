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
/// Whether [ActionReportPrompt] currently has an unanswered question to
/// show — exposed as its own provider (Step 5 authority reconciliation)
/// so other optional-prompt surfaces can honor the parent V1
/// prompt-priority rule (`THIRTY V1 PRODUCTIZATION + COMMERCIAL
/// REVIEW.md` §28: reflection takes priority over an eligible
/// reminder/Premium invitation — see
/// `../../../premium/application/premium_offer_provider.dart`).
/// [ActionReportPrompt] itself is written against the same underlying
/// [_isReflectionPending] check, so the two can never drift apart.
final reflectionPendingProvider = Provider<bool>((ref) {
  return _isReflectionPending(ref.watch(recommendationProvider));
});

bool _isReflectionPending(RecommendationState state) {
  if (state.status != RecommendationStatus.closed) return false;
  final attempt = state.attemptResponse;
  if (attempt == null) return true;
  final isAffirmative =
      attempt == CircleAttemptResponse.yes ||
      attempt == CircleAttemptResponse.aLittle;
  return isAffirmative && state.usefulnessResponse == null;
}

class ActionReportPrompt extends ConsumerWidget {
  const ActionReportPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recommendationProvider);
    if (!_isReflectionPending(state)) {
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
              onPressed: () =>
                  notifier.reportAttempt(CircleAttemptResponse.yes),
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
              onPressed: () =>
                  notifier.reportUsefulness(CircleUsefulnessResponse.notUseful),
            ),
          ],
        ),
      ),
    );
  }
}
