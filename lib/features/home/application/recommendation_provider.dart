import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/activity_category.dart';

/// THIRTY's daily recommendation. Hardcoded for now — no ranking, no
/// personalization; see docs/product/decision-framework.md for how this
/// will eventually be chosen.
class Recommendation {
  const Recommendation({
    required this.intent,
    required this.activity,
    required this.duration,
    required this.why,
    required this.category,
  });

  final String intent;
  final String activity;
  final String duration;
  final String why;

  /// Drives which visual identity (see `presentation/illustrations/`)
  /// represents this recommendation — nothing about ranking or selection,
  /// purely a label for that lookup. Shared with the World Engine
  /// (`core/worlds/`) as the single source of truth for this
  /// classification — see [ActivityCategory].
  final ActivityCategory category;
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
  intent: 'More Energy',
  activity: '30 minute walk',
  duration: '30 minutes',
  why: 'A calm walk to help you build energy for the rest of the day.',
  category: ActivityCategory.walking,
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
