import 'dart:convert';
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
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';

/// V2 Phase D2 (ADR-023 §12) — long-horizon INTERNAL simulations: day 1 to
/// month 12, through the production providers (composer, engine, journal,
/// preferences, kept Circles), for scripted users whose answers depend on what
/// they were actually offered.
///
/// **These are not user validation.** They catch architectural failure —
/// repetition, degeneration, evidence that doesn't move anything, leaks of
/// excluded content, broken lapse — before pre-release users see it. They
/// report behaviour only; no "value score" is derived.
///
/// ```
/// flutter test test/features/personal_circle/personal_circle_simulation_test.dart \
///   --dart-define=TRACE=true
/// ```
///
/// writes every day's line and each profile's checkpoint report to
/// `build/personal_circle_simulations/`. Tagged `long` (about 40 s a
/// profile): part of the full suite; `--exclude-tags long` skips them while
/// iterating.

const _trace = bool.fromEnvironment('TRACE');
const _days = int.fromEnvironment('SIM_DAYS', defaultValue: 365);

final _start = DateTime(2026, 1, 5, 9);

const _v = CircleUsefulnessResponse.veryUseful;
const _s = CircleUsefulnessResponse.somewhatUseful;
const _n = CircleUsefulnessResponse.notUseful;

const _energy = Intention.moreEnergy;
const _head = Intention.clearerHead;
const _gentle = Intention.gentlerPace;

/// The days a profile reports at.
const _checkpoints = {
  1: 'Day 1',
  7: 'Day 7',
  30: 'Day 30',
  90: 'Month 3',
  180: 'Month 6',
  365: 'Month 12',
};

/// A scripted user.
class Profile {
  const Profile({
    required this.name,
    required this.needOn,
    required this.windowOn,
    this.answerRate = 1,
    this.likes = const {},
    this.dislikes = const {},
    this.alwaysPositive = false,
    this.entitledOn,
    this.leavesOut = const {},
    this.dontSuggest = const {},
    this.skipsDisliked = false,
    this.restDays = const {},
    this.reportNeed,
  });

  final String name;
  final Intention Function(int day) needOn;
  final TimeWindow Function(int day) windowOn;

  /// One answer every [answerRate] days (1: every day).
  final int answerRate;

  /// Element kinds the user tends to find useful / not useful as a main
  /// piece. Anything else: "Somewhat useful".
  final Set<ElementKind> likes;
  final Set<ElementKind> dislikes;
  final bool alwaysPositive;

  /// Premium on a given day (default: always).
  final bool Function(int day)? entitledOn;

  /// Elements left out on their first appearance, and activities the user
  /// asks THIRTY not to suggest early on.
  final Set<ElementId> leavesOut;
  final Set<(ActivityId, Intention)> dontSuggest;

  /// Skips a disliked part when it isn't the main piece.
  final bool skipsDisliked;

  /// Days with no Circle at all.
  final Set<int> restDays;

  /// Reports only this need's days, when set.
  final Intention? reportNeed;

  bool entitled(int day) => entitledOn?.call(day) ?? true;
}

/// One simulated day.
class SimDay {
  SimDay(
    this.day,
    this.need,
    this.window,
    this.recommendation,
    this.answer,
    this.entitled,
  );

  final int day;
  final Intention need;
  final TimeWindow window;
  final Recommendation recommendation;
  final CircleUsefulnessResponse? answer;
  final bool entitled;

  CirclePlan? get plan => recommendation.composed?.plan;
  bool get composed =>
      plan != null && !(recommendation.composed?.isKept ?? false);
}

class Simulation {
  Simulation(this.profile);

  final Profile profile;
  late SharedPreferences prefs;
  final days = <SimDay>[];
  final lines = <String>[];

