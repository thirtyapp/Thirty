import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/storage/confirmed_write.dart';
import 'package:thirty/core/storage/store_save_failures.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/insights/domain/insight_engine.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/kept_circle.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// Audit remediation R8 — kept-Circle ownership and the user's own saves:
/// - Astra R7-A02 (HIGH) / Claude F-3: a version-1 kept record whose `kept`
///   is present but not a list is never read as an empty store, so never
///   written over;
/// - Astra R7-A03 (HIGH) / Claude F-6: a Keep — from Today, a Plan or
///   Insight 4 — is confirmed only once it is on disk; I4 is recorded as
///   applied only for a Circle actually kept;
/// - Astra R7-A07 (MEDIUM): damaged saved words are never replaced by
///   today's catalogue words;
/// - the same weakness in Plans and Insights saves.
///
/// Every failure is tried both ways: the disk throws, and the disk returns
/// `false` without throwing.
void main() {
  final morning = DateTime(2026, 10, 30, 9);
  late R8Harness h;
  const valid = ['getItOut:6', 'chooseOne:1', 'clearCorner:8'];
  final plan = CirclePlan.fromWire(valid)!;

  setUp(() async {
    h = R8Harness(morning);
    await h.boot();
  });

  Future<void> bootWith(Map<String, Object> stored) => h.boot(stored);

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

  String i4Journal() => jsonEncode({
    'schemaVersion': circleJournalSchemaVersion,
    'entries': [
      for (final ago in [1, 7, 13, 20]) entry(ago, writing, true).toJson(),
      for (final ago in [3, 9, 16]) entry(ago, reading, false).toJson(),
    ],
  });

  KeptCirclesNotifier kept(ProviderContainer c) =>
      c.read(keptCirclesProvider.notifier);

  /// A Keep's outcome: the Circle, `null`, or the error it failed with.
  Future<(KeptCircle?, Object?)> keep(
    ProviderContainer c,
    String circleId,
  ) async {
    try {
      final result = await kept(
        c,
      ).keepCircle(plan: plan, need: Intention.clearerHead, circleId: circleId);
      return (result, null);
    } catch (error) {
      return (null, error);
    }
  }

  Map<String, Object?> record(
    String id, {
    Object? wording,
    bool hasWording = false,
  }) => {
    'id': id,
    'name': 'Mine $id',
    'need': Intention.clearerHead.name,
    'parts': valid,
    'createdAt': '2026-10-01T09:00:00.000',
    'fromCircleId': '2026-10-01-$id',
    if (hasWording) 'wording': wording,
  };

  group('Astra R7-A02 — a version-1 record whose kept field is present but '
      'malformed', () {
    for (final (label, malformed) in [
      ('an object', {'note': 'damaged'}),
      ('a string', 'kept'),
      ('a number', 5),
      ('null', null),
      ('a boolean', true),
    ]) {
      test('$label: read as a store THIRTY can\'t read — never as empty; a '
          'Keep refuses; the bytes never change, across restarts', () async {
        final raw = jsonEncode({'schemaVersion': 1, 'kept': malformed});
        await bootWith({keptCirclesKey: raw});
        for (var run = 0; run < 3; run++) {
          final c = h.open();
          final state = c.read(keptCirclesProvider);
          expect(state.unreadable, hasLength(1));
          expect(state.unreadable.single.raw, raw);
          expect(state.isFull, isTrue, reason: 'count unknown: nothing kept');
          final (circle, _) = await keep(c, 'day$run');
          expect(circle, isNull);
          await R8Harness.settle();
          expect((await h.disk.stored())[keptCirclesKey], raw);
          await h.restart();
        }
      });
    }

    test(
      'kept missing altogether (the Phase D record\'s shape) is an empty '
      'store; fields THIRTY doesn\'t know are written back unchanged',
      () async {
        await bootWith({
          keptCirclesKey: jsonEncode({
            'schemaVersion': 1,
            'laterField': {'a': 1},
          }),
        });
        final c = h.open();
        expect(c.read(keptCirclesProvider).unreadable, isEmpty);
        final (circle, error) = await keep(c, 'day1');
        expect(error, isNull);
        expect(circle, isNotNull);
        final stored =
            jsonDecode((await h.disk.stored())[keptCirclesKey]! as String)
                as Map<String, Object?>;
        expect(stored['laterField'], {'a': 1});
        expect(stored['kept'], hasLength(1));
      },
    );

    test('a valid record beside one THIRTY can\'t read: both stay, each in '
        'its place, after a Keep', () async {
      final raw = jsonEncode({
        'schemaVersion': 1,
        'kept': [record('a'), 'not a record'],
      });
      await bootWith({keptCirclesKey: raw});
      final c = h.open();
      expect(c.read(keptCirclesProvider).kept, hasLength(1));
      expect(c.read(keptCirclesProvider).retained, hasLength(1));
      await keep(c, 'day1');
      final stored =
          jsonDecode((await h.disk.stored())[keptCirclesKey]! as String)
              as Map<String, Object?>;
      final list = stored['kept']! as List<Object?>;
      expect(list, hasLength(3));
      expect(list[1], 'not a record');
    });
  });

  for (final fault in DiskFault.values) {
    group(
      'the kept store\'s write ${fault.name} (Astra R7-A03, Claude F-6)',
      () {
        test('a Keep isn\'t confirmed: it fails, nothing shows as kept, and '
            'after a restart nothing is kept', () async {
          final c = h.open();
          h.disk.fail(keptCirclesKey, fault);
          final (circle, error) = await keep(c, 'day1');
          expect(circle, isNull);
          expect(error, isA<StorageWriteFailed>());
          expect(c.read(keptCirclesProvider).kept, isEmpty);
          expect(c.read(storeSaveFailuresProvider).count, greaterThan(0));
          await h.restart();
          expect(h.open().read(keptCirclesProvider).kept, isEmpty);
        });

        test('the next Keep, once the disk takes it, keeps one Circle — no '
            'duplicate from the failed one', () async {
          final c = h.open();
          h.disk.fail(keptCirclesKey, fault, times: 1);
          await keep(c, 'day1');
          final (circle, error) = await keep(c, 'day1');
          expect(error, isNull);
          expect(circle, isNotNull);
          expect(c.read(keptCirclesProvider).kept, hasLength(1));
          await h.restart();
          expect(h.open().read(keptCirclesProvider).kept, hasLength(1));
        });

        test('a rename isn\'t confirmed: the old name stays, in memory and on '
            'disk, and the failure is shown', () async {
          final c = h.open();
          final (circle, _) = await keep(c, 'day1');
          h.disk.fail(keptCirclesKey, fault);
          try {
            // Awaited whatever it returns (it completes once saved).
            await (kept(c) as dynamic).renameKept(circle!.id, 'New name');
          } catch (_) {}
          await R8Harness.settle();
          expect(c.read(keptCirclesProvider).kept.single.name, circle!.name);
          expect(c.read(storeSaveFailuresProvider).count, greaterThan(0));
          await h.restart();
          expect(
            h.open().read(keptCirclesProvider).kept.single.name,
            circle.name,
          );
        });
      },
    );
  }

  test('two Keeps at once, one place left: one is kept, the other refused — '
      'never nine', () async {
    final c = h.open();
    for (var k = 0; k < 7; k++) {
      await keep(c, 'old$k');
    }
    final both = await Future.wait([keep(c, 'a'), keep(c, 'b')]);
    expect(both.where((r) => r.$1 != null), hasLength(1));
    expect(c.read(keptCirclesProvider).count, maxKeptCircles);
    await h.restart();
    expect(h.open().read(keptCirclesProvider).count, maxKeptCircles);
  });

  test('the same Circle kept twice at once: kept once', () async {
    final c = h.open();
    final both = await Future.wait([keep(c, 'day1'), keep(c, 'day1')]);
    expect(both.where((r) => r.$1 != null), hasLength(1));
    expect(c.read(keptCirclesProvider).kept, hasLength(1));
  });

  group('Astra R7-A07 — damaged saved words', () {
    for (final (label, wording) in [
      (
        'an item that isn\'t words',
        [
          {'name': 5, 'instruction': 'x'},
          {'name': 'b', 'instruction': 'y'},
          {'name': 'c', 'instruction': 'z'},
        ],
      ),
      (
        'one wording too few',
        [
          {'name': 'a', 'instruction': 'x'},
        ],
      ),
      ('not a list', 'words'),
      ('null', null),
    ]) {
      test('$label: the Circle is kept as stored, never run with today\'s '
          'words or voice — and written back byte for byte', () async {
        final damaged = record('d', wording: wording, hasWording: true);
        await bootWith({
          keptCirclesKey: jsonEncode({
            'schemaVersion': 1,
            'kept': [damaged],
          }),
        });
        final c = h.open();
        final state = c.read(keptCirclesProvider);
        expect(state.kept, isEmpty, reason: 'run with substituted words');
        expect(state.retained.single.stored, damaged);
        expect(state.count, 1);
        await keep(c, 'day1');
        final stored =
            jsonDecode((await h.disk.stored())[keptCirclesKey]! as String)
                as Map<String, Object?>;
        expect((stored['kept']! as List).first, damaged);
      });
    }

    test('a Circle kept before words were saved (no wording field) still '
        'runs with its parts\' words', () async {
      await bootWith({
        keptCirclesKey: jsonEncode({
          'schemaVersion': 1,
          'kept': [record('old')],
        }),
      });
      final c = h.open();
      expect(c.read(keptCirclesProvider).kept, hasLength(1));
      expect(c.read(keptCirclesProvider).kept.single.wording, isNull);
    });
  });

  group('Insight 4\'s Keep (Astra R7-A03)', () {
    Future<InsightSnapshot> showI4() async {
      await bootWith({circleJournalKey: i4Journal()});
      final c = h.open();
      final shown = c.read(insightsProvider.notifier).assess().added.single;
      expect(shown.application, isA<KeepCircleFromHistory>());
      await R8Harness.settle();
      await h.restart();
      return shown;
    }

    for (final status in [
      EntitlementStatus.active,
      EntitlementStatus.inactive,
    ]) {
      for (final fault in DiskFault.values) {
        test('${status.name}: the Circle\'s save ${fault.name} — I4 is not '
            'applied, nothing is kept; once the disk takes it, one Keep and '
            'I4 applied, across a restart', () async {
          final shown = await showI4();
          final c = h.open(status: status);
          final insights = c.read(insightsProvider.notifier);
          h.disk.fail(keptCirclesKey, fault, times: 1);
          final first = await insights.apply(shown.id);
          await R8Harness.settle();
          expect(first, isNot(InsightActionResult.done));
          expect(c.read(insightsProvider).byId(shown.id)!.appliedOn, isNull);
          expect(c.read(keptCirclesProvider).kept, isEmpty);

          final second = await insights.apply(shown.id);
          await R8Harness.settle();
          // R8.3.2 (founder scope decision B2): a Kept Circles write that
          // threw may be on disk all the same, so I4 never keeps again after
          // it, and is never claimed applied. Returning `false` is a
          // refusal, and the retry keeps once.
          if (fault == DiskFault.throws) {
            expect(second, isNot(InsightActionResult.done));
            await h.restart();
            final again = h.open(status: status);
            expect(again.read(keptCirclesProvider).kept, isEmpty);
            expect(
              again.read(insightsProvider).byId(shown.id)!.appliedOn,
              isNull,
            );
            return;
          }
          expect(second, InsightActionResult.done);
          expect(c.read(keptCirclesProvider).kept, hasLength(1));
          await h.restart();
          final again = h.open(status: status);
          expect(again.read(keptCirclesProvider).kept, hasLength(1));
          expect(
            statusOf(
              again.read(insightsProvider).byId(shown.id)!,
              again.read(insightsProvider.notifier).inputs(),
            ),
            InsightStatus.applied,
          );
        });
      }
    }

    test(
      'the Circle kept, I4\'s own record refused: after a restart the '
      'Keep is offered again, keeps nothing twice, and I4 is applied',
      () async {
        final shown = await showI4();
        final c = h.open(status: EntitlementStatus.inactive);
        // R8.3.2 (founder scope decisions B1/B2): an I3 or I4 first records its
        // attempt, so the fault is put on the write that carries the applied
        // mark — the same scenario. For I1 and I2 that is still the first
        // Insights write.
        h.disk.failWhere(insightsKey, (v) => v.contains('"appliedOn"'));
        await c.read(insightsProvider.notifier).apply(shown.id);
        await R8Harness.settle();
        await h.restart();
        final again = h.open(status: EntitlementStatus.inactive);
        final notifier = again.read(insightsProvider.notifier);
        expect(again.read(keptCirclesProvider).kept, hasLength(1));
        await notifier.apply(shown.id);
        await R8Harness.settle();
        expect(again.read(keptCirclesProvider).kept, hasLength(1));
        expect(
          statusOf(
            again.read(insightsProvider).byId(shown.id)!,
            notifier.inputs(),
          ),
          InsightStatus.applied,
        );
      },
    );

    test('lapsed: every other Insight action stays Premium', () async {
      final shown = await showI4();
      final c = h.open(status: EntitlementStatus.inactive);
      expect(
        c.read(insightsProvider.notifier).notNow(shown.id),
        InsightActionResult.needsPremium,
      );
    });
  });

  group('Plans and Insights saves (Claude F-6)', () {
    for (final fault in DiskFault.values) {
      test('a Plan action the disk refuses (${fault.name}) is shown as not '
          'saved', () async {
        final c = h.open();
        h.disk.fail(circlePlansKey, fault);
        c.read(circlePlansProvider.notifier).start('getting_going');
        await R8Harness.settle();
        expect(c.read(storeSaveFailuresProvider).count, greaterThan(0));
        expect(c.read(storeSaveFailuresProvider).last, UserStore.circlePlans);
      });

      test('Plans THIRTY can\'t read, its copy refused (${fault.name}): the '
          'stored Plans are never written over', () async {
        await bootWith({circlePlansKey: '{damaged'});
        h.disk.fail(circlePlansUnreadableKey, fault);
        final c = h.open();
        c.read(circlePlansProvider);
        await R8Harness.settle();
        c.read(circlePlansProvider.notifier).start('getting_going');
        await R8Harness.settle();
        expect((await h.disk.stored())[circlePlansKey], '{damaged');
      });

      test('Insights THIRTY can\'t read, its copy refused (${fault.name}): '
          'the stored Insights are never written over', () async {
        await bootWith({
          insightsKey: '{damaged',
          circleJournalKey: i4Journal(),
        });
        h.disk.fail(insightsUnreadableKey, fault);
        final c = h.open();
        c.read(insightsProvider);
        await R8Harness.settle();
        c.read(insightsProvider.notifier).assess();
        await R8Harness.settle();
        expect((await h.disk.stored())[insightsKey], '{damaged');
      });
    }
  });
}
