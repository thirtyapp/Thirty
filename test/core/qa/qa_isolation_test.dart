import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/analytics/analytics_consent.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/theme_mode_provider.dart';
import 'package:thirty/core/qa/qa_container.dart';
import 'package:thirty/core/qa/qa_entitlement_gateway.dart';
import 'package:thirty/core/qa/qa_scenario.dart';
import 'package:thirty/core/qa/qa_shared_preferences.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/plans/application/plan_provider.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';

/// QA-1 — synthetic history lives only in its own store: the genuine store
/// is never written, the two never merge, and reset is simply the genuine
/// store again, untouched.
void main() {
  final reference = DateTime(2026, 10, 8, 10);
  late SharedPreferences genuine;
  late Map<String, Object?> genuineBefore;

  Map<String, Object?> valuesOf(SharedPreferences prefs) => {
    for (final key in prefs.getKeys()) key: prefs.get(key),
  };

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      themeModeKey: 'dark',
      firstNameKey: 'Thomas',
      firstNamePromptSeenKey: true,
      analyticsConsentKey: true,
    });
    genuine = await SharedPreferences.getInstance();
    // A genuine user's own Circle, written by the real repository.
    await CircleJournalRepository(genuine).recordClosed(
      circleId: '2026-05-01',
      localDate: '2026-05-01',
      direction: Intention.clearerHead,
      activityId: activityPools[Intention.clearerHead]!.first,
      closedAt: DateTime(2026, 5, 1, 18),
    );
    genuineBefore = valuesOf(genuine);
  });

  /// Drives a whole Circle — choose, start, close, reflect — inside a QA
  /// app container over [store].
  Future<void> walkCircleIn(QaSharedPreferences store) async {
    final container = ProviderContainer(
      overrides: [
        ...qaContainerOverrides(
          genuinePreferences: genuine,
          supabaseAvailable: false,
          session: QaSession(
            entitlement: QaEntitlement.active,
            scenario: QaScenario.planInProgress,
            store: store,
          ),
        ),
        nowProvider.overrideWithValue(reference),
      ],
    );
    addTearDown(container.dispose);
    await container.read(entitlementStatusProvider.notifier).initialize();
    final circle = container.read(recommendationProvider.notifier);
    circle.chooseIntention(Intention.moreEnergy);
    circle.start();
    circle.close();
    circle.reportAttempt(CircleAttemptResponse.yes);
    container.read(planProvider.notifier).activatePlan(PlanId.gentlerPacePath);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('building any scenario never writes to the genuine store', () async {
    for (final scenario in QaScenario.values) {
      await buildQaStore(
        scenario: scenario,
        genuine: genuine,
        referenceNow: reference,
      );
      expect(valuesOf(genuine), genuineBefore, reason: scenario.wireName);
    }
  });

  test('synthetic scenarios never contain genuine history — only the '
      'carried appearance and name preferences', () async {
    for (final scenario in QaScenario.values.where(
      (s) => s != QaScenario.none,
    )) {
      final store = await buildQaStore(
        scenario: scenario,
        genuine: genuine,
        referenceNow: reference,
      );
      final journal = CircleJournalRepository(store).readAll();
      expect(
        journal.map((e) => e.localDate),
        isNot(contains('2026-05-01')),
        reason: scenario.wireName,
      );
      expect(store.getString(themeModeKey), 'dark');
      expect(store.getString(firstNameKey), 'Thomas');
      expect(store.containsKey(analyticsConsentKey), isFalse);
    }
  });

  test('a whole Circle walked inside a QA session lands in the QA store '
      'only', () async {
    final store = await buildQaStore(
      scenario: QaScenario.planInProgress,
      genuine: genuine,
      referenceNow: reference,
    );
    final qaJournalBefore = CircleJournalRepository(store).readAll().length;

    await walkCircleIn(store);

    expect(
      CircleJournalRepository(store).readAll(),
      hasLength(qaJournalBefore + 1),
    );
    expect(valuesOf(genuine), genuineBefore);
  });

  test('the sandboxed real-data session starts from a copy of the genuine '
      'history, and its writes stay in the copy', () async {
    final store = await buildQaStore(
      scenario: QaScenario.none,
      genuine: genuine,
      referenceNow: reference,
    );
    expect(CircleJournalRepository(store).readAll().map((e) => e.localDate), [
      '2026-05-01',
    ]);

    await walkCircleIn(store);

    expect(CircleJournalRepository(store).readAll(), hasLength(2));
    expect(valuesOf(genuine), genuineBefore);
  });

  test('reset returns the genuine state exactly as it was', () async {
    final store = await buildQaStore(
      scenario: QaScenario.monthTwo,
      genuine: genuine,
      referenceNow: reference,
    );
    await walkCircleIn(store);

    final reset = ProviderContainer(
      overrides: qaContainerOverrides(
        genuinePreferences: genuine,
        supabaseAvailable: false,
      ),
    );
    addTearDown(reset.dispose);

    expect(
      reset
          .read(circleJournalRepositoryProvider)
          .readAll()
          .map((e) => e.localDate),
      ['2026-05-01'],
    );
    expect(reset.read(planProvider).activePlanId, isNull);
    expect(valuesOf(genuine), genuineBefore);
  });
}
