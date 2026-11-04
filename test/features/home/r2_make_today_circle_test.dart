import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/presentation/widgets/make_today_circle_card.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';

/// Billing as the app sees it, settable mid-test.
class _Billing extends EntitlementNotifier {
  _Billing(this._initial);

  final EntitlementStatus _initial;

  @override
  EntitlementStatus build() => _initial;

  void set(EntitlementStatus status) => state = status;
}

/// A billing provider double for a same-day purchase or restore, through the
/// real [EntitlementNotifier].
class _Store implements EntitlementGateway {
  EntitlementStatus current = EntitlementStatus.inactive;
  PurchaseOutcome purchaseOutcome = PurchaseOutcome.purchased;
  final _updates = StreamController<EntitlementStatus>.broadcast();

  @override
  Stream<EntitlementStatus> get statusUpdates => _updates.stream;

  @override
  Future<EntitlementStatus> initialize() async => current;

  @override
  Future<MonthlyOffer?> monthlyOffer() async =>
      const MonthlyOffer(localizedPrice: '€3.99');

  @override
  Future<PurchaseOutcome> purchaseMonthly() async {
    if (purchaseOutcome == PurchaseOutcome.purchased) {
      current = EntitlementStatus.active;
    }
    return purchaseOutcome;
  }

  @override
  Future<RestoreOutcome> restore() async {
    current = EntitlementStatus.active;
    return RestoreOutcome.restored;
  }

  @override
  Future<String?> managementUrl() async => null;
}

