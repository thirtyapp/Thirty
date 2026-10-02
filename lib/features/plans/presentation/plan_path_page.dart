import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/branding/thirty_wordmark_view.dart';
import '../../../core/premium/premium_access.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_button.dart';
import '../../../core/widgets/thirty_card.dart';
import '../../home/presentation/widgets/home_header.dart'
    show HomeProfileButton;
import '../application/plan_provider.dart';
import '../domain/plan_ids.dart';
import 'widgets/plan_card.dart';
import 'widgets/plan_identity.dart';
import 'widgets/plans_header_art.dart';

/// THIRTY's Plans destination — Batch 2A
/// (`docs/product/adr/ADR-014-v1-batch-2a-circle-plans.md`), converged on
/// the Visual North Star and the approved Home (founder decisions,
/// 2026-10-01).
///
/// A scrolling page in Home's language: the THIRTY wordmark and the You
/// button, "Your Plans" in the editorial serif, one supporting line, the
/// dedicated header artwork across the full width ([plansHeaderArt]), then the
/// three Plans as [PlanCard]s. Each card opens that Plan's Your Path
/// (`/plans/:planId`, `plan_detail_page.dart`), where every Plan action
/// lives. This is Plan *management*, never an activity browser.
///
/// **Reachable regardless of entitlement** — `/plans` is a branch root of
/// the primary navigation shell. Names, purposes and position are not paid
/// content, so the list is the same for everyone; Free users also see one
/// calm [_PremiumCard] after the Plans (Phase C3). Paid stage content and
/// controls are protected on Your Path itself and in `PlanNotifier`
/// (frozen architecture §38.5) — never by a redirect or a paywall on open.
class PlanPathPage extends ConsumerWidget {
  const PlanPathPage({super.key});

  static const title = 'Your Plans';
  static const subtitle = 'Three paths. Small steps. A brighter you.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansState = ref.watch(planProvider);
    final isEntitled = ref.watch(premiumEntitlementProvider);
    final now = ref.watch(nowProvider);
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.l),
          children: [
            const _PlansTopBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                0,
              ),
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
            PlansHeaderArt(art: plansHeaderArt, now: now),
            const SizedBox(height: AppSpacing.l),
            for (final planId in PlanId.values) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: PlanCard(
                  planId: planId,
                  progress: plansState.progress[planId]!,
                  // A Plan only runs while entitled; a lapsed active Plan is not
                  // presented as active (no Session resolves for it).
                  isActive: isEntitled && plansState.activePlanId == planId,
                  cardAsset: PlanIdentity.of(planId).cardAssetAt(planId, now),
                  onTap: () => context.go('/plans/${planId.name}'),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
            ],
            if (!isEntitled)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: _PremiumCard(),
              ),
          ],
        ),
      ),
    );
  }
}

/// The THIRTY wordmark and the You button — the wordmark alone, since the
/// tagline belongs to Home's lockup. Shorter than Home's header so the
/// title, subtitle and band sit high, as in the Visual North Star.
class _PlansTopBar extends StatelessWidget {
  const _PlansTopBar();

  static const height = 56.0;
  static const wordmarkWidth = 96.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        child: Row(
          children: [
            Semantics(
              label: 'THIRTY',
              child: const ExcludeSemantics(
                child: SizedBox(
                  width: wordmarkWidth,
                  child: ThirtyWordmarkView(),
                ),
              ),
            ),
            const Spacer(),
            const HomeProfileButton(),
          ],
        ),
      ),
    );
  }
}

/// The Free upsell, after the three Plans (Phase C3) — You's Premium-card
/// language, compact.
class _PremiumCard extends StatelessWidget {
  const _PremiumCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    return ThirtyCard(
      padding: const EdgeInsets.all(AppSpacing.featuredCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THIRTY Premium', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Guided Plans are part of THIRTY Premium.',
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.m),
          SizedBox(
            width: double.infinity,
            child: ThirtyButton(
              label: 'Become Premium',
              onPressed: () => context.push('/premium'),
            ),
          ),
        ],
      ),
    );
  }
}
