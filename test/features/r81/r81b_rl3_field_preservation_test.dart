import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/storage/store_save_failures.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';

import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.1 RL-3 (founder decision, 2026-11-05): a damaged item inside an
/// otherwise readable Plans or Suggestion Preferences record — a stage
/// record's list item, a revisit entry, a future version's field — is never
/// dropped by a later save. What can be read stays usable; nothing is
/// invented; a record that can't be read at all is never written over.
void main() {
  final morning = DateTime(2026, 10, 12, 9);
  late R8Harness h;

  setUp(() async {
    h = R8Harness(morning);
    await h.boot();
  });

  Future<Map<String, Object?>> json(String key) async =>
      (jsonDecode((await h.disk.stored())[key]! as String) as Map)
          .cast<String, Object?>();

  // ------------------------------------------------------------- Plans
  group('Plans — inside a readable cycle', () {
    final guided = {
      'stageNumber': 1,
      'outcome': 'guided',
      'localDate': '2026-10-05',
      'circleId': '2026-10-05',
      'parts': ['getItOut:6', 42, 'chooseOne:1'],
      'skipped': [null],
      'drawsOn': ['stage.one', 7],
      'futureField': {'from': 'a newer THIRTY'},
    };
    final setAside = {
      'stageNumber': 2,
      'outcome': 'setAside',
      'localDate': '2026-10-06',
      'setAsideBecause': [
        {'element': 'getItOut', 'role': 'main', 'reason': 'leftOut'},
        {'element': 'aNewerElement', 'role': 'main', 'reason': 'resting'},
        'damaged',
      ],
    };

    /// A stored Plans record, its current cycle holding [records] and
    /// [revisits], at stage [cursor].
    Future<Map<String, Object?>> seed({
      List<Object?> records = const [],
      List<Object?> revisits = const [],
      int cursor = 3,
      Object? end,
    }) async {
      final c = h.open();
      c.read(circlePlansProvider.notifier).start('getting_going');
      await R8Harness.settle();
      final raw = await json(circlePlansKey);
      final plan = (raw['plans']! as Map)['getting_going']! as Map;
      final cycle = (plan['cycles']! as List).last as Map;
      cycle['records'] = records;
      cycle['cursor'] = cursor;
      if (revisits.isNotEmpty) cycle['revisitsUsed'] = revisits;
      if (end != null) cycle['end'] = end;
      await h.boot({circlePlansKey: jsonEncode(raw)});
      return raw;
    }

    Map<String, Object?> cycleOf(Map<String, Object?> raw) =>
        (((raw['plans']! as Map)['getting_going']! as Map)['cycles']! as List)
                .last
            as Map<String, Object?>;

    for (final fault in [null, ...DiskFault.values]) {
      test('a stage record with damaged list items and a future field, and '
          'damaged set-aside reasons: kept byte for byte through '
          '${fault == null ? 'repeated saves and restarts' : 'a save that ${fault.name}'}'
          '; what is readable stays usable', () async {
        final original = await seed(records: [guided, setAside]);
        for (var round = 0; round < 2; round++) {
          final c = h.open();
          final plans = c.read(circlePlansProvider);
          expect(plans.active!.current.guidedStages, 1, reason: 'readable');
          expect(plans.active!.current.cursor, 3);
          if (fault != null) h.disk.fail(circlePlansKey, fault, times: 1);
          c.read(circlePlansProvider.notifier).pause('getting_going');
          await R8Harness.settle();
          final after = await json(circlePlansKey);
          expect(
            jsonEncode(cycleOf(after)['records']),
            jsonEncode(cycleOf(original)['records']),
          );
          if (fault != null) {
            expect(jsonEncode(after), jsonEncode(original));
            break;
          }
          await h.restart();
          final again = h.open();
          again.read(circlePlansProvider.notifier).resume('getting_going');
          await R8Harness.settle();
          await h.restart();
        }
      });
    }

    test('revisit entries that aren\'t stage numbers are kept, and the '
        'readable ones still count', () async {
      await seed(revisits: [1, 'two', 2.5]);
      final c = h.open();
      expect(c.read(circlePlansProvider).active!.current.revisitsUsed, {1});
      c.read(circlePlansProvider.notifier).pause('getting_going');
      await R8Harness.settle();
      final revisits = cycleOf(await json(circlePlansKey))['revisitsUsed'];
      expect(revisits, containsAll(<Object?>[1, 'two', 2.5]));
    });

    test('a cycle ended by a reason a newer THIRTY added is kept as stored, '
        'never read as not ended', () async {
      final original = await seed(end: 'aFutureEnd', cursor: 5);
      final c = h.open();
      c.read(circlePlansProvider);
      c.read(circlePlansProvider.notifier).start('making_room');
      await R8Harness.settle();
      final after = await json(circlePlansKey);
      expect(
        jsonEncode((after['plans']! as Map)['getting_going']),
        jsonEncode((original['plans']! as Map)['getting_going']),
      );
    });
  });

  // ----------------------------------------------- Suggestion preferences
  group('Suggestion preferences', () {
    final valid = {
      'activityId': ActivityId.values.first.name,
      'need': Intention.moreEnergy.name,
      'since': '2026-10-01T09:00:00.000',
    };
    final damaged = {'activityId': 'aRetiredOrNewerActivity', 'need': 'x'};

    for (final fault in [null, ...DiskFault.values]) {
      test('a damaged item beside valid ones is kept through '
          '${fault == null ? 'saves and a restart' : 'a save that ${fault.name}'}'
          '; the valid ones still apply', () async {
        final stored = jsonEncode({
          'schemaVersion': suggestionPreferencesSchemaVersion,
          'notSuggested': [valid, damaged],
          'elementsLeftOut': ['damaged'],
          'futureList': [1, 2],
        });
        await h.boot({suggestionPreferencesKey: stored});
        final c = h.open(status: EntitlementStatus.active);
        final prefs = c.read(suggestionPreferencesProvider);
        expect(prefs.notSuggested, hasLength(1));
        if (fault != null) {
          h.disk.fail(suggestionPreferencesKey, fault, times: 1);
        }
        final saved = await c
            .read(suggestionPreferencesProvider.notifier)
            .leaveOut(ElementId.openWindow);
        await R8Harness.settle();
        final after = await json(suggestionPreferencesKey);
        if (fault != null) {
          expect(saved, isFalse);
          expect((await h.disk.stored())[suggestionPreferencesKey], stored);
          return;
        }
        expect(saved, isTrue);
        expect(after['notSuggested'], containsAll(<Object?>[valid, damaged]));
        expect(after['elementsLeftOut'], contains('damaged'));
        expect(after['futureList'], [1, 2]);
        await h.restart();
        final again = h.open(status: EntitlementStatus.active);
        expect(again.read(suggestionPreferencesProvider).leftOut, {
          ElementId.openWindow,
        });
        await again
            .read(suggestionPreferencesProvider.notifier)
            .putBack(ElementId.openWindow);
        await R8Harness.settle();
        final last = await json(suggestionPreferencesKey);
        expect(last['notSuggested'], containsAll(<Object?>[valid, damaged]));
      });
    }

    for (final MapEntry(key: what, value: raw) in {
      'a newer version': jsonEncode({
        'schemaVersion': suggestionPreferencesSchemaVersion + 1,
        'notSuggested': [valid],
      }),
      'not JSON': '{damaged',
      'a list field that is not a list': jsonEncode({
        'schemaVersion': suggestionPreferencesSchemaVersion,
        'notSuggested': {'not': 'a list'},
      }),
    }.entries) {
      test('a record THIRTY can\'t read ($what) is never written over by a '
          'change; the user is told; Reset — the user\'s own erasure — '
          'still works', () async {
        await h.boot({suggestionPreferencesKey: raw});
        final c = h.open(status: EntitlementStatus.active);
        final notifier = c.read(suggestionPreferencesProvider.notifier);
        expect(await notifier.leaveOut(ElementId.openWindow), isFalse);
        await R8Harness.settle();
        expect((await h.disk.stored())[suggestionPreferencesKey], raw);
        expect(
          c.read(storeSaveFailuresProvider).unsaved,
          contains(UserStore.suggestionPreferences),
        );
        await h.restart();
        expect((await h.disk.stored())[suggestionPreferencesKey], raw);

        final again = h.open(status: EntitlementStatus.active);
        expect(
          await again.read(suggestionPreferencesProvider.notifier).reset(),
          isTrue,
        );
        expect(
          (await h.disk.stored()).containsKey(suggestionPreferencesKey),
          isFalse,
        );
      });
    }

    test('regression — the retired Phase D routines field is still dropped '
        'by the next save (pre-release migration, ADR-024)', () async {
      await h.boot({
        suggestionPreferencesKey: jsonEncode({
          'schemaVersion': suggestionPreferencesSchemaVersion,
          retiredRoutinesNotSuggestedField: ['old'],
        }),
      });
      final c = h.open(status: EntitlementStatus.active);
      await c
          .read(suggestionPreferencesProvider.notifier)
          .leaveOut(ElementId.openWindow);
      expect(
        (await json(
          suggestionPreferencesKey,
        )).containsKey(retiredRoutinesNotSuggestedField),
        isFalse,
      );
    });
  });
}
