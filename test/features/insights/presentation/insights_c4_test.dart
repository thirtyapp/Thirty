import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/insights/domain/insight_snapshot.dart';
import 'package:thirty/features/insights/presentation/insights_page.dart';
import 'package:thirty/features/insights/presentation/widgets/circle_history_calendar.dart';
import 'package:thirty/features/insights/presentation/widgets/insight_card.dart';
import 'package:thirty/features/plans/application/plan_provider.dart';
import 'package:thirty/features/plans/domain/plan_catalog.dart';
import 'package:thirty/features/plans/domain/plan_ids.dart';
import 'package:thirty/features/plans/domain/plan_state.dart';

/// Phase C4 — the Insights page's second section, with the app's real
/// fonts at 320 / 360pt, 200% text, light and dark: every Insight / empty
/// / Premium state renders untruncated, Premium's one application is the
/// full-width main action, Free's paid route is one quiet text action, and
/// no state shows two sales surfaces.

final _today = DateTime(2026, 9, 15);

const _nothingToShow =
    'Nothing to show yet. Pattern Insights need at least 5 relevant Circle '
    'records across 3 different days, spanning at least 14 days.';
const _applied = 'Applied. Your Plan is updated.';
const _freeRoute = 'Become Premium to apply this';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(file).readAsBytesSync())),
    );
  }
  await loader.load();
}

/// One retained Insight, per existing family (and the plain current-place
/// form of direction/path continuity).
enum _Seed { currentPlace, continuityPattern, chosenPacing, deliberateRevisits }

const _currentEvidence = [
  '2026-08-25',
  '2026-08-29',
  '2026-09-03',
  '2026-09-08',
  '2026-09-12',
];

/// Older than the 28-day window at [_today].
const _agedOutEvidence = [
  '2026-06-20',
  '2026-06-24',
  '2026-06-29',
  '2026-07-04',
  '2026-07-08',
];

Map<String, Object?> _snapshot(_Seed seed, {bool agedOut = false}) {
  final evidence = agedOut ? _agedOutEvidence : _currentEvidence;
  final (family, application, target, stage, pattern) = switch (seed) {
    _Seed.currentPlace => (
      'directionPathContinuity',
      'activateOrResumePlan',
      PlanId.gentlerPacePath,
      null,
      false,
    ),
    _Seed.continuityPattern => (
      'directionPathContinuity',
      'activateOrResumePlan',
      PlanId.gentlerPacePath,
      null,
      true,
    ),
    _Seed.chosenPacing => (
      'chosenPacing',
      'setLighterDefault',
      PlanId.moreEnergyPath,
      null,
      true,
    ),
    _Seed.deliberateRevisits => (
      'deliberateRevisits',
      'queueRevisit',
      PlanId.moreEnergyPath,
      stageAt(PlanId.moreEnergyPath, 0).id,
      true,
    ),
  };
  return {
    'id': seed.name,
    'family': family,
    'applicationType': application,
    'targetPlanId': target.name,
    'targetStageId': stage,
    'isPatternClaim': pattern,
    'evidenceCount': pattern ? evidence.length : 0,
    'evidenceDateKeys': pattern ? evidence : <String>[],
    'usefulnessNumerator': seed == _Seed.chosenPacing ? 2 : null,
    'usefulnessDenominator': seed == _Seed.chosenPacing ? 3 : null,
    'generatedAt': (agedOut ? DateTime(2026, 7, 9) : _today).toIso8601String(),
    'ruleVersion': insightRuleVersion,
    'templateVersion': insightTemplateVersion,
  };
}

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

