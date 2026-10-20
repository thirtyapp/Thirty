import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/stage_brief.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/presentation/plan_view.dart';

/// ADR-024 B8 — Delete Circle history in the middle of long histories, and
/// what happens after it (contract, Delete / Export): the journal and
/// everything derived from it go — Insight snapshots, stage evidence,
/// reviews, why and when a cycle ended — while each Plan's place and
/// settings, a Leave the user chose, kept Circles and explicit preferences
/// stay. Then the product carries on, and nothing deleted is rebuilt.
///
/// Delete runs the same steps, in the same order, as
/// `JournalDataControls.confirmAndClear` (its dialog and UI path are tested
/// in `circle_plan_today_test.dart` 45–46 and `delete_circle_history_test`).
/// Every day is a fresh container on the stored data — a restart — so no
/// in-memory cache can hide a stale value.
void main() {
  final start = DateTime(2026, 3, 2, 9);
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> settle() async {
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  ProviderContainer open(int day, {bool paid = true}) {
    final now = start.add(Duration(days: day));
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(now),
        eventClockProvider.overrideWithValue(
          () => now.add(const Duration(minutes: 40)),
        ),
        premiumEntitlementProvider.overrideWithValue(paid),
        safetyPendingAllowedProvider.overrideWithValue(false),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// One closed Circle on [day] for [need], with [answer].
  Future<Recommendation> circle(
    int day, {
    Intention need = Intention.moreEnergy,
    CircleUsefulnessResponse? answer,
  }) async {
    final c = open(day);
    final today = c.read(recommendationProvider.notifier);
    today.chooseIntention(need, window: TimeWindow.about20);
    final r = c.read(recommendationProvider).recommendation!;
    today.start();
    today.close();
    if (answer != null) {
      today.reportAttempt(CircleAttemptResponse.yes);
      today.reportUsefulness(answer);
    }
    await settle();
    return r;
  }

  /// Delete Circle history — `JournalDataControls.confirmAndClear`'s steps.
  Future<void> deleteHistory(int day) async {
    final c = open(day);
    final plans = c.read(circlePlansProvider.notifier);
    await c.read(circleJournalRepositoryProvider).clearAll();
    await clearRecordedCircleState(prefs);
    final forgotten = plans.forgetStageEvidence();
    final insights = c.read(insightsProvider.notifier).forgetAll();
    await forgotten;
    await insights;
    await settle();
  }

  PlanProgress progress(int day, [String id = 'getting_going']) =>
      open(day).read(circlePlansProvider).plans[id]!;

  test('active at stage 3 after weeks of history: the place, the cycle, '
      'kept Circles and leave-outs stay; the evidence goes; the next days '
      'build only on what is new', () async {
    var c = open(0);
    c.read(circlePlansProvider.notifier).start('getting_going');
    await settle();
    // Weeks of ordinary history on other needs, with answers.
    for (var d = 0; d < 30; d++) {
      await circle(
        d,
        need: d.isEven ? Intention.clearerHead : Intention.gentlerPace,
        answer: CircleUsefulnessResponse.veryUseful,
      );
    }
    // Two stage Circles with answers: the place reaches 3.
    final first = await circle(30, answer: CircleUsefulnessResponse.veryUseful);
    expect(first.composed!.stage!.stageNumber, 1);
    await circle(31, answer: CircleUsefulnessResponse.notUseful);
    c = open(32);
    c
        .read(keptCirclesProvider.notifier)
        .keepCircle(
          plan: first.composed!.plan,
          need: Intention.moreEnergy,
          circleId: dateKey(start.add(const Duration(days: 30))),
        );
    await c
        .read(suggestionPreferencesProvider.notifier)
        .leaveOut(ElementId.openWindow);
    // An Insight shown before the delete.
    c.read(insightsProvider.notifier).assess();
    await settle();
    final before = progress(32);
    expect(before.current.cursor, 3);
    expect(open(32).read(insightsProvider).snapshots, isNotEmpty);

    await deleteHistory(32);

    final after = progress(33);
    expect(after.current.cursor, 3);
    expect(after.current.id, before.current.id);
    expect(after.current.number, before.current.number);
    expect(after.current.startedOn, before.current.startedOn);
    expect(after.lifecycle, PlanLifecycle.active);
    expect(after.current.records, isEmpty);
    expect(after.lastAdvancedCircleId, isNull);
    c = open(33);
    expect(c.read(circleJournalRepositoryProvider).readAll(), isEmpty);
    expect(c.read(insightsProvider).snapshots, isEmpty);
    expect(c.read(keptCirclesProvider).kept, hasLength(1));
    expect(c.read(suggestionPreferencesProvider).leftOut, {
      ElementId.openWindow,
    });

    // The next More Energy day serves stage 3 — the place, not stage 1.
    final next = await circle(33);
    expect(next.composed!.stage!.stageNumber, 3);
    // Nothing deleted comes back: no pattern Insight until the new
    // evidence itself spans two weeks.
    for (var d = 34; d < 46; d++) {
      await circle(d);
      final added = open(d).read(insightsProvider.notifier).assess().added;
      expect(
        added.where((s) => s.family.isOrdinary),
        isEmpty,
        reason: 'day $d: an Insight from deleted evidence',
      );
      await settle();
    }
    // Stage 5 (reached meanwhile or next) treats stages 1–2 as unanswered:
    // their answers were deleted with the journal.
    final earlier = earlierStages(
      after.definition,
      progress(46).cycles.firstWhere((x) => x.id == before.current.id),
      stageAnswersFrom(
        open(46).read(circleJournalRepositoryProvider).readAll(),
      ),
    );
    expect(earlier[0].answer, isNull);
    expect(earlier[1].answer, isNull);
  });

  test('just before stage 5, with every stage answered "Very useful": after '
      'the delete, stage 5 is case A over unanswered stages — no "you found '
      'useful" claim survives', () async {
    final c = open(0);
    c.read(circlePlansProvider.notifier).start('getting_going');
    await settle();
    for (var d = 0; d < 4; d++) {
      final r = await circle(d, answer: CircleUsefulnessResponse.veryUseful);
      expect(r.composed!.stage!.stageNumber, d + 1);
    }
    expect(progress(4).current.cursor, 5);
    await deleteHistory(4);
    final five = await circle(5);
    final stage = five.composed!.stage!;
    expect(stage.stageNumber, 5);
    final progressNow = progress(6);
    final earlier = earlierStages(
      progressNow.definition,
      progressNow.current,
      const {},
    );
    expect(earlier.every((e) => e.answer == null && !e.setAside), isTrue);
    expect(
      stageFive(progressNow.definition.stage(5).id, earlier, start),
      isA<StageFiveBriefs>().having(
        (b) => b.basis,
        'basis',
        StageFiveBasis.noAnswers,
      ),
    );
    expect(stage.drawsOn.length, greaterThanOrEqualTo(1));
    expect(five.why.toLowerCase(), isNot(contains('useful')));
  });

  test('an ended cycle with its review: the review and its Insight go, and '
      'are never rebuilt; the Plan stays ended at its place', () async {
    final c = open(0);
    c.read(circlePlansProvider.notifier).start('getting_going');
    await settle();
    for (var d = 0; d < 5; d++) {
      await circle(d, answer: CircleUsefulnessResponse.somewhatUseful);
    }
    final ended = progress(5);
    expect(ended.lifecycle, PlanLifecycle.ended);
    expect(
      reviewOf(
        ended.definition,
        ended,
        stageAnswersFrom(
          open(5).read(circleJournalRepositoryProvider).readAll(),
        ),
      ),
      isNotNull,
    );
    open(5).read(insightsProvider.notifier).assess();
    await settle();
    expect(
      open(
        5,
      ).read(insightsProvider).snapshots.where((s) => !s.family.isOrdinary),
      hasLength(1),
    );

    await deleteHistory(5);

    final after = progress(6);
    expect(after.lifecycle, PlanLifecycle.ended);
    expect(after.cycles, hasLength(ended.cycles.length));
    // Ended, but why and when are no longer known: they came from the
    // deleted evidence.
    expect(after.current.end, CycleEnd.historyDeleted);
    expect(after.current.endedOn, isNull);
    expect(after.current.hasReview, isFalse);
    expect(reviewOf(after.definition, after, const {}), isNull);
    for (var d = 6; d < 20; d++) {
      expect(open(d).read(insightsProvider.notifier).assess().added, isEmpty);
      await settle();
    }
  });

  test('a Plan the user left: the Leave and its date survive; the review '
      'built from deleted evidence does not', () async {
    final c = open(0);
    c.read(circlePlansProvider.notifier).start('getting_going');
    await settle();
    for (var d = 0; d < 3; d++) {
      await circle(d, answer: CircleUsefulnessResponse.veryUseful);
    }
    expect(
      open(3).read(circlePlansProvider.notifier).leave('getting_going'),
      PlanActionResult.done,
    );
    await settle();
    final left = progress(4);
    expect(left.lifecycle, PlanLifecycle.left);
    expect(left.current.end, CycleEnd.left);
    expect(left.current.hasReview, isTrue);

    await deleteHistory(4);

    final after = progress(5);
    expect(after.lifecycle, PlanLifecycle.left);
    expect(after.current.end, CycleEnd.left);
    expect(after.current.endedOn, left.current.endedOn);
    expect(after.current.hasReview, isFalse);
    expect(reviewOf(after.definition, after, const {}), isNull);
  });

  test('the gentler setting — an applied setting — survives Delete; its '
      'evidence does not', () async {
    final c = open(0);
    final plans = c.read(circlePlansProvider.notifier);
    plans.start('getting_going');
    expect(plans.keepGentler('getting_going'), PlanActionResult.done);
    await settle();
    await circle(1);
    await deleteHistory(2);
    final after = progress(3);
    expect(after.current.gentlerSince, isNotNull);
    expect(after.current.records, isEmpty);
  });
}
