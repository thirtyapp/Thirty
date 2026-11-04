import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';

class _Settled extends EntitlementNotifier {
  _Settled(this._status);
  final EntitlementStatus _status;
  @override
  EntitlementStatus build() => _status;
}

/// Audit remediation R6b — Insight dates (Audit #2 A2-08, A2-09).
///
/// A2-08: I1's sentence names a date range and a denominator together, so
/// the range must cover every record the denominator counts.
/// A2-09: a journal record whose local date isn't a real `YYYY-MM-DD`
/// calendar date is isolated at the read boundary — never normalised into
/// evidence, never able to break Insights or the rest of the journal.
void main() {
  final morning = DateTime(2026, 10, 30, 9);
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer open() {
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(morning),
        eventClockProvider.overrideWithValue(() => morning),
        entitlementStatusProvider.overrideWith(
          () => _Settled(EntitlementStatus.active),
        ),
        safetyPendingAllowedProvider.overrideWithValue(false),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// A journal record on window day [day] (today is day 1), as stored.
  Map<String, Object?> stored(int day, Intention need, {String? localDate}) {
    final date = morning.subtract(Duration(days: day - 1));
    final key = localDate ?? dateKey(date);
    return CircleJournalEntry(
      schemaVersion: circleJournalSchemaVersion,
      circleId: key,
      localDate: key,
      direction: need,
      activityId: ActivityId.values.first,
      catalogVersion: catalogVersion,
      shownAt: date,
      startedAt: date,
      closedAt: date,
    ).toJson();
  }

  Future<void> seed(List<Map<String, Object?>> entries) => prefs.setString(
    circleJournalKey,
    jsonEncode({
      'schemaVersion': circleJournalSchemaVersion,
      'entries': entries,
    }),
  );

  String day(int n) => dateKey(morning.subtract(Duration(days: n - 1)));

  group('A2-08 — I1\'s dates cover its denominator', () {
    test('the audit\'s fixture: 5 of 10, and the range spans all 10 — not '
        'only the chosen need\'s 5', () async {
      await seed([
        for (final d in [5, 8, 12, 16, 19]) stored(d, Intention.moreEnergy),
        for (final d in [1, 22, 26]) stored(d, Intention.clearerHead),
        for (final d in [2, 28]) stored(d, Intention.gentlerPace),
      ]);
      final c = open();
      final shown = c.read(insightsProvider.notifier).assess().added.single;
      expect(shown.family, InsightFamily.planForNeed);
      expect(shown.facts['count'], 5);
      expect(shown.facts['of'], 10);
      expect(shown.facts['from'], day(28));
      expect(shown.facts['to'], day(1));
      // The evidence stays the chosen need's own Circles, inspectable.
      expect(shown.evidence, [
        for (final d in [19, 16, 12, 8, 5]) day(d),
      ]);
    });

    test('when the chosen need spans the window, nothing changes', () async {
      await seed([
        for (final d in [1, 5, 9, 13, 14]) stored(d, Intention.clearerHead),
      ]);
      final c = open();
      final shown = c.read(insightsProvider.notifier).assess().added.single;
      expect(shown.facts['from'], day(14));
      expect(shown.facts['to'], day(1));
      expect(shown.facts['of'], 5);
    });
  });

  group('A2-09 — a local date that isn\'t a real calendar date', () {
    for (final bad in [
      'bad',
      '2026-02-30',
      '2026-13-01',
      '2026-1-05',
      '2026-10-5',
      ' 2026-10-05',
      '2026-10-05T00:00',
    ]) {
      test('"$bad": that record alone is set aside; the rest of the journal '
          'and Insights read on', () async {
        await seed([
          for (final d in [1, 5, 9, 13, 14]) stored(d, Intention.clearerHead),
          stored(3, Intention.moreEnergy, localDate: bad),
        ]);
        final c = open();
        final entries = c.read(circleJournalRepositoryProvider).readAll();
        expect(entries, hasLength(5));
        expect(entries.map((e) => e.localDate), isNot(contains(bad)));
        final shown = c.read(insightsProvider.notifier).assess().added.single;
        expect(shown.facts['of'], 5);
      });
    }

    test('a real date is never rewritten: 2024-02-29 (a leap day) reads '
        'as stored', () async {
      await seed([stored(1, Intention.clearerHead, localDate: '2024-02-29')]);
      final c = open();
      final entries = c.read(circleJournalRepositoryProvider).readAll();
      expect(entries.single.localDate, '2024-02-29');
    });
  });
}
