import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/core/widgets/thirty_text_action.dart';
import 'package:thirty/core/worlds/daypart.dart';
import 'package:thirty/core/worlds/world.dart' show Daypart;
import 'package:thirty/features/home/presentation/widgets/home_header.dart'
    show HomeProfileButton;
import 'package:thirty/features/insights/domain/insight_snapshot.dart';
import 'package:thirty/features/insights/presentation/insights_page.dart';
import 'package:thirty/features/insights/presentation/widgets/insight_card.dart';
import 'package:thirty/features/insights/presentation/widgets/insights_header_art.dart';
import 'package:thirty/features/plans/application/plan_provider.dart';
import 'package:thirty/features/plans/domain/plan_catalog.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/plans/domain/plan_state.dart';
import 'package:thirty/features/plans/presentation/widgets/plan_identity.dart';

/// Insights' Visual North Star convergence (founder decisions, 2026-10-02):
/// the Plans-style editorial header with its own daypart band, the Insight
/// card family (target Plan identity, NEXT STEP panel, optional Plan
/// scene), and the neutral Free explainer.

/// 14:00 — the afternoon daypart, whose artwork is named `day`.
final _now = DateTime(2026, 9, 15, 14);

/// A current chosen-pacing Insight for the active More Energy Plan.
Map<String, Object?> _snapshot() => {
  'id': 'pacing',
  'family': 'chosenPacing',
  'applicationType': 'setLighterDefault',
  'targetPlanId': PlanId.moreEnergyPath.name,
  'targetStageId': null,
  'isPatternClaim': true,
  'evidenceCount': 5,
  'evidenceDateKeys': const [
    '2026-08-25',
    '2026-08-29',
    '2026-09-03',
    '2026-09-08',
    '2026-09-12',
  ],
  'usefulnessNumerator': null,
  'usefulnessDenominator': null,
  'generatedAt': DateTime(2026, 9, 15).toIso8601String(),
  'ruleVersion': insightRuleVersion,
  'templateVersion': insightTemplateVersion,
};

String _plans() => jsonEncode({
  'schemaVersion': plansStateSchemaVersion,
  'activePlanId': PlanId.moreEnergyPath.name,
  'progress': {
    for (final id in PlanId.values)
      id.name: {
        'planId': id.name,
        'contentVersion': planContentVersion,
        'cycleId': '${id.name}_cycle_1',
        'cycleStartedAt': DateTime(2026, 8, 20).toIso8601String(),
        'forwardCursor': 1,
        'lastEncounteredStageId': stageAt(id, 0).id,
        'pendingRevisit': false,
        'status': PlanCycleStatus.inProgress.name,
        'cycleHistory': <Object?>[],
        'lastAdvancedCircleId': null,
        'lighterDefault': false,
      },
  },
});

