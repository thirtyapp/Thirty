import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/home/presentation/memory_page.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';
import 'package:thirty/features/home/presentation/widgets/circle_session_card.dart';
import 'package:thirty/features/personal_circle/application/guidance_voice.dart';
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/composed_session.dart';
import 'package:thirty/features/personal_circle/domain/spoken_cues.dart';
import 'package:thirty/features/personal_circle/presentation/keep_circle_card.dart';
import 'package:thirty/features/personal_circle/presentation/kept_circle_page.dart';
import 'package:thirty/features/personal_circle/presentation/use_today_control.dart';
import 'package:thirty/features/toolkit/application/toolkit_provider.dart';
import 'package:thirty/features/toolkit/domain/toolkit_model.dart';

/// V2 Phase D2 (ADR-023 §4–§8) — the composed Circle on Today, its running
/// body, Skip and "Leave it out", keeping a Circle, a kept Circle's page,
/// and Memory's way back — with TalkBack labels, enlarged text and reduced
/// motion.

final _morning = DateTime(2026, 11, 20, 9);
const _day = '2026-11-20';

final _plan = CirclePlan(const [
  CirclePart(ElementId.standAndReach, 1),
  CirclePart(ElementId.clearCorner, 8),
  CirclePart(ElementId.getItOut, 6),
  CirclePart(ElementId.chooseOne, 1),
]);

Map<String, Object> _today({
  String status = 'notStarted',
  CompositionBasis basis = CompositionBasis.foundUseful,
  int? startedMinutesAgo,
}) => {
  firstBreathLastPlayedDateKey: _day,
  recommendationDayKey: _day,
  recommendationIntentionKey: 'clearerHead',
  recommendationActivityIdKey: 'tidyOneSurface',
  recommendationTimeWindowKey: 'about20',
  recommendationOfferedMinutesKey: _plan.minutes,
  recommendationReasonKey: 'personalCircle',
  recommendationStatusKey: status,
  if (status != 'notStarted')
    recommendationStartedAtKey: _morning
        .subtract(Duration(minutes: startedMinutesAgo ?? 0))
        .toIso8601String(),
  if (status == 'closed') recommendationClosedAtKey: _morning.toIso8601String(),
  recommendationComposedKey: jsonEncode(
    ComposedSession(plan: _plan, basis: basis).toJson(),
  ),
};

class _Clock {
  DateTime now = _morning;
}

/// A voice that only remembers what it was asked to say.
class _RecordingVoice implements GuidanceVoice {
  final said = <String>[];

  @override
  bool get available => true;

  @override
  Future<void> say(String text) async => said.add(text);

