import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/shared_preferences_provider.dart';
import '../../home/application/circle_journal.dart';
import '../../home/application/home_invitation_slot.dart';
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
/// `false` whenever reminders are already enabled or a reflection question
/// is currently pending (`reflectionPendingProvider` — parent §28's
/// prompt-priority rule: reflection first, then the reminder invitation,
/// then Premium). Otherwise, if the reminder invitation already owns this
/// session's invitation slot (`home_invitation_slot.dart`), it stays until
/// closed — the persisted flag, written once it has been meaningfully
/// visible, is not re-read for the session's own invitation. If the slot
/// is free, the existing eligibility applies: never shown in an earlier
/// session, and at least one Circle closed.
///
/// Watches only `enabled` of the reminder state: permission / timezone /
/// exact-alarm refreshes (every startup and resume) are not eligibility.
final showReminderInvitationProvider = Provider<bool>((ref) {
  if (ref.watch(reflectionPendingProvider)) return false;
  if (ref.watch(reminderProvider.select((state) => state.enabled))) {
    return false;
  }

  final slot = ref.watch(homeInvitationSlotProvider);
  if (slot.owner == HomeInvitation.reminder) return !slot.closed;
  if (slot.owner != null) return false;

  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs.getBool(reminderInvitationShownKey) ?? false) return false;

  final hasClosedAnyCircleEver = ref
      .watch(circleJournalRepositoryProvider)
      .readAll()
      .any((entry) => entry.closedAt != null);
  return hasClosedAnyCircleEver;
});
