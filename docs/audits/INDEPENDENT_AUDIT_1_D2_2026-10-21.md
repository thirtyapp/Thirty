# THIRTY — INDEPENDENT AUDIT #1 REPORT (Phase D2 closure)

> **Audit record, preserved as delivered.** Independent technical, product and commercial audit of the immutable D2 closure commit, performed 2026-10-21 for KEYBRACE. Findings, severities and the verdict are recorded as originally reported, without softening. This file is documentation only. It doesn't change the audited commit, and it isn't part of it.

| | |
|---|---|
| **Audited SHA (full)** | `8bfd42c16693b8f5040ebcf4761db0e9c439981c` |
| **Commit** | "feat(v2-d2): D2 closure — Circle Plans, Insights and the four-tab product" |
| **Remote** | equal to `refs/heads/step5-billing-integration` on `origin` (checked with `git ls-remote`) |
| **Auditor** | Audit #1 — Claude (Claude Code, Opus 5.5) |
| **Date** | 2026-10-21 |
| **Final decision** | **CONDITIONAL** |
| **Phase E recommendation** | **PROCEED**, subject to the stated conditions, Audit #2's outcome and founder approval |

---

## 1. Checkout integrity

- **Clean clone:** a fresh, isolated clone in a temporary directory, with `core.autocrlf=false`, detached at the SHA. It has 939 tracked files.
  - `git fsck` reported no problems.
  - `git status` was clean before and after `pub get`, `analyze` and the full test run.
- **Repository untouched:** no repository, worktree, frozen asset or history was modified during the audit. Nothing was committed or pushed.
- **Probe clone:** findings were reproduced in a separate throwaway clone, never in the audited clone. The probe code isn't preserved in the repository; the reproductions are described below.
- **Existing worktree:** `Development/Thirty-verify-8bfd42c` was not clean. It had 7 modified generated plugin-registrant files and a CRLF `PRODUCTION_SHA1.txt`. It was not used.
- **Gates, re-run independently on the clean clone:**
  - `flutter pub get --enforce-lockfile`: OK.
  - `flutter analyze`: no issues.
  - `flutter test`, full suite including the long simulations: **2,074 passed, 0 failed**. This matches the tracker.
- **Process note (recorded for accuracy):** during the audit, one progress message wrongly said the first test run had finished before it had. A redundant second run was started because of that, then stopped. The 2,074/0 result comes from the first run's real completion (exit code 0).

## 2. Verdicts

### Technical verdict — **SOUND, WITH TWO MAJOR DEFECTS**
- **Engine and Plans:** Engine V2, the composer and the StageBrief seam are deterministic and pure. The Plan domain matches the frozen semantics. Checked in code:
  - guided happens once per Circle, idempotently;
  - wait and set aside behave as frozen;
  - a revisit doesn't move the place;
  - pause, leave and repeat work as specified;
  - the four Stage 5 cases are implemented correctly.
- **Insights:** the gates, denominators, the 7-day cadence, the 28-day same-claim rule, the quiet rule, the 52-snapshot cap and the B8 review fix were checked against ADR-024 §11. They match.
- **Entitlement:** it is enforced at the service boundary for Plans, Insights, Leave it out and voice.
- **Debug-only paths:** dev routes, the QA harness and safety-pending content are all compile-time `kDebugMode` only.
- **What the tests miss:** both MAJOR defects come from runtime timing (entitlement not yet resolved) and future data evolution (content tuning). The test suite either doesn't reach these or deliberately treats the first as correct.

### Product verdict — **COHERENT AND HONEST; THIN IN PLACES**
- **Free:** genuinely complete for its job — one good activity, learning, Memory, History and calendar, Keep, kept Circles on screen, export and delete.
- **Premium:** different in kind. It adds a composed multi-part session sized to the time, a voice with background playback, operating Plans, and actionable Insights.
- **Weaknesses:** a small library (38 elements; More Energy at ≈10 gives 6 mains and 19 materially distinct sessions a year) and Insights that are sparse by design.

### Free/Premium verdict — **FAIR**
- **No hostage mechanics:** cancellation removes services only.
- **Lapse preserves everything owned:** B8 checks this every lapsed day, and it was confirmed in code.
- **One inconsistency:** an I4 "Keep" is refused after a lapse (m2).

### Commercial recurring-value verdict — **STRUCTURALLY PLAUSIBLE, COMMERCIALLY UNPROVEN, SUBSTITUTION RISK HIGH**
See §5.

