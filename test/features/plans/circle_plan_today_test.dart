import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/phase_d_retirement.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/application/v1_premium_retirement.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/domain/recommendation_policy.dart';
import 'package:thirty/features/home/presentation/widgets/journal_data_controls.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/stage_brief.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_stage_provenance.dart';

class _SettledEntitlement extends EntitlementNotifier {
  _SettledEntitlement(this._status);

  final EntitlementStatus _status;

  @override
  EntitlementStatus build() => _status;
}

/// ADR-024 B3 — Circle Plans on Today, through the production providers:
/// precedence, guided progression, feedback, "Not this one today", "Use it
/// today", lapse, persistence, export and delete, and the entitlement at
/// the service boundary.
void main() {
  final morning = DateTime(2026, 10, 12, 9);
  const energy = Intention.moreEnergy;
  const head = Intention.clearerHead;
  const gentle = Intention.gentlerPace;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// The app on day [day] after [morning].
  ProviderContainer open({bool entitled = true, int day = 0}) {
    final now = morning.add(Duration(days: day));
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(now),
        eventClockProvider.overrideWithValue(() => now),
        premiumEntitlementProvider.overrideWithValue(entitled),
        safetyPendingAllowedProvider.overrideWithValue(false),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> settle() async {
    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  CirclePlansNotifier plansOf(ProviderContainer c) =>
      c.read(circlePlansProvider.notifier);
  PlanCycle cycleOf(ProviderContainer c, String planId) =>
      c.read(circlePlansProvider).plans[planId]!.current;
  RecommendationNotifier today(ProviderContainer c) =>
      c.read(recommendationProvider.notifier);
  Recommendation offer(ProviderContainer c) =>
      c.read(recommendationProvider).recommendation!;

  /// Plans already under way: [plans], written as the app keeps them.
  Future<void> seed(CirclePlansState plans) =>
      prefs.setString(circlePlansKey, jsonEncode(plans.toJson()));

  /// [planId] started, then moved through stages up to [through] on
  /// earlier days by Circles `c<n>`.
  CirclePlansState under(String planId, {int through = 0}) {
    var s = CirclePlansState.empty.start(planId, today: '2026-10-01')!;
    for (var n = 1; n <= through; n++) {
      s = s.recordGuided(
        PlanStageProvenance(
          planId: planId,
          cycleId: '$planId#1',
          stageNumber: n,
          stageId: '$planId.$n',
        ),
        circleId: 'c$n',
        today: '2026-10-0$n',
        parts: const [],
        skipped: const [],
      );
    }
    return s;
  }

  /// Today's Circle, started and closed.
  Future<void> walk(ProviderContainer c) async {
    today(c).start();
    today(c).close();
    await settle();
  }

  group('Plan state (§6, through the notifier)', () {
    test(
      '1–7: start, pause, carry on, another Plan, leave, again, repeat',
      () async {
        final c = open();
        expect(plansOf(c).start('getting_going'), PlanActionResult.done);
        expect(cycleOf(c, 'getting_going').cursor, 1);
        // Starting writes no Circle and no history.
        expect(c.read(circleJournalRepositoryProvider).readAll(), isEmpty);
        expect(plansOf(c).pause('getting_going'), PlanActionResult.done);
        expect(plansOf(c).resume('getting_going'), PlanActionResult.done);
        expect(plansOf(c).start('slowing_down'), PlanActionResult.done);
        expect(
          c.read(circlePlansProvider).lifecycleOf('getting_going'),
          PlanLifecycle.paused,
        );
        expect(plansOf(c).leave('slowing_down'), PlanActionResult.done);
        expect(plansOf(c).start('slowing_down'), PlanActionResult.done);
        expect(cycleOf(c, 'slowing_down').id, 'slowing_down#2');
        expect(
          plansOf(c).goThroughAgain('slowing_down'),
          PlanActionResult.notAvailable,
          reason: 'only after an end or leaving',
        );
        await settle();
        // 41: kept across a restart.
        final again = open();
        expect(
          again.read(circlePlansProvider).toJson(),
          c.read(circlePlansProvider).toJson(),
        );
      },
    );
  });

  group('Today precedence (§6)', () {
    test('8. a matching need: the stage steers today\'s Circle, and its '
        'journal record says so', () async {
      await seed(under('slowing_down'));
      final c = open();
      today(c).chooseIntention(gentle, window: TimeWindow.about20);
      final composed = offer(c).composed!;
      expect(composed.stage!.planId, 'slowing_down');
      expect(composed.stage!.stageNumber, 1);
      expect(
        stageBriefById['slowing_down.1']!.accepts(
          composed.plan.parts,
          size: 20,
        ),
        isTrue,
      );
      await settle();
      final entry = c.read(circleJournalRepositoryProvider).readAll().single;
      expect(entry.session!.planStage!.stageId, 'slowing_down.1');
      expect(entry.schemaVersion, 2);
      // A restart restores the same stage Circle — never recomposed.
      final restarted = open();
      expect(offer(restarted).composed!.stage!.stageNumber, 1);
      expect(offer(restarted).composed!.plan, composed.plan);
    });

    test('9. another need: the ordinary Personal Guided Circle; the Plan '
        'is untouched', () async {
      await seed(under('slowing_down', through: 1));
      final c = open();
      final before = jsonEncode(c.read(circlePlansProvider).toJson());
      today(c).chooseIntention(energy, window: TimeWindow.about20);
      expect(offer(c).composed!.stage, isNull);
      expect(offer(c).reason, RecommendationReason.personalCircle);
      await walk(c);
      expect(jsonEncode(c.read(circlePlansProvider).toJson()), before);
    });

    test('10. wait: the ordinary Circle, the place unchanged', () async {
      // Yesterday's main piece was Tend to one thing, the only main piece
      // Slow hands has at ≈10.
      await seed(under('slowing_down'));
      final day0 = open();
      today(day0).chooseIntention(gentle, window: TimeWindow.about10);
      expect(offer(day0).composed!.plan.main.element, ElementId.tendOne);
      // Not started: the next day stage 1 is still due — and waits.
      final day1 = open(day: 1);
      final yesterday = PastCircle(
        date: morning,
        need: gentle,
        activityId: ActivityId.unhurriedTidyPause,
        catalogVersion: catalogVersion,
        components: const [ActivityId.unhurriedTidyPause],
        parts: offer(day0).composed!.plan.toWire(),
      );
      final waits = planToday(
        day1.read(circlePlansProvider),
        premium: true,
        context: ComposerContext(
          date: morning.add(const Duration(days: 1)),
          need: gentle,
          window: TimeWindow.about10,
        ),
        history: [yesterday],
        answers: const {},
      );
      expect(waits.circle, isNull);
      expect(waits.state.plans['slowing_down']!.current.cursor, 1);
    });

    test('11. set aside, then the next stage the same day', () async {
      await seed(under('getting_going', through: 3));
      final c = open();
      await c
          .read(suggestionPreferencesProvider.notifier)
          .leaveOut(ElementId.daylight);
      today(c).chooseIntention(energy, window: TimeWindow.about10);
      final stage = offer(c).composed!.stage!;
      expect(stage.stageNumber, 5);
      final cycle = cycleOf(c, 'getting_going');
      expect(cycle.latest(4)!.outcome, StageOutcome.setAside);
      expect(
        cycle.latest(4)!.setAsideBecause.single.reason,
        StageBlockReason.leftOut,
      );
      await settle();
      expect(
        open()
            .read(circlePlansProvider)
            .plans['getting_going']!
            .current
            .latest(4)!
            .outcome,
        StageOutcome.setAside,
        reason: 'kept',
      );
    });

    test('12. nothing left that honestly composes: the cycle ends at its '
        'review, today is the ordinary Circle', () async {
      await seed(under('getting_going', through: 4));
      // Every earlier stage was "Not useful" (case D).
      final journal = CircleJournalRepository(prefs);
      for (var n = 1; n <= 4; n++) {
        await journal.recordUsefulness(
          circleId: 'c$n',
          localDate: '2026-10-0$n',
          direction: energy,
          activityId: ActivityId.moveToMusic,
          response: CircleUsefulnessResponse.notUseful,
          respondedAt: DateTime(2026, 10, n, 18),
        );
      }
      final c = open();
      today(c).chooseIntention(energy, window: TimeWindow.about20);
      expect(offer(c).composed!.stage, isNull);
      expect(offer(c).reason, RecommendationReason.personalCircle);
      final plan = c.read(circlePlansProvider).plans['getting_going']!;
      expect(plan.lifecycle, PlanLifecycle.ended);
      expect(plan.current.end, CycleEnd.allRejected);
      expect(c.read(circlePlansProvider).activePlanId, isNull);
    });

    test('13. only an applicable Plan steers: not on Free, not paused, not '
        'ended', () async {
      await seed(under('slowing_down'));
      final free = open(entitled: false);
      today(free).chooseIntention(gentle, window: TimeWindow.about20);
      expect(offer(free).composed, isNull);

      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      await seed(under('slowing_down').pause('slowing_down')!);
      final paused = open();
      today(paused).chooseIntention(gentle, window: TimeWindow.about20);
      expect(offer(paused).composed!.stage, isNull);
    });

    test('14. "Use it today" wins: the kept Circle runs; the Plan neither '
        'moves nor is set aside', () async {
      await seed(under('making_room', through: 1));
      final c = open();
      c
          .read(keptCirclesProvider.notifier)
          .keepCircle(
            plan: CirclePlan.fromWire(const [
              'getItOut:6',
              'chooseOne:1',
              'clearCorner:8',
            ])!,
            need: head,
            circleId: '2026-10-01',
            name: 'My reset',
          );
      today(c).chooseIntention(head, window: TimeWindow.about20);
      expect(offer(c).composed!.stage!.stageNumber, 2);
      final before = jsonEncode(c.read(circlePlansProvider).toJson());
      expect(
        today(c).useOwnedToday(
          keptCircleId: c.read(keptCirclesProvider).kept.single.id,
        ),
        UseTodayResult.used,
      );
      expect(offer(c).composed!.isKept, isTrue);
      expect(offer(c).composed!.stage, isNull);
      await walk(c);
      expect(jsonEncode(c.read(circlePlansProvider).toJson()), before);
      final entry = c.read(circleJournalRepositoryProvider).readAll().single;
      expect(entry.session!.planStage, isNull, reason: 'not a stage Circle');
    });
  });

  group('guided: started and later closed (§6)', () {
    test('15–19. shown, started, closed, closed again, restarted', () async {
      await seed(under('getting_going'));
      // 15: shown, never started — the next matching day, still stage 1.
      final day0 = open();
      today(day0).chooseIntention(energy, window: TimeWindow.about20);
      await settle();
      expect(cycleOf(day0, 'getting_going').cursor, 1);
      final day1 = open(day: 1);
      today(day1).chooseIntention(energy, window: TimeWindow.about20);
      expect(offer(day1).composed!.stage!.stageNumber, 1);
      // 16: started, not closed.
      today(day1).start();
      await settle();
      expect(cycleOf(day1, 'getting_going').cursor, 1);
      // 19: a restart mid-Circle doesn't move it either.
      final restarted = open(day: 1);
      expect(cycleOf(restarted, 'getting_going').cursor, 1);
      expect(
        restarted.read(recommendationProvider).status,
        RecommendationStatus.started,
      );
      // 17: closed — guided, once.
      today(restarted).close();
      await settle();
      final cycle = cycleOf(restarted, 'getting_going');
      expect(cycle.cursor, 2);
      final record = cycle.latest(1)!;
      expect(record.outcome, StageOutcome.guided);
      expect(record.circleId, '2026-10-13');
      expect(record.parts, offer(restarted).composed!.plan.toWire());
      // 18: closed again, and a reopened app: no second move.
      today(restarted).close();
      plansOf(restarted).recordGuided(
        offer(restarted).composed!.stage!,
        circleId: '2026-10-13',
        parts: const [],
        skipped: const [],
      );
      await settle();
      final reopened = open(day: 1);
      expect(cycleOf(reopened, 'getting_going').cursor, 2);
      expect(cycleOf(reopened, 'getting_going').records, hasLength(1));
    });
  });

  group('feedback (C5, §6)', () {
    test('20–21. "Not useful" on a stage Circle: the Plan moves on, '
        'nothing rests, the answer is the user\'s', () async {
      await seed(under('slowing_down'));
      final c = open();
      today(c).chooseIntention(gentle, window: TimeWindow.about20);
      final plan = offer(c).composed!.plan;
      await walk(c);
      today(c).reportAttempt(CircleAttemptResponse.yes);
      today(c).reportUsefulness(CircleUsefulnessResponse.notUseful);
      await settle();
      expect(cycleOf(c, 'slowing_down').cursor, 2);
      final answers = stageAnswersFrom(
        c.read(circleJournalRepositoryProvider).readAll(),
      );
      expect(answers['2026-10-12'], PastUsefulness.notUseful);
      final facts = cycleFacts(
        circlePlanById['slowing_down']!,
        cycleOf(c, 'slowing_down'),
        answers,
      );
      expect(facts.first.answer, PastUsefulness.notUseful);
      // No rest: tomorrow its parts may be composed again.
      final next = open(day: 1);
      final memory = RecommendationMemory.of(
        morning.add(const Duration(days: 1)),
        next.read(pastCirclesProvider),
        RecommendationPolicy.initial,
      );
      for (final part in plan.substance) {
        expect(
          elementStanding(part.definition, gentle, memory).allowed,
          isTrue,
          reason: '${part.element}',
        );
      }
      // "Remove this answer" leaves no residue in the stage.
      today(c).removeAnswer('2026-10-12', includingAttempt: true);
      await settle();
      expect(
        stageAnswersFrom(c.read(circleJournalRepositoryProvider).readAll()),
        isEmpty,
      );
    });
  });

  group('"Not this one today" on a stage Circle (C4)', () {
    test('28. inside the stage first, as the same stage', () async {
      await seed(under('making_room', through: 1));
      final c = open();
      today(c).chooseIntention(head, window: TimeWindow.about20);
      final first = offer(c).composed!;
      expect(today(c).replaceToday(ReplacementReason.notFeeling), isTrue);
      final second = offer(c).composed!;
      expect(second.stage!.stageNumber, 2);
      expect(second.plan, isNot(first.plan));
      expect(
        stageBriefById['making_room.2']!.accepts(second.plan.parts, size: 20),
        isTrue,
      );
      // 31: once a day.
      expect(today(c).replaceToday(ReplacementReason.tooMuch), isFalse);
      await walk(c);
      expect(cycleOf(c, 'making_room').cursor, 3);
    });

    test('29. no Circle follows the stage: the ordinary Circle, and the '
        'stage waits', () async {
      await seed(under('getting_going'));
      final c = open();
      today(c).chooseIntention(energy, window: TimeWindow.about20);
      expect(offer(c).composed!.stage!.stageNumber, 1);
      // Loosen up has no other kind of main piece.
      expect(today(c).replaceToday(ReplacementReason.notFeeling), isTrue);
      expect(offer(c).composed!.stage, isNull);
      expect(offer(c).composed, isNotNull);
      await walk(c);
      expect(cycleOf(c, 'getting_going').cursor, 1, reason: 'it waits');
      expect(cycleOf(c, 'getting_going').records, isEmpty);
      final entry = c.read(circleJournalRepositoryProvider).readAll().single;
      expect(entry.session!.planStage, isNull);
    });

    test('30. nothing composes at all: Free\'s one activity', () async {
      await seed(under('getting_going'));
      final c = open();
      today(c).chooseIntention(energy, window: TimeWindow.about20);
      for (final id in ElementId.values) {
        await c.read(suggestionPreferencesProvider.notifier).leaveOut(id);
      }
      expect(today(c).replaceToday(ReplacementReason.tooMuch), isTrue);
      expect(offer(c).composed, isNull);
      expect(offer(c).replacedFrom, isNotNull);
      await walk(c);
      expect(cycleOf(c, 'getting_going').cursor, 1);
    });
  });

  group('revisit, live (§6)', () {
    test('32–33. served on the next matching day; the place stays', () async {
      await seed(under('slowing_down', through: 2));
      final c = open();
      expect(
        plansOf(c).requestRevisit('slowing_down', 1),
        PlanActionResult.done,
      );
      expect(
        plansOf(c).requestRevisit('slowing_down', 1),
        PlanActionResult.notAvailable,
      );
      today(c).chooseIntention(gentle, window: TimeWindow.about20);
      final stage = offer(c).composed!.stage!;
      expect((stage.stageNumber, stage.revisit), (1, true));
      await walk(c);
      final cycle = cycleOf(c, 'slowing_down');
      expect(cycle.cursor, 3);
      expect(cycle.pendingRevisit, isNull);
      final next = open(day: 1);
      today(next).chooseIntention(gentle, window: TimeWindow.about20);
      expect(offer(next).composed!.stage!.stageNumber, 3);
    });
  });

  group('lapse (§6, §13)', () {
    test('36–40. active → lapse → Free → resubscribe: the exact place, '
        'nothing retroactive', () async {
      await seed(under('getting_going', through: 1));
      final before = jsonEncode(
        CirclePlansState.fromJson(
          jsonDecode(prefs.getString(circlePlansKey)!),
        )!.toJson(),
      );
      // Lapsed: Free's Today; no steering, no progression.
      final lapsed = open(entitled: false);
      today(lapsed).chooseIntention(energy, window: TimeWindow.about20);
      expect(offer(lapsed).composed, isNull);
      await walk(lapsed);
      plansOf(lapsed).recordGuided(
        const PlanStageProvenance(
          planId: 'getting_going',
          cycleId: 'getting_going#1',
          stageNumber: 2,
          stageId: 'getting_going.2',
        ),
        circleId: '2026-10-12',
        parts: const [],
        skipped: const [],
      );
      expect(
        plansOf(lapsed).requestRevisit('getting_going', 1),
        PlanActionResult.needsPremium,
      );
      await settle();
      expect(jsonEncode(lapsed.read(circlePlansProvider).toJson()), before);
      // Still readable, still active, at stage 2.
      expect(cycleOf(lapsed, 'getting_going').cursor, 2);
      // Subscribed again: stage 2, where it was.
      final back = open(day: 1);
      today(back).chooseIntention(energy, window: TimeWindow.about20);
      expect(offer(back).composed!.stage!.stageNumber, 2);
      expect(cycleOf(back, 'getting_going').records, hasLength(1));
    });
  });

  group('the entitlement, at the service boundary', () {
    test('47. without Premium, nothing runs a Plan', () async {
      final c = open(entitled: false);
      expect(plansOf(c).start('getting_going'), PlanActionResult.needsPremium);
      expect(c.read(circlePlansProvider).plans, isEmpty);
      await seed(under('getting_going').pause('getting_going')!);
      final d = open(entitled: false);
      expect(plansOf(d).resume('getting_going'), PlanActionResult.needsPremium);
      expect(
        plansOf(d)
            .steerToday(
              ComposerContext(
                date: morning,
                need: energy,
                window: TimeWindow.about20,
              ),
              const [],
            )
            .circle,
        isNull,
      );
      // What the user saved stays theirs to put down.
      expect(plansOf(d).leave('getting_going'), PlanActionResult.done);
    });

    test('48. a grace or cancelled-but-paid period is an active '
        'entitlement: Plans run', () {
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          nowProvider.overrideWithValue(morning),
          entitlementStatusProvider.overrideWith(
            () => _SettledEntitlement(EntitlementStatus.active),
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(premiumEntitlementProvider), isTrue);
      expect(plansOf(c).start('making_room'), PlanActionResult.done);
    });
  });

  group('persistence', () {
    test('42–43. a store without Plans loads; a V1 Plan or a Phase D Path '
        'never becomes one', () async {
      SharedPreferences.setMockInitialValues({
        'plans_state_v1': '{"planId":"moreEnergyPath","stage":2}',
        'toolkit_v1': jsonEncode({
          'schemaVersion': 1,
          'path': {'id': 'path-1', 'need': 'moreEnergy'},
          'kept': <Object>[],
        }),
        circleJournalKey: jsonEncode({
          'schemaVersion': 1,
          'entries': [
            {
              'schemaVersion': 1,
              'circleId': '2026-10-01',
              'localDate': '2026-10-01',
              'direction': 'moreEnergy',
              'activityId': 'moveToMusic',
              'catalogVersion': catalogVersion,
              'shownAt': '2026-10-01T09:00:00.000',
              'planId': 'moreEnergyPath',
              'stageId': 'more_energy_2_develop',
            },
          ],
        }),
      });
      prefs = await SharedPreferences.getInstance();
      await retireV1Premium(prefs);
      await retirePhaseDPremium(prefs);
      final c = open();
      expect(c.read(circlePlansProvider).plans, isEmpty);
      expect(c.read(circlePlansProvider).activePlanId, isNull);
      // The version-1 journal still reads, its V1 record intact.
      final entries = c.read(circleJournalRepositoryProvider).readAll();
      expect(entries.single.planId, 'moreEnergyPath');
      expect(entries.single.session, isNull);
      // A first Premium Circle: ordinary, and the journal carries on.
      today(c).chooseIntention(energy, window: TimeWindow.about20);
      expect(offer(c).composed!.stage, isNull);
      await settle();
      final wrapper =
          jsonDecode(prefs.getString(circleJournalKey)!)
              as Map<String, Object?>;
      expect(wrapper['schemaVersion'], 2);
      expect(c.read(circleJournalRepositoryProvider).readAll(), hasLength(2));
    });

    test('an unreadable record is kept aside, never overwritten', () async {
      await prefs.setString(circlePlansKey, '{not json');
      final c = open();
      expect(c.read(circlePlansProvider).plans, isEmpty);
      await settle();
      expect(prefs.getString(circlePlansUnreadableKey), '{not json');
    });
  });

  group('export and delete (contract, Delete / Export)', () {
    test('44. the export carries each Plan\'s place, cycles and stage '
        'records', () async {
      await seed(under('making_room', through: 2));
      final c = open();
      today(c).chooseIntention(head, window: TimeWindow.about20);
      await walk(c);
      final exported =
          jsonDecode(
                c
                    .read(circleJournalRepositoryProvider)
                    .exportAsJson(
                      circlePlans: c.read(circlePlansProvider).toJson(),
                    ),
              )
              as Map<String, Object?>;
      final plans = exported['circlePlans'] as Map<String, Object?>;
      expect(plans['activePlanId'], 'making_room');
      final entry = (exported['entries'] as List).single as Map;
      expect((entry['session'] as Map)['planStage'], {
        'planId': 'making_room',
        'cycleId': 'making_room#1',
        'stageNumber': 3,
        'stageId': 'making_room.3',
      });
      expect(jsonEncode(plans), isNot(contains('score')));
    });

    testWidgets('45–46. Delete history: the journal and the stage evidence '
        'go; the place and kept Circles stay', (tester) async {
      await seed(under('slowing_down', through: 2));
      final c = open();
      await tester.runAsync(() async {
        c
            .read(keptCirclesProvider.notifier)
            .keepCircle(
              plan: CirclePlan.fromWire(const ['tendOne:8', 'sitAMinute:2'])!,
              need: gentle,
              circleId: '2026-10-01',
              name: 'Mine',
            );
        today(c).chooseIntention(gentle, window: TimeWindow.about20);
        await walk(c);
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => JournalDataControls.confirmAndClear(
                  context,
                  ref.read(circleJournalRepositoryProvider),
                  ref,
                ),
                child: const Text('Delete Circle history'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Delete Circle history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();
      expect(c.read(circleJournalRepositoryProvider).readAll(), isEmpty);
      final cycle = cycleOf(c, 'slowing_down');
      expect(cycle.records, isEmpty);
      expect(cycle.cursor, 4, reason: 'the place stays');
      expect(c.read(circlePlansProvider).activePlanId, 'slowing_down');
      expect(c.read(keptCirclesProvider).kept, hasLength(1));
      // Nothing deleted survives elsewhere in the Plan, and the next
      // matching day carries on truthfully from the kept place.
      final plan = c.read(circlePlansProvider).plans['slowing_down']!;
      expect(plan.lastAdvancedCircleId, isNull);
      // The write lands outside the widget test's fake clock.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      expect(prefs.getString(circlePlansKey), isNot(contains('circleId')));
      final next = open(day: 1);
      today(next).chooseIntention(gentle, window: TimeWindow.about20);
      expect(offer(next).composed!.stage!.stageNumber, 4);
    });
  });

  test('Delete history is written, not only shown: a restart reads the '
      'place without the evidence', () async {
    await seed(under('getting_going', through: 2));
    final c = open();
    await plansOf(c).forgetStageEvidence();
    expect(prefs.getString(circlePlansKey), isNot(contains('circleId')));
    final restarted = open();
    expect(cycleOf(restarted, 'getting_going').cursor, 3);
    expect(cycleOf(restarted, 'getting_going').records, isEmpty);
    expect(
      restarted
          .read(circlePlansProvider)
          .plans['getting_going']!
          .lastAdvancedCircleId,
      isNull,
    );
  });

  group('B3 closure — the entitlement, through the real billing state', () {
    /// The app with the entitlement resolved to [status] — Premium derived
    /// from it exactly as in production (`premiumEntitlementProvider`).
    ProviderContainer billing(EntitlementStatus status, {int day = 0}) {
      final now = morning.add(Duration(days: day));
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          nowProvider.overrideWithValue(now),
          eventClockProvider.overrideWithValue(() => now),
          safetyPendingAllowedProvider.overrideWithValue(false),
          entitlementStatusProvider.overrideWith(
            () => _SettledEntitlement(status),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('active — a paid, grace or cancelled-but-paid period alike — runs '
        'the Plan: start, steer, move on', () async {
      final c = billing(EntitlementStatus.active);
      expect(c.read(premiumEntitlementProvider), isTrue);
      expect(plansOf(c).start('getting_going'), PlanActionResult.done);
      today(c).chooseIntention(energy, window: TimeWindow.about20);
      expect(offer(c).composed!.stage!.stageNumber, 1);
      await walk(c);
      expect(cycleOf(c, 'getting_going').cursor, 2);
    });

    test('inactive or expired — every direct call is refused, nothing '
        'steers or moves, and the saved Plan is untouched', () async {
      await seed(under('getting_going', through: 1).pause('getting_going')!);
      for (final status in [
        EntitlementStatus.inactive,
        EntitlementStatus.unavailable,
        EntitlementStatus.initializing,
      ]) {
        final saved = prefs.getString(circlePlansKey);
        final c = billing(status);
        expect(c.read(premiumEntitlementProvider), isFalse, reason: '$status');
        final plans = plansOf(c);
        expect(plans.start('making_room'), PlanActionResult.needsPremium);
        expect(plans.resume('getting_going'), PlanActionResult.needsPremium);
        expect(
          plans.goThroughAgain('getting_going'),
          PlanActionResult.needsPremium,
        );
        expect(
          plans.requestRevisit('getting_going', 1),
          PlanActionResult.needsPremium,
        );
        final context = ComposerContext(
          date: morning,
          need: energy,
          window: TimeWindow.about20,
        );
        expect(plans.steerToday(context, const []).circle, isNull);
        expect(
          plans.replaceStage(
            const PlanStageProvenance(
              planId: 'getting_going',
              cycleId: 'getting_going#1',
              stageNumber: 2,
              stageId: 'getting_going.2',
            ),
            context,
            const [],
          ),
          isNull,
        );
        plans.recordGuided(
          const PlanStageProvenance(
            planId: 'getting_going',
            cycleId: 'getting_going#1',
            stageNumber: 2,
            stageId: 'getting_going.2',
          ),
          circleId: '2026-10-12',
          parts: const [],
          skipped: const [],
        );
        await settle();
        expect(prefs.getString(circlePlansKey), saved, reason: '$status');
        expect(cycleOf(c, 'getting_going').cursor, 2);
      }
      // Even an active Plan written straight into storage — no UI, no
      // action — doesn't steer without the entitlement.
      await seed(under('getting_going', through: 1));
      final lapsed = billing(EntitlementStatus.inactive);
      today(lapsed).chooseIntention(energy, window: TimeWindow.about20);
      expect(offer(lapsed).composed, isNull);
      await walk(lapsed);
      expect(cycleOf(lapsed, 'getting_going').cursor, 2);
    });
  });
}
