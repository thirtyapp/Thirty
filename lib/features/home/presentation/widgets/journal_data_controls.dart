import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../../../core/widgets/thirty_confirm_dialog.dart';
import '../../../insights/application/insight_provider.dart';
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
              onPressed: hasEntries || !preferences.isEmpty
                  ? () => exportToClipboard(
                      context,
                      journal,
                      preferences: preferences,
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
  }) async {
    await Clipboard.setData(
      ClipboardData(
        text: journal.exportAsJson(
          suggestionPreferences: preferences.isEmpty
              ? null
              : preferences.toJson(),
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
  /// from past Circles — and any Insight derived from them. Today is then
  /// re-derived from the empty store, so no deleted Circle stays on screen.
  /// Shared with You's "Your data" rows.
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
            'and everything THIRTY has learned from them. Your suggestion '
            'preferences are kept — you can reset them in What THIRTY '
            'remembers. It cannot be undone, and nothing is stored anywhere '
            'else to restore it from.',
        cancelLabel: 'Keep my history',
        confirmLabel: 'Delete permanently',
        destructive: true,
      ),
    );
    if (confirmed != true) return;

    await journal.clearAll();
    await clearRecordedCircleState(ref.read(sharedPreferencesProvider));
    ref.invalidate(circleJournalRepositoryProvider);
    ref.invalidate(recommendationProvider);
    // Batch 2C: a derived Insight must never outlive the evidence it was
    // drawn from — "stop derived personalization... remove its dependent
    // snapshots" (frozen architecture §9).
    await ref.read(insightProvider.notifier).clearAll();
  }
}
