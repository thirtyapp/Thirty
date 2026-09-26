import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../plans/presentation/widgets/plan_session_panel.dart';
import '../../premium/presentation/widgets/premium_offer_invitation_card.dart';
import '../../reminder/presentation/widgets/reminder_invitation_card.dart';
import '../application/first_breath_provider.dart';
import '../application/recommendation_provider.dart';
import 'widgets/action_report_prompt.dart';
import 'widgets/circle_hero.dart';
import 'widgets/circle_ready_prompt.dart';
import 'widgets/home_header.dart';
import 'widgets/later_today_label.dart';

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
/// `circle_hero.dart` itself (see ADR-013 §10); since Phase B3 it is passed
/// in as part of CircleHero's `footer`, so it scrolls with the hero as one
/// document rather than taking height from it. Since Phase D1,
/// [PlanSessionPanel] (Batch 2A, only when today's Circle is
/// Plan-resolved) comes first, then a "LATER TODAY" label heading the
/// reflection and, below it, at most one of
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

  /// Tall enough for the fixed-size brand lockup (wordmark + two-line
  /// tagline) and the 48pt profile button.
  static const _headerHeight = 72.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasRecommendation =
        ref.watch(recommendationProvider).recommendation != null;
    // Phase B1 — the header wordmark never duplicates the in-Circle one.
    // It stays hidden in Ready (the Circle holds the wordmark) and
    // throughout The First Breath (whose own wordmark beat plays inside the
    // Circle), and appears only once the ritual has settled into the
    // assigned Home state. `firstBreathProvider` turns false exactly then
    // — on the ritual's completion, or at once when it was already played
    // today or skipped for reduced motion — so this reads the ritual's
    // outcome without touching its timeline.
    final showHeaderWordmark =
        hasRecommendation && !ref.watch(firstBreathProvider);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: _headerHeight,
        titleSpacing: AppSpacing.page,
        // Always laid out, only faded: the AppBar's height and the Circle's
        // position never change when the lockup appears.
        title: AnimatedOpacity(
          opacity: showHeaderWordmark ? 1 : 0,
          duration: reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          child: const HomeBrandLockup(),
        ),
        // Phase D1 — a round shortcut to You, visible in every Home state.
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.page),
            child: HomeProfileButton(),
          ),
        ],
      ),
      body: SafeArea(
        // Phase B3 — one vertical scroll owner per state: CircleHero's own
        // scroll view carries the hero *and* every card below it, so a card
        // extends the page instead of shrinking the hero. Ready has no
        // below-hero cards and keeps its own scroll. Swapping Ready for
        // CircleHero mounts a fresh scroll view, so The First Breath always
        // starts with the Circle at its normal position.
        child: hasRecommendation
            ? const CircleHero(
                // Phase D1: today's Plan guidance first, then the
                // follow-ups under "LATER TODAY" (reflection, then the
                // reminder or Premium invitation — priority unchanged).
                footer: [
                  PlanSessionPanel(),
                  LaterTodayLabel(),
                  ActionReportPrompt(),
                  ReminderInvitationCard(),
                  PremiumOfferInvitationCard(),
                ],
              )
            : const CircleReadyPrompt(),
      ),
    );
  }
}
