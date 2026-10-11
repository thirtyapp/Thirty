/// Every tunable value of the Personal Guided Circle composer in one place
/// (V2 Phase D2, ADR-023 §3). These are hypotheses (PRODUCT_V2_CONTRACT —
/// TUNABLE): change them here and re-read the long-horizon simulation
/// traces (`test/features/personal_circle/personal_circle_simulation_test.dart`,
/// `--dart-define=TRACE=true`).
library;

class ComposerPolicy {
  const ComposerPolicy({
    this.maxParts = 4,
    this.maxPartsShortDay = 3,
    this.minUtilization = 0.6,
    this.targetUtilization = 0.8,
    this.minMainShare = 0.4,
    this.evidenceWeight = 3,
    this.mainEvidenceFactor = 1.5,
    this.composedEvidenceFactor = 0.5,
    this.targetUseBonus = 3,
    this.partialUseBonus = 1.5,
    this.fillWeight = 1,
    this.settleBonus = 1,
    this.arriveBonus = 0.5,
    this.secondBonus = 0.5,
    this.shortFormCost = 0.3,
    this.recentPartDays = 2,
    this.recentPartCost = 1,
    this.recentMainCost = 2,
    this.mainWeeklySoftCap = 2,
    this.mainWeeklyCost = 2,
    this.samePlanDays = 14,
    this.samePlanCost = 4,
    this.sameEdgeCost = 0.5,
    this.declinedCost = 1,
  });

  static const initial = ComposerPolicy();

  /// The most parts one Circle holds: arrive, main, second, settle.
  final int maxParts;

  /// The most parts on a ≈ 10-minute day: fewer, so it never feels
  /// hurried.
  final int maxPartsShortDay;

  /// The least of the time window a composition must use to pass the
  /// quality gate — below it, the honest answer is Free's one activity.
  final double minUtilization;

  /// Use of the window the composer aims for when a coherent session
  /// exists. Never more important than content quality: an honest 17 of 20
  /// minutes beats a padded 20.
  final double targetUtilization;

  /// The least share of a Circle's minutes its main piece holds — what
  /// keeps arrive and settle from becoming filler.
  final double minMainShare;

  /// How much one point of explicit evidence counts.
  final double evidenceWeight;

  /// The main piece's evidence counts this much more.
  final double mainEvidenceFactor;

  /// An answer about a whole composed Circle counts this much, per part,
  /// against an answer about the element's own activity.
  final double composedEvidenceFactor;

  final double targetUseBonus;
  final double partialUseBonus;

  /// Per whole window used: among sessions otherwise alike, the one using
  /// more of the user's time — never enough to outweigh evidence.
  final double fillWeight;
  final double settleBonus;
  final double arriveBonus;

  /// A second piece earns this on a 20- or 30-minute day only.
  final double secondBonus;

  /// Each part at its shorter length: a full piece is preferred.
  final double shortFormCost;

  /// A part composed within this many days counts against itself.
  final int recentPartDays;
  final double recentPartCost;
  final double recentMainCost;

  /// A main piece offered more than this in 7 days counts against itself.
  final int mainWeeklySoftCap;
  final double mainWeeklyCost;

  /// The same set of elements within this many days counts against itself.
  final int samePlanDays;
  final double samePlanCost;

  /// The same first or last part as the last composed Circle.
  final double sameEdgeCost;

  /// A part whose activity the user declined with "Not this one today"
  /// in the last few days.
  final double declinedCost;
}
