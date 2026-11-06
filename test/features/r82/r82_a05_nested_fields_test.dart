import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/utils/date_key.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_stage_provenance.dart';

import '../../support/r8_harness.dart';

/// R8.2 — Astra R81-A05 (MEDIUM): a stored record THIRTY accepts is
/// written back with everything it holds — fields a newer build added,
/// nested values this build doesn't read — through ordinary unrelated
/// saves, repeated saves and restarts. A malformed provenance field is
/// never read as a security-relevant default.
void main() {
  final morning = DateTime(2026, 10, 30, 9);
  late R8Harness h;

  setUp(() async {
    h = R8Harness(morning);
    await h.boot();
  });

  Future<Map<String, Object?>> json(String key) async {
    final raw = (await h.disk.stored())[key];
    return raw is String ? jsonDecode(raw) as Map<String, Object?> : {};
  }

  Future<ProviderContainer> restart() async {
    await h.restart();
    return h.open();
  }

  // --------------------------------------------------------- Preferences
  group('Suggestion Preferences — readable entries keep their own fields', () {
    const leftOut = {
      'elementId': 'openWindow',
      'since': '2026-10-01T09:00:00.000+02:00',
      'futureRule': {'keep': true},
    };
    const notSuggested = {
      'activityId': 'easyWalk',
      'need': 'moreEnergy',
      'since': '2026-10-02T09:00:00.000',
      'futureScope': ['weekdays'],
    };
    const lifted = {
      'activityId': 'easyWalk',
      'need': 'gentlerPace',
      'at': '2026-10-03T09:00:00.000',
      'futureReason': 'asked',
    };

    Future<void> seed() => h.boot({
      suggestionPreferencesKey: jsonEncode({
        'schemaVersion': suggestionPreferencesSchemaVersion,
        'notSuggested': [notSuggested],
        'restsLifted': [lifted],
        'elementsLeftOut': [leftOut],
      }),
    });

    Future<void> exactlyKept() async {
      final stored = await json(suggestionPreferencesKey);
      expect((stored['elementsLeftOut']! as List).first, leftOut);
      expect((stored['notSuggested']! as List).first, notSuggested);
      expect(
        (stored['restsLifted']! as List).firstWhere(
          (r) => (r as Map)['need'] == 'gentlerPace',
        ),
        lifted,
      );
    }

    test('A05 as reported — another part left out: the first entry keeps '
        'futureRule; so do the other lists, through two more saves and '
        'restarts', () async {
      await seed();
      final c = h.open();
      expect(c.read(suggestionPreferencesProvider).leftOut, {
        ElementId.openWindow,
      });
      expect(
        await c
            .read(suggestionPreferencesProvider.notifier)
            .leaveOut(ElementId.readPages),
        isTrue,
      );
      await exactlyKept();
      final again = await restart();
      await again
          .read(suggestionPreferencesProvider.notifier)
          .dontSuggest(ActivityId.values.last, Intention.clearerHead);
      await again
          .read(suggestionPreferencesProvider.notifier)
          .liftRest(ActivityId.values.last, Intention.moreEnergy);
      await exactlyKept();
      await restart();
      await exactlyKept();
    });

    test('a malformed date is not read as a date: the entry is kept as '
        'stored and never applied', () async {
      await h.boot({
        suggestionPreferencesKey: jsonEncode({
          'schemaVersion': suggestionPreferencesSchemaVersion,
          'elementsLeftOut': [
            {'elementId': 'openWindow', 'since': 2026},
          ],
        }),
      });
      final c = h.open();
      expect(c.read(suggestionPreferencesProvider).leftOut, isEmpty);
      await c
          .read(suggestionPreferencesProvider.notifier)
          .leaveOut(ElementId.readPages);
      final stored = await json(suggestionPreferencesKey);
      expect(
        stored['elementsLeftOut'],
        contains(equals({'elementId': 'openWindow', 'since': 2026})),
      );
    });
  });

  // --------------------------------------------------------------- Plans
  group('Plans — the last served record', () {
    final served = {
      'circleId': '2026-10-29',
      'stage': {
        'planId': 'getting_going',
        'cycleId': 'getting_going#1',
        'stageNumber': 1,
        'stageId': 'getting_going.1',
        'futureStageField': 7,
      },
      'futureServedField': 'kept',
    };

    String plansWith(Map<String, Object?> lastServed) {
      final active = CirclePlansState.empty
          .start('getting_going', today: '2026-10-20')!
          .toJson();
      ((active['plans']! as Map)['getting_going'] as Map)['lastServed'] =
          lastServed;
      return jsonEncode(active);
    }

    Future<Object?> servedOnDisk() async =>
        (((await json(circlePlansKey))['plans'] as Map)['getting_going']
            as Map)['lastServed'];

    test('A05 as reported — unknown fields of a valid last served record '
        'survive an unrelated Plan save and restarts', () async {
      await h.boot({circlePlansKey: plansWith(served)});
      final c = h.open();
      expect(
        c.read(circlePlansProvider.notifier).start('making_room'),
        PlanActionResult.done,
      );
      await R8Harness.settle();
      expect(await servedOnDisk(), served);
      final again = await restart();
      again.read(circlePlansProvider.notifier).resume('getting_going');
      await R8Harness.settle();
      expect(await servedOnDisk(), served);
      await restart();
      expect(await servedOnDisk(), served);
    });

    for (final malformed in <Object>['true', 1, 'yes']) {
      test('a malformed startedAfterExpiry ($malformed) is never read as '
          '"started under Premium": no guided credit after a lapse, and it '
          'is written back as stored', () async {
        final damaged = {...served, 'startedAfterExpiry': malformed};
        final raw = plansWith(damaged);
        final state = CirclePlansState.fromJson(jsonDecode(raw))!;
        const stage = PlanStageProvenance(
          planId: 'getting_going',
          cycleId: 'getting_going#1',
          stageNumber: 1,
          stageId: 'getting_going.1',
        );
        expect(
          state.creditsServed(stage, circleId: '2026-10-29'),
          isFalse,
          reason: 'a damaged flag coerced to a credit-earning default',
        );
        await h.boot({circlePlansKey: raw});
        final c = h.open();
        c.read(circlePlansProvider.notifier).start('making_room');
        await R8Harness.settle();
        expect(await servedOnDisk(), damaged);
      });
    }

    test('a malformed revisit flag in the served stage is not read as '
        '"no revisit"', () {
      final damaged = {
        ...served,
        'stage': {...(served['stage']! as Map), 'revisit': 'true'},
      };
      final state = CirclePlansState.fromJson(
        jsonDecode(plansWith(damaged)),
      )!;
      const stage = PlanStageProvenance(
        planId: 'getting_going',
        cycleId: 'getting_going#1',
        stageNumber: 1,
        stageId: 'getting_going.1',
      );
      expect(state.wasServed(stage, circleId: '2026-10-29'), isFalse);
    });
  });

  // ------------------------------------------------------------ Insights
  group('Insights — accepted snapshots keep nested values', () {
    String i4Journal() {
      CirclePart part(ElementId e) => CirclePart(e, elementOf(e).minutes);
      final writing = [
        part(ElementId.closeWhatsOpen),
        part(ElementId.getItOut),
        part(ElementId.chooseOne),
        part(ElementId.firstStep),
      ];
      final reading = [
        part(ElementId.phoneFaceDown),
        part(ElementId.readPages),
      ];
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
          usefulnessResponse: useful
              ? CircleUsefulnessResponse.veryUseful
              : null,
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

    test('A05 as reported — an object-valued fact, a non-text evidence item '
        'and unknown fields on a snapshot and its application survive an '
        'unrelated dismissal and restarts', () async {
      await h.boot({circleJournalKey: i4Journal()});
      final c = h.open();
      c.read(insightsProvider.notifier).assess();
      await R8Harness.settle();
      final stored = await json(insightsKey);
      final original = Map<String, Object?>.from(
        (stored['snapshots']! as List).single as Map,
      );
      final damaged = {
        ...original,
        'facts': {
          ...(original['facts']! as Map),
          'futureFact': {'nested': 1},
        },
        'evidence': [...(original['evidence']! as List), 42],
        'futureSnapshotField': true,
        'application': {
          ...(original['application']! as Map),
          'futureApplicationField': 'x',
        },
      };
      final sibling = {...original, 'id': '${original['id']}-b'};
      await h.boot({
        ...await h.disk.stored(),
        insightsKey: jsonEncode({
          ...stored,
          'snapshots': [damaged, sibling],
        }),
      });
      final again = h.open();
      expect(again.read(insightsProvider).snapshots, hasLength(2));
      again.read(insightsProvider.notifier).notNow('${original['id']}-b');
      await R8Harness.settle();
      Future<Object?> first() async =>
          ((await json(insightsKey))['snapshots']! as List).firstWhere(
            (s) => (s as Map)['id'] == original['id'],
          );
      expect(await first(), damaged, reason: 'nested values dropped');
      final third = await restart();
      third.read(insightsProvider.notifier).assess();
      await R8Harness.settle();
      expect(await first(), damaged);
      await restart();
      expect(await first(), damaged);
    });
  });
}
