import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/premium/premium_access.dart';

void main() {
  group('premiumEntitlementProvider (Batch 2A access seam)', () {
    test('defaults to unentitled — no production build ever falsely '
        'grants Premium access', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(premiumEntitlementProvider), isFalse);
    });

    test('can be overridden for tests/dev via dependency injection', () {
      final container = ProviderContainer(
        overrides: [premiumEntitlementProvider.overrideWithValue(true)],
      );
      addTearDown(container.dispose);

      expect(container.read(premiumEntitlementProvider), isTrue);
    });
  });
}
