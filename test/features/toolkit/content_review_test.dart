import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/premium/presentation/premium_offer_page.dart';
import 'package:thirty/features/toolkit/domain/maintenance.dart';
import 'package:thirty/features/toolkit/domain/module_library.dart';
import 'package:thirty/features/toolkit/domain/path_catalog.dart';
import 'package:thirty/features/toolkit/domain/path_engine.dart';
import 'package:thirty/features/toolkit/domain/toolkit_model.dart';

/// V2 Phase D — the founder's content review pack, generated from the very
/// catalogues the app runs on, so it can never drift from them:
///
/// ```
/// flutter test test/features/toolkit/content_review_test.dart \
///   --dart-define=EXPORT_REVIEW=true
/// ```
///
/// writes `build/premium_content_review.md`.
const _export = bool.fromEnvironment('EXPORT_REVIEW');

/// Why each Path exists beside the other one for its need — a difference
/// in what the user does, not in title, art or indoor/outdoor alone.
const _whyDistinct = {
  PathTemplateId.wakeUpIndoors:
      'Short bursts of movement at home — songs you like, a useful job, a '
      'stretch — stacked into 15–25 minutes, for when you can’t or don’t '
      'want to go out. Out the door is one continuous brisk effort outside; '
      'this is short, indoor and made of different kinds of movement.',
  PathTemplateId.outTheDoor:
      'One sustained, brisk effort outdoors — a walk at a quicker pace, set '
      'up with a stretch — for 25–30 minutes of continuous movement, fresh '
      'air and daylight. A lift at home is short pieces indoors; this is one '
      'longer effort outside.',
  PathTemplateId.clearTheDecks:
      'Offload and put in order: what’s in your head goes onto paper, then '
      'one physical space is cleared, so the next thing has room. It acts on '
      'what is competing for attention. Away from the screen removes the '
      'input instead.',
  PathTemplateId.awayFromTheScreen:
      'Less coming in: a walk with the phone out of sight, then one thing to '
      'listen to with nothing else asked. It removes what competes for '
      'attention rather than sorting it, as Clear the decks does.',
  PathTemplateId.softLanding:
      'Stillness at home: a warm drink, gentle stretching, quiet music — '
      'slowing down without going anywhere or doing anything. Easy time '
      'outdoors slows down through gentle movement outside instead.',
  PathTemplateId.slowTimeOutside:
      'Gentle movement and fresh air: an easy walk, then somewhere outside '
      'to sit. Slowing down by moving slowly outdoors, where A soft landing '
      'stays still at home.',
};

/// Copy that lives in the Toolkit's widgets: quoted here exactly, and
/// checked against the source so the pack can't drift from it.
const _pageCopy = {
  'lib/features/toolkit/presentation/toolkit_page.dart': [
    'Routines that are yours.',
    'This Path has had all its Circles. See what it built, and decide '
        'whether to keep it.',
    'is resting after your “Not useful”, so this Path waits until its '
        'rest is over. Other days, nothing changes.',
    'or more, and this is your Circle. Other days, nothing changes.',
    'Saved where you left it. It continues when Premium is active again.',
    'Nothing is added to your Toolkit. Its Circles stay in your history.',
    'Its Circles stay in your history. You can start a Path again whenever '
        'you like.',
    'Tuning routines is Premium. Your routines stay yours either way.',
    'Routines you built stay yours — THIRTY still offers them on Today. '
        'Building and tuning routines is Premium.',
    'With Premium, a Path tries a few pieces with you over seven Circles — '
        'short, then in full, then together — and ends with a routine you '
        'keep. When your days change, THIRTY offers to tune it.',
    'Routines you build stay yours, with or without Premium. Free stays '
        'complete: THIRTY still chooses one thing for today.',
    'A simple place to start. You can choose another Path.',
  ],
  'lib/features/toolkit/presentation/path_start_page.dart': [
    'Your first Circles try the pieces short, then one in full, then two '
        'together, and a shorter form for busier days. After seven Circles '
        'you see what it built, and decide whether to keep it.',
    'Other days, nothing changes, and missed days don’t matter. Answering '
        'after a Circle helps it fit you, but you never have to.',
    'This Path can’t build an honest routine right now: too few of its '
        'pieces are open. Some you’ve asked THIRTY not to suggest; some are '
        'resting after a recent “Not useful”, and a rest ends on its own. '
        'You’ll find both in What THIRTY remembers.',
    'Paths are part of Premium.',
    'One Path at a time: finish or leave the one under way first.',
  ],
  'lib/features/toolkit/presentation/path_review_page.dart': [
    'What your Path built',
    'Your routine, tuned',
    'useful \${facts.positiveForResult} of the \${facts.answeredForResult} '
        'times you said.',
    'Shaped by what you told THIRTY along the way.',
    'Here’s what you built through this Path.',
    'And a shorter form — about \${shorter.minutes} minutes — for days with '
        'less time.',
    'THIRTY would use it on days with less time. Your routine itself stays '
        'as it is.',
  ],
  'lib/features/toolkit/presentation/routine_detail_page.dart': [
    'Off — THIRTY won’t offer it until you turn it on.',
    'It hasn’t suited you as well lately.',
    'Still learning how this one fits.',
    'A shorter version, or tuning it, is Premium. Your routine stays yours, '
        'and THIRTY keeps offering it either way.',
    'It and its versions leave your Toolkit, and THIRTY won’t offer it '
        'again. Circles you did with it stay in your history.',
  ],
};

