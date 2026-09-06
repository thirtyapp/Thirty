import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/premium/application/premium_offer_provider.dart';

void main() {
  Future<ProviderContainer> containerWith({bool entitled = false}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        premiumEntitlementProvider.overrideWithValue(entitled),
      ],
    );
    return container;
  }

  Future<void> closeOneCircle(ProviderContainer container, String date) {
    final journal = container.read(circleJournalRepositoryProvider);
    final circleId = 'circle_$date';
    return journal
        .recordShown(
          circleId: circleId,
          localDate: date,
          direction: Intention.moreEnergy,
          activityId: ActivityId.thirtyMinuteWalk,
          shownAt: DateTime.parse('${date}T08:00:00'),
        )
        .then(
          (_) => journal.recordClosed(
            circleId: circleId,
            localDate: date,
            direction: Intention.moreEnergy,
            activityId: ActivityId.thirtyMinuteWalk,
            closedAt: DateTime.parse('${date}T08:30:00'),
          ),
        );
  }

  group('showPremiumOfferInvitationProvider', () {
    test('false with zero closed Circles', () async {
      final container = await containerWith();
      addTearDown(container.dispose);

      expect(container.read(showPremiumOfferInvitationProvider), isFalse);
    });

    test('false with only one closed Circle on one distinct date', () async {
      final container = await containerWith();
      addTearDown(container.dispose);
      await closeOneCircle(container, '2026-09-01');

      expect(container.read(showPremiumOfferInvitationProvider), isFalse);
    });

    test('true once a second closed Circle lands on a distinct date', () async {
      final container = await containerWith();
      addTearDown(container.dispose);
      await closeOneCircle(container, '2026-09-01');
      await closeOneCircle(container, '2026-09-02');

      expect(container.read(showPremiumOfferInvitationProvider), isTrue);
    });

    test('never true while already entitled', () async {
      final container = await containerWith(entitled: true);
      addTearDown(container.dispose);
      await closeOneCircle(container, '2026-09-01');
      await closeOneCircle(container, '2026-09-02');

      expect(container.read(showPremiumOfferInvitationProvider), isFalse);
    });

    test('never true once already marked shown, even if still eligible', () async {
      final container = await containerWith();
      addTearDown(container.dispose);
      await closeOneCircle(container, '2026-09-01');
      await closeOneCircle(container, '2026-09-02');
      await container
          .read(sharedPreferencesProvider)
          .setBool(premiumOfferInvitationShownKey, true);

      expect(container.read(showPremiumOfferInvitationProvider), isFalse);
    });
  });
}
