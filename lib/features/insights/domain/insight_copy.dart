/// The words an Insight is shown with (ADR-024 §11), version
/// [insightWordingVersion]. Facts only — what the user chose, skipped,
/// rated or left out, with every denominator — and co-occurrence, never
/// cause. No reason is ever given for a choice.
library;

import '../../home/application/activity_catalog.dart';
import '../../personal_circle/domain/circle_elements.dart';
import 'insight.dart';

abstract final class InsightCopy {
  // I1 — the Plan for your need.
  static String planForNeed(
    Intention need,
    int count,
    int of,
    String from,
    String to,
  ) =>
      'You chose ${intentionLabel(need)} on $count of your last $of Circles, '
      'between ${dayRange(from, to)}.';

  static String planStep(PlanStep step, String plan) => switch (step) {
    PlanStep.start => 'Start $plan',
    PlanStep.carryOn => 'Carry on with $plan',
    PlanStep.goThroughAgain => 'Go through $plan again',
  };

  // I2 — gentler Plan Circles.
  static String planPacing(String plan, int count, int of) =>
      'On $count of your last $of $plan days, you chose “Too much for today”.';

  static const keepGentler = 'Keep this Plan’s Circles gentler for now';

  // I3 — a part you skip.
  static String skippedPart(
    String part,
    int count,
    int of,
    String last, {
    required bool ofMore,
  }) =>
      'You skipped “$part” in $count of the ${ofMore ? 'last ' : ''}$of '
      'Circles it was part of, most recently on ${dayMonth(last)}.';

  static const leaveOut = 'Leave it out next time';
  static const keepIt = 'Keep it';

  // I4 — what your useful Circles shared.
  static String usefulInCommon(
    ElementKind kind,
    Intention need,
    int inUseful,
    int useful,
    int inOther,
    int other,
  ) {
    final n = intentionLabel(need);
    return '${kindLabel(kind)} was part of $inUseful of the $useful $n '
        'Circles you called useful, and $inOther of the $other other $n '
        'Circles in that time.';
  }

  static const keepCircle = 'Keep this Circle';
  static const usefulAlreadyWeighted =
      'Nothing to change — THIRTY already gives parts you’ve rated useful '
      'more weight.';

  // I5 — the Plan review (its words are the review's own, in Plans).
  static String planReview(String plan, String endedOn) =>
      '$plan: what you told THIRTY, ${dayMonth(endedOn)}.';

  // I6 — what's changed.
  static String whatsChanged(
    String from,
    String to,
    Intention earlier,
    int earlierCount,
    int earlierOf,
    Intention recent,
    int recentCount,
    int recentOf,
  ) =>
      'From ${dayRange(from, to, joiner: 'to')} you chose '
      '${intentionLabel(earlier)} most ($earlierCount of $earlierOf). In the '
      'last four weeks it’s been ${intentionLabel(recent)} ($recentCount of '
      '$recentOf).';

  static String alreadyYourPlan(String plan) =>
      'Nothing to change — $plan is already your Plan.';

  // ---------------------------------------------------------------------
  // The Insights page (B6). ADR-024 §12's maturity lines are frozen.

  static const title = 'Insights';
  static const subtitle = 'Your own record, and one useful change.';
  static const nowHeading = 'Now';
  static const circlesHeading = 'Your Circles';
  static const earlierHeading = 'Earlier';
  static const seeAsList = 'See as a list';
  static const seePremium = 'See Premium';
  static const notNow = 'Not now';
  static const reviewThisPlan = 'Review this Plan';
  static const seeThePlan = 'See the Plan';
  static const applied = 'Applied.';
  static const setAside = 'Set aside.';
  static const noLongerCurrent = 'No longer current.';
  static String showAllEarlier(int n) => 'Show all earlier ($n)';
  static const showFewer = 'Show fewer';

  /// Premium, no Circle yet (§12, Day 1).
  static const premiumDayOne =
      'THIRTY says nothing about patterns until your Circles span two '
      'weeks. Your calendar fills in as you go.';

  /// Premium, Circles spanning less than two weeks (§12, Week 1).
  static String premiumSoFar(int circles, int answers) =>
      'So far: ${_count(circles, 'Circle')}, ${_count(answers, 'answer')}. '
      'THIRTY looks for patterns once your Circles span two weeks.';

