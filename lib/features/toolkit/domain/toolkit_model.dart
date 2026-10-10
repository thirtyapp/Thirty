/// The Personal Toolkit's stored state (V2 Phase D, ADR-022): the user's
/// own routines, with their versions, the one Path being worked through,
/// and the few facts maintenance needs to stay quiet (declined offers, the
/// last Toolkit check).
///
/// Only user-owned definitions and choices live here. What happened — every
/// Circle, its answers, its time — stays in the Circle journal, the one
/// source of evidence; nothing here is a derived score.
library;

import '../../home/application/activity_catalog.dart';
import 'module_library.dart';
import 'path_catalog.dart';

/// Why a routine version exists.
enum VersionOrigin {
  /// The routine a Path built.
  path,

  /// A tune-up the user accepted.
  tuneUp,

  /// A shorter version the user accepted, for days with less time.
  shorter,
}

/// One version of a routine. Never rewritten once created: a change is a
/// new version, so what a routine used to be stays true.
class RoutineVersion {
  const RoutineVersion({
    required this.id,
    required this.number,
    required this.composition,
    required this.createdAt,
    required this.origin,
    this.pathRunId,
  });

  /// Stable identity, recorded on every Circle that used it.
  final String id;

  /// 1, 2, 3… — "Version 2".
  final int number;
  final Composition composition;
  final DateTime createdAt;
  final VersionOrigin origin;

  /// The Path or tune-up run that produced it, if any — its Circles are
  /// this version's first evidence.
  final String? pathRunId;

  int get minutes => composition.minutes;

  Map<String, Object?> toJson() => {
    'id': id,
    'number': number,
    'modules': composition.toWire(),
    'createdAt': createdAt.toIso8601String(),
    'origin': origin.name,
    'pathRunId': pathRunId,
  };

  static RoutineVersion? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final id = raw['id'];
    final number = raw['number'];
    final composition = Composition.fromWire(raw['modules']);
    final createdAt = DateTime.tryParse('${raw['createdAt']}');
    final origin = VersionOrigin.values.asNameMap()[raw['origin']];
    final pathRunId = raw['pathRunId'];
    if (id is! String ||
        number is! int ||
        composition == null ||
        createdAt == null ||
        origin == null) {
      return null;
    }
    return RoutineVersion(
      id: id,
      number: number,
      composition: composition,
      createdAt: createdAt,
      origin: origin,
      pathRunId: pathRunId is String ? pathRunId : null,
    );
  }
}

/// A user-owned routine. It stays the user's whatever happens to Premium:
/// usable, renamable, disableable, deletable and exportable.
class Routine {
  const Routine({
    required this.id,
    required this.name,
    required this.need,
    required this.versions,
    required this.activeVersionId,
    required this.createdAt,
    this.shortVersionId,
    this.sourceTemplate,
    this.enabled = true,
  });

  final String id;
  final String name;

  /// The need it was built for.
  final Intention need;

  /// Every version, oldest first.
  final List<RoutineVersion> versions;

  /// "The version THIRTY uses now."
  final String activeVersionId;

  /// An accepted shorter version THIRTY may use when there's less time.
  final String? shortVersionId;

  final DateTime createdAt;
  final PathTemplateId? sourceTemplate;

  /// A disabled routine is kept but never offered.
  final bool enabled;

  RoutineVersion get active =>
      versions.firstWhere((v) => v.id == activeVersionId);

  RoutineVersion? get shortVersion {
    final id = shortVersionId;
    if (id == null) return null;
    for (final version in versions) {
      if (version.id == id) return version;
    }
    return null;
  }

  RoutineVersion? versionById(String id) {
    for (final version in versions) {
      if (version.id == id) return version;
    }
    return null;
  }

  /// The versions THIRTY may offer, longest first: the active one, then
  /// the shorter one when it really is shorter.
  List<RoutineVersion> get offerableVersions => [
    active,
    if (shortVersion case final short? when short.minutes < active.minutes)
      short,
  ];

  /// How this routine fits [need]: primary for the need it was built for;
  /// secondary where every piece fits; otherwise not at all.
  NeedFit fitFor(Intention need) {
    if (need == this.need) return NeedFit.primary;
    return active.composition.fitsNeed(need) ? NeedFit.secondary : NeedFit.none;
  }

