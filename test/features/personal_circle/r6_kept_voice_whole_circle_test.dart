import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/personal_circle/application/guidance_conductor.dart';
import 'package:thirty/features/personal_circle/application/guidance_session.dart';
import 'package:thirty/features/personal_circle/application/guidance_voice.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/composed_session.dart';
import 'package:thirty/features/personal_circle/domain/kept_circle.dart';
import 'package:thirty/features/personal_circle/domain/spoken_cues.dart';

/// Audit remediation R6 (D-B, founder decision 2026-11-03): THIRTY's voice
/// speaks a kept Circle only when every part's words — the saved words the
/// screen shows — are exactly the words THIRTY recorded. A kept Circle with
/// any part whose saved words differ runs whole on screen and paced: no
/// opening, no cue, no ending, no closing line, no background session. It
/// stays the user's, unchanged; nothing is guessed, migrated or matched
/// approximately. A kept Circle whose words all match — and one kept before
/// words were saved, which shows the recorded words — is spoken as before.
void main() {
  final morning = DateTime(2026, 10, 12, 9);
  late SharedPreferences prefs;
  late DateTime now;

  const valid = ['getItOut:6', 'chooseOne:1', 'clearCorner:8'];

  Map<String, Object?> record(String id, String name, {Object? wording}) => {
    'id': id,
    'name': name,
    'need': Intention.clearerHead.name,
    'parts': valid,
    'createdAt': '2026-10-01T09:00:00.000',
    'fromCircleId': '2026-10-01-$id',
    'wording': ?wording,
  };

  String stored(List<Object?> kept) =>
      jsonEncode({'schemaVersion': keptCirclesSchemaVersion, 'kept': kept});

  Future<void> boot(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    SharedPreferences.resetStatic();
    prefs = await SharedPreferences.getInstance();
  }

  List<Map<String, Object?>> recorded() => [
    for (final wire in valid)
      PartWording.of(CirclePart.fromWire(wire)!.definition).toJson(),
  ];

  /// Saved words for part 2 ("Choose one thing") that THIRTY never recorded.
  List<Map<String, Object?>> editedSecond() {
    final words = recorded();
    words[1] = {...words[1], 'instruction': 'Pick the one thing that matters.'};
    return words;
  }

  ({ProviderContainer c, _RecordingVoice voice, _RecordingSession session})
  open({EntitlementStatus status = EntitlementStatus.active}) {
    final voice = _RecordingVoice();
    final session = _RecordingSession();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(morning),
        eventClockProvider.overrideWithValue(() => now),
        entitlementStatusProvider.overrideWith(() => _Status(status)),
        safetyPendingAllowedProvider.overrideWithValue(false),
        guidanceVoiceProvider.overrideWithValue(voice),
        guidanceSessionProvider.overrideWithValue(session),
      ],
    );
    addTearDown(c.dispose);
    keepGuidanceConducting(c);
    return (c: c, voice: voice, session: session);
  }

  /// Uses kept Circle 'a' today, starts it, and walks the clock through
  /// every part (6 + 1 + 8 minutes) to its end, then closes it.
  Future<void> runThrough(WidgetTester tester, ProviderContainer c) async {
    final today = c.read(recommendationProvider.notifier);
    expect(today.useOwnedToday(keptCircleId: 'a'), UseTodayResult.used);
    today.start();
    await tester.pump();
    for (final minutes in [6, 7, 15]) {
      now = morning.add(Duration(minutes: minutes, seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    }
    today.close();
    await tester.pump(const Duration(seconds: 1));
  }

  setUp(() async {
    now = morning;
    await boot({});
  });

  group('R6 — a kept Circle is voiced whole or not at all (D-B)', () {
    testWidgets('one part\'s saved words differ from the recording: nothing '
        'is said for the whole Circle — no opening, cue, ending or closing '
        'line — and no background session runs', (tester) async {
      await boot({
        keptCirclesKey: stored([
          record('a', 'Morning', wording: editedSecond()),
        ]),
      });
      final o = open();
      await runThrough(tester, o.c);
      expect(o.voice.said, isEmpty);
      expect(o.session.shown, isEmpty);
    });

    testWidgets('all saved words match the recording: spoken as before', (
      tester,
    ) async {
      await boot({
        keptCirclesKey: stored([record('a', 'Morning', wording: recorded())]),
      });
      final o = open();
      await runThrough(tester, o.c);
      final plan = CirclePlan.fromWire(valid)!;
      expect(o.voice.said, [
        [spokenOpening, ...spokenCueFor(plan, 0)],
        spokenCueFor(plan, 1),
        spokenCueFor(plan, 2),
        [spokenEnding],
        [spokenNextCircle],
      ]);
      expect(o.session.shown, isNotEmpty);
    });

    testWidgets('kept before words were saved: it shows the recorded words, '
        'so it is spoken — nothing guessed or written back', (tester) async {
      final legacy = stored([record('a', 'Old one')]);
      await boot({keptCirclesKey: legacy});
      final o = open();
      await runThrough(tester, o.c);
      expect(o.voice.said, isNotEmpty);
      expect(prefs.getString(keptCirclesKey), legacy);
    });

    testWidgets('the unvoiced Circle stays the user\'s: it runs to its end '
        'and closes, and the kept record is byte-identical', (tester) async {
      final saved = stored([record('a', 'Morning', wording: editedSecond())]);
      await boot({keptCirclesKey: saved});
      final o = open();
      await runThrough(tester, o.c);
      expect(
        o.c.read(recommendationProvider).status,
        RecommendationStatus.closed,
      );
      expect(o.c.read(keptCirclesProvider).kept.single.id, 'a');
      expect(prefs.getString(keptCirclesKey), saved);
    });

    test('the note: on every running part while THIRTY\'s voice is '
        'available; never without a voice, past the end, for a Circle whose '
        'words match, or one THIRTY composed', () {
      final plan = CirclePlan.fromWire(valid)!;
      final unvoiced = ComposedSession(
        plan: plan,
        keptCircleId: 'a',
        wording: [for (final w in editedSecond()) PartWording.fromJson(w)!],
      );
      expect(unvoiced.voiced, isFalse);
      for (final p in [0, 1, 2]) {
        expect(
          unvoiced.partNote(p, voiceAvailable: true),
          ComposedCopy.notSpokenCircle,
        );
        expect(unvoiced.partNote(p, voiceAvailable: false), isNull);
      }
      expect(unvoiced.partNote(3, voiceAvailable: true), isNull);
      final matching = ComposedSession(
        plan: plan,
        keptCircleId: 'a',
        wording: [for (final w in recorded()) PartWording.fromJson(w)!],
      );
      expect(matching.voiced, isTrue);
      expect(matching.partNote(1, voiceAvailable: true), isNull);
      final composed = ComposedSession(plan: plan, keptCircleId: null);
      expect(composed.voiced, isTrue);
      expect(composed.partNote(1, voiceAvailable: true), isNull);
    });

    test('a part corrected for safety shows the corrected words and its own '
        'note first; it no longer blocks the voice by itself', () {
      final plan = CirclePlan.fromWire(valid)!;
      final saved = [for (final w in recorded()) PartWording.fromJson(w)!];
      // Kept before a safety correction to part 1: an older revision.
      saved[0] = PartWording(
        name: saved[0].name,
        instruction: 'Older words.',
        safetyRevision: -1,
      );
      final session = ComposedSession(
        plan: plan,
        keptCircleId: 'a',
        wording: saved,
      );
      expect(
        session.wordingAt(0),
        PartWording.of(plan.parts[0].definition),
      );
      expect(session.voiced, isTrue);
      expect(
        session.partNote(0, voiceAvailable: true),
        ComposedCopy.correctedForSafety,
      );
    });

    testWidgets('a restart mid-Circle keeps it unvoiced', (tester) async {
      await boot({
        keptCirclesKey: stored([
          record('a', 'Morning', wording: editedSecond()),
        ]),
      });
      final first = open();
      final today = first.c.read(recommendationProvider.notifier);
      expect(today.useOwnedToday(keptCircleId: 'a'), UseTodayResult.used);
      today.start();
      await tester.pump(const Duration(seconds: 1));
      final values = <String, Object>{
        for (final key in prefs.getKeys()) key: prefs.get(key)!,
      };
      await boot(values);
      now = morning.add(const Duration(minutes: 7, seconds: 1));
      final again = open();
      await tester.pump(const Duration(seconds: 1));
      final restored = again.c.read(recommendationProvider);
      expect(restored.status, RecommendationStatus.started);
      expect(restored.recommendation!.composed!.voiced, isFalse);
      now = morning.add(const Duration(minutes: 15, seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(again.voice.said, isEmpty);
      expect(again.session.shown, isEmpty);
    });

    test('without Premium a kept Circle is still the user\'s to use; no '
        'voice is offered', () async {
      await boot({
        keptCirclesKey: stored([record('a', 'Morning', wording: recorded())]),
      });
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          nowProvider.overrideWithValue(morning),
          eventClockProvider.overrideWithValue(() => now),
          entitlementStatusProvider.overrideWith(
            () => _Status(EntitlementStatus.inactive),
          ),
          safetyPendingAllowedProvider.overrideWithValue(false),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(premiumEntitlementProvider), isFalse);
      expect(c.read(guidanceVoiceProvider).available, isFalse);
      expect(
        c
            .read(recommendationProvider.notifier)
            .useOwnedToday(keptCircleId: 'a'),
        UseTodayResult.used,
      );
    });
  });
}

class _Status extends EntitlementNotifier {
  _Status(this._status);
  final EntitlementStatus _status;
  @override
  EntitlementStatus build() => _status;
}

class _RecordingVoice implements GuidanceVoice {
  final said = <List<SpokenClip>>[];

  @override
  bool get available => true;

  @override
  Future<void> play(
    List<SpokenClip> clips, {
    bool deferToScreenReader = false,
    bool afterCurrent = false,
  }) async => said.add(clips);

  @override
  Future<void> stop() async {}
}

class _RecordingSession implements GuidanceSession {
  final shown = <GuidanceSessionStatus>[];

  @override
  Future<void> show(GuidanceSessionStatus status) async => shown.add(status);

  @override
  Future<void> end({bool afterSpeech = false}) async {}

  @override
  void listen(void Function(GuidanceAction action)? onAction) {}
}
