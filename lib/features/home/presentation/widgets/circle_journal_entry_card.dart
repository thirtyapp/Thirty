import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_card.dart';
import '../../../plans/domain/plan_catalog.dart';
import '../../../plans/domain/plan_ids.dart';
import '../../application/activity_catalog.dart';
import '../../application/circle_journal.dart';

/// One Circle journal record, rendered as a plain, factual card — the
/// exact shown/started/closed/reported-attempt/reported-usefulness
/// distinction (ADR-010, ADR-013 §4) is the entire point: nothing here
/// blurs into a claim of verified completion or a performance score.
///
/// Extracted from `../circle_history_page.dart` (founder IA correction —
/// Journal/history amendment) so the founder-approved date-Circle
/// calendar's record-detail route
/// (`../circle_record_detail_page.dart`) can render one record with the
/// exact same truthful semantics as the existing full-list page, without
/// duplicating the rendering logic.
class CircleJournalEntryCard extends StatelessWidget {
  const CircleJournalEntryCard({super.key, required this.entry});

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
