import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../application/circle_journal.dart';
import 'widgets/circle_journal_entry_card.dart';

/// One recorded local date's Circle detail — reached by tapping a
/// marked date on the founder-approved date-Circle calendar
/// (`../../insights/presentation/widgets/circle_history_calendar.dart`).
///
/// Free/shared, entitlement-independent, exactly like the existing
/// `/history` list it is derived from — reading an already-recorded date
/// is never paid content. Reuses the same [CircleJournalEntryCard] and
/// the same underlying [circleJournalRepositoryProvider] as
/// `../circle_history_page.dart` — no new history store, no duplicated
/// record.
///
/// [localDate] may no longer resolve (the record was deleted, or the
/// date was never actually recorded — a stale link) — that renders a
/// safe, truthful "no longer available" message rather than a crash or
/// a fabricated record.
class CircleRecordDetailPage extends ConsumerWidget {
  const CircleRecordDetailPage({super.key, required this.localDate});

  final String localDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(circleJournalRepositoryProvider);
    CircleJournalEntry? entry;
    for (final candidate in journal.readAll()) {
      if (candidate.localDate == localDate) {
        entry = candidate;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(localDate)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: entry == null
              ? _NoLongerAvailable(localDate: localDate)
              : CircleJournalEntryCard(entry: entry),
        ),
      ),
    );
  }
}

class _NoLongerAvailable extends StatelessWidget {
  const _NoLongerAvailable({required this.localDate});

  final String localDate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Text(
        'No record for $localDate is available anymore.',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
      ),
    );
  }
}
