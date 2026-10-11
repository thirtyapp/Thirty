import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';

/// V2 Phase D2 (ADR-023 §2) — the element library's invariants: safety,
/// stable identity, authored-length truth and content guards.
void main() {
  const gated = {
    ActivityId.briskStepBurst,
    ActivityId.activeMovementSnack,
    ActivityId.focusedBreathingCount,
    ActivityId.restfulBreathingPause,
  };

  group('safety', () {
    test('no element comes from safety-pending or retired content', () {
      for (final element in elementLibrary.values) {
        final from = element.from;
        if (from == null) continue;
        expect(gated, isNot(contains(from)), reason: element.id.name);
        expect(from, isNot(ActivityId.energisingBreathReset));
        expect(
          activityDefinition(from).status,
          ActivityStatus.live,
          reason: element.id.name,
        );
      }
    });

    test('every release element is live and offerable', () {
      for (final element in elementLibrary.values) {
        expect(element.status, ActivityStatus.live, reason: element.id.name);
        expect(isElementOfferable(element), isTrue, reason: element.id.name);
      }
    });

    test('no element breathes, paces or asks for exertion', () {
      final forbidden = RegExp(
        r'breath|inhale|exhale|stairs|slope|climb|press-up|push-up|squat|'
        r'jump|go for a run|\brunning\b|jog|sprint|heart rate|out of breath',
        caseSensitive: false,
      );
      for (final element in elementLibrary.values) {
        expect(
          forbidden.hasMatch('${element.name} ${element.instruction}'),
          isFalse,
          reason: element.id.name,
        );
      }
    });

    test('an element of an activity follows that activity’s status', () {
      // Simulated: a piece of gated content would never be offerable.
      const piece = CircleElement(
        id: ElementId.standAndReach,
        name: 'x',
        instruction: 'x',
        needs: {Intention.moreEnergy},
        roles: {ElementRole.arrive},
        minutes: 1,
        kind: ElementKind.movement,
        setting: ActivitySetting.either,
        art: ActivityId.briskStepBurst,
        from: ActivityId.briskStepBurst,
      );
      expect(isElementOfferable(piece), isFalse);
      const retired = CircleElement(
        id: ElementId.standAndReach,
        name: 'x',
        instruction: 'x',
        needs: {Intention.moreEnergy},
        roles: {ElementRole.arrive},
        minutes: 1,
        kind: ElementKind.movement,
        setting: ActivitySetting.either,
        art: ActivityId.easyWalk,
        status: ActivityStatus.retired,
      );
      expect(isElementOfferable(retired), isFalse);
    });
  });

  group('identity', () {
    test('every id has exactly one element, keyed by its own id', () {
      expect(elementLibrary.keys.toSet(), ElementId.values.toSet());
      for (final MapEntry(:key, :value) in elementLibrary.entries) {
        expect(value.id, key);
      }
    });

    test('stored ids are stable (journal and kept Circles store them)', () {
      // A rename or removal here breaks history: add, never change.
      expect(ElementId.values.map((e) => e.name).toList(), [
        'phoneFaceDown',
        'nameWhatsOn',
        'openWindow',
        'standAndReach',
        'songOn',
        'comfortableSpot',
        'lookAround',
        'moveToMusic',
        'standingStretch',
        'activeJob',
        'briskWalk',
        'roundTheBlock',
        'quickClearUp',
        'daylight',
        'getItOut',
        'clearCorner',
        'oneTask',
        'listenOne',
        'readPages',
        'phoneFreeWalk',
        'closeWhatsOpen',
        'lookFar',
        'warmDrink',
        'gentleStretch',
        'neckAndShoulders',
        'quietMusic',
        'easyWalk',
        'sitOutside',
        'tendOne',
        'chooseOne',
        'firstStep',
        'sitAMinute',
        'putThingsBack',
        'glassOfWater',
        'shakeOut',
        'whatsNext',
        'noteOneThing',
        'oneLongReach',
      ]);
    });

    test('a part round-trips; a made-up length never restores', () {
      for (final element in elementLibrary.values) {
        for (final minutes in element.lengths) {
          final part = CirclePart(element.id, minutes);
          expect(CirclePart.fromWire(part.wire), part);
        }
        expect(CirclePart.fromWire('${element.id.name}:99'), isNull);
      }
      expect(CirclePart.fromWire('nothing:4'), isNull);
      expect(CirclePart.fromWire(4), isNull);
      final plan = CirclePlan(const [
        CirclePart(ElementId.nameWhatsOn, 1),
        CirclePart(ElementId.getItOut, 4),
        CirclePart(ElementId.chooseOne, 1),
      ]);
      expect(CirclePlan.fromWire(plan.toWire()), plan);
      expect(CirclePlan.fromWire(['getItOut:4', 'bad']), isNull);
    });
  });

  group('authored-length truth', () {
    test('lengths are authored, short forms truly shorter', () {
      for (final element in elementLibrary.values) {
        expect(element.minutes, inInclusiveRange(1, 20), reason: '$element');
        final short = element.shortMinutes;
        if (short != null) {
          expect(short, lessThan(element.minutes));
          expect(short, greaterThanOrEqualTo(4));
        }
        // A piece of an activity is never longer than the activity itself.
        final from = element.from;
        if (from != null && element.carriesEvidence) {
          expect(
            element.minutes,
            lessThanOrEqualTo(activityDefinition(from).typicalMinutes),
            reason: element.id.name,
          );
        }
      }
    });

    test('instructions never state a length (one text, every length)', () {
      final length = RegExp(r'\d+\s*(minute|min|second)', caseSensitive: false);
      for (final element in elementLibrary.values) {
        expect(
          length.hasMatch(element.instruction),
          isFalse,
          reason: element.id.name,
        );
      }
    });

    test('arrive and settle stay short; main pieces carry the time', () {
      for (final element in elementLibrary.values) {
        final roles = element.roles;
        if (roles.contains(ElementRole.main)) {
          expect(element.minutes, greaterThanOrEqualTo(5));
        }
        if (!roles.contains(ElementRole.main) &&
            !roles.contains(ElementRole.second)) {
          expect(element.minutes, lessThanOrEqualTo(3), reason: '$element');
        }
      }
    });

    test('a part that needs another names one that can come before it', () {
      for (final element in elementLibrary.values) {
        final after = element.after;
        if (after == null) continue;
        expect(elementOf(after).needs.intersection(element.needs), isNotEmpty);
      }
    });
  });

  group('semantic dependencies (correction pass, 2026-10-11)', () {
    // Words that refer to something an earlier part left behind.
    final refersBack = RegExp(
      r'(what you wrote|you circled|what you used|you made|you’ve done|'
      r'the list|that thing)',
      caseSensitive: false,
    );
    // Words that only hold at the start, or at the very end, of a Circle.
    final opening = RegExp(r'(before you begin|while you start|for the rest)');
    final closing = RegExp(r'(^Finish|before you move on|before you carry on)');

    test('an element that refers back always names what it builds on', () {
      for (final e in elementLibrary.values) {
        if (refersBack.hasMatch(e.instruction)) {
          expect(e.after, isNotNull, reason: e.id.name);
        }
      }
      expect(elementOf(ElementId.chooseOne).after, ElementId.getItOut);
      expect(elementOf(ElementId.firstStep).after, ElementId.chooseOne);
    });

    test('words that only hold at the start or the end take only that '
        'place', () {
      for (final e in elementLibrary.values) {
        if (opening.hasMatch(e.instruction)) {
          expect(e.roles, {ElementRole.arrive}, reason: e.id.name);
        }
        if (closing.hasMatch(e.instruction)) {
          expect(e.roles, {ElementRole.settle}, reason: e.id.name);
        }
      }
    });

    test('in every Circle the composer can make, a part that builds on '
        'another comes directly after it — never without it', () {
      var checked = 0;
      for (final need in Intention.values) {
        final allowed = [
          for (final e in elementLibrary.values)
            if (isElementOfferable(e) && e.fits(need)) e,
        ];
        for (final window in TimeWindow.values) {
          for (final parts in gatePassingShapes(
            allowed,
            window: window.maxMinutes,
          )) {
            for (final (i, part) in parts.indexed) {
              final after = part.definition.after;
              if (after == null) continue;
              checked++;
              expect(i, greaterThan(0));
              expect(parts[i - 1].element, after, reason: '$parts');
            }
          }
        }
      }
      // The dependent parts do appear: the rule is exercised, not vacuous.
      expect(checked, greaterThan(0));
    });

    test('without what it builds on, a dependent part never composes', () {
      final allowed = [
        for (final e in elementLibrary.values)
          if (isElementOfferable(e) &&
              e.fits(Intention.clearerHead) &&
              e.id != ElementId.getItOut)
            e,
      ];
      for (final window in TimeWindow.values) {
        for (final parts in gatePassingShapes(
          allowed,
          window: window.maxMinutes,
        )) {
          final ids = [for (final p in parts) p.element];
          expect(ids, isNot(contains(ElementId.chooseOne)));
          expect(ids, isNot(contains(ElementId.firstStep)));
        }
      }
    });

    test('skipping a part takes the parts that build on it along', () {
      final plan = CirclePlan(const [
        CirclePart(ElementId.phoneFaceDown, 1),
        CirclePart(ElementId.getItOut, 6),
        CirclePart(ElementId.chooseOne, 1),
        CirclePart(ElementId.firstStep, 2),
      ]);
      expect(plan.partsBuildingOn(1), 2);
      expect(plan.partsBuildingOn(2), 1);
      expect(plan.partsBuildingOn(3), 0);
      expect(plan.partsBuildingOn(0), 0);
    });
  });

  group('content guards', () {
    test('names are short enough for the Today card line', () {
      for (final element in elementLibrary.values) {
        expect(
          element.name.length,
          lessThanOrEqualTo(22),
          reason: element.name,
        );
      }
    });

    test('no medical claim, outcome promise, pressure or achievement', () {
      final banned = RegExp(
        r'\b(heal|cure|therapy|therapeutic|anxiety|depress|stress|mood|'
        r'boost|improve|reduce|guarantee|proven|calm(s|ing)? (you|your)|'
        r'will help|helps you|you need|you should|must|achiev|well done|'
        r'great job|streak|score|level|goal|burn|fat|calorie|detox)\b',
        caseSensitive: false,
      );
      for (final element in elementLibrary.values) {
        expect(
          banned.hasMatch('${element.name} ${element.instruction}'),
          isFalse,
          reason: element.id.name,
        );
      }
    });

    test('every need has main pieces for every time window', () {
      for (final need in Intention.values) {
        final allowed = [
          for (final e in elementLibrary.values)
            if (isElementOfferable(e) && e.fits(need)) e,
        ];
        for (final window in TimeWindow.values) {
          expect(
            gatePassingShapes(allowed, window: window.maxMinutes),
            isNotEmpty,
            reason: '${need.name} ${window.name}',
          );
        }
      }
    });

    test('the Today card names a composed Circle by its substance, always '
        'short enough for two lines (S25 finding)', () {
      for (final need in Intention.values) {
        for (final window in TimeWindow.values) {
          for (final parts in gatePassingShapes([
            for (final e in elementLibrary.values)
              if (isElementOfferable(e) && e.fits(need)) e,
          ], window: window.maxMinutes)) {
            final plan = CirclePlan(parts);
            expect(plan.substance.first, plan.main);
            expect(plan.substance.length, inInclusiveRange(1, 2));
            expect(
              plan.substanceLine.length,
              lessThanOrEqualTo(46),
              reason: plan.substanceLine,
            );
          }
        }
      }
    });

    test('the longest composed line fits two lines of the Today card', () {
      for (final need in Intention.values) {
        final allowed = [
          for (final e in elementLibrary.values)
            if (isElementOfferable(e) && e.fits(need)) e,
        ];
        for (final window in TimeWindow.values) {
          for (final parts in gatePassingShapes(
            allowed,
            window: window.maxMinutes,
          )) {
            expect(
              CirclePlan(parts).line.length,
              lessThanOrEqualTo(86),
              reason: CirclePlan(parts).line,
            );
          }
        }
      }
    });
  });
}
