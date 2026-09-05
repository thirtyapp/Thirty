import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/analytics/analytics_event_type.dart';
import 'package:thirty/core/analytics/analytics_service.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';

void main() {
  group('SupabaseAnalyticsService', () {
    test(
      'track() never throws, even when Supabase has not been initialized '
      '— a dropped analytics event must never affect the product '
      'experience (ADR-004)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        final service = container.read(analyticsServiceProvider);

        expect(
          () => service.track(AnalyticsEventType.appOpened),
          returnsNormally,
        );

        // Give the fire-and-forget internal Future a chance to run and
        // swallow its own failure — an uncaught rejection here would
        // otherwise surface as a test failure via Zone error reporting.
        await Future<void>.delayed(Duration.zero);
      },
    );
  });
}
