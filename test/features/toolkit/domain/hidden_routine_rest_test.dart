import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/home/domain/recommendation_policy.dart';
import 'package:thirty/features/toolkit/application/toolkit_provider.dart';
import 'package:thirty/features/toolkit/domain/maintenance.dart';
import 'package:thirty/features/toolkit/domain/module_library.dart';
import 'package:thirty/features/toolkit/domain/toolkit_model.dart';

/// V2 Phase D2 regression (ADR-023 §10; audits at d89a035): a "Not useful"
/// given during a Path's trial — here on Circle 6's shorter form — must not
/// become an invisible rest on the routine the user then chose to keep.
///
/// Path experiment evidence informs the build and the routine's standing
/// ("it used to suit"); only real use of the owned routine may rest it.
void main() {
  final today = DateTime(2026, 10, 20);
  const need = Intention.clearerHead;
  const runId = 'path-1';
  final full = Composition(const [
    ModuleUse(ModuleId.writeDown, short: false),
    ModuleUse(ModuleId.clearSurface, short: false),
  ]);
  final short = Composition(const [
    ModuleUse(ModuleId.writeDown, short: true),
    ModuleUse(ModuleId.clearSurface, short: true),
  ]);

  String day(int ago) {
    final d = today.subtract(Duration(days: ago));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  CircleJournalEntry pathCircle(
    int ago,
    Composition composition,
    int circle,
    CircleUsefulnessResponse answer,
  ) => CircleJournalEntry(
    schemaVersion: 1,
    circleId: day(ago),
    localDate: day(ago),
    direction: need,
    activityId: ActivityId.writeItDown,
    catalogVersion: catalogVersion,
    shownAt: today.subtract(Duration(days: ago)),
    closedAt: today.subtract(Duration(days: ago)),
    attemptResponse: CircleAttemptResponse.yes,
    usefulnessResponse: answer,
    timeWindow: 'upTo30',
    session: CircleSessionRecord(
      title: composition.title,
      modules: composition.toWire(),
      pathRunId: runId,
      pathKind: 'build',
      pathName: 'Clear the decks',
      pathCircle: circle,
      pathCircles: 7,
    ),
  );

  CircleJournalEntry routineUse(int ago, CircleUsefulnessResponse? answer) =>
      CircleJournalEntry(
        schemaVersion: 1,
        circleId: day(ago),
        localDate: day(ago),
        direction: need,
        activityId: ActivityId.writeItDown,
        catalogVersion: catalogVersion,
        shownAt: today.subtract(Duration(days: ago)),
        closedAt: today.subtract(Duration(days: ago)),
        attemptResponse: answer == null ? null : CircleAttemptResponse.yes,
        usefulnessResponse: answer,
        timeWindow: 'upTo30',
        session: CircleSessionRecord(
          title: 'My reset',
          modules: full.toWire(),
          routineId: 'reset',
          routineVersionId: 'reset-v1',
          routineVersionNumber: 1,
        ),
      );

  final routine = Routine(
    id: 'reset',
    name: 'My reset',
    need: need,
    versions: [
      RoutineVersion(
        id: 'reset-v1',
        number: 1,
        composition: full,
        createdAt: today.subtract(const Duration(days: 4)),
        origin: VersionOrigin.path,
        pathRunId: runId,
      ),
      RoutineVersion(
        id: 'reset-v2',
        number: 1,
        composition: short,
        createdAt: today.subtract(const Duration(days: 4)),
        origin: VersionOrigin.shorter,
        pathRunId: runId,
      ),
    ],
    activeVersionId: 'reset-v1',
    shortVersionId: 'reset-v2',
    createdAt: today.subtract(const Duration(days: 4)),
  );

  // Circles 4–7 of the trial: the pair, liked; the shorter form on Circle 6
  // "Not useful"; the routine as it stands, liked — then kept.
  final trial = [
    pathCircle(12, full, 4, CircleUsefulnessResponse.veryUseful),
    pathCircle(10, full, 5, CircleUsefulnessResponse.somewhatUseful),
    pathCircle(8, short, 6, CircleUsefulnessResponse.notUseful),
    pathCircle(6, full, 7, CircleUsefulnessResponse.veryUseful),
  ];

  RecommendationMemory memoryOf(List<CircleJournalEntry> entries) =>
      RecommendationMemory.of(
        today,
        pastCirclesFrom(entries, routines: [routine]),
        RecommendationPolicy.initial,
      );

  test('a Path Circle is the routine’s trial, never its use', () {
    final past = pastCirclesFrom(trial, routines: [routine]);
    for (final c in past) {
      expect(c.routineId, isNull);
      expect(c.builtRoutineId, 'reset');
      expect(c.composite, isTrue, reason: 'never activity evidence');
    }
  });

  test('a pre-keep "Not useful" never rests the kept routine', () {
    final memory = memoryOf(trial);
    expect(memory.routineDaysSinceNotUseful('reset', need), isNull);
    final decision = recommend(
      RecommendationContext(
        date: today,
        need: need,
        window: TimeWindow.upTo30,
        allowSafetyPending: false,
        routines: [routineCandidate(routine)],
      ),
      pastCirclesFrom(trial, routines: [routine]),
    );
    expect(decision, isNotNull);
    expect(
      decision!.trace,
      isNot(matches(RegExp(r'routine:reset\([^)]*blk3'))),
    );
  });

  test('the trial’s positive answers stay its first evidence', () {
    final memory = memoryOf(trial);
    // Very useful (2) + Somewhat (1) + Very useful (2); the "Not useful" is
    // superseded by the decision to keep.
    expect(memory.routineStrength('reset', need), 5);
  });

  test('the routine’s standing still remembers the trial (“used to suit”)', () {
    final standing = routineStanding(
      routine,
      pastCirclesFrom(trial, routines: [routine]),
      today,
    );
    // The full form's three trial answers; the shorter-form try belongs to
    // the shorter version.
    expect(standing.rated, [
      PastUsefulness.veryUseful,
      PastUsefulness.somewhatUseful,
      PastUsefulness.veryUseful,
    ]);
  });

  test('the trial never touches its pieces’ own evidence', () {
    final memory = memoryOf(trial);
    expect(memory.strengthFor(ActivityId.writeItDown, need), 0);
    expect(memory.daysSinceNotUseful(ActivityId.writeItDown, need), isNull);
    expect(memory.daysSinceNotUseful(ActivityId.tidyOneSurface, need), isNull);
  });

  test('a "Not useful" from real use of the routine does rest it', () {
    final memory = memoryOf([
      ...trial,
      routineUse(2, CircleUsefulnessResponse.notUseful),
    ]);
    expect(memory.routineDaysSinceNotUseful('reset', need), 2);
  });

  test('history keeps every trial Circle exactly as it was', () {
    final past = pastCirclesFrom(trial, routines: [routine]);
    expect(past.map((c) => c.usefulness), [
      PastUsefulness.veryUseful,
      PastUsefulness.somewhatUseful,
      PastUsefulness.notUseful,
      PastUsefulness.veryUseful,
    ]);
    for (final entry in trial) {
      final round = CircleJournalEntry.fromJson(entry.toJson())!;
      expect(round.session!.pathRunId, runId);
      expect(round.usefulnessResponse, entry.usefulnessResponse);
    }
  });
}
