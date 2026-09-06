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
/// "THIRTY — V1 PRODUCTIZATION BATCH 1 / FREE FOUNDATION" (`1.3.0+4`): the
/// build under which the frozen 21-placement V1 catalogue, the
/// cross-direction diversity guard, the optional action-report foundation,
/// the prospective local Circle journal, the read-only history/data
/// controls, and the `circle_attempt_reported`/`circle_usefulness_reported`
/// analytics events shipped (see
/// `docs/product/adr/ADR-013-v1-free-foundation-and-journal.md`).
///
/// "THIRTY — V1 PRODUCTIZATION BATCH 2A / CIRCLE PLANS + GUIDED SESSIONS"
/// (`1.4.0+5`): the build under which the three five-stage Circle Plans,
/// their forward-cursor/one-off-revisit/cycle state, the daily
/// Plan-vs-Free resolution rule, the standard/lighter treatment toggle,
/// the additive Plan journal fields, the pre-billing
/// `premiumEntitlementProvider` access seam, and the
/// `plan_started`/`plan_session_shown`/`plan_cycle_completed`/
/// `plan_revisit_queued`/`plan_revisit_used` analytics events shipped (see
/// `docs/product/adr/ADR-014-v1-batch-2a-circle-plans.md`). No billing,
/// Coach, Insights, or Premium Atmosphere work is included in this build.
///
/// "THIRTY — V1 PRODUCTIZATION BATCH 2B / MINIMUM CIRCLE COACH" (`1.5.0+6`):
/// the build under which the six bounded Coach situation families, their
/// one-cue priority policy, the persistent Plan-level lighter default and
/// its `PlanTreatmentSource` provenance, the additive
/// `treatmentSource` journal field, the `CoachCueBanner` presentation
/// surface, and the `coach_cue_shown`/`coach_application_accepted`/
/// `coach_application_cleared` analytics events shipped (see
/// `docs/product/adr/ADR-015-v1-batch-2b-circle-coach.md`). No Insights,
/// billing, runtime AI, or Premium Atmosphere work is included in this
/// build.
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
  static const String appVersion = '1.5.0+6';
}
