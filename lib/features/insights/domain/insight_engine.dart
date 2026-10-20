/// The Insights evaluator (ADR-024 §11–§12, B5): pure, local and
/// deterministic. Every observation is recomputed from the facts it is
/// given — the journal's Circles, the Plans and the user's own controls —
/// for an explicit [InsightInputs.today]; nothing reads a clock, and nothing
/// is learned or kept beyond the snapshots the caller stores.
///
/// **Windows** count days back from today, which is day 1: "the last 28
/// days" is days 1–28, I6's earlier window days 57–84, I4's window days
/// 1–90.
///
/// **The pattern gate** (contract: at least 5 relevant records on at least
/// 3 dates spanning at least 14 days, within the family's window) is a
/// floor on each family's records — a need's choices (I1), the active
/// Plan's stage offers (I2), the composed Circles (I3, and I4's need), each
/// window (I6). Each family then adds its own condition. "Spanning 14 days"
/// counts both end dates. The Plan review has no gate: it's a bounded
/// record.
library;

import '../../home/application/activity_catalog.dart';
import '../../home/application/circle_journal.dart';
import '../../home/domain/recommendation_engine.dart';
import '../../personal_circle/domain/circle_composer.dart';
import '../../personal_circle/domain/circle_elements.dart';
import '../../personal_circle/domain/kept_circle.dart';
import '../../plans/domain/circle_plan.dart';
import '../../plans/domain/plan_stage_provenance.dart';
import 'insight.dart';
import 'insight_copy.dart';

/// One journal Circle, as the facts an Insight may use.
class InsightCircle {
  const InsightCircle({
    required this.circleId,
    required this.localDate,
    required this.need,
    this.parts = const [],
    this.skipped = const {},
    this.kept = false,
    this.answer,
    this.stage,
    this.replacedFromStage,
    this.replacementReason,
  });

  final String circleId;

  /// `YYYY-MM-DD`.
  final String localDate;

  /// The need the user chose.
  final Intention need;

  /// A composed Circle's parts; empty for a single activity.
  final List<CirclePart> parts;

  /// Every part skipped that day — directly or with the part it builds on.
  final Set<ElementId> skipped;

  /// The day ran one of the user's kept Circles.
  final bool kept;

  /// The user's explicit usefulness answer, or `null`: no answer — never
  /// "not useful".
  final PastUsefulness? answer;

  /// The Plan stage it was composed for.
  final PlanStageProvenance? stage;

  /// The Plan stage of the Circle "Not this one today" replaced.
  final PlanStageProvenance? replacedFromStage;

  /// Why it was replaced (`ReplacementReason.name`).
  final String? replacementReason;

  /// A Personal Guided Circle or a stage Circle — not a kept Circle, not a
  /// single activity.
  bool get composed => parts.isNotEmpty && !kept;

  bool get calledUseful =>
      answer == PastUsefulness.veryUseful ||
      answer == PastUsefulness.somewhatUseful;

  /// The parts the user skipped themselves. A part that builds on the one
  /// before it ([CircleElement.after]) is skipped with it, and isn't.
  Set<ElementId> get directSkips => {
    for (var i = 0; i < parts.length; i++)
      if (skipped.contains(parts[i].element) &&
          !(i > 0 &&
              parts[i].definition.after == parts[i - 1].element &&
              skipped.contains(parts[i - 1].element)))
        parts[i].element,
  };

  /// [kind] as the main or second piece.
  bool hasMainOrSecond(ElementKind kind, {bool unskipped = false}) => parts.any(
    (p) =>
        p.definition.kind == kind &&
        const {
          ElementRole.main,
          ElementRole.second,
        }.contains(partRole(parts, p)) &&
        !(unskipped && skipped.contains(p.element)),
  );

  /// The facts of one journal entry.
  static InsightCircle fromJournal(CircleJournalEntry entry) {
    final session = entry.session;
    return InsightCircle(
      circleId: entry.circleId,
      localDate: entry.localDate,
      need: entry.direction,
      parts: CirclePlan.fromWire(session?.parts)?.parts ?? const [],
      skipped: {
        for (final wire in session?.skipped ?? const <String>[])
          ?ElementId.values.asNameMap()[wire],
      },
      kept: session?.keptCircleId != null,
      answer: switch (entry.usefulnessResponse) {
        CircleUsefulnessResponse.veryUseful => PastUsefulness.veryUseful,
        CircleUsefulnessResponse.somewhatUseful =>
          PastUsefulness.somewhatUseful,
        CircleUsefulnessResponse.notUseful => PastUsefulness.notUseful,
        null => null,
      },
      stage: session?.planStage,
      replacedFromStage: entry.replacedFromStage,
      replacementReason: entry.replacementReason,
    );
  }
}

