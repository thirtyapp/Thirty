import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/config/supabase_config.dart';

void main() {
  group('SupabaseConfig.isConfigured', () {
    test('is false when both values are empty (the default, unset '
        'dart-define state under `flutter test`)', () {
      const config = SupabaseConfig(url: '', publishableKey: '');
      expect(config.isConfigured, isFalse);
    });

    test('is false when only the url is present', () {
      const config = SupabaseConfig(
        url: 'https://example.supabase.co',
        publishableKey: '',
      );
      expect(config.isConfigured, isFalse);
    });

    test('is false when only the publishableKey is present', () {
      const config = SupabaseConfig(url: '', publishableKey: 'key');
      expect(config.isConfigured, isFalse);
    });

    test('is false for whitespace-only values — never treated as '
        'present', () {
      const config = SupabaseConfig(url: '   ', publishableKey: '  \n');
      expect(config.isConfigured, isFalse);
    });

    test('is true only once both values are non-blank', () {
      const config = SupabaseConfig(
        url: 'https://example.supabase.co',
        publishableKey: 'key',
      );
      expect(config.isConfigured, isTrue);
    });

    test('fromEnvironment is unconfigured under flutter test — no real '
        'or placeholder identifier is ever compiled in', () {
      expect(SupabaseConfig.fromEnvironment.isConfigured, isFalse);
    });
  });
}
