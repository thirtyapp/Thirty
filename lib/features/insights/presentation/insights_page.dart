import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/branding/thirty_wordmark_view.dart';
import '../../../core/premium/premium_access.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/thirty_text_action.dart';
import '../../home/application/circle_journal.dart';
import '../../home/application/suggestion_preferences.dart';
import '../../personal_circle/application/kept_circles_provider.dart';
import '../../personal_circle/domain/circle_elements.dart';
import '../../personal_circle/presentation/keep_circle_card.dart';
import '../../personal_circle/presentation/widgets/yours_parts.dart';
import '../../plans/application/circle_plans_provider.dart';
import '../../plans/domain/circle_plan.dart';
import '../../plans/domain/plan_copy.dart';
import '../../plans/presentation/plan_actions.dart';
import '../../settings/presentation/widgets/you_header_art.dart';
import '../application/insights_provider.dart';
import '../domain/insight.dart';
import '../domain/insight_copy.dart';
import '../domain/insight_engine.dart';
import 'widgets/circle_history_calendar.dart';
import 'widgets/insight_card.dart';

/// The approved Insights header band (founder, 2026-10-02), by time of day.
const insightsHeaderArt = YouHeaderArtSet(
  morning: YouHeaderArtImage(
    'assets/insights/insights_header_morning_v1.webp',
    width: 2020,
    height: 258,
  ),
  day: YouHeaderArtImage(
    'assets/insights/insights_header_day_v1.webp',
    width: 2020,
    height: 254,
  ),
  evening: YouHeaderArtImage(
    'assets/insights/insights_header_evening_v1.webp',
    width: 2020,
    height: 253,
  ),
);

/// How many earlier records show before "Show all".
const earlierShown = 4;

