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

    return Row(
      children: [
        Expanded(
          child: ThirtyButton(
            label: 'Copy as text',
            variant: ThirtyButtonVariant.secondary,
            onPressed: hasEntries
                ? () => _exportToClipboard(context, journal)
                : null,
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: ThirtyButton(
            label: 'Delete all',
            variant: ThirtyButtonVariant.secondary,
            onPressed: hasEntries
                ? () => _confirmClear(context, journal, ref)
                : null,
          ),
        ),
      ],
    );
  }

  static Future<void> _exportToClipboard(
    BuildContext context,
    CircleJournalRepository journal,
  ) async {
    await Clipboard.setData(ClipboardData(text: journal.exportAsJson()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied your Circle history as text.')),
    );
  }

  static Future<void> _confirmClear(
    BuildContext context,
    CircleJournalRepository journal,
    WidgetRef ref,
  ) async {
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
