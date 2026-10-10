import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show DebugSemanticsDumpOrder, SemanticsNode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/app_theme.dart';
import 'package:thirty/core/worlds/world.dart' show Daypart;
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/application/suggestion_preferences.dart';
import 'package:thirty/features/toolkit/application/toolkit_provider.dart';
import 'package:thirty/features/toolkit/domain/module_library.dart';
import 'package:thirty/features/toolkit/domain/path_catalog.dart';
import 'package:thirty/features/toolkit/domain/toolkit_model.dart';
import 'package:thirty/features/toolkit/presentation/path_review_page.dart';
import 'package:thirty/features/toolkit/presentation/path_start_page.dart';
import 'package:thirty/features/toolkit/presentation/routine_detail_page.dart';
import 'package:thirty/features/toolkit/presentation/toolkit_page.dart';
import 'package:thirty/features/toolkit/presentation/widgets/toolkit_header_art.dart';

/// V2 Phase D — the Toolkit's pages (ADR-022): every state of the Toolkit,
/// the Path's start and review, a routine's page — calm, owned, honest,
/// and readable at large text.

final _now = DateTime(2026, 11, 20, 9);

Routine _routine({
  String id = 'r',
  String name = 'My pick-me-up',
  bool enabled = true,
  int createdDaysAgo = 30,
  bool withEarlier = false,
}) {
  final created = _now.subtract(Duration(days: createdDaysAgo));
  final v1 = RoutineVersion(
    id: '$id-v1',
    number: 1,
    composition: Composition(const [
      ModuleUse(ModuleId.standingStretch, short: false),
      ModuleUse(ModuleId.musicMove, short: false),
    ]),
    createdAt: created,
    origin: VersionOrigin.path,
  );
  final v2 = RoutineVersion(
    id: '$id-v2',
    number: 2,
    composition: Composition(const [
      ModuleUse(ModuleId.standingStretch, short: false),
      ModuleUse(ModuleId.activeTask, short: true),
    ]),
    createdAt: created.add(const Duration(days: 10)),
    origin: VersionOrigin.tuneUp,
  );
  return Routine(
    id: id,
    name: name,
    need: Intention.moreEnergy,
    versions: [v1, if (withEarlier) v2],
    activeVersionId: withEarlier ? v2.id : v1.id,
    createdAt: created,
    sourceTemplate: PathTemplateId.wakeUpIndoors,
    enabled: enabled,
  );
}

