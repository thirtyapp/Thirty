import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../../../core/widgets/thirty_card.dart';
import '../../../../core/widgets/viewport_visibility.dart';
import '../../../home/application/home_invitation_slot.dart';
import '../../application/reminder_invitation_provider.dart';
import '../../application/reminder_provider.dart';

/// THIRTY's one reminder invitation — parent authority (`THIRTY V1
/// PRODUCTIZATION + COMMERCIAL REVIEW.md` §27): "after the first Circle
/// closes, the user becomes eligible for one unobtrusive invitation to
/// choose a daily reminder time." §48's Reminder Return-Ritual Amendment
/// asks this one eligible moment to read as an invitation into THIRTY's
/// intended daily ritual, not a buried convenience — a wording change
/// only; eligibility, timing, and every consent/control guarantee below
/// are unchanged.
///
/// Renders nothing unless [showReminderInvitationProvider] is `true`. A
/// plain inline card — never a dialog, never a permission prompt by
/// itself (the OS permission is requested only after the user taps
/// "Choose a time" and actually picks one).
///
/// Invitation semantics (`home_invitation_slot.dart`): the first render
/// claims this session's invitation slot, so the card stays until "Not
/// now", a chosen time, or reminders being enabled — no provider refresh
/// can remove it or hand its place to Premium. The persisted "shown" flag
/// is written only once the card has been meaningfully visible
/// ([ViewportVisibility]); a card that only rendered below the fold may
/// appear again in a later session. Mirrors `PremiumOfferInvitationCard`.
class ReminderInvitationCard extends ConsumerStatefulWidget {
  const ReminderInvitationCard({super.key});

  @override
  ConsumerState<ReminderInvitationCard> createState() =>
      _ReminderInvitationCardState();
}

class _ReminderInvitationCardState
    extends ConsumerState<ReminderInvitationCard> {
  void _dismiss() => ref
      .read(homeInvitationSlotProvider.notifier)
      .close(HomeInvitation.reminder);

  void _markShown() {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getBool(reminderInvitationShownKey) ?? false) return;
    prefs.setBool(reminderInvitationShownKey, true);
  }

  Future<void> _chooseTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked == null || !mounted) return;
    await ref
        .read(reminderProvider.notifier)
        .enable(hour: picked.hour, minute: picked.minute);
    if (mounted) _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final shouldShow = ref.watch(showReminderInvitationProvider);
    if (!shouldShow) return const SizedBox.shrink();

    // Selected for this session: claim the invitation slot (idempotent).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(homeInvitationSlotProvider.notifier)
          .claim(HomeInvitation.reminder);
    });

    final textTheme = Theme.of(context).textTheme;
    final card = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.page,
      ),
      child: ThirtyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'When would you like THIRTY to remind you about tomorrow\'s '
              'Circle?',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                Expanded(
                  child: ThirtyButton(
                    label: 'Choose a time',
                    onPressed: _chooseTime,
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: ThirtyButton(
                    label: 'Not now',
                    variant: ThirtyButtonVariant.secondary,
                    onPressed: _dismiss,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return ViewportVisibility(onVisible: _markShown, child: card);
  }
}