  Future<void> init() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> _settle() async {
    for (var i = 0; i < 6; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  CircleUsefulnessResponse? _answer(int day, Recommendation r) {
    if (day % profile.answerRate != 0) return null;
    if (profile.alwaysPositive) return day.isEven ? _v : _s;
    final plan = r.composed?.plan;
    final ElementKind? kind = plan?.main.definition.kind;
    if (kind != null) {
      if (profile.likes.contains(kind)) return _v;
      if (profile.dislikes.contains(kind)) return _n;
      return _s;
    }
    // A Free activity or routine: by its family's closest kind.
    final title = r.activity.toLowerCase();
    if (profile.likes.contains(ElementKind.walking) && title.contains('walk')) {
      return _v;
    }
    if (profile.likes.contains(ElementKind.writing) &&
        title.contains('write')) {
      return _v;
    }
    return _s;
  }

  Future<void> run() async {
    await init();
    for (var day = 1; day <= _days; day++) {
      if (profile.restDays.contains(day)) continue;
      final morning = _start.add(Duration(days: day - 1));
      var clock = morning;
      final entitled = profile.entitled(day);
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          nowProvider.overrideWithValue(morning),
          eventClockProvider.overrideWithValue(() => clock),
          premiumEntitlementProvider.overrideWithValue(entitled),
          safetyPendingAllowedProvider.overrideWithValue(false),
        ],
      );
      try {
        if (day == 2) {
          for (final (activity, need) in profile.dontSuggest) {
            await c
                .read(suggestionPreferencesProvider.notifier)
                .dontSuggest(activity, need);
          }
        }
        await _settle();
        final need = profile.needOn(day);
        final window = profile.windowOn(day);
        final notifier = c.read(recommendationProvider.notifier);
        notifier.chooseIntention(need, window: window);
        final r = c.read(recommendationProvider).recommendation;
        if (r == null) {
          lines.add(
            'D$day ${need.name} ≈${window.maxMinutes} → nothing to offer',
          );
          continue;
        }
        notifier.start();
        // Skips and leave-outs, as this user would.
        final plan = r.composed?.plan;
        if (plan != null) {
          final first = plan.parts.first;
          final leave =
              profile.leavesOut.contains(first.element) &&
              !c.read(suggestionPreferencesProvider).isLeftOut(first.element);
          final skip =
              profile.skipsDisliked &&
              first != plan.main &&
              profile.dislikes.contains(first.definition.kind);
          if (leave || skip) {
            clock = morning.add(const Duration(seconds: 30));
            notifier.skipPart(leaveOut: leave);
            await _settle();
          }
        }
        clock = morning.add(Duration(minutes: r.offeredMinutes));
        notifier.close();
        final answer = _answer(day, r);
        if (answer != null) {
          notifier.reportAttempt(CircleAttemptResponse.yes);
          notifier.reportUsefulness(answer);
        }
        await _settle();
        days.add(SimDay(day, need, window, r, answer, entitled));
        lines.add(_line(day, need, window, r, answer, entitled));
      } finally {
        c.dispose();
      }
    }
  }

  String _line(
    int day,
    Intention need,
    TimeWindow window,
    Recommendation r,
    CircleUsefulnessResponse? answer,
    bool entitled,
  ) {
    final what = r.composed != null
        ? '[CIRCLE ${r.composed!.basis?.name ?? 'kept'}] ${r.composed!.plan}'
        : '[${r.composerFellBack ? 'FALLBACK' : 'FREE'}] ${r.activity}';
    return 'D${day.toString().padLeft(3)} ${entitled ? 'P' : 'F'} ${need.name} ≈${window.maxMinutes} '
        '→ $what ${r.offeredMinutes}m · ${answer?.name ?? 'no answer'}';
  }

