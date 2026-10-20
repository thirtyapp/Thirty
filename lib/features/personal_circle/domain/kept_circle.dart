/// Kept Circles (V2 Phase D2, ADR-023 §8; ADR-024 §3): the only reusable
/// object the user owns. A kept Circle is a Personal Guided Circle the user
/// chose to keep, with its parts fixed at their authored lengths. It is never
/// tuned, versioned or shortened, and THIRTY never offers it unasked.
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
  });

  final String id;
  final String name;

  /// The need it was composed for.
  final Intention need;
  final CirclePlan plan;
  final DateTime createdAt;

  /// The day's Circle it was kept from, so the same Circle is kept once.
  final String? fromCircleId;

  int get minutes => plan.minutes;

  KeptCircle copyWith({String? name}) => KeptCircle(
    id: id,
    name: name ?? this.name,
    need: need,
    plan: plan,
    createdAt: createdAt,
    fromCircleId: fromCircleId,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'need': need.name,
    'parts': plan.toWire(),
    'createdAt': createdAt.toIso8601String(),
    'fromCircleId': fromCircleId,
  };

  static KeptCircle? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final id = raw['id'];
    final name = raw['name'];
    final need = Intention.values.asNameMap()[raw['need']];
    final plan = CirclePlan.fromWire(raw['parts']);
    final createdAt = DateTime.tryParse('${raw['createdAt']}');
    final fromCircleId = raw['fromCircleId'];
    if (id is! String ||
        name is! String ||
        name.trim().isEmpty ||
        need == null ||
        plan == null ||
        createdAt == null) {
      return null;
    }
    return KeptCircle(
      id: id,
      name: name,
      need: need,
      plan: plan,
      createdAt: createdAt,
      fromCircleId: fromCircleId is String ? fromCircleId : null,
    );
  }
}

/// The most Circles the user keeps: enough to have a few favourites, never a
/// catalogue to browse.
const maxKeptCircles = 8;

/// The stored record's shape version. Unchanged from the Phase D Toolkit
/// record it continues ([keptCirclesFromRecord]).
const keptCirclesSchemaVersion = 1;

/// The kept Circles in a stored record, oldest first — or `null` when the
/// record can't be read at all. Whatever single Circle can't be read safely
/// is left out, never guessed at.
///
/// The record is the one the Phase D Toolkit wrote (`toolkit_v1`). Its retired
/// Path, routine and maintenance fields are ignored here, and dropped by the
/// pre-release migration (`phase_d_retirement.dart`) and by the next write.
List<KeptCircle>? keptCirclesFromRecord(Object? raw) {
  if (raw is! Map<String, Object?>) return null;
  if (raw['schemaVersion'] != keptCirclesSchemaVersion) return null;
  final rawKept = raw['kept'];
  return [
    if (rawKept is List)
      for (final k in rawKept) ?KeptCircle.fromJson(k),
  ];
}

/// [kept] as the stored record.
Map<String, Object?> keptCirclesRecord(List<KeptCircle> kept) => {
  'schemaVersion': keptCirclesSchemaVersion,
  'kept': [for (final k in kept) k.toJson()],
};
