import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../../../core/widgets/thirty_card.dart';
import '../../application/reminder_invitation_provider.dart';
import '../../application/reminder_provider.dart';

/// THIRTY's one quiet reminder invitation — parent authority (`THIRTY V1
/// PRODUCTIZATION + COMMERCIAL REVIEW.md` §27): "after the first Circle
/// closes, the user becomes eligible for one unobtrusive invitation to
/// choose a daily reminder time."
///
/// Renders nothing unless [showReminderInvitationProvider] is `true`. A
/// plain inline card — never a dialog, never a permission prompt by
/// itself (the OS permission is requested only after the user taps
/// "Choose a time" and actually picks one). Marks itself shown (so it
/// never appears again, regardless of the outcome) the first time it
/// actually renders — mirroring `PremiumOfferInvitationCard`'s own
/// established pattern for the same "single... invitation" semantics.
class ReminderInvitationCard extends ConsumerStatefulWidget {
  const ReminderInvitationCard({super.key});

  @override
  ConsumerState<ReminderInvitationCard> createState() =>
      _ReminderInvitationCardState();
}

class _ReminderInvitationCardState
    extends ConsumerState<ReminderInvitationCard> {
  bool _dismissed = false;

  void _dismiss() => setState(() => _dismissed = true);

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
    final shouldShow = !_dismissed && ref.watch(showReminderInvitationProvider);
    if (!shouldShow) return const SizedBox.shrink();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(sharedPreferencesProvider)
          .setBool(reminderInvitationShownKey, true);
    });

    final textTheme = Theme.of(context).textTheme;
    return Padding(
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
              'A moment for your next Circle, if it fits today.',
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
  }
}
