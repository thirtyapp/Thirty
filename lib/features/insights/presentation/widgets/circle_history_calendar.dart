import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/clock_provider.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/date_key.dart';
import '../../../home/application/circle_journal.dart';

const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _monthNames = [
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

/// THIRTY's shared personal-history calendar — founder IA correction
/// ("Today | Plans | Insights | You"): Free/shared, entitlement-
/// independent, presenting the existing local Circle journal
/// (`../../../home/application/circle_journal.dart`) as a calm calendar
/// instead of the retired primary Journal tab.
///
/// Reuses [circleJournalRepositoryProvider] directly — no new history
/// store, no duplicated records, no computed metric beyond "does a
/// record exist for this local date." Ordinary month navigation only;
/// never touches [nowProvider] beyond reading it once for the initial
/// displayed month, and never calls anything that could start, close, or
/// advance a Circle or Plan.
///
/// Live refresh: `recommendation_provider.dart` invalidates
/// [circleJournalRepositoryProvider] after every journal-mutating write
/// (matching `journal_data_controls.dart`'s existing clearAll path), so
/// this widget's `ref.watch` below picks up a just-closed Circle even
/// while kept alive off-screen by `StatefulShellRoute.indexedStack` — no
/// polling, no forced route recreation, and [_displayedMonth] is untouched
/// by that rebuild.
///
/// A recorded date shows a calm ring around its number (the "Circle"
/// visual echo) and opens `/history/<date>` (a single record's read-only
/// detail) when tapped. An empty date is plain, non-interactive text —
/// no streak, no broken-chain mark, no score, no completion percentage,
/// no health-progress claim.
class CircleHistoryCalendar extends ConsumerStatefulWidget {
  const CircleHistoryCalendar({super.key});

  @override
  ConsumerState<CircleHistoryCalendar> createState() =>
      _CircleHistoryCalendarState();
}

class _CircleHistoryCalendarState
    extends ConsumerState<CircleHistoryCalendar> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = ref.read(nowProvider);
    _displayedMonth = DateTime(now.year, now.month);
  }

  void _goToPreviousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      );
    });
  }

  void _goToNextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final journal = ref.watch(circleJournalRepositoryProvider);
    final recordedDates = journal.readAll().map((e) => e.localDate).toSet();
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;

    final daysInMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;
    // Monday-first grid: DateTime.weekday is 1 (Mon) .. 7 (Sun).
    final leadingBlanks = _displayedMonth.weekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous month',
              onPressed: _goToPreviousMonth,
            ),
            Expanded(
              child: Text(
                '${_monthNames[_displayedMonth.month - 1]} '
                '${_displayedMonth.year}',
                textAlign: TextAlign.center,
                style: textTheme.titleSmall,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next month',
              onPressed: _goToNextMonth,
            ),
          ],
        ),
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var week = 0; week < rowCount; week++)
          Row(
            children: [
              for (var weekday = 0; weekday < 7; weekday++)
                Expanded(
                  child: _CalendarCell(
                    dayNumber:
                        week * 7 + weekday - leadingBlanks + 1,
                    daysInMonth: daysInMonth,
                    month: _displayedMonth,
                    recordedDates: recordedDates,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.dayNumber,
    required this.daysInMonth,
    required this.month,
    required this.recordedDates,
  });

  final int dayNumber;
  final int daysInMonth;
  final DateTime month;
  final Set<String> recordedDates;

  @override
  Widget build(BuildContext context) {
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return const SizedBox(height: 44);
    }

    final date = DateTime(month.year, month.month, dayNumber);
    final key = dateKey(date);
    final hasRecord = recordedDates.contains(key);
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final numberLabel = FittedBox(
      child: Text('$dayNumber', style: textTheme.bodyMedium),
    );

    final content = Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: hasRecord
            ? DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primary, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: numberLabel,
                ),
              )
            : Padding(padding: const EdgeInsets.all(4), child: numberLabel),
      ),
    );

    // `ExcludeSemantics` on the visual content in both branches, matching
    // `daily_intention_prompt.dart`'s own established pattern — without
    // it, the day number `Text`'s own implicit semantics would merge
    // into this node's label instead of leaving it exactly the
    // machine-checkable string above.
    return Semantics(
      label: hasRecord
          ? '$key, Circle recorded'
          : '$key, no record',
      button: hasRecord,
      onTap: hasRecord ? () => context.push('/history/$key') : null,
      child: ExcludeSemantics(
        child: SizedBox(
          height: 44,
          child: hasRecord
              ? InkWell(
                  onTap: () => context.push('/history/$key'),
                  child: content,
                )
              : content,
        ),
      ),
    );
  }
}
