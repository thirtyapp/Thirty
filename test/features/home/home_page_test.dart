import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/presentation/home_page.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';

Future<Widget> _wrap() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(theme: AppTheme.light, home: const HomePage()),
  );
}

void main() {
  testWidgets('HomePage renders the Circle Hero experience', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await _wrap());

    expect(find.byType(CircleHero), findsOneWidget);
  });
}
