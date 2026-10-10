import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_card.dart';
import '../../../../core/widgets/thirty_text_action.dart';
import '../../application/activity_catalog.dart';
import '../../domain/v1_plan_history.dart';
import '../../application/circle_journal.dart';

/// One Circle journal record, written as a personal memory rather than a
/// log — but exactly as truthful (ADR-010, ADR-013 §4): it says when the
/// Circle was offered, started and closed, and what the user answered.
/// Closing is never presented as having done the activity; only the user's
/// own answer to "Did you try it?" speaks to that.
///
/// Shared by the full history list (`../circle_history_page.dart`) and the
/// calendar's record detail (`../circle_record_detail_page.dart`).
class CircleJournalEntryCard extends StatelessWidget {
  const CircleJournalEntryCard({
    super.key,
    required this.entry,
    this.onRemoveAttempt,
    this.onRemoveUsefulness,
  });

  final CircleJournalEntry entry;

  /// V2 Phase C — "Remove this answer": offered beside an answer when given
  /// (the record's own page). The Circle's record always stays.
  final VoidCallback? onRemoveAttempt;
  final VoidCallback? onRemoveUsefulness;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final secondary = textTheme.bodySmall?.copyWith(
      color: colors.textSecondary,
    );

    return ThirtyCard(
      // Full width, so the card reads as one record, not a text-sized chip.
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              humanJournalDate(entry.localDate),
              style: textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(entry.title, style: textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(needLine(entry), style: secondary),
            if (replacementLine(entry) case final swap?) ...[
              const SizedBox(height: 2),
              Text(swap, style: secondary),
            ],
            if (contextLine(entry) case final label?) ...[
              const SizedBox(height: 2),
              Text(label, style: secondary),
            ],
            const SizedBox(height: AppSpacing.m),
            Text(timelineSentence(entry), style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.s),
            _AnswerLine(
              question: 'Did you try it?',
              answer: _attemptLabel(entry.attemptResponse),
              onRemove: entry.attemptResponse == null ? null : onRemoveAttempt,
            ),
            _AnswerLine(
              question: 'Was it useful?',
              answer: _usefulnessLabel(entry.usefulnessResponse),
              onRemove: entry.usefulnessResponse == null
                  ? null
                  : onRemoveUsefulness,
            ),
          ],
        ),
      ),
    );
  }

  /// The need, and — for V2 Circles — the length offered that day.
  static String needLine(CircleJournalEntry entry) {
    final need = intentionLabel(entry.direction);
    final minutes = entry.offeredMinutes;
    return minutes == null ? need : '$need · about $minutes minutes';
  }

  /// "Not this one today" (V2 Phase B), as a plain fact: what it replaced,
  /// and why — or `null`.
  static String? replacementLine(CircleJournalEntry entry) {
    final replaced = entry.replacedFrom;
    if (replaced == null) return null;
    final why = switch (entry.replacementReason) {
      'cantGoOutside' => ' — you couldn’t go outside',
      'tooMuch' => ' — it was too much for that day',
      'notFeeling' => ' — you weren’t feeling it',
      _ => '',
    };
    final title = entry.session?.replacedFromTitle ?? activityLabel(replaced);
    return 'Instead of $title$why';
  }

  /// What happened to the Circle that day, in one plain sentence. It only
  /// ever states the app facts — offered, started, closed — never that the
  /// activity itself was done.
  static String timelineSentence(CircleJournalEntry entry) {
    final startedAt = entry.startedAt;
    final closedAt = entry.closedAt;
    if (startedAt == null) {
      return 'Offered at ${_formatTime(entry.shownAt)}. Not started.';
    }
    if (closedAt == null) {
      return 'Started at ${_formatTime(startedAt)}. Not closed.';
    }
    return 'Started at ${_formatTime(startedAt)}, closed at '
        '${_formatTime(closedAt)}.';
  }

  /// Where the Circle came from, when it wasn't a single activity: a
  /// routine and its version, a Path and its Circle — or, for an old
  /// record, the V1 Plan it came from. Only what was true that day.
  static String? contextLine(CircleJournalEntry entry) {
    final session = entry.session;
    if (session != null && session.pathName != null) {
      final circle = session.pathCircle;
      final circles = session.pathCircles;
      return circle == null || circles == null
          ? session.pathName
          : '${session.pathName} · Circle $circle of $circles';
    }
    if (session != null && session.routineId != null) {
      final version = session.routineVersionNumber;
      return version == null || version == 1
          ? 'Your routine'
          : 'Your routine · version $version';
    }
    return v1PlanLabel(entry.planId, entry.stageId);
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _attemptLabel(CircleAttemptResponse? response) =>
      switch (response) {
        null => 'Not answered',
        CircleAttemptResponse.yes => 'Yes',
        CircleAttemptResponse.aLittle => 'A little',
        CircleAttemptResponse.notToday => 'Not today',
      };

  static String _usefulnessLabel(CircleUsefulnessResponse? response) =>
      switch (response) {
        null => 'Not answered',
        CircleUsefulnessResponse.veryUseful => 'Very useful',
        CircleUsefulnessResponse.somewhatUseful => 'Somewhat useful',
        CircleUsefulnessResponse.notUseful => 'Not useful',
      };
}

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// A journal `localDate` ("2026-09-05") as people say it — "Saturday
/// 5 September 2026" — or without the weekday for tighter places. An
/// unparseable value is shown as stored rather than guessed at.
String humanJournalDate(String localDate, {bool withWeekday = true}) {
  final parts = localDate.split('-');
  if (parts.length != 3) return localDate;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null || month < 1 || month > 12) {
    return localDate;
  }
  final date = DateTime(year, month, day);
  final text = '$day ${_months[month - 1]} $year';
  return withWeekday ? '${_weekdays[date.weekday - 1]} $text' : text;
}

class _AnswerLine extends StatelessWidget {
  const _AnswerLine({
    required this.question,
    required this.answer,
    this.onRemove,
  });

  final String question;
  final String answer;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    // One wrapping line, so a long answer at large text flows onto the
    // next line instead of overflowing.
    final line = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$question  ',
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          TextSpan(text: answer, style: textTheme.bodySmall),
        ],
      ),
    );
    final remove = onRemove;
    if (remove == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: line,
      );
    }
    return Row(
      children: [
        Expanded(child: line),
        Semantics(
          button: true,
          label: 'Remove your answer to $question',
          onTap: remove,
          excludeSemantics: true,
          child: ThirtyTextAction(label: 'Remove', onPressed: remove),
        ),
      ],
    );
  }
}
