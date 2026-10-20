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
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/personal_circle/application/guidance_voice.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/composed_session.dart';
import 'package:thirty/features/personal_circle/domain/kept_circle.dart';
import 'package:thirty/features/personal_circle/domain/spoken_cues.dart';
import 'package:thirty/features/personal_circle/presentation/skip_part_sheet.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';

class _SettledEntitlement extends EntitlementNotifier {
  _SettledEntitlement(this._status);

  final EntitlementStatus _status;

  @override
  EntitlementStatus build() => _status;
}

class _SilentPlayer implements GuidanceAudioPlayer {
  @override
  Future<void> play(List<String> assets, {bool deferToScreenReader = true}) =>
      Future.value();

  @override
  Future<void> stop() => Future.value();
}

/// B7 — the final entitlement audit at the service boundary (ADR-024 §13;
/// contract, Free / Premium / after lapse). Every paid operation is called
/// on its own service, never through a widget, in each billing state the
/// app can be in. Billing reaches THIRTY as four values: RevenueCat reports
/// a grace period and a cancelled-but-paid period as `isActive`, which the
/// gateway maps to [EntitlementStatus.active]; true expiry, like never
/// having subscribed, is [EntitlementStatus.inactive] (both mappings tested
/// in `premium_access_test.dart`). "Expired" below is inactive with the
/// Premium state a subscriber left behind.
void main() {
  final morning = DateTime(2026, 10, 30, 9);
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer open(EntitlementStatus status, {int day = 0}) {
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
        bundledGuidanceVoicesProvider.overrideWithValue(
          ThirtyVoice.values.toSet(),
        ),
        guidanceAudioPlayerProvider.overrideWithValue(_SilentPlayer()),
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

  /// Clearer Head chosen on 5 days across two weeks — enough for one
  /// Insight (I1) on Premium.
  Future<void> seedHistory() => prefs.setString(
    circleJournalKey,
    jsonEncode({
      'schemaVersion': circleJournalSchemaVersion,
      'entries': [
        for (final ago in [1, 5, 9, 13, 14])
          () {
            final date = morning.subtract(Duration(days: ago));
            return CircleJournalEntry(
              schemaVersion: circleJournalSchemaVersion,
              circleId: dateKey(date),
              localDate: dateKey(date),
              direction: Intention.clearerHead,
              activityId: ActivityId.values.first,
              catalogVersion: catalogVersion,
              shownAt: date,
              startedAt: date,
              closedAt: date,
            ).toJson();
          }(),
      ],
    }),
  );

  final keptPlan = CirclePlan.fromWire(const [
    'getItOut:6',
    'chooseOne:1',
    'clearCorner:8',
  ])!;

  /// What a subscriber leaves behind: an Insight shown and applied (Making
  /// room started), the gentler setting on it, a paused second Plan, and a
  /// kept Circle.
  Future<String> subscriberState() async {
    await seedHistory();
    final paid = open(EntitlementStatus.active);
    final insights = paid.read(insightsProvider.notifier);
    final shown = insights.assess().added.single;
    expect(insights.apply(shown.id), InsightActionResult.done);
    final plans = paid.read(circlePlansProvider.notifier);
    expect(plans.keepGentler('making_room'), PlanActionResult.done);
    expect(plans.start('getting_going'), PlanActionResult.done);
    expect(plans.pause('getting_going'), PlanActionResult.done);
    expect(plans.resume('making_room'), PlanActionResult.done);
    paid
        .read(keptCirclesProvider.notifier)
        .keepCircle(
          plan: keptPlan,
          need: Intention.clearerHead,
          circleId: '2026-10-29',
        );
    await settle();
    return shown.text;
  }

  // The seven billing states the brief names, as billing reports them.
  const billing = <(String, EntitlementStatus)>[
    ('initializing', EntitlementStatus.initializing),
    ('unavailable', EntitlementStatus.unavailable),
    ('inactive (never subscribed)', EntitlementStatus.inactive),
    ('active', EntitlementStatus.active),
    ('grace period', EntitlementStatus.active),
    ('cancelled but paid through the period', EntitlementStatus.active),
  ];

  for (final (label, status) in billing) {
    final paid = status == EntitlementStatus.active;
    group('$label → ${status.name}', () {
      test('Personal Guided Circle: composed only while paid', () {
        final c = open(status);
        expect(c.read(premiumEntitlementProvider), paid);
        c
            .read(recommendationProvider.notifier)
            .chooseIntention(Intention.clearerHead, window: TimeWindow.about20);
        final today = c.read(recommendationProvider).recommendation!;
        expect(today.composed != null, paid);
        expect(today.reason == RecommendationReason.personalCircle, paid);
      });

      test("THIRTY's voice: offered and speaking only while paid", () {
        final c = open(status);
        expect(c.read(spokenGuidanceOfferedProvider), paid);
        expect(c.read(guidanceVoiceProvider).available, paid);
      });

      test('Plans: start, carry on, repeat, revisit and gentler need '
          'Premium; pause, leave and gentler off never do', () {
        final c = open(status);
        final plans = c.read(circlePlansProvider.notifier);
        final gate = paid
            ? isNot(PlanActionResult.needsPremium)
            : equals(PlanActionResult.needsPremium);
        expect(plans.start('slowing_down'), gate);
        expect(plans.resume('slowing_down'), gate);
        expect(plans.goThroughAgain('slowing_down'), gate);
        expect(plans.requestRevisit('slowing_down', 1), gate);
        expect(plans.keepGentler('slowing_down'), gate);
        expect(
          c.read(circlePlansProvider).lifecycleOf('slowing_down'),
          paid ? PlanLifecycle.active : PlanLifecycle.neverStarted,
        );
        for (final ungated in [
          plans.stopGentler('slowing_down'),
          plans.pause('slowing_down'),
          plans.leave('slowing_down'),
        ]) {
          expect(ungated, isNot(PlanActionResult.needsPremium));
        }
      });

      test('Insights: a new assessment and its application only while '
          'paid', () async {
        await seedHistory();
        final c = open(status);
        final insights = c.read(insightsProvider.notifier);
        final added = insights.assess().added;
        expect(added, paid ? hasLength(1) : isEmpty);
        if (paid) {
          expect(insights.apply(added.single.id), InsightActionResult.done);
        } else {
          expect(c.read(insightsProvider).snapshots, isEmpty);
          expect(insights.apply('any'), InsightActionResult.needsPremium);
          expect(insights.notNow('any'), InsightActionResult.needsPremium);
        }
      });

      test('Keep is never gated', () {
        final c = open(status);
        final kept = c
            .read(keptCirclesProvider.notifier)
            .keepCircle(
              plan: keptPlan,
              need: Intention.clearerHead,
              circleId: '2026-10-30',
            );
        expect(kept, isA<KeptCircle>());
      });

      test('Leave it out: a composer control — recorded only while paid, '
          'even when a kept Circle runs on a Free day', () async {
        final c = open(status);
        c
            .read(keptCirclesProvider.notifier)
            .keepCircle(
              plan: keptPlan,
              need: Intention.clearerHead,
              circleId: '2026-10-29',
            );
        final today = c.read(recommendationProvider.notifier);
        expect(
          today.useOwnedToday(
            keptCircleId: c.read(keptCirclesProvider).kept.single.id,
          ),
          UseTodayResult.used,
        );
        today.start();
        today.skipPart(leaveOut: true);
        await settle();
        // The skip itself is everyone's.
        expect(c.read(recommendationProvider).skipped, isNotEmpty);
        expect(
          c.read(suggestionPreferencesProvider).elementsLeftOut,
          paid ? hasLength(1) : isEmpty,
        );
      });
    });
  }

  group('expired (true expiry after a subscription) → inactive', () {
    test('new Premium work stops, even called directly; everything the '
        'subscriber had stays readable and theirs', () async {
      final shownText = await subscriberState();
      final lapsed = open(EntitlementStatus.inactive, day: 1);

      // Readable: History, the Insight shown, the Plans' places, Yours.
      expect(
        lapsed.read(circleJournalRepositoryProvider).readAll(),
        hasLength(5),
      );
      expect(lapsed.read(insightsProvider).snapshots.single.text, shownText);
      final plans = lapsed.read(circlePlansProvider);
      expect(plans.lifecycleOf('making_room'), PlanLifecycle.active);
      expect(plans.lifecycleOf('getting_going'), PlanLifecycle.paused);
      expect(plans.plans['making_room']!.current.gentlerSince, isNotNull);
      expect(lapsed.read(keptCirclesProvider).kept, hasLength(1));

      // Today is Free's again: no composition, no steering, no voice.
      lapsed
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.clearerHead, window: TimeWindow.about20);
      final today = lapsed.read(recommendationProvider).recommendation!;
      expect(today.composed, isNull);
      expect(lapsed.read(guidanceVoiceProvider).available, isFalse);
      expect(
        lapsed.read(circlePlansProvider).plans['making_room']!.current.cursor,
        plans.plans['making_room']!.current.cursor,
      );

      // New paid operations are refused by their services.
      final planner = lapsed.read(circlePlansProvider.notifier);
      expect(planner.resume('getting_going'), PlanActionResult.needsPremium);
      expect(
        planner.requestRevisit('making_room', 1),
        PlanActionResult.needsPremium,
      );
      final insights = lapsed.read(insightsProvider.notifier);
      expect(insights.assess().added, isEmpty);
      expect(
        insights.apply(lapsed.read(insightsProvider).snapshots.single.id),
        InsightActionResult.needsPremium,
      );

      // Giving something up never needs Premium: gentler off, pause, leave.
      expect(planner.stopGentler('making_room'), PlanActionResult.done);
      expect(
        lapsed
            .read(circlePlansProvider)
            .plans['making_room']!
            .current
            .gentlerSince,
        isNull,
      );
      expect(planner.pause('making_room'), PlanActionResult.done);

      // Use it today stays the user's own, on screen.
      final kept = lapsed.read(keptCirclesProvider).kept.single;
      final freshDay = open(EntitlementStatus.inactive, day: 2);
      expect(
        freshDay
            .read(recommendationProvider.notifier)
            .useOwnedToday(keptCircleId: kept.id),
        UseTodayResult.used,
      );
      expect(
        freshDay.read(recommendationProvider).recommendation!.composed!.isKept,
        isTrue,
      );
    });

    test('resubscribing restores the paid services where they were', () async {
      await subscriberState();
      final back = open(EntitlementStatus.active, day: 3);
      expect(
        back.read(circlePlansProvider.notifier).resume('getting_going'),
        PlanActionResult.done,
      );
      back
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.gentlerPace, window: TimeWindow.about20);
      expect(
        back.read(recommendationProvider).recommendation!.composed,
        isNotNull,
      );
    });
  });

  for (final offerLeaveOut in [true, false]) {
    testWidgets('the skip sheet offers Leave it out only with Premium '
        '(offered: $offerLeaveOut)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: SkipPartSheet(offerLeaveOut: offerLeaveOut)),
        ),
      );
      expect(find.text(ComposedCopy.skipToday), findsOneWidget);
      expect(
        find.text(ComposedCopy.leaveOut),
        offerLeaveOut ? findsOneWidget : findsNothing,
      );
      expect(find.text(ComposedCopy.keepGoing), findsOneWidget);
    });
  }
}