String _need(Intention need) => intentionLabel(need);

String _fit(SessionModule m) => [
  for (final need in Intention.values)
    if (m.fitFor(need) != NeedFit.none)
      '${_need(need)} (${m.fitFor(need).name})',
].join(', ');

List<PathTemplate> _pathsUsing(ModuleId id) => [
  for (final t in pathCatalog)
    if (t.pool.contains(id)) t,
];

String _treatments(SessionModule m) {
  final partners = {
    for (final t in _pathsUsing(m.id))
      for (final other in t.pool)
        if (other != m.id) moduleOf(other).name,
  };
  return [
    if (m.hasShortForm)
      '  - **short** (${m.shortMinutes} min): “${m.shortInstruction}”'
    else
      '  - **short:** none — one authored length, so it is always tried whole.',
    if (m.guided)
      '  - **full** (${m.fullMinutes} min): its own '
          '${m.activity.steps.length} Guided steps, as authored in Phase A.'
    else
      '  - **full** (${m.fullMinutes} min): “${m.fullInstruction}”',
    '  - **combined:** joined with ${partners.join(' or ')} as one Circle, '
        'this piece as the ${m.role.name} — a routine.',
    m.hasShortForm
        ? '  - *What changes:* short is ${m.fullMinutes - m.shortMinutes} '
              'minutes shorter and asks only for the core of the piece; full '
              'adds the idea that makes it work; combined is a different '
              'Circle — two pieces one after the other.'
        : '  - *What changes:* there is no shorter form to pretend with; the '
              'only other treatment is combined — a different Circle.',
  ].join('\n');
}

String _guidedSteps(SessionModule m) => [
  for (final (i, step) in m.activity.steps.indexed)
    '  ${i + 1}. **${step.name}** — ${step.instruction} (${step.cue})',
].join('\n');

/// The default walk: a Path with no answers at all, as a sparse user
/// would get it. Returns its seven lines and what it proposes.
(List<String>, PathProposal) _walk(PathTemplate t) {
  var run = PathRun(
    id: 'r',
    kind: PathKind.build,
    need: t.need,
    startedAt: DateTime(2026),
    pool: t.pool,
    seed: SeedReason.sparseStart,
    template: t.id,
  );
  final lines = <String>[];
  for (var i = 1; i <= 7; i++) {
    final step = nextPathStep(run, const {})!;
    lines.add(
      '  $i. ${step.composition.title} — ${step.composition.minutes} min — '
      '“${step.explanation}”',
    );
    run = run.withCircle(
      PathCircle(
        circleId: 'c$i',
        number: i,
        composition: step.composition,
        reason: step.reason,
      ),
    );
  }
  return (lines, proposalFor(run, const {})!);
}

