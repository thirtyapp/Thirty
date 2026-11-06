import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/storage/confirmed_write.dart';
import '../../../core/storage/store_save_failures.dart';
import '../../personal_circle/domain/circle_elements.dart';
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
    this.source,
  });

  final ActivityId activity;
  final Intention need;
  final DateTime since;

  /// The stored item this was read from, written back exactly as stored
  /// (R8.2, Astra R81-A05) — a newer build's fields too. An item is never
  /// changed in place, only added or removed.
  final Map<String, Object?>? source;

  Map<String, Object?> toJson() =>
      source ??
      {
        'activityId': activity.name,
        'need': need.name,
        'since': since.toIso8601String(),
      };

  static NotSuggested? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final activity = ActivityId.values.asNameMap()[json['activityId']];
    final need = Intention.values.asNameMap()[json['need']];
    final since = _storedDate(json['since']);
    if (activity == null || need == null || since == null) return null;
    return NotSuggested(
      activity: activity,
      need: need,
      since: since,
      source: json,
    );
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
    this.source,
  });

  final ActivityId activity;
  final Intention need;
  final DateTime at;

  /// As [NotSuggested.source].
  final Map<String, Object?>? source;

  Map<String, Object?> toJson() =>
      source ??
      {
        'activityId': activity.name,
        'need': need.name,
        'at': at.toIso8601String(),
      };

  static RestLifted? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final activity = ActivityId.values.asNameMap()[json['activityId']];
    final need = Intention.values.asNameMap()[json['need']];
    final at = _storedDate(json['at']);
    if (activity == null || need == null || at == null) return null;
    return RestLifted(activity: activity, need: need, at: at, source: json);
  }
}

/// The retired Phase D field for "Don't suggest" on a routine. Routines are
/// retired before release (ADR-024): it is never read, and the pre-release
/// migration (`phase_d_retirement.dart`) and the next save drop it.
const retiredRoutinesNotSuggestedField = 'routinesNotSuggested';

/// V2 Phase D2 (ADR-023 §7): "Leave this out next time" — an element the
/// user asked THIRTY not to put in their Personal Guided Circles again,
/// chosen on [since]. An explicit preference about future composition,
/// never a usefulness answer, and reversible in Memory.
class ElementLeftOut {
  const ElementLeftOut({
    required this.element,
    required this.since,
    this.byInsight,
    this.source,
  });

  final ElementId element;
  final DateTime since;

  /// The Insight (I3) whose own action left [element] out, when it was one
  /// (R8.2, founder decision C): saved with it, so a retry can tell that
  /// Insight's change from the same part left out some other way.
  final String? byInsight;

  /// As [NotSuggested.source].
  final Map<String, Object?>? source;

  Map<String, Object?> toJson() =>
      source ??
      {
        'elementId': element.name,
        'since': since.toIso8601String(),
        'byInsight': ?byInsight,
      };

  static ElementLeftOut? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final element = ElementId.values.asNameMap()[json['elementId']];
    final since = _storedDate(json['since']);
    if (element == null || since == null) return null;
    final by = json['byInsight'];
    return ElementLeftOut(
      element: element,
      since: since,
      // Anything but text attributes nothing; it is kept as stored.
      byInsight: by is String ? by : null,
      source: json,
    );
  }
}

/// A stored date: text THIRTY wrote with [DateTime.toIso8601String], or
/// `null` (R8.2, Astra R81-A05) — a number or anything else is never read
/// as a date; its item is kept as stored ([SuggestionPreferences
/// .unreadable]) and never applied.
DateTime? _storedDate(Object? raw) =>
    raw is String ? DateTime.tryParse(raw) : null;

class SuggestionPreferences {
  const SuggestionPreferences({
    this.notSuggested = const [],
    this.restsLifted = const [],
    this.elementsLeftOut = const [],
    this.unreadable = const {},
    this.extra = const {},
  });

  static const empty = SuggestionPreferences();

  final List<NotSuggested> notSuggested;
  final List<RestLifted> restsLifted;

  /// V2 Phase D2.
  final List<ElementLeftOut> elementsLeftOut;

  /// Stored items THIRTY can't read, by list (R8.1 RL-3) — a damaged one, or
  /// one naming an activity or part this build doesn't know — exactly as
  /// stored: never applied, written back by every save. Reset removes them.
  final Map<String, List<Object?>> unreadable;

  /// Fields of the stored record this build doesn't know, written back as
  /// stored (R8.1 RL-3) — except the retired Phase D routines field, which
  /// the next save drops ([retiredRoutinesNotSuggestedField]).
  final Map<String, Object?> extra;