### Safety/privacy verdict — **PASS FOR D2; PHASE E ITEMS OPEN**
- **Safety gate:** gated breathing and exertion content is unreachable in profile and release builds (`safetyPendingContentAllowed = kDebugMode`).
- **Storage:** `android:allowBackup="false"`; analytics are opt-in and off by default.
- **Delete:** its scope matches the contract, including the unreadable-record keys.
- **Open for Phase E:** analytics privacy, Play policy items and the public-release safety review (R5, R6, R8).

---

## 3. Defects with evidence and severity

There are no CRITICAL and no BLOCKER findings.

### F1 — MAJOR (observed and reproduced): a transient non-active entitlement silently downgrades a paying subscriber's day and loses Plan progression

**Location**
- `lib/features/home/application/recommendation_provider.dart:754` reads `premiumEntitlementProvider` synchronously in `chooseIntention`.
- `recommendation_provider.dart:731` means "decides once a day"; it is never re-made.
- `recommendation_provider.dart:1211–1219` with `lib/features/plans/application/circle_plans_provider.dart:187` (`recordGuided`) returns early unless Premium is active.
- The entitlement state is `initializing` at every cold start until RevenueCat resolves (`lib/core/premium/premium_access.dart`), and `unavailable` on SDK failure.
- `lib/features/home/presentation/widgets/daily_intention_prompt.dart:180` does not wait for entitlement.

**Evidence** (probe tests, through the production providers)
- *P1:* an active Plan, a cold start, a need chosen while billing is still `initializing`, then billing resolves to `active`. Today stays Free's single activity (`thirtyMinuteWalk`, `composed=null`), with no stage, for the rest of the day. A second `chooseIntention` does nothing.
- *P1b:* a stage Circle started while Premium, the app reopened, and Close tapped while billing is still `initializing`. The Plan stays at `cursor=1` with no stage record, permanently. Nothing reconciles it from the journal.
- `test/features/premium/b7_entitlement_matrix_test.dart` and `test/features/plans/circle_plan_today_test.dart:770` treat `initializing` as Free, so the suite enshrines this behaviour.

**Consequence:** a subscriber can be silently denied the paid daily job, and the stage they actually guided isn't credited. There is no visible indication. The window is short on a normal start with the SDK cache, but larger after a fresh install, on poor connectivity or when Play services fail. It also breaks the contract's GUIDED rule ("started and later closed").

**Smallest correction**
- While the status is `initializing`, hold the need/time choice briefly ("Checking…"), or allow one recomposition of a not-started, uncomposed day when the entitlement becomes `active`.
- In `close()`, record guided when the Circle's stored provenance was served under Premium, rather than requiring Premium at the moment of Close.

**Blocks D2 audit acceptance?** No — it is not an architecture or contract-design defect. It must be fixed before any build with live billing reaches testers (Phase E entry condition).

### F2 — MAJOR (latent, reproduced mechanism): user-owned kept Circles can be silently and permanently deleted by a future content tuning

**Location**
- `lib/features/personal_circle/domain/circle_elements.dart:793`: `CirclePart.fromWire` rejects a stored length the catalogue no longer authors.
- `lib/features/personal_circle/domain/kept_circle.dart:96–104`: `keptCirclesFromRecord` drops that whole Circle, without setting it aside.
- `lib/features/personal_circle/application/kept_circles_provider.dart:83–90`: the next write persists the shortened list.

**Evidence** (probe P2)
- Two kept Circles were stored, one holding `getItOut:7`, a length the catalogue doesn't author. Only one is visible, and `toolkit_v1_unreadable` stays empty.
- Renaming the *other* Circle rewrites the stored record as `[kept-a]`, and `kept-b` is gone for good.

**Consequence:** the contract makes element minutes TUNABLE, and an element ID can also be removed or renamed. The contract also says kept Circles "never change", "survive", and that the business model "never depends on confiscating owned content". The first content tuning after release would silently confiscate owned Circles. Export would omit them too.

**Smallest correction:** keep any unparseable Circle verbatim in the stored record, or in a per-Circle set-aside list, rather than dropping it. Also add a test that a catalogue change never removes a kept Circle.

**Blocks D2 audit acceptance?** No — no data is lost at this SHA, and there are no public installs. It must be fixed before any element change ships, and before public release.

### m1 — MINOR (reproduced, P3): the Stage 5 "no last Circle" headline is untrue for mixed cycles

**Location:** `lib/features/personal_circle/domain/stage_brief.dart` `stageFive` → `allRejected`; `lib/features/plans/presentation/plan_view.dart:156–158` `endLine`.

