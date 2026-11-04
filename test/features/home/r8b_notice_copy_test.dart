import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/storage/store_save_failures.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_notice_dialog.dart';
import 'package:thirty/features/home/presentation/widgets/journal_data_controls.dart';
import 'package:thirty/features/home/presentation/widgets/journal_save_failure_notice.dart';

/// Founder decision D1 (2026-11-04): the approved words for a kept-Circle,
/// Plan or Insight save that wasn't confirmed, and for a Delete that never
/// began — each in THIRTY's one-action notice, announced by its title (not
/// "Alert"), dismissed by "Close", never claiming more than is proven.
void main() {
  test('the approved words, exactly', () {
    expect(
      JournalSaveCopy.changeNotSavedTitle,
      'This change couldn’t be saved.',
    );
    expect(JournalSaveCopy.changeNotSavedBody, 'Please try again.');
    expect(deleteNotStartedTitle, 'Your history wasn’t deleted.');
    expect(deleteNotStartedBody, 'Nothing was changed. You can try again.');
    // No claim about earlier saved data on this path (founder: unproven).
    expect(JournalSaveCopy.changeNotSavedBody, isNot(contains('overwritten')));
  });

  testWidgets('a store save not confirmed: one notice, by its title, with '
      'the approved body and a Close button', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: JournalSaveFailureNotice(child: SizedBox.expand()),
          ),
        ),
      ),
    );
    c.read(storeSaveFailuresProvider.notifier).record(UserStore.keptCircles);
    await tester.pumpAndSettle();
    expect(find.byType(ThirtyNoticeDialog), findsOneWidget);
    expect(find.text('This change couldn’t be saved.'), findsOneWidget);
    expect(find.text('Please try again.'), findsOneWidget);
    expect(
      tester.widget<AlertDialog>(find.byType(AlertDialog)).semanticLabel,
      JournalSaveCopy.changeNotSavedTitle,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(ThirtyNoticeDialog), findsNothing);

    // A refusal the caller reports its own way adds no second notice.
    c
        .read(storeSaveFailuresProvider.notifier)
        .record(UserStore.circlePlans, notify: false);
    await tester.pumpAndSettle();
    expect(find.byType(ThirtyNoticeDialog), findsNothing);
    expect(
      c.read(storeSaveFailuresProvider).unsaved,
      containsAll([UserStore.keptCircles, UserStore.circlePlans]),
    );
  });
}
