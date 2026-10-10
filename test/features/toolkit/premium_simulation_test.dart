import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/toolkit/application/toolkit_provider.dart';
import 'package:thirty/features/toolkit/domain/maintenance.dart';
import 'package:thirty/features/toolkit/domain/module_library.dart';
import 'package:thirty/features/toolkit/domain/path_catalog.dart';
import 'package:thirty/features/toolkit/domain/toolkit_model.dart';
import 'package:thirty/features/toolkit/presentation/toolkit_page.dart';

/// V2 Phase D — eight-week Premium simulations (ADR-022). Each runs 56
/// local days through the production providers (engine, Toolkit, journal,
/// preferences) with a scripted user who answers according to what they
/// were actually offered. Assertions hold the behaviour; the traces are for
/// reading:
///
/// ```
/// flutter test test/features/toolkit/premium_simulation_test.dart \
///   --dart-define=TRACE=true
/// ```
///
/// writes every day's line to `build/premium_simulations/<sim>.txt`.

const _trace = bool.fromEnvironment('TRACE');

final _start = DateTime(2026, 9, 1, 9);

typedef Answer = CircleUsefulnessResponse?;
const _v = CircleUsefulnessResponse.veryUseful;
const _s = CircleUsefulnessResponse.somewhatUseful;
const _n = CircleUsefulnessResponse.notUseful;

const _energy = Intention.moreEnergy;
const _head = Intention.clearerHead;
const _gentle = Intention.gentlerPace;

/// What a day's Circle was, for the assertions.
class Day {
  Day(this.n, this.recommendation, this.answer);

  final int n;
  final Recommendation? recommendation;
  final Answer answer;

  bool get path => recommendation?.session?.isPath ?? false;
  bool get routine => recommendation?.session?.isRoutine ?? false;
}

/// One simulated user over eight weeks.
class Sim {
  Sim(this.name);

  final String name;
  late SharedPreferences prefs;
  bool entitled = false;
  final days = <Day>[];
  final lines = <String>[];
  final offersSeen = <OfferKind>[];

