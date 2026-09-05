import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/utils/date_key.dart';

/// SharedPreferences key for the last local calendar date (`YYYY-MM-DD`)
/// on which The First Breath ritual played. Exposed so tests can seed or
/// assert on it without duplicating the literal string.
const firstBreathLastPlayedDateKey = 'first_breath_last_played_date';

/// Whether The First Breath opening ritual should play on this app open.
///
/// The First Breath is a once-per-local-calendar-day ritual (Playbook
/// Ch.1 §4, "The Daily Ritual" — every day begins the same way, once).
/// `true` means it has not yet played today; `false` means it has, and the
/// Circle Hero should render its fully-settled state with no animation.
///
/// Only one value is persisted: the last date the ritual played. There is
/// deliberately no repository or service layer around it — this mirrors
/// [`RecommendationNotifier`](../../home/application/recommendation_provider.dart)
/// and [`ThemeModeNotifier`](../../../core/providers/theme_mode_provider.dart),
/// which also read/write their one piece of state directly.
class FirstBreathNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final today = dateKey(ref.watch(nowProvider));
    final lastPlayedDate = prefs.getString(firstBreathLastPlayedDateKey);
    return lastPlayedDate != today;
  }

  /// Marks The First Breath as played for today, so it does not play again
  /// until the local calendar date changes.
  Future<void> markPlayedToday() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final today = dateKey(ref.read(nowProvider));
    await prefs.setString(firstBreathLastPlayedDateKey, today);
    state = false;
  }
}

final firstBreathProvider = NotifierProvider<FirstBreathNotifier, bool>(
  FirstBreathNotifier.new,
);
