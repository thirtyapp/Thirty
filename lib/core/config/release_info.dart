/// THIRTY's release boundary.
///
/// "THIRTY — BATCH 1 / POST-FIX RETENTION COHORT" (`1.1.0+2`): the build
/// under which the Close Circle confirmation, the post-close "Done for
/// today" state, and behavioural instrumentation shipped (see
/// `docs/product/adr/ADR-011-batch-1-post-fix-retention-cohort.md`).
///
/// "THIRTY — BATCH 2 / RECOMMENDATION DIVERSITY" (`1.2.0+3`): the build
/// under which the recommendation anti-repetition guard and the
/// `recommendation_shown` analytics event shipped (see
/// `docs/product/adr/ADR-012-batch-2-recommendation-diversity.md`).
///
/// Every analytics event records [appVersion] so future analysis can
/// always trace a row back to the exact build it happened under — the
/// frozen evaluation boundary the post-fix measurement protocol depends
/// on.
///
/// [appVersion] must be bumped by hand in lockstep with `pubspec.yaml`'s
/// own `version:` field whenever a new build ships — there is no
/// `package_info_plus` dependency to read it at runtime (AGENTS.md §5:
/// no new packages beyond what's already in `pubspec.yaml`), so this is
/// the one place that value is deliberately duplicated.
class ReleaseInfo {
  const ReleaseInfo._();

  /// Keep in sync with `pubspec.yaml`'s `version:` field.
  static const String appVersion = '1.2.0+3';
}
