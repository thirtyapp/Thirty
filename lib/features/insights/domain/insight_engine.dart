/// THIRTY's minimum Circle Insights evaluation policy — Batch 2C
/// (`docs/product/adr/ADR-016-v1-batch-2c-circle-insights.md`,
/// `RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md` §9).
///
/// [evaluateInsight] is a pure, deterministic function — the same inputs
/// always produce the same [Insight]? — no randomness, no runtime AI, no
/// mutation. It never touches today's already-resolved `Recommendation`
/// and never itself decides an [ActivityId] — it only ever reads the local
/// journal and Plan state to find at most one eligible observation.
library;

import '../../home/application/activity_catalog.dart' show Intention;
import '../../home/application/circle_journal.dart';
import '../../plans/domain/plan_ids.dart';
import '../../plans/domain/plan_state.dart';
import 'insight.dart';
import 'insight_family.dart';

/// The frozen V1 design guardrail for a *pattern* claim — "at least five
/// relevant records across at least three distinct dates spanning at least
/// fourteen days" (frozen architecture §9). A design guardrail against
/// trivial overstatement, not statistical significance. Does not apply to
/// [InsightFamily.directionPathContinuity]'s plain current-place fact,
/// which needs no count at all.
const insightMinRecordCount = 5;
const insightMinDistinctDates = 3;
const insightMinSpanDays = 14;

/// How far back an observation may look for evidence — "using up to the
/// last 28 days" (frozen architecture §9's cadence rule).
const insightEvaluationWindowDays = 28;

/// A usefulness-specific statement additionally needs at least this many
/// relevant affirmative-attempt usefulness responses before it may be
/// shown at all (frozen architecture §9) — below this, the response
/// denominator is simply omitted, never shown as a misleadingly small
/// count.
const insightMinUsefulnessResponses = 3;

/// Evaluates THIRTY's current eligible Insight, or `null` if no family has
/// sufficient evidence right now.
///
/// Checked in a fixed, bounded order —
/// [InsightFamily.directionPathContinuity], then
/// [InsightFamily.chosenPacing], then [InsightFamily.deliberateRevisits] —
/// so at most one Insight is ever returned, matching the frozen
/// architecture's "at most one current observation and one application."
/// [journal] and [plansState] are read-only local records; [now] is the
/// explicit evaluation moment (never `DateTime.now()` read internally, so
/// this stays a pure function of its inputs).
Insight? evaluateInsight({
  required List<CircleJournalEntry> journal,
  required PlansState plansState,
  required DateTime now,
}) {
  return _evaluateDirectionPathContinuity(journal, plansState, now) ??
      _evaluateChosenPacing(journal, plansState, now) ??
      _evaluateDeliberateRevisits(journal, plansState, now);
}

// ---------------------------------------------------------------------------
// A. Direction + path continuity
// ---------------------------------------------------------------------------

