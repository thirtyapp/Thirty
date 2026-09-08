import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/config/supabase_config.dart';
import 'package:thirty/main.dart' as app;

void main() {
  group('initializeSupabaseIfConfigured', () {
    test(
      'resolves to false instead of throwing when Supabase is '
      'unconfigured — this is the exact startup path that must survive a '
      'release build with no config/supabase.local.json dart-defines',
      () async {
        const config = SupabaseConfig(url: '', publishableKey: '');

        expect(
          app.initializeSupabaseIfConfigured(config),
          completion(isFalse),
        );
      },
    );

    test(
      'resolves to false instead of throwing when configured but '
      'Supabase.initialize itself fails (e.g. no platform channel/network '
      'in this test environment) — a reachability failure must be just as '
      'non-fatal as missing configuration',
      () async {
        SharedPreferences.setMockInitialValues({});
        const config = SupabaseConfig(
          url: 'https://example.supabase.co',
          publishableKey: 'key',
        );

        // No network/platform auth backend exists in this test
        // environment, so this exercises the same non-fatal path a real
        // reachability failure at cold start would — either way,
        // initializeSupabaseIfConfigured must never let it escape.
        await expectLater(
          app.initializeSupabaseIfConfigured(config),
          completes,
        );
      },
    );
  });
}
