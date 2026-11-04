import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/insights/domain/insight_engine.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';

/// An entitlement the test can move, as billing would mid-session.
class _MovableEntitlement extends EntitlementNotifier {
  _MovableEntitlement(this._initial);

  final EntitlementStatus _initial;

  @override
  EntitlementStatus build() => _initial;

  void move(EntitlementStatus next) => state = next;
}

/// Audit remediation R5 (Audit #2 A2-05): Insight 4's Keep of a Circle the
/// user already has in History is ownership, and "Keep is never gated"
/// (PRODUCT_V2_CONTRACT "Kept Circles and Yours"; ADR-024 §3). A valid I4
/// shown while Premium was active keeps its Keep after a lapse — within the
/// same staleness, duplicate and eight-Circle checks. Generating Insights,
/// every other application and "Not now" stay Premium.
void main() {
  final morning = DateTime(2026, 10, 30, 9);
  const head = Intention.clearerHead;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

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
          () => _MovableEntitlement(status),
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

  void moveTo(ProviderContainer c, EntitlementStatus status) =>
      (c.read(entitlementStatusProvider.notifier) as _MovableEntitlement).move(
        status,
      );

  CirclePart part(ElementId e) => CirclePart(e, elementOf(e).minutes);
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
      session: parts.isEmpty
          ? null
          : CircleSessionRecord(
              title: 'Circle',
              parts: CirclePlan(parts).toWire(),
              skipped: [for (final e in skipped) e.name],
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

  /// I4's evidence: Writing in all 4 useful Clearer Head Circles, in none
  /// of the 3 others. Its Keep targets the most recent: 2026-10-29.
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

  /// I1's evidence alone: Clearer Head chosen on 5 days across two weeks.
  List<CircleJournalEntry> choosingHead() => [
    for (final ago in [1, 5, 9, 13, 14]) entry(ago, head),
  ];

  /// An I4 shown while Premium was active, its Keep still current.
  Future<InsightSnapshot> showI4WhilePaid() async {
    await seedJournal(usefulWriting());
    final paid = open();
    final shown = insights(paid).assess().added.single;
    expect(shown.family, InsightFamily.usefulInCommon);
    expect(shown.application, isA<KeepCircleFromHistory>());
    await settle();
    return shown;
  }

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

  group('R5 — a shown I4 keeps its Keep after a lapse (A2-05)', () {
    test('Premium active: the I4 Keep keeps the Circle (unchanged)', () async {
      final shown = await showI4WhilePaid();
      final c = open();
      expect(insights(c).apply(shown.id), InsightActionResult.done);
      expect(
        c.read(keptCirclesProvider).kept.single.fromCircleId,
        '2026-10-29',
      );
    });

    for (final status in [
      EntitlementStatus.inactive,
      EntitlementStatus.unavailable,
      EntitlementStatus.initializing,
    ]) {
      test('${status.name}: the shown I4 still keeps its Circle, once — '
          'and is recorded as applied', () async {
        final shown = await showI4WhilePaid();
        final lapsed = open(status: status, day: 1);
        expect(insights(lapsed).status(shown), InsightStatus.current);
        expect(insights(lapsed).apply(shown.id), InsightActionResult.done);
        final kept = lapsed.read(keptCirclesProvider).kept;
        expect(kept, hasLength(1));
        expect(kept.single.fromCircleId, '2026-10-29');
        expect(kept.single.plan.toWire(), CirclePlan(writing).toWire());
        expect(
          lapsed.read(insightsProvider).byId(shown.id)!.appliedOn,
          dateKey(morning.add(const Duration(days: 1))),
        );
        expect(
          insights(lapsed).apply(shown.id),
          InsightActionResult.alreadyApplied,
        );
        expect(lapsed.read(keptCirclesProvider).kept, hasLength(1));
      });
    }

    test('lapsed: nothing new is generated, and every other application '
        'and "Not now" stay Premium — even called directly', () async {
      final shown = await showI4WhilePaid();
      final lapsed = open(status: EntitlementStatus.inactive, day: 8);
      expect(insights(lapsed).assess().added, isEmpty);
      expect(
        insights(lapsed).notNow(shown.id),
        InsightActionResult.needsPremium,
      );
      expect(lapsed.read(insightsProvider).byId(shown.id)!.notNowOn, isNull);

      // A Plan direction (I1) shown while paid: still Premium to apply.
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      await seedJournal(choosingHead());
      final paid = open();
      final i1 = insights(paid).assess().added.single;
      expect(i1.application, isA<PlanDirection>());
      await settle();
      final lapsedAgain = open(status: EntitlementStatus.inactive, day: 7);
      expect(
        insights(lapsedAgain).apply(i1.id),
        InsightActionResult.needsPremium,
      );
      expect(
        lapsedAgain.read(circlePlansProvider).lifecycleOf('making_room'),
        PlanLifecycle.neverStarted,
      );
    });

    test('lapsed: I3 "Leave it out" — whose own domain has no Premium '
        'check — is still refused, and nothing is left out', () async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      final window = [
        part(ElementId.openWindow),
        part(ElementId.standingStretch),
        part(ElementId.sitAMinute),
      ];
      await seedJournal([
        for (final ago in [2, 4, 6, 8, 10, 12, 15])
          entry(ago, head, parts: reading),
        for (final (k, ago) in [1, 5, 9, 11].indexed)
          entry(
            ago,
            Intention.moreEnergy,
            parts: window,
            skipped: k == 1 ? const {} : {ElementId.openWindow},
          ),
      ]);
      final paid = open();
      final i3 = insights(paid).assess().added.single;
      expect(i3.application, isA<LeaveOutPart>());
      await settle();
      final lapsed = open(status: EntitlementStatus.inactive, day: 1);
      expect(insights(lapsed).apply(i3.id), InsightActionResult.needsPremium);
      await settle();
      expect(
        open(
          status: EntitlementStatus.inactive,
          day: 1,
        ).read(suggestionPreferencesProvider).leftOut,
        isEmpty,
      );
    });

    test('lapsed: an I4 no longer true (stale) keeps nothing', () async {
      final shown = await showI4WhilePaid();
      // Four more useful Clearer Head Circles without Writing: Writing is
      // now in 4 of 8 useful Circles, below the claim's threshold.
      await seedJournal([
        ...usefulWriting(),
        for (final ago in [0, 2, 4, 6])
          entry(
            ago,
            head,
            parts: reading,
            answer: CircleUsefulnessResponse.veryUseful,
          ),
      ]);
      final lapsed = open(status: EntitlementStatus.inactive, day: 1);
      expect(insights(lapsed).status(shown), InsightStatus.stale);
      expect(
        insights(lapsed).apply(shown.id),
        InsightActionResult.notAvailable,
      );
      expect(lapsed.read(keptCirclesProvider).kept, isEmpty);
      expect(lapsed.read(insightsProvider).byId(shown.id)!.appliedOn, isNull);
    });

    test('lapsed: an I4 set aside with "Not now" keeps nothing', () async {
      final shown = await showI4WhilePaid();
      final paid = open();
      expect(insights(paid).notNow(shown.id), InsightActionResult.done);
      await settle();
      final lapsed = open(status: EntitlementStatus.inactive, day: 1);
      expect(
        insights(lapsed).status(lapsed.read(insightsProvider).byId(shown.id)!),
        InsightStatus.notNow,
      );
      expect(
        insights(lapsed).apply(shown.id),
        InsightActionResult.notAvailable,
      );
      expect(lapsed.read(keptCirclesProvider).kept, isEmpty);
    });

    test('lapsed: an id THIRTY never showed is still refused as Premium '
        '— no new path into the service', () async {
      await seedJournal(usefulWriting());
      final lapsed = open(status: EntitlementStatus.inactive);
      expect(
        insights(lapsed).apply('not-a-snapshot'),
        InsightActionResult.needsPremium,
      );
      expect(lapsed.read(keptCirclesProvider).kept, isEmpty);
      expect(lapsed.read(insightsProvider).snapshots, isEmpty);
    });

    test('lapsed with eight kept: the truthful limit, nothing replaced, '
        'nothing recorded', () async {
      final shown = await showI4WhilePaid();
      final lapsed = open(status: EntitlementStatus.inactive, day: 1);
      keepEight(lapsed);
      final before = [
        for (final k in lapsed.read(keptCirclesProvider).kept) k.id,
      ];
      expect(
        insights(lapsed).apply(shown.id),
        InsightActionResult.keptLimitReached,
      );
      expect([
        for (final k in lapsed.read(keptCirclesProvider).kept) k.id,
      ], before);
      expect(lapsed.read(insightsProvider).byId(shown.id)!.appliedOn, isNull);
    });

    test('lapsed after Delete Circle history: the Insight is gone, nothing '
        'to keep', () async {
      final shown = await showI4WhilePaid();
      final lapsed = open(status: EntitlementStatus.inactive, day: 1);
      await insights(lapsed).forgetAll();
      expect(insights(lapsed).apply(shown.id), isNot(InsightActionResult.done));
      expect(lapsed.read(keptCirclesProvider).kept, isEmpty);
    });

    test('late entitlement: a lapse mid-session keeps the Keep; generation '
        'follows the entitlement as it changes', () async {
      await seedJournal(usefulWriting());
      final c = open(status: EntitlementStatus.initializing);
      expect(insights(c).assess().added, isEmpty);
      moveTo(c, EntitlementStatus.active);
      final shown = insights(c).assess().added.single;
      expect(shown.application, isA<KeepCircleFromHistory>());
      moveTo(c, EntitlementStatus.inactive);
      expect(c.read(premiumEntitlementProvider), isFalse);
      expect(insights(c).assess().added, isEmpty);
      expect(insights(c).apply(shown.id), InsightActionResult.done);
      expect(c.read(keptCirclesProvider).kept, hasLength(1));
    });

    test('restart while lapsed: the kept Circle and the applied record '
        'survive; a repeat keeps nothing twice', () async {
      final shown = await showI4WhilePaid();
      final lapsed = open(status: EntitlementStatus.inactive, day: 1);
      expect(insights(lapsed).apply(shown.id), InsightActionResult.done);
      await settle();
      final restarted = open(status: EntitlementStatus.inactive, day: 2);
      final kept = restarted.read(keptCirclesProvider).kept;
      expect(kept, hasLength(1));
      expect(kept.single.fromCircleId, '2026-10-29');
      expect(
        insights(
          restarted,
        ).status(restarted.read(insightsProvider).byId(shown.id)!),
        InsightStatus.applied,
      );
      expect(
        insights(restarted).apply(shown.id),
        InsightActionResult.alreadyApplied,
      );
      expect(restarted.read(keptCirclesProvider).kept, hasLength(1));
    });
  });
}