  /// The behaviour report at [upTo] — counts and intervals, never a score.
  Map<String, Object?> report(int upTo) {
    final need = profile.reportNeed;
    final within = days
        .where((d) => d.day <= upTo && (need == null || d.need == need))
        .toList();
    final premiumDays = within.where((d) => d.entitled).toList();
    final composed = within.where((d) => d.composed).toList();
    final fallback = premiumDays
        .where((d) => d.recommendation.composerFellBack)
        .length;
    final sets = <String, List<int>>{};
    final material = <String>{};
    final partCounts = <ElementId, int>{};
    final mainCounts = <ElementId, int>{};
    var partTotal = 0;
    final uses = <double>[];
    for (final d in composed) {
      final plan = d.plan!;
      final key = ([for (final e in plan.elements) e.name]..sort()).join('+');
      (sets[key] ??= []).add(d.day);
      final core = plan.parts.where(
        (p) =>
            p.definition.roles.contains(ElementRole.main) ||
            p.definition.roles.contains(ElementRole.second),
      );
      material.add(([for (final p in core) p.element.name]..sort()).join('+'));
      for (final p in plan.parts) {
        partCounts[p.element] = (partCounts[p.element] ?? 0) + 1;
        partTotal++;
      }
      mainCounts[plan.main.element] = (mainCounts[plan.main.element] ?? 0) + 1;
      uses.add(plan.minutes / d.window.maxMinutes);
    }
    final intervals = <int>[];
    for (final daysSeen in sets.values) {
      for (var i = 1; i < daysSeen.length; i++) {
        intervals.add(daysSeen[i] - daysSeen[i - 1]);
      }
    }
    intervals.sort();
    uses.sort();
    final topParts = partCounts.values.toList()..sort((a, b) => b - a);
    final topMains = mainCounts.values.toList()..sort((a, b) => b - a);
    var sameFirst = 0;
    var sameLast = 0;
    for (var i = 1; i < composed.length; i++) {
      final plan = composed[i].plan!;
      final previous = composed[i - 1].plan!;
      if (plan.parts.first.element == previous.parts.first.element) {
        sameFirst++;
      }
      if (plan.parts.last.element == previous.parts.last.element) sameLast++;
    }
    final foundUseful = composed
        .where(
          (d) =>
              d.recommendation.composed!.basis == CompositionBasis.foundUseful,
        )
        .length;
    // Evidence-driven adaptation: how the main pieces of the kinds this
    // user answers "Very useful" / "Not useful" about move over time.
    String? share(Iterable<SimDay> span, Set<ElementKind> kinds) {
      final list = span.toList();
      if (kinds.isEmpty || list.isEmpty) return null;
      final hits = list
          .where((d) => kinds.contains(d.plan!.main.definition.kind))
          .length;
      return '$hits/${list.length}';
    }

    final early = composed.where((d) => d.day <= 30);
    final late = composed.where((d) => d.day > 60);
    return {
      if (need != null) 'reported need': need.name,
      'days with a Circle': within.length,
      'Premium days': premiumDays.length,
      'Personal Guided Circles': composed.length,
      'fell back to Free': fallback,
      'unique compositions (element sets)': sets.length,
      'materially distinct (main + second)': material.length,
      'distinct main pieces': mainCounts.length,
      'median repeat interval (days)': intervals.isEmpty
          ? null
          : intervals[intervals.length ~/ 2],
      'shortest repeat interval (days)': intervals.isEmpty
          ? null
          : intervals.first,
      'top-3 parts share': partTotal == 0
          ? null
          : (topParts.take(3).fold(0, (a, b) => a + b) / partTotal)
                .toStringAsFixed(2),
      'top main share': composed.isEmpty
          ? null
          : (topMains.first / composed.length).toStringAsFixed(2),
      'same first part as previous Circle': sameFirst,
      'same last part as previous Circle': sameLast,
      '"found useful" basis': foundUseful,
      'median time use': uses.isEmpty
          ? null
          : uses[uses.length ~/ 2].toStringAsFixed(2),
      'lowest time use': uses.isEmpty ? null : uses.first.toStringAsFixed(2),
      'liked-kind mains, days 1–30': share(early, profile.likes),
      'liked-kind mains, after day 60': share(late, profile.likes),
      'disliked-kind mains, days 1–30': share(early, profile.dislikes),
      'disliked-kind mains, after day 60': share(late, profile.dislikes),
    };
  }

