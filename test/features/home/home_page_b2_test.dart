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
import 'package:thirty/features/home/presentation/widgets/daily_intention_prompt.dart';
import 'package:thirty/features/home/presentation/widgets/home_circle_metrics.dart';

/// Phase B2 — hero CTA width/arrow and the Home text-column rhythm, on the
/// real `HomePage` composition. Lifecycle behavior stays covered by the
/// existing Golden Home suites.

final _today = DateTime(2026, 8, 2);

const _chosen = <String, Object>{
  recommendationDayKey: '2026-08-02',
  recommendationIntentionKey: 'moreEnergy',
  recommendationActivityIdKey: 'thirtyMinuteWalk',
};

final _started = <String, Object>{
  ..._chosen,
  recommendationStatusKey: 'started',
  recommendationStartedAtKey: _today.toIso8601String(),
};

final _closed = <String, Object>{
  ..._started,
  recommendationStatusKey: 'closed',
  recommendationClosedAtKey: _today.toIso8601String(),
};

// circle_hero.dart's full First Breath timeline, mirrored rather than read
// from the private constant: 300 + 700 + 300 + 2200 + 500 + 200 + 400 +
// 200 + 350 + 200 + 450 + 300 + 400.
const _firstBreathTotalMs = 6500;

Future<(Widget, SharedPreferences)> _wrap({
  Map<String, Object> storedPrefs = const {},
  ThemeData? theme,
  bool disableAnimations = false,
  double textScale = 1.0,
}) async {
  SharedPreferences.setMockInitialValues(storedPrefs);
  final prefs = await SharedPreferences.getInstance();
  final widget = ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_today),
    ],
    child: MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScale),
          ),
          child: const HomePage(),
        ),
      ),
    ),
  );
  return (widget, prefs);
}

void _setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder _cta(String label) => find.widgetWithText(ThirtyButton, label);

