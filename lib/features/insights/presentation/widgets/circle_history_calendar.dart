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
/// record exist for this local date, and was its Circle closed."
/// Ordinary month navigation only;
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
/// Three states per date (founder decision, 2026-10-02):
/// - **Closed** — the date's Circle was closed in the app
///   ([CircleJournalEntry.closedAt]): a calm ring around its number (the
///   "Circle" visual echo). Closing is an app interaction only (ADR-010):
///   never proof the activity was done, or for how long.
/// - **Recorded, not closed** — a Circle was shown (or started) but never
///   closed: a small neutral dot under the number, never the ring.
/// - **No record** — plain, non-interactive text.
///
/// Both recorded states open `/history/<date>` (a single record's
/// read-only detail) when tapped — the calendar is the in-app way back to
/// every record, so a record is never hidden for being unclosed. No
/// streak, no broken-chain mark, no score, no completion percentage, no
/// health-progress claim.
///
/// **Accessibility (responsive presentation only — same data and
/// behaviour):** every interactive date is at least a 48×48pt target and
/// every number follows the user's text size. The 7-column month grid is
/// used whenever the calendar can be at least [_minGridWidth] wide — its
/// side inset narrows from the page's 24pt toward 12pt to get there (a
/// 360pt screen gets exactly 12pt). Narrower than that (e.g. 320pt), the
/// month's recorded dates are listed instead, one full-width 48pt row
/// each, with the same ring or dot. Spoken labels are localized,
/// human-readable dates followed by the state: "Circle closed", "Circle
/// recorded, not closed" or "no Circle recorded".
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

/// What the journal holds for one local date.
enum _DayRecord { closed, recordedNotClosed }

/// Each recorded local date's state: closed if any of its entries was
/// closed (there is one entry per date today), otherwise recorded.
Map<String, _DayRecord> _dayRecords(List<CircleJournalEntry> entries) {
  final records = <String, _DayRecord>{};
  for (final entry in entries) {
    if (entry.closedAt != null) {
      records[entry.localDate] = _DayRecord.closed;
    } else {
      records.putIfAbsent(entry.localDate, () => _DayRecord.recordedNotClosed);
    }
  }
  return records;
}

String _spokenState(_DayRecord? record) => switch (record) {
  _DayRecord.closed => 'Circle closed',
  _DayRecord.recordedNotClosed => 'Circle recorded, not closed',
  null => 'no Circle recorded',
};

/// The recorded-but-not-closed marker: a small neutral dot — deliberately
/// not the ring, and never the primary colour.
class _UnclosedDot extends StatelessWidget {
  const _UnclosedDot();

  static const size = 5.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.textSecondary,
      ),
    );
  }
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
    final recordedDates = _dayRecords(journal.readAll());

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
  final Map<String, _DayRecord> recordedDates;

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
  final Map<String, _DayRecord> recordedDates;

  @override
  Widget build(BuildContext context) {
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return const SizedBox(height: _minTarget);
    }

    final date = DateTime(month.year, month.month, dayNumber);
    final key = dateKey(date);
    final record = recordedDates[key];
    final hasRecord = record != null;
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

    // Closed: the ring. Recorded, not closed: a small dot under the
    // number, inside the same square — so no state moves the layout.
    final ring = SizedBox.square(
      dimension: side,
      child: DecoratedBox(
        decoration: record == _DayRecord.closed
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.primary, width: 2),
              )
            : const BoxDecoration(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text('$dayNumber', style: style, maxLines: 1, softWrap: false),
            if (record == _DayRecord.recordedNotClosed)
              const Positioned(bottom: 0, child: _UnclosedDot()),
          ],
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
      label: '$spokenDate, ${_spokenState(record)}',
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

/// The narrow-screen presentation: the displayed month's recorded dates —
/// closed or not — one full-width row each (at least 48pt tall), each
/// opening the same read-only detail as a recorded grid day. Unrecorded
/// dates have nothing to open, so they are not listed.
class _RecordedDateList extends StatelessWidget {
  const _RecordedDateList({required this.month, required this.recordedDates});

  final DateTime month;
  final Map<String, _DayRecord> recordedDates;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final dates = [
      for (var day = 1; day <= daysInMonth; day++)
        DateTime(month.year, month.month, day),
    ].where((date) => recordedDates.containsKey(dateKey(date))).toList();

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
            record: recordedDates[dateKey(date)]!,
            label: MaterialLocalizations.of(context).formatFullDate(date),
          ),
      ],
    );
  }
}

class _RecordedDateRow extends StatelessWidget {
  const _RecordedDateRow({
    required this.date,
    required this.record,
    required this.label,
  });

  final DateTime date;
  final _DayRecord record;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final key = dateKey(date);
    void open() => context.push('/history/$key');

    return Semantics(
      label: '$label, ${_spokenState(record)}',
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
                  // The same marker as in the grid: the ring for a closed
                  // Circle, the small dot for one recorded but not closed.
                  SizedBox.square(
                    dimension: 16,
                    child: record == _DayRecord.closed
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.primary,
                                width: 2,
                              ),
                            ),
                          )
                        : const Center(child: _UnclosedDot()),
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
