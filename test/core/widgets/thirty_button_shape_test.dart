import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_button.dart';

/// [ThirtyButton]'s shape follows its rendered label, with the app's real
/// fonts: the pill for one or two lines; the card's 24pt corner radius only
/// once a label allowed past two lines ([ThirtyButton.maxLabelLines]
/// `null`, Phase C4) actually renders in three or more. The two-line
/// default, semantics and loading are unchanged.

const _long = 'Use lighter guidance as this Plan\'s default';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(file).readAsBytesSync())),
    );
  }
  await loader.load();
}

Widget _button(
  ThirtyButton button, {
  required double width,
  double textScale = 1.0,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: button),
        ),
      ),
    ),
  );
}

BorderRadiusGeometry _radius(WidgetTester tester) {
  final material = tester.widget<Material>(
    find
        .descendant(
          of: find.byType(ThirtyButton),
          matching: find.byType(Material),
        )
        .first,
  );
  return (material.shape! as RoundedRectangleBorder).borderRadius;
}

RenderParagraph _label(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: find.byType(ThirtyButton), matching: find.text(text)),
    );

int _lineCount(RenderParagraph paragraph) => paragraph
    .getBoxesForSelection(
      TextSelection(
        baseOffset: 0,
        extentOffset: paragraph.text.toPlainText().length,
      ),
    )
    .map((box) => box.top)
    .toSet()
    .length;

void main() {
  setUpAll(() async {
    await _loadFont('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ]);
  });

  test('the two-line limit stays the default', () {
    expect(ThirtyButton(label: 'x', onPressed: () {}).maxLabelLines, 2);
  });

  testWidgets('one line: the pill', (tester) async {
    await tester.pumpWidget(
      _button(
        ThirtyButton(label: 'Resume this Plan', onPressed: () {}),
        width: 264,
      ),
    );
    expect(_lineCount(_label(tester, 'Resume this Plan')), 1);
    expect(_radius(tester), AppRadius.pill);
  });

  testWidgets('two lines (default limit, 200%): still the pill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _button(
        ThirtyButton(label: 'Manage subscription', onPressed: () {}),
        width: 224,
        textScale: 2.0,
      ),
    );
    expect(_lineCount(_label(tester, 'Manage subscription')), 2);
    expect(_radius(tester), AppRadius.pill);
  });

  testWidgets('a long label under the default limit still ellipsizes at two '
      'lines, as a pill', (tester) async {
    await tester.pumpWidget(
      _button(
        ThirtyButton(label: _long, onPressed: () {}),
        width: 224,
        textScale: 2.0,
      ),
    );
    final label = _label(tester, _long);
    expect(label.didExceedMaxLines, isTrue);
    expect(_lineCount(label), 2);
    expect(_radius(tester), AppRadius.pill);
  });

  testWidgets('unlimited, but rendering in two lines: the pill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _button(
        ThirtyButton(label: _long, maxLabelLines: null, onPressed: () {}),
        width: 264,
      ),
    );
    expect(_lineCount(_label(tester, _long)), 2);
    expect(_radius(tester), AppRadius.pill);
  });

  for (final width in const [224.0, 264.0]) {
    testWidgets('unlimited, three or more lines at 200% (${width.toInt()}pt): '
        'complete label, 24pt corners', (tester) async {
      await tester.pumpWidget(
        _button(
          ThirtyButton(label: _long, maxLabelLines: null, onPressed: () {}),
          width: width,
          textScale: 2.0,
        ),
      );
      final label = _label(tester, _long);
      expect(label.didExceedMaxLines, isFalse);
      expect(_lineCount(label), greaterThanOrEqualTo(3));
      expect(_radius(tester), AppRadius.xl);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the taller shape keeps semantics and the loading size', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _button(
        ThirtyButton(label: _long, maxLabelLines: null, onPressed: () {}),
        width: 224,
        textScale: 2.0,
      ),
    );
    final idle = tester.getSize(find.byType(ThirtyButton));
    expect(
      tester.getSemantics(find.byType(ThirtyButton)),
      matchesSemantics(
        label: _long,
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );

    await tester.pumpWidget(
      _button(
        ThirtyButton(
          label: _long,
          maxLabelLines: null,
          isLoading: true,
          onPressed: () {},
        ),
        width: 224,
        textScale: 2.0,
      ),
    );
    expect(tester.getSize(find.byType(ThirtyButton)), idle);
    expect(_radius(tester), AppRadius.xl);
    expect(
      tester.getSemantics(find.byType(ThirtyButton)).label,
      '$_long, bezig',
    );
    handle.dispose();
  });
}
