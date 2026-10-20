import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';
import 'package:thirty/features/personal_circle/application/guidance_session.dart';
import 'package:thirty/features/personal_circle/application/guidance_voice.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/composed_session.dart';
import 'package:thirty/features/personal_circle/domain/spoken_cues.dart';
import 'package:thirty/features/settings/presentation/widgets/you_preferences_card.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/kept_circle.dart';

/// V2 Phase D2 — the guided-voice entitlement correction (founder decision,
/// 2026-10-12): THIRTY's own voice is a Premium service layer; accessibility
/// is not. A kept Circle on Free runs complete — on screen, with its timing,
/// its controls and every screen-reader announcement — without THIRTY's
/// voice and without the background service.

final _morning = DateTime(2026, 11, 20, 9);
const _day = '2026-11-20';

final _plan = CirclePlan(const [
  CirclePart(ElementId.standAndReach, 1),
  CirclePart(ElementId.clearCorner, 8),
  CirclePart(ElementId.getItOut, 6),
  CirclePart(ElementId.chooseOne, 1),
]);

final _keptCircle = KeptCircle(
  id: 'kept-1',
  name: 'My clear-head Circle',
  need: Intention.clearerHead,
  plan: _plan,
  createdAt: _morning.subtract(const Duration(days: 30)),
);

/// Today: the kept Circle the user chose with "Use it today".
Map<String, Object> _keptToday({
  String status = 'notStarted',
  int startedMinutesAgo = 0,
  String? voice,
}) => {
  firstBreathLastPlayedDateKey: _day,
  recommendationDayKey: _day,
  recommendationIntentionKey: 'clearerHead',
  recommendationActivityIdKey: 'tidyOneSurface',
  recommendationTimeWindowKey: 'about20',
  recommendationOfferedMinutesKey: _plan.minutes,
  recommendationReasonKey: 'ownChoice',
  recommendationStatusKey: status,
  if (status != 'notStarted')
    recommendationStartedAtKey: _morning
        .subtract(Duration(minutes: startedMinutesAgo))
        .toIso8601String(),
  recommendationComposedKey: jsonEncode(
    ComposedSession(
      plan: _plan,
      keptCircleId: _keptCircle.id,
      keptName: _keptCircle.name,
    ).toJson(),
  ),
  keptCirclesKey: jsonEncode(keptCirclesRecord([_keptCircle])),
  thirtyVoiceKey: ?voice,
};

class _Clock {
  DateTime now = _morning;
}

/// The entitlement, changeable mid-test: a lapse, a resubscription.
class _Entitled extends Notifier<bool> {
  _Entitled(this._initial);

  final bool _initial;

  @override
  bool build() => _initial;

  void set(bool value) => state = value;
}

/// The platform player: what THIRTY's voice actually played.
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

/// The background service: what it was asked to show.
class _RecordingSession implements GuidanceSession {
  final shown = <GuidanceSessionStatus>[];
  final ended = <bool>[];

  @override
  Future<void> show(GuidanceSessionStatus status) async => shown.add(status);

  @override
  Future<void> end({bool afterSpeech = false}) async => ended.add(afterSpeech);

  @override
  void listen(void Function(GuidanceAction action)? onAction) {}
}

class _Rig {
  _Rig(this.container, this.entitled, this.player, this.session, this.clock);

  final ProviderContainer container;
  final NotifierProvider<_Entitled, bool> entitled;
  final _RecordingPlayer player;
  final _RecordingSession session;
  final _Clock clock;

  void setEntitled(bool value) => container.read(entitled.notifier).set(value);

  Future<void> advanceTo(WidgetTester tester, Duration sinceMorning) async {
    clock.now = _morning.add(sinceMorning);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }
}

