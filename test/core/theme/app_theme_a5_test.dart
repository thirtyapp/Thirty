import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/theme/design_tokens.dart';

void main() {
  group('Phase A5 dialog shape', () {
    for (final (name, theme) in [
      ('light', AppTheme.light),
      ('dark', AppTheme.dark),
    ]) {
      test('$name: dialogs and the time picker share the 24pt card radius', () {
        const expected = RoundedRectangleBorder(borderRadius: AppRadius.xl);
        expect(theme.dialogTheme.shape, expected);
        expect(theme.timePickerTheme.shape, expected);
      });
    }

    testWidgets('a rendered AlertDialog uses the 24pt radius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const AlertDialog(title: Text('Title')),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(Material),
        ),
      );
      expect(
        material.shape,
        const RoundedRectangleBorder(borderRadius: AppRadius.xl),
      );
    });
  });
}
