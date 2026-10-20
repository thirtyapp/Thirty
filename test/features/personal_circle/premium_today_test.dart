import 'dart:convert';

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
import 'package:thirty/features/home/domain/recommendation_policy.dart';
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/composed_session.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/kept_circle.dart';

/// V2 Phase D2 (ADR-023 §4, §7, §8) — Premium Today through the production
/// providers: composition, fallback, lapse and resubscription, "Use it
/// today", skips and "Leave this out", and exact restore.
void main() {
  final morning = DateTime(2026, 10, 11, 9);
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer open({
    required bool entitled,
    DateTime? at,
    DateTime Function()? clock,
  }) {
    final now = at ?? morning;
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(now),
        eventClockProvider.overrideWithValue(clock ?? () => now),
        premiumEntitlementProvider.overrideWithValue(entitled),
        safetyPendingAllowedProvider.overrideWithValue(false),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> settle() async {
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// A Circle the user kept a month ago.
  KeptCircle keptReset() => KeptCircle(
    id: 'kept-reset',
    name: 'My reset',
    need: Intention.clearerHead,
    plan: CirclePlan.fromWire(const [
      'getItOut:6',
      'chooseOne:1',
      'clearCorner:8',
    ])!,
    createdAt: morning.subtract(const Duration(days: 30)),
    fromCircleId: '2026-09-11',
  );

  /// The Phase D record a development install may hold: a Clearer Head
  /// routine, a Clearer Head Path under way — retired by ADR-024 — beside
  /// [keptReset].
  String legacyRecord() => jsonEncode({
    'schemaVersion': 1,
    'routines': [
      {
        'id': 'routine-1',
        'name': 'My old reset',
        'need': 'clearerHead',
        'versions': [
          {
            'id': 'routine-1-v1',
            'number': 1,
            'modules': ['writeDown:full', 'clearSurface:full'],
            'createdAt': '2026-09-01T09:00:00.000',
            'origin': 'path',
          },
        ],
        'activeVersionId': 'routine-1-v1',
        'createdAt': '2026-09-01T09:00:00.000',
        'enabled': true,
      },
    ],
    'path': {
      'id': 'path-2',
      'kind': 'build',
      'need': 'clearerHead',
      'startedAt': '2026-10-05T09:00:00.000',
      'pool': ['writeDown', 'clearSurface', 'standingStretch'],
      'seed': 'sparseStart',
      'template': 'clearTheDecks',
      'circles': <Object>[],
    },
    'kept': [keptReset().toJson()],
  });

  group('Premium Today', () {
    test('Premium composes one Personal Guided Circle for need and time', () {
      final c = open(entitled: true);
      c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.clearerHead, window: TimeWindow.about20);
      final today = c.read(recommendationProvider).recommendation!;
      expect(today.reason, RecommendationReason.personalCircle);
      final composed = today.composed!;
      expect(composed.plan.minutes, lessThanOrEqualTo(20));
      expect(today.offeredMinutes, composed.plan.minutes);
      expect(today.activity, composed.plan.substanceLine);
      // New user: nothing personal is claimed.
      expect(
        today.why,
        'Small parts, one after another, to fit your 20 minutes.',
      );
      expect(today.canReplace, isTrue);
      final session = today.sessionDefinition;
      expect(session.steps, hasLength(composed.plan.parts.length));
      expect(session.ending, ComposedCopy.ending);
    });

    test('Free never composes: one fitting activity, as before', () {
      final c = open(entitled: false);
      c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.clearerHead, window: TimeWindow.about20);
      final today = c.read(recommendationProvider).recommendation!;
      expect(today.composed, isNull);
      expect(today.reason, isNot(RecommendationReason.personalCircle));
      expect(today.composerFellBack, isFalse);
    });

    test('no honest composition: Free’s activity, said plainly', () async {
      final c = open(entitled: true);
      for (final id in ElementId.values) {
        await c.read(suggestionPreferencesProvider.notifier).leaveOut(id);
      }
      c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.gentlerPace, window: TimeWindow.about20);
      final today = c.read(recommendationProvider).recommendation!;
      expect(today.composed, isNull);
      expect(today.composerFellBack, isTrue);
      expect(today.why, ComposedCopy.fallbackLine);
    });

    test('Not this one today recomposes under the constraint, once', () {
      final c = open(entitled: true);
      final notifier = c.read(recommendationProvider.notifier);
      notifier.chooseIntention(
        Intention.gentlerPace,
        window: TimeWindow.upTo30,
      );
      final first = c.read(recommendationProvider).recommendation!;
      expect(notifier.replaceToday(ReplacementReason.cantGoOutside), isTrue);
      final second = c.read(recommendationProvider).recommendation!;
      expect(second.composed, isNotNull);
      for (final part in second.composed!.plan.parts) {
        expect(part.definition.setting, isNot(ActivitySetting.outdoor));
      }
      expect(second.replacementReason, ReplacementReason.cantGoOutside);
      expect(second.replacedFrom, first.activityId);
      expect(second.canReplace, isFalse);
      expect(notifier.replaceToday(ReplacementReason.notFeeling), isFalse);
    });

    test('a composed Circle is restored exactly after a restart', () async {
      final c = open(entitled: true);
      c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy, window: TimeWindow.upTo30);
      final offered = c.read(recommendationProvider).recommendation!;
      await settle();
      final again = open(entitled: true);
      final restored = again.read(recommendationProvider).recommendation!;
      expect(restored.composed!.plan, offered.composed!.plan);
      expect(restored.composed!.basis, offered.composed!.basis);
      expect(restored.why, offered.why);
      expect(restored.reason, RecommendationReason.personalCircle);
    });
  });

  group('the guided composed runtime', () {
    test('parts move on by themselves; Next and Back re-anchor; restart '
        'lands exactly where time says', () async {
      var now = morning;
      final c = open(entitled: true, clock: () => now);
      final notifier = c.read(recommendationProvider.notifier);
      notifier.chooseIntention(
        Intention.clearerHead,
        window: TimeWindow.about20,
      );
      final plan = c
          .read(recommendationProvider)
          .recommendation!
          .composed!
          .plan;
      notifier.start();
      final first = Duration(minutes: plan.parts.first.minutes);
      now = morning.add(first + const Duration(seconds: 5));
      var moment = c.read(recommendationProvider).partMomentAt(now)!;
      expect(moment.position, 1, reason: 'moved on by itself');
      notifier.movePart(0);
      moment = c.read(recommendationProvider).partMomentAt(now)!;
      expect(moment.position, 0);
      expect(moment.partElapsed, Duration.zero);
      await settle();
      final again = open(entitled: true, clock: () => now);
      final restored = again.read(recommendationProvider);
      expect(restored.partMomentAt(now)!.position, 0);
      expect(restored.partAnchor, c.read(recommendationProvider).partAnchor);
    });

    test('skipping a part is never a usefulness answer', () async {
      var now = morning;
      final c = open(entitled: true, clock: () => now);
      final notifier = c.read(recommendationProvider.notifier);
      notifier.chooseIntention(
        Intention.clearerHead,
        window: TimeWindow.about20,
      );
      final plan = c
          .read(recommendationProvider)
          .recommendation!
          .composed!
          .plan;
      notifier.start();
      notifier.skipPart();
      final state = c.read(recommendationProvider);
      expect(state.skipped, [plan.parts.first.element]);
      expect(state.partMomentAt(now)!.position, 1);
      notifier.close();
      notifier.reportAttempt(CircleAttemptResponse.yes);
      notifier.reportUsefulness(CircleUsefulnessResponse.veryUseful);
      await settle();
      final entry = c.read(circleJournalRepositoryProvider).readAll().single;
      expect(entry.session!.skipped, [plan.parts.first.element.name]);
      expect(entry.session!.parts, plan.toWire());
      // The day's answer never reaches the skipped part, nor any activity.
      final past = pastCirclesFrom([entry]);
      final skippedStanding = elementStanding(
        plan.parts.first.definition,
        Intention.clearerHead,
        RecommendationMemory.of(morning.add(const Duration(days: 1)), past, _p),
      );
      expect(skippedStanding.evidence, 0);
      expect(skippedStanding.allowed, isTrue);
      for (final activity in ActivityId.values) {
        expect(
          RecommendationMemory.of(
            morning.add(const Duration(days: 1)),
            past,
            _p,
          ).strengthFor(activity, Intention.clearerHead),
          0,
        );
      }
      // Nothing was left out: a skip is not a preference.
      expect(c.read(suggestionPreferencesProvider).elementsLeftOut, isEmpty);
    });

    test('"Leave this out next time" is an explicit, reversible '
        'preference', () async {
      final c = open(entitled: true);
      final notifier = c.read(recommendationProvider.notifier);
      notifier.chooseIntention(
        Intention.clearerHead,
        window: TimeWindow.about20,
      );
      final plan = c
          .read(recommendationProvider)
          .recommendation!
          .composed!
          .plan;
      notifier.start();
      notifier.skipPart(leaveOut: true);
      await settle();
      final element = plan.parts.first.element;
      expect(c.read(suggestionPreferencesProvider).isLeftOut(element), isTrue);
      // Tomorrow it is never composed…
      final tomorrow = open(
        entitled: true,
        at: morning.add(const Duration(days: 1)),
      );
      tomorrow
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.clearerHead, window: TimeWindow.about20);
      final next = tomorrow.read(recommendationProvider).recommendation!;
      expect(next.composed!.plan.elements, isNot(contains(element)));
      // …until the user puts it back.
      await tomorrow
          .read(suggestionPreferencesProvider.notifier)
          .putBack(element);
      expect(
        tomorrow.read(suggestionPreferencesProvider).isLeftOut(element),
        isFalse,
      );
    });
  });

  group('ownership', () {
    test('Use it today is Free, replaces today’s not-started choice, and '
        'records no decline', () async {
      await prefs.setString(
        keptCirclesKey,
        jsonEncode(keptCirclesRecord([keptReset()])),
      );
      final c = open(entitled: false);
      final notifier = c.read(recommendationProvider.notifier);
      notifier.chooseIntention(
        Intention.clearerHead,
        window: TimeWindow.about20,
      );
      expect(
        notifier.useOwnedToday(keptCircleId: 'kept-reset'),
        UseTodayResult.used,
      );
      final today = c.read(recommendationProvider).recommendation!;
      expect(today.reason, RecommendationReason.ownChoice);
      expect(today.composed!.keptCircleId, 'kept-reset');
      // Fixed parts, at the lengths they were kept at — never shortened.
      expect(today.composed!.plan, keptReset().plan);
      expect(today.offeredMinutes, 15);
      expect(today.replacedFrom, isNull);
      expect(today.canReplace, isFalse);
      notifier.start();
      expect(
        notifier.useOwnedToday(keptCircleId: 'kept-reset'),
        UseTodayResult.alreadyStarted,
      );
      await settle();
      final entry = c.read(circleJournalRepositoryProvider).readAll().single;
      expect(entry.session!.keptCircleId, 'kept-reset');
      expect(entry.session!.routineId, isNull);
      expect(entry.replacedFrom, isNull);
    });

    test('a kept Circle is the user’s: kept, used today in Free, never '
        'offered unasked', () async {
      final premium = open(entitled: true);
      final notifier = premium.read(recommendationProvider.notifier);
      notifier.chooseIntention(
        Intention.gentlerPace,
        window: TimeWindow.about20,
      );
      final composed = premium
          .read(recommendationProvider)
          .recommendation!
          .composed!;
      final kept = premium
          .read(keptCirclesProvider.notifier)
          .keepCircle(
            plan: composed.plan,
            need: Intention.gentlerPace,
            circleId: '2026-10-11',
          )!;
      expect(kept.name, 'My gentle Circle');
      // The same day's Circle is kept once.
      expect(
        premium
            .read(keptCirclesProvider.notifier)
            .keepCircle(
              plan: composed.plan,
              need: Intention.gentlerPace,
              circleId: '2026-10-11',
            ),
        isNull,
      );
      await settle();
      // Lapsed: tomorrow is Free's — and the kept Circle can be chosen.
      final free = open(
        entitled: false,
        at: morning.add(const Duration(days: 1)),
      );
      final freeNotifier = free.read(recommendationProvider.notifier);
      freeNotifier.chooseIntention(
        Intention.gentlerPace,
        window: TimeWindow.about20,
      );
      expect(
        free.read(recommendationProvider).recommendation!.composed,
        isNull,
      );
      expect(
        freeNotifier.useOwnedToday(keptCircleId: kept.id),
        UseTodayResult.used,
      );
      final today = free.read(recommendationProvider).recommendation!;
      expect(today.composed!.isKept, isTrue);
      expect(today.composed!.plan, composed.plan);
      expect(today.activity, composed.plan.substanceLine);
      expect(today.why, ComposedCopy.keptLine);
    });

    test('lapse stops new composition; resubscribing restores it', () async {
      final premium = open(entitled: true);
      premium
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      expect(
        premium.read(recommendationProvider).recommendation!.composed,
        isNotNull,
      );
      await settle();
      final lapsed = open(
        entitled: false,
        at: morning.add(const Duration(days: 1)),
      );
      lapsed
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      final free = lapsed.read(recommendationProvider).recommendation!;
      expect(free.composed, isNull);
      expect(free.composerFellBack, isFalse);
      await settle();
      final back = open(
        entitled: true,
        at: morning.add(const Duration(days: 2)),
      );
      back
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.moreEnergy, window: TimeWindow.about20);
      expect(
        back.read(recommendationProvider).recommendation!.composed,
        isNotNull,
      );
      // History is the user's throughout.
      await settle();
      expect(
        back.read(circleJournalRepositoryProvider).readAll(),
        hasLength(3),
      );
    });

    test('export includes composed parts and skips, kept Circles and '
        'left-out parts — the user’s own data', () async {
      final c = open(entitled: true);
      final notifier = c.read(recommendationProvider.notifier);
      notifier.chooseIntention(
        Intention.clearerHead,
        window: TimeWindow.about20,
      );
      final plan = c
          .read(recommendationProvider)
          .recommendation!
          .composed!
          .plan;
      notifier.start();
      notifier.skipPart(leaveOut: true);
      notifier.close();
      c
          .read(keptCirclesProvider.notifier)
          .keepCircle(
            plan: plan,
            need: Intention.clearerHead,
            circleId: '2026-10-11',
          );
      await settle();
      final exported =
          jsonDecode(
                c
                    .read(circleJournalRepositoryProvider)
                    .exportAsJson(
                      suggestionPreferences: c
                          .read(suggestionPreferencesProvider)
                          .toJson(),
                      keptCircles: [
                        for (final k in c.read(keptCirclesProvider).kept)
                          k.toJson(),
                      ],
                    ),
              )
              as Map<String, Object?>;
      final entry = (exported['entries']! as List).single as Map;
      expect((entry['session'] as Map)['parts'], plan.toWire());
      expect((entry['session'] as Map)['skipped'], [
        plan.parts.first.element.name,
      ]);
      expect(
        (exported['keptCircles']! as List).single,
        containsPair('parts', plan.toWire()),
      );
      expect(
        ((exported['suggestionPreferences']! as Map)['elementsLeftOut'] as List)
            .single,
        containsPair('elementId', plan.parts.first.element.name),
      );
    });

    test('one Circle a day: choosing again changes nothing', () {
      final c = open(entitled: true);
      final notifier = c.read(recommendationProvider.notifier);
      notifier.chooseIntention(
        Intention.clearerHead,
        window: TimeWindow.about20,
      );
      final first = c.read(recommendationProvider).recommendation!;
      notifier.chooseIntention(Intention.moreEnergy, window: TimeWindow.upTo30);
      expect(c.read(recommendationProvider).recommendation, same(first));
    });
  });

  group('B1 — retired Paths and routines (ADR-024)', () {
    test('a Path under way for today’s need never takes Today: Premium '
        'composes, as on any day', () async {
      await prefs.setString(keptCirclesKey, legacyRecord());
      final c = open(entitled: true);
      c
          .read(recommendationProvider.notifier)
          .chooseIntention(Intention.clearerHead, window: TimeWindow.upTo30);
      final today = c.read(recommendationProvider).recommendation!;
      expect(today.composed, isNotNull);
      expect(today.composed!.isKept, isFalse);
      expect(today.reason, RecommendationReason.personalCircle);
      await settle();
      final entry = c.read(circleJournalRepositoryProvider).readAll().single;
      expect(entry.session!.pathRunId, isNull);
      expect(entry.session!.routineId, isNull);
    });

    test('a stored routine is never a candidate — not on Free, whatever the '
        'day', () async {
      await prefs.setString(keptCirclesKey, legacyRecord());
      for (var day = 0; day < 6; day++) {
        final c = open(entitled: false, at: morning.add(Duration(days: day)));
        c
            .read(recommendationProvider.notifier)
            .chooseIntention(Intention.clearerHead, window: TimeWindow.upTo30);
        final today = c.read(recommendationProvider).recommendation!;
        expect(today.composed, isNull);
        expect(today.retiredSession, isNull);
        expect(today.reason, isNot(RecommendationReason.ownChoice));
        expect(today.activity, isNot('My old reset'));
        await settle();
      }
      final journal = open(
        entitled: false,
      ).read(circleJournalRepositoryProvider).readAll();
      expect(journal, hasLength(6));
      for (final entry in journal) {
        expect(entry.session?.routineId, isNull);
        expect(entry.session?.pathRunId, isNull);
      }
    });

    test('the kept Circle beside them survives, unchanged, and nothing '
        'makes a routine of it', () async {
      await prefs.setString(keptCirclesKey, legacyRecord());
      final c = open(entitled: false);
      final kept = c.read(keptCirclesProvider).kept.single;
      expect(kept.id, 'kept-reset');
      expect(kept.plan, keptReset().plan);
      c.read(keptCirclesProvider.notifier).renameKept(kept.id, 'Mine');
      await settle();
      final record = jsonDecode(prefs.getString(keptCirclesKey)!) as Map;
      expect(record.containsKey('routines'), isFalse);
      expect(record.containsKey('path'), isFalse);
      expect(c.read(keptCirclesProvider).kept.single.name, 'Mine');
    });
  });
}

const _p = RecommendationPolicy.initial;