/// Everything the evaluator looks at.
class InsightInputs {
  const InsightInputs({
    required this.today,
    required this.circles,
    this.plans = CirclePlansState.empty,
    this.leftOut = const {},
    this.keptFromCircles = const {},
    this.keptCount = 0,
  });

  /// The local date assessed; its time of day is ignored.
  final DateTime today;
  final List<InsightCircle> circles;
  final CirclePlansState plans;
  final Set<ElementId> leftOut;

  /// The journal Circles already kept.
  final Set<String> keptFromCircles;
  final int keptCount;
}

/// One qualifying observation, before it is shown.
class InsightCandidate {
  const InsightCandidate({
    required this.family,
    required this.text,
    required this.facts,
    required this.evidence,
    required this.subject,
    required this.application,
  });

  final InsightFamily family;
  final String text;
  final Map<String, Object> facts;
  final List<String> evidence;
  final String subject;
  final InsightApplication application;

  InsightSnapshot snapshot(String today) => InsightSnapshot(
    id: '${family.id}@$today#$subject',
    family: family,
    generatedOn: today,
    wordingVersion: insightWordingVersion,
    text: text,
    facts: facts,
    evidence: evidence,
    subject: subject,
    application: application,
  );
}

// ---------------------------------------------------------------------------
// Dates.

