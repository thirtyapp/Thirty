import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_stage_provenance.dart';

/// Billing as the app sees it, settable mid-test: the app reopened while the
/// entitlement is still being checked, a lookup that failed, an expiry.
class _Billing extends EntitlementNotifier {
  _Billing(this._initial);

  final EntitlementStatus _initial;

  @override
  EntitlementStatus build() => _initial;

  void set(EntitlementStatus status) => state = status;
}

/// The real store, except that a Plans write waits while [hold] is pending
/// — a slow write the start must not overtake.
class _HeldPrefs implements SharedPreferences {
  _HeldPrefs(this._inner);

  final SharedPreferences _inner;
  Completer<void>? hold;

  @override
  Future<bool> setString(String key, String value) async {
    if (key == circlePlansKey && hold != null) await hold!.future;
    return _inner.setString(key, value);
  }

  @override
  Set<String> getKeys() => _inner.getKeys();
  @override
  Object? get(String key) => _inner.get(key);
  @override
  bool? getBool(String key) => _inner.getBool(key);
  @override
  int? getInt(String key) => _inner.getInt(key);
  @override
  double? getDouble(String key) => _inner.getDouble(key);
  @override
  String? getString(String key) => _inner.getString(key);
  @override
  bool containsKey(String key) => _inner.containsKey(key);
  @override
  List<String>? getStringList(String key) => _inner.getStringList(key);
  @override
  Future<bool> setBool(String key, bool value) => _inner.setBool(key, value);
  @override
  Future<bool> setInt(String key, int value) => _inner.setInt(key, value);
  @override
  Future<bool> setDouble(String key, double value) =>
      _inner.setDouble(key, value);
  @override
  Future<bool> setStringList(String key, List<String> value) =>
      _inner.setStringList(key, value);
  @override
  Future<bool> remove(String key) => _inner.remove(key);
  @override
  Future<bool> commit() async => true;
  @override
  Future<bool> clear() => _inner.clear();
  @override
  Future<void> reload() => _inner.reload();
}