  Routine copyWith({
    String? name,
    List<RoutineVersion>? versions,
    String? activeVersionId,
    String? shortVersionId,
    bool clearShortVersion = false,
    bool? enabled,
  }) => Routine(
    id: id,
    name: name ?? this.name,
    need: need,
    versions: versions ?? this.versions,
    activeVersionId: activeVersionId ?? this.activeVersionId,
    createdAt: createdAt,
    shortVersionId: clearShortVersion
        ? null
        : (shortVersionId ?? this.shortVersionId),
    sourceTemplate: sourceTemplate,
    enabled: enabled ?? this.enabled,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'need': need.name,
    'versions': [for (final v in versions) v.toJson()],
    'activeVersionId': activeVersionId,
    'shortVersionId': shortVersionId,
    'createdAt': createdAt.toIso8601String(),
    'sourceTemplate': sourceTemplate?.name,
    'enabled': enabled,
  };

  /// A routine, or `null` if it can't be read safely. Versions that can't
  /// be read are skipped; a routine whose active version is lost is not
  /// restored at all rather than restored as something it wasn't.
  static Routine? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final id = raw['id'];
    final name = raw['name'];
    final need = Intention.values.asNameMap()[raw['need']];
    final createdAt = DateTime.tryParse('${raw['createdAt']}');
    final activeVersionId = raw['activeVersionId'];
    final rawVersions = raw['versions'];
    if (id is! String ||
        name is! String ||
        name.trim().isEmpty ||
        need == null ||
        createdAt == null ||
        activeVersionId is! String ||
        rawVersions is! List) {
      return null;
    }
    final versions = [for (final v in rawVersions) ?RoutineVersion.fromJson(v)];
    if (!versions.any((v) => v.id == activeVersionId)) return null;
    final shortVersionId = raw['shortVersionId'];
    return Routine(
      id: id,
      name: name,
      need: need,
      versions: versions,
      activeVersionId: activeVersionId,
      createdAt: createdAt,
      shortVersionId:
          shortVersionId is String &&
              versions.any((v) => v.id == shortVersionId)
          ? shortVersionId
          : null,
      sourceTemplate: PathTemplateId.values.asNameMap()[raw['sourceTemplate']],
      enabled: raw['enabled'] != false,
    );
  }
}

/// What a Path run is doing.
enum PathKind {
  /// Builds a new routine (seven Circles).
  build,

  /// Tests one change to an existing routine (three Circles).
  tuneUp,

  /// Establishes a shorter version of an existing routine (three Circles).
  shorter,
}

/// Why a Path started as it did.
enum SeedReason {
  /// Too little evidence: the template's own order.
  sparseStart,

  /// A piece the user found useful for this need comes first.
  usefulModule,
}

/// Why a Path Circle is what it is — internal, never shown as a code.
enum PathStepReason {
  firstTry,
  startsWithUseful,
  secondTry,
  thirdTry,
  fullPiece,
  repeatUseful,
  alternateAfterNegative,
  together,
  otherPairing,
  shorterForm,
  asItStands,
  shorterToFit,
  tuneSwap,
  tuneShorter,
  otherShorter;

  /// The step says something the user told THIRTY.
  bool get fromAnswers => switch (this) {
    startsWithUseful || repeatUseful || alternateAfterNegative => true,
    _ => false,
  };
}

/// One Path Circle that counted: today's Circle was this Path step, and it
/// was closed. Close moves the sequence on — it never says the step was
/// done.
class PathCircle {
  const PathCircle({
    required this.circleId,
    required this.number,
    required this.composition,
    required this.reason,
    Composition? planned,
  }) : planned = planned ?? composition;

  /// The journal's Circle id (its local date).
  final String circleId;
  final int number;

  /// What the Circle ran: the step, or its shorter form on a short day.
  final Composition composition;

  /// The step itself — what the Path settled on, whatever the day allowed.
  final Composition planned;
  final PathStepReason reason;

  Map<String, Object?> toJson() => {
    'circleId': circleId,
    'number': number,
    'modules': composition.toWire(),
    'planned': planned.toWire(),
    'reason': reason.name,
  };

