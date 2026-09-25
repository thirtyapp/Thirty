import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/premium/entitlement_status.dart';
import '../../../core/premium/premium_access.dart';
import '../../../core/premium/premium_offer_providers.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_button.dart';
import '../../../core/widgets/thirty_card.dart';
import 'widgets/manage_subscription.dart';
import 'widgets/premium_restore_footer.dart';

/// THIRTY's one Premium offer surface — Step 5
/// (`docs/product/adr/ADR-017-v1-step5-revenuecat-billing.md`), recomposed
/// in Phase C2 to match the You funnel ("THIRTY Premium" → "Become
/// Premium").
///
/// Reachable from You's Premium card, Plans' and Insights' Premium entry
/// points, and the quiet, single, non-modal Home invitation after a
/// second closed Circle on a distinct date (frozen architecture §26). No
/// interstitial, no forced paywall on Free Circle launch (§12).
///
/// Answers, in order and without clutter: what you get (the value card:
/// Plans, Coach and Insights — the actual V1 Premium value), what it costs
/// (the store's own localized monthly price, never a hardcoded figure),
/// that it renews monthly until cancelled (the disclosure directly under
/// the price), that Free stays complete (next to the quiet "Not now"
/// exit), and how to restore or cancel (the shared restore footer and the
/// cancel line). One monthly auto-renewing subscription only — no trial,
/// annual price, urgency, testimonial or comparison (frozen architecture
/// §11/§12).
///
/// Purchase success is only claimed once the entitlement is confirmed
/// active; a pending Google Play payment and a still-confirming purchase
/// are explained, never shown as success or as an error.
class PremiumOfferPage extends ConsumerStatefulWidget {
  const PremiumOfferPage({super.key});

  @override
  ConsumerState<PremiumOfferPage> createState() => _PremiumOfferPageState();
}

class _PremiumOfferPageState extends ConsumerState<PremiumOfferPage> {
  bool _isPurchasing = false;
  String? _message;

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
        PurchaseOutcome.pending =>
          'Your payment is pending with Google Play. Premium unlocks when '
              'it completes.',
        PurchaseOutcome.confirming =>
          'Your purchase is being confirmed. Premium unlocks as soon as '
              'Google Play confirms it.',
      };
    });
  }

  void _leave() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final status = ref.watch(entitlementStatusProvider);
    final quiet = textTheme.bodySmall?.copyWith(color: colors.textSecondary);

    return Scaffold(
      appBar: AppBar(title: const Text('THIRTY Premium')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            Text('Plans, Coach and Insights', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.m),
            const _ValueCard(),
            const SizedBox(height: AppSpacing.l),
            switch (status) {
              EntitlementStatus.initializing => const _StatusNote(
                label: 'Checking your Premium status…',
              ),
              EntitlementStatus.unavailable => const _StatusNote(
                label: 'Premium status is temporarily unavailable',
                description:
                    'This does not affect your saved records. Please try '
                    'again later.',
              ),
              EntitlementStatus.active => _ActiveBlock(onDone: _leave),
              EntitlementStatus.inactive => _PurchaseBlock(
                isPurchasing: _isPurchasing,
                onPurchase: _purchase,
                onNotNow: _leave,
              ),
            },
            if (_message != null) ...[
              const SizedBox(height: AppSpacing.m),
              Semantics(
                liveRegion: true,
                child: Text(_message!, style: textTheme.bodyMedium),
              ),
            ],
            const SizedBox(height: AppSpacing.l),
            PremiumRestoreFooter(horizontalInset: 0, enabled: !_isPurchasing),
            const SizedBox(height: AppSpacing.s),
            Text(
              'You can cancel anytime in Google Play. Premium stays active '
              'until the end of your current billing period.',
              style: quiet,
            ),
          ],
        ),
      ),
    );
  }
}

/// What you get: Premium V1's three actual features.
class _ValueCard extends StatelessWidget {
  const _ValueCard();

  static const _points = [
    ('Circle Plans', 'three guided Plans that remember your place'),
    ('Circle Coach', 'contextual pacing and gentle resumption'),
    ('Circle Insights', 'what your own choices tell you'),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    return ThirtyCard(
      padding: const EdgeInsets.all(AppSpacing.featuredCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, (name, line)) in _points.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.m),
            // Its own semantics node: one screen-reader stop per point.
            Semantics(
              container: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Decorative: each point reads as one sentence.
                  ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: name,
                            style: textTheme.titleSmall?.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          TextSpan(text: ': $line'),
                        ],
                      ),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Free user: price, disclosure, the one CTA, and the quiet exit.
class _PurchaseBlock extends ConsumerWidget {
  const _PurchaseBlock({
    required this.isPurchasing,
    required this.onPurchase,
    required this.onNotNow,
  });

  final bool isPurchasing;
  final VoidCallback onPurchase;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final quiet = textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    final offerState = ref.watch(monthlyOfferProvider);
    final offer = offerState.value;
    final loading = offerState.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (loading)
          Semantics(
            liveRegion: true,
            child: Text('Checking the current price…', style: quiet),
          )
        else if (offer == null)
          Text('Pricing isn’t available right now.', style: quiet)
        else ...[
          Text('${offer.localizedPrice} / month', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Billed monthly. Renews automatically until you cancel.',
            style: quiet,
          ),
        ],
        if (loading || offer != null) ...[
          const SizedBox(height: AppSpacing.m),
          ThirtyButton(
            label: 'Become Premium',
            size: ThirtyButtonSize.hero,
            isLoading: isPurchasing,
            // No purchase before the store has returned a real price.
            onPressed: offer == null || isPurchasing ? null : onPurchase,
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        TextButton(
          onPressed: isPurchasing ? null : onNotNow,
          style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
          child: const Text('Not now'),
        ),
        Text('Free stays complete.', style: quiet, textAlign: TextAlign.center),
      ],
    );
  }
}

/// Active subscriber: status and management — no price, no acquisition.
class _ActiveBlock extends StatelessWidget {
  const _ActiveBlock({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Premium is active',
          style: textTheme.bodyLarge?.copyWith(color: colors.primary),
        ),
        const SizedBox(height: AppSpacing.s),
        const ManageSubscription(),
        const SizedBox(height: AppSpacing.xs),
        TextButton(
          onPressed: onDone,
          style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

/// Checking / unavailable: a truthful status line, no purchase.
class _StatusNote extends StatelessWidget {
  const _StatusNote({required this.label, this.description});

  final String label;
  final String? description;

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
            Text(label, style: textTheme.bodyLarge),
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
