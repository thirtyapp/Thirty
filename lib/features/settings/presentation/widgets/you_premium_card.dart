import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/premium/entitlement_status.dart';
import '../../../../core/premium/premium_access.dart';
import '../../../../core/premium/premium_offer_providers.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/thirty_button.dart';
import '../../../../core/widgets/thirty_card.dart';

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
class YouPremiumCard extends ConsumerWidget {
  const YouPremiumCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final status = ref.watch(entitlementStatusProvider);

    return ThirtyCard(
      padding: const EdgeInsets.all(AppSpacing.featuredCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THIRTY Premium', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Plans, Coach and Insights',
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.m),
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
              _ManageSubscription(),
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

class _ManageSubscription extends ConsumerWidget {
  const _ManageSubscription();

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final urlState = ref.watch(subscriptionManagementUrlProvider);
    if (urlState.isLoading) return const SizedBox.shrink();

    final url = urlState.value;
    if (url == null) {
      return Text(
        'Manage or cancel this subscription from the Google Play Store app.',
        style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ThirtyButton(
        label: 'Manage subscription',
        variant: ThirtyButtonVariant.secondary,
        onPressed: () => _open(url),
      ),
    );
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
