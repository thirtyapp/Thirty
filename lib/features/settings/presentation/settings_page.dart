import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import 'widgets/you_billing_footer.dart';
import 'widgets/you_data_card.dart';
import 'widgets/you_preferences_card.dart';
import 'widgets/you_premium_card.dart';

/// THIRTY's "You" destination — Step 5
/// (`docs/product/adr/ADR-017-v1-step5-revenuecat-billing.md`,
/// reconciled against the parent `THIRTY V1 PRODUCTIZATION + COMMERCIAL
/// REVIEW.md` §9/§32's actual V1 Settings minimum), retitled and
/// promoted to the fourth primary bottom-nav destination by the founder's
/// later IA correction ("Today | Plans | Insights | You").
///
/// **"You" is "my THIRTY experience and data," not "my account."** No
/// login, sign-in/out, avatar, demographic profile, cloud journal, or new
/// backend is introduced here — this class (`SettingsPage`, kept as the
/// existing name for continuity — see `core/routing/app_router.dart`) is
/// reused verbatim, presentation changes only. Premium continues to work
/// through the existing Google Play / managed-entitlement identity alone;
/// that identity and this page's local THIRTY data remain entirely
/// separate (restoring Premium entitlement never restores or implies
/// restoring local journal/Plan data, and vice versa).
///
/// Exposes exactly the controls that authority both requires *and* this
/// app can truthfully back today:
///
/// - Premium status/upgrade, restore, manage subscription (frozen
///   architecture §14);
/// - theme (System/Light/Dark) — [themeModeProvider] already drives
///   `ThirtyApp`'s real `MaterialApp.router`; before this screen, the
///   only place a user could reach it was the internal `/showcase`
///   developer route, not a real product surface;
/// - analytics consent (`AnalyticsConsentNotifier` — off by default, the
///   sole gate `analyticsServiceProvider` now checks before transmitting
///   anything);
/// - the local reminder's on/off state, permission state and one time
///   (`ReminderNotifier` — parent §27/§28), reusing the same
///   `showTimePicker` flow as `ReminderInvitationCard`;
/// - the existing Circle-history data controls (export/delete,
///   [JournalDataControls] — inline here since the IA correction, rather
///   than a link out to `/history`'s full list).
///
/// Deliberately **not** included, because no authoritative value exists
/// anywhere in this repository to back it truthfully — fabricating
/// either would be worse than omitting them: a support contact and a
/// privacy-policy link.
///
/// **Phase C1 layout** (approved commercial hierarchy): the THIRTY
/// Premium card first ([YouPremiumCard] — live store price, never a
/// hardcoded one; no acquisition CTA while the entitlement is unknown or
/// unavailable), the quiet billing footer with "Restore purchases"
/// ([YouBillingFooter]), then "Preferences" as one grouped card
/// ([YouPreferencesCard]: reminder, appearance, analytics), and "Your
/// data" last ([YouDataCard]), with "Delete all" as the final row.
///
/// `url_launcher` (used by the Premium card's manage link) is already
/// present transitively via `supabase_flutter`'s own dependency graph —
/// not a new package added for this screen (frozen architecture's
/// dependency-exception, §3 of the Step 5 report, is scoped to
/// `purchases_flutter` only).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('You')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            const YouPremiumCard(),
            const YouBillingFooter(),
            const SizedBox(height: AppSpacing.l),
            Text('Preferences', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s),
            const YouPreferencesCard(),
            const SizedBox(height: AppSpacing.l),
            Text('Your data', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s),
            const YouDataCard(),
          ],
        ),
      ),
    );
  }
}