  bool get isEmpty =>
      notSuggested.isEmpty &&
      restsLifted.isEmpty &&
      elementsLeftOut.isEmpty &&
      unreadable.values.every((items) => items.isEmpty) &&
      extra.isEmpty;

  /// What the Personal Guided Circle composer reads.
  Set<ElementId> get leftOut => {for (final e in elementsLeftOut) e.element};

  bool isLeftOut(ElementId element) =>
      elementsLeftOut.any((e) => e.element == element);

  SuggestionPreferences copyWith({
    List<NotSuggested>? notSuggested,
    List<RestLifted>? restsLifted,
    List<ElementLeftOut>? elementsLeftOut,
  }) => SuggestionPreferences(
    notSuggested: notSuggested ?? this.notSuggested,
    restsLifted: restsLifted ?? this.restsLifted,
    elementsLeftOut: elementsLeftOut ?? this.elementsLeftOut,
    unreadable: unreadable,
    extra: extra,
  );

  bool isNotSuggested(ActivityId activity, Intention need) =>
      notSuggested.any((n) => n.activity == activity && n.need == need);

  /// What Recommendation Engine V2 and the memory page read.
  SuggestionControls get controls => SuggestionControls(
    notSuggested: {for (final n in notSuggested) (n.activity, n.need)},
    restsLifted: {for (final r in restsLifted) (r.activity, r.need): r.at},
  );

  Map<String, Object?> toJson() => {
    ...extra,
    'schemaVersion': suggestionPreferencesSchemaVersion,
    'notSuggested': [
      for (final n in notSuggested) n.toJson(),
      ...?unreadable['notSuggested'],
    ],
    'restsLifted': [
      for (final r in restsLifted) r.toJson(),
      ...?unreadable['restsLifted'],
    ],
    'elementsLeftOut': [
      for (final e in elementsLeftOut) e.toJson(),
      ...?unreadable['elementsLeftOut'],
    ],
  };

  /// Reads [raw], failing safe to [empty] for anything unreadable; a single
  /// malformed item is set aside ([unreadable]), never the rest.
  static SuggestionPreferences fromRaw(String? raw) => tryRead(raw) ?? empty;

  /// [raw] read, or `null` when it is a record THIRTY can't read as a whole
  /// (R8.1 RL-3) — not JSON, not a record, a version this build doesn't
  /// know, or a list field that isn't a list. No record reads as [empty].
  ///
  /// R8.2 (Astra R81-A09): [raw] is the stored value as it is; one that
  /// isn't text can't be read either.
  static SuggestionPreferences? tryRead(Object? raw) {
    if (raw == null) return empty;
    if (raw is! String) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return null;
      if (decoded['schemaVersion'] != suggestionPreferencesSchemaVersion) {
        return null;
      }
      const lists = ['notSuggested', 'restsLifted', 'elementsLeftOut'];
      for (final list in lists) {
        final value = decoded[list];
        if (value != null && value is! List) return null;
      }
      final unreadable = <String, List<Object?>>{};
      List<T> items<T>(String list, T? Function(Object?) parse) {
        final read = <T>[];
        for (final item in (decoded[list] as List?) ?? const <Object?>[]) {
          switch (parse(item)) {
            case final T parsed:
              read.add(parsed);
            case null:
              (unreadable[list] ??= []).add(item);
          }
        }
        return read;
      }

      return SuggestionPreferences(
        notSuggested: items('notSuggested', NotSuggested.fromJson),
        restsLifted: items('restsLifted', RestLifted.fromJson),
        elementsLeftOut: items('elementsLeftOut', ElementLeftOut.fromJson),
        unreadable: unreadable,
        extra: {
          for (final MapEntry(:key, :value) in decoded.entries)
            if (key != 'schemaVersion' &&
                !lists.contains(key) &&
                key != retiredRoutinesNotSuggestedField)
              key: value,
        },
      );
    } catch (_) {
      return null;
    }
  }
}

class SuggestionPreferencesNotifier extends Notifier<SuggestionPreferences> {
  /// Whether the stored record is one THIRTY can't read as a whole (R8.1
  /// RL-3): then no change is written over it — only Reset, the user's own
  /// erasure, removes it.
  var _storedUnreadable = false;