void main() {
  group('Circle rect across the real daily flow', () {
    testWidgets('identical in Ready, Directions and the assigned Circle Hero '
        '(one HomePage, driven by taps)', (tester) async {
      final (widget, _) = await _wrap(disableAnimations: true);
      await tester.pumpWidget(widget);
      final ready = tester.getRect(find.byType(ThirtyProgressCircle));

      await tester.tap(find.text("Begin today's Circle"));
      await tester.pump();
      expect(find.byType(DailyIntentionPrompt), findsOneWidget);
      final directions = tester.getRect(find.byType(ThirtyProgressCircle));

      await tester.ensureVisible(find.text('More Energy'));
      await tester.tap(find.text('More Energy'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircleHero), findsOneWidget);
      // Circle Hero mounts with its own scroll view at offset 0, so the
      // scroll used to reach the option above does not carry over.
      final assigned = tester.getRect(find.byType(ThirtyProgressCircle));

      expect(directions, ready);
      expect(assigned, ready);
    });
  });

  group('Hero CTA', () {
    // 320pt is covered by the QA floor below: there the test font's wide
    // glyphs make "Begin today's Circle" / "Start Circle →" need more than
    // the 231pt column, and the CTA's minWidth lets it grow rather than
    // overflow — by design.
    for (final width in [360.0, 412.0]) {
      testWidgets('${width.toInt()}pt: Begin, Start and Close are 56pt and '
          'exactly the bounded content column wide', (tester) async {
        _setSurface(tester, Size(width, 915));
        final column = HomeCircleMetrics.forWidth(width).textMaxWidth;
        expect(column, lessThan(width - AppSpacing.page * 2 + 1e-9));

        final (ready, _) = await _wrap(disableAnimations: true);
        await tester.pumpWidget(ready);
        expect(tester.getSize(_cta("Begin today's Circle")), Size(column, 56));

        final (notStarted, _) = await _wrap(
          storedPrefs: _chosen,
          disableAnimations: true,
        );
        await tester.pumpWidget(notStarted);
        await tester.pump();
        // Start reserves a mirrored slot for its arrow, so under the test
        // font's wide glyphs its content can exceed the column at 360pt;
        // the CTA's minWidth then lets it grow instead of clipping. It is
        // exactly the column whenever its content fits.
        final startIntrinsic = tester
            .renderObject<RenderBox>(_cta('Start Circle'))
            .getMaxIntrinsicWidth(56);
        expect(
          tester.getSize(_cta('Start Circle')),
          Size(startIntrinsic > column ? startIntrinsic : column, 56),
        );
        expect(
          tester.getSize(_cta('Start Circle')).width,
          lessThanOrEqualTo(width - AppSpacing.page * 2),
        );

        final (started, _) = await _wrap(
          storedPrefs: _started,
          disableAnimations: true,
        );
        await tester.pumpWidget(started);
        await tester.pump();
        expect(tester.getSize(_cta('Close Circle')), Size(column, 56));
      });
    }

    testWidgets('only the Home hero CTA is 56pt — direction choices stay '
        '48pt', (tester) async {
      final (widget, _) = await _wrap(disableAnimations: true);
      await tester.pumpWidget(widget);
      await tester.tap(find.text("Begin today's Circle"));
      await tester.pump();

      final buttons = tester.widgetList<ThirtyButton>(
        find.byType(ThirtyButton),
      );
      expect(buttons, hasLength(3));
      for (final button in buttons) {
        expect(button.size, ThirtyButtonSize.regular, reason: button.label);
      }
    });

    testWidgets('Start Circle alone carries the trailing arrow', (
      tester,
    ) async {
      final (ready, _) = await _wrap(disableAnimations: true);
      await tester.pumpWidget(ready);
      expect(tester.widget<ThirtyButton>(_cta("Begin today's Circle"))
          .trailingIcon, isNull);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);

      final (notStarted, _) = await _wrap(
        storedPrefs: _chosen,
        disableAnimations: true,
      );
      await tester.pumpWidget(notStarted);
      await tester.pump();
      expect(
        find.descendant(
          of: _cta('Start Circle'),
          matching: find.byIcon(Icons.arrow_forward_rounded),
        ),
        findsOneWidget,
      );
      // The arrow is decorative: the button still announces its label only.
      expect(
        tester.getSemantics(_cta('Start Circle')).label,
        'Start Circle',
      );

      final (started, _) = await _wrap(
        storedPrefs: _started,
        disableAnimations: true,
      );
      await tester.pumpWidget(started);
      await tester.pump();
      expect(tester.widget<ThirtyButton>(_cta('Close Circle')).trailingIcon,
          isNull);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    });

    testWidgets('Start Circle label is optically centered on the button and '
        'Circle axis; the arrow sits in the trailing slot', (tester) async {
      final (widget, _) = await _wrap(
        storedPrefs: _chosen,
        disableAnimations: true,
      );
      await tester.pumpWidget(widget);
      await tester.pump();

      final button = tester.getRect(_cta('Start Circle'));
      final label = tester.getRect(find.text('Start Circle'));
      final arrow = tester.getRect(find.byIcon(Icons.arrow_forward_rounded));
      final circleX = tester.getCenter(find.byType(ThirtyProgressCircle)).dx;

      expect(label.center.dx, closeTo(button.center.dx, 0.5));
      expect(label.center.dx, closeTo(circleX, 0.5));
      // Trailing slot: flush with the button's inner (padded) edge, and
      // clear of the label.
      expect(arrow.right, closeTo(button.right - AppSpacing.l, 0.5));
      expect(arrow.left, greaterThanOrEqualTo(label.right));
    });

    for (final size in const [Size(320, 640), Size(360, 640)]) {
      testWidgets('${size.width.toInt()}pt at 200% text: Start label and '
          'arrow never overlap, no overflow', (tester) async {
        _setSurface(tester, size);
        final (widget, _) = await _wrap(
          storedPrefs: _chosen,
          disableAnimations: true,
          textScale: 2.0,
        );
        await tester.pumpWidget(widget);
        await tester.pump();
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(_cta('Start Circle'));
        await tester.pump();
        final button = tester.getRect(_cta('Start Circle'));
        final label = tester.getRect(find.text('Start Circle'));
        final arrow = tester.getRect(
          find.byIcon(Icons.arrow_forward_rounded),
        );
        expect(label.overlaps(arrow), isFalse);
        expect(button.contains(arrow.center), isTrue);
        expect(label.left, greaterThanOrEqualTo(button.left));
        expect(arrow.right, lessThanOrEqualTo(button.right));
        expect(label.center.dx, closeTo(button.center.dx, 0.5));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Start Circle stays inside the reveal-gated IgnorePointer '
        'and still performs the Start transition', (tester) async {
      final (widget, prefs) = await _wrap(storedPrefs: _chosen);
      await tester.pumpWidget(widget);

      final gate = find.ancestor(
        of: _cta('Start Circle'),
        matching: find.byType(IgnorePointer),
      );
      expect(gate, findsWidgets);

      // Mid-ritual: ignored.
      await tester.pump(const Duration(milliseconds: 3000));
      expect(tester.widget<IgnorePointer>(gate.first).ignoring, isTrue);
      await tester.ensureVisible(_cta('Start Circle'));
      await tester.tap(_cta('Start Circle'), warnIfMissed: false);
      await tester.pump();
      expect(find.text('Close Circle'), findsNothing);

      // Settled: accepted, and it is the real lifecycle transition.
      await tester.pumpAndSettle();
      expect(tester.widget<IgnorePointer>(gate.first).ignoring, isFalse);
      await tester.ensureVisible(_cta('Start Circle'));
      await tester.tap(_cta('Start Circle'));
      await tester.pump();
      expect(find.text('Close Circle'), findsOneWidget);
      expect(prefs.getString(recommendationStatusKey), 'started');
    });
  });

  testWidgets('First Breath total duration is unchanged (6500ms)', (
    tester,
  ) async {
    final (widget, prefs) = await _wrap(storedPrefs: _chosen);
    await tester.pumpWidget(widget);
    // The ritual's ticker takes its start time from the first timed frame
    // after mounting; a zero-length pump does not produce one.
    await tester.pump(const Duration(milliseconds: 1));

    await tester.pump(const Duration(milliseconds: _firstBreathTotalMs - 1));
    expect(prefs.getString(firstBreathLastPlayedDateKey), isNull);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(prefs.getString(firstBreathLastPlayedDateKey), '2026-08-02');
  });

  group('Text-column rhythm', () {
    testWidgets('Circle → content gap is the same in Ready and Circle Hero', (
      tester,
    ) async {
      final (ready, _) = await _wrap(disableAnimations: true);
      await tester.pumpWidget(ready);
      final readyGap =
          tester.getTopLeft(_cta("Begin today's Circle")).dy -
          tester.getBottomLeft(find.byType(ThirtyProgressCircle)).dy;

      final (assigned, _) = await _wrap(
        storedPrefs: _chosen,
        disableAnimations: true,
      );
      await tester.pumpWidget(assigned);
      await tester.pump();
      final heroGap =
          tester.getTopLeft(find.text("Today's Circle")).dy -
          tester.getBottomLeft(find.byType(ThirtyProgressCircle)).dy;

      expect(readyGap, HomeCircleMetrics.circleToContentGap);
      expect(heroGap, HomeCircleMetrics.circleToContentGap);
    });

    testWidgets('eyebrow, hero line, activity, support and CTA follow the '
        'Home rhythm', (tester) async {
      final (widget, _) = await _wrap(
        storedPrefs: _chosen,
        disableAnimations: true,
      );
      await tester.pumpWidget(widget);
      await tester.pump();

      double gap(Finder above, Finder below) =>
          tester.getTopLeft(below).dy - tester.getBottomLeft(above).dy;

      final recommendation = ProviderScope.containerOf(
        tester.element(find.byType(HomePage)),
      ).read(recommendationProvider).recommendation!;
      final eyebrow = find.text("Today's Circle");
      final intent = find.text(recommendation.intent);
      final activity = find.text(recommendation.activity);
      final why = find.text(recommendation.why);
      expect(gap(eyebrow, intent), HomeCircleMetrics.eyebrowToHeroGap);
      expect(gap(intent, activity), HomeCircleMetrics.heroToActivityGap);
      expect(gap(activity, why), HomeCircleMetrics.activityToSupportGap);
      expect(gap(why, _cta('Start Circle')), HomeCircleMetrics.contentToCtaGap);
    });
  });

  group('QA floor — 200% text', () {
    for (final size in const [Size(320, 568), Size(360, 640)]) {
      final name = '${size.width.toInt()}x${size.height.toInt()}';
      for (final (state, prefs) in [
        ('Ready', const <String, Object>{}),
        ('assigned', _chosen),
        ('started', _started),
        ('closed', _closed),
      ]) {
        testWidgets('$name, $state: no overflow', (tester) async {
          _setSurface(tester, size);
          final (widget, _) = await _wrap(
            storedPrefs: prefs,
            disableAnimations: true,
            textScale: 2.0,
          );
          await tester.pumpWidget(widget);
          await tester.pump();
          expect(tester.takeException(), isNull);

          if (state == 'Ready') {
            await tester.ensureVisible(find.text("Begin today's Circle"));
            await tester.tap(find.text("Begin today's Circle"));
            await tester.pump();
            expect(tester.takeException(), isNull);
            expect(find.byType(DailyIntentionPrompt), findsOneWidget);
          }
        });
      }
    }
  });
}
