import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/premium/entitlement_status.dart';
import '../../../../core/premium/premium_access.dart';
import '../../../../core/premium/premium_offer_providers.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../../../core/widgets/thirty_card.dart';
import '../../../premium/presentation/widgets/manage_subscription.dart';

/// You's Premium card — the top of You (Phase C1, approved commercial
/// hierarchy). One card, four billing states:
///
/// | status         | shows                                             |
/// |----------------|---------------------------------------------------|
/// | `initializing` | "Checking…" only — no acquisition CTA             |
/// | `inactive`     | live store price / month + "Become Premium"       |
/// | `active`       | "Premium is active" + manage (store URL or guide) |
/// | `unavailable`  | truthful "temporarily unavailable" — no CTA       |
///
/// The price is only ever the store's own localized string
/// ([monthlyOfferProvider]); with no offer there is no price, never a
/// hardcoded one. Purchase itself stays on the `/premium` offer page.
///
/// North Star convergence: a quiet Circle mark beside "THIRTY Premium" in
/// the editorial serif (the Insights Premium card's language), and one
/// founder-approved line naming what Premium is — never an outcome it
/// promises. The four states and everything they do are unchanged.
class YouPremiumCard extends ConsumerWidget {
  const YouPremiumCard({super.key});

  /// V2 Phase D: what Premium actually does.
  static const body =
      'Build a few routines of your own, and keep them fitting as your days '
      'change.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final status = ref.watch(entitlementStatusProvider);
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.3;

    return ThirtyCard(
      padding: const EdgeInsets.all(AppSpacing.featuredCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PremiumMark(size: largeText ? 40 : 44),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'THIRTY Premium',
                    style: AppTypography.editorialDisplay(
                      colors,
                    ).copyWith(fontSize: 21),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            body,
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.l),
          ...switch (status) {
            EntitlementStatus.initializing => const [
              _StatusText(label: 'Checking your Premium status…'),
            ],
            EntitlementStatus.inactive => [
              const _LivePrice(),
              const SizedBox(height: AppSpacing.m),
              SizedBox(
                width: double.infinity,
                child: ThirtyButton(
                  label: 'Become Premium',
                  onPressed: () => context.push('/premium'),
                ),
              ),
            ],
            EntitlementStatus.active => const [
              _StatusText(label: 'Premium is active', emphasis: true),
              SizedBox(height: AppSpacing.s),
              ManageSubscription(),
            ],
            EntitlementStatus.unavailable => const [
              _StatusText(
                label: 'Premium status is temporarily unavailable',
                description:
                    'This does not affect your saved records. Please try '
                    'again later.',
              ),
            ],
          },
        ],
      ),
    );
  }
}

/// The card's quiet identity mark: THIRTY's Circle — a sage ring on a muted
/// disc. Decorative; the headline beside it carries the meaning.
class _PremiumMark extends StatelessWidget {
  const _PremiumMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.surfaceMuted,
        ),
        alignment: Alignment.center,
        child: Container(
          width: size * 0.42,
          height: size * 0.42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}

/// The live store price for a free user. Loading shows nothing yet; no
/// offer shows a plain note instead of a price.
class _LivePrice extends ConsumerWidget {
  const _LivePrice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final offerState = ref.watch(monthlyOfferProvider);
    if (offerState.isLoading) return const SizedBox.shrink();

    final offer = offerState.value;
    if (offer == null) {
      return Text(
        'Pricing isn’t available right now.',
        style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
      );
    }
    return Text('${offer.localizedPrice} / month', style: textTheme.bodyLarge);
  }
}

/// A status line (and optional description) announced as one semantics
/// node, as before C1.
class _StatusText extends StatelessWidget {
  const _StatusText({
    required this.label,
    this.description,
    this.emphasis = false,
  });

  final String label;
  final String? description;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    return Semantics(
      label: description == null ? label : '$label. $description',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.bodyLarge?.copyWith(
                color: emphasis ? colors.primary : null,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                description!,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
