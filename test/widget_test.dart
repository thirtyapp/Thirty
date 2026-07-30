import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/main.dart';

void main() {
  testWidgets('ThirtyApp starts and shows the design system showcase', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ThirtyApp());
    await tester.pumpAndSettle();

    expect(find.text('THIRTY — Design System'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
