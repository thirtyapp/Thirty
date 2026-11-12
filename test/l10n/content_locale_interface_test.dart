import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/core/l10n/content_locale.dart';
import 'package:thirty/features/personal_circle/application/guidance_voice.dart';
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/composed_session.dart';
import 'package:thirty/features/personal_circle/domain/spoken_cues.dart';

/// L-CONTENT-AUDIO (ADR-025 §7): the language-aware content and spoken
/// guidance interface.
///
/// A. In English it gives exactly what the English API gives — the same
///    words, clips, files, manifest, completeness and eligibility (the
///    English API itself is locked to `064af36c` by
///    `content_audio_en_golden_test.dart`).
/// B. Any other content language — none has approved words or recordings —
///    gets nothing: no words, no clips, no rendition, no voice. Nothing
///    falls back to English, and no sequence mixes languages.
/// C. Nothing about it is persisted.
const others = [
  ContentLocale('fr'),
  ContentLocale('nl'),
  ContentLocale('es'),
  ContentLocale('de'),
  ContentLocale('it'),
  ContentLocale('pt'),
  ContentLocale('ja'),
  ContentLocale('EN'),
];

class RecordingPlayer implements GuidanceAudioPlayer {
  final calls = <List<String>>[];

  @override
  Future<void> play(
    List<String> assets, {
    bool deferToScreenReader = false,
    bool afterCurrent = false,
  }) async => calls.add(assets);

  @override
  Future<void> stop() async {}
}

Set<String> frozenPaths() => {
  for (final line in File(
    'test/l10n/audio_en_frozen_manifest.tsv',
  ).readAsLinesSync())
    if (line.isNotEmpty && !line.startsWith('#')) line.split('\t').first,
};

List<CircleElement> offerable() => [
  for (final e in elementLibrary.values)
    if (isElementOfferable(e)) e,
];

CirclePlan planOf(int n) => CirclePlan([
  for (final e in offerable().take(n)) CirclePart(e.id, e.minutes),
]);

Map<String, ComposedSession> sessions() {
  final plan = planOf(3);
  final exact = [for (final p in plan.parts) PartWording.of(p.definition)];
  final differing = [...exact];
  differing[1] = PartWording(
    name: exact[1].name,
    instruction: '${exact[1].instruction} (edited)',
  );
  return {
    'composed': ComposedSession(
      plan: plan,
      basis: CompositionBasis.values.first,
    ),
    'keptExact': ComposedSession(
      plan: plan,
      keptCircleId: 'k1',
      keptName: 'Kept',
      wording: exact,
    ),
    'keptDiffering': ComposedSession(
      plan: plan,
      keptCircleId: 'k2',
      keptName: 'Kept',
      wording: differing,
    ),
    'keptUnverified': ComposedSession(
      plan: plan,
      keptCircleId: 'k3',
      keptName: 'Kept',
      wordingUnverified: true,
    ),
  };
}

