import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/widgets/action_report_prompt.dart';
import 'package:thirty/features/premium/application/premium_offer_provider.dart';
import 'package:thirty/features/reminder/application/reminder_invitation_provider.dart';

void main() {
  Future<ProviderContainer> containerWith({
    bool entitled = false,
    Map<String, Object> extraPrefs = const {},
  }) async {
    // Pre-mark the reminder invitation as already shown by default — these
    // tests exercise Premium-invitation eligibility specifically; the
    // reminder-invitation/Premium-invitation interaction itself has its
    // own dedicated test below.
    SharedPreferences.setMockInitialValues({
      reminderInvitationShownKey: true,
      ...extraPrefs,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        premiumEntitlementProvider.overrideWithValue(entitled),
        nowProvider.overrideWithValue(DateTime(2026, 9, 2)),
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

    test(
      'never true while a reflection question is pending — prompt-priority '
      'rule (parent §28): reflection first, Premium invitation waits until '
      'neither is being presented',
      () async {
        final container = await containerWith(
          extraPrefs: {
            recommendationDayKey: '2026-09-02',
            recommendationIntentionKey: 'moreEnergy',
            recommendationActivityIdKey: 'thirtyMinuteWalk',
            recommendationStatusKey: 'closed',
            recommendationStartedAtKey: DateTime(
              2026,
              9,
              2,
            ).toIso8601String(),
            recommendationClosedAtKey: DateTime(2026, 9, 2).toIso8601String(),
          },
        );
        addTearDown(container.dispose);
        await closeOneCircle(container, '2026-09-01');
        await closeOneCircle(container, '2026-09-02');

        expect(container.read(reflectionPendingProvider), isTrue);
        expect(container.read(showPremiumOfferInvitationProvider), isFalse);
      },
    );

    test(
      'becomes true once the pending reflection is answered, still on the '
      'same visit',
      () async {
        final container = await containerWith(
          extraPrefs: {
            recommendationDayKey: '2026-09-02',
            recommendationIntentionKey: 'moreEnergy',
            recommendationActivityIdKey: 'thirtyMinuteWalk',
            recommendationStatusKey: 'closed',
            recommendationStartedAtKey: DateTime(
              2026,
              9,
              2,
            ).toIso8601String(),
            recommendationClosedAtKey: DateTime(2026, 9, 2).toIso8601String(),
          },
        );
        addTearDown(container.dispose);
        await closeOneCircle(container, '2026-09-01');
        await closeOneCircle(container, '2026-09-02');
        expect(container.read(showPremiumOfferInvitationProvider), isFalse);

        container
            .read(recommendationProvider.notifier)
            .reportAttempt(CircleAttemptResponse.notToday);

        expect(container.read(reflectionPendingProvider), isFalse);
        expect(container.read(showPremiumOfferInvitationProvider), isTrue);
      },
    );

    test(
      'never true while the reminder invitation is currently eligible — '
      'prompt-priority rule (parent §28): reminder invitation before '
      'Premium invitation',
      () async {
        final container = await containerWith(
          extraPrefs: {reminderInvitationShownKey: false},
        );
        addTearDown(container.dispose);
        await closeOneCircle(container, '2026-09-01');
        await closeOneCircle(container, '2026-09-02');

        expect(container.read(showReminderInvitationProvider), isTrue);
        expect(container.read(showPremiumOfferInvitationProvider), isFalse);
      },
    );
  });
}
