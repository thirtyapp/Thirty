import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_button.dart';
import '../../../core/widgets/thirty_card.dart';
import '../../plans/domain/plan_catalog.dart';
import '../../plans/domain/plan_ids.dart';
import '../application/activity_catalog.dart';
import '../application/circle_journal.dart';

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
class CircleHistoryPage extends ConsumerWidget {
  const CircleHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(circleJournalRepositoryProvider);
    final entries = journal.readAll().reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Your Circle history')),
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
                          _JournalEntryCard(entry: entries[index]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.page),
              child: Row(
                children: [
                  Expanded(
                    child: ThirtyButton(
                      label: 'Copy as text',
                      variant: ThirtyButtonVariant.secondary,
                      onPressed: entries.isEmpty
                          ? null
                          : () => _exportToClipboard(context, journal),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: ThirtyButton(
                      label: 'Delete all',
                      variant: ThirtyButtonVariant.secondary,
                      onPressed: entries.isEmpty
                          ? null
                          : () => _confirmClear(context, journal, ref),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToClipboard(
    BuildContext context,
    CircleJournalRepository journal,
  ) async {
    await Clipboard.setData(ClipboardData(text: journal.exportAsJson()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied your Circle history as text.')),
    );
  }

  Future<void> _confirmClear(
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

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({required this.entry});

  final CircleJournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;

    return ThirtyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.localDate, style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${intentionLabel(entry.direction)} — '
            '${activityLabel(entry.activityId)}',
            style: textTheme.bodyMedium,
          ),
          if (_planContextLabel(entry) case final label?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.s),
          _StatusLine(label: 'Shown', value: _formatTime(entry.shownAt)),
          _StatusLine(
            label: 'Started',
            value: entry.startedAt == null
                ? 'Not started'
                : _formatTime(entry.startedAt!),
          ),
          _StatusLine(
            label: 'Closed',
            value: entry.closedAt == null
                ? 'Not closed'
                : _formatTime(entry.closedAt!),
          ),
          _StatusLine(
            label: 'Reported attempt',
            value: _attemptLabel(entry.attemptResponse),
          ),
          _StatusLine(
            label: 'Reported usefulness',
            value: _usefulnessLabel(entry.usefulnessResponse),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Closed is a factual app interaction only — it never confirms '
            'the activity was actually done.',
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// A plain, bounded Plan-context line for [entry] — "Plan name, stage/
  /// place, cycle" (frozen architecture §15) — or `null` for a
  /// Free-selector-resolved entry, or one whose stage reference no longer
  /// resolves in the current catalogue (fail-safe: the rest of the record
  /// still displays normally either way). Never an activity browser, a
  /// score, or anything beyond this one factual line.
  static String? _planContextLabel(CircleJournalEntry entry) {
    final planIdName = entry.planId;
    final stageId = entry.stageId;
    if (planIdName == null || stageId == null) return null;

    final planId = PlanId.values.asNameMap()[planIdName];
    if (planId == null) return null;
    final plan = planDefinitionFor(planId);
    final stageIndex = plan.stages.indexWhere((s) => s.id == stageId);
    final stageLabel = stageIndex >= 0
        ? ', stage ${stageIndex + 1} of ${plan.stages.length}'
        : '';
    final cycleId = entry.planCycleId;
    final cycleLabel = cycleId == null ? '' : ' (cycle $cycleId)';
    return 'Plan: ${plan.name}$stageLabel$cycleLabel';
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _attemptLabel(CircleAttemptResponse? response) =>
      switch (response) {
        null => 'No answer',
        CircleAttemptResponse.yes => 'Yes',
        CircleAttemptResponse.aLittle => 'A little',
        CircleAttemptResponse.notToday => 'Not today',
      };

  static String _usefulnessLabel(CircleUsefulnessResponse? response) =>
      switch (response) {
        null => 'No answer',
        CircleUsefulnessResponse.veryUseful => 'Very useful',
        CircleUsefulnessResponse.somewhatUseful => 'Somewhat useful',
        CircleUsefulnessResponse.notUseful => 'Not useful',
      };
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Semantics(
        label: '$label: $value',
        child: ExcludeSemantics(
          child: Row(
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Expanded(child: Text(value, style: textTheme.bodySmall)),
            ],
          ),
        ),
      ),
    );
  }
}
