/// The words Circle Plans use, in one place (ADR-024 §4 — founder-approved
/// launch copy). Plans are counted in Circles on days the user chooses
/// their need: never days, streaks, scores or "completed".
library;

import '../../home/application/activity_catalog.dart';
import '../../home/domain/recommendation_engine.dart';
import 'circle_plan.dart';
import 'plan_stage_provenance.dart';

abstract final class PlanCopy {
  // The Plans page.
  static const title = 'Plans';
  static const subtitle = 'Where your next few Circles are going.';
  static const intro =
      'A Plan gives your next few Circles for one need a direction. On days '
      'you choose something else, it waits.';
  static const yourPlan = 'Your Plan';
  static const otherPlans = 'Other Plans';
  static const allPlans = 'Plans';
  static const stagesHeading = 'The five stages';

  /// Free (ADR-024 §4).
  static const free =
      'Plans run with Premium. Each one is five Circles with a direction, on '
      'the days you choose its need.';

  /// Each Plan's purpose and card line (ADR-024 §4).
  static const purpose = {
    'getting_going':
        'A few Circles that try different ways of getting moving, at home and '
        'outside, and end with a mix of what suited you.',
    'making_room':
        'A few Circles that make a little room — on paper, around you and in '
        'what comes in — and end with a mix of what suited you.',
    'slowing_down':
        'A few unhurried Circles — something in your hands, an easy stretch, '
        'something quiet, a slower place — that end with a mix of what '
        'suited you.',
  };
  static const card = {
    'getting_going': 'From a stretch at home to time outside, in five Circles.',
    'making_room': 'Paper, then a space, then one thing — in five Circles.',
    'slowing_down':
        'Hands, body, quiet, then a slower place — in five Circles.',
  };

  /// Each stage's Today line (ADR-024 §4) — stage 5's is [stageFiveLine].
  static const todayLine = {
    'getting_going.1': 'Start small: a stretch at home.',
    'getting_going.2': 'One part that keeps you on your feet for a while.',
    'getting_going.3': 'Two kinds of moving, one after the other.',
    'getting_going.4': 'Take it outside: a walk, or air at an open door.',
    'making_room.1': 'Everything on your mind onto paper. No sorting yet.',
    'making_room.2': 'Clear one space around you.',
    'making_room.3': 'Narrow it down to one thing.',
    'making_room.4': 'Screens down, and just one thing coming in.',
    'slowing_down.1': 'Something warm, or one small thing to look after.',
    'slowing_down.2': 'An easy stretch, only as far as is comfortable.',
    'slowing_down.3': 'One quiet thing to listen to or read.',
    'slowing_down.4': 'Somewhere slower: outside, or by an open door.',
  };

  /// The stage-5 lines (ADR-024 §4, §7).
  static const stageFiveMix = 'A mix of this Plan’s earlier stages.';
  static String stageFiveLed(String stage) =>
      'Built around $stage, which you said was useful.';
  static const stageFiveTogether = 'The stages you said were useful, together.';

  // Plan-page copy (ADR-024 §4).
  static String ready(Intention need) =>
      'Five Circles on days you choose ${intentionLabel(need)}. It waits on '
      'other days.';
  static String stageHeading(int number, String stage) =>
      'Stage $number of 5 · $stage';
  static String next(Intention need) =>
      'Next time you choose ${intentionLabel(need)}, your Circle follows this '
      'stage.';
  static const today = 'Today’s Circle follows this stage.';
  static String waitingOtherNeed(Intention need) =>
      'Waiting for your next ${intentionLabel(need)} day.';
  static const waitingFit =
      'Today’s Circle couldn’t follow this stage honestly, so it waits.';
  static String paused(int stage) =>
      'Paused at stage $stage. It stays here until you carry on.';
  static String lapsed(int stage) =>
      'Saved at stage $stage. It carries on with Premium.';
  static String reachedEnd(int guided, int setAside) => guided == 5
      ? 'This Plan has reached its end. All five stages guided.'
      : 'This Plan has reached its end: ${_stages(guided)} guided, '
            '${_stages(setAside)} set aside.';
  static const endedWithoutRecord = 'This Plan has reached its end.';
  static String left(int guided, int setAside) =>
      'You left this Plan: ${_stages(guided)} guided, ${_stages(setAside)} '
      'set aside.';
  static const allSetAside =
      'Every stage of this Plan uses parts you’ve left out or asked THIRTY not '
      'to suggest.';
  static String revisitPending(String stage) => '$stage again next time.';

  /// Set aside, and why — the user's own control, never blamed (ADR-024 §4).
  static String setAsideLeftOut(String part) =>
      'Set aside this time: it’s built around $part, which you’ve asked '
      'THIRTY to leave out.';
  static String setAsideResting(String part, String? since) => since == null
      ? 'Set aside this time: it’s built around $part, which is resting after '
            'you said it wasn’t useful.'
      : 'Set aside this time: it’s built around $part, which is resting after '
            'you said it wasn’t useful on $since.';
  static String setAsideNotSuggested(String part) =>
      'Set aside this time: it’s built around $part, which you asked THIRTY '
      'not to suggest.';

