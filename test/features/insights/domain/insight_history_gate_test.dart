import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/insights/domain/insight_engine.dart';

/// [insightHistoryGateMet] tells the Insights page whether to name the
/// pattern thresholds (not enough history yet) or say "nothing new right
/// now" (enough history, no Insight) — the same design gate and 28-day
/// window as a pattern claim.

final _now = DateTime(2026, 9, 15, 10);

CircleJournalEntry _entry(String date) => CircleJournalEntry(
  schemaVersion: circleJournalSchemaVersion,
  circleId: date,
  localDate: date,
  direction: Intention.moreEnergy,
  activityId: ActivityId.thirtyMinuteWalk,
  catalogVersion: catalogVersion,
  shownAt: DateTime.parse('${date}T09:00:00'),
);

List<CircleJournalEntry> _journal(List<String> dates) => [
  for (final date in dates) _entry(date),
];

void main() {
  test('no history: not met', () {
    expect(insightHistoryGateMet(const [], _now), isFalse);
  });

  test('five records across three days spanning 14 days: met', () {
    expect(
      insightHistoryGateMet(
        _journal([
          '2026-08-30',
          '2026-08-30',
          '2026-09-06',
          '2026-09-13',
          '2026-09-13',
        ]),
        _now,
      ),
      isTrue,
    );
  });

  test('fewer than five records: not met', () {
    expect(
      insightHistoryGateMet(
        _journal(['2026-08-25', '2026-09-01', '2026-09-08', '2026-09-14']),
        _now,
      ),
      isFalse,
    );
  });

  test('five records on only two days: not met', () {
    expect(
      insightHistoryGateMet(
        _journal([
          '2026-08-25',
          '2026-08-25',
          '2026-08-25',
          '2026-09-12',
          '2026-09-12',
        ]),
        _now,
      ),
      isFalse,
    );
  });

  test('spanning under 14 days: not met', () {
    expect(
      insightHistoryGateMet(
        _journal([
          '2026-09-02',
          '2026-09-05',
          '2026-09-08',
          '2026-09-11',
          '2026-09-14',
        ]),
        _now,
      ),
      isFalse,
    );
  });

  test('records older than the 28-day window do not count', () {
    expect(
      insightHistoryGateMet(
        _journal([
          '2026-07-01',
          '2026-07-05',
          '2026-07-10',
          '2026-07-15',
          '2026-07-20',
        ]),
        _now,
      ),
      isFalse,
    );
  });
}