  Future<void> init() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  }

  ProviderContainer open(int n) {
    final morning = _start.add(Duration(days: n));
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(morning),
        eventClockProvider.overrideWithValue(() => morning),
        premiumEntitlementProvider.overrideWithValue(entitled),
        safetyPendingAllowedProvider.overrideWithValue(false),
      ],
    );
  }

  Future<void> _settle() async {
    for (var i = 0; i < 6; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// Runs day [n]: Toolkit actions ([before]), today's Circle for [need]
  /// (none if `null`), the user's [answer] to whatever was offered, an
  /// optional "Not this one today", keeping a finished Path when [keep].
  Future<Day> day(
    int n, {
    Intention? need,
    TimeWindow window = TimeWindow.about20,
    Answer Function(Recommendation)? answer,
    void Function(ProviderContainer)? before,
    ReplacementReason? replace,
    bool keep = true,
    String? keepName,
  }) async {
    final c = open(n);
    try {
      before?.call(c);
      await _settle();
      final offer = c.read(primaryOfferProvider);
      if (offer != null && !offersSeen.contains(offer.kind)) {
        offersSeen.add(offer.kind);
      }
      Recommendation? today;
      Answer given;
      if (need != null) {
        final circle = c.read(recommendationProvider.notifier);
        circle.chooseIntention(need, window: window);
        if (replace != null) circle.replaceToday(replace);
        today = c.read(recommendationProvider).recommendation;
        if (today != null) {
          circle.start();
          circle.close();
          given = answer?.call(today);
          if (given != null) {
            circle.reportAttempt(CircleAttemptResponse.yes);
            circle.reportUsefulness(given);
          }
        }
        await _settle();
      }
      final toolkit = c.read(toolkitProvider);
      if (keep && (toolkit.path?.finished ?? false)) {
        c.read(toolkitProvider.notifier).keepProposal(name: keepName);
        await _settle();
      }
      final record = Day(n, today, given);
      days.add(record);
      lines.add(_line(c, n, need, window, today, given, offer));
      return record;
    } finally {
      c.dispose();
    }
  }

  String _line(
    ProviderContainer c,
    int n,
    Intention? need,
    TimeWindow window,
    Recommendation? today,
    Answer given,
    MaintenanceOffer? offer,
  ) {
    final toolkit = c.read(toolkitProvider);
    final week = n ~/ 7 + 1;
    final what = today == null
        ? '—'
        : today.session?.isPath ?? false
        ? '[PATH ${today.session!.pathName} ${today.session!.pathCircle}/'
              '${today.session!.pathCircles}] ${today.activity} '
              '${today.offeredMinutes}m · ${today.session!.pathReason!.name}'
        : today.session?.isRoutine ?? false
        ? '[ROUTINE] ${today.activity} v${today.session!.routineVersionNumber} '
              '${today.offeredMinutes}m · ${today.reason.name}'
        : '${today.activity} ${today.offeredMinutes}m · ${today.reason.name}';
    final premium = entitled ? 'P' : 'F';
    final routines = [
      for (final r in toolkit.routines)
        '${r.name}(v${r.active.number}'
            '${r.shortVersion == null ? '' : '+short'}'
            '${r.enabled ? '' : ' off'})',
    ];
    return 'D${n.toString().padLeft(2)} W$week $premium '
        '${need?.name ?? '(no Circle)'} ${need == null ? '' : '≈${window.maxMinutes}'} '
        '→ $what · ${given?.name ?? 'no answer'}'
        '${offer == null ? '' : ' · OFFER ${offer.kind.name}'}'
        ' · toolkit $routines'
        '${toolkit.path == null ? '' : ' path ${toolkit.path!.kind.name} ${toolkit.path!.circles.length}/${toolkit.path!.length}'}';
  }

  void write() {
    if (!_trace) return;
    final dir = Directory('build/premium_simulations')
      ..createSync(recursive: true);
    File('${dir.path}/$name.txt').writeAsStringSync('${lines.join('\n')}\n');
  }

  ToolkitState toolkit([int n = 56]) {
    final c = open(n);
    try {
      return c.read(toolkitProvider);
    } finally {
      c.dispose();
    }
  }
}

/// A user who finds music and the stretch useful, everything else somewhat
/// — and doesn't always answer (every fifth day, no answer).
Answer _likesMovement(Recommendation r, int n) {
  if (n % 5 == 4) return null;
  final title = r.activity;
  if (title.contains('music') || title.contains('pick-me-up')) return _v;
  if (title.contains('stretch')) return _s;
  return _s;
}

/// Free weeks 1–2 for [needs] in turn: the engine's own picks.
Future<void> _freeWeeks(Sim sim, List<Intention> needs, {int days = 14}) async {
  for (var n = 0; n < days; n++) {
    if (n % 3 == 2) continue; // not every day
    await sim.day(
      n,
      need: needs[n % needs.length],
      answer: (r) => _likesMovement(r, n),
    );
  }
}

/// Runs [need] days from [from] until the Path under way is finished and
/// kept (at most [limit] days).
Future<int> _buildThrough(
  Sim sim,
  int from,
  Intention need, {
  TimeWindow window = TimeWindow.about20,
  Answer Function(Recommendation, int)? answer,
  int limit = 30,
  String? keepName,
}) async {
  var n = from;
  while (n < from + limit) {
    await sim.day(
      n,
      need: need,
      window: window,
      answer: (r) => (answer ?? _likesMovement)(r, n),
      keepName: keepName,
    );
    n += 2;
    if (sim.toolkit(n).path == null) break;
  }
  return n;
}

void main() {
  test('SIM 1 — first build: sparse but valid Free history, Premium starts, '
      'a seeded first Path, a review, the first routine', () async {
    final sim = Sim('sim01_first_build');
    await sim.init();
    addTearDown(sim.write);
    await _freeWeeks(sim, [_energy, _energy, _head]);
    sim.entitled = true;
    late PathTemplateId suggested;
    await sim.day(
      14,
      before: (c) {
        suggested = c.read(suggestedPathProvider).template;
        c.read(toolkitProvider.notifier).startBuild(suggested);
      },
    );
    expect(suggested, PathTemplateId.wakeUpIndoors);
    final run = sim.toolkit(14).path!;
    expect(run.seed, SeedReason.usefulModule);
    expect(run.pool.first, ModuleId.musicMove);

    final end = await _buildThrough(sim, 15, _energy);
    final routine = sim.toolkit(end).routines.single;
    expect(routine.need, _energy);
    expect(routine.active.composition.modules, contains(ModuleId.musicMove));
    // Then four ordinary weeks.
    for (var n = end; n < 56; n++) {
      if (n % 3 == 2) continue;
      await sim.day(
        n,
        need: n % 4 == 0 ? _head : _energy,
        answer: (r) => _likesMovement(r, n),
      );
    }
    final pathDays = sim.days.where((d) => d.path).length;
    expect(pathDays, 7);
    // Path Circles never claim anything the user didn't say.
    for (final d in sim.days.where((d) => d.path)) {
      expect(d.recommendation!.why, isNot(contains('works for you')));
    }
  });

  test('SIM 2 — two routines, both in ordinary daily picks, neither '
      'dominating; no Premium bias', () async {
    final sim = Sim('sim02_two_routines');
    await sim.init();
    addTearDown(sim.write);
    await _freeWeeks(sim, [_energy, _head]);
    sim.entitled = true;
    await sim.day(
      14,
      before: (c) => c
          .read(toolkitProvider.notifier)
          .startBuild(PathTemplateId.wakeUpIndoors),
    );
    var n = await _buildThrough(sim, 15, _energy);
    await sim.day(
      n,
      before: (c) => c
          .read(toolkitProvider.notifier)
          .startBuild(PathTemplateId.clearTheDecks),
    );
    n = await _buildThrough(
      sim,
      n + 1,
      _head,
      window: TimeWindow.upTo30,
      answer: (r, d) => d % 5 == 4 ? null : _v,
    );
    expect(sim.toolkit(n).routines, hasLength(2));
    final firstOrdinary = n;
    for (; n < 56; n++) {
      await sim.day(
        n,
        need: n.isEven ? _energy : _head,
        window: TimeWindow.upTo30,
        answer: (r) => _likesMovement(r, n),
      );
    }
    final ordinary = sim.days.where((d) => d.n >= firstOrdinary);
    final routineDays = ordinary.where((d) => d.routine).toList();
    final names = {for (final d in routineDays) d.recommendation!.activity};
    expect(names, containsAll(['My pick-me-up', 'My reset']));
    // Not every day: variety still applies.
    expect(routineDays.length, lessThan(ordinary.length * 0.6));
    // Never on consecutive days of the same need.
    for (var i = 1; i < routineDays.length; i++) {
      final a = routineDays[i - 1];
      final b = routineDays[i];
      if (b.n - a.n == 2 &&
          a.recommendation!.intention == b.recommendation!.intention) {
        expect(a.recommendation!.activity, isNot(b.recommendation!.activity));
      }
    }
  });

  test('SIM 3 — week 7: the time the user has changes; a shorter version is '
      'offered, built and then used — and it is still their routine: every '
      'piece, each in its authored short form', () async {
    final sim = Sim('sim03_week7_time_change');
    await sim.init();
    addTearDown(sim.write);
    await _freeWeeks(sim, [_head, _energy]);
    sim.entitled = true;
    await sim.day(
      14,
      before: (c) => c
          .read(toolkitProvider.notifier)
          .startBuild(PathTemplateId.clearTheDecks),
    );
    // Built on days with up to 30 minutes. Its shorter form (Circle 6) was
    // "Not useful" then — there was time enough — so it keeps none.
    var n = await _buildThrough(
      sim,
      15,
      _head,
      window: TimeWindow.upTo30,
      answer: (r, _) => r.session?.pathCircle == 6 ? _n : _v,
    );
    final routine = sim.toolkit(n).routines.single;
    expect(routine.active.composition.combined, isTrue);
    expect(routine.shortVersion, isNull);
    // Weeks 5–6: up to 30 minutes, the routine in use.
    for (; n < 38; n++) {
      if (n.isOdd) continue;
      await sim.day(
        n,
        need: _head,
        window: TimeWindow.upTo30,
        answer: (r) => _s,
      );
    }
    // Week 6 on: about 20 minutes most days.
    var offeredOn = -1;
    for (; n < 63; n++) {
      if (n.isOdd) continue;
      await sim.day(
        n,
        need: _head,
        window: TimeWindow.about20,
        answer: (r) => _s,
        before: (c) {
          final offer = c.read(primaryOfferProvider);
          if (offer?.kind == OfferKind.timeMisfit && offeredOn < 0) {
            offeredOn = n;
            c
                .read(toolkitProvider.notifier)
                .startShorter(offer!.routine!.id, offer.targetMinutes!);
          }
        },
      );
    }
    expect(offeredOn, inInclusiveRange(42, 49), reason: 'week 7');
    final after = sim.toolkit(63).routines.single;
    final short = after.shortVersion!;
    expect(short.minutes, lessThanOrEqualTo(20));
    // The same routine: every piece, in order, none dropped.
    expect(
      [for (final u in short.composition.uses) u.module],
      [for (final u in after.active.composition.uses) u.module],
    );
    // The shorter version then serves the shorter days.
    final lastShort = sim.days.where((d) => d.n > offeredOn + 6);
    expect(
      lastShort.any(
        (d) => d.routine && d.recommendation!.offeredMinutes == short.minutes,
      ),
      isTrue,
    );
  });

  test(
    'SIM 4 — fading: no claim too early; after enough lower answers a '
    'tune-up is offered, run in three Circles, and becomes version 2',
    () async {
      final sim = Sim('sim04_fading');
      await sim.init();
      addTearDown(sim.write);
      await _freeWeeks(sim, [_energy, _head]);
      sim.entitled = true;
      await sim.day(
        14,
        before: (c) => c
            .read(toolkitProvider.notifier)
            .startBuild(PathTemplateId.wakeUpIndoors),
      );
      var n = await _buildThrough(sim, 15, _energy);
      var lowAnswers = 0;
      var offeredOn = -1;
      // Ten weeks: a "Not useful" rests the routine for two weeks, so its
      // next answer takes that long to come.
      for (; n < 70; n++) {
        await sim.day(
          n,
          need: n.isEven ? _energy : _head,
          answer: (r) {
            if (!(r.session?.isRoutine ?? false)) return _s;
            lowAnswers++;
            return lowAnswers.isOdd ? _n : _s;
          },
          before: (c) {
            final offer = c.read(primaryOfferProvider);
            if (offer?.kind == OfferKind.fading && offeredOn < 0) {
              offeredOn = n;
              c.read(toolkitProvider.notifier).startTuneUp(offer!.routine!.id);
            }
          },
        );
      }
      expect(offeredOn, isNot(-1));
      // Not before two answers about the routine in use.
      expect(lowAnswers, greaterThanOrEqualTo(2));
      final routine = sim.toolkit(70).routines.single;
      expect(routine.versions.length, greaterThanOrEqualTo(2));
      expect(routine.active.origin, VersionOrigin.tuneUp);
      expect(routine.versions.first.origin, VersionOrigin.path);
    },
  );

  /// SIM 5's user: a pick-me-up built, then Clearer Head chosen most days
  /// with up to 30 minutes, Free's Clearer Head picks answered by
  /// [freeAnswer]. Returns the day the gap build was offered (or -1).
  Future<int> gapUser(Sim sim, Answer Function(int n) freeAnswer) async {
    await sim.init();
    await _freeWeeks(sim, [_energy]);
    sim.entitled = true;
    await sim.day(
      14,
      before: (c) => c
          .read(toolkitProvider.notifier)
          .startBuild(PathTemplateId.wakeUpIndoors),
    );
    var n = await _buildThrough(sim, 15, _energy);
    var gapOn = -1;
    for (; n < 56; n++) {
      await sim.day(
        n,
        need: n % 3 == 0 ? _energy : _head,
        window: TimeWindow.upTo30,
        answer: (r) => n % 5 == 4
            ? null
            : (r.session?.isPath ?? false) || (r.session?.isRoutine ?? false)
            ? _v
            : n % 3 == 0
            ? _s
            : freeAnswer(n),
        before: (c) {
          final offer = c.read(primaryOfferProvider);
          if (offer?.kind == OfferKind.gap && gapOn < 0) {
            gapOn = n;
            c.read(toolkitProvider.notifier).startBuild(offer!.template!);
          }
        },
      );
    }
    return gapOn;
  }

  test('SIM 5 — gap: a need chosen often, Free\'s picks for it genuinely '
      'weak, no routine for it: one bounded build offered; the missing '
      'routine built', () async {
    final sim = Sim('sim05_gap');
    addTearDown(sim.write);
    // Free's Clearer Head picks: "Not useful" more often than not.
    final gapOn = await gapUser(sim, (n) => n.isEven ? _n : _s);
    expect(gapOn, isNot(-1));
    final routines = sim.toolkit().routines;
    expect(routines.map((r) => r.need), containsAll([_energy, _head]));
    // Only one gap build: no duplicate routine for the same need.
    expect(routines.where((r) => r.need == _head), hasLength(1));
  });

  test('SIM 5b — served well: the same user, but Free\'s Clearer Head picks '
      'are "Somewhat useful" every time — Free serves the need, so no gap '
      'is offered in eight weeks', () async {
    final sim = Sim('sim05b_served_well');
    addTearDown(sim.write);
    final gapOn = await gapUser(sim, (n) => _s);
    expect(gapOn, -1);
    expect(sim.toolkit().routines.map((r) => r.need), [_energy]);
  });

  test('SIM 6 — stable user: the four-week check says nothing needs '
      'changing, and Premium invents no work', () async {
    final sim = Sim('sim06_stable');
    await sim.init();
    addTearDown(sim.write);
    await _freeWeeks(sim, [_energy]);
    sim.entitled = true;
    await sim.day(
      14,
      before: (c) => c
          .read(toolkitProvider.notifier)
          .startBuild(PathTemplateId.wakeUpIndoors),
    );
    var n = await _buildThrough(sim, 15, _energy);
    ToolkitCheck? check;
    for (; n < 56 + 14; n++) {
      await sim.day(
        n,
        need: n % 7 == 3 ? _head : _energy,
        answer: (r) => n % 4 == 0 ? _s : _v,
        before: (c) => check ??= c.read(toolkitCheckProvider),
      );
    }
    expect(sim.offersSeen, isEmpty);
    expect(check?.state, CheckState.stable);
  });

  test('SIM 7 — missed days: nothing happens to the Path; it resumes where '
      'it was', () async {
    final sim = Sim('sim07_missed_days');
    await sim.init();
    addTearDown(sim.write);
    sim.entitled = true;
    await sim.day(
      0,
      before: (c) => c
          .read(toolkitProvider.notifier)
          .startBuild(PathTemplateId.wakeUpIndoors),
    );
    await sim.day(1, need: _energy, answer: (r) => _v);
    await sim.day(2, need: _energy, answer: (r) => _s);
    final before = sim.toolkit(2).path!.circles.length;
    // Eleven days without opening THIRTY.
    final back = await sim.day(14, need: _energy, answer: (r) => _v);
    expect(before, 2);
    expect(back.recommendation!.session!.pathCircle, 3);
  });

  test('SIM 8 — another need: Free decides; the Path is untouched', () async {
    final sim = Sim('sim08_other_need');
    await sim.init();
    addTearDown(sim.write);
    sim.entitled = true;
    await sim.day(
      0,
      before: (c) => c
          .read(toolkitProvider.notifier)
          .startBuild(PathTemplateId.wakeUpIndoors),
    );
    await sim.day(1, need: _energy, answer: (r) => _v);
    for (var n = 2; n < 9; n++) {
      final d = await sim.day(n, need: _gentle, answer: (r) => _s);
      expect(d.path, isFalse);
    }
    expect(sim.toolkit(9).path!.circles, hasLength(1));
    final next = await sim.day(9, need: _energy, answer: (r) => _v);
    expect(next.recommendation!.session!.pathCircle, 2);
  });

  test('SIM 9 — "Not this one today" on a Path step: the engine replaces '
      'it; the Path waits and offers the same step next time', () async {
    final sim = Sim('sim09_path_replacement');
    await sim.init();
    addTearDown(sim.write);
    sim.entitled = true;
    await sim.day(
      0,
      before: (c) => c
          .read(toolkitProvider.notifier)
          .startBuild(PathTemplateId.wakeUpIndoors),
    );
    await sim.day(1, need: _energy, answer: (r) => _v);
    final replaced = await sim.day(
      2,
      need: _energy,
      replace: ReplacementReason.notFeeling,
      answer: (r) => _s,
    );
    expect(replaced.path, isFalse);
    expect(replaced.recommendation!.replacedFromTitle, isNotNull);
    expect(sim.toolkit(2).path!.circles, hasLength(1));
    final next = await sim.day(3, need: _energy, answer: (r) => _v);
    expect(next.recommendation!.session!.pathCircle, 2);
  });

  test('SIM 10 — "Don\'t suggest": Path, routine engine and maintenance all '
      'respect it; nothing overrides it', () async {
    final sim = Sim('sim10_dont_suggest');
    await sim.init();
    addTearDown(sim.write);
    await _freeWeeks(sim, [_energy]);
    sim.entitled = true;
    await sim.day(
      14,
      before: (c) => c
          .read(toolkitProvider.notifier)
          .startBuild(PathTemplateId.wakeUpIndoors),
    );
    var n = await _buildThrough(sim, 15, _energy);
    final routine = sim.toolkit(n).routines.single;
    expect(routine.active.composition.modules, contains(ModuleId.musicMove));
    // The user asks THIRTY not to suggest Move to music for More Energy.
    await sim.day(
      n,
      before: (c) => c
          .read(suggestionPreferencesProvider.notifier)
          .dontSuggest(ActivityId.moveToMusic, _energy),
    );
    for (n = n + 1; n < 56; n++) {
      final d = await sim.day(
        n,
        need: _energy,
        answer: (r) => n.isEven ? _n : _s,
        before: (c) {
          for (final offer in c.read(maintenanceOffersProvider)) {
            expect(offer.routine?.id, isNot(routine.id));
          }
          expect(
            c.read(toolkitProvider.notifier).startTuneUp(routine.id),
            anyOf(PathStart.nothingToBuild, PathStart.started),
          );
          c.read(toolkitProvider.notifier).leavePath();
        },
      );
      expect(d.routine, isFalse);
      expect(d.recommendation?.activityId, isNot(ActivityId.moveToMusic));
      expect(
        d.recommendation?.session?.composition.modules ?? const {},
        isNot(contains(ModuleId.musicMove)),
      );
    }
  });

  test('SIM 10b — an active rest: a piece found "Not useful" in Free is '
      'left out of a Path while it rests — never brought back in by the '
      'Path — and may come back once the rest is over', () async {
    final sim = Sim('sim10b_active_rest');
    await sim.init();
    addTearDown(sim.write);
    // Free weeks: Move to music is "Not useful" whenever Free picks it.
    for (var n = 0; n < 14; n++) {
      if (n % 3 == 2) continue;
      await sim.day(
        n,
        need: _energy,
        answer: (r) => r.activityId == ActivityId.moveToMusic ? _n : _s,
      );
    }
    final lastNotUseful = sim.days
        .where(
          (d) =>
              d.recommendation?.activityId == ActivityId.moveToMusic &&
              d.answer == _n,
        )
        .map((d) => d.n)
        .last;
    sim.entitled = true;
    List<ModuleId>? pool;
    await sim.day(
      14,
      before: (c) {
        c
            .read(toolkitProvider.notifier)
            .startBuild(PathTemplateId.wakeUpIndoors);
        pool = c.read(toolkitProvider).path?.pool;
      },
    );
    // Still resting (14 days): left out of the Path.
    expect(14 - lastNotUseful, lessThanOrEqualTo(14));
    expect(pool, isNot(contains(ModuleId.musicMove)));
    var n = await _buildThrough(sim, 15, _energy, answer: (r, _) => _s);
    for (final d in sim.days.where((d) => d.n >= 15)) {
      expect(
        d.recommendation?.session?.composition.modules ?? const {},
        isNot(contains(ModuleId.musicMove)),
        reason: 'D${d.n}',
      );
    }
    expect(
      sim.toolkit(n).routines.single.active.composition.modules,
      isNot(contains(ModuleId.musicMove)),
    );
    // The rest is long over: starting this Path again, Move to music may
    // be part of it — the rest was never a ban.
    List<ModuleId>? later;
    await sim.day(
      n + 10,
      before: (c) {
        c
            .read(toolkitProvider.notifier)
            .startBuild(PathTemplateId.wakeUpIndoors);
        later = c.read(toolkitProvider).path?.pool;
        c.read(toolkitProvider.notifier).leavePath();
      },
    );
    expect(later, contains(ModuleId.musicMove));
  });

  test('SIM 11 — lapse: routines stay usable in Free with their controls; '
      'the Path is saved and frozen; restored, it resumes exactly', () async {
    final sim = Sim('sim11_lapse');
    await sim.init();
    addTearDown(sim.write);
    await _freeWeeks(sim, [_energy, _head]);
    sim.entitled = true;
    await sim.day(
      14,
      before: (c) => c
          .read(toolkitProvider.notifier)
          .startBuild(PathTemplateId.wakeUpIndoors),
    );
    var n = await _buildThrough(sim, 15, _energy);
    await sim.day(
      n,
      before: (c) => c
          .read(toolkitProvider.notifier)
          .startBuild(PathTemplateId.clearTheDecks),
    );
    await sim.day(
      n + 1,
      need: _head,
      window: TimeWindow.upTo30,
      answer: (r) => _v,
    );
    await sim.day(
      n + 2,
      need: _head,
      window: TimeWindow.upTo30,
      answer: (r) => _s,
    );
    final frozen = sim.toolkit(n + 2).path!;
    expect(frozen.circles, hasLength(2));

    sim.entitled = false;
    var routineDays = 0;
    for (var d = n + 3; d < n + 17; d++) {
      final day = await sim.day(
        d,
        need: d.isEven ? _energy : _head,
        window: TimeWindow.upTo30,
        answer: (r) => _v,
        before: (c) {
          expect(
            c
                .read(toolkitProvider.notifier)
                .startTuneUp(c.read(toolkitProvider).routines.single.id),
            PathStart.notEntitled,
          );
        },
      );
      expect(day.path, isFalse);
      if (day.routine) routineDays++;
    }
    expect(routineDays, greaterThan(0), reason: 'routines stay in Free');
    expect(sim.toolkit(n + 17).path!.circles.length, 2);

    sim.entitled = true;
    final resumed = await sim.day(
      n + 17,
      need: _head,
      window: TimeWindow.upTo30,
      answer: (r) => _v,
    );
    expect(resumed.recommendation!.session!.pathCircle, 3);
    expect(resumed.recommendation!.session!.pathRunId, frozen.id);
  });

  test('SIM 12 — Delete Circle history: every derived claim goes; routines, '
      'the Path and explicit choices stay', () async {
    final sim = Sim('sim12_delete');
    await sim.init();
    addTearDown(sim.write);
    await _freeWeeks(sim, [_energy]);
    sim.entitled = true;
    await sim.day(
      14,
      before: (c) => c
          .read(toolkitProvider.notifier)
          .startBuild(PathTemplateId.wakeUpIndoors),
    );
    var n = await _buildThrough(sim, 15, _energy);
    // Clearer Head most days, Free's picks for it rated weak: by week 7
    // THIRTY has derived a gap from those answers.
    for (; n < 44; n++) {
      if (n.isOdd) continue;
      await sim.day(
        n,
        need: _head,
        window: TimeWindow.about20,
        answer: (r) => n % 4 == 0 ? _n : _s,
      );
    }
    var offersBefore = const <MaintenanceOffer>[];
    await sim.day(
      44,
      before: (c) {
        c
            .read(suggestionPreferencesProvider.notifier)
            .dontSuggest(ActivityId.activeHouseholdTask, _energy);
        offersBefore = c.read(maintenanceOffersProvider);
      },
    );
    expect(offersBefore.map((o) => o.kind), contains(OfferKind.gap));
    // Delete, as the confirmation does.
    final c = sim.open(45);
    await c.read(circleJournalRepositoryProvider).clearAll();
    await clearRecordedCircleState(sim.prefs);
    c.invalidate(circleJournalRepositoryProvider);
    expect(c.read(maintenanceOffersProvider), isEmpty);
    expect(c.read(toolkitHistoryProvider), isEmpty);
    expect(c.read(toolkitProvider).routines, hasLength(1));
    expect(
      c
          .read(suggestionPreferencesProvider)
          .isNotSuggested(ActivityId.activeHouseholdTask, _energy),
      isTrue,
    );
    final check = c.read(toolkitCheckProvider);
    expect(check?.state ?? CheckState.learning, isNot(CheckState.action));
    c.dispose();
    sim.lines.add(
      'D45 — Delete Circle history: offers none, routines kept, '
      "preferences kept, check ${check?.state.name ?? 'not due'}",
    );
  });
}
