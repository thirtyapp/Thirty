import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
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
import 'package:thirty/features/personal_circle/application/guidance_session.dart';
import 'package:thirty/features/personal_circle/application/guidance_voice.dart';
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/composed_session.dart';
import 'package:thirty/features/personal_circle/domain/spoken_cues.dart';
import 'package:thirty/features/personal_circle/presentation/keep_circle_card.dart';
import 'package:thirty/features/personal_circle/presentation/kept_circle_page.dart';
import 'package:thirty/features/personal_circle/presentation/use_today_control.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/kept_circle.dart';

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

/// A voice that only remembers what it was asked to play.
class _RecordingVoice implements GuidanceVoice {
  final said = <List<SpokenClip>>[];
  final deferred = <bool>[];
  var stops = 0;

  @override
  bool get available => true;

  @override
  Future<void> play(
    List<SpokenClip> clips, {
    bool deferToScreenReader = false,
  }) async {
    said.add(clips);
    deferred.add(deferToScreenReader);
  }

  @override
  Future<void> stop() async => stops++;
}

/// A platform player that only remembers what it was asked to play.
class _RecordingPlayer implements GuidanceAudioPlayer {
  final played = <List<String>>[];

  @override
  Future<void> play(
    List<String> assets, {
    bool deferToScreenReader = false,
  }) async => played.add(assets);

  @override
  Future<void> stop() async {}
}

/// A background session that only remembers what it was asked to show.
class _RecordingSession implements GuidanceSession {
  final shown = <GuidanceSessionStatus>[];
  final ended = <bool>[];
  void Function(GuidanceAction action)? _onAction;

  /// The notification's control, as the platform would deliver it.
  void tap(GuidanceAction action) => _onAction!(action);

  @override
  Future<void> show(GuidanceSessionStatus status) async => shown.add(status);

  @override
  Future<void> end({bool afterSpeech = false}) async => ended.add(afterSpeech);

  @override
  void listen(void Function(GuidanceAction action)? onAction) =>
      _onAction = onAction;
}