Insight? _evaluateDirectionPathContinuity(
  List<CircleJournalEntry> journal,
  PlansState plansState,
  DateTime now,
) {
  final windowEntries = _withinWindow(journal, now);

  // Step 1: a pattern claim — which direction was chosen most, backed by
  // the design gate, and only when its Plan is not already active (never
  // "pretend this is a new discovery" for the Plan already being worked).
  final byDirection = <Intention, List<CircleJournalEntry>>{};
  for (final entry in windowEntries) {
    (byDirection[entry.direction] ??= []).add(entry);
  }
  Intention? topDirection;
  var topCount = 0;
  var tied = false;
  for (final entry in byDirection.entries) {
    final count = entry.value.length;
    if (count > topCount) {
      topCount = count;
      topDirection = entry.key;
      tied = false;
    } else if (count == topCount && topDirection != null) {
      tied = true;
    }
  }

  if (topDirection != null && !tied) {
    final records = byDirection[topDirection]!;
    if (_patternGateMet(records)) {
      final planId = _planForDirection(topDirection);
      if (plansState.activePlanId != planId) {
        return Insight(
          family: InsightFamily.directionPathContinuity,
          applicationType: InsightApplicationType.activateOrResumePlan,
          targetPlanId: planId,
          isPatternClaim: true,
          evidenceCount: records.length,
          evidenceDateKeys: _distinctSortedDates(records),
        );
      }
    }
  }

  // Step 2: a plain current-place fact — useful from the first saved Plan
  // transition, no count required. Only for a Plan that has ever been
  // encountered and is not currently active. Ties (including "no dated
  // entry found at all") resolve by fixed [PlanId] enum order, so this
  // stays deterministic.
  PlanId? bestPlaceholder;
  DateTime? bestPlaceholderDate;
  for (final planId in PlanId.values) {
    if (planId == plansState.activePlanId) continue;
    final progress = plansState.progress[planId];
    if (progress == null || progress.lastEncounteredStageId == null) {
      continue;
    }
    final lastEntry = _lastEntryForPlan(journal, planId);
    final lastDate = lastEntry == null
        ? null
        : _parseLocalDate(lastEntry.localDate);
    final isMoreRecent =
        bestPlaceholderDate == null ||
        (lastDate != null && lastDate.isAfter(bestPlaceholderDate));
    if (bestPlaceholder == null || isMoreRecent) {
      bestPlaceholder = planId;
      bestPlaceholderDate = lastDate ?? bestPlaceholderDate;
    }
  }
  if (bestPlaceholder != null) {
    return Insight(
      family: InsightFamily.directionPathContinuity,
      applicationType: InsightApplicationType.activateOrResumePlan,
      targetPlanId: bestPlaceholder,
    );
  }

  return null;
}

PlanId _planForDirection(Intention intention) {
  for (final planId in PlanId.values) {
    if (planDirection(planId) == intention) return planId;
  }
  throw StateError('No Plan aligned with $intention.');
}

CircleJournalEntry? _lastEntryForPlan(
  List<CircleJournalEntry> journal,
  PlanId planId,
) {
  CircleJournalEntry? latest;
  DateTime? latestDate;
  for (final entry in journal) {
    if (entry.planId != planId.name) continue;
    final date = _parseLocalDate(entry.localDate);
    if (date == null) continue;
    if (latestDate == null || date.isAfter(latestDate)) {
      latest = entry;
      latestDate = date;
    }
  }
  return latest;
}

// ---------------------------------------------------------------------------
// B. Chosen pacing
// ---------------------------------------------------------------------------

Insight? _evaluateChosenPacing(
  List<CircleJournalEntry> journal,
  PlansState plansState,
  DateTime now,
) {
  final activePlanId = plansState.activePlanId;
  if (activePlanId == null) return null;
  final progress = plansState.progress[activePlanId];
  if (progress == null) return null;
  // Never offer a default already in effect (no duplicate application).
  if (progress.lighterDefault) return null;

  final windowEntries = _withinWindow(journal, now);
  final directChoices = windowEntries.where((entry) {
    return entry.planId == activePlanId.name &&
        entry.treatmentUsed == PlanTreatment.lighter.name &&
        // Only a genuine direct user choice counts as a fresh explicit
        // pacing choice — an automatic application of an already-saved
        // preference is never counted as endorsement (load-bearing
        // invariant, frozen architecture §9/§10 of this batch's prompt).
        entry.treatmentSource == PlanTreatmentSource.directChoice.name;
  }).toList();

  if (!_patternGateMet(directChoices)) return null;

  final usefulness = _usefulnessCoverage(directChoices);

  return Insight(
    family: InsightFamily.chosenPacing,
    applicationType: InsightApplicationType.setLighterDefault,
    targetPlanId: activePlanId,
    isPatternClaim: true,
    evidenceCount: directChoices.length,
    evidenceDateKeys: _distinctSortedDates(directChoices),
    usefulnessNumerator: usefulness.$1,
    usefulnessDenominator: usefulness.$2,
  );
}

