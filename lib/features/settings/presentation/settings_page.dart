import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/branding/thirty_wordmark_view.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../premium/presentation/widgets/premium_restore_footer.dart';
import 'widgets/you_about_card.dart';
import 'widgets/you_data_card.dart';
import 'widgets/you_group_card.dart';
import 'widgets/you_header_art.dart';
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
/// the same page, presentation changes only. Premium continues to work
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
/// - theme (System/Light/Dark) — [themeModeProvider], persisted locally;
/// - analytics consent (`AnalyticsConsentNotifier` — off by default, the
///   sole gate `analyticsServiceProvider` checks before transmitting
///   anything);
/// - the local reminder's on/off state, permission state and one time
///   (`ReminderNotifier` — parent §27/§28), reusing the same
///   `showTimePicker` flow as `ReminderInvitationCard`;
/// - the existing Circle-history data controls (export, and delete of the
///   Circle history itself — [YouDataCard]);
/// - the running build's version ([YouAboutCard]).
///
/// Deliberately **not** included, because no authoritative value exists
/// anywhere in this repository to back it truthfully: a support contact
/// and a privacy-policy link.
///
/// **North Star convergence** (founder-approved order): the scrolling
/// header in the Plans / Insights language — the THIRTY wordmark, "You" in
/// the editorial serif, [subtitle], the You band ([youHeaderArt]) — with no
/// profile button, since on You it would only open the page it is on. Then
/// the THIRTY Premium card ([YouPremiumCard]), "Preferences"
/// ([YouPreferencesCard]), "Data & privacy" ([YouDataCard]), "About"
/// ([YouAboutCard]) and, last, the quiet "Restore purchases" footer
/// ([PremiumRestoreFooter]) — reachable in every state it was before, but
/// never competing with the Premium proposition.
///
/// A future personal row (an optional first name, edited here) belongs as
/// its own one-row [YouGroupCard] between the Premium card and
/// "Preferences" — the top of the personal content — without reordering
/// anything else.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const title = 'You';
  static const subtitle = 'Your space in THIRTY.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider);
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    // No pinned Material AppBar: the header scrolls with the page, as on
    // Home, Plans and Insights.
    return Scaffold(
      body: SafeArea(
        child: ListView(
          // Room below Restore so its last line clears the page's bottom
          // edge (the floating nav sits outside this page's body).
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            const _YouTopBar(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: AppTypography.editorialDisplay(
                        colors,
                      ).copyWith(fontSize: 34, height: 1.05),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            YouHeaderArt(art: youHeaderArt, now: now),
            const SizedBox(height: AppSpacing.l),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  YouPremiumCard(),
                  SizedBox(height: AppSpacing.section),
                  YouSectionHeading('Preferences'),
                  SizedBox(height: AppSpacing.s),
                  YouPreferencesCard(),
                  SizedBox(height: AppSpacing.section),
                  YouSectionHeading('Data & privacy'),
                  SizedBox(height: AppSpacing.s),
                  YouDataCard(),
                  SizedBox(height: AppSpacing.section),
                  YouSectionHeading('About'),
                  SizedBox(height: AppSpacing.s),
                  YouAboutCard(),
                  SizedBox(height: AppSpacing.l),
                  PremiumRestoreFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The THIRTY wordmark alone — the Plans / Insights top row without the
/// You button, which on You would only open the page it is on.
class _YouTopBar extends StatelessWidget {
  const _YouTopBar();

  static const height = 56.0;
  static const wordmarkWidth = 96.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Semantics(
            label: 'THIRTY',
            child: const ExcludeSemantics(
              child: SizedBox(
                width: wordmarkWidth,
                child: ThirtyWordmarkView(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
