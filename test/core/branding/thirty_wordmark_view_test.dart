import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/branding/thirty_wordmark_view.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('ThirtyWordmarkView', () {
    testWidgets('renders without exceptions', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(width: 200, height: 60, child: ThirtyWordmarkView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ThirtyWordmarkView), findsOneWidget);
    });

    testWidgets('renders exactly one SvgPicture', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(width: 200, height: 60, child: ThirtyWordmarkView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('uses the approved wordmark asset', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(width: 200, height: 60, child: ThirtyWordmarkView()),
        ),
      );
      await tester.pumpAndSettle();

      final svgPicture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      final loader = svgPicture.bytesLoader as SvgAssetLoader;

      expect(loader.assetName, 'assets/brand/thirty_wordmark.svg');
      expect(svgPicture.fit, BoxFit.contain);
    });

    testWidgets(
      "preserves the SVG's own aspect ratio when given only a width, no "
      'height',
      (tester) async {
        const width = 200.0;
        // assets/brand/thirty_wordmark.svg's own viewBox
        // (`166.30199 x 34.217251`) — the widget must guard this ratio
        // itself, since a caller giving only a width (no height) is
        // exactly how this widget is actually used (e.g. CircleHero).
        const expectedAspectRatio = 166.30199 / 34.217251;

        await tester.pumpWidget(
          _wrap(const SizedBox(width: width, child: ThirtyWordmarkView())),
        );
        await tester.pumpAndSettle();

        final size = tester.getSize(find.byType(ThirtyWordmarkView));

        expect(size.width, width);
        expect(size.height, closeTo(width / expectedAspectRatio, 0.01));
      },
    );

    testWidgets('is decorative and carries no semantic content', (
      tester,
    ) async {
      // Mirrors QuietTrailHeroAssetView's own semantics test
      // (quiet_trail_hero_asset_view_test.dart): find.byType would simply
      // walk up to the nearest ancestor node that has semantics rather
      // than proving this widget contributes none, so an isolated,
      // explicit-children probe is used instead.
      const probeKey = Key('thirty-wordmark-semantics-probe');
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          Semantics(
            key: probeKey,
            container: true,
            explicitChildNodes: true,
            child: const SizedBox(
              width: 200,
              height: 60,
              child: ThirtyWordmarkView(),
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