/// Insights (ADR-024 §11–§12, B6): "What does my actual use show, and is
/// there one useful change I can approve?"
///
/// Three calm parts, not equally loud: **Now** — at most one current
/// Insight (Premium), or one plain line about where things stand; **Your
/// Circles** — the calendar, everyone's own; **Earlier** — what THIRTY
/// showed before, as dated rows. Everything shown is B5's: the page only
/// reads the Insights service, asks it to assess once when opened, and
/// passes the user's choices to it. Nothing here decides what qualifies.
class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  static const location = '/insights';

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  var _showAllEarlier = false;

  /// The Insight applied on this visit, and what applying it did — shown
  /// once, in place of its action.
  String? _appliedId;
  String? _outcome;

  /// Whether the page was on screen at the last dependency change.
  var _onScreen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pull-based (§11): opening Insights is the only time THIRTY assesses.
    // As a tab the page outlives each visit, so it assesses whenever it
    // comes on screen — the tab chosen, or a page over it closed (the shell
    // and the Navigator turn an unseen page's tickers off). Without Premium
    // the service generates nothing.
    final onScreen = TickerMode.valuesOf(context).enabled;
    if (onScreen && !_onScreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(insightsProvider.notifier).assess();
      });
    }
    _onScreen = onScreen;
  }

  String? _actionLabel(InsightApplication application) => switch (application) {
    PlanDirection(:final planId, :final step) => InsightCopy.planStep(
      step,
      circlePlanById[planId]!.name,
    ),
    KeepGentler() => InsightCopy.keepGentler,
    LeaveOutPart() => InsightCopy.leaveOut,
    KeepCircleFromHistory() => InsightCopy.keepCircle,
    OpenPlanReview() => InsightCopy.reviewThisPlan,
    NothingToChange() => null,
  };

  void _apply(InsightSnapshot snapshot) {
    final result = ref.read(insightsProvider.notifier).apply(snapshot.id);
    final said = switch (result) {
      InsightActionResult.done => switch (snapshot.application) {
        PlanDirection(:final planId) => InsightCopy.nowYourPlan(
          circlePlanById[planId]!.name,
        ),
        KeepGentler() => InsightCopy.gentlerOn,
        LeaveOutPart(:final element) => InsightCopy.leftOut(
          elementOf(ElementId.values.byName(element)).name,
        ),
        KeepCircleFromHistory(:final circleId) => KeepCircleCopy.kept(
          ref
              .read(keptCirclesProvider)
              .kept
              .lastWhere((k) => k.fromCircleId == circleId)
              .name,
        ),
        _ => null,
      },
      InsightActionResult.alreadyApplied => InsightCopy.alreadyInPlace,
      InsightActionResult.keptLimitReached => KeepCircleCopy.full,
      InsightActionResult.needsPremium => null,
      InsightActionResult.notAvailable => null,
      InsightActionResult.nothingToApply => null,
    };
    if (result == InsightActionResult.needsPremium) {
      context.push('/premium');
      return;
    }
    setState(() {
      _appliedId = said == null ? null : snapshot.id;
      _outcome = said;
    });
  }

  /// The canonical review in Plans: the Plan's page — for an earlier
  /// cycle, with that cycle's review.
  void _openReview(InsightSnapshot snapshot) {
    final review = snapshot.application;
    if (review is! OpenPlanReview) return;
    final current = ref.read(circlePlansProvider).plans[review.planId]?.current;
    final location = planLocation(review.planId);
    context.push(
      current?.id == review.cycleId
          ? location
          : '$location?cycle=${Uri.encodeComponent(review.cycleId)}',
    );
  }

  /// The day an earlier Insight speaks of: a Plan review, the day its
  /// cycle ended; any other, the day THIRTY showed it.
  static String _shownOn(InsightSnapshot snapshot) =>
      switch (snapshot.facts['endedOn']) {
        final String ended when snapshot.family == InsightFamily.planReview =>
          ended,
        _ => snapshot.generatedOn,
      };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final now = ref.watch(nowProvider);
    final premium = ref.watch(premiumEntitlementProvider);
    final state = ref.watch(insightsProvider);
    final journal = ref.watch(circleJournalRepositoryProvider).readAll();
    final plans = ref.watch(circlePlansProvider);
    ref.watch(suggestionPreferencesProvider);
    ref.watch(keptCirclesProvider);

    final inputs = ref.read(insightsProvider.notifier).inputs();
    final assessment = assessInsights(inputs, state.snapshots, generate: false);
    final snapshots = assessment.snapshots;
    InsightStatus status(InsightSnapshot s) => statusOf(s, inputs);

    // Now: the current Insight, or the one just applied on this visit.
    final applied = _appliedId == null ? null : state.byId(_appliedId!);
    final current =
        applied ?? (premium ? currentInsight(snapshots, inputs) : null);
    // The newest Plan review whose cycle ended within the last 28 days.
    final todayKey = dayOf(now, 1);
    final reviews = [
      for (final s in snapshots.reversed)
        if (s.family == InsightFamily.planReview &&
            status(s) == InsightStatus.current)
          s,
    ];
    final recentReview = reviews.where((s) {
      final ended = s.facts['endedOn'];
      return ended is String && daysBetween(ended, todayKey) < 28;
    }).firstOrNull;
    final earlier = [
      for (final s in snapshots.reversed)
        if (!identical(s, current) && !identical(s, recentReview)) s,
    ];
    final active = plans.active;
    final early =
        assessment.readiness == InsightReadiness.noHistory ||
        assessment.readiness == InsightReadiness.tooShort;
    final lapsed = !premium && (snapshots.isNotEmpty || plans.plans.isNotEmpty);

    final nowParts = <Widget>[
      if (current != null)
        InsightCard(
          snapshot: current,
          actionLabel: _actionLabel(current.application),
          onAction: () => _apply(current),
          onNotNow: current.family.isOrdinary ? () => _notNow(current) : null,
          outcome: identical(current, applied) ? _outcome : null,
          onSeePlan:
              identical(current, applied) &&
                  current.planId != null &&
                  circlePlanById.containsKey(current.planId)
              ? () => context.push(planLocation(current.planId!))
              : null,
        )
      else if (premium)
        YoursNote(switch (assessment.readiness) {
          InsightReadiness.noHistory => InsightCopy.premiumDayOne,
          InsightReadiness.tooShort => InsightCopy.premiumSoFar(
            assessment.circles,
            assessment.answers,
          ),
          _ => InsightCopy.premiumQuiet,
        }),
      if (premium && early && active != null)
        YoursRows(
          rows: [
            YoursRow(
              title: active.definition.name,
              detail: active.current.isOver
                  ? PlanCopy.endedWithoutRecord
                  : PlanCopy.stageHeading(
                      active.current.cursor,
                      active.definition.stage(active.current.cursor).name,
                    ),
              onTap: () => context.push(planLocation(active.planId)),
            ),
          ],
        ),
      if (recentReview != null)
        InsightCard(
          snapshot: recentReview,
          actionLabel: InsightCopy.reviewThisPlan,
          onAction: () => _openReview(recentReview),
          secondary: current != null,
        ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            const _InsightsTopBar(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      InsightCopy.title,
                      style: AppTypography.editorialDisplay(
                        colors,
                      ).copyWith(fontSize: 34, height: 1.05),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    InsightCopy.subtitle,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            YouHeaderArt(art: insightsHeaderArt, now: now),
            const SizedBox(height: AppSpacing.l),
            if (nowParts.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: YoursSection(
                  title: InsightCopy.nowHeading,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, part) in nowParts.indexed) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.m),
                        part,
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.section),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: YoursEyebrow(InsightCopy.circlesHeading),
            ),
            const SizedBox(height: AppSpacing.s),
            // The calendar takes the page's width and sets its own inset.
            Semantics(container: true, child: const CircleHistoryCalendar()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (journal.isEmpty && !premium)
                    const YoursNote(InsightCopy.freeEmpty)
                  else if (journal.isNotEmpty)
                    ThirtyTextAction(
                      label: InsightCopy.seeAsList,
                      onPressed: () => context.push('/history'),
                    ),
                  if (!premium) ...[
                    const SizedBox(height: AppSpacing.l),
                    YoursNote(lapsed ? InsightCopy.lapsed : InsightCopy.free),
                    ThirtyTextAction(
                      label: InsightCopy.seePremium,
                      onPressed: () => context.push('/premium'),
                    ),
                  ],
                  if (earlier.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.section),
                    YoursSection(
                      title: InsightCopy.earlierHeading,
                      child: YoursRows(
                        rows: [
                          for (final s
                              in _showAllEarlier
                                  ? earlier
                                  : earlier.take(earlierShown))
                            YoursRow(
                              title:
                                  '${InsightCopy.dayMonth(_shownOn(s))} · '
                                  '${InsightCopy.familyName(s.family)}',
                              detail: [
                                InsightCopy.keepDatesTogether(s.text),
                                ?switch (status(s)) {
                                  InsightStatus.applied => InsightCopy.applied,
                                  InsightStatus.notNow ||
                                  InsightStatus.declined =>
                                    InsightCopy.setAside,
                                  InsightStatus.stale =>
                                    InsightCopy.noLongerCurrent,
                                  InsightStatus.current => null,
                                },
                              ].join(' '),
                              onTap:
                                  s.family == InsightFamily.planReview &&
                                      status(s) == InsightStatus.current
                                  ? () => _openReview(s)
                                  : null,
                            ),
                        ],
                      ),
                    ),
                    if (earlier.length > earlierShown)
                      ThirtyTextAction(
                        label: _showAllEarlier
                            ? InsightCopy.showFewer
                            : InsightCopy.showAllEarlier(earlier.length),
                        onPressed: () =>
                            setState(() => _showAllEarlier = !_showAllEarlier),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _notNow(InsightSnapshot snapshot) {
    ref.read(insightsProvider.notifier).notNow(snapshot.id);
    setState(() {
      _appliedId = null;
      _outcome = null;
    });
  }
}

class _InsightsTopBar extends StatelessWidget {
  const _InsightsTopBar();

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return SizedBox(
      height: 56,
      child: Padding(
        padding: EdgeInsets.only(
          left: canPop ? AppSpacing.xs : AppSpacing.page,
          right: AppSpacing.page,
        ),
        child: Row(
          children: [
            if (canPop) const BackButton(),
            Semantics(
              label: 'THIRTY',
              child: const ExcludeSemantics(
                child: SizedBox(width: 96, child: ThirtyWordmarkView()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
