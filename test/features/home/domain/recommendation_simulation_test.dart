// Recommendation Engine V2 — deterministic 40-local-day simulations
// (PRODUCT_V2_CONTRACT / tracker Phase B acceptance). Each simulation plays
// a scripted user through the pure engine, day by day, feeding its own
// answers back as history. Run with `--dart-define=TRACE=true` to print
// every day's decision for human review.
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';

const _trace = bool.fromEnvironment('TRACE');

const _e = Intention.moreEnergy;
const _c = Intention.clearerHead;
const _g = Intention.gentlerPace;
const _t10 = TimeWindow.about10;
const _t20 = TimeWindow.about20;
const _t30 = TimeWindow.upTo30;

/// One simulated day.
class SimDay {
  SimDay({
    required this.day,
    required this.date,
    required this.need,
    required this.window,
    required this.first,
    this.replacement,
    this.replacementReason,
    this.answer,
  });

  final int day;
  final DateTime date;
  final Intention need;
  final TimeWindow window;
  final RecommendationDecision first;
  final RecommendationDecision? replacement;
  final ReplacementReason? replacementReason;
  final PastUsefulness? answer;

  RecommendationDecision get offered => replacement ?? first;

  @override
  String toString() {
    final o = offered;
    final swap = replacement == null
        ? ''
        : '  [${replacementReason!.name}: was ${first.activityId.name}]';
    return 'd${day.toString().padLeft(2)} ${need.name.padRight(11)} '
        '${window.name.padRight(7)} ${o.activityId.name.padRight(22)} '
        '${o.offeredMinutes.toString().padLeft(2)}m '
        '${o.reason.name.padRight(16)} ${(answer?.name ?? '-').padRight(14)}'
        '$swap';
  }
}

typedef DayScript = ({
  Intention need,
  TimeWindow window,
  ReplacementReason? Function(RecommendationDecision offer)? replace,
  PastUsefulness? Function(ActivityId activity, Intention need)? answer,
});

final _start = DateTime(2026, 11, 2);

/// Plays [days] days of [script] through the engine, starting from
/// [history]. [clearAfterDay], if set, deletes the whole history after that
/// day (Delete Circle history).
List<SimDay> simulate(
  DayScript Function(int day) script, {
  int days = 40,
  List<PastCircle> history = const [],
  int? clearAfterDay,
  String? label,
}) {
  final past = [...history];
  final out = <SimDay>[];
  for (var day = 1; day <= days; day++) {
    final date = _start.add(Duration(days: day - 1));
    final s = script(day);
    final first = recommend(
      RecommendationContext(
        date: date,
        need: s.need,
        window: s.window,
        allowSafetyPending: false,
      ),
      past,
    )!;
    final reason = s.replace?.call(first);
    final replacement = reason == null
        ? null
        : recommend(
            RecommendationContext(
              date: date,
              need: s.need,
              window: s.window,
              allowSafetyPending: false,
              replacement: ReplacementRequest(
                reason: reason,
                replacing: first.activityId,
                replacingMinutes: first.offeredMinutes,
              ),
            ),
            past,
          );
    final offered = replacement ?? first;
    final answer = s.answer?.call(offered.activityId, s.need);
    final simDay = SimDay(
      day: day,
      date: date,
      need: s.need,
      window: s.window,
      first: first,
      replacement: replacement,
      replacementReason: replacement == null ? null : reason,
      answer: answer,
    );
    out.add(simDay);
    past.add(
      PastCircle(
        date: date,
        need: s.need,
        activityId: offered.activityId,
        catalogVersion: catalogVersion,
        usefulness: answer,
        replacedFrom: replacement == null ? null : first.activityId,
      ),
    );
    if (clearAfterDay == day) past.clear();
  }
  if (_trace) {
    print('\n=== ${label ?? 'simulation'} ===');
    out.forEach(print);
  }
  return out;
}

