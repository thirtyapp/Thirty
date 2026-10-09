import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/activity_category.dart';
import 'package:thirty/core/theme/app_colors.dart';
import 'package:thirty/core/theme/app_spacing.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/presentation/widgets/today_card.dart';

const _asset = 'assets/worlds/reading_nook/read/card_evening.webp';

Widget _card(ThemeData theme, {double textScale = 1}) => MaterialApp(
  theme: theme,
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(412, 915),
      textScaler: TextScaler.linear(textScale),
    ),
    child: const Scaffold(
      body: TodayCard(
        intent: 'Clearer Head',
        activity: 'Quiet reading',
        why: 'For a clearer head: quiet reading.',
        category: ActivityCategory.quietFocus,
        minutes: 20,
        firstAction: 'Pick up what you are already reading.',
        showFirstAction: false,
        onShowGuide: null,
        cardAsset: _asset,
        intentOpacity: AlwaysStoppedAnimation(1),
        detailOpacity: AlwaysStoppedAnimation(1),
      ),
    ),
  ),
);

List<Image> _images(WidgetTester tester) =>
    tester.widgetList<Image>(find.byType(Image)).toList();

void main() {
  group('TodayCard World art', () {
    testWidgets('light: the art alone, at full opacity, with no backing', (
      tester,
    ) async {
      await tester.pumpWidget(_card(AppTheme.light));

      final images = _images(tester);
      expect(images, hasLength(1));
      expect((images.single.image as AssetImage).assetName, _asset);
      expect(images.single.color, isNull);
      expect(
        tester
            .widget<Opacity>(
              find.ancestor(
                of: find.byType(Image),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        1.0,
      );
    });

    testWidgets('dark: the art over its own Cream paper silhouette, lightly '
        'dimmed (WORLD_SYSTEM.md §10a)', (tester) async {
      await tester.pumpWidget(_card(AppTheme.dark));

      final images = _images(tester);
      expect(images, hasLength(2));
      for (final image in images) {
        expect((image.image as AssetImage).assetName, _asset);
      }
      final paper = images.first;
      expect(paper.colorBlendMode, BlendMode.srcIn);
      expect(paper.color!.a, closeTo(0.12, 0.001));
      expect(
        paper.color!.withValues(alpha: 1),
        AppColors.light.background.withValues(alpha: 1),
      );
      expect(images.last.color, isNull);
      expect(
        tester
            .widget<Opacity>(
              find.ancestor(
                of: find.byWidget(images.last),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        0.85,
      );
    });

    testWidgets('the art is decorative in both themes', (tester) async {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(_card(theme));
        expect(find.bySemanticsLabel(RegExp(r'assets/|\.webp')), findsNothing);
        semantics.dispose();
      }
    });

    testWidgets('large text hides the art in dark mode too', (tester) async {
      await tester.pumpWidget(_card(AppTheme.dark, textScale: 1.3));
      expect(find.byType(Image), findsNothing);
      expect(find.text('Quiet reading'), findsOneWidget);
    });

    testWidgets('one art viewport in both themes: right of the text '
        'content, full card height and more', (tester) async {
      Rect artRect() => tester.getRect(find.byType(Image).last);

      await tester.pumpWidget(_card(AppTheme.light));
      final light = artRect();
      await tester.pumpWidget(_card(AppTheme.dark));
      final dark = artRect();
      expect(dark, light);

      final card = tester.getRect(find.byType(TodayCard));
      // The text column keeps 75% of the card, less its own padding.
      expect(light.left, closeTo(card.left + card.width * 0.75 - 24, 0.5));
      expect(light.top, lessThan(card.top));
      expect(light.bottom, greaterThan(card.bottom));
      expect(light.right, greaterThan(card.right));
      // Drawn at 112% of the card's height (approved V1 treatment).
      expect(light.height, closeTo(card.height * 1.12, 0.5));
    });
  });

  group('TodayCard reason and first action (S25 device findings)', () {
    // Real glyph widths, not the test font's: whether a line wraps or
    // truncates depends on them.
    setUpAll(() async {
      final inter = FontLoader('Inter')
        ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'));
      await inter.load();
    });

    // A Galaxy S25 at its default display size (411 × 891 dp), with Home's
    // page margins either side of the card.
    Widget card(ActivityId id, {required bool running, double scale = 1}) {
      final activity = activityDefinition(id);
      return MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(411, 891),
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: TodayCard(
                intent: 'More Energy',
                activity: activity.title,
                why: activity.reasons.values.first,
                category: activity.category,
                minutes: activity.typicalMinutes,
                firstAction: activity.firstAction,
                showFirstAction: running,
                onShowGuide: () {},
                cardAsset: _asset,
                intentOpacity: const AlwaysStoppedAnimation(1),
                detailOpacity: const AlwaysStoppedAnimation(1),
              ),
            ),
          ),
        ),
      );
    }

    String text(ActivityId id, {required bool running}) => running
        ? activityDefinition(id).firstAction
        : activityDefinition(id).reasons.values.first;

    Iterable<ActivityId> offerable() => ActivityId.values.where(
      (id) => isActivityOfferable(id, allowSafetyPending: true),
    );

    void useS25(WidgetTester tester) {
      tester.view.physicalSize = const Size(411, 891);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('at normal text, beside the World art, every reason fits two '
        'lines and every first action three, so the card stays compact', (
      tester,
    ) async {
      useS25(tester);
      // bodyMedium: 14pt at a 1.5 line height.
      const line = 14 * 1.5;
      final tooLong = <String>[];
      for (final id in offerable()) {
        for (final (running, lines) in [(false, 2), (true, 3)]) {
          await tester.pumpWidget(card(id, running: running));
          expect(find.byType(Image), findsOneWidget, reason: '$id: art shown');
          final copy = text(id, running: running);
          if (tester.getSize(find.text(copy)).height > lines * line + 0.5) {
            tooLong.add('$id: $copy');
          }
        }
      }
      expect(tooLong, isEmpty);
    });

    testWidgets('with enlarged text that still shows the World art, nothing '
        'is cut off — the card grows instead', (tester) async {
      useS25(tester);
      final truncated = <String>[];
      for (final id in offerable()) {
        for (final running in [false, true]) {
          await tester.pumpWidget(card(id, running: running, scale: 1.29));
          expect(find.byType(Image), findsOneWidget, reason: '$id: art shown');
          final copy = text(id, running: running);
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(copy),
          );
          if (paragraph.didExceedMaxLines) truncated.add('$id: $copy');
        }
      }
      expect(truncated, isEmpty);
    });
  });
}
