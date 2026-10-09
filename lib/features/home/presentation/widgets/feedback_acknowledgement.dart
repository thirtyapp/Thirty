import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../application/circle_journal.dart';
import '../../application/recommendation_provider.dart';

/// What today's answer changes, said once and plainly (V2 Phase B —
/// "the effect of that feedback is acknowledged"). Every line is true of
/// Recommendation Engine V2: a useful activity comes back now and then; "Not
/// useful" rests it for this need; "Not today" is no verdict on it.
String? feedbackAcknowledgement(RecommendationState state) {
  if (state.status != RecommendationStatus.closed) return null;
  if (state.attemptResponse == CircleAttemptResponse.notToday) {
    return 'No problem — that won’t count against it.';
  }
  return switch (state.usefulnessResponse) {
    CircleUsefulnessResponse.veryUseful ||
    CircleUsefulnessResponse.somewhatUseful =>
      'Thanks — you’ll see this again now and then.',
    CircleUsefulnessResponse.notUseful =>
      'Thanks — THIRTY will rest this one for a while.',
    null => null,
  };
}

/// The acknowledgement beneath a closed, answered Circle.
class FeedbackAcknowledgement extends ConsumerWidget {
  const FeedbackAcknowledgement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final line = feedbackAcknowledgement(ref.watch(recommendationProvider));
    if (line == null) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.m,
      ),
      child: Semantics(
        liveRegion: true,
        child: Text(
          line,
          style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