  @override
  SuggestionPreferences build() {
    // R8.2 (Astra R81-A09): read as whatever native type is stored.
    final raw = ref.watch(sharedPreferencesProvider).get(suggestionPreferencesKey);
    final read = SuggestionPreferences.tryRead(raw);
    _storedUnreadable = read == null;
    return read ?? SuggestionPreferences.empty;
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  Future<void> _writes = Future<void>.value();

  /// Applies [change] to the preferences as they then stand, and shows the
  /// result once the store has confirmed it (R8.1, Astra N05; the R8 Kept
  /// Circles rule): a write that throws or returns `false` changes nothing —
  /// in memory or on disk — and the user is told
  /// ([storeSaveFailuresProvider]). Completes with whether the preferences
  /// now hold the change; changes run one after another, each on what the
  /// one before it left. [change] returning `null` changes nothing.
  ///
  /// R8.1 RL-3: never over a stored record THIRTY can't read ([tryRead]):
  /// the change is refused, the stored bytes stay, and the user is told —
  /// unless [erase] (Reset).
  Future<bool> _save(
    SuggestionPreferences? Function(SuggestionPreferences current) change, {
    bool erase = false,
  }) {
    final prefs = _prefs;
    final run = _writes.then((_) async {
      final next = change(state);
      if (next == null) return true;
      if (_storedUnreadable && !erase) {
        if (ref.mounted) {
          ref
              .read(storeSaveFailuresProvider.notifier)
              .record(UserStore.suggestionPreferences);
        }
        return false;
      }
      try {
        await writeConfirmed(
          prefs,
          suggestionPreferencesKey,
          next.isEmpty ? null : jsonEncode(next.toJson()),
        );
      } on StorageWriteFailed {
        if (ref.mounted) {
          ref
              .read(storeSaveFailuresProvider.notifier)
              .record(UserStore.suggestionPreferences);
        }
        return false;
      }
      _storedUnreadable = false;
      if (ref.mounted) {
        state = next;
        ref
            .read(storeSaveFailuresProvider.notifier)
            .saved(UserStore.suggestionPreferences);
      }
      return true;
    });
    _writes = run.then((_) {}, onError: (Object _) {});
    return run;
  }

  /// "Don't suggest" [activity] for [need] — until the user says otherwise.
  Future<bool> dontSuggest(ActivityId activity, Intention need) {
    final since = ref.read(eventClockProvider)();
    return _save(
      (current) => current.isNotSuggested(activity, need)
          ? null
          : current.copyWith(
              notSuggested: [
                ...current.notSuggested,
                NotSuggested(activity: activity, need: need, since: since),
              ],
            ),
    );
  }

  /// "Suggest again" for an activity the user asked THIRTY not to suggest:
  /// it is eligible under the normal rules again — nothing more.
  Future<bool> allowAgain(ActivityId activity, Intention need) => _save(
    (current) => current.copyWith(
      notSuggested: [
        for (final n in current.notSuggested)
          if (n.activity != activity || n.need != need) n,
      ],
    ),
  );

  /// "Suggest again" for an activity resting after "Not useful": the
  /// current rest ends now. The answer is kept.
  Future<bool> liftRest(ActivityId activity, Intention need) {
    final at = ref.read(eventClockProvider)();
    return _save(
      (current) => current.copyWith(
        restsLifted: [
          for (final r in current.restsLifted)
            if (r.activity != activity || r.need != need) r,
          RestLifted(activity: activity, need: need, at: at),
        ],
      ),
    );
  }

  /// V2 Phase D2: "Leave this out next time" — [element] stays out of the
  /// user's Personal Guided Circles until they put it back.
  ///
  /// [byInsight]: the I3 Insight whose own action this is (R8.2, founder
  /// decision C), saved with the part ([ElementLeftOut.byInsight]).
  Future<bool> leaveOut(ElementId element, {String? byInsight}) {
    final since = ref.read(eventClockProvider)();
    return _save(
      (current) => current.isLeftOut(element)
          ? null
          : current.copyWith(
              elementsLeftOut: [
                ...current.elementsLeftOut,
                ElementLeftOut(
                  element: element,
                  since: since,
                  byInsight: byInsight,
                ),
              ],
            ),
    );
  }

  /// V2 Phase D2: "Put it back" — [element] may be composed again.
  Future<bool> putBack(ElementId element) => _save(
    (current) => current.copyWith(
      elementsLeftOut: [
        for (final e in current.elementsLeftOut)
          if (e.element != element) e,
      ],
    ),
  );

  /// "Reset suggestion preferences": every "Don't suggest", lifted rest and
  /// left-out part goes. Circle history and its answers stay.
  ///
  /// R8.1 RL-3: the user's own erasure — it removes a stored record THIRTY
  /// can't read too, and every item set aside as unreadable.
  Future<bool> reset() =>
      _save((_) => SuggestionPreferences.empty, erase: true);
}

final suggestionPreferencesProvider =
    NotifierProvider<SuggestionPreferencesNotifier, SuggestionPreferences>(
      SuggestionPreferencesNotifier.new,
    );
