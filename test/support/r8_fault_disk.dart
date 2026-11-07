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

  /// R8.3: every write or removal that landed although its call then
  /// reported a failure ([ackLost]), in order (`set key` / `remove key`).
  final ackLostLog = <String>[];

  /// R8.3 single-writer guard: each write or removal that began while
  /// another to the same key was still pending (held, or not yet landed),
  /// as `op key`. Recorded, never failed here; a test asserts on it.
  final overlaps = <String>[];

  final _pendingByKey = <String, int>{};

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

  final _ackLost = <String, (int, bool)>{};

  /// R8.3: the next [times] writes or removals of [key] reach the disk —
  /// the value lands — and the call then throws, as if the platform's
  /// answer were lost after the write. With [thenStop] the process stops
  /// right after the value lands instead ([stopAfter]): the call never
  /// completes, as when the app dies between the platform's commit and
  /// Dart hearing of it.
  ///
  /// A simulation inside one Dart process: it is not the behaviour of
  /// Android's storage, and passing tests with it prove nothing about a
  /// real process kill or a real device fault.
  void ackLost(String key, {int times = 1, bool thenStop = false}) =>
      _ackLost[_bare(key)] = (times, thenStop);

  bool? _takeAckLost(String key) {
    final entry = _ackLost[key];
    if (entry == null) return null;
    final (times, thenStop) = entry;
    if (times <= 1) {
      _ackLost.remove(key);
    } else {
      _ackLost[key] = (times - 1, thenStop);
    }
    return thenStop;
  }

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

  final _holds = <String, HeldWrite>{};

  /// The next write or removal of [key] waits, before it reaches the disk,
  /// until the returned [HeldWrite] is released (R8.1, Astra N02). The
  /// SharedPreferences cache has already changed by then, exactly as on a
  /// device while a platform write is pending. Other keys are not held.
  HeldWrite hold(String key) => _holds[_bare(key)] = HeldWrite._();

  Future<bool> _attempt(
    String op,
    String key,
    Future<bool> Function() land,
  ) async {
    final bare = _bare(key);
    attempts.add('$op $bare');
    if (_stopped) return Completer<bool>().future;
    if ((_pendingByKey[bare] ?? 0) > 0) overlaps.add('$op $bare');
    _pendingByKey[bare] = (_pendingByKey[bare] ?? 0) + 1;
    try {
      return await _attemptOnce(op, bare, land);
    } finally {
      _pendingByKey[bare] = _pendingByKey[bare]! - 1;
    }
  }

  Future<bool> _attemptOnce(
    String op,
    String bare,
    Future<bool> Function() land,
  ) async {
    if (_holds.remove(bare) case final held?) {
      held._reached.complete();
      final release = await held._released.future;
      if (release.ackLost) return _landThenFail(op, bare, land, false);
      switch (release.fault) {
        case DiskFault.throws:
          throw StateError('disk $op failed for $bare');
        case DiskFault.returnsFalse:
          return false;
        case null:
          log.add('$op $bare');
          return land();
      }
    }
    if (_takeAckLost(bare) case final thenStop?) {
      return _landThenFail(op, bare, land, thenStop);
    }
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

  Future<bool> _landThenFail(
    String op,
    String bare,
    Future<bool> Function() land,
    bool thenStop,
  ) async {
    log.add('$op $bare');
    ackLostLog.add('$op $bare');
    await land();
    if (thenStop) {
      stopAfter = log.length;
      return Completer<bool>().future;
    }
    throw StateError('disk $op landed for $bare; its answer was lost');
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

/// One platform write held before the disk ([FaultDisk.hold]).
class HeldWrite {
  HeldWrite._();

  final _reached = Completer<void>();
  final _released = Completer<({DiskFault? fault, bool ackLost})>();

  /// Completes once the write has arrived and is waiting.
  Future<void> get reached => _reached.future;

  /// Whether the write has arrived and is waiting.
  bool get isWaiting => _reached.isCompleted && !_released.isCompleted;

  /// Lets the write land — or fail as [fault].
  void release([DiskFault? fault]) =>
      _released.complete((fault: fault, ackLost: false));

  /// R8.3: lets the write land, then fails its call ([FaultDisk.ackLost]).
  void releaseAckLost() => _released.complete((fault: null, ackLost: true));
}
