import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/app/thirty_app.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/personal_circle/application/guidance_conductor.dart';
import 'package:thirty/features/personal_circle/application/guidance_session.dart';
import 'package:thirty/features/personal_circle/application/guidance_voice.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/composed_session.dart';
import 'package:thirty/features/personal_circle/domain/spoken_cues.dart';
import 'package:thirty/features/settings/application/first_name_provider.dart';

/// R8.1 RL-2 (founder-approved copy, 2026-11-05): a saved Circle already
/// started whose own instructions can't be recovered shows today's
/// instructions with a note saying so — on every part, accessible, never
/// interrupting the Circle — and is never voiced.
void main() {
  const valid = ['getItOut:6', 'chooseOne:1', 'clearCorner:8'];
  const note =
      'Some saved instructions are unavailable. THIRTY is showing the current '
      'instructions, which may differ from what you saved. Spoken guidance '
      'isn’t available for this Circle.';
  final plan = CirclePlan.fromWire(valid)!;
  final morning = DateTime(2026, 10, 12, 9);

  test('the copy is exactly the approved wording', () {
    expect(
      ComposedCopy.unverifiedWordingTitle,
      'Some saved instructions are unavailable.',
    );
    expect(
      ComposedCopy.unverifiedWordingBody,
      'THIRTY is showing the current instructions, which may differ from '
      'what you saved. Spoken guidance isn’t available for this Circle.',
    );
  });

  test('shown on every part only when the fallback happens — with or '
      'without a voice — and never past the end', () {
    final unverified = ComposedSession(
      plan: plan,
      keptCircleId: 'a',
      wordingUnverified: true,
    );
    expect(unverified.voiced, isFalse);
    for (final p in [0, 1, 2]) {
      expect(unverified.partNote(p, voiceAvailable: true), note);
      expect(unverified.partNote(p, voiceAvailable: false), note);
    }
    expect(unverified.partNote(3, voiceAvailable: true), isNull);

    // Not the fallback: a kept Circle with its own (differing) words keeps
    // the existing note; one THIRTY composed has none.
    final ownWords = ComposedSession(
      plan: plan,
      keptCircleId: 'a',
      wording: [
        for (final p in plan.parts)
          PartWording(name: p.definition.name, instruction: 'Saved words.'),
      ],
    );
    expect(
      ownWords.partNote(0, voiceAvailable: true),
      ComposedCopy.notSpokenCircle,
    );
    expect(ownWords.partNote(0, voiceAvailable: false), isNull);
    expect(
      ComposedSession(
        plan: plan,
        keptCircleId: null,
      ).partNote(0, voiceAvailable: true),
      isNull,
    );
  });

  /// Today's started kept Circle, its saved words damaged, the kept Circle
  /// itself gone — the fallback.
  Map<String, Object> startedUnverified() => {
    firstNamePromptSeenKey: true,
    recommendationDayKey: '2026-10-12',
    recommendationIntentionKey: Intention.clearerHead.name,
    recommendationActivityIdKey: plan.main.definition.art.name,
    recommendationStatusKey: 'started',
    recommendationStartedAtKey: morning.toUtc().toIso8601String(),
    recommendationReasonKey: RecommendationReason.ownChoice.name,
    recommendationComposedKey: jsonEncode({
      'parts': valid,
      'keptCircleId': 'kept-gone',
      'keptName': 'Morning',
      'wording': [42, 'damaged'],
    }),
  };

  testWidgets('a running Circle shows the note to a screen reader, keeps '
      'running, and THIRTY\'s voice says nothing', (tester) async {
    final semantics = tester.ensureSemantics();
    SharedPreferences.setMockInitialValues(startedUnverified());
    final prefs = await SharedPreferences.getInstance();
    var now = morning.add(const Duration(minutes: 1));
    final voice = _RecordingVoice();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWith((ref) => now),
        eventClockProvider.overrideWithValue(() => now),
        entitlementStatusProvider.overrideWith(
          () => _Status(EntitlementStatus.active),
        ),
        safetyPendingAllowedProvider.overrideWithValue(false),
        guidanceVoiceProvider.overrideWithValue(voice),
        guidanceSessionProvider.overrideWithValue(_NoSession()),
      ],
    );
    addTearDown(c.dispose);
    keepGuidanceConducting(c);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const ThirtyApp()),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final state = c.read(recommendationProvider);
    expect(state.status, RecommendationStatus.started);
    expect(state.recommendation!.composed!.wordingUnverified, isTrue);
    expect(
      find.bySemanticsLabel(RegExp('Some saved instructions are unavailable')),
      findsWidgets,
    );
    expect(find.textContaining('Some saved instructions'), findsWidgets);

    now = morning.add(const Duration(minutes: 8));
    await tester.pump(const Duration(seconds: 1));
    expect(c.read(recommendationProvider).status, RecommendationStatus.started);
    expect(voice.said, isEmpty);
    semantics.dispose();
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

class _NoSession implements GuidanceSession {
  @override
  Future<void> show(GuidanceSessionStatus status) async {}

  @override
  Future<void> end({bool afterSpeech = false}) async {}

  @override
  void listen(void Function(GuidanceAction action)? onAction) {}
}
