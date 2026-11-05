import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/insights/domain/insight.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';

import '../../support/r8_harness.dart';

/// R8.1 — Astra N06 (MEDIUM): damaged saved words of Today's kept Circle
/// never fall back to today's catalogue words and voice as if they were the
/// Circle's own. Astra N07 (MEDIUM) / Claude AUD-3, AUD-4 (LOW): a damaged
/// or unknown part inside a readable Plans or Insights record is never
/// dropped by the next save.
void main() {
  final morning = DateTime(2026, 10, 12, 9);
  late R8Harness h;

  setUp(() async {
    h = R8Harness(morning);
    await h.boot();
  });

  // ---------------------------------------------------------------- N06
  group('N06 — Today\'s kept Circle with damaged saved words', () {
    const saved = 'The words as they were when this Circle was kept.';

    /// A kept Circle whose saved words differ from today's catalogue,
    /// chosen as today's Circle — and [started], if asked.
    Future<(String, List<PartWording>)> keptToday({
      required bool started,
    }) async {
      final c = h.open(status: EntitlementStatus.inactive);
      final kept = (await c
          .read(keptCirclesProvider.notifier)
          .keepCircle(
            plan: CirclePlan.fromWire(const [
              'getItOut:6',
              'chooseOne:1',
              'clearCorner:8',
            ])!,
            need: Intention.clearerHead,
            circleId: '2026-10-01',
          ))!;
      final store =
          jsonDecode((await h.disk.stored())[keptCirclesKey]! as String)
              as Map<String, Object?>;
      final record = (store['kept']! as List).single as Map<String, Object?>;
      (record['wording']! as List)[0] = {
        ...((record['wording']! as List)[0] as Map),
        'instruction': saved,
      };
      await h.boot({
        ...await h.disk.stored(),
        keptCirclesKey: jsonEncode(store),
      });
      final again = h.open(status: EntitlementStatus.inactive);
      expect(
        again
            .read(recommendationProvider.notifier)
            .useOwnedToday(keptCircleId: kept.id),
        UseTodayResult.used,
      );
      await R8Harness.settle();
      final composed = again
          .read(recommendationProvider)
          .recommendation!
          .composed!;
      expect(composed.wording![0].instruction, saved);
      expect(composed.voiced, isFalse, reason: 'its words differ');
      if (started) {
        again.read(recommendationProvider.notifier).start();
        await R8Harness.settle();
      }
      return (kept.id, composed.wording!);
    }

    /// The stored composed Circle with its saved words damaged by [damage].
    Future<Map<String, Object>> damaged(
      void Function(Map<String, Object?>) damage,
    ) async {
      final stored = await h.disk.stored();
      final composed =
          jsonDecode(stored[recommendationComposedKey]! as String)
              as Map<String, Object?>;
      damage(composed);
      return {...stored, recommendationComposedKey: jsonEncode(composed)};
    }

    final damages = <String, void Function(Map<String, Object?>)>{
      'one item not words': (c) => (c['wording']! as List)[1] = 42,
      'the wrong length': (c) => (c['wording']! as List).removeLast(),
      'not a list': (c) => c['wording'] = 'damaged',
    };

    for (final MapEntry(key: how, value: damage) in damages.entries) {
      for (final started in [false, true]) {
        final when = started ? 'started' : 'not started';
        test('$how, $when, kept Circle intact: restored with its own saved '
            'words from the kept Circle — never today\'s, never voiced as '
            'if they were', () async {
          final (_, words) = await keptToday(started: started);
          await h.boot(await damaged(damage));
          final c = h.open(status: EntitlementStatus.active);
          final composed = c
              .read(recommendationProvider)
              .recommendation
              ?.composed;
          expect(composed, isNotNull);
          expect(composed!.wording, words);
          expect(composed.voiced, isFalse);
          expect(composed.wordingAt(0).instruction, saved);
        });

        test('$how, $when, kept Circle gone: never run or voiced with '
            'today\'s words; the stored bytes are left as they were', () async {
          final (keptId, _) = await keptToday(started: started);
          final bytes = await damaged(damage);
          await h.boot({...bytes}..remove(keptCirclesKey));
          final c = h.open(status: EntitlementStatus.active);
          final state = c.read(recommendationProvider);
          final composed = state.recommendation?.composed;
          if (started) {
            expect(state.status, RecommendationStatus.started);
            expect(composed, isNotNull);
            expect(composed!.keptCircleId, keptId);
            expect(composed.voiced, isFalse, reason: 'voiced as historical');
            expect(
              composed.wording,
              isNull,
              reason: "no words are claimed as the Circle's own",
            );
          } else {
            expect(
              composed?.keptCircleId,
              isNull,
              reason: 'an unverifiable kept Circle offered to run',
            );
          }
          await R8Harness.settle();
          expect(
            (await h.disk.stored())[recommendationComposedKey],
            bytes[recommendationComposedKey],
          );
        });
      }
    }

    test("the words field missing from Today's copy while the kept Circle "
        'has its words: they come from the kept Circle', () async {
      await keptToday(started: false);
      await h.boot(await damaged((c) => c.remove('wording')));
      final c = h.open(status: EntitlementStatus.inactive);
      final composed = c.read(recommendationProvider).recommendation?.composed;
      expect(composed, isNotNull);
      expect(composed!.wording, isNotNull, reason: 'from the kept Circle');
    });
  });

  // ---------------------------------------------------------------- N07
  group('N07 — damaged or unknown data inside a readable record', () {
    Future<Map<String, Object?>> plansWith(
      void Function(Map<String, Object?> plans) change,
    ) async {
      final c = h.open();
      c.read(circlePlansProvider.notifier).start('getting_going');
      await R8Harness.settle();
      final raw =
          jsonDecode((await h.disk.stored())[circlePlansKey]! as String)
              as Map<String, Object?>;
      change(raw);
      await h.boot({circlePlansKey: jsonEncode(raw)});
      return raw;
    }

    Future<Map<String, Object?>> afterPause() async {
      final c = h.open();
      c.read(circlePlansProvider);
      c.read(circlePlansProvider.notifier).pause('getting_going');
      await R8Harness.settle();
      final stored = await h.disk.stored();
      expect(stored[circlePlansUnreadableKey], isNull);
      return jsonDecode(stored[circlePlansKey]! as String)
          as Map<String, Object?>;
    }

    test('AUD-3 — a Plan this build doesn\'t know (a newer build\'s) is kept '
        'byte for byte through a Plan save', () async {
      final original = await plansWith((raw) {
        final plans = raw['plans']! as Map<String, Object?>;
        plans['future_plan'] = {
          ...(plans['getting_going']! as Map),
          'lifecycle': 'paused',
          'futureField': [1, 2, 3],
        };
      });
      final after = await afterPause();
      expect(
        jsonEncode((after['plans']! as Map)['future_plan']),
        jsonEncode((original['plans']! as Map)['future_plan']),
      );
      expect(
        ((after['plans']! as Map)['getting_going'] as Map)['lifecycle'],
        'paused',
      );
    });

    test('a Plan whose cycle is damaged is kept as stored, never rewritten '
        'without it', () async {
      final original = await plansWith((raw) {
        final plan =
            (raw['plans']! as Map)['getting_going']! as Map<String, Object?>;
        plan['cycles'] = [
          {'id': 'getting_going#0', 'number': 'damaged'},
          ...plan['cycles']! as List,
        ];
      });
      final c = h.open();
      c.read(circlePlansProvider);
      c.read(circlePlansProvider.notifier).start('making_room');
      await R8Harness.settle();
      final stored =
          jsonDecode((await h.disk.stored())[circlePlansKey]! as String)
              as Map<String, Object?>;
      expect(
        jsonEncode((stored['plans']! as Map)['getting_going']),
        jsonEncode((original['plans']! as Map)['getting_going']),
      );
      expect(
        ((stored['plans']! as Map)['making_room'] as Map)['lifecycle'],
        'active',
      );
    });

    test('a damaged stage record inside a readable cycle is kept through a '
        'save', () async {
      final damagedRecord = {'stageNumber': 'two', 'outcome': 'guided'};
      await plansWith((raw) {
        final plan =
            (raw['plans']! as Map)['getting_going']! as Map<String, Object?>;
        final cycle = (plan['cycles']! as List).last as Map<String, Object?>;
        cycle['records'] = [damagedRecord];
      });
      final after = await afterPause();
      final cycle =
          (((after['plans']! as Map)['getting_going'] as Map)['cycles'] as List)
                  .last
              as Map;
      expect(jsonEncode(cycle['records']), jsonEncode([damagedRecord]));
    });

    test(
      'unknown fields of the Plans record itself are written back',
      () async {
        await plansWith((raw) => raw['addedLater'] = {'keep': 'me'});
        final after = await afterPause();
        expect(after['addedLater'], {'keep': 'me'});
      },
    );

    test('a Plans record of a newer whole-record version stays unreadable '
        'and is kept aside, not reinterpreted', () async {
      final original = await plansWith((raw) => raw['schemaVersion'] = 2);
      final c = h.open();
      c.read(circlePlansProvider);
      c.read(circlePlansProvider.notifier).start('making_room');
      await R8Harness.settle();
      expect(
        (await h.disk.stored())[circlePlansUnreadableKey],
        jsonEncode(original),
      );
    });

    test('AUD-4 / N07-A — Insights whose snapshots field is present but not '
        'a list are kept, never replaced unkept', () async {
      final damaged = jsonEncode({
        'schemaVersion': insightsSchemaVersion,
        'snapshots': {'recoverable': 'original payload'},
      });
      await h.boot({
        insightsKey: damaged,
        circleJournalKey: _i4Journal(morning),
      });
      final c = h.open();
      expect(c.read(insightsProvider.notifier).assess().added, isNotEmpty);
      await R8Harness.settle();
      final stored = await h.disk.stored();
      expect(
        stored[insightsKey] == damaged ||
            stored[insightsUnreadableKey] == damaged,
        isTrue,
      );
    });

    test(
      'unknown fields of the Insights record itself are written back',
      () async {
        await h.boot({
          insightsKey: jsonEncode({
            'schemaVersion': insightsSchemaVersion,
            'snapshots': <Object?>[],
            'addedLater': 7,
          }),
          circleJournalKey: _i4Journal(morning),
        });
        final c = h.open();
        c.read(insightsProvider.notifier).assess();
        await R8Harness.settle();
        final stored =
            jsonDecode((await h.disk.stored())[insightsKey]! as String) as Map;
        expect(stored['addedLater'], 7);
        expect(stored['snapshots'], isNotEmpty);
      },
    );

    test('regression — an Insights record without a snapshots field (none '
        'yet) is readable, as before', () async {
      await h.boot({
        insightsKey: jsonEncode({'schemaVersion': insightsSchemaVersion}),
        circleJournalKey: _i4Journal(morning),
      });
      final c = h.open();
      expect(c.read(insightsProvider.notifier).assess().added, isNotEmpty);
      await R8Harness.settle();
      expect((await h.disk.stored())[insightsUnreadableKey], isNull);
    });
  });
}

/// A journal from which, with Premium, Insights generate an Insight 4.
String _i4Journal(DateTime morning) {
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

  return jsonEncode({
    'schemaVersion': circleJournalSchemaVersion,
    'entries': [
      for (final ago in [1, 7, 13, 20]) entry(ago, writing, true).toJson(),
      for (final ago in [3, 9, 16]) entry(ago, reading, false).toJson(),
    ],
  });
}
