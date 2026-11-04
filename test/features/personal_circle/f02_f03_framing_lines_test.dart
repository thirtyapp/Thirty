import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/first_breath_provider.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/widgets/circle_hero.dart';
import 'package:thirty/features/personal_circle/application/guidance_conductor.dart';
import 'package:thirty/features/personal_circle/application/guidance_session.dart';
import 'package:thirty/features/personal_circle/application/guidance_voice.dart';
import 'package:thirty/features/personal_circle/domain/circle_composer.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/composed_session.dart';
import 'package:thirty/features/personal_circle/domain/spoken_cues.dart';

/// F02 / F03 (founder approval, 2026-10-26): a voiced Premium Guided
/// Circle's spoken opening, "Your Circle for today.", at the user's Start,
/// and its closing line, "Your next Circle opens tomorrow.", after the
/// user's Close — through the real voice providers, the real conductor and
/// Today's real Circle, with the platform player recorded.

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
  int startedMinutesAgo = 0,
  ThirtyVoice? voice,
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
        .subtract(Duration(minutes: startedMinutesAgo))
        .toIso8601String(),
  if (status == 'closed') recommendationClosedAtKey: _morning.toIso8601String(),
  recommendationComposedKey: jsonEncode(
    ComposedSession(plan: _plan, basis: CompositionBasis.foundUseful).toJson(),
  ),
  thirtyVoiceKey: ?voice?.id,
};

class _Clock {
  DateTime now = _morning;
}

/// The entitlement, changeable mid-test: a lapse.
class _Entitled extends Notifier<bool> {
  _Entitled(this._initial);

  final bool _initial;

  @override
  bool build() => _initial;

  void set(bool value) => state = value;
}

/// The platform player: what THIRTY's voice was asked to play, and how.
class _Player implements GuidanceAudioPlayer {
  final played = <List<String>>[];
  final deferred = <bool>[];
  final followed = <bool>[];
  var stops = 0;

  /// While set, a play never completes — a player that hangs.
  Completer<void>? hold;

  @override
  Future<void> play(
    List<String> assets, {
    bool deferToScreenReader = false,
    bool afterCurrent = false,
  }) {
    played.add(assets);
    deferred.add(deferToScreenReader);
    followed.add(afterCurrent);
    return hold?.future ?? Future.value();
  }

  @override
  Future<void> stop() async => stops++;
}

class _Session implements GuidanceSession {
  final ended = <bool>[];

  @override
  Future<void> show(GuidanceSessionStatus status) async {}

  @override
  Future<void> end({bool afterSpeech = false}) async => ended.add(afterSpeech);

  @override
  void listen(void Function(GuidanceAction action)? onAction) {}
}

class _Rig {
  _Rig(this.container, this.entitled, this.player, this.session, this.clock);

  final ProviderContainer container;
  final NotifierProvider<_Entitled, bool> entitled;
  final _Player player;
  final _Session session;
  final _Clock clock;

  RecommendationNotifier get notifier =>
      container.read(recommendationProvider.notifier);

  Future<void> advanceTo(WidgetTester tester, Duration sinceMorning) async {
    clock.now = _morning.add(sinceMorning);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }
}

Future<_Rig> _pump(
  WidgetTester tester,
  Map<String, Object> stored, {
  bool entitled = true,
  bool screenReader = false,
  DateTime? today,
}) async {
  tester.view.physicalSize = const Size(412, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  final clock = _Clock();
  if (today != null) clock.now = today;
  final player = _Player();
  final session = _Session();
  final entitledProvider = NotifierProvider<_Entitled, bool>(
    () => _Entitled(entitled),
  );
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(today ?? _morning),
      eventClockProvider.overrideWithValue(() => clock.now),
      safetyPendingAllowedProvider.overrideWithValue(false),
      premiumEntitlementProvider.overrideWith(
        (ref) => ref.watch(entitledProvider),
      ),
      bundledGuidanceVoicesProvider.overrideWithValue(
        ThirtyVoice.values.toSet(),
      ),
      guidanceAudioPlayerProvider.overrideWithValue(player),
      guidanceSessionProvider.overrideWithValue(session),
    ],
  );
  addTearDown(container.dispose);
  // As main.dart does: the conductor lives with the container.
  keepGuidanceConducting(container);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(412, 1400),
          accessibleNavigation: screenReader,
        ),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SingleChildScrollView(child: CircleHero()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return _Rig(container, entitledProvider, player, session, clock);
}

