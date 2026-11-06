import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.2 reconciliation with the original Claude post-R8.1 audit report
/// (docs/audits/THIRTY_CLAUDE_POST_R8_1_AUDIT_REPORT.txt), NEW-1. Its
/// acceptance condition asks for "a regression test for both triggers"; the
/// R8.2 NEW-1 tests (r82_a03_new1_stage_publication_test.dart) cover the
/// mechanism, these run the report's own trigger scenarios:
///
/// - Trigger A: stage 5 closes, the Plan ends, and "Go through it again" is
///   tapped on the review page — or the I1 Insight is applied — before that
///   Circle's reflection is answered; and Leave, then starting the same Plan
///   again mid-Circle.
/// - Trigger B: one transient Plans failure at choice time. The Circle must
///   never be run and then lost: it is taken back before it can start, the
///   user is told, and the next choice is saved and runs.
void main() {
  final morning = DateTime(2026, 10, 12, 9);
  late R8Harness h;

  setUp(() async {
    h = R8Harness(morning);
    await h.boot();
  });

  RecommendationNotifier today(ProviderContainer c) =>
      c.read(recommendationProvider.notifier);
  CirclePlansNotifier plans(ProviderContainer c) =>
      c.read(circlePlansProvider.notifier);

  Future<void> closeAndReflect(ProviderContainer c) async {
    today(c).close();
    await R8Harness.settle();
    today(c).reportAttempt(CircleAttemptResponse.yes);
    await R8Harness.settle();
    today(c).reportUsefulness(CircleUsefulnessResponse.veryUseful);
    await R8Harness.settle();
  }

  /// The Circle [id] closed and fully answered — on disk, and in a fresh
  /// process, in Today and in History.
  Future<void> savedAcrossRestart(String id) async {
    final stored = await h.disk.stored();
    expect(stored[recommendationStatusKey], 'closed', reason: 'Close lost');
    expect(stored[recommendationAttemptResponseKey], 'yes');
    expect(stored[recommendationUsefulnessResponseKey], 'veryUseful');
    await h.restart();
    final again = h.open();
    expect(
      again.read(recommendationProvider).status,
      RecommendationStatus.closed,
    );
    final entry = again
        .read(circleJournalRepositoryProvider)
        .readAll()
        .singleWhere((e) => e.circleId == id);
    expect(entry.closedAt, isNotNull, reason: 'History lost the Close');
    expect(entry.attemptResponse, CircleAttemptResponse.yes);
    expect(entry.usefulnessResponse, CircleUsefulnessResponse.veryUseful);
  }

  /// Five real days of "Getting going": each stage Circle chosen, started
  /// and closed; the last one's Close ends the Plan, its reflection not yet
  /// answered. Returns the open container and that stage-5 Circle's id.
  Future<(ProviderContainer, String)> stageFiveClosed() async {
    var c = h.open();
    expect(plans(c).start('getting_going'), PlanActionResult.done);
    await R8Harness.settle();
    String? lastId;
    for (var day = 0; day < 8; day++) {
      today(
        c,
      ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await R8Harness.settle();
      lastId = c.read(recommendationProvider).recommendation!.circleId;
      today(c).start();
      await R8Harness.settle();
      today(c).close();
      await R8Harness.settle();
      if (c.read(circlePlansProvider).plans['getting_going']!.lifecycle ==
          PlanLifecycle.ended) {
        break;
      }
      today(c).reportAttempt(CircleAttemptResponse.yes);
      await R8Harness.settle();
      h.clock.value = h.clock.value.add(const Duration(days: 1));
      await h.restart();
      c = h.open();
      c.read(nowProvider);
    }
    expect(
      c.read(circlePlansProvider).plans['getting_going']!.lifecycle,
      PlanLifecycle.ended,
      reason: 'precondition: stage 5 closed and credited',
    );
    return (c, lastId!);
  }

  group('Trigger A — no storage fault', () {
    test('stage 5 closed, the Plan ended; "Go through it again" on the '
        'review page; that Circle\'s reflection is saved, also after a '
        'restart', () async {
      final (c, id) = await stageFiveClosed();
      expect(plans(c).goThroughAgain('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      today(c).reportAttempt(CircleAttemptResponse.yes);
      await R8Harness.settle();
      today(c).reportUsefulness(CircleUsefulnessResponse.veryUseful);
      await R8Harness.settle();
      expect(c.read(journalSaveStatusProvider)[id], isNot(false));
      await savedAcrossRestart(id);
    });

    test('stage 5 closed, the Plan ended; the I1 application (its confirmed '
        '"Go through it again"); that Circle\'s reflection is saved, also '
        'after a restart', () async {
      final (c, id) = await stageFiveClosed();
      expect(
        await plans(c).confirmed(
          (p) => p.goThroughAgain('getting_going', byInsight: 'i1_proxy'),
        ),
        PlanActionResult.done,
      );
      await R8Harness.settle();
      today(c).reportAttempt(CircleAttemptResponse.yes);
      await R8Harness.settle();
      today(c).reportUsefulness(CircleUsefulnessResponse.veryUseful);
      await R8Harness.settle();
      expect(c.read(journalSaveStatusProvider)[id], isNot(false));
      await savedAcrossRestart(id);
    });

    test('a stage Circle started; Leave, then Start the same Plan again '
        'mid-Circle; its Close and reflection are saved, also after a '
        'restart', () async {
      final c = h.open();
      expect(plans(c).start('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      today(
        c,
      ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await R8Harness.settle();
      final rec = c.read(recommendationProvider).recommendation!;
      expect(rec.composed?.stage, isNotNull, reason: 'precondition: stage');
      today(c).start();
      await R8Harness.settle();
      expect((await h.disk.stored())[recommendationStatusKey], 'started');
      expect(plans(c).leave('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      expect(plans(c).start('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      expect(plans(c).hasUnsavedChanges, isFalse);
      h.clock.value = morning.add(const Duration(minutes: 25));
      await closeAndReflect(c);
      expect(c.read(journalSaveStatusProvider)[rec.circleId], isNot(false));
      await savedAcrossRestart(rec.circleId);
    });
  });

  for (final fault in DiskFault.values) {
    test('Trigger B (${fault.name}) — one transient failure of the '
        'served-stage write at choice time: the Circle is taken back before '
        'it can start and the user is told; the next choice is saved, runs, '
        'and reaches History', () async {
      final c = h.open();
      expect(plans(c).start('getting_going'), PlanActionResult.done);
      await R8Harness.settle();
      h.disk.fail(circlePlansKey, fault, times: 1);
      today(
        c,
      ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      final id = c.read(recommendationProvider).recommendation!.circleId;
      await R8Harness.settle();
      expect(
        c.read(recommendationProvider).recommendation,
        isNull,
        reason: 'an unsaveable stage Circle left on screen to run',
      );
      expect(
        c.read(journalSaveStatusProvider)[id],
        isFalse,
        reason: 'taken back without telling the user',
      );
      expect((await h.disk.stored())[recommendationStatusKey], isNull);

      // The store has healed (one failure only): today's choice again.
      today(
        c,
      ).chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await R8Harness.settle();
      final again = c.read(recommendationProvider).recommendation!;
      expect((await h.disk.stored())[recommendationDayKey], again.circleId);
      today(c).start();
      await R8Harness.settle();
      expect(
        c.read(recommendationProvider).status,
        RecommendationStatus.started,
      );
      expect((await h.disk.stored())[recommendationStatusKey], 'started');
      h.clock.value = morning.add(const Duration(minutes: 25));
      await closeAndReflect(c);
      expect(c.read(journalSaveStatusProvider)[again.circleId], isNot(false));
      await savedAcrossRestart(again.circleId);
    });
  }
}
