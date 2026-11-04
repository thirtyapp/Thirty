/// Kept Circles (V2 Phase D2, ADR-023 §8; ADR-024 §3): the only reusable
/// object the user owns. A kept Circle is a Personal Guided Circle the user
/// chose to keep, with its parts fixed at their authored lengths. It is never
/// tuned, versioned or shortened, and THIRTY never offers it unasked.
///
/// **Ownership (audit remediation R4):** a kept Circle is read back as it was
/// kept — its parts, their order and lengths, and the words each part had —
/// not as today's catalogue would make it. One THIRTY can't read is never
/// dropped: it stays in the record exactly as stored ([RetainedKept]).
library;

import '../../home/application/activity_catalog.dart';
import 'circle_elements.dart';

/// A Personal Guided Circle the user kept, to use again on a day they choose
/// ("Use it today"). It is theirs whatever happens to Premium: renamable,
/// removable and exportable.
class KeptCircle {
  const KeptCircle({
    required this.id,
    required this.name,
    required this.need,
    required this.plan,
    required this.createdAt,
    this.fromCircleId,
    this.wording,
    this.stored = const {},
  });

  final String id;
  final String name;

  /// The need it was composed for.
  final Intention need;

  /// Its parts as kept: the same elements, order and lengths
  /// ([CirclePlan.fromSaved]).
  final CirclePlan plan;
  final DateTime createdAt;

  /// The day's Circle it was kept from, so the same Circle is kept once.
  final String? fromCircleId;

  /// The words each part had when it was kept, one per part — `null` for a
  /// Circle kept before they were saved, which shows its elements' own.
  final List<PartWording>? wording;

  /// The rest of its stored record, as stored: fields this build doesn't
  /// use are written back unchanged, never dropped.
  final Map<String, Object?> stored;

  int get minutes => plan.minutes;

  /// The words the part at [position] is shown with ([partWordingFor]).
  PartWording wordingAt(int position) =>
      partWordingFor(plan.parts[position], wording?[position]);

  /// Whether the part at [position] shows words corrected for safety in
  /// place of its saved ones ([partWordingCorrectedForSafety]).
  bool correctedForSafetyAt(int position) =>
      partWordingCorrectedForSafety(plan.parts[position], wording?[position]);

  KeptCircle copyWith({String? name}) => KeptCircle(
    id: id,
    name: name ?? this.name,
    need: need,
    plan: plan,
    createdAt: createdAt,
    fromCircleId: fromCircleId,
    wording: wording,
    stored: stored,
  );

  Map<String, Object?> toJson() => {
    ...stored,
    'id': id,
    'name': name,
    'need': need.name,
    'parts': plan.toWire(),
    'createdAt': createdAt.toIso8601String(),
    'fromCircleId': fromCircleId,
    if (wording case final wording?)
      'wording': [for (final w in wording) w.toJson()],
  };

  /// The fields [toJson] writes itself.
  static const _fields = {
    'id',
    'name',
    'need',
    'parts',
    'createdAt',
    'fromCircleId',
    'wording',
  };

  /// A stored kept Circle, as kept — or `null` when it can't be read safely
  /// (an element this build doesn't know, a damaged field). The caller keeps
  /// such a record as it is ([RetainedKept]).
  static KeptCircle? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final id = raw['id'];
    final name = raw['name'];
    final need = Intention.values.asNameMap()[raw['need']];
    final plan = CirclePlan.fromSaved(raw['parts']);
    final createdAt = DateTime.tryParse('${raw['createdAt']}');
    final fromCircleId = raw['fromCircleId'];
    if (id is! String ||
        id.isEmpty ||
        name is! String ||
        name.trim().isEmpty ||
        need == null ||
        plan == null ||
        createdAt == null ||
        (fromCircleId != null && fromCircleId is! String)) {
      return null;
    }
    final wording = PartWording.listFromJson(raw['wording'], plan.parts.length);
    // Audit remediation R8 (Astra R7-A07): saved words that are there but
    // damaged — an item that isn't words, the wrong number, not a list —
    // are never replaced by today's catalogue words and voiced as if they
    // were the Circle's own. The whole record is kept as stored instead
    // ([RetainedKept]): shown, renamable, removable, exported — never run.
    // A Circle kept before words were saved (no field) shows its parts'.
    if (raw.containsKey('wording') && wording == null) return null;
    return KeptCircle(
      id: id,
      name: name,
      need: need,
      plan: plan,
      createdAt: createdAt,
      fromCircleId: fromCircleId as String?,
      wording: wording,
      stored: {
        for (final MapEntry(:key, :value) in raw.entries)
          if (!_fields.contains(key)) key: value,
      },
    );
  }
}

