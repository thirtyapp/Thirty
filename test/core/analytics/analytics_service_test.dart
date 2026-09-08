import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/analytics/analytics_consent.dart';
import 'package:thirty/core/analytics/analytics_event_type.dart';
import 'package:thirty/core/analytics/analytics_service.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/providers/supabase_availability_provider.dart';

void main() {
  group('SupabaseAnalyticsService', () {
    Future<ProviderContainer> containerWithConsent() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      // Consent defaults to false, which would otherwise short-circuit
      // this call before it ever reaches SupabaseAnalyticsService itself
      // — opt in explicitly so these tests exercise it directly, not
      // ConsentGatedAnalyticsService's separate short-circuit (covered on
      // its own in analytics_consent_test.dart).
      container.read(analyticsConsentProvider.notifier).setConsent(true);
      return container;
    }

    test(
      'track() never throws, even when Supabase has not been initialized '
      '— a dropped analytics event must never affect the product '
      'experience (ADR-004)',
      () async {
        final container = await containerWithConsent();
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

    test(
      'unavailable telemetry is a safe no-op: with '
      'supabaseAvailableProvider at its default false, track() resolves '
      'without ever needing Supabase.instance to have been initialized — '
      'this is a deliberate skip, not a caught crash',
      () async {
        final container = await containerWithConsent();
        addTearDown(container.dispose);
        expect(container.read(supabaseAvailableProvider), isFalse);

        final service = container.read(analyticsServiceProvider);

        expect(
          () => service.track(AnalyticsEventType.appOpened),
          returnsNormally,
        );

        await Future<void>.delayed(Duration.zero);
      },
    );
  });
}
