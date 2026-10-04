import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/providers/theme_mode_provider.dart';

Future<(ProviderContainer, SharedPreferences)> _container([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return (container, prefs);
}

void main() {
  group('themeModeProvider', () {
    test('no stored value → System', () async {
      final (container, _) = await _container();
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    for (final mode in ThemeMode.values) {
      test('selecting ${mode.name} updates state and stores it', () async {
        final (container, prefs) = await _container();
        container.read(themeModeProvider.notifier).setThemeMode(mode);
        expect(container.read(themeModeProvider), mode);
        expect(prefs.getString(themeModeKey), mode.name);
      });

      test('stored ${mode.name} rehydrates as ${mode.name} on a cold '
          'start', () async {
        final (container, _) = await _container({themeModeKey: mode.name});
        expect(container.read(themeModeProvider), mode);
      });
    }

    test('a choice survives a new container over the same storage — the '
        'cold-start path', () async {
      final (first, prefs) = await _container();
      first.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      await pumpEventQueue();

      final restarted = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(restarted.dispose);
      expect(restarted.read(themeModeProvider), ThemeMode.dark);
    });

    for (final malformed in ['', 'Dark', 'sepia', 'ThemeMode.dark']) {
      test(
        'malformed stored value "$malformed" falls back to System',
        () async {
          final (container, _) = await _container({themeModeKey: malformed});
          expect(container.read(themeModeProvider), ThemeMode.system);
        },
      );
    }

    test('a stored value of the wrong type falls back to System', () async {
      SharedPreferences.setMockInitialValues({themeModeKey: 2});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      expect(
        () => container.read(themeModeProvider),
        returnsNormally,
        reason: 'a corrupt preference must never break app start',
      );
      expect(container.read(themeModeProvider), ThemeMode.system);
    });
  });
}
