import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/dev_preview/paced_qa_bench_page.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/qa/qa_container.dart';
import 'package:thirty/core/qa/qa_entitlement_gateway.dart';
import 'package:thirty/core/qa/qa_scenario.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/domain/circle_session.dart';
import 'package:thirty/features/home/domain/memory_overview.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';

/// V2 Phase C — every QA fixture (A–R), built through the same seeding the
/// harness uses and opened on the reference moment: each proves its state
/// before anyone walks it on a device.
void main() {
  final reference = DateTime(2026, 10, 8, 10);
  late SharedPreferences genuine;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    genuine = await SharedPreferences.getInstance();
  });

  Future<ProviderContainer> open(QaScenario scenario) async {
    final container = ProviderContainer(
      overrides: [
        ...qaContainerOverrides(
          genuinePreferences: genuine,
          supabaseAvailable: false,
          session: QaSession(
            entitlement: QaEntitlement.inactive,
            scenario: scenario,
            store: await buildQaStore(
              scenario: scenario,
              genuine: genuine,
              referenceNow: reference,
            ),
          ),
        ),
        nowProvider.overrideWithValue(reference),
        eventClockProvider.overrideWithValue(() => reference),
      ],
    );
    await container.read(entitlementStatusProvider.notifier).initialize();
    addTearDown(container.dispose);
    return container;
  }

  Duration elapsed(ProviderContainer c) =>
      c.read(recommendationProvider).activeElapsedAt(reference);

  test('A–C · Open: fresh, its time reached, and four minutes in', () async {
    final fresh = await open(QaScenario.cOpenFresh);
    expect(
      fresh.read(recommendationProvider).status,
      RecommendationStatus.notStarted,
    );
    expect(
      fresh.read(recommendationProvider).recommendation!.activityId,
      ActivityId.writeItDown,
    );

    final ended = await open(QaScenario.cOpenEnded);
    expect(
      ended.read(recommendationProvider).status,
      RecommendationStatus.started,
    );
    expect(
      naturalEndReached(elapsed(ended), const Duration(minutes: 15)),
      isTrue,
    );

    final running = await open(QaScenario.cOpenRunning);
    expect(elapsed(running).inMinutes, 4);
  });

  test('D–G · Guided: step 1, the middle, paused, its time reached', () async {
    final first = await open(QaScenario.cGuidedFirst);
    expect(first.read(recommendationProvider).guidedPosition, 0);

    final middle = await open(QaScenario.cGuidedMiddle);
    expect(middle.read(recommendationProvider).guidedPosition, 2);

    final paused = await open(QaScenario.cGuidedPaused);
    expect(paused.read(recommendationProvider).isPaused, isTrue);
    expect(paused.read(recommendationProvider).guidedPosition, 3);
    expect(elapsed(paused).inMinutes, 2);

    final ended = await open(QaScenario.cGuidedEnded);
    expect(
      naturalEndReached(elapsed(ended), const Duration(minutes: 5)),
      isTrue,
    );
  });

  test('H · Paced opens on the internal bench, never on Today', () {
    expect(QaScenario.cPacedInternal.opensAt, PacedQaBenchPage.location);
    for (final scenario in QaScenario.values) {
      if (scenario == QaScenario.cPacedInternal) continue;
      expect(scenario.opensAt, isNull, reason: scenario.wireName);
    }
  });

  test('I–K · closed: no answer, "Very useful", "Not useful"', () async {
    final none = await open(QaScenario.cClosedNoAnswer);
    expect(
      none.read(recommendationProvider).status,
      RecommendationStatus.closed,
    );
    expect(none.read(recommendationProvider).attemptResponse, isNull);

    final useful = await open(QaScenario.cClosedUseful);
    expect(
      useful.read(recommendationProvider).usefulnessResponse,
      CircleUsefulnessResponse.veryUseful,
    );

    final notUseful = await open(QaScenario.cClosedNotUseful);
    expect(
      notUseful.read(recommendationProvider).usefulnessResponse,
      CircleUsefulnessResponse.notUseful,
    );
  });

  NeedMemory memory(ProviderContainer c, Intention need) => needMemoryOf(
    today: reference,
    need: need,
    history: pastCirclesFrom(c.read(circleJournalRepositoryProvider).readAll()),
    controls: c.read(suggestionPreferencesProvider).controls,
    allowSafetyPending: false,
  );

  test(
    'L–O · memory: mixed, resting, "Don\'t suggest", a lifted rest',
    () async {
      final mixed = await open(QaScenario.cMemoryMixed);
      final clearer = memory(mixed, Intention.clearerHead);
      expect(clearer.usefulBefore, isNotEmpty);
      expect(clearer.resting, isNotEmpty);
      expect(memory(mixed, Intention.gentlerPace).resting, isNotEmpty);
      expect(memory(mixed, Intention.gentlerPace).notUsefulBefore, isNotEmpty);

      final resting = await open(QaScenario.cMemoryResting);
      expect(
        memory(resting, Intention.gentlerPace).resting.single.activity,
        ActivityId.easyWalk,
      );

      final notSuggested = await open(QaScenario.cMemoryNotSuggested);
      expect(memory(notSuggested, Intention.moreEnergy).notSuggested, [
        ActivityId.moveToMusic,
      ]);

      final lifted = await open(QaScenario.cMemoryRestLifted);
      expect(memory(lifted, Intention.gentlerPace).resting, isEmpty);
    },
  );

  test(
    'P · nothing fits More Energy at ≈ 10, and the time is preset to it',
    () async {
      final c = await open(QaScenario.cMemoryNothingFits);
      expect(c.read(timeWindowChoiceProvider), TimeWindow.about10);
      c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy);
      expect(c.read(recommendationProvider).recommendation, isNull);
      expect(c.read(recommendationProvider).noCandidateFor, (
        Intention.moreEnergy,
        TimeWindow.about10,
      ));
    },
  );

  test('Q–R · history with preferences, to delete or to reset', () async {
    for (final scenario in [
      QaScenario.cDeleteKeepsPreferences,
      QaScenario.cResetPreferences,
    ]) {
      final c = await open(scenario);
      expect(
        c.read(circleJournalRepositoryProvider).readAll(),
        isNotEmpty,
        reason: scenario.wireName,
      );
      expect(
        c.read(suggestionPreferencesProvider).isEmpty,
        isFalse,
        reason: scenario.wireName,
      );
    }
  });
}
