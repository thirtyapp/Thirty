import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/toolkit/application/toolkit_provider.dart';
import 'package:thirty/features/toolkit/application/v1_premium_retirement.dart';
import 'package:thirty/features/toolkit/domain/module_library.dart';
import 'package:thirty/features/toolkit/domain/path_catalog.dart';
import 'package:thirty/features/toolkit/domain/toolkit_model.dart';

/// V2 Phase D — the Toolkit through the real providers (ADR-022): paid
/// operations check the entitlement; ownership never does; a Path claims
/// only a matching, entitled, fitting day; the journal records what each
/// Circle was; V1 Premium state is retired, never migrated.

final _morning = DateTime(2026, 11, 20, 9);

class _World {
  _World(this.prefs, {required this.entitled, required this.day});

  final SharedPreferences prefs;
  bool entitled;
  DateTime day;

  ProviderContainer open() => ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(day),
      eventClockProvider.overrideWithValue(() => day),
      premiumEntitlementProvider.overrideWithValue(entitled),
      safetyPendingAllowedProvider.overrideWithValue(false),
    ],
  );
}

Future<_World> _world({bool entitled = true}) async {
  SharedPreferences.setMockInitialValues({});
  return _World(
    await SharedPreferences.getInstance(),
    entitled: entitled,
    day: _morning,
  );
}

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// One day: choose [need] in [window], start, close and answer.
Future<Recommendation> _circle(
  _World world,
  Intention need, {
  TimeWindow window = TimeWindow.about20,
  CircleUsefulnessResponse? answer,
}) async {
  final c = world.open();
  try {
    final circle = c.read(recommendationProvider.notifier);
    circle.chooseIntention(need, window: window);
    final today = c.read(recommendationProvider).recommendation!;
    circle.start();
    circle.close();
    if (answer != null) {
      circle.reportAttempt(CircleAttemptResponse.yes);
      circle.reportUsefulness(answer);
    }
    await _settle();
    return today;
  } finally {
    c.dispose();
  }
}

