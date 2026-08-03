import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/shared_preferences_provider.dart';

void main() {
  group('sharedPreferencesProvider', () {
    test('throws until it has been overridden', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Riverpod wraps the provider's build-time error in a
      // ProviderException, so assert on the message it carries rather than
      // the raw UnimplementedError type.
      expect(
        () => container.read(sharedPreferencesProvider),
        throwsA(
          isA<Object>().having(
            (e) => e.toString(),
            'message',
            contains('sharedPreferencesProvider must be overridden'),
          ),
        ),
      );
    });

    test('returns the overridden instance', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(sharedPreferencesProvider), prefs);
    });
  });
}
