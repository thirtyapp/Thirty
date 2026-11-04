import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../home/application/activity_catalog.dart';
import '../domain/circle_elements.dart';
import '../domain/kept_circle.dart';

/// Where kept Circles are stored: one versioned JSON record. The key is the
/// Phase D Toolkit's, kept so nothing the user kept moves (ADR-024 §3).
const keptCirclesKey = 'toolkit_v1';

/// Where builds before audit remediation R4.1 set aside a whole record they
/// couldn't read. Kept as it is — never overwritten, and no longer written.
const keptCirclesUnreadableKey = 'toolkit_v1_unreadable';

/// A whole stored kept-Circle record THIRTY can't read (audit remediation
/// R4.1): left exactly where it is, as stored. How many Circles it holds
/// can't be known, so while one exists no Circle is kept; it is shown in
/// Yours, exported as stored, and removed only by the user.
class UnreadableKeptStore {
  const UnreadableKeptStore({required this.key, required this.raw});

  /// Where it is stored.
  final String key;

  /// What is stored there, exactly.
  final String raw;

  /// How Yours addresses it.
  String get address => 'store-$key';
}

/// The local store of kept Circles. Local only, no account.
class KeptCirclesRepository {
  KeptCirclesRepository(this._prefs);

  final SharedPreferences _prefs;

  /// The kept Circles; empty when there are none. One that can't be read is
  /// kept as it is, in its place (audit remediation R4). A whole record that
  /// can't be read stays exactly where it is (R4.1): nothing is copied over
  /// anything, and nothing is guessed from it.
  KeptCircles read() {
    final stores = [
      if (_prefs.getString(keptCirclesUnreadableKey) case final setAside?)
        UnreadableKeptStore(key: keptCirclesUnreadableKey, raw: setAside),
    ];
    final raw = _prefs.getString(keptCirclesKey);
    if (raw == null) return KeptCircles(const [], unreadable: stores);
    final read = _collectionIn(raw);
    if (read != null) {
      return KeptCircles(
        read.kept,
        retained: read.retained,
        unreadable: stores,
      );
    }
    return KeptCircles(
      const [],
      unreadable: [
        ...stores,
        UnreadableKeptStore(key: keptCirclesKey, raw: raw),
      ],
    );
  }

