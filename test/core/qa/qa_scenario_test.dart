import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/qa/qa_container.dart';
import 'package:thirty/core/qa/qa_entitlement_gateway.dart';
import 'package:thirty/core/qa/qa_scenario.dart';
import 'package:thirty/core/qa/qa_shared_preferences.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_copy.dart';
import 'package:thirty/features/plans/presentation/plan_view.dart';

/// QA-1 — each synthetic scenario, built through the production Circle and
/// kept-Circle notifiers, then opened on the reference day exactly as the
/// harness would open it. The V2 Phase D2 group is the founder's Premium
/// proofs, checked here before they are walked on the S25. (Phase D's Path,
/// routine and maintenance proofs retired with those features, ADR-024.)
void main() {
  final reference = DateTime(2026, 10, 8, 10);
  late SharedPreferences genuine;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    genuine = await SharedPreferences.getInstance();
  });

  Future<QaSharedPreferences> build(QaScenario scenario) => buildQaStore(
    scenario: scenario,
    genuine: genuine,
    referenceNow: reference,
  );

  /// The harness's app container for [scenario] on the reference day.
  Future<ProviderContainer> open(
    QaScenario scenario, {
    QaEntitlement entitlement = QaEntitlement.active,
  }) async {
    final container = ProviderContainer(
      overrides: [
        ...qaContainerOverrides(
          genuinePreferences: genuine,
          supabaseAvailable: false,
          session: QaSession(
            entitlement: scenario.fixedEntitlement ?? entitlement,
            scenario: scenario,
            store: await build(scenario),
          ),
        ),
        nowProvider.overrideWithValue(reference),
        eventClockProvider.overrideWithValue(() => reference),
      ],
    );
    await container.read(entitlementStatusProvider.notifier).initialize();
    return container;
  }

  List<CircleJournalEntry> journalOf(ProviderContainer container) =>
      container.read(circleJournalRepositoryProvider).readAll();

  test('only the lapsed scenarios fix their entitlement (inactive)', () {
    for (final scenario in QaScenario.values) {
      expect(
        scenario.fixedEntitlement,
        scenario == QaScenario.d2Lapsed || scenario == QaScenario.e6Lapsed
            ? QaEntitlement.inactive
            : isNull,
      );
    }
  });

  test('scenario wire names are the ones the walkthrough uses', () {
    expect(QaScenario.values.map((s) => s.wireName), [
      'none',
      'new_user',
      'free_not_useful',
      'free_useful',
      'free_exploration',
      'free_secondary',
      'free_v1_history',
      'c_open_fresh',
      'c_open_ended',
      'c_open_running',
      'c_guided_first',
      'c_guided_middle',
      'c_guided_paused',
      'c_guided_ended',
      'c_paced_internal',
      'c_closed_no_answer',
      'c_closed_useful',
      'c_closed_not_useful',
      'c_memory_mixed',
      'c_memory_resting',
      'c_memory_not_suggested',
      'c_memory_rest_lifted',
      'c_memory_nothing_fits',
      'c_delete_keeps_preferences',
      'c_reset_preferences',
      'd2_first_premium',
      'd2_month',
      'd2_running',
      'd2_lapsed',
      'd2_back',
      'd3_plan_stage',
      'd3_plan_set_aside',
      'd4_plan_review',
      'd4_plan_review_unanswered',
      'd4_plan_review_none_useful',
      'e6_empty',
      'e6_calendar',
      'e6_early_week',
      'e6_skipped_part',
      'e6_pacing',
      'e6_useful_in_common',
      'e6_nothing_to_change',
      'e6_lapsed',
      'e6_plan_review',
    ]);
  });

  test('synthetic history never includes the reference day itself, so '
      "today's Circle is still open to walk — unless a V2 Phase C scenario "
      'sets today up on purpose', () async {
    for (final scenario in QaScenario.values) {
      if (qaTodayFor(scenario) != null) continue;
      final container = await open(scenario);
      addTearDown(container.dispose);
      expect(
        journalOf(container).map((e) => e.localDate),
        isNot(contains('2026-10-08')),
      );
      expect(
        container.read(recommendationProvider).recommendation,
        isNull,
        reason: scenario.wireName,
      );
    }
  });

  test('the same scenario and reference date always build the same '
      'store', () async {
    for (final scenario in QaScenario.values) {
      final first = (await build(scenario)).snapshot();
      final second = (await build(scenario)).snapshot();
      expect(second, first, reason: scenario.wireName);
    }
  });

  group('V2 Phase D2 — recurring Premium proofs', () {
    test('D2-A — d2_first_premium: two weeks of Free, then the first '
        'Personal Guided Circle is one choice away', () async {
      final c = await open(QaScenario.d2FirstPremium);
      addTearDown(c.dispose);
      expect(journalOf(c).every((e) => e.session == null), isTrue);
      c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.clearerHead, window: TimeWindow.about20);
      final today = c.read(recommendationProvider).recommendation!;
      expect(today.composed, isNotNull);
      expect(today.reason, RecommendationReason.personalCircle);
      expect(today.offeredMinutes, lessThanOrEqualTo(20));
    });

    test('D2-B — d2_month: composed days, a skip, a part left out, a kept '
        'Circle', () async {
      final c = await open(QaScenario.d2Month);
      addTearDown(c.dispose);
      final composed = journalOf(
        c,
      ).where((e) => e.session?.parts.isNotEmpty ?? false).toList();
      expect(composed.length, greaterThanOrEqualTo(15));
      expect(
        composed.where((e) => e.session!.skipped.isNotEmpty),
        hasLength(2),
        reason: 'one skip, one skip that also left the part out',
      );
      expect(
        c.read(suggestionPreferencesProvider).elementsLeftOut,
        hasLength(1),
      );
      expect(c.read(keptCirclesProvider).kept, hasLength(1));
      // A composed answer never becomes activity evidence.
      for (final entry in composed) {
        expect(pastCirclesFrom([entry]).single.composite, isTrue);
      }
    });

    test('D2-C — d2_running: today’s composed Circle on its second part, '
        'moving on by itself', () async {
      final c = await open(QaScenario.d2Running);
      addTearDown(c.dispose);
      final state = c.read(recommendationProvider);
      expect(state.status, RecommendationStatus.started);
      final composed = state.recommendation!.composed!;
      expect(composed.plan.parts, hasLength(4));
      final moment = state.partMomentAt(reference)!;
      expect(moment.position, 1);
      expect(state.recommendation!.sessionDefinition.steps, hasLength(4));
    });

    test('D2-D — d2_lapsed: Today is Free’s; the kept Circle is the user’s '
        'to use today', () async {
      final c = await open(QaScenario.d2Lapsed);
      addTearDown(c.dispose);
      final owned = c.read(keptCirclesProvider);
      expect(owned.kept, hasLength(1));
      final notifier = c.read(recommendationProvider.notifier);
      notifier.chooseIntention(
        Intention.gentlerPace,
        window: TimeWindow.about20,
      );
      expect(c.read(recommendationProvider).recommendation!.composed, isNull);
      expect(
        notifier.useOwnedToday(keptCircleId: owned.kept.single.id),
        UseTodayResult.used,
      );
      expect(
        c.read(recommendationProvider).recommendation!.composed!.isKept,
        isTrue,
      );
    });

    test('D2-E — d2_back: subscribed again, composition returns', () async {
      final c = await open(QaScenario.d2Back);
      addTearDown(c.dispose);
      c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.clearerHead, window: TimeWindow.about20);
      expect(
        c.read(recommendationProvider).recommendation!.composed,
        isNotNull,
      );
    });
  });

  group('ADR-024 B3 — Circle Plan proofs', () {
    test('D3-A — d3_plan_stage: More Energy steers stage 2, closing it '
        'moves the Plan on once; another need leaves it untouched', () async {
      final c = await open(QaScenario.d3PlanStage);
      addTearDown(c.dispose);
      final plans = c.read(circlePlansProvider);
      expect(plans.activePlanId, 'getting_going');
      expect(plans.active!.current.cursor, 2);
      final today = c.read(recommendationProvider.notifier);
      today.chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      final offer = c.read(recommendationProvider).recommendation!;
      expect(offer.composed!.stage!.stageNumber, 2);
      today.start();
      today.close();
      expect(c.read(circlePlansProvider).active!.current.cursor, 3);
      expect(c.read(keptCirclesProvider).kept, isNotEmpty, reason: 'Use it');

      final other = await open(QaScenario.d3PlanStage);
      addTearDown(other.dispose);
      other
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.gentlerPace, window: TimeWindow.about20);
      expect(
        other.read(recommendationProvider).recommendation!.composed!.stage,
        isNull,
      );
      expect(other.read(circlePlansProvider).active!.current.cursor, 2);
    });

    test('D3-A on INACTIVE: Free, the place kept', () async {
      final c = await open(
        QaScenario.d3PlanStage,
        entitlement: QaEntitlement.inactive,
      );
      addTearDown(c.dispose);
      c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      expect(c.read(recommendationProvider).recommendation!.composed, isNull);
      expect(c.read(circlePlansProvider).active!.current.cursor, 2);
    });

    test('D3-B — d3_plan_set_aside: at ≈10, Fresh air is set aside and '
        'stage 5 is today\'s Circle', () async {
      final c = await open(QaScenario.d3PlanSetAside);
      addTearDown(c.dispose);
      c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy, window: TimeWindow.about10);
      final stage = c
          .read(recommendationProvider)
          .recommendation!
          .composed!
          .stage!;
      expect(stage.stageNumber, 5);
      final cycle = c.read(circlePlansProvider).active!.current;
      expect(cycle.latest(4)!.outcome, StageOutcome.setAside);
      expect(cycle.cursor, 5);
    });

    test('D4-A — d4_plan_review: two real cycles of Making room, the second '
        'reviewed against the first, with Circles to keep', () async {
      final c = await open(QaScenario.d4PlanReview);
      addTearDown(c.dispose);
      final plan = c.read(circlePlansProvider).plans['making_room']!;
      expect(plan.lifecycle, PlanLifecycle.ended);
      expect(plan.cycles.map((x) => x.end), [
        CycleEnd.reachedEnd,
        CycleEnd.reachedEnd,
      ]);
      expect(plan.current.guidedStages, 5);
      final answers = stageAnswersFrom(
        c.read(circleJournalRepositoryProvider).readAll(),
      );
      final review = reviewOf(plan.definition, plan, answers)!;
      expect(review.summary.single, startsWith('You said these stages were'));
      expect(review.compared, isNotEmpty);
      expect(review.keepable, hasLength(5));
    });

    test('D4-B — d4_plan_review_unanswered: Slowing down through once with '
        'no answer — the review says so (case A)', () async {
      final c = await open(QaScenario.d4PlanReviewUnanswered);
      addTearDown(c.dispose);
      final plan = c.read(circlePlansProvider).plans['slowing_down']!;
      expect(plan.lifecycle, PlanLifecycle.ended);
      expect(plan.cycles.single.end, CycleEnd.reachedEnd);
      expect(plan.current.guidedStages, 5);
      final answers = stageAnswersFrom(
        c.read(circleJournalRepositoryProvider).readAll(),
      );
      final review = reviewOf(plan.definition, plan, answers)!;
      expect(review.summary, [PlanCopy.noAnswers]);
      expect(review.caseD, isFalse);
    });

    test('D4-C — d4_plan_review_none_useful: every stage said Not useful — '
        'no last Circle, and the review says why (case D)', () async {
      final c = await open(QaScenario.d4PlanReviewNoneUseful);
      addTearDown(c.dispose);
      final plan = c.read(circlePlansProvider).plans['making_room']!;
      expect(plan.lifecycle, PlanLifecycle.ended);
      expect(plan.cycles.single.end, CycleEnd.allRejected);
      expect(plan.current.guidedStages, 4);
      final answers = stageAnswersFrom(
        c.read(circleJournalRepositoryProvider).readAll(),
      );
      final review = reviewOf(plan.definition, plan, answers)!;
      expect(review.caseD, isTrue);
      expect(review.endLine, PlanCopy.allRejected);
    });
  });
}