/// Audit remediation R2, J2 (founder decision D1): Premium verified after
/// today's ordinary Free offer was decided can turn that unstarted offer
/// into today's composed Circle — once, and only on the user's tap.
void main() {
  final morning = DateTime(2026, 10, 12, 9);
  const energy = Intention.moreEnergy;
  const head = Intention.clearerHead;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer open({
    EntitlementStatus status = EntitlementStatus.initializing,
    _Store? store,
    int day = 0,
  }) {
    final now = morning.add(Duration(days: day));
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(now),
        eventClockProvider.overrideWithValue(() => now),
        if (store != null)
          entitlementGatewayProvider.overrideWithValue(store)
        else
          entitlementStatusProvider.overrideWith(() => _Billing(status)),
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

  RecommendationNotifier today(ProviderContainer c) =>
      c.read(recommendationProvider.notifier);
  Recommendation offer(ProviderContainer c) =>
      c.read(recommendationProvider).recommendation!;
  void billing(ProviderContainer c, EntitlementStatus status) =>
      (c.read(entitlementStatusProvider.notifier) as _Billing).set(status);
  List<CircleJournalEntry> journal(ProviderContainer c) =>
      c.read(circleJournalRepositoryProvider).readAll();

  /// Today's offer decided while billing was [before], then Premium
  /// verified.
  Future<ProviderContainer> freeThenActive(EntitlementStatus before) async {
    final c = open(status: before);
    today(c).chooseIntention(energy, window: TimeWindow.about20);
    expect(offer(c).composed, isNull);
    expect(offer(c).isFreeDecision, isTrue);
    await settle();
    billing(c, EntitlementStatus.active);
    return c;
  }

  group('entitlement transitions (D1)', () {
    for (final before in [
      EntitlementStatus.initializing,
      EntitlementStatus.unavailable,
      EntitlementStatus.inactive,
    ]) {
      test(
        '${before.name} → active: the Free offer stays until the tap, '
        'then becomes one composed Circle for the same need and time',
        () async {
          final c = await freeThenActive(before);
          final free = offer(c);
          // Never swapped by itself.
          await settle();
          expect(offer(c).activityId, free.activityId);
          expect(offer(c).composed, isNull);

          expect(today(c).upgradeToday(), UpgradeTodayResult.upgraded);
          final made = offer(c);
          expect(made.composed, isNotNull);
          expect(made.composed!.isKept, isFalse);
          expect(made.intention, free.intention);
          expect(made.timeWindow, free.timeWindow);
          expect(made.circleId, free.circleId);
          expect(made.canReplace, isTrue, reason: 'the day\'s one swap stays');
          expect(
            c.read(recommendationProvider).status,
            RecommendationStatus.notStarted,
          );
          await settle();
          // One journal record for today, naming the composed Circle.
          final entry = journal(c).single;
          expect(entry.circleId, '2026-10-12');
          expect(entry.session!.parts, made.composed!.plan.toWire());
          expect(entry.replacedFrom, isNull, reason: 'not a "Not this one"');
          expect(entry.startedAt, isNull);
        },
      );
    }

    test('inactive → active after a same-day purchase', () async {
      final store = _Store();
      final c = open(store: store);
      await c.read(entitlementStatusProvider.notifier).initialize();
      today(c).chooseIntention(energy, window: TimeWindow.about20);
      expect(today(c).upgradeToday(), UpgradeTodayResult.notAvailable);

      expect(
        await c.read(entitlementStatusProvider.notifier).purchaseMonthly(),
        PurchaseOutcome.purchased,
      );
      expect(today(c).upgradeToday(), UpgradeTodayResult.upgraded);
      expect(offer(c).composed, isNotNull);
    });

    test('inactive → active after a restore', () async {
      final store = _Store();
      final c = open(store: store);
      await c.read(entitlementStatusProvider.notifier).initialize();
      today(c).chooseIntention(energy, window: TimeWindow.about20);
      expect(
        await c.read(entitlementStatusProvider.notifier).restore(),
        RestoreOutcome.restored,
      );
      expect(today(c).upgradeToday(), UpgradeTodayResult.upgraded);
    });

    test('a pending purchase grants nothing: the Free offer stays and cannot '
        'be made into a Circle', () async {
      final store = _Store()..purchaseOutcome = PurchaseOutcome.pending;
      final c = open(store: store);
      await c.read(entitlementStatusProvider.notifier).initialize();
      today(c).chooseIntention(energy, window: TimeWindow.about20);
      expect(
        await c.read(entitlementStatusProvider.notifier).purchaseMonthly(),
        PurchaseOutcome.pending,
      );
      expect(c.read(premiumEntitlementProvider), isFalse);
      expect(today(c).upgradeToday(), UpgradeTodayResult.notAvailable);
      expect(offer(c).composed, isNull);
    });

    test('active before the choice composes as before — nothing to make', () {
      final c = open(status: EntitlementStatus.active);
      today(c).chooseIntention(energy, window: TimeWindow.about20);
      expect(offer(c).composed, isNotNull);
      expect(offer(c).isFreeDecision, isFalse);
      expect(today(c).upgradeToday(), UpgradeTodayResult.notAvailable);
    });
  });

  group('the explicit action (D1)', () {
    test('ignored: the Free offer stays, across a restart', () async {
      final c = await freeThenActive(EntitlementStatus.initializing);
      final free = offer(c);
      final before = jsonEncode(journal(c).single.toJson());
      await settle();
      final restarted = open(status: EntitlementStatus.active);
      expect(offer(restarted).activityId, free.activityId);
      expect(offer(restarted).composed, isNull);
      expect(jsonEncode(journal(restarted).single.toJson()), before);
    });

    test('a double tap makes exactly one Circle', () async {
      final c = await freeThenActive(EntitlementStatus.initializing);
      expect(today(c).upgradeToday(), UpgradeTodayResult.upgraded);
      final made = offer(c);
      expect(today(c).upgradeToday(), UpgradeTodayResult.notAvailable);
      expect(identical(offer(c), made), isTrue);
      await settle();
      expect(journal(c), hasLength(1));
    });

    test('nothing honest to compose: the original offer stays, nothing is '
        'written', () async {
      final c = await freeThenActive(EntitlementStatus.inactive);
      for (final id in ElementId.values) {
        await c.read(suggestionPreferencesProvider.notifier).leaveOut(id);
      }
      final free = offer(c);
      final before = jsonEncode(journal(c).single.toJson());
      expect(today(c).upgradeToday(), UpgradeTodayResult.noComposition);
      expect(identical(offer(c), free), isTrue);
      await settle();
      expect(jsonEncode(journal(c).single.toJson()), before);
      expect(offer(open(status: EntitlementStatus.active)).composed, isNull);
    });

    test('a restart before the tap: still offered; after it: the made '
        'Circle is restored, never the Free one', () async {
      final c = open(status: EntitlementStatus.initializing);
      today(c).chooseIntention(energy, window: TimeWindow.about20);
      await settle();
      final reopened = open(status: EntitlementStatus.active);
      expect(offer(reopened).isFreeDecision, isTrue);
      expect(today(reopened).upgradeToday(), UpgradeTodayResult.upgraded);
      final made = offer(reopened).composed!;
      await settle();
      for (final status in [
        EntitlementStatus.active,
        EntitlementStatus.initializing,
        EntitlementStatus.inactive,
      ]) {
        final again = open(status: status);
        expect(offer(again).composed!.plan.toWire(), made.plan.toWire());
        expect(today(again).upgradeToday(), UpgradeTodayResult.notAvailable);
      }
    });
  });

  group('never for a committed or owned day (D1)', () {
    test('a started Free Circle', () async {
      final c = await freeThenActive(EntitlementStatus.initializing);
      today(c).start();
      expect(today(c).upgradeToday(), UpgradeTodayResult.notAvailable);
      expect(offer(c).composed, isNull);
    });

    test('a closed Free Circle', () async {
      final c = await freeThenActive(EntitlementStatus.initializing);
      today(c).start();
      today(c).close();
      expect(today(c).upgradeToday(), UpgradeTodayResult.notAvailable);
    });

    test('a replaced Free offer ("Not this one today")', () async {
      final c = open(status: EntitlementStatus.inactive);
      today(c).chooseIntention(energy, window: TimeWindow.about20);
      expect(today(c).replaceToday(ReplacementReason.notFeeling), isTrue);
      billing(c, EntitlementStatus.active);
      expect(today(c).upgradeToday(), UpgradeTodayResult.notAvailable);
    });

    test('a kept Circle used today', () async {
      final c = open(status: EntitlementStatus.inactive);
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
      expect(
        today(c).useOwnedToday(
          keptCircleId: c.read(keptCirclesProvider).kept.single.id,
        ),
        UseTodayResult.used,
      );
      billing(c, EntitlementStatus.active);
      expect(today(c).upgradeToday(), UpgradeTodayResult.notAvailable);
      expect(offer(c).composed!.isKept, isTrue);
    });

    test(
      'a Premium day\'s Free fallback (no honest composition then)',
      () async {
        final c = open(status: EntitlementStatus.active);
        for (final id in ElementId.values) {
          await c.read(suggestionPreferencesProvider.notifier).leaveOut(id);
        }
        today(c).chooseIntention(energy, window: TimeWindow.about20);
        expect(offer(c).composerFellBack, isTrue);
        expect(today(c).upgradeToday(), UpgradeTodayResult.notAvailable);
      },
    );
  });

  group('what the upgrade leaves alone (D1)', () {
    test('a stage Circle made by the tap moves no Plan until it is started '
        'and closed', () async {
      await prefs.setString(
        circlePlansKey,
        jsonEncode(
          CirclePlansState.empty
              .start('getting_going', today: '2026-10-01')!
              .toJson(),
        ),
      );
      final c = await freeThenActive(EntitlementStatus.initializing);
      expect(today(c).upgradeToday(), UpgradeTodayResult.upgraded);
      expect(offer(c).composed!.stage!.stageNumber, 1);
      await settle();
      PlanCycle cycle() =>
          c.read(circlePlansProvider).plans['getting_going']!.current;
      expect(cycle().cursor, 1);
      expect(cycle().records, isEmpty);
      today(c).start();
      today(c).close();
      await settle();
      expect(cycle().cursor, 2);
      expect(cycle().records, hasLength(1));
    });

    test('earlier History and kept Circles are untouched', () async {
      final day0 = open(status: EntitlementStatus.active);
      today(day0).chooseIntention(head, window: TimeWindow.about20);
      today(day0).start();
      today(day0).close();
      await settle();
      day0
          .read(keptCirclesProvider.notifier)
          .keepCircle(
            plan: offer(day0).composed!.plan,
            need: head,
            circleId: '2026-10-12',
          );
      await settle();
      final yesterday = jsonEncode(journal(day0).single.toJson());
      final kept = jsonEncode([
        for (final k in day0.read(keptCirclesProvider).kept) k.toJson(),
      ]);

      final day1 = open(status: EntitlementStatus.initializing, day: 1);
      today(day1).chooseIntention(energy, window: TimeWindow.about20);
      billing(day1, EntitlementStatus.active);
      expect(today(day1).upgradeToday(), UpgradeTodayResult.upgraded);
      await settle();
      final entries = journal(day1);
      expect(entries, hasLength(2));
      expect(jsonEncode(entries.first.toJson()), yesterday);
      expect(
        jsonEncode([
          for (final k in day1.read(keptCirclesProvider).kept) k.toJson(),
        ]),
        kept,
      );
    });
  });

  group('MakeTodayCircleCard', () {
    Future<ProviderContainer> pumpCard(
      WidgetTester tester, {
      required EntitlementStatus status,
      double textScale = 1,
    }) async {
      final c = open(status: status);
      today(c).chooseIntention(energy, window: TimeWindow.about20);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
              child: const Scaffold(body: MakeTodayCircleCard()),
            ),
          ),
        ),
      );
      return c;
    }

    testWidgets('hidden until Premium is verified; then one quiet row with '
        'the one action', (tester) async {
      final c = await pumpCard(tester, status: EntitlementStatus.initializing);
      expect(find.text(MakeTodayCircleCopy.action), findsNothing);
      billing(c, EntitlementStatus.unavailable);
      await tester.pump();
      expect(find.text(MakeTodayCircleCopy.action), findsNothing);
      billing(c, EntitlementStatus.active);
      await tester.pump();
      expect(find.text(MakeTodayCircleCopy.offer), findsOneWidget);
      expect(find.text(MakeTodayCircleCopy.action), findsOneWidget);
      // The offer is untouched until the tap.
      expect(offer(c).composed, isNull);

      await tester.tap(find.text(MakeTodayCircleCopy.action));
      await tester.pump();
      expect(offer(c).composed, isNotNull);
      expect(find.text(MakeTodayCircleCopy.action), findsNothing);
    });

    testWidgets('gone once today\'s Circle has started', (tester) async {
      final c = await pumpCard(tester, status: EntitlementStatus.active);
      // Decided as Premium: nothing to make.
      expect(find.text(MakeTodayCircleCopy.action), findsNothing);
      expect(offer(c).composed, isNotNull);
    });

    testWidgets('nothing to compose: says so calmly, keeps the offer, no '
        'second try', (tester) async {
      final c = await pumpCard(tester, status: EntitlementStatus.inactive);
      for (final id in ElementId.values) {
        await c.read(suggestionPreferencesProvider.notifier).leaveOut(id);
      }
      billing(c, EntitlementStatus.active);
      await tester.pump();
      await tester.tap(find.text(MakeTodayCircleCopy.action));
      await tester.pump();
      expect(find.text(MakeTodayCircleCopy.noFit), findsOneWidget);
      expect(find.text(MakeTodayCircleCopy.action), findsNothing);
      expect(offer(c).composed, isNull);
    });

    testWidgets('readable at 2× text: no overflow, the action reachable', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = await pumpCard(
        tester,
        status: EntitlementStatus.initializing,
        textScale: 2,
      );
      billing(c, EntitlementStatus.active);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(TextButton)).height,
        greaterThanOrEqualTo(48),
      );
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel(MakeTodayCircleCopy.action), findsOneWidget);
      semantics.dispose();
    });
  });
}
