import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_app_bar.dart';
import '../application/circle_journal.dart';
import 'widgets/circle_journal_entry_card.dart';
import 'widgets/journal_data_controls.dart';

/// THIRTY's narrow, read-only personal-record view (ADR-013 §6): the
/// user's own recorded Circle history, plus local deletion/reset and a
/// local export.
///
/// Deliberately **not**: activity replay, activity browsing, rankings,
/// streaks, progress scores, Insights, charts/dashboards, or a search
/// system — this is a plain, factual list, and the clear distinction it
/// draws per entry (shown/started/closed/reported attempt/reported
/// usefulness — ADR-010, ADR-013 §4) is the entire point: nothing here is
/// allowed to blur into a claim of verified completion or a performance
/// score.
///
/// **Founder IA correction:** no longer a primary bottom-nav destination
/// — the calm date-Circle calendar inside Insights
/// (`../../insights/presentation/widgets/circle_history_calendar.dart`)
/// is now the primary way to browse this same data, and export/delete
/// ([JournalDataControls]) now also live under the "You" destination's
/// own "Your data" section. This page stays registered at `/history`
/// as a secondary/compatibility surface — same data, same controls, just
/// no longer linked from any primary-nav element.
class CircleHistoryPage extends ConsumerWidget {
  const CircleHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(circleJournalRepositoryProvider);
    final entries = journal.readAll().reversed.toList();

    return Scaffold(
      appBar: const ThirtyAppBar(title: Text('Your Circle history')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: entries.isEmpty
                  ? const _EmptyHistory()
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.page),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.s),
                      itemBuilder: (context, index) =>
                          CircleJournalEntryCard(entry: entries[index]),
                    ),
            ),
            const Padding(
              padding: EdgeInsets.all(AppSpacing.page),
              child: JournalDataControls(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Text(
          'Nothing recorded yet. Your Circle history will appear here once '
          'you\'ve had a few days with THIRTY.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
      ),
    );
  }
}

