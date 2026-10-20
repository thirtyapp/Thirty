import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/presentation/widgets/today_card.dart';
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/composed_session.dart';
import 'package:thirty/features/personal_circle/domain/spoken_cues.dart';
import 'package:thirty/features/personal_circle/presentation/keep_circle_card.dart';
import 'package:thirty/features/personal_circle/presentation/use_today_control.dart';
import 'package:thirty/features/premium/presentation/premium_offer_page.dart';
import 'package:thirty/features/settings/presentation/widgets/you_premium_card.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/presentation/yours_page.dart';
import 'package:thirty/features/settings/presentation/widgets/you_personal_card.dart';

/// V2 Phase D2 (ADR-023 §2, §12) — the element coverage report and the
/// founder's content review pack, generated from the very library and copy
/// the app runs on, so neither can drift:
///
/// ```
/// flutter test test/features/personal_circle/d2_review_pack_test.dart \
///   --dart-define=EXPORT_REVIEW=true
/// ```
///
/// writes `build/d2_element_coverage.md` and `build/d2_content_review.md`.
/// The content guards run always.
const _export = bool.fromEnvironment('EXPORT_REVIEW');

List<CircleElement> _allowedFor(Intention need) => [
  for (final e in elementLibrary.values)
    if (isElementOfferable(e) && e.fits(need)) e,
];

/// What one need × window can produce.
class Coverage {
  Coverage(this.need, this.window) {
    for (final parts in gatePassingShapes(
      _allowedFor(need),
      window: window.maxMinutes,
    )) {
      final plan = CirclePlan(parts);
      shapes++;
      mains.add(plan.main.element);
      final core = [
        for (final p in plan.parts)
          if (p.definition.roles.contains(ElementRole.main) ||
              p.definition.roles.contains(ElementRole.second))
            p.element.name,
      ]..sort();
      material.add(core.join('+'));
      totals.add(plan.minutes);
    }
  }

  final Intention need;
  final TimeWindow window;
  var shapes = 0;
  final mains = <ElementId>{};

  /// Materially distinct: the main and second pieces — the session's
  /// substance — never counting a different arrival or close, and never an
  /// order (the order is fixed by role, so no re-ordering exists to count).
  final material = <String>{};
  final totals = <int>[];
}

/// Every user-facing D2 string, by where it appears.
Map<String, List<String>> d2Copy() => {
  'Today — before Start': [
    ComposedCopy.title,
    ComposedCopy.greetingSubline,
    ComposedCopy.basisLine(CompositionBasis.foundUseful, TimeWindow.about10),
    ComposedCopy.basisLine(CompositionBasis.foundUseful, TimeWindow.about20),
    ComposedCopy.basisLine(CompositionBasis.foundUseful, TimeWindow.upTo30),
    ComposedCopy.basisLine(CompositionBasis.sized, TimeWindow.about10),
    ComposedCopy.basisLine(CompositionBasis.sized, TimeWindow.about20),
    ComposedCopy.basisLine(CompositionBasis.sized, TimeWindow.upTo30),
    ComposedCopy.keptLine,
    ComposedCopy.fallbackLine,
    ActivityRowCue.parts.text,
    ActivityRowCue.partsOrNotThisOne.text,
    ActivityRowCue.partsOrNotThisOne.hint,
  ],
  'Today — running': [
    ComposedCopy.partDetail(1, 4, 'Get it out'),
    ComposedCopy.partDetail(3, 4, null),
    ComposedCopy.partCue(1),
    ComposedCopy.partCue(6),
    ComposedCopy.ending,
    ComposedCopy.howItRuns,
    ComposedCopy.skip,
  ],
  'Skip sheet': [
    ComposedCopy.skipTitle,
    ComposedCopy.skipToday,
    ComposedCopy.skipTodayDetail,
    ComposedCopy.skipTodayDetailFor(['Choose one thing']),
    ComposedCopy.skipTodayDetailFor([
      'Choose one thing',
      'Write the first step',
    ]),
    ComposedCopy.leaveOut,
    ComposedCopy.leaveOutDetail,
    ComposedCopy.keepGoing,
  ],
  'After Close — keep this Circle': [
    KeepCircleCopy.offer,
    KeepCircleCopy.action,
    KeepCircleCopy.kept('My clear-head Circle'),
    KeepCircleCopy.full,
    for (final need in Intention.values) keptCircleDefaultName(need),
  ],
  'Use it today (the kept Circle page)': [
    UseTodayCopy.action,
    UseTodayCopy.isToday,
    UseTodayCopy.started,
    UseTodayCopy.closed,
    UseTodayCopy.unavailable,
    'THIRTY never offers a kept Circle unasked. It stays yours, with or '
        'without Premium.',
  ],
  'Memory': [
    'Left out of your Circles',
    'You asked THIRTY to leave it out',
    'Put it back',
    'THIRTY will forget which activities you asked it not to suggest, any '
        'rests you lifted, and any parts you left out of your Circles. Your '
        'Circle history and your answers stay.',
  ],
  'Premium offer': [
    PremiumOfferPage.headline,
    PremiumOfferPage.promise,
    for (final (name, line) in PremiumOfferPage.points) '$name: $line',
    'With THIRTY’s voice bundled — ${PremiumOfferPage.voicedPoints[1].$1}: '
        '${PremiumOfferPage.voicedPoints[1].$2}',
    PremiumOfferPage.freeLine,
    'What you keep stays yours, with or without Premium.',
    PremiumOfferPage.lapseLine,
    'With THIRTY’s voice bundled: ${PremiumOfferPage.voicedLapseLine}',
    'THIRTY Premium makes you a guided Circle each day, around the time you '
        'have.',
    YouPremiumCard.body,
  ],
  'You — spoken guidance (Premium only, when the recordings are bundled)': [
    SpokenGuidanceCopy.title,
    SpokenGuidanceCopy.detail,
    SpokenGuidanceCopy.voice,
    for (final voice in ThirtyVoice.values) voice.label,
  ],
  'Notification while a voiced Circle runs (Android; the part on show is '
      'its text)': [
    SpokenGuidanceCopy.sessionRunning,
    SpokenGuidanceCopy.sessionPaused,
    SpokenGuidanceCopy.pause,
    SpokenGuidanceCopy.resume,
    SpokenGuidanceCopy.next,
  ],
  // ADR-024 B1: the Toolkit is retired; kept Circles are managed in Yours,
  // under You.
  'Yours (under You)': [
    YouPersonalCard.yoursTitle,
    YouPersonalCard.yoursDetail(0),
    YouPersonalCard.yoursDetail(1),
    YouPersonalCard.yoursDetail(3),
    YoursPage.intro,
    YoursPage.empty,
    'Circles you kept',
    'This Circle is no longer in Yours.',
    'It leaves Yours. Days you used it stay in your history.',
  ],
};

