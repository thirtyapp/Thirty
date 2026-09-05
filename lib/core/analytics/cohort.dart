/// Batch 1's two evaluation cohorts (Phase F — cohort integrity).
///
/// Pre-fix and post-fix testers must never be pooled: [preFix] testers
/// already used THIRTY before the Close Circle confirmation / post-close
/// clarity shipped, [postFixBatch1] testers' very first observed exposure
/// to THIRTY was already on the Batch 1 build. See
/// [`TesterIdentity`](tester_identity_provider.dart) for exactly how a
/// device is classified, and
/// `docs/product/adr/ADR-011-batch-1-post-fix-retention-cohort.md` for why.
enum Cohort { preFix, postFixBatch1 }

/// The stable string this cohort is written as in `analytics_events.cohort`
/// — see [Cohort]'s own doc comment.
extension CohortWire on Cohort {
  String get wireName => switch (this) {
    Cohort.preFix => 'PRE_FIX',
    Cohort.postFixBatch1 => 'POST_FIX_BATCH_1',
  };
}

/// The [Cohort] [wireName] names, or `null` if it matches none — the
/// inverse of [CohortWire.wireName], used to restore a persisted cohort
/// value.
Cohort? cohortFromWireName(String? wireName) {
  for (final cohort in Cohort.values) {
    if (cohort.wireName == wireName) return cohort;
  }
  return null;
}
