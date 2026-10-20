import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_consent.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../home/application/circle_journal.dart';
import '../../../home/application/suggestion_preferences.dart';
import '../../../home/presentation/widgets/journal_data_controls.dart';
import '../../../insights/application/insights_provider.dart';
import '../../../personal_circle/application/kept_circles_provider.dart';
import '../../../plans/application/circle_plans_provider.dart';
import 'you_group_card.dart';

/// You's "Data & privacy" group: "Share anonymous usage data" (analytics
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
class YouDataCard extends ConsumerWidget {
  const YouDataCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(circleJournalRepositoryProvider);
    final hasEntries = journal.readAll().isNotEmpty;
    final preferences = ref.watch(suggestionPreferencesProvider);
    final kept = ref.watch(keptCirclesProvider);
    final plans = ref.watch(circlePlansProvider);
    final insights = ref.watch(insightsProvider);

    return YouGroupCard(
      children: [
        const YouRow(
          key: ValueKey('you.analytics'),
          child: _AnalyticsConsentRow(),
        ),
        YouActionRow(
          label: 'Copy as text',
          icon: Icons.content_copy_outlined,
          onTap:
              hasEntries ||
                  !preferences.isEmpty ||
                  !kept.isEmpty ||
                  plans.plans.isNotEmpty
              ? () => JournalDataControls.exportToClipboard(
                  context,
                  journal,
                  preferences: preferences,
                  kept: kept,
                  plans: plans,
                  insights: insights,
                )
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
                      YouRowTitle('Share anonymous usage data'),
                      SizedBox(height: AppSpacing.xs),
                      YouRowDetail(
                        'Off by default. Helps us understand what to '
                        'improve. Your Circle history is never included.',
                      ),
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
