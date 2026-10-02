import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_card.dart';
import 'package:thirty/features/insights/presentation/widgets/insight_card.dart';
import 'package:thirty/features/plans/application/plan_provider.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/plans/presentation/plan_detail_page.dart';
import 'package:thirty/features/plans/presentation/plan_path_page.dart';
import 'package:thirty/features/plans/presentation/widgets/plan_card.dart';
import 'package:thirty/features/plans/presentation/widgets/plans_header_art.dart';

final _today = DateTime(2026, 8, 2, 14);

/// The Plans list inside a minimal router with Your Path as its child, so
/// a card tap really navigates. The list itself never hosts a Plan action
/// any more — those are covered in `plan_detail_page_test.dart`.
Future<ProviderContainer> _pump(
  WidgetTester tester, {
  bool entitled = true,
}) async {
  tester.view.physicalSize = const Size(412, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: '/plans',
    routes: [
      GoRoute(
        path: '/plans',
        builder: (_, _) => const PlanPathPage(),
        routes: [
          GoRoute(
            path: ':planId',
            builder: (_, state) => PlanDetailPage(
              planId: PlanId.values.byName(state.pathParameters['planId']!),
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('lists all three Plans by name, each as a PlanCard', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('More Energy Path'), findsOneWidget);
    expect(find.text('Clearer Head Path'), findsOneWidget);
    expect(find.text('Gentler Pace Path'), findsOneWidget);
    expect(find.byType(PlanCard), findsNWidgets(3));
  });

  testWidgets('the header: Your Plans, its supporting line, and the full-'
      'width art band for the current daypart at its own proportions', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text(PlanPathPage.title), findsOneWidget);
    expect(find.text(PlanPathPage.subtitle), findsOneWidget);
    // 14:00 is the afternoon daypart, whose artwork is named `day`.
    final image = tester.widget<Image>(
      find.descendant(
        of: find.byType(PlansHeaderArt),
        matching: find.byType(Image),
      ),
    );
    expect(
      (image.image as AssetImage).assetName,
      'assets/plans/plans_header_day_v1.webp',
    );
    final band = tester.getSize(find.byType(PlansHeaderArt));
    expect(band.width, 412, reason: 'edge to edge, outside the page inset');
    expect(
      band.width / band.height,
      closeTo(PlansHeaderArt.bandAspectRatio, 0.01),
    );
    final fit = tester.widget<Image>(
      find.descendant(
        of: find.byType(PlansHeaderArt),
        matching: find.byType(Image),
      ),
    );
    expect(fit.fit, BoxFit.cover, reason: 'scaled and centred, not stretched');
    // Between the supporting line and the first Plan card.
    expect(
      tester.getTopLeft(find.byType(PlansHeaderArt)).dy,
      greaterThan(tester.getBottomLeft(find.text(PlanPathPage.subtitle)).dy),
    );
    expect(
      tester.getBottomLeft(find.byType(PlansHeaderArt)).dy,
      lessThan(tester.getTopLeft(find.byType(PlanCard).first).dy),
    );
    // No pinned bar: the header scrolls with the page, like Home.
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('the list hosts no Plan action — every action lives on Your '
      'Path', (tester) async {
    await _pump(tester);

    for (final label in [
      'Activate',
      'Resume',
      'Repeat this cycle',
      'Queue a revisit of the last stage',
      'Pause this plan',
    ]) {
      expect(find.text(label), findsNothing, reason: label);
    }
  });

  testWidgets('tapping a Plan card opens that Plan\'s Your Path', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Clearer Head Path'));
    await tester.pumpAndSettle();

    final detail = tester.widget<PlanDetailPage>(find.byType(PlanDetailPage));
    expect(detail.planId, PlanId.clearerHeadPath);
  });

  testWidgets('the active Plan\'s card carries the Active tag', (tester) async {
    final container = await _pump(tester);
    container.read(planProvider.notifier).activatePlan(PlanId.gentlerPacePath);
    await tester.pumpAndSettle();

    expect(find.text('Active'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(PlanCard, 'Gentler Pace Path'),
        matching: find.byType(PlanActiveTag),
      ),
      findsOneWidget,
    );
  });

  testWidgets('each card\'s progress is one spoken position, never colour '
      'alone', (tester) async {
    final container = await _pump(tester);
    final notifier = container.read(planProvider.notifier);
    notifier.activatePlan(PlanId.moreEnergyPath);
    notifier.advanceCursorForCircle(
      PlanId.moreEnergyPath,
      'circle-0',
      isRevisit: false,
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Stage 2 of 5, 1 closed.'), findsOneWidget);
    expect(find.bySemanticsLabel('5 stages. Not started.'), findsNWidgets(2));
  });

  testWidgets('no longer hosts InsightCard — it moved to its own Insights '
      'destination in Batch B (see insights_page_test.dart)', (tester) async {
    await _pump(tester);

    expect(find.byType(InsightCard), findsNothing);
  });

  group('Batch A — unentitled Free list', () {
    testWidgets('shows each Plan\'s name and purpose, no interactive '
        'controls, and one Become Premium action (Phase C3 copy)', (
      tester,
    ) async {
      await _pump(tester, entitled: false);

      expect(find.text('More Energy Path'), findsOneWidget);
      expect(find.text('Clearer Head Path'), findsOneWidget);
      expect(find.text('Gentler Pace Path'), findsOneWidget);
      expect(find.text('Activate'), findsNothing);
      expect(find.text('Pause this plan'), findsNothing);
      expect(find.text('Become Premium'), findsOneWidget);
      expect(find.text('Open Premium'), findsNothing);
    });

    testWidgets('the Premium card keeps its featured padding; Plan cards are '
        'edge-to-edge art cards, like Home\'s Today card', (tester) async {
      await _pump(tester, entitled: false);

      final premium = tester.widget<ThirtyCard>(
        find.ancestor(
          of: find.text('THIRTY Premium'),
          matching: find.byType(ThirtyCard),
        ),
      );
      expect(premium.padding, const EdgeInsets.all(AppSpacing.featuredCard));
      for (final card in tester.widgetList<ThirtyCard>(
        find.descendant(
          of: find.byType(PlanCard),
          matching: find.byType(ThirtyCard),
        ),
      )) {
        expect(card.padding, EdgeInsets.zero);
      }
    });
  });
}
