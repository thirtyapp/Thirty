import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../../insights/application/insight_provider.dart';
import '../../application/circle_journal.dart';

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
              onPressed: hasEntries
                  ? () => exportToClipboard(context, journal)
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

  /// Copies the journal as text and confirms with a SnackBar. Shared with
  /// You's own "Your data" rows (`settings_page.dart`), which present the
  /// same actions stacked; this widget's own side-by-side layout (Circle
  /// history) is unchanged.
  static Future<void> exportToClipboard(
    BuildContext context,
    CircleJournalRepository journal,
  ) async {
    await Clipboard.setData(ClipboardData(text: journal.exportAsJson()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied your Circle history as text.')),
    );
  }

  /// Asks for explicit confirmation, then deletes every recorded Circle and
  /// any Insight derived from them. Shared with You's "Your data" rows.
  static Future<void> confirmAndClear(
    BuildContext context,
    CircleJournalRepository journal,
    WidgetRef ref,
  ) async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete your Circle history?'),
        content: const Text(
          'This permanently deletes every recorded Circle on this device. '
          'It cannot be undone, and nothing is stored anywhere else to '
          'restore it from.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep my history'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: colors.errorText),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await journal.clearAll();
    ref.invalidate(circleJournalRepositoryProvider);
    // Batch 2C: a derived Insight must never outlive the evidence it was
    // drawn from — "stop derived personalization... remove its dependent
    // snapshots" (frozen architecture §9).
    await ref.read(insightProvider.notifier).clearAll();
  }
}
