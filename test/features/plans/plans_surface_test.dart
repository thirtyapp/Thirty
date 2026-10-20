import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/routing/app_router.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/personal_circle/domain/kept_circle.dart';
import 'package:thirty/features/personal_circle/domain/stage_brief.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_copy.dart';
import 'package:thirty/features/plans/domain/plan_stage_provenance.dart';
import 'package:thirty/features/plans/presentation/plan_detail_page.dart';
import 'package:thirty/features/plans/presentation/plan_view.dart';
import 'package:thirty/features/plans/presentation/plans_page.dart';
import 'package:thirty/features/premium/presentation/premium_offer_page.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';

class _SettledEntitlement extends EntitlementNotifier {
  _SettledEntitlement(this._status);

  final EntitlementStatus _status;

  @override
  EntitlementStatus build() => _status;
}

/// ADR-024 B4 — the Plans product surface through the real app: the
/// catalogue, Free and Premium, a Plan's states and actions, revisits, the
/// review and keeping from it, Today's stage context, routes and
/// accessibility.
void main() {
  final now = DateTime(2026, 10, 14, 9);
  const day = '2026-10-14';
  late SharedPreferences prefs;
  late ProviderContainer container;

  CirclePlansState under(String planId, {int through = 0}) {
    var s = CirclePlansState.empty.start(planId, today: '2026-10-01')!;
    for (var n = 1; n <= through; n++) {
      s = s.recordGuided(
        PlanStageProvenance(
          planId: planId,
          cycleId: s.plans[planId]!.current.id,
          stageNumber: n,
          stageId: '$planId.$n',
        ),
        circleId: '2026-10-0$n',
        today: '2026-10-0$n',
        parts: const ['getItOut:6', 'chooseOne:1', 'clearCorner:8'],
        skipped: const [],
      );
    }
    return s;
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    bool entitled = true,
    CirclePlansState? plans,
    Map<String, Object> extra = const {},
    String at = '/plans',
    double textScale = 1,
  }) async {
    SharedPreferences.setMockInitialValues({
      firstNamePromptSeenKey: true,
      if (plans != null) circlePlansKey: jsonEncode(plans.toJson()),
      ...extra,
    });
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(now),
        eventClockProvider.overrideWithValue(() => now),
        premiumEntitlementProvider.overrideWithValue(entitled),
        safetyPendingAllowedProvider.overrideWithValue(false),
        entitlementStatusProvider.overrideWith(
          () => _SettledEntitlement(
            entitled ? EntitlementStatus.active : EntitlementStatus.inactive,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ThirtyApp()),
    );
    await tester.pumpAndSettle();
    appRouter.go(at);
    await tester.pumpAndSettle();
  }

  Future<void> leaveRouterHome(WidgetTester tester) async {
    appRouter.go('/');
    await tester.pumpAndSettle();
  }

  Future<void> tapText(
    WidgetTester tester,
    String text, {
    bool first = false,
  }) async {
    if (find.text(text).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.text(text),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    final finder = first ? find.text(text).first : find.text(text).last;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  PlanCycle cycleOf(String planId) =>
      container.read(circlePlansProvider).plans[planId]!.current;

  group('catalogue', () {
    test('1–3. exactly the three launch Plans, in the frozen words; nothing '
        'retired', () {
      expect(launchCirclePlans.map((p) => p.name), [
        'Getting going',
        'Making room',
        'Slowing down',
      ]);
      expect(PlanCopy.purpose.keys, [
        'getting_going',
        'making_room',
        'slowing_down',
      ]);
      expect(
        PlanCopy.purpose['getting_going'],
        'A few Circles that try different ways of getting moving, at home and '
        'outside, and end with a mix of what suited you.',
      );
      expect(
        PlanCopy.card['making_room'],
        'Paper, then a space, then one thing — in five Circles.',
      );
      expect(
        PlanCopy.card['slowing_down'],
        'Hands, body, quiet, then a slower place — in five Circles.',
      );
      expect(PlanCopy.todayLine, hasLength(12));
      expect(
        PlanCopy.todayLine['getting_going.2'],
        'One part that keeps you on your feet for a while.',
      );
      for (final retired in [
        'moreEnergyPath',
        'clearerHeadPath',
        'clearTheDecks',
      ]) {
        expect(circlePlanById.containsKey(retired), isFalse);
      }
    });
  });

  group('Free', () {
    testWidgets('4. Plans is readable on Free: the three Plans, their card '
        'lines and stages, and one quiet Premium action', (tester) async {
      await pumpApp(tester, entitled: false);
      expect(find.byType(PlansPage), findsOneWidget);
      for (final plan in launchCirclePlans) {
        expect(find.text(plan.name), findsOneWidget);
        expect(find.text(PlanCopy.card[plan.id]!), findsOneWidget);
      }
      expect(
        find.text(
          'Loosen\u00A0up\u00A0· On\u00A0your\u00A0feet\u00A0· Two\u00A0together\u00A0· Fresh\u00A0air\u00A0· Your\u00A0mix',
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(find.text(PlanCopy.free), 200);
      expect(find.text(PlanCopy.startWithPremium), findsOneWidget);
      await leaveRouterHome(tester);
    });

    testWidgets('5–7. a Plan reads on Free; Start leads to Premium\'s own '
        'page; nothing starts', (tester) async {
      await pumpApp(tester, entitled: false, at: '/plans/getting_going');
      expect(find.byType(PlanDetailPage), findsOneWidget);
      expect(find.text(PlanCopy.purpose['getting_going']!), findsOneWidget);
      expect(find.text(PlanCopy.ready(Intention.moreEnergy)), findsOneWidget);
      expect(find.text(PlanCopy.start), findsNothing);
      await tapText(tester, PlanCopy.startWithPremium);
      expect(find.byType(PremiumOfferPage), findsOneWidget);
      expect(container.read(circlePlansProvider).plans, isEmpty);
      // A direct call can't bypass it either.
      expect(
        container.read(circlePlansProvider.notifier).start('getting_going'),
        PlanActionResult.needsPremium,
      );
      await leaveRouterHome(tester);
    });
  });

  group('Premium actions', () {
    testWidgets('8–9. start: stage 1, and what happens next', (tester) async {
      await pumpApp(tester, at: '/plans/getting_going');
      await tapText(tester, PlanCopy.start);
      expect(cycleOf('getting_going').cursor, 1);
      expect(find.text(PlanCopy.stageHeading(1, 'Loosen up')), findsOneWidget);
      expect(find.text(PlanCopy.next(Intention.moreEnergy)), findsOneWidget);
      // Starting a Plan is not starting today's Circle.
      expect(container.read(recommendationProvider).recommendation, isNull);
      await leaveRouterHome(tester);
    });

    testWidgets('10–12. pause, carry on, leave', (tester) async {
      await pumpApp(
        tester,
        plans: under('making_room', through: 2),
        at: '/plans/making_room',
      );
      await tapText(tester, PlanCopy.pause);
      expect(find.text(PlanCopy.paused(3)), findsOneWidget);
      await tapText(tester, PlanCopy.carryOn);
      expect(
        container.read(circlePlansProvider).lifecycleOf('making_room'),
        PlanLifecycle.active,
      );
      expect(cycleOf('making_room').cursor, 3);
      await tapText(tester, PlanCopy.leave);
      expect(find.text(PlanCopy.leaveBody), findsOneWidget);
      await tapText(tester, 'Leave');
      expect(
        container.read(circlePlansProvider).lifecycleOf('making_room'),
        PlanLifecycle.left,
      );
      expect(cycleOf('making_room').records, hasLength(2));
      expect(find.text(PlanCopy.start), findsOneWidget);
      await leaveRouterHome(tester);
    });

    testWidgets('13. switching says the other Plan pauses at its place, '
        'then does it', (tester) async {
      await pumpApp(
        tester,
        plans: under('getting_going', through: 2),
        at: '/plans/making_room',
      );
      await tapText(tester, PlanCopy.start);
      expect(
        find.text(PlanCopy.switchBody('Making room', 'Getting going', 3)),
        findsOneWidget,
      );
      await tapText(tester, PlanCopy.start);
      final plans = container.read(circlePlansProvider);
      expect(plans.activePlanId, 'making_room');
      expect(plans.lifecycleOf('getting_going'), PlanLifecycle.paused);
      expect(plans.plans['getting_going']!.current.cursor, 3);
      expect(plans.plans['making_room']!.current.cursor, 1);
      await leaveRouterHome(tester);
    });

    testWidgets('14. the end, then "Go through it again": a new cycle', (
      tester,
    ) async {
      await pumpApp(
        tester,
        plans: under('slowing_down', through: 5),
        at: '/plans/slowing_down',
      );
      expect(find.text(PlanCopy.reviewHeading.toUpperCase()), findsOneWidget);
      await tapText(tester, PlanCopy.goThroughAgain);
      expect(cycleOf('slowing_down').number, 2);
      expect(cycleOf('slowing_down').cursor, 1);
      await leaveRouterHome(tester);
    });
  });

  group('a Plan\'s states', () {
    final getting = circlePlanById['getting_going']!;
    PlanStatusView status(
      CirclePlansState plans, {
      bool premium = true,
      PlanToday today = const PlanToday(),
    }) => planStatus(
      getting,
      plans,
      premium: premium,
      today: today,
      todayKey: day,
      journal: const [],
    );

    test('15–18. the arc: guided with its date, set aside, next, and the '
        'rest unmarked', () {
      var s = under('getting_going', through: 2);
      final p = s.plans['getting_going']!;
      s = CirclePlansState(
        activePlanId: 'getting_going',
        plans: {
          'getting_going': p.withCurrent(
            p.current.copyWith(
              cursor: 4,
              records: [
                ...p.current.records,
                const StageRecord(
                  stageNumber: 3,
                  outcome: StageOutcome.setAside,
                  localDate: day,
                  setAsideBecause: [
                    StageBlock(
                      ElementId.moveToMusic,
                      ElementRole.second,
                      StageBlockReason.leftOut,
                    ),
                  ],
                ),
              ],
            ),
          ),
        },
      );
      final rows = stageRows(getting, s, premium: true, journal: const []);
      expect(rows.map((r) => r.status), [
        ['Guided 1 Oct'],
        ['Guided 2 Oct'],
        ['Set aside'],
        ['Next'],
        <String>[],
      ]);
      expect(rows[2].reason, PlanCopy.setAsideLeftOut('Move to music'));
      // The set-aside also leads the status on the day it happened.
      expect(status(s).lines.first, PlanCopy.setAsideLeftOut('Move to music'));
    });

    test('19–20. waiting: another need, or a day the stage couldn\'t '
        'follow', () {
      final s = under('getting_going');
      expect(
        status(s, today: const PlanToday(need: Intention.gentlerPace)).lines,
        [PlanCopy.waitingOtherNeed(Intention.moreEnergy)],
      );
      expect(
        status(s, today: const PlanToday(need: Intention.moreEnergy)).lines,
        [PlanCopy.waitingFit],
      );
      expect(status(s).lines, [PlanCopy.next(Intention.moreEnergy)]);
      // A kept Circle the user chose isn't a wait.
      expect(
        status(
          s,
          today: const PlanToday(need: Intention.moreEnergy, kept: true),
        ).lines,
        [PlanCopy.next(Intention.moreEnergy)],
      );
    });

    test(
      '21. lapsed: the saved place, and Premium\'s own page to carry on',
      () {
        final s = status(under('getting_going', through: 2), premium: false);
        expect(s.lines, [PlanCopy.lapsed(3)]);
        expect(s.primary, PlanPrimary.continueWithPremium);
        expect(s.canPause, isFalse);
        expect(s.canLeave, isTrue);
      },
    );

    test('22. history deleted: the place, no evidence, nothing broken', () {
      final s = under('getting_going', through: 2).forgetStageEvidence();
      expect(status(s).heading, PlanCopy.stageHeading(3, 'Two together'));
      final rows = stageRows(getting, s, premium: true, journal: const []);
      expect(rows.map((r) => r.status), [
        <String>[],
        <String>[],
        ['Next'],
        <String>[],
        <String>[],
      ]);
      expect(reviewOf(getting, s.plans['getting_going']!, const {}), isNull);
    });
  });

  group('revisit', () {
    test('23–25. offered only where the Plan allows it; pending, shown '
        'calmly; never twice', () {
      final getting = circlePlanById['getting_going']!;
      var s = under('getting_going', through: 2);
      var rows = stageRows(getting, s, premium: true, journal: const []);
      expect(rows.map((r) => r.canRevisit), [true, true, false, false, false]);
      expect(
        stageRows(
          getting,
          s,
          premium: false,
          journal: const [],
        ).any((r) => r.canRevisit),
        isFalse,
      );
      s = s.requestRevisit('getting_going', 1)!;
      rows = stageRows(getting, s, premium: true, journal: const []);
      expect(rows.first.status, ['Guided 1 Oct', 'Again next time']);
      expect(rows.any((r) => r.canRevisit), isFalse, reason: 'one at a time');
      expect(
        planStatus(
          getting,
          s,
          premium: true,
          today: const PlanToday(),
          todayKey: day,
          journal: const [],
        ).heading,
        PlanCopy.revisitPending('Loosen up'),
      );
    });

    testWidgets('the revisit action is the Plan\'s own', (tester) async {
      await pumpApp(
        tester,
        plans: under('getting_going', through: 2),
        at: '/plans/getting_going',
      );
      await tapText(tester, PlanCopy.revisit, first: true);
      expect(cycleOf('getting_going').pendingRevisit, 1);
      expect(cycleOf('getting_going').cursor, 3);
      await leaveRouterHome(tester);
    });
  });

  group('the review', () {
    final room = circlePlanById['making_room']!;
    const very = PastUsefulness.veryUseful;
    const somewhat = PastUsefulness.somewhatUseful;
    const not = PastUsefulness.notUseful;
    PlanProgress ended(String planId) =>
        under(planId, through: 5).plans[planId]!;

    test('26. no answers', () {
      final r = reviewOf(room, ended('making_room'), const {})!;
      expect(r.summary, [PlanCopy.noAnswers]);
      expect(
        r.endLine,
        'This Plan has reached its end. All five stages guided.',
      );
    });

    test('27. one positive, with the others said plainly', () {
      final r = reviewOf(room, ended('making_room'), {
        '2026-10-02': very,
        '2026-10-04': not,
      })!;
      expect(r.summary, [
        PlanCopy.onePositive('Room around you'),
        PlanCopy.othersUnanswered,
        PlanCopy.wasNot('Less coming in'),
      ]);
    });

    test('28. several positive', () {
      final r = reviewOf(room, ended('making_room'), {
        '2026-10-01': very,
        '2026-10-03': somewhat,
      })!;
      expect(r.summary, [
        PlanCopy.severalPositive(['Out of your head', 'Down to one']),
      ]);
      expect(
        r.summary.single,
        'You said these stages were useful: Out of '
        'your head and Down to one.',
      );
    });

    test('29. every stage rejected: no last Circle, fewer options', () {
      var s = under('making_room', through: 4);
      s = planToday(
        s,
        premium: true,
        context: ComposerContext(
          date: now,
          need: Intention.clearerHead,
          window: TimeWindow.about20,
        ),
        history: const [],
        answers: {for (var n = 1; n <= 4; n++) '2026-10-0$n': not},
      ).state;
      final r = reviewOf(room, s.plans['making_room']!, {
        for (var n = 1; n <= 4; n++) '2026-10-0$n': not,
      })!;
      expect(r.endLine, PlanCopy.allRejected);
      expect(r.caseD, isTrue);
    });

    test('30–32. set aside named; left with three guided has a review, '
        'with two has none', () {
      final three = under(
        'making_room',
        through: 3,
      ).leave('making_room', today: day)!;
      final r = reviewOf(room, three.plans['making_room']!, const {})!;
      expect(r.endLine, PlanCopy.left(3, 0));
      final two = under(
        'making_room',
        through: 2,
      ).leave('making_room', today: day)!;
      expect(reviewOf(room, two.plans['making_room']!, const {}), isNull);
      final p = under('making_room', through: 4).plans['making_room']!;
      final withAside = p.withCurrent(
        p.current.copyWith(
          records: [
            ...p.current.records,
            const StageRecord(
              stageNumber: 5,
              outcome: StageOutcome.setAside,
              localDate: day,
            ),
          ],
          end: CycleEnd.reachedEnd,
          endedOn: day,
        ),
      );
      final aside = reviewOf(room, withAside, const {})!;
      expect(aside.endLine, PlanCopy.reachedEnd(4, 1));
      expect(
        reviewFactLine(room, aside.facts.last, const []),
        PlanCopy.setAside,
      );
    });

    test('33. against the cycle before, only what the user said both '
        'times', () {
      var s = under('making_room', through: 5);
      s = s.goThroughAgain('making_room', today: day)!;
      for (var n = 1; n <= 5; n++) {
        s = s.recordGuided(
          PlanStageProvenance(
            planId: 'making_room',
            cycleId: 'making_room#2',
            stageNumber: n,
            stageId: 'making_room.$n',
          ),
          circleId: 'second-$n',
          today: day,
          parts: const ['getItOut:6'],
          skipped: const [],
        );
      }
      final r = reviewOf(room, s.plans['making_room']!, {
        '2026-10-01': very,
        'second-1': very,
        '2026-10-02': somewhat,
        'second-2': not,
        'second-3': very,
      })!;
      expect(r.compared, [
        'Out of your head · Very useful both times.',
        'Room around you · Somewhat useful last time, not useful this time.',
      ]);
    });

    test('34. never an outcome: no worked, improved, success or score', () {
      final r = reviewOf(room, ended('making_room'), {
        '2026-10-01': very,
        '2026-10-02': not,
      })!;
      final all = [
        r.endLine,
        ...r.summary,
        ...r.compared,
      ].join(' ').toLowerCase();
      for (final word in [
        'worked',
        'improv',
        'success',
        'helped',
        'complet',
        '%',
      ]) {
        expect(all, isNot(contains(word)), reason: word);
      }
    });
  });

  group('Keep from the review', () {
    testWidgets('35–38. the user picks a guided stage Circle; it is theirs, '
        'on Free too; never from a set-aside; never past eight', (
      tester,
    ) async {
      await pumpApp(
        tester,
        entitled: false,
        plans: under('making_room', through: 5),
        at: '/plans/making_room',
      );
      await tapText(tester, PlanCopy.keepOne);
      expect(find.text(PlanCopy.keepTitle), findsWidgets);
      await tapText(tester, 'Room around you');
      final kept = container.read(keptCirclesProvider).kept;
      expect(kept.single.fromCircleId, '2026-10-02');
      expect(kept.single.need, Intention.clearerHead);
      // Already kept: shown as in Yours, not offered again.
      await tapText(tester, PlanCopy.keepOne);
      expect(find.textContaining(PlanCopy.inYours), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await leaveRouterHome(tester);
    });

    test('a set-aside stage is never offered; max eight holds', () {
      final p = under('making_room', through: 4).plans['making_room']!;
      final withAside = p.withCurrent(
        p.current.copyWith(
          records: [
            ...p.current.records,
            const StageRecord(
              stageNumber: 5,
              outcome: StageOutcome.setAside,
              localDate: day,
            ),
          ],
          end: CycleEnd.reachedEnd,
        ),
      );
      final r = reviewOf(circlePlanById['making_room']!, withAside, const {})!;
      expect(r.keepable.map((k) => k.stageNumber), [1, 2, 3, 4]);
      expect(maxKeptCircles, 8);
    });
  });

  group('Today', () {
    testWidgets('39–41. a stage Circle names its Plan and stage, with the '
        'stage\'s own line; an ordinary day is unchanged', (tester) async {
      await pumpApp(tester, plans: under('getting_going'), at: '/');
      container
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await tester.pumpAndSettle();
      final today = container.read(recommendationProvider).recommendation!;
      expect(today.composed!.stage!.stageNumber, 1);
      expect(today.why, 'Start small: a stretch at home.');
      expect(find.text('Start small: a stretch at home.'), findsOneWidget);
      expect(
        find.textContaining('STAGE\u00A01\u00A0OF\u00A05'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Getting going, stage 1 of 5')),
        findsOneWidget,
      );
      for (final word in ['complet', 'done', 'streak']) {
        expect(today.why.toLowerCase(), isNot(contains(word)));
      }
      await leaveRouterHome(tester);
    });

    testWidgets('40. no Plan: Today\'s card is the ordinary one', (
      tester,
    ) async {
      await pumpApp(tester, at: '/');
      container
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await tester.pumpAndSettle();
      final today = container.read(recommendationProvider).recommendation!;
      expect(today.composed!.stage, isNull);
      expect(today.why, startsWith('Small parts, one after another'));
      expect(find.textContaining('YOUR\u00A0CIRCLE'), findsOneWidget);
      await leaveRouterHome(tester);
    });

    testWidgets('42. after the last stage closes, a calm way to the review '
        '— never a jump', (tester) async {
      await pumpApp(tester, plans: under('slowing_down', through: 4), at: '/');
      final today = container.read(recommendationProvider.notifier);
      today.chooseIntention(Intention.gentlerPace, window: TimeWindow.about20);
      await tester.pumpAndSettle();
      expect(
        container
            .read(recommendationProvider)
            .recommendation!
            .composed!
            .stage!
            .stageNumber,
        5,
      );
      today.start();
      today.close();
      await tester.pumpAndSettle();
      expect(cycleOf('slowing_down').end, CycleEnd.reachedEnd);
      await tester.scrollUntilVisible(find.text(PlanCopy.endedToday), 200);
      expect(find.byType(PlanDetailPage), findsNothing, reason: 'not forced');
      await tapText(tester, PlanCopy.reviewInPlans);
      expect(find.byType(PlanDetailPage), findsOneWidget);
      expect(find.text(PlanCopy.reviewHeading.toUpperCase()), findsOneWidget);
      await leaveRouterHome(tester);
    });
  });

  group('routes', () {
    testWidgets('43–45. /plans, a Plan, and any other id — a V1 Plan\'s '
        'included — back to Plans', (tester) async {
      await pumpApp(tester);
      expect(find.byType(PlansPage), findsOneWidget);
      appRouter.go('/plans/slowing_down');
      await tester.pumpAndSettle();
      expect(find.byType(PlanDetailPage), findsOneWidget);
      for (final retired in ['moreEnergyPath', 'nonsense']) {
        appRouter.go('/plans/$retired');
        await tester.pumpAndSettle();
        expect(find.byType(PlanDetailPage), findsNothing, reason: retired);
        expect(find.byType(PlansPage), findsOneWidget);
      }
      await leaveRouterHome(tester);
    });

    testWidgets('46–47. a deep link on Free or lapsed reads, and runs '
        'nothing', (tester) async {
      await pumpApp(
        tester,
        entitled: false,
        plans: under('making_room', through: 2),
        at: '/plans/making_room',
      );
      expect(find.text(PlanCopy.lapsed(3)), findsOneWidget);
      expect(find.text(PlanCopy.pause), findsNothing);
      expect(find.text(PlanCopy.revisit), findsNothing);
      expect(find.text(PlanCopy.continueWithPremium), findsOneWidget);
      expect(
        container.read(circlePlansProvider.notifier).resume('making_room'),
        PlanActionResult.needsPremium,
      );
      expect(
        container
            .read(circlePlansProvider.notifier)
            .requestRevisit('making_room', 1),
        PlanActionResult.needsPremium,
      );
      await leaveRouterHome(tester);
    });
  });

  group('accessibility', () {
    testWidgets('48–49. stages read as guided, never completed', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        plans: under('getting_going', through: 2),
        at: '/plans/getting_going',
      );
      expect(
        find.bySemanticsLabel(RegExp(r'Stage 1, Loosen up\. Guided 1 Oct')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'Stage 3, Two together\. Next')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('complet', caseSensitive: false)),
        findsNothing,
      );
      handle.dispose();
      await leaveRouterHome(tester);
    });

    testWidgets('50. at large text the primary action is still reachable', (
      tester,
    ) async {
      await pumpApp(tester, at: '/plans/making_room', textScale: 2);
      expect(tester.takeException(), isNull);
      await tapText(tester, PlanCopy.start);
      expect(cycleOf('making_room').cursor, 1);
      await leaveRouterHome(tester);
    });
  });
}
