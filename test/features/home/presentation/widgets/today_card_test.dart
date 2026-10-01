import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/activity_category.dart';
import 'package:thirty/core/theme/app_colors.dart';
import 'package:thirty/core/theme/app_theme.dart';
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
}
