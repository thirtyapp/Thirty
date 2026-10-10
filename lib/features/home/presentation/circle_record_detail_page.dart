import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_app_bar.dart';
import '../../../core/widgets/thirty_confirm_dialog.dart';
import '../application/circle_journal.dart';
import '../application/recommendation_provider.dart';
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
      appBar: ThirtyAppBar(
        title: Text(humanJournalDate(localDate, withWeekday: false)),
      ),
      body: SafeArea(
        child: entry == null
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.page),
                child: _NoLongerAvailable(localDate: localDate),
              )
            : _ScrollableRecord(
                entry: entry,
                onRemoveAttempt: () => _confirmRemove(
                  context,
                  ref,
                  entry!,
                  includingAttempt: true,
                ),
                onRemoveUsefulness: () => _confirmRemove(
                  context,
                  ref,
                  entry!,
                  includingAttempt: false,
                ),
              ),
      ),
    );
  }

  /// "Remove this answer" (V2 Phase C): the record stays; THIRTY stops
  /// using the answer, and its memory and future picks recompute at once.
  static Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    CircleJournalEntry entry, {
    required bool includingAttempt,
  }) async {
    final alsoUsefulness = includingAttempt && entry.usefulnessResponse != null;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierLabel: 'Keep it',
      builder: (_) => ThirtyConfirmDialog(
        title: 'Remove this answer?',
        body: alsoUsefulness
            ? 'Your “Was it useful?” answer goes with it. The Circle stays in '
                  'your history; THIRTY stops using these answers.'
            : 'The Circle stays in your history; THIRTY stops using this '
                  'answer.',
        cancelLabel: 'Keep it',
        confirmLabel: 'Remove answer',
        destructive: true,
      ),
    );
    if (confirmed != true) return;
    ref
        .read(recommendationProvider.notifier)
        .removeAnswer(entry.circleId, includingAttempt: includingAttempt);
  }
}

/// The record card, scrollable once it is taller than the screen (large
/// accessibility text on a small phone overflowed by hundreds of pixels
/// when this was a plain [Padding]). The `minHeight` keeps the card's
/// existing treatment at normal sizes: it still fills the available
/// height, exactly as it did unscrolled, and only grows past it — and
/// starts scrolling — when its content genuinely needs more room.
class _ScrollableRecord extends StatelessWidget {
  const _ScrollableRecord({
    required this.entry,
    required this.onRemoveAttempt,
    required this.onRemoveUsefulness,
  });

  final CircleJournalEntry entry;
  final VoidCallback onRemoveAttempt;
  final VoidCallback onRemoveUsefulness;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(
                0,
                constraints.maxHeight - AppSpacing.page * 2,
              ),
            ),
            // The card hugs its record instead of stretching to the screen.
            child: Align(
              alignment: Alignment.topCenter,
              child: CircleJournalEntryCard(
                entry: entry,
                onRemoveAttempt: onRemoveAttempt,
                onRemoveUsefulness: onRemoveUsefulness,
              ),
            ),
          ),
        );
      },
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
        'There’s no record for '
        '${humanJournalDate(localDate, withWeekday: false)} anymore.',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
      ),
    );
  }
}