PathRun _path({
  int circles = 2,
  PathTemplateId t = PathTemplateId.wakeUpIndoors,
}) {
  var run = PathRun(
    id: 'p',
    kind: PathKind.build,
    need: pathTemplate(t).need,
    startedAt: _now.subtract(const Duration(days: 10)),
    pool: pathTemplate(t).pool,
    seed: SeedReason.sparseStart,
    template: t,
  );
  for (var i = 0; i < circles; i++) {
    run = run.withCircle(
      PathCircle(
        circleId: '2026-11-${(10 + i).toString().padLeft(2, '0')}',
        number: i + 1,
        composition: Composition([ModuleUse(run.pool[i % 2], short: true)]),
        reason: PathStepReason.firstTry,
      ),
    );
  }
  return run;
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget page, {
  ToolkitState toolkit = ToolkitState.empty,
  bool entitled = true,
  double textScale = 1,
  Size size = const Size(412, 915),
  Map<String, Object> extra = const {},
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    toolkitStateKey: jsonEncode(toolkit.toJson()),
    ...extra,
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(_now),
      eventClockProvider.overrideWithValue(() => _now),
      premiumEntitlementProvider.overrideWithValue(entitled),
      safetyPendingAllowedProvider.overrideWithValue(false),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => page),
      GoRoute(
        path: '/toolkit',
        builder: (_, _) => const Text('toolkit root'),
        routes: [
          GoRoute(path: 'paths', builder: (_, _) => const Text('paths')),
          GoRoute(
            path: 'paths/:t',
            builder: (_, s) => Text('start ${s.pathParameters['t']}'),
          ),
          GoRoute(path: 'review', builder: (_, _) => const Text('review')),
          GoRoute(
            path: 'routine/:id',
            builder: (_, s) => Text('routine ${s.pathParameters['id']}'),
          ),
        ],
      ),
      GoRoute(path: '/premium', builder: (_, _) => const Text('premium')),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('the Toolkit, in each of its states', () {
    testWidgets('A — Free, nothing built: what Premium builds, without '
        'making Free look unfinished', (tester) async {
      await _pump(tester, const ToolkitPage(), entitled: false);
      expect(find.text('A few routines of your own'), findsOneWidget);
      expect(find.textContaining('Free stays complete'), findsOneWidget);
      expect(find.textContaining('stay yours'), findsOneWidget);
      expect(find.text('See Premium'), findsOneWidget);
    });

    testWidgets('B — Premium, nothing built: one sensible first Path, with '
        'nothing claimed without evidence', (tester) async {
      await _pump(tester, const ToolkitPage());
      expect(find.text('Your first Path'.toUpperCase()), findsOneWidget);
      expect(find.text(pathCatalog.first.name), findsOneWidget);
      expect(
        find.text('A simple place to start. You can choose another Path.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Look at this Path'));
      await tester.tap(find.text('Look at this Path'));
      await tester.pumpAndSettle();
      expect(find.text('start wakeUpIndoors'), findsOneWidget);
    });

    testWidgets('C — a Path under way is the focus: where it is, what comes '
        'next, how it reaches Today', (tester) async {
      await _pump(
        tester,
        const ToolkitPage(),
        toolkit: ToolkitState(path: _path()),
      );
      expect(find.text('A lift at home'), findsOneWidget);
      expect(find.text('More Energy · Circle 3 of 7'), findsOneWidget);
      expect(find.textContaining('Next:'), findsOneWidget);
      expect(
        find.textContaining('Choose More Energy on Today'),
        findsOneWidget,
      );
      expect(find.text('Leave this Path'), findsOneWidget);
    });

    testWidgets('TalkBack reads the Toolkit in its visual order: each '
        'section\'s heading, then its card, then any note beneath — nothing '
        'gathered up front (S25 finding)', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        const ToolkitPage(),
        entitled: false,
        toolkit: ToolkitState(routines: [_routine()], path: _path()),
      );
      // Every label, in the order TalkBack's swipes reach them.
      final spoken = <String>[];
      void visit(SemanticsNode node) {
        if (node.label.isNotEmpty) spoken.add(node.label);
        for (final child in node.debugListChildrenInOrder(
          DebugSemanticsDumpOrder.traversalOrder,
        )) {
          visit(child);
        }
      }

      var root = tester.getSemantics(find.byType(ToolkitPage));
      while (root.parent != null) {
        root = root.parent!;
      }
      visit(root);
      int at(String start) => spoken.indexWhere((l) => l.startsWith(start));
      final order = [
        at('Your Path'),
        at('A lift at home'),
        at('Next:'),
        at('Saved where you left it'),
        at('See Premium'),
        at('Your routines'),
        at('My pick-me-up'),
        at('Routines you built stay yours'),
      ];
      expect(order, everyElement(isNonNegative), reason: '$spoken');
      expect(order, orderedEquals([...order]..sort()), reason: '$spoken');
      semantics.dispose();
    });

    testWidgets('D — routines are the heart of it; another can be built', (
      tester,
    ) async {
      await _pump(
        tester,
        const ToolkitPage(),
        toolkit: ToolkitState(
          routines: [
            _routine(),
            _routine(id: 'q', name: 'Evenings', enabled: false),
          ],
        ),
      );
      expect(find.text('Your routines'.toUpperCase()), findsOneWidget);
      expect(find.text('My pick-me-up'), findsOneWidget);
      expect(find.text('More Energy · about 15 minutes'), findsOneWidget);
      expect(find.text('Off · More Energy · about 15 minutes'), findsOneWidget);
      expect(find.text('Build another routine'), findsOneWidget);
    });

    testWidgets('E — lapsed, with routines: they stay, usable; building and '
        'tuning are Premium', (tester) async {
      await _pump(
        tester,
        const ToolkitPage(),
        toolkit: ToolkitState(routines: [_routine()]),
        entitled: false,
      );
      expect(find.text('My pick-me-up'), findsOneWidget);
      expect(
        find.textContaining('Routines you built stay yours'),
        findsOneWidget,
      );
      expect(find.text('Build another routine'), findsNothing);
    });

    testWidgets('F — lapsed mid-Path: saved where it was, never lost', (
      tester,
    ) async {
      await _pump(
        tester,
        const ToolkitPage(),
        toolkit: ToolkitState(routines: [_routine()], path: _path()),
        entitled: false,
      );
      expect(find.text('More Energy · Circle 3 of 7'), findsOneWidget);
      expect(
        find.text(
          'Saved where you left it. It continues when Premium is active '
          'again.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a finished Path waits for its review', (tester) async {
      await _pump(
        tester,
        const ToolkitPage(),
        toolkit: ToolkitState(path: _path(circles: 7)),
      );
      expect(find.text('See what it built'), findsOneWidget);
      await tester.tap(find.text('See what it built'));
      await tester.pumpAndSettle();
      expect(find.text('review'), findsOneWidget);
    });

    testWidgets('the stable Toolkit check: nothing to change, said plainly, '
        'seen once', (tester) async {
      final routine = _routine(createdDaysAgo: 40);
      final journal = {
        'schemaVersion': 1,
        'entries': [
          for (final d in [20, 13, 6])
            CircleJournalEntry(
              schemaVersion: 1,
              circleId: '2026-11-${(20 - d).toString().padLeft(2, '0')}',
              localDate: '2026-11-${(20 - d).toString().padLeft(2, '0')}',
              direction: Intention.moreEnergy,
              activityId: ActivityId.energisingStretchFlow,
              catalogVersion: catalogVersion,
              shownAt: _now.subtract(Duration(days: d)),
              attemptResponse: CircleAttemptResponse.yes,
              usefulnessResponse: CircleUsefulnessResponse.veryUseful,
              timeWindow: 'about20',
              session: const CircleSessionRecord(
                title: 'My pick-me-up',
                modules: ['standingStretch:full', 'musicMove:full'],
                routineId: 'r',
                routineVersionId: 'r-v1',
                routineVersionNumber: 1,
              ),
            ).toJson(),
        ],
      };
      final c = await _pump(
        tester,
        const ToolkitPage(),
        toolkit: ToolkitState(routines: [routine]),
        extra: {circleJournalKey: jsonEncode(journal)},
      );
      expect(
        find.text('Your routines are working well — nothing to change.'),
        findsOneWidget,
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(c.read(toolkitProvider).lastCheckAt, isNotNull);
      expect(
        find.text('Your routines are working well — nothing to change.'),
        findsNothing,
      );
    });

    for (final (label, scale, size) in [
      ('130% text', 1.3, const Size(412, 915)),
      ('200% text at 360pt', 2.0, const Size(360, 740)),
    ]) {
      testWidgets('$label: every state lays out without overflow', (
        tester,
      ) async {
        for (final (toolkit, entitled) in [
          (ToolkitState.empty, false),
          (ToolkitState.empty, true),
          (ToolkitState(path: _path()), true),
          (ToolkitState(routines: [_routine()], path: _path()), false),
          (
            ToolkitState(
              routines: [
                for (var i = 0; i < 8; i++)
                  _routine(id: 'r$i', name: 'A routine with a long name $i'),
              ],
            ),
            true,
          ),
        ]) {
          await _pump(
            tester,
            const ToolkitPage(),
            toolkit: toolkit,
            entitled: entitled,
            textScale: scale,
            size: size,
          );
          expect(tester.takeException(), isNull);
          await tester.drag(find.byType(ListView), const Offset(0, -4000));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }

    test('the header art is the approved band, bundled for every daypart', () {
      for (final daypart in Daypart.values) {
        final image = toolkitHeaderArt.at(daypart);
        expect(File(image.asset).existsSync(), isTrue, reason: image.asset);
      }
    });
  });

  group('a Path before it starts', () {
    testWidgets('sparse evidence: says so; starting is one tap', (
      tester,
    ) async {
      final c = await _pump(
        tester,
        const PathStartPage(template: PathTemplateId.softLanding),
        size: const Size(412, 2400),
      );
      expect(find.text('A soft landing'), findsOneWidget);
      expect(
        find.text(
          'A simple place to start — nothing here is based on your answers '
          'yet.',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Start this Path'));
      await tester.tap(find.text('Start this Path'));
      await tester.pumpAndSettle();
      expect(
        c.read(toolkitProvider).path?.template,
        PathTemplateId.softLanding,
      );
    });

    testWidgets('Free: Paths are Premium — no Start', (tester) async {
      await _pump(
        tester,
        const PathStartPage(template: PathTemplateId.softLanding),
        size: const Size(412, 2400),
        entitled: false,
      );
      expect(find.text('Start this Path'), findsNothing);
      expect(find.text('Paths are part of Premium.'), findsOneWidget);
    });

    testWidgets('the user\'s "Don\'t suggest" leaves too little: no Start, '
        'and why', (tester) async {
      await _pump(
        tester,
        const PathStartPage(template: PathTemplateId.wakeUpIndoors),
        size: const Size(412, 2400),
        extra: {
          suggestionPreferencesKey: jsonEncode(
            SuggestionPreferences(
              notSuggested: [
                NotSuggested(
                  activity: ActivityId.moveToMusic,
                  need: Intention.moreEnergy,
                  since: _now,
                ),
                NotSuggested(
                  activity: ActivityId.activeHouseholdTask,
                  need: Intention.moreEnergy,
                  since: _now,
                ),
              ],
            ).toJson(),
          ),
        },
      );
      expect(find.text('Start this Path'), findsNothing);
      expect(
        find.textContaining('can’t build an honest routine'),
        findsOneWidget,
      );
    });

    testWidgets('one Path at a time', (tester) async {
      await _pump(
        tester,
        const PathStartPage(template: PathTemplateId.softLanding),
        size: const Size(412, 2400),
        toolkit: ToolkitState(path: _path()),
      );
      expect(find.text('Start this Path'), findsNothing);
      expect(find.textContaining('One Path at a time'), findsOneWidget);
    });
  });

  group('the review', () {
    testWidgets('no answers: no personal claim — the routine is kept under '
        'the name the user gives it', (tester) async {
      final semantics = tester.ensureSemantics();
      final c = await _pump(
        tester,
        const PathReviewPage(),
        size: const Size(412, 2400),
        toolkit: ToolkitState(path: _path(circles: 7)),
      );
      expect(find.text('What your Path built'), findsOneWidget);
      expect(
        find.text('Here’s what you built through this Path.'),
        findsOneWidget,
      );
      expect(find.textContaining('useful'), findsNothing);
      // Each Circle's number sits above its pieces, and is read with them.
      expect(find.text('CIRCLE 1'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Circle 1\. \w')), findsOneWidget);
      // Each Circle is its own stop, and the name field is never merged
      // with what the routine holds (S25 TalkBack).
      expect(
        find.bySemanticsLabel(RegExp(r'Circle 1\..*Circle 2')),
        findsNothing,
      );
      expect(
        tester.getSemantics(find.byType(TextField)).label,
        isNot(contains('in all')),
      );
      await tester.enterText(find.byType(TextField), 'Mornings');
      await tester.ensureVisible(find.text('Keep this routine'));
      await tester.tap(find.text('Keep this routine'));
      await tester.pumpAndSettle();
      final toolkit = c.read(toolkitProvider);
      expect(toolkit.routines.single.name, 'Mornings');
      expect(toolkit.path, isNull);
      semantics.dispose();
    });
  });

  group('a routine\'s page', () {
    testWidgets('what it is, what\'s in it, the version THIRTY uses, and '
        'what can be changed', (tester) async {
      await _pump(
        tester,
        const RoutineDetailPage(routineId: 'r'),
        toolkit: ToolkitState(routines: [_routine(withEarlier: true)]),
        size: const Size(412, 2400),
      );
      expect(find.text('My pick-me-up'), findsOneWidget);
      expect(find.text('Still learning how this one fits.'), findsOneWidget);
      expect(find.text('Version 2'), findsOneWidget);
      expect(find.text('Earlier versions'.toUpperCase()), findsOneWidget);
      expect(find.text('Offered for More Energy'), findsOneWidget);
      expect(find.text('Tune this routine'), findsOneWidget);
      for (final control in ['Rename', 'Turn it off', 'Delete']) {
        expect(find.text(control), findsOneWidget, reason: control);
      }
    });

    testWidgets('lapsed: changing it is Premium; owning it is not', (
      tester,
    ) async {
      await _pump(
        tester,
        const RoutineDetailPage(routineId: 'r'),
        toolkit: ToolkitState(routines: [_routine()]),
        entitled: false,
        size: const Size(412, 2400),
      );
      expect(find.text('Tune this routine'), findsNothing);
      expect(find.text('See Premium'), findsOneWidget);
      for (final control in ['Rename', 'Turn it off', 'Delete']) {
        expect(find.text(control), findsOneWidget, reason: control);
      }
    });

    testWidgets('a piece the user asked not to see keeps it off that need — '
        'and says so', (tester) async {
      await _pump(
        tester,
        const RoutineDetailPage(routineId: 'r'),
        toolkit: ToolkitState(routines: [_routine()]),
        size: const Size(412, 2400),
        extra: {
          suggestionPreferencesKey: jsonEncode(
            SuggestionPreferences(
              notSuggested: [
                NotSuggested(
                  activity: ActivityId.moveToMusic,
                  need: Intention.moreEnergy,
                  since: _now,
                ),
              ],
            ).toJson(),
          ),
        },
      );
      expect(
        find.textContaining(
          'Not offered for More Energy: it includes move to '
          'music',
        ),
        findsOneWidget,
      );
    });

    testWidgets('turning off "Offered for More Energy" is the same "Don\'t '
        'suggest" as the memory page', (tester) async {
      final c = await _pump(
        tester,
        const RoutineDetailPage(routineId: 'r'),
        toolkit: ToolkitState(routines: [_routine()]),
        size: const Size(412, 2400),
      );
      await tester.tap(find.text('Offered for More Energy'));
      await tester.pumpAndSettle();
      expect(
        c
            .read(suggestionPreferencesProvider)
            .isRoutineNotSuggested('r', Intention.moreEnergy),
        isTrue,
      );
    });

    testWidgets('delete asks first, then the routine leaves the Toolkit', (
      tester,
    ) async {
      final c = await _pump(
        tester,
        const RoutineDetailPage(routineId: 'r'),
        toolkit: ToolkitState(routines: [_routine()]),
        size: const Size(412, 2400),
      );
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete My pick-me-up?'), findsOneWidget);
      expect(find.textContaining('stay in your history'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(c.read(toolkitProvider).routines, isEmpty);
    });
  });
}
