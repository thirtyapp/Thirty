import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/premium/premium_access.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_button.dart';
import '../application/insight_provider.dart';
import 'widgets/insight_card.dart';

/// THIRTY's Insights destination — Batch B navigation shell
/// (`THIRTY_STEP1_FINAL_IA_AND_IMPLEMENTATION_CONTRACT_2026-09-09.md`
/// §2/§6.B).
///
/// Hosts [InsightCard] — moved here verbatim from
/// `../../plans/presentation/plan_path_page.dart`, not duplicated. Its own
/// entitlement branching (Batch A: retained observation/evidence stay
/// readable; only the "Apply" action gates on [premiumEntitlementProvider])
/// is unchanged by this move.
///
/// [InsightCard] itself renders nothing when [currentInsightProvider] is
/// `null` — correct when it was one card among several on "Your path", but
/// this destination cannot be a blank screen. [build] fills that gap with
/// the minimal truthful text the contract's §4 Insights row already
/// specifies: a calm explanatory preview + `/premium` CTA when unentitled
/// (no snapshot has ever existed, or none does yet), or — when entitled —
/// a plain "not enough evidence yet" line, with no CTA, since there is
/// nothing to unlock. Neither branch invents a new Insight family, engine,
/// or fabricated data; both are presentation-only.
class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  @override
  void initState() {
    super.initState();
    // Batch 2C: "assess a new current Insight at most once per seven-day
    // interval when the user opens the relevant surface" — moved here from
    // `plan_path_page.dart`'s `initState` along with `InsightCard` itself,
    // since Insights is now that surface. Scheduled after the first frame,
    // never during build, since it may write persisted state
    // (`InsightNotifier.refreshIfDue`). A no-op unless the cadence interval
    // has elapsed, and unless `premiumEntitlementProvider` is true (Batch A
    // — computing a new observation is new paid interpretation).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(insightProvider.notifier).refreshIfDue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasCurrentInsight = ref.watch(currentInsightProvider) != null;
    final isEntitled = ref.watch(premiumEntitlementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: hasCurrentInsight
              ? const InsightCard()
              : _InsightsEmptyState(isEntitled: isEntitled),
        ),
      ),
    );
  }
}

class _InsightsEmptyState extends StatelessWidget {
  const _InsightsEmptyState({required this.isEntitled});

  final bool isEntitled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isEntitled
              ? 'Nothing to show yet. Insights turns your recorded choices '
                    'into guidance once a clear pattern exists.'
              : 'Insights turns your recorded choices into guidance.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
        if (!isEntitled) ...[
          const SizedBox(height: AppSpacing.m),
          ThirtyButton(
            label: 'Open Premium',
            onPressed: () => context.push('/premium'),
          ),
        ],
      ],
    );
  }
}
