import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/widgets/viewport_visibility.dart';

/// A 600pt-tall test viewport with a 100pt target placed [offsetAbove]
/// below the top of a scrollable column.
Widget _scrollingTarget({
  required VoidCallback onVisible,
  required double offsetAbove,
  ScrollController? controller,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        controller: controller,
        child: Column(
          children: [
            SizedBox(height: offsetAbove),
            ViewportVisibility(
              onVisible: onVisible,
              child: const SizedBox(height: 100, child: Text('target')),
            ),
            const SizedBox(height: 2000),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('does not fire while the child is below the fold', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      _scrollingTarget(onVisible: () => calls++, offsetAbove: 1000),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(calls, 0);
  });

  testWidgets('fires once after the dwell once scrolled into view, and never '
      'again when scrolled away and back', (tester) async {
    var calls = 0;
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _scrollingTarget(
        onVisible: () => calls++,
        offsetAbove: 1000,
        controller: controller,
      ),
    );

    controller.jumpTo(700);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(calls, 0, reason: 'not yet for the full dwell');
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls, 1);

    controller.jumpTo(0);
    await tester.pump(const Duration(seconds: 2));
    controller.jumpTo(700);
    await tester.pump(const Duration(seconds: 2));
    expect(calls, 1);
  });

  testWidgets('a pass through the viewport shorter than the dwell does not '
      'count', (tester) async {
    var calls = 0;
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _scrollingTarget(
        onVisible: () => calls++,
        offsetAbove: 1000,
        controller: controller,
      ),
    );

    controller.jumpTo(700);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    controller.jumpTo(1800);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(calls, 0);
  });

  testWidgets('needs at least half of the child in view', (tester) async {
    var calls = 0;
    // Top of the 100pt target at 560: only 40pt inside a 600pt viewport.
    await tester.pumpWidget(
      _scrollingTarget(onVisible: () => calls++, offsetAbove: 560),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(calls, 0);

    await tester.pumpWidget(
      _scrollingTarget(onVisible: () => calls++, offsetAbove: 540),
    );
    await tester.pump(const Duration(seconds: 2));
    // Same State, re-checked on update: 60pt of 100pt is enough.
    expect(calls, 1);
  });

  testWidgets('does not fire inside an inactive (TickerMode-disabled) '
      'subtree, like an offstage tab', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TickerMode(
          enabled: false,
          child: ViewportVisibility(
            onVisible: () => calls++,
            child: const SizedBox(height: 100, child: Text('target')),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(calls, 0);
  });

  testWidgets('does not fire while another route covers it', (tester) async {
    var calls = 0;
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: ViewportVisibility(
          onVisible: () => calls++,
          dwell: const Duration(seconds: 1),
          child: const SizedBox(height: 100, child: Text('target')),
        ),
      ),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Text('covering')),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    expect(calls, 0);
  });
}
