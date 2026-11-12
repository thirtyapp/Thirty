import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../features/b8/b8_live_copy_guard_test.dart' show guards;

/// ADR-025 §6 G-ARB-CONTENT (L-INF, test S-9): the words in THIRTY's ARB
/// catalogues obey the same frozen content rules as the copy in Dart — the
/// B8 guards (retired products, false completion, streak or guilt, health
/// claims, hidden inference, Premium drift, AI positioning), read from
/// `b8_live_copy_guard_test.dart` itself so the two never diverge.
///
/// Generated code (`lib/l10n/gen/`) is excluded from the B8 Dart scan
/// (`support/live_copy.dart`); its words are these catalogue values. No
/// catalogue entry has an exemption: there is no allowlist here.
List<String> arbViolations(String dir) {
  final out = <String>[];
  for (final f in Directory(dir).listSync().whereType<File>()) {
    if (!f.path.endsWith('.arb')) continue;
    final raw = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
    for (final MapEntry(:key, :value) in raw.entries) {
      if (key.startsWith('@')) continue;
      for (final guard in guards) {
        if (guard.rx.hasMatch('$value')) {
          out.add('${f.uri.pathSegments.last} "$key": ${guard.name}: $value');
        }
      }
    }
  }
  return out;
}

void main() {
  test('S-9: the real catalogues carry no forbidden concept', () {
    expect(arbViolations('lib/l10n/arb'), isEmpty);
  });

  group('S-9: the guard fails on forbidden concepts in a catalogue', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('thirty_arb_c_'));
    tearDown(() => dir.deleteSync(recursive: true));

    for (final (text, guard) in [
      ('[fixture] Keep your streak going', 'streak / guilt'),
      ('[fixture] You finished your Circle', 'false completion'),
      ('[fixture] Boost your energy', 'unsupported health claim'),
      ('[fixture] Open your Toolkit', 'retired product'),
      ('[fixture] Start a free trial', 'Premium drift'),
      ('[fixture] Your AI coach', 'AI positioning'),
    ]) {
      test('"$text" → $guard', () {
        File('${dir.path}/app_en.arb').writeAsStringSync(
          jsonEncode({
            '@@locale': 'en',
            'x': text,
            '@x': {'description': 'fixture'},
          }),
        );
        expect(arbViolations(dir.path).join('\n'), contains(guard));
      });
    }
  });
}
