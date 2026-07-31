import 'package:flutter_riverpod/flutter_riverpod.dart';

/// THIRTY's daily recommendation. Hardcoded for now — no ranking, no
/// personalization; see docs/product/decision-framework.md for how this
/// will eventually be chosen.
class Recommendation {
  const Recommendation({
    required this.intent,
    required this.activity,
    required this.duration,
    required this.why,
  });

  final String intent;
  final String activity;
  final String duration;
  final String why;
}

/// Whether the user has started today's recommendation. Purely local and
/// in-memory — nothing is timed, tracked or persisted.
enum RecommendationStatus { notStarted, started }

class RecommendationState {
  const RecommendationState({
    required this.recommendation,
    required this.status,
  });

  final Recommendation recommendation;
  final RecommendationStatus status;

  RecommendationState copyWith({RecommendationStatus? status}) {
    return RecommendationState(
      recommendation: recommendation,
      status: status ?? this.status,
    );
  }
}

const _todaysRecommendation = Recommendation(
  intent: 'Meer energie',
  activity: '30 minuten wandelen',
  duration: '30 minuten',
  why:
      'Een rustige wandeling is vandaag een eenvoudige manier om energie '
      'op te bouwen.',
);

class RecommendationNotifier extends Notifier<RecommendationState> {
  @override
  RecommendationState build() {
    return const RecommendationState(
      recommendation: _todaysRecommendation,
      status: RecommendationStatus.notStarted,
    );
  }

  void start() => state = state.copyWith(status: RecommendationStatus.started);
}

final recommendationProvider =
    NotifierProvider<RecommendationNotifier, RecommendationState>(
      RecommendationNotifier.new,
    );
