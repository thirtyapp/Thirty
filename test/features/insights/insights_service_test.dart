import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/presentation/widgets/journal_data_controls.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/insights/domain/insight_engine.dart';
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

/// ADR-024 B5 — Insights through the production providers: the Premium
/// boundary (Free, lapsed, active — including grace and cancelled-but-paid,
/// which billing reports as active), every application through its own
/// domain and safe to repeat, I2 on the real composer, "Not now", Delete
/// history and export.
void main() {
  final morning = DateTime(2026, 10, 30, 9);
  const energy = Intention.moreEnergy;
  const head = Intention.clearerHead;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// The app on day [day] after [morning], its entitlement resolved to
  /// [status] — Premium derived from it exactly as in production.
  ProviderContainer open({
    EntitlementStatus status = EntitlementStatus.active,
    int day = 0,
  }) {
    final now = morning.add(Duration(days: day));
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(now),
        eventClockProvider.overrideWithValue(() => now),
        entitlementStatusProvider.overrideWith(
          () => _SettledEntitlement(status),
        ),
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

  InsightsNotifier insights(ProviderContainer c) =>
      c.read(insightsProvider.notifier);

  CirclePart part(ElementId e) => CirclePart(e, elementOf(e).minutes);
  final window = [
    part(ElementId.openWindow),
    part(ElementId.standingStretch),
    part(ElementId.sitAMinute),
  ];
  final writing = [
    part(ElementId.closeWhatsOpen),
    part(ElementId.getItOut),
    part(ElementId.chooseOne),
    part(ElementId.firstStep),
  ];
  final reading = [part(ElementId.phoneFaceDown), part(ElementId.readPages)];

  /// One journal record [ago] days before [morning].
  CircleJournalEntry entry(
    int ago,
    Intention need, {
    List<CirclePart> parts = const [],
    Set<ElementId> skipped = const {},
    CircleUsefulnessResponse? answer,
    PlanStageProvenance? stage,
    PlanStageProvenance? replacedFromStage,
    String? reason,
  }) {
    final date = morning.subtract(Duration(days: ago));
    return CircleJournalEntry(
      schemaVersion: circleJournalSchemaVersion,
      circleId: dateKey(date),
      localDate: dateKey(date),
      direction: need,
      activityId: ActivityId.values.first,
      catalogVersion: catalogVersion,
      shownAt: date,
      startedAt: date,
      closedAt: date,
      attemptResponse: answer == null ? null : CircleAttemptResponse.yes,
      usefulnessResponse: answer,
      replacementReason: reason,
      replacedFromStage: replacedFromStage,
      session: parts.isEmpty
          ? null
          : CircleSessionRecord(
              title: 'Circle',
              parts: CirclePlan(parts).toWire(),
              skipped: [for (final e in skipped) e.name],
              planStage: stage,
            ),
    );
  }

  Future<void> seedJournal(List<CircleJournalEntry> entries) => prefs.setString(
    circleJournalKey,
    jsonEncode({
      'schemaVersion': circleJournalSchemaVersion,
      'entries': [for (final e in entries) e.toJson()],
    }),
  );

  /// I3's evidence: "Open a window" skipped in 3 of its 4 Circles, among
  /// composed Circles across two weeks.
  List<CircleJournalEntry> skipping() => [
    for (final ago in [2, 4, 6, 8, 10, 12, 15])
      entry(ago, head, parts: reading),
    for (final (k, ago) in [1, 5, 9, 11].indexed)
      entry(
        ago,
        energy,
        parts: window,
        skipped: k == 1 ? const {} : {ElementId.openWindow},
      ),
  ];

  /// I1's evidence alone: Clearer Head chosen on 5 days across two weeks.
  List<CircleJournalEntry> choosingHead() => [
    for (final ago in [1, 5, 9, 13, 14]) entry(ago, head),
  ];

  group('the Premium boundary (ADR-024 §13), through billing', () {
    for (final status in [
      EntitlementStatus.inactive,
      EntitlementStatus.unavailable,
      EntitlementStatus.initializing,
    ]) {
      test('${status.name}: no new Insight, no application', () async {
        await seedJournal(choosingHead());
        final c = open(status: status);
        final result = insights(c).assess();
        expect(result.added, isEmpty);
        expect(c.read(insightsProvider).snapshots, isEmpty);
        expect(prefs.getString(insightsKey), isNull);
      });
    }

    test(
      'active (paid, grace, or cancelled but paid): assess and apply',
      () async {
        await seedJournal(choosingHead());
        final c = open();
        final shown = insights(c).assess().added.single;
        expect(shown.family, InsightFamily.planForNeed);
        expect(insights(c).apply(shown.id), InsightActionResult.done);
      },
    );

    test('lapsed: what was shown stays readable; nothing new, nothing '
        'applied — even by calling the service directly', () async {
      await seedJournal(choosingHead());
      final paid = open();
      final shown = insights(paid).assess().added.single;
      await settle();
      final lapsed = open(status: EntitlementStatus.inactive, day: 7);
      expect(lapsed.read(insightsProvider).snapshots.single.text, shown.text);
      expect(insights(lapsed).read().snapshots, hasLength(1));
      expect(insights(lapsed).assess().added, isEmpty);
      expect(
        insights(lapsed).apply(shown.id),
        InsightActionResult.needsPremium,
      );
      expect(
        insights(lapsed).notNow(shown.id),
        InsightActionResult.needsPremium,
      );
      expect(
        lapsed.read(circlePlansProvider).lifecycleOf('making_room'),
        PlanLifecycle.neverStarted,
      );
    });
  });

  group(
    'applications — explicit, through their own domains, safe to repeat',
    () {
      test('I1: the Plan starts through Plans; again → already so', () async {
        await seedJournal(choosingHead());
        final c = open();
        final shown = insights(c).assess().added.single;
        expect(insights(c).apply(shown.id), InsightActionResult.done);
        expect(
          c.read(circlePlansProvider).lifecycleOf('making_room'),
          PlanLifecycle.active,
        );
        expect(
          c.read(insightsProvider).byId(shown.id)!.appliedOn,
          '2026-10-30',
        );
        expect(insights(c).apply(shown.id), InsightActionResult.alreadyApplied);
        expect(
          c.read(circlePlansProvider).plans['making_room']!.cycles,
          hasLength(1),
        );
        // Nothing was written to History.
        expect(c.read(circleJournalRepositoryProvider).readAll(), hasLength(5));
      });

      test(
        'I1 resolves truthfully when the Plan was started some other way',
        () async {
          await seedJournal(choosingHead());
          final c = open();
          final shown = insights(c).assess().added.single;
          c.read(circlePlansProvider.notifier).start('making_room');
          expect(
            insights(c).apply(shown.id),
            InsightActionResult.notAvailable,
            reason: 'withdrawn: its Plan is active',
          );
          expect(c.read(insightsProvider).byId(shown.id)!.appliedOn, isNull);
        },
      );

      test(
        'I3: the existing Leave it out, once; Put it back undoes it',
        () async {
          await seedJournal(skipping());
          final c = open();
          final shown = insights(c).assess().added.single;
          expect(shown.family, InsightFamily.skippedPart);
          expect(
            c.read(suggestionPreferencesProvider).leftOut,
            isEmpty,
            reason: 'never applied by showing it',
          );
          expect(insights(c).apply(shown.id), InsightActionResult.done);
          expect(
            insights(c).apply(shown.id),
            InsightActionResult.alreadyApplied,
          );
          await settle();
          final prefsNow = c.read(suggestionPreferencesProvider);
          expect(prefsNow.elementsLeftOut.map((e) => e.element), [
            ElementId.openWindow,
          ]);
          await c
              .read(suggestionPreferencesProvider.notifier)
              .putBack(ElementId.openWindow);
          expect(c.read(suggestionPreferencesProvider).leftOut, isEmpty);
          // The record of what was applied stays; the same observation is quiet
          // for 28 days.
          expect(
            insights(c).status(c.read(insightsProvider).byId(shown.id)!),
            InsightStatus.applied,
          );
        },
      );

      test('I3 "Keep it": a dismissal — no preference, no answer, no '
          'ranking evidence, no second exclusion', () async {
        await seedJournal(skipping());
        final c = open();
        final shown = insights(c).assess().added.single;
        await settle();
        final journalBefore = prefs.getString(circleJournalKey);
        final suggestionsBefore = prefs.getString(suggestionPreferencesKey);
        final keysBefore = prefs.getKeys();
        expect(insights(c).keepPart(shown.id), InsightActionResult.done);
        await settle();
        expect(c.read(suggestionPreferencesProvider).leftOut, isEmpty);
        expect(prefs.getString(circleJournalKey), journalBefore);
        expect(prefs.getString(suggestionPreferencesKey), suggestionsBefore);
        // Only the Insight record itself changed.
        expect(prefs.getKeys(), keysBefore);
        final kept = c.read(insightsProvider).byId(shown.id)!;
        expect(
          kept.toJson().keys.toSet().difference(shown.toJson().keys.toSet()),
          {'declinedOn'},
        );
        expect(
          insights(c).status(c.read(insightsProvider).byId(shown.id)!),
          InsightStatus.declined,
        );
        expect(insights(c).apply(shown.id), InsightActionResult.notAvailable);
      });

      group('I4: Keep, through the kept Circles', () {
        List<CircleJournalEntry> useful() => [
          for (final (k, ago) in [1, 7, 13, 20].indexed)
            entry(
              ago,
              head,
              parts: writing,
              answer: k.isEven
                  ? CircleUsefulnessResponse.veryUseful
                  : CircleUsefulnessResponse.somewhatUseful,
            ),
          for (final ago in [3, 9, 16]) entry(ago, head, parts: reading),
        ];

        test(
          'keeps the most recent useful Circle once — never a routine',
          () async {
            await seedJournal(useful());
            final c = open();
            final shown = insights(c).assess().added.single;
            expect(shown.family, InsightFamily.usefulInCommon);
            expect(insights(c).apply(shown.id), InsightActionResult.done);
            final kept = c.read(keptCirclesProvider).kept;
            expect(kept, hasLength(1));
            expect(kept.single.fromCircleId, '2026-10-29');
            expect(kept.single.plan.toWire(), CirclePlan(writing).toWire());
            expect(
              insights(c).apply(shown.id),
              InsightActionResult.alreadyApplied,
            );
            expect(c.read(keptCirclesProvider).kept, hasLength(1));
          },
        );

        void keepEight(ProviderContainer c) {
          for (var k = 0; k < 8; k++) {
            c
                .read(keptCirclesProvider.notifier)
                .keepCircle(
                  plan: CirclePlan(reading),
                  need: head,
                  circleId: 'other$k',
                );
          }
        }

        test(
          '8 kept when shown → Nothing to change, nothing to apply',
          () async {
            await seedJournal(useful());
            final c = open();
            keepEight(c);
            final shown = insights(c).assess().added.single;
            expect(shown.application, isA<NothingToChange>());
            expect(
              insights(c).apply(shown.id),
              InsightActionResult.nothingToApply,
            );
            expect(c.read(keptCirclesProvider).kept, hasLength(8));
          },
        );

        test('room gone between showing and applying → the limit, nothing '
            'replaced', () async {
          await seedJournal(useful());
          final c = open();
          final shown = insights(c).assess().added.single;
          expect(shown.application, isA<KeepCircleFromHistory>());
          keepEight(c);
          final before = [
            for (final k in c.read(keptCirclesProvider).kept) k.id,
          ];
          expect(insights(c).status(shown), InsightStatus.current);
          expect(
            insights(c).apply(shown.id),
            InsightActionResult.keptLimitReached,
          );
          expect([
            for (final k in c.read(keptCirclesProvider).kept) k.id,
          ], before);
          expect(c.read(insightsProvider).byId(shown.id)!.appliedOn, isNull);
        });
      });
    },
  );

  group('I2 — gentler, on the real composer', () {
    const stage = PlanStageProvenance(
      planId: 'getting_going',
      cycleId: 'getting_going#1',
      stageNumber: 1,
      stageId: 'getting_going.1',
    );

    Future<void> seedPacing() async {
      await prefs.setString(
        circlePlansKey,
        jsonEncode(
          CirclePlansState.empty
              .start('getting_going', today: '2026-10-01')!
              .toJson(),
        ),
      );
      await seedJournal([
        for (final (k, ago) in [2, 5, 9, 13, 17].indexed)
          k.isEven
              ? entry(ago, energy, replacedFromStage: stage, reason: 'tooMuch')
              : entry(ago, energy, parts: window, stage: stage),
      ]);
    }

    test('applied by the user → the next matching Plan Circle is gentler; '
        'ordinary Today is unchanged', () async {
      await seedPacing();
      final c = open();
      final shown = insights(c).assess().added.single;
      expect(shown.family, InsightFamily.planPacing);
      expect(
        c.read(circlePlansProvider).active!.current.isGentler,
        isFalse,
        reason: 'never turned on by being shown',
      );
      expect(insights(c).apply(shown.id), InsightActionResult.done);
      expect(insights(c).apply(shown.id), InsightActionResult.alreadyApplied);
      await settle();
      final cycle = c.read(circlePlansProvider).active!.current;
      expect(cycle.gentlerSince, '2026-10-30');

      // The next matching day, on an up-to-30 day: ≈20 size, low effort.
      final next = open(day: 1);
      next
          .read(recommendationProvider.notifier)
          .chooseIntention(energy, window: TimeWindow.upTo30);
      final composed = next
          .read(recommendationProvider)
          .recommendation!
          .composed!;
      expect(composed.stage!.gentler, isTrue);
      expect(composed.stage!.stageNumber, 1);
      expect(composed.plan.minutes, lessThanOrEqualTo(20));
      for (final p in composed.plan.parts) {
        expect(p.definition.effort, ActivityEffort.low, reason: '$p');
      }
      // Its brief still holds (C1): the stage's own condition.
      expect(
        stageBriefById['getting_going.1']!.accepts(
          composed.plan.parts,
          size: 20,
        ),
        isTrue,
      );
      // A treated offer is never evidence for the Insight again.
      expect(planPacing(insights(next).inputs()), isNull);
    });

    test('a different need: ordinary composition, untouched', () async {
      await seedPacing();
      final c = open();
      insights(c).apply(insights(c).assess().added.single.id);
      await settle();
      final next = open(day: 1);
      next
          .read(recommendationProvider.notifier)
          .chooseIntention(head, window: TimeWindow.upTo30);
      final today = next.read(recommendationProvider).recommendation!;
      expect(today.composed!.stage, isNull);
      final expected = composeCircle(
        ComposerContext(
          date: morning.add(const Duration(days: 1)),
          need: head,
          window: TimeWindow.upTo30,
        ),
        next.read(pastCirclesProvider),
      )!;
      expect(today.composed!.plan, expected.plan);
    });

    test('never below ≈10, and Not this one today stays gentler', () async {
      await seedPacing();
      final c = open();
      insights(c).apply(insights(c).assess().added.single.id);
      await settle();
      final next = open(day: 1);
      final today = next.read(recommendationProvider.notifier);
      today.chooseIntention(energy, window: TimeWindow.about10);
      final first = next.read(recommendationProvider).recommendation!;
      expect(first.composed!.stage!.gentler, isTrue);
      expect(first.composed!.plan.minutes, lessThanOrEqualTo(10));
      expect(today.replaceToday(ReplacementReason.notFeeling), isTrue);
      final replaced = next.read(recommendationProvider).recommendation!;
      if (replaced.composed?.stage != null) {
        expect(replaced.composed!.stage!.gentler, isTrue);
        for (final p in replaced.composed!.plan.parts) {
          expect(p.definition.effort, ActivityEffort.low);
        }
      }
    });

    test('turned off by the user; ends with the cycle', () async {
      await seedPacing();
      final c = open();
      insights(c).apply(insights(c).assess().added.single.id);
      final plans = c.read(circlePlansProvider.notifier);
      expect(plans.stopGentler('getting_going'), PlanActionResult.done);
      expect(c.read(circlePlansProvider).active!.current.isGentler, isFalse);
      expect(plans.stopGentler('getting_going'), PlanActionResult.notAvailable);
      // A new cycle never inherits it.
      final s = c
          .read(circlePlansProvider)
          .keepGentler('getting_going', today: '2026-10-30')!
          .leave('getting_going', today: '2026-10-30')!
          .goThroughAgain('getting_going', today: '2026-10-31')!;
      expect(s.active!.current.isGentler, isFalse);
      expect(s.plans['getting_going']!.cycles.first.isGentler, isTrue);
    });

    test('lapsed: not applied', () async {
      await seedPacing();
      final paid = open();
      final shown = insights(paid).assess().added.single;
      await settle();
      final lapsed = open(status: EntitlementStatus.inactive);
      expect(
        insights(lapsed).apply(shown.id),
        InsightActionResult.needsPremium,
      );
      expect(
        lapsed.read(circlePlansProvider.notifier).keepGentler('getting_going'),
        PlanActionResult.needsPremium,
      );
      expect(
        lapsed.read(circlePlansProvider).active!.current.isGentler,
        isFalse,
      );
    });

    test('without the setting, a Plan stage composes exactly as before', () {
      final plans = CirclePlansState.empty.start(
        'getting_going',
        today: '2026-10-01',
      )!;
      final context = ComposerContext(
        date: morning,
        need: energy,
        window: TimeWindow.upTo30,
      );
      final day = planToday(
        plans,
        premium: true,
        context: context,
        history: const [],
        answers: const {},
      );
      final direct = composeStage(context, const [], [
        stageBriefById['getting_going.1']!,
      ]);
      expect(day.stage!.gentler, isFalse);
      expect(day.circle!.plan, (direct as StageComposed).circle.plan);
    });
  });

  group('the journal keeps a replaced stage offer (I2\'s evidence)', () {
    test('"Too much for today" on a stage Circle is recorded against the '
        'stage, whatever replaced it', () async {
      final c = open();
      c.read(circlePlansProvider.notifier).start('getting_going');
      final today = c.read(recommendationProvider.notifier);
      today.chooseIntention(energy, window: TimeWindow.about20);
      expect(
        c.read(recommendationProvider).recommendation!.composed!.stage,
        isNotNull,
      );
      expect(today.replaceToday(ReplacementReason.tooMuch), isTrue);
      await settle();
      final recorded = c.read(circleJournalRepositoryProvider).readAll().single;
      expect(recorded.replacementReason, 'tooMuch');
      expect(recorded.replacedFromStage!.planId, 'getting_going');
      expect(recorded.replacedFromStage!.stageNumber, 1);
      // Kept through later writes (start, close).
      today.start();
      today.close();
      await settle();
      expect(
        c
            .read(circleJournalRepositoryProvider)
            .readAll()
            .single
            .replacedFromStage,
        isNotNull,
      );
    });

    test(
      'an ordinary day writes nothing new: old JSON stays byte-identical',
      () {
        final e = entry(1, head, parts: reading);
        expect(e.toJson().containsKey('replacedFromPlanStage'), isFalse);
        expect(
          (e.toJson()['session'] as Map).containsKey('planStage'),
          isFalse,
        );
      },
    );
  });

  group('"Not now" (§11)', () {
    test('a Plan review is not dismissed here: Plans owns it', () async {
      var plans = CirclePlansState.empty.start(
        'making_room',
        today: '2026-10-01',
      )!;
      for (var n = 1; n <= 5; n++) {
        plans = plans.recordGuided(
          PlanStageProvenance(
            planId: 'making_room',
            cycleId: 'making_room#1',
            stageNumber: n,
            stageId: 'making_room.$n',
          ),
          circleId: 'c$n',
          today: '2026-10-1$n',
          parts: const [],
          skipped: const [],
        );
      }
      await prefs.setString(circlePlansKey, jsonEncode(plans.toJson()));
      await seedJournal([entry(3, head)]);
      final c = open();
      final review = insights(c).assess().added.single;
      expect(review.family, InsightFamily.planReview);
      expect(insights(c).notNow(review.id), InsightActionResult.notAvailable);
      expect(insights(c).keepPart(review.id), InsightActionResult.notAvailable);
      expect(c.read(insightsProvider).byId(review.id)!.notNowOn, isNull);
    });

    test('hides the same observation for 28 days; History and suggestions '
        'untouched', () async {
      await seedJournal(skipping());
      final c = open();
      final shown = insights(c).assess().added.single;
      final journalBefore = prefs.getString(circleJournalKey);
      final suggestionsBefore = prefs.getString(suggestionPreferencesKey);
      expect(insights(c).notNow(shown.id), InsightActionResult.done);
      await settle();
      expect(prefs.getString(circleJournalKey), journalBefore);
      expect(prefs.getString(suggestionPreferencesKey), suggestionsBefore);
      expect(insights(c).apply(shown.id), InsightActionResult.notAvailable);
      // A week on, the same observation stays quiet.
      final week = open(day: 7);
      expect(
        insights(week).assess().added.map((s) => s.subject),
        isNot(contains(shown.subject)),
      );
    });
  });

  group('Delete history and export (contract, Delete / Export)', () {
    testWidgets('Delete history: every snapshot goes; what the user applied, '
        'kept and their Plan\'s place stay', (tester) async {
      late ProviderContainer c;
      await tester.runAsync(() async {
        await seedJournal(skipping());
        await prefs.setString(
          circlePlansKey,
          jsonEncode(
            CirclePlansState.empty
                .start('getting_going', today: '2026-10-01')!
                .keepGentler('getting_going', today: '2026-10-02')!
                .toJson(),
          ),
        );
        c = open();
        final shown = insights(c).assess().added.single;
        insights(c).apply(shown.id);
        c
            .read(keptCirclesProvider.notifier)
            .keepCircle(
              plan: CirclePlan(reading),
              need: head,
              circleId: '2026-10-28',
            );
        await settle();
      });
      expect(c.read(insightsProvider).snapshots, isNotEmpty);
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
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      expect(c.read(insightsProvider).snapshots, isEmpty);
      expect(prefs.getString(insightsKey), isNull);
      // Nothing quotes the deleted evidence, and nothing rebuilds it.
      final assessed = insights(c).assess();
      expect(assessed.added, isEmpty);
      expect(assessed.readiness, InsightReadiness.noHistory);
      // Kept by the contract: what the user chose and owns.
      expect(c.read(suggestionPreferencesProvider).leftOut, {
        ElementId.openWindow,
      });
      expect(c.read(keptCirclesProvider).kept, hasLength(1));
      final plan = c.read(circlePlansProvider).plans['getting_going']!;
      expect(plan.lifecycle, PlanLifecycle.active);
      expect(plan.current.isGentler, isTrue);
    });

    test('the export carries the snapshots as shown — no profile', () async {
      await seedJournal(skipping());
      final c = open();
      final shown = insights(c).assess().added.single;
      insights(c).notNow(shown.id);
      final exported =
          jsonDecode(
                c
                    .read(circleJournalRepositoryProvider)
                    .exportAsJson(insights: c.read(insightsProvider).toJson()),
              )
              as Map<String, Object?>;
      final block = exported['insights'] as Map<String, Object?>;
      final snapshot = (block['snapshots'] as List).single as Map;
      expect(snapshot['text'], shown.text);
      expect(snapshot['notNowOn'], '2026-10-30');
      expect(snapshot['evidence'], hasLength(4));
      final text = jsonEncode(block);
      for (final word in ['likes', 'profile', 'score', 'prefers', 'needs']) {
        expect(text, isNot(contains(word)));
      }
    });

    test('a restart reads exactly what was stored', () async {
      await seedJournal(skipping());
      final c = open();
      insights(c).assess();
      await settle();
      final restarted = open();
      expect(
        restarted.read(insightsProvider).toJson(),
        c.read(insightsProvider).toJson(),
      );
    });
  });
}
