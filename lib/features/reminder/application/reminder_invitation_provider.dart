import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/shared_preferences_provider.dart';
import '../../home/application/circle_journal.dart';
import '../../home/presentation/widgets/action_report_prompt.dart';
import 'reminder_provider.dart';

/// SharedPreferences key recording that THIRTY's one quiet reminder
/// invitation has already been shown — parent authority (`THIRTY V1
/// PRODUCTIZATION + COMMERCIAL REVIEW.md` §27): "after the first Circle
/// closes, the user becomes eligible for one unobtrusive invitation to
/// choose a daily reminder time." Once set, never cleared — declining or
/// accepting are both a completed decision, never re-prompted.
const reminderInvitationShownKey = 'reminder_invitation_shown_v1';

/// Whether `reminder_invitation_card.dart` should render right now.
///
/// `false` whenever reminders are already enabled, the invitation has
/// already been shown once, no Circle has ever been closed yet, or a
/// reflection question is currently pending
/// (`reflectionPendingProvider` — parent §28's prompt-priority rule:
/// reflection first, then the reminder invitation, then Premium).
final showReminderInvitationProvider = Provider<bool>((ref) {
  if (ref.watch(reflectionPendingProvider)) return false;
  if (ref.watch(reminderProvider).enabled) return false;

  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs.getBool(reminderInvitationShownKey) ?? false) return false;

  final hasClosedAnyCircleEver = ref
      .watch(circleJournalRepositoryProvider)
      .readAll()
      .any((entry) => entry.closedAt != null);
  return hasClosedAnyCircleEver;
});
