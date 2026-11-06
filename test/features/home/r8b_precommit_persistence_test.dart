import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/storage/confirmed_write.dart';
import 'package:thirty/core/storage/store_save_failures.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_history_deletion.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/insights/domain/insight_engine.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// Fails only the *removal* of [key]; its writes go through.
class _RemovalFaultDisk extends FaultDisk {
  _RemovalFaultDisk(super.data);
  String? key;
  DiskFault? fault;

  @override
  Future<bool> remove(String k) async {
    if (k == 'flutter.$key') {
      if (fault == DiskFault.throws) throw StateError('removal failed');
      if (fault == DiskFault.returnsFalse) return false;
    }
    return super.remove(k);
  }
}

/// Audit remediation R8 — the pre-commit gate (founder directive,
/// 2026-11-04):
/// - P2: a recovery record whose removal fails after every required write
///   landed is retried, never reported as "not saved";
/// - a persistent History failure never lets the next day's choice destroy
///   an earlier day's session History doesn't hold yet;
/// - D3: a Delete that never began (its intent not stored) stops no write;
/// - D2: the six-hour carry-over, at its boundaries, across restarts,
///   resumes and a daylight-saving change;
/// - the remaining failure-injection gaps, each state named — unsaved,
///   pending retry, durably saved.
void main() {
  final morning = DateTime(2026, 10, 12, 9);
  late R8Harness h;
  late _RemovalFaultDisk rdisk;

  Future<void> boot([Map<String, Object> stored = const {}]) async {
    rdisk = _RemovalFaultDisk(stored);
    h.disk = rdisk;
    SharedPreferencesStorePlatform.instance = rdisk;
    SharedPreferences.resetStatic();
    h.prefs = await SharedPreferences.getInstance();
  }

  setUp(() async {
    h = R8Harness(morning);
    await boot();
  });

  Future<ProviderContainer> reopen({
    EntitlementStatus status = EntitlementStatus.active,
  }) async {
    await h.restart();
    final c = h.open(status: status);
    c.read(recommendationProvider);
    await R8Harness.settle();
    return c;
  }

  RecommendationNotifier today(ProviderContainer c) =>
      c.read(recommendationProvider.notifier);
  List<CircleJournalEntry> journal(ProviderContainer c) =>
      c.read(circleJournalRepositoryProvider).readAll();
  CircleJournalEntry? entryOf(ProviderContainer c, String id) =>
      journal(c).where((e) => e.circleId == id).firstOrNull;

  Future<ProviderContainer> stageChosen({DateTime? at}) async {
    if (at != null) h.clock.value = at;
    final c = h.open();
    c.read(circlePlansProvider.notifier).start('getting_going');
    today(c).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
    await R8Harness.settle();
    expect(
      c.read(recommendationProvider).recommendation!.composed?.stage,
      isNotNull,
    );
    return c;
  }

  int credits(ProviderContainer c, String id) => c
      .read(circlePlansProvider)
      .plans['getting_going']!
      .current
      .records
      .where((r) => r.circleId == id)
      .length;

  // ------------------------------------------------------------------ P2
  for (final fault in DiskFault.values) {
    test(
      'P2 — every key landed, only the recovery record\'s removal '
      '${fault.name}: durably saved and said so; History has the Start; '
      'the record stays for retry, and the next write removes it — once',
      () async {
        final c = h.open(status: EntitlementStatus.inactive);
        today(c).chooseIntention(Intention.moreEnergy);
        await R8Harness.settle();
        final id = c.read(recommendationProvider).recommendation!.circleId;
        rdisk
          ..key = recommendationPendingWriteKey
          ..fault = fault;
        today(c).start();
        await R8Harness.settle();

        var stored = await h.disk.stored();
        expect(stored[recommendationStatusKey], 'started', reason: 'durable');
        expect(
          c.read(journalSaveStatusProvider)[id],
          isTrue,
          reason: 'saved, and the user must not be told otherwise',
        );
        expect(entryOf(c, id)?.startedAt, isNotNull);
        // Pending retry: the record is still on disk, holding the same values.
        expect(stored.containsKey(recommendationPendingWriteKey), isTrue);

        rdisk.fault = null;
        h.clock.value = morning.add(const Duration(minutes: 25));
        today(c).close();
        await R8Harness.settle();
        stored = await h.disk.stored();
        expect(stored.containsKey(recommendationPendingWriteKey), isFalse);
        expect(stored[recommendationStatusKey], 'closed');
        expect(journal(c), hasLength(1));
      },
    );

    test('P2 — the record\'s removal ${fault.name}, then a restart before '
        'any retry: the restart reads the same Circle, and the next write '
        'cleans up', () async {
      final c = h.open(status: EntitlementStatus.inactive);
      today(c).chooseIntention(Intention.moreEnergy);
      await R8Harness.settle();
      rdisk
        ..key = recommendationPendingWriteKey
        ..fault = fault;
      today(c).start();
      await R8Harness.settle();
      final again = await reopen(status: EntitlementStatus.inactive);
      expect(
        again.read(recommendationProvider).status,
        RecommendationStatus.started,
      );
      expect(journal(again), hasLength(1));
      expect(journal(again).single.startedAt, isNotNull);
      h.clock.value = morning.add(const Duration(minutes: 25));
      today(again).close();
      await R8Harness.settle();
      expect(
        (await h.disk.stored()).containsKey(recommendationPendingWriteKey),
        isFalse,
      );
      expect(journal(again), hasLength(1));
    });

    // ---------------------------------------- Astra R7-A01 exact sequence
    test('Astra R7-A01 as reproduced: Start saved; Close\'s recovery-record '
        'write ${fault.name} — not saved and said so; a restart shows the '
        'Circle still started; Close again saves it', () async {
      final c = h.open(status: EntitlementStatus.inactive);
      today(c).chooseIntention(Intention.moreEnergy);
      await R8Harness.settle();
      final id = c.read(recommendationProvider).recommendation!.circleId;
      today(c).start();
      await R8Harness.settle();
      h.disk.fail(recommendationPendingWriteKey, fault);
      h.clock.value = morning.add(const Duration(minutes: 25));
      today(c).close();
      await R8Harness.settle();
      expect(c.read(journalSaveStatusProvider)[id], isFalse);
      expect((await h.disk.stored())[recommendationStatusKey], 'started');
      final again = await reopen(status: EntitlementStatus.inactive);
      expect(
        again.read(recommendationProvider).status,
        RecommendationStatus.started,
      );
      today(again).close();
      await R8Harness.settle();
      expect((await h.disk.stored())[recommendationStatusKey], 'closed');
      expect(journal(again).single.closedAt, isNotNull);
      expect(again.read(journalSaveStatusProvider)[id], isTrue);
    });

    // ---------------- persistent History failure, then the next day (item 5)
    test(
      'History refusing every save (${fault.name}): the next day\'s choice '
      'never writes over yesterday\'s Close that History doesn\'t hold '
      'yet; once History saves again, yesterday\'s Close is recorded',
      () async {
        final c = h.open(status: EntitlementStatus.inactive);
        today(c).chooseIntention(Intention.moreEnergy);
        await R8Harness.settle();
        final yesterday = c
            .read(recommendationProvider)
            .recommendation!
            .circleId;
        h.disk.fail(circleJournalKey, fault);
        today(c).start();
        await R8Harness.settle();
        h.clock.value = morning.add(const Duration(minutes: 25));
        today(c).close();
        await R8Harness.settle();
        expect(entryOf(c, yesterday)?.closedAt, isNull);

        // The next day — a restart — History still refusing.
        h.clock.value = morning.add(const Duration(days: 1));
        await h.restart(keepFaults: true);
        final next = h.open(status: EntitlementStatus.inactive);
        next.read(recommendationProvider);
        await R8Harness.settle();
        today(next).chooseIntention(Intention.gentlerPace);
        await R8Harness.settle();
        final stored = await h.disk.stored();
        expect(
          stored[recommendationDayKey],
          yesterday,
          reason: 'yesterday\'s unrecorded Close was overwritten',
        );
        expect(stored[recommendationStatusKey], 'closed');
        final todayId = dateKey(morning.add(const Duration(days: 1)));
        expect(next.read(journalSaveStatusProvider)[todayId], isFalse);

        // History saves again: the next start records yesterday's Close.
        h.disk.healAll();
        final healed = await reopen(status: EntitlementStatus.inactive);
        expect(entryOf(healed, yesterday)?.closedAt, isNotNull);
        expect(entryOf(healed, yesterday)?.startedAt, isNotNull);
        today(healed).chooseIntention(Intention.gentlerPace);
        await R8Harness.settle();
        expect((await h.disk.stored())[recommendationDayKey], todayId);
        expect(journal(healed).map((e) => e.circleId), [yesterday, todayId]);
      },
    );

    // ----------------------------------------------------------------- D3
    test(
      'D3 — a Close on its way when Delete can\'t record its intent '
      '(${fault.name}): nothing is deleted, and the Close still lands',
      () async {
        final c = h.open(status: EntitlementStatus.inactive);
        today(c).chooseIntention(Intention.moreEnergy);
        await R8Harness.settle();
        today(c).start();
        await R8Harness.settle();
        h.disk.fail(historyDeletionPendingKey, fault);
        h.clock.value = morning.add(const Duration(minutes: 25));
        today(c).close();
        Object? error;
        try {
          await c.read(circleHistoryDeletionProvider).delete();
        } catch (e) {
          error = e;
        }
        await R8Harness.settle();
        expect(error, isA<HistoryDeletionNotStarted>());
        final stored = await h.disk.stored();
        expect(
          stored[recommendationStatusKey],
          'closed',
          reason: 'a write was stopped by a Delete that never began',
        );
        expect(stored.containsKey(historyDeletionPendingKey), isFalse);
        expect(journal(c).single.closedAt, isNotNull);
      },
    );

    test('D3 — the marker\'s removal, Delete\'s last step, ${fault.name}: '
        'Delete fails, the marker stays, nothing deleted shows; the next '
        'start finishes it', () async {
      final c = await stageChosen();
      today(c).start();
      await R8Harness.settle();
      today(c).close();
      await R8Harness.settle();
      rdisk
        ..key = historyDeletionPendingKey
        ..fault = fault;
      Object? error;
      try {
        await c.read(circleHistoryDeletionProvider).delete();
      } catch (e) {
        error = e;
      }
      expect(error, isNotNull);
      expect((await h.disk.stored())[historyDeletionPendingKey], isTrue);
      expect(journal(c), isEmpty);
      final again = await reopen();
      expect(journal(again), isEmpty);
      expect(
        (await h.disk.stored()).containsKey(historyDeletionPendingKey),
        isFalse,
      );
    });

    // ------------------------------------------------- remaining gaps
    test('a stage Circle\'s Start whose Plans evidence write ${fault.name} '
        '(billing verifiably ended): the Start isn\'t saved and the user is '
        'told; a restart brings back the unstarted offer', () async {
      final c = await stageChosen();
      final id = c.read(recommendationProvider).recommendation!.circleId;
      (c.read(entitlementStatusProvider.notifier) as SettableEntitlement).set(
        EntitlementStatus.inactive,
      );
      h.disk.fail(circlePlansKey, fault);
      today(c).start();
      await R8Harness.settle();
      // R8.2 founder decision B: the Start is refused — the Circle isn't
      // started — and told with "This change couldn't be saved. Please try
      // again." (the offer itself is saved, so History's notice doesn't
      // apply).
      expect(
        c.read(recommendationProvider).status,
        RecommendationStatus.notStarted,
      );
      expect(c.read(recommendationProvider).recommendation?.circleId, id);
      expect(c.read(storeSaveFailuresProvider).count, greaterThan(0));
      expect((await h.disk.stored())[recommendationStatusKey], 'notStarted');
      final again = await reopen();
      expect(
        again.read(recommendationProvider).status,
        RecommendationStatus.notStarted,
      );
      expect(journal(again).single.startedAt, isNull);
    });

    test('removing a kept Circle ${fault.name}: it stays, in memory and on '
        'disk, and the failure is shown', () async {
      final c = h.open();
      final kept = (await c
          .read(keptCirclesProvider.notifier)
          .keepCircle(
            plan: CirclePlan.fromWire(const [
              'getItOut:6',
              'chooseOne:1',
              'clearCorner:8',
            ])!,
            need: Intention.clearerHead,
            circleId: 'd1',
          ))!;
      h.disk.fail(keptCirclesKey, fault);
      await expectLater(
        c.read(keptCirclesProvider.notifier).deleteKept(kept.id),
        throwsA(isA<StorageWriteFailed>()),
      );
      expect(c.read(keptCirclesProvider).kept, hasLength(1));
      expect(c.read(storeSaveFailuresProvider).count, greaterThan(0));
      final again = await reopen();
      expect(again.read(keptCirclesProvider).kept, hasLength(1));
    });

    // R8.1 RL-1 (founder decision 2026-11-05) supersedes R8's "still on
    // screen": a refused Plan change is taken back off the screen, never
    // shown as made; it stays marked unsaved until a later save lands.
    test('a Plan action the store refuses (${fault.name}): taken back off '
        'the screen, marked unsaved; a restart before any retry shows what '
        'is durable; the next save makes it durably saved', () async {
      final c = h.open();
      h.disk.fail(circlePlansKey, fault);
      c.read(circlePlansProvider.notifier).start('getting_going');
      await R8Harness.settle();
      expect(
        c.read(circlePlansProvider).active,
        isNull,
        reason: 'an unsaved change shown as made',
      );
      expect(
        c.read(storeSaveFailuresProvider).unsaved,
        contains(UserStore.circlePlans),
      );
      expect((await h.disk.stored()).containsKey(circlePlansKey), isFalse);

      // Restart before any retry: only what is durable.
      final restarted = await reopen();
      expect(restarted.read(circlePlansProvider).active, isNull);
      expect(restarted.read(storeSaveFailuresProvider).unsaved, isEmpty);

      // In the first session, the next save carries the change.
      h.disk.healAll();
      final again = h.open();
      again.read(circlePlansProvider.notifier).start('getting_going');
      await R8Harness.settle();
      again.read(circlePlansProvider.notifier).pause('getting_going');
      await R8Harness.settle();
      expect(again.read(storeSaveFailuresProvider).unsaved, isEmpty);
      expect((await h.disk.stored())[circlePlansKey], isNotNull);
    });

    test('Plans THIRTY can\'t read, with a different copy already set aside '
        '(${fault.name} irrelevant): the save is refused, both stay byte for '
        'byte, and the failure is shown', () async {
      await boot({
        circlePlansKey: '{damaged now',
        circlePlansUnreadableKey: '{damaged earlier',
      });
      final c = h.open();
      c.read(circlePlansProvider.notifier).start('getting_going');
      await R8Harness.settle();
      final stored = await h.disk.stored();
      expect(stored[circlePlansKey], '{damaged now');
      expect(stored[circlePlansUnreadableKey], '{damaged earlier');
      expect(
        c.read(storeSaveFailuresProvider).unsaved,
        contains(UserStore.circlePlans),
      );
    });
  }

  test('Insights THIRTY can\'t read, with a different copy already set '
      'aside: the save is refused, both stay byte for byte', () async {
    await boot({
      insightsKey: '{damaged now',
      insightsUnreadableKey: '{damaged earlier',
      circleJournalKey: _i4Journal(morning),
    });
    final c = h.open();
    c.read(insightsProvider.notifier).assess();
    await R8Harness.settle();
    final stored = await h.disk.stored();
    expect(stored[insightsKey], '{damaged now');
    expect(stored[insightsUnreadableKey], '{damaged earlier');
    expect(
      c.read(storeSaveFailuresProvider).unsaved,
      contains(UserStore.insights),
    );
  });

  test(
    'I4: the Circle kept, I4\'s own record throws: after a restart the '
    'Keep keeps nothing twice and I4 is applied; lapsed throughout',
    () async {
      await boot({circleJournalKey: _i4Journal(morning)});
      final paid = h.open();
      final shown = paid.read(insightsProvider.notifier).assess().added.single;
      expect(shown.application, isA<KeepCircleFromHistory>());
      await R8Harness.settle();
      final c = await reopen(status: EntitlementStatus.inactive);
      h.disk.fail(insightsKey, DiskFault.throws);
      await c.read(insightsProvider.notifier).apply(shown.id);
      await R8Harness.settle();
      expect(c.read(keptCirclesProvider).kept, hasLength(1));
      final again = await reopen(status: EntitlementStatus.inactive);
      final notifier = again.read(insightsProvider.notifier);
      await notifier.apply(shown.id);
      await R8Harness.settle();
      expect(again.read(keptCirclesProvider).kept, hasLength(1));
      expect(
        statusOf(
          again.read(insightsProvider).byId(shown.id)!,
          notifier.inputs(),
        ),
        InsightStatus.applied,
      );
      expect(notifier.notNow(shown.id), InsightActionResult.needsPremium);
    },
  );

  // ------------------------------------------------------------------ D2
  group('D2 — the six-hour carry-over', () {
    final start = DateTime(2026, 10, 12, 23, 40);

    Future<ProviderContainer> startedLate() async {
      h.clock.value = start;
      final c = h.open(status: EntitlementStatus.inactive);
      today(c).chooseIntention(Intention.moreEnergy);
      await R8Harness.settle();
      today(c).start();
      await R8Harness.settle();
      return c;
    }

    for (final (label, after, carried) in [
      (
        'a minute before six hours',
        const Duration(hours: 5, minutes: 59),
        true,
      ),
      ('exactly six hours', const Duration(hours: 6), true),
      ('a minute after six hours', const Duration(hours: 6, minutes: 1), false),
    ]) {
      test('running, restarted $label after its Start: '
          '${carried ? 'brought back' : 'not brought back'}', () async {
        await startedLate();
        h.clock.value = start.add(after);
        final c = await reopen(status: EntitlementStatus.inactive);
        final state = c.read(recommendationProvider);
        if (carried) {
          expect(state.status, RecommendationStatus.started);
          expect(state.recommendation!.circleId, dateKey(start));
        } else {
          expect(state.recommendation, isNull);
          // History keeps it as started, unfinished — nothing made up.
          final e = entryOf(c, dateKey(start))!;
          expect(e.startedAt, start);
          expect(e.closedAt, isNull);
          expect(e.attemptResponse, isNull);
        }
      });

      test(
        'running, resumed $label after its Start: '
        '${carried ? 'still on show' : 'the new day opens, nothing starts'}',
        () async {
          final c = await startedLate();
          h.clock.value = start.add(after);
          c.invalidate(nowProvider);
          final state = c.read(recommendationProvider);
          if (carried) {
            expect(state.status, RecommendationStatus.started);
          } else {
            expect(state.recommendation, isNull);
            expect(state.status, RecommendationStatus.notStarted);
          }
        },
      );

      test('closed after midnight, reflection open, $label after its Close: '
          '${carried ? 'reflection still on show' : 'the new day opens'}; '
          'the answer already given is kept', () async {
        final c = await startedLate();
        final closedAt = DateTime(2026, 10, 13, 0, 5);
        h.clock.value = closedAt;
        today(c).close();
        await R8Harness.settle();
        today(c).reportAttempt(CircleAttemptResponse.yes);
        await R8Harness.settle();
        h.clock.value = closedAt.add(after);
        c.invalidate(nowProvider);
        final state = c.read(recommendationProvider);
        expect(
          state.status,
          carried
              ? RecommendationStatus.closed
              : RecommendationStatus.notStarted,
        );
        final e = entryOf(c, dateKey(start))!;
        expect(e.attemptResponse, CircleAttemptResponse.yes);
        expect(e.usefulnessResponse, isNull);
      });
    }

    test(
      'expired: the next day\'s Circle is chosen deliberately and starts '
      '— nothing starts by itself; yesterday\'s record is unchanged',
      () async {
        await startedLate();
        h.clock.value = start.add(const Duration(hours: 7));
        final c = await reopen(status: EntitlementStatus.inactive);
        expect(c.read(recommendationProvider).recommendation, isNull);
        today(c).chooseIntention(Intention.gentlerPace);
        await R8Harness.settle();
        today(c).start();
        await R8Harness.settle();
        expect(
          c.read(recommendationProvider).status,
          RecommendationStatus.started,
        );
        expect(
          c.read(recommendationProvider).recommendation!.circleId,
          dateKey(start.add(const Duration(hours: 7))),
        );
        final old = entryOf(c, dateKey(start))!;
        expect(old.startedAt, start);
        expect(old.closedAt, isNull);
      },
    );

    test('a stage Circle carried over, closed after a restart past midnight: '
        'its Plan is credited once, under that Circle', () async {
      final c = await stageChosen(at: start);
      final id = c.read(recommendationProvider).recommendation!.circleId;
      today(c).start();
      await R8Harness.settle();
      h.clock.value = DateTime(2026, 10, 13, 0, 10);
      final again = await reopen();
      expect(again.read(recommendationProvider).recommendation!.circleId, id);
      today(again).close();
      await R8Harness.settle();
      expect(credits(again, id), 1);
      final third = await reopen();
      expect(credits(third, id), 1);
    });

    test('elapsed time, not the clock face: across the daylight-saving change '
        'of 25 October 2026 (where the device\'s zone has one)', () async {
      // 23:30 on 24 Oct, then 05:20 on 25 Oct by the clock face: 5 h 50 min
      // on the face; 6 h 50 min of real time where the clocks went back an
      // hour that night (Central Europe), 5 h 50 min where they didn't.
      final began = DateTime(2026, 10, 24, 23, 30);
      final later = DateTime(2026, 10, 25, 5, 20);
      final elapsed = later.difference(began);
      final zoneShifted = began.timeZoneOffset != later.timeZoneOffset;
      expect(
        elapsed,
        zoneShifted
            ? const Duration(hours: 6, minutes: 50)
            : const Duration(hours: 5, minutes: 50),
      );
      h.clock.value = began;
      final c = h.open(status: EntitlementStatus.inactive);
      today(c).chooseIntention(Intention.moreEnergy);
      await R8Harness.settle();
      today(c).start();
      await R8Harness.settle();
      h.clock.value = later;
      final again = await reopen(status: EntitlementStatus.inactive);
      expect(
        again.read(recommendationProvider).recommendation != null,
        elapsed <= midnightCarryOverLimit,
      );
    });
  });
}

String _i4Journal(DateTime morning) {
  CirclePart part(ElementId e) => CirclePart(e, elementOf(e).minutes);
  final writing = [
    part(ElementId.closeWhatsOpen),
    part(ElementId.getItOut),
    part(ElementId.chooseOne),
    part(ElementId.firstStep),
  ];
  final reading = [part(ElementId.phoneFaceDown), part(ElementId.readPages)];
  CircleJournalEntry entry(int ago, List<CirclePart> parts, bool useful) {
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
      attemptResponse: useful ? CircleAttemptResponse.yes : null,
      usefulnessResponse: useful ? CircleUsefulnessResponse.veryUseful : null,
      session: CircleSessionRecord(
        title: 'Circle',
        parts: CirclePlan(parts).toWire(),
      ),
    );
  }

  return jsonEncode({
    'schemaVersion': circleJournalSchemaVersion,
    'entries': [
      for (final ago in [1, 7, 13, 20]) entry(ago, writing, true).toJson(),
      for (final ago in [3, 9, 16]) entry(ago, reading, false).toJson(),
    ],
  });
}
