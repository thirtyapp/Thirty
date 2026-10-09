import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';
import 'package:thirty/features/home/presentation/widgets/daily_intention_prompt.dart';
import 'package:thirty/features/home/presentation/widgets/feedback_acknowledgement.dart';

/// V2 Phase B on screen: the time choice, the personal reason, "Not this
/// one today" and the feedback acknowledgement.

final _now = DateTime(2026, 11, 20, 9);
const _day = '2026-11-20';

Future<(Widget, ProviderContainer)> _app(
  Widget home, {
  Map<String, Object> stored = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    firstBreathLastPlayedDateKey: _day,
    ...stored,
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_now),
      eventClockProvider.overrideWithValue(() => _now),
      safetyPendingAllowedProvider.overrideWithValue(false),
    ],
  );
  return (
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: SingleChildScrollView(child: home)),
      ),
    ),
    container,
  );
}

/// Today's Circle, already offered.
Map<String, Object> _offered(
  Intention need,
  ActivityId activity, {
  RecommendationReason reason = RecommendationReason.bestFit,
  int? minutes,
  String? status,
}) => {
  recommendationDayKey: _day,
  recommendationIntentionKey: need.name,
  recommendationActivityIdKey: activity.name,
  recommendationTimeWindowKey: TimeWindow.about20.name,
  recommendationOfferedMinutesKey:
      minutes ?? activityTypicalMinutes(activity).clamp(0, 20),
  recommendationReasonKey: reason.name,
  recommendationStatusKey: ?status,
  if (status != null) recommendationStartedAtKey: _now.toIso8601String(),
};