  /// Premium, enough Circles and nothing current — silence, said once.
  static const premiumQuiet = 'Nothing new stands out in your Circles now.';

  /// Free (§12): the job Premium does, never a sample.
  static const free =
      'With Premium, THIRTY looks at your own Circles and answers, and '
      'suggests one useful change when there’s enough to go on.';

  /// Free, no Circle yet (§12, Day 1).
  static const freeEmpty = 'Your Circles will appear here, date by date.';

  /// After Premium: what stays, and what Premium would do again.
  static const lapsed =
      'New Insights are part of Premium. What THIRTY showed you before '
      'stays here, and your calendar is always yours.';

  /// The Circles an Insight rests on, by their dates.
  static String basedOn(int circles, String from, String to) => circles == 1
      ? 'From your Circle on ${dayMonth(from)}.'
      : 'From $circles of your Circles, ${dayRange(from, to, joiner: 'to')}.';

  /// The family's own name, above its observation.
  static String familyName(InsightFamily family) => switch (family) {
    InsightFamily.planForNeed => 'The Plan for your need',
    InsightFamily.planPacing => 'Gentler Plan Circles',
    InsightFamily.skippedPart => 'A part you skip',
    InsightFamily.usefulInCommon => 'What your useful Circles shared',
    InsightFamily.planReview => 'A Plan review',
    InsightFamily.whatsChanged => 'What’s changed',
  };

  // What an application did — said once, plainly.
  static String nowYourPlan(String plan) => '$plan is your Plan now.';
  static const gentlerOn = 'This Plan’s Circles are being kept gentler.';
  static String leftOut(String part) =>
      '“$part” is left out. You can put it back in What THIRTY remembers.';
  static const alreadyInPlace = 'That’s already in place.';

  static String _count(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

  /// A plain name for what a main or second piece is — never a judgment.
  static String kindLabel(ElementKind kind) => switch (kind) {
    ElementKind.writing => 'Writing',
    ElementKind.tidying => 'Tidying',
    ElementKind.music => 'Music',
    ElementKind.walking => 'Walking',
    ElementKind.listening => 'Listening',
    ElementKind.reading => 'Reading',
    ElementKind.movement => 'Stretching',
    ElementKind.outdoors => 'Time outside',
    ElementKind.focus => 'One task at a time',
    ElementKind.looking => 'Looking far away',
    ElementKind.ritual => 'A slow drink',
    ElementKind.tending => 'Tending to one thing',
    ElementKind.sorting => 'Choosing one thing',
    ElementKind.planning => 'Writing a first step',
    ElementKind.stillness => 'Sitting still',
    ElementKind.screens => 'Setting screens aside',
    ElementKind.air => 'Fresh air',
    ElementKind.phone => 'Putting the phone down',
    ElementKind.orient => 'A comfortable spot',
  };

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static (int, int, int)? _ymd(String localDate) {
    final parts = localDate.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null || m < 1 || m > 12) return null;
    return (y, m, d);
  }

  /// [text] with each "14 October" kept on one line — for display only;
  /// what was stored is never rewritten.
  static String keepDatesTogether(String text) => text.replaceAllMapped(
    RegExp('(\\d{1,2}) (${_months.join('|')})'),
    (m) => '${m[1]}\u00A0${m[2]}',
  );

  /// "14 October".
  static String dayMonth(String localDate) => switch (_ymd(localDate)) {
    (_, final m, final d) => '$d ${_months[m - 1]}',
    null => localDate,
  };

  /// "2 and 27 October" · "28 September and 12 October" · with the years
  /// when they differ.
  static String dayRange(String from, String to, {String joiner = 'and'}) {
    final a = _ymd(from);
    final b = _ymd(to);
    if (a == null || b == null) return '$from $joiner $to';
    final (ya, ma, da) = a;
    final (yb, mb, db) = b;
    if (ya != yb) {
      return '$da ${_months[ma - 1]} $ya $joiner $db ${_months[mb - 1]} $yb';
    }
    if (ma != mb) {
      return '$da ${_months[ma - 1]} $joiner $db ${_months[mb - 1]}';
    }
    return '$da $joiner $db ${_months[mb - 1]}';
  }
}