String _pieces(Composition c) => [
  for (final use in c.uses)
    '${use.definition.name} ${use.short ? '(short)' : '(full)'} '
        '${use.minutes} min',
].join(' + ');

/// Every routine [t] can build (each pair of its pieces), with its truly
/// shorter versions.
String _routines(PathTemplate t) {
  final b = StringBuffer();
  final seen = <Set<ModuleId>>[];
  for (final a in t.pool) {
    for (final p in t.pool) {
      if (a == p) continue;
      final base = fullTogether(a, p);
      if (base == null || seen.any((s) => s.containsAll(base.modules))) {
        continue;
      }
      seen.add(base.modules);
      final shorter = {
        for (final target in const [10, 20, 30])
          ...shorterVersionsOf(base, target),
      }.toList()..sort((x, y) => y.minutes.compareTo(x.minutes));
      b.writeln(
        '  - **${base.title}** — ${base.minutes} min: ${_pieces(base)}',
      );
      if (shorter.isEmpty) {
        b.writeln(
          '    - Shorter version: **none.** No piece has a shorter authored '
          'form that would make it shorter, so THIRTY never offers one; on '
          'a shorter day this routine simply doesn’t fit, and Free decides.',
        );
      }
      for (final s in shorter) {
        b.writeln(
          '    - Shorter version: ${s.minutes} min — ${_pieces(s)}. Same '
          'routine: every piece, in the same order, each at a length it was '
          'written for.',
        );
      }
    }
  }
  return b.toString();
}

(int, int) _pairRange(PathTemplate t) {
  final minutes = [
    for (final a in t.pool)
      for (final p in t.pool)
        if (a != p) ?fullTogether(a, p)?.minutes,
  ];
  return (
    minutes.reduce((a, b) => a < b ? a : b),
    minutes.reduce((a, b) => a > b ? a : b),
  );
}

