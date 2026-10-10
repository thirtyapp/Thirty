import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/dev_preview/paced_qa_bench_page.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';
import 'package:thirty/features/home/presentation/widgets/circle_session_card.dart';
import 'package:thirty/features/home/presentation/widgets/daily_intention_prompt.dart';

/// V2 Phase C on screen (ADR-021): the running Circle's session — Open,
/// Guided and Paced — its natural end, and the no-candidate note.

final _morning = DateTime(2026, 11, 20, 9);
const _day = '2026-11-20';
late DateTime _clock;

Map<String, Object> _running(
  Intention need,
  ActivityId activity,
  int minutes, {
  int startedMinutesAgo = 0,
  int position = 0,
}) => {
  firstBreathLastPlayedDateKey: _day,
  recommendationDayKey: _day,
  recommendationIntentionKey: need.name,
  recommendationActivityIdKey: activity.name,
  recommendationTimeWindowKey: TimeWindow.about20.name,
  recommendationOfferedMinutesKey: minutes,
  recommendationReasonKey: RecommendationReason.bestFit.name,
  recommendationStatusKey: 'started',
  recommendationStartedAtKey: _morning
      .subtract(Duration(minutes: startedMinutesAgo))
      .toIso8601String(),
  recommendationGuidedPositionKey: ?(position == 0 ? null : position),
};

Future<(Widget, ProviderContainer)> _app(
  Widget home, {
  Map<String, Object> stored = const {},
  bool reducedMotion = false,
}) async {
  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_morning),
      eventClockProvider.overrideWithValue(() => _clock),
      safetyPendingAllowedProvider.overrideWithValue(false),
    ],
  );
  return (
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(412, 915),
            disableAnimations: reducedMotion,
          ),
          child: Scaffold(body: home),
        ),
      ),
    ),
    container,
  );
}