// ---------------------------------------------------------------------------
// C. Deliberate revisits
// ---------------------------------------------------------------------------

Insight? _evaluateDeliberateRevisits(
  List<CircleJournalEntry> journal,
  PlansState plansState,
  DateTime now,
) {
  final activePlanId = plansState.activePlanId;
  if (activePlanId == null) return null;
  final progress = plansState.progress[activePlanId];
  if (progress == null) return null;
  // Never offer a revisit already queued (no duplicate application).
  if (progress.pendingRevisit) return null;
  final targetStageId = progress.lastEncounteredStageId;
  if (targetStageId == null) return null;

  final windowEntries = _withinWindow(journal, now);
  final revisits = windowEntries.where((entry) {
    return entry.planId == activePlanId.name &&
        entry.stageId == targetStageId &&
        // Deliberate revisits only — accidental/recovery duplication does
        // not carry `revisitUsed: true` (Batch 2A's own semantics).
        entry.revisitUsed == true;
  }).toList();

  if (!_patternGateMet(revisits)) return null;

  final usefulness = _usefulnessCoverage(revisits);

  return Insight(
    family: InsightFamily.deliberateRevisits,
    applicationType: InsightApplicationType.queueRevisit,
    targetPlanId: activePlanId,
    targetStageId: targetStageId,
    isPatternClaim: true,
    evidenceCount: revisits.length,
    evidenceDateKeys: _distinctSortedDates(revisits),
    usefulnessNumerator: usefulness.$1,
    usefulnessDenominator: usefulness.$2,
  );
}

// ---------------------------------------------------------------------------
// Shared evidence helpers
// ---------------------------------------------------------------------------

List<CircleJournalEntry> _withinWindow(
  List<CircleJournalEntry> journal,
  DateTime now,
) {
  final windowStart = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: insightEvaluationWindowDays));
  return journal.where((entry) {
    final date = _parseLocalDate(entry.localDate);
    if (date == null) return false;
    return !date.isBefore(windowStart) && !date.isAfter(now);
  }).toList();
}

/// The frozen V1 design guardrail: at least [insightMinRecordCount]
/// relevant records, across at least [insightMinDistinctDates] distinct
/// dates, spanning at least [insightMinSpanDays] days.
bool _patternGateMet(List<CircleJournalEntry> records) {
  if (records.length < insightMinRecordCount) return false;
  final dates = _distinctSortedDates(records);
  if (dates.length < insightMinDistinctDates) return false;
  final first = _parseLocalDate(dates.first);
  final last = _parseLocalDate(dates.last);
  if (first == null || last == null) return false;
  return last.difference(first).inDays >= insightMinSpanDays;
}

List<String> _distinctSortedDates(List<CircleJournalEntry> records) {
  final dates = records.map((r) => r.localDate).toSet().toList()..sort();
  return dates;
}

/// Usefulness denominator/numerator among [records] — only counting a
/// response that followed an affirmative attempt, and only returning a
/// non-null pair once at least [insightMinUsefulnessResponses] relevant
/// responses exist. A missing response stays unknown; `notToday` is never
/// counted as a usefulness result.
(int?, int?) _usefulnessCoverage(List<CircleJournalEntry> records) {
  var denominator = 0;
  var numerator = 0;
  for (final entry in records) {
    final attempt = entry.attemptResponse;
    final usefulness = entry.usefulnessResponse;
    final isAffirmative =
        attempt == CircleAttemptResponse.yes ||
        attempt == CircleAttemptResponse.aLittle;
    if (!isAffirmative || usefulness == null) continue;
    denominator++;
    if (usefulness == CircleUsefulnessResponse.veryUseful ||
        usefulness == CircleUsefulnessResponse.somewhatUseful) {
      numerator++;
    }
  }
  if (denominator < insightMinUsefulnessResponses) return (null, null);
  return (numerator, denominator);
}

DateTime? _parseLocalDate(String localDate) {
  final parts = localDate.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}
