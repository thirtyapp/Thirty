import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'confirmed_write.dart';

/// The copies being kept aside of stored records THIRTY can't read — Plans
/// and Insights — while their writes are under way (R8.1, Astra N02).
///
/// [SharedPreferences] shows a value in its memory before the platform has
/// written it, so a copy whose write hasn't completed is not a preserved
/// copy yet. Every such write is tracked here: a save that would write over
/// the original waits for it ([settled]) and then sees only what the store
/// confirmed; Delete Circle history waits for all of them ([settledAll])
/// before its last pass, so none can land after it.
class PreservationWrites {
  final _pending = <String, Future<void>>{};

  /// Begins keeping [raw] aside under [key], confirmed by the store
  /// ([writeConfirmed]) — unless a copy under [key] is already being
  /// written. A failed copy is taken back out of memory, so nothing reads it
  /// as kept.
  ///
  /// R8.2 (Astra R81-A09): [raw] is the stored value as it is — text, or a
  /// value of another native type, which keeps its type.
  void keepAside(SharedPreferences prefs, String key, Object raw) {
    if (_pending.containsKey(key)) return;
    final write = writeConfirmed(prefs, key, raw);
    _pending[key] = write;
    write.then((_) {}, onError: (Object _) {}).whenComplete(() {
      if (identical(_pending[key], write)) _pending.remove(key);
    });
  }

  /// Completes, never failing, once no copy under [key] is being written.
  Future<void> settled(String key) => switch (_pending[key]) {
    final write? => write.then((_) {}, onError: (Object _) {}),
    null => Future<void>.value(),
  };

  /// Completes, never failing, once no copy is being written.
  Future<void> settledAll() =>
      Future.wait([for (final key in _pending.keys.toList()) settled(key)]);
}

/// Whether two stored values — text, numbers, Booleans or lists of text —
/// are the same value of the same type (R8.2, Astra R81-A09).
bool sameStoredValue(Object? a, Object? b) => jsonEncode(a) == jsonEncode(b);

/// The app's [PreservationWrites].
final preservationWritesProvider = Provider<PreservationWrites>(
  (ref) => PreservationWrites(),
);
