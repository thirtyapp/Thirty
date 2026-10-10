/// Every tunable Premium value in one place (V2 Phase D, ADR-022). These
/// are hypotheses (PRODUCT_V2_CONTRACT — TUNABLE): change them here and
/// re-read the eight-week simulation traces
/// (`test/features/toolkit/premium_simulation_test.dart`,
/// `--dart-define=TRACE=true`).
library;

class ToolkitPolicy {
  const ToolkitPolicy({
    this.buildCircles = 7,
    this.tuneCircles = 3,
    this.fadingMinRatedUses = 3,
    this.fadingRecentAnswers = 3,
    this.fadingMaxRecentScore = 0,
    this.fadingMaxLastTwoScore = -1,
    this.fadingRestedMinPositives = 2,
    this.timeMisfitWindowDays = 28,
    this.timeMisfitRecentDays = 6,
    this.timeMisfitMinMisfits = 4,
    this.gapWindowDays = 28,
    this.gapMinDays = 5,
    this.gapMaxRoutines = 6,
    this.gapMinAnswers = 3,
    this.gapSomewhatWeight = 0.7,
    this.gapServedWellScore = 0.5,
    this.declineCooldownDays = 21,
    this.checkCadenceDays = 28,
    this.stableMinRatedUses = 3,
  });

  static const initial = ToolkitPolicy();

  /// Path Circles in a build (starting hypothesis 7).
  final int buildCircles;

  /// Path Circles in a tune-up or a shorter version (starting hypothesis 3).
  final int tuneCircles;

  /// **Fading.** Rated uses since the routine last changed before any
  /// claim — fewer, and THIRTY is still learning.
  final int fadingMinRatedUses;

  /// The most recent answers weighed ("lately").
  final int fadingRecentAnswers;

  /// The recent answers' score (Very +2, Somewhat +1, Not useful −2) at or
  /// below which a previously positive routine counts as fading. Three
  /// "Somewhat useful" (3) is steady, not fading; "Somewhat, Not useful,
  /// Somewhat" (0) is.
  final int fadingMaxRecentScore;

  /// Or the last two answers scoring at or below this — a "Not useful"
  /// with nothing better beside it ("Somewhat, Not useful": −1). A "Not
  /// useful" rests a routine for two weeks, so three low answers can take a
  /// month to gather; two that include a "Not useful" are already a clear
  /// change (policy tuning, ADR-022: SIM 4 found no offer in eight weeks).
  final int fadingMaxLastTwoScore;

  /// Or, for a routine that clearly used to suit — at least this many
  /// positive answers — a "Not useful" in use: the engine now rests it for
  /// two weeks, after which other picks may keep it away for good. Better to
  /// offer the tune-up than to let it quietly disappear (policy tuning,
  /// ADR-022: SIM 4).
  final int fadingRestedMinPositives;

  /// **Time misfit.** Days looked back over.
  final int timeMisfitWindowDays;

  /// The most recent days of the routine's need weighed ("most days").
  final int timeMisfitRecentDays;

  /// Of those, the days with less time than the routine takes before
  /// THIRTY offers a shorter version.
  final int timeMisfitMinMisfits;

  /// **Gap.** Days looked back over.
  final int gapWindowDays;

  /// Days a need was chosen with no routine that fits it in the usual
  /// time, before a build is offered.
  final int gapMinDays;

  /// A small Toolkit stays small: no gap build is offered at this many
  /// routines.
  final int gapMaxRoutines;

  /// A gap needs the user's own word that Free isn't serving the need: at
  /// least this many explicit answers to its ordinary picks for that need
  /// in the window. Unanswered Circles are never read as a gap.
  final int gapMinAnswers;

  /// How much a "Somewhat useful" counts towards Free serving a need well
  /// ("Very useful" 1, "Not useful" 0). It is positive evidence too.
  final double gapSomewhatWeight;

  /// No gap is offered for a need Free already serves well: the mean of
  /// those answers at or above this (five "Somewhat useful" are 0.7 —
  /// served). Offering a build there would be work invented for Premium's
  /// sake (founder correction, ADR-022: Somewhat useful counts).
  final double gapServedWellScore;

  /// Days a declined offer stays away.
  final int declineCooldownDays;

  /// **Toolkit check** cadence (about every four weeks).
  final int checkCadenceDays;

  /// Rated uses in the check period before THIRTY says "nothing to change".
  final int stableMinRatedUses;
}