  static ({List<KeptCircle> kept, List<RetainedKept> retained})? _collectionIn(
    String raw,
  ) {
    try {
      return keptCollectionFromRecord(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  /// One write of the whole record — a single key, so it is never half
  /// written — with every kept Circle in it, read or not. Never over a
  /// record THIRTY can't read (R4.1): that stays as it is.
  Future<void> write(KeptCircles state) async {
    final current = _prefs.getString(keptCirclesKey);
    if (current != null && _collectionIn(current) == null) return;
    await _prefs.setString(
      keptCirclesKey,
      jsonEncode(keptCirclesRecord(state.kept, retained: state.retained)),
    );
  }

  /// Removes [store] — only ever on the user's own request.
  Future<void> remove(UnreadableKeptStore store) => _prefs.remove(store.key);
}

final keptCirclesRepositoryProvider = Provider<KeptCirclesRepository>(
  (ref) => KeptCirclesRepository(ref.watch(sharedPreferencesProvider)),
);

/// The Circles the user kept, oldest first — and any THIRTY can't read,
/// kept as they are ([RetainedKept]).
class KeptCircles {
  const KeptCircles(
    this.kept, {
    this.retained = const [],
    this.unreadable = const [],
  });

  static const empty = KeptCircles([]);

  final List<KeptCircle> kept;
  final List<RetainedKept> retained;

  /// Whole stored records THIRTY can't read (R4.1), as stored.
  final List<UnreadableKeptStore> unreadable;

  /// Every kept Circle THIRTY can count, read or not.
  int get count => kept.length + retained.length;

  /// Whether every kept Circle can be counted: not while a whole record
  /// THIRTY can't read holds an unknown number of them (R4.1).
  bool get countKnown => unreadable.isEmpty;

  bool get isEmpty => count == 0 && unreadable.isEmpty;

  /// No Circle can be kept now: [maxKeptCircles] are kept — or how many are
  /// kept can't be known (R4.1). Another needs one removed first.
  bool get isFull => !countKnown || count >= maxKeptCircles;

  /// The whole stored record THIRTY can't read that [address] addresses.
  UnreadableKeptStore? unreadableAt(String address) {
    for (final store in unreadable) {
      if (store.address == address) return store;
    }
    return null;
  }

  KeptCircle? keptById(String id) {
    for (final circle in kept) {
      if (circle.id == id) return circle;
    }
    return null;
  }

  /// The kept Circle THIRTY can't read that [key] addresses.
  RetainedKept? retainedByKey(String key) {
    for (final record in retained) {
      if (record.key == key) return record;
    }
    return null;
  }
}

/// Whether a kept part may run (audit remediation R4, R4.1): its element
/// live, not from content awaiting the safety review or retired, and not at
/// a length retired for safety ([isPartOffered]) — in every build. A saved
/// Circle is never a way around it. Overridable only so tests can stand for
/// a later catalogue.
final partOfferableProvider = Provider<bool Function(CirclePart)>(
  (ref) =>
      (part) => isPartOffered(part.definition, part.minutes),
);

/// The user's kept Circles: keep, rename, remove. Never gated — what was
/// made for the user is theirs, whatever Premium's state.
class KeptCirclesNotifier extends Notifier<KeptCircles> {
  Future<void> _writes = Future<void>.value();

  @override
  KeptCircles build() => ref.watch(keptCirclesRepositoryProvider).read();

  void _set(List<KeptCircle> kept, {List<RetainedKept>? retained}) {
    final next = KeptCircles(
      kept,
      retained: retained ?? state.retained,
      unreadable: state.unreadable,
    );
    state = next;
    _writes = _writes
        .then((_) => ref.read(keptCirclesRepositoryProvider).write(next))
        .catchError((Object _) {});
    unawaited(_writes);
  }

  DateTime get _now => ref.read(eventClockProvider)();

  /// Keeps today's composed Circle as one of the user's own — named [name],
  /// or by its need — with the words each part has now. Returns `null` when
  /// [maxKeptCircles] are kept already (counting any THIRTY can't read), or
  /// this day's Circle is already kept.
  KeptCircle? keepCircle({
    required CirclePlan plan,
    required Intention need,
    required String circleId,
    String? name,
  }) {
    if (state.isFull) return null;
    if (state.kept.any((k) => k.fromCircleId == circleId)) return null;
    final trimmed = name?.trim();
    final circle = KeptCircle(
      id: 'kept-${_now.microsecondsSinceEpoch}-${state.count}',
      name: trimmed == null || trimmed.isEmpty
          ? keptCircleDefaultName(need)
          : trimmed,
      need: need,
      plan: plan,
      createdAt: _now,
      fromCircleId: circleId,
      wording: [for (final p in plan.parts) PartWording.of(p.definition)],
    );
    _set([...state.kept, circle]);
    return circle;
  }

  /// Renames the kept Circle [id] addresses — one THIRTY can't read too,
  /// changing nothing else in it.
  void renameKept(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (state.keptById(id) != null) {
      _set([
        for (final k in state.kept) k.id == id ? k.copyWith(name: trimmed) : k,
      ]);
      return;
    }
    final record = state.retainedByKey(id);
    if (record == null || !record.canRename) return;
    _set(
      state.kept,
      retained: [
        for (final r in state.retained) r == record ? r.renamed(trimmed) : r,
      ],
    );
  }

  /// Removes a kept Circle — one THIRTY can't read too, only ever on the
  /// user's own request. History keeps the days it was used, under the name
  /// it had then.
  void deleteKept(String id) {
    if (state.keptById(id) != null) {
      _set([
        for (final k in state.kept)
          if (k.id != id) k,
      ]);
      return;
    }
    final record = state.retainedByKey(id);
    if (record == null) return;
    _set(
      state.kept,
      retained: [
        for (final r in state.retained)
          if (r != record) r,
      ],
    );
  }

  /// Removes a whole stored record THIRTY can't read (R4.1) — only ever on
  /// the user's own request. Nothing else changes.
  void removeUnreadable(String address) {
    final store = state.unreadableAt(address);
    if (store == null) return;
    state = KeptCircles(
      state.kept,
      retained: state.retained,
      unreadable: [
        for (final s in state.unreadable)
          if (s != store) s,
      ],
    );
    final repository = ref.read(keptCirclesRepositoryProvider);
    _writes = _writes
        .then((_) => repository.remove(store))
        .catchError((Object _) => true);
    unawaited(_writes);
  }
}

final keptCirclesProvider = NotifierProvider<KeptCirclesNotifier, KeptCircles>(
  KeptCirclesNotifier.new,
);

/// A kept Circle's name until the user gives it one: its need, plainly.
String keptCircleDefaultName(Intention need) => switch (need) {
  Intention.moreEnergy => 'My energy Circle',
  Intention.clearerHead => 'My clear-head Circle',
  Intention.gentlerPace => 'My gentle Circle',
};

/// The parts of [circle] THIRTY won't run (audit remediation R4, R4.1): an
/// element no longer offered — retired, or awaiting the safety review — or a
/// length retired for safety, in any build. A kept Circle with any such part
/// stays the user's, readable and theirs to rename or remove, but isn't run
/// — and is never shortened.
List<CirclePart> keptPartsNotOffered(
  KeptCircle circle,
  bool Function(CirclePart) offerable,
) => [
  for (final part in circle.plan.parts)
    if (!offerable(part)) part,
];