/// Audit remediation R2, J3 (founder decision D2): a stage Circle served
/// under Premium, started and then closed is guided exactly once — whatever
/// billing says at the moment of Close. Nothing served without Premium ever
/// gains a stage. Through the production providers, across restarts.
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

  /// The app (re)opened on day [day] after [morning], with billing at
  /// [status].
  ProviderContainer open(
    EntitlementStatus status, {
    int day = 0,
    Duration later = Duration.zero,
    SharedPreferences? store,
  }) {
    final now = morning.add(Duration(days: day)).add(later);
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(store ?? prefs),
        nowProvider.overrideWithValue(now),
        eventClockProvider.overrideWithValue(() => now),
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
  PlanCycle cycleOf(ProviderContainer c, String planId) =>
      c.read(circlePlansProvider).plans[planId]!.current;
  void billing(ProviderContainer c, EntitlementStatus status) =>
      (c.read(entitlementStatusProvider.notifier) as _Billing).set(status);

  Future<void> seed(CirclePlansState plans) =>
      prefs.setString(circlePlansKey, jsonEncode(plans.toJson()));

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

  /// Today's stage Circle, served and started under verified Premium.
  Future<ProviderContainer> servedAndStarted({
    String planId = 'getting_going',
    Intention need = energy,
    int through = 0,
  }) async {
    await seed(under(planId, through: through));
    final c = open(EntitlementStatus.active);
    today(c).chooseIntention(need, window: TimeWindow.about20);
    expect(offer(c).composed!.stage!.planId, planId);
    today(c).start();
    await settle();
    return c;
  }

  group('credit by provenance (D2)', () {
    test('served, started and closed while Premium stays active: guided '
        'once', () async {
      final c = await servedAndStarted();
      today(c).close();
      await settle();
      final cycle = cycleOf(c, 'getting_going');
      expect(cycle.cursor, 2);
      expect(cycle.latest(1)!.outcome, StageOutcome.guided);
      expect(cycle.records, hasLength(1));
    });

    for (final atClose in [
      EntitlementStatus.initializing,
      EntitlementStatus.unavailable,
      EntitlementStatus.inactive,
    ]) {
      test('served and started under Premium, the app reopened, closed while '
          'billing is ${atClose.name}: guided once, and it stays', () async {
        final c = await servedAndStarted();
        final stage = offer(c).composed!.stage!;
        final reopened = open(atClose, later: const Duration(minutes: 25));
        expect(
          reopened.read(recommendationProvider).status,
          RecommendationStatus.started,
        );
        expect(offer(reopened).composed!.stage!.stageId, stage.stageId);

        today(reopened).close();
        await settle();
        expect(cycleOf(reopened, 'getting_going').cursor, 2);
        expect(
          cycleOf(reopened, 'getting_going').latest(1)!.circleId,
          '2026-10-12',
        );

        // Billing resolving afterwards changes nothing; a restart neither.
        billing(reopened, EntitlementStatus.active);
        today(reopened).close();
        await settle();
        final after = open(
          EntitlementStatus.active,
          later: const Duration(hours: 1),
        );
        expect(cycleOf(after, 'getting_going').cursor, 2);
        expect(cycleOf(after, 'getting_going').records, hasLength(1));
      });
    }

    test('started before an expiry, closed after it, in the same session: '
        'the already-earned stage is credited', () async {
      final c = await servedAndStarted();
      billing(c, EntitlementStatus.inactive);
      today(c).close();
      await settle();
      expect(cycleOf(c, 'getting_going').cursor, 2);
    });

    test('repeated Close, a direct second credit and a restart: one advance '
        'only', () async {
      final c = await servedAndStarted();
      final stage = offer(c).composed!.stage!;
      billing(c, EntitlementStatus.initializing);
      today(c).close();
      today(c).close();
      c
          .read(circlePlansProvider.notifier)
          .recordGuided(
            stage,
            circleId: '2026-10-12',
            parts: const [],
            skipped: const [],
          );
      await settle();
      final reopened = open(EntitlementStatus.unavailable);
      today(reopened).close();
      await settle();
      expect(cycleOf(reopened, 'getting_going').cursor, 2);
      expect(cycleOf(reopened, 'getting_going').records, hasLength(1));
    });
  });

  /// What the saved Plans record says about the Circle served for [planId].
  Map<String, Object?>? savedServed(String planId) {
    final raw = jsonDecode(prefs.getString(circlePlansKey)!) as Map;
    return (raw['plans'] as Map)[planId]['lastServed'] as Map<String, Object?>?;
  }

  /// Today's stage Circle served under verified Premium, not started.
  Future<ProviderContainer> served() async {
    await seed(under('getting_going'));
    final c = open(EntitlementStatus.active);
    today(c).chooseIntention(energy, window: TimeWindow.about20);
    expect(offer(c).composed!.stage!.planId, 'getting_going');
    await settle();
    return c;
  }

  group('expiry before Start (R2, founder decision: Design A)', () {
    test('served under Premium, started only after a verified expiry, closed '
        'still lapsed: no credit, and the served evidence stays', () async {
      final c = await served();
      final stage = offer(c).composed!.stage!;
      billing(c, EntitlementStatus.inactive);
      today(c).start();
      await settle();
      today(c).close();
      await settle();

      expect(cycleOf(c, 'getting_going').cursor, 1);
      expect(cycleOf(c, 'getting_going').records, isEmpty);
      final plans = c.read(circlePlansProvider);
      expect(plans.wasServed(stage, circleId: '2026-10-12'), isTrue);
      expect(plans.creditsServed(stage, circleId: '2026-10-12'), isFalse);
      expect(savedServed('getting_going'), {
        'circleId': '2026-10-12',
        'stage': stage.toJson(),
        'startedAfterExpiry': true,
      });
      // The Circle itself stays: shown, started and closed as served.
      expect(offer(c).composed!.stage!.stageId, stage.stageId);
      expect(
        c.read(recommendationProvider).status,
        RecommendationStatus.closed,
      );
    });

    test('the app reopened after the expiry: started under verified '
        'inactive, closed — no credit', () async {
      await served();
      final lapsed = open(
        EntitlementStatus.inactive,
        later: const Duration(hours: 2),
      );
      expect(offer(lapsed).composed!.stage, isNotNull);
      today(lapsed).start();
      today(lapsed).close();
      await settle();
      expect(cycleOf(lapsed, 'getting_going').cursor, 1);
      expect(cycleOf(lapsed, 'getting_going').records, isEmpty);
    });

    for (final atClose in [
      EntitlementStatus.initializing,
      EntitlementStatus.unavailable,
    ]) {
      test('started after a verified expiry, reopened and closed while billing '
          'is ${atClose.name}: no credit, nor after another restart', () async {
        final c = await served();
        billing(c, EntitlementStatus.inactive);
        today(c).start();
        await settle();
        final reopened = open(atClose, later: const Duration(minutes: 25));
        expect(
          reopened.read(recommendationProvider).status,
          RecommendationStatus.started,
        );
        today(reopened).close();
        await settle();
        expect(cycleOf(reopened, 'getting_going').records, isEmpty);
        final after = open(atClose, later: const Duration(hours: 1));
        today(after).close();
        await settle();
        expect(cycleOf(after, 'getting_going').cursor, 1);
        expect(cycleOf(after, 'getting_going').records, isEmpty);
      });
    }

    test('started after a verified expiry, Premium verified again by Close: '
        'credited once, as Premium now', () async {
      final c = await served();
      billing(c, EntitlementStatus.inactive);
      today(c).start();
      await settle();
      billing(c, EntitlementStatus.active);
      today(c).close();
      today(c).close();
      await settle();
      final after = open(EntitlementStatus.unavailable);
      today(after).close();
      await settle();
      expect(cycleOf(after, 'getting_going').cursor, 2);
      expect(cycleOf(after, 'getting_going').records, hasLength(1));
    });

    for (final atStart in [
      EntitlementStatus.initializing,
      EntitlementStatus.unavailable,
    ]) {
      test('started while billing is ${atStart.name} — no proof of expiry — '
          'then verified inactive at Close: credited once, nothing noted on '
          'the served evidence', () async {
        final c = await served();
        billing(c, atStart);
        today(c).start();
        await settle();
        expect(
          savedServed('getting_going'),
          isNot(contains('startedAfterExpiry')),
        );
        billing(c, EntitlementStatus.inactive);
        today(c).close();
        await settle();
        expect(cycleOf(c, 'getting_going').cursor, 2);
        expect(cycleOf(c, 'getting_going').records, hasLength(1));
      });
    }

    test('started under verified Premium: a later expiry, a repeated Start and '
        'a lapsed reopen never revoke the earned credit', () async {
      final c = await servedAndStarted();
      billing(c, EntitlementStatus.inactive);
      today(c).start();
      await settle();
      expect(
        savedServed('getting_going'),
        isNot(contains('startedAfterExpiry')),
      );
      final lapsed = open(EntitlementStatus.inactive);
      today(lapsed).start();
      today(lapsed).close();
      await settle();
      expect(cycleOf(lapsed, 'getting_going').cursor, 2);
      expect(cycleOf(lapsed, 'getting_going').records, hasLength(1));
    });

    test('a second Start, a direct credit and a restart after a start past '
        'expiry: nothing credited', () async {
      final c = await served();
      final stage = offer(c).composed!.stage!;
      billing(c, EntitlementStatus.inactive);
      today(c).start();
      today(c).start();
      billing(c, EntitlementStatus.unavailable);
      c
          .read(circlePlansProvider.notifier)
          .recordGuided(
            stage,
            circleId: '2026-10-12',
            parts: const [],
            skipped: const [],
          );
      today(c).close();
      await settle();
      final reopened = open(EntitlementStatus.initializing);
      today(reopened).close();
      await settle();
      expect(cycleOf(reopened, 'getting_going').records, isEmpty);
      expect(
        reopened
            .read(circlePlansProvider)
            .creditsServed(stage, circleId: '2026-10-12'),
        isFalse,
      );
    });

    test('the start is never saved ahead of its note: while the Plans write '
        'is held, the start waits; once it lands, both are saved', () async {
      await seed(under('getting_going'));
      final held = _HeldPrefs(prefs);
      final c = open(EntitlementStatus.active, store: held);
      today(c).chooseIntention(energy, window: TimeWindow.about20);
      await settle();
      held.hold = Completer<void>();
      billing(c, EntitlementStatus.inactive);
      today(c).start();
      await settle();
      expect(prefs.getString(recommendationStatusKey), isNot('started'));
      expect(
        savedServed('getting_going'),
        isNot(contains('startedAfterExpiry')),
      );

      held.hold!.complete();
      await settle();
      expect(prefs.getString(recommendationStatusKey), 'started');
      expect(savedServed('getting_going')!['startedAfterExpiry'], isTrue);
    });
  });

  group('noteStart on the served evidence', () {
    const stage = PlanStageProvenance(
      planId: 'getting_going',
      cycleId: 'getting_going#1',
      stageNumber: 1,
      stageId: 'getting_going.1',
    );
    final servedState = under('getting_going').served(stage, circleId: 'c1');

    test('only the served Circle and its exact stage are noted, once', () {
      for (final (other, id) in [
        (stage, 'c2'),
        (
          const PlanStageProvenance(
            planId: 'getting_going',
            cycleId: 'getting_going#2',
            stageNumber: 1,
            stageId: 'getting_going.1',
          ),
          'c1',
        ),
        (
          const PlanStageProvenance(
            planId: 'getting_going',
            cycleId: 'getting_going#1',
            stageNumber: 2,
            stageId: 'getting_going.2',
          ),
          'c1',
        ),
        (
          const PlanStageProvenance(
            planId: 'getting_going',
            cycleId: 'getting_going#1',
            stageNumber: 1,
            stageId: 'getting_going.1',
            revisit: true,
          ),
          'c1',
        ),
      ]) {
        expect(
          servedState.noteStart(other, circleId: id, active: false),
          same(servedState),
        );
      }
      expect(
        under('getting_going').noteStart(stage, circleId: 'c1', active: false),
        isA<CirclePlansState>().having(
          (s) => s.wasServed(stage, circleId: 'c1'),
          'served',
          isFalse,
        ),
      );
      final lapsed = servedState.noteStart(
        stage,
        circleId: 'c1',
        active: false,
      );
      expect(lapsed.creditsServed(stage, circleId: 'c1'), isFalse);
      expect(lapsed.wasServed(stage, circleId: 'c1'), isTrue);
      expect(
        lapsed.noteStart(stage, circleId: 'c1', active: false),
        same(lapsed),
      );
      expect(
        servedState.noteStart(stage, circleId: 'c1', active: true),
        same(servedState),
      );
    });

    test('a start under verified Premium (after a start never saved) clears '
        'the note; the record round-trips, and one saved without it '
        'credits', () {
      final lapsed = servedState.noteStart(
        stage,
        circleId: 'c1',
        active: false,
      );
      expect(
        lapsed
            .noteStart(stage, circleId: 'c1', active: true)
            .creditsServed(stage, circleId: 'c1'),
        isTrue,
      );
      final reread = CirclePlansState.fromJson(
        jsonDecode(jsonEncode(lapsed.toJson())),
      )!;
      expect(reread.creditsServed(stage, circleId: 'c1'), isFalse);
      expect(reread.wasServed(stage, circleId: 'c1'), isTrue);
      expect(
        CirclePlansState.fromJson(
          jsonDecode(jsonEncode(servedState.toJson())),
        )!.creditsServed(stage, circleId: 'c1'),
        isTrue,
      );
    });
  });

  group('nothing without Premium provenance', () {
    test('a Free Circle closed while lapsed never moves the Plan, nor does a '
        'stage nobody served', () async {
      await seed(under('getting_going', through: 1));
      final before = jsonEncode(
        CirclePlansState.fromJson(
          jsonDecode(prefs.getString(circlePlansKey)!),
        )!.toJson(),
      );
      final lapsed = open(EntitlementStatus.inactive);
      today(lapsed).chooseIntention(energy, window: TimeWindow.about20);
      expect(offer(lapsed).composed, isNull);
      today(lapsed).start();
      today(lapsed).close();
      lapsed
          .read(circlePlansProvider.notifier)
          .recordGuided(
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
      expect(jsonEncode(lapsed.read(circlePlansProvider).toJson()), before);
    });

    test('a Circle made after an expiry gains no stage: a stage served '
        'yesterday credits nothing today', () async {
      await seed(under('getting_going'));
      final yesterday = open(EntitlementStatus.active);
      today(yesterday).chooseIntention(energy, window: TimeWindow.about20);
      final served = offer(yesterday).composed!.stage!;
      await settle();

      final expired = open(EntitlementStatus.inactive, day: 1);
      today(expired).chooseIntention(energy, window: TimeWindow.about20);
      expect(offer(expired).composed, isNull);
      today(expired).start();
      today(expired).close();
      expired
          .read(circlePlansProvider.notifier)
          .recordGuided(
            served,
            circleId: '2026-10-13',
            parts: const [],
            skipped: const [],
          );
      await settle();
      expect(cycleOf(expired, 'getting_going').cursor, 1);
      expect(cycleOf(expired, 'getting_going').records, isEmpty);
    });

    test('a kept Circle used today never moves the Plan, whatever billing '
        'says at Close', () async {
      await seed(under('making_room', through: 1));
      final c = open(EntitlementStatus.active);
      await c
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
      today(c).start();
      billing(c, EntitlementStatus.initializing);
      today(c).close();
      await settle();
      expect(cycleOf(c, 'making_room').cursor, 2);
      expect(cycleOf(c, 'making_room').records, hasLength(1));
    });
  });

  group('existing Plan rules still decide', () {
    test('a revisit served under Premium and closed while billing is being '
        'checked: recorded as the revisit, the place does not move', () async {
      await seed(under('slowing_down', through: 2));
      final c = open(EntitlementStatus.active);
      expect(
        c.read(circlePlansProvider.notifier).requestRevisit('slowing_down', 1),
        PlanActionResult.done,
      );
      today(c).chooseIntention(gentle, window: TimeWindow.about20);
      final stage = offer(c).composed!.stage!;
      expect((stage.stageNumber, stage.revisit), (1, true));
      today(c).start();
      await settle();
      final reopened = open(EntitlementStatus.initializing);
      today(reopened).close();
      await settle();
      final cycle = cycleOf(reopened, 'slowing_down');
      expect(cycle.cursor, 3);
      expect(cycle.pendingRevisit, isNull);
      expect(cycle.records.where((r) => r.revisit), hasLength(1));
    });

    // R8.2 final Plan lifecycle policy (founder directive, 2026-11-06)
    // replaces the earlier expectation here (not moved): a stage Circle
    // served and started before its Plan was paused is credited once its
    // Close is durable — billing still being checked at Close, as before —
    // and the Plan stays paused.
    test('a Plan paused after its stage Circle was served and started is '
        'credited at Close, and stays paused', () async {
      final c = await servedAndStarted();
      expect(
        c.read(circlePlansProvider.notifier).pause('getting_going'),
        PlanActionResult.done,
      );
      await settle();
      final reopened = open(EntitlementStatus.initializing);
      today(reopened).close();
      await settle();
      expect(cycleOf(reopened, 'getting_going').cursor, 2);
      expect(cycleOf(reopened, 'getting_going').records, hasLength(1));
      expect(
        reopened.read(circlePlansProvider).plans['getting_going']!.lifecycle,
        PlanLifecycle.paused,
      );
    });

    test('a Plan left after its stage Circle was served is not moved at '
        'Close', () async {
      final c = await servedAndStarted();
      expect(
        c.read(circlePlansProvider.notifier).leave('getting_going'),
        PlanActionResult.done,
      );
      await settle();
      final reopened = open(EntitlementStatus.unavailable);
      today(reopened).close();
      await settle();
      expect(cycleOf(reopened, 'getting_going').records, isEmpty);
    });

    test('a stage Circle replaced by an ordinary one ("Not this one today", '
        'nothing in the stage fits) credits nothing', () async {
      await seed(under('getting_going'));
      final c = open(EntitlementStatus.active);
      today(c).chooseIntention(energy, window: TimeWindow.about20);
      expect(today(c).replaceToday(ReplacementReason.notFeeling), isTrue);
      expect(offer(c).composed!.stage, isNull);
      today(c).start();
      billing(c, EntitlementStatus.initializing);
      today(c).close();
      await settle();
      expect(cycleOf(c, 'getting_going').cursor, 1);
    });

    test('nothing composes for the stage when every part is left out: Free\'s '
        'one activity, and no stage is ever credited as guided (the stages '
        'are set aside by the existing Plan rules)', () async {
      await seed(under('getting_going'));
      final c = open(EntitlementStatus.active);
      for (final id in ElementId.values) {
        await c.read(suggestionPreferencesProvider.notifier).leaveOut(id);
      }
      today(c).chooseIntention(energy, window: TimeWindow.about20);
      expect(offer(c).composed, isNull);
      today(c).start();
      billing(c, EntitlementStatus.unavailable);
      today(c).close();
      await settle();
      expect(
        cycleOf(
          c,
          'getting_going',
        ).records.where((r) => r.outcome == StageOutcome.guided),
        isEmpty,
      );
    });
  });
}
