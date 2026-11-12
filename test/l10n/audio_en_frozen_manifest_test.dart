import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/personal_circle/application/guidance_voice.dart';
import 'package:thirty/features/personal_circle/domain/spoken_cues.dart';

/// ADR-025 §7.2 G-AUDIO-EN (L-INF, test S-10): THIRTY's English guidance
/// audio is frozen — the 180 files (4 voices × 42 manifest clips, the
/// preview and the two framing lines), their exact paths, the script
/// fingerprints those paths carry, and their bytes. Localization must never
/// move a path, change a script the code derives a fingerprint from, or
/// touch a recording.
///
/// `audio_en_frozen_manifest.tsv` was captured from `b62984bc` and is never
/// edited by hand.
const _frozen = 'test/l10n/audio_en_frozen_manifest.tsv';

/// FNV-1a, 64-bit, as 16 hex digits.
String fnv1a64(List<int> bytes) {
  var h = BigInt.parse('cbf29ce484222325', radix: 16);
  final prime = BigInt.parse('100000001b3', radix: 16);
  final mask = (BigInt.one << 64) - BigInt.one;
  for (final b in bytes) {
    h = ((h ^ BigInt.from(b)) * prime) & mask;
  }
  return h.toRadixString(16).padLeft(16, '0');
}

List<(String path, int bytes, String fnv)> readFrozen() => [
  for (final line in File(_frozen).readAsLinesSync())
    if (line.isNotEmpty && !line.startsWith('#'))
      switch (line.split('\t')) {
        [final p, final n, final h, _] => (p, int.parse(n), h),
        _ => throw StateError('bad line: $line'),
      },
];

/// Every guidance file the code expects, per voice: the manifest, the
/// voice's preview and the framing lines.
Set<String> expectedByCode() => {
  for (final voice in ThirtyVoice.values)
    for (final clip in [
      ...spokenGuidanceManifest,
      spokenPreviewFor(voice),
      ...spokenFramingClips,
    ])
      clip.assetFor(voice),
};

void main() {
  final frozen = readFrozen();

  test('S-10: 180 frozen files — 4 voices × (42 + preview + 2 framing)', () {
    expect(frozen, hasLength(180));
    expect(ThirtyVoice.values, hasLength(4));
    expect(spokenGuidanceManifest, hasLength(42));
    expect(spokenFramingClips, hasLength(2));
  });

  test('S-10: the paths the code derives (ids + script fingerprints) are '
      'exactly the frozen paths', () {
    expect(expectedByCode(), {for (final f in frozen) f.$1});
  });

  test(
    'S-10: the bundled files are exactly the frozen files, byte for byte',
    () {
      final onDisk = {
        for (final f in Directory(
          'assets/audio/guidance',
        ).listSync(recursive: true).whereType<File>())
          f.path.replaceAll(r'\', '/'),
      };
      expect(onDisk, {for (final f in frozen) f.$1});
      for (final (path, bytes, fnv) in frozen) {
        final data = File(path).readAsBytesSync();
        expect(data.length, bytes, reason: path);
        expect(fnv1a64(data), fnv, reason: path);
      }
    },
  );

  test('S-10: every voice is complete under the frozen file set (the '
      'start-up check that decides whether a voice speaks)', () {
    expect(
      completeGuidanceVoices({for (final f in frozen) f.$1}),
      ThirtyVoice.values.toSet(),
    );
  });

  test('S-10: the comparison fails when one script fingerprint changes', () {
    // A script edited by one character gets another fingerprint, so the
    // derived path set no longer equals the frozen one.
    final derived = expectedByCode().toList()..sort();
    final mutated = {
      ...derived.skip(1),
      derived.first.replaceFirst(
        RegExp(r'_[0-9a-f]{8}\.m4a$'),
        '_00000000.m4a',
      ),
    };
    expect(mutated, hasLength(180));
    expect(mutated, isNot({for (final f in frozen) f.$1}));
  });
}
