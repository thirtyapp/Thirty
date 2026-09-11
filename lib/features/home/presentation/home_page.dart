import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../plans/presentation/widgets/plan_session_panel.dart';
import '../../premium/presentation/widgets/premium_offer_invitation_card.dart';
import '../../reminder/presentation/widgets/reminder_invitation_card.dart';
import '../application/recommendation_provider.dart';
import 'widgets/action_report_prompt.dart';
import 'widgets/circle_hero.dart';
import 'widgets/circle_ready_prompt.dart';

/// THIRTY's product entry screen.
///
/// Shows the Circle-first Ready state ([CircleReadyPrompt] — Golden Home
/// Batch) whenever today's recommendation doesn't exist yet
/// (`RecommendationState.recommendation == null` — Recommendation MVP v0,
/// `docs/product/recommendation-mvp-v0.md`): a closed Circle and
/// `Begin today's Circle`, which reveals the existing Daily Context
/// Question (`daily_intention_prompt.dart`) inline once tapped. Once a
/// direction is chosen and an activity assigned, this gives way to the
/// Circle Hero — the first true emotional experience of the product
/// (Playbook Ch.1 §3 — "The Circle is not the app icon... it is the thing
/// THIRTY is") — including its own unchanged First Breath ritual.
///
/// Once today's Circle is closed, [ActionReportPrompt] (ADR-013 §4) renders
/// beneath [CircleHero] — a separate widget, deliberately not folded into
/// `circle_hero.dart` itself, so this batch's functional addition stays
/// independent of that file's own in-progress visual work (see ADR-013
/// §10). [PlanSessionPanel] (Batch 2A) renders below that, and only when
/// today's Circle is Plan-resolved. Below that, at most one of
/// `ReminderInvitationCard` or `PremiumOfferInvitationCard` ever renders
/// — each is internally gated on the other (and both on
/// `ActionReportPrompt`'s own pending state) to enforce the parent V1
/// prompt-priority order: reflection, then reminder invitation, then
/// Premium invitation, never stacked (Step 5 local closure).
///
/// **Founder IA correction:** the AppBar's former history/Plans/Settings
/// shortcut icons are gone — all three destinations they pointed at
/// (Journal's history now inside Insights' calendar, Plans, and "You")
/// are primary bottom-nav destinations of `../../../core/routing/app_shell.dart`,
/// always one tap away regardless of which screen is showing; retaining
/// a duplicate AppBar shortcut here would just be a second, redundant
/// path to the same place. Today's own widget tree is otherwise
/// unchanged by this correction.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasRecommendation =
        ref.watch(recommendationProvider).recommendation != null;

    return Scaffold(
      appBar: AppBar(title: const Text('THIRTY')),
      body: SafeArea(
        child: hasRecommendation
            ? const Column(
                children: [
                  Expanded(child: CircleHero()),
                  ActionReportPrompt(),
                  PlanSessionPanel(),
                  ReminderInvitationCard(),
                  PremiumOfferInvitationCard(),
                ],
              )
            : const CircleReadyPrompt(),
      ),
    );
  }
}