/// The invariants every simulation must hold.
void expectInvariants(List<SimDay> days, {Set<int> forgetsBefore = const {}}) {
  for (final d in days) {
    for (final decision in [d.first, ?d.replacement]) {
      final a = activityDefinition(decision.activityId);
      expect(
        a.status,
        ActivityStatus.live,
        reason: '$d — gated or retired content',
      );
      expect(a.fitFor(d.need), isNot(NeedFit.none), reason: '$d — fit NONE');
      expect(
        decision.offeredMinutes,
        lessThanOrEqualTo(d.window.maxMinutes),
        reason: '$d — longer than the window',
      );
      expect(
        decision.offeredMinutes,
        inInclusiveRange(a.minMinutes, a.typicalMinutes),
        reason: '$d — not a real length of this activity',
      );
      if (a.mode != CircleMode.open) {
        expect(decision.offeredMinutes, a.typicalMinutes, reason: '$d');
      }
    }
    if (d.first.reason == RecommendationReason.tryingNew) {
      expect(d.window, isNot(TimeWindow.about10), reason: '$d — explored');
    }
    if (d.replacement case final r?) {
      final a = activityDefinition(r.activityId);
      expect(r.activityId, isNot(d.first.activityId), reason: '$d');
      switch (d.replacementReason!) {
        case ReplacementReason.cantGoOutside:
          expect(a.setting, isNot(ActivitySetting.outdoor), reason: '$d');
        case ReplacementReason.tooMuch:
          expect(a.effort, ActivityEffort.low, reason: '$d');
          if (r.reason == RecommendationReason.replacedLighter) {
            expect(r.offeredMinutes, lessThan(d.first.offeredMinutes));
          }
        case ReplacementReason.notFeeling:
          break;
      }
    }
  }
  // Exploration happens, but never dominates.
  expect(
    days
        .where((d) => d.offered.reason == RecommendationReason.tryingNew)
        .length,
    lessThanOrEqualTo(days.length ~/ 5),
  );
  // Never the same activity on consecutive days, unless the engine had to
  // fall back and says so.
  for (var i = 1; i < days.length; i++) {
    if (days[i].offered.reason == RecommendationReason.fallback) continue;
    // After Delete there is no yesterday to avoid.
    if (forgetsBefore.contains(days[i].day)) continue;
    expect(
      days[i].offered.activityId,
      isNot(days[i - 1].offered.activityId),
      reason: 'consecutive repeat on ${days[i]}',
    );
  }
}

/// The days on which the offered activity was still resting after a "Not
/// useful" for that need, within the rest period.
List<SimDay> restingOffers(List<SimDay> days, {int restDays = 14}) => [
  for (var i = 0; i < days.length; i++)
    if (days
        .take(i)
        .any(
          (e) =>
              e.offered.activityId == days[i].offered.activityId &&
              e.need == days[i].need &&
              e.answer == PastUsefulness.notUseful &&
              days[i].day - e.day <= restDays,
        ))
      days[i],
];

/// Normal behaviour, positive evidence included: consecutive repetition is
/// a fallback only, so a user with ordinary answers never meets one.
void expectNoFallbackRepeats(List<SimDay> days) {
  for (var i = 0; i < days.length; i++) {
    expect(
      days[i].offered.reason,
      isNot(RecommendationReason.fallback),
      reason: '${days[i]}',
    );
    if (i > 0) {
      expect(
        days[i].offered.activityId,
        isNot(days[i - 1].offered.activityId),
        reason: 'repeat on ${days[i]}',
      );
    }
  }
}

/// Offers of [activity] in [days].
int countOf(List<SimDay> days, ActivityId activity) =>
    days.where((d) => d.offered.activityId == activity).length;

/// The most offers of any one activity in any 7-day span.
int maxWeekly(List<SimDay> days, ActivityId activity) {
  var best = 0;
  for (var i = 0; i < days.length; i++) {
    final n = days
        .skip(i)
        .take(7)
        .where((d) => d.offered.activityId == activity)
        .length;
    if (n > best) best = n;
  }
  return best;
}