  static PathCircle? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final circleId = raw['circleId'];
    final number = raw['number'];
    final composition = Composition.fromWire(raw['modules']);
    final reason = PathStepReason.values.asNameMap()[raw['reason']];
    if (circleId is! String ||
        number is! int ||
        composition == null ||
        reason == null) {
      return null;
    }
    return PathCircle(
      circleId: circleId,
      number: number,
      composition: composition,
      reason: reason,
      planned: Composition.fromWire(raw['planned']),
    );
  }
}

/// The one Path being worked through — a build, a tune-up or a shorter
/// version. Its position is the Circles that counted; missed days change
/// nothing.
class PathRun {
  const PathRun({
    required this.id,
    required this.kind,
    required this.need,
    required this.startedAt,
    required this.pool,
    required this.seed,
    this.template,
    this.routineId,
    this.baseVersionId,
    this.targetMinutes,
    this.circles = const [],
  });

  final String id;
  final PathKind kind;
  final Intention need;
  final DateTime startedAt;

  /// The pieces in the order the seed put them.
  final List<ModuleId> pool;
  final SeedReason seed;

  /// A build's template.
  final PathTemplateId? template;

  /// A tune-up's or shorter version's routine, and the version it changes.
  final String? routineId;
  final String? baseVersionId;

  /// A shorter version's most minutes.
  final int? targetMinutes;

  final List<PathCircle> circles;

  int get length => kind == PathKind.build ? 7 : 3;

  /// Every Circle counted: ready for its review.
  bool get finished => circles.length >= length;

  /// The Circle the next Path step would be: 1-based.
  int get nextNumber => circles.length + 1;

  PathRun withCircle(PathCircle circle) => PathRun(
    id: id,
    kind: kind,
    need: need,
    startedAt: startedAt,
    pool: pool,
    seed: seed,
    template: template,
    routineId: routineId,
    baseVersionId: baseVersionId,
    targetMinutes: targetMinutes,
    circles: [...circles, circle],
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'need': need.name,
    'startedAt': startedAt.toIso8601String(),
    'pool': [for (final m in pool) m.name],
    'seed': seed.name,
    'template': template?.name,
    'routineId': routineId,
    'baseVersionId': baseVersionId,
    'targetMinutes': targetMinutes,
    'circles': [for (final c in circles) c.toJson()],
  };

  static PathRun? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final id = raw['id'];
    final kind = PathKind.values.asNameMap()[raw['kind']];
    final need = Intention.values.asNameMap()[raw['need']];
    final startedAt = DateTime.tryParse('${raw['startedAt']}');
    final seed = SeedReason.values.asNameMap()[raw['seed']];
    final rawPool = raw['pool'];
    final rawCircles = raw['circles'];
    if (id is! String ||
        kind == null ||
        need == null ||
        startedAt == null ||
        seed == null ||
        rawPool is! List ||
        rawCircles is! List) {
      return null;
    }
    final pool = [for (final m in rawPool) ?ModuleId.values.asNameMap()[m]];
    if (pool.isEmpty) return null;
    final circles = <PathCircle>[];
    for (final c in rawCircles) {
      final circle = PathCircle.fromJson(c);
      // A gap in the sequence can't be trusted: stop at it.
      if (circle == null || circle.number != circles.length + 1) break;
      circles.add(circle);
    }
    final template = PathTemplateId.values.asNameMap()[raw['template']];
    final routineId = raw['routineId'];
    final baseVersionId = raw['baseVersionId'];
    final targetMinutes = raw['targetMinutes'];
    if (kind == PathKind.build && template == null) return null;
    if (kind != PathKind.build &&
        (routineId is! String || baseVersionId is! String)) {
      return null;
    }
    return PathRun(
      id: id,
      kind: kind,
      need: need,
      startedAt: startedAt,
      pool: pool,
      seed: seed,
      template: template,
      routineId: routineId is String ? routineId : null,
      baseVersionId: baseVersionId is String ? baseVersionId : null,
      targetMinutes: targetMinutes is int ? targetMinutes : null,
      circles: circles,
    );
  }
}

/// A finished Path, kept briefly so the Toolkit can say what it led to.
class FinishedPath {
  const FinishedPath({
    required this.runId,
    required this.kind,
    required this.need,
    required this.finishedAt,
    required this.kept,
    this.template,
    this.routineId,
  });

  final String runId;
  final PathKind kind;
  final Intention need;
  final DateTime finishedAt;

