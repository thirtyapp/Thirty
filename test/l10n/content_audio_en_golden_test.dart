import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/personal_circle/application/guidance_voice.dart';
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/composed_session.dart';
import 'package:thirty/features/personal_circle/domain/spoken_cues.dart';

/// L-CONTENT-AUDIO English compatibility golden (ADR-025 §7).
///
/// Every English word THIRTY's elements show and its voice says, every clip
/// identity (id, role, script, fingerprinted file), the manifest in order,
/// every voice's asset paths, the completeness check on complete and
/// incomplete file sets, the cue sequences of sample Circles, and the
/// whole-Circle voice eligibility of composed and kept Circles (R6/R8: exact
/// words, one differing part, a safety-revised part, unverified words).
///
/// Recorded by this same file on `064af36c` — it uses only API that existed
/// there — so equality means the language-aware interface changed none of
/// it.
///
/// Record (on the baseline tree only):
/// `flutter test test/l10n/content_audio_en_golden_test.dart
///  --dart-define=WRITE_CONTENT_AUDIO_GOLDEN=true`.
const _golden = 'test/l10n/content_audio_en_golden_064af36c.json';
const _write = bool.fromEnvironment('WRITE_CONTENT_AUDIO_GOLDEN');

Map<String, Object?> clip(SpokenClip c) => {
  'id': c.id,
  'role': c.role.name,
  'script': c.script,
  'file': c.file,
};

List<String> names(Set<ThirtyVoice> voices) =>
    [for (final v in voices) v.name]..sort();

Map<String, Object?> snapshot() {
  final frozen = {
    for (final line in File(
      'test/l10n/audio_en_frozen_manifest.tsv',
    ).readAsLinesSync())
      if (line.isNotEmpty && !line.startsWith('#')) line.split('\t').first,
  };
  final offerable = [
    for (final e in elementLibrary.values)
      if (isElementOfferable(e)) e,
  ];
  CirclePlan planOf(int n) => CirclePlan([
    for (final e in offerable.take(n)) CirclePart(e.id, e.minutes),
  ]);
  final plans = {
    for (final n in [1, 2, 3, 5]) 'parts$n': planOf(n),
  };

  final three = plans['parts3']!;
  List<PartWording> exact() => [
    for (final p in three.parts) PartWording.of(p.definition),
  ];
  final differing = exact();
  differing[1] = PartWording(
    name: differing[1].name,
    instruction: '${differing[1].instruction} (edited)',
  );
  final safetyRevised = exact();
  safetyRevised[2] = PartWording(
    name: safetyRevised[2].name,
    instruction: 'Older words, before a safety correction.',
    safetyRevision: -1,
  );
  final sessions = {
    'composed': ComposedSession(
      plan: three,
      basis: CompositionBasis.values.first,
    ),
    'keptExactWords': ComposedSession(
      plan: three,
      keptCircleId: 'kept-a',
      keptName: 'Kept',
      wording: exact(),
    ),
    'keptWithoutWords': ComposedSession(
      plan: three,
      keptCircleId: 'kept-b',
      keptName: 'Kept',
    ),
    'keptOneDifferingPart': ComposedSession(
      plan: three,
      keptCircleId: 'kept-c',
      keptName: 'Kept',
      wording: differing,
    ),
    'keptSafetyRevisedPart': ComposedSession(
      plan: three,
      keptCircleId: 'kept-d',
      keptName: 'Kept',
      wording: safetyRevised,
    ),
    'keptUnverifiedWords': ComposedSession(
      plan: three,
      keptCircleId: 'kept-e',
      keptName: 'Kept',
      wordingUnverified: true,
    ),
  };

  final manifestAssets = {
    for (final v in ThirtyVoice.values)
      v: [for (final c in spokenGuidanceManifest) c.assetFor(v)],
  };
  return {
    'elements': {
      for (final id in ElementId.values)
        id.name: {
          'name': elementOf(id).name,
          'instruction': elementOf(id).instruction,
          'safetyRevision': elementOf(id).safetyRevision,
          'offerable': isElementOfferable(elementOf(id)),
          'wording': PartWording.of(elementOf(id)).toJson(),
          'partClip': clip(partClip(elementOf(id))),
        },
    },
    'leads': [
      for (final c in [leadFirst, leadNext, leadLast]) clip(c),
    ],
    'ending': clip(spokenEnding),
    'opening': clip(spokenOpening),
    'nextCircle': clip(spokenNextCircle),
    'framing': [for (final c in spokenFramingClips) clip(c)],
    'manifest': [for (final c in spokenGuidanceManifest) clip(c)],
    'voices': {
      for (final v in ThirtyVoice.values)
        v.name: {
          'id': v.id,
          'label': v.label,
          'assetDir': v.assetDir,
          'preview': clip(spokenPreviewFor(v)),
          'assets': [
            for (final c in [
              ...spokenGuidanceManifest,
              spokenPreviewFor(v),
              ...spokenFramingClips,
            ])
              c.assetFor(v),
          ],
        },
    },
    'complete': {
      'frozenSet': names(completeGuidanceVoices(frozen)),
      'emptySet': names(completeGuidanceVoices(const {})),
      for (final v in ThirtyVoice.values) ...{
        'without_${v.name}_firstManifestClip': names(
          completeGuidanceVoices({...frozen}..remove(manifestAssets[v]!.first)),
        ),
        'without_${v.name}_lastManifestClip': names(
          completeGuidanceVoices({...frozen}..remove(manifestAssets[v]!.last)),
        ),
        'without_${v.name}_preview': names(
          completeGuidanceVoices(
            {...frozen}..remove(spokenPreviewFor(v).assetFor(v)),
          ),
        ),
        'without_${v.name}_framing': names(
          completeGuidanceVoices(
            {...frozen}
              ..removeAll([for (final c in spokenFramingClips) c.assetFor(v)]),
          ),
        ),
      },
    },
    'cues': {
      for (final MapEntry(:key, :value) in plans.entries)
        key: [
          for (var i = 0; i < value.parts.length; i++)
            [for (final c in spokenCueFor(value, i)) clip(c)],
        ],
    },
    'voiced': {
      for (final MapEntry(:key, :value) in sessions.entries)
        key: {
          'voiced': value.voiced,
          'voicedAt': [
            for (var i = 0; i < value.plan.parts.length; i++) value.voicedAt(i),
          ],
          'wordingAt': [
            for (var i = 0; i < value.plan.parts.length; i++)
              value.wordingAt(i).toJson(),
          ],
          'partNote': [
            for (var i = 0; i < value.plan.parts.length; i++)
              value.partNote(i, voiceAvailable: true),
          ],
        },
    },
  };
}

void main() {
  test('English content and spoken guidance are exactly as on 064af36c', () {
    final now = jsonDecode(jsonEncode(snapshot())) as Map<String, Object?>;
    if (_write) {
      File(_golden).writeAsStringSync(
        '${const JsonEncoder.withIndent(' ').convert(now)}\n',
      );
    }
    final golden =
        jsonDecode(File(_golden).readAsStringSync()) as Map<String, Object?>;
    expect(now.keys, golden.keys);
    for (final key in golden.keys) {
      expect(now[key], golden[key], reason: key);
    }
    // The snapshot is not trivial.
    final manifest = golden['manifest']! as List;
    expect(manifest, hasLength(42));
    expect((golden['complete']! as Map)['frozenSet'], [
      'brittney',
      'heather',
      'locke',
      'milo',
    ]);
  });
}
