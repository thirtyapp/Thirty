import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/presentation/home_page.dart';

Widget _wrap() {
  return ProviderScope(
    child: MaterialApp(theme: AppTheme.light, home: const HomePage()),
  );
}

void main() {
  testWidgets('HomePage shows the THIRTY brand name and slogan', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());

    expect(find.text('THIRTY'), findsOneWidget);
    expect(find.text('Your healthiest 30 minutes.'), findsOneWidget);
  });

  testWidgets("HomePage shows today's recommendation", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());

    expect(find.text('Meer energie'), findsOneWidget);
    expect(find.text('30 minuten wandelen'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('tapping Start updates the button label locally', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());

    await tester.tap(find.text('Start'));
    await tester.pump();

    expect(find.text('Gestart'), findsOneWidget);
    expect(find.text('Start'), findsNothing);
  });
}
