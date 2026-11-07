import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/storage/confirmed_write.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/plans/application/circle_plans_provider.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';

import '../../support/r83_invariants.dart';
import '../../support/r8_fault_disk.dart';
import '../../support/r8_harness.dart';

/// R8.3 — the test infrastructure checks itself: the "landed, answer lost"
/// fault is distinguishable from a write that never landed; the
/// single-writer guard sees overlapping writes to one key; the durable-state
/// oracle reports what it should, and nothing on a clean disk. These are
/// simulations in one Dart process — not Android's storage behaviour.
void main() {
  late R8Harness h;

  setUp(() async {
    h = R8Harness(DateTime(2026, 10, 12, 9));
    await h.boot();
  });

  group('the ack-lost fault', () {
    test('the value lands and the call throws; writeConfirmed then puts the '
        'previous value back, which lands too', () async {
      await h.boot({'k': 'old'});
      h.disk.ackLost('k');
      await expectLater(
        writeConfirmed(h.prefs, 'k', 'new'),
        throwsA(isA<StorageWriteFailed>()),
      );
      expect(h.disk.ackLostLog, ['set k']);
      expect(h.disk.log, ['set k', 'set k']);
      expect((await h.disk.stored())['k'], 'old');
    });

    test('with thenStop the value lands and the process stops: the call '
        'never completes, nothing after it lands', () async {
      h.disk.ackLost('k', thenStop: true);
      var completed = false;
      writeConfirmed(h.prefs, 'k', 'new').then((_) => completed = true).ignore();
      await R8Harness.settle();
      expect(completed, isFalse);
      expect((await h.disk.stored())['k'], 'new');
      h.prefs.setString('other', 'x').ignore();
      await R8Harness.settle();
      expect((await h.disk.stored()).containsKey('other'), isFalse);
    });

    test('distinct from a refused write, which never lands', () async {
      await h.boot({'k': 'old'});
      h.disk.fail('k', DiskFault.returnsFalse, times: 1);
      await expectLater(
        writeConfirmed(h.prefs, 'k', 'new'),
        throwsA(isA<StorageWriteFailed>()),
      );
      expect(h.disk.ackLostLog, isEmpty);
      expect(h.disk.log, ['set k']);
      expect((await h.disk.stored())['k'], 'old');
    });

    test('a held write released as ack-lost lands, then fails', () async {
      final held = h.disk.hold('k');
      final write = h.prefs.setString('k', 'new');
      await held.reached;
      held.releaseAckLost();
      await expectLater(write, throwsA(isA<StateError>()));
      expect((await h.disk.stored())['k'], 'new');
    });
  });

  group('the single-writer guard', () {
    test('two writes of one key in flight at once are recorded', () async {
      final held = h.disk.hold('k');
      final first = h.prefs.setString('k', 'a');
      await held.reached;
      final second = h.prefs.setString('k', 'b');
      held.release();
      await first;
      await second;
      expect(h.disk.overlaps, ['set k']);
    });

    test('one write after another is not', () async {
      await h.prefs.setString('k', 'a');
      await h.prefs.setString('k', 'b');
      await SharedPreferences.getInstance();
      expect(h.disk.overlaps, isEmpty);
    });
  });

  group('the durable-state oracle', () {
    test('a clean disk shows no violation', () {
      final state = DurableState({
        circlePlansKey: jsonEncode(
          CirclePlansState.empty.start('getting_going', today: '2026-10-12')!
              .toJson(),
        ),
      });
      expect(state.always(), isEmpty);
      expect(state.deletionResidue(), isEmpty);
      expect(state.appliedWithoutProvenance(), isEmpty);
    });

    test('V: a record whose re-encoding differs is reported', () {
      final plans = jsonDecode(
        jsonEncode(
          CirclePlansState.empty.start('getting_going', today: '2026-10-12')!
              .toJson(),
        ),
      ) as Map<String, Object?>;
      // A key THIRTY writes only when set, stored as null, re-encodes
      // without it.
      ((plans['plans'] as Map)['getting_going'] as Map)['lastServed'] = null;
      final state = DurableState({circlePlansKey: jsonEncode(plans)});
      expect(state.roundTripViolations(), hasLength(1));
    });

    test('IV: a Circle started on another day than its own is reported', () {
      final state = DurableState({
        recommendationDayKey: '2026-10-30',
        recommendationStatusKey: 'started',
        recommendationStartedAtKey: DateTime(2026, 10, 31, 0, 0, 1)
            .toUtc()
            .toIso8601String(),
      });
      expect(state.startedOffDay(), hasLength(1));
    });

    test('VI: residue after a Delete is reported', () {
      final state = DurableState({
        suggestionPreferencesKey: jsonEncode({
          'schemaVersion': suggestionPreferencesSchemaVersion,
          'elementsLeftOut': [
            {
              'elementId': 'openWindow',
              'since': '2026-10-01T09:00:00.000',
              'byInsight': 'I3@x',
            },
          ],
        }),
        recommendationDayKey: '2026-10-12',
      });
      expect(state.deletionResidue(), hasLength(2));
    });
  });
}
