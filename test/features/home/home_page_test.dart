import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/home_page.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';
import 'package:thirty/features/home/presentation/widgets/daily_intention_prompt.dart';

final _today = DateTime(2026, 8, 2);

Future<Widget> _wrap({Map<String, Object> storedPrefs = const {}}) async {
  SharedPreferences.setMockInitialValues(storedPrefs);
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_today),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const HomePage()),
  );
}

void main() {
  testWidgets(
    'shows the Daily Context Question when today has no recommendation yet',
    (WidgetTester tester) async {
      await tester.pumpWidget(await _wrap());

      expect(find.byType(DailyIntentionPrompt), findsOneWidget);
      expect(find.byType(CircleHero), findsNothing);
    },
  );

  testWidgets(
    'renders the Circle Hero experience once today\'s recommendation exists',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        await _wrap(
          storedPrefs: {
            recommendationDayKey: '2026-08-02',
            recommendationIntentionKey: 'moreEnergy',
            recommendationActivityIdKey: 'thirtyMinuteWalk',
          },
        ),
      );

      expect(find.byType(CircleHero), findsOneWidget);
      expect(find.byType(DailyIntentionPrompt), findsNothing);
    },
  );
}
