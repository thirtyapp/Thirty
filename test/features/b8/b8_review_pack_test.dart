import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/spoken_cues.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_copy.dart';
import 'package:thirty/features/premium/presentation/premium_offer_page.dart';

import 'support/live_copy.dart';

/// ADR-024 B8 — the founder's content review pack, generated from current
/// production source so it cannot drift:
///
/// ```
/// flutter test test/features/b8/b8_review_pack_test.dart \
///   --dart-define=EXPORT_B8_PACK=true
/// ```
///
/// writes `artifacts/v2_phase_d2/b8/CONTENT_REVIEW_PACK.md` and its
/// `MANIFEST.json`. Without the flag the test regenerates the pack in
/// memory and fails if its content no longer matches the manifest — so any
/// change to live copy shows up until the pack is regenerated and looked at.
/// The pack is evidence, never a source of truth: production never reads it.
const _export = bool.fromEnvironment('EXPORT_B8_PACK');
const _dir = 'artifacts/v2_phase_d2/b8';

/// Where each surface's words live.
const surfaces = <(String, String, List<String>)>[
  (
    'A',
    'Today',
    [
      'lib/features/home/presentation/home_page.dart',
      'lib/features/home/presentation/widgets/',
      'lib/features/home/domain/recommendation_engine.dart',
      'lib/features/home/application/recommendation_provider.dart',
      'lib/features/personal_circle/domain/composed_session.dart',
      'lib/features/personal_circle/presentation/keep_circle_card.dart',
      'lib/features/personal_circle/presentation/skip_part_sheet.dart',
      'lib/features/personal_circle/presentation/use_today_control.dart',
      'lib/features/premium/presentation/widgets/premium_offer_invitation_card.dart',
      'lib/features/reminder/',
    ],
  ),
  ('B', 'Plans', ['lib/features/plans/']),
  (
    'C',
    'Insights',
    [
      'lib/features/insights/',
      'lib/features/home/presentation/circle_history_page.dart',
      'lib/features/home/presentation/circle_record_detail_page.dart',
    ],
  ),
  (
    'D',
    'You',
    [
      'lib/features/settings/',
      'lib/features/home/presentation/memory_page.dart',
      'lib/features/personal_circle/presentation/yours_page.dart',
      'lib/features/personal_circle/presentation/kept_circle_page.dart',
      'lib/features/personal_circle/presentation/widgets/',
      'lib/features/personal_circle/domain/spoken_cues.dart',
      'lib/features/premium/presentation/widgets/manage_subscription.dart',
      'lib/features/premium/presentation/widgets/premium_restore_footer.dart',
      'lib/core/routing/app_shell.dart',
    ],
  ),
  (
    'E',
    'Premium offer',
    ['lib/features/premium/presentation/premium_offer_page.dart'],
  ),
];

final _lapse = RegExp(
  r'cancel|lapse|stays active|with or without Premium|carries on with '
  r'Premium|part of Premium|without THIRTY’s voice|Saved at stage|'
  r'Premium status is',
  caseSensitive: false,
);
final _accessibility = RegExp(
  r'label:|tooltip:|barrierLabel:|semanticLabel|semanticsLabel|Semantics\(',
);

/// FNV-1a, 64-bit: a stable content hash without another dependency.
String fnv64(String s) {
  var h = 0xcbf29ce484222325;
  for (final b in utf8.encode(s)) {
    h ^= b;
    h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  }
  return h.toUnsigned(64).toRadixString(16).padLeft(16, '0');
}

String _norm(String s) => s.replaceAll("'", '’').trim();

class Pack {
  Pack() {
    final files = productionFiles();
    for (final f in files) {
      // Only files a surface owns: the World catalogue's art direction and
      // other internal text never reach a person.
      if (!surfaces.any((x) => x.$3.any(f.startsWith))) continue;
      for (final s in literalsIn(f)) {
        if (looksLikeCopy(s)) strings.add(s);
      }
    }
  }

  final strings = <LiveString>[];
  final flags = <String>[];
  final body = StringBuffer();
  final sources = <String>{};

  void line([String s = '']) => body.writeln(s);

  /// One surface's strings, each once, with where it first appears.
  void stringsOf(List<String> prefixes) {
    final seen = <String, (LiveString, int)>{};
    for (final s in strings) {
      if (!prefixes.any(s.file.startsWith)) continue;
      sources.add(s.file);
      final key = s.text;
      final prior = seen[key];
      seen[key] = prior == null ? (s, 1) : (prior.$1, prior.$2 + 1);
    }
    final byFile = <String, List<(LiveString, int)>>{};
    for (final v in seen.values) {
      (byFile[v.$1.file] ??= []).add(v);
    }
    for (final file in byFile.keys.toList()..sort()) {
      line('**`${file.replaceFirst('lib/', '')}`**');
      line();
      for (final (s, n)
          in byFile[file]!..sort((a, b) => a.$1.line - b.$1.line)) {
        line('- ${s.text}${n > 1 ? ' *(×$n)*' : ''}');
      }
      line();
    }
  }

