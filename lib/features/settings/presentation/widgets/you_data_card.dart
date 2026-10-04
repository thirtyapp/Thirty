import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/application/circle_journal.dart';
import '../../../home/presentation/widgets/journal_data_controls.dart';
import 'you_group_card.dart';

/// You's "Data & privacy" group: "Copy as text", then "Delete Circle
/// history" as the group's final, destructive row. The same actions — and
/// the same confirmation — as Circle history's [JournalDataControls],
/// presented stacked here; the history page's own layout is unchanged.
///
/// "Delete Circle history" names exactly what it deletes: the Circle
/// journal, and the Insight snapshots drawn from it
/// ([JournalDataControls.confirmAndClear]). Plans, reminder, appearance,
/// analytics consent and Premium are untouched by it.
class YouDataCard extends ConsumerWidget {
  const YouDataCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(circleJournalRepositoryProvider);
    final hasEntries = journal.readAll().isNotEmpty;

    return YouGroupCard(
      children: [
        YouActionRow(
          label: 'Copy as text',
          icon: Icons.content_copy_outlined,
          onTap: hasEntries
              ? () => JournalDataControls.exportToClipboard(context, journal)
              : null,
        ),
        YouActionRow(
          label: 'Delete Circle history',
          icon: Icons.delete_outline,
          destructive: true,
          onTap: hasEntries
              ? () => JournalDataControls.confirmAndClear(context, journal, ref)
              : null,
        ),
      ],
    );
  }
}