String _pack() {
  final b = StringBuffer()
    ..writeln('# THIRTY V2 — Phase D: Premium content for founder review')
    ..writeln()
    ..writeln(
      'Generated from the app’s own catalogues (module_library, path_catalog, '
      'path_engine, maintenance, the offer page) and checked against the '
      'Toolkit’s widgets, so it cannot drift from what ships. Claude drafted '
      'this copy; it is not final until the founder approves it. No piece is '
      'new health content: each module reuses a live Phase A activity.',
    )
    ..writeln()
    ..writeln('## Modules (${moduleLibrary.length}, all release-eligible)')
    ..writeln();
  for (final m in moduleLibrary.values) {
    b
      ..writeln('### ${m.name} — `${m.id.name}`')
      ..writeln()
      ..writeln(
        '- **Source activity:** “${m.activity.title}” (`${m.source.name}`), '
        '${m.activity.status.name}',
      )
      ..writeln('- **Need fit:** ${_fit(m)}')
      ..writeln(
        '- **Durations:** '
        '${m.hasShortForm ? 'short ${m.shortMinutes} min · full ${m.fullMinutes} min' : 'one length, ${m.fullMinutes} min'}',
      )
      ..writeln(
        '- **Mode:** ${m.guided ? 'Guided steps (${m.activity.steps.length})' : 'Open'}',
      )
      ..writeln('- **Role in a routine:** ${m.role.name}')
      ..writeln('- **Purpose:** “${m.purpose}”')
      ..writeln(
        '- **Paths using it:** '
        '${_pathsUsing(m.id).map((t) => t.name).join(', ')}',
      )
      ..writeln(
        '- **Safety note (its activity’s own):** '
        '${m.activity.safetyNote == null ? 'none' : '“${m.activity.safetyNote}”'}',
      )
      ..writeln('- **Treatments** (internal words, never shown to users):')
      ..writeln(_treatments(m));
    if (m.guided) {
      b
        ..writeln('- **Key copy — its Guided steps:**')
        ..writeln(_guidedSteps(m));
    }
    b.writeln();
  }

  b
    ..writeln('## Paths (${pathCatalog.length})')
    ..writeln();
  for (final t in pathCatalog) {
    final (lines, proposal) = _walk(t);
    final pool = t.pool.map(moduleOf).toList();
    b
      ..writeln('### ${t.name} — `${t.id.name}`')
      ..writeln()
      ..writeln('- **Need:** ${_need(t.need)}')
      ..writeln('- **Job (“What you’re building”):** “${t.building}”')
      ..writeln('- **Why distinct:** ${_whyDistinct[t.id]}')
      ..writeln('- **Pieces:** ${pool.map((m) => m.name).join(', ')}')
      ..writeln('- **Default routine name:** “${t.routineName}”')
      ..writeln(
        '- **Seed copy:** on the start page “${moduleOf(t.pool.first).name} '
        'comes first: you’ve found it useful.”; on Today “${pathStepExplanation(PathStepReason.startsWithUseful)}” '
        '(when the user found a piece useful for ${_need(t.need)})',
      )
      ..writeln(
        '- **Sparse copy:** “A simple place to start. You can choose another '
        'Path.” on the Toolkit, and “${pathStepExplanation(PathStepReason.firstTry)}” '
        'on Circle 1 — nothing personal is claimed.',
      )
      ..writeln(
        '- **Adaptation copy:** “${pathStepExplanation(PathStepReason.alternateAfterNegative)} · ${pathStepExplanation(PathStepReason.alternateAfterNegative, combined: true)}” · '
        '“${pathStepExplanation(PathStepReason.repeatUseful)} · ${pathStepExplanation(PathStepReason.repeatUseful, combined: true)}”',
      )
      ..writeln(
        '- **Review copy:** “What your Path built”, then one of: “You found '
        'these together useful n of the m times you said.” (only from 2+ '
        'positive answers) · “Shaped by what you told THIRTY along the way.” '
        '· “Here’s what you built through this Path.”',
      )
      ..writeln('- **7-Circle structure, with no answers at all:**')
      ..writeln(lines.join('\n'))
      ..writeln(
        '- **Routine produced (that walk):** “${t.routineName}” — '
        '${_pieces(proposal.composition)}, ${proposal.composition.minutes} min'
        '${proposal.shorter == null ? '; no shorter version' : '; shorter version ${_pieces(proposal.shorter!)}, ${proposal.shorter!.minutes} min'}',
      )
      ..writeln(
        '- **Every routine this Path can build, and its shorter versions:**',
      )
      ..write(_routines(t))
      ..writeln();
  }

  b
    ..writeln('## Path step lines (the Today card)')
    ..writeln();
  for (final reason in PathStepReason.values) {
    final single = pathStepExplanation(reason);
    final together = pathStepExplanation(reason, combined: true);
    b.writeln(
      '- `${reason.name}`: “$single”'
      '${together == single ? '' : ' · two pieces: “$together”'}',
    );
  }

  final sample = Routine(
    id: 'x',
    name: 'My reset',
    need: Intention.clearerHead,
    versions: [
      RoutineVersion(
        id: 'x1',
        number: 1,
        composition: Composition(const [
          ModuleUse(ModuleId.writeDown, short: false),
          ModuleUse(ModuleId.clearSurface, short: false),
        ]),
        createdAt: DateTime(2026),
        origin: VersionOrigin.path,
      ),
    ],
    activeVersionId: 'x1',
    createdAt: DateTime(2026),
  );
  b
    ..writeln()
    ..writeln('## Maintenance, check and evidence copy')
    ..writeln();
  for (final offer in [
    MaintenanceOffer(
      kind: OfferKind.timeMisfit,
      key: '',
      need: Intention.clearerHead,
      routine: sample,
      targetMinutes: 20,
      window: TimeWindow.about20,
    ),
    MaintenanceOffer(
      kind: OfferKind.fading,
      key: '',
      need: Intention.clearerHead,
      routine: sample,
    ),
    const MaintenanceOffer(
      kind: OfferKind.gap,
      key: '',
      need: Intention.clearerHead,
      window: TimeWindow.about20,
      template: PathTemplateId.clearTheDecks,
    ),
  ]) {
    b.writeln(
      '- **${offer.kind.name}:** “${offer.evidence}” — “${offer.proposal}”',
    );
  }
  b
    ..writeln(
      '- **Stable (Toolkit check):** '
      '“${const ToolkitCheck(state: CheckState.stable).message}”',
    )
    ..writeln(
      '- **Insufficient evidence (Toolkit check):** '
      '“${const ToolkitCheck(state: CheckState.learning).message}”; on a '
      'routine’s page: “Still learning how this one fits.”',
    )
    ..writeln(
      '- **Offers:** eyebrow “Worth a look” (or “Toolkit check” when the '
      'check came round), actions “Try it” / “Not now”.',
    )
    ..writeln()
    ..writeln('## Offer page')
    ..writeln()
    ..writeln('- **Headline:** “${PremiumOfferPage.headline}”')
    ..writeln('- **Promise:** “${PremiumOfferPage.promise}”');
  for (final (name, line) in PremiumOfferPage.points) {
    b.writeln('- **$name:** “$line”');
  }
  b
    ..writeln('- **Free line:** “${PremiumOfferPage.freeLine}”')
    ..writeln('- **Under the action:** “Routines you build stay yours.”')
    ..writeln()
    ..writeln('## Toolkit, start, review, routine and lapse copy')
    ..writeln();
  for (final MapEntry(key: file, value: lines) in _pageCopy.entries) {
    b.writeln('From `${file.split('/').last}`:');
    for (final line in lines) {
      b.writeln('- “${line.replaceAll(r'${', '{')}”');
    }
    b.writeln();
  }
  return b.toString();
}

void main() {
  test('the review pack covers every module and Path', () {
    final pack = _pack();
    for (final m in moduleLibrary.values) {
      expect(pack, contains('`${m.id.name}`'));
    }
    for (final t in pathCatalog) {
      expect(pack, contains('`${t.id.name}`'));
      expect(_whyDistinct[t.id], isNotNull, reason: t.name);
    }
    if (_export) {
      Directory('build').createSync(recursive: true);
      File('build/premium_content_review.md').writeAsStringSync(pack);
    }
  });

  test('the page copy quoted in the pack is the copy that ships', () {
    for (final MapEntry(key: file, value: lines) in _pageCopy.entries) {
      final source = File(
        file,
      ).readAsStringSync().replaceAll(RegExp(r"'\s*\n\s*'"), '');
      for (final line in lines) {
        expect(source, contains(line), reason: '$file: $line');
      }
    }
  });

  test('each Path\'s job states the length its routines really have', () {
    for (final t in pathCatalog) {
      final (low, high) = _pairRange(t);
      final stated = low == high
          ? 'about $low minutes'
          : 'about $low to $high minutes';
      expect(t.building, contains(stated), reason: t.name);
    }
  });

  test('no Path job or offer line promises an outcome — it may say what the '
      'user wants and what the routine holds, never that it will work', () {
    const promises = [
      'so you come back',
      'lifts your',
      'you will feel',
      'you’ll feel',
      'makes you',
      'calmer',
      'clearer head',
      'better mood',
      'healthier',
      'boost',
    ];
    final copy = [
      for (final t in pathCatalog) t.building,
      PremiumOfferPage.headline,
      PremiumOfferPage.promise,
      PremiumOfferPage.freeLine,
      for (final (name, line) in PremiumOfferPage.points) '$name $line',
    ];
    for (final line in copy) {
      for (final promise in promises) {
        expect(line.toLowerCase(), isNot(contains(promise)), reason: line);
      }
    }
  });

  test('no default routine name is a mechanical "My <Path>" or tied to a '
      'time of day', () {
    for (final t in pathCatalog) {
      expect(t.routineName, isNot('My ${t.name}'));
      for (final word in ['wake', 'morning', 'evening', 'night', 'wind-down']) {
        expect(t.routineName.toLowerCase(), isNot(contains(word)));
        expect(t.name.toLowerCase(), isNot(contains(word)));
      }
    }
  });
}