String _journal() => jsonEncode({
  'schemaVersion': circleJournalSchemaVersion,
  'entries': [
    for (final date in const ['2026-09-08', '2026-09-12'])
      {
        'schemaVersion': circleJournalSchemaVersion,
        'circleId': date,
        'localDate': date,
        'direction': Intention.moreEnergy.name,
        'activityId': ActivityId.thirtyMinuteWalk.name,
        'catalogVersion': catalogVersion,
        'shownAt': '${date}T09:00:00.000',
      },
  ],
});

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required double width,
  required bool entitled,
  _Seed? seed,
  bool agedOut = false,
  double textScale = 2.0,
  bool dark = false,
}) async {
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({
    circleJournalKey: _journal(),
    plansStateKey: _plans(),
    insightSnapshotsKey: jsonEncode({
      'schemaVersion': insightSnapshotsSchemaVersion,
      'lastAssessedAt': _today.toIso8601String(),
      'snapshots': [if (seed != null) _snapshot(seed, agedOut: agedOut)],
    }),
  });
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
            GoRoute(
              path: '/premium',
              builder: (context, state) =>
                  const Scaffold(body: Text('premium offer')),
            ),
            GoRoute(
              path: '/history/:date',
              builder: (context, state) => const Scaffold(body: Text('detail')),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

/// Nothing overflows, nothing is ellipsized, every text action keeps its
/// 48pt target.
void _expectClean(WidgetTester tester) {
  expect(tester.takeException(), isNull);
  final truncated = [
    for (final element in find.byType(RichText).evaluate())
      if ((element.renderObject! as RenderParagraph).didExceedMaxLines)
        (element.renderObject! as RenderParagraph).text.toPlainText(),
  ];
  expect(truncated, isEmpty);
  for (final element in find.byType(ThirtyTextAction).evaluate()) {
    final size = tester.getSize(find.byWidget(element.widget));
    expect(size.height, greaterThanOrEqualTo(48));
  }
}

/// At most one route to Premium on the page at a time.
int _salesSurfaces() =>
    find.text('Become Premium').evaluate().length +
    find.text(_freeRoute).evaluate().length;

String _applicationLabel(_Seed seed) => switch (seed) {
  _Seed.currentPlace || _Seed.continuityPattern => 'Resume this Plan',
  _Seed.chosenPacing => 'Use lighter guidance as this Plan\'s default',
  _Seed.deliberateRevisits => 'Queue a one-off revisit of this stage',
};

/// The observation paragraph: the card's first text, in the primary
/// onSurface body colour (never a muted / "locked" treatment); the evidence
/// and date metadata after it stay muted.
void _expectObservationReadable(WidgetTester tester) {
  final texts = find.descendant(
    of: find.byType(InsightCard),
    matching: find.byType(Text),
  );
  final observation = tester.widget<Text>(texts.first);
  final context = tester.element(texts.first);
  final theme = Theme.of(context);
  expect(observation.style?.color, theme.colorScheme.onSurface);
  final muted = theme.extension<AppColors>()!.textSecondary;
  for (final metadata in [
    find.textContaining('Based on'),
    find.textContaining('Observed on'),
    find.textContaining('An earlier Insight from'),
  ]) {
    for (final element in metadata.evaluate()) {
      expect((element.widget as Text).style?.color, muted);
    }
  }
}

/// Each localized date stays together on one line (non-breaking spaces),
/// while its spoken form keeps ordinary spaces.
void _expectDatesKeptTogether(WidgetTester tester, String date) {
  final shown = date.replaceAll(' ', ' ');
  final texts = tester.widgetList<Text>(find.textContaining(shown)).toList();
  expect(texts, isNotEmpty);
  for (final text in texts) {
    expect(text.semanticsLabel, contains(date));
    expect(text.semanticsLabel, isNot(contains(' ')));
  }
}

void main() {
  setUpAll(() async {
    await _loadFont('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ]);
  });

  for (final width in const [320.0, 360.0]) {
    for (final dark in const [false, true]) {
      final tag = '${width.toInt()}pt · 200% · ${dark ? 'dark' : 'light'}';

      group(tag, () {
        testWidgets('page order: Your history, calendar, then Insights', (
          tester,
        ) async {
          await _pump(tester, width: width, entitled: false, dark: dark);

          final history = tester.getTopLeft(find.text('Your history'));
          final calendar = tester.getTopLeft(
            find.byType(CircleHistoryCalendar),
          );
          final insights = tester.getTopLeft(
            find.descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.text('Insights'),
            ),
          );
          expect(history.dy, lessThan(calendar.dy));
          expect(calendar.dy, lessThan(insights.dy));
          // Headings sit on the page's 24pt left edge; no divider.
          expect(history.dx, AppSpacing.page);
          expect(insights.dx, AppSpacing.page);
          expect(find.byType(Divider), findsNothing);
          _expectClean(tester);
        });

        testWidgets('Free · no Insight: one compact THIRTY Premium card', (
          tester,
        ) async {
          await _pump(tester, width: width, entitled: false, dark: dark);

          expect(find.text('THIRTY Premium'), findsOneWidget);
          expect(
            tester.getTopLeft(find.text('THIRTY Premium')).dx,
            AppSpacing.page + AppSpacing.featuredCard,
          );
          expect(
            tester.getSize(find.byType(ThirtyButton)).width,
            width - AppSpacing.page * 2 - AppSpacing.featuredCard * 2,
          );
          expect(_salesSurfaces(), 1);
          expect(find.text(_nothingToShow), findsNothing);
          _expectClean(tester);

          await tester.tap(find.text('Become Premium'));
          await tester.pumpAndSettle();
          expect(find.text('premium offer'), findsOneWidget);
        });

        testWidgets('Premium · no Insight: the truthful reason, no sales', (
          tester,
        ) async {
          await _pump(tester, width: width, entitled: true, dark: dark);

          expect(find.text(_nothingToShow), findsOneWidget);
          expect(
            tester.getTopLeft(find.text(_nothingToShow)).dx,
            AppSpacing.page,
          );
          expect(_salesSurfaces(), 0);
          expect(find.text('THIRTY Premium'), findsNothing);
          _expectClean(tester);
        });

        for (final seed in _Seed.values) {
          testWidgets('Premium · current ${seed.name}: full-width main '
              'action naming its change, quiet Dismiss', (tester) async {
            await _pump(
              tester,
              width: width,
              entitled: true,
              seed: seed,
              dark: dark,
            );

            final action = find.widgetWithText(
              ThirtyButton,
              _applicationLabel(seed),
            );
            expect(action, findsOneWidget);
            final button = tester.widget<ThirtyButton>(action);
            expect(button.variant, ThirtyButtonVariant.primary);
            expect(
              tester.getSize(action).width,
              width - AppSpacing.page * 2 - AppSpacing.featuredCard * 2,
            );
            expect(find.text('Dismiss'), findsOneWidget);
            expect(find.textContaining('Observed on'), findsOneWidget);
            _expectDatesKeptTogether(tester, 'Sep 15, 2026');
            if (seed != _Seed.currentPlace) {
              expect(
                find.textContaining('Based on 5 recorded'),
                findsOneWidget,
              );
              _expectDatesKeptTogether(tester, 'Aug 25, 2026');
              _expectDatesKeptTogether(tester, 'Sep 12, 2026');
              // Human-readable dates, never the stored keys.
              expect(
                find.textContaining(RegExp(r'\d{4}-\d{2}-\d{2}')),
                findsNothing,
              );
            }
            expect(_salesSurfaces(), 0);
            _expectObservationReadable(tester);
            _expectClean(tester);
          });

          testWidgets('Free · retained ${seed.name}: readable, one quiet '
              'route, no Premium card', (tester) async {
            await _pump(
              tester,
              width: width,
              entitled: false,
              seed: seed,
              dark: dark,
            );

            expect(find.text(_applicationLabel(seed)), findsNothing);
            expect(
              find.descendant(
                of: find.byType(InsightCard),
                matching: find.byType(ThirtyButton),
              ),
              findsNothing,
            );
            expect(
              find.widgetWithText(ThirtyTextAction, _freeRoute),
              findsOneWidget,
            );
            expect(find.text('THIRTY Premium'), findsNothing);
            expect(_salesSurfaces(), 1);
            _expectObservationReadable(tester);
            _expectClean(tester);

            await tester.tap(find.text(_freeRoute));
            await tester.pumpAndSettle();
            expect(find.text('premium offer'), findsOneWidget);
          });
        }

        testWidgets('just applied: the confirmation, never the empty state', (
          tester,
        ) async {
          final container = await _pump(
            tester,
            width: width,
            entitled: true,
            seed: _Seed.chosenPacing,
            dark: dark,
          );

          await tester.tap(find.text(_applicationLabel(_Seed.chosenPacing)));
          await tester.pump();

          expect(
            container
                .read(planProvider)
                .progress[PlanId.moreEnergyPath]!
                .lighterDefault,
            isTrue,
          );
          expect(find.text(_applied), findsOneWidget);
          expect(find.text(_nothingToShow), findsNothing);
          expect(find.byType(InsightCard), findsNothing);
          expect(_salesSurfaces(), 0);
          _expectClean(tester);
        });

        testWidgets('dismissed: back to the plain state, no confirmation', (
          tester,
        ) async {
          await _pump(
            tester,
            width: width,
            entitled: true,
            seed: _Seed.deliberateRevisits,
            dark: dark,
          );

          await tester.tap(find.text('Dismiss'));
          await tester.pump();

          expect(find.byType(InsightCard), findsNothing);
          expect(find.text(_applied), findsNothing);
          expect(find.text(_nothingToShow), findsOneWidget);
          _expectClean(tester);
        });

        for (final entitled in const [true, false]) {
          testWidgets(
            'earlier aged-out Insight (${entitled ? 'Premium' : 'Free'}'
            '): dated, read-only, no sales',
            (tester) async {
              await _pump(
                tester,
                width: width,
                entitled: entitled,
                seed: _Seed.chosenPacing,
                agedOut: true,
                dark: dark,
              );

              expect(
                find.textContaining('An earlier Insight from'),
                findsOneWidget,
              );
              expect(find.textContaining('recent'), findsNothing);
              expect(find.byType(ThirtyButton), findsNothing);
              expect(_salesSurfaces(), 0);
              expect(find.text('THIRTY Premium'), findsNothing);
              expect(find.text('Dismiss'), findsOneWidget);
              _expectObservationReadable(tester);
              _expectClean(tester);
            },
          );
        }
      });
    }
  }
}
