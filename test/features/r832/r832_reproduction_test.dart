import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_history_deletion.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/insights/domain/insight_engine.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_stage_provenance.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.3.2 — consolidated integrity closure: the reproduction gate.
///
/// One test per auditor scenario, under the auditor's own finding id, with
/// the ordinary controls beside them. Each asserts the contract — the
/// founder's lifecycle table (R83-F1 Option B), decisions B, D2 and D3 —
/// and prints one `R832-EVIDENCE` line with what reached the disk.
///
/// A step a tree can't construct (an R8.2 tree has no paused-Start record
/// to hold) fails with a message starting `PRECONDITION`: not applicable
/// there, never counted as a pass.
void main() {
  // ---------------------------------------------------------------------
  // Shared helpers.

  void evidence(String id, Map<String, Object?> facts) {
    // ignore: avoid_print
    print('R832-EVIDENCE ${jsonEncode({'test': id, ...facts})}');
  }

  void pre(bool holds, String what) {
    if (!holds) fail('PRECONDITION not constructible on this tree: $what');
  }

  group('Plans — Start identity and historical eligibility', () {
    final day1 = DateTime(2026, 10, 12, 9);
    late R8Harness h;

    setUp(() async {
      h = R8Harness(day1);
      await h.boot();
    });

    RecommendationNotifier today(ProviderContainer c) =>
        c.read(recommendationProvider.notifier);
    CirclePlansNotifier plans(ProviderContainer c) =>
        c.read(circlePlansProvider.notifier);
    RecommendationStatus status(ProviderContainer c) =>
        c.read(recommendationProvider).status;

    Future<Map<String, Object?>> planOnDisk() async {
      final raw = (await h.disk.stored())[circlePlansKey];
      if (raw is! String) return {};
      final stored = (jsonDecode(raw) as Map)['plans'] as Map?;
      return (stored?['getting_going'] as Map?)?.cast<String, Object?>() ?? {};
    }

    /// Every guided record of [circleId] on disk, as `cycleId`.
    Future<List<String>> creditsOnDisk(String circleId) async {
      final raw = (await h.disk.stored())[circlePlansKey];
      if (raw is! String) return [];
      return [
        for (final plan in ((jsonDecode(raw) as Map)['plans'] as Map).values)
          for (final cycle in ((plan as Map)['cycles'] as List))
            for (final r in (cycle as Map)['records'] as List)
              if ((r as Map)['circleId'] == circleId) cycle['id'] as String,
      ];
    }

    Future<Map<String, Object?>> facts(String circleId) async {
      final plan = await planOnDisk();
      final stored = await h.disk.stored();
      return {
        'credits': await creditsOnDisk(circleId),
        'lifecycle': plan['lifecycle'],
        'startedWhilePaused': plan['startedWhilePaused'],
        'lastServed': plan['lastServed'],
        'cycles': [
          for (final c in (plan['cycles'] as List? ?? []))
            {'id': (c as Map)['id'], 'cursor': c['cursor'], 'end': c['end']},
        ],
        'dayStatus': stored[recommendationStatusKey],
        'dayStartedAt': stored[recommendationStartedAtKey],
      };
    }

    Future<ProviderContainer> restart({int times = 1}) async {
      late ProviderContainer c;
      for (var i = 0; i < times; i++) {
        await h.restart();
        c = h.open();
        c.read(circlePlansProvider);
        c.read(recommendationProvider);
        await R8Harness.settle();
      }
      return c;
    }

    Future<(ProviderContainer, String)> offered() async {
      final c = h.open();
      expect(plans(c).start('getting_going'), PlanActionResult.done);
      today(
        c,
      ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await R8Harness.settle();
      final rec = c.read(recommendationProvider).recommendation!;
      expect(rec.composed?.stage, isNotNull);
      return (c, rec.circleId);
    }

    Future<void> act(ProviderContainer c, String step) async {
      switch (step) {
        case 'Start':
          today(c).start();
        case 'Pause':
          expect(plans(c).pause('getting_going'), PlanActionResult.done);
        case 'Resume':
          expect(plans(c).resume('getting_going'), PlanActionResult.done);
        case 'Leave':
          expect(plans(c).leave('getting_going'), PlanActionResult.done);
        case 'Again':
          expect(
            plans(c).goThroughAgain('getting_going'),
            PlanActionResult.done,
          );
        case 'AgainByInsight':
          expect(
            plans(c).goThroughAgain('getting_going', byInsight: 'i1-probe'),
            PlanActionResult.done,
          );
        case 'StartPlan':
          expect(plans(c).start('getting_going'), PlanActionResult.done);
        case 'Close':
          h.clock.value = h.clock.value.add(const Duration(minutes: 25));
          today(c).close();
        default:
          fail('unknown step $step');
      }
      await R8Harness.settle();
    }

    /// Waits for a held write to arrive — or reports that this tree never
    /// makes it (an R8.2 tree has no paused-Start write).
    Future<void> reached(HeldWrite held, String what) async {
      var arrived = true;
      await held.reached.timeout(
        const Duration(seconds: 2),
        onTimeout: () => arrived = false,
      );
      pre(arrived, what);
    }

    // -------------------------------------------------------------------
    // Group A — historical eligibility lost during a new cycle.

    group('Group A — Claude AUD-R83-1', () {
      final sequences = <String, List<String>>{
        'A1 seq1': ['Pause', 'Start', 'Close', 'Resume', 'Leave', 'Again'],
        'A2 seq2': ['Pause', 'Start', 'Resume', 'Close', 'Leave', 'Again'],
        'A4 left Plan started again': [
          'Pause', 'Start', 'Close', 'Resume', 'Leave', 'StartPlan', //
        ],
        'A5 I1-style Go through again': [
          'Pause', 'Start', 'Close', 'Resume', 'Leave', 'AgainByInsight', //
        ],
        'A6 later lifecycle changes': [
          'Pause', 'Start', 'Close', 'Resume', 'Leave', 'Again', //
          'Pause', 'Resume', 'Leave', 'Again',
        ],
      };
      for (final MapEntry(key: id, value: steps) in sequences.entries) {
        test(
          '$id: ${steps.join(' → ')} → restart ×2: never credited',
          () async {
            final (c, circle) = await offered();
            for (final step in steps) {
              await act(c, step);
            }
            final inSession = await creditsOnDisk(circle);
            await restart(times: 2);
            evidence('AUD-R83-1 $id', {
              'inSession': inSession,
              ...await facts(circle),
            });
            expect(inSession, isEmpty, reason: 'credited in the session');
            expect(
              await creditsOnDisk(circle),
              isEmpty,
              reason: 'retroactive credit after restart',
            );
          },
        );
      }

      test('A3 seq1 then the next day\'s catch-up: never credited', () async {
        final (c, circle) = await offered();
        for (final s in [
          'Pause',
          'Start',
          'Close',
          'Resume',
          'Leave',
          'Again',
        ]) {
          await act(c, s);
        }
        h.clock.value = day1.add(const Duration(days: 1));
        final c2 = await restart();
        today(
          c2,
        ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
        await R8Harness.settle();
        await restart();
        evidence('AUD-R83-1 A3', await facts(circle));
        expect(await creditsOnDisk(circle), isEmpty);
      });

      test('A7 Premium lapse verified at Start, then resubscribed: never '
          'credited', () async {
        final (c, circle) = await offered();
        (c.read(entitlementStatusProvider.notifier) as SettableEntitlement).set(
          EntitlementStatus.inactive,
        );
        await R8Harness.settle();
        for (final s in ['Pause', 'Start', 'Close']) {
          await act(c, s);
        }
        (c.read(entitlementStatusProvider.notifier) as SettableEntitlement).set(
          EntitlementStatus.active,
        );
        await R8Harness.settle();
        for (final s in ['Resume', 'Leave', 'Again']) {
          await act(c, s);
        }
        await restart(times: 2);
        evidence('AUD-R83-1 A7', await facts(circle));
        expect(await creditsOnDisk(circle), isEmpty);
      });

      test('A-ctl1 control: Start → Close → Leave → Again (valid Start): '
          'credited once, on the first cycle', () async {
        final (c, circle) = await offered();
        for (final s in ['Start', 'Close', 'Leave', 'Again']) {
          await act(c, s);
        }
        await restart(times: 2);
        evidence('AUD-R83-1 A-ctl1', await facts(circle));
        expect(await creditsOnDisk(circle), ['getting_going#1']);
      });

      test('A-ctl2 control: Start → Close requested → Leave while the Close '
          'is saving → Again: credited once, on the left cycle', () async {
        final (c, circle) = await offered();
        await act(c, 'Start');
        final held = h.disk.hold(recommendationPendingWriteKey);
        h.clock.value = h.clock.value.add(const Duration(minutes: 25));
        today(c).close();
        await held.reached;
        expect(plans(c).leave('getting_going'), PlanActionResult.done);
        await R8Harness.settle();
        held.release();
        await R8Harness.settle();
        await act(c, 'Again');
        await restart(times: 2);
        evidence('AUD-R83-1 A-ctl2', await facts(circle));
        expect(await creditsOnDisk(circle), ['getting_going#1']);
      });

      test('A-ctl3 control: Pause → Start → Close → Resume → Leave, no new '
          'cycle: never credited', () async {
        final (c, circle) = await offered();
        for (final s in ['Pause', 'Start', 'Close', 'Resume', 'Leave']) {
          await act(c, s);
        }
        await restart(times: 2);
        evidence('AUD-R83-1 A-ctl3', await facts(circle));
        expect(await creditsOnDisk(circle), isEmpty);
      });
    });

    // -------------------------------------------------------------------
    // Group B — orphaned or cancelled Start evidence.

    group('Group B — Astra R83-N01 / Claude AUD-R83-3', () {
      /// After an abandoned paused Start: the Plan carried on, the Circle
      /// genuinely started while it is active, then closed. A minute later
      /// than the abandoned attempt — the harness clock stands still, a
      /// real one doesn't (B-tie: the same instant).
      Future<void> laterActiveStart(ProviderContainer c, String id) async {
        h.clock.value = h.clock.value.add(const Duration(minutes: 1));
        await act(c, 'Resume');
        await act(c, 'Start');
        expect(status(c), RecommendationStatus.started);
        await act(c, 'Close');
        await restart(times: 2);
      }

      test('B1 (N01-A) the paused-Start prerequisite lands and the process '
          'stops before the Start: a later valid active Start is credited '
          'once', () async {
        final (c, circle) = await offered();
        await act(c, 'Pause');
        h.disk.ackLost(circlePlansKey, thenStop: true);
        today(c).start();
        await R8Harness.settle();
        final c2 = await restart();
        pre(
          status(c2) == RecommendationStatus.notStarted,
          'the Start never became valid (got ${status(c2)})',
        );
        final orphan = await facts(circle);
        await laterActiveStart(c2, circle);
        evidence('R83-N01 B1', {'afterStop': orphan, ...await facts(circle)});
        expect(await creditsOnDisk(circle), ['getting_going#1']);
      });

      test('B2 (AUD-R83-3) the prerequisite lands, the Start\'s own day-keys '
          'save fails: after a restart, a later valid active Start is '
          'credited once', () async {
        final (c, circle) = await offered();
        await act(c, 'Pause');
        h.disk.fail(recommendationStatusKey, DiskFault.returnsFalse);
        h.disk.fail(recommendationPendingWriteKey, DiskFault.returnsFalse);
        await act(c, 'Start');
        final c2 = await restart();
        pre(
          status(c2) == RecommendationStatus.notStarted,
          'the Start was durable after all (got ${status(c2)})',
        );
        final orphan = await facts(circle);
        await laterActiveStart(c2, circle);
        evidence('AUD-R83-3 B2', {
          'afterRestart': orphan,
          ...await facts(circle),
        });
        expect(await creditsOnDisk(circle), ['getting_going#1']);
      });

      test(
        'B3 control: the prerequisite lands but its answer is lost (the '
        'Start is refused): a later valid active Start is credited once',
        () async {
          final (c, circle) = await offered();
          await act(c, 'Pause');
          h.disk.ackLost(circlePlansKey);
          await act(c, 'Start');
          pre(
            status(c) == RecommendationStatus.notStarted,
            'the Start was not refused (got ${status(c)})',
          );
          final c2 = await restart();
          final orphan = await facts(circle);
          await laterActiveStart(c2, circle);
          evidence('AUD-R83-3 B3', {
            'afterRestart': orphan,
            ...await facts(circle),
          });
          expect(await creditsOnDisk(circle), ['getting_going#1']);
        },
      );

      test('B4 (N01-B) a pending paused Start is cancelled by a same-day '
          'rebuild; its prerequisite then lands: a later valid active Start '
          'is credited once', () async {
        final (c, circle) = await offered();
        await act(c, 'Pause');
        final held = h.disk.hold(circlePlansKey);
        today(c).start();
        await reached(held, 'a paused-Start write');
        h.clock.value = h.clock.value.add(const Duration(minutes: 1));
        c.invalidate(nowProvider);
        await R8Harness.settle();
        held.release();
        await R8Harness.settle();
        pre(
          status(c) == RecommendationStatus.notStarted,
          'the cancelled attempt started anyway (got ${status(c)})',
        );
        final orphan = await facts(circle);
        await laterActiveStart(c, circle);
        evidence('R83-N01 B4', {'afterCancel': orphan, ...await facts(circle)});
        expect(await creditsOnDisk(circle), ['getting_going#1']);
      });

      test('B-tie an abandoned prerequisite, then a later active Start at the '
          'very same instant (the harness clock stands still): the abandoned '
          'record is superseded first — credited once', () async {
        final (c, circle) = await offered();
        await act(c, 'Pause');
        h.disk.ackLost(circlePlansKey, thenStop: true);
        today(c).start();
        await R8Harness.settle();
        final c2 = await restart();
        pre(
          status(c2) == RecommendationStatus.notStarted,
          'the Start never became valid (got ${status(c2)})',
        );
        await act(c2, 'Resume');
        await act(c2, 'Start');
        expect(status(c2), RecommendationStatus.started);
        await act(c2, 'Close');
        await restart(times: 2);
        evidence('R83-N01 B-tie', await facts(circle));
        expect(await creditsOnDisk(circle), ['getting_going#1']);
      });

      test('B7 an abandoned prerequisite whose removal the store refuses: '
          'that Start is refused, the record stays; the next tap removes it '
          'and starts — credited once', () async {
        final (c, circle) = await offered();
        await act(c, 'Pause');
        h.disk.ackLost(circlePlansKey, thenStop: true);
        today(c).start();
        await R8Harness.settle();
        final c2 = await restart();
        pre(
          status(c2) == RecommendationStatus.notStarted,
          'the Start never became valid (got ${status(c2)})',
        );
        await act(c2, 'Resume');
        h.clock.value = h.clock.value.add(const Duration(minutes: 1));
        h.disk.fail(circlePlansKey, DiskFault.returnsFalse, times: 1);
        await act(c2, 'Start');
        final refused = status(c2);
        final whileRefused = await facts(circle);
        await act(c2, 'Start');
        expect(status(c2), RecommendationStatus.started);
        await act(c2, 'Close');
        await restart(times: 2);
        evidence('R83-N01 B7', {
          'firstTap': refused.name,
          'whileRefused': whileRefused,
          ...await facts(circle),
        });
        expect(refused, RecommendationStatus.notStarted);
        expect(whileRefused['startedWhilePaused'], isNotNull);
        expect(await creditsOnDisk(circle), ['getting_going#1']);
      });

      // Expectation changed by the founder's N01-C decision (2026-11-07,
      // "R8.3.2 final founder scope decisions" §5): a lifecycle change while
      // a Start is unresolved cancels that Start. Before it, this test
      // recorded the conservative linearization (started, never credited).
      test('B5 (N01-C) Resume tapped while the paused Start\'s prerequisite '
          'is being written, which lands: that Start is cancelled; a fresh '
          'Start on the active Plan is credited once', () async {
        final (c, circle) = await offered();
        await act(c, 'Pause');
        final held = h.disk.hold(circlePlansKey);
        today(c).start();
        await reached(held, 'a paused-Start write');
        expect(plans(c).resume('getting_going'), PlanActionResult.done);
        held.release();
        await R8Harness.settle();
        expect(status(c), RecommendationStatus.notStarted);
        h.clock.value = h.clock.value.add(const Duration(minutes: 1));
        await act(c, 'Start');
        expect(status(c), RecommendationStatus.started);
        await act(c, 'Close');
        await restart(times: 2);
        evidence('R83-N01 B5', await facts(circle));
        expect(await creditsOnDisk(circle), ['getting_going#1']);
      });

      test(
        'B6 control: an abandoned prerequisite, then a genuine paused '
        'Start on the still-paused Plan, Close, Resume: never credited',
        () async {
          final (c, circle) = await offered();
          await act(c, 'Pause');
          h.disk.ackLost(circlePlansKey, thenStop: true);
          today(c).start();
          await R8Harness.settle();
          final c2 = await restart();
          pre(
            status(c2) == RecommendationStatus.notStarted,
            'the Start never became valid (got ${status(c2)})',
          );
          await act(c2, 'Start');
          expect(status(c2), RecommendationStatus.started);
          await act(c2, 'Close');
          await act(c2, 'Resume');
          await restart(times: 2);
          evidence('R83-N01 B6', await facts(circle));
          expect(await creditsOnDisk(circle), isEmpty);
        },
      );

      final table = <(List<String>, int)>[
        (['Pause', 'Start', 'Close', 'Resume'], 0),
        (['Start', 'Pause', 'Close'], 1),
        (['Start', 'Pause', 'Resume', 'Close'], 1),
      ];
      for (final (steps, credit) in table) {
        test('B-ctl ${steps.join(' → ')} → restart ×2: '
            '${credit == 1 ? 'credited once' : 'never credited'}', () async {
          final (c, circle) = await offered();
          for (final s in steps) {
            await act(c, s);
          }
          await restart(times: 2);
          evidence('B-ctl ${steps.join('>')}', await facts(circle));
          expect((await creditsOnDisk(circle)).length, credit);
        });
      }

      test('S1 (Astra single-slot concern) two Circles started while paused '
          'on consecutive days, the Plan carried on between, restarts and '
          'catch-ups: neither credited', () async {
        final (c, a) = await offered();
        for (final s in ['Pause', 'Start', 'Close', 'Resume']) {
          await act(c, s);
        }
        h.clock.value = day1.add(const Duration(days: 1));
        final c2 = await restart();
        today(
          c2,
        ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
        await R8Harness.settle();
        final b = c2.read(recommendationProvider).recommendation!.circleId;
        pre(b != a, 'a second day\'s Circle');
        for (final s in ['Pause', 'Start', 'Close', 'Resume']) {
          await act(c2, s);
        }
        await restart(times: 2);
        h.clock.value = day1.add(const Duration(days: 2));
        await restart(times: 2);
        evidence('S1 two paused Starts', {
          'a': await creditsOnDisk(a),
          ...await facts(b),
        });
        expect(await creditsOnDisk(a), isEmpty);
        expect(await creditsOnDisk(b), isEmpty);
      });

      test('B-ctl Delete while the paused-Start prerequisite is being '
          'written: no paused-Start fact survives; nothing credited', () async {
        final (c, circle) = await offered();
        await act(c, 'Pause');
        final held = h.disk.hold(circlePlansKey);
        today(c).start();
        await reached(held, 'a paused-Start write');
        final del = c.read(circleHistoryDeletionProvider).delete();
        held.release();
        await R8Harness.settle();
        try {
          await del;
        } catch (_) {}
        await R8Harness.settle();
        await restart();
        evidence('B-ctl delete', await facts(circle));
        expect((await planOnDisk()).containsKey('startedWhilePaused'), isFalse);
        expect(await creditsOnDisk(circle), isEmpty);
      });
    });

    // -------------------------------------------------------------------
    // Group C — optimistic Plan state and incomplete confirmation.

    group('Group C — Astra R83-N02 / Claude AUD-R83-2', () {
      /// Astra's interleaving: the first paused Start's prerequisite held, a
      /// same-day rebuild, a second tap — then [release].
      Future<void> astra(
        String id,
        void Function(HeldWrite held) release,
      ) async {
        final (c, circle) = await offered();
        await act(c, 'Pause');
        final held = h.disk.hold(circlePlansKey);
        today(c).start();
        await reached(held, 'a paused-Start write');
        h.clock.value = h.clock.value.add(const Duration(minutes: 1));
        c.invalidate(nowProvider);
        await R8Harness.settle();
        pre(
          status(c) == RecommendationStatus.notStarted,
          'the rebuilt offer is not startable',
        );
        today(c).start();
        final atTap = status(c);
        await R8Harness.settle();
        final beforeRelease = status(c);
        release(held);
        await R8Harness.settle();
        final afterRelease = status(c);
        final settled = await facts(circle);
        // The user taps Start again if it didn't start.
        if (status(c) == RecommendationStatus.notStarted) {
          await act(c, 'Start');
        }
        final started = status(c) == RecommendationStatus.started;
        if (started) {
          await act(c, 'Close');
          await act(c, 'Resume');
          await restart(times: 2);
        }
        evidence(id, {
          'atSecondTap': atTap.name,
          'beforeRelease': beforeRelease.name,
          'afterRelease': afterRelease.name,
          'afterRelease_disk': settled,
          ...await facts(circle),
        });
        expect(
          beforeRelease,
          isNot(RecommendationStatus.started),
          reason:
              'the Start became valid before its paused-Start record '
              'was confirmed on disk',
        );
        expect(started, isTrue);
        expect(await creditsOnDisk(circle), isEmpty);
      }

      test('C1 (N02) Astra — first prerequisite refused', () async {
        await astra(
          'R83-N02 C1 refused',
          (w) => w.release(DiskFault.returnsFalse),
        );
      });
      test('C1b (N02) Astra — first prerequisite lands', () async {
        await astra('R83-N02 C1b success', (w) => w.release());
      });
      test('C1c (N02) Astra — first prerequisite lands, answer lost', () async {
        await astra('R83-N02 C1c ackLost', (w) => w.releaseAckLost());
      });

      /// Claude's interleaving: the Plan durably paused; Resume tapped and
      /// held; Start tapped meanwhile — then [release].
      Future<(ProviderContainer, String, Map<String, Object?>)> claude(
        void Function(HeldWrite held) release,
      ) async {
        final (c, circle) = await offered();
        await act(c, 'Pause');
        final held = h.disk.hold(circlePlansKey);
        expect(plans(c).resume('getting_going'), PlanActionResult.done);
        today(c).start();
        final atTap = status(c);
        await R8Harness.settle();
        final during = status(c);
        release(held);
        await R8Harness.settle();
        if (status(c) == RecommendationStatus.notStarted) {
          await act(c, 'Start');
        }
        return (
          c,
          circle,
          <String, Object?>{
            'atTap': atTap.name,
            'whileResumePending': during.name,
            'afterRelease': status(c).name,
            'diskLifecycleAfterRelease': (await planOnDisk())['lifecycle'],
          },
        );
      }

      test('C2 (AUD-R83-2) Resume refused by the store while Start is '
          'tapped: Close, Resume, restarts — never credited', () async {
        final (c, circle, seen) = await claude(
          (w) => w.release(DiskFault.returnsFalse),
        );
        expect(seen['diskLifecycleAfterRelease'], 'paused');
        expect(status(c), RecommendationStatus.started);
        await act(c, 'Close');
        final atClose = await creditsOnDisk(circle);
        await act(c, 'Resume');
        await restart(times: 2);
        evidence('AUD-R83-2 C2 refused', {
          ...seen,
          'atClose': atClose,
          ...await facts(circle),
        });
        expect(atClose, isEmpty);
        expect(await creditsOnDisk(circle), isEmpty);
      });

      test('C2b control (AUD-R83-2) the held Resume lands: the Start is on an '
          'active Plan — credited once', () async {
        final (c, circle, seen) = await claude((w) => w.release());
        expect(status(c), RecommendationStatus.started);
        await act(c, 'Close');
        await restart(times: 2);
        evidence('AUD-R83-2 C2b success', {...seen, ...await facts(circle)});
        expect(await creditsOnDisk(circle), ['getting_going#1']);
      });

      test(
        'C2c (AUD-R83-2) the held Resume lands but its answer is lost '
        '(reported refused): Close, Resume, restarts — never credited',
        () async {
          final (c, circle, seen) = await claude((w) => w.releaseAckLost());
          expect(status(c), RecommendationStatus.started);
          await act(c, 'Close');
          await act(c, 'Resume');
          await restart(times: 2);
          evidence('AUD-R83-2 C2c ackLost', {...seen, ...await facts(circle)});
          expect(await creditsOnDisk(circle), isEmpty);
        },
      );

      test('C3 a Pause that lands and a Resume the store refuses, both '
          'pending at the Start tap: never credited', () async {
        final (c, circle) = await offered();
        final held = h.disk.hold(circlePlansKey);
        expect(plans(c).pause('getting_going'), PlanActionResult.done);
        expect(plans(c).resume('getting_going'), PlanActionResult.done);
        today(c).start();
        final atTap = status(c);
        await reached(held, 'the Pause write');
        h.disk.fail(circlePlansKey, DiskFault.returnsFalse, times: 1);
        held.release();
        await R8Harness.settle();
        final lifecycle = (await planOnDisk())['lifecycle'];
        if (status(c) == RecommendationStatus.notStarted) {
          await act(c, 'Start');
        }
        expect(status(c), RecommendationStatus.started);
        await act(c, 'Close');
        await act(c, 'Resume');
        await restart(times: 2);
        evidence('C3 pause-landed resume-refused', {
          'atTap': atTap.name,
          'diskLifecycleAfterRelease': lifecycle,
          ...await facts(circle),
        });
        expect(lifecycle, 'paused');
        expect(await creditsOnDisk(circle), isEmpty);
      });

      test('C4 control: nothing pending, the Plan active — the Start is '
          'valid at once (decision B fast path) and credited once', () async {
        final (c, circle) = await offered();
        today(c).start();
        final atTap = status(c);
        await R8Harness.settle();
        await act(c, 'Close');
        await restart(times: 2);
        evidence('C4 fast path', {'atTap': atTap.name, ...await facts(circle)});
        expect(atTap, RecommendationStatus.started);
        expect(await creditsOnDisk(circle), ['getting_going#1']);
      });
    });
  });

  // -----------------------------------------------------------------------
  // Group D — Insight provenance overwritten (Contract B). The two probes of
  // the open findings R832-B1/B2 (I3, I4 manual reversal) are kept outside
  // the suite, in the R8.3.2 evidence folder's open_findings/.

  group('Group D — Astra R83-N03 and Insight idempotence', () {
    final morning = DateTime(2026, 10, 30, 9);
    late R8Harness h;

    setUp(() async {
      h = R8Harness(morning);
      await h.boot();
    });

    Future<Map<String, Object?>> json(String key) async {
      final raw = (await h.disk.stored())[key];
      return raw is String ? jsonDecode(raw) as Map<String, Object?> : {};
    }

    CirclePart part(ElementId e) => CirclePart(e, elementOf(e).minutes);
    final window = [
      part(ElementId.openWindow),
      part(ElementId.standingStretch),
      part(ElementId.sitAMinute),
    ];
    final reading = [part(ElementId.phoneFaceDown), part(ElementId.readPages)];

    CircleJournalEntry entry(
      int ago,
      Intention need, {
      List<CirclePart> parts = const [],
      Set<ElementId> skipped = const {},
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

    String journalOf(List<CircleJournalEntry> entries) => jsonEncode({
      'schemaVersion': circleJournalSchemaVersion,
      'entries': [for (final e in entries) e.toJson()],
    });

    const energy = Intention.moreEnergy;
    const head = Intention.clearerHead;
    const stage = PlanStageProvenance(
      planId: 'getting_going',
      cycleId: 'getting_going#1',
      stageNumber: 1,
      stageId: 'getting_going.1',
    );
    // The fixture of r83_insight_attribution_test.dart: I2 qualifies.
    final i2 = <String, Object>{
      circlePlansKey: jsonEncode(
        CirclePlansState.empty
            .start('getting_going', today: '2026-10-01')!
            .toJson(),
      ),
      circleJournalKey: journalOf([
        for (final (k, ago) in [2, 5, 9, 13, 17].indexed)
          k.isEven
              ? entry(ago, energy, replacedFromStage: stage, reason: 'tooMuch')
              : entry(ago, energy, parts: window, stage: stage),
      ]),
    };
    final i3 = <String, Object>{
      circleJournalKey: journalOf([
        for (final ago in [2, 4, 6, 8, 10, 12, 15])
          entry(ago, head, parts: reading),
        for (final (k, ago) in [1, 5, 9, 11].indexed)
          entry(
            ago,
            energy,
            parts: window,
            skipped: k == 1 ? const {} : {ElementId.openWindow},
          ),
      ]),
    };

    InsightsNotifier insights(ProviderContainer c) =>
        c.read(insightsProvider.notifier);
    CirclePlansNotifier plans(ProviderContainer c) =>
        c.read(circlePlansProvider.notifier);

    Future<Map?> snapshotOnDisk(String id) async {
      final list = (await json(insightsKey))['snapshots'] as List? ?? [];
      for (final s in list) {
        if ((s as Map)['id'] == id) return s;
      }
      return null;
    }

    Future<Map?> planOnDisk() async =>
        ((await json(circlePlansKey))['plans'] as Map?)?['getting_going']
            as Map?;

    /// [shown] applied: its own change lands with its provenance, and only
    /// its applied mark is refused by the store.
    Future<InsightActionResult> applyMarkRefused(
      ProviderContainer c,
      InsightSnapshot shown,
    ) async {
      h.disk.fail(insightsKey, DiskFault.returnsFalse);
      final result = await insights(c).apply(shown.id);
      await R8Harness.settle();
      h.disk.healAll();
      return result;
    }

    /// Astra's R83-N03 sequence up to the retry: I2 applied with its mark
    /// refused; gentler turned off by hand and the Plan paused; seven days
    /// on, I1 applied to carry the same Plan on.
    Future<(ProviderContainer, InsightSnapshot, Map<String, Object?>)>
    overwritten() async {
      await h.boot(i2);
      final c = h.open();
      final shownI2 = insights(c).assess().added.single;
      expect(shownI2.family, InsightFamily.planPacing);
      await R8Harness.settle();
      expect(await applyMarkRefused(c, shownI2), InsightActionResult.done);
      final i2On = ((await planOnDisk())?['appliedInsight'] as Map?)?['on'];
      pre(i2On != null, 'I2\'s provenance on the Plan');
      expect(plans(c).stopGentler('getting_going'), PlanActionResult.done);
      expect(plans(c).pause('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      h.clock.value = morning.add(const Duration(days: 7));
      await h.restart();
      final c2 = h.open();
      final added = insights(c2).assess().added;
      await R8Harness.settle();
      final shownI1 = added
          .where((s) => s.family == InsightFamily.planForNeed)
          .firstOrNull;
      pre(
        shownI1 != null,
        'I1 generated seven days on (added: '
        '${[for (final s in added) s.family.name]})',
      );
      final i1Result = await insights(c2).apply(shownI1!.id);
      await R8Harness.settle();
      pre(i1Result == InsightActionResult.done, 'I1 applied ($i1Result)');
      return (
        c2,
        shownI2,
        <String, Object?>{
          'i2AppliedOnPlan': i2On,
          'i1': shownI1.id,
          'planAfterI1': await planOnDisk(),
          'i2StatusBeforeRetry': insights(
            c2,
          ).status(insights(c2).state.byId(shownI2.id)!).name,
          'i2SnapshotBeforeRetry': await snapshotOnDisk(shownI2.id),
        },
      );
    }

    test('D1 (R83-N03) I2 applied, mark refused; gentler off by hand and the '
        'Plan paused; I1 carries the Plan on seven days later; the original '
        'I2 retried: gentler is never turned on again', () async {
      final (c, shownI2, before) = await overwritten();
      final userPlan = await planOnDisk();
      final otherSnapshots = [
        for (final s in (await json(insightsKey))['snapshots'] as List)
          if ((s as Map)['id'] != shownI2.id) s,
      ];
      final retried = await insights(c).apply(shownI2.id);
      await R8Harness.settle();
      await h.restart();
      final after = await planOnDisk();
      final cycle = ((after?['cycles'] as List).last as Map);
      evidence('R83-N03 D1', {
        ...before,
        'retry': retried.name,
        'planAfterRetry': after,
        'i2SnapshotAfterRetry': await snapshotOnDisk(shownI2.id),
      });
      expect(
        cycle['gentlerSince'],
        isNull,
        reason: 'the retry turned gentler on again over the user\'s choice',
      );
      expect(jsonEncode(after), jsonEncode(userPlan));
      final mark = (await snapshotOnDisk(shownI2.id))?['appliedOn'];
      expect(
        mark,
        anyOf(isNull, before['i2AppliedOnPlan']),
        reason: 'a false application date was recorded',
      );
      expect(
        [
          for (final s in (await json(insightsKey))['snapshots'] as List)
            if ((s as Map)['id'] != shownI2.id) s,
        ],
        otherSnapshots,
        reason: 'another Insight was changed',
      );
    });

    test('D-ctl1 control: I2 never applied; I1 carries the Plan on later; '
        'I2 applied then: gentler turned on, I2 marked that day', () async {
      await h.boot(i2);
      final c = h.open();
      final shownI2 = insights(c).assess().added.single;
      await R8Harness.settle();
      expect(plans(c).pause('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      h.clock.value = morning.add(const Duration(days: 7));
      await h.restart();
      final c2 = h.open();
      final i1 = insights(c2)
          .assess()
          .added
          .where((s) => s.family == InsightFamily.planForNeed)
          .firstOrNull;
      await R8Harness.settle();
      pre(i1 != null, 'I1 generated seven days on');
      expect(await insights(c2).apply(i1!.id), InsightActionResult.done);
      await R8Harness.settle();
      pre(
        insights(c2).status(insights(c2).state.byId(shownI2.id)!) ==
            InsightStatus.current,
        'I2 still current',
      );
      final result = await insights(c2).apply(shownI2.id);
      await R8Harness.settle();
      final cycle = ((await planOnDisk())!['cycles'] as List).last as Map;
      evidence('R83-N03 D-ctl1', {
        'result': result.name,
        'plan': await planOnDisk(),
        'i2': await snapshotOnDisk(shownI2.id),
      });
      expect(result, InsightActionResult.done);
      expect(cycle['gentlerSince'], isNotNull);
      expect(
        (await snapshotOnDisk(shownI2.id))?['appliedOn'],
        dateKey(h.clock.value),
      );
    });

    test(
      'D-ctl2 control: I2 applied, mark refused, no other Insight: the '
      'retry records the mark with the original date and changes nothing',
      () async {
        await h.boot(i2);
        final c = h.open();
        final shownI2 = insights(c).assess().added.single;
        await R8Harness.settle();
        expect(await applyMarkRefused(c, shownI2), InsightActionResult.done);
        expect(plans(c).stopGentler('getting_going'), PlanActionResult.done);
        await R8Harness.settle();
        final userPlan = jsonEncode(await planOnDisk());
        await h.restart();
        final retried = await insights(h.open()).apply(shownI2.id);
        await R8Harness.settle();
        evidence('R83-N03 D-ctl2', {
          'retry': retried.name,
          'plan': await planOnDisk(),
          'i2': await snapshotOnDisk(shownI2.id),
        });
        expect(retried, InsightActionResult.done);
        expect(jsonEncode(await planOnDisk()), userPlan);
        expect(
          (await snapshotOnDisk(shownI2.id))?['appliedOn'],
          dateKey(morning),
        );
      },
    );

    test('D-ctl3 (R83-N03) the displaced Insight\'s mark is refused: the '
        'later Insight changes nothing, the earlier provenance stays, and '
        'both resolve once the store accepts', () async {
      await h.boot(i2);
      final c = h.open();
      final shownI2 = insights(c).assess().added.single;
      await R8Harness.settle();
      expect(await applyMarkRefused(c, shownI2), InsightActionResult.done);
      final i2On = ((await planOnDisk())?['appliedInsight'] as Map?)?['on'];
      expect(plans(c).stopGentler('getting_going'), PlanActionResult.done);
      expect(plans(c).pause('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      h.clock.value = morning.add(const Duration(days: 7));
      await h.restart();
      final c2 = h.open();
      final i1 = insights(c2)
          .assess()
          .added
          .where((s) => s.family == InsightFamily.planForNeed)
          .firstOrNull;
      await R8Harness.settle();
      pre(i1 != null, 'I1 generated seven days on');
      final planBefore = jsonEncode(await planOnDisk());
      h.disk.fail(insightsKey, DiskFault.returnsFalse);
      final refused = await insights(c2).apply(i1!.id);
      await R8Harness.settle();
      final planWhileRefused = jsonEncode(await planOnDisk());
      h.disk.healAll();
      final accepted = await insights(c2).apply(i1.id);
      await R8Harness.settle();
      final retriedI2 = await insights(c2).apply(shownI2.id);
      await R8Harness.settle();
      final cycle = ((await planOnDisk())!['cycles'] as List).last as Map;
      evidence('R83-N03 D-ctl3', {
        'refused': refused.name,
        'accepted': accepted.name,
        'retriedI2': retriedI2.name,
        'plan': await planOnDisk(),
        'i2': await snapshotOnDisk(shownI2.id),
        'i1': await snapshotOnDisk(i1.id),
      });
      expect(refused, InsightActionResult.notSaved);
      expect(planWhileRefused, planBefore);
      expect(accepted, InsightActionResult.done);
      expect((await planOnDisk())!['lifecycle'], 'active');
      expect(retriedI2, InsightActionResult.alreadyApplied);
      expect(cycle['gentlerSince'], isNull);
      expect((await snapshotOnDisk(shownI2.id))?['appliedOn'], i2On);
      expect((await snapshotOnDisk(i1.id))?['appliedOn'], '2026-11-06');
    });

    group('Claude H1 — I3 around Delete\'s final Preferences pass', () {
      for (final order in ['apply-then-delete', 'delete-then-apply']) {
        for (final heldPrefs in [false, true]) {
          test('H1 $order${heldPrefs ? ', Preferences write held' : ''}: no '
              'Insight id survives a Delete reported done', () async {
            await h.boot(i3);
            final c = h.open();
            final shown = insights(c).assess().added.single;
            await R8Harness.settle();
            final held = heldPrefs
                ? h.disk.hold(suggestionPreferencesKey)
                : null;
            Future<InsightActionResult>? applying;
            Future<void>? deleting;
            if (order == 'apply-then-delete') {
              applying = insights(c).apply(shown.id);
              deleting = c.read(circleHistoryDeletionProvider).delete();
            } else {
              deleting = c.read(circleHistoryDeletionProvider).delete();
              applying = insights(c).apply(shown.id);
            }
            await R8Harness.settle();
            held?.release();
            Object? deleteError;
            try {
              await deleting;
            } catch (e) {
              deleteError = e;
            }
            final applied = await applying;
            await R8Harness.settle();
            final raw = (await h.disk.stored())[suggestionPreferencesKey];
            evidence('H1 $order held=$heldPrefs', {
              'apply': applied.name,
              'deleteError': deleteError?.toString(),
              'prefs': raw,
              'pending': (await h.disk.stored())[historyDeletionPendingKey],
            });
            if (deleteError == null) {
              expect(
                raw is String && raw.contains('byInsight'),
                isFalse,
                reason: 'an Insight id survived a Delete reported done',
              );
            }
          });
        }
      }
    });
  });

  group('The paused-Start record\'s stored form', () {
    String read(Object? value) {
      final plan = PlanProgress.fromJson('getting_going', {
        'lifecycle': 'paused',
        'cycles': [
          PlanCycle(
            id: 'getting_going#1',
            number: 1,
            startedOn: '2026-10-01',
          ).toJson(),
        ],
        'startedWhilePaused': value,
      });
      return plan == null
          ? 'UNREADABLE'
          : jsonEncode(plan.toJson()['startedWhilePaused']);
    }

    test('O1 (Astra §7 observation) a value that names no day, or no '
        'instant, makes the Plan unreadable — kept as stored, never read as '
        'an exclusion that matches nothing', () {
      final damaged = <Object?>[
        '',
        'not-a-day',
        42,
        {'circleId': '2026-10-12'},
        {'circleId': '2026-10-12', 'startedAt': 'soon'},
        {'circleId': 'x', 'startedAt': '2026-10-12T07:00:00.000Z'},
        {'circleId': '2026-10-12', 'startedAt': 7},
      ];
      final seen = {for (final v in damaged) jsonEncode(v): read(v)};
      evidence('O1 malformed marker', seen);
      expect(seen.values.toSet(), {'UNREADABLE'});
    });

    test('O2 the record round-trips with its instant and any field this '
        'build doesn\'t know; an R8.3.1 record (the day alone) is read and '
        'written back as stored', () {
      const record = {
        'circleId': '2026-10-12',
        'startedAt': '2026-10-12T07:00:00.000Z',
        'futureField': 'kept',
      };
      expect(jsonDecode(read(record)), record);
      expect(read('2026-10-12'), jsonEncode('2026-10-12'));
    });

    test('O3 an R8.3.1 record still excludes every Start of its Circle; a '
        'record with an instant excludes only that Start', () {
      final at = DateTime.utc(2026, 10, 12, 7);

      /// Whether an active Plan holding [record] credits the Circle of
      /// 2026-10-12 started at [startedAt].
      bool credits(Object record, DateTime? startedAt) {
        final s = CirclePlansState.empty.start(
          'getting_going',
          today: '2026-10-12',
        )!;
        final json = jsonDecode(jsonEncode(s.toJson())) as Map<String, Object?>;
        final plan = (json['plans'] as Map)['getting_going'] as Map;
        plan['lastServed'] = {
          'circleId': '2026-10-12',
          'stage': {
            'planId': 'getting_going',
            'cycleId': 'getting_going#1',
            'stageNumber': 1,
            'stageId': 'getting_going.1',
          },
        };
        plan['startedWhilePaused'] = record;
        final read = CirclePlansState.fromJson(json)!;
        final after = read.recordGuided(
          read.plans['getting_going']!.lastServed!.stage,
          circleId: '2026-10-12',
          today: '2026-10-12',
          parts: const [],
          skipped: const [],
          startedAt: startedAt,
          closedAt: startedAt?.add(const Duration(minutes: 25)),
        );
        return !identical(after, read);
      }

      final exact = {
        'circleId': '2026-10-12',
        'startedAt': at.toIso8601String(),
      };
      final seen = {
        'legacy, any Start': credits('2026-10-12', at),
        'legacy, no instant': credits('2026-10-12', null),
        'exact, that Start': credits(exact, at),
        'exact, that Start as local time': credits(exact, at.toLocal()),
        'exact, no instant': credits(exact, null),
        'exact, a later Start': credits(
          exact,
          at.add(const Duration(minutes: 1)),
        ),
        'exact, 1 µs later': credits(
          exact,
          at.add(const Duration(microseconds: 1)),
        ),
      };
      evidence('O3 exclusion', seen);
      expect(seen, {
        'legacy, any Start': false,
        'legacy, no instant': false,
        'exact, that Start': false,
        'exact, that Start as local time': false,
        'exact, no instant': false,
        'exact, a later Start': true,
        'exact, 1 µs later': true,
      });
    });
  });
}
