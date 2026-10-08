import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/shared_preferences_provider.dart';

/// The SharedPreferences key holding the user's optional first name.
const firstNameKey = 'user_first_name_v1';

/// The longest first name THIRTY accepts, in Unicode code points.
const maxFirstNameLength = 40;

/// The outcome of [FirstNameNotifier.setFirstName].
enum FirstNameSaveResult {
  /// The trimmed name was stored.
  saved,

  /// The input was blank after trimming, so any stored name was removed.
  cleared,

  /// The trimmed input is longer than [maxFirstNameLength]; nothing changed.
  tooLong,
}

/// [input] trimmed, or `null` when nothing is left.
String? trimmedFirstName(String input) {
  final trimmed = input.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Whether [input], once trimmed, fits [maxFirstNameLength] code points.
bool firstNameFits(String input) =>
    input.trim().runes.length <= maxFirstNameLength;

/// The user's optional first name — local personal data, held on this
/// device only.
///
/// One trimmed String, or `null` for none. It is never sent anywhere:
/// not to analytics, the Circle journal or its export, Insights, billing,
/// or Supabase. "Delete Circle history" leaves it alone; only
/// [clear] (or saving a blank name) removes it.
///
/// This is the one setter a future first-run question ("What should we
/// call you?") uses too — whether that question has been shown is that
/// flow's own concern, not state kept here.
class FirstNameNotifier extends Notifier<String?> {
  @override
  String? build() {
    // `get`, not `getString`: a corrupt non-String value must read as no
    // name, never throw.
    final stored = ref.read(sharedPreferencesProvider).get(firstNameKey);
    if (stored is! String) return null;
    final name = trimmedFirstName(stored);
    if (name == null || !firstNameFits(name)) return null;
    return name;
  }

  /// Stores [input] trimmed. A blank input removes the name instead; one
  /// over [maxFirstNameLength] code points is rejected — never truncated —
  /// and changes nothing.
  Future<FirstNameSaveResult> setFirstName(String input) async {
    final name = trimmedFirstName(input);
    if (name == null) {
      await clear();
      return FirstNameSaveResult.cleared;
    }
    if (!firstNameFits(name)) return FirstNameSaveResult.tooLong;
    state = name;
    await ref.read(sharedPreferencesProvider).setString(firstNameKey, name);
    return FirstNameSaveResult.saved;
  }

  /// Removes the stored name — and nothing else.
  Future<void> clear() async {
    state = null;
    await ref.read(sharedPreferencesProvider).remove(firstNameKey);
  }
}

final firstNameProvider = NotifierProvider<FirstNameNotifier, String?>(
  FirstNameNotifier.new,
);

/// The SharedPreferences key recording that the first-use question
/// ("What should we call you?") has been resolved.
const firstNamePromptSeenKey = 'first_name_prompt_seen_v1';

/// Whether the first-use name question has been resolved — by saving a
/// name or by skipping it. Not the same as having a name: a user who
/// skipped, or later removed their name in You, has no name and is still
/// never asked again. Absent, `false` or malformed means "ask once".
class FirstNamePromptSeenNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).get(firstNamePromptSeenKey) == true;

  Future<void> markSeen() async {
    state = true;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(firstNamePromptSeenKey, true);
  }
}

final firstNamePromptSeenProvider =
    NotifierProvider<FirstNamePromptSeenNotifier, bool>(
      FirstNamePromptSeenNotifier.new,
    );
