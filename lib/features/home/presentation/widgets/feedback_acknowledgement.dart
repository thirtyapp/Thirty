import '../../application/circle_journal.dart';
import '../../application/recommendation_provider.dart';

/// What today's answer changes, said once and plainly (V2 Phase B — "the
/// effect of that feedback is acknowledged"); shown in the closed Circle's
/// reflection (`circle_reflection_card.dart`, V2 Phase C). Every line is
/// true of Recommendation Engine V2: a useful activity comes back now and
/// then; "Not useful" rests it for this need; "Not today" is no verdict on
/// it.
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
