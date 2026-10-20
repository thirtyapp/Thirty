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

/// A record that couldn't be read is kept here, untouched, rather than
/// overwritten — so nothing the user kept is silently lost.
const keptCirclesUnreadableKey = 'toolkit_v1_unreadable';

/// The local store of kept Circles. Local only, no account.
class KeptCirclesRepository {
  KeptCirclesRepository(this._prefs);

  final SharedPreferences _prefs;

  /// The kept Circles; empty when there are none. A record that can't be
  /// read at all is set aside under [keptCirclesUnreadableKey] first.
  KeptCircles read() {
    final raw = _prefs.getString(keptCirclesKey);
    if (raw == null) return KeptCircles.empty;
    try {
      final kept = keptCirclesFromRecord(jsonDecode(raw));
      if (kept != null) return KeptCircles(kept);
    } catch (_) {
      // Unreadable: kept aside below.
    }
    unawaited(_prefs.setString(keptCirclesUnreadableKey, raw));
    return KeptCircles.empty;
  }

  /// One write of the whole record — a single key, so it is never half
  /// written.
  Future<void> write(KeptCircles state) => _prefs.setString(
    keptCirclesKey,
    jsonEncode(keptCirclesRecord(state.kept)),
  );
}

final keptCirclesRepositoryProvider = Provider<KeptCirclesRepository>(
  (ref) => KeptCirclesRepository(ref.watch(sharedPreferencesProvider)),
);

/// The Circles the user kept, oldest first.
class KeptCircles {
  const KeptCircles(this.kept);

  static const empty = KeptCircles([]);

  final List<KeptCircle> kept;

  bool get isEmpty => kept.isEmpty;

  KeptCircle? keptById(String id) {
    for (final circle in kept) {
      if (circle.id == id) return circle;
    }
    return null;
  }
}

/// The user's kept Circles: keep, rename, remove. Never gated — what was
/// made for the user is theirs, whatever Premium's state.
class KeptCirclesNotifier extends Notifier<KeptCircles> {
  Future<void> _writes = Future<void>.value();

  @override
  KeptCircles build() => ref.watch(keptCirclesRepositoryProvider).read();

  void _set(List<KeptCircle> kept) {
    final next = KeptCircles(kept);
    state = next;
    _writes = _writes
        .then((_) => ref.read(keptCirclesRepositoryProvider).write(next))
        .catchError((Object _) {});
    unawaited(_writes);
  }

  DateTime get _now => ref.read(eventClockProvider)();

  /// Keeps today's composed Circle as one of the user's own — named [name],
  /// or by its need. Returns `null` when [maxKeptCircles] are kept already,
  /// or this day's Circle is already kept.
  KeptCircle? keepCircle({
    required CirclePlan plan,
    required Intention need,
    required String circleId,
    String? name,
  }) {
    if (state.kept.length >= maxKeptCircles) return null;
    if (state.kept.any((k) => k.fromCircleId == circleId)) return null;
    final trimmed = name?.trim();
    final circle = KeptCircle(
      id: 'kept-${_now.microsecondsSinceEpoch}-${state.kept.length}',
      name: trimmed == null || trimmed.isEmpty
          ? keptCircleDefaultName(need)
          : trimmed,
      need: need,
      plan: plan,
      createdAt: _now,
      fromCircleId: circleId,
    );
    _set([...state.kept, circle]);
    return circle;
  }

  void renameKept(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || state.keptById(id) == null) return;
    _set([
      for (final k in state.kept) k.id == id ? k.copyWith(name: trimmed) : k,
    ]);
  }

  /// Removes a kept Circle. History keeps the days it was used, under the
  /// name it had then.
  void deleteKept(String id) {
    if (state.keptById(id) == null) return;
    _set([
      for (final k in state.kept)
        if (k.id != id) k,
    ]);
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