**Evidence:** stages 1–2 answered Not useful and 3–4 set aside end with the headline "You said none of these stages was useful, so THIRTY hasn't made a last Circle from them." The user never answered about stages 3–4. This affects 14 of the 16 no-Stage-5 combinations B8 counted.

**Contract:** C7 and §7 D ("If **every** earlier stage was explicitly rejected"). The "Go through it again" option is also hidden in these cases.

**Correction:** add a mixed end reason with wording that names both facts.

**Blocks?** No.

### m2 — MINOR: Keep from I4 is refused without Premium

**Location:** `lib/features/insights/application/insights_provider.dart:133`.

**Contract:** "Keep is **never gated**" (Kept Circles; ADR-024 §3) conflicts with "new Insight applications" stopping after a lapse.

**Correction:** exempt `KeepCircleFromHistory` from the gate, or clarify the contract.

**Blocks?** No.

### m3 — MINOR: I4 kind labels overstate parts

**Location:** `lib/features/insights/domain/insight_copy.dart` `kindLabel`.

**Evidence:**
- "Some fresh air" (stand at an open door or window, set as indoor) is reported as "Time outside".
- "One active job" (carrying things) is reported as "Tidying".

**Consequence:** a co-occurrence claim slightly misstates what was in the Circles.

**Correction:** use labels that match the actual parts.

**Blocks?** No.

### m4 — MINOR: documentation at the closure SHA doesn't fully match the implementation

This is a D2 acceptance criterion ("Documentation matches the implementation").
- `docs/product/PRODUCT_V2_CONTRACT.md:28` (Amendment 2) still says "Implementation: pending … the built app still shows the Phase D/D2 Toolkit".
- `artifacts/v2_phase_d2/final_audit/README.md` says "D2: NOT COMPLETE".
- `final_audit/KNOWN_COMMERCIAL_HYPOTHESES.md` says "no production voice yet", and H2 still cites 40/60 instead of B8's 111/120.
- `final_audit/RELEASE_AUDIT_NOTES.md` cites the removed `lib/features/toolkit/domain/module_library.dart`.
- Evidence the docs point to is not in the commit: `artifacts/v2_phase_d2/screenshots/`, `bg_qa/logcat_session.txt`, `voice_production/listen/`.

**Correction:** a documentation-only refresh.

**Blocks?** No.

### m5 — MINOR (portability, not audio corruption): the hash manifests become CRLF on a default Windows checkout

**Location:** `artifacts/v2_phase_d2/voice_production/PRODUCTION_SHA1.txt`, and the other `*SHA1.txt` manifests. None has a `.gitattributes` rule.

**Evidence:**
- The blob is LF; 0 CRs were counted.
- The system git config has `core.autocrlf=true`, so the checked-out file becomes CRLF.
- `sha1sum -c` then gives **0/172**, each failing as `'…lead_first_d97b30dd.m4a'$'\r': No such file`. The carriage return is in the filename field.

**Actual audio:**
- **172/172 OK** on the clean LF clone, and 172/172 with CRs stripped in the existing verify worktree.
- The `.m4a` files are detected as binary (`-text`), so autocrlf never touches them, and the blobs are identical. There is no audio corruption.

**Correction:** add `artifacts/**/*SHA1.txt text eol=lf` to `.gitattributes`.

**Blocks?** No.

### m6 — MINOR (known, carried forward): older Free activity wording still on the release-audit list

"…out of sight in a pocket or bag", "a bit livelier" and "walk a little quicker than usual" remain at `lib/features/home/application/activity_catalog.dart:309, 331, 335, 358`. This needs resolving before public release.

---

## 4. Non-blocking risks

- **R1 — Kept-Circle substitution (commercial, HIGH).**
  - Keep appears after any closed composed Circle, and Close doesn't check elapsed time. A subscriber can harvest 8 personal sessions in about 8 days.
  - B8's **111/120** figure is *coverage, not behaviour*. It counts lapsed days on which a matching kept Circle existed, and the scripted user always used one.
  - What a lapsed user loses is variety, the voice, Plans and Insights. Whether they value those is unknown.
- **R2 — More Energy thinness:** 6 mains and 19 materially distinct sessions a year at ≈10, with the first exact repeat on day 23. Widening it depends on the safety review.
- **R3 — Insights volume:**
  - non-responder: 24–42 of 53 weeks silent, and no I2, I3 or I4;
  - heavy single-Plan user: 75 of 86 Insights are Plan reviews, so the tab risks reading as a Plan log;
  - I2 and I3 rarely fire in the profiles.
