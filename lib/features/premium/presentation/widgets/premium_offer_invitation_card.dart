import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/viewport_visibility.dart';
import '../../../home/application/home_invitation_slot.dart';
import '../../application/premium_offer_provider.dart';

/// THIRTY's one quiet Premium invitation — frozen architecture §26.
///
/// Renders nothing unless [showPremiumOfferInvitationProvider] is `true`.
/// A plain inline row (a card before Phase D1), never a dialog/interstitial/snackbar — it never
/// interrupts an active Circle and never stacks with the action-report or
/// Plan-session surfaces already on this screen (frozen architecture §12).
/// A one-time event, not a dismiss-to-hide banner (see
/// [premiumOfferInvitationShownKey]). Invitation semantics
/// (`home_invitation_slot.dart`): the first render claims this session's
/// invitation slot, so the card stays for the session (until entitlement)
/// and no refresh can remove it; the persisted "shown" flag is written
/// only once it has been meaningfully visible ([ViewportVisibility]), so
/// a card that only rendered below the fold may appear in a later
/// session.
class PremiumOfferInvitationCard extends ConsumerStatefulWidget {
  const PremiumOfferInvitationCard({super.key});

  @override
  ConsumerState<PremiumOfferInvitationCard> createState() =>
      _PremiumOfferInvitationCardState();
}

class _PremiumOfferInvitationCardState
    extends ConsumerState<PremiumOfferInvitationCard> {
  void _markShown() {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getBool(premiumOfferInvitationShownKey) ?? false) return;
    prefs.setBool(premiumOfferInvitationShownKey, true);
  }

  @override
  Widget build(BuildContext context) {
    final shouldShow = ref.watch(showPremiumOfferInvitationProvider);
    if (!shouldShow) return const SizedBox.shrink();

    // Selected for this session: claim the invitation slot (idempotent).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(homeInvitationSlotProvider.notifier)
          .claim(HomeInvitation.premium);
    });

    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    // Phase D1 (Design vision): a flat "Later today" row — icon chip,
    // copy, chevron — on the page itself rather than a card. The chevron
    // is read as "Learn more", so the row still says where it leads.
    final card = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page - AppSpacing.s,
        0,
        AppSpacing.page - AppSpacing.s,
        AppSpacing.page,
      ),
      child: MergeSemantics(
        child: Semantics(
          button: true,
          child: InkWell(
            onTap: () => context.push('/premium'),
            borderRadius: AppRadius.large,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s,
                  vertical: AppSpacing.s,
                ),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.surfaceMuted,
                        ),
                        child: Icon(
                          Icons.auto_awesome_outlined,
                          size: 22,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Text(
                        'THIRTY Premium adds guided Plans, Coach and Insights.',
                        style: textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Semantics(
                      label: 'Learn more',
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return ViewportVisibility(onVisible: _markShown, child: card);
  }
}