  @override
  Future<void> stop() async {}
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Map<String, Object> stored, {
  double width = 412,
  double height = 1400,
  double textScale = 1,
  bool reducedMotion = false,
  _Clock? clock,
  Widget? home,
  GuidanceVoice? voice,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  final time = clock ?? _Clock();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_morning),
      eventClockProvider.overrideWithValue(() => time.now),
      safetyPendingAllowedProvider.overrideWithValue(false),
      premiumEntitlementProvider.overrideWithValue(true),
      if (voice != null) guidanceVoiceProvider.overrideWithValue(voice),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reducedMotion,
        ),
        child: MaterialApp(
          theme: AppTheme.light,
          home: home ?? const Scaffold(body: CircleHero()),
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  group('before Start', () {
    testWidgets('one Circle: "Your Circle", its parts in order, and only '
        'what is true about it', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, _today(), width: 900);
      expect(find.text('YOUR CIRCLE  ·  16 MIN'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Your Circle, about 16 minutes'),
        findsOneWidget,
      );
      expect(find.text(_plan.substanceLine), findsOneWidget);
      expect(_plan.substanceLine, 'Clear one corner · Get it out');
      expect(
        find.text(
          'Built from things you’ve found useful, to fit your 20 minutes.',
        ),
        findsOneWidget,
      );
      expect(find.text(ComposedCopy.greetingSubline), findsOneWidget);
      expect(find.text('See the parts · Not this one?'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a sparse start claims nothing personal', (tester) async {
      await _pump(tester, _today(basis: CompositionBasis.sized), width: 900);
      expect(
        find.text('Small parts, one after another, to fit your 20 minutes.'),
        findsOneWidget,
      );
      expect(find.textContaining('found useful'), findsNothing);
    });
  });

  group('running', () {
    testWidgets('the part on show by name, where it sits, what comes next — '
        'its instruction and time in the card, read out as one', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, _today(status: 'started', startedMinutesAgo: 2));
      final card = tester.widget<CircleSessionCard>(
        find.byType(CircleSessionCard),
      );
      expect(card.body, SessionBody.composed);
      expect(card.partMoment!.position, 1);
      expect(find.text('Clear one corner'), findsOneWidget);
      expect(find.text('Part 2 of 4 · next: Get it out'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp(r'^Part 2 of 4\. Clear one corner\. One corner of a desk'),
        ),
        findsOneWidget,
      );
      for (final label in [ComposedCopy.skip, 'Next']) {
        final size = tester.getSize(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byWidgetPredicate(
                  (w) => w is ButtonStyleButton || w is ThirtyButton,
                ),
              )
              .first,
        );
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
      }
      expect(find.byTooltip('Pause'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('THIRTY holds the structure: when a part’s time is up, the '
        'next one takes over by itself', (tester) async {
      final clock = _Clock();
      await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 2),
        clock: clock,
      );
      expect(find.text('Clear one corner'), findsOneWidget);
      clock.now = _morning.add(const Duration(minutes: 8));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Get it out'), findsOneWidget);
      expect(find.text('Part 3 of 4 · next: Choose one thing'), findsOneWidget);
    });

    testWidgets('Skip asks what is meant: skip it today — the next part '
        'begins, and nothing is recorded against it', (tester) async {
      final container = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 2),
      );
      await tester.tap(find.text(ComposedCopy.skip));
      await tester.pumpAndSettle();
      expect(find.text(ComposedCopy.skipTitle), findsOneWidget);
      expect(find.text(ComposedCopy.skipTodayDetail), findsOneWidget);
      await tester.tap(find.text(ComposedCopy.skipToday));
      await tester.pumpAndSettle();
      final state = container.read(recommendationProvider);
      expect(state.skipped, [ElementId.clearCorner]);
      expect(find.text('Get it out'), findsOneWidget);
      expect(
        container.read(suggestionPreferencesProvider).elementsLeftOut,
        isEmpty,
      );
    });

    testWidgets('…or leave it out next time — an explicit preference', (
      tester,
    ) async {
      final container = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 2),
      );
      await tester.tap(find.text(ComposedCopy.skip));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ComposedCopy.leaveOut));
      await tester.pumpAndSettle();
      expect(
        container
            .read(suggestionPreferencesProvider)
            .isLeftOut(ElementId.clearCorner),
        isTrue,
      );
    });

    testWidgets('the Skip sheet never overflows at 200 % text on a narrow '
        'phone (S25 finding at 130 %)', (tester) async {
      await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 2),
        width: 320,
        height: 640,
        textScale: 2,
      );
      await tester.ensureVisible(find.text(ComposedCopy.skip));
      await tester.tap(find.text(ComposedCopy.skip));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text(ComposedCopy.keepGoing).last,
        100,
        scrollable: find.byType(Scrollable).last,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Keep going changes nothing', (tester) async {
      final container = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 2),
      );
      await tester.tap(find.text(ComposedCopy.skip));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ComposedCopy.keepGoing));
      await tester.pumpAndSettle();
      expect(container.read(recommendationProvider).skipped, isEmpty);
      expect(find.text('Clear one corner'), findsOneWidget);
    });

    testWidgets('past the last part: the ending, and Close leads', (
      tester,
    ) async {
      await _pump(tester, _today(status: 'started', startedMinutesAgo: 2));
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      expect(find.text('To finish'), findsOneWidget);
      expect(find.text(ComposedCopy.ending), findsOneWidget);
      final close = tester.widget<ThirtyButton>(
        find.widgetWithText(ThirtyButton, 'Close Circle'),
      );
      expect(close.variant, ThirtyButtonVariant.primary);
    });

    for (final (label, scale, width) in [
      ('130% text', 1.3, 412.0),
      ('200% text on a narrow phone', 2.0, 320.0),
    ]) {
      testWidgets('nothing overflows at $label', (tester) async {
        await _pump(
          tester,
          _today(status: 'started', startedMinutesAgo: 2),
          width: width,
          height: 2400,
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Clear one corner'), findsOneWidget);
      });
    }

    testWidgets('spoken guidance: when a part begins, the voice says its cue '
        '— never on a first look into a Circle already under way', (
      tester,
    ) async {
      final clock = _Clock();
      final voice = _RecordingVoice();
      await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 2),
        clock: clock,
        voice: voice,
      );
      await tester.pump();
      expect(voice.said, isEmpty);
      clock.now = _morning.add(const Duration(minutes: 8));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(voice.said, [spokenCueFor(_plan, 2)]);
      expect(voice.said.single, startsWith('Next: Get it out.'));
    });

    test('the silent voice is the default: nothing ships until a voice is '
        'approved', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(guidanceVoiceProvider).available, isFalse);
    });

    testWidgets('reduced motion: the same parts, no movement needed', (
      tester,
    ) async {
      final clock = _Clock();
      await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 2),
        reducedMotion: true,
        clock: clock,
      );
      clock.now = _morning.add(const Duration(minutes: 8));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Get it out'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('owned', () {
    testWidgets('after Close, a composed Circle can be kept — once', (
      tester,
    ) async {
      final container = await _pump(
        tester,
        _today(status: 'closed', startedMinutesAgo: 20),
        home: const Scaffold(body: KeepCircleCard()),
      );
      expect(find.text(KeepCircleCopy.offer), findsOneWidget);
      await tester.tap(find.text(KeepCircleCopy.action));
      await tester.pumpAndSettle();
      final kept = container.read(toolkitProvider).kept.single;
      expect(kept.plan, _plan);
      expect(kept.name, 'My clear-head Circle');
      expect(find.text(KeepCircleCopy.kept(kept.name)), findsOneWidget);
      expect(find.text(KeepCircleCopy.action), findsNothing);
    });

    testWidgets('never before Close', (tester) async {
      await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 2),
        home: const Scaffold(body: KeepCircleCard()),
      );
      expect(find.text(KeepCircleCopy.offer), findsNothing);
    });

    testWidgets('a kept Circle’s page: its parts, Use it today, and the '
        'user’s own controls', (tester) async {
      final kept = KeptCircle(
        id: 'kept-1',
        name: 'My clear-head Circle',
        need: Intention.clearerHead,
        plan: _plan,
        createdAt: _morning.subtract(const Duration(days: 3)),
      );
      tester.view.physicalSize = const Size(412, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: '/toolkit/kept/kept-1',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('TODAY')),
          ),
          GoRoute(
            path: '/toolkit/kept/:id',
            builder: (_, state) =>
                KeptCirclePage(keptId: state.pathParameters['id']!),
          ),
        ],
      );
      SharedPreferences.setMockInitialValues({
        toolkitStateKey: jsonEncode(ToolkitState(kept: [kept]).toJson()),
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          nowProvider.overrideWithValue(_morning),
          eventClockProvider.overrideWithValue(() => _morning),
          safetyPendingAllowedProvider.overrideWithValue(false),
          premiumEntitlementProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('My clear-head Circle'), findsOneWidget);
      expect(find.text(keptCircleLine(kept)), findsOneWidget);
      expect(find.text('Clear one corner'), findsOneWidget);
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
      // Free: owned things are the user's to use.
      await tester.tap(find.text(UseTodayCopy.action));
      await tester.pumpAndSettle();
      expect(find.text('TODAY'), findsOneWidget);
      final today = container.read(recommendationProvider).recommendation!;
      expect(today.composed!.keptCircleId, 'kept-1');
      expect(today.reason.name, 'ownChoice');
    });

    testWidgets('Memory shows what was left out, and puts it back', (
      tester,
    ) async {
      final container = await _pump(tester, {
        suggestionPreferencesKey: jsonEncode(
          SuggestionPreferences(
            elementsLeftOut: [
              ElementLeftOut(
                element: ElementId.sitAMinute,
                since: _morning.subtract(const Duration(days: 2)),
              ),
            ],
          ).toJson(),
        ),
      }, home: const MemoryPage());
      await tester.scrollUntilVisible(
        find.text('Sit for a minute'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('LEFT OUT OF YOUR CIRCLES'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Put it back: Sit for a minute'),
        findsOneWidget,
      );
      await tester.tap(find.text('Put it back'));
      await tester.pumpAndSettle();
      expect(
        container.read(suggestionPreferencesProvider).elementsLeftOut,
        isEmpty,
      );
      expect(find.text('Sit for a minute'), findsNothing);
    });
  });
}