  /// Whether the user kept what it proposed.
  final bool kept;
  final PathTemplateId? template;
  final String? routineId;

  Map<String, Object?> toJson() => {
    'runId': runId,
    'kind': kind.name,
    'need': need.name,
    'finishedAt': finishedAt.toIso8601String(),
    'kept': kept,
    'template': template?.name,
    'routineId': routineId,
  };

  static FinishedPath? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final runId = raw['runId'];
    final kind = PathKind.values.asNameMap()[raw['kind']];
    final need = Intention.values.asNameMap()[raw['need']];
    final finishedAt = DateTime.tryParse('${raw['finishedAt']}');
    if (runId is! String ||
        kind == null ||
        need == null ||
        finishedAt == null) {
      return null;
    }
    final routineId = raw['routineId'];
    return FinishedPath(
      runId: runId,
      kind: kind,
      need: need,
      finishedAt: finishedAt,
      kept: raw['kept'] == true,
      template: PathTemplateId.values.asNameMap()[raw['template']],
      routineId: routineId is String ? routineId : null,
    );
  }
}

/// Everything the Toolkit stores.
class ToolkitState {
  const ToolkitState({
    this.routines = const [],
    this.path,
    this.finished = const [],
    this.declined = const {},
    this.lastCheckAt,
  });

  static const empty = ToolkitState();

  /// Nothing the user built, started or chose.
  bool get isEmpty =>
      routines.isEmpty &&
      path == null &&
      finished.isEmpty &&
      declined.isEmpty &&
      lastCheckAt == null;

  /// Oldest first.
  final List<Routine> routines;

  /// The one Path being worked through, finished or not — a finished one
  /// waits here for its review.
  final PathRun? path;

  /// Finished Paths, oldest first.
  final List<FinishedPath> finished;

  /// Declined maintenance offers, by offer key, and when.
  final Map<String, DateTime> declined;

  /// When the user last saw the Toolkit check.
  final DateTime? lastCheckAt;

  Routine? routineById(String id) {
    for (final routine in routines) {
      if (routine.id == id) return routine;
    }
    return null;
  }

  List<Routine> get enabledRoutines => [
    for (final routine in routines)
      if (routine.enabled) routine,
  ];

  ToolkitState copyWith({
    List<Routine>? routines,
    PathRun? path,
    bool clearPath = false,
    List<FinishedPath>? finished,
    Map<String, DateTime>? declined,
    DateTime? lastCheckAt,
  }) => ToolkitState(
    routines: routines ?? this.routines,
    path: clearPath ? null : (path ?? this.path),
    finished: finished ?? this.finished,
    declined: declined ?? this.declined,
    lastCheckAt: lastCheckAt ?? this.lastCheckAt,
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': toolkitSchemaVersion,
    'routines': [for (final r in routines) r.toJson()],
    'path': path?.toJson(),
    'finished': [for (final f in finished) f.toJson()],
    'declined': {
      for (final MapEntry(:key, :value) in declined.entries)
        key: value.toIso8601String(),
    },
    'lastCheckAt': lastCheckAt?.toIso8601String(),
  };

  /// The stored state, item by item: whatever can't be read safely is left
  /// out, never guessed at. `null` only when the whole record is unusable.
  static ToolkitState? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    if (raw['schemaVersion'] != toolkitSchemaVersion) return null;
    final rawRoutines = raw['routines'];
    final rawFinished = raw['finished'];
    final rawDeclined = raw['declined'];
    final routines = <Routine>[];
    final seen = <String>{};
    if (rawRoutines is List) {
      for (final r in rawRoutines) {
        final routine = Routine.fromJson(r);
        if (routine != null && seen.add(routine.id)) routines.add(routine);
      }
    }
    return ToolkitState(
      routines: routines,
      path: PathRun.fromJson(raw['path']),
      finished: [
        if (rawFinished is List)
          for (final f in rawFinished) ?FinishedPath.fromJson(f),
      ],
      declined: {
        if (rawDeclined is Map<String, Object?>)
          for (final MapEntry(:key, :value) in rawDeclined.entries)
            key: ?DateTime.tryParse('$value'),
      },
      lastCheckAt: DateTime.tryParse('${raw['lastCheckAt']}'),
    );
  }
}

/// The Toolkit record's shape version.
const toolkitSchemaVersion = 1;
