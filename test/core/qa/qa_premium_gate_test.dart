import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/analytics/analytics_service.dart';
import 'package:thirty/core/premium/entitlement_gateway.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/qa/qa_container.dart';
import 'package:thirty/core/qa/qa_entitlement_gateway.dart';
import 'package:thirty/core/qa/qa_inert_services.dart';
import 'package:thirty/core/qa/qa_premium_gate.dart';
import 'package:thirty/core/qa/qa_scenario.dart';
import 'package:thirty/core/qa/qa_shared_preferences.dart';
import 'package:thirty/core/reminder/reminder_gateway.dart';

/// QA-1 — activation safety: the harness exists only in a debug build
/// launched with THIRTY_QA_PREMIUM=true, and outside an applied QA session
/// the app container is exactly production's.
void main() {
  group('qaPremiumHarnessAllowed', () {
    test('a release or profile build (kDebugMode false) can never enable '
        'the harness, with or without the flag', () {
      expect(
        qaPremiumHarnessAllowed(debugMode: false, flagEnabled: true),
        isFalse,
      );
      expect(
        qaPremiumHarnessAllowed(debugMode: false, flagEnabled: false),
        isFalse,
      );
    });

    test('a debug build without the flag stays on the normal path', () {
      expect(
        qaPremiumHarnessAllowed(debugMode: true, flagEnabled: false),
        isFalse,
      );
    });

    test('only a debug build with the flag enables the harness', () {
      expect(
        qaPremiumHarnessAllowed(debugMode: true, flagEnabled: true),
        isTrue,
      );
    });

    test('the compile-time gate is off when THIRTY_QA_PREMIUM is not '
        'defined, as in this test run', () {
      expect(qaPremiumFlag, isFalse);
      expect(kQaPremiumHarnessEnabled, isFalse);
    });
  });

  group('qaContainerOverrides', () {
    late SharedPreferences genuine;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      genuine = await SharedPreferences.getInstance();
    });

    test('with no QA session the container is production\'s: the genuine '
        'store, the unchanged gateway selection, real analytics', () {
      final container = ProviderContainer(
        overrides: qaContainerOverrides(
          genuinePreferences: genuine,
          supabaseAvailable: false,
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(sharedPreferencesProvider), same(genuine));
      // RevenueCat is unconfigured under `flutter test`, so production
      // selection resolves to the unavailable gateway — never the QA one.
      expect(
        container.read(entitlementGatewayProvider),
        isA<UnavailableEntitlementGateway>(),
      );
      expect(
        container.read(analyticsServiceProvider),
        isA<ConsentGatedAnalyticsService>(),
      );
    });

    test('with a QA session every substitution happens together: isolated '
        'store, QA gateway, silent analytics, inert reminders', () {
      final store = QaSharedPreferences();
      final container = ProviderContainer(
        overrides: qaContainerOverrides(
          genuinePreferences: genuine,
          supabaseAvailable: true,
          session: QaSession(
            entitlement: QaEntitlement.active,
            scenario: QaScenario.newUser,
            store: store,
          ),
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(sharedPreferencesProvider), same(store));
      expect(
        container.read(entitlementGatewayProvider),
        isA<QaEntitlementGateway>(),
      );
      expect(
        container.read(analyticsServiceProvider),
        isA<QaSilentAnalyticsService>(),
      );
      expect(
        container.read(reminderGatewayProvider),
        isA<QaInertReminderGateway>(),
      );
    });
  });

  test('outside lib/core/qa, only main.dart references the QA harness — '
      'no QA branches spread through production feature code', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.startsWith('lib/core/qa/') || path == 'lib/main.dart') {
        continue;
      }
      if (entity.readAsStringSync().contains('/qa/')) offenders.add(path);
    }
    // ThirtyApp's optional `builder` names the harness only in a doc
    // comment; it has no QA import.
    expect(offenders, ['lib/core/app/thirty_app.dart']);
    expect(
      File('lib/core/app/thirty_app.dart').readAsStringSync(),
      isNot(contains("import '../qa/")),
    );
  });
}
