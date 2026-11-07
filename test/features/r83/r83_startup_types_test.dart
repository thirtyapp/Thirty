import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/analytics/analytics_consent.dart';
import 'package:thirty/core/analytics/tester_identity_provider.dart';
import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/reminder/reminder_gateway.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/v1_premium_retirement.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/premium/application/premium_offer_provider.dart';
import 'package:thirty/features/reminder/application/reminder_invitation_provider.dart';
import 'package:thirty/features/reminder/application/reminder_provider.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';

/// R8.3 — founder decision D5 (Claude O-2, architecture review §3): the
/// typed preference reads on the app's start-up path. A value of an
/// unexpected native type under one of these keys — a damaged or foreign
/// store — must never stop THIRTY from starting or from showing Today, and
/// is never replaced by a default written over it.
///
/// The start-up path, as traced in the source:
/// - `main()` awaits [retireV1Premium] before `runApp`;
/// - `main()` reads `reminderProvider.notifier` before `runApp`, which
///   builds the reminder state;
/// - `ThirtyApp` tracks `appOpened` on its first frame, through the
///   consent gate and, with consent, the tester identity;
/// - Today's first frame reads the First Breath date and the two
///   invitation flags.
void main() {
  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  ProviderContainer containerOn(SharedPreferences prefs) {
    final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('main(): the V1 retirement marker', () {
    for (final odd in <Object>['true', 1]) {
      test('stored as ${odd.runtimeType}: retirement completes, the V1 '
          'records go, the marker is kept as stored', () async {
        final prefs = await prefsWith({
          v1PremiumRetiredKey: odd,
          'plans_state_v1': '{}',
        });
        await retireV1Premium(prefs);
        expect(prefs.get('plans_state_v1'), isNull);
        expect(prefs.get(v1PremiumRetiredKey), odd);
      });
    }

    test('control — absent: retirement runs and records the marker', () async {
      final prefs = await prefsWith({'insight_snapshots_v1': '[]'});
      await retireV1Premium(prefs);
      expect(prefs.get('insight_snapshots_v1'), isNull);
      expect(prefs.get(v1PremiumRetiredKey), isTrue);
    });

    test('control — true: nothing runs', () async {
      final prefs = await prefsWith({
        v1PremiumRetiredKey: true,
        'plans_state_v1': '{}',
      });
      await retireV1Premium(prefs);
      expect(prefs.get('plans_state_v1'), '{}');
    });
  });

  group('main(): the reminder state', () {
    test('values of the wrong type read as the defaults, and stay stored',
        () async {
      final prefs = await prefsWith({
        reminderEnabledKey: 'yes',
        reminderHourKey: '7',
        reminderMinuteKey: true,
      });
      final c = containerOn(prefs);
      expect(() => c.read(reminderProvider.notifier), returnsNormally);
      final state = c.read(reminderProvider);
      expect(state.enabled, isFalse);
      expect(prefs.get(reminderEnabledKey), 'yes');
      expect(prefs.get(reminderHourKey), '7');
      expect(prefs.get(reminderMinuteKey), true);
    });

    test('a time the user sets is saved without writing the default over '
        'an enabled flag of the wrong type', () async {
      final prefs = await prefsWith({
        reminderEnabledKey: 'yes',
        reminderHourKey: 7,
        reminderMinuteKey: 0,
      });
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          reminderGatewayProvider.overrideWithValue(_QuietGateway()),
        ],
      );
      addTearDown(c.dispose);
      await c.read(reminderProvider.notifier).setTime(hour: 8, minute: 30);
      expect(prefs.get(reminderHourKey), 8);
      expect(prefs.get(reminderMinuteKey), 30);
      expect(prefs.get(reminderEnabledKey), 'yes');
    });

    test('control — values of the right type are read', () async {
      final prefs = await prefsWith({
        reminderEnabledKey: true,
        reminderHourKey: 7,
        reminderMinuteKey: 15,
      });
      final state = containerOn(prefs).read(reminderProvider);
      expect((state.enabled, state.hour, state.minute), (true, 7, 15));
    });
  });

  group('first frame: analytics, First Breath, invitations', () {
    test('analytics consent of the wrong type means no consent, kept as '
        'stored', () async {
      final prefs = await prefsWith({analyticsConsentKey: 'true'});
      expect(containerOn(prefs).read(analyticsConsentProvider), isFalse);
      expect(prefs.get(analyticsConsentKey), 'true');
    });

    test('a tester id or cohort of the wrong type is never written over',
        () async {
      final prefs = await prefsWith({
        analyticsTesterIdKey: 42,
        analyticsCohortKey: 7,
      });
      final identity = containerOn(prefs).read(testerIdentityProvider);
      expect(identity.testerId, isNotEmpty);
      await Future<void>.delayed(Duration.zero);
      expect(prefs.get(analyticsTesterIdKey), 42);
      expect(prefs.get(analyticsCohortKey), 7);
    });

    test('a First Breath date of the wrong type reads as not played today',
        () async {
      final prefs = await prefsWith({firstBreathLastPlayedDateKey: 20261030});
      expect(containerOn(prefs).read(firstBreathProvider), isTrue);
      expect(prefs.get(firstBreathLastPlayedDateKey), 20261030);
    });

    test('invitation flags of the wrong type never break Today, and are '
        'never written over', () async {
      final prefs = await prefsWith({
        premiumOfferInvitationShownKey: 'yes',
        reminderInvitationShownKey: 1,
      });
      final c = containerOn(prefs);
      expect(() => c.read(showReminderInvitationProvider), returnsNormally);
      expect(() => c.read(showPremiumOfferInvitationProvider), returnsNormally);
      expect(prefs.get(premiumOfferInvitationShownKey), 'yes');
    });

    final cases = <String, Map<String, Object>>{
      'analytics consent stored as text': {analyticsConsentKey: 'true'},
      'consent given, tester id and cohort stored as numbers': {
        analyticsConsentKey: true,
        analyticsTesterIdKey: 42,
        analyticsCohortKey: 7,
      },
      'First Breath date and invitation flags of the wrong type': {
        firstBreathLastPlayedDateKey: 20261030,
        premiumOfferInvitationShownKey: 'yes',
        reminderInvitationShownKey: 1,
      },
    };
    testWidgets('cold start with today\'s Circle on show and a First Breath '
        'date and invitation flags of the wrong type: THIRTY starts and shows '
        'Today', (tester) async {
      final prefs = await prefsWith({firstNamePromptSeenKey: true});
      final seed = containerOn(prefs);
      seed
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      expect(prefs.get(recommendationDayKey), isNotNull);
      await prefs.setInt(firstBreathLastPlayedDateKey, 20261030);
      await prefs.setString(premiumOfferInvitationShownKey, 'yes');
      await prefs.setInt(reminderInvitationShownKey, 1);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const ThirtyApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(prefs.get(premiumOfferInvitationShownKey), 'yes');
      expect(prefs.get(reminderInvitationShownKey), 1);
    });

    for (final MapEntry(key: name, value: values) in cases.entries) {
      testWidgets('cold start with $name: THIRTY starts and shows Today',
          (tester) async {
        final prefs = await prefsWith({firstNamePromptSeenKey: true, ...values});
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: const ThirtyApp(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        expect(find.byType(Scaffold), findsWidgets);
        for (final MapEntry(:key, :value) in values.entries) {
          expect(prefs.get(key), value, reason: '$key was written over');
        }
      });
    }
  });
}

/// A reminder gateway that schedules nothing and grants everything.
class _QuietGateway implements ReminderGateway {
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<bool> hasExactAlarmAccess() async => true;
  @override
  Future<void> requestExactAlarmAccess() async {}
  @override
  Future<ScheduleOutcome> scheduleDaily({
    required DateTime firstOccurrenceLocal,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async => ScheduleOutcome.scheduled;
  @override
  Future<void> cancel() async {}
}
