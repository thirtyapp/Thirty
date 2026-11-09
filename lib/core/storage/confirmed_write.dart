import 'package:shared_preferences/shared_preferences.dart';

/// A write the local store did not confirm (audit remediation R8): the
/// platform call threw, or returned `false`. Nothing is claimed for it.
class StorageWriteFailed implements Exception {
  const StorageWriteFailed(
    this.key, [
    this.reason = 'not confirmed',
    this.uncertain = false,
  ]);

  /// The key that was being written or removed.
  final String key;
  final String reason;

  /// R8.3.2 (founder scope decisions B1/B2): whether the value may have
  /// reached the disk all the same — the platform call threw, as when its
  /// answer is lost after the write landed. `false`: the store answered
  /// that it didn't write it, or nothing was written.
  final bool uncertain;

  @override
  String toString() => 'StorageWriteFailed($key): $reason';
}

/// Writes [value] under [key] — a `String`, `int`, `bool`, `double` or list
/// of strings; `null` removes the key — and completes only once the store
/// confirms it (audit remediation R8, Astra R7-A01/A03/A04, Claude F-5/F-6).
///
/// [SharedPreferences] puts a value in its memory before the disk write, and
/// keeps it there whatever the disk says. So a write that throws, or returns
/// `false`, is a failure here: the key is put back as it was — in memory,
/// and on disk if the disk takes it — so nothing reads back what was never
/// saved; then [StorageWriteFailed] is thrown.
///
/// With [restoreOnFailure] `false` — Delete Circle history's own removals
/// only — a value the user asked to delete is never put back in memory:
/// the deletion stays recorded on disk and is finished on the next start,
/// and nothing deleted is shown again in the meantime (audit remediation
/// R3, founder decision).
Future<void> writeConfirmed(
  SharedPreferences prefs,
  String key,
  Object? value, {
  bool restoreOnFailure = true,
}) async {
  final previous = _copy(prefs.get(key));
  bool confirmed;
  var threw = false;
  try {
    confirmed = await _write(prefs, key, value);
  } catch (_) {
    confirmed = false;
    threw = true;
  }
  if (confirmed) return;
  if (!restoreOnFailure) {
    throw StorageWriteFailed(key, 'not confirmed', threw);
  }
  try {
    await _write(prefs, key, previous);
  } catch (_) {
    // Memory is put back before the disk call, which is all that matters
    // here: the disk never confirmed the value.
  }
  throw StorageWriteFailed(key, 'not confirmed', threw);
}

Object? _copy(Object? value) =>
    value is List ? List<String>.from(value.cast<String>()) : value;

Future<bool> _write(SharedPreferences prefs, String key, Object? value) =>
    switch (value) {
      null => prefs.remove(key),
      final String v => prefs.setString(key, v),
      final bool v => prefs.setBool(key, v),
      final int v => prefs.setInt(key, v),
      final double v => prefs.setDouble(key, v),
      final List<Object?> v => prefs.setStringList(key, [
        for (final item in v) '$item',
      ]),
      _ => throw ArgumentError.value(value, 'value', 'not storable'),
    };
