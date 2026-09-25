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
///
/// **Accessibility (responsive presentation only — same data and
/// behaviour):** every interactive date is at least a 48×48pt target and
/// every number follows the user's text size. The 7-column month grid is
/// used whenever the calendar can be at least [_minGridWidth] wide — its
/// side inset narrows from the page's 24pt toward 12pt to get there (a
/// 360pt screen gets exactly 12pt). Narrower than that (e.g. 320pt), the
/// month's recorded dates are listed instead, one full-width 48pt row
/// each. Spoken labels are localized, human-readable dates.
///
/// Give it the page's full width: it applies its own horizontal inset.
class CircleHistoryCalendar extends ConsumerStatefulWidget {
  const CircleHistoryCalendar({super.key});

  @override
  ConsumerState<CircleHistoryCalendar> createState() =>
      _CircleHistoryCalendarState();
}

/// Seven 48pt columns.
const _minGridWidth = 7 * 48.0;

/// The narrowest side inset the grid may use to reach [_minGridWidth].
const _minGridInset = 12.0;

/// Minimum interactive target, both presentations.
const _minTarget = 48.0;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // The page's inset when the grid fits inside it, otherwise just
        // enough (never under 12pt) to reach seven 48pt columns.
        final gridInset = width - AppSpacing.page * 2 >= _minGridWidth
            ? AppSpacing.page
            : ((width - _minGridWidth) / 2).clamp(0.0, AppSpacing.page);
        final useGrid = gridInset >= _minGridInset;
        final inset = useGrid ? gridInset : AppSpacing.page;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MonthHeader(
                month: _displayedMonth,
                onPrevious: _goToPreviousMonth,
                onNext: _goToNextMonth,
              ),
              if (useGrid)
                _MonthGrid(
                  month: _displayedMonth,
                  recordedDates: recordedDates,
                )
              else
                _RecordedDateList(
                  month: _displayedMonth,
                  recordedDates: recordedDates,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous month',
          onPressed: onPrevious,
        ),
        Expanded(
          child: Text(
            '${_monthNames[month.month - 1]} ${month.year}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next month',
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.recordedDates});

  final DateTime month;
  final Set<String> recordedDates;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday-first grid: DateTime.weekday is 1 (Mon) .. 7 (Sun).
    final leadingBlanks = month.weekday - 1;
    final rowCount = ((leadingBlanks + daysInMonth) / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          // Rows grow with the text size; each cell is at least 48pt.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var weekday = 0; weekday < 7; weekday++)
                  Expanded(
                    child: _CalendarCell(
                      dayNumber: week * 7 + weekday - leadingBlanks + 1,
                      daysInMonth: daysInMonth,
                      month: month,
                      recordedDates: recordedDates,
                    ),
                  ),
              ],
            ),
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
      return const SizedBox(height: _minTarget);
    }

    final date = DateTime(month.year, month.month, dayNumber);
    final key = dateKey(date);
    final hasRecord = recordedDates.contains(key);
    final colors = Theme.of(context).extension<AppColors>()!;
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(height: 1);
    final spokenDate = MaterialLocalizations.of(context).formatFullDate(date);

    // The number at the user's own text size (never shrunk to fit), inside
    // a square ring that grows with it — at least 32pt.
    final painter = TextPainter(
      text: TextSpan(text: '$dayNumber', style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final side = [
      32.0,
      painter.width + AppSpacing.s,
      painter.height + AppSpacing.s,
    ].reduce((a, b) => a > b ? a : b);
    painter.dispose();

    final ring = SizedBox.square(
      dimension: side,
      child: DecoratedBox(
        decoration: hasRecord
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.primary, width: 2),
              )
            : const BoxDecoration(),
        child: Center(
          child: Text(
            '$dayNumber',
            style: style,
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ),
    );

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Center(child: ring),
      ),
    );

    // `ExcludeSemantics` on the visual content in both branches, matching
    // `daily_intention_prompt.dart`'s own established pattern — the node's
    // label is exactly the spoken date below, never merged with the digit.
    return Semantics(
      label: hasRecord
          ? '$spokenDate, Circle recorded'
          : '$spokenDate, no Circle recorded',
      button: hasRecord,
      onTap: hasRecord ? () => context.push('/history/$key') : null,
      child: ExcludeSemantics(
        child: hasRecord
            ? InkWell(
                onTap: () => context.push('/history/$key'),
                child: content,
              )
            : content,
      ),
    );
  }
}

/// The narrow-screen presentation: the displayed month's recorded dates,
/// one full-width row each (at least 48pt tall), each opening the same
/// read-only detail as a recorded grid day. Unrecorded dates have nothing
/// to open, so they are not listed.
class _RecordedDateList extends StatelessWidget {
  const _RecordedDateList({required this.month, required this.recordedDates});

  final DateTime month;
  final Set<String> recordedDates;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final dates = [
      for (var day = 1; day <= daysInMonth; day++)
        DateTime(month.year, month.month, day),
    ].where((date) => recordedDates.contains(dateKey(date))).toList();

    if (dates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        child: Text(
          'No Circles recorded this month.',
          style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final date in dates)
          _RecordedDateRow(
            date: date,
            label: MaterialLocalizations.of(context).formatFullDate(date),
          ),
      ],
    );
  }
}

class _RecordedDateRow extends StatelessWidget {
  const _RecordedDateRow({required this.date, required this.label});

  final DateTime date;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final key = dateKey(date);
    void open() => context.push('/history/$key');

    return Semantics(
      label: '$label, Circle recorded',
      button: true,
      onTap: open,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: open,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _minTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
              child: Row(
                children: [
                  // The recorded-date ring, as in the grid.
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.primary, width: 2),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