void main() {
  group('paid operations check the entitlement; ownership never does', () {
    test('starting a Path is Premium, and one at a time', () async {
      final free = await _world(entitled: false);
      final c = free.open();
      addTearDown(c.dispose);
      expect(
        c
            .read(toolkitProvider.notifier)
            .startBuild(PathTemplateId.wakeUpIndoors),
        PathStart.notEntitled,
      );
      free.entitled = true;
      final p = free.open();
      addTearDown(p.dispose);
      final notifier = p.read(toolkitProvider.notifier);
      expect(
        notifier.startBuild(PathTemplateId.wakeUpIndoors),
        PathStart.started,
      );
      expect(
        notifier.startBuild(PathTemplateId.softLanding),
        PathStart.pathUnderWay,
      );
    });

    test('a whole build through real days: claimed on matching days only, '
        'kept as the user\'s routine, persisted', () async {
      final world = await _world();
      final c = world.open();
      c.read(toolkitProvider.notifier).startBuild(PathTemplateId.wakeUpIndoors);
      await _settle();
      c.dispose();

      var claimed = 0;
      for (var day = 0; day < 10; day++) {
        world.day = _morning.add(Duration(days: day));
        final need = day == 3 ? Intention.clearerHead : Intention.moreEnergy;
        final today = await _circle(
          world,
          need,
          answer: CircleUsefulnessResponse.veryUseful,
        );
        if (today.session?.isPath ?? false) {
          claimed++;
          expect(need, Intention.moreEnergy);
          expect(today.session!.pathCircle, claimed);
        }
        if (claimed == 7) break;
      }
      expect(claimed, 7);

      final k = world.open();
      addTearDown(k.dispose);
      expect(k.read(toolkitProvider).path!.finished, isTrue);
      final routine = k
          .read(toolkitProvider.notifier)
          .keepProposal(name: 'Mornings')!;
      await _settle();
      expect(routine.name, 'Mornings');
      expect(routine.versions.first.pathRunId, isNotNull);

      // A restart reads the same Toolkit back.
      final r = world.open();
      addTearDown(r.dispose);
      expect(r.read(toolkitProvider).routines.single.name, 'Mornings');
      expect(r.read(toolkitProvider).path, isNull);
    });

    test('lapsed: rename, turn off and on, choose a version, delete — all '
        'still the user\'s', () async {
      final world = await _world(entitled: false);
      final routine = Routine(
        id: 'r',
        name: 'My pick-me-up',
        need: Intention.moreEnergy,
        versions: [
          RoutineVersion(
            id: 'r-v1',
            number: 1,
            composition: Composition(const [
              ModuleUse(ModuleId.standingStretch, short: false),
              ModuleUse(ModuleId.musicMove, short: false),
            ]),
            createdAt: _morning,
            origin: VersionOrigin.path,
          ),
          RoutineVersion(
            id: 'r-v2',
            number: 2,
            composition: Composition(const [
              ModuleUse(ModuleId.standingStretch, short: false),
              ModuleUse(ModuleId.activeTask, short: true),
            ]),
            createdAt: _morning,
            origin: VersionOrigin.tuneUp,
          ),
        ],
        activeVersionId: 'r-v2',
        createdAt: _morning,
      );
      await world.prefs.setString(
        toolkitStateKey,
        jsonEncode(ToolkitState(routines: [routine]).toJson()),
      );
      final c = world.open();
      addTearDown(c.dispose);
      final notifier = c.read(toolkitProvider.notifier);
      notifier.rename('r', '  Mornings ');
      expect(c.read(toolkitProvider).routines.single.name, 'Mornings');
      notifier.rename('r', '   ');
      expect(c.read(toolkitProvider).routines.single.name, 'Mornings');
      notifier.setEnabled('r', enabled: false);
      expect(c.read(routineCandidatesProvider), isEmpty);
      notifier.setEnabled('r', enabled: true);
      expect(c.read(routineCandidatesProvider), hasLength(1));
      notifier.useVersion('r', 'r-v1');
      expect(c.read(toolkitProvider).routines.single.activeVersionId, 'r-v1');
      expect(notifier.startTuneUp('r'), PathStart.notEntitled);
      await c
          .read(suggestionPreferencesProvider.notifier)
          .dontSuggestRoutine('r', Intention.moreEnergy);
      notifier.deleteRoutine('r');
      await _settle();
      expect(c.read(toolkitProvider).routines, isEmpty);
      // Its "Don't suggest" goes with it.
      expect(
        c.read(suggestionPreferencesProvider).routinesNotSuggested,
        isEmpty,
      );
    });
  });

  group('a Path and today\'s Circle', () {
    Future<_World> pathUnderWay({bool entitled = true}) async {
      final world = await _world(entitled: true);
      final c = world.open();
      c.read(toolkitProvider.notifier).startBuild(PathTemplateId.outTheDoor);
      await _settle();
      c.dispose();
      world.entitled = entitled;
      return world;
    }

    test(
      'a different need: the engine decides, the Path waits untouched',
      () async {
        final world = await pathUnderWay();
        final today = await _circle(world, Intention.gentlerPace);
        expect(today.session, isNull);
        final c = world.open();
        addTearDown(c.dispose);
        expect(c.read(toolkitProvider).path!.circles, isEmpty);
      },
    );

    test('too little time for the step, even shortened: the Path waits — '
        'nothing is cut', () async {
      final world = await pathUnderWay();
      // Out the door starts with a brisk walk: 15 minutes at its shortest.
      final today = await _circle(
        world,
        Intention.moreEnergy,
        window: TimeWindow.about10,
      );
      expect(today.session?.isPath ?? false, isFalse);
      expect(today.offeredMinutes, lessThanOrEqualTo(10));
    });

    test('Premium ended: the Path is saved, and today is a Free day', () async {
      final world = await pathUnderWay(entitled: false);
      final today = await _circle(world, Intention.moreEnergy);
      expect(today.session?.isPath ?? false, isFalse);
      final c = world.open();
      addTearDown(c.dispose);
      expect(c.read(toolkitProvider).path, isNotNull);
    });

    test('a piece the user has since asked not to see: the step doesn\'t '
        'claim the day', () async {
      final world = await pathUnderWay();
      final c = world.open();
      await c
          .read(suggestionPreferencesProvider.notifier)
          .dontSuggest(ActivityId.thirtyMinuteWalk, Intention.moreEnergy);
      c.dispose();
      final today = await _circle(world, Intention.moreEnergy);
      expect(today.session?.isPath ?? false, isFalse);
      expect(today.activityId, isNot(ActivityId.thirtyMinuteWalk));
    });

    test('a claimed step is restored exactly after a restart, and counts '
        'once when closed', () async {
      final world = await pathUnderWay();
      final c = world.open();
      c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      final shown = c.read(recommendationProvider).recommendation!;
      expect(shown.session!.pathCircle, 1);
      await _settle();
      c.dispose();

      final again = world.open();
      addTearDown(again.dispose);
      final restored = again.read(recommendationProvider).recommendation!;
      expect(restored.session!.pathRunId, shown.session!.pathRunId);
      expect(restored.activity, shown.activity);
      final circle = again.read(recommendationProvider.notifier);
      circle.start();
      circle.close();
      circle.close();
      await _settle();
      expect(again.read(toolkitProvider).path!.circles, hasLength(1));
      final entry = again.read(circleJournalRepositoryProvider).readAll().last;
      expect(entry.session?.pathCircle, 1);
      expect(entry.session?.pathName, 'Out the door');
    });
  });

  group('V1 Premium retirement', () {
    test('removes V1 Plans and Insights, keeps the journal and every Free '
        'preference, and runs once', () async {
      SharedPreferences.setMockInitialValues({
        'plans_state_v1': '{"schemaVersion":1}',
        'insight_snapshots_v1': '{"schemaVersion":1}',
        recommendationPlanIdKey: 'moreEnergyPath',
        circleJournalKey: '{"schemaVersion":1,"entries":[]}',
        suggestionPreferencesKey: '{"schemaVersion":1}',
        'theme_mode': 'dark',
      });
      final prefs = await SharedPreferences.getInstance();
      await retireV1Premium(prefs);
      expect(prefs.containsKey('plans_state_v1'), isFalse);
      expect(prefs.containsKey('insight_snapshots_v1'), isFalse);
      expect(prefs.containsKey(recommendationPlanIdKey), isFalse);
      expect(prefs.getString(circleJournalKey), isNotNull);
      expect(prefs.getString(suggestionPreferencesKey), isNotNull);
      expect(prefs.getString('theme_mode'), 'dark');
      expect(prefs.getBool(v1PremiumRetiredKey), isTrue);
      // Nothing is made from V1 progress.
      expect(prefs.containsKey(toolkitStateKey), isFalse);

      // Idempotent: a later stray key (an old backup) isn't touched again.
      await prefs.setString('plans_state_v1', 'restored-by-hand');
      await retireV1Premium(prefs);
      expect(prefs.getString('plans_state_v1'), 'restored-by-hand');
    });

    test(
      'an interrupted retirement (no marker yet) simply runs again',
      () async {
        SharedPreferences.setMockInitialValues({'insight_snapshots_v1': 'x'});
        final prefs = await SharedPreferences.getInstance();
        await retireV1Premium(prefs);
        expect(prefs.containsKey('insight_snapshots_v1'), isFalse);
      },
    );
  });

  group('the store', () {
    test('an unreadable record is set aside untouched, and the Toolkit '
        'starts empty rather than guessing', () async {
      SharedPreferences.setMockInitialValues({toolkitStateKey: '{not json'});
      final prefs = await SharedPreferences.getInstance();
      final state = ToolkitRepository(prefs).read();
      await _settle();
      expect(state.isEmpty, isTrue);
      expect(prefs.getString(toolkitUnreadableKey), '{not json');
    });

    test(
      'export carries routines, versions and the Path — no scores',
      () async {
        final world = await _world();
        final c = world.open();
        addTearDown(c.dispose);
        c.read(toolkitProvider.notifier).startBuild(PathTemplateId.softLanding);
        final exported =
            jsonDecode(
                  c
                      .read(circleJournalRepositoryProvider)
                      .exportAsJson(toolkit: c.read(toolkitProvider).toJson()),
                )
                as Map<String, Object?>;
        final toolkit = exported['toolkit']! as Map<String, Object?>;
        expect(toolkit['path'], isNotNull);
        expect(toolkit.keys, isNot(contains('score')));
        expect(jsonEncode(toolkit), isNot(contains('strength')));
      },
    );
  });
}
