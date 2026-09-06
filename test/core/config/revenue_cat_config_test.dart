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
}
