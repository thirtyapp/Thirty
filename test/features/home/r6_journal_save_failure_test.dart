import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The platform store is the controlled "disk" here; it ships with
// shared_preferences, so no dependency is added.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/presentation/circle_history_page.dart';
import 'package:thirty/features/home/presentation/widgets/journal_save_failure_notice.dart';

class _Disk extends InMemorySharedPreferencesStore {
  _Disk(super.data) : super.withData();

  String? failing;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == failing) throw StateError('disk write failed');
    return super.setValue(valueType, key, value);
  }
}

/// R6 final (founder direction 2026-11-03): a Circle whose save to History
/// fails is never shown as saved. The outcome of each save reaches the
/// screen — once for each Circle, accessibly — and History that THIRTY
/// couldn't open is said so, never shown as "nothing recorded". Nothing
/// stored is overwritten; the Circle itself stays usable.
void main() {
  final morning = DateTime(2026, 10, 12, 9);
  late _Disk disk;
  late SharedPreferences prefs;

  final newer = jsonEncode({
    'schemaVersion': circleJournalSchemaVersion + 1,
    'entries': const <Object?>[],
  });

  Future<void> boot(Map<String, Object> stored) async {
    disk = _Disk({
      for (final MapEntry(:key, :value) in stored.entries)
        'flutter.$key': value,
    });
    SharedPreferencesStorePlatform.instance = disk;
    SharedPreferences.resetStatic();
    prefs = await SharedPreferences.getInstance();
  }

  Future<Object?> onDisk(String key) async =>
      (await disk.getAll())['flutter.$key'];

  ProviderContainer open() {
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(morning),
        eventClockProvider.overrideWithValue(() => morning),
        safetyPendingAllowedProvider.overrideWithValue(false),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('the outcome of each save', () {
    test('a readable journal: saved — recorded as saved', () async {
      await boot({});
      final c = open();
      c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy, window: TimeWindow.about10);
      await settle();
      expect(c.read(journalSaveStatusProvider), {'2026-10-12': true});
      expect(c.read(circleJournalRepositoryProvider).readAll(), hasLength(1));
    });

    test('a journal from a newer THIRTY: not saved — recorded as not '
        'saved, the stored bytes unchanged, the Circle still usable', () async {
      await boot({circleJournalKey: newer});
      final c = open();
      final today = c.read(recommendationProvider.notifier);
      today.chooseIntention(Intention.moreEnergy, window: TimeWindow.about10);
      await settle();
      expect(c.read(journalSaveStatusProvider), {'2026-10-12': false});
      expect(await onDisk(circleJournalKey), newer);
      today.start();
      await settle();
      expect(
        c.read(recommendationProvider).status,
        RecommendationStatus.started,
      );
      today.close();
      await settle();
      expect(
        c.read(recommendationProvider).status,
        RecommendationStatus.closed,
      );
      expect(c.read(journalSaveStatusProvider)['2026-10-12'], isFalse);
      expect(await onDisk(circleJournalKey), newer);
      expect(c.read(circleJournalRepositoryProvider).readAll(), isEmpty);
    });

    test('a damaged journal whose copy can\'t be written: not saved, '
        'nothing written over; once the disk recovers, saved', () async {
      await boot({circleJournalKey: 'damaged'});
      disk.failing = 'flutter.$circleJournalPreservedKey';
      final c = open();
      c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy, window: TimeWindow.about10);
      await settle();
      expect(c.read(journalSaveStatusProvider), {'2026-10-12': false});
      expect(await onDisk(circleJournalKey), 'damaged');
      disk.failing = null;
      c.read(recommendationProvider.notifier).start();
      await settle();
      expect(c.read(journalSaveStatusProvider), {'2026-10-12': true});
      expect(await onDisk(circleJournalPreservedKey), ['damaged']);
    });
  });

  group('what the user is told', () {
    Future<ProviderContainer> pumpNotice(WidgetTester tester) async {
      await boot({});
      final c = open();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const JournalSaveFailureNotice(
              child: Scaffold(body: Text('today')),
            ),
          ),
        ),
      );
      await tester.pump();
      return c;
    }

    testWidgets('a failed save: the notice, in the founder\'s words, once '
        'for that Circle; announced by its title', (tester) async {
      final c = await pumpNotice(tester);
      final status = c.read(journalSaveStatusProvider.notifier);
      status.record('2026-10-12', saved: false);
      await tester.pumpAndSettle();
      expect(find.text(JournalSaveCopy.notSavedTitle), findsOneWidget);
      expect(find.text(JournalSaveCopy.notSavedBody), findsOneWidget);
      expect(
        find.bySemanticsLabel(JournalSaveCopy.notSavedTitle),
        findsWidgets,
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      // The same Circle fails again: not told twice.
      status
        ..record('2026-10-12', saved: true)
        ..record('2026-10-12', saved: false);
      await tester.pumpAndSettle();
      expect(find.text(JournalSaveCopy.notSavedTitle), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      status.record('2026-10-12', saved: false);
      await tester.pumpAndSettle();
      expect(find.text(JournalSaveCopy.notSavedTitle), findsNothing);
    });

    testWidgets('a successful save: nothing is shown', (tester) async {
      final c = await pumpNotice(tester);
      c
          .read(journalSaveStatusProvider.notifier)
          .record('2026-10-12', saved: true);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    test('the founder\'s words, exactly', () {
      expect(
        '${JournalSaveCopy.notSavedTitle} ${JournalSaveCopy.notSavedBody}',
        'This Circle couldn’t be saved to History. Your existing saved data '
            'wasn’t overwritten.',
      );
      expect(
        JournalSaveCopy.unopened,
        'Your History couldn’t be opened. THIRTY has left the stored data '
        'unchanged.',
      );
      expect(
        JournalSaveCopy.preserved,
        'Some earlier History couldn’t be opened. THIRTY preserved a copy '
        'before continuing.',
      );
    });
  });

  group('History that couldn\'t be opened', () {
    Future<void> pumpHistory(WidgetTester tester) async {
      final c = open();
      tester.view.physicalSize = const Size(412, 915) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const CircleHistoryPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a journal from a newer THIRTY: said so — never "nothing '
        'recorded"', (tester) async {
      await boot({circleJournalKey: newer});
      await pumpHistory(tester);
      expect(find.text(JournalSaveCopy.unopened), findsOneWidget);
      expect(find.textContaining('Nothing recorded yet'), findsNothing);
      // A screen reader reaches it as its own stop.
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel(JournalSaveCopy.unopened), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a copy was kept before saving: said so, beside today\'s '
        'History', (tester) async {
      await boot({circleJournalKey: 'damaged'});
      await CircleJournalRepository(prefs).recordShown(
        circleId: '2026-10-12',
        localDate: '2026-10-12',
        direction: Intention.moreEnergy,
        activityId: ActivityId.values.first,
        shownAt: morning,
      );
      await pumpHistory(tester);
      expect(find.text(JournalSaveCopy.preserved), findsOneWidget);
      expect(find.text(JournalSaveCopy.unopened), findsNothing);
    });

    testWidgets('an ordinary journal: no notice', (tester) async {
      await boot({});
      await pumpHistory(tester);
      expect(find.text(JournalSaveCopy.preserved), findsNothing);
      expect(find.text(JournalSaveCopy.unopened), findsNothing);
      expect(find.textContaining('Nothing recorded yet'), findsOneWidget);
    });
  });
}
