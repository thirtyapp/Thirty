import 'dart:convert';

import 'package:flutter/material.dart';
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
import 'package:thirty/features/home/presentation/widgets/circle_session_card.dart';
import 'package:thirty/features/personal_circle/application/kept_circles_provider.dart';
import 'package:thirty/features/personal_circle/domain/circle_elements.dart';
import 'package:thirty/features/personal_circle/domain/composed_session.dart';
import 'package:thirty/features/personal_circle/domain/kept_circle.dart';
import 'package:thirty/features/personal_circle/presentation/keep_circle_card.dart';
import 'package:thirty/features/personal_circle/presentation/kept_circle_page.dart';
import 'package:thirty/features/personal_circle/presentation/yours_page.dart';

/// Audit remediation R4.1 — the kept-Circle store when a whole record can't
/// be read, more than once; the founder's notes for a safety correction and
/// for a part THIRTY's voice can't say; lengths retired for safety.
void main() {
  final morning = DateTime(2026, 10, 12, 9);
  late SharedPreferences prefs;

  const valid = ['getItOut:6', 'chooseOne:1', 'clearCorner:8'];

  Map<String, Object?> record(
    String id,
    String name, {
    List<String> parts = valid,
    Object? wording,
  }) => {
    'id': id,
    'name': name,
    'need': Intention.clearerHead.name,
    'parts': parts,
    'createdAt': '2026-10-01T09:00:00.000',
    'fromCircleId': '2026-10-01-$id',
    'wording': ?wording,
  };

  String stored(List<Object?> kept) =>
      jsonEncode({'schemaVersion': keptCirclesSchemaVersion, 'kept': kept});

  // Two whole records THIRTY can't read: one an earlier build set aside, one
  // in place now (a later build's version, or damage).
  const firstSetAside = '{"schemaVersion": 7, "kept": ["first original"]}';
  const secondInPlace = '{"schemaVersion": 9, "kept": ["second original"]}';

  Future<void> boot(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    SharedPreferences.resetStatic();
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> restart() async {
    await boot({for (final key in prefs.getKeys()) key: prefs.get(key)!});
  }

  ProviderContainer open({bool Function(CirclePart)? offerable}) {
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWithValue(morning),
        eventClockProvider.overrideWithValue(() => morning),
        entitlementStatusProvider.overrideWith(_Inactive.new),
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

  KeptCircle? keep(ProviderContainer c, String circleId) => c
      .read(keptCirclesProvider.notifier)
      .keepCircle(
        plan: CirclePlan.fromWire(valid)!,
        need: Intention.clearerHead,
        circleId: circleId,
      );

  setUp(() => boot({}));

  group('a whole record THIRTY can\'t read — and then another', () {
    test('the second never overwrites the first: both stay exactly as they '
        'were, through reads, attempted keeps, restarts', () async {
      await boot({
        keptCirclesUnreadableKey: firstSetAside,
        keptCirclesKey: secondInPlace,
      });
      for (var i = 0; i < 3; i++) {
        final c = open();
        final kept = c.read(keptCirclesProvider);
        expect(kept.kept, isEmpty);
        expect(kept.unreadable.map((s) => s.raw), [
          firstSetAside,
          secondInPlace,
        ]);
        expect(kept.countKnown, isFalse);
        expect(keep(c, '2026-10-1$i'), isNull, reason: 'count unknown');
        await settle();
        expect(prefs.getString(keptCirclesUnreadableKey), firstSetAside);
        expect(prefs.getString(keptCirclesKey), secondInPlace);
        await restart();
      }
    });

    test('a record in place that can\'t be read is never written over — not '
        'even by a direct write of the store', () async {
      await boot({keptCirclesKey: secondInPlace});
      final c = open();
      await c
          .read(keptCirclesRepositoryProvider)
          .write(KeptCircles([KeptCircle.fromJson(record('a', 'Morning'))!]));
      expect(prefs.getString(keptCirclesKey), secondInPlace);
      expect(prefs.getString(keptCirclesUnreadableKey), isNull);
    });

    test('readable Circles beside an earlier set-aside: renaming and '
        'removing them never touches it, and damaged records inside stay '
        'too; no keep while the count is unknown', () async {
      final damagedA = {'id': 'x', 'parts': 'not a list'};
      final damagedB = ['not', 'a', 'record'];
      await boot({
        keptCirclesUnreadableKey: firstSetAside,
        keptCirclesKey: stored([
          record('a', 'Morning'),
          damagedA,
          record('b', 'Evening'),
          damagedB,
        ]),
      });
      final c = open();
      final notifier = c.read(keptCirclesProvider.notifier);
      notifier.renameKept('a', 'Mine');
      notifier.deleteKept('b');
      await settle();
      final written =
          (jsonDecode(prefs.getString(keptCirclesKey)!) as Map)['kept'] as List;
      expect(written, hasLength(3));
      expect(written[1], damagedA);
      expect(written[2], damagedB);
      expect(prefs.getString(keptCirclesUnreadableKey), firstSetAside);
      expect(c.read(keptCirclesProvider).count, 3);
      expect(c.read(keptCirclesProvider).isFull, isTrue);
      expect(keep(c, '2026-10-11'), isNull);
      expect(
        KeepCircleCopy.fullFor(c.read(keptCirclesProvider)),
        KeepCircleCopy.countUnknown,
      );
    });

    test('export carries every one of them as stored', () async {
      await boot({
        keptCirclesUnreadableKey: firstSetAside,
        keptCirclesKey: secondInPlace,
      });
      final c = open();
      final kept = c.read(keptCirclesProvider);
      final exported =
          jsonDecode(
                c
                    .read(circleJournalRepositoryProvider)
                    .exportAsJson(
                      keptCirclesUnreadable: [
                        for (final store in kept.unreadable) store.raw,
                      ],
                    ),
              )
              as Map;
      expect(exported['keptCirclesUnreadable'], [firstSetAside, secondInPlace]);
    });

    test('only the user removes one; the other stays; once none is left, '
        'the count is known again and a Circle can be kept — after a '
        'restart too', () async {
      await boot({
        keptCirclesUnreadableKey: firstSetAside,
        keptCirclesKey: secondInPlace,
      });
      final c = open();
      final notifier = c.read(keptCirclesProvider.notifier);
      notifier.removeUnreadable('store-$keptCirclesUnreadableKey');
      await settle();
      expect(prefs.getString(keptCirclesUnreadableKey), isNull);
      expect(prefs.getString(keptCirclesKey), secondInPlace);
      expect(keep(c, '2026-10-11'), isNull);
      notifier.removeUnreadable('store-$keptCirclesKey');
      await settle();
      expect(c.read(keptCirclesProvider).countKnown, isTrue);
      expect(keep(c, '2026-10-11'), isNotNull);
      await settle();
      await restart();
      final kept = open().read(keptCirclesProvider);
      expect(kept.unreadable, isEmpty);
      expect(kept.kept, hasLength(1));
    });

    Future<ProviderContainer> pumpYours(
      WidgetTester tester, {
      double textScale = 1,
    }) async {
      tester.view.physicalSize = const Size(412, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = open();
      final router = GoRouter(
        initialLocation: YoursPage.location,
        routes: [
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

    for (final textScale in [1.0, 2.0]) {
      testWidgets('Yours shows them — never as Circles, never silently — and '
          'removing them asks first, in the founder\'s words '
          '(${textScale}x text)', (tester) async {
        await boot({
          keptCirclesUnreadableKey: firstSetAside,
          keptCirclesKey: stored([record('a', 'Morning')]),
        });
        final c = await pumpYours(tester, textScale: textScale);
        expect(find.text('Morning'), findsOneWidget);
        expect(find.text(KeptCircleCopy.unreadableStore), findsOneWidget);
        await tester.tap(find.text(KeptCircleCopy.unreadableStore));
        await tester.pumpAndSettle();
        expect(find.text(KeptCircleCopy.unreadableStoreNote), findsOneWidget);
        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Remove stored Circles?'), findsOneWidget);
        expect(
          find.text(
            'THIRTY can’t tell how many Circles are in this saved data. '
            'Removing it deletes all of them from this device. You can copy '
            'your history as text first.',
          ),
          findsOneWidget,
        );
        // Announced by its title.
        expect(
          tester.widget<AlertDialog>(find.byType(AlertDialog)).semanticLabel,
          'Remove stored Circles?',
        );
        // Cancel keeps everything, exactly.
        await tester.tap(find.text('Keep them'));
        await tester.pumpAndSettle();
        expect(prefs.getString(keptCirclesUnreadableKey), firstSetAside);
        // Confirmed: only that stored data goes; the readable Circle stays.
        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Remove'),
          ),
        );
        await tester.pumpAndSettle();
        expect(prefs.getString(keptCirclesUnreadableKey), isNull);
        expect(c.read(keptCirclesProvider).kept.single.name, 'Morning');
        expect(c.read(keptCirclesProvider).countKnown, isTrue);
        expect(find.text(KeptCircleCopy.unreadableStore), findsNothing);
      });
    }

    testWidgets('removing one kept Circle keeps its own confirmation — never '
        'the stored-data warning — and leaves stored data alone', (
      tester,
    ) async {
      await boot({
        keptCirclesUnreadableKey: firstSetAside,
        keptCirclesKey: stored([record('a', 'Morning')]),
      });
      final c = await pumpYours(tester);
      await tester.tap(find.text('Morning'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.text('Remove Morning?'), findsOneWidget);
      expect(
        find.text('It leaves Yours. Days you used it stay in your history.'),
        findsOneWidget,
      );
      expect(find.text('Remove stored Circles?'), findsNothing);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Remove'),
        ),
      );
      await tester.pumpAndSettle();
      expect(c.read(keptCirclesProvider).kept, isEmpty);
      expect(prefs.getString(keptCirclesUnreadableKey), firstSetAside);
      expect(c.read(keptCirclesProvider).unreadable, hasLength(1));
    });
  });

  group('the founder\'s notes on a kept part', () {
    List<Map<String, Object?>> savedWords() => [
      for (final wire in valid)
        PartWording.of(CirclePart.fromWire(wire)!.definition).toJson(),
    ];

    test(
      'words corrected for safety since it was kept: the corrected words '
      'show, with the founder\'s note; the saved record is unchanged',
      () async {
        final saved = savedWords();
        // Saved before a safety correction (an earlier revision).
        saved[0] = {
          ...saved[0],
          'instruction': 'Old words.',
          'safetyRevision': -1,
        };
        await boot({
          keptCirclesKey: stored([record('a', 'Morning', wording: saved)]),
        });
        final c = open();
        final circle = c.read(keptCirclesProvider).kept.single;
        expect(circle.correctedForSafetyAt(0), isTrue);
        expect(circle.correctedForSafetyAt(1), isFalse);
        expect(
          circle.wordingAt(0).instruction,
          elementOf(ElementId.getItOut).instruction,
        );
        final session = ComposedSession(
          plan: circle.plan,
          keptCircleId: 'a',
          keptName: 'Morning',
          wording: circle.wording,
        );
        expect(
          session.partNote(0, voiceAvailable: true),
          'This part has updated guidance for safety. Your saved Circle is '
          'unchanged.',
        );
        expect(session.partNote(1, voiceAvailable: true), isNull);
        c.read(keptCirclesProvider.notifier).renameKept('a', 'Mine');
        await settle();
        final written =
            ((jsonDecode(prefs.getString(keptCirclesKey)!) as Map)['kept']
                        as List)
                    .single
                as Map;
        expect(
          ((written['wording'] as List)[0] as Map)['instruction'],
          'Old words.',
        );
      },
    );

    // R6 (founder decision 2026-11-03): one part's differing saved words
    // leave the whole Circle unvoiced, so every running part says so — not
    // only the part that differs (it was per part in R4.1).
    test('saved words the recording doesn\'t say: the whole Circle is noted '
        'while THIRTY\'s voice is available; nothing said when there is no '
        'voice', () {
      final saved = [
        for (final wire in valid)
          PartWording.of(CirclePart.fromWire(wire)!.definition),
      ];
      saved[1] = PartWording(name: saved[1].name, instruction: 'Pick one.');
      final session = ComposedSession(
        plan: CirclePlan.fromWire(valid)!,
        keptCircleId: 'a',
        wording: saved,
      );
      expect(
        session.partNote(1, voiceAvailable: true),
        ComposedCopy.notSpokenCircle,
      );
      expect(session.partNote(1, voiceAvailable: false), isNull);
      expect(
        session.partNote(0, voiceAvailable: true),
        ComposedCopy.notSpokenCircle,
      );
      expect(session.partNote(0, voiceAvailable: false), isNull);
      // Past the last part the ending shows: nothing to say, nothing read.
      expect(session.partNote(3, voiceAvailable: true), isNull);
      // A Circle THIRTY composed has no saved words: never a note.
      final composed = ComposedSession(
        plan: CirclePlan.fromWire(valid)!,
        basis: null,
        keptCircleId: null,
      );
      expect(composed.partNote(1, voiceAvailable: true), isNull);
    });

    testWidgets('the running part shows the note, and a screen reader hears '
        'it with the part', (tester) async {
      final plan = CirclePlan.fromWire(valid)!;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CircleSessionCard(
              activity: sessionForPlan(plan, title: 'Morning'),
              body: SessionBody.composed,
              elapsed: Duration.zero,
              offered: const Duration(minutes: 15),
              guidedPosition: 0,
              paused: false,
              ended: false,
              onShowGuide: null,
              onMoveTo: (_) {},
              onPause: () {},
              onResume: () {},
              partMoment: partMomentFor(
                plan,
                anchorPosition: 0,
                anchorElapsed: Duration.zero,
                elapsed: Duration.zero,
              ),
              partNote: ComposedCopy.notSpokenCircle,
            ),
          ),
        ),
      );
      expect(find.text(ComposedCopy.notSpokenCircle), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(ComposedCopy.notSpokenCircle)),
        findsOneWidget,
      );
    });
  });

  group('a length retired for safety', () {
    test('a part at that length never runs; its Circle stays as kept — '
        'never shortened — and readable; an older record falls back to the '
        'catalogue\'s words, under the same gate', () async {
      const element = CircleElement(
        id: ElementId.getItOut,
        name: 'Get it out',
        instruction: 'x',
        needs: {Intention.clearerHead},
        roles: {ElementRole.main},
        minutes: 6,
        shortMinutes: 4,
        kind: ElementKind.writing,
        setting: ActivitySetting.either,
        art: ActivityId.writeItDown,
        retiredLengths: {8},
      );
      expect(isPartOffered(element, 8), isFalse);
      expect(isPartOffered(element, 6), isTrue);

      // A pre-R4 record (no saved words), with a length now retired.
      await boot({
        keptCirclesKey: stored([
          record('old', 'Old one', parts: ['getItOut:8', 'chooseOne:1']),
        ]),
      });
      bool offerable(CirclePart p) =>
          !(p.element == ElementId.getItOut && p.minutes == 8);
      final c = open(offerable: offerable);
      final circle = c.read(keptCirclesProvider).kept.single;
      expect(circle.wording, isNull);
      expect(
        circle.wordingAt(0).instruction,
        elementOf(ElementId.getItOut).instruction,
      );
      expect(
        c
            .read(recommendationProvider.notifier)
            .useOwnedToday(keptCircleId: 'old'),
        UseTodayResult.unavailable,
      );
      expect(circle.plan.toWire(), ['getItOut:8', 'chooseOne:1']);
      expect(keptPartsNotOffered(circle, offerable).single.minutes, 8);
    });
  });
}

class _Inactive extends EntitlementNotifier {
  @override
  EntitlementStatus build() => EntitlementStatus.inactive;
}
