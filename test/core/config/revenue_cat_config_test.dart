import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/config/revenue_cat_config.dart';

void main() {
  group('RevenueCatConfig.isConfigured', () {
    test('is false when both values are empty (the default, unset '
        'dart-define state under `flutter test`)', () {
      const config = RevenueCatConfig(androidApiKey: '', entitlementId: '');
      expect(config.isConfigured, isFalse);
    });

    test('is false when only the API key is present', () {
      const config = RevenueCatConfig(
        androidApiKey: 'goog_example',
        entitlementId: '',
      );
      expect(config.isConfigured, isFalse);
    });

    test('is false when only the entitlement id is present', () {
      const config = RevenueCatConfig(
        androidApiKey: '',
        entitlementId: 'premium',
      );
      expect(config.isConfigured, isFalse);
    });

    test('is false for whitespace-only values — never treated as '
        'present', () {
      const config = RevenueCatConfig(
        androidApiKey: '   ',
        entitlementId: '  \n',
      );
      expect(config.isConfigured, isFalse);
    });

    test('is true only once both values are non-blank', () {
      const config = RevenueCatConfig(
        androidApiKey: 'goog_example',
        entitlementId: 'premium',
      );
      expect(config.isConfigured, isTrue);
    });

    test('fromEnvironment is unconfigured under flutter test — no real '
        'or placeholder identifier is ever compiled in', () {
      expect(RevenueCatConfig.fromEnvironment.isConfigured, isFalse);
    });
  });

  group('RevenueCatConfig.releaseProblems', () {
    test('real-looking Google Play values are release-ready', () {
      const config = RevenueCatConfig(
        androidApiKey: 'goog_AbC123',
        entitlementId: 'premium',
      );
      expect(config.releaseProblems(), isEmpty);
    });

    test('missing or blank values block a release, each named', () {
      for (final config in const [
        RevenueCatConfig(androidApiKey: '', entitlementId: ''),
        RevenueCatConfig(androidApiKey: '  ', entitlementId: '\t'),
      ]) {
        expect(config.releaseProblems(), [
          'REVENUECAT_ANDROID_API_KEY is missing.',
          'REVENUECAT_ENTITLEMENT_ID is missing.',
        ]);
      }
    });

    test('the example-file placeholders block a release', () {
      const config = RevenueCatConfig(
        androidApiKey: RevenueCatConfig.exampleAndroidApiKey,
        entitlementId: RevenueCatConfig.exampleEntitlementId,
      );
      expect(config.releaseProblems(), [
        'REVENUECAT_ANDROID_API_KEY is still the example placeholder.',
        'REVENUECAT_ENTITLEMENT_ID is still the example placeholder.',
      ]);
    });

    test('a key that is not a Google Play public SDK key (Test Store, '
        'Amazon, a secret key) blocks a release', () {
      for (final key in ['test_AbC123', 'amzn_AbC123', 'sk_AbC123']) {
        final config = RevenueCatConfig(
          androidApiKey: key,
          entitlementId: 'premium',
        );
        expect(config.releaseProblems(), hasLength(1), reason: key);
        expect(config.releaseProblems().single, contains('goog_'));
      }
    });

    test('problems name the setting but never echo its value', () {
      const config = RevenueCatConfig(
        androidApiKey: 'sk_SECRETVALUE',
        entitlementId: '',
      );
      expect(config.releaseProblems().join(), isNot(contains('SECRETVALUE')));
    });

    test('is stricter than isConfigured, which keeps its runtime meaning — '
        'debug may still run with Test Store values', () {
      const config = RevenueCatConfig(
        androidApiKey: 'test_AbC123',
        entitlementId: 'premium',
      );
      expect(config.isConfigured, isTrue);
      expect(config.releaseProblems(), isNotEmpty);
    });

    test('the example placeholders match config/revenuecat.example.json', () {
      final example = File('config/revenuecat.example.json').readAsStringSync();
      expect(example, contains(RevenueCatConfig.exampleAndroidApiKey));
      expect(example, contains(RevenueCatConfig.exampleEntitlementId));
    });
  });
}
