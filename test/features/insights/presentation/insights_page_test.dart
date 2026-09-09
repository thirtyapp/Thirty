import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/insights/application/insight_provider.dart';
import 'package:thirty/features/insights/presentation/insights_page.dart';
import 'package:thirty/features/insights/presentation/widgets/insight_card.dart';
import 'package:thirty/features/plans/application/plan_provider.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';

final _today = DateTime(2026, 8, 2);

/// `entitled` defaults to `true`, matching `plan_path_page_test.dart`'s own
/// convention — this still hosts a plain `MaterialApp` (no `GoRouter`);
/// real `/insights` → `/premium`/`/settings` navigation is covered
/// separately in `app_router_test.dart` against the real app.
Future<(Widget, ProviderContainer)> _wrap({bool entitled = true}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_today),
      eventClockProvider.overrideWithValue(() => _today),
      premiumEntitlementProvider.overrideWithValue(entitled),
    ],
  );
  final widget = UncontrolledProviderScope(
    container: container,
    child: MaterialApp(theme: AppTheme.light, home: const InsightsPage()),
  );
  return (widget, container);
}

void main() {
  group('Batch B — Insights destination hosts InsightCard', () {
    testWidgets(
      'renders the InsightCard, moved here from Plans, once an eligible '
      'Insight exists',
      (tester) async {
        final (widget, container) = await _wrap();
        addTearDown(container.dispose);
        final notifier = container.read(planProvider.notifier);
        notifier.activatePlan(PlanId.gentlerPacePath);
        notifier.advanceCursorForCircle(
          PlanId.gentlerPacePath,
          'circle-0',
          isRevisit: false,
        );
        notifier.activatePlan(PlanId.moreEnergyPath);

        await tester.pumpWidget(widget);
        await tester.pump();

        expect(find.byType(InsightCard), findsOneWidget);
      },
    );

    testWidgets(
      'opening the page assesses a current Insight when eligible evidence '
      'already exists',
      (tester) async {
        final (widget, container) = await _wrap();
        addTearDown(container.dispose);
        final notifier = container.read(planProvider.notifier);
        notifier.activatePlan(PlanId.gentlerPacePath);
        notifier.advanceCursorForCircle(
          PlanId.gentlerPacePath,
          'circle-0',
          isRevisit: false,
        );
        notifier.activatePlan(PlanId.moreEnergyPath);
        expect(container.read(insightProvider).lastAssessedAt, isNull);

        await tester.pumpWidget(widget);
        await tester.pump();

        expect(container.read(insightProvider).lastAssessedAt, isNotNull);
        expect(find.textContaining('Gentler Pace'), findsOneWidget);
      },
    );

    testWidgets(
      'opening the destination while unentitled never triggers a new '
      'assessment — refreshIfDue\'s own entitlement guard (Batch A) still '
      'applies at its new call site',
      (tester) async {
        final (widget, container) = await _wrap(entitled: false);
        addTearDown(container.dispose);

        await tester.pumpWidget(widget);
        await tester.pump();

        // If the entitlement guard were missing, `refreshIfDue()` would
        // have advanced `lastAssessedAt` to `_today` regardless of whether
        // any candidate Insight was found (see `insight_provider.dart`).
        expect(container.read(insightProvider).lastAssessedAt, isNull);
      },
    );
  });

  group('Batch B — minimal truthful empty state (no fabricated content)', () {
    testWidgets(
      'entitled with no eligible evidence yet shows a plain waiting '
      'message and no Premium CTA',
      (tester) async {
        final (widget, container) = await _wrap();
        addTearDown(container.dispose);

        await tester.pumpWidget(widget);

        expect(
          find.textContaining('Insights turns your recorded choices'),
          findsOneWidget,
        );
        expect(find.text('Open Premium'), findsNothing);
      },
    );

    testWidgets(
      'unentitled with no retained snapshot shows the calm Free preview '
      'and an Open Premium CTA',
      (tester) async {
        final (widget, container) = await _wrap(entitled: false);
        addTearDown(container.dispose);

        await tester.pumpWidget(widget);

        expect(
          find.textContaining('Insights turns your recorded choices'),
          findsOneWidget,
        );
        expect(find.text('Open Premium'), findsOneWidget);
      },
    );
  });
}
