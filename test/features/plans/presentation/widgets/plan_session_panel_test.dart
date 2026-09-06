import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/plans/domain/plan_catalog.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/plans/presentation/widgets/plan_session_panel.dart';

final _today = DateTime(2026, 8, 2);
final _firstStage = planDefinitionFor(PlanId.moreEnergyPath).stages.first;

Map<String, Object> _planResolvedToday({String? treatment = 'standard'}) {
  final prefs = <String, Object>{
    recommendationDayKey: '2026-08-02',
    recommendationIntentionKey: 'moreEnergy',
    recommendationActivityIdKey: _firstStage.activityId.name,
    recommendationPlanIdKey: PlanId.moreEnergyPath.name,
    recommendationStageIdKey: _firstStage.id,
    recommendationPlanCycleIdKey: 'moreEnergyPath_cycle_1',
    recommendationPlanVersionKey: planContentVersion,
    recommendationIsPlanRevisitKey: false,
  };
  if (treatment != null) prefs[recommendationTreatmentKey] = treatment;
  return prefs;
}

Future<(Widget, ProviderContainer)> _wrap(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final resolved = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(resolved),
      nowProvider.overrideWithValue(_today),
    ],
  );
  final widget = UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: PlanSessionPanel()),
    ),
  );
  return (widget, container);
}

void main() {
  testWidgets('renders nothing for a Free-selector-resolved Circle', (
    tester,
  ) async {
    final (widget, container) = await _wrap({
      recommendationDayKey: '2026-08-02',
      recommendationIntentionKey: 'moreEnergy',
      recommendationActivityIdKey: 'thirtyMinuteWalk',
    });
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    expect(find.byType(PlanSessionPanel), findsOneWidget);
    expect(find.text('More Energy Path'), findsNothing);
  });

  testWidgets('shows the Plan name, stage position, purpose and rationale',
      (tester) async {
    final (widget, container) = await _wrap(_planResolvedToday());
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    expect(find.text('More Energy Path'), findsOneWidget);
    expect(find.text('Stage 1 of 5'), findsOneWidget);
    expect(find.text(_firstStage.purpose), findsOneWidget);
    expect(find.text(_firstStage.rationale), findsOneWidget);
  });

  testWidgets('shows standard guidance by default, and both treatment '
      'buttons', (tester) async {
    final (widget, container) = await _wrap(_planResolvedToday());
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    expect(find.text(_firstStage.standardGuidance), findsOneWidget);
    expect(find.text('Standard'), findsOneWidget);
    expect(find.text('Lighter'), findsOneWidget);
  });

  testWidgets('tapping Lighter switches to lighter guidance, without '
      'changing the underlying activity', (tester) async {
    final (widget, container) = await _wrap(_planResolvedToday());
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    await tester.tap(find.text('Lighter'));
    await tester.pump();

    expect(find.text(_firstStage.lighterGuidance), findsOneWidget);
    expect(find.text(_firstStage.standardGuidance), findsNothing);
    expect(
      container.read(recommendationProvider).recommendation!.activityId,
      _firstStage.activityId,
    );
  });

  testWidgets('a persisted lighter treatment renders lighter guidance on '
      'restore', (tester) async {
    final (widget, container) = await _wrap(
      _planResolvedToday(treatment: 'lighter'),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    expect(find.text(_firstStage.lighterGuidance), findsOneWidget);
  });

  testWidgets('renders nothing if the stage id no longer resolves in the '
      'current catalogue (fail-safe)', (tester) async {
    final prefs = _planResolvedToday()
      ..[recommendationStageIdKey] = 'not_a_real_stage';
    final (widget, container) = await _wrap(prefs);
    addTearDown(container.dispose);
    await tester.pumpWidget(widget);

    expect(find.text('More Energy Path'), findsNothing);
  });
}
