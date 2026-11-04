import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/widgets/journal_data_controls.dart';
import 'package:thirty/features/insights/application/insights_provider.dart';
import 'package:thirty/features/personal_circle/application/guidance_conductor.dart';
import 'package:thirty/features/personal_circle/application/guidance_session.dart';
import 'package:thirty/features/personal_circle/application/guidance_voice.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/composed_session.dart';
import 'package:thirty/features/personal_circle/domain/kept_circle.dart';
import 'package:thirty/features/personal_circle/domain/spoken_cues.dart';
import 'package:thirty/features/personal_circle/presentation/kept_circle_page.dart';
import 'package:thirty/features/personal_circle/presentation/use_today_control.dart';
import 'package:thirty/features/personal_circle/presentation/yours_page.dart';

/// Audit remediation R4 — a kept Circle is the user's: read back as it was
/// kept, never as today's catalogue would make it, and never dropped
/// (J6, Audit #1 F2, Audit #2 A2-03).
///
/// The stored records below stand for what an earlier catalogue wrote: a
/// length since retuned, an element id since removed or renamed, words since
/// edited, a damaged record. Nothing is a round trip through today's
/// catalogue only.
void main() {
  final morning = DateTime(2026, 10, 12, 9);
  late SharedPreferences prefs;

  const valid = ['getItOut:6', 'chooseOne:1', 'clearCorner:8'];
  // A length "Get it out" was once authored at, and no longer is.
  final retunedLength = [
    for (var m = 1; m < 30; m++) m,
  ].firstWhere((m) => !elementOf(ElementId.getItOut).lengths.contains(m));
  final retuned = ['getItOut:$retunedLength', 'chooseOne:1', 'clearCorner:8'];

  Map<String, Object?> record(
    String id,
    String name, {
    List<String> parts = valid,
    Intention need = Intention.clearerHead,
    Object? wording,
    String? fromCircleId,
    Map<String, Object?> more = const {},
  }) => {
    'id': id,
    'name': name,
    'need': need.name,
    'parts': parts,
    'createdAt': '2026-10-01T09:00:00.000',
    'fromCircleId': fromCircleId ?? '2026-10-01-$id',
    'wording': ?wording,
    ...more,
  };

  String stored(List<Object?> kept) =>
      jsonEncode({'schemaVersion': keptCirclesSchemaVersion, 'kept': kept});

  Future<void> boot(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    SharedPreferences.resetStatic();
    prefs = await SharedPreferences.getInstance();
  }

  /// The next start, on what was written.
  Future<void> restart() async {
    final values = <String, Object>{
      for (final key in prefs.getKeys()) key: prefs.get(key)!,
    };
    await boot(values);
  }

  ProviderContainer open({
    EntitlementStatus status = EntitlementStatus.inactive,
    bool Function(CirclePart)? offerable,
  }) {
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(morning),
        eventClockProvider.overrideWithValue(() => morning),
        entitlementStatusProvider.overrideWith(() => _Status(status)),
        safetyPendingAllowedProvider.overrideWithValue(false),
        if (offerable != null)
          partOfferableProvider.overrideWithValue(offerable),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  KeptCircles keptOf(ProviderContainer c) => c.read(keptCirclesProvider);
  List<Object?> storedKept() =>
      (jsonDecode(prefs.getString(keptCirclesKey)!) as Map)['kept'] as List;

  setUp(() => boot({}));

  group('read back as kept, whatever the catalogue does later', () {
    test(
      '1. a Circle valid in today\'s catalogue reads as it was kept',
      () async {
        await boot({
          keptCirclesKey: stored([record('a', 'Morning')]),
        });
        final circle = keptOf(open()).kept.single;
        expect(circle.plan.toWire(), valid);
        expect(circle.name, 'Morning');
        expect(circle.need, Intention.clearerHead);
      },
    );

    test('2. a part whose length was retuned since: kept at the length it '
        'was kept with — never dropped, never re-lengthened', () async {
      await boot({
        keptCirclesKey: stored([record('a', 'Morning', parts: retuned)]),
      });
      final circle = keptOf(open()).kept.single;
      expect(circle.plan.toWire(), retuned);
      expect(circle.minutes, retunedLength + 1 + 8);
    });

    for (final (what, wire) in [
      ('3. an element id since removed', 'oldCalmingThing:5'),
      ('4. an element id since renamed', 'getItAllOut:6'),
    ]) {
      test('$what: the Circle stays — kept as stored, in its place, '
          'named, never guessed into another', () async {
        final unknown = record(
          'b',
          'Evening',
          parts: ['chooseOne:1', wire, 'clearCorner:8'],
        );
        await boot({
          keptCirclesKey: stored([record('a', 'Morning'), unknown]),
        });
        final kept = keptOf(open());
        expect(kept.kept.map((k) => k.id), ['a']);
        expect(kept.retained.single.stored, unknown);
        expect(kept.retained.single.name, 'Evening');
        expect(kept.count, 2);
      });
    }

    test('5. words edited in the catalogue since: the Circle keeps the words '
        'it was kept with, on its page and when it runs; only parts whose '
        'words still match the recording are voiced', () async {
      final saved = [
        for (final wire in valid)
          PartWording.of(CirclePart.fromWire(wire)!.definition).toJson(),
      ];
      saved[0] = {
        ...saved[0],
        'instruction': 'Write down everything on your mind, as it comes.',
      };
      await boot({
        keptCirclesKey: stored([record('a', 'Morning', wording: saved)]),
      });
      final c = open();
      final circle = keptOf(c).kept.single;
      expect(
        circle.wordingAt(0).instruction,
        'Write down everything on your mind, as it comes.',
      );
      expect(
        circle.wordingAt(1).instruction,
        elementOf(ElementId.chooseOne).instruction,
      );
      expect(
        c
            .read(recommendationProvider.notifier)
            .useOwnedToday(keptCircleId: 'a'),
        UseTodayResult.used,
      );
      final today = c.read(recommendationProvider).recommendation!;
      expect(
        today.sessionDefinition.steps.first.instruction,
        'Write down everything on your mind, as it comes.',
      );
      final composed = today.composed!;
      expect(composed.voicedAt(0), isFalse);
      expect(composed.voicedAt(1), isTrue);
      expect(composed.voicedAt(2), isTrue);
      // The words survive a restart of today's Circle too.
      await settle();
      await restart();
      final again = open().read(recommendationProvider).recommendation!;
      expect(
        again.sessionDefinition.steps.first.instruction,
        'Write down everything on your mind, as it comes.',
      );
    });

    test('a Circle kept now saves the words each part has now', () async {
      final c = open();
      final kept = (await c
          .read(keptCirclesProvider.notifier)
          .keepCircle(
            plan: CirclePlan.fromWire(valid)!,
            need: Intention.clearerHead,
            circleId: '2026-10-11',
          ))!;
      await settle();
      expect(kept.wording, [
        for (final p in kept.plan.parts) PartWording.of(p.definition),
      ]);
      final written = storedKept().single as Map;
      expect((written['wording'] as List).length, 3);
    });

    test('7. a legacy Circle (kept before words were saved) reads beside a '
        'current one — shown with its elements\' own words, never guessed '
        'into saved ones, and written back without inventing any', () async {
      final legacy = record('old', 'Old one');
      await boot({
        keptCirclesKey: stored([
          legacy,
          record(
            'new',
            'New one',
            wording: [
              for (final wire in valid)
                PartWording.of(CirclePart.fromWire(wire)!.definition).toJson(),
            ],
          ),
        ]),
      });
      final c = open();
      final old = keptOf(c).keptById('old')!;
      expect(old.wording, isNull);
      expect(
        old.wordingAt(0).instruction,
        elementOf(ElementId.getItOut).instruction,
      );
      c.read(keptCirclesProvider.notifier).renameKept('new', 'Newer');
      await settle();
      expect((storedKept().first as Map).containsKey('wording'), isFalse);
    });
  });

  group('never dropped, never rewritten from the survivors', () {
    final damaged = {'id': 'x', 'parts': 'not a list', 'name': 42};

    test('6. one damaged record beside seven good ones: all eight count, all '
        'eight show in Yours, and an eighth Circle can\'t be kept', () async {
      await boot({
        keptCirclesKey: stored([
          for (var i = 0; i < 3; i++) record('k$i', 'Circle $i'),
          damaged,
          for (var i = 3; i < 7; i++) record('k$i', 'Circle $i'),
        ]),
      });
      final c = open();
      final kept = keptOf(c);
      expect(kept.kept, hasLength(7));
      expect(kept.retained.single.stored, damaged);
      expect(kept.retained.single.position, 3);
      expect(kept.count, maxKeptCircles);
      expect(kept.isFull, isTrue);
      expect(
        await c
            .read(keptCirclesProvider.notifier)
            .keepCircle(
              plan: CirclePlan.fromWire(valid)!,
              need: Intention.clearerHead,
              circleId: '2026-10-11',
            ),
        isNull,
        reason: '10. the limit counts the one THIRTY can\'t read',
      );
    });

    for (final (what, act) in [
      (
        '8. renaming another',
        (KeptCirclesNotifier n) => n.renameKept('a', 'Mine'),
      ),
      ('9. removing another', (KeptCirclesNotifier n) => n.deleteKept('a')),
    ]) {
      test('$what Circle while one can\'t be read: that one is written back '
          'exactly as stored, in its place', () async {
        final unknown = record('b', 'Evening', parts: ['oldThing:5']);
        await boot({
          keptCirclesKey: stored([
            record('a', 'Morning'),
            unknown,
            damaged,
            record('c', 'Night', parts: retuned),
          ]),
        });
        act(open().read(keptCirclesProvider.notifier));
        await settle();
        final written = storedKept();
        int at(Object record) =>
            written.indexWhere((r) => equals(record).matches(r, {}));
        expect(at(unknown), isNot(-1));
        expect(at(damaged), isNot(-1));
        expect(at(unknown) < at(damaged), isTrue);
        final night = written.firstWhere((r) => (r as Map)['id'] == 'c') as Map;
        expect(night['parts'], retuned, reason: 'its own lengths, kept');
        // 14. And after a restart, all of it is still there.
        await restart();
        final kept = keptOf(open());
        expect(kept.retained.map((r) => r.stored), [unknown, damaged]);
        expect(kept.keptById('c')!.plan.toWire(), retuned);
      });
    }

    test('fields a later build added are written back, not dropped', () async {
      await boot({
        keptCirclesKey: stored([
          record('a', 'Morning', more: {'colour': 'sage', 'pinned': true}),
        ]),
      });
      open().read(keptCirclesProvider.notifier).renameKept('a', 'Mine');
      await settle();
      final written = storedKept().single as Map;
      expect(written['colour'], 'sage');
      expect(written['pinned'], true);
      expect(written['name'], 'Mine');
    });

    test('13. one THIRTY can\'t read is renamed or removed only by the user, '
        'and nothing else in it changes', () async {
      final unknown = record('b', 'Evening', parts: ['oldThing:5']);
      await boot({
        keptCirclesKey: stored([record('a', 'Morning'), unknown, damaged]),
      });
      final c = open();
      final notifier = c.read(keptCirclesProvider.notifier);
      notifier.renameKept('b', 'Late');
      await settle();
      expect(storedKept()[1], {...unknown, 'name': 'Late'});
      final damagedKey = keptOf(c).retained.last.key;
      expect(keptOf(c).retained.last.canRename, isTrue);
      notifier.deleteKept(damagedKey);
      notifier.deleteKept('b');
      await settle();
      expect(storedKept(), hasLength(1));
      expect(keptOf(c).count, 1);
    });

    test('11. export keeps every kept Circle as stored — one THIRTY can\'t '
        'read, and a whole record set aside as unreadable', () async {
      final unknown = record('b', 'Evening', parts: ['oldThing:5']);
      await boot({
        keptCirclesKey: stored([record('a', 'Morning'), unknown]),
        keptCirclesUnreadableKey: '{"schemaVersion": 9, "kept": ["future"]}',
      });
      final c = open();
      final kept = keptOf(c);
      final exported =
          jsonDecode(
                c
                    .read(circleJournalRepositoryProvider)
                    .exportAsJson(
                      keptCircles:
                          keptCirclesRecord(
                                kept.kept,
                                retained: kept.retained,
                              )['kept']
                              as List<Object?>,
                      keptCirclesUnreadable: [
                        for (final store in kept.unreadable) store.raw,
                      ],
                    ),
              )
              as Map;
      expect(exported['keptCircles'], storedKept());
      expect(exported['keptCirclesUnreadable'], [
        '{"schemaVersion": 9, "kept": ["future"]}',
      ]);
    });
  });

  group('use: owned whatever Premium\'s state; never past a safety gate', () {
    for (final status in [
      EntitlementStatus.inactive,
      EntitlementStatus.active,
      EntitlementStatus.unavailable,
    ]) {
      test('12. ${status.name}: a kept Circle — one with a retuned length '
          'too — runs as kept, at its own length, and restarts so', () async {
        await boot({
          keptCirclesKey: stored([record('a', 'Morning', parts: retuned)]),
        });
        final c = open(status: status);
        expect(
          c
              .read(recommendationProvider.notifier)
              .useOwnedToday(keptCircleId: 'a'),
          UseTodayResult.used,
        );
        final today = c.read(recommendationProvider).recommendation!;
        expect(today.offeredMinutes, retunedLength + 1 + 8);
        expect(today.composed!.plan.toWire(), retuned);
        await settle();
        await restart();
        final again = open(status: status);
        final restored = again.read(recommendationProvider).recommendation!;
        expect(restored.composed!.keptCircleId, 'a');
        expect(restored.composed!.plan.toWire(), retuned);
      });
    }

    test('15. a part THIRTY no longer offers (retired, or awaiting the '
        'safety review): the Circle stays, readable and theirs, but isn\'t '
        'run — and its page says so truthfully', () async {
      await boot({
        keptCirclesKey: stored([record('a', 'Morning')]),
      });
      bool offerable(CirclePart p) => p.element != ElementId.chooseOne;
      final c = open(offerable: offerable);
      expect(
        c
            .read(recommendationProvider.notifier)
            .useOwnedToday(keptCircleId: 'a'),
        UseTodayResult.unavailable,
      );
      expect(c.read(recommendationProvider).recommendation, isNull);
      expect(keptOf(c).kept.single.plan.toWire(), valid);
      expect(
        keptPartsNotOffered(
          keptOf(c).kept.single,
          offerable,
        ).map((p) => p.element),
        [ElementId.chooseOne],
      );
    });

    test(
      '16. nothing awaiting the safety review is unlocked — in any build, '
      'saved words or not; a record THIRTY can\'t read is never run',
      () async {
        const pending = CircleElement(
          id: ElementId.getItOut,
          name: 'x',
          instruction: 'x',
          needs: {Intention.clearerHead},
          roles: {ElementRole.main},
          minutes: 5,
          kind: ElementKind.writing,
          setting: ActivitySetting.either,
          art: ActivityId.writeItDown,
          status: ActivityStatus.safetyReviewPending,
        );
        expect(isElementOfferable(pending), isFalse);
        // The default gate is the catalogue's own, whatever the build.
        final c = open();
        expect(isPartOffered(pending, 5), isFalse);
        expect(
          c.read(partOfferableProvider)(CirclePart.fromWire('getItOut:6')!),
          isTrue,
        );
        await boot({
          keptCirclesKey: stored([
            record('b', 'Evening', parts: ['oldThing:5']),
          ]),
        });
        final d = open();
        expect(
          d
              .read(recommendationProvider.notifier)
              .useOwnedToday(keptCircleId: 'b'),
          UseTodayResult.unavailable,
        );
      },
    );

    test('a safety correction to an element\'s words supersedes saved words '
        'from before it; the saved record itself is unchanged', () {
      final part = CirclePart.fromWire('getItOut:6')!;
      const saved = PartWording(
        name: 'Get it out',
        instruction: 'Old words, before a correction.',
      );
      final shown = partWordingFor(part, saved, safetyRevisionOf: (_) => 1);
      expect(shown.instruction, elementOf(ElementId.getItOut).instruction);
      expect(shown.safetyRevision, 1);
      expect(saved.instruction, 'Old words, before a correction.');
      // No correction since: the saved words stand.
      expect(partWordingFor(part, saved), saved);
    });
  });

  // R6 (founder decision 2026-11-03) replaced R4's per-part rule: one part
  // whose saved words differ leaves the whole Circle unvoiced. The matching
  // parts used to be spoken; nothing is now. Full cases:
  // r6_kept_voice_whole_circle_test.dart.
  testWidgets('a kept part whose saved words differ from the recording: the '
      'whole Circle runs on screen, unvoiced — matching parts too', (
    tester,
  ) async {
    final saved = [
      for (final wire in valid)
        PartWording.of(CirclePart.fromWire(wire)!.definition).toJson(),
    ];
    saved[1] = {...saved[1], 'instruction': 'Pick the one thing that matters.'};
    await boot({
      keptCirclesKey: stored([record('a', 'Morning', wording: saved)]),
    });
    var now = morning;
    final voice = _RecordingVoice();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(morning),
        eventClockProvider.overrideWithValue(() => now),
        entitlementStatusProvider.overrideWith(
          () => _Status(EntitlementStatus.active),
        ),
        safetyPendingAllowedProvider.overrideWithValue(false),
        guidanceVoiceProvider.overrideWithValue(voice),
        guidanceSessionProvider.overrideWithValue(_QuietSession()),
      ],
    );
    addTearDown(c.dispose);
    keepGuidanceConducting(c);
    final today = c.read(recommendationProvider.notifier);
    expect(today.useOwnedToday(keptCircleId: 'a'), UseTodayResult.used);
    today.start();
    await tester.pump();
    final composed = c.read(recommendationProvider).recommendation!.composed!;
    expect(composed.voicedAt(0), isTrue);
    expect(composed.voicedAt(1), isFalse);
    expect(composed.voiced, isFalse);
    // The user's Start: no opening, no cue — part 1's words match, but the
    // Circle as a whole isn't the recorded one.
    expect(voice.said, isEmpty);
    // Part 2 ("Choose one thing"): its saved words aren't the recorded ones.
    now = morning.add(const Duration(minutes: 6, seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(voice.said, isEmpty);
    // Part 3: its words match — still unspoken.
    now = morning.add(const Duration(minutes: 7, seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(voice.said, isEmpty);
    today.close();
    await tester.pump(const Duration(seconds: 1));
    expect(voice.said, isEmpty);
  });

  group('Yours shows every kept Circle, truthfully', () {
    Future<ProviderContainer> pump(
      WidgetTester tester,
      String location, {
      bool Function(CirclePart)? offerable,
      double textScale = 1,
    }) async {
      tester.view.physicalSize = const Size(412, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = open(offerable: offerable);
      final router = GoRouter(
        initialLocation: location,
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('TODAY')),
          GoRoute(
            path: YoursPage.location,
            builder: (_, _) => const YoursPage(),
          ),
          GoRoute(
            path: KeptCirclePage.pathPattern,
            builder: (_, state) =>
                KeptCirclePage(keptId: state.pathParameters['id']!),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('a Circle THIRTY can\'t read stays in the list and opens to a '
        'calm note — rename and remove, no way to run it', (tester) async {
      await boot({
        keptCirclesKey: stored([
          record('a', 'Morning'),
          record('b', 'Evening', parts: ['oldThing:5']),
          {'parts': 'damaged'},
        ]),
      });
      await pump(tester, YoursPage.location);
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Evening'), findsOneWidget);
      expect(find.text(KeptCircleCopy.unnamed), findsOneWidget);
      expect(find.text(KeptCircleCopy.unreadableLine), findsNWidgets(2));

      await tester.tap(find.text('Evening'));
      await tester.pumpAndSettle();
      expect(find.text(KeptCircleCopy.unreadable), findsOneWidget);
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
      expect(find.text(UseTodayCopy.action), findsNothing);
    });

    testWidgets('a kept Circle with a part no longer offered: its page says '
        'so — never that the user asked for it — and offers no Use it '
        'today', (tester) async {
      await boot({
        keptCirclesKey: stored([record('a', 'Morning')]),
      });
      await pump(
        tester,
        KeptCirclePage.locationFor('a'),
        offerable: (p) => p.element != ElementId.chooseOne,
      );
      expect(
        find.text(KeptCircleCopy.notOffered(['Choose one thing'])),
        findsOneWidget,
      );
      expect(find.textContaining('you asked'), findsNothing);
      expect(find.text(UseTodayCopy.action), findsNothing);
      expect(find.text('Rename'), findsOneWidget);
    });

    testWidgets('at 2× text the note for a Circle THIRTY can\'t read reads in '
        'full', (tester) async {
      await boot({
        keptCirclesKey: stored([
          record('b', 'Evening', parts: ['oldThing:5']),
        ]),
      });
      await pump(tester, KeptCirclePage.locationFor('b'), textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text(KeptCircleCopy.unreadable), findsOneWidget);
    });

    testWidgets('Copy as text exports kept Circles as stored, one THIRTY '
        'can\'t read included', (tester) async {
      final unknown = record('b', 'Evening', parts: ['oldThing:5']);
      await boot({
        keptCirclesKey: stored([record('a', 'Morning'), unknown]),
      });
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final c = open();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: JournalDataControls()),
          ),
        ),
      );
      await tester.tap(find.text('Copy as text'));
      await tester.pumpAndSettle();
      final exported = jsonDecode(copied!) as Map;
      expect(exported['keptCircles'], [record('a', 'Morning'), unknown]);
      expect(c.read(insightsProvider).snapshots, isEmpty);
    });
  });

  test('a kept Circle composed into today restores its own lengths after a '
      'restart, but a Circle THIRTY composed still needs today\'s', () {
    final kept = ComposedSession.fromJson({
      'parts': retuned,
      'keptCircleId': 'a',
      'keptName': 'Morning',
    });
    expect(kept!.plan.toWire(), retuned);
    final composed = ComposedSession.fromJson({
      'parts': retuned,
      'basis': 'sized',
    });
    expect(composed, isNull);
  });
}

class _Status extends EntitlementNotifier {
  _Status(this._status);
  final EntitlementStatus _status;
  @override
  EntitlementStatus build() => _status;
}

/// A voice that only remembers what it was asked to play.
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

/// A background session that shows nothing.
class _QuietSession implements GuidanceSession {
  @override
  Future<void> show(GuidanceSessionStatus status) async {}

  @override
  Future<void> end({bool afterSpeech = false}) async {}

  @override
  void listen(void Function(GuidanceAction action)? onAction) {}
}
