import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
import 'package:thirty/features/home/presentation/widgets/journal_data_controls.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/insights/domain/insight_copy.dart';
import 'package:thirty/features/insights/presentation/insights_page.dart';
import 'package:thirty/features/insights/presentation/widgets/insight_card.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/presentation/keep_circle_card.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_copy.dart';
import 'package:thirty/features/plans/domain/plan_stage_provenance.dart';
import 'package:thirty/features/plans/presentation/plan_detail_page.dart';

class _SettledEntitlement extends EntitlementNotifier {
  _SettledEntitlement(this._status);

  final EntitlementStatus _status;

  @override
  EntitlementStatus build() => _status;
}

/// ADR-024 B6 — the Insights surface on the real providers and the B5
/// service: Free owns the calendar and History; Premium adds one current
/// Insight with its evidence and one bounded action; lapsed users read
/// what was shown. Nothing on the page decides what qualifies.
void main() {
  final morning = DateTime(2026, 10, 30, 9);
  const energy = Intention.moreEnergy;
  const head = Intention.clearerHead;
  const gentle = Intention.gentlerPace;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

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

  CircleJournalEntry entry(
    int ago,
    Intention need, {
    List<CirclePart> parts = const [],
    Set<ElementId> skipped = const {},
    CircleUsefulnessResponse? answer,
    PlanStageProvenance? stage,
    PlanStageProvenance? replacedFromStage,
    String? reason,
    bool closed = true,
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
      startedAt: closed ? date : null,
      closedAt: closed ? date : null,
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

  Future<void> seedPlans(CirclePlansState plans) =>
      prefs.setString(circlePlansKey, jsonEncode(plans.toJson()));

  /// I3's evidence (and I1's): "Open a window" skipped in 3 of its last 4.
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

  List<CircleJournalEntry> choosingHead() => [
    for (final ago in [1, 5, 9, 13, 14]) entry(ago, head),
  ];

  List<CircleJournalEntry> usefulWriting() => [
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

  ProviderContainer container({
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

  /// The Insights page as opened at [location], over a router whose other
  /// destinations say where a tap went.
  Future<ProviderContainer> open(
    WidgetTester tester, {
    EntitlementStatus status = EntitlementStatus.active,
    int day = 0,
    double textScale = 1.0,
    Size size = const Size(412, 915),
    ProviderContainer? reuse,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final c = reuse ?? container(status: status, day: day);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          routerConfig: GoRouter(
            initialLocation: '/start',
            routes: [
              GoRoute(
                path: '/start',
                builder: (context, state) => Consumer(
                  builder: (context, ref, _) => Scaffold(
                    body: Column(
                      children: [
                        TextButton(
                          onPressed: () => context.push('/insights'),
                          child: const Text('open insights'),
                        ),
                        TextButton(
                          onPressed: () => JournalDataControls.confirmAndClear(
                            context,
                            ref.read(circleJournalRepositoryProvider),
                            ref,
                          ),
                          child: const Text('Delete Circle history'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: '/insights',
                builder: (context, state) => const InsightsPage(),
              ),
              GoRoute(
                path: '/history',
                builder: (context, state) => const Text('history list'),
              ),
              GoRoute(
                path: '/history/:date',
                builder: (context, state) =>
                    Text('detail:${state.pathParameters['date']}'),
              ),
              GoRoute(
                path: '/premium',
                builder: (context, state) => const Text('premium offer'),
              ),
              GoRoute(
                path: '/plans/:id',
                builder: (context, state) => Text(
                  'plan:${state.pathParameters['id']}'
                  ':${state.uri.queryParameters['cycle'] ?? ''}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('open insights'));
    await tester.pumpAndSettle();
    return c;
  }

  Finder cards() => find.byType(InsightCard);

  /// What the page shows for [text]: each date kept on one line.
  String nb(String text) => InsightCopy.keepDatesTogether(text);

  /// Every text on screen, for the content guards.
  String visibleText(WidgetTester tester) => [
    for (final t in tester.widgetList<Text>(find.byType(Text)))
      t.data ?? t.textSpan?.toPlainText() ?? '',
  ].join('\n');

  final forbidden = RegExp(
    r'\b(you need|because|caused?|improv\w*|boosts?|reduces? anxiety|'
    r'healthier|more focused|calmer|success rate|streaks?|missed days?|'
    r'perfect week|completed|score|percent)\b|%',
    caseSensitive: false,
  );

  void guarded(WidgetTester tester) {
    final text = visibleText(tester);
    expect(forbidden.hasMatch(text), isFalse, reason: text);
  }

  Future<void> scrollTo(WidgetTester tester, Finder target) =>
      tester.scrollUntilVisible(
        target,
        200,
        scrollable: find.byType(Scrollable).first,
      );

  group('the surface', () {
    testWidgets('opens the real page: title, header, calendar, no '
        'dashboard', (tester) async {
      await seedJournal(skipping());
      await open(tester);
      expect(find.text(InsightCopy.title), findsOneWidget);
      expect(find.text(InsightCopy.subtitle), findsOneWidget);
      expect(
        find.text(InsightCopy.circlesHeading.toUpperCase()),
        findsOneWidget,
      );
      guarded(tester);
    });

    testWidgets('exactly one current ordinary Insight, with its evidence '
        'and one action', (tester) async {
      await seedJournal(skipping());
      final c = await open(tester);
      expect(cards(), findsOneWidget);
      final shown = c.read(insightsProvider).snapshots.single;
      expect(shown.family, InsightFamily.skippedPart);
      // Its own words, as B5 stored them — and the Circles it rests on.
      expect(find.text(nb(shown.text)), findsOneWidget);
      expect(
        find.text(nb('From 4 of your Circles, 19 to 29 October.')),
        findsOneWidget,
      );
      expect(find.text(InsightCopy.leaveOut), findsOneWidget);
      expect(find.text(InsightCopy.notNow), findsOneWidget);
      // A second visit the same day adds nothing.
      await open(tester, reuse: c);
      expect(c.read(insightsProvider).snapshots, hasLength(1));
      expect(cards(), findsOneWidget);
    });

    testWidgets('too little evidence: no Insight, the truthful count', (
      tester,
    ) async {
      await seedJournal([
        entry(1, head, answer: CircleUsefulnessResponse.veryUseful),
        entry(3, head),
        entry(5, energy, closed: false),
      ]);
      final c = await open(tester);
      expect(cards(), findsNothing);
      expect(c.read(insightsProvider).snapshots, isEmpty);
      expect(find.text(InsightCopy.premiumSoFar(3, 1)), findsOneWidget);
      guarded(tester);
    });
  });

  group('Free: the calendar and History are theirs', () {
    testWidgets('no History: an empty calendar, said plainly, and what '
        'Premium would do', (tester) async {
      await open(tester, status: EntitlementStatus.inactive);
      expect(find.text(InsightCopy.freeEmpty), findsOneWidget);
      expect(find.text(InsightCopy.free), findsOneWidget);
      expect(cards(), findsNothing);
      guarded(tester);
    });

    testWidgets('populated: readable calendar and History; a recorded date '
        'opens its record; nothing Premium is generated', (tester) async {
      await seedJournal(skipping());
      final c = await open(tester, status: EntitlementStatus.inactive);
      expect(cards(), findsNothing);
      expect(c.read(insightsProvider).snapshots, isEmpty);
      final handle = tester.ensureSemantics();
      final label = find.bySemanticsLabel(
        RegExp(r'October 29, 2026, Circle closed in THIRTY'),
      );
      expect(label, findsOneWidget);
      await tester.tap(label);
      await tester.pumpAndSettle();
      expect(find.text('detail:2026-10-29'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('"See as a list" opens History; "See Premium" the existing '
        'offer', (tester) async {
      await seedJournal(skipping());
      await open(tester, status: EntitlementStatus.inactive);
      await scrollTo(tester, find.text(InsightCopy.seePremium));
      await tester.tap(find.text(InsightCopy.seePremium));
      await tester.pumpAndSettle();
      expect(find.text('premium offer'), findsOneWidget);
    });
  });

  group('Premium early life', () {
    testWidgets('day 1: no History, no Insight', (tester) async {
      await open(tester);
      expect(find.text(InsightCopy.premiumDayOne), findsOneWidget);
      expect(cards(), findsNothing);
    });

    testWidgets('week 1 with a Plan under way: the count and the Plan\'s '
        'place', (tester) async {
      var plans = CirclePlansState.empty.start(
        'getting_going',
        today: '2026-10-23',
      )!;
      plans = plans.recordGuided(
        const PlanStageProvenance(
          planId: 'getting_going',
          cycleId: 'getting_going#1',
          stageNumber: 1,
          stageId: 'getting_going.1',
        ),
        circleId: '2026-10-25',
        today: '2026-10-25',
        parts: const [],
        skipped: const [],
      );
      await seedPlans(plans);
      await seedJournal([entry(5, energy), entry(2, energy)]);
      await open(tester);
      expect(find.text(InsightCopy.premiumSoFar(2, 0)), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Getting going. ${PlanCopy.stageHeading(2, 'On your feet')}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a genuine Plan review appears at once, and opens the '
        'canonical review in Plans', (tester) async {
      var plans = CirclePlansState.empty.start(
        'making_room',
        today: '2026-10-10',
      )!;
      for (var n = 1; n <= 5; n++) {
        plans = plans.recordGuided(
          PlanStageProvenance(
            planId: 'making_room',
            cycleId: 'making_room#1',
            stageNumber: n,
            stageId: 'making_room.$n',
          ),
          circleId: '2026-10-2$n',
          today: '2026-10-2$n',
          parts: const [],
          skipped: const [],
        );
      }
      await seedPlans(plans);
      await seedJournal([entry(4, head)]);
      await open(tester);
      expect(
        find.text(
          InsightCopy.familyName(InsightFamily.planReview).toUpperCase(),
        ),
        findsOneWidget,
      );
      expect(find.text(InsightCopy.notNow), findsNothing);
      await tester.tap(find.text(InsightCopy.reviewThisPlan));
      await tester.pumpAndSettle();
      expect(find.text('plan:making_room:'), findsOneWidget);
      guarded(tester);
    });
  });

  group('applications — through the service, no stale button', () {
    testWidgets('I1: Start Making room', (tester) async {
      await seedJournal(choosingHead());
      final c = await open(tester);
      await tester.tap(find.text('Start Making room'));
      await tester.pumpAndSettle();
      expect(
        c.read(circlePlansProvider).lifecycleOf('making_room'),
        PlanLifecycle.active,
      );
      expect(find.text('Start Making room'), findsNothing);
      expect(find.text(InsightCopy.nowYourPlan('Making room')), findsOneWidget);
      await tester.tap(find.text(InsightCopy.seeThePlan));
      await tester.pumpAndSettle();
      expect(find.text('plan:making_room:'), findsOneWidget);
    });

    testWidgets('I2: keep this Plan\'s Circles gentler', (tester) async {
      const stage = PlanStageProvenance(
        planId: 'getting_going',
        cycleId: 'getting_going#1',
        stageNumber: 1,
        stageId: 'getting_going.1',
      );
      await seedPlans(
        CirclePlansState.empty.start('getting_going', today: '2026-10-01')!,
      );
      await seedJournal([
        for (final (k, ago) in [2, 5, 9, 13, 17].indexed)
          k.isEven
              ? entry(ago, energy, replacedFromStage: stage, reason: 'tooMuch')
              : entry(ago, energy, parts: window, stage: stage),
      ]);
      final c = await open(tester);
      expect(
        find.text(
          'On 3 of your last 5 Getting going days, you chose “Too much for '
          'today”.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(InsightCopy.keepGentler));
      await tester.pumpAndSettle();
      expect(c.read(circlePlansProvider).active!.current.isGentler, isTrue);
      expect(find.text(InsightCopy.gentlerOn), findsOneWidget);
      expect(find.text(InsightCopy.keepGentler), findsNothing);
    });

    testWidgets('I3: Leave it out, through the existing control; the '
        'dismissal is "Not now", never "Keep it"', (tester) async {
      await seedJournal(skipping());
      final c = await open(tester);
      expect(find.text('Keep it'), findsNothing);
      await tester.tap(find.text(InsightCopy.leaveOut));
      await tester.pumpAndSettle();
      expect(c.read(suggestionPreferencesProvider).leftOut, {
        ElementId.openWindow,
      });
      expect(find.text(InsightCopy.leftOut('Open a window')), findsOneWidget);
      expect(find.text(InsightCopy.leaveOut), findsNothing);
    });

    testWidgets('I4: both fractions, and Keep through the kept Circles', (
      tester,
    ) async {
      await seedJournal(usefulWriting());
      final c = await open(tester);
      expect(
        find.text(
          'Writing was part of 4 of the 4 Clearer Head Circles you called '
          'useful, and 0 of the 3 other Clearer Head Circles in that time.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(InsightCopy.keepCircle));
      await tester.pumpAndSettle();
      final kept = c.read(keptCirclesProvider).kept;
      expect(kept.single.fromCircleId, '2026-10-29');
      expect(find.text(KeepCircleCopy.kept(kept.single.name)), findsOneWidget);
    });

    testWidgets('I4 with no room by the time it is applied: the truthful '
        'limit, nothing replaced', (tester) async {
      await seedJournal(usefulWriting());
      final c = await open(tester);
      for (var k = 0; k < 8; k++) {
        c
            .read(keptCirclesProvider.notifier)
            .keepCircle(
              plan: CirclePlan(reading),
              need: head,
              circleId: 'other$k',
            );
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text(InsightCopy.keepCircle));
      await tester.pumpAndSettle();
      expect(find.text(KeepCircleCopy.full), findsOneWidget);
      expect(c.read(keptCirclesProvider).kept, hasLength(8));
    });

    testWidgets('Nothing to change: calm, with no fake action', (tester) async {
      await seedJournal(usefulWriting());
      final c = container();
      c
          .read(keptCirclesProvider.notifier)
          .keepCircle(
            plan: CirclePlan(writing),
            need: head,
            circleId: '2026-10-29',
          );
      await open(tester, reuse: c);
      expect(find.text(InsightCopy.usefulAlreadyWeighted), findsOneWidget);
      expect(find.text(InsightCopy.keepCircle), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('I6: both periods with their counts, and the Plan for the '
        'recent need', (tester) async {
      await seedJournal([
        for (var ago = 90; ago > 30; ago -= 2) entry(ago, gentle),
        for (var ago = 27; ago >= 1; ago -= 2) entry(ago, energy),
      ]);
      final c = container();
      // I1 for the same need was shown three weeks ago: cooling down, so
      // I6 has the week.
      await open(tester, reuse: c);
      final first = c.read(insightsProvider).snapshots.single;
      expect(first.family, InsightFamily.planForNeed);
      await tester.tap(find.text(InsightCopy.notNow));
      await tester.pumpAndSettle();
      final later = container(day: 7);
      await open(tester, reuse: later);
      final shown = later.read(insightsProvider).snapshots.last;
      expect(shown.family, InsightFamily.whatsChanged);
      expect(
        find.textContaining('you chose Gentler Pace most'),
        findsOneWidget,
      );
      expect(find.textContaining('it’s been More Energy'), findsOneWidget);
      await tester.tap(find.text('Start Getting going'));
      await tester.pumpAndSettle();
      expect(
        later.read(circlePlansProvider).lifecycleOf('getting_going'),
        PlanLifecycle.active,
      );
      guarded(tester);
    });
  });

  group('"Not now"', () {
    testWidgets('sets it aside through the service; nothing else changes; '
        'no other Insight takes its place', (tester) async {
      await seedJournal(skipping());
      final c = await open(tester);
      await tester.pump(const Duration(milliseconds: 50));
      final journalBefore = prefs.getString(circleJournalKey);
      final suggestionsBefore = prefs.getString(suggestionPreferencesKey);
      await tester.tap(find.text(InsightCopy.notNow));
      await tester.pumpAndSettle();
      final shown = c.read(insightsProvider).snapshots.single;
      expect(shown.notNowOn, '2026-10-30');
      expect(cards(), findsNothing);
      expect(find.text(InsightCopy.premiumQuiet), findsOneWidget);
      expect(prefs.getString(circleJournalKey), journalBefore);
      expect(prefs.getString(suggestionPreferencesKey), suggestionsBefore);
      // Opening Insights again the same day brings nothing new (7-day
      // cadence; and I1, though eligible, waits its turn).
      await open(tester, reuse: c);
      expect(cards(), findsNothing);
      expect(c.read(insightsProvider).snapshots, hasLength(1));
      // It stays readable, set aside.
      await scrollTo(tester, find.textContaining(InsightCopy.setAside));
      expect(find.textContaining(nb(shown.text)), findsOneWidget);
    });
  });

  group('lapsed', () {
    testWidgets('what was shown stays readable; nothing new, nothing to '
        'apply; the calendar is theirs', (tester) async {
      await seedJournal(skipping());
      final paid = container();
      final shown = paid.read(insightsProvider.notifier).assess().added.single;
      await tester.pump(const Duration(milliseconds: 50));
      final c = await open(tester, status: EntitlementStatus.inactive, day: 1);
      final handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(RegExp(r'Circle closed in THIRTY')),
        findsWidgets,
      );
      handle.dispose();
      expect(cards(), findsNothing);
      await scrollTo(tester, find.textContaining(nb(shown.text)));
      expect(find.text(InsightCopy.lapsed), findsOneWidget);
      expect(find.textContaining(nb(shown.text)), findsOneWidget);
      expect(find.text(InsightCopy.leaveOut), findsNothing);
      expect(c.read(insightsProvider).snapshots, hasLength(1));
    });
  });

  group('Earlier', () {
    testWidgets('dated rows: a stale record readable and not actionable; '
        'four shown, the rest on request', (tester) async {
      await seedJournal(choosingHead());
      final records = [
        for (var k = 0; k < 6; k++)
          InsightSnapshot(
            id: 'old$k',
            family: InsightFamily.whatsChanged,
            generatedOn: '2026-0${k + 1}-15',
            wordingVersion: 1,
            text: 'Earlier observation $k.',
            facts: const {},
            evidence: const [],
            subject: 'insight.whats_changed:old$k',
            application: const NothingToChange('x'),
          ),
      ];
      await prefs.setString(
        insightsKey,
        jsonEncode(InsightsState(records).toJson()),
      );
      await open(tester, size: const Size(412, 2600));
      expect(find.textContaining('Earlier observation 5.'), findsOneWidget);
      expect(find.textContaining('Earlier observation 1.'), findsNothing);
      expect(
        find.textContaining(InsightCopy.noLongerCurrent),
        findsNWidgets(4),
      );
      await tester.tap(find.text(InsightCopy.showAllEarlier(6)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Earlier observation 0.'), findsOneWidget);
      expect(find.text(InsightCopy.showFewer), findsOneWidget);
    });

    testWidgets('an earlier Plan review is dated by the day its cycle '
        'ended, not the day it was shown', (tester) async {
      await seedJournal(choosingHead());
      const review = InsightSnapshot(
        id: 'review1',
        family: InsightFamily.planReview,
        generatedOn: '2026-09-20',
        wordingVersion: 1,
        text: 'Making room: what you told THIRTY, 2 August.',
        facts: {'endedOn': '2026-08-02'},
        evidence: [],
        subject: 'insight.plan_review:making_room#1',
        application: OpenPlanReview('making_room', 'making_room#1'),
      );
      await prefs.setString(
        insightsKey,
        jsonEncode(const InsightsState([review]).toJson()),
      );
      await open(tester, size: const Size(412, 2600));
      final name = InsightCopy.familyName(InsightFamily.planReview);
      expect(find.text('2 August · $name'), findsOneWidget);
      expect(find.text('20 September · $name'), findsNothing);
    });
  });

  group('Delete Circle history', () {
    testWidgets('the calendar clears, every snapshot goes, the current '
        'Insight withdraws; the Plan\'s place and kept Circles stay', (
      tester,
    ) async {
      await seedJournal(skipping());
      await seedPlans(
        CirclePlansState.empty.start('getting_going', today: '2026-10-20')!,
      );
      final c = container();
      c
          .read(keptCirclesProvider.notifier)
          .keepCircle(
            plan: CirclePlan(reading),
            need: head,
            circleId: '2026-10-28',
          );
      await open(tester, reuse: c);
      expect(cards(), findsOneWidget);
      // Delete from elsewhere in the app, then come back.
      Navigator.of(tester.element(find.byType(InsightsPage))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Circle history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.tap(find.text('open insights'));
      await tester.pumpAndSettle();
      expect(cards(), findsNothing);
      expect(c.read(insightsProvider).snapshots, isEmpty);
      expect(find.text(InsightCopy.premiumDayOne), findsOneWidget);
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel(RegExp(r'Circle closed')), findsNothing);
      handle.dispose();
      expect(
        c.read(circlePlansProvider).lifecycleOf('getting_going'),
        PlanLifecycle.active,
      );
      expect(c.read(keptCirclesProvider).kept, hasLength(1));
    });
  });

  group('accessibility and large text', () {
    for (final scale in [1.6, 2.0]) {
      testWidgets('${(scale * 100).toInt()}%: the evidence and the action '
          'are reachable, nothing overflows', (tester) async {
        await seedJournal(skipping());
        await open(tester, textScale: scale);
        expect(tester.takeException(), isNull);
        await scrollTo(tester, find.text(InsightCopy.leaveOut));
        expect(
          find.text(nb('From 4 of your Circles, 19 to 29 October.')),
          findsOneWidget,
        );
        final button = tester.getRect(find.text(InsightCopy.leaveOut));
        expect(button.height, greaterThan(0));
        await tester.tap(find.text(InsightCopy.leaveOut));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('TalkBack reads the Insight, then its action, then Not now', (
      tester,
    ) async {
      await seedJournal(skipping());
      final c = await open(tester);
      final handle = tester.ensureSemantics();
      final text = nb(c.read(insightsProvider).snapshots.single.text);
      final observation = tester.getRect(
        find.bySemanticsLabel(RegExp(RegExp.escape(text))),
      );
      final action = tester.getRect(
        find.bySemanticsLabel(InsightCopy.leaveOut),
      );
      final notNow = tester.getRect(find.bySemanticsLabel(InsightCopy.notNow));
      expect(observation.top, lessThan(action.top));
      expect(action.top, lessThan(notNow.top));
      // One stop holds the family, the observation and its evidence.
      expect(
        find.bySemanticsLabel(
          RegExp(
            '${InsightCopy.familyName(InsightFamily.skippedPart)}.*'
            '${RegExp.escape(text)}.*From 4 of your Circles',
            dotAll: true,
          ),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('Plans: the gentler setting (I2) and earlier reviews', () {
    Future<void> openPlan(
      WidgetTester tester,
      ProviderContainer c, {
      String? cycle,
    }) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.light,
            home: PlanDetailPage(planId: 'making_room', cycleId: cycle),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    final gentler = CirclePlansState.empty
        .start('making_room', today: '2026-10-20')!
        .keepGentler('making_room', today: '2026-10-25')!;

    for (final status in [
      EntitlementStatus.active,
      EntitlementStatus.inactive,
    ]) {
      testWidgets('${status.name}: the note shows, and "Use usual pacing" '
          'turns it off — never gated', (tester) async {
        await seedPlans(gentler);
        final c = container(status: status);
        await openPlan(tester, c);
        expect(find.text(PlanCopy.gentlerNote), findsOneWidget);
        await tester.tap(find.text(PlanCopy.usualPacing));
        await tester.pumpAndSettle();
        expect(
          c.read(circlePlansProvider).plans['making_room']!.current.isGentler,
          isFalse,
        );
        expect(find.text(PlanCopy.gentlerNote), findsNothing);
      });
    }

    testWidgets('a new cycle never shows it', (tester) async {
      await seedPlans(
        gentler
            .leave('making_room', today: '2026-10-26')!
            .goThroughAgain('making_room', today: '2026-10-27')!,
      );
      await openPlan(tester, container());
      expect(find.text(PlanCopy.gentlerNote), findsNothing);
    });

    testWidgets('an earlier cycle\'s review, as a record: Keep, never "go '
        'through it again" from the past', (tester) async {
      var plans = CirclePlansState.empty.start(
        'making_room',
        today: '2026-09-01',
      )!;
      for (var n = 1; n <= 5; n++) {
        plans = plans.recordGuided(
          PlanStageProvenance(
            planId: 'making_room',
            cycleId: 'making_room#1',
            stageNumber: n,
            stageId: 'making_room.$n',
          ),
          circleId: '2026-09-1$n',
          today: '2026-09-1$n',
          parts: const ['getItOut:6'],
          skipped: const [],
        );
      }
      plans = plans.goThroughAgain('making_room', today: '2026-10-01')!;
      await seedPlans(plans);
      await openPlan(tester, container(), cycle: 'making_room#1');
      expect(
        find.text(PlanCopy.earlierReviewHeading(1).toUpperCase()),
        findsOneWidget,
      );
      expect(find.text(PlanCopy.goThroughAgain), findsNothing);
      expect(find.text(PlanCopy.keepOne), findsOneWidget);
    });
  });
}
