import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/storage/confirmed_write.dart';
import 'package:thirty/core/storage/store_save_failures.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/presentation/widgets/journal_save_failure_notice.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.1 — Astra N10 (LOW): a failure that happens while another notice is
/// open is still told once that notice closes, across stores and Circles;
/// a Kept Circles save that later succeeds clears its stale "unsaved"
/// status.
void main() {
  Future<ProviderContainer> pump(WidgetTester tester, R8Harness h) async {
    final c = h.open();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(
          home: JournalSaveFailureNotice(child: Scaffold(body: SizedBox())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> dismiss(WidgetTester tester) async {
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();
  }

  testWidgets('a store failure while the History notice is open is told '
      'after it closes — with no further change', (tester) async {
    final semantics = tester.ensureSemantics();
    final h = R8Harness(DateTime(2026, 10, 12, 9));
    await tester.runAsync(h.boot);
    final c = await pump(tester, h);
    c
        .read(journalSaveStatusProvider.notifier)
        .record('2026-10-12', saved: false);
    await tester.pumpAndSettle();
    expect(find.text(JournalSaveCopy.notSavedTitle), findsOneWidget);

    c.read(storeSaveFailuresProvider.notifier).record(UserStore.circlePlans);
    await tester.pumpAndSettle();
    expect(find.text(JournalSaveCopy.changeNotSavedTitle), findsNothing);

    await dismiss(tester);
    expect(
      find.text(JournalSaveCopy.changeNotSavedTitle),
      findsOneWidget,
      reason: 'the later failure was never told',
    );
    expect(
      find.bySemanticsLabel(JournalSaveCopy.changeNotSavedTitle),
      findsWidgets,
      reason: 'announced to a screen reader',
    );
    await dismiss(tester);
    expect(find.byType(AlertDialog), findsNothing);
    semantics.dispose();
  });

  testWidgets('a second Circle\'s History failure while a store notice is '
      'open is told after it closes', (tester) async {
    final h = R8Harness(DateTime(2026, 10, 12, 9));
    await tester.runAsync(h.boot);
    final c = await pump(tester, h);
    c.read(storeSaveFailuresProvider.notifier).record(UserStore.insights);
    await tester.pumpAndSettle();
    expect(find.text(JournalSaveCopy.changeNotSavedTitle), findsOneWidget);
    c
        .read(journalSaveStatusProvider.notifier)
        .record('2026-10-12', saved: false);
    await tester.pumpAndSettle();
    await dismiss(tester);
    expect(find.text(JournalSaveCopy.notSavedTitle), findsOneWidget);
    await dismiss(tester);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('several store failures while one notice is open: told once '
      'more after it closes, never stacked', (tester) async {
    final h = R8Harness(DateTime(2026, 10, 12, 9));
    await tester.runAsync(h.boot);
    final c = await pump(tester, h);
    final failures = c.read(storeSaveFailuresProvider.notifier);
    failures.record(UserStore.keptCircles);
    await tester.pumpAndSettle();
    failures
      ..record(UserStore.circlePlans)
      ..record(UserStore.insights);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await dismiss(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    await dismiss(tester);
    expect(find.byType(AlertDialog), findsNothing);
  });

  for (final fault in DiskFault.values) {
    test('a failed Keep (${fault.name}) then a successful one: Kept Circles '
        'are no longer marked unsaved', () async {
      final h = R8Harness(DateTime(2026, 10, 12, 9));
      await h.boot();
      final c = h.open(status: EntitlementStatus.inactive);
      final kept = c.read(keptCirclesProvider.notifier);
      final plan = CirclePlan.fromWire(const [
        'getItOut:6',
        'chooseOne:1',
        'clearCorner:8',
      ])!;
      h.disk.fail(keptCirclesKey, fault, times: 1);
      await expectLater(
        kept.keepCircle(
          plan: plan,
          need: Intention.clearerHead,
          circleId: 'd1',
        ),
        throwsA(isA<StorageWriteFailed>()),
      );
      await R8Harness.settle();
      expect(
        c.read(storeSaveFailuresProvider).unsaved,
        contains(UserStore.keptCircles),
      );
      expect(
        await kept.keepCircle(
          plan: plan,
          need: Intention.clearerHead,
          circleId: 'd1',
        ),
        isNotNull,
      );
      await R8Harness.settle();
      expect(c.read(storeSaveFailuresProvider).unsaved, isEmpty);
    });
  }
}