/// THIRTY leaves the screen (another app, or the display off), as Android
/// reports it.
void _goOutOfSight(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

/// …and comes back.
void _comeBack(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Map<String, Object> stored, {
  double width = 412,
  double height = 1400,
  double textScale = 1,
  bool reducedMotion = false,
  bool screenReader = false,
  _Clock? clock,
  Widget? home,
  GuidanceVoice? voice,
  List<Override> extra = const [],
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
      ...extra,
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
          accessibleNavigation: screenReader,
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

/// Ends the app with a voiced Circle still running: the conductor goes with
/// its container, and so does its once-a-second check.
Future<void> _leave(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox());
  container.dispose();
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
      expect(voice.said.single.map((c) => c.script), [
        'Next.',
        'Get it out. ${elementOf(ElementId.getItOut).instruction}',
      ]);
      // The last part is announced as the last; then the close.
      clock.now = _morning.add(const Duration(minutes: 13, seconds: 30));
      await tester.pump(const Duration(seconds: 1));
      expect(voice.said.last.first, leadLast);
      clock.now = _morning.add(const Duration(minutes: 15));
      await tester.pump(const Duration(seconds: 1));
      expect(voice.said.last, [spokenEnding]);
    });

    testWidgets('through the real providers: with the recordings bundled, '
        'the platform player gets the part’s clips (S25 finding: the voice '
        'never became available)', (tester) async {
      final clock = _Clock();
      final player = _RecordingPlayer();
      final container = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 2),
        clock: clock,
        extra: [
          bundledGuidanceVoicesProvider.overrideWithValue({ThirtyVoice.locke}),
          guidanceAudioPlayerProvider.overrideWithValue(player),
        ],
      );
      await tester.pump();
      clock.now = _morning.add(const Duration(minutes: 8));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(player.played, [
        [
          for (final clip in spokenCueFor(_plan, 2))
            clip.assetFor(ThirtyVoice.locke),
        ],
      ]);
      await _leave(tester, container);
    });

    testWidgets('spoken guidance stops at Pause, and says nothing while '
        'paused', (tester) async {
      final clock = _Clock();
      final voice = _RecordingVoice();
      await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 0),
        clock: clock,
        voice: voice,
      );
      expect(voice.said, hasLength(1));
      expect(voice.said.single, spokenCueFor(_plan, 0));
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      expect(voice.stops, 1);
      clock.now = _morning.add(const Duration(minutes: 20));
      await tester.pump(const Duration(seconds: 1));
      expect(voice.said, hasLength(1));
      // Paused, the parts hold still: nothing moves on while the user is
      // away from it.
      expect(find.text('Stand and reach'), findsOneWidget);
    });

    testWidgets('in front, the voice defers to a screen reader (decided by '
        'the platform from the screen reader itself, not Flutter’s '
        'accessibleNavigation — S25 finding) — never two voices at once', (
      tester,
    ) async {
      final clock = _Clock();
      final voice = _RecordingVoice();
      final container = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 2),
        clock: clock,
        voice: voice,
        screenReader: true,
      );
      clock.now = _morning.add(const Duration(minutes: 8));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('Get it out'), findsOneWidget);
      // Flutter's flag alone silences nothing: on the S25 it is true for an
      // unrelated accessibility service.
      expect(voice.said, [spokenCueFor(_plan, 2)]);
      expect(voice.deferred, [isTrue]);
      await _leave(tester, container);
    });

    test('this build bundles the four production voices, each complete: '
        'exactly the 42 manifest clips and its own preview per voice, '
        'nothing stale, nothing else', () async {
      expect(
        await bundledGuidanceVoices(rootBundle),
        ThirtyVoice.values.toSet(),
      );
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final guidance = manifest
          .listAssets()
          .where((a) => a.startsWith('$spokenGuidanceAssetDir/'))
          .toSet();
      expect(guidance, {
        for (final voice in ThirtyVoice.values) ...[
          for (final clip in spokenGuidanceManifest) clip.assetFor(voice),
          spokenPreviewFor(voice).assetFor(voice),
        ],
      });
      expect(guidance, hasLength(4 * 43));
    });

    test('a voice is all or nothing: one missing clip, or one recorded for '
        'an older script, silences that voice and no other', () {
      final all = {
        for (final voice in ThirtyVoice.values) ...[
          for (final clip in spokenGuidanceManifest) clip.assetFor(voice),
          spokenPreviewFor(voice).assetFor(voice),
        ],
      };
      expect(completeGuidanceVoices(all), ThirtyVoice.values.toSet());
      final missing = {...all}
        ..remove(spokenEnding.assetFor(ThirtyVoice.heather));
      expect(completeGuidanceVoices(missing), {
        ThirtyVoice.locke,
        ThirtyVoice.milo,
        ThirtyVoice.brittney,
      });
      final stale = {...all}
        ..remove(leadNext.assetFor(ThirtyVoice.milo))
        ..add('${ThirtyVoice.milo.assetDir}/lead_next_00000000.m4a');
      expect(completeGuidanceVoices(stale), isNot(contains(ThirtyVoice.milo)));
      final noPreview = {...all}
        ..remove(
          spokenPreviewFor(ThirtyVoice.locke).assetFor(ThirtyVoice.locke),
        );
      expect(
        completeGuidanceVoices(noPreview),
        isNot(contains(ThirtyVoice.locke)),
      );
      expect(completeGuidanceVoices(const {}), isEmpty);
    });

    test('voice identities are stable and neutral — never gender', () {
      expect(ThirtyVoice.values.map((v) => v.id), [
        'voice_locke_v1',
        'voice_heather_v1',
        'voice_milo_v1',
        'voice_brittney_v1',
      ]);
      expect(ThirtyVoice.values.map((v) => v.label), [
        'Locke',
        'Heather',
        'Milo',
        'Brittney',
      ]);
      for (final voice in ThirtyVoice.values) {
        expect(voice.id, isNot(matches(RegExp('male|female|man|woman'))));
        expect(voice.assetDir, '$spokenGuidanceAssetDir/${voice.id}');
      }
    });

    test('without a bundled voice the voice is silent', () {
      final container = ProviderContainer(
        overrides: [bundledGuidanceVoicesProvider.overrideWithValue(const {})],
      );
      addTearDown(container.dispose);
      expect(container.read(guidanceVoiceProvider).available, isFalse);
      expect(container.read(spokenGuidanceAvailableProvider), isFalse);
    });

    test('with every recording bundled the voice plays them — unless the '
        'user turned it off', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          bundledGuidanceVoicesProvider.overrideWithValue({ThirtyVoice.locke}),
          premiumEntitlementProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(guidanceVoiceProvider),
        isA<BundledGuidanceVoice>(),
      );
      container.read(spokenGuidanceEnabledProvider.notifier).set(false);
      expect(container.read(guidanceVoiceProvider).available, isFalse);
      expect(prefs.getBool(spokenGuidanceEnabledKey), isFalse);
    });

    testWidgets('skipping a part skips the parts that build on it, and the '
        'sheet says so', (tester) async {
      final clock = _Clock();
      final container = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 2),
        clock: clock,
      );
      clock.now = _morning.add(const Duration(minutes: 8));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Get it out'), findsOneWidget);
      await tester.tap(find.text(ComposedCopy.skip));
      await tester.pumpAndSettle();
      expect(
        find.text(ComposedCopy.skipTodayDetailFor(['Choose one thing'])),
        findsOneWidget,
      );
      await tester.tap(find.text(ComposedCopy.skipToday));
      await tester.pumpAndSettle();
      final state = container.read(recommendationProvider);
      // "Look over what you wrote" never follows a skipped "Get it out".
      expect(state.partMomentAt(clock.now)!.finished, isTrue);
      expect(state.skipped, [ElementId.getItOut, ElementId.chooseOne]);
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

  group('out of sight — the background session (ADR-023 §6)', () {
    testWidgets('Start speaks "First." and opens the session, which keeps the '
        'device awake for the rest of the Circle', (tester) async {
      final clock = _Clock();
      final voice = _RecordingVoice();
      final session = _RecordingSession();
      final container = await _pump(
        tester,
        _today(),
        clock: clock,
        voice: voice,
        extra: [guidanceSessionProvider.overrideWithValue(session)],
      );
      expect(session.shown, isEmpty);
      expect(voice.said, isEmpty);
      container.read(recommendationProvider.notifier).start();
      await tester.pump();
      expect(voice.said, [spokenCueFor(_plan, 0)]);
      expect(session.shown.single.part, 'Stand and reach');
      expect(session.shown.single.paused, isFalse);
      expect(
        session.shown.single.keepAwakeFor,
        Duration(minutes: _plan.minutes) + const Duration(minutes: 1),
      );
      await _leave(tester, container);
      expect(session.ended, [false]);
    });

    testWidgets('out of sight, the next part is spoken on time and once — by '
        'the voice, not a screen reader, since nothing is on screen — and '
        'the return shows the right part without saying it again', (
      tester,
    ) async {
      final clock = _Clock();
      final voice = _RecordingVoice();
      final session = _RecordingSession();
      final container = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 2),
        clock: clock,
        voice: voice,
        screenReader: true,
        extra: [guidanceSessionProvider.overrideWithValue(session)],
      );
      // A first look into a Circle under way: the session, not a cue.
      expect(voice.said, isEmpty);
      expect(session.shown.single.part, 'Clear one corner');
      _goOutOfSight(tester);
      clock.now = _morning.add(const Duration(minutes: 6, seconds: 59));
      await tester.pump(const Duration(seconds: 1));
      expect(voice.said, isEmpty);
      clock.now = _morning.add(const Duration(minutes: 7));
      await tester.pump(const Duration(seconds: 1));
      expect(voice.said, [spokenCueFor(_plan, 2)]);
      expect(voice.deferred, [isFalse]);
      expect(session.shown.last.part, 'Get it out');
      expect(
        session.shown.last.keepAwakeFor,
        const Duration(minutes: 7) + const Duration(minutes: 1),
      );
      for (var i = 0; i < 5; i++) {
        clock.now = clock.now.add(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
      }
      _comeBack(tester);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(voice.said, hasLength(1));
      expect(find.text('Get it out'), findsOneWidget);
      expect(find.text('Part 3 of 4 · next: Choose one thing'), findsOneWidget);
      await _leave(tester, container);
    });

    testWidgets('the notification’s Pause holds the Circle’s time and lets '
        'the device sleep; Resume carries on where it was; Next moves '
        'exactly once', (tester) async {
      final clock = _Clock();
      final voice = _RecordingVoice();
      final session = _RecordingSession();
      final container = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 2),
        clock: clock,
        voice: voice,
        extra: [guidanceSessionProvider.overrideWithValue(session)],
      );
      _goOutOfSight(tester);
      RecommendationState state() => container.read(recommendationProvider);
      final before = state().partMomentAt(clock.now)!;
      session.tap(GuidanceAction.pause);
      await tester.pump();
      expect(state().isPaused, isTrue);
      expect(session.shown.last.paused, isTrue);
      expect(session.shown.last.keepAwakeFor, Duration.zero);
      // Paused for half an hour: nothing moves, nothing is said.
      clock.now = _morning.add(const Duration(minutes: 30));
      await tester.pump(const Duration(seconds: 1));
      expect(voice.said, isEmpty);
      expect(state().partMomentAt(clock.now)!.partElapsed, before.partElapsed);
      session.tap(GuidanceAction.resume);
      await tester.pump();
      expect(state().isPaused, isFalse);
      expect(session.shown.last.paused, isFalse);
      // 7 more minutes of "Clear one corner" before "Get it out".
      clock.now = clock.now.add(const Duration(minutes: 6, seconds: 59));
      await tester.pump(const Duration(seconds: 1));
      expect(voice.said, isEmpty);
      clock.now = clock.now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(voice.said, [spokenCueFor(_plan, 2)]);
      session.tap(GuidanceAction.next);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(state().partMomentAt(clock.now)!.position, 3);
      expect(voice.said, [spokenCueFor(_plan, 2), spokenCueFor(_plan, 3)]);
      expect(state().skipped, isEmpty);
      await _leave(tester, container);
    });

    testWidgets('after the last part the ending is spoken, once, and the '
        'session ends once it has been said', (tester) async {
      final clock = _Clock();
      final voice = _RecordingVoice();
      final session = _RecordingSession();
      await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 14),
        clock: clock,
        voice: voice,
        extra: [guidanceSessionProvider.overrideWithValue(session)],
      );
      _goOutOfSight(tester);
      clock.now = _morning.add(const Duration(minutes: 2));
      await tester.pump(const Duration(seconds: 1));
      expect(voice.said, [
        [spokenEnding],
      ]);
      expect(session.ended, [true]);
      clock.now = _morning.add(const Duration(minutes: 5));
      await tester.pump(const Duration(seconds: 1));
      expect(voice.said, hasLength(1));
      expect(session.ended, [true]);
    });

    testWidgets('a first look into a Circle already past its last part says '
        'nothing — not even the ending', (tester) async {
      final voice = _RecordingVoice();
      final session = _RecordingSession();
      await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 20),
        voice: voice,
        extra: [guidanceSessionProvider.overrideWithValue(session)],
      );
      await tester.pump(const Duration(seconds: 1));
      expect(voice.said, isEmpty);
      expect(session.shown, isEmpty);
    });

    testWidgets('Close ends the session at once, and so does turning the voice '
        'off', (tester) async {
      final session = _RecordingSession();
      final container = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 2),
        extra: [
          bundledGuidanceVoicesProvider.overrideWithValue({ThirtyVoice.locke}),
          guidanceAudioPlayerProvider.overrideWithValue(_RecordingPlayer()),
          guidanceSessionProvider.overrideWithValue(session),
        ],
      );
      expect(session.shown, hasLength(1));
      container.read(spokenGuidanceEnabledProvider.notifier).set(false);
      await tester.pump();
      expect(session.ended, [false]);
      container.read(spokenGuidanceEnabledProvider.notifier).set(true);
      await tester.pump();
      expect(session.shown, hasLength(2));
      container.read(recommendationProvider.notifier).close();
      await tester.pump();
      expect(session.ended, [false, false]);
    });

    testWidgets('without the voice there is no session at all', (tester) async {
      final session = _RecordingSession();
      final container = await _pump(
        tester,
        _today(),
        extra: [guidanceSessionProvider.overrideWithValue(session)],
      );
      container.read(recommendationProvider.notifier).start();
      await tester.pump(const Duration(seconds: 3));
      expect(session.shown, isEmpty);
      expect(session.ended, isEmpty);
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
      final kept = container.read(keptCirclesProvider).kept.single;
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
        initialLocation: KeptCirclePage.locationFor('kept-1'),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('TODAY')),
          ),
          GoRoute(
            path: KeptCirclePage.pathPattern,
            builder: (_, state) =>
                KeptCirclePage(keptId: state.pathParameters['id']!),
          ),
        ],
      );
      SharedPreferences.setMockInitialValues({
        keptCirclesKey: jsonEncode(keptCirclesRecord([kept])),
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
