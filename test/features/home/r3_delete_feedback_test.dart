import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The platform store is the controlled "disk" here; it ships with
// shared_preferences, so no dependency is added.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_notice_dialog.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_history_deletion.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/presentation/widgets/daily_intention_prompt.dart';
import 'package:thirty/features/home/presentation/widgets/journal_data_controls.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';

/// Audit remediation R3 — when Delete Circle history can't be finished, the
/// user is told so in the founder's words, never that it was done; the
/// deletion stays recorded and the next start finishes it. Nothing deleted
/// comes back while the message is on screen.
void main() {
  final now = DateTime(2026, 10, 12, 9);
  late _Disk disk;
  late SharedPreferences prefs;

  Future<void> boot([Map<String, Object> stored = const {}]) async {
    disk = _Disk(Map.of(stored));
    SharedPreferencesStorePlatform.instance = disk;
    SharedPreferences.resetStatic();
    prefs = await SharedPreferences.getInstance();
  }

  ProviderContainer open() {
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(now),
        eventClockProvider.overrideWithValue(() => now),
        entitlementStatusProvider.overrideWith(_Active.new),
        safetyPendingAllowedProvider.overrideWithValue(false),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// A Plan under way and today's stage Circle closed: history to delete.
  Future<ProviderContainer> withHistory(WidgetTester tester) async {
    await boot();
    final c = open();
    c.read(circlePlansProvider.notifier).start('getting_going');
    final today = c.read(recommendationProvider.notifier);
    today.chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
    today.start();
    await tester.pumpAndSettle();
    today.close();
    await tester.pumpAndSettle();
    expect(c.read(circleJournalRepositoryProvider).readAll(), hasLength(1));
    return c;
  }

  Future<void> deleteThroughDialog(
    WidgetTester tester,
    ProviderContainer c, {
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Consumer(
              builder: (context, ref, _) => Scaffold(
                body: TextButton(
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
        ),
      ),
    );
    await tester.tap(find.text('Delete Circle history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete permanently'));
    await tester.pumpAndSettle();
  }

  /// What reached the disk, opened as the next start opens it.
  Future<ProviderContainer> restart() async {
    await boot(await disk.getAll());
    await completeInterruptedHistoryDeletion(prefs);
    return open();
  }

  void expectNothingDeletedOnShow(ProviderContainer c) {
    expect(c.read(circleJournalRepositoryProvider).readAll(), isEmpty);
    expect(c.read(recommendationProvider).recommendation, isNull);
    expect(
      c.read(circlePlansProvider).plans['getting_going']!.current.records,
      isEmpty,
    );
    expect(c.read(insightsProvider).snapshots, isEmpty);
  }

  testWidgets('it worked: no message — the history is simply gone', (
    tester,
  ) async {
    final c = await withHistory(tester);
    await deleteThroughDialog(tester, c);
    expect(find.byType(ThirtyNoticeDialog), findsNothing);
    expect(find.text(deleteUnfinishedTitle), findsNothing);
    expectNothingDeletedOnShow(c);
    expect((await disk.getAll())['flutter.$historyDeletionPendingKey'], isNull);
  });

  for (final (what, failing, removalsOnly, once) in [
    ('the journal', 'flutter.$circleJournalKey', false, false),
    ('today\'s Circle', 'flutter.$recommendationStatusKey', false, false),
    ('Plan stage evidence', 'flutter.$circlePlansKey', false, false),
    ('Insight snapshots', 'flutter.$insightsKey', false, false),
    // The intent itself is recorded; only removing it — the last step —
    // fails.
    ('the last step', 'flutter.$historyDeletionPendingKey', true, false),
  ]) {
    testWidgets('a write to $what fails: the founder\'s message, the intent '
        'kept, nothing deleted back on screen — and the next start '
        'finishes it', (tester) async {
      final c = await withHistory(tester);
      disk
        ..failing = failing
        ..removalsOnly = removalsOnly
        ..failuresLeft = once ? 1 : null;
      await deleteThroughDialog(tester, c);

      expect(find.byType(ThirtyNoticeDialog), findsOneWidget);
      expect(
        find.text('Couldn’t finish deleting your history.'),
        findsOneWidget,
      );
      expect(
        find.text('THIRTY will try to finish when you next open the app.'),
        findsOneWidget,
      );
      // Announced by its title, not "Alert".
      expect(
        tester.widget<AlertDialog>(find.byType(AlertDialog)).semanticLabel,
        deleteUnfinishedTitle,
      );
      expectNothingDeletedOnShow(c);
      expect(
        (await disk.getAll())['flutter.$historyDeletionPendingKey'],
        isTrue,
      );

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(ThirtyNoticeDialog), findsNothing);
      expectNothingDeletedOnShow(c);

      disk.failing = null;
      final next = await restart();
      expectNothingDeletedOnShow(next);
      final stored = await disk.getAll();
      expect(
        stored.keys.where(
          (k) =>
              k.startsWith('flutter.recommendation_') ||
              k == 'flutter.$circleJournalKey' ||
              k == 'flutter.$insightsKey' ||
              k == 'flutter.$historyDeletionPendingKey',
        ),
        isEmpty,
      );
      // The Plan's place stays.
      expect(
        next.read(circlePlansProvider).plans['getting_going']!.current.cursor,
        2,
      );
    });
  }

  // Audit remediation R8 (Astra R7-A04): the intent is recorded — and
  // confirmed — before anything is removed.
  testWidgets('recording the intent fails once: it is tried again, and the '
      'deletion completes — no message, nothing pending', (tester) async {
    final c = await withHistory(tester);
    disk
      ..failing = 'flutter.$historyDeletionPendingKey'
      ..failuresLeft = 1;
    await deleteThroughDialog(tester, c);
    expect(find.byType(ThirtyNoticeDialog), findsNothing);
    expectNothingDeletedOnShow(c);
    expect((await disk.getAll())['flutter.$historyDeletionPendingKey'], isNull);
  });

  testWidgets('the intent can\'t be recorded at all: nothing is deleted, and '
      'the user is told so — never that it will finish', (tester) async {
    final c = await withHistory(tester);
    disk.failing = 'flutter.$historyDeletionPendingKey';
    await deleteThroughDialog(tester, c);
    expect(find.text(deleteNotStartedTitle), findsOneWidget);
    expect(find.text(deleteNotStartedBody), findsOneWidget);
    // Announced by its title, not "Alert" (founder decision D1).
    expect(
      tester.widget<AlertDialog>(find.byType(AlertDialog)).semanticLabel,
      deleteNotStartedTitle,
    );
    expect(find.text(deleteUnfinishedBody), findsNothing);
    expect(c.read(circleJournalRepositoryProvider).readAll(), hasLength(1));
    final stored = await disk.getAll();
    expect(stored['flutter.$historyDeletionPendingKey'], isNull);
    expect(stored['flutter.$circleJournalKey'], isNotNull);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    disk.failing = null;
    final next = await restart();
    expect(next.read(circleJournalRepositoryProvider).readAll(), hasLength(1));
  });

  testWidgets('a Delete still pending, then a need tapped: finished first '
      'when it can be; when it can\'t, the same message and no Circle', (
    tester,
  ) async {
    final c = await withHistory(tester);
    disk.failing = 'flutter.$circleJournalKey';
    await deleteThroughDialog(tester, c);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(c.read(circleHistoryDeletionProvider).isPending, isTrue);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SingleChildScrollView(child: DailyIntentionPrompt()),
          ),
        ),
      ),
    );
    // Still failing: told so, and today waits.
    await tester.tap(find.text('Clearer Head'));
    await tester.pumpAndSettle();
    expect(find.text(deleteUnfinishedTitle), findsOneWidget);
    expect(c.read(recommendationProvider).recommendation, isNull);
    expect(c.read(circleJournalRepositoryProvider).readAll(), isEmpty);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    // It can be finished now: it is, and the Circle begins.
    disk.failing = null;
    await tester.tap(find.text('Clearer Head'));
    await tester.pumpAndSettle();
    expect(find.text(deleteUnfinishedTitle), findsNothing);
    expect(c.read(circleHistoryDeletionProvider).isPending, isFalse);
    expect(
      c.read(recommendationProvider).recommendation!.intention,
      Intention.clearerHead,
    );
    expect((await disk.getAll())['flutter.$historyDeletionPendingKey'], isNull);
  });

  testWidgets('at 2× text the message reads in full', (tester) async {
    final c = await withHistory(tester);
    disk.failing = 'flutter.$circleJournalKey';
    await deleteThroughDialog(tester, c, textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text(deleteUnfinishedTitle), findsOneWidget);
    expect(find.text(deleteUnfinishedBody), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });
}

class _Active extends EntitlementNotifier {
  @override
  EntitlementStatus build() => EntitlementStatus.active;
}

/// The platform store, where one key's writes can be made to fail.
class _Disk extends InMemorySharedPreferencesStore {
  _Disk(super.data) : super.withData();

  String? failing;
  bool removalsOnly = false;

  /// How many more writes fail; `null`: every one.
  int? failuresLeft;

  void _maybeFail(String key) {
    if (key != failing || failuresLeft == 0) return;
    if (failuresLeft != null) failuresLeft = failuresLeft! - 1;
    throw StateError('disk write failed');
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (!removalsOnly) _maybeFail(key);
    return super.setValue(valueType, key, value);
  }

  @override
  Future<bool> remove(String key) async {
    _maybeFail(key);
    return super.remove(key);
  }
}
