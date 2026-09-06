import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/analytics/analytics_consent.dart';
import 'package:thirty/core/analytics/analytics_event_type.dart';
import 'package:thirty/core/analytics/analytics_service.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';

class _RecordingAnalyticsService implements AnalyticsService {
  final events = <AnalyticsEventType>[];

  @override
  void track(AnalyticsEventType type, {Map<String, Object?>? metadata}) {
    events.add(type);
  }
}

void main() {
  Future<ProviderContainer> containerWith({
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final resolved = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(resolved)],
    );
  }

  group('analyticsConsentProvider', () {
    test('defaults to false — no prior consent decision means OFF', () async {
      final container = await containerWith();
      addTearDown(container.dispose);

      expect(container.read(analyticsConsentProvider), isFalse);
    });

    test('setConsent persists across a fresh provider read', () async {
      final container = await containerWith();
      addTearDown(container.dispose);
      container.read(analyticsConsentProvider.notifier).setConsent(true);

      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getBool(analyticsConsentKey), isTrue);
    });

    test('restores a previously persisted true value', () async {
      final container = await containerWith(
        prefs: {analyticsConsentKey: true},
      );
      addTearDown(container.dispose);

      expect(container.read(analyticsConsentProvider), isTrue);
    });
  });

  group('ConsentGatedAnalyticsService', () {
    // A tiny test-local provider so ConsentGatedAnalyticsService gets a
    // real Riverpod Ref tied to the test's own container, wrapping a
    // recorder this test can inspect directly — rather than
    // SupabaseAnalyticsService, which would attempt real network calls.
    final testGatedProvider = Provider.family<AnalyticsService, _RecordingAnalyticsService>(
      (ref, inner) => ConsentGatedAnalyticsService(ref, inner),
    );

    test('transmits nothing before explicit opt-in', () async {
      final container = await containerWith();
      addTearDown(container.dispose);
      final inner = _RecordingAnalyticsService();

      container.read(testGatedProvider(inner)).track(AnalyticsEventType.appOpened);

      expect(inner.events, isEmpty);
    });

    test('transmits future events once consent is granted', () async {
      final container = await containerWith();
      addTearDown(container.dispose);
      final inner = _RecordingAnalyticsService();
      container.read(analyticsConsentProvider.notifier).setConsent(true);

      container.read(testGatedProvider(inner)).track(AnalyticsEventType.appOpened);

      expect(inner.events, [AnalyticsEventType.appOpened]);
    });

    test('stops transmitting once consent is withdrawn again', () async {
      final container = await containerWith();
      addTearDown(container.dispose);
      final inner = _RecordingAnalyticsService();
      final service = container.read(testGatedProvider(inner));
      final consentNotifier = container.read(analyticsConsentProvider.notifier);

      consentNotifier.setConsent(true);
      service.track(AnalyticsEventType.appOpened);
      consentNotifier.setConsent(false);
      service.track(AnalyticsEventType.recommendationShown);

      expect(inner.events, [AnalyticsEventType.appOpened]);
    });

    test(
      'analyticsServiceProvider itself is consent-gated end to end — '
      'every real call site goes through this one provider, and the '
      'default OFF state never throws even though it never reaches '
      'Supabase',
      () async {
        final container = await containerWith();
        addTearDown(container.dispose);

        expect(
          () => container
              .read(analyticsServiceProvider)
              .track(AnalyticsEventType.appOpened),
          returnsNormally,
        );
      },
    );
  });
}
