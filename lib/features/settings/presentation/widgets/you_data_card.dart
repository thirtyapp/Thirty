import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/application/circle_journal.dart';
import '../../../home/presentation/widgets/journal_data_controls.dart';
import 'you_group_card.dart';

/// You's "Your data" group (Phase C1): "Copy as text", then "Delete all"
/// as the page's final, destructive row. The same actions — and the same
/// confirmation — as Circle history's [JournalDataControls], presented
/// stacked here; the history page's own layout is unchanged.
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
          onTap: hasEntries
              ? () => JournalDataControls.exportToClipboard(context, journal)
              : null,
        ),
        YouActionRow(
          label: 'Delete all',
          destructive: true,
          onTap: hasEntries
              ? () => JournalDataControls.confirmAndClear(context, journal, ref)
              : null,
        ),
      ],
    );
  }
}
