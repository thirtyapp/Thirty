import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/features/home/application/circle_history_deletion.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/presentation/memory_page.dart';
import 'package:thirty/features/home/presentation/widgets/journal_data_controls.dart';
import 'package:thirty/features/settings/presentation/widgets/you_data_card.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';
import 'l1_fixture.dart';

/// L-1 Option B (founder decision, 2026-11-11) — what the user sees and can
/// do about a Suggestion Preferences record THIRTY can't read as a whole.
///
/// - L-1A: a Delete Circle history that succeeds says so truthfully: the
///   History was deleted, but the record couldn't be checked for links to
///   it and was kept unchanged. The confirmation says so beforehand. No
///   such word after a Delete that didn't start, or didn't finish.
/// - L-1B: "Copy as text" carries the record exactly as the store holds it
///   (`suggestionPreferencesStored`, typed), from You and from History, even
///   when it is the only thing stored; a copy that fails says so.
/// - L-1C: the memory page says, from what is stored — after any restart —
///   that some saved preferences can't be read, offers Copy as text, and
///   offers Reset with its own warning; the notice goes only once the store
///   has confirmed the Reset.
///
/// Black-box: the store, the screen and the clipboard only — the same tests
/// ran on the frozen tree before the change (failing-before evidence).
void main() {
  late L1Fixture f;
  late R8Harness h;
  late FakeClipboard clipboard;

  setUpAll(() async => f = await L1Fixture.seed());

  Future<ProviderContainer> boot(
    WidgetTester tester,
    Map<String, Object> stored,
  ) async {
    h = R8Harness(L1Fixture.morning);
    await h.boot(stored);
    clipboard = FakeClipboard()..install(tester);
    return h.open();
  }

  void bigView(WidgetTester tester) {
    tester.view.physicalSize = const Size(412, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  bool unreadable(String name) => L1Fixture.unreadableCases.contains(name);
  bool shown(String text) => find.text(text).evaluate().isNotEmpty;

  final entryPoints = [
    ('You', const YouDataCard(), 'Delete Circle history'),
    ('History', const JournalDataControls(), 'Delete all'),
  ];

  group('L-1A — Delete Circle history, from You and from History', () {
    for (final (where, controls, deleteLabel) in entryPoints) {
      final cases = where == 'You'
          ? L1Fixture.allCases
          : [L1Fixture.readable, L1Fixture.newerSchema, L1Fixture.nativeInt];
      for (final name in cases) {
        testWidgets('$where, $name: the confirmation and the outcome say only '
            'what is true', (tester) async {
          final c = await boot(tester, f.withPreferences(name));
          await pumpL1(tester, c, controls);
          await tester.tap(find.text(deleteLabel));
          await tester.pumpAndSettle();
          expect(find.text('Delete your Circle history?'), findsOneWidget);
          expect(
            find.textContaining(L1Words.confirmQualifier),
            unreadable(name) ? findsOneWidget : findsNothing,
          );
          await tester.tap(find.text('Delete permanently'));
          await tester.pumpAndSettle();
          final s = await h.disk.stored();
          expect(s.containsKey(historyDeletionPendingKey), isFalse);
          expect(s.containsKey(circleJournalKey), isFalse);
          expect(shown(L1Words.notStartedTitle), isFalse);
          expect(shown(L1Words.unfinishedTitle), isFalse);
          if (unreadable(name)) {
            expect(find.text(L1Words.deletedNoticeTitle), findsOneWidget);
            expect(find.text(L1Words.deletedNoticeBody), findsOneWidget);
            expect(
              sameStoredValue(s[suggestionPreferencesKey], f.variants[name]),
              isTrue,
            );
            await tester.tap(find.text('Close'));
            await tester.pumpAndSettle();
            expect(find.byType(Dialog), findsNothing);
          } else {
            expect(find.byType(Dialog), findsNothing);
            expect(
              '${s[suggestionPreferencesKey]}',
              isNot(contains(f.insightId)),
            );
          }
        });
      }
    }

    for (final (label, fault, expected) in [
      (
        'the intent refused',
        (FaultDisk d) =>
            d.fail(historyDeletionPendingKey, DiskFault.returnsFalse),
        L1Words.notStartedTitle,
      ),
      (
        'the intent uncertain (its write threw)',
        (FaultDisk d) => d.fail(historyDeletionPendingKey, DiskFault.throws),
        L1Words.notStartedTitle,
      ),
      (
        'a History removal refused',
        (FaultDisk d) => d.fail(circleJournalKey, DiskFault.returnsFalse),
        L1Words.unfinishedTitle,
      ),
      (
        'a History removal landed with its answer lost',
        (FaultDisk d) => d.ackLost(circleJournalKey),
        L1Words.unfinishedTitle,
      ),
    ]) {
      testWidgets('$label, record unreadable: the usual failure words, never '
          'the qualified-completion notice', (tester) async {
        final c = await boot(tester, f.withPreferences(L1Fixture.newerSchema));
        await pumpL1(tester, c, const YouDataCard());
        fault(h.disk);
        await tester.tap(find.text('Delete Circle history'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete permanently'));
        await tester.pumpAndSettle();
        expect(find.text(expected), findsOneWidget);
        expect(shown(L1Words.deletedNoticeTitle), isFalse);
        h.disk.healAll();
        expect(
          sameStoredValue(
            (await h.disk.stored())[suggestionPreferencesKey],
            f.variants[L1Fixture.newerSchema],
          ),
          isTrue,
        );
      });
    }

    testWidgets('control — a History removal refused, record readable: the '
        'usual words, no notice', (tester) async {
      final c = await boot(tester, f.withPreferences(L1Fixture.readable));
      await pumpL1(tester, c, const YouDataCard());
      h.disk.fail(circleJournalKey, DiskFault.returnsFalse);
      await tester.tap(find.text('Delete Circle history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();
      expect(find.text(L1Words.unfinishedTitle), findsOneWidget);
      expect(shown(L1Words.deletedNoticeTitle), isFalse);
    });
  });

  group('L-1B — Copy as text, from You and from History', () {
    for (final (where, controls, _) in entryPoints) {
      final cases = where == 'You'
          ? L1Fixture.allCases
          : [L1Fixture.readable, L1Fixture.newerSchema, L1Fixture.nativeInt];
      for (final name in cases) {
        testWidgets('$where, $name: the preferences are exported — a record '
            'THIRTY can\'t read exactly as stored, a readable one as '
            'before', (tester) async {
          final c = await boot(tester, f.withPreferences(name));
          await pumpL1(tester, c, controls);
          await tester.tap(find.text('Copy as text'));
          await tester.pumpAndSettle();
          expect(clipboard.copied, hasLength(1));
          expect(find.text(L1Words.copied), findsOneWidget);
          final out = clipboard.last;
          for (final key in [
            'entries',
            'keptCircles',
            'circlePlans',
            'insights',
          ]) {
            expect(out.containsKey(key), isTrue, reason: key);
          }
          if (unreadable(name)) {
            expect(out.containsKey('suggestionPreferences'), isFalse);
            expect(
              sameStoredValue(
                decodeStoredPreferences(out['suggestionPreferencesStored']),
                f.variants[name],
              ),
              isTrue,
            );
          } else {
            expect(out.containsKey('suggestionPreferencesStored'), isFalse);
            expect(
              out['suggestionPreferences'],
              jsonDecode(f.variants[name]! as String),
            );
          }
        });
      }
    }

    final values = <(String, Object)>[
      (
        'text, with whitespace and non-ASCII',
        '  {"schemaVersion": 7}\n\té😀  ',
      ),
      ('empty text', ''),
      ('text with an unpaired surrogate', 'a\uD800b'),
      ('true', true),
      ('false', false),
      ('an int beyond JavaScript\'s safe range', 9007199254740993),
      ('the smallest int', -9223372036854775807 - 1),
      ('zero', 0),
      ('-0.0', -0.0),
      ('NaN', double.nan),
      ('infinity', double.infinity),
      ('negative infinity', double.negativeInfinity),
      ('the smallest subnormal', 5e-324),
      ('0.1', 0.1),
      (
        'a string list with duplicates and blanks',
        <String>['b', 'a', 'a', '', ' x '],
      ),
      ('an empty string list', <String>[]),
    ];
    for (final (label, value) in values) {
      testWidgets('the only thing stored is a preferences value THIRTY can\'t '
          'read — $label: Copy is offered and exports it losslessly', (
        tester,
      ) async {
        final c = await boot(tester, {suggestionPreferencesKey: value});
        await pumpL1(tester, c, const YouDataCard());
        await tester.tap(find.text('Copy as text'));
        await tester.pumpAndSettle();
        expect(clipboard.copied, hasLength(1));
        final out = clipboard.last;
        expect(out.containsKey('suggestionPreferences'), isFalse);
        final back = decodeStoredPreferences(
          out['suggestionPreferencesStored'],
        );
        expect(
          sameStoredValue(back, h.prefs.get(suggestionPreferencesKey)),
          isTrue,
          reason: '$back',
        );
      });
    }

    for (final name in [L1Fixture.readable, L1Fixture.newerSchema]) {
      testWidgets('$name: a copy the clipboard refuses says so — never '
          '"Copied"', (tester) async {
        final c = await boot(tester, f.withPreferences(name));
        await pumpL1(tester, c, const YouDataCard());
        clipboard.fail = true;
        await tester.tap(find.text('Copy as text'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(shown(L1Words.copied), isFalse);
        expect(find.text(L1Words.copyFailed), findsOneWidget);
      });
    }

    testWidgets('control — nothing stored: nothing to copy', (tester) async {
      final c = await boot(tester, const {});
      await pumpL1(tester, c, const YouDataCard());
      await tester.tap(find.text('Copy as text'));
      await tester.pumpAndSettle();
      expect(clipboard.copied, isEmpty);
    });
  });

  group('L-1C — What THIRTY remembers: the notice and Reset', () {
    Future<ProviderContainer> memory(
      WidgetTester tester,
      Map<String, Object> stored, {
      double textScale = 1,
    }) async {
      bigView(tester);
      final c = await boot(tester, stored);
      await pumpL1(tester, c, const MemoryPage(), textScale: textScale);
      return c;
    }

    Future<void> confirmReset(
      WidgetTester tester, {
      bool confirm = true,
    }) async {
      await tester.tap(find.text(L1Words.resetLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(confirm ? 'Reset' : 'Keep them'));
      await tester.pumpAndSettle();
    }

    for (final name in L1Fixture.allCases) {
      testWidgets('$name: the notice shows only for a record THIRTY can\'t '
          'read; Reset is offered either way', (tester) async {
        await memory(tester, f.withPreferences(name));
        expect(
          find.text(L1Words.memoryNotice),
          unreadable(name) ? findsOneWidget : findsNothing,
        );
        expect(find.text(L1Words.resetLabel), findsOneWidget);
      });
    }

    testWidgets('control — no preferences stored: no notice, no Reset', (
      tester,
    ) async {
      await memory(tester, {...f.store}..remove(suggestionPreferencesKey));
      expect(find.text(L1Words.memoryNotice), findsNothing);
      expect(find.text(L1Words.resetLabel), findsNothing);
    });

    for (final name in L1Fixture.unreadableCases) {
      testWidgets('$name: Reset warns in its own words; confirmed by the '
          'store, the record goes and so does the notice — at once and after '
          'a restart', (tester) async {
        final c = await memory(tester, f.withPreferences(name));
        await tester.tap(find.text(L1Words.resetLabel));
        await tester.pumpAndSettle();
        expect(find.text(L1Words.resetUnreadableTitle), findsOneWidget);
        expect(find.text(L1Words.resetUnreadableBody), findsOneWidget);
        expect(find.text(L1Words.resetReadableTitle), findsNothing);
        await tester.tap(find.text('Reset'));
        await tester.pumpAndSettle();
        expect(
          (await h.disk.stored()).containsKey(suggestionPreferencesKey),
          isFalse,
        );
        expect(find.text(L1Words.memoryNotice), findsNothing);
        expect(find.text(L1Words.resetLabel), findsNothing);
        expect(c.read(suggestionPreferencesProvider).isEmpty, isTrue);
        await h.restart();
        await pumpL1(tester, h.open(), const MemoryPage());
        expect(find.text(L1Words.memoryNotice), findsNothing);
      });
    }

    testWidgets('Reset cancelled: nothing is written; the notice stays', (
      tester,
    ) async {
      await memory(tester, f.withPreferences(L1Fixture.newerSchema));
      final before = h.disk.attempts.length;
      await confirmReset(tester, confirm: false);
      expect([
        for (final a in h.disk.attempts.skip(before))
          if (a.endsWith(suggestionPreferencesKey)) a,
      ], isEmpty);
      expect(find.text(L1Words.memoryNotice), findsOneWidget);
    });

    for (final (label, fault) in [
      (
        'refused',
        (FaultDisk d) =>
            d.fail(suggestionPreferencesKey, DiskFault.returnsFalse),
      ),
      (
        'uncertain (its write threw)',
        (FaultDisk d) => d.fail(suggestionPreferencesKey, DiskFault.throws),
      ),
      (
        'landed with its answer lost',
        (FaultDisk d) => d.ackLost(suggestionPreferencesKey),
      ),
    ]) {
      testWidgets('Reset $label: the record is kept as stored, and the notice '
          'and Reset stay — nothing claims it was removed', (tester) async {
        await memory(tester, f.withPreferences(L1Fixture.newerSchema));
        fault(h.disk);
        await confirmReset(tester);
        h.disk.healAll();
        expect(
          sameStoredValue(
            (await h.disk.stored())[suggestionPreferencesKey],
            f.variants[L1Fixture.newerSchema],
          ),
          isTrue,
        );
        expect(find.text(L1Words.memoryNotice), findsOneWidget);
        expect(find.text(L1Words.resetLabel), findsOneWidget);
      });
    }

    testWidgets('control — readable preferences: Reset keeps its own words '
        'and still removes them', (tester) async {
      await memory(tester, f.withPreferences(L1Fixture.readable));
      await tester.tap(find.text(L1Words.resetLabel));
      await tester.pumpAndSettle();
      expect(find.text(L1Words.resetReadableTitle), findsOneWidget);
      expect(find.text(L1Words.resetUnreadableTitle), findsNothing);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(
        (await h.disk.stored()).containsKey(suggestionPreferencesKey),
        isFalse,
      );
    });

    testWidgets('a restart rebuilds the notice from what is stored', (
      tester,
    ) async {
      await memory(tester, f.withPreferences(L1Fixture.malformed));
      expect(find.text(L1Words.memoryNotice), findsOneWidget);
      await h.restart();
      await pumpL1(tester, h.open(), const MemoryPage());
      expect(find.text(L1Words.memoryNotice), findsOneWidget);
    });

    testWidgets('after a Delete that succeeded — and after the start-up that '
        'finished an interrupted one — the memory page still says so', (
      tester,
    ) async {
      bigView(tester);
      final c = await boot(tester, f.withPreferences(L1Fixture.newerSchema));
      await pumpL1(tester, c, const YouDataCard());
      await tester.tap(find.text('Delete Circle history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();
      await pumpL1(tester, c, const MemoryPage());
      expect(find.text(L1Words.memoryNotice), findsOneWidget);

      h = R8Harness(L1Fixture.morning);
      await h.boot({
        ...f.withPreferences(L1Fixture.stringList),
        historyDeletionPendingKey: true,
      });
      await h.restart();
      await pumpL1(tester, h.open(), const MemoryPage());
      expect(find.text(L1Words.memoryNotice), findsOneWidget);
      expect(
        (await h.disk.stored()).containsKey(historyDeletionPendingKey),
        isFalse,
      );
    });

    testWidgets('Copy as text from the notice exports the record as stored', (
      tester,
    ) async {
      await memory(tester, f.withPreferences(L1Fixture.nativeInt));
      await tester.tap(find.text('Copy as text'));
      await tester.pumpAndSettle();
      expect(find.text(L1Words.copied), findsOneWidget);
      expect(
        decodeStoredPreferences(clipboard.last['suggestionPreferencesStored']),
        42,
      );
    });

    testWidgets('Copy while a Reset is being written exports the record as '
        'last confirmed; once the Reset is confirmed it is gone from the '
        'notice and the export', (tester) async {
      final c = await memory(tester, f.withPreferences(L1Fixture.newerSchema));
      final held = h.disk.hold(suggestionPreferencesKey);
      await confirmReset(tester);
      expect(held.isWaiting, isTrue);
      expect(find.text(L1Words.memoryNotice), findsOneWidget);
      await tester.tap(find.text('Copy as text'));
      await tester.pumpAndSettle();
      expect(
        sameStoredValue(
          decodeStoredPreferences(
            clipboard.last['suggestionPreferencesStored'],
          ),
          f.variants[L1Fixture.newerSchema],
        ),
        isTrue,
      );
      held.release();
      await tester.pumpAndSettle();
      expect(find.text(L1Words.memoryNotice), findsNothing);
      await pumpL1(tester, c, const YouDataCard());
      await tester.tap(find.text('Copy as text'));
      await tester.pumpAndSettle();
      expect(
        clipboard.last.containsKey('suggestionPreferencesStored'),
        isFalse,
      );
      expect(clipboard.last.containsKey('suggestionPreferences'), isFalse);
    });

    testWidgets('a Reset being written that the store then refuses: the '
        'notice and the export keep the record', (tester) async {
      final c = await memory(tester, f.withPreferences(L1Fixture.newerSchema));
      final held = h.disk.hold(suggestionPreferencesKey);
      await confirmReset(tester);
      held.release(DiskFault.returnsFalse);
      await tester.pumpAndSettle();
      expect(find.text(L1Words.memoryNotice), findsOneWidget);
      await pumpL1(tester, c, const YouDataCard());
      await tester.tap(find.text('Copy as text'));
      await tester.pumpAndSettle();
      expect(
        sameStoredValue(
          decodeStoredPreferences(
            clipboard.last['suggestionPreferencesStored'],
          ),
          f.variants[L1Fixture.newerSchema],
        ),
        isTrue,
      );
    });

    testWidgets('Reset tapped twice before its warning opens: each warning '
        'still needs its own confirmation; confirmed, the record goes and '
        'nothing fails', (tester) async {
      await memory(tester, f.withPreferences(L1Fixture.newerSchema));
      await tester.tap(find.text(L1Words.resetLabel));
      await tester.tap(find.text(L1Words.resetLabel), warnIfMissed: false);
      await tester.pumpAndSettle();
      final warnings = find
          .text(L1Words.resetUnreadableTitle)
          .evaluate()
          .length;
      expect(warnings, inInclusiveRange(1, 2));
      expect(
        (await h.disk.stored()).containsKey(suggestionPreferencesKey),
        isTrue,
        reason: 'nothing may be removed before a confirmation',
      );
      for (var i = 0; i < warnings; i++) {
        await tester.tap(find.text('Reset').last);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      expect(
        (await h.disk.stored()).containsKey(suggestionPreferencesKey),
        isFalse,
      );
      expect(find.text(L1Words.memoryNotice), findsNothing);
    });

    testWidgets('the page closed while its Reset is still being written: no '
        'error; the confirmed outcome is what the page shows when it opens '
        'again', (tester) async {
      final c = await memory(tester, f.withPreferences(L1Fixture.newerSchema));
      final held = h.disk.hold(suggestionPreferencesKey);
      await confirmReset(tester);
      await tester.pumpWidget(const SizedBox());
      held.release();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        (await h.disk.stored()).containsKey(suggestionPreferencesKey),
        isFalse,
      );
      await pumpL1(tester, c, const MemoryPage());
      expect(find.text(L1Words.memoryNotice), findsNothing);
    });

    testWidgets('the preferences rebuilt (invalidated): the notice still '
        'reads what is stored', (tester) async {
      final c = await memory(tester, f.withPreferences(L1Fixture.listShape));
      c.invalidate(suggestionPreferencesProvider);
      await tester.pumpAndSettle();
      expect(find.text(L1Words.memoryNotice), findsOneWidget);
      await confirmReset(tester);
      c.invalidate(suggestionPreferencesProvider);
      await tester.pumpAndSettle();
      expect(find.text(L1Words.memoryNotice), findsNothing);
    });

    testWidgets('large text (200%) and a screen reader: the notice reads '
        'before Reset, every control is a 48pt button with its own label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await memory(
        tester,
        f.withPreferences(L1Fixture.newerSchema),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      final notice = find.text(L1Words.memoryNotice);
      expect(notice, findsOneWidget);
      final copy = find.widgetWithText(ThirtyButton, 'Copy as text');
      expect(copy, findsOneWidget);
      expect(tester.getSize(copy).height, greaterThanOrEqualTo(48));
      expect(
        tester.getTopLeft(notice).dy,
        lessThan(tester.getTopLeft(find.text(L1Words.resetLabel)).dy),
      );
      final reset = tester.getSemantics(find.text(L1Words.resetLabel));
      expect(reset, isSemantics(isButton: true));
      expect(reset.label, startsWith(L1Words.resetLabel));
      expect(find.bySemanticsLabel(RegExp('couldn’t be read')), findsWidgets);
      semantics.dispose();
    });
  });
}
