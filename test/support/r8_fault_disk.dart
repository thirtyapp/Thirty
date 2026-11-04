import 'dart:async';

// The platform store is the controlled "disk" here; it ships with
// shared_preferences, so no dependency is added.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// How a write to the disk goes wrong (audit remediation R8).
enum DiskFault {
  /// The platform call throws.
  throws,

  /// The platform call returns `false` without throwing — the case a store
  /// that only catches exceptions misses.
  returnsFalse,
}

/// The platform store behind the real [SharedPreferences] — the "disk"
/// (audit remediation R8). The real `SharedPreferences` class runs on top of
/// it, so its in-memory cache behaves exactly as on a device: it is updated
/// before the disk write, whatever the disk then says.
///
/// Any key's writes and removals can be made to throw or return `false`,
/// for a number of times or until cleared; the process can stop after a
/// number of writes, after which nothing lands and nothing completes. Keys
/// are given without the plugin's `flutter.` prefix.
class FaultDisk extends InMemorySharedPreferencesStore {
  /// A disk holding [data] (keys unprefixed).
  FaultDisk([Map<String, Object> data = const {}])
    : super.withData({
        for (final MapEntry(:key, :value) in data.entries)
          'flutter.${_bare(key)}': value,
      });

  final _faults = <String, (DiskFault, int?)>{};

  /// Every write and removal that reached the disk, in order
  /// (`set key` / `remove key`, unprefixed).
  final log = <String>[];

  /// Every write and removal attempted, landed or not.
  final attempts = <String>[];

  /// The process stops once this many writes or removals have landed.
  int? stopAfter;

  bool get _stopped => stopAfter != null && log.length >= stopAfter!;

  static String _bare(String key) =>
      key.startsWith('flutter.') ? key.substring('flutter.'.length) : key;

  /// From now on [key]'s writes and removals fail as [fault] — [times] times,
  /// or until [heal] when `null`.
  void fail(String key, DiskFault fault, {int? times}) =>
      _faults[key] = (fault, times);

  /// [key] writes normally again.
  void heal(String key) => _faults.remove(key);

  /// Every key writes normally again.
  void healAll() => _faults.clear();

  /// The fault to apply to this attempt on [key], if any.
  DiskFault? _faultFor(String key) {
    final entry = _faults[key];
    if (entry == null) return null;
    final (fault, times) = entry;
    if (times != null) {
      if (times <= 1) {
        _faults.remove(key);
      } else {
        _faults[key] = (fault, times - 1);
      }
    }
    return fault;
  }

  Future<bool> _attempt(
    String op,
    String key,
    Future<bool> Function() land,
  ) async {
    final bare = _bare(key);
    attempts.add('$op $bare');
    if (_stopped) return Completer<bool>().future;
    switch (_faultFor(bare)) {
      case DiskFault.throws:
        throw StateError('disk $op failed for $bare');
      case DiskFault.returnsFalse:
        return false;
      case null:
        break;
    }
    log.add('$op $bare');
    return land();
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      _attempt('set', key, () => super.setValue(valueType, key, value));

  @override
  Future<bool> remove(String key) =>
      _attempt('remove', key, () => super.remove(key));

  /// What is on the disk now, unprefixed.
  Future<Map<String, Object>> stored() async => {
    for (final MapEntry(:key, :value) in (await getAll()).entries)
      _bare(key): value,
  };
}
