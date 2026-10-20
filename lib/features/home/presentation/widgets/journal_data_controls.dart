import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../../../core/widgets/thirty_confirm_dialog.dart';
import '../../../insights/application/insights_provider.dart';
import '../../../insights/domain/insight.dart';
import '../../../personal_circle/application/kept_circles_provider.dart';
import '../../../plans/application/circle_plans_provider.dart';
import '../../../plans/domain/circle_plan.dart';
import '../../application/circle_journal.dart';
import '../../application/recommendation_provider.dart';
import '../../application/suggestion_preferences.dart';

/// THIRTY's local Circle-journal export/delete controls — extracted from
/// `../circle_history_page.dart` (founder IA correction — "export/delete
/// remain under You > Your data") so the same behavior is available both
/// there and from `../../../settings/presentation/settings_page.dart`'s
/// "Your data" section, without duplicating the confirm-dialog/export
/// logic or the underlying data.
///
/// Free/shared, entitlement-independent — Journal access never depended
/// on Premium and this correction does not change that.
class JournalDataControls extends ConsumerWidget {
  const JournalDataControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(circleJournalRepositoryProvider);
    final hasEntries = journal.readAll().isNotEmpty;
    final preferences = ref.watch(suggestionPreferencesProvider);
    final kept = ref.watch(keptCirclesProvider);
    final plans = ref.watch(circlePlansProvider);
    final insights = ref.watch(insightsProvider);

    // Paired buttons share one height: if large text wraps one label onto
    // a second line, both grow together (IntrinsicHeight + stretch). At
    // ordinary text sizes both stay exactly 48pt.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ThirtyButton(
              label: 'Copy as text',
              variant: ThirtyButtonVariant.secondary,
              onPressed:
                  hasEntries ||
                      !preferences.isEmpty ||
                      !kept.isEmpty ||
                      plans.plans.isNotEmpty
                  ? () => exportToClipboard(
                      context,
                      journal,
                      preferences: preferences,
                      kept: kept,
                      plans: plans,
                      insights: insights,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: ThirtyButton(
              label: 'Delete all',
              variant: ThirtyButtonVariant.secondary,
              onPressed: hasEntries
                  ? () => confirmAndClear(context, journal, ref)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Copies the journal as text — with the user's suggestion preferences
  /// beside it (V2 Phase C), when there are any — and confirms with a
  /// SnackBar. Shared with You's own "Your data" rows (`settings_page.dart`),
  /// which present the same actions stacked; this widget's own side-by-side
  /// layout (Circle history) is unchanged.
  static Future<void> exportToClipboard(
    BuildContext context,
    CircleJournalRepository journal, {
    SuggestionPreferences preferences = SuggestionPreferences.empty,
    KeptCircles kept = KeptCircles.empty,
    CirclePlansState plans = CirclePlansState.empty,
    InsightsState insights = InsightsState.empty,
  }) async {
    await Clipboard.setData(
      ClipboardData(
        text: journal.exportAsJson(
          suggestionPreferences: preferences.isEmpty
              ? null
              : preferences.toJson(),
          // The Circles the user kept — never a derived score.
          keptCircles: kept.isEmpty
              ? null
              : [for (final circle in kept.kept) circle.toJson()],
          // Each Circle Plan's place, cycles and stage records (B3).
          circlePlans: plans.plans.isEmpty ? null : plans.toJson(),
          // The Insights THIRTY showed, as shown (B5) — no profile.
          insights: insights.isEmpty ? null : insights.toJson(),
        ),
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied your Circle history as text.')),
    );
  }

  /// Asks for explicit confirmation, then deletes every recorded Circle —
  /// the journal, today's Circle session and the selection history drawn
  /// from past Circles — and with them everything learned from them. Today
  /// is then re-derived from the empty store, so no deleted Circle stays on
  /// screen. Shared with You's "Your data" rows.
  ///
  /// Kept Circles and suggestion preferences are kept — they have their own
  /// controls — but nothing learned survives the evidence it came from.
  /// A Circle Plan keeps its place; its stage evidence and reviews go with
  /// the journal (contract, Delete / Export), and so does every Insight
  /// snapshot — each is derived from it.
  static Future<void> confirmAndClear(
    BuildContext context,
    CircleJournalRepository journal,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierLabel: 'Keep my history',
      builder: (_) => const ThirtyConfirmDialog(
        title: 'Delete your Circle history?',
        body:
            'This permanently deletes every recorded Circle on this device, '
            'and everything THIRTY has learned from them, Insights and Plan '
            'reviews included. Your kept Circles, each Plan’s place and '
            'your suggestion preferences are kept — you can change those '
            'yourself. It cannot be undone, and nothing is '
            'stored anywhere else to restore it from.',
        cancelLabel: 'Keep my history',
        confirmLabel: 'Delete permanently',
        destructive: true,
      ),
    );
    if (confirmed != true) return;

    final plans = ref.read(circlePlansProvider.notifier);
    await journal.clearAll();
    await clearRecordedCircleState(ref.read(sharedPreferencesProvider));
    final forgotten = plans.forgetStageEvidence();
    final insightsForgotten = ref.read(insightsProvider.notifier).forgetAll();
    ref.invalidate(circleJournalRepositoryProvider);
    ref.invalidate(recommendationProvider);
    await forgotten;
    await insightsForgotten;
  }
}
