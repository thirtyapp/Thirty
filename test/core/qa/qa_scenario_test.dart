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
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/toolkit/application/toolkit_provider.dart';
import 'package:thirty/features/toolkit/domain/maintenance.dart';
import 'package:thirty/features/toolkit/domain/module_library.dart';
import 'package:thirty/features/toolkit/domain/path_catalog.dart';
import 'package:thirty/features/toolkit/domain/toolkit_model.dart';

/// QA-1 — each synthetic scenario, built through the production Circle and
/// Toolkit notifiers, then opened on the reference day exactly as the
/// harness would open it. The V2 Phase D group is the founder's Premium
/// proofs, checked here before they are walked on the S25.
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

  test('only d_lapsed fixes its entitlement (inactive)', () {
    for (final scenario in QaScenario.values) {
      expect(
        scenario.fixedEntitlement,
        scenario == QaScenario.dLapsed ? QaEntitlement.inactive : isNull,
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
      'd_first_path',
      'd_path_under_way',
      'd_path_adapted',
      'd_path_review',
      'd_routine_saved',
      'd_routine_daily_pick',
      'd_routine_piece_resting',
      'd_routine_rest_lifted',
      'd_week7_time_misfit',
      'd_fading',
      'd_tune_up_under_way',
      'd_tune_up_review',
      'd_stable_check',
      'd_lapsed',
      'd_month_two',
      'd_gap',
      'd_served_well',
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

  ToolkitState toolkitOf(ProviderContainer c) => c.read(toolkitProvider);

  group('V2 Phase D — Premium proofs', () {
    test('new_user: nothing built, nothing claimed', () async {
      final c = await open(QaScenario.newUser);
      addTearDown(c.dispose);
      expect(toolkitOf(c).isEmpty, isTrue);
      expect(c.read(maintenanceOffersProvider), isEmpty);
      expect(c.read(toolkitCheckProvider), isNull);
    });

    test('B — d_first_path: the first Path is seeded from Free evidence: '
        'Move to music, found very useful, comes first', () async {
      final c = await open(QaScenario.dFirstPath);
      addTearDown(c.dispose);
      expect(toolkitOf(c).path, isNull);
      expect(
        c
            .read(toolkitProvider.notifier)
            .startBuild(PathTemplateId.wakeUpIndoors),
        PathStart.started,
      );
      final run = toolkitOf(c).path!;
      expect(run.seed, SeedReason.usefulModule);
      expect(run.pool.first, ModuleId.musicMove);
      final step = c.read(nextPathStepProvider)!;
      expect(
        step.explanation,
        'You’ve found this useful before, so it comes first.',
      );
    });

    test("C/D — d_path_under_way: today's More Energy Circle is Circle 3, "
        'and it keeps the piece found useful', () async {
      final c = await open(QaScenario.dPathUnderWay);
      addTearDown(c.dispose);
      final run = toolkitOf(c).path!;
      expect(run.circles, hasLength(2));
      // A Clearer Head day in between left the Path where it was.
      final journal = journalOf(c);
      expect(journal.last.direction, Intention.clearerHead);
      expect(journal.last.session, isNull);

      c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      final today = c.read(recommendationProvider).recommendation!;
      expect(today.session?.pathCircle, 3);
      expect(today.activity, 'Move to music');
      expect(today.why, 'You found this useful, so here it is in full.');
      expect(today.offeredMinutes, 10);
    });

    test('E — "Not this one today" on a Path step: the engine replaces it, '
        'and the Path waits', () async {
      final c = await open(QaScenario.dPathUnderWay);
      addTearDown(c.dispose);
      final circle = c.read(recommendationProvider.notifier);
      circle.chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      expect(circle.replaceToday(ReplacementReason.notFeeling), isTrue);
      final today = c.read(recommendationProvider).recommendation!;
      expect(today.session?.isPath ?? false, isFalse);
      expect(today.replacedFromTitle, 'Move to music');
      circle.start();
      circle.close();
      await Future<void>.delayed(Duration.zero);
      expect(toolkitOf(c).path!.circles, hasLength(2));
    });

    test('D — d_path_adapted: Circle 4 turned down, so Circle 5 tries '
        'another partner', () async {
      final c = await open(QaScenario.dPathAdapted);
      addTearDown(c.dispose);
      expect(toolkitOf(c).path!.circles, hasLength(4));
      final step = c.read(nextPathStepProvider)!;
      expect(step.number, 5);
      expect(step.reason, PathStepReason.alternateAfterNegative);
      expect(step.composition.modules, {
        ModuleId.musicMove,
        ModuleId.activeTask,
      });
      expect(
        step.explanation,
        'That pairing didn’t suit you, so this tries another.',
      );

      // On an about-20 day it runs in its shorter form, and still says why
      // it changed: the answer outranks the time line (S25 finding).
      c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      final today = c.read(recommendationProvider).recommendation!;
      expect(today.offeredMinutes, lessThan(step.composition.minutes));
      expect(today.why, step.explanation);
    });

    test('F — d_path_review: seven Circles; the review proposes the routine '
        'and claims only what the answers support', () async {
      final c = await open(QaScenario.dPathReview);
      addTearDown(c.dispose);
      final run = toolkitOf(c).path!;
      expect(run.finished, isTrue);
      final proposal = c.read(pathProposalProvider)!;
      expect(proposal.composition.modules, {
        ModuleId.standingStretch,
        ModuleId.musicMove,
      });
      expect(proposal.composition.minutes, 15);
      expect(proposal.shorter?.minutes, 10);
      expect(proposal.facts.answeredForResult, 4);
      expect(proposal.facts.positiveForResult, 4);
      // Until kept, nothing is in the Toolkit.
      expect(toolkitOf(c).routines, isEmpty);
    });

    test("G — d_routine_saved: the routine is the user's, with a shorter "
        'version from the Path', () async {
      final c = await open(QaScenario.dRoutineSaved);
      addTearDown(c.dispose);
      final routine = toolkitOf(c).routines.single;
      expect(routine.name, 'My pick-me-up');
      expect(routine.active.minutes, 15);
      expect(routine.shortVersion?.minutes, 10);
      expect(toolkitOf(c).path, isNull);
    });

    test('H — d_routine_daily_pick: an ordinary More Energy day offers the '
        'routine — on its evidence, no Premium bonus', () async {
      final c = await open(QaScenario.dRoutineDailyPick);
      addTearDown(c.dispose);
      c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      final today = c.read(recommendationProvider).recommendation!;
      expect(today.session?.routineId, toolkitOf(c).routines.single.id);
      expect(today.reason, RecommendationReason.usefulHere);
      expect(today.sessionDefinition.steps, isNotEmpty);
    });

    test(
      'H2 — d_routine_piece_resting: Move to music, a piece of the '
      'routine, is resting after "Not useful" — Memory says so, and Today '
      'never brings it back inside the routine; Free picks normally',
      () async {
        final c = await open(QaScenario.dRoutinePieceResting);
        addTearDown(c.dispose);
        final routine = toolkitOf(c).routines.single;
        expect(
          routine.active.composition.modules,
          contains(ModuleId.musicMove),
        );
        c
            .read(recommendationProvider.notifier)
            .chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
        final today = c.read(recommendationProvider).recommendation!;
        expect(today.session?.routineId, isNull);
        expect(today.activityId, isNot(ActivityId.moveToMusic));
      },
    );

    test('H3 — d_routine_rest_lifted: "Suggest again" lifted that rest — the '
        'routine is today\'s pick again', () async {
      final c = await open(QaScenario.dRoutineRestLifted);
      addTearDown(c.dispose);
      c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      final today = c.read(recommendationProvider).recommendation!;
      expect(today.session?.routineId, toolkitOf(c).routines.single.id);
    });

    test('I — d_week7_time_misfit: about 20 minutes most days lately: the '
        'one offer is a shorter version — and it is still the same routine, '
        'every piece in its authored short form', () async {
      final c = await open(QaScenario.dWeek7TimeMisfit);
      addTearDown(c.dispose);
      final offer = c.read(primaryOfferProvider)!;
      expect(offer.kind, OfferKind.timeMisfit);
      expect(offer.targetMinutes, 20);
      final routine = toolkitOf(c).routines.single;
      expect(routine.name, 'My reset');
      expect(routine.shortVersion, isNull);
      expect(routine.active.minutes, 30);
      expect(
        offer.evidence,
        'You’ve had about 20 minutes most days lately, and My reset takes 30.',
      );
      // Try it: the shorter Path's first Circle is the same pieces, short.
      expect(
        c.read(toolkitProvider.notifier).startShorter(routine.id, 20),
        PathStart.started,
      );
      final step = c.read(nextPathStepProvider)!;
      expect(step.composition.minutes, 20);
      expect(
        [for (final u in step.composition.uses) u.module],
        [for (final u in routine.active.composition.uses) u.module],
      );
      expect(step.composition.uses.every((u) => u.short), isTrue);
    });

    test('N2 — d_served_well: Clearer Head chosen as often, but every Free '
        'pick "Somewhat useful": Free serves it — no gap offer', () async {
      final c = await open(QaScenario.dServedWell);
      addTearDown(c.dispose);
      expect(c.read(maintenanceOffersProvider), isEmpty);
    });

    test('J — d_fading: a routine that used to suit, suiting less well '
        'lately: a tune-up is offered', () async {
      final c = await open(QaScenario.dFading);
      addTearDown(c.dispose);
      final offer = c.read(primaryOfferProvider)!;
      expect(offer.kind, OfferKind.fading);
      expect(offer.evidence, 'My pick-me-up hasn’t suited you as well lately.');
    });

    test("J2 — d_tune_up_under_way: two Circles in; today's More Energy "
        'Circle is its Circle 3', () async {
      final c = await open(QaScenario.dTuneUpUnderWay);
      addTearDown(c.dispose);
      final run = toolkitOf(c).path!;
      expect(run.kind, PathKind.tuneUp);
      expect(run.circles, hasLength(2));
      expect(c.read(nextPathStepProvider)!.number, 3);
    });

    test('J3 — d_tune_up_review: keeping it makes version 2 the one THIRTY '
        'uses, and keeps version 1', () async {
      final c = await open(QaScenario.dTuneUpReview);
      addTearDown(c.dispose);
      expect(toolkitOf(c).path!.finished, isTrue);
      final kept = c.read(toolkitProvider.notifier).keepProposal()!;
      expect(kept.versions.length, greaterThanOrEqualTo(2));
      expect(kept.active.number, kept.versions.last.number);
      expect(kept.active.origin, VersionOrigin.tuneUp);
      expect(kept.versions.first.origin, VersionOrigin.path);
    });

    test('K — d_stable_check: four weeks of steady answers: nothing to '
        'change, and nothing invented', () async {
      final c = await open(QaScenario.dStableCheck);
      addTearDown(c.dispose);
      expect(c.read(maintenanceOffersProvider), isEmpty);
      final check = c.read(toolkitCheckProvider)!;
      expect(check.state, CheckState.stable);
      expect(
        check.message,
        'Your routines are working well — nothing to change.',
      );
    });

    test('L — d_lapsed: the routine stays usable in Free; the second Path is '
        'saved and does not claim the day', () async {
      final c = await open(QaScenario.dLapsed);
      addTearDown(c.dispose);
      expect(c.read(premiumEntitlementProvider), isFalse);
      final toolkit = toolkitOf(c);
      expect(toolkit.routines.single.name, 'My pick-me-up');
      expect(toolkit.path?.template, PathTemplateId.clearTheDecks);
      expect(toolkit.path!.circles, hasLength(2));
      // Paid operations stop.
      expect(
        c
            .read(toolkitProvider.notifier)
            .startTuneUp(toolkit.routines.single.id),
        PathStart.notEntitled,
      );
      // A Clearer Head day is a Free day: the Path waits.
      c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.clearerHead, window: TimeWindow.upTo30);
      expect(
        c.read(recommendationProvider).recommendation!.session?.isPath ?? false,
        isFalse,
      );
      // Ownership stays.
      c
          .read(toolkitProvider.notifier)
          .rename(toolkit.routines.single.id, 'Mornings');
      expect(toolkitOf(c).routines.single.name, 'Mornings');
    });

    test('L — restored: the same Path resumes exactly where it was', () async {
      final store = await build(QaScenario.dLapsed);
      final c = ProviderContainer(
        overrides: [
          ...qaContainerOverrides(
            genuinePreferences: genuine,
            supabaseAvailable: false,
            session: QaSession(
              entitlement: QaEntitlement.active,
              scenario: QaScenario.dLapsed,
              store: store,
            ),
          ),
          nowProvider.overrideWithValue(reference),
          eventClockProvider.overrideWithValue(() => reference),
        ],
      );
      addTearDown(c.dispose);
      await c.read(entitlementStatusProvider.notifier).initialize();
      expect(c.read(premiumEntitlementProvider), isTrue);
      c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.clearerHead, window: TimeWindow.upTo30);
      final today = c.read(recommendationProvider).recommendation!;
      expect(today.session?.pathCircle, 3);
      expect(toolkitOf(c).path!.circles, hasLength(2));
    });

    test('M — d_month_two: two routines, a shorter version, ordinary use — '
        'and no new content needed', () async {
      final c = await open(QaScenario.dMonthTwo);
      addTearDown(c.dispose);
      final routines = toolkitOf(c).routines;
      expect(routines.map((r) => r.name), ['My pick-me-up', 'My desk reset']);
      expect(routines.first.shortVersion, isNotNull);
      expect(routines.first.shortVersion!.minutes, lessThanOrEqualTo(10));
      // The desk reset's shorter version, from the time misfit: both its
      // pieces, each short — the same routine.
      final reset = routines.last;
      expect(reset.shortVersion, isNotNull);
      expect(
        reset.shortVersion!.composition.modules,
        reset.active.composition.modules,
      );
      expect(reset.shortVersion!.minutes, lessThanOrEqualTo(20));
      expect(toolkitOf(c).path, isNull);
      final offers = c.read(maintenanceOffersProvider);
      expect(offers.where((o) => o.kind == OfferKind.gap), isEmpty);
    });

    test('N — d_gap: Clearer Head chosen often, no routine for it: a build '
        'is offered — one, bounded', () async {
      final c = await open(QaScenario.dGap);
      addTearDown(c.dispose);
      final offer = c.read(primaryOfferProvider)!;
      expect(offer.kind, OfferKind.gap);
      expect(offer.need, Intention.clearerHead);
      expect(offer.template, PathTemplateId.clearTheDecks);
    });
  });
}
