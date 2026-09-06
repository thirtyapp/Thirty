import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/premium/premium_access.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../home/application/circle_journal.dart';
import '../../home/presentation/widgets/action_report_prompt.dart';
import '../../reminder/application/reminder_invitation_provider.dart';

/// SharedPreferences key recording that THIRTY's one quiet Premium
/// invitation has already been shown — frozen architecture §26: "a single
/// nonmodal invitation after the second closed Circle on distinct dates."
/// Once set, never cleared: this is deliberately not tied to entitlement
/// state, so losing/regaining Premium never re-triggers it (frozen
/// architecture §12 — no repeated interstitials, no stacked prompts).
const premiumOfferInvitationShownKey = 'premium_offer_invitation_shown_v1';

/// Whether `premium_offer_invitation_card.dart` should render right now.
///
/// `false` whenever already entitled, already shown once, fewer than two
/// distinct local dates have a closed Circle, a reflection question is
/// currently pending, **or the reminder invitation is currently being
/// shown**. This is the parent V1 prompt-priority rule in full (`THIRTY
/// V1 PRODUCTIZATION + COMMERCIAL REVIEW.md` §28): reflection first, then
/// an eligible reminder invitation, then Premium — "an eligible Premium
/// invitation waits until neither is being presented" — never stacked on
/// the same screen. Recomputed on every read from the journal's actual
/// current contents — this app has no separate cached counter to drift
/// out of sync with it.
final showPremiumOfferInvitationProvider = Provider<bool>((ref) {
  if (ref.watch(premiumEntitlementProvider)) return false;
  if (ref.watch(reflectionPendingProvider)) return false;
  if (ref.watch(showReminderInvitationProvider)) return false;

  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs.getBool(premiumOfferInvitationShownKey) ?? false) return false;

  final entries = ref.watch(circleJournalRepositoryProvider).readAll();
  final distinctClosedDates = <String>{
    for (final entry in entries)
      if (entry.closedAt != null) entry.localDate,
  };
  return distinctClosedDates.length >= 2;
});
