import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/core/widgets/thirty_button.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

/// Audit remediation R6: a loading ThirtyButton told TalkBack
/// "<label>, bezig" — Dutch inside the English app. It now says the
/// English busy label; everything else about the button is unchanged.
void main() {
  group('R6 — the busy label is English', () {
    testWidgets('loading: "<label>, in progress", disabled, a live region — no '
        'Dutch', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(ThirtyButton(label: 'Save', onPressed: () {}, isLoading: true)),
      );
      final node = tester.getSemantics(find.byType(ThirtyButton));
      expect(node.label, 'Save, in progress');
      expect(node.label, isNot(contains('bezig')));
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(node.flagsCollection.isLiveRegion, isTrue);
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('not loading: the label alone, enabled, no live region', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(ThirtyButton(label: 'Save', onPressed: () {})),
      );
      final node = tester.getSemantics(find.byType(ThirtyButton));
      expect(node.label, 'Save');
      expect(node.flagsCollection.isEnabled, Tristate.isTrue);
      expect(node.flagsCollection.isLiveRegion, isFalse);
      handle.dispose();
    });

    testWidgets('disabled (no action), not loading: the label alone', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(const ThirtyButton(label: 'Save', onPressed: null)),
      );
      final node = tester.getSemantics(find.byType(ThirtyButton));
      expect(node.label, 'Save');
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('a focused loading button keeps the English label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _wrap(
          ThirtyButton(
            label: 'Save',
            onPressed: () {},
            isLoading: true,
            focusNode: focus,
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      expect(
        tester.getSemantics(find.byType(ThirtyButton)).label,
        'Save, in progress',
      );
      handle.dispose();
    });

    test('the busy label is built in one place', () {
      expect(ThirtyButtonCopy.busy('Keep'), 'Keep, in progress');
    });
  });
}