- **R4 — Answer-rate dependency (MEDIUM):** I4, Stage 5 cases B/C and cross-cycle comparison all need explicit answers.
- **R5 — Analytics privacy (Phase E):**
  - When consent is on, `recommendation_shown` sends the need and activity ID, and attempt/usefulness events send the user's answers, all under a pseudonymous tester ID.
  - Delete doesn't reach that data, and there's no remote deletion path. For a consented user, the Delete copy "nothing is stored anywhere else" is only true in the restore sense.
  - This must be addressed in privacy and Data Safety work.
- **R6 — Play policy dependencies:** the `mediaPlayback` foreground-service declaration with demonstration video, and the `SCHEDULE_EXACT_ALARM` justification.
- **R7 — Device evidence:** S25 and TalkBack claims are mostly checkable only through text summaries, because media were excluded from the commit. The auditor could not run a device.
- **R8 — Safety:** debug builds expose gated content, by design for internal use. Closed-test builds must be profile/release builds. The public-release safety review is still pending.
- **R9 — iOS:** there is no iOS guidance player and billing is Android-only, so the Guidance job doesn't exist on iOS.
- **R10 — Entitlement freshness:** expiry while the app stays in the foreground relies on the RevenueCat listener and resume refresh, with no polling. Live purchase and restore have not been tested.

---

## 5. Commercial questions

- **Is Premium materially better than Free?** Yes in kind — composition, voice, Plans and Insights are real, functional work. How material it feels day to day, compared with one good activity, is unmeasured.
- **Is there a genuine recurring software job?** Yes, but it is finite. Composition is recomputed daily over a fixed 38-element library. For mixed users that gives about 18 mains and 111–127 materially distinct sessions a year, with median exact-repeat gaps of 59–73 days. Plans are 3 × 5 authored stages, recomposed each cycle.
- **Does Premium stay useful once a subscriber has kept Circles?** Partly. What remains is the voice, variety, Plans and Insights. For a visual-only user who mostly picks one need, the case is weak.
- **Are Plans and Insights real sources of value or mostly presentation?** Both are functional: Plans steer composition, and Insight applications change behaviour. Plans give continuing direction. Insights are low-frequency, and their recurring weight is small.
- **Is €5–7/month defensible?** Structurally plausible at the low end, not defensible on evidence. Phase E should test price, and test annual pricing.
- **Month 1 vs 6 vs 12:**
  - Month 1 has the most novelty, and it is also the harvest window.
  - Month 6 adds cross-cycle reviews, I4 and I6, with variety near its plateau.
  - Month 12 adds no new mechanism (B8 says so honestly), so value rests on the voice and daily convenience.
- **What remains unproven:** willingness to pay, conversion, Month-2 paid retention, answer rate, substitution in practice, voice value, Plan uptake, Insight usefulness, and how repetitive More Energy feels.
- **Does any risk block Phase E?** No. Phase E is the validation step. But it must instrument lapse and kept-Circle use, the voice, Plans and Insights, with explicit decision thresholds.

### B8 simulation figures used (from `artifacts/v2_phase_d2/b8/simulations/`)

| Profile | Composed days | Distinct sessions | Materially distinct | Distinct mains | First exact repeat | Median repeat gap |
|---|---|---|---|---|---|---|
| A non-responder | 311 | 211 | 127 | 18 | day 34 | 73 days |
| B mixed answerer | 321 | 225 | 111 | 18 | day 38 | 67 days |
| C More Energy ≈10 | 365 | 52 | 19 | 6 | day 23 | 23 days |
| D lapse and return | 245 | 184 | 116 | 18 | day 41 | 59 days |

Lapse profile D: 120 lapsed days; a kept Circle could stand in on 111 and was used on 111 (scripted to always use one).

## 6. Outstanding market validation

- Willingness to pay and price
- Trial-to-paid conversion
- D7, D30 and Month-2 paid retention
- Usefulness answer rate
- Real kept-Circle substitution after a lapse
- Voice usage and perceived value
- Plan start and repeat rates
- Insight application rates
- Perceived repetition for More-Energy-dominant users

## 7. Final decision: **CONDITIONAL**

No CRITICAL or BLOCKER defect was found, so this audit does not trigger the restart rule. The conditions:

1. F1 is fixed before any live-billing build reaches testers.
2. F2 is fixed before any content tuning ships, and before public release.
3. m1–m6 and R5/R6 are tracked as Phase E work.

## 8. Phase E recommendation: **PROCEED**

This is subject to the conditions above, Audit #2's outcome and founder approval.
