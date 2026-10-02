import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/branding/thirty_wordmark_view.dart';
import '../../../core/premium/premium_access.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_button.dart';
import '../../../core/widgets/thirty_card.dart';
import '../../home/application/circle_journal.dart';
import '../../home/presentation/widgets/home_header.dart'
    show HomeProfileButton;
import '../application/insight_provider.dart';
import '../domain/insight_engine.dart'
    show
        insightHistoryGateMet,
        insightMinDistinctDates,
        insightMinRecordCount,
        insightMinSpanDays;
import 'widgets/circle_history_calendar.dart';
import 'widgets/insight_card.dart';
import 'widgets/insights_header_art.dart';

/// THIRTY's Insights destination — founder IA correction ("Today | Plans
/// | Insights | You" supersedes the previous "...| Journal") on top of
/// the Batch B navigation shell
/// (`THIRTY_STEP1_FINAL_IA_AND_IMPLEMENTATION_CONTRACT_2026-09-09.md`
/// §2/§6.B), converged on the Visual North Star (founder decisions,
/// 2026-10-02).
///
/// A scrolling page in the frozen Plans header language: the THIRTY
/// wordmark and the You button, "Your Insights" in the editorial serif, one
/// supporting line, the dedicated header artwork ([insightsHeaderArt]),
/// then two clearly separated responsibilities:
///
/// 1. **Insight interpretation/application — PREMIUM.** Exactly one of —
///    the [InsightCard] (current or earlier); the "Applied. Your Plan is
///    updated." confirmation once this page applied one; for Premium, a
///    quiet truthful line (the pattern thresholds while there is not yet
///    enough recorded history, otherwise "nothing new right now"); for
///    Free, one calm THIRTY Premium explainer. Its own entitlement
///    branching (Batch A: retained observation/evidence stay readable;
///    only the application gates on [premiumEntitlementProvider]) is
///    unchanged.
/// 2. **Shared personal history — FREE, entitlement-independent.**
///    [CircleHistoryCalendar] under "Your history", presenting the existing
///    local Circle journal — what replaced the retired primary Journal tab.
///
/// None of them invents a new Insight family, engine, or fabricated data.
class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  static const title = 'Your Insights';
  static const subtitle = 'Drawn from your own recorded Circles.';

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  /// Whether this tab is the one on screen: go_router's indexed stack keeps
  /// every visited branch alive and disables [TickerMode] for the inactive
  /// ones.
  bool _visible = false;

  /// Set once this page's Insight application was actually made: the
  /// applied Insight withdraws (it no longer describes an open next step),
  /// and this confirmation takes its place instead of the empty state —
  /// until a new Insight is shown. Presentation only, never persisted.
  bool _justApplied = false;

  /// Batch 2C: "assess a new current Insight at most once per seven-day
  /// interval when the user opens the relevant surface." The surface stays
  /// alive in the indexed stack, so opening it is not only the first build:
  /// it is also coming back to the tab, coming back to the app (which
  /// renews [nowProvider]), and Premium becoming verified while the tab is
  /// open. Each of those asks [InsightNotifier.refreshIfDue], whose own
  /// cadence and entitlement guards keep it a no-op unless an assessment is
  /// actually due — so nothing is recomputed more often than before.
  /// Scheduled after the frame, never during build, since it may write
  /// persisted state.
  void _refreshIfDue() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_visible) return;
      ref.read(insightProvider.notifier).refreshIfDue();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    final becameVisible = visible && !_visible;
    _visible = visible;
    if (becameVisible) _refreshIfDue();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DateTime>(nowProvider, (_, _) => _refreshIfDue());
    ref.listen<bool>(premiumEntitlementProvider, (previous, entitled) {
      if (entitled && previous != true) _refreshIfDue();
    });

    // The current Insight, or a dated earlier one whose evidence aged out.
    final hasDisplayedInsight = ref.watch(displayedInsightProvider) != null;
    final isEntitled = ref.watch(premiumEntitlementProvider);
    final now = ref.watch(nowProvider);
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final Widget insights;
    if (hasDisplayedInsight) {
      insights = InsightCard(
        onApplied: () => setState(() => _justApplied = true),
      );
    } else if (_justApplied) {
      insights = const _AppliedConfirmation();
    } else if (isEntitled) {
      final journal = ref.watch(circleJournalRepositoryProvider).readAll();
      insights = insightHistoryGateMet(journal, now)
          ? const _NothingNewRightNow()
          : const _NotEnoughHistoryYet();
    } else {
      insights = const _InsightsPremiumCard();
    }

    // No pinned Material AppBar: the header scrolls with the page, as on
    // Plans and Home. No Settings icon — the You button is the shortcut.
    return Scaffold(
      body: SafeArea(
        // Horizontal page insets are applied per section: the calendar and
        // the full-width band set their own, everything else keeps the
        // page's 24pt.
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _InsightsTopBar(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        InsightsPage.title,
                        style: AppTypography.editorialDisplay(
                          colors,
                        ).copyWith(fontSize: 34, height: 1.05),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      InsightsPage.subtitle,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              InsightsHeaderArt(art: insightsHeaderArt, now: now),
              const SizedBox(height: AppSpacing.l),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: insights,
              ),
              const SizedBox(height: AppSpacing.section),
              const _SectionHeading('Your history'),
              const SizedBox(height: AppSpacing.s),
              const CircleHistoryCalendar(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The THIRTY wordmark and the You button — the same row as Plans'
/// (`../../plans/presentation/plan_path_page.dart`), kept as Insights' own
/// copy so this page never changes Plans.
class _InsightsTopBar extends StatelessWidget {
  const _InsightsTopBar();

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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

/// The already-approved confirmation after an Insight's application.
class _AppliedConfirmation extends StatelessWidget {
  const _AppliedConfirmation();

  @override
  Widget build(BuildContext context) {
    return ThirtyCard(
      padding: const EdgeInsets.all(AppSpacing.featuredCard),
      child: Semantics(
        liveRegion: true,
        child: Text(
          'Applied. Your Plan is updated.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

/// A quiet, non-personal Insights card: the neutral THIRTY badge beside
/// plain lines, no action. For the Premium "no Insight" states.
class _QuietInsightsCard extends StatelessWidget {
  const _QuietInsightsCard({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary);
    return ThirtyCard(
      padding: const EdgeInsets.all(AppSpacing.featuredCard),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InsightsNeutralBadge(size: 40),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.xs),
                  Text(lines[i], style: style),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium, not yet enough recorded history for any pattern: the truthful
/// reason, naming the thresholds, no sales CTA. A current-place Insight
/// needs no count, so the thresholds are named for *pattern* Insights only.
class _NotEnoughHistoryYet extends StatelessWidget {
  const _NotEnoughHistoryYet();

  @override
  Widget build(BuildContext context) {
    return const _QuietInsightsCard(
      lines: [
        'Nothing to show yet. Pattern Insights need at least '
            '$insightMinRecordCount relevant Circle records across '
            '$insightMinDistinctDates different days, spanning at least '
            '$insightMinSpanDays days.',
      ],
    );
  }
}

/// Premium, enough recorded history but no Insight to show right now (none
/// eligible, already applied, or dismissed): never the thresholds, which
/// would wrongly suggest the history is missing.
class _NothingNewRightNow extends StatelessWidget {
  const _NothingNewRightNow();

  @override
  Widget build(BuildContext context) {
    return const _QuietInsightsCard(
      lines: [
        'Nothing new to surface right now.',
        'Your history is still here when you want to look back.',
      ],
    );
  }
}

/// Free, no Insight: one calm THIRTY Premium explainer in the Insight card
/// language — the neutral badge, never a Plan identity, and no sample or
/// blurred Insight.
class _InsightsPremiumCard extends StatelessWidget {
  const _InsightsPremiumCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
    return ThirtyCard(
      padding: const EdgeInsets.all(AppSpacing.featuredCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InsightsNeutralBadge(size: largeText ? 40 : 44),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Text(
                  'THIRTY Premium',
                  style: AppTypography.editorialDisplay(
                    colors,
                  ).copyWith(fontSize: 21),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Premium can turn patterns in your recorded Circles into one '
            'clear next step for your Plan.',
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