void main() {
  const en = ContentLocale.english;

  group('A: English through the interface equals the English API', () {
    test('this build: English is the only approved content language, and '
        'the content language of every Circle', () {
      expect(currentContentLocale, en);
      expect(approvedContentLocales, {en});
      expect(const ContentLocale('en'), en);
      expect(ContentLocale(['e', 'n'].join()), en, reason: 'value equality');
      expect(ContentLocale(['e', 'n'].join()).hasApprovedContent, isTrue);
      expect(approvedRenditionsIn(en), ThirtyVoice.values.toSet());
    });

    test('every element: the same words and the same clip', () {
      for (final e in elementLibrary.values) {
        expect(elementWordingIn(e, en), PartWording.of(e), reason: '${e.id}');
        final clip = partClipIn(e, en)!;
        expect(clip, partClip(e));
        expect(clip.file, partClip(e).file);
        expect(clip.script, '${e.name}. ${e.instruction}'.replaceAll(' ', ' '));
        expect(clip.locale, en);
      }
    });

    test('the manifest, leads, ending, framing and previews', () {
      expect(spokenGuidanceManifestIn(en), spokenGuidanceManifest);
      expect(spokenGuidanceManifest, hasLength(42));
      final frame = spokenFrameIn(en)!;
      expect(
        [frame.first, frame.next, frame.last, frame.ending],
        [leadFirst, leadNext, leadLast, spokenEnding],
      );
      expect([frame.opening, frame.nextCircle], spokenFramingClips);
      expect(spokenFramingClipsIn(en), spokenFramingClips);
      for (final v in ThirtyVoice.values) {
        expect(spokenPreviewIn(v, en), spokenPreviewFor(v));
      }
    });

    test('every asset path is the frozen one, through either API', () {
      final viaInterface = {
        for (final v in ThirtyVoice.values)
          for (final c in [
            ...spokenGuidanceManifestIn(en)!,
            spokenPreviewIn(v, en)!,
            ...spokenFramingClipsIn(en)!,
          ])
            spokenAssetIn(c, v)!,
      };
      expect(viaInterface, frozenPaths());
      for (final v in ThirtyVoice.values) {
        expect(renditionAssetDirIn(v, en), v.assetDir);
        for (final c in spokenGuidanceManifest) {
          expect(spokenAssetIn(c, v), c.assetFor(v));
        }
      }
    });

    test('completeness: four voices on the frozen set; one missing clip '
        'or preview takes that voice out; framing is optional', () {
      final frozen = frozenPaths();
      expect(completeGuidanceVoicesIn(frozen, en), ThirtyVoice.values.toSet());
      expect(
        completeGuidanceVoicesIn(frozen, en),
        completeGuidanceVoices(frozen),
      );
      for (final v in ThirtyVoice.values) {
        for (final missing in [
          spokenGuidanceManifest.first.assetFor(v),
          spokenGuidanceManifest[20].assetFor(v),
          spokenPreviewFor(v).assetFor(v),
        ]) {
          final incomplete = {...frozen}..remove(missing);
          expect(
            completeGuidanceVoicesIn(incomplete, en),
            ThirtyVoice.values.toSet()..remove(v),
          );
        }
        final noFraming = {...frozen}
          ..removeAll([for (final c in spokenFramingClips) c.assetFor(v)]);
        expect(
          completeGuidanceVoicesIn(noFraming, en),
          ThirtyVoice.values.toSet(),
        );
      }
      expect(completeGuidanceVoicesIn(const {}, en), isEmpty);
    });

    test('cue sequences', () {
      for (final n in [1, 2, 3, 5]) {
        final plan = planOf(n);
        for (var i = 0; i < n; i++) {
          expect(spokenCueIn(plan, i, en), spokenCueFor(plan, i));
        }
      }
    });

    test('Circle eligibility (R6 whole-Circle rule unchanged)', () {
      for (final MapEntry(:key, :value) in sessions().entries) {
        expect(value.voicedIn(en), value.voiced, reason: key);
        for (var i = 0; i < value.plan.parts.length; i++) {
          expect(value.voicedAtIn(i, en), value.voicedAt(i), reason: key);
        }
      }
      final s = sessions();
      expect(s['composed']!.voicedIn(en), isTrue);
      expect(s['keptExact']!.voicedIn(en), isTrue);
      expect(s['keptDiffering']!.voicedIn(en), isFalse);
      expect(s['keptDiffering']!.voicedAtIn(0, en), isTrue);
      expect(s['keptUnverified']!.voicedIn(en), isFalse);
    });
  });

  group('B: no approved content → nothing, never English', () {
    for (final locale in others) {
      test('$locale', () {
        expect(locale.hasApprovedContent, isFalse);
        for (final e in elementLibrary.values) {
          expect(elementWordingIn(e, locale), isNull);
          expect(partClipIn(e, locale), isNull);
        }
        expect(spokenFrameIn(locale), isNull);
        expect(spokenFramingClipsIn(locale), isNull);
        expect(spokenGuidanceManifestIn(locale), isNull);
        expect(approvedRenditionsIn(locale), isEmpty);
        for (final n in [1, 3]) {
          final plan = planOf(n);
          for (var i = 0; i < n; i++) {
            expect(spokenCueIn(plan, i, locale), isNull);
          }
        }
        for (final v in ThirtyVoice.values) {
          expect(spokenPreviewIn(v, locale), isNull);
          expect(renditionAssetDirIn(v, locale), isNull);
        }
        // Even a bundle holding every English file and files laid out as a
        // localized rendition might be gives no voice in this language.
        final everything = {
          ...frozenPaths(),
          for (final p in frozenPaths()) ...[
            p.replaceFirst('_v1/', '_v1/${locale.languageCode}/'),
            p.replaceFirst('_v1/', '_${locale.languageCode}_v1/'),
          ],
        };
        expect(completeGuidanceVoicesIn(everything, locale), isEmpty);
        // No Circle is voiced in a language without approved words.
        for (final MapEntry(:key, :value) in sessions().entries) {
          expect(value.voicedIn(locale), isFalse, reason: key);
          for (var i = 0; i < value.plan.parts.length; i++) {
            expect(value.voicedAtIn(i, locale), isFalse);
          }
        }
      });
    }

    final french = SpokenClip.forTesting(
      'lead_first',
      SpokenClipRole.lead,
      '[test] premier',
      const ContentLocale('fr'),
    );

    test('a clip in a language without a rendition has no recording in any '
        'voice', () {
      for (final v in ThirtyVoice.values) {
        expect(spokenAssetIn(french, v), isNull);
      }
      expect(french, isNot(leadFirst));
    });

    test('one language per sequence', () {
      expect(spokenInOneLanguage(const []), isTrue);
      expect(spokenInOneLanguage(spokenCueFor(planOf(3), 1)), isTrue);
      expect(spokenInOneLanguage([leadFirst, french]), isFalse);
      expect(spokenInOneLanguage([french]), isTrue);
    });

    test('the voice plays English exactly as before, and refuses a mixed '
        'sequence or a clip without a recording', () async {
      for (final v in ThirtyVoice.values) {
        final player = RecordingPlayer();
        final voice = BundledGuidanceVoice(player, v);
        final cue = [spokenOpening, ...spokenCueFor(planOf(3), 0)];
        await voice.play(cue);
        expect(player.calls, [
          [for (final c in cue) c.assetFor(v)],
        ]);
        await voice.play([leadFirst, french]);
        await voice.play([french]);
        await voice.play([...cue, french]);
        expect(player.calls, hasLength(1), reason: 'nothing else played');
      }
    });
  });

  group('C: nothing is persisted', () {
    test('no locale field in a running Circle\'s stored form', () {
      for (final s in sessions().values) {
        final keys = s.toJson().keys.toSet();
        expect(
          keys.difference({
            'parts',
            'basis',
            'keptCircleId',
            'keptName',
            'stage',
            'wording',
          }),
          isEmpty,
        );
      }
    });

    test('no persisted locale key or field anywhere in lib/', () {
      final sources = [
        for (final f in Directory('lib').listSync(recursive: true))
          if (f is File && f.path.endsWith('.dart')) f.readAsStringSync(),
      ].join('\n');
      for (final key in [
        "'locale'",
        "'contentLocale'",
        "'sourceLocale'",
        "'languageCode'",
        'app_locale',
      ]) {
        expect(sources, isNot(contains(key)), reason: key);
      }
    });
  });
}