  String build() {
    line('## A. Today');
    line();
    line('### A1. Activities (live catalogue)');
    line();
    for (final a in activityCatalog.values) {
      if (a.status != ActivityStatus.live) continue;
      final needs = [
        for (final e in a.fit.entries)
          if (e.value != NeedFit.none) '${e.key.name} (${e.value.name})',
      ];
      line('#### ${a.title}');
      line();
      line(
        '- Needs: ${needs.join(', ')} · ${a.minMinutes}–${a.typicalMinutes} '
        'min · ${a.mode.name}',
      );
      for (final e in a.reasons.entries) {
        line('- Why (${e.key.name}): ${e.value}');
      }
      line('- First action: ${a.firstAction}');
      if (a.preparation != null) line('- Preparation: ${a.preparation}');
      for (final w in a.whileYoureThere) {
        line('- While you’re there: $w');
      }
      for (final s in a.steps) {
        line('- Step — ${s.name}: ${s.instruction}');
      }
      if (a.lighter != null) line('- Lighter: ${a.lighter}');
      if (a.safetyNote != null) line('- Safety: ${a.safetyNote}');
      line('- Ending: ${a.ending}');
      line();
    }
    line('### A2. Circle parts (live, safe library)');
    line();
    for (final e in elementLibrary.values) {
      if (!isElementOfferable(e)) continue;
      line(
        '- **${e.name}** (${[for (final n in e.needs) n.name].join(', ')}; '
        '${e.lengths.join('/')} min): ${e.instruction}',
      );
    }
    line();
    line('### A3. Today’s words');
    line();
    stringsOf(surfaces[0].$3);

    line('## B. Plans');
    line();
    for (final plan in launchCirclePlans) {
      line('### ${plan.name} — ${plan.need.name}');
      line();
      line('- Purpose: ${PlanCopy.purpose[plan.id]}');
      line('- Card: ${PlanCopy.card[plan.id]}');
      for (final s in plan.stages) {
        line(
          '- Stage ${s.number} · ${s.name}: '
          '${PlanCopy.todayLine[s.id] ?? PlanCopy.stageFiveMix}',
        );
      }
      line();
    }
    line('### B1. Plans’ words');
    line();
    stringsOf(surfaces[1].$3);

    line('## C. Insights');
    line();
    stringsOf(surfaces[2].$3);

    line('## D. You');
    line();
    line('Voices: ${[for (final v in ThirtyVoice.values) v.label].join(', ')}');
    line();
    stringsOf(surfaces[3].$3);

    line('## E. Premium offer');
    line();
    line('- Headline: ${PremiumOfferPage.headline}');
    line('- Promise: ${PremiumOfferPage.promise}');
    for (final (name, l) in PremiumOfferPage.points) {
      line('- Point — $name: $l');
    }
    line(
      '- With THIRTY’s voice — ${PremiumOfferPage.voicedPoints[1].$1}: '
      '${PremiumOfferPage.voicedPoints[1].$2}',
    );
    line('- Free: ${PremiumOfferPage.freeLine}');
    line('- Lapse: ${PremiumOfferPage.lapseLine}');
    line('- Lapse (with voice): ${PremiumOfferPage.voicedLapseLine}');
    line();
    stringsOf(surfaces[4].$3);

    line('## F. Lapse and cancellation (every surface)');
    line();
    for (final t in {
      for (final s in strings)
        if (_lapse.hasMatch(s.text)) s.text,
    }) {
      line('- $t');
    }
    line();

    line('## G. Accessibility (spoken labels with product meaning)');
    line();
    line(
      '- Tabs: “Today, Tab 1 of 4” · “Plans, Tab 2 of 4” · “Insights, Tab '
      '3 of 4” · “You, Tab 4 of 4” (Material’s position, with the selected '
      'state)',
    );
    for (final t in {
      for (final s in strings)
        if (_accessibility.hasMatch(s.context) &&
            s.file.contains('/presentation/'))
          s.text,
    }) {
      line('- $t');
    }
    line();
    _founderFlags();
    return body.toString();
  }