void _useS25(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Every TalkBack announcement made while the test runs.
List<String> _announcements(WidgetTester tester) {
  final heard = <String>[];
  tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
    SystemChannels.accessibility,
    (message) async {
      if (message case {'type': 'announce', 'data': {'message': final text}}) {
        heard.add('$text');
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(
          SystemChannels.accessibility,
          null,
        ),
  );
  return heard;
}

double _warmth(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find
          .ancestor(
            of: find.byType(CircleEndWarmth),
            matching: find.byType(FadeTransition),
          )
          .first,
    )
    .opacity
    .value;

ThirtyButton _close(WidgetTester tester) => tester.widget<ThirtyButton>(
  find.widgetWithText(ThirtyButton, 'Close Circle'),
);

void main() {
  setUp(() => _clock = _morning);

  group('Open', () {
    final write = activityDefinition(ActivityId.writeItDown);

    testWidgets('the session: the activity, its time, the first action — '
        'then each idea, then its ending; Close quiet until the time set '
        'aside is here', (tester) async {
      _useS25(tester);
      final (app, c) = await _app(
        const CircleHero(),
        stored: _running(Intention.clearerHead, ActivityId.writeItDown, 15),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();

      expect(find.text('Write it down'), findsOneWidget);
      expect(find.text('0 of 15 minutes'), findsOneWidget);
      expect(find.text('FIRST'), findsOneWidget);
      expect(find.text(write.firstAction), findsOneWidget);
      expect(find.text('How to do it'), findsOneWidget);
      expect(_close(tester).variant, ThirtyButtonVariant.secondary);
      // No greeting, no Today card chrome while the Circle runs.
      expect(find.text('Here’s one thing for today.'), findsNothing);
      expect(find.textContaining('TODAY'), findsNothing);

      _clock = _morning.add(const Duration(minutes: 4));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('4 of 15 minutes'), findsOneWidget);
      expect(find.text('WHILE YOU’RE THERE'), findsOneWidget);
      expect(find.text(write.whileYoureThere.first), findsOneWidget);

      _clock = _morning.add(const Duration(minutes: 15));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('That’s your 15 minutes'), findsOneWidget);
      expect(find.text('TO FINISH'), findsOneWidget);
      expect(find.text(write.ending), findsOneWidget);
      // Nothing is closed for the user, and nothing is claimed.
      expect(
        c.read(recommendationProvider).status,
        RecommendationStatus.started,
      );
      expect(_close(tester).variant, ThirtyButtonVariant.primary);
      for (final claim in ['complete', 'Complete', 'done', 'Great', 'well']) {
        expect(find.textContaining(claim), findsNothing, reason: claim);
      }
    });
  });

  group('the natural end beat', () {
    testWidgets('reached while here: the World warms over a moment, and '
        'TalkBack hears it once', (tester) async {
      _useS25(tester);
      final heard = _announcements(tester);
      final (app, c) = await _app(
        const CircleHero(),
        stored: _running(
          Intention.clearerHead,
          ActivityId.writeItDown,
          15,
          startedMinutesAgo: 14,
        ),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();
      expect(_warmth(tester), 0);

      _clock = _morning.add(const Duration(minutes: 1));
      await tester.pump(const Duration(seconds: 1));
      // The beat's first frame is its zero point.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final midway = _warmth(tester);
      expect(midway, inExclusiveRange(0, 1));
      await tester.pump(const Duration(seconds: 2));
      expect(_warmth(tester), 1);

      final ending = activityDefinition(ActivityId.writeItDown).ending;
      expect(heard, [SessionCopy.naturalEndAnnouncement(15, ending)]);

      // Time keeps passing: never replayed, never repeated.
      for (var i = 0; i < 5; i++) {
        _clock = _clock.add(const Duration(minutes: 1));
        await tester.pump(const Duration(seconds: 1));
      }
      expect(_warmth(tester), 1);
      expect(heard, hasLength(1));
    });

    testWidgets('found on arrival — after the background, or a restart — it '
        'is simply there: no replay, no announcement', (tester) async {
      _useS25(tester);
      final heard = _announcements(tester);
      final (app, c) = await _app(
        const CircleHero(),
        stored: _running(
          Intention.clearerHead,
          ActivityId.writeItDown,
          15,
          startedMinutesAgo: 40,
        ),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();
      expect(_warmth(tester), 1);
      expect(find.text('That’s your 15 minutes'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(heard, isEmpty);
    });

    testWidgets('reduced motion: the same end, at once — the meaning and the '
        'announcement, without the movement', (tester) async {
      _useS25(tester);
      final heard = _announcements(tester);
      final (app, c) = await _app(
        const CircleHero(),
        stored: _running(
          Intention.clearerHead,
          ActivityId.writeItDown,
          15,
          startedMinutesAgo: 14,
        ),
        reducedMotion: true,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();

      _clock = _morning.add(const Duration(minutes: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(_warmth(tester), 1);
      await tester.pump(CircleHero.naturalEndAnnouncementDelay);
      expect(heard, hasLength(1));
    });

    testWidgets('an early Close never warms the World', (tester) async {
      _useS25(tester);
      final (app, c) = await _app(
        const CircleHero(),
        stored: _running(
          Intention.clearerHead,
          ActivityId.writeItDown,
          15,
          startedMinutesAgo: 4,
        ),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();
      c.read(recommendationProvider.notifier).close();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(_warmth(tester), 0);
      expect(find.text(CircleHero.closedHeading), findsOneWidget);
    });

    test('the closed words: about the app\'s Circle, never the activity', () {
      expect(CircleHero.closedHeading, 'Your Circle for today.');
      expect(CircleHero.closedDetail, 'Your next Circle opens tomorrow.');
    });
  });

  group('Guided', () {
    final stretch = activityDefinition(ActivityId.energisingStretchFlow);

    testWidgets('one step at a time: its name as the heading, its '
        'instruction and cue below; Next and Back; then "To finish"', (
      tester,
    ) async {
      _useS25(tester);
      final semantics = tester.ensureSemantics();
      final (app, c) = await _app(
        const CircleHero(),
        stored: _running(
          Intention.moreEnergy,
          ActivityId.energisingStretchFlow,
          5,
        ),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();

      final first = stretch.steps.first;
      expect(find.text(first.name), findsOneWidget);
      expect(
        find.text('Step 1 of 5 · A quick standing stretch'),
        findsOneWidget,
      );
      expect(find.text(first.instruction), findsOneWidget);
      expect(find.text(first.cue), findsOneWidget);
      // Back keeps its place but is not offered on step 1.
      expect(find.bySemanticsLabel('Back'), findsNothing);
      // One step only: the next one is not on screen.
      expect(find.text(stretch.steps[1].instruction), findsNothing);
      // Read once, whole, when it changes.
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp(r'^Step 1 of 5\. '))),
        matchesSemantics(
          label:
              'Step 1 of 5. ${first.name}. ${first.instruction} '
              '${first.cue}.',
          isLiveRegion: true,
        ),
      );

      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(stretch.steps[1].name), findsOneWidget);
      expect(c.read(recommendationProvider).guidedPosition, 1);

      await tester.tap(find.text('Back'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(first.name), findsOneWidget);

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('Next'));
        await tester.pump(const Duration(milliseconds: 600));
      }
      expect(find.text('To finish'), findsOneWidget);
      expect(find.text(stretch.ending), findsOneWidget);
      expect(find.text('Next'), findsNothing);
      // Reaching the end of the steps closes nothing and claims nothing.
      expect(
        c.read(recommendationProvider).status,
        RecommendationStatus.started,
      );
      semantics.dispose();
    });

    testWidgets('Pause stops the time and says so; Resume continues', (
      tester,
    ) async {
      _useS25(tester);
      final (app, c) = await _app(
        const CircleHero(),
        stored: _running(
          Intention.moreEnergy,
          ActivityId.energisingStretchFlow,
          5,
          position: 2,
        ),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();

      // An icon of one width in both states — pausing never reflows the
      // card — named for TalkBack, with the state in words in the heading.
      final pauseSize = tester.getSize(find.byTooltip('Pause'));
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      expect(c.read(recommendationProvider).isPaused, isTrue);
      expect(find.text('Paused · Step 3 of 5'), findsOneWidget);
      expect(find.byTooltip('Resume'), findsOneWidget);
      expect(tester.getSize(find.byTooltip('Resume')), pauseSize);

      await tester.tap(find.byTooltip('Resume'));
      await tester.pump();
      expect(c.read(recommendationProvider).isPaused, isFalse);
      expect(find.byTooltip('Pause'), findsOneWidget);
    });

    testWidgets('one filled action at a time: Next while the steps run; '
        'Close once on "To finish" or the time is reached — and no step '
        'controls after it', (tester) async {
      _useS25(tester);
      ThirtyButton button(String label) =>
          tester.widget<ThirtyButton>(find.widgetWithText(ThirtyButton, label));
      Future<void> pumpAt(int position, {int startedMinutesAgo = 0}) async {
        final (app, c) = await _app(
          const CircleHero(),
          stored: _running(
            Intention.moreEnergy,
            ActivityId.energisingStretchFlow,
            5,
            position: position,
            startedMinutesAgo: startedMinutesAgo,
          ),
        );
        addTearDown(c.dispose);
        await tester.pumpWidget(app);
        await tester.pump();
      }

      await pumpAt(2);
      expect(button('Next').variant, ThirtyButtonVariant.primary);
      expect(button('Close Circle').variant, ThirtyButtonVariant.secondary);

      await pumpAt(5);
      expect(find.text('Next'), findsNothing);
      expect(button('Close Circle').variant, ThirtyButtonVariant.primary);

      await pumpAt(4, startedMinutesAgo: 6);
      expect(find.text('Next'), findsNothing);
      expect(find.text('Back'), findsNothing);
      expect(find.byTooltip('Pause'), findsNothing);
      expect(button('Close Circle').variant, ThirtyButtonVariant.primary);
    });

    testWidgets('every control is a full 48pt target', (tester) async {
      _useS25(tester);
      final (app, c) = await _app(
        const CircleHero(),
        stored: _running(
          Intention.moreEnergy,
          ActivityId.energisingStretchFlow,
          5,
          position: 2,
        ),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();
      for (final (control, finder) in [
        ('Back', find.text('Back')),
        ('Pause', find.byTooltip('Pause')),
        ('Next', find.text('Next')),
      ]) {
        final button = find.ancestor(
          of: finder,
          matching: find.byWidgetPredicate(
            (w) =>
                w is ButtonStyleButton || w is ThirtyButton || w is IconButton,
          ),
        );
        expect(
          tester.getSize(button.first).height,
          greaterThanOrEqualTo(48),
          reason: control,
        );
      }
    });
  });

  group('Guided natural end: time never fabricates step progress', () {
    final stretch = activityDefinition(ActivityId.energisingStretchFlow);
    final endAnnouncement = SessionCopy.naturalEndAnnouncement(
      5,
      stretch.ending,
    );

    /// The end, truthfully: the activity and its time, the ending line,
    /// Close leading — and no step number, on screen or to TalkBack.
    void expectTruthfulEnd(WidgetTester tester) {
      expect(find.text(stretch.title), findsOneWidget);
      expect(find.text('That’s your 5 minutes'), findsOneWidget);
      expect(find.text('TO FINISH'), findsOneWidget);
      expect(find.text(stretch.ending), findsOneWidget);
      expect(find.textContaining(RegExp(r'Step \d')), findsNothing);
      expect(find.bySemanticsLabel(RegExp(r'Step \d')), findsNothing);
      for (final step in stretch.steps) {
        expect(find.text(step.name), findsNothing, reason: step.name);
        expect(find.text(step.instruction), findsNothing, reason: step.name);
      }
      expect(find.text('Next'), findsNothing);
      expect(find.text('Back'), findsNothing);
      expect(find.byTooltip('Pause'), findsNothing);
      expect(_close(tester).variant, ThirtyButtonVariant.primary);
      for (final claim in ['complete', 'Complete', 'done', 'Great', 'well']) {
        expect(find.textContaining(claim), findsNothing, reason: claim);
      }
    }

    test('the heading never carries a step once the time is reached — '
        'whichever step was on show, paused or not', () {
      for (var position = 0; position <= stretch.steps.length; position++) {
        for (final paused in [false, true]) {
          expect(
            sessionHeadingFor(
              activity: stretch,
              body: SessionBody.guided,
              elapsedMinutes: 5,
              offeredMinutes: 5,
              ended: true,
              paused: paused,
              guidedPosition: position,
            ),
            (title: stretch.title, detail: 'That’s your 5 minutes'),
            reason: 'position $position, paused $paused',
          );
        }
      }
    });

    for (final (where, position) in [
      ('step 1', 0),
      ('a middle step (2 of 5)', 1),
      ('the final step', 4),
    ]) {
      testWidgets('reached live on $where: the end takes over, with one '
          'announcement and no step claimed', (tester) async {
        _useS25(tester);
        final semantics = tester.ensureSemantics();
        final heard = _announcements(tester);
        final (app, c) = await _app(
          const CircleHero(),
          stored: _running(
            Intention.moreEnergy,
            ActivityId.energisingStretchFlow,
            5,
            startedMinutesAgo: 4,
            position: position,
          ),
        );
        addTearDown(c.dispose);
        await tester.pumpWidget(app);
        await tester.pump();
        expect(find.text(stretch.steps[position].name), findsOneWidget);
        expect(
          find.textContaining('Step ${position + 1} of 5'),
          findsOneWidget,
        );

        _clock = _morning.add(const Duration(minutes: 1));
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        // Whatever step control TalkBack was on is gone: Close — the one
        // thing left — has focus first, and the end is spoken just after,
        // where TalkBack's reaction to the change can no longer cut it off.
        expect(
          tester.getSemantics(
            find.widgetWithText(ThirtyButton, 'Close Circle'),
          ),
          matchesSemantics(
            label: 'Close Circle',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
            isFocusable: true,
            isFocused: true,
          ),
        );
        expect(heard, isEmpty);
        await tester.pump(const Duration(seconds: 2));

        expectTruthfulEnd(tester);
        expect(heard, [endAnnouncement]);
        // The step on show is left exactly where the user left it.
        expect(c.read(recommendationProvider).guidedPosition, position);

        for (var i = 0; i < 3; i++) {
          _clock = _clock.add(const Duration(minutes: 1));
          await tester.pump(const Duration(seconds: 1));
        }
        expect(heard, hasLength(1));
        semantics.dispose();
      });
    }

    testWidgets('reached in the background on step 2 of 5: on return the '
        'end is simply there — no replay, no announcement, no step', (
      tester,
    ) async {
      _useS25(tester);
      final semantics = tester.ensureSemantics();
      final heard = _announcements(tester);
      final binding = tester.binding;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final (app, c) = await _app(
        const CircleHero(),
        stored: _running(
          Intention.moreEnergy,
          ActivityId.energisingStretchFlow,
          5,
          startedMinutesAgo: 3,
          position: 1,
        ),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();
      expect(find.text('Step 2 of 5 · ${stretch.title}'), findsOneWidget);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      _clock = _morning.add(const Duration(minutes: 9));
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      // The first look after coming back — the Circle's own second tick.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(_warmth(tester), 1);
      await tester.pump(const Duration(milliseconds: 400));
      expect(_warmth(tester), 1);
      await tester.pump(const Duration(seconds: 3));

      expectTruthfulEnd(tester);
      expect(heard, isEmpty);
      expect(c.read(recommendationProvider).guidedPosition, 1);
      semantics.dispose();
    });

    testWidgets('a restart after the time ran out on step 2 of 5: the same '
        'truthful end, still, and the step kept as it was', (tester) async {
      _useS25(tester);
      final semantics = tester.ensureSemantics();
      final heard = _announcements(tester);
      final (app, c) = await _app(
        const CircleHero(),
        stored: _running(
          Intention.moreEnergy,
          ActivityId.energisingStretchFlow,
          5,
          startedMinutesAgo: 12,
          position: 1,
        ),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();
      expect(_warmth(tester), 1);
      await tester.pump(const Duration(seconds: 3));

      expectTruthfulEnd(tester);
      expect(heard, isEmpty);
      expect(c.read(recommendationProvider).guidedPosition, 1);
      expect(
        c
            .read(sharedPreferencesProvider)
            .getInt(recommendationGuidedPositionKey),
        1,
      );
      semantics.dispose();
    });
  });

  group('Paced (internal QA runtime)', () {
    testWidgets('the bench\'s ring is named for what it is — a test '
        'session, never "Today\'s Circle"', (tester) async {
      _useS25(tester);
      final semantics = tester.ensureSemantics();
      final (app, c) = await _app(const PacedQaBenchPage());
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();
      expect(PacedQaBenchPage.ringLabel, 'Paced test session');
      expect(find.bySemanticsLabel(PacedQaBenchPage.ringLabel), findsOneWidget);
      expect(find.bySemanticsLabel("Today's Circle"), findsNothing);
      semantics.dispose();
    });

    testWidgets('leaving the foreground pauses it; coming back leaves it '
        'paused', (tester) async {
      var hidden = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PauseWhenHidden(
            onHidden: () => hidden++,
            child: const SizedBox(),
          ),
        ),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(hidden, greaterThanOrEqualTo(1));
      final before = hidden;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      // Returning never resumes it.
      expect(hidden, greaterThanOrEqualTo(before));
    });

    Future<void> pumpBody(WidgetTester tester, {required bool reduced}) =>
        tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: const Scaffold(
                body: PacedSessionBody(
                  pattern: pacedQaFixture,
                  elapsed: Duration(seconds: 2),
                  paused: false,
                ),
              ),
            ),
          ),
        );

    testWidgets('the phase, in words and seconds; with reduced motion, '
        'nothing grows or pulses', (tester) async {
      await pumpBody(tester, reduced: false);
      expect(find.text('Pace one · 2 s'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await pumpBody(tester, reduced: true);
      expect(find.text('Pace one · 2 s'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('nothing left to suggest', () {
    testWidgets('the daily question says so plainly and points to memory — '
        'it never overrides the user', (tester) async {
      final (app, c) = await _app(
        const SingleChildScrollView(child: DailyIntentionPrompt()),
      );
      addTearDown(c.dispose);
      final prefs = c.read(suggestionPreferencesProvider.notifier);
      for (final id in [
        ActivityId.moveToMusic,
        ActivityId.energisingStretchFlow,
        ActivityId.activeHouseholdTask,
        ActivityId.tidyOneSurface,
        ActivityId.gentleStretchPause,
      ]) {
        await prefs.dontSuggest(id, Intention.moreEnergy);
      }
      c.read(timeWindowChoiceProvider.notifier).choose(TimeWindow.about10);
      await tester.pumpWidget(app);
      await tester.tap(find.text('More Energy'));
      await tester.pump();

      expect(
        find.text(
          NothingFitsNote.message(Intention.moreEnergy, TimeWindow.about10),
        ),
        findsOneWidget,
      );
      expect(find.text(NothingFitsNote.review), findsOneWidget);
      expect(c.read(recommendationProvider).recommendation, isNull);
    });

    testWidgets('"Review what THIRTY remembers" opens memory on the need '
        'that has nothing left (S25 TalkBack finding)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final opened = <Uri>[];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: SingleChildScrollView(child: DailyIntentionPrompt()),
            ),
          ),
          GoRoute(
            path: '/memory',
            builder: (_, state) {
              opened.add(state.uri);
              return const Text('memory page');
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          nowProvider.overrideWithValue(_morning),
          safetyPendingAllowedProvider.overrideWithValue(false),
        ],
      );
      addTearDown(c.dispose);
      final preferences = c.read(suggestionPreferencesProvider.notifier);
      for (final id in [
        ActivityId.moveToMusic,
        ActivityId.energisingStretchFlow,
        ActivityId.activeHouseholdTask,
        ActivityId.tidyOneSurface,
        ActivityId.gentleStretchPause,
      ]) {
        await preferences.dontSuggest(id, Intention.moreEnergy);
      }
      c.read(timeWindowChoiceProvider.notifier).choose(TimeWindow.about10);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.tap(find.text('More Energy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(NothingFitsNote.review));
      await tester.pumpAndSettle();

      expect(find.text('memory page'), findsOneWidget);
      expect(opened.single.queryParameters['need'], 'moreEnergy');
    });

    testWidgets('below the fold, it brings itself into view — a tap is never '
        'answered by nothing (S25 finding)', (tester) async {
      tester.view.physicalSize = const Size(412, 420);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final (app, c) = await _app(
        SingleChildScrollView(
          child: Column(
            children: const [SizedBox(height: 300), DailyIntentionPrompt()],
          ),
        ),
      );
      addTearDown(c.dispose);
      final prefs = c.read(suggestionPreferencesProvider.notifier);
      for (final id in [
        ActivityId.moveToMusic,
        ActivityId.energisingStretchFlow,
        ActivityId.activeHouseholdTask,
        ActivityId.tidyOneSurface,
        ActivityId.gentleStretchPause,
      ]) {
        await prefs.dontSuggest(id, Intention.moreEnergy);
      }
      c.read(timeWindowChoiceProvider.notifier).choose(TimeWindow.about10);
      await tester.pumpWidget(app);
      await tester.ensureVisible(find.text('More Energy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('More Energy'));
      await tester.pumpAndSettle();

      final review = tester.getRect(find.text(NothingFitsNote.review));
      expect(review.bottom, lessThanOrEqualTo(420));
      expect(review.top, greaterThanOrEqualTo(0));
    });
  });
}
