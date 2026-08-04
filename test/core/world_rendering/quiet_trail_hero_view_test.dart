import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/world_rendering/quiet_trail_hero_view.dart';
import 'package:thirty/core/worlds/reference/quiet_trail_hero_scene.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));
}

final _baseScene = QuietTrailHeroScene(
  atmosphereIntensity: 0.6,
  lightWarmth: LightWarmth.warm,
  showDistantHills: true,
  showMiddleLandscape: true,
  showTree: true,
  showPath: true,
  vegetationDensity: 0.35,
  birds: const [
    BirdPlacement(x: 0.20, y: 0.22),
    BirdPlacement(x: 0.32, y: 0.16, scale: 0.85),
    BirdPlacement(x: 0.62, y: 0.24, scale: 1.1),
  ],
);

void main() {
  group('QuietTrailHeroView', () {
    testWidgets('renders without exceptions at a small size', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 4,
            height: 4,
            child: QuietTrailHeroView(scene: _baseScene),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(QuietTrailHeroView), findsOneWidget);
    });

    testWidgets('renders without exceptions at a large size', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 2000,
            height: 2000,
            child: QuietTrailHeroView(scene: _baseScene),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(QuietTrailHeroView), findsOneWidget);
    });

    testWidgets('remains inside the bounds it is given', (tester) async {
      const bounds = Size(240, 240);
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: bounds.width,
            height: bounds.height,
            child: QuietTrailHeroView(scene: _baseScene),
          ),
        ),
      );

      expect(tester.getSize(find.byType(QuietTrailHeroView)), bounds);
    });

    testWidgets('is decorative and carries no semantic content', (
      tester,
    ) async {
      // find.byType(QuietTrailHeroView) is not usable here: since the
      // widget excludes all of its own semantics, tester.getSemantics
      // would simply walk up to the nearest ancestor node that *does*
      // have one (MaterialApp's route boundary) and report that instead.
      // Wrapping it in an explicit, isolated Semantics container and
      // asserting that container has zero children is what actually
      // proves this widget contributes nothing to the semantics tree.
      const probeKey = Key('quiet-trail-hero-semantics-probe');
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          Semantics(
            key: probeKey,
            container: true,
            explicitChildNodes: true,
            child: SizedBox(
              width: 200,
              height: 200,
              child: QuietTrailHeroView(scene: _baseScene),
            ),
          ),
        ),
      );

      final probeSemantics = tester.getSemantics(find.byKey(probeKey));
      expect(probeSemantics.childrenCount, 0);

      handle.dispose();
    });

    testWidgets('renders every documented scene variation without throwing', (
      tester,
    ) async {
      final scenes = <QuietTrailHeroScene>[
        _baseScene,
        QuietTrailHeroScene(
          atmosphereIntensity: 0,
          lightWarmth: LightWarmth.cool,
          showDistantHills: false,
          showMiddleLandscape: false,
          showTree: false,
          showPath: false,
          vegetationDensity: 0,
          birds: const [
            BirdPlacement(x: 0.1, y: 0.1),
            BirdPlacement(x: 0.9, y: 0.9),
          ],
        ),
        QuietTrailHeroScene(
          atmosphereIntensity: 1,
          lightWarmth: LightWarmth.neutral,
          showDistantHills: true,
          showMiddleLandscape: true,
          showTree: true,
          showPath: true,
          vegetationDensity: 1,
          birds: const [
            BirdPlacement(x: 0.0, y: 0.0),
            BirdPlacement(x: 0.5, y: 0.5),
            BirdPlacement(x: 1.0, y: 1.0),
          ],
        ),
      ];

      for (final scene in scenes) {
        await tester.pumpWidget(
          _wrap(
            SizedBox(
              width: 220,
              height: 220,
              child: QuietTrailHeroView(scene: scene),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('does not require a ProviderScope or recommendation state', (
      tester,
    ) async {
      // Deliberately no ProviderScope anywhere in this file's _wrap — if
      // this widget silently depended on Home's recommendation state, this
      // test would fail to build instead of passing.
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 100,
            height: 100,
            child: QuietTrailHeroView(scene: _baseScene),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
