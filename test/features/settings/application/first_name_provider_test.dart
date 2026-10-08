import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';

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
  group('firstNameProvider — reading', () {
    test('no stored value → null', () async {
      final (container, _) = await _container();
      expect(container.read(firstNameProvider), isNull);
    });

    test('a stored valid name rehydrates', () async {
      final (container, _) = await _container({firstNameKey: 'Thomas'});
      expect(container.read(firstNameProvider), 'Thomas');
    });

    test('an empty stored string → null', () async {
      final (container, _) = await _container({firstNameKey: ''});
      expect(container.read(firstNameProvider), isNull);
    });

    test('a whitespace-only stored string → null', () async {
      final (container, _) = await _container({firstNameKey: '  \t '});
      expect(container.read(firstNameProvider), isNull);
    });

    for (final (label, value) in [
      ('an int', 7 as Object),
      ('a bool', true),
      ('a string list', <String>['Thomas']),
    ]) {
      test(
        'a wrong-type stored value ($label) → null, without throwing',
        () async {
          final (container, _) = await _container({firstNameKey: value});
          expect(() => container.read(firstNameProvider), returnsNormally);
          expect(container.read(firstNameProvider), isNull);
        },
      );
    }

    test('a stored value over the cap (bad data) → null', () async {
      final (container, _) = await _container({firstNameKey: 'a' * 41});
      expect(container.read(firstNameProvider), isNull);
    });
  });

  group('firstNameProvider — writing', () {
    test('saving a valid name persists it', () async {
      final (container, prefs) = await _container();
      final result = await container
          .read(firstNameProvider.notifier)
          .setFirstName('Thomas');
      expect(result, FirstNameSaveResult.saved);
      expect(container.read(firstNameProvider), 'Thomas');
      expect(prefs.getString(firstNameKey), 'Thomas');
    });

    test('saving trims leading and trailing whitespace', () async {
      final (container, prefs) = await _container();
      await container
          .read(firstNameProvider.notifier)
          .setFirstName('  Anna \n');
      expect(container.read(firstNameProvider), 'Anna');
      expect(prefs.getString(firstNameKey), 'Anna');
    });

    test(
      'saving a blank name removes the key rather than storing ""',
      () async {
        final (container, prefs) = await _container({firstNameKey: 'Thomas'});
        final result = await container
            .read(firstNameProvider.notifier)
            .setFirstName('   ');
        expect(result, FirstNameSaveResult.cleared);
        expect(container.read(firstNameProvider), isNull);
        expect(prefs.containsKey(firstNameKey), isFalse);
      },
    );

    test('clearing removes the key — and only that key', () async {
      final (container, prefs) = await _container({
        firstNameKey: 'Thomas',
        'theme_mode_v1': 'dark',
        'circle_journal_v1': '{}',
      });
      await container.read(firstNameProvider.notifier).clear();
      expect(container.read(firstNameProvider), isNull);
      expect(prefs.containsKey(firstNameKey), isFalse);
      expect(prefs.getString('theme_mode_v1'), 'dark');
      expect(prefs.getString('circle_journal_v1'), '{}');
    });

    test('a name of exactly 40 code points is accepted', () async {
      final (container, prefs) = await _container();
      final name = 'é' * maxFirstNameLength;
      expect(name.runes.length, 40);
      final result = await container
          .read(firstNameProvider.notifier)
          .setFirstName(name);
      expect(result, FirstNameSaveResult.saved);
      expect(prefs.getString(firstNameKey), name);
    });

    test('over 40 code points is rejected — never truncated — and changes '
        'nothing', () async {
      final (container, prefs) = await _container({firstNameKey: 'Thomas'});
      final result = await container
          .read(firstNameProvider.notifier)
          .setFirstName('a' * 41);
      expect(result, FirstNameSaveResult.tooLong);
      expect(container.read(firstNameProvider), 'Thomas');
      expect(prefs.getString(firstNameKey), 'Thomas');
    });

    test('the cap counts code points: 20 emoji (40 UTF-16 units) fit, 41 '
        'code points do not', () async {
      final (container, _) = await _container();
      final twenty = '😊' * 20;
      expect(twenty.length, 40);
      expect(twenty.runes.length, 20);
      expect(
        await container.read(firstNameProvider.notifier).setFirstName(twenty),
        FirstNameSaveResult.saved,
      );
      expect(
        await container
            .read(firstNameProvider.notifier)
            .setFirstName('😊' * 41),
        FirstNameSaveResult.tooLong,
      );
    });

    for (final name in [
      'Zoë',
      'Søren',
      'Łukasz',
      'Ngọc',
      'José María',
      'さくら',
      'Аня',
    ]) {
      test('Unicode name "$name" is stored exactly', () async {
        final (container, prefs) = await _container();
        await container.read(firstNameProvider.notifier).setFirstName(name);
        expect(container.read(firstNameProvider), name);
        expect(prefs.getString(firstNameKey), name);
      });
    }

    test(
      'a saved name survives a cold start (new container, same storage)',
      () async {
        final (first, prefs) = await _container();
        await first.read(firstNameProvider.notifier).setFirstName('Thomas');

        final restarted = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(restarted.dispose);
        expect(restarted.read(firstNameProvider), 'Thomas');
      },
    );
  });
}
