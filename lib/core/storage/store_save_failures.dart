import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which of the user's own stores a save failed for (audit remediation R8;
/// suggestion preferences since R8.1, Astra N05; today's Circle since R8.2,
/// founder decision B — a Start refused because the Circle, or its Plan's
/// record of the Start, couldn't be saved first).
enum UserStore {
  keptCircles,
  circlePlans,
  insights,
  suggestionPreferences,
  todaysCircle,
}

/// Saves of the user's own things — kept Circles, Circle Plans, Insights —
/// that the local store didn't confirm (audit remediation R8, Claude F-6,
/// Astra R7-A03). Each failure is an event the app shell tells the user
/// about (`JournalSaveFailureNotice`); nothing is ever shown as saved that
/// wasn't. History has its own, per Circle (`journalSaveStatusProvider`).
class StoreSaveFailures extends Notifier<StoreSaveState> {
  @override
  StoreSaveState build() => const StoreSaveState();

  /// A save of [store] wasn't confirmed: what is on screen for it is now
  /// unsaved — pending retry by its next save. With [notify], the user is
  /// told ([count]); without, the caller tells them its own way.
  void record(UserStore store, {bool notify = true}) => state = StoreSaveState(
    count: notify ? state.count + 1 : state.count,
    last: notify ? store : state.last,
    unsaved: {...state.unsaved, store},
  );

  /// A save of [store] was confirmed, holding everything on screen for it:
  /// durably saved.
  void saved(UserStore store) {
    if (!state.unsaved.contains(store)) return;
    state = StoreSaveState(
      count: state.count,
      last: state.last,
      unsaved: {...state.unsaved}..remove(store),
    );
  }
}

/// The failures told so far ([count], [last]) and which stores' last save
/// failed with no confirmed save since ([unsaved]) — what it tried to save
/// isn't on disk. Since R8.1 RL-1 a Plans or Insights change that failed is
/// also taken back off the screen; its store stays in [unsaved] until a
/// later save of it is confirmed, and is gone after a restart. A store not
/// in [unsaved] is durably saved.
class StoreSaveState {
  const StoreSaveState({this.count = 0, this.last, this.unsaved = const {}});

  final int count;
  final UserStore? last;
  final Set<UserStore> unsaved;
}

final storeSaveFailuresProvider =
    NotifierProvider<StoreSaveFailures, StoreSaveState>(StoreSaveFailures.new);