/// THIRTY's app, through the real voice providers, with [voices] bundled
/// and the entitlement as given.
Future<_Rig> _pump(
  WidgetTester tester,
  Map<String, Object> stored, {
  required bool entitled,
  Set<ThirtyVoice> voices = const {
    ThirtyVoice.locke,
    ThirtyVoice.heather,
    ThirtyVoice.milo,
    ThirtyVoice.brittney,
  },
  bool screenReader = false,
  Widget home = const Scaffold(
    body: SingleChildScrollView(child: CircleHero()),
  ),
  List<Override> extra = const [],
}) async {
  tester.view.physicalSize = const Size(412, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  final clock = _Clock();
  final player = _RecordingPlayer();
  final session = _RecordingSession();
  final entitledProvider = NotifierProvider<_Entitled, bool>(
    () => _Entitled(entitled),
  );
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_morning),
      eventClockProvider.overrideWithValue(() => clock.now),
      safetyPendingAllowedProvider.overrideWithValue(false),
      premiumEntitlementProvider.overrideWith(
        (ref) => ref.watch(entitledProvider),
      ),
      bundledGuidanceVoicesProvider.overrideWithValue(voices),
      guidanceAudioPlayerProvider.overrideWithValue(player),
      guidanceSessionProvider.overrideWithValue(session),
      ...extra,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(412, 1400),
          accessibleNavigation: screenReader,
        ),
        child: MaterialApp(theme: AppTheme.light, home: home),
      ),
    ),
  );
  await tester.pump();
  return _Rig(container, entitledProvider, player, session, clock);
}

/// Ends the app with the conductor's once-a-second check still running.
Future<void> _leave(WidgetTester tester, _Rig rig) async {
  await tester.pumpWidget(const SizedBox());
  rig.container.dispose();
}

/// Every TalkBack announcement made from now on.
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
  return heard;
}

/// What a screen reader is given: every labelled node, with whether it is
/// a live region (read out by itself when it changes).
List<String> _accessibilityTree(WidgetTester tester) {
  final lines = <String>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.label.isNotEmpty) {
      final live = data.flagsCollection.isLiveRegion ? ' [live]' : '';
      lines.add('${data.label}$live');
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return lines;
}

String _assets(ThirtyVoice voice, int position) =>
    spokenCueFor(_plan, position).map((c) => c.assetFor(voice)).join(',');