DateTime _day(String localDate) {
  final p = localDate.split('-');
  return DateTime.utc(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

DateTime _utcDay(DateTime local) =>
    DateTime.utc(local.year, local.month, local.day);

String _key(DateTime utcDay) =>
    '${utcDay.year.toString().padLeft(4, '0')}-'
    '${utcDay.month.toString().padLeft(2, '0')}-'
    '${utcDay.day.toString().padLeft(2, '0')}';

/// Today is day 1.
int _dayIndex(DateTime today, String localDate) =>
    _utcDay(today).difference(_day(localDate)).inDays + 1;

/// The local date of day [n].
String dayOf(DateTime today, int n) =>
    _key(_utcDay(today).subtract(Duration(days: n - 1)));

/// Days from [earlier] to [later] (`YYYY-MM-DD`).
int daysBetween(String earlier, String later) =>
    _day(later).difference(_day(earlier)).inDays;

List<InsightCircle> _within(InsightInputs i, int from, int to) =>
    [
      for (final c in i.circles)
        if (_dayIndex(i.today, c.localDate) case final n
            when n >= from && n <= to)
          c,
    ]..sort((a, b) {
      final d = a.localDate.compareTo(b.localDate);
      return d != 0 ? d : a.circleId.compareTo(b.circleId);
    });

Set<String> _dates(Iterable<InsightCircle> circles) => {
  for (final c in circles) c.localDate,
};

/// At least 5 records on at least 3 dates spanning at least 14 days.
bool patternGate(Iterable<InsightCircle> records) {
  final dates = _dates(records).toList()..sort();
  return records.length >= 5 &&
      dates.length >= 3 &&
      daysBetween(dates.first, dates.last) + 1 >= 14;
}

/// The need chosen most, if exactly one was.
(Intention, int)? _uniqueTop(List<InsightCircle> circles) {
  final counts = {
    for (final need in Intention.values)
      need: circles.where((c) => c.need == need).length,
  };
  final best = counts.values.fold(0, (a, b) => a > b ? a : b);
  final top = [
    for (final e in counts.entries)
      if (e.value == best) e.key,
  ];
  return best > 0 && top.length == 1 ? (top.single, best) : null;
}

CirclePlanDefinition _planFor(Intention need) =>
    launchCirclePlans.firstWhere((p) => p.need == need);

/// Start, carry on with, or go through [planId] again — as it stands.
PlanStep? _stepFor(CirclePlansState plans, String planId) =>
    switch (plans.lifecycleOf(planId)) {
      PlanLifecycle.active => null,
      PlanLifecycle.paused => PlanStep.carryOn,
      PlanLifecycle.neverStarted => PlanStep.start,
      PlanLifecycle.ended || PlanLifecycle.left => PlanStep.goThroughAgain,
    };

// ---------------------------------------------------------------------------
// I1 — the Plan for your need.

InsightCandidate? planForNeed(InsightInputs i) {
  final window = _within(i, 1, 28);
  final top = _uniqueTop(window);
  if (top == null) return null;
  final (need, count) = top;
  final chosen = [
    for (final c in window)
      if (c.need == need) c,
  ];
  if (!patternGate(chosen)) return null;
  final plan = _planFor(need);
  final step = _stepFor(i.plans, plan.id);
  if (step == null) return null;
  final from = chosen.first.localDate;
  final to = chosen.last.localDate;
  return InsightCandidate(
    family: InsightFamily.planForNeed,
    text: InsightCopy.planForNeed(need, count, window.length, from, to),
    facts: {
      'need': need.name,
      'count': count,
      'of': window.length,
      'from': from,
      'to': to,
      'planId': plan.id,
    },
    evidence: [for (final c in chosen) c.circleId],
    subject: '${InsightFamily.planForNeed.id}:${need.name}',
    application: PlanDirection(plan.id, step),
  );
}

// ---------------------------------------------------------------------------
// I2 — gentler Plan Circles.

InsightCandidate? planPacing(InsightInputs i) {
  final active = i.plans.active;
  if (active == null) return null;
  final cycle = active.current;
  if (cycle.isOver || cycle.isGentler) return null;
  bool ofThisPlan(PlanStageProvenance? s) => s?.planId == active.planId;
  // Offers composed under the gentler setting are THIRTY's doing — never
  // evidence for offering it.
  final offers = [
    for (final c in _within(i, 1, 28))
      if ((ofThisPlan(c.stage) || ofThisPlan(c.replacedFromStage)) &&
          c.stage?.gentler != true &&
          c.replacedFromStage?.gentler != true)
        c,
  ];
  if (!patternGate(offers)) return null;
  final tooMuch = [
    for (final c in offers)
      if (c.replacementReason == 'tooMuch' && ofThisPlan(c.replacedFromStage))
        c,
  ];
  if (tooMuch.length < 3 || _dates(tooMuch).length < 3) return null;
  final plan = active.definition;
  return InsightCandidate(
    family: InsightFamily.planPacing,
    text: InsightCopy.planPacing(plan.name, tooMuch.length, offers.length),
    facts: {
      'planId': plan.id,
      'cycleId': cycle.id,
      'count': tooMuch.length,
      'of': offers.length,
    },
    evidence: [for (final c in offers) c.circleId],
    // Per Plan; the cycle is in the facts. Its evidence — the untreated
    // offers — decides what "Not now" or an earlier application hides.
    subject: '${InsightFamily.planPacing.id}:${plan.id}',
    application: KeepGentler(plan.id, cycle.id),
  );
}

// ---------------------------------------------------------------------------
// I3 — a part you skip.

InsightCandidate? skippedPart(InsightInputs i) {
  final composed = [
    for (final c in _within(i, 1, 28))
      if (c.composed) c,
  ];
  if (!patternGate(composed)) return null;
  InsightCandidate? best;
  (int, String, int)? bestRank;
  for (final element in ElementId.values) {
    if (i.leftOut.contains(element)) continue;
    final held = [
      for (final c in composed)
        if (c.parts.any((p) => p.element == element)) c,
    ];
    if (held.length < 3) continue;
    final last = held.sublist(held.length > 4 ? held.length - 4 : 0);
    final direct = [
      for (final c in last)
        if (c.directSkips.contains(element)) c,
    ];
    if (direct.length < 3 || _dates(direct).length < 3) continue;
    final rank = (
      direct.length * 4 ~/ last.length,
      direct.last.localDate,
      -element.index,
    );
    if (bestRank != null && _compareRank(rank, bestRank) <= 0) continue;
    bestRank = rank;
    best = InsightCandidate(
      family: InsightFamily.skippedPart,
      text: InsightCopy.skippedPart(
        elementOf(element).name,
        direct.length,
        last.length,
        direct.last.localDate,
        ofMore: held.length > last.length,
      ),
      facts: {
        'element': element.name,
        'count': direct.length,
        'of': last.length,
        'appearances': held.length,
        'last': direct.last.localDate,
      },
      evidence: [for (final c in last) c.circleId],
      subject: '${InsightFamily.skippedPart.id}:${element.name}',
      application: LeaveOutPart(element.name),
    );
  }
  return best;
}

int _compareRank((int, String, int) a, (int, String, int) b) {
  if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
  final d = a.$2.compareTo(b.$2);
  if (d != 0) return d;
  return a.$3.compareTo(b.$3);
}

// ---------------------------------------------------------------------------
// I4 — what your useful Circles shared.

InsightCandidate? usefulInCommon(InsightInputs i) {
  final window = [
    for (final c in _within(i, 1, 90))
      if (c.composed) c,
  ];
  InsightCandidate? best;
  (int, int, int, int)? bestRank;
  for (final need in Intention.values) {
    final forNeed = [
      for (final c in window)
        if (c.need == need) c,
    ];
    final useful = [
      for (final c in forNeed)
        if (c.calledUseful) c,
    ];
    final dates = _dates(useful).toList()..sort();
    if (useful.length < 4 ||
        dates.length < 3 ||
        daysBetween(dates.first, dates.last) + 1 < 14) {
      continue;
    }
    // An exposure baseline: unanswered and Not-useful Circles alike —
    // never called "the ones that weren't useful".
    final other = [
      for (final c in forNeed)
        if (!c.calledUseful) c,
    ];
    if (other.length < 3) continue;
    for (final kind in ElementKind.values) {
      final inUseful = [
        for (final c in useful)
          if (c.hasMainOrSecond(kind, unskipped: true)) c,
      ];
      final a = inUseful.length;
      final u = useful.length;
      if (a < 3 || a * 3 < 2 * u) continue;
      final b = other.where((c) => c.hasMainOrSecond(kind)).length;
      final o = other.length;
      // a/u − b/o ≥ 25 percentage points, in whole numbers.
      if (4 * (a * o - b * u) < u * o) continue;
      final rank = (
        (a * o - b * u) * 1000 ~/ (u * o),
        a,
        -need.index,
        -kind.index,
      );
      if (bestRank != null && _compareRank4(rank, bestRank) <= 0) continue;
      bestRank = rank;
      final target = inUseful.last;
      final canKeep =
          !i.keptFromCircles.contains(target.circleId) &&
          i.keptCount < maxKeptCircles;
      best = InsightCandidate(
        family: InsightFamily.usefulInCommon,
        text: InsightCopy.usefulInCommon(kind, need, a, u, b, o),
        facts: {
          'need': need.name,
          'kind': kind.name,
          'inUseful': a,
          'useful': u,
          'inOther': b,
          'other': o,
          'circleId': target.circleId,
        },
        evidence: [for (final c in forNeed) c.circleId],
        subject: '${InsightFamily.usefulInCommon.id}:${need.name}:${kind.name}',
        application: canKeep
            ? KeepCircleFromHistory(target.circleId)
            : const NothingToChange(InsightCopy.usefulAlreadyWeighted),
      );
    }
  }
  return best;
}

int _compareRank4((int, int, int, int) a, (int, int, int, int) b) {
  for (final (x, y) in [
    (a.$1, b.$1),
    (a.$2, b.$2),
    (a.$3, b.$3),
    (a.$4, b.$4),
  ]) {
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

// ---------------------------------------------------------------------------
// I6 — what's changed.

InsightCandidate? whatsChanged(InsightInputs i) {
  final recent = _within(i, 1, 28);
  final earlier = _within(i, 57, 84);
  if (!patternGate(recent) || !patternGate(earlier)) return null;
  final r = _uniqueTop(recent);
  final e = _uniqueTop(earlier);
  if (r == null || e == null) return null;
  final (recentNeed, recentCount) = r;
  final (earlierNeed, earlierCount) = e;
  if (recentNeed == earlierNeed) return null;
  // Each top need at least 40 % of its window.
  if (recentCount * 5 < recent.length * 2) return null;
  if (earlierCount * 5 < earlier.length * 2) return null;
  final plan = _planFor(recentNeed);
  final step = _stepFor(i.plans, plan.id);
  final from = dayOf(i.today, 84);
  final to = dayOf(i.today, 57);
  return InsightCandidate(
    family: InsightFamily.whatsChanged,
    text: InsightCopy.whatsChanged(
      from,
      to,
      earlierNeed,
      earlierCount,
      earlier.length,
      recentNeed,
      recentCount,
      recent.length,
    ),
    facts: {
      'earlierNeed': earlierNeed.name,
      'earlierCount': earlierCount,
      'earlierOf': earlier.length,
      'recentNeed': recentNeed.name,
      'recentCount': recentCount,
      'recentOf': recent.length,
      'from': from,
      'to': to,
      'planId': plan.id,
    },
    evidence: [
      for (final c in [...earlier, ...recent]) c.circleId,
    ],
    subject:
        '${InsightFamily.whatsChanged.id}:${earlierNeed.name}>${recentNeed.name}',
    application: step == null
        ? NothingToChange(InsightCopy.alreadyYourPlan(plan.name))
        : PlanDirection(plan.id, step),
  );
}

// ---------------------------------------------------------------------------
// I5 — the Plan review: a reference to the cycle Plans keeps, never a copy.

/// Every Plan cycle with a review (B3's [PlanCycle.hasReview]: an end, or a
/// Plan left with at least three stages guided — never one whose evidence
/// was deleted).
List<InsightCandidate> planReviews(InsightInputs i) => [
  for (final progress in i.plans.plans.values)
    for (final cycle in progress.cycles)
      if (cycle.hasReview && cycle.endedOn != null)
        InsightCandidate(
          family: InsightFamily.planReview,
          text: InsightCopy.planReview(
            progress.definition.name,
            cycle.endedOn!,
          ),
          facts: {
            'planId': progress.planId,
            'cycleId': cycle.id,
            'cycle': cycle.number,
            'endedOn': cycle.endedOn!,
          },
          evidence: [for (final r in cycle.records) ?r.circleId],
          subject:
              '${InsightFamily.planReview.id}:${progress.planId}:${cycle.id}',
          application: OpenPlanReview(progress.planId, cycle.id),
        ),
];

/// Every ordinary family that qualifies today, in priority order.
List<InsightCandidate> ordinaryCandidates(InsightInputs i) => [
  for (final family in ordinaryInsightPriority)
    ?switch (family) {
      InsightFamily.skippedPart => skippedPart(i),
      InsightFamily.planPacing => planPacing(i),
      InsightFamily.usefulInCommon => usefulInCommon(i),
      InsightFamily.planForNeed => planForNeed(i),
      InsightFamily.whatsChanged => whatsChanged(i),
      InsightFamily.planReview => null,
    },
];

// ---------------------------------------------------------------------------
// A snapshot over time.

enum InsightStatus {
  /// Still true today, and not yet acted on.
  current,

  /// The user applied it.
  applied,

  /// The user said "Not now".
  notNow,

  /// I3: the user kept the part.
  declined,

  /// No longer true today: a dated record, readable, not actionable.
  stale,
}

/// What [snapshot] is today.
InsightStatus statusOf(InsightSnapshot snapshot, InsightInputs i) {
  if (snapshot.appliedOn != null) return InsightStatus.applied;
  if (snapshot.notNowOn != null) return InsightStatus.notNow;
  if (snapshot.declinedOn != null) return InsightStatus.declined;
  return _stillTrue(snapshot, i) ? InsightStatus.current : InsightStatus.stale;
}

/// The same observation still holds when the family, evaluated today, makes
/// the same claim from evidence that still includes some of what was shown
/// — so a new day of the same pattern keeps it, and the same claim formed
/// again from entirely new Circles is a new Insight, not this one.
bool _stillTrue(InsightSnapshot s, InsightInputs i) {
  bool same(InsightCandidate? now) =>
      now != null &&
      now.subject == s.subject &&
      now.evidence.any(s.evidence.contains);
  return switch (s.family) {
    InsightFamily.planForNeed => same(planForNeed(i)),
    // …and for the same cycle: a setting of that cycle only.
    InsightFamily.planPacing =>
      same(planPacing(i)) &&
          planPacing(i)!.facts['cycleId'] == s.facts['cycleId'],
    InsightFamily.usefulInCommon => same(usefulInCommon(i)),
    InsightFamily.whatsChanged => same(whatsChanged(i)),
    InsightFamily.skippedPart => _skipStillTrue(s, i),
    // A dated record — never stale while Plans still has the review.
    InsightFamily.planReview => planReviews(
      i,
    ).any((c) => c.subject == s.subject),
  };
}

/// I3 is withdrawn once the part is left out, or after 2 appearances in a
/// row since it was shown without being skipped.
bool _skipStillTrue(InsightSnapshot s, InsightInputs i) {
  final element = ElementId.values.asNameMap()[s.facts['element']];
  if (element == null || i.leftOut.contains(element)) return false;
  final since = [
    for (final c in i.circles)
      if (c.composed &&
          c.localDate.compareTo(s.generatedOn) >= 0 &&
          !s.evidence.contains(c.circleId) &&
          c.parts.any((p) => p.element == element))
        c,
  ]..sort((a, b) => a.localDate.compareTo(b.localDate));
  final lastTwo = since.length < 2 ? since : since.sublist(since.length - 2);
  return !(lastTwo.length == 2 &&
      lastTwo.every((c) => !c.skipped.contains(element)));
}

/// Whether [candidate]'s evidence set is hidden today (§11: "Not now"
/// hides that evidence set for 28 days). It is when, within
/// [insightQuietDays], the user said "Not now" to, applied or dismissed an
/// ordinary snapshot with the same subject whose evidence holds every
/// Circle [candidate] rests on — the same set ([insightFingerprint]), or
/// what is left of it as older Circles leave the window. A Circle relevant
/// to the claim that wasn't in it is new evidence; an irrelevant one
/// changes nothing. Plan reviews are never hidden this way.
bool isQuiet(
  InsightCandidate candidate,
  List<InsightSnapshot> snapshots,
  DateTime today,
) {
  if (!candidate.family.isOrdinary) return false;
  final now = _key(_utcDay(today));
  final fingerprint = insightFingerprint(candidate.subject, candidate.evidence);
  return snapshots.any(
    (s) =>
        s.family.isOrdinary &&
        s.subject == candidate.subject &&
        [
          s.notNowOn,
          s.appliedOn,
          s.declinedOn,
        ].any((on) => on != null && daysBetween(on, now) < insightQuietDays) &&
        (s.evidenceFingerprint == fingerprint ||
            candidate.evidence.every(s.evidence.contains)),
  );
}

/// Whether the claim [subject] — an ordinary family and its subject — was
/// shown within [insightRepeatDays], so it can't be shown again today: a
/// selection rule, never a preference or evidence. Plan reviews are never
/// held back by it.
bool claimCooling(
  String subject,
  List<InsightSnapshot> snapshots,
  DateTime today,
) {
  final now = _key(_utcDay(today));
  return snapshots.any(
    (s) =>
        s.family.isOrdinary &&
        s.subject == subject &&
        daysBetween(s.generatedOn, now) < insightRepeatDays,
  );
}

/// Whether a new ordinary Insight may be generated today.
bool cadenceAllows(List<InsightSnapshot> snapshots, DateTime today) {
  final now = _key(_utcDay(today));
  return !snapshots.any(
    (s) =>
        s.family.isOrdinary &&
        daysBetween(s.generatedOn, now) < insightCadenceDays,
  );
}

// ---------------------------------------------------------------------------
// Assessment.

/// Where the user's Insights stand (§12) — what B6 shows. Never a made-up
/// Insight.
enum InsightReadiness {
  /// No Circle recorded yet.
  noHistory,

  /// The Circles don't span two weeks yet: THIRTY says nothing about
  /// patterns.
  tooShort,

  /// Enough history; no family qualifies.
  nothingQualifies,

  /// A new ordinary Insight would wait for the 7-day cadence.
  cadenceWaiting,

  /// A current Insight is there.
  insightAvailable,
}

/// The outcome of one assessment (or of reading what is kept).
class InsightAssessment {
  const InsightAssessment({
    required this.snapshots,
    required this.added,
    required this.readiness,
    required this.circles,
    required this.answers,
  });

  /// Everything kept after the assessment, oldest first.
  final List<InsightSnapshot> snapshots;

  /// What this assessment generated — Plan reviews first.
  final List<InsightSnapshot> added;

  final InsightReadiness readiness;

  /// The status line's counts (§12, Week 1): Circles and answers so far.
  final int circles;
  final int answers;
}

/// Pull-based: what opening Insights on [i]'s day would show and store.
/// Plan reviews appear at once; at most one new ordinary Insight per
/// [insightCadenceDays], the first family that qualifies in priority order
/// whose observation isn't already current or quiet. [generate] `false`
/// only reads.
InsightAssessment assessInsights(
  InsightInputs i,
  List<InsightSnapshot> kept, {
  required bool generate,
}) {
  final today = _key(_utcDay(i.today));
  final snapshots = [...kept];
  final added = <InsightSnapshot>[];
  if (generate) {
    final known = {for (final s in snapshots) s.subject};
    // A review is shown once, by the first assessment after its cycle
    // ended. Once the cap has dropped snapshots (there are never fewer than
    // [maxInsightSnapshots] afterwards), a review that isn't kept although
    // a snapshot was generated after its cycle ended was dropped by the
    // cap — and a dropped review never comes back as new (B8).
    final newest = snapshots.length < maxInsightSnapshots
        ? null
        : snapshots.map((s) => s.generatedOn).reduce(_later);
    for (final review in planReviews(i)) {
      final ended = review.facts['endedOn']! as String;
      if (newest != null && newest.compareTo(ended) > 0) {
        known.add(review.subject);
        continue;
      }
      if (known.add(review.subject)) {
        added.add(review.snapshot(today));
      }
    }
    if (cadenceAllows(snapshots, i.today)) {
      // Priority among the eligible only: a claim shown within 28 days, or
      // an evidence set set aside, is not eligible — and nothing fills the
      // week for the sake of it.
      for (final candidate in ordinaryCandidates(i)) {
        if (claimCooling(candidate.subject, snapshots, i.today)) continue;
        final showing = snapshots.any(
          (s) =>
              s.subject == candidate.subject &&
              statusOf(s, i) == InsightStatus.current,
        );
        if (showing || isQuiet(candidate, snapshots, i.today)) {
          continue;
        }
        added.add(candidate.snapshot(today));
        break;
      }
    }
    snapshots.addAll(added);
  }
  final pruned = pruneSnapshots(snapshots, i);
  return InsightAssessment(
    snapshots: pruned,
    added: [
      for (final s in added)
        if (pruned.contains(s)) s,
    ],
    readiness: _readiness(pruned, i),
    circles: i.circles.length,
    answers: i.circles.where((c) => c.answer != null).length,
  );
}

/// The later of two `YYYY-MM-DD` keys.
String _later(String a, String b) => a.compareTo(b) >= 0 ? a : b;

/// The newest ordinary snapshot still current, if any.
InsightSnapshot? currentInsight(
  List<InsightSnapshot> snapshots,
  InsightInputs i,
) {
  for (final s in snapshots.reversed) {
    if (s.family.isOrdinary && statusOf(s, i) == InsightStatus.current) {
      return s;
    }
  }
  return null;
}

InsightReadiness _readiness(List<InsightSnapshot> snapshots, InsightInputs i) {
  if (i.circles.isEmpty) return InsightReadiness.noHistory;
  if (currentInsight(snapshots, i) != null) {
    return InsightReadiness.insightAvailable;
  }
  final dates = _dates(i.circles).toList()..sort();
  if (daysBetween(dates.first, dates.last) + 1 < 14) {
    return InsightReadiness.tooShort;
  }
  return cadenceAllows(snapshots, i.today)
      ? InsightReadiness.nothingQualifies
      : InsightReadiness.cadenceWaiting;
}

/// At most [maxInsightSnapshots], dropping the oldest first — never the
/// current Insight, nor an ordinary one still in its 28-day repeat window. A Plan review dropped here is still the user's in
/// Plans: the snapshot is only a reference to it.
List<InsightSnapshot> pruneSnapshots(
  List<InsightSnapshot> snapshots,
  InsightInputs i,
) {
  if (snapshots.length <= maxInsightSnapshots) return snapshots;
  final keep = currentInsight(snapshots, i);
  // Every ordinary snapshot younger than [insightRepeatDays] is kept, so a
  // claim never repeats early because its snapshot was dropped. With one
  // ordinary Insight per 7 days that is at most four.
  final now = _key(_utcDay(i.today));
  bool cooling(InsightSnapshot s) =>
      s.family.isOrdinary &&
      daysBetween(s.generatedOn, now) < insightRepeatDays;
  final order = [...snapshots]
    ..sort((a, b) {
      final d = a.generatedOn.compareTo(b.generatedOn);
      return d != 0 ? d : snapshots.indexOf(a).compareTo(snapshots.indexOf(b));
    });
  final drop = <InsightSnapshot>{};
  for (final s in order) {
    if (snapshots.length - drop.length <= maxInsightSnapshots) break;
    if (identical(s, keep) || cooling(s)) continue;
    drop.add(s);
  }
  return [
    for (final s in snapshots)
      if (!drop.contains(s)) s,
  ];
}
