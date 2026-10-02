import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/coach/presentation/widgets/coach_cue_banner.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/plans/application/plan_provider.dart';
import 'package:thirty/features/plans/domain/plan_catalog.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/plans/presentation/plan_detail_page.dart';
import 'package:thirty/features/plans/presentation/plan_path_page.dart';

/// Phase C3, extended for the Plans convergence (2026-10-01) — Plans and
/// Your Path with the app's real fonts loaded (Inter and the Newsreader
/// serif of their titles): every Plan state, on both pages, and Home's
/// Coach banner, at 320 / 360pt and 200% text, light and dark — nothing
/// truncated, nothing overflowing, everything reachable.

final _today = DateTime(2026, 8, 10, 9);

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(file).readAsBytesSync())),
    );
  }
  await loader.load();
}

Future<void> _seedCoachShortcuts(PlanNotifier plans, ProviderContainer c) async {
  final priorStage = planDefinitionFor(PlanId.moreEnergyPath).stages[0];
  plans.activatePlan(PlanId.moreEnergyPath);
  plans.advanceCursorForCircle(
    PlanId.moreEnergyPath,
    '2026-08-09',
    isRevisit: false,
  );
  final journal = c.read(circleJournalRepositoryProvider);
  await journal.recordShown(
    circleId: '2026-08-09',
    localDate: '2026-08-09',
    direction: Intention.moreEnergy,
    activityId: priorStage.activityId,
    shownAt: DateTime(2026, 8, 9, 9),
    planId: PlanId.moreEnergyPath.name,
    planVersion: planContentVersion,
    stageId: priorStage.id,
    planCycleId: 'moreEnergyPath_cycle_1',
    treatmentUsed: 'standard',
    revisitUsed: false,
  );
  await journal.recordAttempt(
    circleId: '2026-08-09',
    localDate: '2026-08-09',
    direction: Intention.moreEnergy,
    activityId: priorStage.activityId,
    response: CircleAttemptResponse.notToday,
    respondedAt: DateTime(2026, 8, 9, 10),
    planId: PlanId.moreEnergyPath.name,
    planVersion: planContentVersion,
    stageId: priorStage.id,
    planCycleId: 'moreEnergyPath_cycle_1',
    treatmentUsed: 'standard',
    revisitUsed: false,
  );
  c.read(recommendationProvider.notifier).chooseIntention(Intention.moreEnergy);
}

void main() {
  setUpAll(() async {
    await _loadFont('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ]);
    await _loadFont('Newsreader', ['assets/fonts/Newsreader[opsz,wght].ttf']);
  });

  const states = [
    'free',
    'free with a saved position',
    'none active',
    'active, started',
    'revisit queued',
    'cycle completed',
    'Coach with both shortcuts',
    'Home Coach banner',
  ];

  for (final width in [320.0, 360.0]) {
    for (final state in states) {
      for (final page in [
        'Plans',
        if (state != 'Home Coach banner') 'Your Path',
      ]) {
        for (final (themeName, theme) in [
          ('light', AppTheme.light),
          ('dark', AppTheme.dark),
        ]) {
          testWidgets('${width.toInt()}pt, 200%, $state, '
              '${state == 'Home Coach banner' ? 'Home' : page}, $themeName: '
              'nothing truncated or overflowing', (tester) async {
            tester.view.physicalSize = Size(width, 4000);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            SharedPreferences.setMockInitialValues({});
            final prefs = await SharedPreferences.getInstance();
            final free = state.startsWith('free');
            final container = ProviderContainer(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                nowProvider.overrideWithValue(_today),
                eventClockProvider.overrideWithValue(() => _today),
                premiumEntitlementProvider.overrideWithValue(!free),
              ],
            );
            addTearDown(container.dispose);
            // Plan progress is built while entitled (a saved position a Free
            // user sees was earned while Premium).
            final entitled = ProviderContainer(
              parent: container,
              overrides: [premiumEntitlementProvider.overrideWithValue(true)],
            );
            addTearDown(entitled.dispose);
            final plans = entitled.read(planProvider.notifier);
            switch (state) {
              case 'free with a saved position' || 'active, started':
                plans.activatePlan(PlanId.moreEnergyPath);
                plans.advanceCursorForCircle(
                  PlanId.moreEnergyPath,
                  'c0',
                  isRevisit: false,
                );
              case 'revisit queued':
                plans.activatePlan(PlanId.moreEnergyPath);
                plans.advanceCursorForCircle(
                  PlanId.moreEnergyPath,
                  'c0',
                  isRevisit: false,
                );
                plans.queueRevisit();
              case 'cycle completed':
                plans.activatePlan(PlanId.moreEnergyPath);
                for (var i = 0; i < 5; i++) {
                  plans.advanceCursorForCircle(
                    PlanId.moreEnergyPath,
                    'c$i',
                    isRevisit: false,
                  );
                }
              case 'Coach with both shortcuts' || 'Home Coach banner':
                await _seedCoachShortcuts(plans, container);
            }

            final isHome = state == 'Home Coach banner';
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  theme: theme,
                  home: Builder(
                    builder: (context) => MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(textScaler: const TextScaler.linear(2.0)),
                      child: isHome
                          // Home's Plan session panel width: the page inset.
                          ? const Scaffold(
                              body: Padding(
                                padding: EdgeInsets.all(AppSpacing.page),
                                child: CoachCueBanner(
                                  planId: PlanId.moreEnergyPath,
                                ),
                              ),
                            )
                          : page == 'Plans'
                          ? const PlanPathPage()
                          : const PlanDetailPage(planId: PlanId.moreEnergyPath),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();

            expect(tester.takeException(), isNull);
            final truncated = [
              for (final element in find.byType(RichText).evaluate())
                if ((element.renderObject! as RenderParagraph)
                    .didExceedMaxLines)
                  (element.renderObject! as RenderParagraph).text.toPlainText(),
            ];
            expect(truncated, isEmpty);

            // The Coach cue lives on Your Path (and Home), not the list.
            if ((state == 'Coach with both shortcuts' && page == 'Your Path') ||
                isHome) {
              // Home's banner-only scaffold has nothing to scroll.
              if (!isHome) {
                await tester.scrollUntilVisible(
                  find.text('Try lighter guidance today'),
                  300,
                );
              }
              expect(find.text('Try lighter guidance today'), findsOneWidget);
            }
            if (free) {
              await tester.scrollUntilVisible(find.text('Become Premium'), 300);
              expect(tester.takeException(), isNull);
            }
          });
        }
      }
    }
  }
}
