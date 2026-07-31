import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/presentation/home_page.dart';

void main() {
  testWidgets('HomePage shows the THIRTY brand name and slogan', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const HomePage()),
    );

    expect(find.text('THIRTY'), findsOneWidget);
    expect(find.text('Your healthiest 30 minutes.'), findsOneWidget);
  });
}
