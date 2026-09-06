import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/premium/entitlement_gateway.dart';
import '../../../core/premium/entitlement_status.dart';
import '../../../core/premium/premium_access.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_button.dart';
import '../../../core/widgets/thirty_card.dart';

/// THIRTY's one Premium offer surface — Step 5
/// (`docs/product/adr/ADR-017-v1-step5-revenuecat-billing.md`).
///
/// Reachable from Settings' "Upgrade to Premium" row and from the quiet,
/// single, non-modal invitation on the home screen after a user's second
/// closed Circle on a distinct date (`home_offer_invitation.dart`, frozen
/// architecture §26). There is no other entry point — no interstitial, no
/// forced paywall on Free Circle launch (frozen architecture §12).
///
/// States the actual paid contract truthfully: Plans + Coach + Insights,
/// the real localized monthly price returned by the store (never a
/// hardcoded figure), automatic monthly renewal, that Free remains
/// available either way, how management/cancellation works, restore, and
/// that THIRTY's personal history is device-local, not cloud-synced.
/// Never mentions Atmosphere, AI, trials, annual pricing or scarcity
/// language (frozen architecture §11/§12).
class PremiumOfferPage extends ConsumerStatefulWidget {
  const PremiumOfferPage({super.key});

  @override
  ConsumerState<PremiumOfferPage> createState() => _PremiumOfferPageState();
}

class _PremiumOfferPageState extends ConsumerState<PremiumOfferPage> {
  late Future<MonthlyOffer?> _offerFuture;
  bool _isPurchasing = false;
  bool _isRestoring = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _offerFuture = ref.read(entitlementGatewayProvider).monthlyOffer();
  }

  Future<void> _purchase() async {
    setState(() {
      _isPurchasing = true;
      _message = null;
    });
    final outcome = await ref
        .read(entitlementStatusProvider.notifier)
        .purchaseMonthly();
    if (!mounted) return;
    setState(() {
      _isPurchasing = false;
      _message = switch (outcome) {
        PurchaseOutcome.purchased => 'You now have Premium.',
        PurchaseOutcome.userCancelled => null,
        PurchaseOutcome.unavailable =>
          'Premium isn’t available to purchase right now.',
        PurchaseOutcome.error =>
          'Something went wrong. Please try again in a moment.',
      };
    });
  }

  Future<void> _restore() async {
    setState(() {
      _isRestoring = true;
      _message = null;
    });
    final outcome = await ref.read(entitlementStatusProvider.notifier).restore();
    if (!mounted) return;
    setState(() {
      _isRestoring = false;
      _message = switch (outcome) {
        RestoreOutcome.restored => 'Your Premium access has been restored.',
        RestoreOutcome.notFound => 'No previous purchase was found to restore.',
        RestoreOutcome.unavailable =>
          'Restore isn’t available right now. Please try again later.',
        RestoreOutcome.error =>
          'Something went wrong restoring your purchase. Please try again.',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final isEntitled = ref.watch(premiumEntitlementProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('THIRTY Premium')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            Text('Plans, Coach and Insights', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s),
            Text(
              'A guided path that remembers your place, helps you adjust '
              'its pace, and uses your own recorded choices to make the '
              'next step easier to work with.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.m),
            ThirtyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _OfferPoint(text: 'Three guided Circle Plans that remember your place'),
                  _OfferPoint(text: 'Circle Coach: contextual pacing and gentle resumption'),
                  _OfferPoint(text: 'Circle Insights: what your own choices tell you'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            if (isEntitled)
              Text(
                'You already have Premium.',
                style: textTheme.bodyMedium?.copyWith(color: colors.primary),
              )
            else ...[
              FutureBuilder<MonthlyOffer?>(
                future: _offerFuture,
                builder: (context, snapshot) {
                  final offer = snapshot.data;
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.s),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (offer == null) {
                    return Text(
                      'Premium is temporarily unavailable. Please try '
                      'again later.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${offer.localizedPrice} / month, billed automatically '
                        'until cancelled.',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.s),
                      ThirtyButton(
                        label: 'Subscribe',
                        isLoading: _isPurchasing,
                        onPressed: _isPurchasing ? null : _purchase,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.s),
              ThirtyButton(
                label: 'Restore purchases',
                variant: ThirtyButtonVariant.secondary,
                isLoading: _isRestoring,
                onPressed: _isRestoring ? null : _restore,
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: AppSpacing.s),
              Semantics(
                liveRegion: true,
                child: Text(
                  _message!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.m),
            Text(
              'Free remains complete either way. You can cancel anytime '
              'through Google Play; access continues until the current '
              'paid period ends. Your Circle history stays on this '
              'device only — it is not backed up to the cloud, so '
              'restoring a purchase recovers Premium access but not a '
              'lost device’s history.',
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferPoint extends StatelessWidget {
  const _OfferPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
