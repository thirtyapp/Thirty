import 'coach_family.dart';

/// One resolved Coach cue — Batch 2B (ADR-015). At most one of these is
/// ever shown at a time (`../application/coach_engine.dart`'s bounded
/// priority order).
///
/// [message] is always a bounded, non-clinical, general-wellness sentence
/// grounded in explicit state — never free text, never generated, never a
/// health/outcome claim.
class CoachCue {
  const CoachCue({
    required this.family,
    required this.message,
    this.offersLighterAction = false,
    this.offersRevisitAction = false,
  });

  final CoachFamily family;
  final String message;

  /// Whether this cue's presentation may offer a shortcut to the existing
  /// "use lighter guidance for today" control
  /// (`../../home/application/recommendation_provider.dart`'s
  /// `RecommendationNotifier.setPlanTreatment`) — never a new mechanism,
  /// only contextual exposure of one that already exists. The presentation
  /// layer still applies its own guards (e.g. already lighter today) before
  /// actually rendering a button.
  final bool offersLighterAction;

  /// Whether this cue's presentation may offer a shortcut to the existing
  /// one-off revisit control
  /// (`../../plans/application/plan_provider.dart`'s
  /// `PlanNotifier.queueRevisit`) — same "expose, never invent" rule as
  /// [offersLighterAction].
  final bool offersRevisitAction;
}
