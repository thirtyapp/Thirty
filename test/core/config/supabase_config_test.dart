import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/config/supabase_config.dart';

void main() {
  group('SupabaseConfig.assertValid', () {
    test('throws when url is empty', () {
      const config = SupabaseConfig(url: '', publishableKey: 'key');

      expect(config.assertValid, throwsStateError);
    });

    test('throws when publishableKey is empty', () {
      const config = SupabaseConfig(
        url: 'https://example.supabase.co',
        publishableKey: '',
      );

      expect(config.assertValid, throwsStateError);
    });

    test('throws when both are empty', () {
      const config = SupabaseConfig(url: '', publishableKey: '');

      expect(config.assertValid, throwsStateError);
    });

    test('throws when url is whitespace-only', () {
      const config = SupabaseConfig(url: '   ', publishableKey: 'key');

      expect(config.assertValid, throwsStateError);
    });

    test('throws when publishableKey is whitespace-only', () {
      const config = SupabaseConfig(
        url: 'https://example.supabase.co',
        publishableKey: '   ',
      );

      expect(config.assertValid, throwsStateError);
    });

    test('does not throw when both are set', () {
      const config = SupabaseConfig(
        url: 'https://example.supabase.co',
        publishableKey: 'key',
      );

      expect(config.assertValid, returnsNormally);
    });
  });
}
