import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/storage/confirmed_write.dart';
import '../../../core/storage/store_save_failures.dart';
import '../../home/application/activity_catalog.dart';
import '../../home/application/phase_d_retirement.dart';
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
      if (_stored(keptCirclesUnreadableKey) case final setAside?)
        UnreadableKeptStore(key: keptCirclesUnreadableKey, raw: setAside),
    ];
    final raw = _stored(keptCirclesKey);
    if (raw == null) return KeptCircles(const [], unreadable: stores);
    final read = _collectionIn(raw);
    if (read != null) {
      return KeptCircles(
        read.kept,
        retained: read.retained,
        unreadable: stores,
        // Every field this build doesn't use is written back (audit
        // remediation R8) — except Phase D's, retired before release
        // (ADR-024 §3): the next write drops them, as the migration does.
        extra: {
          for (final MapEntry(:key, :value) in read.extra.entries)
            if (!retiredToolkitFields.contains(key)) key: value,
        },
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

  /// What is stored under [key], as text — a value of another type is
  /// stored data THIRTY can't read, given as its text, never dropped.
  String? _stored(String key) => switch (_prefs.get(key)) {
    null => null,
    final String raw => raw,
    final Object other => '$other',
  };

  static ({
    List<KeptCircle> kept,
    List<RetainedKept> retained,
    Map<String, Object?> extra,
  })?
  _collectionIn(String raw) {
    try {
      return keptCollectionFromRecord(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  /// One write of the whole record — a single key, so it is never half
  /// written — with every kept Circle in it, read or not. Never over a
  /// record THIRTY can't read (R4.1): that stays as it is.
  ///
  /// Completes only once the store confirms it (audit remediation R8,
  /// Astra R7-A03, Claude F-6); otherwise — or over a record THIRTY can't
  /// read — it fails with [StorageWriteFailed], and nothing is written.
  Future<void> write(KeptCircles state) async {
    final current = _prefs.get(keptCirclesKey);
    if (current != null &&
        (current is! String || _collectionIn(current) == null)) {
      throw const StorageWriteFailed(
        keptCirclesKey,
        'the stored kept Circles can\'t be read',
      );
    }
    await writeConfirmed(
      _prefs,
      keptCirclesKey,
      jsonEncode(
        keptCirclesRecord(
          state.kept,
          retained: state.retained,
          extra: state.extra,
        ),
      ),
    );
  }

  /// Removes [store] — only ever on the user's own request. Fails with
  /// [StorageWriteFailed] unless the store confirms it.
  Future<void> remove(UnreadableKeptStore store) =>
      writeConfirmed(_prefs, store.key, null);
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
    this.extra = const {},
  });

  static const empty = KeptCircles([]);

  final List<KeptCircle> kept;
  final List<RetainedKept> retained;

  /// The stored record's fields this build doesn't know, written back
  /// unchanged (audit remediation R8).
  final Map<String, Object?> extra;

  KeptCircles _with({
    List<KeptCircle>? kept,
    List<RetainedKept>? retained,
    List<UnreadableKeptStore>? unreadable,
  }) => KeptCircles(
    kept ?? this.kept,
    retained: retained ?? this.retained,
    unreadable: unreadable ?? this.unreadable,
    extra: extra,
  );

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

  /// R8.3.3 (Astra R832-A02): how many kept Circles — read or not — [id]
  /// addresses. More than one only in a record written before R8.3.3, when
  /// two I4 Keeps of one day could be given the same id.
  int addressedBy(String id) =>
      kept.where((k) => k.id == id).length +
      retained.where((r) => r.key == id).length;

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

/// R8.3.3 (Astra R832-A02): where a new kept Circle's id gets its random
/// part ([KeptCirclesNotifier.newKeptId]). Overridable only so tests can
/// force two ids to collide.
final keptIdRandomProvider = Provider<Random>((ref) {
  try {
    return Random.secure();
  } on UnsupportedError {
    return Random();
  }
});

/// The user's kept Circles: keep, rename, remove. Never gated — what was
/// made for the user is theirs, whatever Premium's state.
///
/// **Audit remediation R8 (Astra R7-A03, Claude F-6).** Every change is
/// shown only once the store has confirmed it: until then, and if it fails,
/// the kept Circles stay as they were — in memory and on disk — the failure
/// is shown ([storeSaveFailuresProvider]) and the returned future fails with
/// [StorageWriteFailed]. Changes run one after another, each on what the one
/// before it left.
class KeptCirclesNotifier extends Notifier<KeptCircles> {
  Future<void> _writes = Future<void>.value();

  /// Days whose Circle is being kept now — counted, so two Keeps at once
  /// never keep it twice or pass [maxKeptCircles].
  final _keeping = <String>{};

  /// R8.3.3 (Astra R832-A02): the ids of the Keeps under way, so two at
  /// once never share one.
  final _keepingIds = <String>{};

  @override
  KeptCircles build() => ref.watch(keptCirclesRepositoryProvider).read();

  /// Applies [change] to the kept Circles as they then stand, and shows the
  /// result once it is on disk. [change] returning `null` changes nothing.
  Future<KeptCircles?> _commit(KeptCircles? Function(KeptCircles) change) {
    final run = _writes.then((_) async {
      final next = change(state);
      if (next == null) return null;
      await ref.read(keptCirclesRepositoryProvider).write(next);
      if (ref.mounted) state = next;
      return next;
    });
    _writes = run.then(
      // R8.1 (Astra N10): a confirmed save holds everything shown, so an
      // earlier failure's "unsaved" status is cleared.
      (_) {
        if (ref.mounted) {
          ref
              .read(storeSaveFailuresProvider.notifier)
              .saved(UserStore.keptCircles);
        }
      },
      onError: (Object _) {
        if (ref.mounted) {
          ref
              .read(storeSaveFailuresProvider.notifier)
              .record(UserStore.keptCircles);
        }
      },
    );
    return run;
  }

  DateTime get _now => ref.read(eventClockProvider)();

  /// R8.3.3 (Astra R832-A02): a new kept Circle's own id — no other kept
  /// Circle, read or not, and no Keep under way has it. Never from a
  /// cached calendar clock: the event clock's instant and 48 random bits
  /// ([keptIdRandomProvider]), with a count added only if even that is
  /// taken. [tag] says who chose it (`insight`), so an id Insight 4 recorded
  /// is never one a Keep of the user's own is given.
  String newKeptId({String? tag}) {
    final random = ref.read(keptIdRandomProvider);
    final bits = (random.nextInt(1 << 24) << 24) | random.nextInt(1 << 24);
    final base = [
      'kept',
      '${_now.microsecondsSinceEpoch}',
      bits.toRadixString(16).padLeft(12, '0'),
      ?tag,
    ].join('-');
    var id = base;
    for (var n = 1; _idTaken(state, id); n++) {
      id = '$base-$n';
    }
    return id;
  }

  bool _idTaken(KeptCircles current, String id) =>
      _keepingIds.contains(id) || current.addressedBy(id) > 0;

  /// Keeps today's composed Circle as one of the user's own — named [name],
  /// or by its need — with the words each part has now. Completes with the
  /// kept Circle once it is on disk; with `null` when [maxKeptCircles] are
  /// kept already (counting any THIRTY can't read, and Keeps under way), or
  /// this day's Circle is already kept or being kept. Fails with
  /// [StorageWriteFailed] when the store doesn't confirm it — then nothing
  /// is kept.
  ///
  /// [id] (R8.3.2, founder scope decision B2): the kept Circle's own id, when
  /// the caller chose it beforehand — Insight 4 records it before keeping,
  /// so its own Keep can be told from any other Keep of the same day.
  ///
  /// R8.3.3 (Astra R832-A02): every kept Circle's id is its own. Without
  /// [id] one is allocated ([newKeptId]); an [id] that a kept Circle — read
  /// or not — or another Keep under way already has is refused like any
  /// other Keep that can't be made: `null`, nothing written, nothing
  /// replaced.
  Future<KeptCircle?> keepCircle({
    required CirclePlan plan,
    required Intention need,
    required String circleId,
    String? name,
    String? id,
  }) async {
    final keptId = id ?? newKeptId();
    bool refused(KeptCircles current) =>
        !current.countKnown ||
        current.count + _keeping.length >= maxKeptCircles ||
        current.kept.any((k) => k.fromCircleId == circleId) ||
        current.addressedBy(keptId) > 0;
    if (_keeping.contains(circleId) ||
        _keepingIds.contains(keptId) ||
        refused(state)) {
      return null;
    }
    final trimmed = name?.trim();
    final circle = KeptCircle(
      id: keptId,
      name: trimmed == null || trimmed.isEmpty
          ? keptCircleDefaultName(need)
          : trimmed,
      need: need,
      plan: plan,
      createdAt: _now,
      fromCircleId: circleId,
      wording: [for (final p in plan.parts) PartWording.of(p.definition)],
    );
    _keeping.add(circleId);
    _keepingIds.add(keptId);
    try {
      final next = await _commit((current) {
        _keeping.remove(circleId);
        _keepingIds.remove(keptId);
        if (refused(current)) return null;
        return current._with(kept: [...current.kept, circle]);
      });
      return next == null ? null : circle;
    } finally {
      _keeping.remove(circleId);
      _keepingIds.remove(keptId);
    }
  }

  /// Renames the kept Circle [id] addresses — one THIRTY can't read too,
  /// changing nothing else in it. Completes once on disk.
  ///
  /// R8.3.3 (Astra R832-A02): an [id] that addresses more than one kept
  /// Circle ([KeptCircles.addressedBy]) renames none of them — one action
  /// never changes two Circles the user owns separately.
  Future<void> renameKept(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _commit((current) {
      if (current.addressedBy(id) > 1) return null;
      if (current.keptById(id) != null) {
        return current._with(
          kept: [
            for (final k in current.kept)
              k.id == id ? k.copyWith(name: trimmed) : k,
          ],
        );
      }
      final record = current.retainedByKey(id);
      if (record == null || !record.canRename) return null;
      return current._with(
        retained: [
          for (final r in current.retained)
            r == record ? r.renamed(trimmed) : r,
        ],
      );
    });
  }

  /// Removes a kept Circle — one THIRTY can't read too, only ever on the
  /// user's own request. History keeps the days it was used, under the name
  /// it had then. Completes once on disk.
  ///
  /// R8.3.3 (Astra R832-A02): an [id] that addresses more than one kept
  /// Circle removes none of them, as for [renameKept].
  Future<void> deleteKept(String id) async {
    await _commit((current) {
      if (current.addressedBy(id) > 1) return null;
      if (current.keptById(id) != null) {
        return current._with(
          kept: [
            for (final k in current.kept)
              if (k.id != id) k,
          ],
        );
      }
      final record = current.retainedByKey(id);
      if (record == null) return null;
      return current._with(
        retained: [
          for (final r in current.retained)
            if (r != record) r,
        ],
      );
    });
  }

  /// Removes a whole stored record THIRTY can't read (R4.1) — only ever on
  /// the user's own request. Nothing else changes. Completes once the store
  /// confirms the removal; until then, and if it fails, the record is still
  /// shown.
  Future<void> removeUnreadable(String address) async {
    final store = state.unreadableAt(address);
    if (store == null) return;
    final repository = ref.read(keptCirclesRepositoryProvider);
    final run = _writes.then((_) async {
      await repository.remove(store);
      if (ref.mounted) {
        state = state._with(
          unreadable: [
            for (final s in state.unreadable)
              if (s != store) s,
          ],
        );
      }
    });
    _writes = run.then(
      (_) {},
      onError: (Object _) {
        if (ref.mounted) {
          ref
              .read(storeSaveFailuresProvider.notifier)
              .record(UserStore.keptCircles);
        }
      },
    );
    await run;
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