  // Actions.
  static const start = 'Start this Plan';
  static const startWithPremium = 'Start with Premium';
  static const continueWithPremium = 'Carry on with Premium';
  static const carryOn = 'Carry on';
  static const pause = 'Pause';
  static const leave = 'Leave this Plan';
  static const goToToday = 'Go to Today';
  static const openToday = 'Open today’s Circle';
  static const revisit = 'This stage again next time';
  static const seeReview = 'See what you told THIRTY';
  static const leaveTitle = 'Leave this Plan?';
  static const leaveBody =
      'Its Circles stay in your history. You can start it again from stage 1.';
  static const leaveCancel = 'Stay';
  static String switchBody(String starting, String pausing, int stage) =>
      'Starting $starting will pause $pausing at stage $stage. You can come '
      'back to it later.';
  static const switchTitle = 'Start another Plan?';
  static const switchCancel = 'Not now';

  // Stage status in the arc — never "done" or "completed".
  static String guidedOn(String date) => 'Guided $date';
  static const setAside = 'Set aside';
  static const nextStage = 'Next';
  static const againNext = 'Again next time';

  // The review (ADR-024 §6–§7, C7).
  static const reviewHeading = 'What you told THIRTY';
  static String earlierReviewHeading(int cycle) =>
      'What you told THIRTY · cycle $cycle';

  // I2's setting (B6): a fact, and the way back.
  static const gentlerNote = 'Circles in this cycle are being kept gentler.';
  static const usualPacing = 'Use usual pacing';
  static const noAnswers =
      'You didn’t answer after these Circles, so THIRTY can’t say which '
      'stages suited you.';
  static String onePositive(String stage) => 'You said $stage was useful.';
  static const othersUnanswered = 'You didn’t answer after the others.';
  static String wasNot(String stage) => 'You said $stage wasn’t.';
  static String severalPositive(List<String> stages) =>
      'You said these stages were useful: ${_list(stages)}.';
  static const allRejected =
      'You said none of these stages was useful, so THIRTY hasn’t made a last '
      'Circle from them.';
  static String answer(PastUsefulness? answer) => switch (answer) {
    PastUsefulness.veryUseful => 'Very useful',
    PastUsefulness.somewhatUseful => 'Somewhat useful',
    PastUsefulness.notUseful => 'Not useful',
    null => 'No answer',
  };
  static String youSaid(PastUsefulness answer) =>
      'You said ${PlanCopy.answer(answer).toLowerCase()}';
  static const comparedHeading = 'Compared with last time';
  static String bothTimes(String stage, PastUsefulness answer) =>
      '$stage · ${PlanCopy.answer(answer)} both times.';
  static String lastTimeThisTime(
    String stage,
    PastUsefulness last,
    PastUsefulness now,
  ) =>
      '$stage · ${PlanCopy.answer(last)} last time, '
      '${PlanCopy.answer(now).toLowerCase()} this time.';
  static String skipped(List<String> parts) => 'Skipped: ${parts.join(', ')}';

  // Review actions (ADR-024 §4).
  static const keepOne = 'Keep one of these Circles';
  static const goThroughAgain = 'Go through it again';
  static const chooseAnother = 'Choose another Plan';
  static const enough = 'That’s enough for now';
  static const keepTitle = 'Keep one of these Circles';
  static const keepNote =
      'Kept Circles stay yours, with or without Premium. You’ll find it in '
      'Yours, under You.';
  static const inYours = 'In Yours';

  // Today, after a Plan reached its end (no force-navigation).
  static const endedToday = 'Your Plan has reached its end.';
  static const reviewInPlans = 'Review in Plans';

  /// The Today card's label for a stage Circle: "Getting going · Stage 2 of
  /// 5", read as "Getting going, stage 2 of 5".
  static String todayLabel(PlanStageProvenance stage) =>
      '${circlePlanById[stage.planId]!.name} · Stage ${stage.stageNumber} of 5';
  static String todaySpokenLabel(PlanStageProvenance stage) =>
      '${circlePlanById[stage.planId]!.name}, stage ${stage.stageNumber} of 5';

  /// The Today card's line for a stage Circle: the stage's own line, or
  /// stage 5's — chosen from what this Circle combines and what the user
  /// said about those stages, so it never claims more than is true.
  static String todayStageLine(
    PlanStageProvenance stage, {
    required PlanCycle? cycle,
    required StageAnswers answers,
  }) {
    if (stage.stageNumber < 5) return todayLine[stage.stageId]!;
    final plan = circlePlanById[stage.planId]!;
    final positive = [
      for (final id in stage.drawsOn)
        if (cycle != null && _positive(plan, cycle, id, answers))
          plan.stages.firstWhere((s) => s.id == id).name,
    ];
    if (positive.length >= 2) return stageFiveTogether;
    if (positive.length == 1) return stageFiveLed(positive.single);
    return stageFiveMix;
  }

  static bool _positive(
    CirclePlanDefinition plan,
    PlanCycle cycle,
    String stageId,
    StageAnswers answers,
  ) {
    final stage = plan.stages.firstWhere((s) => s.id == stageId);
    final facts = cycleFacts(
      plan,
      cycle,
      answers,
    ).firstWhere((f) => f.stage.number == stage.number);
    return facts.answer == PastUsefulness.veryUseful ||
        facts.answer == PastUsefulness.somewhatUseful;
  }

  static String _stages(int n) => n == 1 ? '1 stage' : '$n stages';

  static String _list(List<String> items) => switch (items) {
    [final one] => one,
    [...final rest, final last] => '${rest.join(', ')} and $last',
    _ => '',
  };
}

const _shortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// A `YYYY-MM-DD` local date as "12 Oct"; anything else as stored.
String planShortDate(String localDate) {
  final parts = localDate.split('-');
  if (parts.length != 3) return localDate;
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (month == null || day == null || month < 1 || month > 12) {
    return localDate;
  }
  return '$day ${_shortMonths[month - 1]}';
}