Future<void> _pump(
  WidgetTester tester, {
  bool entitled = false,
  bool withInsight = false,
  double width = 412,
  double textScale = 1.0,
  bool dark = false,
}) async {
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({
    plansStateKey: _plans(),
    insightSnapshotsKey: jsonEncode({
      'schemaVersion': insightSnapshotsSchemaVersion,
      'lastAssessedAt': DateTime(2026, 9, 15).toIso8601String(),
      'snapshots': [if (withInsight) _snapshot()],
    }),
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_now),
      eventClockProvider.overrideWithValue(() => _now),
      premiumEntitlementProvider.overrideWithValue(entitled),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const InsightsPage(),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

Finder get _bandImage => find.descendant(
  of: find.byType(InsightsHeaderArt),
  matching: find.byType(Image),
);

void main() {
  group('Insights header art', () {
    test("resolves each daypart through THIRTY's own daypart boundaries", () {
      expect(
        insightsHeaderArt.at(daypartAt(DateTime(2026, 8, 2, 5))).asset,
        'assets/insights/insights_header_morning_v1.webp',
      );
      expect(
        insightsHeaderArt.at(daypartAt(DateTime(2026, 8, 2, 12))).asset,
        'assets/insights/insights_header_day_v1.webp',
      );
      expect(
        insightsHeaderArt.at(daypartAt(DateTime(2026, 8, 2, 18))).asset,
        'assets/insights/insights_header_evening_v1.webp',
      );
      expect(
        insightsHeaderArt.at(daypartAt(DateTime(2026, 8, 2, 2))).asset,
        'assets/insights/insights_header_evening_v1.webp',
      );
    });

    test('every asset is a bundled WebP of the declared size, and its own — '
        'never the Plans band or a World scene', () {
      for (final daypart in Daypart.values) {
        final image = insightsHeaderArt.at(daypart);
        expect(image.asset, startsWith('assets/insights/'));
        final file = File(image.asset);
        expect(file.existsSync(), isTrue, reason: image.asset);
        // WebP VP8 lossy: width and height are 14-bit fields at byte 26.
        final bytes = file.readAsBytesSync();
        expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WEBP');
        final data = ByteData.sublistView(bytes);
        expect(data.getUint16(26, Endian.little) & 0x3fff, image.width);
        expect(data.getUint16(28, Endian.little) & 0x3fff, image.height);
      }
    });

    testWidgets('renders nothing without registered art', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InsightsHeaderArt(art: null, now: DateTime(2026, 8, 2, 14)),
        ),
      );
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('dimmed slightly in dark mode, full strength in light', (
      tester,
    ) async {
      for (final (dark, opacity) in [(false, 1.0), (true, 0.85)]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: InsightsHeaderArt(art: insightsHeaderArt, now: _now),
          ),
        );
        await tester.pumpAndSettle();
        final fade = tester.widget<Opacity>(
          find.descendant(
            of: find.byType(InsightsHeaderArt),
            matching: find.byType(Opacity),
          ),
        );
        expect(fade.opacity, opacity);
      }
    });
  });

  group('Insights header', () {
    testWidgets('the Plans editorial hierarchy: wordmark and You button, '
        'Your Insights, the exact subtitle, then the full-width band — no '
        'pinned AppBar', (tester) async {
      await _pump(tester);

      expect(find.byType(AppBar), findsNothing);
      expect(find.bySemanticsLabel('THIRTY'), findsOneWidget);
      expect(find.byType(HomeProfileButton), findsOneWidget);
      expect(find.text('Your Insights'), findsOneWidget);
      expect(
        find.text('Drawn from your own recorded Circles.'),
        findsOneWidget,
      );
      expect(find.text('Small shifts. Real change.'), findsNothing);

      final image = tester.widget<Image>(_bandImage);
      expect(
        (image.image as AssetImage).assetName,
        'assets/insights/insights_header_day_v1.webp',
      );
      expect(image.fit, BoxFit.cover, reason: 'scaled and centred');
      expect(image.alignment, Alignment.center);
      final band = tester.getSize(find.byType(InsightsHeaderArt));
      expect(band.width, 412, reason: 'edge to edge, outside the page inset');
      expect(
        band.width / band.height,
        closeTo(InsightsHeaderArt.bandAspectRatio, 0.01),
      );
      expect(
        tester.getTopLeft(find.byType(InsightsHeaderArt)).dy,
        greaterThan(tester.getBottomLeft(find.text(InsightsPage.subtitle)).dy),
      );
      expect(
        tester.getBottomLeft(find.byType(InsightsHeaderArt)).dy,
        lessThan(tester.getTopLeft(find.text('THIRTY Premium')).dy),
      );
    });

    testWidgets('headings in reading order, and the band is decorative', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);

      expect(
        tester.getSemantics(find.text('Your Insights')),
        isSemantics(isHeader: true),
      );
      expect(
        tester.getSemantics(find.text('Your history')),
        isSemantics(isHeader: true),
      );
      expect(
        tester.getTopLeft(find.text('Your Insights')).dy,
        lessThan(tester.getTopLeft(find.text('Your history')).dy),
      );
      expect(
        find.ancestor(of: _bandImage, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
      semantics.dispose();
    });
  });

  group('Insight card family', () {
    testWidgets('a real Insight: the target Plan identity and name, the '
        'observation, a NEXT STEP panel naming the change, quiet Dismiss — '
        'no artwork, no chevron', (tester) async {
      await _pump(tester, entitled: true, withInsight: true);

      final card = find.byType(InsightCard);
      expect(
        tester
            .widget<PlanIdentityBadge>(
              find.descendant(
                of: card,
                matching: find.byType(PlanIdentityBadge),
              ),
            )
            .planId,
        PlanId.moreEnergyPath,
      );
      expect(
        find.descendant(of: card, matching: find.text('More Energy Path')),
        findsOneWidget,
      );
      expect(find.textContaining('You chose lighter guidance'), findsOneWidget);
      expect(find.text('NEXT STEP'), findsOneWidget);
      expect(find.text('TRY THIS'), findsNothing);
      expect(find.text('Apply'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(InsightActionPanel),
          matching: find.widgetWithText(
            ThirtyButton,
            'Use lighter guidance as this Plan\'s default',
          ),
        ),
        findsOneWidget,
      );
      final dismiss = find.widgetWithText(ThirtyTextAction, 'Dismiss');
      expect(dismiss, findsOneWidget);
      expect(tester.getSize(dismiss).height, greaterThanOrEqualTo(48));

      // No image of any kind on the card (founder decision): the badge
      // names the Plan, the header band carries the atmosphere.
      expect(
        find.descendant(of: card, matching: find.byType(Image)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.byIcon(Icons.chevron_right_rounded),
        ),
        findsNothing,
      );
    });

    testWidgets('the headline keeps the full text width of the card — nothing '
        'beside it but the badge', (tester) async {
      await _pump(tester, entitled: true, withInsight: true);
      final card = find.byType(InsightCard);
      final headline = find.descendant(
        of: card,
        matching: find.text('More Energy Path'),
      );
      // Badge 44 + 16 gap inside the 24pt inset: the headline runs to the
      // card's right inset.
      expect(
        tester.getTopRight(headline).dx,
        closeTo(tester.getTopRight(card).dx - AppSpacing.featuredCard, 0.5),
      );
    });

    testWidgets('Free with a retained Insight: the panel is the one quiet '
        'route to Premium, never the application', (tester) async {
      await _pump(tester, withInsight: true);

      expect(
        find.descendant(
          of: find.byType(InsightActionPanel),
          matching: find.widgetWithText(
            ThirtyTextAction,
            'Become Premium to apply this',
          ),
        ),
        findsOneWidget,
      );
      expect(find.byType(ThirtyButton), findsNothing);
      expect(find.text('THIRTY Premium'), findsNothing);
    });

    testWidgets('the NEXT STEP panel has one geometry: Free and Premium '
        'panels span the same full inner width', (tester) async {
      await _pump(tester, entitled: true, withInsight: true);
      final premium = tester.getRect(find.byType(InsightActionPanel));

      await _pump(tester, withInsight: true);
      final free = tester.getRect(find.byType(InsightActionPanel));

      expect(free.left, premium.left);
      expect(free.width, premium.width);
      expect(
        premium.width,
        412 - AppSpacing.page * 2 - AppSpacing.featuredCard * 2,
      );
    });

    testWidgets('Free, no Insight: one neutral explainer, never a Plan '
        'identity or a sample Insight', (tester) async {
      await _pump(tester);

      expect(find.byType(InsightsNeutralBadge), findsOneWidget);
      expect(find.byType(PlanIdentityBadge), findsNothing);
      expect(find.byType(InsightCard), findsNothing);
      expect(find.byType(InsightActionPanel), findsNothing);
      expect(find.text('Become Premium'), findsOneWidget);
    });
  });
}
