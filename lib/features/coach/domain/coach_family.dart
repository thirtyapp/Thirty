/// THIRTY's minimum Circle Coach — Batch 2B
/// (`docs/product/adr/ADR-015-v1-batch-2b-circle-coach.md`,
/// `RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md` §7).
///
/// Exactly the frozen architecture's **six bounded situation families** —
/// no chatbot, no free-text intake, no inferred health state, and no
/// second recommendation engine. A family only ever changes *how* the
/// current or a future Plan Session is approached, never *which*
/// [ActivityId] is assigned.
library;

enum CoachFamily {
  /// Explains why today's assigned activity belongs at this point in the
  /// Plan — the ordinary fallback when no stronger contextual cue applies.
  stageExplanation,

  /// The current Session's treatment is [PlanTreatment.lighter] — either a
  /// direct choice for today, or the automatic application of a saved
  /// Plan-level default (`../application/coach_engine.dart` distinguishes
  /// the two truthfully in its message).
  lighterPacing,

  /// Responds to a truthful, explicit action/usefulness report on the
  /// immediately preceding matching Plan Circle — never an inference about
  /// motivation, exhaustion, or recovery need.
  actionFeedback,

  /// The user is returning to this Plan after a qualifying (7+ local
  /// calendar day) gap — a display rule only, never a claim about fitness,
  /// health, or being "behind."
  resumption,

  /// Explains that today's Session is a deliberately queued one-off
  /// revisit of a previously encountered stage — never an accidental
  /// repeat, and forward progress is preserved.
  deliberateRevisit,

  /// The current cycle has finished; explains the plain repeat/choose-
  /// another-direction/continue-Free options with no automatic restart or
  /// outcome claim.
  cycleTransition,
}