/// Ends the app: the conductor goes with its container.
Future<void> _leave(WidgetTester tester, _Rig rig) async {
  await tester.pumpWidget(const SizedBox());
  rig.container.dispose();
}

List<String> _assets(ThirtyVoice voice, List<SpokenClip> clips) => [
  for (final clip in clips) clip.assetFor(voice),
];

/// What Start plays: the opening, then the first part's own cue.
List<String> _startCue(ThirtyVoice voice) =>
    _assets(voice, [spokenOpening, ...spokenCueFor(_plan, 0)]);

Future<void> _tapStart(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Start Circle'));
  await tester.tap(find.text('Start Circle'));
  await tester.pump();
}

/// Close Circle, confirmed.
Future<void> _tapClose(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Close Circle'));
  await tester.tap(find.text('Close Circle'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Close Circle').last);
  await tester.pump();
}

bool _played(_Rig rig, SpokenClip clip) => rig.player.played.any(
  (assets) => assets.any((a) => a.contains('/${clip.file}')),
);

int _times(_Rig rig, SpokenClip clip) => rig.player.played
    .expand((assets) => assets)
    .where((a) => a.contains('/${clip.file}'))
    .length;

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

/// An MPEG-4 file's length, from its movie header (`mvhd`).
Duration _m4aLength(File file) {
  final bytes = file.readAsBytesSync();
  final at = String.fromCharCodes(bytes).indexOf('mvhd');
  final box = ByteData.sublistView(bytes, at + 4);
  final version = box.getUint8(0);
  final scale = box.getUint32(version == 0 ? 12 : 20);
  final length = version == 0 ? box.getUint32(16) : box.getUint64(24);
  return Duration(microseconds: length * 1000000 ~/ scale);
}

void main() {
  group('the lines and their recordings', () {
    test('each line says exactly the words on the screen: the opening is '
        'the closed Circle’s heading, the closing line its own detail', () {
      expect(spokenOpening.script, 'Your Circle for today.');
      expect(spokenOpening.script, CircleHero.closedHeading);
      expect(spokenOpening.script, ComposedCopy.opening);
      expect(spokenNextCircle.script, 'Your next Circle opens tomorrow.');
      expect(spokenNextCircle.script, CircleHero.closedDetail);
      expect(spokenOpening.role, SpokenClipRole.opening);
      expect(spokenNextCircle.role, SpokenClipRole.nextCircle);
      expect(spokenFramingClips, [spokenOpening, spokenNextCircle]);
    });

    test('the 42-cue manifest is unchanged: its identifiers and scripts are '
        'not touched, and the lines are no part of it', () {
      expect(spokenGuidanceManifest, hasLength(42));
      for (final clip in spokenFramingClips) {
        expect(spokenGuidanceManifest, isNot(contains(clip)));
      }
      expect(spokenEnding.script, ComposedCopy.ending);
      expect(spokenEnding.file, 'close_3b06cf13.m4a');
    });

    test('this build bundles both lines in each of the four voices', () async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets().toSet();
      for (final voice in ThirtyVoice.values) {
        for (final clip in spokenFramingClips) {
          expect(assets, contains(clip.assetFor(voice)));
          final file = File(clip.assetFor(voice));
          expect(file.lengthSync(), greaterThan(10000), reason: file.path);
        }
      }
      expect(spokenOpening.file, 'opening_d1293026.m4a');
      expect(spokenNextCircle.file, 'next_circle_3c38eb7b.m4a');
    });

    test('a voice is complete without them: a missing line never silences '
        'a voice’s guidance', () {
      final cues = {
        for (final voice in ThirtyVoice.values) ...[
          for (final clip in spokenGuidanceManifest) clip.assetFor(voice),
          spokenPreviewFor(voice).assetFor(voice),
        ],
      };
      expect(completeGuidanceVoices(cues), ThirtyVoice.values.toSet());
    });
  });

  group('F02 — the opening', () {
    testWidgets('1 · said once when the user starts the Circle — before '
        '"First." — with its words on show while it is said, then the '
        'part', (tester) async {
      final rig = await _pump(tester, _today());
      expect(rig.player.played, isEmpty);
      await _tapStart(tester);
      expect(rig.player.played, [_startCue(ThirtyVoice.locke)]);
      expect(find.text(ComposedCopy.opening), findsWidgets);
      expect(find.text('Part 1 of 4 · next: Clear one corner'), findsOneWidget);
      await tester.pump(GuidanceConductor.openingOnShow[ThirtyVoice.locke]!);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(ComposedCopy.opening), findsNothing);
      expect(find.text('Stand and reach'), findsOneWidget);
      // A minute on, the next part: no opening again.
      await rig.advanceTo(tester, const Duration(minutes: 1, seconds: 1));
      expect(_times(rig, spokenOpening), 1);
      expect(
        rig.player.played.last,
        _assets(ThirtyVoice.locke, spokenCueFor(_plan, 1)),
      );
      await _leave(tester, rig);
    });

    testWidgets('2 · never on opening Today: before Start, and on a first '
        'look into a Circle already under way or just begun', (tester) async {
      var rig = await _pump(tester, _today());
      await tester.pump(const Duration(seconds: 3));
      expect(rig.player.played, isEmpty);
      expect(find.text(ComposedCopy.opening), findsNothing);
      await _leave(tester, rig);
      // A restart a moment after Start: the first part's cue, as before —
      // never the opening.
      rig = await _pump(tester, _today(status: 'started'));
      expect(rig.player.played, [
        _assets(ThirtyVoice.locke, spokenCueFor(_plan, 0)),
      ]);
      expect(_played(rig, spokenOpening), isFalse);
      expect(find.text(ComposedCopy.opening), findsNothing);
      await _leave(tester, rig);
    });

    testWidgets('3 · Pause and Resume never repeat it; a Pause while it is '
        'said stops it and its words', (tester) async {
      final rig = await _pump(tester, _today());
      await _tapStart(tester);
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      expect(rig.player.stops, greaterThanOrEqualTo(1));
      expect(find.text(ComposedCopy.opening), findsNothing);
      rig.clock.now = _morning.add(const Duration(seconds: 20));
      await tester.tap(find.byTooltip('Resume'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(rig.player.played, [_startCue(ThirtyVoice.locke)]);
      expect(find.text(ComposedCopy.opening), findsNothing);
      await _leave(tester, rig);
    });
  });

  group('F02 — its words on show for exactly its recording', () {
    test('each voice’s time on show is its own opening recording’s length '
        '(read from the bundled file)', () {
      for (final voice in ThirtyVoice.values) {
        final length = _m4aLength(File(spokenOpening.assetFor(voice)));
        final onShow = GuidanceConductor.openingOnShow[voice]!;
        expect(
          (onShow - length).inMilliseconds.abs(),
          lessThanOrEqualTo(5),
          reason: '${voice.label}: $onShow vs the file’s $length',
        );
      }
      expect(
        GuidanceConductor.openingOnShowAtMost,
        GuidanceConductor.openingOnShow[ThirtyVoice.heather],
      );
    });

    for (final voice in ThirtyVoice.values) {
      testWidgets('${voice.label}: on show until its line ends, then the '
          'part', (tester) async {
        final rig = await _pump(tester, _today(voice: voice));
        await _tapStart(tester);
        final onShow = GuidanceConductor.openingOnShow[voice]!;
        await tester.pump(onShow - const Duration(milliseconds: 20));
        expect(find.text(ComposedCopy.opening), findsWidgets);
        await tester.pump(const Duration(milliseconds: 20));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text(ComposedCopy.opening), findsNothing);
        expect(find.text('Stand and reach'), findsOneWidget);
        await _leave(tester, rig);
      });
    }
  });

  group('F03 — the closing line', () {
    testWidgets('4 · said once after the user closes the Circle, with its '
        'line on the closed screen', (tester) async {
      final rig = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 3),
      );
      expect(_played(rig, spokenNextCircle), isFalse);
      await _tapClose(tester);
      expect(
        rig.player.played.last,
        _assets(ThirtyVoice.locke, [spokenNextCircle]),
      );
      expect(rig.player.followed.last, isFalse);
      expect(find.text(CircleHero.closedHeading), findsWidgets);
      expect(find.text(CircleHero.closedDetail), findsWidgets);
      // Close ends the background session at once, as before.
      expect(rig.session.ended, contains(false));
      await _leave(tester, rig);
    });

    testWidgets('5 · never duplicated: after the ending it follows — never '
        'cutting it off, never said twice — and later changes say nothing', (
      tester,
    ) async {
      final rig = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 3),
      );
      await rig.advanceTo(tester, const Duration(minutes: 14));
      expect(
        rig.player.played.last,
        _assets(ThirtyVoice.locke, [spokenEnding]),
      );
      final stopsBefore = rig.player.stops;
      await _tapClose(tester);
      expect(
        rig.player.played.last,
        _assets(ThirtyVoice.locke, [spokenNextCircle]),
      );
      // Queued after the ending, which is left to finish.
      expect(rig.player.followed.last, isTrue);
      expect(rig.player.stops, stopsBefore);
      expect(_times(rig, spokenEnding), 1);
      // The reflection answered, time passing, a rebuild: nothing more.
      rig.notifier.reportAttempt(CircleAttemptResponse.yes);
      await rig.advanceTo(tester, const Duration(minutes: 20));
      await tester.pumpAndSettle();
      expect(_times(rig, spokenNextCircle), 1);
      expect(rig.player.stops, stopsBefore);
      await _leave(tester, rig);
    });

    testWidgets('6 · a repeated Close stays one Close: one closing line, '
        'the first Close’s time kept', (tester) async {
      final rig = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 3),
      );
      rig.notifier.close();
      await tester.pump();
      final closedAt = rig.container.read(recommendationProvider).closedAt;
      rig.clock.now = _morning.add(const Duration(minutes: 2));
      rig.notifier.close();
      rig.notifier.close();
      await tester.pump();
      expect(rig.container.read(recommendationProvider).closedAt, closedAt);
      expect(_times(rig, spokenNextCircle), 1);
      await _leave(tester, rig);
    });

    testWidgets('Close is never held by the voice: with a player that never '
        'answers, the Close is saved at once', (tester) async {
      final rig = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 3),
      );
      rig.player.hold = Completer<void>();
      rig.notifier.close();
      await tester.pump();
      await tester.pump();
      final prefs = rig.container.read(sharedPreferencesProvider);
      expect(prefs.getString(recommendationStatusKey), 'closed');
      expect(_times(rig, spokenNextCircle), 1);
      await _leave(tester, rig);
    });
  });

  group('7 · restart and lifecycle', () {
    testWidgets('reopening a closed Circle never repeats the closing line', (
      tester,
    ) async {
      final rig = await _pump(
        tester,
        _today(status: 'closed', startedMinutesAgo: 20),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(rig.player.played, isEmpty);
      expect(find.text(CircleHero.closedDetail), findsOneWidget);
      await _leave(tester, rig);
    });

    testWidgets('THIRTY out of sight and back: neither line again, and the '
        'closing line is not stopped by leaving', (tester) async {
      final rig = await _pump(tester, _today());
      await _tapStart(tester);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump(const Duration(seconds: 1));
      expect(_times(rig, spokenOpening), 1);
      await _tapClose(tester);
      final stops = rig.player.stops;
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump(const Duration(seconds: 1));
      expect(rig.player.stops, stops);
      expect(_times(rig, spokenNextCircle), 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _leave(tester, rig);
    });
  });

  group('8 · the calendar day', () {
    testWidgets('a Circle kept open past midnight, closed on the next day: '
        'no "tomorrow" — that day’s Circle is already there', (tester) async {
      final rig = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 10),
      );
      rig.clock.now = DateTime(2026, 11, 21, 0, 10);
      await tester.pump(const Duration(seconds: 1));
      rig.notifier.close();
      await tester.pump();
      expect(
        rig.container.read(recommendationProvider).status,
        RecommendationStatus.closed,
      );
      expect(_played(rig, spokenNextCircle), isFalse);
      // Nor is it on the screen: the closed Circle stays itself — its
      // heading, its reflection — without a wait that isn't there.
      expect(find.text(CircleHero.closedDetail), findsNothing);
      expect(find.textContaining('tomorrow'), findsNothing);
      expect(find.text(CircleHero.closedHeading), findsOneWidget);
      expect(
        rig.container.read(recommendationProvider).recommendation?.circleId,
        _day,
      );
      await _leave(tester, rig);
    });

    testWidgets('closed a moment before midnight, on its own day: the line '
        'is true, and said', (tester) async {
      final rig = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 10),
      );
      rig.clock.now = DateTime(2026, 11, 20, 23, 59, 59);
      await tester.pump(const Duration(seconds: 1));
      rig.notifier.close();
      await tester.pump();
      expect(_times(rig, spokenNextCircle), 1);
      expect(find.text(CircleHero.closedDetail), findsOneWidget);
      await _leave(tester, rig);
    });

    testWidgets('a closed Circle left on show across midnight: "tomorrow" '
        'goes at midnight, with nothing else to trigger it, and nothing is '
        'said', (tester) async {
      final rig = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 10),
      );
      await _tapClose(tester);
      expect(_times(rig, spokenNextCircle), 1);
      rig.clock.now = DateTime(2026, 11, 20, 23, 59, 30);
      await tester.pump(const Duration(minutes: 1));
      expect(find.text(CircleHero.closedDetail), findsOneWidget);
      // The look again is due at midnight itself, 30 s on.
      rig.clock.now = DateTime(2026, 11, 21, 0, 0, 0, 5);
      await tester.pump(const Duration(seconds: 30));
      expect(find.text(CircleHero.closedDetail), findsNothing);
      expect(find.textContaining('tomorrow'), findsNothing);
      expect(find.text(CircleHero.closedHeading), findsOneWidget);
      expect(_times(rig, spokenNextCircle), 1);
      final state = rig.container.read(recommendationProvider);
      expect(state.status, RecommendationStatus.closed);
      expect(state.recommendation?.circleId, _day);
      await _leave(tester, rig);
    });

    testWidgets('the device’s date or time zone changed while it is on '
        'show: seen within a minute', (tester) async {
      final rig = await _pump(
        tester,
        _today(status: 'closed', startedMinutesAgo: 20),
      );
      expect(find.text(CircleHero.closedDetail), findsOneWidget);
      rig.clock.now = DateTime(2026, 11, 21, 9, 0, 30);
      await tester.pump(const Duration(minutes: 1));
      expect(find.text(CircleHero.closedDetail), findsNothing);
      // Set back to the Circle's own day: true again, once rebuilt.
      rig.clock.now = _morning.add(const Duration(minutes: 5));
      rig.notifier.reportAttempt(CircleAttemptResponse.yes);
      await tester.pump();
      expect(find.text(CircleHero.closedDetail), findsOneWidget);
      await _leave(tester, rig);
    });

    test('a restart on the next day: the day resets as before — the next '
        'Circle, never yesterday’s "tomorrow"', () async {
      SharedPreferences.setMockInitialValues(
        _today(status: 'closed', startedMinutesAgo: 20),
      );
      final prefs = await SharedPreferences.getInstance();
      final nextMorning = DateTime(2026, 11, 21, 7);
      ProviderContainer containerOn(DateTime now) => ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          nowProvider.overrideWithValue(now),
          eventClockProvider.overrideWithValue(() => now),
          safetyPendingAllowedProvider.overrideWithValue(false),
        ],
      );
      final sameDay = containerOn(_morning.add(const Duration(hours: 1)));
      addTearDown(sameDay.dispose);
      final closed = sameDay.read(recommendationProvider);
      expect(closed.status, RecommendationStatus.closed);
      expect(closed.nextCircleIsTomorrowAt(_morning), isTrue);
      expect(closed.nextCircleIsTomorrowAt(nextMorning), isFalse);
      expect(
        closed.nextCircleIsTomorrowAt(DateTime(2026, 11, 20, 23, 59, 59)),
        isTrue,
      );
      expect(closed.nextCircleIsTomorrowAt(DateTime(2026, 11, 21)), isFalse);
      final nextDay = containerOn(nextMorning);
      addTearDown(nextDay.dispose);
      final restored = nextDay.read(recommendationProvider);
      expect(restored.status, RecommendationStatus.notStarted);
      expect(restored.nextCircleIsTomorrowAt(nextMorning), isFalse);
    });
  });

  group('8b · the Close confirmation and the calendar day', () {
    /// One title on every day — shown and announced — never "today's".
    void expectGenericTitle(WidgetTester tester) {
      expect(CircleHero.closeConfirmTitle, 'Close this Circle?');
      expect(find.text(CircleHero.closeConfirmTitle), findsOneWidget);
      expect(
        tester.widget<AlertDialog>(find.byType(AlertDialog)).semanticLabel,
        CircleHero.closeConfirmTitle,
      );
      for (final today in ["today's", 'today’s']) {
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.textContaining(today),
          ),
          findsNothing,
        );
      }
    }

    Future<void> openConfirmation(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Close Circle'));
      await tester.tap(find.text('Close Circle'));
      await tester.pumpAndSettle();
      expectGenericTitle(tester);
    }

    testWidgets('on the Circle’s own day: "until tomorrow", as approved — '
        'and keeping it open changes nothing', (tester) async {
      final rig = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 10),
      );
      await openConfirmation(tester);
      expect(find.text(CircleHero.closeConfirmBody), findsOneWidget);
      await tester.tap(find.text('Keep Circle open'));
      await tester.pumpAndSettle();
      expect(
        rig.container.read(recommendationProvider).status,
        RecommendationStatus.started,
      );
      await _leave(tester, rig);
    });

    testWidgets('kept open past midnight: no "tomorrow" — and Close still '
        'closes at once, durably, with no closing line', (tester) async {
      final rig = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 10),
      );
      final at = DateTime(2026, 11, 21, 0, 10);
      rig.clock.now = at;
      await tester.pump(const Duration(seconds: 1));
      await openConfirmation(tester);
      expect(find.text(CircleHero.closeConfirmBodyPastItsDay), findsOneWidget);
      expect(find.textContaining('tomorrow'), findsNothing);
      await tester.tap(find.text('Close Circle').last);
      await tester.pump();
      final state = rig.container.read(recommendationProvider);
      expect(state.status, RecommendationStatus.closed);
      expect(state.closedAt, at);
      expect(state.recommendation?.circleId, _day);
      final prefs = rig.container.read(sharedPreferencesProvider);
      expect(prefs.getString(recommendationStatusKey), 'closed');
      expect(prefs.getString(recommendationDayKey), _day);
      expect(_played(rig, spokenNextCircle), isFalse);
      await _leave(tester, rig);
    });

    testWidgets('left open across midnight: "tomorrow" goes at midnight '
        'itself, with nothing else to trigger it', (tester) async {
      final rig = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 10),
      );
      rig.clock.now = DateTime(2026, 11, 20, 23, 59, 30);
      await tester.pump(const Duration(seconds: 1));
      await openConfirmation(tester);
      expect(find.text(CircleHero.closeConfirmBody), findsOneWidget);
      rig.clock.now = DateTime(2026, 11, 21, 0, 0, 0, 5);
      await tester.pump(const Duration(seconds: 30));
      expect(find.text(CircleHero.closeConfirmBodyPastItsDay), findsOneWidget);
      expect(find.textContaining('tomorrow'), findsNothing);
      expectGenericTitle(tester);
      await tester.tap(find.text('Close Circle').last);
      await tester.pump();
      expect(
        rig.container.read(recommendationProvider).status,
        RecommendationStatus.closed,
      );
      expect(_played(rig, spokenNextCircle), isFalse);
      await _leave(tester, rig);
    });

    testWidgets('the device’s date or time zone changed while it is open: '
        'seen within a minute', (tester) async {
      final rig = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 10),
      );
      await openConfirmation(tester);
      expect(find.text(CircleHero.closeConfirmBody), findsOneWidget);
      rig.clock.now = DateTime(2026, 11, 21, 9, 0, 30);
      await tester.pump(const Duration(minutes: 1));
      expect(find.text(CircleHero.closeConfirmBodyPastItsDay), findsOneWidget);
      await tester.tap(find.text('Keep Circle open'));
      await tester.pumpAndSettle();
      await _leave(tester, rig);
    });

    test('a restart on the next day: yesterday’s Circle is never offered to '
        'close again — the day resets, as before', () async {
      SharedPreferences.setMockInitialValues(
        _today(status: 'started', startedMinutesAgo: 10),
      );
      final prefs = await SharedPreferences.getInstance();
      final nextMorning = DateTime(2026, 11, 21, 7);
      ProviderContainer containerOn(DateTime now) => ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          nowProvider.overrideWithValue(now),
          eventClockProvider.overrideWithValue(() => now),
          safetyPendingAllowedProvider.overrideWithValue(false),
        ],
      );
      final sameDay = containerOn(_morning.add(const Duration(minutes: 5)));
      addTearDown(sameDay.dispose);
      final running = sameDay.read(recommendationProvider);
      expect(running.status, RecommendationStatus.started);
      expect(running.isOnItsOwnDayAt(_morning), isTrue);
      expect(
        running.isOnItsOwnDayAt(DateTime(2026, 11, 20, 23, 59, 59)),
        isTrue,
      );
      expect(running.isOnItsOwnDayAt(DateTime(2026, 11, 21)), isFalse);
      expect(running.isOnItsOwnDayAt(nextMorning), isFalse);
      final nextDay = containerOn(nextMorning);
      addTearDown(nextDay.dispose);
      final restored = nextDay.read(recommendationProvider);
      expect(restored.status, RecommendationStatus.notStarted);
      expect(restored.recommendation?.circleId, isNot(_day));
    });
  });

  group('Premium only', () {
    testWidgets('9 · a lapse during the Circle stops the voice; its Close '
        'says nothing', (tester) async {
      final rig = await _pump(tester, _today());
      await _tapStart(tester);
      expect(_times(rig, spokenOpening), 1);
      rig.container.read(rig.entitled.notifier).set(false);
      await tester.pump();
      expect(find.text(ComposedCopy.opening), findsNothing);
      final stops = rig.player.stops;
      expect(stops, greaterThanOrEqualTo(1));
      rig.notifier.close();
      await tester.pump();
      expect(_played(rig, spokenNextCircle), isFalse);
      await _leave(tester, rig);
    });

    testWidgets('10 · Free: Start and Close say nothing, and the screen '
        'shows no opening', (tester) async {
      final rig = await _pump(tester, _today(), entitled: false);
      await _tapStart(tester);
      expect(find.text(ComposedCopy.opening), findsNothing);
      expect(find.text('Stand and reach'), findsOneWidget);
      await _tapClose(tester);
      expect(rig.player.played, isEmpty);
      expect(find.text(CircleHero.closedDetail), findsWidgets);
      await _leave(tester, rig);
    });
  });

  group('11 · each of the four voices', () {
    for (final voice in ThirtyVoice.values) {
      testWidgets('${voice.label}: its own opening and closing line', (
        tester,
      ) async {
        final rig = await _pump(tester, _today(voice: voice));
        await _tapStart(tester);
        expect(rig.player.played.single, _startCue(voice));
        await _tapClose(tester);
        expect(rig.player.played.last, _assets(voice, [spokenNextCircle]));
        for (final asset in rig.player.played.expand((a) => a)) {
          expect(asset, startsWith('${voice.assetDir}/'));
        }
        await _leave(tester, rig);
      });
    }
  });

  group('12 · missing or broken audio', () {
    const channel = MethodChannel('com.thirty.app/guidance_audio');

    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    test('a clip the platform can’t play is skipped, never an error — and '
        'the player is told to follow, not cut', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            throw PlatformException(code: 'unplayable');
          });
      const player = PlatformGuidanceAudioPlayer();
      await player.play([
        spokenNextCircle.assetFor(ThirtyVoice.heather),
      ], afterCurrent: true);
      expect(calls.single.arguments, {
        'assets': [spokenNextCircle.assetFor(ThirtyVoice.heather)],
        'deferToScreenReader': false,
        'afterCurrent': true,
      });
    });

    test('no platform player at all: silent', () async {
      const player = PlatformGuidanceAudioPlayer();
      await player.play([spokenOpening.assetFor(ThirtyVoice.milo)]);
    });
  });

  group('13 · TalkBack', () {
    testWidgets('in front, both lines defer to a screen reader (the '
        'platform stays silent while it is on); the opening’s words are no '
        'live region, and nothing new is announced', (tester) async {
      final semantics = tester.ensureSemantics();
      final heard = _announcements(tester);
      final rig = await _pump(tester, _today(), screenReader: true);
      await _tapStart(tester);
      expect(rig.player.deferred.single, isTrue);
      // The words are on show, but the screen reader keeps the part's own
      // heading: the same tree as before the opening existed.
      expect(find.text(ComposedCopy.opening), findsWidgets);
      expect(find.bySemanticsLabel(ComposedCopy.opening), findsNothing);
      final heading = tester.getSemantics(
        find.text(ComposedCopy.opening).first,
      );
      final data = heading.getSemanticsData();
      expect(data.label, 'Stand and reach');
      expect(data.flagsCollection.isHeader, isTrue);
      expect(data.flagsCollection.isLiveRegion, isFalse);
      await tester.pump(GuidanceConductor.openingOnShow[ThirtyVoice.locke]!);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(ComposedCopy.opening), findsNothing);
      expect(
        tester.getSemantics(find.text('Stand and reach').first).label,
        'Stand and reach',
      );
      await _tapClose(tester);
      expect(rig.player.deferred.last, isTrue);
      expect(heard, isNot(contains(ComposedCopy.opening)));
      expect(heard, isNot(contains(ComposedCopy.nextCircle)));
      expect(heard.where((m) => m == 'Circle closed.'), hasLength(1));
      await _leave(tester, rig);
      semantics.dispose();
    });
  });

  group('14 · interruption and disposal', () {
    testWidgets('a Close while the opening is said replaces it with the '
        'closing line', (tester) async {
      final rig = await _pump(tester, _today());
      await _tapStart(tester);
      rig.notifier.close();
      await tester.pump();
      expect(
        rig.player.played.last,
        _assets(ThirtyVoice.locke, [spokenNextCircle]),
      );
      expect(rig.player.followed.last, isFalse);
      // The opening is over; the closed heading's same words are the
      // closed Circle's own.
      expect(rig.container.read(spokenOpeningProvider), isNull);
      await _leave(tester, rig);
    });

    testWidgets('THIRTY going away stops the voice and leaves nothing '
        'pending', (tester) async {
      final rig = await _pump(tester, _today());
      await _tapStart(tester);
      final stops = rig.player.stops;
      await _leave(tester, rig);
      expect(rig.player.stops, stops + 1);
    });

    testWidgets('the voice turned off mid-closing-line stops it', (
      tester,
    ) async {
      final rig = await _pump(
        tester,
        _today(status: 'started', startedMinutesAgo: 3),
      );
      rig.notifier.close();
      await tester.pump();
      final stops = rig.player.stops;
      rig.container.read(spokenGuidanceEnabledProvider.notifier).set(false);
      await tester.pump();
      expect(rig.player.stops, stops + 1);
      await _leave(tester, rig);
    });
  });
}
