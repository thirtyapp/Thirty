import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'b8_review_pack_test.dart'
    show
        CatalogueMessage,
        Pack,
        catalogueMessages,
        englishCatalogue,
        fnv64,
        surfaces;
import 'support/live_copy.dart';

/// G-02 Batch 1 review-coverage correction: copy that moves from Dart into
/// THIRTY's English catalogue stays in the founder's B8 review pack
/// (section I), and the pack's deterministic hash and manifest catch every
/// catalogue change. Fixture catalogues are marked "[fixture]"; none of it
/// is product copy.
void main() {
  /// The pack's section I.
  String sectionI(String body) =>
      body.substring(body.indexOf('## I. English catalogue (ARB)'));

  /// Everything before section I: the Dart-derived pack (A–H).
  String beforeI(String body) =>
      body.substring(0, body.indexOf('## I. English catalogue (ARB)'));

  final real = Pack();
  final realBody = real.build();

  group('the real catalogue', () {
    test('every user-facing English message is listed with its key, text, '
        'catalogue path, description and placeholders', () {
      final messages = catalogueMessages(englishCatalogue);
      final raw =
          jsonDecode(File(englishCatalogue).readAsStringSync())
              as Map<String, Object?>;
      expect(
        [for (final m in messages) m.key],
        [
          for (final k in raw.keys)
            if (!k.startsWith('@')) k,
        ],
        reason: 'every message key, and no metadata entry',
      );
      final section = sectionI(realBody);
      for (final CatalogueMessage(:key, :text, :description, :placeholders)
          in messages) {
        final entry = section.substring(section.indexOf('- **`$key`**: '));
        expect(entry, startsWith('- **`$key`**: $text\n'), reason: key);
        expect(entry, contains('  - Source: `$englishCatalogue`'));
        expect(description, isNotNull, reason: key);
        expect(entry, contains('  - Description: $description'));
        for (final name in placeholders.keys) {
          expect(entry, contains('`{$name}` ('), reason: '$key {$name}');
        }
      }
      // Metadata is never listed as copy.
      expect(section, isNot(contains('`@')));
      expect(section, isNot(contains('@@locale')));
    });

    test('Batch 1 is visible: brandName, youAboutSectionTitle and '
        'youAboutVersion, with its placeholder documented', () {
      final section = sectionI(realBody);
      expect(section, contains('- **`brandName`**: THIRTY\n'));
      expect(section, contains('- **`youAboutSectionTitle`**: About\n'));
      expect(section, contains('- **`youAboutVersion`**: Version {version}\n'));
      expect(section, contains('  - Placeholders: `{version}` (type: String)'));
    });

    test('the Dart-derived review is unchanged: every surface string is '
        'still listed, and the catalogue adds only section I', () {
      for (final s in real.strings) {
        if (!surfaces.any((x) => x.$3.any(s.file.startsWith))) continue;
        expect(realBody, contains(s.text), reason: '${s.file}: ${s.text}');
      }
      final dir = Directory.systemTemp.createTempSync('thirty_b8_cat_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final empty = File('${dir.path}/app_en.arb')
        ..writeAsStringSync(jsonEncode({'@@locale': 'en'}));
      final without = Pack(catalogue: empty.path).build();
      expect(beforeI(realBody), beforeI(without));
      expect(sectionI(without), contains('NONE'));
    });

    test('the manifest names the catalogue and its keys, and counts the '
        'production Dart files actually scanned', () {
      final manifest =
          jsonDecode(
                File(
                  'artifacts/v2_phase_d2/b8/MANIFEST.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      expect(manifest['productionFilesScanned'], productionFiles().length);
      expect(
        productionFiles().where((f) => f.startsWith('lib/l10n/gen/')),
        isEmpty,
        reason: 'generated code is never counted or listed as copy',
      );
      expect(manifest['catalogueFilesInPack'], [englishCatalogue]);
      expect(manifest['catalogueKeys'], [for (final m in real.messages) m.key]);
      expect(manifest['catalogueMessagesListed'], real.messages.length);
      expect(manifest['contentHashFnv64'], fnv64(realBody));
    });
  });

  group('the hash catches every catalogue change', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('thirty_b8_cat_'));
    tearDown(() => dir.deleteSync(recursive: true));

    final base = <String, Object?>{
      '@@locale': 'en',
      'fixtureTitle': '[fixture] A title',
      '@fixtureTitle': {'description': '[fixture] a heading'},
      'fixtureCount': '[fixture] {count} items',
      '@fixtureCount': {
        'description': '[fixture] a count',
        'placeholders': {
          'count': {'type': 'int', 'format': 'compact'},
        },
      },
    };

    (String, Pack) packFor(Map<String, Object?> catalogue) {
      final f = File('${dir.path}/app_en.arb')
        ..writeAsStringSync(jsonEncode(catalogue));
      final pack = Pack(catalogue: f.path);
      return (pack.build(), pack);
    }

    test('a fixture catalogue is listed in full, placeholders included', () {
      final (body, pack) = packFor(base);
      expect(pack.messages.map((m) => m.key), ['fixtureTitle', 'fixtureCount']);
      final section = sectionI(body);
      expect(section, contains('- **`fixtureTitle`**: [fixture] A title'));
      expect(
        section,
        contains(
          '- **`fixtureCount`**: [fixture] {count} items\n'
          '  - Source: `${dir.path}',
        ),
      );
      expect(
        section,
        contains('  - Placeholders: `{count}` (format: compact, type: int)'),
      );
    });

    /// The base catalogue's pack, built in its own directory. The catalogue
    /// path is part of section I, so paths are compared as `<dir>`.
    String baseHash() {
      final dir = Directory.systemTemp.createTempSync('thirty_b8_cat_');
      try {
        final f = File('${dir.path}/app_en.arb')
          ..writeAsStringSync(jsonEncode(base));
        return Pack(catalogue: f.path).build().replaceAll(dir.path, '<dir>');
      } finally {
        dir.deleteSync(recursive: true);
      }
    }

    String hashOf(Map<String, Object?> catalogue) {
      final (body, _) = packFor(catalogue);
      return fnv64(body.replaceAll(dir.path, '<dir>'));
    }

    test('the same catalogue gives the same hash', () {
      expect(hashOf(base), fnv64(baseHash()));
    });

    for (final (name, changed) in <(String, Map<String, Object?>)>[
      (
        'a new message',
        {
          ...base,
          'fixtureNew': '[fixture] New words',
          '@fixtureNew': {'description': '[fixture] new'},
        },
      ),
      ('a removed message', {...base}..remove('fixtureTitle')),
      ('a changed English value', {...base, 'fixtureTitle': '[fixture] B'}),
      (
        'a changed description',
        {
          ...base,
          '@fixtureTitle': {'description': '[fixture] another heading'},
        },
      ),
      (
        'a changed placeholder',
        {
          ...base,
          '@fixtureCount': {
            'description': '[fixture] a count',
            'placeholders': {
              'count': {'type': 'num'},
            },
          },
        },
      ),
    ]) {
      test('$name changes the hash, so the pack must be regenerated and '
          'reviewed', () {
        expect(hashOf(changed), isNot(fnv64(baseHash())));
      });
    }

    test('a lapse line or a straight apostrophe in the catalogue reaches '
        'the cross-surface views (F and the apostrophe flag)', () {
      final (body, _) = packFor({
        ...base,
        'fixtureLapse': '[fixture] Saved at stage two',
        '@fixtureLapse': {'description': '[fixture] lapse'},
        'fixtureStraight': "[fixture] It's here",
        '@fixtureStraight': {'description': '[fixture] apostrophe'},
      });
      final f = body.substring(
        body.indexOf('## F. Lapse'),
        body.indexOf('## G. Accessibility'),
      );
      expect(f, contains('- [fixture] Saved at stage two'));
      final h = body.substring(
        body.indexOf('## H. Founder flags'),
        body.indexOf('## I. English catalogue'),
      );
      final (baseBody, _) = packFor(base);
      int straight(String body) => int.parse(
        RegExp(
          r'Apostrophes are mixed: (\d+) live strings',
        ).firstMatch(body)!.group(1)!,
      );
      expect(straight(h), straight(baseBody) + 1);
    });
  });
}
