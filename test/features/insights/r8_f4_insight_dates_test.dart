import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';

import '../../support/r8_harness.dart';

/// Audit remediation R8 — Claude F-4 (LOW): an Insight snapshot whose stored
/// dates aren't real `YYYY-MM-DD` dates never reaches the date arithmetic —
/// reading and opening Insights never throw — and it is kept on disk
/// exactly as stored, never dropped by the next save. Nothing about it
/// grants Premium.
void main() {
  final morning = DateTime(2026, 10, 30, 9);
  late R8Harness h;

  CirclePart part(ElementId e) => CirclePart(e, elementOf(e).minutes);
  final writing = [
    part(ElementId.closeWhatsOpen),
    part(ElementId.getItOut),
    part(ElementId.chooseOne),
    part(ElementId.firstStep),
  ];
  final reading = [part(ElementId.phoneFaceDown), part(ElementId.readPages)];

  CircleJournalEntry entry(int ago, List<CirclePart> parts, bool useful) {
    final date = morning.subtract(Duration(days: ago));
    return CircleJournalEntry(
      schemaVersion: circleJournalSchemaVersion,
      circleId: dateKey(date),
      localDate: dateKey(date),
      direction: Intention.clearerHead,
      activityId: ActivityId.values.first,
      catalogVersion: catalogVersion,
      shownAt: date,
      startedAt: date,
      closedAt: date,
      attemptResponse: useful ? CircleAttemptResponse.yes : null,
      usefulnessResponse: useful ? CircleUsefulnessResponse.veryUseful : null,
      session: CircleSessionRecord(
        title: 'Circle',
        parts: CirclePlan(parts).toWire(),
      ),
    );
  }

  final journal = jsonEncode({
    'schemaVersion': circleJournalSchemaVersion,
    'entries': [
      for (final ago in [1, 7, 13, 20]) entry(ago, writing, true).toJson(),
      for (final ago in [3, 9, 16]) entry(ago, reading, false).toJson(),
    ],
  });

  /// A real stored snapshot, one of its fields damaged.
  Future<(String raw, Map<String, Object?> damaged)> damagedSnapshot(
    String field,
    Object value, {
    bool inFacts = false,
  }) async {
    h = R8Harness(morning);
    await h.boot({circleJournalKey: journal});
    final c = h.open(status: EntitlementStatus.active);
    c.read(insightsProvider.notifier).assess();
    await R8Harness.settle();
    final stored =
        jsonDecode((await h.disk.stored())[insightsKey]! as String)
            as Map<String, Object?>;
    final snapshot = Map<String, Object?>.of(
      (stored['snapshots']! as List).single as Map<String, Object?>,
    );
    if (inFacts) {
      snapshot['facts'] = {
        ...(snapshot['facts']! as Map<String, Object?>),
        field: value,
      };
    } else {
      snapshot[field] = value;
    }
    final raw = jsonEncode({
      'schemaVersion': insightsSchemaVersion,
      'snapshots': [snapshot],
    });
    return (raw, snapshot);
  }

  for (final (field, value, inFacts) in [
    ('generatedOn', 'garbage', false),
    ('generatedOn', '2026-02-30', false),
    ('appliedOn', 'not a date', false),
    ('notNowOn', '30/10/2026', false),
    ('declinedOn', '2026-1-5', false),
    ('endedOn', 'soon', true),
  ]) {
    for (final status in [
      EntitlementStatus.active,
      EntitlementStatus.inactive,
    ]) {
      test('${inFacts ? 'facts.' : ''}$field "$value", ${status.name}: '
          'Insights opens and reads without throwing; the snapshot is kept '
          'on disk as stored; nothing is applied', () async {
        final (raw, damaged) = await damagedSnapshot(
          field,
          value,
          inFacts: inFacts,
        );
        await h.boot({circleJournalKey: journal, insightsKey: raw});
        final c = h.open(status: status);
        final insights = c.read(insightsProvider.notifier);
        expect(() => insights.read(), returnsNormally);
        expect(() => insights.assess(), returnsNormally);
        await R8Harness.settle();
        for (final s in c.read(insightsProvider).snapshots) {
          expect(() => insights.status(s), returnsNormally);
        }
        final after =
            jsonDecode((await h.disk.stored())[insightsKey]! as String)
                as Map<String, Object?>;
        expect([
          for (final s in after['snapshots']! as List) jsonEncode(s),
        ], contains(jsonEncode(damaged)));
        // Never read as a snapshot to show or act on. (With Premium, the
        // same observation may be made afresh, under the same id, as a new
        // valid snapshot — never the damaged one.)
        for (final s in c.read(insightsProvider).snapshots) {
          expect(
            jsonEncode(s.toJson()),
            isNot(jsonEncode(damaged)),
            reason: 'a snapshot with a damaged date is never acted on',
          );
        }
      });
    }
  }
}
