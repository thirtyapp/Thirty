import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/core/widgets/thirty_progress_circle.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/home_page.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';
import 'package:thirty/features/home/presentation/widgets/home_circle_metrics.dart';

/// Phase B1 — Home composition foundations: the shared Circle metrics, the
/// halo, the 56pt Home CTA and the First-Breath-gated header wordmark.
/// Lifecycle behavior itself stays covered by `home_page_test.dart`,
/// `circle_ready_prompt_test.dart` and `circle_hero_test.dart`.

final _today = DateTime(2026, 8, 2);

const _chosen = <String, Object>{
  recommendationDayKey: '2026-08-02',
  recommendationIntentionKey: 'moreEnergy',
  recommendationActivityIdKey: 'thirtyMinuteWalk',
};

// circle_hero.dart's full First Breath timeline, mirrored (as in
// circle_hero_test.dart) rather than read from the private constant.
const _firstBreathTotalMs = 6500;

Future<Widget> _wrap({
  Map<String, Object> storedPrefs = const {},
  ThemeData? theme,
  bool disableAnimations = false,
}) async {
  SharedPreferences.setMockInitialValues(storedPrefs);
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_today),
    ],
    child: MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: const HomePage(),
        ),
      ),
    ),
  );
}

double _headerOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

double _ctaHeight(WidgetTester tester, String label) =>
    tester.getSize(find.widgetWithText(ThirtyButton, label)).height;