/// A kept Circle THIRTY can't read (audit remediation R4) — an element this
/// build doesn't know, or a damaged record — kept exactly as it was stored,
/// in its place. It is never dropped, never guessed at and never run; the
/// user can still rename it, remove it and export it.
class RetainedKept {
  const RetainedKept(this.stored, {required this.position});

  /// The record, exactly as stored.
  final Object? stored;

  /// Where it stood among the kept Circles, so it is written back there.
  final int position;

  /// How it is addressed: its own id, or its place when it has none.
  String get key => switch (stored) {
    {'id': final String id} when id.isNotEmpty => id,
    _ => 'retained-$position',
  };

  /// The name the user gave it, when the record still has one.
  String? get name => switch (stored) {
    {'name': final String name} when name.trim().isNotEmpty => name,
    _ => null,
  };

  /// Whether a new name can be written into it without touching anything
  /// else.
  bool get canRename => stored is Map<String, Object?>;

  RetainedKept renamed(String name) => switch (stored) {
    final Map<String, Object?> record => RetainedKept({
      ...record,
      'name': name,
    }, position: position),
    _ => this,
  };
}

/// The most Circles the user keeps: enough to have a few favourites, never a
/// catalogue to browse. Every kept Circle counts, read or not.
const maxKeptCircles = 8;

/// The stored record's shape version. Unchanged from the Phase D Toolkit
/// record it continues ([keptCirclesFromRecord]); a kept Circle's saved
/// words are an addition older builds ignore.
const keptCirclesSchemaVersion = 1;

/// The kept Circles in a stored record, oldest first, and those that can't
/// be read, kept as they are — or `null` when the record can't be read at
/// all. Nothing is guessed at, and nothing is left out.
///
/// The record is the one the Phase D Toolkit wrote (`toolkit_v1`). Its retired
/// Path, routine and maintenance fields are removed by the pre-release
/// migration (`phase_d_retirement.dart`) before anything reads it.
///
/// **Audit remediation R8 (Astra R7-A02, Claude F-3).** A `kept` field that
/// is there but isn't a list makes the whole record unreadable — never an
/// empty store a Keep would write over. A record with no `kept` field at all
/// is the Phase D Toolkit's, from before anything was kept: empty. Fields
/// this build doesn't know are returned in [extra] and written back
/// unchanged ([keptCirclesRecord]).
({
  List<KeptCircle> kept,
  List<RetainedKept> retained,
  Map<String, Object?> extra,
})?
keptCollectionFromRecord(Object? raw) {
  if (raw is! Map<String, Object?>) return null;
  if (raw['schemaVersion'] != keptCirclesSchemaVersion) return null;
  if (raw.containsKey('kept') && raw['kept'] is! List) return null;
  final rawKept = raw['kept'] as List? ?? const [];
  final kept = <KeptCircle>[];
  final retained = <RetainedKept>[];
  for (final (position, record) in rawKept.indexed) {
    switch (KeptCircle.fromJson(record)) {
      case final circle?:
        kept.add(circle);
      case null:
        retained.add(RetainedKept(record, position: position));
    }
  }
  return (
    kept: kept,
    retained: retained,
    extra: {
      for (final MapEntry(:key, :value) in raw.entries)
        if (key != 'schemaVersion' && key != 'kept') key: value,
    },
  );
}

/// The kept Circles a stored record holds that can be read
/// ([keptCollectionFromRecord]).
List<KeptCircle>? keptCirclesFromRecord(Object? raw) =>
    keptCollectionFromRecord(raw)?.kept;

/// [kept] as the stored record — with every [retained] one back in its
/// place, exactly as it was stored, and the record's other fields ([extra])
/// unchanged.
Map<String, Object?> keptCirclesRecord(
  List<KeptCircle> kept, {
  List<RetainedKept> retained = const [],
  Map<String, Object?> extra = const {},
}) {
  final entries = <Object?>[for (final k in kept) k.toJson()];
  for (final r in [
    ...retained,
  ]..sort((a, b) => a.position.compareTo(b.position))) {
    entries.insert(r.position.clamp(0, entries.length), r.stored);
  }
  return {...extra, 'schemaVersion': keptCirclesSchemaVersion, 'kept': entries};
}
