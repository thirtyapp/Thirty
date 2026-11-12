import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/l10n/thirty_locales.dart';
import 'package:thirty/l10n/gen/app_localizations.dart';

import 'support/arb_catalogue.dart';

/// ADR-025 §6 G-KEYS (L-INF, tests S-4 and S-5): THIRTY's catalogue is
/// complete and well-formed, and the guard fails on every kind of defect —
/// proven here on throwaway catalogues written to a temporary directory
/// (marked "[fixture]"; none of it is product copy).
void main() {
  const arbDir = 'lib/l10n/arb';

  group('S-5: the real catalogue', () {
    test(
      'the English catalogue passes every rule, for the enabled locales',
      () {
        final enabled = {
          for (final l in thirtyReleaseLocales) l.toLanguageTag(),
        };
        expect(enabled, {'en'});
        expect(catalogueViolations(arbDir, enabledLocales: enabled), isEmpty);
      },
    );

    test('only the English catalogue exists: no other language is shipped '
        'before ADR-026 Part B (G-5C)', () {
      final files = [
        for (final f in Directory(arbDir).listSync()) f.uri.pathSegments.last,
      ]..sort();
      expect(files, ['app_en.arb']);
      expect(AppLocalizations.supportedLocales, thirtyReleaseLocales);
    });

    test('the generated code carries every key of the catalogue', () {
      final keys =
          (jsonDecode(File('$arbDir/app_en.arb').readAsStringSync())
                  as Map<String, Object?>)
              .keys
              .where((k) => !k.startsWith('@'));
      final generated = File(
        'lib/l10n/gen/app_localizations.dart',
      ).readAsStringSync();
      final english = File(
        'lib/l10n/gen/app_localizations_en.dart',
      ).readAsStringSync();
      for (final key in keys) {
        expect(generated, matches(RegExp('String (get )?$key\\b')));
        expect(english, matches(RegExp('String (get )?$key\\b')));
      }
    });
  });

  group('S-4: the guard fails on each defect', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('thirty_arb_'));
    tearDown(() => dir.deleteSync(recursive: true));

    void write(String locale, Map<String, Object?> content) => File(
      '${dir.path}/app_$locale.arb',
    ).writeAsStringSync(jsonEncode({'@@locale': locale, ...content}));

    final template = <String, Object?>{
      'greeting': '[fixture] Hello {name}',
      '@greeting': {
        'description': 'fixture',
        'placeholders': {
          'name': {'type': 'String'},
        },
      },
      'circles':
          '{count, plural, =0{[fixture] none} one{[fixture] one} '
          'other{[fixture] {count} items}}',
      '@circles': {
        'description': 'fixture',
        'placeholders': {
          'count': {'type': 'int'},
        },
      },
      'need': '{need, select, moreEnergy{[fixture] a} other{[fixture] b}}',
      '@need': {
        'description': 'fixture',
        'placeholders': {
          'need': {'type': 'String'},
        },
      },
      'closedOn': '[fixture] {date}',
      '@closedOn': {
        'description': 'fixture',
        'placeholders': {
          'date': {'type': 'DateTime', 'format': 'yMMMMd'},
        },
      },
    };
    final complete = <String, Object?>{
      'greeting': '[fixture] Bonjour {name}',
      'circles':
          '{count, plural, =0{[fixture] aucun} one{[fixture] un} '
          'many{[fixture] {count} m} other{[fixture] {count} o}}',
      'need': '{need, select, moreEnergy{[fixture] a} other{[fixture] b}}',
      'closedOn': '[fixture] {date}',
    };

    List<String> check({Set<String> enabled = const {'en', 'fr'}}) =>
        catalogueViolations(dir.path, enabledLocales: enabled);

    test('a complete pair with placeholders, plurals, select and a date '
        'passes', () {
      write('en', template);
      write('fr', complete);
      expect(check(), isEmpty);
    });

    final cases =
        <String, (Map<String, Object?>, Map<String, Object?>?, String)>{
          'missing translation': (
            template,
            {...complete}..remove('need'),
            'missing translation "need"',
          ),
          'unsupported key': (
            template,
            {...complete, 'extra': '[fixture]'},
            'unsupported key "extra"',
          ),
          'placeholder renamed in a translation': (
            template,
            {...complete, 'greeting': '[fixture] Bonjour {nom}'},
            'placeholders',
          ),
          'placeholder used but not declared': (
            {...template, 'greeting': '[fixture] Hello {name} {other}'},
            complete,
            'without declaring',
          ),
          'placeholder declared but unused': (
            {...template, 'greeting': '[fixture] Hello'},
            {...complete, 'greeting': '[fixture] Bonjour'},
            'never uses',
          ),
          'malformed ICU (unclosed brace)': (
            {...template, 'greeting': '[fixture] Hello {name'},
            complete,
            'malformed ICU',
          ),
          'malformed ICU (unknown argument type)': (
            {...template, 'greeting': '[fixture] {name, number}'},
            complete,
            'unsupported argument type',
          ),
          'plural without other': (
            {...template, 'circles': '{count, plural, one{[fixture] one}}'},
            complete,
            'no "other" case',
          ),
          'plural category the language lacks': (
            {
              ...template,
              'circles': '{count, plural, few{[fixture] f} other{[fixture] o}}',
            },
            complete,
            'not a en plural category',
          ),
          'select without other': (
            {...template, 'need': '{need, select, moreEnergy{[fixture] a}}'},
            complete,
            'no "other" case',
          ),
          'missing description': (
            {...template, '@greeting': <String, Object?>{}},
            complete,
            'has no @greeting.description',
          ),
          'date placeholder without a format': (
            {
              ...template,
              '@closedOn': {
                'description': 'fixture',
                'placeholders': {
                  'date': {'type': 'DateTime'},
                },
              },
            },
            complete,
            'needs a format',
          ),
          'empty translation': (
            template,
            {...complete, 'greeting': ' '},
            'is empty',
          ),
        };
    for (final MapEntry(key: name, value: (en, fr, expected))
        in cases.entries) {
      test('fails: $name', () {
        write('en', en);
        if (fr != null) write('fr', fr);
        expect(check().join('\n'), contains(expected));
      });
    }

    test('fails: an enabled locale without a catalogue', () {
      write('en', template);
      expect(check().join('\n'), contains('enabled locale "fr"'));
    });

    test('fails: a catalogue in a language outside the six', () {
      write('en', template);
      write('fr', complete);
      write('pt', complete);
      expect(check().join('\n'), contains('unsupported language "pt"'));
    });
  });
}
