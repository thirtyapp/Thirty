import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/analytics/analytics_event_type.dart';
import 'package:thirty/core/analytics/analytics_service.dart';
import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';

/// Records every [track] call instead of reaching Supabase.
class _RecordingAnalyticsService implements AnalyticsService {
  final List<AnalyticsEventType> events = [];

  @override
  void track(AnalyticsEventType type, {Map<String, Object?>? metadata}) {
    events.add(type);
  }
}

/// A mutable stand-in for "the real current time" — `nowProvider` is
/// overridden with a function reading [value], so advancing it and then
/// invalidating `nowProvider` simulates a calendar day actually passing
/// between two reads, the same way a real device's clock would.
class _MutableClock {
  _MutableClock(this.value);
  DateTime value;
}

void main() {
  group('ThirtyApp — Batch 1 daily-reset legibility + app-open '
      'instrumentation (Phase D/E)', () {
    testWidgets('fires an appOpened event on cold start', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final analytics = _RecordingAnalyticsService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            analyticsServiceProvider.overrideWithValue(analytics),
          ],
          child: const ThirtyApp(),
        ),
      );
      await tester.pump();

      expect(analytics.events, [AnalyticsEventType.appOpened]);
    });

    testWidgets('fires another appOpened event on every foreground resume', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final analytics = _RecordingAnalyticsService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            analyticsServiceProvider.overrideWithValue(analytics),
          ],
          child: const ThirtyApp(),
        ),
      );
      await tester.pump();
      expect(analytics.events, [AnalyticsEventType.appOpened]);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pump();

      expect(analytics.events, [
        AnalyticsEventType.appOpened,
        AnalyticsEventType.appOpened,
      ]);
    });

    testWidgets(
      'a stale Circle/day state left over from before local midnight is '
      're-evaluated the moment the app resumes, correctly clearing to a '
      'fresh day',
      (WidgetTester tester) async {
        final clock = _MutableClock(DateTime(2026, 8, 1, 9));
        SharedPreferences.setMockInitialValues({
          recommendationDayKey: '2026-08-01',
          recommendationIntentionKey: 'moreEnergy',
          recommendationActivityIdKey: 'thirtyMinuteWalk',
          recommendationStatusKey: 'closed',
          recommendationStartedAtKey: DateTime(
            2026,
            8,
            1,
            9,
          ).toIso8601String(),
          recommendationClosedAtKey: DateTime(
            2026,
            8,
            1,
            10,
          ).toIso8601String(),
        });
        final prefs = await SharedPreferences.getInstance();

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            nowProvider.overrideWith((ref) => clock.value),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const ThirtyApp(),
          ),
        );
        await tester.pump();

        // An app instance kept alive across local midnight stays on
        // yesterday's stale state until something re-evaluates it — see
        // recommendationProvider's own "Known limitation" doc comment.
        expect(
          container.read(recommendationProvider).status,
          RecommendationStatus.closed,
        );

        // The calendar day actually passes, then the app resumes — the
        // real-world path this fix targets (backgrounded overnight,
        // reopened the next day without being fully killed).
        clock.value = DateTime(2026, 8, 2, 8);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();

        final state = container.read(recommendationProvider);
        expect(state.recommendation, isNull);
        expect(state.status, RecommendationStatus.notStarted);
      },
    );
  });
}
