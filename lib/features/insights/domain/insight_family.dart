/// THIRTY's minimum Circle Insights families — Batch 2C
/// (`docs/product/adr/ADR-016-v1-batch-2c-circle-insights.md`,
/// `RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md` §9).
///
/// Exactly the frozen architecture's three bounded template families. No
/// fourth family, no open-ended insight generator.
library;

/// One of THIRTY's three bounded Insight families.
enum InsightFamily {
  /// Which broad direction the person actually chose on recorded visits,
  /// and where its Plan was left. Available without any reflections — it
  /// uses recorded direction choices and Plan state only.
  directionPathContinuity,

  /// How often the user explicitly chose lighter guidance for the active
  /// Plan — never an automatic application of an already-saved default.
  chosenPacing,

  /// Which stage of the active Plan was deliberately revisited, and how
  /// often — never an accidental/recovery duplication.
  deliberateRevisits,
}
