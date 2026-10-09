import '../application/activity_catalog.dart';

/// Every tunable value of Recommendation Engine V2 (ADR-020), in one place.
///
/// These are **tunable hypotheses** (PRODUCT_V2_CONTRACT — "TUNABLE
/// PARAMETERS"), chosen from the 40-day simulations
/// (`test/features/home/domain/recommendation_simulation_test.dart`). They
/// are not product rules: change them here, re-run the simulations, and
/// read the traces before and after.
class RecommendationPolicy {
  const RecommendationPolicy({
    required this.evidenceWindowDays,
    required this.evidenceHalfLifeDays,
    required this.usefulThreshold,
    required this.provenSpacingDays,
    required this.provenSpacingCircles,
    required this.usefulMaxSoftPenalties,
    required this.restDays,
    required this.recentDays,
    required this.weeklyCap,
    required this.familyWeeklySoftCap,
    required this.familyCarryOverDays,
    required this.declinedContextDays,
    required this.starterCircles,
    required this.explorationMinAnswers,
    required this.explorationInterval,
    required this.starterOrder,
  });

  /// The starting policy.
  static const initial = RecommendationPolicy(
    evidenceWindowDays: 90,
    evidenceHalfLifeDays: 45,
    usefulThreshold: 2,
    provenSpacingDays: 4,
    provenSpacingCircles: 2,
    usefulMaxSoftPenalties: 1,
    restDays: 14,
    recentDays: 2,
    weeklyCap: 2,
    familyWeeklySoftCap: 2,
    familyCarryOverDays: 7,
    declinedContextDays: 3,
    starterCircles: 3,
    explorationMinAnswers: 3,
    explorationInterval: 4,
    starterOrder: {
      Intention.moreEnergy: [
        ActivityId.thirtyMinuteWalk,
        ActivityId.moveToMusic,
        ActivityId.energisingStretchFlow,
        ActivityId.activeHouseholdTask,
      ],
      Intention.clearerHead: [
        ActivityId.writeItDown,
        ActivityId.phoneFreeWalk,
        ActivityId.quietReading,
        ActivityId.tidyOneSurface,
        ActivityId.quietAudioFocus,
        ActivityId.singleTaskFocus,
      ],
      Intention.gentlerPace: [
        ActivityId.easyWalk,
        ActivityId.quietMusicBreak,
        ActivityId.smallComfortRitual,
        ActivityId.gentleStretchPause,
        ActivityId.unhurriedTidyPause,
        ActivityId.quietSittingOutside,
      ],
    },
  );

  /// Answers older than this many days no longer count as evidence.
  final int evidenceWindowDays;

  /// Answers older than this count half.
  final int evidenceHalfLifeDays;

  /// The evidence strength ("Very useful" = 2, "Somewhat useful" = 1) from
  /// which an activity counts as useful for a need — and from which "You
  /// found this useful before." may be shown.
  final double usefulThreshold;

  /// A useful activity is brought back first only once it hasn't been
  /// offered for this many days — positive evidence without a favourite
  /// loop.
  final int provenSpacingDays;

  /// …and only once it was not among the last this-many Circles of that
  /// need, so a need chosen only weekly doesn't loop either.
  final int provenSpacingCircles;

  /// A useful activity that is ready again still leads through this many
  /// soft reasons against it (a busy family week, a little short for the
  /// time) — so a loved activity isn't crowded out by variety alone.
  final int usefulMaxSoftPenalties;

  /// After "Not useful", the activity rests for this need for this many
  /// days, then stays a little less likely for as long again.
  final int restDays;

  /// Offered within this many days: a little less likely.
  final int recentDays;

  /// At most this many offers of one activity in any 7 days.
  final int weeklyCap;

  /// Once a family has been offered this many times in 7 days, its
  /// activities are a little less likely.
  final int familyWeeklySoftCap;

  /// After "Not useful", the rest of that activity's family is a little less
  /// likely for this need for this many days.
  final int familyCarryOverDays;

  /// An activity declined with "Not this one today" is treated as recently
  /// offered for this many days — soft context, never "Not useful".
  final int declinedContextDays;

  /// Until a need has been chosen this many times, its curated
  /// [starterOrder] leads instead of the date-seeded order.
  final int starterCircles;

  /// Exploration starts only once a need has this many usefulness answers.
  final int explorationMinAnswers;

  /// …and then at most once every this many Circles of that need, never on
  /// a short day.
  final int explorationInterval;

  /// The curated start for each need (PRODUCT_V2_CONTRACT — "A curated
  /// starter order serves new users"). Activities not listed come after.
  final Map<Intention, List<ActivityId>> starterOrder;
}
