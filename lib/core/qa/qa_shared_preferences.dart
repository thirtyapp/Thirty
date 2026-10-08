import 'package:shared_preferences/shared_preferences.dart';

/// QA-1 — an in-memory, never-persisted stand-in for [SharedPreferences].
///
/// Every THIRTY repository and notifier reads and writes through
/// `sharedPreferencesProvider`. While a QA session is applied, that provider
/// resolves to one of these instead of the device's real store, so the
/// exact production code runs against a separate namespace: synthetic
/// history is written here and only here, nothing here ever reaches disk,
/// and discarding the instance discards the whole QA state. The genuine
/// store is only ever *read* — once, by [QaSharedPreferences.copyOf].
class QaSharedPreferences implements SharedPreferences {
  QaSharedPreferences([Map<String, Object> initialValues = const {}]) {
    initialValues.forEach((key, value) => _values[key] = _copy(value));
  }

  /// A QA store seeded from [source]'s current values — every key, or only
  /// [keys] when given. Reads [source]; never writes it.
  factory QaSharedPreferences.copyOf(
    SharedPreferences source, {
    Set<String>? keys,
  }) {
    final values = <String, Object>{};
    for (final key in source.getKeys()) {
      if (keys != null && !keys.contains(key)) continue;
      final value = source.get(key);
      if (value != null) values[key] = value;
    }
    return QaSharedPreferences(values);
  }

  final Map<String, Object> _values = {};

  /// A copy of everything currently held — for tests and diagnostics.
  Map<String, Object> snapshot() => {
    for (final entry in _values.entries) entry.key: _copy(entry.value),
  };

  static Object _copy(Object value) =>
      value is List ? List<String>.from(value) : value;

  @override
  Set<String> getKeys() => Set<String>.from(_values.keys);

  @override
  Object? get(String key) {
    final value = _values[key];
    return value == null ? null : _copy(value);
  }

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  int? getInt(String key) => _values[key] as int?;

  @override
  double? getDouble(String key) => _values[key] as double?;

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  bool containsKey(String key) => _values.containsKey(key);

  @override
  List<String>? getStringList(String key) {
    final value = _values[key];
    return value == null ? null : List<String>.from(value as List);
  }

  @override
  Future<bool> setBool(String key, bool value) => _set(key, value);

  @override
  Future<bool> setInt(String key, int value) => _set(key, value);

  @override
  Future<bool> setDouble(String key, double value) => _set(key, value);

  @override
  Future<bool> setString(String key, String value) => _set(key, value);

  @override
  Future<bool> setStringList(String key, List<String> value) =>
      _set(key, List<String>.from(value));

  @override
  Future<bool> remove(String key) async {
    _values.remove(key);
    return true;
  }

  @override
  Future<bool> commit() async => true;

  @override
  Future<bool> clear() async {
    _values.clear();
    return true;
  }

  @override
  Future<void> reload() async {}

  Future<bool> _set(String key, Object value) async {
    _values[key] = value;
    return true;
  }
}
