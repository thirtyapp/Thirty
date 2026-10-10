import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/premium/premium_access.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../home/application/activity_catalog.dart';
import '../../home/application/circle_journal.dart';
import '../../home/application/recommendation_provider.dart';
import '../../home/application/suggestion_preferences.dart';
import '../../home/domain/recommendation_engine.dart';
import '../../home/domain/recommendation_policy.dart';
import '../domain/maintenance.dart';
import '../domain/module_library.dart';
import '../domain/path_catalog.dart';
import '../domain/path_engine.dart';
import '../domain/toolkit_model.dart';

/// Where the Toolkit is stored: one versioned JSON record.
const toolkitStateKey = 'toolkit_v1';

/// A Toolkit record that couldn't be read is kept here, untouched, rather
/// than overwritten — so nothing the user built is silently lost.
const toolkitUnreadableKey = 'toolkit_v1_unreadable';

/// The local Toolkit store (V2 Phase D, ADR-022). Local only, no account.
class ToolkitRepository {
  ToolkitRepository(this._prefs);

  final SharedPreferences _prefs;

  /// The stored Toolkit; empty when there is none. A record that can't be
  /// read at all is set aside under [toolkitUnreadableKey] first.
  ToolkitState read() {
    final raw = _prefs.getString(toolkitStateKey);
    if (raw == null) return ToolkitState.empty;
    try {
      final state = ToolkitState.fromJson(jsonDecode(raw));
      if (state != null) return state;
    } catch (_) {
      // Unreadable: kept aside below.
    }
    unawaited(_prefs.setString(toolkitUnreadableKey, raw));
    return ToolkitState.empty;
  }

  /// One write of the whole record — a single key, so it is never half
  /// written.
  Future<void> write(ToolkitState state) =>
      _prefs.setString(toolkitStateKey, jsonEncode(state.toJson()));
}

final toolkitRepositoryProvider = Provider<ToolkitRepository>(
  (ref) => ToolkitRepository(ref.watch(sharedPreferencesProvider)),
);

/// Why a Path could or couldn't start.
enum PathStart {
  started,

  /// Starting Paths is Premium.
  notEntitled,

  /// One Path at a time.
  pathUnderWay,

  /// The user's own choices (or the safety gate) leave too little to build
  /// an honest routine from.
  nothingToBuild,
}

/// The user's Toolkit: routines, the one Path, and maintenance memory.
///
/// Paid operations — starting a Path, a tune-up or a shorter version —
/// check the existing entitlement. Ownership never does: renaming,
/// disabling, deleting, keeping what a finished Path proposed, and leaving
/// a Path all work whatever Premium's state.
class ToolkitNotifier extends Notifier<ToolkitState> {
  Future<void> _writes = Future<void>.value();

  @override
  ToolkitState build() => ref.watch(toolkitRepositoryProvider).read();

  void _set(ToolkitState next) {
    state = next;
    final snapshot = next;
    _writes = _writes
        .then((_) => ref.read(toolkitRepositoryProvider).write(snapshot))
        .catchError((Object _) {});
    unawaited(_writes);
  }

  DateTime get _now => ref.read(eventClockProvider)();

  bool get _entitled => ref.read(premiumEntitlementProvider);

  String _newId(String prefix) =>
      '$prefix-${_now.microsecondsSinceEpoch}-'
      '${state.routines.length + state.finished.length}';

  /// The journal as the engine sees it, with this Toolkit's routines —
  /// built here rather than read from [toolkitHistoryProvider], which
  /// watches this notifier.
  List<PastCircle> get _history => pastCirclesFrom(
    ref.read(circleJournalRepositoryProvider).readAll(),
    routines: state.routines,
  );

  RecommendationMemory _memory() => RecommendationMemory.of(
    ref.read(nowProvider),
    _history,
    RecommendationPolicy.initial,
    restsLifted: ref.read(suggestionPreferencesProvider).controls.restsLifted,
  );

  SuggestionControls get _controls =>
      ref.read(suggestionPreferencesProvider).controls;

  bool get _allowSafetyPending => ref.read(safetyPendingAllowedProvider);

  /// Starts a build of [template] (Premium).
  PathStart startBuild(PathTemplateId template) {
    if (!_entitled) return PathStart.notEntitled;
    if (state.path != null) return PathStart.pathUnderWay;
    final seed = seedBuild(
      pathTemplate(template),
      _memory(),
      controls: _controls,
      allowSafetyPending: _allowSafetyPending,
    );
    if (seed == null) return PathStart.nothingToBuild;
    _set(
      state.copyWith(
        path: PathRun(
          id: _newId('path'),
          kind: PathKind.build,
          need: pathTemplate(template).need,
          startedAt: _now,
          pool: seed.pool,
          seed: seed.reason,
          template: template,
        ),
      ),
    );
    return PathStart.started;
  }

