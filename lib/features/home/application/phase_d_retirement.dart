import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../personal_circle/application/kept_circles_provider.dart';
import '../../personal_circle/domain/kept_circle.dart';
import 'suggestion_preferences.dart';

/// The Phase D fields of the stored kept-Circle record (`toolkit_v1`) that
/// are retired before public release (ADR-024 §3): routines and their
/// versions, the Path under way, finished Paths, and maintenance memory.
const retiredToolkitFields = [
  'routines',
  'path',
  'finished',
  'declined',
  'lastCheckAt',
];

/// Set once the retirement has run.
const phaseDPremiumRetiredKey = 'phase_d_premium_retired';

/// Retires Phase D's Paths, routines and maintenance from local storage —
/// deterministically, idempotently, before anything reads the store
/// (`main.dart`, beside `retireV1Premium`).
///
/// **Nothing is migrated.** A Path's position is not a Circle Plan's, and a
/// routine is not a kept Circle: no Plan, kept Circle or claim is made from
/// them. Only the retired fields are removed; everything else in each record
/// is written back as it was stored, so every kept Circle stays exactly as
/// kept. What stays is what stays true: the kept Circles, every recorded
/// Circle (the journal, where routine and Path days keep their own labels),
/// and every other preference.
///
/// A record that can't be read is left untouched: the kept-Circle store sets
/// it aside on its own read, and nothing here guesses at it. Safe if
/// interrupted: each step is independent, the marker is written last, and
/// running it again changes nothing.
Future<void> retirePhaseDPremium(SharedPreferences prefs) async {
  if (prefs.getBool(phaseDPremiumRetiredKey) ?? false) return;

  final rawKept = prefs.getString(keptCirclesKey);
  final kept = _decode(rawKept);
  if (kept != null &&
      kept['schemaVersion'] == keptCirclesSchemaVersion &&
      retiredToolkitFields.any(kept.containsKey)) {
    retiredToolkitFields.forEach(kept.remove);
    await prefs.setString(keptCirclesKey, jsonEncode(kept));
  }

  final rawPreferences = prefs.getString(suggestionPreferencesKey);
  final preferences = _decode(rawPreferences);
  if (preferences != null &&
      preferences.containsKey(retiredRoutinesNotSuggestedField)) {
    preferences.remove(retiredRoutinesNotSuggestedField);
    await prefs.setString(suggestionPreferencesKey, jsonEncode(preferences));
  }

  await prefs.setBool(phaseDPremiumRetiredKey, true);
}

Map<String, Object?>? _decode(String? raw) {
  if (raw == null) return null;
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map<String, Object?> ? decoded : null;
  } catch (_) {
    return null;
  }
}