final _guards = <String, RegExp>{
  'medical claim or diagnosis': RegExp(
    r'\b(heal|cure|therap|treat(ment)?|symptom|diagnos|anxiety|depress|'
    r'stress|mental health|disorder|clinical|insomnia|burnout)',
    caseSensitive: false,
  ),
  'guaranteed outcome': RegExp(
    r'\b(guarantee|proven|will (help|make|give|fix)|boost|improves?|'
    r'reduces?|increase your|feel better|more energy|calmer)\b',
    caseSensitive: false,
  ),
  'invented personalisation': RegExp(
    r'\b(knows you|understands you|you need|just for you|personality|'
    r'mood|what works for you|works for you)\b',
    caseSensitive: false,
  ),
  'guilt': RegExp(
    r'\b(should|must|don.t forget|missed|failed|behind|lazy)\b',
    caseSensitive: false,
  ),
  'pressure': RegExp(
    r'(hurry up|limited time|today only|don.t miss|last chance|streak|'
    r'act now|now!|before it.s gone|every day or)',
    caseSensitive: false,
  ),
  'achievement framing': RegExp(
    r'\b(well done|great job|achiev|reward|unlock|level|score|badge|'
    r'congrat|crush|goal)',
    caseSensitive: false,
  ),
  'unsafe instruction': RegExp(
    r'(push through|no pain|harder|as fast as|breath|until you can.t)',
    caseSensitive: false,
  ),
  // Correction pass (2026-10-11): THIRTY needs neither louder audio nor
  // faster chores to be worth doing.
  'needless intensity': RegExp(
    r'(louder|quicker|faster|livelier|as many .* as you can)',
    caseSensitive: false,
  ),
  // The phone is the guide: it may be face down, in a pocket, silenced —
  // never somewhere the Circle can't be heard.
  'phone out of earshot': RegExp(
    r'(phone[^.]*\b(left|out of reach|elsewhere|inside|another room|switched '
    r'off|turned off|on silent|out of sight)\b|(leave|without) (your|the) '
    r'phone|airplane mode|flight mode)',
    caseSensitive: false,
  ),
  // Nothing that could lose unsaved work.
  'destructive closing': RegExp(
    r'\bclos(e|ing) (every|all|everything|tabs|windows|apps|what)',
    caseSensitive: false,
  ),
  // THIRTY knows the user's need and time — not the weather or the light.
  'assumed context': RegExp(
    r'\b(daylight|sunshine|sunlight|sunny|weather|rain|morning|evening|'
    r'tonight|dark)\b',
    caseSensitive: false,
  ),
};