  /// Starts a tune-up of [routineId]: three Circles that try one change
  /// (Premium).
  PathStart startTuneUp(String routineId) {
    if (!_entitled) return PathStart.notEntitled;
    if (state.path != null) return PathStart.pathUnderWay;
    final routine = state.routineById(routineId);
    if (routine == null) return PathStart.nothingToBuild;
    final pool = tuneUpPool(
      routine,
      _memory(),
      controls: _controls,
      allowSafetyPending: _allowSafetyPending,
    );
    if (pool == null) return PathStart.nothingToBuild;
    _set(
      state.copyWith(
        path: PathRun(
          id: _newId('tune'),
          kind: PathKind.tuneUp,
          need: routine.need,
          startedAt: _now,
          pool: pool,
          seed: SeedReason.sparseStart,
          routineId: routine.id,
          baseVersionId: routine.activeVersionId,
        ),
      ),
    );
    return PathStart.started;
  }

  /// Starts a shorter version of [routineId], at most [targetMinutes]
  /// (Premium).
  PathStart startShorter(String routineId, int targetMinutes) {
    if (!_entitled) return PathStart.notEntitled;
    if (state.path != null) return PathStart.pathUnderWay;
    final routine = state.routineById(routineId);
    if (routine == null) return PathStart.nothingToBuild;
    final memory = _memory();
    final leadFirst =
        [for (final use in routine.active.composition.uses) use.module]..sort(
          (a, b) => memory
              .strengthFor(moduleOf(b).source, routine.need)
              .compareTo(memory.strengthFor(moduleOf(a).source, routine.need)),
        );
    if (shorterVersionOf(routine.active.composition, targetMinutes) == null ||
        routine.active.composition.uses.any(
          (use) => moduleResting(use.module, routine.need, memory),
        )) {
      return PathStart.nothingToBuild;
    }
    _set(
      state.copyWith(
        path: PathRun(
          id: _newId('short'),
          kind: PathKind.shorter,
          need: routine.need,
          startedAt: _now,
          pool: leadFirst,
          seed: SeedReason.sparseStart,
          routineId: routine.id,
          baseVersionId: routine.activeVersionId,
          targetMinutes: targetMinutes,
        ),
      ),
    );
    return PathStart.started;
  }

  /// Counts today's Path Circle — called once it is closed. Close moves the
  /// sequence on; it never says the step was done. Idempotent per Circle.
  void recordPathCircle({
    required String runId,
    required String circleId,
    required Composition composition,
    required Composition planned,
    required PathStepReason reason,
  }) {
    final run = state.path;
    if (run == null || run.id != runId || run.finished) return;
    if (run.circles.any((c) => c.circleId == circleId)) return;
    _set(
      state.copyWith(
        path: run.withCircle(
          PathCircle(
            circleId: circleId,
            number: run.nextNumber,
            composition: composition,
            planned: planned,
            reason: reason,
          ),
        ),
      ),
    );
  }

  /// Keeps what the finished Path proposes: a new routine (named [name],
  /// or the Path's own name for it), a tuned version that THIRTY uses from
  /// now on, or a shorter version for days with less time. Never gated:
  /// the work is done, and it is the user's.
  Routine? keepProposal({String? name}) {
    final run = state.path;
    if (run == null || !run.finished) return null;
    final proposal = proposalFor(
      run,
      pathAnswersFrom(ref.read(circleJournalRepositoryProvider).readAll(), run),
    );
    if (proposal == null) return null;
    final now = _now;
    Routine? kept;
    var routines = state.routines;
    switch (run.kind) {
      case PathKind.build:
        final template = pathTemplate(run.template!);
        final id = _newId('routine');
        final versions = [
          RoutineVersion(
            id: '$id-v1',
            number: 1,
            composition: proposal.composition,
            createdAt: now,
            origin: VersionOrigin.path,
            pathRunId: run.id,
          ),
          if (proposal.shorter case final shorter?)
            RoutineVersion(
              id: '$id-v2',
              number: 1,
              composition: shorter,
              createdAt: now,
              origin: VersionOrigin.shorter,
              pathRunId: run.id,
            ),
        ];
        final trimmed = name?.trim();
        kept = Routine(
          id: id,
          name: trimmed == null || trimmed.isEmpty
              ? template.routineName
              : trimmed,
          need: run.need,
          versions: versions,
          activeVersionId: versions.first.id,
          shortVersionId: versions.length > 1 ? versions[1].id : null,
          createdAt: now,
          sourceTemplate: template.id,
        );
        routines = [...routines, kept];
      case PathKind.tuneUp:
      case PathKind.shorter:
        final routine = state.routineById(run.routineId!);
        if (routine == null) break;
        // A tuned routine is the next version; a shorter version shares
        // the number of the version it shortens ("Version 2", and its
        // shorter version).
        final number = run.kind == PathKind.tuneUp
            ? routine.versions
                      .where((v) => v.origin != VersionOrigin.shorter)
                      .map((v) => v.number)
                      .reduce((a, b) => a > b ? a : b) +
                  1
            : routine.active.number;
        final version = RoutineVersion(
          id: '${routine.id}-v${routine.versions.length + 1}',
          number: number,
          composition: proposal.composition,
          createdAt: now,
          origin: run.kind == PathKind.tuneUp
              ? VersionOrigin.tuneUp
              : VersionOrigin.shorter,
          pathRunId: run.id,
        );
        kept = run.kind == PathKind.tuneUp
            // A tuned routine is a new version THIRTY uses from now on; a
            // shorter form of the old one no longer describes it.
            ? routine.copyWith(
                versions: [...routine.versions, version],
                activeVersionId: version.id,
                clearShortVersion: true,
              )
            : routine.copyWith(
                versions: [...routine.versions, version],
                shortVersionId: version.id,
              );
        routines = [for (final r in routines) r.id == routine.id ? kept : r];
    }
    _set(
      state.copyWith(
        routines: routines,
        clearPath: true,
        finished: [
          ...state.finished,
          FinishedPath(
            runId: run.id,
            kind: run.kind,
            need: run.need,
            finishedAt: now,
            kept: kept != null,
            template: run.template,
            routineId: kept?.id ?? run.routineId,
          ),
        ],
      ),
    );
    return kept;
  }

