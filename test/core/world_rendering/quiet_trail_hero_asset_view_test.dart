import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/world_rendering/quiet_trail_hero_asset_view.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('QuietTrailHeroAssetView', () {
    testWidgets('renders without exceptions', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 200,
            height: 200,
            child: QuietTrailHeroAssetView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(QuietTrailHeroAssetView), findsOneWidget);
    });

    testWidgets('clips the illustration to a circle', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 200,
            height: 200,
            child: QuietTrailHeroAssetView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ClipOval), findsOneWidget);
    });

    testWidgets('uses the approved master illustration asset', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 200,
            height: 200,
            child: QuietTrailHeroAssetView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as AssetImage;

      expect(
        provider.assetName,
        'assets/worlds/quiet_trail/quiet_trail_hero_master_v1.png',
      );
      expect(image.fit, BoxFit.cover);
      expect(image.alignment, Alignment.center);
      expect(image.filterQuality, FilterQuality.high);
    });

    testWidgets('preserves a square aspect ratio at any given size', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 200,
            height: 340,
            child: QuietTrailHeroAssetView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final aspectRatio = tester.widget<AspectRatio>(
        find.byType(AspectRatio),
      );
      expect(aspectRatio.aspectRatio, 1);
    });

    testWidgets('is decorative and carries no semantic content', (
      tester,
    ) async {
      // Mirrors QuietTrailHeroView's own semantics test
      // (quiet_trail_hero_view_test.dart): find.byType would simply walk
      // up to the nearest ancestor node that has semantics rather than
      // proving this widget contributes none, so an isolated,
      // explicit-children probe is used instead.
      const probeKey = Key('quiet-trail-hero-asset-semantics-probe');
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          Semantics(
            key: probeKey,
            container: true,
            explicitChildNodes: true,
            child: const SizedBox(
              width: 200,
              height: 200,
              child: QuietTrailHeroAssetView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final probeSemantics = tester.getSemantics(find.byKey(probeKey));
      expect(probeSemantics.childrenCount, 0);

      handle.dispose();
    });
  });
}
