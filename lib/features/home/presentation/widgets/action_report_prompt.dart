import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/circle_journal.dart';
import '../../application/recommendation_provider.dart';

/// Whether today's closed Circle still has an unanswered reflection
/// question (ADR-013 §4) — "Did you try it?", or "Was it useful?" after
/// "Yes" / "A little". Since V2 Phase C the questions themselves live in the
/// Circle (`circle_reflection_card.dart`); this provider remains the one
/// definition of "pending" so other optional-prompt surfaces honour the
/// parent V1 prompt-priority rule (`THIRTY V1 PRODUCTIZATION + COMMERCIAL
/// REVIEW.md` §28: reflection takes priority over an eligible
/// reminder/Premium invitation — see
/// `../../../premium/application/premium_offer_provider.dart`).
final reflectionPendingProvider = Provider<bool>((ref) {
  return isReflectionPending(ref.watch(recommendationProvider));
});

/// See [reflectionPendingProvider].
bool isReflectionPending(RecommendationState state) {
  if (state.status != RecommendationStatus.closed) return false;
  final attempt = state.attemptResponse;
  if (attempt == null) return true;
  final isAffirmative =
      attempt == CircleAttemptResponse.yes ||
      attempt == CircleAttemptResponse.aLittle;
  return isAffirmative && state.usefulnessResponse == null;
}
