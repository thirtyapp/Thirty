import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/insights/domain/insight_engine.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// A random source that always gives the same numbers — so two ids built at
/// one event-clock instant would collide but for the domain's own check.
class _StuckRandom implements Random {
  @override
  int nextInt(int max) => 7 % max;
  @override
  double nextDouble() => 0.5;
  @override
  bool nextBool() => false;
}

/// R8.3.3 (Astra R832-A02) — the kept-Circle identity contract, with
/// collisions forced through [keptIdRandomProvider]. Uses APIs introduced
/// by R8.3.3: not applicable to (does not compile on) R8.3.2.
void main() {
  void evidence(String id, Map<String, Object?> facts) {
    // ignore: avoid_print
    print('R833ID-EVIDENCE ${jsonEncode({'test': id, ...facts})}');
  }

  final morning = DateTime(2026, 10, 30, 9);
  late R8Harness h;

  setUp(() async {
    h = R8Harness(morning);
    await h.boot();
  });

  CirclePart part(ElementId e) => CirclePart(e, elementOf(e).minutes);
  final reading = [part(ElementId.phoneFaceDown), part(ElementId.readPages)];
  final writing = [
    part(ElementId.closeWhatsOpen),
    part(ElementId.getItOut),
    part(ElementId.chooseOne),
    part(ElementId.firstStep),
  ];
  const head = Intention.clearerHead;

  CircleJournalEntry entry(
    int ago, {
    List<CirclePart> parts = const [],
    bool useful = false,
  }) {
    final date = morning.subtract(Duration(days: ago));
    return CircleJournalEntry(
      schemaVersion: circleJournalSchemaVersion,
      circleId: dateKey(date),
      localDate: dateKey(date),
      direction: head,
      activityId: ActivityId.values.first,
      catalogVersion: catalogVersion,
      shownAt: date,
      startedAt: date,
      closedAt: date,
      attemptResponse: useful ? CircleAttemptResponse.yes : null,
      usefulnessResponse: useful
          ? (ago.isEven
                ? CircleUsefulnessResponse.veryUseful
                : CircleUsefulnessResponse.somewhatUseful)
          : null,
      session: CircleSessionRecord(
        title: 'Circle',
        parts: CirclePlan(parts).toWire(),
        skipped: const [],
      ),
    );
  }

  String journalOf(List<CircleJournalEntry> entries) => jsonEncode({
    'schemaVersion': circleJournalSchemaVersion,
    'entries': [for (final e in entries) e.toJson()],
  });

  final i4Journal = [
    for (final ago in [1, 7, 13, 20]) entry(ago, parts: writing, useful: true),
    for (final ago in [3, 9, 16]) entry(ago, parts: reading),
  ];
  final i4Later = [
    ...i4Journal,
    for (final ago in [-21, -28]) entry(ago, parts: writing, useful: true),
  ];

  final stuck = keptIdRandomProvider.overrideWithValue(_StuckRandom());

  InsightsNotifier insights(ProviderContainer c) =>
      c.read(insightsProvider.notifier);
  KeptCirclesNotifier keptN(ProviderContainer c) =>
      c.read(keptCirclesProvider.notifier);

  Future<List<Map>> keptOnDisk() async {
    final raw = (await h.disk.stored())[keptCirclesKey];
    if (raw is! String) return [];
    return [for (final k in (jsonDecode(raw) as Map)['kept'] as List) k as Map];
  }

  Future<Map?> snapshotOnDisk(String id) async {
    final raw = (await h.disk.stored())[insightsKey];
    if (raw is! String) return null;
    for (final s in (jsonDecode(raw) as Map)['snapshots'] as List) {
      if ((s as Map)['id'] == id) return s;
    }
    return null;
  }

  test('ID-1 one clock instant, one random value: every Keep still gets its '
      'own id, and a user\'s Keep never an Insight\'s', () async {
    await h.boot({circleJournalKey: journalOf(i4Journal)});
    final c = h.open(overrides: [stuck]);
    final ids = <String>[];
    for (final day in ['2026-10-29', '2026-10-27', '2026-10-23']) {
      final k = await keptN(c).keepCircle(
        plan: CirclePlan(writing),
        need: head,
        circleId: day,
      );
      ids.add(k!.id);
    }
    final insightId = keptN(c).newKeptId(tag: 'insight');
    evidence('ID-1', {'ids': ids, 'insightId': insightId});
    expect(ids.toSet(), hasLength(3));
    expect(ids.any((id) => id.endsWith('-insight')), isFalse);
    expect(insightId, endsWith('-insight'));
    expect((await keptOnDisk()).map((k) => k['id']).toSet(), hasLength(3));
  });

  test('ID-2 forced collision: I4-A\'s Keep throws before landing; I4-B is '
      'given the very id A recorded; A is never proven by B\'s Circle',
      () async {
    await h.boot({circleJournalKey: journalOf(i4Journal)});
    final c = h.open();
    final first = insights(c).assess().added.single;
    await R8Harness.settle();
    final stored = await h.disk.stored();
    h.clock.value = morning.add(const Duration(days: 30));
    await h.boot({...stored, circleJournalKey: journalOf(i4Later)});
    final c2 = h.open(overrides: [stuck]);
    h.disk.fail(keptCirclesKey, DiskFault.throws, times: 1);
    expect(await insights(c2).apply(first.id), InsightActionResult.notSaved);
    await R8Harness.settle();
    final recorded =
        ((await snapshotOnDisk(first.id))?['attempt'] as Map?)?['keptId'];
    final newer = insights(c2)
        .assess()
        .added
        .where((s) => s.family == InsightFamily.usefulInCommon)
        .single;
    await R8Harness.settle();
    expect(await insights(c2).apply(newer.id), InsightActionResult.done);
    await R8Harness.settle();
    await h.restart();
    final c3 = h.open();
    insights(c3).assess();
    await R8Harness.settle();
    final kept = await keptOnDisk();
    evidence('ID-2', {
      'recordedByA': recorded,
      'kept': [
        for (final k in kept) [k['id'], k['fromCircleId']],
      ],
      'a': await snapshotOnDisk(first.id),
    });
    expect(kept.single['id'], recorded, reason: 'collision not forced');
    expect((await snapshotOnDisk(first.id))?['appliedOn'], isNull);
    expect(
      insights(c3).status(insights(c3).state.byId(first.id)!),
      InsightStatus.stale,
    );
  });

  test('ID-3 a caller id taken by a kept Circle THIRTY can\'t read is '
      'refused', () async {
    await h.boot({
      keptCirclesKey: jsonEncode({
        'schemaVersion': 1,
        'kept': [
          {'id': 'kept-retained', 'name': 'Old'},
        ],
      }),
    });
    final c = h.open();
    final retained = c.read(keptCirclesProvider).retained;
    final k = await keptN(c).keepCircle(
      plan: CirclePlan(writing),
      need: head,
      circleId: '2026-10-29',
      id: 'kept-retained',
    );
    evidence('ID-3', {
      'retained': [for (final r in retained) r.key],
      'kept': k?.id,
      'stored': await keptOnDisk(),
    });
    expect(retained.map((r) => r.key), ['kept-retained']);
    expect(k, isNull);
    expect(await keptOnDisk(), hasLength(1));
  });
}
