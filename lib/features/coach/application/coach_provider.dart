import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_provider.dart';
import '../../home/application/circle_journal.dart';
import '../../home/application/recommendation_provider.dart';
import '../../plans/application/plan_provider.dart';
import '../../plans/domain/plan_catalog.dart';
import '../../plans/domain/plan_ids.dart';
import '../domain/coach_cue.dart';
import '../domain/coach_engine.dart';

/// Resolves the single relevant [CoachCue] for [planId] right now, or
/// `null` — Batch 2B (`docs/product/adr/ADR-015-v1-batch-2b-circle-coach.md`).
///
/// Only ever produces a cue for the currently **active** Plan
/// (`PlanNotifier.state.activePlanId`) — Coach speaks about the current
/// path, never about a Plan the user isn't currently working. Gathers only
/// explicit local state: today's Plan-resolved `Recommendation` (if any),
/// the immediately preceding matching Plan journal entry's truthful
/// attempt/usefulness report, and its local date for the resumption gap —
/// never mood, wearables, or any inferred signal (§7's explicit-context
/// boundary).
///
/// A pure re-derivation on every read — no side effects, no analytics.
/// Analytics for a shown cue are fired from the presentation layer
/// (`../presentation/widgets/coach_cue_banner.dart`), exactly once per
/// distinct family transition, so this provider can be watched freely
/// without risking duplicate "shown" events.
final coachCueProvider = Provider.family<CoachCue?, PlanId>((ref, planId) {
  final plansState = ref.watch(planProvider);
  if (plansState.activePlanId != planId) return null;
  final progress = plansState.progress[planId];
  if (progress == null) return null;
  final plan = planDefinitionFor(planId);

  final recommendation = ref.watch(recommendationProvider).recommendation;
  final todayIsThisPlan = recommendation?.planId == planId;
  final todayStageId = todayIsThisPlan ? recommendation!.stageId : null;
  final todayTreatment = todayIsThisPlan ? recommendation!.treatmentUsed : null;
  final todayTreatmentSource = todayIsThisPlan
      ? recommendation!.treatmentSource
      : null;
  final todayIsRevisit = todayIsThisPlan && recommendation!.isPlanRevisit;
  final todayCircleId = recommendation?.circleId;

  // The most recent *prior* (never today's own) matching Plan journal
  // entry — its truthful attempt/usefulness report and local date are the
  // only "recent feedback"/"last encounter" evidence Coach ever uses.
  final journal = ref.watch(circleJournalRepositoryProvider);
  final priorEntries =
      journal
          .readAll()
          .where(
            (entry) =>
                entry.planId == planId.name && entry.circleId != todayCircleId,
          )
          .toList()
        ..sort((a, b) => a.localDate.compareTo(b.localDate));
  final lastPrior = priorEntries.isEmpty ? null : priorEntries.last;
  final lastEncounterAt = lastPrior == null
      ? null
      : DateTime.tryParse(lastPrior.localDate);

  final now = ref.watch(nowProvider);

  return selectCoachCue(
    plan: plan,
    progress: progress,
    todayStageId: todayStageId,
    todayTreatment: todayTreatment,
    todayTreatmentSource: todayTreatmentSource,
    todayIsRevisit: todayIsRevisit,
    lastAttempt: lastPrior?.attemptResponse,
    lastUsefulness: lastPrior?.usefulnessResponse,
    lastEncounterAt: lastEncounterAt,
    now: now,
  );
});
