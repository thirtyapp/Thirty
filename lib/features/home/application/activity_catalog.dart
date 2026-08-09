import '../../../core/activity_category.dart';

/// The desired direction the user picks via the Daily Context Question
/// ("What would help most today?") — Recommendation MVP v0
/// (`docs/product/recommendation-mvp-v0.md`). Explicitly selected by the
/// user, never inferred from behavior, mood, or any other signal — see
/// [ADR-009](../../../../docs/product/adr/ADR-009-daily-intention-question.md).
///
/// This is [Decision Framework §4](../../../../docs/product/decision-framework.md#4-intentie-versus-activiteit)'s
/// "Intentie": the first, primary decision. [ActivityId] is the later,
/// narrower "Activiteit" chosen within it.
enum Intention { moreEnergy, clearerHead, gentlerPace }

/// The label shown for [intention] itself (used as
/// `Recommendation.intent` — see `recommendation_provider.dart`).
String intentionLabel(Intention intention) => switch (intention) {
  Intention.moreEnergy => 'More Energy',
  Intention.clearerHead => 'Clearer Head',
  Intention.gentlerPace => 'Gentler Pace',
};

/// The one-line meaning shown for [intention] on the Daily Context Question
/// (`daily_intention_prompt.dart`) — the exact, approved wording from
/// `docs/product/recommendation-mvp-v0.md`. A desired direction the user
/// explicitly recognizes and picks, never a health-state description.
String intentionMeaning(Intention intention) => switch (intention) {
  Intention.moreEnergy =>
    'I want to spend this half-hour being somewhat more active and '
        'engaged.',
  Intention.clearerHead =>
    'I want this half-hour to contain less competing input and more '
        'single-focus attention.',
  Intention.gentlerPace =>
    'I want to use this half-hour without turning it into another '
        'performance or productivity demand.',
};

/// A canonical activity identity, stable across intentions — the "same
/// underlying activity" identity anti-repetition compares against, distinct
/// from how that activity is presented/explained for a given [Intention].
///
/// Every value belongs to exactly one [activityPools] entry in this
/// version, even where two activities are conceptually similar (e.g.
/// [thirtyMinuteWalk], [phoneFreeWalk] and [easyWalk] are three distinct
/// walks, not variants of one canonical activity). The same [ActivityId]
/// appearing in more than one pool remains a supported way to model one
/// activity offered under multiple intentions — see
/// `docs/product/recommendation-mvp-v0.md` — it simply has no current
/// example: v0 deliberately keeps every retained activity concrete enough
/// that the user immediately knows the chosen action, which ruled out the
/// one previous candidate for this (Gentle mobility).
enum ActivityId {
  thirtyMinuteWalk,
  moveToMusic,
  phoneFreeWalk,
  writeItDown,
  quietReading,
  easyWalk,
  quietMusicBreak,
}

/// The approved activities for each [Intention], in a fixed order —
/// [selectActivityId] indexes into this order deterministically. Pool
/// sizes are intentionally unequal; every pool still has at least two
/// entries, which is what guarantees anti-repetition always has an
/// alternative to fall back to.
const Map<Intention, List<ActivityId>> activityPools = {
  Intention.moreEnergy: [ActivityId.thirtyMinuteWalk, ActivityId.moveToMusic],
  Intention.clearerHead: [
    ActivityId.phoneFreeWalk,
    ActivityId.writeItDown,
    ActivityId.quietReading,
  ],
  Intention.gentlerPace: [ActivityId.easyWalk, ActivityId.quietMusicBreak],
};

/// [activityId]'s display name — intention-independent, unlike
/// [whyCopyFor].
String activityLabel(ActivityId activityId) => switch (activityId) {
  ActivityId.thirtyMinuteWalk => '30-minute walk',
  ActivityId.moveToMusic => 'Move to music',
  ActivityId.phoneFreeWalk => 'Phone-free walk',
  ActivityId.writeItDown => 'Write it down',
  ActivityId.quietReading => 'Quiet reading',
  ActivityId.easyWalk => 'Easy walk',
  ActivityId.quietMusicBreak => 'Quiet music break',
};

