import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../domain/recommendation_engine.dart';
import 'activity_catalog.dart';

/// The user's explicit suggestion preferences (V2 Phase C, ADR-021): what
/// they asked THIRTY, on the memory page, not to suggest — or to suggest
/// again. Local only, user-owned and exportable, and deliberately separate
/// from the Circle journal: "Delete Circle history" keeps them, and they
/// have their own reset ([SuggestionPreferencesNotifier.reset]).
const suggestionPreferencesKey = 'suggestion_preferences_v1';
const suggestionPreferencesSchemaVersion = 1;

/// "Don't suggest" [activity] for [need], chosen on [since] (local date).
class NotSuggested {
  const NotSuggested({
    required this.activity,
    required this.need,
    required this.since,
  });

  final ActivityId activity;
  final Intention need;
  final DateTime since;

  Map<String, Object?> toJson() => {
    'activityId': activity.name,
    'need': need.name,
    'since': since.toIso8601String(),
  };

  static NotSuggested? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final activity = ActivityId.values.asNameMap()[json['activityId']];
    final need = Intention.values.asNameMap()[json['need']];
    final since = DateTime.tryParse('${json['since']}');
    if (activity == null || need == null || since == null) return null;
    return NotSuggested(activity: activity, need: need, since: since);
  }
}

/// "Suggest again" on [activity] while it rested for [need]: "Not useful"
/// answers given before [at] no longer rest it. The answers themselves stay
/// in history.
class RestLifted {
  const RestLifted({
    required this.activity,
    required this.need,
    required this.at,
  });

  final ActivityId activity;
  final Intention need;
  final DateTime at;

  Map<String, Object?> toJson() => {
    'activityId': activity.name,
    'need': need.name,
    'at': at.toIso8601String(),
  };

  static RestLifted? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final activity = ActivityId.values.asNameMap()[json['activityId']];
    final need = Intention.values.asNameMap()[json['need']];
    final at = DateTime.tryParse('${json['at']}');
    if (activity == null || need == null || at == null) return null;
    return RestLifted(activity: activity, need: need, at: at);
  }
}

class SuggestionPreferences {
  const SuggestionPreferences({
    this.notSuggested = const [],
    this.restsLifted = const [],
  });

  static const empty = SuggestionPreferences();

  final List<NotSuggested> notSuggested;
  final List<RestLifted> restsLifted;

  bool get isEmpty => notSuggested.isEmpty && restsLifted.isEmpty;

  bool isNotSuggested(ActivityId activity, Intention need) =>
      notSuggested.any((n) => n.activity == activity && n.need == need);

  /// What Recommendation Engine V2 and the memory page read.
  SuggestionControls get controls => SuggestionControls(
    notSuggested: {for (final n in notSuggested) (n.activity, n.need)},
    restsLifted: {for (final r in restsLifted) (r.activity, r.need): r.at},
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': suggestionPreferencesSchemaVersion,
    'notSuggested': [for (final n in notSuggested) n.toJson()],
    'restsLifted': [for (final r in restsLifted) r.toJson()],
  };

  /// Reads [raw], failing safe to [empty] for anything unreadable; a single
  /// malformed item is dropped, never the rest.
  static SuggestionPreferences fromRaw(String? raw) {
    if (raw == null) return empty;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return empty;
      if (decoded['schemaVersion'] != suggestionPreferencesSchemaVersion) {
        return empty;
      }
      List<T> items<T>(Object? list, T? Function(Object?) parse) => [
        if (list is List)
          for (final item in list)
            if (parse(item) case final T parsed) parsed,
      ];
      return SuggestionPreferences(
        notSuggested: items(decoded['notSuggested'], NotSuggested.fromJson),
        restsLifted: items(decoded['restsLifted'], RestLifted.fromJson),
      );
    } catch (_) {
      return empty;
    }
  }
}

class SuggestionPreferencesNotifier extends Notifier<SuggestionPreferences> {
  @override
  SuggestionPreferences build() => SuggestionPreferences.fromRaw(
    ref.watch(sharedPreferencesProvider).getString(suggestionPreferencesKey),
  );

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  Future<void> _save(SuggestionPreferences next) async {
    state = next;
    if (next.isEmpty) {
      await _prefs.remove(suggestionPreferencesKey);
    } else {
      await _prefs.setString(
        suggestionPreferencesKey,
        jsonEncode(next.toJson()),
      );
    }
  }

  /// "Don't suggest" [activity] for [need] — until the user says otherwise.
  Future<void> dontSuggest(ActivityId activity, Intention need) {
    if (state.isNotSuggested(activity, need)) return Future.value();
    return _save(
      SuggestionPreferences(
        notSuggested: [
          ...state.notSuggested,
          NotSuggested(
            activity: activity,
            need: need,
            since: ref.read(eventClockProvider)(),
          ),
        ],
        restsLifted: state.restsLifted,
      ),
    );
  }

  /// "Suggest again" for an activity the user asked THIRTY not to suggest:
  /// it is eligible under the normal rules again — nothing more.
  Future<void> allowAgain(ActivityId activity, Intention need) => _save(
    SuggestionPreferences(
      notSuggested: [
        for (final n in state.notSuggested)
          if (n.activity != activity || n.need != need) n,
      ],
      restsLifted: state.restsLifted,
    ),
  );

  /// "Suggest again" for an activity resting after "Not useful": the
  /// current rest ends now. The answer is kept.
  Future<void> liftRest(ActivityId activity, Intention need) => _save(
    SuggestionPreferences(
      notSuggested: state.notSuggested,
      restsLifted: [
        for (final r in state.restsLifted)
          if (r.activity != activity || r.need != need) r,
        RestLifted(
          activity: activity,
          need: need,
          at: ref.read(eventClockProvider)(),
        ),
      ],
    ),
  );

  /// "Reset suggestion preferences": every "Don't suggest" and lifted rest
  /// goes. Circle history and its answers stay.
  Future<void> reset() => _save(SuggestionPreferences.empty);
}

final suggestionPreferencesProvider =
    NotifierProvider<SuggestionPreferencesNotifier, SuggestionPreferences>(
      SuggestionPreferencesNotifier.new,
    );
