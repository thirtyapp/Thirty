import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/dev_preview/paced_qa_bench_page.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/domain/circle_session.dart';
import 'package:thirty/features/home/presentation/widgets/circle_session_card.dart';

/// V2 Phase C — the Circle's runtime as pure functions of stored facts
/// (ADR-021): wall-clock time less pauses, the Open card's moments, Guided
/// positions and Paced phases.
void main() {
  final start = DateTime(2026, 11, 20, 9);
  Duration m(int minutes) => Duration(minutes: minutes);
  Duration s(int seconds) => Duration(seconds: seconds);

  group('active time', () {
    test('is the wall clock since Start — the app being away changes '
        'nothing', () {
      expect(activeElapsed(startedAt: start, at: start.add(m(12))), m(12));
    });

    test('sets every pause aside, and stops while paused', () {
      expect(
        activeElapsed(
          startedAt: start,
          at: start.add(m(12)),
          pausedTotal: m(3),
        ),
        m(9),
      );
      // Paused at minute 5: however long it stays paused, 5 minutes.
      for (final later in [m(5), m(6), m(60)]) {
        expect(
          activeElapsed(
            startedAt: start,
            at: start.add(later),
            pausedAt: start.add(m(5)),
          ),
          m(5),
        );
      }
    });

    test('is never negative', () {
      expect(
        activeElapsed(startedAt: start, at: start.subtract(m(1))),
        Duration.zero,
      );
    });

    test('the natural end is time only, reached at the time set aside', () {
      expect(naturalEndReached(m(14), m(15)), isFalse);
      expect(naturalEndReached(m(15), m(15)), isTrue);
      expect(naturalEndReached(m(40), m(15)), isTrue);
      expect(naturalEndReached(m(1), Duration.zero), isFalse);
    });
  });

  group('Open: first action, ideas one at a time, then the ending', () {
    final write = activityDefinition(ActivityId.writeItDown);

    test('the first action stays a fifth of the Circle, at least two '
        'minutes and never more than half', () {
      expect(openFirstActionSpan(m(15)), m(3));
      expect(openFirstActionSpan(m(5)), m(2));
      expect(openFirstActionSpan(m(3)), const Duration(seconds: 90));
      expect(openFirstActionSpan(m(25)), m(5));
      expect(openFirstActionSpan(m(10)), m(2));
    });

    test('Write it down, 15 minutes: each authored idea in turn, the '
        'ending from the natural end on', () {
      OpenMoment at(Duration elapsed) =>
          openMomentFor(write, elapsed: elapsed, offered: m(15));
      expect(at(Duration.zero), const OpenMoment(OpenPhase.firstAction));
      expect(at(m(2)), const OpenMoment(OpenPhase.firstAction));
      expect(at(m(3)), const OpenMoment(OpenPhase.idea, 0));
      expect(at(m(7)), const OpenMoment(OpenPhase.idea, 1));
      expect(at(m(11)), const OpenMoment(OpenPhase.idea, 2));
      expect(at(m(15)), const OpenMoment(OpenPhase.ending));
      expect(at(m(90)), const OpenMoment(OpenPhase.ending));
    });

    test('every live Open activity: only authored content, the ideas in '
        'order, never past the last', () {
      for (final id in ActivityId.values) {
        final activity = activityDefinition(id);
        if (activity.mode != CircleMode.open ||
            activity.status != ActivityStatus.live) {
          continue;
        }
        final offered = m(activity.typicalMinutes);
        var last = -1;
        for (var second = 0; second < offered.inSeconds; second += 10) {
          final moment = openMomentFor(
            activity,
            elapsed: s(second),
            offered: offered,
          );
          expect(moment.phase, isNot(OpenPhase.ending), reason: id.name);
          if (moment.phase == OpenPhase.idea) {
            expect(moment.ideaIndex, greaterThanOrEqualTo(last));
            expect(
              moment.ideaIndex,
              lessThan(activity.whileYoureThere.length),
              reason: id.name,
            );
            last = moment.ideaIndex;
          }
        }
      }
    });
  });

  group('Guided: positions', () {
    final stretch = activityDefinition(ActivityId.energisingStretchFlow);

    test('the authored steps, then "To finish" — clamped, never beyond', () {
      expect(stretch.steps, hasLength(5));
      expect(guidedFinishPosition(stretch), 5);
      expect(clampGuidedPosition(stretch, -3), 0);
      expect(clampGuidedPosition(stretch, 2), 2);
      expect(clampGuidedPosition(stretch, 9), 5);
    });

    test('the heading is the step on show, and where it sits — never a '
        'score or a percentage', () {
      SessionHeading heading(int position, {bool paused = false}) =>
          sessionHeadingFor(
            activity: stretch,
            body: SessionBody.guided,
            elapsedMinutes: 2,
            offeredMinutes: 5,
            ended: false,
            paused: paused,
            guidedPosition: position,
          );
      expect(heading(0), (
        title: 'Reach up',
        detail: 'Step 1 of 5 · A quick standing stretch',
      ));
      expect(heading(3, paused: true), (
        title: 'Gentle twist',
        detail: 'Paused · Step 4 of 5',
      ));
      expect(heading(5), (
        title: 'To finish',
        detail: 'A quick standing stretch',
      ));
    });
  });

  group('Paced: a deterministic phase runtime', () {
    const pattern = pacedQaFixture;

    test('phase, time left and cycle follow active time alone', () {
      final at0 = paceMomentFor(pattern, Duration.zero);
      expect((at0.phaseIndex, at0.cycle, at0.finished), (0, 0, false));
      expect(at0.phaseRemaining, s(4));

      final at5 = paceMomentFor(pattern, s(5));
      expect((at5.phaseIndex, at5.cycle), (1, 0));
      expect(at5.phaseRemaining, s(5));

      final at23 = paceMomentFor(pattern, s(23));
      expect((at23.phaseIndex, at23.cycle), (0, 2));
      expect(at23.phaseElapsed, s(3));
    });

    test('ends at its total and never runs on', () {
      final end = paceMomentFor(pattern, pattern.total);
      expect(end.finished, isTrue);
      expect(paceMomentFor(pattern, m(9)).finished, isTrue);
    });

    test('the same active time is always the same moment — a pause resumes '
        'exactly where it stopped', () {
      final before = paceMomentFor(pattern, s(37));
      final after = paceMomentFor(pattern, s(37));
      expect(
        (after.phaseIndex, after.cycle, after.phaseElapsed),
        (before.phaseIndex, before.cycle, before.phaseElapsed),
      );
    });
  });

  group('the safety gate (unchanged by Phase C)', () {
    test('no catalogue activity paces: no pattern exists until the '
        'separate safety/content review supplies one', () {
      for (final id in ActivityId.values) {
        final activity = activityDefinition(id);
        expect(activity.pace, isNull, reason: id.name);
        expect(
          sessionBodyFor(activity, activity.pace),
          isNot(SessionBody.paced),
          reason: id.name,
        );
      }
    });

    test('breathing and exertion stay gated; the breath reset stays '
        'retired', () {
      for (final id in [
        ActivityId.briskStepBurst,
        ActivityId.activeMovementSnack,
        ActivityId.focusedBreathingCount,
        ActivityId.restfulBreathingPause,
      ]) {
        expect(
          activityDefinition(id).status,
          ActivityStatus.safetyReviewPending,
          reason: id.name,
        );
        expect(
          isActivityOfferable(id, allowSafetyPending: false),
          isFalse,
          reason: id.name,
        );
      }
      expect(
        activityDefinition(ActivityId.energisingBreathReset).status,
        ActivityStatus.retired,
      );
    });

    test('only a given pattern makes a Paced activity pace; Guided runs '
        'its steps', () {
      final paced = activityDefinition(ActivityId.focusedBreathingCount);
      expect(sessionBodyFor(paced, null), SessionBody.open);
      expect(sessionBodyFor(paced, pacedQaFixture), SessionBody.paced);
      expect(
        sessionBodyFor(activityDefinition(ActivityId.gentleStretchPause), null),
        SessionBody.guided,
      );
    });
  });
}