/// The Premium offer's words: true on a subscriber's first day. Only
/// Today's own line may say "found useful", and only with evidence.
final _offerClaims = RegExp(
  r'(found useful|you.ve found|what you find useful|stays complete|knows what)',
  caseSensitive: false,
);

void main() {
  final coverage = [
    for (final need in Intention.values)
      for (final window in TimeWindow.values) Coverage(need, window),
  ];

  test('coverage: every need and time has honest, materially varied '
      'sessions', () {
    for (final c in coverage) {
      expect(
        c.mains.length,
        greaterThanOrEqualTo(5),
        reason: '${c.need} ${c.window}',
      );
      expect(
        c.material.length,
        greaterThanOrEqualTo(15),
        reason: '${c.need} ${c.window}',
      );
    }
  });

  test('content guards: no medical claim, guarantee, invented '
      'personalisation, guilt, pressure, achievement or unsafe wording', () {
    final strings = [
      for (final lines in d2Copy().values) ...lines,
      for (final e in elementLibrary.values) ...[e.name, e.instruction],
    ];
    for (final line in strings) {
      for (final MapEntry(key: guard, value: pattern) in _guards.entries) {
        expect(pattern.hasMatch(line), isFalse, reason: '$guard: “$line”');
      }
    }
  });

  test('the Premium offer claims nothing a first-day subscriber hasn’t '
      'given THIRTY', () {
    for (final place in ['Premium offer', 'Yours (under You)']) {
      for (final line in d2Copy()[place]!) {
        expect(_offerClaims.hasMatch(line), isFalse, reason: '$place: “$line”');
      }
    }
  });

  test('export the coverage report and the content pack', () {
    if (!_export) return;
    final cov = StringBuffer()
      ..writeln('# THIRTY Phase D2 — element coverage report')
      ..writeln()
      ..writeln(
        'Generated by `test/features/personal_circle/d2_review_pack_test.dart` '
        'from the release element library (ADR-023 §2). Every count comes '
        'from the composer’s own quality gate (`gatePassingShapes`).',
      )
      ..writeln()
      ..writeln('## Library')
      ..writeln()
      ..writeln('- Total elements: ${elementLibrary.length}')
      ..writeln(
        '- Release-safe (live, offerable): '
        '${elementLibrary.values.where(isElementOfferable).length}',
      )
      ..writeln(
        '- Pieces of live activities: '
        '${elementLibrary.values.where((e) => e.from != null).length} '
        '(carrying that activity’s evidence: '
        '${elementLibrary.values.where((e) => e.carriesEvidence).length})',
      )
      ..writeln(
        '- New small cues (no activity): '
        '${elementLibrary.values.where((e) => e.from == null).length}',
      )
      ..writeln(
        '- From gated breathing/exertion or retired content: 0 (tested)',
      )
      ..writeln()
      ..writeln('### Per need')
      ..writeln();
    for (final need in Intention.values) {
      cov.writeln('- ${intentionLabel(need)}: ${_allowedFor(need).length}');
    }
    cov
      ..writeln()
      ..writeln('### Per role (an element may take more than one)')
      ..writeln();
    for (final role in ElementRole.values) {
      cov.writeln(
        '- ${role.name}: '
        '${elementLibrary.values.where((e) => e.roles.contains(role)).length}',
      );
    }
    final lengths = <int, int>{};
    for (final e in elementLibrary.values) {
      for (final m in e.lengths) {
        lengths[m] = (lengths[m] ?? 0) + 1;
      }
    }
    cov
      ..writeln()
      ..writeln('### Authored lengths (minutes → how many element lengths)')
      ..writeln();
    for (final m in lengths.keys.toList()..sort()) {
      cov.writeln('- $m: ${lengths[m]}');
    }
    cov
      ..writeln()
      ..writeln('## Compositions that pass the quality gate')
      ..writeln()
      ..writeln(
        '“Materially distinct” counts sessions by their substance — the main '
        'and second piece — so a different arrival or close, or a different '
        'length of the same piece, is not a new session. Order is fixed by '
        'role, so no re-ordering is ever counted.',
      )
      ..writeln()
      ..writeln(
        '| Need | Time | Gate-passing shapes | Materially distinct | Distinct '
        'main pieces | Shortest–longest |',
      )
      ..writeln('|---|---|---|---|---|---|');
    for (final c in coverage) {
      final sorted = [...c.totals]..sort();
      cov.writeln(
        '| ${intentionLabel(c.need)} | ≈${c.window.maxMinutes} | ${c.shapes} | '
        '${c.material.length} | ${c.mains.length} | '
        '${sorted.first}–${sorted.last} min |',
      );
    }
    cov
      ..writeln()
      ..writeln('## Notes')
      ..writeln()
      ..writeln(
        '- **More Energy is the thinnest need** (fewest mains at every time, '
        'and the fewest 30-minute sessions). Its exertion and breathing '
        'content stays behind the safety gate; nothing was invented to fill '
        'it. A separate safety review of the gated activities is the honest '
        'way to widen it.',
      )
      ..writeln(
        '- The library is deliberately not padded to a number: fewer, '
        'distinct elements over many paraphrases.',
      );
    Directory('build').createSync(recursive: true);
    File('build/d2_element_coverage.md').writeAsStringSync(cov.toString());

    final pack = StringBuffer()
      ..writeln('# THIRTY Phase D2 — founder content review pack')
      ..writeln()
      ..writeln(
        'Every user-facing string Phase D2 adds or changes, generated from '
        'the shipping code (`d2_review_pack_test.dart`). The content guards '
        '(medical claims, diagnosis, guarantees, invented personalisation, '
        'guilt, pressure, achievement, unsafe instructions) run on all of it '
        'in the test suite. **Founder approval is required before release.**',
      )
      ..writeln()
      ..writeln('## Elements (${elementLibrary.length})')
      ..writeln();
    for (final role in ElementRole.values) {
      pack
        ..writeln('### ${role.name[0].toUpperCase()}${role.name.substring(1)}')
        ..writeln();
      for (final e in elementLibrary.values.where(
        (e) => e.roles.first == role,
      )) {
        pack.writeln(
          '- **${e.name}** (`${e.id.name}`; '
          '${[for (final n in e.needs) intentionLabel(n)].join(', ')}; '
          '${e.lengths.join(' or ')} min; '
          '${e.from == null ? 'new cue' : 'from ${activityLabel(e.from!)}'}'
          '${e.carriesEvidence ? ', carries its evidence' : ''}): '
          '“${e.instruction}”',
        );
      }
      pack.writeln();
    }
    for (final MapEntry(key: place, value: lines) in d2Copy().entries) {
      pack
        ..writeln('## $place')
        ..writeln();
      for (final line in lines) {
        pack.writeln('- “$line”');
      }
      pack.writeln();
    }
    pack
      ..writeln('## Parts that build on another')
      ..writeln()
      ..writeln(
        'Composed only directly after the part they build on; skipping that '
        'part skips them too (the Skip sheet says so).',
      )
      ..writeln();
    for (final e in elementLibrary.values.where((e) => e.after != null)) {
      pack.writeln(
        '- **${e.name}** builds on **${elementOf(e.after!).name}**: '
        '“${e.instruction}”',
      );
    }
    final manifest = spokenGuidanceManifest;
    pack
      ..writeln()
      ..writeln('## Spoken guidance — the recording manifest')
      ..writeln()
      ..writeln(
        'Founder decision: bundled, pre-generated recordings. **No recording '
        'exists yet** — the voice and every clip need founder approval. '
        '${manifest.length} clips: three leads, one per element, and the '
        'close. When a part begins the voice plays its lead (“First.” for '
        'the first part, “And last.” for the last, otherwise “Next.”), then '
        'the part’s own clip; after the last part, the close. Each file '
        'name carries a fingerprint of its script: changing a line makes '
        'its clip missing, and the voice stays silent until the whole set '
        'is complete again. Each of THIRTY’s two voices records the whole '
        'set in its own folder: `$spokenGuidanceAssetDir/<voice>/<file>`, '
        'with <voice> one of ${ThirtyVoice.values.map((v) => v.id).join(', ')}.',
      )
      ..writeln()
      ..writeln('| Clip | File | Script |')
      ..writeln('|---|---|---|');
    for (final clip in manifest) {
      pack.writeln('| `${clip.id}` | `${clip.file}` | ${clip.script} |');
    }
    final sample = composeCircle(
      ComposerContext(
        date: DateTime(2026, 10, 11),
        need: Intention.clearerHead,
        window: TimeWindow.about20,
      ),
      const [],
    )!.plan;
    pack
      ..writeln()
      ..writeln('### One Circle, as it would be heard (${sample.line})')
      ..writeln();
    for (var i = 0; i < sample.parts.length; i++) {
      pack.writeln(
        '- “${spokenCueFor(sample, i).map((c) => c.script).join(' ')}”',
      );
    }
    pack
      ..writeln('- “${spokenEnding.script}”')
      ..writeln();
    File('build/d2_content_review.md').writeAsStringSync(pack.toString());
    final csv = StringBuffer()..writeln('clip,role,file,script');
    for (final clip in manifest) {
      csv.writeln(
        '${clip.id},${clip.role.name},${clip.file},'
        '"${clip.script.replaceAll('"', '""')}"',
      );
    }
    File(
      'build/d2_spoken_guidance_manifest.csv',
    ).writeAsStringSync(csv.toString());
  });
}
