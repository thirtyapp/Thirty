/// THIRTY's Batch 1 release boundary.
///
/// "THIRTY — BATCH 1 / POST-FIX RETENTION COHORT": the build under which
/// the Close Circle confirmation, the post-close "Done for today" state,
/// and behavioural instrumentation shipped (see
/// `docs/product/adr/ADR-011-batch-1-post-fix-retention-cohort.md`). Every
/// analytics event records [appVersion] so future analysis can always
/// trace a row back to whether it happened at or after this exact build —
/// the frozen evaluation boundary the post-fix measurement protocol
/// depends on.
///
/// [appVersion] must be bumped by hand in lockstep with `pubspec.yaml`'s
/// own `version:` field whenever a new build ships — there is no
/// `package_info_plus` dependency to read it at runtime (AGENTS.md §5:
/// no new packages beyond what's already in `pubspec.yaml`), so this is
/// the one place that value is deliberately duplicated.
class ReleaseInfo {
  const ReleaseInfo._();

  /// Keep in sync with `pubspec.yaml`'s `version:` field.
  static const String appVersion = '1.1.0+2';
}