void main() {
  group('HomeCircleMetrics', () {
    test('keeps the pre-B1 Circle geometry at 320 / 360 / 412pt', () {
      // 320: 281.6 capped by the page margins (320 - 48 = 272).
      expect(HomeCircleMetrics.forWidth(320).circleSize, 272);
      // 360: 316.8 capped by the page margins (360 - 48 = 312).
      expect(HomeCircleMetrics.forWidth(360).circleSize, 312);
      // 412: 362.56 fits inside 364.
      expect(HomeCircleMetrics.forWidth(412).circleSize, closeTo(362.56, 1e-9));
      final m = HomeCircleMetrics.forWidth(360);
      // Phase D1: the wordmark keeps its pre-D1 reference interior; the
      // ring sits 8pt inside the halo and the illustration inside it.
      expect(m.interiorSize, 312 - 20);
      expect(m.ringSize, 312 - 16);
      expect(m.illustrationSize, 312 - 36);
      expect(m.textMaxWidth, closeTo(312 * 0.85, 1e-9));
    });
  });

  group('Circle halo', () {
    for (final (name, theme, shadows) in [
      ('light', AppTheme.light, AppShadows.haloLight),
      ('dark', AppTheme.dark, AppShadows.haloDark),
    ]) {
      testWidgets('$name: Ready and Circle Hero share the same halo, with '
          'the D1 ring inset 8pt inside it', (tester) async {
        for (final prefs in [const <String, Object>{}, _chosen]) {
          await tester.pumpWidget(
            await _wrap(
              storedPrefs: prefs,
              theme: theme,
              disableAnimations: true,
            ),
          );
          await tester.pump();

          final halo = find.byType(HomeCircleHalo);
          expect(halo, findsOneWidget);
          expect(
            tester.getRect(find.byType(ThirtyProgressCircle)),
            tester.getRect(halo).deflate(HomeCircleMetrics.ringInset),
          );
          final decoration =
              tester
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: halo,
                          matching: find.byType(DecoratedBox),
                        ).first,
                      )
                      .decoration
                  as BoxDecoration;
          expect(decoration.shape, BoxShape.circle);
          expect(decoration.boxShadow, shadows);
          expect(
            decoration.color,
            theme.extension<AppColors>()!.surface,
          );
        }
      });
    }

    testWidgets('Phase D1: the not-started Circle shows the soft track with '
        'an empty arc', (tester) async {
      await tester.pumpWidget(
        await _wrap(storedPrefs: _chosen, disableAnimations: true),
      );
      await tester.pump();

      final circle = tester.widget<ThirtyProgressCircle>(
        find.byType(ThirtyProgressCircle),
      );
      expect(circle.trackColor, AppColors.light.ringTrack);
      expect(circle.progress, 0.0);
    });
  });

  group('56pt Home CTA', () {
    testWidgets('Begin today\'s Circle is 56pt with no trailing icon; the '
        'three direction choices stay 48pt', (tester) async {
      await tester.pumpWidget(await _wrap(disableAnimations: true));

      expect(_ctaHeight(tester, "Begin today's Circle"), 56);
      expect(
        find.descendant(
          of: find.widgetWithText(ThirtyButton, "Begin today's Circle"),
          matching: find.byType(Icon),
        ),
        findsNothing,
      );

      await tester.tap(find.text("Begin today's Circle"));
      await tester.pump();
      for (final label in ['More Energy', 'Clearer Head', 'Gentler Pace']) {
        expect(_ctaHeight(tester, label), 48, reason: label);
      }
    });

    testWidgets('Start Circle and Close Circle are 56pt', (tester) async {
      await tester.pumpWidget(
        await _wrap(storedPrefs: _chosen, disableAnimations: true),
      );
      await tester.pump();
      expect(_ctaHeight(tester, 'Start Circle'), 56);

      await tester.ensureVisible(find.text('Start Circle'));
      await tester.tap(find.text('Start Circle'));
      await tester.pump();
      expect(_ctaHeight(tester, 'Close Circle'), 56);
    });

    testWidgets('the 56pt CTA is still gated by First Breath\'s reveal', (
      tester,
    ) async {
      await tester.pumpWidget(await _wrap(storedPrefs: _chosen));
      await tester.pump(const Duration(milliseconds: 3000));

      await tester.ensureVisible(find.text('Start Circle'));
      await tester.tap(find.text('Start Circle'), warnIfMissed: false);
      await tester.pump();
      expect(find.text('Start Circle'), findsOneWidget);
      expect(find.text('Close Circle'), findsNothing);

      await tester.pumpAndSettle();
    });
  });

  group('Header wordmark', () {
    testWidgets('hidden in Ready, including after Begin today\'s Circle', (
      tester,
    ) async {
      await tester.pumpWidget(await _wrap());
      expect(_headerOpacity(tester), 0);
      expect(find.bySemanticsLabel('THIRTY'), findsNothing);

      await tester.tap(find.text("Begin today's Circle"));
      await tester.pumpAndSettle();
      expect(_headerOpacity(tester), 0);
    });

    testWidgets('hidden throughout The First Breath, revealed only once it '
        'has settled', (tester) async {
      await tester.pumpWidget(await _wrap(storedPrefs: _chosen));

      // Cumulative samples: in-Circle wordmark hold, Circle opening,
      // content reveal, and just before the ritual's final frame.
      var elapsedMs = 0;
      for (final sampleMs in [0, 1000, 3000, _firstBreathTotalMs - 100]) {
        await tester.pump(Duration(milliseconds: sampleMs - elapsedMs));
        elapsedMs = sampleMs;
        expect(_headerOpacity(tester), 0, reason: 'at ${sampleMs}ms');
      }

      await tester.pumpAndSettle();
      expect(_headerOpacity(tester), 1);
      expect(find.bySemanticsLabel('THIRTY'), findsOneWidget);
    });

    testWidgets('shown at once when First Breath already played today', (
      tester,
    ) async {
      await tester.pumpWidget(
        await _wrap(
          storedPrefs: {..._chosen, firstBreathLastPlayedDateKey: '2026-08-02'},
        ),
      );
      expect(_headerOpacity(tester), 1);
      expect(find.bySemanticsLabel('THIRTY'), findsOneWidget);
    });

    testWidgets('reduced motion on the first open of the day reveals it '
        'with no fade', (tester) async {
      await tester.pumpWidget(
        await _wrap(storedPrefs: _chosen, disableAnimations: true),
      );
      await tester.pump();
      expect(_headerOpacity(tester), 1);
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.descendant(
                of: find.byType(AppBar),
                matching: find.byType(AnimatedOpacity),
              ),
            )
            .duration,
        Duration.zero,
      );
    });

    testWidgets('revealing the header never moves the Circle', (tester) async {
      await tester.pumpWidget(await _wrap(storedPrefs: _chosen));
      await tester.pump();
      final during = tester.getRect(find.byType(ThirtyProgressCircle));

      await tester.pumpAndSettle();
      expect(_headerOpacity(tester), 1);
      expect(find.byType(CircleHero), findsOneWidget);
      expect(tester.getRect(find.byType(ThirtyProgressCircle)), during);
    });
  });
}
