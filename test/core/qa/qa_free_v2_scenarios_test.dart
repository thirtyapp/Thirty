import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/qa/qa_container.dart';
import 'package:thirty/core/qa/qa_entitlement_gateway.dart';
import 'package:thirty/core/qa/qa_scenario.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';

/// V2 Phase B — the Free QA fixtures, built through the production
/// notifiers, then opened on the reference day exactly as the harness would:
/// each proves its behaviour before anyone walks it on a device.
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

  Recommendation choose(ProviderContainer c, Intention need) {
    c.read(recommendationProvider.notifier).chooseIntention(need);
    return c.read(recommendationProvider).recommendation!;
  }

  test('A · new user: the curated start, nothing personal, ≈ 20', () async {
    final c = await open(QaScenario.newUser);
    expect(c.read(timeWindowChoiceProvider), TimeWindow.about20);
    final r = choose(c, Intention.moreEnergy);
    expect(r.activityId, ActivityId.thirtyMinuteWalk);
    expect(r.personalReason, isNull);
  });

  test('B · one Not useful: on day 5 that activity is resting', () async {
    final c = await open(QaScenario.freeNotUseful);
    final rested = c
        .read(circleJournalRepositoryProvider)
        .readAll()
        .first
        .activityId;
    expect(rested, ActivityId.thirtyMinuteWalk);
    expect(choose(c, Intention.moreEnergy).activityId, isNot(rested));
  });

  test('C · useful before: it comes back, and says so', () async {
    final c = await open(QaScenario.freeUseful);
    final r = choose(c, Intention.moreEnergy);
    expect(r.activityId, ActivityId.thirtyMinuteWalk);
    expect(r.personalReason, 'You found this useful before.');
  });

  test('I · exploration: a settled need is offered something new', () async {
    final c = await open(QaScenario.freeExploration);
    final r = choose(c, Intention.clearerHead);
    expect(r.reason, RecommendationReason.tryingNew);
    expect(r.personalReason, 'Something new to try for this.');
  });

  test('H · a secondary fit promoted by its evidence, at ≈ 10', () async {
    final c = await open(QaScenario.freeSecondary);
    expect(c.read(timeWindowChoiceProvider), TimeWindow.about10);
    final r = choose(c, Intention.moreEnergy);
    expect(r.activityId, ActivityId.gentleStretchPause);
    expect(r.personalReason, 'You found this useful before.');
  });

  test('J · V1 history: compatible counts, LEARNING_RESET does not', () async {
    final clearer = choose(
      await open(QaScenario.freeV1History),
      Intention.clearerHead,
    );
    expect(clearer.activityId, ActivityId.writeItDown);
    expect(clearer.personalReason, 'You found this useful before.');

    final energy = choose(
      await open(QaScenario.freeV1History),
      Intention.moreEnergy,
    );
    expect(
      energy.activityId == ActivityId.thirtyMinuteWalk &&
          energy.personalReason != null,
      isFalse,
    );
  });
}
