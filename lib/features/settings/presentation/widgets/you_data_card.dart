import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_consent.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../home/application/circle_journal.dart';
import '../../../home/presentation/widgets/journal_data_controls.dart';
import 'you_group_card.dart';

/// You's "Data & privacy" group: "Share usage data" (analytics
/// consent — founder decision, B7: a privacy control, not a preference),
/// "Copy as text", then "Delete Circle history" as the group's final,
/// destructive row. "Reset suggestion preferences" stays in What THIRTY
/// remembers, beside what it resets. The same actions — and
/// the same confirmation — as Circle history's [JournalDataControls],
/// presented stacked here; the history page's own layout is unchanged.
///
/// "Delete Circle history" names exactly what it deletes: the Circle
/// journal and everything learned from it
/// ([JournalDataControls.confirmAndClear]). Kept Circles, suggestion
/// preferences, reminder, appearance, analytics consent and Premium are
/// untouched by it.
/// The usage-data setting's words (audit remediation R6, Audit #2 A2-06):
/// what is actually sent while it is on — the six events, their shared
/// fields, the random ID this phone makes — and what turning it off does.
/// Title founder-approved (2026-11-03): "anonymous" is gone, since one
/// stable ID links the events.
abstract final class UsageDataCopy {
  static const title = 'Share usage data';
  static const detail =
      'Off by default. It helps us understand what to improve. When on, '
      'THIRTY sends a few facts about your use: '
      'when you open the app, which need and activity it suggests, when you '
      'start and close a Circle, and your “Did you try it?” and “Was it '
      'useful?” answers — each with the date and time, the app version, a '
      'test-group label and a random ID made on this phone. Never your name, '
      'anything you type, or your History as a whole. Turning this off stops '
      'sending; what was already sent isn’t deleted.';
}

class YouDataCard extends ConsumerWidget {
  const YouDataCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(circleJournalRepositoryProvider);
    // Audit remediation R8 (Astra R7-A06): History THIRTY can't read is
    // still the user's to export and delete — never only what it reads.
    final hasEntries = journal.holdsHistory;

    return YouGroupCard(
      children: [
        const YouRow(
          key: ValueKey('you.analytics'),
          child: _AnalyticsConsentRow(),
        ),
        YouActionRow(
          label: 'Copy as text',
          icon: Icons.content_copy_outlined,
          // L-1 Option B: the same Copy as History's — a preferences record
          // THIRTY can't read included, even when it is all there is.
          onTap: JournalDataControls.canCopyAsText(ref)
              ? () => JournalDataControls.copyAsText(context, ref)
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

class _AnalyticsConsentRow extends ConsumerWidget {
  const _AnalyticsConsentRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(analyticsConsentProvider);

    return MergeSemantics(
      child: Row(
        children: [
          const Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                YouRowIcon(Icons.query_stats),
                SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      YouRowTitle(UsageDataCopy.title),
                      SizedBox(height: AppSpacing.xs),
                      YouRowDetail(UsageDataCopy.detail),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: consent,
            onChanged: (value) =>
                ref.read(analyticsConsentProvider.notifier).setConsent(value),
          ),
        ],
      ),
    );
  }
}