/// [activityId]'s [ActivityCategory], for illustration purposes only.
///
/// Only genuinely walking-based activities resolve to
/// [ActivityCategory.walking] — every other v0 activity resolves to
/// [ActivityCategory.generalWellness], a neutral category with no approved
/// Place of its own yet (see that enum's own doc comment). This mapping
/// exists so `Recommendation.category` stays a truthful description of the
/// activity, even though, in v0, every category currently renders the same
/// illustration in `circle_hero.dart`.
ActivityCategory activityCategory(ActivityId activityId) => switch (activityId) {
  ActivityId.thirtyMinuteWalk ||
  ActivityId.phoneFreeWalk ||
  ActivityId.easyWalk => ActivityCategory.walking,
  ActivityId.moveToMusic ||
  ActivityId.writeItDown ||
  ActivityId.quietReading ||
  ActivityId.quietMusicBreak => ActivityCategory.generalWellness,
};

/// The "Why This Today?" copy for ([intention], [activityId]) — deliberately
/// keyed on the pair, not on [activityId] alone, so a future activity
/// shared across pools (see [ActivityId]'s own doc comment) could carry a
/// different reason per intention even though the activity itself is the
/// same.
///
/// Every string here may reference only (1) the intention the user
/// explicitly selected, and (2) a truthful, practical characteristic of the
/// activity — never a claim of hidden knowledge about the user (no "your
/// body needs...", no "based on your energy...", no medical or emotional
/// claims). See `docs/product/recommendation-mvp-v0.md` for the full rule.
const Map<(Intention, ActivityId), String> _whyCopy = {
  (Intention.moreEnergy, ActivityId.thirtyMinuteWalk):
      'For more energy: a 30-minute walk, wherever you are — no pace or '
      'distance to keep up with.',
  (Intention.moreEnergy, ActivityId.moveToMusic):
      'For more energy: moving to your own music, at whatever pace feels '
      'good.',
  (Intention.clearerHead, ActivityId.phoneFreeWalk):
      'For a clearer head: a walk with your phone\'s content set aside — '
      'just you and where you\'re walking.',
  (Intention.clearerHead, ActivityId.writeItDown):
      'For a clearer head: spend about 30 minutes writing down the tasks, '
      'reminders and loose thoughts competing for your attention, in any '
      'order. No need to solve or organise them.',
  (Intention.clearerHead, ActivityId.quietReading):
      'For a clearer head: quiet reading, one thing to focus on instead '
      'of many.',
  (Intention.gentlerPace, ActivityId.easyWalk):
      'For a gentler pace: an easy, unhurried walk with nothing to hit '
      'or beat.',
  (Intention.gentlerPace, ActivityId.quietMusicBreak):
      'For a gentler pace: a quiet music break, just for you, with no '
      'goal attached.',
};

/// The "why" explanation for choosing [activityId] under [intention].
///
/// Throws a [StateError] if the pair has no copy defined — this can only
/// happen if [activityPools] and [_whyCopy] have drifted out of sync, which
/// is a programming error, not a runtime condition to recover from.
String whyCopyFor(Intention intention, ActivityId activityId) {
  final why = _whyCopy[(intention, activityId)];
  if (why == null) {
    throw StateError('No why-copy defined for ($intention, $activityId).');
  }
  return why;
}

/// A stable, calendar-derived integer for [date]'s local calendar day —
/// the same value for every [DateTime] on the same local date, regardless
/// of time-of-day, and strictly increasing from one calendar day to the
/// next. Built from [DateTime.utc] (never a local-time difference) so it
/// can never be perturbed by daylight-saving transitions.
///
/// This is the deterministic "which day is it, as a number" primitive
/// [selectActivityId] rotates through [activityPools] with — never a
/// hash code, and never randomness.
int epochDay(DateTime date) =>
    DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

/// Deterministically picks one [ActivityId] from [intention]'s pool.
///
/// - **Deterministic:** the same ([dayIndex], [intention]) always resolves
///   to the same [ActivityId] — no scoring, no AI, no probabilistic
///   ranking.
/// - **Anti-repetition:** if the normal candidate (`dayIndex % pool.length`)
///   equals [previousActivityId], the next candidate in the pool is used
///   instead — a single, fixed step, not a weighted or novelty-scored
///   choice. Every [activityPools] entry has at least two activities, so an
///   alternative is always available.
ActivityId selectActivityId({
  required Intention intention,
  required int dayIndex,
  ActivityId? previousActivityId,
}) {
  final pool = activityPools[intention]!;
  final normalIndex = dayIndex % pool.length;
  final candidate = pool[normalIndex];
  if (candidate != previousActivityId) {
    return candidate;
  }
  return pool[(normalIndex + 1) % pool.length];
}