void main() {
  group('Time you have', () {
    testWidgets('with the real font at S25 width, three quiet segments at '
        'normal and 130% text', (tester) async {
      final inter = FontLoader('Inter')
        ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'));
      await inter.load();
      tester.view.physicalSize = const Size(411, 891);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      for (final scale in [1.0, 1.3]) {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        final (app, c) = await _app(const DailyIntentionPrompt());
        addTearDown(c.dispose);
        await tester.pumpWidget(app);
        for (final label in ['10 min', '20 min', '30 min']) {
          expect(find.text(label), findsOneWidget, reason: '$label at $scale');
        }
        // The 48pt touch target holds, however light it looks.
        expect(
          tester.getSize(find.byType(SegmentedButton<TimeWindow>)).height,
          greaterThanOrEqualTo(48),
        );
      }
    });

    testWidgets('already set to ≈ 20, announced by its meaning, and the need '
        'stays the only required tap', (tester) async {
      final semantics = tester.ensureSemantics();
      final (app, c) = await _app(const DailyIntentionPrompt());
      addTearDown(c.dispose);
      await tester.pumpWidget(app);

      expect(c.read(timeWindowChoiceProvider), TimeWindow.about20);
      for (final meaning in [
        'About 10 minutes',
        'About 20 minutes',
        'Up to 30 minutes',
      ]) {
        expect(find.bySemanticsLabel(meaning), findsOneWidget);
      }

      await tester.tap(find.text('More Energy'));
      await tester.pump();
      final r = c.read(recommendationProvider).recommendation!;
      expect(r.timeWindow, TimeWindow.about20);
      semantics.dispose();
    });

    testWidgets('choosing ≈ 10 first gives an offer that fits it', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final (app, c) = await _app(const DailyIntentionPrompt());
      addTearDown(c.dispose);
      await tester.pumpWidget(app);

      // By its meaning: the same in three segments or, when they don't
      // fit, full-width rows.
      await tester.tap(find.bySemanticsLabel('About 10 minutes'));
      await tester.pump();
      expect(c.read(timeWindowChoiceProvider), TimeWindow.about10);
      await tester.tap(find.text('More Energy'));
      await tester.pump();
      final r = c.read(recommendationProvider).recommendation!;
      expect(r.timeWindow, TimeWindow.about10);
      expect(r.offeredMinutes, lessThanOrEqualTo(10));
      semantics.dispose();
    });
  });

  group('the Today card', () {
    testWidgets('a personal reason takes the line; the activity\'s own '
        'reason stays in its how-to', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final (app, c) = await _app(
        const CircleHero(),
        stored: _offered(
          Intention.clearerHead,
          ActivityId.quietReading,
          reason: RecommendationReason.usefulHere,
        ),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();

      final own = activityReasonFor(
        Intention.clearerHead,
        ActivityId.quietReading,
      );
      expect(find.text('You found this useful before.'), findsOneWidget);
      expect(find.text(own), findsNothing);

      await tester.tap(find.bySemanticsLabel('Quiet reading'));
      await tester.pumpAndSettle();
      expect(find.text(own), findsOneWidget);
    });

    testWidgets('the card and the ring use today\'s length', (tester) async {
      final semantics = tester.ensureSemantics();
      final (app, c) = await _app(
        const CircleHero(),
        stored: _offered(
          Intention.moreEnergy,
          ActivityId.thirtyMinuteWalk,
          minutes: 20,
          status: 'started',
        ),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();
      expect(find.text('TODAY  ·  20 MIN'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel("Today's Circle")),
        matchesSemantics(
          label: "Today's Circle",
          value: 'Circle in progress. 0 of 20 minutes.',
        ),
      );
      semantics.dispose();
    });
  });

  group('Not this one today', () {
    Future<void> openGuide(WidgetTester tester, String activity) async {
      await tester.tap(find.bySemanticsLabel(activity));
      await tester.pumpAndSettle();
    }

    testWidgets('from the how-to, three reasons for an outdoor activity, '
        'one replacement, and then it is gone', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final (app, c) = await _app(
        const CircleHero(),
        stored: _offered(Intention.gentlerPace, ActivityId.easyWalk),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();

      // Visible on the card, quietly: the row says the swap lives in its
      // how-to.
      expect(find.textContaining('Not this one?'), findsOneWidget);

      await openGuide(tester, 'Easy walk');
      await tester.tap(find.text('Not this one today'));
      await tester.pumpAndSettle();
      expect(find.text('What’s in the way today?'), findsOneWidget);
      for (final reason in [
        'Can’t go outside',
        'Too much for today',
        'Not feeling this one',
      ]) {
        expect(find.text(reason), findsOneWidget);
      }

      await tester.tap(find.text('Can’t go outside'));
      await tester.pumpAndSettle();
      final r = c.read(recommendationProvider).recommendation!;
      expect(r.activityId, isNot(ActivityId.easyWalk));
      expect(find.text('An indoor one instead.'), findsOneWidget);
      // One a day: the card no longer offers it…
      expect(find.textContaining('Not this one?'), findsNothing);
      expect(find.text('How to do it'), findsOneWidget);

      // …and neither does the how-to.
      await openGuide(tester, r.activity);
      expect(find.text('Not this one today'), findsNothing);
    });

    testWidgets('TalkBack hears the same: the activity, then what the row '
        'opens', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      final (app, c) = await _app(
        const CircleHero(),
        stored: _offered(Intention.gentlerPace, ActivityId.easyWalk),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Easy walk')),
        matchesSemantics(
          label: 'Easy walk',
          hint: 'How to do it, or not this one today',
          isButton: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('"Can\'t go outside" only when today\'s activity is '
        'outdoors', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final (app, c) = await _app(
        const CircleHero(),
        stored: _offered(Intention.clearerHead, ActivityId.writeItDown),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();

      await openGuide(tester, 'Write it down');
      await tester.tap(find.text('Not this one today'));
      await tester.pumpAndSettle();
      expect(find.text('Can’t go outside'), findsNothing);
      expect(find.text('Too much for today'), findsOneWidget);
      expect(find.text('Not feeling this one'), findsOneWidget);
    });

    testWidgets('never once the Circle has started', (tester) async {
      final (app, c) = await _app(
        const CircleHero(),
        stored: _offered(
          Intention.gentlerPace,
          ActivityId.easyWalk,
          status: 'started',
        ),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(app);
      await tester.pump();

      // Once started, Phase A's row: no cue, and no swap.
      expect(find.textContaining('Not this one?'), findsNothing);
      expect(find.text('How to do it'), findsNothing);
      await openGuide(tester, 'Easy walk');
      expect(find.text('Not this one today'), findsNothing);
    });
  });

  group('the feedback acknowledgement', () {
    RecommendationState closed({
      CircleAttemptResponse? attempt,
      CircleUsefulnessResponse? usefulness,
    }) => RecommendationState(
      recommendation: Recommendation(
        intent: 'More Energy',
        activity: 'Move to music',
        duration: '10 minutes',
        why: '',
        category: activityCategory(ActivityId.moveToMusic),
        activityId: ActivityId.moveToMusic,
        intention: Intention.moreEnergy,
        circleId: _day,
        catalogVersion: catalogVersion,
        offeredMinutes: 10,
      ),
      status: RecommendationStatus.closed,
      startedAt: _now,
      closedAt: _now,
      attemptResponse: attempt,
      usefulnessResponse: usefulness,
    );

    test('says what each answer changes — and nothing before one', () {
      expect(feedbackAcknowledgement(closed()), isNull);
      expect(
        feedbackAcknowledgement(closed(attempt: CircleAttemptResponse.yes)),
        isNull,
      );
      expect(
        feedbackAcknowledgement(
          closed(
            attempt: CircleAttemptResponse.yes,
            usefulness: CircleUsefulnessResponse.veryUseful,
          ),
        ),
        'Thanks — you’ll see this again now and then.',
      );
      expect(
        feedbackAcknowledgement(
          closed(
            attempt: CircleAttemptResponse.aLittle,
            usefulness: CircleUsefulnessResponse.notUseful,
          ),
        ),
        'Thanks — THIRTY will rest this one for a while.',
      );
      expect(
        feedbackAcknowledgement(
          closed(attempt: CircleAttemptResponse.notToday),
        ),
        'No problem — that won’t count against it.',
      );
    });
  });
}
