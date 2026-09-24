import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/routing/app_shell.dart';
import 'package:thirty/core/theme/design_tokens.dart';

final _root = GlobalKey();

/// The floating nav exactly as `AppShell` composes it — same margins, same
/// surface, a real four-destination [NavigationBar] — without GoRouter.
Widget _floatingNav(ThemeData theme, {double textScale = 1}) {
  return RepaintBoundary(
    key: _root,
    child: MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.m,
                  0,
                  AppSpacing.m,
                  AppSpacing.s,
                ),
                child: FloatingNavSurface(
                  child: NavigationBar(
                    selectedIndex: 0,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        label: 'Today',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.route_outlined),
                        label: 'Plans',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.insights_outlined),
                        label: 'Insights',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        label: 'You',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<ByteData> _capture(WidgetTester tester) async {
  return (await tester.runAsync(() async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    return (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  }))!;
}

Color _pixel(ByteData bytes, int width, Offset at) {
  final i = (at.dy.floor() * width + at.dx.floor()) * 4;
  return Color.fromARGB(
    bytes.getUint8(i + 3),
    bytes.getUint8(i),
    bytes.getUint8(i + 1),
    bytes.getUint8(i + 2),
  );
}

double _distance(Color a, Color b) {
  final dr = a.r - b.r, dg = a.g - b.g, db = a.b - b.b;
  return dr * dr + dg * dg + db * db;
}

void main() {
  for (final (mode, theme, colors) in [
    ('light', AppTheme.light, AppColors.light),
    ('dark', AppTheme.dark, AppColors.dark),
  ]) {
    group('FloatingNavSurface — $mode', () {
      testWidgets('one authoritative surface: the container owns color, '
          '24pt radius and shadow; no outer border', (tester) async {
        await tester.pumpWidget(_floatingNav(theme));

        final decoration =
            tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(FloatingNavSurface),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        expect(decoration.color, colors.surface);
        expect(decoration.borderRadius, AppRadius.xl);
        expect(
          decoration.boxShadow,
          mode == 'light' ? AppShadows.light : AppShadows.dark,
        );
        expect(decoration.border, isNull);

        final clip = tester.widget<ClipRRect>(
          find.descendant(
            of: find.byType(FloatingNavSurface),
            matching: find.byType(ClipRRect),
          ),
        );
        expect(clip.borderRadius, AppRadius.xl);
        expect(clip.clipBehavior, Clip.antiAlias);

        // The bar itself paints no surface of its own.
        final barMaterial = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(NavigationBar),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(barMaterial.color, Colors.transparent);
      });

      testWidgets('nothing paints outside the rounded corners', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_floatingNav(theme));

        final rect = tester.getRect(find.byType(FloatingNavSurface));
        final bytes = await _capture(tester);
        const width = 360;

        // Just inside each bounding-box corner — ~31pt from the arc's
        // centre, well outside the 24pt radius — must read as the page
        // (plus at most a faint shadow), never as the bar's surface.
        for (final corner in [
          rect.topLeft + const Offset(2, 2),
          rect.topRight + const Offset(-3, 2),
          rect.bottomLeft + const Offset(2, -3),
          rect.bottomRight + const Offset(-3, -3),
        ]) {
          final seen = _pixel(bytes, width, corner);
          expect(
            _distance(seen, colors.background),
            lessThan(_distance(seen, colors.surface)),
            reason: 'surface leaked into the corner at $corner ($seen)',
          );
        }

        // And the bar's own edge, away from the corners, is the surface.
        final edge = _pixel(bytes, width, Offset(rect.left + 4, rect.center.dy));
        expect(edge, colors.surface);
      });

      testWidgets('at 360pt and 200% text every label still fits', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_floatingNav(theme, textScale: 2));

        expect(tester.takeException(), isNull);
        for (final label in ['Today', 'Plans', 'Insights', 'You']) {
          expect(find.text(label).hitTestable(), findsOneWidget);
        }
      });
    });
  }
}
