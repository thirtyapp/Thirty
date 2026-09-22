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
/// "THIRTY — V1 PRODUCTIZATION BATCH 2C / MINIMUM CIRCLE INSIGHTS"
/// (`1.6.0+7`): the build under which the three bounded Insight families
/// (direction/path continuity, chosen pacing, deliberate revisits), the
/// claim-specific evidence/pattern-gate evaluator, the bounded local
/// snapshot history (capped at 52), the seven-day assessment cadence with
/// an immediate live-validity recheck, the three-target application
/// adapter (activate/resume a Plan, set the lighter default, queue a
/// revisit), the `InsightCard` presentation surface inside "Your path",
/// and the `insight_shown`/`insight_application_accepted`/
/// `insight_application_invalidated` analytics events shipped (see
/// `docs/product/adr/ADR-016-v1-batch-2c-circle-insights.md`). No billing,
/// runtime AI, or Premium Atmosphere work is included in this build.
///
/// "THIRTY — V1 STEP 5 / REVENUECAT BILLING INTEGRATION" (`1.7.0+8`): the
/// build under which `premiumEntitlementProvider` stopped being a
/// hardcoded pre-billing seam and started reading verified RevenueCat
/// entitlement state; the `/premium` offer and `/settings` (status,
/// upgrade, restore, manage subscription, theme, analytics consent,
/// reminder) surfaces shipped; the one-time first-use onboarding
/// explanation shipped; and the quiet post-second-Circle Premium
/// invitation and the quiet post-first-Circle reminder invitation
/// shipped, each correctly deferring to reflection and to each other per
/// the parent prompt-priority order (see
/// `docs/product/adr/ADR-017-v1-step5-revenuecat-billing.md`, including
/// its Reconciliation and Local closure sections). The optional local
/// reminder (`flutter_local_notifications`/`timezone`/`flutter_timezone`)
/// schedules against the device's actual resolved local IANA timezone,
/// never a fixed/UTC fallback, so the user's chosen wall-clock time
/// survives a DST transition; and the default-off analytics-consent gate
/// (`ConsentGatedAnalyticsService`) both shipped in the same build. Live
/// billing proof (a real Play/RevenueCat test purchase) and live
/// reminder-delivery proof both remain BLOCKED pending a real Android
/// device — see that ADR's Consequences. A privacy policy and a support
/// contact remain REQUIRED BEFORE FEATURE-COMPLETE — neither has been
/// supplied yet.
///
/// `1.7.0+9`: a narrow bootstrap correction only — no product surface
/// changed. The first Play-delivered release AAB (`1.7.0+8`) shipped
/// without `--dart-define-from-file=config/supabase.local.json`, so
/// `main()`'s then-unconditional `SupabaseConfig.assertValid()` threw
/// before `runApp` ever ran (a white screen on every launch). Fixed by
/// replacing that fail-fast assertion with `isConfigured` plus
/// `initializeSupabaseIfConfigured` (`main.dart`), which now treats a
/// missing/invalid Supabase configuration exactly like a reachability
/// failure — non-fatal, `runApp` always runs — and by gating
/// `SupabaseAnalyticsService` on the new `supabaseAvailableProvider` so it
/// never attempts to touch an uninitialized client in the first place.
///
/// "THIRTY — STEP 1 / FOUR-DESTINATION NAVIGATION SHELL + REMINDER
/// RETURN-RITUAL AMENDMENT" (`1.7.0+10`): the build under which the
/// Batch A Premium entitlement boundary correction (`activatePlan` and
/// its four sibling `PlanNotifier` mutation methods, `InsightNotifier
/// .refreshIfDue`/`applyCurrent`, and `CoachCueBanner` all gated on
/// `premiumEntitlementProvider`; `PlanPathPage`/`InsightCard` branch on
/// entitlement into a calm Free preview rather than a route-level
/// redirect) and the Batch B/C four-destination primary navigation shell
/// (`StatefulShellRoute.indexedStack`: Today | Plans | Insights |
/// Journal, `InsightsPage` hosting the relocated `InsightCard`, a
/// matching Settings AppBar icon on Plans/Insights/Journal, and a
/// `ThirtyButton` label-overflow fix found during the shell's own
/// small-screen/text-scale verification) shipped, alongside the §48
/// Reminder Return-Ritual Amendment (`THIRTY V1 PRODUCTIZATION +
/// COMMERCIAL REVIEW.md` §48): the reminder invitation's copy changed to
/// reflect its recommended-ritual framing, and `ReminderNotifier
/// ._rescheduleIfNeeded` now re-checks live OS permission on every call
/// rather than a possibly-stale cached value, closing a startup race
/// that could wrongly cancel an already-armed reminder. Live reminder
/// delivery — specifically, a real physical non-delivery observed on the
/// `1.7.0+9` Internal Testing build — remains UNRESOLVED: the
/// investigation found the app-side scheduling/suppression logic correct
/// (verified against `flutter_local_notifications`' own native Android
/// source) but could not establish a proven root cause; an OS/OEM
/// background-alarm restriction (Samsung battery management, or Doze
/// deferral of the deliberately inexact alarm) remains an unconfirmed
/// hypothesis pending physical retest on this build. Do not treat this
/// build as proof reminder delivery is fixed.
///
/// `1.7.0+11`: an Internal Testing candidate only — no product, navigation,
/// reminder, billing, or design surface changed from `1.7.0+10`. Prepared
/// to physically verify the founder-corrected four-destination IA (Today |
/// Plans | Insights | You) and the shared Free Circle-history calendar
/// inside Insights on a real device. Separately, the `1.7.0+10` build has
/// now physically proven same-day local reminder delivery with THIRTY
/// fully closed, same-day delivery with THIRTY backgrounded and another
/// app active, and next-day delivery without opening THIRTY before
/// delivery (an 18:00 schedule delivered at 18:07); exact-minute delivery
/// remains intentionally not promised, and the earlier isolated 22:10 miss
/// remains unexplained but has not reproduced across these subsequent
/// tests. No reminder code, Android scheduling mode, notification
/// permission, or battery-configuration change was made on the strength of
/// this evidence.
///
/// `1.7.0+12`: an Internal Testing candidate only — no product, navigation,
/// reminder, billing, or design surface changed from `1.7.0+11`. Prepared to
/// physically verify the targeted Step 1 fix committed at `925d276`: live
/// refresh of the Insights Circle-history calendar after a Circle is closed
/// (an already-mounted calendar, kept alive off-screen by
/// `StatefulShellRoute.indexedStack`, now reactively picks up the newly
/// closed Circle's journal record instead of requiring a full app restart —
/// see that commit's own message for the root cause), plus a modest
/// recorded-date ring-stroke-width increase (1.5 → 2) on a real device.
///
/// **STEP 1 — CLOSED, physically verified PASS on `1.7.0+12`** (release-
/// candidate HEAD `bd14730`, live-refresh fix ancestor `925d276`; full
/// regression 620/620, analyzer clean). On the founder's Samsung: primary
/// navigation (Today | Plans | Insights | You) and the Today → Plans →
/// Insights → You → Today cycle both work; the Insights calendar renders
/// correctly and an existing recorded date still opens its correct record
/// detail, with Back returning correctly; "You" carries the expected
/// personal-control surfaces; pre-existing journal data survived the
/// update; Circle state survives tab switching; and — the specific defect
/// this candidate was built to prove fixed — a newly closed Circle now
/// appears in Insights immediately, with no app restart, confirming the
/// `925d276` indexedStack/calendar live-refresh correction. The recorded-
/// date ring is visually accepted as shipped in both Light and Dark mode;
/// the founder explicitly decided no further ring-weight change is needed,
/// and the current calendar presentation is accepted for Step 1. This
/// closes the founder-corrected four-destination IA + shared Free
/// Circle-history calendar verification opened by `1.7.0+11`.
///
/// `1.7.0+13`: an Internal Testing candidate only — no product, navigation,
/// reminder, billing, or lifecycle surface changed from `1.7.0+12` beyond
/// what shipped at commit `5f0b42d`: the Circle-first Home Ready state
/// (`CircleReadyPrompt`) now precedes the Daily Context Question — a
/// closed Circle and `Begin today's Circle`, revealing the existing three
/// directions inline once tapped — before THIRTY assigns a concrete
/// activity and the existing, unchanged First Breath ritual plays.
/// `RecommendationProvider`, the journal, reminder suppression, Plan
/// advancement, and entitlement behavior are all unchanged. Prepared to
/// physically verify this Golden Home + First Breath + beauty/interactions
/// batch on a real device — full regression 630/630 (up from the prior
/// verified baseline of 620/620: 10 new test cases, 4 existing tests
/// updated in place for the new Ready-state flow), analyzer clean.
///
/// `1.7.0+14`: an Internal Testing candidate. Physical verification of
/// `1.7.0+13` found two defects, both fixed here: the Circle composition
/// disappeared behind full-screen direction cards instead of staying
/// mounted through direction choice (`4a0dd13`, Golden Home continuity
/// correction), and the direction-choice state carried a redundant
/// explanatory paragraph removed for the final interaction polish
/// (`ec6b6ed`). Separately, `e8800e2` stopped validating release-signing
/// secrets for debug builds — unrelated to any product surface. The
/// reminder transport also changed in this build, in response to
/// physical evidence gathered on `1.7.0+13`: a correctly
/// `inexactAllowWhileIdle`-scheduled 18:05 reminder was twice actually
/// delivered ~03:48 the next local day on the founder's Samsung
/// SM-S931B — Doze deferring the inexact alarm hours past its intended
/// calendar day, independent of Closed-Circle suppression. `a44959e`
/// first hardened the existing transport (cancels the same-day alarm
/// before any async step, never only after) as an independent
/// correctness fix; this build then replaces the transport itself,
/// switching from `AndroidScheduleMode.inexactAllowWhileIdle` to
/// `exactAllowWhileIdle` via the user-granted `SCHEDULE_EXACT_ALARM`
/// special access (never `USE_EXACT_ALARM`, reserved by Google Play for
/// apps whose core function is precise timing) — `flutter_local_
/// notifications`' own supported exact-scheduling pipeline, not an
/// app-owned AlarmManager transport. Without granted access, THIRTY now
/// fails closed (schedules nothing, surfaces "Android access is needed"
/// in Settings) rather than ever falling back to the proven-bad inexact
/// mode. Prepared to physically verify both the Golden Home fixes and
/// the new exact-reminder delivery/permission flow on a real device —
/// full regression 641/641 (up from the prior verified baseline of
/// 630/630: 11 new test cases), analyzer clean.
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
  static const String appVersion = '1.7.0+14';
}