  /// Doesn't keep what a finished Path proposed. Nothing else changes.
  void setAsideProposal() {
    final run = state.path;
    if (run == null || !run.finished) return;
    _set(
      state.copyWith(
        clearPath: true,
        finished: [
          ...state.finished,
          FinishedPath(
            runId: run.id,
            kind: run.kind,
            need: run.need,
            finishedAt: _now,
            kept: false,
            template: run.template,
            routineId: run.routineId,
          ),
        ],
      ),
    );
  }

  /// Stops the Path under way. Its Circles stay in History.
  void leavePath() {
    final run = state.path;
    if (run == null) return;
    _set(
      state.copyWith(
        clearPath: true,
        finished: [
          ...state.finished,
          FinishedPath(
            runId: run.id,
            kind: run.kind,
            need: run.need,
            finishedAt: _now,
            kept: false,
            template: run.template,
            routineId: run.routineId,
          ),
        ],
      ),
    );
  }

  void rename(String routineId, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _replace(routineId, (r) => r.copyWith(name: trimmed));
  }

  void setEnabled(String routineId, {required bool enabled}) =>
      _replace(routineId, (r) => r.copyWith(enabled: enabled));

  /// Makes [versionId] the version THIRTY uses — the user's own choice
  /// between versions they already have.
  void useVersion(String routineId, String versionId) =>
      _replace(routineId, (r) {
        if (r.versionById(versionId) == null || r.shortVersionId == versionId) {
          return r;
        }
        return r.copyWith(activeVersionId: versionId);
      });

  /// Deletes the routine and its versions. History keeps the Circles that
  /// used it, under the name they had. A tune-up of it stops too.
  void deleteRoutine(String routineId) {
    if (state.routineById(routineId) == null) return;
    final path = state.path;
    _set(
      state.copyWith(
        routines: [
          for (final r in state.routines)
            if (r.id != routineId) r,
        ],
        clearPath: path?.routineId == routineId,
      ),
    );
    unawaited(
      ref
          .read(suggestionPreferencesProvider.notifier)
          .allowRoutineAgain(routineId),
    );
  }

  void _replace(String routineId, Routine Function(Routine) change) {
    final routine = state.routineById(routineId);
    if (routine == null) return;
    final changed = change(routine);
    if (identical(changed, routine)) return;
    _set(
      state.copyWith(
        routines: [
          for (final r in state.routines) r.id == routineId ? changed : r,
        ],
      ),
    );
  }

  /// "Not now" on an offer: it stays away for a while.
  void declineOffer(String key) =>
      _set(state.copyWith(declined: {...state.declined, key: _now}));

  /// The Toolkit check was seen; the next comes round in about four weeks.
  void seeCheck() => _set(state.copyWith(lastCheckAt: _now));
}

final toolkitProvider = NotifierProvider<ToolkitNotifier, ToolkitState>(
  ToolkitNotifier.new,
);

/// The journal as the engine and the Toolkit see it, with each routine's
/// evidence attached (`pastCirclesFrom`).
final toolkitHistoryProvider = Provider<List<PastCircle>>(
  (ref) => pastCirclesFrom(
    ref.watch(circleJournalRepositoryProvider).readAll(),
    routines: ref.watch(toolkitProvider).routines,
  ),
);

