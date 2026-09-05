import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/analytics/cohort.dart';
import 'package:thirty/core/analytics/tester_identity_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';

final _uuidV4Like = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

Future<ProviderContainer> _containerWith(
  Map<String, Object> storedPrefs,
) async {
  SharedPreferences.setMockInitialValues(storedPrefs);
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  return container;
}

void main() {
  group('testerIdentityProvider', () {
    test(
      'a device with no prior Circle/First Breath evidence is classified '
      'POST_FIX_BATCH_1 — this is its first-ever observed exposure',
      () async {
        final container = await _containerWith({});
        addTearDown(container.dispose);

        final identity = container.read(testerIdentityProvider);

        expect(identity.cohort, Cohort.postFixBatch1);
      },
    );

    test(
      'a device with pre-existing recommendation state is classified '
      'PRE_FIX — it already used THIRTY before Batch 1',
      () async {
        final container = await _containerWith({
          recommendationDayKey: '2026-08-01',
        });
        addTearDown(container.dispose);

        expect(container.read(testerIdentityProvider).cohort, Cohort.preFix);
      },
    );

    test(
      'a device with pre-existing First Breath state alone is also '
      'classified PRE_FIX',
      () async {
        final container = await _containerWith({
          firstBreathLastPlayedDateKey: '2026-08-01',
        });
        addTearDown(container.dispose);

        expect(container.read(testerIdentityProvider).cohort, Cohort.preFix);
      },
    );

    test('generates a stable, UUID-v4-shaped pseudonymous tester id', () async {
      final container = await _containerWith({});
      addTearDown(container.dispose);

      final identity = container.read(testerIdentityProvider);

      expect(identity.testerId, matches(_uuidV4Like));
    });

    test('persists the tester id so a fresh container restores the same '
        'one', () async {
      final container1 = await _containerWith({});
      final firstId = container1.read(testerIdentityProvider).testerId;
      final prefs = container1.read(sharedPreferencesProvider);
      container1.dispose();

      final container2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container2.dispose);

      expect(container2.read(testerIdentityProvider).testerId, firstId);
    });

    test(
      'once a cohort is persisted, it is never re-derived — a later app '
      'update (new prior-usage evidence appearing) does not silently '
      'convert an already-classified tester',
      () async {
        final container1 = await _containerWith({});
        final identity1 = container1.read(testerIdentityProvider);
        expect(identity1.cohort, Cohort.postFixBatch1);
        final prefs = container1.read(sharedPreferencesProvider);
        container1.dispose();

        // Simulate this same device later accumulating ordinary usage
        // evidence (it used the app normally after Batch 1) — cohort must
        // stay exactly what it was first classified as.
        await prefs.setString(recommendationDayKey, '2026-08-05');

        final container2 = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container2.dispose);

        final identity2 = container2.read(testerIdentityProvider);
        expect(identity2.cohort, Cohort.postFixBatch1);
        expect(identity2.testerId, identity1.testerId);
      },
    );
  });
}
