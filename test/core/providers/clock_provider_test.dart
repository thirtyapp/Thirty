import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/providers/clock_provider.dart';

void main() {
  group('nowProvider', () {
    test('returns the current moment by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final before = DateTime.now();
      final value = container.read(nowProvider);
      final after = DateTime.now();

      expect(
        value.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(value.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('can be overridden for deterministic date-dependent logic', () {
      final fixed = DateTime(2026, 8, 2);
      final container = ProviderContainer(
        overrides: [nowProvider.overrideWithValue(fixed)],
      );
      addTearDown(container.dispose);

      expect(container.read(nowProvider), fixed);
    });
  });
}