/// The answers given to [run]'s counted Circles, from the journal.
PathAnswers pathAnswersFrom(Iterable<CircleJournalEntry> entries, PathRun run) {
  final ids = {for (final c in run.circles) c.circleId};
  return {
    for (final entry in entries)
      if (ids.contains(entry.circleId))
        entry.circleId: switch (entry.usefulnessResponse) {
          CircleUsefulnessResponse.veryUseful => PastUsefulness.veryUseful,
          CircleUsefulnessResponse.somewhatUseful =>
            PastUsefulness.somewhatUseful,
          CircleUsefulnessResponse.notUseful => PastUsefulness.notUseful,
          null => null,
        },
  };
}

/// The answers given to the current Path's counted Circles.
final pathAnswersProvider = Provider<PathAnswers>((ref) {
  final run = ref.watch(toolkitProvider).path;
  if (run == null) return const {};
  return pathAnswersFrom(
    ref.watch(circleJournalRepositoryProvider).readAll(),
    run,
  );
});

/// The pieces of the Path under way that are resting today after a recent
/// "Not useful" ([moduleResting]): the Path never turns to one of them, and
/// waits rather than run one. Their rest ends on its own.
final pathRestingProvider = Provider<Set<ModuleId>>((ref) {
  final run = ref.watch(toolkitProvider).path;
  if (run == null) return const {};
  final memory = RecommendationMemory.of(
    ref.watch(nowProvider),
    ref.watch(toolkitHistoryProvider),
    RecommendationPolicy.initial,
    restsLifted: ref.watch(suggestionPreferencesProvider).controls.restsLifted,
  );
  return {
    for (final module in run.pool)
      if (moduleResting(module, run.need, memory)) module,
  };
});

/// The next step of the Path under way, ignoring today's time — what the
/// Toolkit shows as "next".
final nextPathStepProvider = Provider<PathStep?>((ref) {
  final toolkit = ref.watch(toolkitProvider);
  final run = toolkit.path;
  if (run == null) return null;
  final base = run.routineId == null
      ? null
      : toolkit.routineById(run.routineId!)?.versionById(run.baseVersionId!);
  return nextPathStep(
    run,
    ref.watch(pathAnswersProvider),
    base: base,
    resting: ref.watch(pathRestingProvider),
  );
});

/// What a finished Path proposes, for its review.
final pathProposalProvider = Provider<PathProposal?>((ref) {
  final run = ref.watch(toolkitProvider).path;
  if (run == null || !run.finished) return null;
  return proposalFor(run, ref.watch(pathAnswersProvider));
});

/// The user's routines as the engine sees them: ordinary candidates.
final routineCandidatesProvider = Provider<List<RoutineCandidate>>((ref) {
  final routines = ref.watch(toolkitProvider).enabledRoutines;
  return [for (final routine in routines) routineCandidate(routine)];
});

/// [routine] as an engine candidate.
RoutineCandidate routineCandidate(Routine routine) {
  final session = sessionFor(routine.active.composition);
  return RoutineCandidate(
    id: routine.id,
    fit: {for (final need in Intention.values) need: routine.fitFor(need)},
    forms: [
      for (final version in routine.offerableVersions)
        (versionId: version.id, minutes: version.minutes),
    ],
    components: routine.active.composition.activities,
    setting: session.setting,
    effort: session.effort,
  );
}

/// Maintenance today: every offer that holds, highest priority first.
final maintenanceOffersProvider = Provider<List<MaintenanceOffer>>((ref) {
  final history = ref.watch(toolkitHistoryProvider);
  final preferences = ref.watch(suggestionPreferencesProvider);
  final today = ref.watch(nowProvider);
  return maintenanceOffers(
    toolkit: ref.watch(toolkitProvider),
    history: history,
    today: today,
    memory: RecommendationMemory.of(
      today,
      history,
      RecommendationPolicy.initial,
      restsLifted: preferences.controls.restsLifted,
    ),
    controls: preferences.controls,
    allowSafetyPending: ref.watch(safetyPendingAllowedProvider),
  );
});

/// The one maintenance offer shown, if any.
final primaryOfferProvider = Provider<MaintenanceOffer?>(
  (ref) => ref.watch(maintenanceOffersProvider).firstOrNull,
);

/// The Toolkit check, when it's due.
final toolkitCheckProvider = Provider<ToolkitCheck?>(
  (ref) => toolkitCheck(
    toolkit: ref.watch(toolkitProvider),
    history: ref.watch(toolkitHistoryProvider),
    today: ref.watch(nowProvider),
    offer: ref.watch(primaryOfferProvider),
  ),
);
