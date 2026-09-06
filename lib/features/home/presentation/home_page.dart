import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/premium/premium_access.dart';
import '../../plans/presentation/widgets/plan_session_panel.dart';
import '../application/recommendation_provider.dart';
import 'widgets/action_report_prompt.dart';
import 'widgets/circle_hero.dart';
import 'widgets/daily_intention_prompt.dart';

/// THIRTY's product entry screen.
///
/// Shows the Daily Context Question ([DailyIntentionPrompt]) whenever
/// today's recommendation doesn't exist yet
/// (`RecommendationState.recommendation == null` — Recommendation MVP v0,
/// `docs/product/recommendation-mvp-v0.md`), and the Circle Hero — the first
/// true emotional experience of the product (Playbook Ch.1 §3 — "The Circle
/// is not the app icon... it is the thing THIRTY is") — once it does.
///
/// Once today's Circle is closed, [ActionReportPrompt] (ADR-013 §4) renders
/// beneath [CircleHero] — a separate widget, deliberately not folded into
/// `circle_hero.dart` itself, so this batch's functional addition stays
/// independent of that file's own in-progress visual work (see ADR-013
/// §10). [PlanSessionPanel] (Batch 2A) renders below that, and only when
/// today's Circle is Plan-resolved.
///
/// The AppBar's history icon opens [CircleHistoryPage] (ADR-013 §6) — the
/// one entry point into the user's own recorded Circle history, reachable
/// from every state this page can be in. A second AppBar icon opens
/// [PlanPathPage] (Batch 2A), but only when [premiumEntitlementProvider] is
/// `true` — see `../../../core/premium/premium_access.dart`'s own doc
/// comment for why this is the chosen pre-billing access seam.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasRecommendation =
        ref.watch(recommendationProvider).recommendation != null;
    final isEntitled = ref.watch(premiumEntitlementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('THIRTY'),
        actions: [
          if (isEntitled)
            IconButton(
              icon: const Icon(Icons.route_outlined),
              tooltip: 'Your path',
              onPressed: () => context.push('/plans'),
            ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Your Circle history',
            onPressed: () => context.push('/history'),
          ),
        ],
      ),
      body: SafeArea(
        child: hasRecommendation
            ? const Column(
                children: [
                  Expanded(child: CircleHero()),
                  ActionReportPrompt(),
                  PlanSessionPanel(),
                ],
              )
            : const DailyIntentionPrompt(),
      ),
    );
  }
}