  /// Only concrete items: copy that differs from frozen authority, thin
  /// content, historical wording still shown, and typographic
  /// inconsistency — never a style opinion.
  void _founderFlags() {
    // 1. Plan copy against ADR-024 §4 (the founder-approved launch copy).
    final adr = File(
      'docs/product/adr/ADR-024-v2-circle-plans-insights-and-four-tab-product.md',
    ).readAsStringSync();
    for (final plan in launchCirclePlans) {
      for (final (what, text) in [
        ('purpose', PlanCopy.purpose[plan.id]!),
        ('card', PlanCopy.card[plan.id]!),
        for (final s in plan.stages.take(4))
          ('stage ${s.number} line', PlanCopy.todayLine[s.id]!),
        for (final s in plan.stages) ('stage ${s.number} name', s.name),
      ]) {
        if (!_norm(adr).contains(_norm(text))) {
          flags.add('${plan.name} $what differs from ADR-024 §4: “$text”');
        }
      }
    }
    // 2. Thin content: need × time cells with few materially distinct
    //    sessions (main and second piece).
    for (final need in Intention.values) {
      for (final window in TimeWindow.values) {
        final allowed = [
          for (final e in elementLibrary.values)
            if (isElementOfferable(e) && e.fits(need)) e,
        ];
        final material = <String>{};
        final mains = <ElementId>{};
        for (final parts in gatePassingShapes(
          allowed,
          window: window.maxMinutes,
        )) {
          final plan = CirclePlan(parts);
          mains.add(plan.main.element);
          material.add(
            ([
              for (final p in plan.parts)
                if (p.definition.roles.contains(ElementRole.main) ||
                    p.definition.roles.contains(ElementRole.second))
                  p.element.name,
            ]..sort()).join('+'),
          );
        }
        if (material.length < 25) {
          flags.add(
            'Thin: ${need.name} at ≈${window.maxMinutes} has '
            '${material.length} materially distinct sessions and '
            '${mains.length} main pieces (ADR-024 §10 known risk).',
          );
        }
      }
    }
    // 3. Historical wording that live code still shows.
    for (final s in strings) {
      if (s.text.startsWith('Your routine')) {
        flags.add(
          '“${s.text}” is still shown for History records from '
          'retired routines (development devices only; ADR-024 §3 keeps '
          'such records readable).',
        );
        break;
      }
    }
    // 4. Apostrophes: straight and curly both appear in live copy.
    final straight = {
      for (final s in strings)
        if (RegExp(r"[A-Za-z]'[A-Za-z]").hasMatch(s.text)) s.text,
    };
    final curly = strings.where((s) => s.text.contains('’')).length;
    if (straight.isNotEmpty && curly > 0) {
      final examples = straight.take(6).map((t) => '“$t”').join(', ');
      flags.add(
        'Apostrophes are mixed: ${straight.length} live strings use a '
        'straight one (e.g. $examples) while $curly use ’.',
      );
    }
    line('## H. Founder flags (concrete only)');
    line();
    if (flags.isEmpty) {
      line('NONE');
    } else {
      for (final f in flags) {
        line('- $f');
      }
    }
  }
}

void main() {
  test('the review pack is generated from production and matches its '
      'manifest', () {
    final pack = Pack();
    final body = pack.build();
    final hash = fnv64(body);
    expect(pack.strings.length, greaterThan(500));
    expect(body, contains(PremiumOfferPage.headline));
    for (final heading in [
      '## A. Today',
      '## B. Plans',
      '## C. Insights',
      '## D. You',
      '## E. Premium offer',
      '## F. Lapse',
      '## G. Accessibility',
      '## H. Founder flags',
    ]) {
      expect(body, contains(heading));
    }
    if (_export) {
      Directory(_dir).createSync(recursive: true);
      final head = Process.runSync('git', [
        'rev-parse',
        'HEAD',
      ]).stdout.toString().trim();
      final generated = DateTime.now().toUtc().toIso8601String();
      File('$_dir/CONTENT_REVIEW_PACK.md').writeAsStringSync(
        '# THIRTY — D2 content review pack (B8)\n\n'
        '> **REVIEW ARTIFACT — DERIVED FROM CURRENT PRODUCTION COPY.** Not '
        'canonical authority: the product contract, ADR-024 and the code '
        'are. Generated $generated from the working tree at HEAD `$head` '
        '(intentionally uncommitted B0–B8 work). Manifest: `MANIFEST.json`.'
        '\n\n$body',
      );
      final files = productionFiles();
      File('$_dir/MANIFEST.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'artifact': 'CONTENT_REVIEW_PACK.md',
          'kind': 'REVIEW ARTIFACT — DERIVED FROM CURRENT PRODUCTION COPY',
          'canonicalAuthority': false,
          'generatedAtUtc': generated,
          'gitHead': head,
          'workingTree':
              'intentionally uncommitted (B0–B8 for founder review); the pack '
              'reflects the working tree, not HEAD',
          'generator': 'test/features/b8/b8_review_pack_test.dart',
          'extractor': 'test/features/b8/support/live_copy.dart',
          'productionFilesScanned': files.length,
          'copyStringsExtracted': pack.strings.length,
          'sourceFilesInPack': pack.sources.toList()..sort(),
          'contentHashFnv64': hash,
          'founderFlags': pack.flags.length,
        }),
      );
    }
    final manifest =
        jsonDecode(File('$_dir/MANIFEST.json').readAsStringSync())
            as Map<String, Object?>;
    expect(
      manifest['contentHashFnv64'],
      hash,
      reason:
          'live copy changed since the pack was generated — regenerate '
          'it with --dart-define=EXPORT_B8_PACK=true and review the diff',
    );
    expect(manifest['copyStringsExtracted'], pack.strings.length);
    expect(manifest['canonicalAuthority'], false);
    expect(
      File('$_dir/CONTENT_REVIEW_PACK.md').readAsStringSync(),
      contains(body),
    );
  });
}
