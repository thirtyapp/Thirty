/// What THIRTY remembers, per need (V2 Phase C, ADR-021) — derived on every
/// read from the user's explicit answers and suggestion controls, the same
/// facts Recommendation Engine V2 decides from. Never stored, never inferred:
/// a Circle that was started or closed but not answered says nothing here.
library;

import '../application/activity_catalog.dart';
import 'recommendation_engine.dart';
import 'recommendation_policy.dart';

/// One activity the user answered about for a need.
class RememberedActivity {
  const RememberedActivity({
    required this.activity,
    required this.answer,
    required this.answeredOn,
    this.restsUntil,
  });

  final ActivityId activity;

  /// The latest answer that still counts for this need.
  final PastUsefulness answer;

  /// The local date of that answer.
  final DateTime answeredOn;

  /// The last local date the activity rests for this need, while resting.
  final DateTime? restsUntil;
}

/// The memory page's view of one need.
class NeedMemory {
  const NeedMemory({
    required this.need,
    required this.usefulBefore,
    required this.resting,
    required this.notUsefulBefore,
    required this.notSuggested,
    required this.usualTime,
    required this.notOfferedYet,
  });

  final Intention need;

  /// The latest answer was "Very useful" or "Somewhat useful".
  final List<RememberedActivity> usefulBefore;

  /// Resting for now after a "Not useful" for this need.
  final List<RememberedActivity> resting;

  /// The latest answer was "Not useful", and its rest is over or was
  /// lifted: offered again, less often while that answer still counts.
  final List<RememberedActivity> notUsefulBefore;

  /// "Don't suggest" for this need — the user's own choice.
  final List<ActivityId> notSuggested;

  /// The time the user has clearly chosen most for this need, or `null`.
  final TimeWindow? usualTime;

  /// Fitting activities THIRTY has not offered for this need yet.
  final int notOfferedYet;

  bool get hasAnswers =>
      usefulBefore.isNotEmpty ||
      resting.isNotEmpty ||
      notUsefulBefore.isNotEmpty;
}

/// At least this many explicit time choices for a need before a usual time
/// is claimed, and the leading one must be at least [usualTimeShare] of them
/// and ahead of every other. TUNABLE.
const usualTimeMinChoices = 3;
const usualTimeShare = 0.6;

DateTime _day(DateTime date) => DateTime.utc(date.year, date.month, date.day);

int _ageInDays(DateTime date, DateTime today) =>
    _day(today).difference(_day(date)).inDays;

/// [need]'s memory on [today], from [history] — today's own Circle
/// included — and the user's [controls].
NeedMemory needMemoryOf({
  required DateTime today,
  required Intention need,
  required List<PastCircle> history,
  SuggestionControls controls = SuggestionControls.none,
  RecommendationPolicy policy = RecommendationPolicy.initial,
  bool allowSafetyPending = safetyPendingContentAllowed,
}) {
  bool counts(PastCircle c) =>
      c.usefulness != null &&
      _ageInDays(c.date, today) <= policy.evidenceWindowDays &&
      historicalEvidenceEligible(c.activityId, c.catalogVersion);

  bool restLifted(PastCircle c) {
    final liftedAt = controls.restsLifted[(c.activityId, need)];
    return liftedAt != null && !(c.answeredAt ?? c.date).isAfter(liftedAt);
  }

  final ordered = [...history]..sort((a, b) => a.date.compareTo(b.date));
  final latest = <ActivityId, PastCircle>{};
  final restingFrom = <ActivityId, PastCircle>{};
  for (final c in ordered) {
    if (c.need != need || !counts(c)) continue;
    latest[c.activityId] = c;
    if (c.usefulness == PastUsefulness.notUseful && !restLifted(c)) {
      restingFrom[c.activityId] = c;
    }
  }

  final notSuggested = [
    for (final id in ActivityId.values)
      if (controls.notSuggested.contains((id, need))) id,
  ];

  final usefulBefore = <RememberedActivity>[];
  final resting = <RememberedActivity>[];
  final notUsefulBefore = <RememberedActivity>[];
  for (final MapEntry(key: id, value: answer) in latest.entries) {
    // The user's direct choice is what this need shows for it.
    if (notSuggested.contains(id)) continue;
    final rest = restingFrom[id];
    if (rest != null && _ageInDays(rest.date, today) <= policy.restDays) {
      resting.add(
        RememberedActivity(
          activity: id,
          answer: PastUsefulness.notUseful,
          answeredOn: _day(rest.date),
          restsUntil: _day(rest.date).add(Duration(days: policy.restDays)),
        ),
      );
      continue;
    }
    final remembered = RememberedActivity(
      activity: id,
      answer: answer.usefulness!,
      answeredOn: _day(answer.date),
    );
    if (answer.usefulness == PastUsefulness.notUseful) {
      notUsefulBefore.add(remembered);
    } else {
      usefulBefore.add(remembered);
    }
  }
  int newestFirst(RememberedActivity a, RememberedActivity b) {
    final byDate = b.answeredOn.compareTo(a.answeredOn);
    return byDate != 0 ? byDate : a.activity.index - b.activity.index;
  }

  usefulBefore.sort(newestFirst);
  resting.sort(newestFirst);
  notUsefulBefore.sort(newestFirst);

  final offered = {
    for (final c in history)
      if (c.need == need) ...[c.activityId, ?c.replacedFrom],
  };
  final notOfferedYet = ActivityId.values.where((id) {
    final activity = activityDefinition(id);
    return activity.fitFor(need) != NeedFit.none &&
        isActivityOfferable(id, allowSafetyPending: allowSafetyPending) &&
        !notSuggested.contains(id) &&
        !offered.contains(id);
  }).length;

  return NeedMemory(
    need: need,
    usefulBefore: usefulBefore,
    resting: resting,
    notUsefulBefore: notUsefulBefore,
    notSuggested: notSuggested,
    usualTime: _usualTime(history, need, today, policy),
    notOfferedYet: notOfferedYet,
  );
}

/// The window chosen clearly most often for [need], from explicit choices
/// within the evidence window — or `null` while the evidence is thin.
TimeWindow? _usualTime(
  List<PastCircle> history,
  Intention need,
  DateTime today,
  RecommendationPolicy policy,
) {
  final counts = <TimeWindow, int>{};
  for (final c in history) {
    final window = c.window;
    if (c.need != need || window == null) continue;
    if (_ageInDays(c.date, today) > policy.evidenceWindowDays) continue;
    counts[window] = (counts[window] ?? 0) + 1;
  }
  final total = counts.values.fold(0, (sum, n) => sum + n);
  if (total < usualTimeMinChoices) return null;
  final ranked = counts.entries.toList()..sort((a, b) => b.value - a.value);
  final top = ranked.first;
  if (ranked.length > 1 && ranked[1].value == top.value) return null;
  if (top.value < total * usualTimeShare) return null;
  return top.key;
}