  void write() {
    if (!_trace) return;
    final dir = Directory('build/personal_circle_simulations')
      ..createSync(recursive: true);
    File(
      '${dir.path}/${profile.name}.txt',
    ).writeAsStringSync('${lines.join('\n')}\n');
    final reports = {
      for (final MapEntry(:key, :value) in _checkpoints.entries)
        if (key <= _days) value: report(key),
    };
    File(
      '${dir.path}/${profile.name}.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(reports));
  }
}

Intention _rotate(int day) => const [_head, _energy, _gentle][day % 3];
TimeWindow _mixedTime(int day) => const [
  TimeWindow.about20,
  TimeWindow.about10,
  TimeWindow.upTo30,
  TimeWindow.about20,
][(day ~/ 3) % 4];

/// The profiles, as named in the brief.
final profiles = <Profile>[
  Profile(
    name: 'p01_sparse_feedback',
    needOn: _rotate,
    windowOn: _mixedTime,
    answerRate: 5,
  ),
  Profile(
    name: 'p02_frequent_feedback',
    needOn: _rotate,
    windowOn: _mixedTime,
    likes: const {
      ElementKind.writing,
      ElementKind.walking,
      ElementKind.tending,
    },
    dislikes: const {ElementKind.music},
  ),
  Profile(
    name: 'p03_stable_positive',
    needOn: _rotate,
    windowOn: _mixedTime,
    alwaysPositive: true,
  ),
  Profile(
    name: 'p04_mixed',
    needOn: _rotate,
    windowOn: _mixedTime,
    likes: const {ElementKind.reading, ElementKind.listening},
    dislikes: const {ElementKind.tidying, ElementKind.walking},
    skipsDisliked: true,
  ),
  Profile(
    name: 'p05_one_need_dominant',
    needOn: (d) => d % 5 == 0 ? _gentle : _head,
    windowOn: _mixedTime,
    likes: const {ElementKind.writing, ElementKind.focus},
  ),
  Profile(
    name: 'p06_all_three_needs',
    needOn: _rotate,
    windowOn: (d) => TimeWindow.about20,
    likes: const {ElementKind.movement},
  ),
  Profile(
    name: 'p07_mostly_10_minutes',
    needOn: _rotate,
    windowOn: (d) => d % 6 == 0 ? TimeWindow.about20 : TimeWindow.about10,
    likes: const {ElementKind.movement, ElementKind.writing},
  ),
  Profile(
    name: 'p08_mostly_20_minutes',
    needOn: _rotate,
    windowOn: (d) => d % 6 == 0 ? TimeWindow.upTo30 : TimeWindow.about20,
    likes: const {ElementKind.tidying},
  ),
  Profile(
    name: 'p09_mostly_30_minutes',
    needOn: _rotate,
    windowOn: (d) => d % 6 == 0 ? TimeWindow.about10 : TimeWindow.upTo30,
    likes: const {ElementKind.walking},
  ),
  Profile(
    name: 'p10_lapse_and_resubscribe',
    needOn: _rotate,
    windowOn: _mixedTime,
    likes: const {ElementKind.writing},
    // Premium for three months, a month on Free, then back.
    entitledOn: (d) => d <= 90 || d > 120,
  ),
  Profile(
    name: 'p11_many_exclusions',
    needOn: _rotate,
    windowOn: _mixedTime,
    leavesOut: const {
      ElementId.sitAMinute,
      ElementId.neckAndShoulders,
      ElementId.openWindow,
      ElementId.phoneFaceDown,
      ElementId.lookAround,
      ElementId.standAndReach,
    },
    dontSuggest: const {
      (ActivityId.moveToMusic, _energy),
      (ActivityId.writeItDown, _head),
    },
  ),
  Profile(
    name: 'p13_no_routine',
    needOn: _rotate,
    windowOn: (d) => TimeWindow.upTo30,
    likes: const {ElementKind.writing, ElementKind.tidying},
  ),
  // Correction pass (2026-10-11): the thinnest need, on most days, under
  // real answers — liking music and movement, finding tidying not useful.
  Profile(
    name: 'p14_more_energy_dominant',
    needOn: (d) => d % 7 == 0
        ? _head
        : d % 11 == 0
        ? _gentle
        : _energy,
    windowOn: (d) => const [
      TimeWindow.about10,
      TimeWindow.about20,
      TimeWindow.upTo30,
      TimeWindow.about20,
      TimeWindow.about10,
    ][(d * 3) % 5],
    likes: const {ElementKind.music, ElementKind.movement},
    dislikes: const {ElementKind.tidying},
    reportNeed: _energy,
  ),
];

void main() {
  for (final profile in profiles) {
    test(
      '${profile.name} — $_days days, structurally sound',
      () async {
        final sim = Simulation(profile);
        addTearDown(sim.write);
        await sim.run();
        final preferences = SuggestionPreferences.fromRaw(
          prefs(sim).getString(suggestionPreferencesKey),
        );

        for (final d in sim.days) {
          final r = d.recommendation;
          // One Circle a day, never over the chosen time when THIRTY chose it.
          if (r.reason != RecommendationReason.ownChoice) {
            expect(
              r.offeredMinutes,
              lessThanOrEqualTo(d.window.maxMinutes),
              reason: 'D${d.day}',
            );
          }
          // No composition without Premium; never a gated or retired part.
          if (d.composed) {
            expect(d.entitled, isTrue, reason: 'D${d.day}');
            for (final part in d.plan!.parts) {
              expect(isElementOfferable(part.definition), isTrue);
              expect(part.definition.fits(d.need), isTrue);
              final from = part.definition.from;
              // From the day the user asked (day 2) — never after.
              if (from != null && d.day >= 2) {
                expect(
                  profile.dontSuggest.contains((from, d.need)),
                  isFalse,
                  reason: 'D${d.day} $from',
                );
              }
            }
          }
        }
        // A part left out never comes back.
        for (final left in preferences.elementsLeftOut) {
          final after = sim.days.where(
            (d) => d.composed && d.day > _dayOf(left.since),
          );
          for (final d in after) {
            expect(
              d.plan!.elements,
              isNot(contains(left.element)),
              reason: 'D${d.day}',
            );
          }
        }
        final report = sim.report(_days);
        // Premium does work every Premium day, honestly.
        final premiumDays = report['Premium days']! as int;
        final composed = report['Personal Guided Circles']! as int;
        final fallback = report['fell back to Free']! as int;
        expect(
          fallback,
          lessThanOrEqualTo(premiumDays ~/ 10),
          reason: 'falls back rarely',
        );
        if (premiumDays > 60) {
          expect(composed, greaterThan(premiumDays * 0.7));
        }
        // Not a loop: many distinct sessions, no exact repeat within a week.
        if (composed >= 60) {
          expect(
            report['unique compositions (element sets)']! as int,
            greaterThanOrEqualTo(composed ~/ 4),
          );
          expect(
            report['shortest repeat interval (days)'] as int? ?? 99,
            greaterThanOrEqualTo(7),
          );
          expect(
            double.parse(report['top main share']! as String),
            lessThan(0.35),
          );
        }
        // Lapse: Free while lapsed, composition again after.
        if (profile.entitledOn != null) {
          final lapsed = sim.days.where((d) => !d.entitled);
          expect(lapsed, isNotEmpty);
          expect(lapsed.every((d) => !d.composed), isTrue);
          expect(sim.days.where((d) => d.day > 120 && d.composed), isNotEmpty);
        }
        // The thinnest need, under real answers, still moves with them: the
        // kinds found useful lead more Circles later than early on, and the
        // kind found not useful fewer.
        if (profile.reportNeed != null) {
          double share(String key) {
            final [hits, of] = (report[key]! as String).split('/');
            return int.parse(hits) / int.parse(of);
          }

          final early = sim.report(30);
          double earlyShare(String key) {
            final [hits, of] = (early[key]! as String).split('/');
            return int.parse(hits) / int.parse(of);
          }

          expect(
            share('liked-kind mains, after day 60'),
            greaterThan(earlyShare('liked-kind mains, days 1–30')),
          );
          expect(
            share('disliked-kind mains, after day 60'),
            lessThan(earlyShare('disliked-kind mains, days 1–30')),
          );
        }
        // Sparse evidence stays neutral at first.
        expect(
          sim.days.first.recommendation.composed?.basis,
          isNot(CompositionBasis.foundUseful),
        );
      },
      timeout: const Timeout(Duration(minutes: 10)),
      tags: 'long',
    );
  }
}

SharedPreferences prefs(Simulation sim) => sim.prefs;

int _dayOf(DateTime moment) => moment.difference(_start).inDays + 1;