void main() {
  group('Premium: THIRTY’s voice', () {
    testWidgets('Premium with the voice on: Start speaks in the chosen '
        'voice and opens the background session', (tester) async {
      final rig = await _pump(tester, _keptToday(), entitled: true);
      rig.container.read(recommendationProvider.notifier).start();
      await tester.pump();
      expect(rig.player.played.map((a) => a.join(',')), [
        _assets(ThirtyVoice.locke, 0),
      ]);
      expect(rig.session.shown, hasLength(1));
      await _leave(tester, rig);
    });

    testWidgets('the voice the user chose speaks; a choice the build '
        'doesn’t bundle falls back to the one it does', (tester) async {
      var rig = await _pump(
        tester,
        _keptToday(voice: 'voice_milo_v1'),
        entitled: true,
      );
      rig.container.read(recommendationProvider.notifier).start();
      await tester.pump();
      expect(rig.player.played.single.join(','), _assets(ThirtyVoice.milo, 0));
      await _leave(tester, rig);

      rig = await _pump(
        tester,
        _keptToday(voice: 'voice_milo_v1'),
        entitled: true,
        voices: const {ThirtyVoice.locke},
      );
      rig.container.read(recommendationProvider.notifier).start();
      await tester.pump();
      expect(rig.player.played.single.join(','), _assets(ThirtyVoice.locke, 0));
      await _leave(tester, rig);
    });
  });

  group('Free — a kept Circle stays whole, without THIRTY’s voice', () {
    testWidgets('no voice and no background service: at Start, at each '
        'timed part, out of sight, and at the end', (tester) async {
      final rig = await _pump(tester, _keptToday(), entitled: false);
      expect(rig.container.read(guidanceVoiceProvider).available, isFalse);
      rig.container.read(recommendationProvider.notifier).start();
      await tester.pump();
      for (final minutes in [1, 9]) {
        await rig.advanceTo(tester, Duration(minutes: minutes));
      }
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await rig.advanceTo(tester, const Duration(minutes: 15));
      await rig.advanceTo(tester, const Duration(minutes: 16));
      expect(rig.player.played, isEmpty);
      expect(rig.session.shown, isEmpty);
      await _leave(tester, rig);
    });

    testWidgets('the visual runtime is complete: parts move on with time, '
        'and Pause, Next and Skip work', (tester) async {
      final rig = await _pump(tester, _keptToday(), entitled: false);
      final notifier = rig.container.read(recommendationProvider.notifier);
      RecommendationState state() => rig.container.read(recommendationProvider);
      notifier.start();
      await tester.pump();
      expect(find.text('Stand and reach'), findsOneWidget);
      await rig.advanceTo(tester, const Duration(minutes: 1));
      expect(find.text('Clear one corner'), findsOneWidget);
      expect(find.text('Part 2 of 4 · next: Get it out'), findsOneWidget);
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      expect(state().isPaused, isTrue);
      await tester.tap(find.byTooltip('Resume'));
      await tester.pump();
      expect(state().isPaused, isFalse);
      await tester.tap(find.text(ComposedCopy.skip));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ComposedCopy.skipToday));
      await tester.pumpAndSettle();
      expect(state().skipped, [ElementId.clearCorner]);
      expect(find.text('Get it out'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Choose one thing'), findsOneWidget);
      expect(rig.player.played, isEmpty);
      await _leave(tester, rig);
    });

    testWidgets('a screen reader gets exactly what it gets on Premium: the '
        'same labels and live regions, and the same announcements', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final trees = <bool, List<String>>{};
      final heard = <bool, List<String>>{};
      for (final entitled in [true, false]) {
        final rig = await _pump(
          tester,
          _keptToday(status: 'started', startedMinutesAgo: 2),
          entitled: entitled,
          screenReader: true,
        );
        final announced = _announcements(tester);
        // A timed part change, then the natural end.
        await rig.advanceTo(tester, const Duration(minutes: 7));
        trees[entitled] = _accessibilityTree(tester);
        await rig.advanceTo(tester, const Duration(minutes: 14));
        await tester.pump(CircleHero.naturalEndAnnouncementDelay);
        await tester.pump();
        heard[entitled] = [...announced];
        await _leave(tester, rig);
      }
      expect(
        trees[false],
        contains(
          allOf(
            startsWith(
              'Part 3 of 4. Get it out. '
              '${elementOf(ElementId.getItOut).instruction}',
            ),
            endsWith('[live]'),
          ),
        ),
      );
      expect(trees[false], trees[true]);
      expect(heard[false], isNotEmpty);
      expect(heard[false], heard[true]);
      semantics.dispose();
    });

    testWidgets('reopening the app into a running kept Circle on Free — or '
        'before the entitlement has resolved — starts no voice and no '
        'service', (tester) async {
      final rig = await _pump(
        tester,
        _keptToday(status: 'started', startedMinutesAgo: 8),
        entitled: false,
      );
      await rig.advanceTo(tester, const Duration(minutes: 1));
      expect(rig.player.played, isEmpty);
      expect(rig.session.shown, isEmpty);
      await _leave(tester, rig);
    });
  });

  group('lapse and return — a service boundary, not an ownership one', () {
    testWidgets('a lapse during a voiced Circle: the voice and the service '
        'stop at once, the Circle runs on; a resubscription brings the '
        'voice back from the next part, never repeating one', (tester) async {
      final rig = await _pump(
        tester,
        _keptToday(status: 'started', startedMinutesAgo: 2),
        entitled: true,
      );
      expect(rig.session.shown, hasLength(1));
      rig.setEntitled(false);
      await tester.pump();
      expect(rig.session.ended, [false]);
      // "Get it out" begins while lapsed: shown, not spoken.
      await rig.advanceTo(tester, const Duration(minutes: 7));
      expect(find.text('Get it out'), findsOneWidget);
      // A minute into it, Premium resumes.
      await rig.advanceTo(tester, const Duration(minutes: 8));
      expect(rig.player.played, isEmpty);
      rig.setEntitled(true);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(rig.session.shown, hasLength(2));
      expect(rig.player.played, isEmpty);
      await rig.advanceTo(tester, const Duration(minutes: 13));
      expect(rig.player.played.map((a) => a.join(',')), [
        _assets(ThirtyVoice.locke, 3),
      ]);
      await _leave(tester, rig);
    });

    testWidgets('the user’s voice and on/off choices survive a lapse, '
        'untouched, and apply again on return', (tester) async {
      final rig = await _pump(tester, _keptToday(), entitled: true);
      final prefs = rig.container.read(sharedPreferencesProvider);
      rig.container
          .read(thirtyVoiceChoiceProvider.notifier)
          .set(ThirtyVoice.milo);
      rig.setEntitled(false);
      await tester.pump();
      expect(rig.container.read(guidanceVoiceProvider).available, isFalse);
      expect(prefs.getString(thirtyVoiceKey), 'voice_milo_v1');
      expect(prefs.get(spokenGuidanceEnabledKey), isNull);
      rig.setEntitled(true);
      await tester.pump();
      final voice = rig.container.read(guidanceVoiceProvider);
      expect(voice, isA<BundledGuidanceVoice>());
      expect((voice as BundledGuidanceVoice).voice, ThirtyVoice.milo);
      await _leave(tester, rig);
    });
  });

  group('You', () {
    testWidgets('Premium: spoken guidance on or off, and the choice of '
        'THIRTY’s four voices', (tester) async {
      final rig = await _pump(
        tester,
        {},
        entitled: true,
        home: const Scaffold(
          body: SingleChildScrollView(child: YouPreferencesCard()),
        ),
      );
      expect(find.text(SpokenGuidanceCopy.title), findsOneWidget);
      await tester.tap(find.text(ThirtyVoice.milo.label));
      await tester.pump();
      expect(rig.container.read(thirtyVoiceProvider), ThirtyVoice.milo);
      await _leave(tester, rig);
    });

    testWidgets('the four voices are offered by name, and the preview plays '
        'the chosen voice introducing itself — its own recording, never one '
        'of a Circle’s activities', (tester) async {
      final rig = await _pump(
        tester,
        {},
        entitled: true,
        home: const Scaffold(
          body: SingleChildScrollView(child: YouPreferencesCard()),
        ),
      );
      for (final name in ['Locke', 'Heather', 'Milo', 'Brittney']) {
        expect(find.widgetWithText(ChoiceChip, name), findsOneWidget);
      }
      await tester.tap(find.text(SpokenGuidanceCopy.preview('Locke')));
      await tester.pump();
      await tester.tap(find.text('Brittney'));
      await tester.pump();
      await tester.tap(find.text(SpokenGuidanceCopy.preview('Brittney')));
      await tester.pump();
      expect(rig.player.played, [
        [
          'assets/audio/guidance/voice_locke_v1/'
              '${spokenPreviewFor(ThirtyVoice.locke).file}',
        ],
        [
          'assets/audio/guidance/voice_brittney_v1/'
              '${spokenPreviewFor(ThirtyVoice.brittney).file}',
        ],
      ]);
      expect(
        spokenPreviewFor(ThirtyVoice.brittney).script,
        'Hi, I’m Brittney. I’ll tell you when each part of your Circle '
        'begins, so you can put the screen down.',
      );
      // No preview is a clip a Circle plays.
      for (final voice in ThirtyVoice.values) {
        expect(
          spokenGuidanceManifest,
          isNot(contains(spokenPreviewFor(voice))),
        );
      }
      await _leave(tester, rig);
    });

    testWidgets('with spoken guidance off there is no voice to choose or '
        'hear', (tester) async {
      await _pump(
        tester,
        {spokenGuidanceEnabledKey: false},
        entitled: true,
        home: const Scaffold(
          body: SingleChildScrollView(child: YouPreferencesCard()),
        ),
      );
      expect(find.text(SpokenGuidanceCopy.title), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(
        find.byKey(const ValueKey('you.spokenGuidance.preview')),
        findsNothing,
      );
    });

    testWidgets('a stored choice no voice answers to (a pre-release '
        'placeholder) speaks in the first voice, and is replaced only when '
        'the user chooses', (tester) async {
      final rig = await _pump(
        tester,
        _keptToday(voice: 'female'),
        entitled: true,
      );
      expect(rig.container.read(thirtyVoiceProvider), ThirtyVoice.locke);
      expect(
        rig.container.read(sharedPreferencesProvider).get(thirtyVoiceKey),
        'female',
      );
      await _leave(tester, rig);
    });

    testWidgets('Free: nothing to set — and nothing is erased', (tester) async {
      final rig = await _pump(
        tester,
        {thirtyVoiceKey: 'voice_milo_v1', spokenGuidanceEnabledKey: false},
        entitled: false,
        home: const Scaffold(
          body: SingleChildScrollView(child: YouPreferencesCard()),
        ),
      );
      expect(find.text(SpokenGuidanceCopy.title), findsNothing);
      final prefs = rig.container.read(sharedPreferencesProvider);
      expect(prefs.getString(thirtyVoiceKey), 'voice_milo_v1');
      expect(prefs.getBool(spokenGuidanceEnabledKey), isFalse);
      await _leave(tester, rig);
    });
  });
}
