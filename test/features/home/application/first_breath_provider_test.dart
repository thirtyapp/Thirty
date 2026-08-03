import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';

final _today = DateTime(2026, 8, 2);

Future<ProviderContainer> _containerWith(
  Map<String, Object> storedPrefs,
) async {
  SharedPreferences.setMockInitialValues(storedPrefs);
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_today),
    ],
  );
  return container;
}

void main() {
  group('firstBreathProvider', () {
    test('plays when no date has ever been stored', () async {
      final container = await _containerWith({});
      addTearDown(container.dispose);

      expect(container.read(firstBreathProvider), isTrue);
    });

    test('does not play when the stored date is today', () async {
      final container = await _containerWith({
        firstBreathLastPlayedDateKey: '2026-08-02',
      });
      addTearDown(container.dispose);

      expect(container.read(firstBreathProvider), isFalse);
    });

    test('plays again when the stored date is yesterday', () async {
      final container = await _containerWith({
        firstBreathLastPlayedDateKey: '2026-08-01',
      });
      addTearDown(container.dispose);

      expect(container.read(firstBreathProvider), isTrue);
    });

    test('marking today as played makes subsequent reads skip it', () async {
      final container = await _containerWith({});
      addTearDown(container.dispose);

      expect(container.read(firstBreathProvider), isTrue);

      await container.read(firstBreathProvider.notifier).markPlayedToday();

      expect(container.read(firstBreathProvider), isFalse);

      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getString(firstBreathLastPlayedDateKey), '2026-08-02');
    });
  });
}