void main() {
  // Mixed windows, mostly ≈20, sometimes short or long.
  TimeWindow mixedWindow(int day) => switch (day % 5) {
    0 => _t10,
    3 => _t30,
    _ => _t20,
  };

  group('40-day simulations', () {
    test('1 · sparse: one need most days, mixed time, no answers', () {
      final days = simulate(
        (day) => (
          need: day % 6 == 0 ? _c : (day % 7 == 0 ? _g : _e),
          window: mixedWindow(day),
          replace: null,
          answer: null,
        ),
        label: 'SIM 1 sparse',
      );
      expectInvariants(days);
      expectNoFallbackRepeats(days);
      // Day 1 is the curated start, with nothing personal to say.
      expect(days.first.offered.activityId, ActivityId.thirtyMinuteWalk);
      expect(days.first.offered.reason, RecommendationReason.starter);
      // No evidence-based reason is ever shown without evidence.
      for (final d in days) {
        expect(d.offered.reason.visibleCopy, isNull, reason: '$d');
      }
      // Variety: every live Energy primary appears; nothing dominates.
      final energy = days.where((d) => d.need == _e).toList();
      for (final id in [
        ActivityId.thirtyMinuteWalk,
        ActivityId.moveToMusic,
        ActivityId.energisingStretchFlow,
        ActivityId.activeHouseholdTask,
      ]) {
        expect(countOf(energy, id), greaterThan(2), reason: id.name);
        expect(maxWeekly(days, id), lessThanOrEqualTo(2), reason: id.name);
      }
    });

    test('2 · positive: the user keeps finding walks very useful', () {
      final days = simulate(
        (day) => (
          need: day % 4 == 0 ? _g : _e,
          window: day % 9 == 0 ? _t10 : _t20,
          replace: null,
          answer: (activity, need) =>
              activityFamily(activity) == ActivitySemanticFamily.walking
              ? PastUsefulness.veryUseful
              : (day % 3 == 0 ? PastUsefulness.somewhatUseful : null),
        ),
        label: 'SIM 2 positive',
      );
      expectInvariants(days);
      expectNoFallbackRepeats(days);
      final walk = ActivityId.thirtyMinuteWalk;
      // Positive evidence matters: the walks come back, with their reason,
      // for both needs they were found useful for…
      expect(countOf(days, walk), greaterThanOrEqualTo(5));
      final gentle = days.where((d) => d.need == _g).toList();
      expect(
        gentle.where(
          (d) =>
              d.offered.activityId == ActivityId.easyWalk &&
              d.offered.reason == RecommendationReason.usefulHere,
        ),
        isNotEmpty,
      );
      expect(
        days.where(
          (d) =>
              d.offered.activityId == walk &&
              d.offered.reason == RecommendationReason.usefulHere,
        ),
        isNotEmpty,
      );
      // …but never as a favourite loop.
      expect(maxWeekly(days, walk), lessThanOrEqualTo(2));
    });

    test('3 · negative: one "Not useful" rests that activity, then it '
        'returns', () {
      final days = simulate(
        (day) => (
          need: _e,
          window: _t20,
          replace: null,
          answer: (activity, need) => activity == ActivityId.moveToMusic
              ? (day < 20 ? PastUsefulness.notUseful : null)
              : PastUsefulness.somewhatUseful,
        ),
        label: 'SIM 3 negative',
      );
      expectInvariants(days);
      expectNoFallbackRepeats(days);
      final music = days
          .where((d) => d.offered.activityId == ActivityId.moveToMusic)
          .map((d) => d.day)
          .toList();
      expect(music, isNotEmpty);
      final firstNotUseful = music.first;
      // Rested for at least the rest period after the answer…
      expect(
        music.where((d) => d > firstNotUseful && d <= firstNotUseful + 14),
        isEmpty,
      );
      // …but no permanent ban.
      expect(music.where((d) => d > firstNotUseful + 14), isNotEmpty);
      // The rest of its need is unharmed: other primaries keep coming.
      for (final id in [
        ActivityId.thirtyMinuteWalk,
        ActivityId.energisingStretchFlow,
        ActivityId.activeHouseholdTask,
      ]) {
        expect(countOf(days, id), greaterThan(4), reason: id.name);
      }
    });

    test('4 · mixed and realistic: three needs, changing time, '
        'replacements, mixed answers', () {
      final days = simulate(
        (day) => (
          need: [_e, _c, _g, _e, _c][day % 5],
          window: [_t20, _t10, _t30, _t20, _t20, _t10, _t20][day % 7],
          replace: (offer) {
            final a = activityDefinition(offer.activityId);
            if (day % 6 == 1 && a.setting == ActivitySetting.outdoor) {
              return ReplacementReason.cantGoOutside;
            }
            if (day % 11 == 4) return ReplacementReason.tooMuch;
            if (day % 13 == 7) return ReplacementReason.notFeeling;
            return null;
          },
          answer: (activity, need) {
            if (day % 4 == 0) return null;
            if (activity == ActivityId.quietReading) {
              return PastUsefulness.notUseful;
            }
            if (activity == ActivityId.writeItDown ||
                activity == ActivityId.easyWalk) {
              return PastUsefulness.veryUseful;
            }
            return PastUsefulness.somewhatUseful;
          },
        ),
        label: 'SIM 4 mixed',
      );
      expectInvariants(days);
      expectNoFallbackRepeats(days);
      expect(days.where((d) => d.replacement != null), isNotEmpty);
    });

    test('5 · migration: only compatible V1 answers count', () {
      final v1 = [
        for (var i = 0; i < 3; i++) ...[
          PastCircle(
            date: _start.subtract(Duration(days: 30 - i * 6)),
            need: _e,
            activityId: ActivityId.thirtyMinuteWalk,
            catalogVersion: v1CatalogVersion,
            usefulness: PastUsefulness.veryUseful,
          ),
          PastCircle(
            date: _start.subtract(Duration(days: 27 - i * 6)),
            need: _c,
            activityId: ActivityId.writeItDown,
            catalogVersion: v1CatalogVersion,
            usefulness: PastUsefulness.veryUseful,
          ),
        ],
      ];
      final days = simulate(
        (day) => (
          need: day.isOdd ? _e : _c,
          window: _t20,
          replace: null,
          answer: null,
        ),
        history: v1,
        label: 'SIM 5 migration',
      );
      expectInvariants(days);
      expectNoFallbackRepeats(days);
      // A brisk walk is LEARNING_RESET: its V1 answers never surface.
      expect(
        days.where(
          (d) =>
              d.offered.activityId == ActivityId.thirtyMinuteWalk &&
              d.offered.reason == RecommendationReason.usefulHere,
        ),
        isEmpty,
      );
      // Write it down is compatible: its V1 answers do.
      expect(
        days.where(
          (d) =>
              d.offered.activityId == ActivityId.writeItDown &&
              d.offered.reason == RecommendationReason.usefulHere,
        ),
        isNotEmpty,
      );
    });

    test('6 · delete: learn for 20 days, delete, and start honestly '
        'again', () {
      final days = simulate(
        (day) => (
          need: _e,
          window: _t20,
          replace: null,
          answer: (activity, need) => day <= 20
              ? (activity == ActivityId.energisingStretchFlow
                    ? PastUsefulness.veryUseful
                    : PastUsefulness.notUseful)
              : null,
        ),
        clearAfterDay: 20,
        label: 'SIM 6 delete',
      );
      expectInvariants(days, forgetsBefore: {21});
      // Learned before: the stretch the user found useful is offered far
      // more than anything they rejected.
      final before = days.take(20).toList();
      final stretch = ActivityId.energisingStretchFlow;
      expect(countOf(before, stretch), greaterThanOrEqualTo(6));
      for (final id in ActivityId.values.where((id) => id != stretch)) {
        expect(countOf(before, id), lessThan(countOf(before, stretch)));
      }
      // After Delete: the curated start again, nothing personal.
      final after = days.skip(20).toList();
      expect(after.first.offered.activityId, ActivityId.thirtyMinuteWalk);
      expect(after.first.offered.reason, RecommendationReason.starter);
      for (final d in after) {
        expect(d.offered.reason.visibleCopy, isNull, reason: '$d');
      }
    });
  });

  group('pathological: almost everything "Not useful"', () {
    // The user needs More Energy every day, at ≈ 20 minutes, and rates
    // every activity "Not useful" — except [kept], which they keep.
    List<SimDay> rejectAllBut(
      Map<ActivityId, PastUsefulness?> kept, {
      TimeWindow window = _t20,
      int days = 60,
      String? label,
    }) => simulate(
      (day) => (
        need: _e,
        window: window,
        replace: null,
        answer: (activity, need) => kept.containsKey(activity)
            ? kept[activity]
            : PastUsefulness.notUseful,
      ),
      days: days,
      label: label,
    );

    test('7a · one activity kept: it repeats rather than a rest is broken; '
        'rests end on time; no lock-in', () {
      final days = rejectAllBut({
        ActivityId.moveToMusic: PastUsefulness.veryUseful,
      }, label: 'SIM 7a one kept');
      expectInvariants(days);
      // A non-resting fit always exists here (Move to music), so a rest is
      // never broken — repeating it, labelled fallback, comes first.
      expect(restingOffers(days), isEmpty);
      final repeats = [
        for (var i = 1; i < days.length; i++)
          if (days[i].offered.activityId == days[i - 1].offered.activityId)
            days[i],
      ];
      expect(repeats, isNotEmpty);
      for (final d in repeats) {
        expect(d.offered.activityId, ActivityId.moveToMusic, reason: '$d');
        expect(d.offered.reason, RecommendationReason.fallback, reason: '$d');
        expect(d.offered.reason.visibleCopy, isNull, reason: '$d');
      }
      // Rests end naturally: each rejected primary is offered again after
      // its rest, and is never offered within it.
      for (final id in [
        ActivityId.thirtyMinuteWalk,
        ActivityId.energisingStretchFlow,
        ActivityId.activeHouseholdTask,
      ]) {
        final offers = days.where((d) => d.offered.activityId == id).toList();
        expect(offers.length, greaterThanOrEqualTo(3), reason: id.name);
        for (var i = 1; i < offers.length; i++) {
          expect(offers[i].day - offers[i - 1].day, greaterThan(14));
        }
      }
      // No permanent lock-in: in every fortnight after the first week
      // something else is offered as soon as a rest ends.
      for (var start = 8; start + 14 <= days.length; start += 7) {
        final span = days.skip(start - 1).take(14);
        expect(
          span.where((d) => d.offered.activityId != ActivityId.moveToMusic),
          isNotEmpty,
          reason: 'days $start–${start + 13}',
        );
      }
    });

    test('7b · two kept (one with no answer): they alternate before any '
        'rest is broken', () {
      final days = rejectAllBut({
        ActivityId.moveToMusic: PastUsefulness.veryUseful,
        ActivityId.gentleStretchPause: null,
      }, label: 'SIM 7b two kept');
      expectInvariants(days);
      expect(restingOffers(days), isEmpty);
    });

    test('7c · every fit resting at ≈ 10: the rest that ends soonest gives '
        'way, deterministically, without a personal reason', () {
      final days = rejectAllBut(
        const {},
        window: _t10,
        days: 40,
        label: 'SIM 7c all resting',
      );
      expectInvariants(days);
      final broken = restingOffers(days);
      expect(broken, isNotEmpty);
      for (final d in broken) {
        expect(d.offered.reason, RecommendationReason.fallback, reason: '$d');
        expect(d.offered.reason.visibleCopy, isNull, reason: '$d');
      }
      // Determinism.
      expect(
        rejectAllBut(const {}, window: _t10, days: 40).map((d) => '$d'),
        days.map((d) => '$d'),
      );
    });
  });

  test('determinism: the same inputs give the same 40 days', () {
    DayScript script(int day) => (
      need: [_e, _c, _g][day % 3],
      window: mixedWindow(day),
      replace: null,
      answer: (a, n) => day.isEven ? PastUsefulness.somewhatUseful : null,
    );
    final a = simulate(script).map((d) => d.toString()).toList();
    final b = simulate(script).map((d) => d.toString()).toList();
    expect(a, b);
  });
}
