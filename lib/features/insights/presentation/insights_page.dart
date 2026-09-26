import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/premium/premium_access.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_app_bar.dart';
import '../../../core/widgets/thirty_button.dart';
import '../../../core/widgets/thirty_card.dart';
import '../application/insight_provider.dart';
import '../domain/insight_engine.dart'
    show insightMinDistinctDates, insightMinRecordCount, insightMinSpanDays;
import 'widgets/circle_history_calendar.dart';
import 'widgets/insight_card.dart';

/// THIRTY's Insights destination — founder IA correction ("Today | Plans
/// | Insights | You" supersedes the previous "...| Journal") on top of
/// the Batch B navigation shell
/// (`THIRTY_STEP1_FINAL_IA_AND_IMPLEMENTATION_CONTRACT_2026-09-09.md`
/// §2/§6.B).
///
/// Two clearly separated responsibilities, top to bottom:
///
/// 1. **Shared personal history — FREE, entitlement-independent.**
///    [CircleHistoryCalendar] presents the existing local Circle journal
///    as a calm calendar — this is what replaced the retired primary
///    Journal tab; the underlying `/history` route and its data still
///    exist (see `../../home/presentation/circle_history_page.dart`),
///    just no longer as a bottom-nav destination.
/// 2. **Insight interpretation/application — PREMIUM**, unchanged from
///    before: [InsightCard], moved here verbatim from
///    `../../plans/presentation/plan_path_page.dart` in Batch B, not
///    duplicated. Its own entitlement branching (Batch A: retained
///    observation/evidence stay readable; only the "Apply" action gates
///    on [premiumEntitlementProvider]) is unaffected by this page's
///    layout change.
///
/// Phase C4: the second section, under its own "Insights" heading, shows
/// exactly one of — the [InsightCard] (current or earlier); the
/// "Applied. Your Plan is updated." confirmation once this page applied
/// one; for Premium, a plain "nothing to show yet" line naming the
/// pattern thresholds, with no CTA; for Free, one compact THIRTY Premium
/// card. None of them invents a new Insight family, engine, or fabricated
/// data; all are presentation-only, same as the calendar above them.
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

  /// Set once this page's Insight application was actually made: the
  /// applied Insight withdraws (it no longer describes an open next step),
  /// and this confirmation takes its place instead of the empty state —
  /// until a new Insight is shown. Presentation only, never persisted.
  bool _justApplied = false;

  @override
  Widget build(BuildContext context) {
    // The current Insight, or a dated earlier one whose evidence aged out.
    final hasDisplayedInsight = ref.watch(displayedInsightProvider) != null;
    final isEntitled = ref.watch(premiumEntitlementProvider);

    final Widget insights;
    if (hasDisplayedInsight) {
      insights = InsightCard(
        onApplied: () => setState(() => _justApplied = true),
      );
    } else if (_justApplied) {
      insights = const _AppliedConfirmation();
    } else if (isEntitled) {
      insights = const _NothingToShowYet();
    } else {
      insights = const _InsightsPremiumCard();
    }

    // No Settings icon here — founder IA correction: once "You" is a
    // persistent primary destination, every branch's own Settings
    // shortcut becomes a redundant entry point (see `app_shell.dart`).
    return Scaffold(
      appBar: const ThirtyAppBar(title: Text('Insights')),
      body: SafeArea(
        // Horizontal page insets are applied per section: the calendar sets
        // its own (it may narrow them to keep 48pt day targets), everything
        // else keeps the page's 24pt.
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionHeading('Your history'),
              const SizedBox(height: AppSpacing.s),
              const CircleHistoryCalendar(),
              // Phase C4: two sections separated by the section rhythm and
              // their own headings — no divider.
              const SizedBox(height: AppSpacing.section),
              const _SectionHeading('Insights'),
              const SizedBox(height: AppSpacing.m),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: insights,
              ),
            ],
          ),
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

/// Premium, nothing to show: the truthful reason, no sales CTA. Names the
/// thresholds only for *pattern* Insights — a current-place Insight needs
/// no count.
class _NothingToShowYet extends StatelessWidget {
  const _NothingToShowYet();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Text(
      'Nothing to show yet. Pattern Insights need at least '
      '$insightMinRecordCount relevant Circle records across '
      '$insightMinDistinctDates different days, spanning at least '
      '$insightMinSpanDays days.',
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
    );
  }
}

/// Free, no Insight: the compact Premium card in the Plans/You language
/// (Phase C3's in-list card) — below the user's own, free History.
class _InsightsPremiumCard extends StatelessWidget {
  const _InsightsPremiumCard();

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
