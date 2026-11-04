# THIRTY — INDEPENDENT AUDIT #2: GPT-6 ASTRA

**Independent product, technical and commercial audit for KEYBRACE**  
**Audit date:** 21 October 2026  
**Immutable target:** thirtyapp/Thirty · step5-billing-integration · **8bfd42c16693b8f5040ebcf4761db0e9c439981c**

## Executive verdict

**Overall decision: FAIL. Phase E recommendation: HOLD.**

THIRTY has a coherent core product and substantial implementation behind it. Free offers a useful daily decision without requiring payment or feedback. Premium genuinely changes the experience through composition, Plan direction and spoken guidance. The implementation generally preserves the distinction between a recorded interaction, a reported attempt and reported usefulness.

Nevertheless, this commit should not pass the independent D2 gate. The production billing adapter treats the normal absence of a purchased entitlement as an unavailable billing service. The paywall consequently withholds its purchase control from a legitimate new customer. Independently of that defect, a paid customer who chooses today's need before entitlement initialization finishes can be locked into a Free offer for the day. Owned content also depends on the current catalogue, and session persistence and deletion lack a shared consistency boundary.

These are specific, correctable problems. They do not require replacing the product architecture or adding more features. They do prevent an unconditional acceptance of this immutable version.

| Required statement | Audit result |
|---|---|
| Repository identity | Verified: public repository **thirtyapp/Thirty**, repository ID 1315703674 |
| Exact audited commit | **8bfd42c16693b8f5040ebcf4761db0e9c439981c** |
| Commit tree | **57fab70bfd141972d60ee70feb0ad6f9b7a19a48** |
| Source access verified | **YES** |
| Independently executed application tests | **NO** — Flutter and Dart were unavailable in this audit environment; no Flutter suite, Android build or device journey was executed |
| Independently executed audit calculations | **YES** — Git-blob verification, catalogue enumeration, committed-trace reanalysis, substitution counterfactuals and audio-container checks |
| Overall decision | **FAIL** |
| Phase E | **HOLD** |
| Confidence | High in source identity, the billing mapping defect and the identified guard/serialization behavior; moderate in interruption failure scenarios; low in market predictions, for which there is no live demand evidence |

The strongest favorable conclusion is that the product could help a person stop deciding and start one manageable activity. The strongest unfavorable commercial conclusion is that the continuing subscription job is much less established than the implementation. A small library of kept Circles can cover many future need/time combinations. Voice and Plans may justify renewal for some users, but the repository cannot establish that enough people will pay €5–7 each month.

No CRITICAL finding is asserted. No runtime defect is described as reproduced in this audit.

## 1. Scope, independence and evidence

### 1.1 Version and source verification

GitHub repository and Git-data endpoints were used to resolve the repository, exact commit and recursive tree. The tree response was not truncated and contained 1,171 entries, including directories. The archive was requested by the full immutable SHA, not by the moving branch name.

All 937 included file blobs were checked against the Git tree using Git's blob hash construction: SHA-1 over the blob header and original bytes. All matched. The source snapshot was kept separate from audit calculations and the report.

The entire docs/audits directory was excluded from extraction. Independent Audit #1 was not opened or used. Earlier implementation reports, B8 simulations and B9 closure material were treated as claims to investigate, not as independent acceptance.

No application code, tests, repository documentation or configuration was changed. No commits, pushes, pull requests, entitlement changes, pricing changes or Phase E work were performed.

### 1.2 What the evidence labels mean

| Label | Meaning in this report |
|---|---|
| **Source-verified** | The exact audited implementation contains the stated branch, guard, data structure or behavior |
| **Code-derived failure** | A concrete input or event ordering leads to the described outcome by inspection; it has not been executed in Flutter or on a device |
| **Executed audit analysis** | A calculation, enumeration, integrity check or media-container inspection was run independently in Python/ffprobe |
| **Reported evidence** | A test or device result committed by the project; inspected but not independently rerun |
| **Commercial hypothesis** | A plausible effect on value, renewal or acquisition; requires customers to establish |
| **Unknown** | The available code and evidence cannot answer the question |

The reported 2,074 passing tests and clean analyzer result are **project-reported**, from the tracker and B9 closure material. They are not this audit's test results. Older reports with smaller test counts describe earlier work and are not substituted for the closure result.

The independent calculations establish consistency of selected static properties and expose weaknesses in the measurement definitions. They do not validate the production SDK, platform channels, provider scheduling, real payment flows, audio intelligibility or actual retention.

### 1.3 Coverage

Inspection covered the current product contract and amendments; delivery tracker; relevant accepted ADRs, particularly ADR-020, ADR-023 and ADR-024; Brand Book, Design System and World System; startup, routing, clocks and providers; recommendation and composition logic; Plan and Insight domains; kept Circles and journal persistence; export, deletion and retirement migrations; RevenueCat boundaries; analytics and consent; Android manifest, signing/configuration gates, guidance and reminder implementation; audio declarations; targeted tests and D2 artifacts.

This is comprehensive coverage of the requested systems, not a claim that every line of every included file received equally deep review. There was no independent physical-device, visual-accessibility or listening session. Production Play/RevenueCat/Supabase account configuration and deployment state were not accessible or verified.

## 2. Authority and document conflicts

The amended PRODUCT_V2_CONTRACT governs current product behavior. Its 17 October amendment takes precedence over the earlier Premium design. ADR-024 describes the current four-tab product. The tracker is authoritative for delivery status, not proof of correctness. Brand, design and world principles remain applicable where the newer product contract has not superseded them.

| Disagreement | Governing interpretation and actual code | Classification |
|---|---|---|
| Contract amendment says implementation is pending and the built app still has Toolkit, while the tracker declares D2 complete | Contract line 28 is stale status prose. Actual routing implements Today, Plans, Insights and You; retired Toolkit destinations redirect. The tracker owns status. | Harmless status drift; correct when documentation is next authorized |
| Older Brand Book describes fixed daily 30 minutes and AI assistance | Current contract provides natural durations, three time windows and deterministic local decisions. Code follows the newer contract. | Historical, not a missing AI or 30-minute feature |
| Older brand turquoise versus current sage implementation | Design System explicitly explains the approved palette evolution and accessibility-related token differences. | Documented evolution, not a visual defect |
| Retired Paths/routines versus current Plans/kept Circles | Amendment 2 and ADR-024 govern. Retirement migration removes retired fields without fabricating equivalent new objects. | Intentional pre-release retirement |
| “Never the same activity on consecutive days” in contract line 204 versus Free fallback | Accepted ADR-020, lines 30–36, records the founder's narrow relaxation order. Engine V2 follows it when alternatives are exhausted. The absolute contract sentence was not reconciled. | Bounded authority/copy inconsistency; do not silently call the rule absolute |
| All new Insight applications are Premium versus “Keep is never gated,” explicitly including Insight 4 | The specific ownership guarantee in contract line 399 and ADR-024 §3 should govern keeping an already generated Circle. The service currently applies the general Premium guard to that action. | **Material: A2-05** |
| Android manifest says allowBackup=false also disables all Android 12 device transfer | Official Android documentation explicitly describes manufacturer-dependent exceptions. | **Material: A2-07** |
| Closure says ownership/commercial behavior is PASS | Real source still contains the billing, ownership and persistence issues below. Closure is implementation evidence, not the independent gate's conclusion. | **Material acceptance disagreement** |

The corrections recommended here are bounded responses to evidence. They do not reopen the product's identity, four-tab architecture, kept-Circle ownership or recurring model without cause.

## 3. Technical assessment

### 3.1 Architecture, lifecycle and persistence

The separation of pure domain decisions from providers and presentation is sound. Recommendation and composition can be evaluated from explicit inputs. Plan progression and Insight evaluation have domain-level checks, rather than relying only on which button is visible. This is a good basis for deterministic regression testing.

The weak point is coordination across asynchronous boundaries:

- Entitlement initialization deliberately does not block Free. That is appropriate, but the boolean access seam collapses “not yet known” into “Free” at the moment an irreversible daily choice is recorded.
- Today's offer and lifecycle are stored across numerous preference keys. A serialized queue prevents two ordinary writes from overtaking each other, but does not make a multi-key update atomic.
- Journal, Plan and Insight persistence are separately managed. Close can schedule the session write and advance a Plan through another queue. There is no general transaction or recovery protocol tying these records together.
- Delete history clears stores directly without first cancelling, draining or invalidating all pending session writes.
- Several persistence queues swallow errors. A successful-looking in-memory action is not necessarily durable after restart.

These weaknesses matter more than whether the code is aesthetically modular. See A2-02 and A2-04.

Idempotency is nevertheless well considered in normal sequential operation. A daily choice is made once; lifecycle methods guard their current state; Plan progression validates plan, cycle, expected stage and prior Circle IDs. In circle_plan.dart:649–700, both lastAdvancedCircleId and existing cycle records prevent duplicate progress. These checks do not by themselves repair an interrupted write across stores.

The day clock is cached and refreshed on foreground resume. Event timestamps use a fresh callable clock. This avoids using launch time for every action, but continuous foreground use across midnight retains the old day until invalidation. Time-zone travel and midnight/resume during queued writes need targeted verification. A2-11 describes the bounded foreground gap.

The four-tab indexed-stack router supports independent branch navigation. History, Memory and ownership surfaces remain reachable without requiring an active entitlement. Direct navigation does not grant Premium service access. Debug routes are debug-gated; Android's default Flutter deep-link handling is disabled. Full process-death navigation restoration was not demonstrated in this audit.

### 3.2 Today Engine V2

The Free engine delivers the core decision service, including explicit feedback, time fit and user exclusions. It does not reserve the fundamental recommendation intelligence for paying users.

Positive findings from recommendation_engine.dart and its callers:

- Need fit and time fit constrain candidates; excluded or unsafe content is not rescued by a high score.
- Explicit “Don't suggest” survives fallback.
- Missing usefulness feedback is unknown, rather than a negative answer.
- Feedback is bounded and decays; explicit reversals are possible.
- Replacement has a reason and a bounded daily opportunity. Replacing is not recorded as “Not useful.”
- Deterministic date-seeded selection avoids a visible fixed rotation.
- A no-candidate condition is presented without silently reversing the user's exclusions.
- Sparse evidence does not justify a personalized outcome claim.

The Free engine has a documented protective-rule relaxation order: weekly cap, then yesterday's activity, then a temporary negative-feedback rest only if nothing non-resting fits. This is not an unconditional no-repetition guarantee. Safety, explicit exclusions and time constraints stay hard.

One daily decision is a useful simplification, but increases the cost of a wrong state transition: an early Free choice, stale date or partially written record can affect the whole day's experience.

### 3.3 Personal Guided Circle

The composer is a substantive local service, not merely a different title above the Free activity. It constructs bounded sequences from authored parts and enforces:

- live/offerable source content;
- need fit, explicit exclusions and relevant rests;
- actual authored lengths;
- no duplicate element or kind;
- compatible indoor/outdoor context;
- adjacency for parts whose instructions depend on a preceding part;
- a meaningful main piece and a second piece no longer than the main;
- maximum part counts and minimum time utilization;
- no consecutive repetition of yesterday's main piece;
- StageBrief constraints without bypassing the main quality gate.

An honest shorter result is allowed; padding to fill 30 minutes is not. If nothing passes, the app falls back to a single Free activity and identifies that fallback. The main/second evidence calculation uses bounded, half-weight contributions from composed-session answers; it does not claim causality.

Independent source-metadata enumeration reproduced every published gate-passing shape count for the nine need/time cells. This supports structural feasibility of the baseline library. It does not establish feasibility under every combination of exclusions, recency, negative feedback and StageBrief.

The content library is real but uneven. More Energy has the narrowest breadth. The published “materially distinct” metric also counts some arrival and closing parts because of their possible roles, rather than their roles in the actual session. A2-10 and §5 quantify the difference.

### 3.4 Plans

Plans are a direction over matching daily Circles. They are not an additional mandatory daily task. The active Plan's need must match today's need, and using an owned Circle takes precedence without advancing a stage.

The domain distinguishes a temporarily waiting stage from a stage that cannot be served because of lasting user exclusions. Pause, leave, revisit and repeat have explicit state transitions. A revisit clears its pending request rather than advancing the ordinary cursor as a new stage.

Stage 5 uses the current cycle's eligible earlier stages. Negative and set-aside stages are excluded. No positive answers produces an honest earlier-stage mix; one positive prioritizes that stage; multiple positives prioritize supported combinations. If no eligible material remains, there is no fabricated fifth-stage success. All-history learning may affect composition ranking, but does not silently substitute old cycles for current-cycle eligibility.

This is a credible implementation of the amended contract. The existing exhaustive Stage 5 and adversarial-cycle tests are useful **reported evidence**, not a guarantee about asynchronous production behavior.

“Guided” records a started-and-closed stage Circle; it does not prove the person performed the activity or benefited. Review wording generally respects that distinction. Repeated cycles revisit a fixed five-stage design with different compositions and explicit answers; they do not become an increasingly sophisticated curriculum simply because six or twelve months have passed.

On lapse, place and reviews remain readable while new paid progression stops. Returning subscribers can resume their place, subject to the entitlement timing issue. Interrupted Close and independent persistence queues remain a reliability risk.

### 3.5 All six Insight families

The evaluator stores dated snapshots and separates observation from application. It has a seven-day ordinary cadence, a 28-day same-claim limit, evidence-based Not-now suppression and a 52-snapshot cap. Plan reviews are separate from ordinary cadence; pruning protects relevant ordinary claims and avoids presenting a dropped old review as new.

| Family | Actual evidence/action model | Assessment |
|---|---|---|
| **I1 — Plan for your need** | Unique most-chosen need in a 28-day window; relevant pattern gate; start, resume or repeat its Plan | Useful simple direction. Date range and denominator can describe different record sets: **A2-08** |
| **I2 — Gentler Plan Circles** | Repeated “Too much” choices for Plan offers; excludes offers already produced under gentler treatment; applies a current-cycle setting | Avoids treating the app's own setting as new user evidence; value depends on this pattern actually occurring |
| **I3 — A part you skip** | Repeated direct skips among recent appearances; dependency skips are not counted as independent rejection | Actionable and reversible. No I3 events appeared in the four inspected B8 traces; this says more about those scripts than correctness |
| **I4 — What useful Circles shared** | Explicit positive answers versus other exposures, with a minimum difference and denominators; actual main/second roles | Co-occurrence wording is appropriate. It cannot prove a component caused benefit. Existing-Circle Keep action is wrongly gated after lapse: **A2-05** |
| **I5 — Plan review** | Reference to an eligible completed/left cycle's review in Plans; outside ordinary cadence | Honest summary of the cycle, not an independent weekly discovery |
| **I6 — What's changed** | Comparison of chosen needs in separated recent and earlier windows; Plan direction or nothing to change | Describes choices, not inferred psychological improvement |

Silence is an acceptable product behavior. It is also a commercial limitation: a paid tab that often has no new actionable observation should not be sold as a weekly stream of meaningful learning.

Malformed local dates can reach the evaluator's unchecked date parser. This breaks the intended isolation of one malformed journal entry; see A2-09.

### 3.6 Billing and access matrix

The following are source-derived assessments, not store/device test results.

| Situation | Current behavior and assessment |
|---|---|
| Fresh customer; correctly configured SDK; no purchase history | Empty entitlement map becomes unavailable; paywall has no purchase block. **A2-01, BLOCKER** |
| Entitlement still initializing | Free remains usable, but choosing a need can permanently select Free for today. **A2-02** |
| Active before daily choice | New composition, Plan operation, new Insights and THIRTY voice are available |
| Active arrives after a Free daily choice | No dependency/listener replaces the unstarted Free offer. Same-day purchase/restore has the same problem |
| True expiry | New paid services stop; ordinary Free and owned/readable data remain. I4 Keep exception is missed |
| Cancellation while paid-through access remains active | Adapter follows isActive, not a cancellation flag; this is the appropriate distinction |
| Offline with usable SDK cache | Adapter asks RevenueCat for its own cached CustomerInfo. No independent app entitlement cache is invented |
| Offline with no usable result / SDK failure | Unavailable, no false Premium grant. The “unknown” state can still affect today's paid experience |
| Pending payment | Not represented as confirmed purchase success |
| Resubscription/restore | Uses verified CustomerInfo and preserves local records; same-day daily-offer timing remains unresolved |
| External subscription change / resume | Refresh is initiated. Out-of-order overlapping refresh/purchase results deserve a delayed-response test |
| Direct navigation to paid surfaces | Domain service guards still apply; readable ownership surfaces remain accessible |

RevenueCat's official documentation explicitly says CustomerInfo may contain no entitlements for a customer who has not purchased or synced transactions. The presence of a configured entitlement in the dashboard does not make it appear in every customer's map. That is why A2-01 is a production integration defect, not simply an unconfigured development build. [External source E1]

### 3.7 Ownership, export and migration

Kept Circles are available without Premium for normal use, rename, removal and export. The maximum is eight. Existing visual pacing and accessibility output are separate from THIRTY's paid voice. This is a strong, respectful boundary.

However, kept records store element identifiers and minutes, not an immutable content representation or versioned catalogue reference. Their instructions and validity are resolved against today's catalogue. Stable enum names alone do not protect against changed authored durations or text. Partial read failures are silently omitted, and a later whole-list write can discard those entries. See A2-03.

Journal export includes records and can include explicit suggestion preferences, kept Circles, Plan state and Insight snapshots. It is copied as JSON text. This is useful ownership access, but it is not a complete import/restore system or a durable backup solution. No new cloud-sync feature is required by this audit.

The pre-release retirement migration removes retired Path/routine fields and preserves kept/raw fields it does not own. Its marker is written last and it is intended to be idempotent. Intentional pre-release removal is distinguished from future loss of a customer's owned Circle.

At a settled state, Delete history clears the journal, today's session keys, Plan stage evidence/reviews and Insight snapshots while retaining kept Circles, Plan place and explicit preferences. The failure is coordination with writes already in flight, not the nominal list of data to remove.

### 3.8 Safety, privacy, Android and accessibility

**Safety.** Offerability checks isolate safety-pending content from external builds; the composer requires live content even in debug. Plans and Insights do not create an alternate route around that gate. The contract still requires a bounded review of live breathing/exertion material before public release. A regex content guard or a founder's engineering review is not a clinical safety assessment. No claim of medical efficacy or completed independent safety approval is made here.

**Analytics.** Consent defaults off and is centrally checked. There is no retrospective queue of pre-consent events. Free decisions do not require successful telemetry. However, when configured and opted in, the app transmits dated recommendation choices and attempt/usefulness responses under a persistent tester identifier. The copy “Your Circle history is never included” does not adequately distinguish that granular event history from the full journal. Local history deletion also does not remove existing remote events. This is a disclosure/scope problem, not a claim that events are sent without opt-in. See A2-06.

**Android backup.** allowBackup=false is present, but the claim that this prevents every device-to-device transfer is incorrect across manufacturers. Explicit extraction rules and transfer verification are needed for the stated promise. See A2-07 and Android's official guidance. [External source E2]

**Android execution.** The manifest declares billing, notification, reminder, foreground media-playback and wake-lock permissions. Guidance is a non-exported media-playback service with bounded session work, not a general background service. Release signing and billing configuration have build-time checks; target SDK is declared as 36. These are appropriate safeguards, but syntactically valid billing configuration does not prove a correct offering, entitlement mapping or Play product.

The committed foreground-service manifest verification used a profile merge; the tracker itself requires checking the final release APK. Real signing, Play installation, store purchase/restore/expiry and platform declarations remain release gates.

The native audio player requests audio focus; interruption behavior still needs device validation, including a call, another media app, Bluetooth loss, process removal, lock-screen controls and screen-reader coexistence. No audio-interruption defect is asserted from a missing device run alone.

**Assets.** All four declared voice folders contain 43 nonempty M4A files, including each common guidance clip and a voice preview. Independent ffprobe inspection read positive durations from all 172 files. This establishes container availability, not voice quality, exact spoken wording, licensing or correct runtime sequencing.

**Accessibility.** Source includes semantic labels, screen-reader accommodation and layouts intended for larger text; accessibility is not tied to the paid voice. Committed S25/TalkBack and 1.6× text evidence is valuable but remains reported evidence. It does not establish all-device, all-screen accessibility. No absence of independent visual testing is disguised as a UI pass.

**Dependencies.** The application uses a lockfile and recognizable Flutter, RevenueCat, Supabase and notification dependencies. No supply-chain compromise was identified. An exhaustive advisory/license review of every transitive dependency and the final signed artifact was not performed; a clean security bill cannot be inferred from package names or a passing test suite.

### 3.9 Verification quality

There is substantial useful testing of deterministic decisions, Plan states, eligibility constraints, lapse ownership, guards and long-horizon operation. These are meaningful tests, not merely a count.

The important gaps are at boundaries the tests replace or settle:

- The entitlement matrix supplies a never-subscribed state as inactive, rather than constructing the empty CustomerInfo that the real adapter receives.
- Gateway tests cover unavailable configuration and purchase error/outcome mapping, but do not exercise the defective customer-entitlement mapping.
- Long-horizon B8 runs override Premium with a pre-resolved boolean, fixed day/clock inputs and mocked preferences.
- The simulation settles asynchronous work before checking many outcomes. It cannot demonstrate crash safety or deletion while a write is blocked.
- Current-catalog round trips do not demonstrate compatibility with later content revisions.
- Reported device QA does not replace a clean Play purchase journey by a customer who has never owned the entitlement.

After corrections are authorized elsewhere, the necessary verification is a small set of failure-path regressions and actual billing journeys. A larger undirected test count is not the objective.

## 4. Product and Free/Premium assessment

### 4.1 Core promise and first use

The core promise is credible: choose the kind of help needed and a manageable time window; receive one thing to do; get sufficient guidance to begin and close it. A short need choice avoids forcing someone to navigate a content library or self-diagnose.

The first-use flow appears structurally short, and ordinary Free does not need a purchase or network response to make a recommendation once initialization completes. This audit did not measure seconds to first useful action. Whether the suggested activity feels useful, feasible and well described remains a user-research question.

Today is the strongest and clearest product surface. Plan direction can be valuable to a person who wants continuity. Insights is more conditional. You sensibly holds ownership, controls and settings.

Four tabs are defensible for the implemented product, but a Free or low-feedback user may experience Plans and Insights mainly as low-activity destinations. The calendar's placement within Insights is a comprehension risk if people assume the whole tab is paid. Free access is implemented; findability needs observation, not another navigation redesign by assumption.

### 4.2 Agency, copy and usefulness

The app provides meaningful ways to reject a suggestion, change time before committing, leave out a component, reverse preferences, pause a Plan and decline feedback. These support the intended calm, non-judgmental character.

Most inspected copy is appropriately restrained. It does not use streak pressure, fabricated urgency or diagnosis. Explicitly distinguishing no answer from not useful is especially important. The remaining honesty issues are concrete: the I1 date range, analytics disclosure, and an ownership action gated inside Insights.

The no-feedback user still receives useful structure, variety and Plan direction. The user does not receive evidence-backed claims about what works for them. That is honest behavior, though it means “personal” may be experienced mainly as matching today's chosen need and time.

### 4.3 Fairness and actual differentiation

| Capability | Free / lapsed | Active Premium | Judgment |
|---|---|---|---|
| One daily recommendation, explanation and basic learning | Available | Available | Free solves the central decision job |
| New multi-part composition | No | Yes, when quality gate permits | Substantive distinction; startup timing can undermine delivery |
| Kept Circles: visual use, rename, remove, export | Available | Available | Fair; future catalogue compatibility needs repair |
| Keep from an existing I4 suggestion | Blocked by generic application guard | Available | Violates the specific never-gated Keep rule |
| History, calendar, Memory, export and local deletion | Available | Available | Ownership boundary is sound in intent; persistence/disclosure caveats apply |
| Plan place and past reviews | Readable | Readable | Fair |
| New Plan progression and repeat operation | Stopped | Available | A distinct paid service |
| Earlier Insight snapshots | Readable, within retention policy | Readable | Fair |
| New Insights and paid applications | Stopped | Available | Legitimate boundary except the Keep exception |
| On-screen pacing and TalkBack | Available for owned content | Available | Accessibility is preserved |
| THIRTY voice and background spoken cues | Stopped | Available | Clearly defined access; recurring willingness to pay is unproven |

Cancellation generally leaves a coherent product. It does not confiscate the kept collection, basic recommendations or readable history. This is a strength even where it makes renewal harder to sell.

Premium is not purely cosmetic, but technical differentiation is not the same as sufficient perceived value. For a person satisfied with one Free suggestion or a favorite saved routine, Premium may be unnecessary. The correct response is to validate who values the continuing service, not weaken ownership.

## 5. Content depth, simulations and recurring value

### 5.1 Independently checked baseline content

The catalogue contains 38 elements: 20 fit More Energy, 33 Clearer Head and 20 Gentler Pace; categories overlap. Eighteen elements can serve as main pieces. Many elements are brief arrival or settlement cues, so “38” is not 38 fully different substantive activities.

The table compares the committed coverage metric with an independent Python enumeration using actual session roles. The calculation uses the unchanged source metadata and baseline quality gate, with no history, exclusions or StageBrief. All nine shape counts and original metric counts were reproduced. The adjusted measure counts the unordered identities of the actual main and second parts, ignoring durations, arrival and settlement.

| Need | Window | Gate-passing shapes | Published “material” combinations | Actual-role main/second combinations | Distinct mains | Actual length range |
|---|---:|---:|---:|---:|---:|---:|
| More Energy | 10 min | 195 | 19 | **19** | 6 | 6–10 min |
| More Energy | 20 min | 617 | 39 | **34** | 9 | 12–20 min |
| More Energy | Up to 30 | 208 | 19 | **16** | 7 | 18–30 min |
| Clearer Head | 10 min | 950 | 65 | **47** | 10 | 6–10 min |
| Clearer Head | 20 min | 9,496 | 355 | **122** | 15 | 12–20 min |
| Clearer Head | Up to 30 | 6,576 | 271 | **82** | 12 | 18–30 min |
| Gentler Pace | 10 min | 285 | 35 | **26** | 7 | 6–10 min |
| Gentler Pace | 20 min | 2,346 | 199 | **75** | 11 | 12–20 min |
| Gentler Pace | Up to 30 | 1,577 | 151 | **49** | 10 | 18–29 min |

Even the adjusted counts are structural combinations, not measured differences that a person will notice. A different pairing of familiar tasks may be useful without feeling novel. Conversely, repeating a helpful session is not inherently a product failure. The risk is selling continuing discovery while the value is mainly comfortable repetition.

The smallest content decision is to observe whether the Energy/10-minute cohort experiences a meaningful limitation. It is not to unlock safety-pending content merely to inflate variety.

### 5.2 What the 12-month evidence actually shows

The committed B8 simulation uses production providers with mocked storage, scripted actions and pre-resolved entitlement. It is a useful structural test. It does not simulate acquisition, price resistance, natural disengagement or a real subscription renewal decision.

The following counts were independently recounted from the committed trace files. App behavior itself was not rerun.

| Profile | New composed days | Ordinary Insights | Plan reviews shown | Weeks without a new ordinary Insight, out of 53 | Published material variety → actual-role recount |
|---|---:|---:|---:|---:|---:|
| A: no usefulness answers | 311 | 15 | 21 | 38 | 127 → **77** |
| B: mixed answers and interventions | 321 | 29 | 18 | 24 | 111 → **71** |
| C: More Energy / 10 minutes | 365 | 11 | 75 | 42 | 19 → **19** |
| D: lapse and return | 245 | 14 | 19 | 39 | 116 → **77** |

“Silent weeks” means no **new ordinary Insight**, not an empty tab: an old observation or Plan review can remain visible. Profile D's count also includes 120 lapsed days and cannot be treated as 53 weeks of paid service. Profile scripts open Insights every three or four days and often automatically repeat Plans.

The ordinary family recounts matched the committed reports. Profile C had 10 I1 observations, one I4 and 75 I5 reviews. That is mainly recurring Plan review, not 86 different discoveries. No I3 appeared across these four scripts; only one I2 appeared. This does not invalidate those features, but weakens any assumption that all six families contribute recurring value for a typical subscriber.

In profile C, the first repeat of the entire element set was reported on day 23. The independent role-based recount finds the first repeated substantive combination on day 11. Duration and edge changes should not be advertised as guaranteed novelty.

The existing reports already disclaim proof of retention and conversion. This audit agrees with that limitation and additionally corrects the material-variety definition.

### 5.3 One-month kept-Circle counterfactual

The original lapse profile stays Premium for 150 days, lapses for days 151–270, then returns. Its 111/120 coverage result does not directly test cancellation after one month.

An additional audit calculation used only the **first 30 daily offers** from that committed profile to build collections, then checked their fit against later scripted needs and time windows. It did not rerun the app under the changed subscription schedule.

Coverage was deliberately defined exactly as the original simple substitute test: **same need and stored duration no greater than available time**. It does not mean equal benefit, adequate duration, desired variety, appropriate setting or willingness to repeat.

| First-month collection rule | Full by | Minimum stored duration: Energy / Head / Pace | Need/time cells covered | Later days 31–365 covered | Original lapse-window days covered |
|---|---:|---|---:|---:|---:|
| Keep the first eight daily compositions | Day 8 | 10 / 10 / 24 min | 7/9 | **295/335** | **111/120** |
| Keep the first eight with positive scripted usefulness answers | Day 16 | 10 / 10 / 24 min | 7/9 | **295/335** | **111/120** |
| Retrospectively select the shortest observed offer for each need, then fill the collection | Day 29 | 8 / 9 / 9 min | 9/9 | **335/335** | **120/120** |

The third row is a deliberate collector's upper-bound illustration, not a realistic behavioral forecast. The first two rows use straightforward chronological strategies. Kept-Circle mutations are not inputs to the composer itself, but changing subscription timing could change subsequent user behavior and app-generated history; therefore these are coverage counterfactuals, not independently simulated production trajectories.

The structural conclusion is robust: only three sufficiently short, suitable Circles—one per need—can fit all nine need/time cells under this permissive definition. Eight slots are ample to weaken the need for continued composition. The exact satisfaction and renewal effect is unknown.

Voice can offset substitution if hands-free cues are a frequent valued service. Plans can offset it if direction makes people actually use the app more effectively. Insights can offset it for people who provide sufficient evidence and value the resulting applications. None of these offsets is established by the coverage calculation.

Do not restrict kept ownership to repair this commercial risk.

### 5.4 Adversarial profile assessment

| Profile | Functionality in the current design | Incremental Premium value and repetition | Evidence limit |
|---|---|---|---|
| Never answers usefulness | Composition and Plans continue; useful-for-you claims stay absent | Structure/voice remain; personalized discovery is weak | B8 trace supports structural behavior, not benefit |
| Always Energy / 10 min | Baseline has feasible output; six mains, 19 substantive combinations | Repetition likely noticeable much sooner than a year | Actual perception and whether repetition is welcome are unknown |
| Repeats the same Plan | New cycles and current-cycle Stage 5 are implemented | Familiar direction, changing mixtures; fixed stage architecture | No evidence that month 6 is more valuable than month 2 |
| Changes needs frequently | Need/time matching and shared eligible content continue | More breadth, but Plan progression may be intermittent | Scripted mixed profiles cannot establish real decision quality |
| Collects eight kept Circles | Collection can fill in eight used days; normal lapse use is Free | Strong substitute for new composition | “Fits” is not “as good”; catalogue resilience remains defective |
| Cancels after one month | Free and kept use remain by contract | Additional first-month coverage calculation shows substantial substitution | Counterfactual calculation, not a Flutter rerun |
| Returns after several months | Place and stored content remain; active entitlement resumes paid services | New current need/time choices, not an automatically expanded catalogue | Same-day timing and future catalogue changes require repair |
| Ignores Insights | Today and Plans do not depend on opening Insights | No experienced value from unseen new Insights | Silence/absence of use is not evidence of poor wellbeing |
| Intermittent connectivity | Local decisions and bundled audio do not need per-session cloud generation | SDK cache may preserve access; unknown startup state can wrongly fix a Free day | Real SDK cache/error timing not executed |
| Saved records predate catalogue changes | Supported IDs/lengths read; changed text resolves dynamically; unsupported parts can disappear | Ownership trust is at risk before any novelty benefit | Code-derived future-compatibility failure, not observed current customer loss |

### 5.5 The recurring job and its limits

The strongest recurring job is: **make today's small activity decision easy, adapt it to explicit constraints, and guide the person through it without requiring them to manage a routine.**

This can remain valuable after month one if the person repeatedly experiences reduced friction or appreciates spoken guidance and Plan direction. It does not require the app to generate entirely new content every day.

What is lost on lapse is mainly automatic fresh composition, operation of a Plan, new evidence evaluation/application and THIRTY voice. That is a coherent service boundary. However, much of the underlying activity knowledge and the favorite routines can be retained. The buyer must value continued orchestration enough to renew.

The phrase “continuing software work” is not proof of a recurring economic need. Local computation is cheap, and the voices are bundled assets. Consumers pay for a recurring result or convenience, not because an algorithm runs again.

THIRTY's differentiation is its constrained decision interface, mixed everyday activities, bounded personalization, lack of pressure and combined guidance. Generic self-care suggestions, a few written routines and basic timers can substitute for portions of this. Meditation libraries compete strongly on content and voice. Habit tools compete on reminders and recording, though THIRTY deliberately avoids their pressure mechanics.

For a current reference point, Insight Timer offers substantial free content, and its official Member Plus page advertises US$60 annually for premium courses/features. Headspace's official support describes a paid library with trial access. These are alternative value propositions, not directly comparable Belgian monthly prices. THIRTY should compete on relieving decision effort, not claim superior catalogue depth. [External sources E5–E7]

The implementation is reproducible by a capable team. There is no evidenced proprietary model, exclusive distribution channel, network effect or unique outcome dataset that constitutes a strong moat. Trust, execution, habit of use and a sharply defined customer could become defensible advantages; they have not yet been established.

### 5.6 Pricing and bounded unit economics

A €5–7 monthly subscription is technically plausible for this cost structure. No observed conversion, renewal or acquisition data in the reviewed evidence establishes that users will accept it.

The following is a **sensitivity model, not a forecast or an asserted tax treatment**:

- Consumer price includes an illustrative **20% consumption tax**. Actual tax and store treatment depend on the market.
- Total Play service plus billing deduction is modeled at **15%** of the tax-exclusive amount. Google's current schedule lists 10% service plus 5% Google Play billing for auto-renewing subscriptions in the named rollout markets, and 15% subscriptions in remaining markets pending rollout. [E3]
- RevenueCat is modeled at **1% of gross tracked revenue** once its paid threshold applies. Its published offer is free up to US$2,500 monthly tracked revenue and 1% thereafter. Exact contractual/account terms must be checked. [E4]
- Ongoing support and other variable cost are assumed at **€0.25–€1 per paying subscriber-month**. This is a scenario range, not measured KEYBRACE cost.
- Founder pay, product development, fixed hosting, content/safety review, refunds and acquisition are excluded.

| Consumer monthly price | After illustrative tax, store and RevenueCat | Contribution after assumed €0.25–€1 variable cost |
|---|---:|---:|
| €5 | €3.49 | **€2.49–€3.24** |
| €6 | €4.19 | **€3.19–€3.94** |
| €7 | €4.89 | **€3.89–€4.64** |

At the €6 midpoint, a deliberately simplified constant-churn model gives:

| Assumed monthly churn | Mathematical expected paid months | Undiscounted contribution before acquisition and fixed costs |
|---|---:|---:|
| 5% | 20 | **€64–€79** |
| 10% | 10 | **€32–€39** |
| 20% | 5 | **€16–€20** |

Expected months use 1/churn. This assumes constant independent monthly churn and ignores cohort shape, reactivation, refunds, price changes and annual plans. It is not evidence that THIRTY will achieve any row.

Acquisition costs must be recovered from contribution, not gross receipts. Under the 10% illustrative churn row, €30 acquisition cost leaves very little room for development or founder income. Under the 20% row, paid acquisition could be unattractive even at much lower cost. Bundled audio and local computation keep marginal serving costs low, but do not solve churn or distribution.

Conversion must be measured with a stated denominator: exposed eligible users, purchase attempts, successful purchases and surviving renewals are different quantities. No generic industry conversion percentage should be inserted as a THIRTY forecast.

### 5.7 Three business scenarios

**1. Optimistic but plausible.** A defined group repeatedly struggles with deciding how to use a short break. They value the mix of activities and hands-free guidance, use Plans voluntarily and find enough benefit to renew without novelty pressure. Trusted recommendations or a focused distribution channel keep acquisition modest. The 5% churn sensitivity row illustrates the kind of economics that could support a small sustainable business. This scenario requires evidence that ongoing orchestration is worth paying for even when users own good substitutes.

**2. Base case with conservative assumptions.** Free is useful; a smaller group pays for voice and convenience. Some subscribers leave after building a collection, and some return for a period when they want direction. Insights are occasional supporting value. The 10% churn sensitivity row shows limited room for acquisition and founder costs. This can be a respectable small product, but does not yet support a confident growth or income-replacement claim.

**3. Downside.** Users like the presentation but do not repeatedly act on suggestions, or the suggestions feel generic. Those who pay sample the experience, keep favorites and cancel. Narrow Energy content and repeated Plan reviews expose a plateau. The 20% churn sensitivity row may still be optimistic for this behavior. Better engineering alone would not create demand. The correct decision would be to limit further investment or narrow the paying audience, not impose ownership restrictions.

These scenarios are hypotheses. There is no defensible probability or revenue forecast to attach to them from the available evidence.

### 5.8 Evidence needed for product-market fit

After engineering corrections and audit clearance, a bounded validation round should answer:

1. Can a new person explain the value and begin an appropriate activity without assistance?
2. Do they actually attempt it, and do they voluntarily report it as useful? Close alone is not completion evidence.
3. What brings them back on days 7 and 30, including users who decline feedback?
4. Which continuing service causes a real purchase and a second and third paid month?
5. Do people keep using the product after collecting substitutes? Do they keep paying?
6. How do Energy/10-minute users experience repetition compared with other need/time profiles?
7. What do cancellers say they no longer need, and what do returners believe changed?
8. What are actual contribution, support burden and acquisition cost per surviving subscriber?

Record cohort definitions and uncertainty. Consent-based telemetry has selection bias; complement it with observed sessions and voluntary interviews. Do not turn more feedback prompts into a requirement merely to make the personalization story look stronger.

## 6. Findings register

Severity follows the requested definitions. “Code-derived” does not mean runtime-reproduced. Commercial risks are separated from application defects; lack of product-market-fit evidence is not itself a reason to manufacture a technical blocker.

| ID | Severity | Category | Evidence | Impact | Required action | Timing |
|---|---|---|---|---|---|---|
| **A2-01** | **BLOCKER** | Billing | [Gateway:71–76][gateway]; [paywall:197–213][paywall]; E1 | Normal never-purchased customer has no purchase CTA | Separate no ownership from service/configuration failure; verify real fresh customer path | **Before Phase E and billing tests** |
| **A2-02** | **MAJOR** | Paid delivery/state | [Startup:79–84][startup]; [access:29–31][premiumstate]; [choice:730–819][choice] | Paid user can receive Free for the day because access resolved late | Reconcile unresolved/changed access before an unstarted daily offer is finalized | **Before Phase E** |
| **A2-03** | **MAJOR** | Ownership | [Kept serialization:45–103][kept]; [part reader:779–794][wire]; [repository:29–47][keptrepo] | Catalogue updates can change or silently remove owned content | Preserve immutable/version-resolvable content and unreadable individual records | **Before Phase E acceptance of ownership; certainly before public release/content updates** |
| **A2-04** | **MAJOR** | Integrity/deletion | [Queue:565–574][queue]; [persist:1494–1518][persistchoice]; [delete:152–160][delete] | Mixed-day state after interruption; pending writes can reintroduce deleted history | Atomic session publication plus coordinated deletion/write barrier and recovery | **Before Phase E** |
| **A2-05** | **MAJOR** | Fairness | [Apply:132–149][apply]; [contract:399][contractkeep] | Existing I4 Keep action is subscription-gated | Apply specific ungated ownership rule to Keep, retaining validity checks | **Before Phase E** |
| **A2-06** | **MAJOR** | Privacy/copy | [Consent copy:96–100][datacopy]; [telemetry metadata][telemetry]; [sender][analytics] | Opt-in description understates transmitted Circle-related history | Disclose actual event fields, identifier and deletion/retention scope | **Before Phase E measurement or external analytics use** |
| **A2-07** | **MAJOR** | Android/privacy | [Manifest:42–55][manifest]; E2 | Device-local/no-restore promise not assured on all Android devices | Explicit cloud/device-transfer exclusions and final-artifact transfer test | **Before public release** |
| **A2-08** | **MINOR** | Insight accuracy | [I1 evaluator:266–295][i1]; [copy:13–21][i1copy] | Date range does not necessarily cover denominator | Make range, denominator and evidence scope consistent | **Before public release** |
| **A2-09** | **MINOR** | Malformed data | [Journal parser:486–503][journalparse]; [Insight date parser:189–218][dateparse] | One accepted malformed date can break Insights | Validate canonical dates at the read boundary; isolate invalid entries | **Before public release** |
| **A2-10** | **MINOR** | Verification evidence | [Coverage metric:47–65][covermetric]; [B8 metric:573–578][b8metric] | Some “material” diversity counts include arrival/settlement changes | Count actual session roles and relabel/recompute evidence | **Before relying on these metrics in acceptance or commercial claims** |
| **A2-11** | **MINOR** | Day boundary | [Cached clock][clock]; [resume-only invalidation][appresume] | Continuous foreground session does not observe a new day | Revalidate local day on relevant actions; define active-session rollover | **Before public release** |
| **R-01** | **NON-BLOCKING RISK** | Commercial | First-month substitution analysis; paid boundary | Composition alone may not sustain renewal | Measure renewal reasons and kept-substitute use; preserve ownership | During authorized validation |
| **R-02** | **NON-BLOCKING RISK** | Content/retention | Catalogue breadth and 12-month traces | Repetition and sparse Insights may weaken perceived value | Observe narrow-profile cohorts; avoid generic content expansion | During authorized validation |
| **R-03** | **NON-BLOCKING RISK** | Release evidence | No independent signed-build/device/store execution | Platform failures remain unmeasured | Complete focused release, billing, safety and accessibility gates | Before public release |

### A2-01 — Normal new customers are classified as billing unavailable

**Severity:** BLOCKER.  
**Evidence status:** source-verified mapping plus official SDK semantics; code-derived user journey, not an executed purchase reproduction.

**Exact evidence.** In lib/core/premium/revenue_cat_entitlement_gateway.dart:64–77, _statusFor looks up the configured ID in CustomerInfo.entitlements.all and returns unavailable when absent. The comment explicitly assumes absence is a configuration mismatch. In lib/features/premium/presentation/premium_offer_page.dart:197–213, only inactive renders _PurchaseBlock. Unavailable renders a status note.

**Expected.** A successful response for a customer who has never purchased should mean no owned entitlement, while a valid available monthly offer remains purchasable. Failure to fetch status or validate configuration is a different condition.

**Actual.** An empty owned-entitlement map becomes unavailable. The purchase action is absent even if the offering and product are valid.

**Supporting external evidence.** RevenueCat explicitly documents that CustomerInfo can be empty before a purchase or transaction sync, even when entitlements exist in the dashboard. [E1]

**Reproduction to execute after authorization.** Configure the correct entitlement and a valid monthly offering; use a clean customer with no purchase history; let getCustomerInfo return an empty entitlement collection; open the offer page. Expected: monthly price and purchase control. Source-predicted result: unavailable note and no purchase block.

**Test gap.** test/core/premium/entitlement_gateway_test.dart:49–118 tests outcome/error mapping and the unconfigured fallback, not _statusFor with real CustomerInfo shapes. test/features/premium/b7_entitlement_matrix_test.dart:149–157 manually supplies inactive for “never subscribed.” That bypasses the defect.

**Consequence.** The primary conversion path can fail for precisely the customers the business needs to acquire. Restore is not a remedy for someone who has never purchased.

**Smallest correction.** Treat a successful customer response with no owned entitlement as inactive. Validate offering/configuration separately and keep failure closed for access. Add a focused adapter-to-paywall regression and run a clean Play test-account purchase. A local bool override is insufficient.

**Timing:** before Phase E acceptance and before meaningful billing tests.

### A2-02 — Late entitlement resolution freezes an unstarted paid day as Free

**Severity:** MAJOR.  
**Evidence status:** code-derived, high confidence; not runtime-reproduced.

**Exact evidence.** lib/main.dart:79–84 starts entitlement initialization without awaiting it. premium_access.dart:29–31 returns true only for active. recommendation_provider.dart:730–819 reads that boolean once when selecting the daily offer and persists the result. Its build at 577–705 does not depend on entitlement. A later chooseIntention returns immediately when a recommendation exists. Replacement at 893–905 only enters the composition branch if the current offer was already composed.

**Expected.** A customer whose paid entitlement resolves after the first frame should receive the paid service for an unstarted daily choice, or be given an explicit bounded way to resolve that choice. Free should remain usable without waiting indefinitely for billing.

**Actual.** Selecting a need while access is initializing, or unavailable until a successful refresh, creates a normal Free offer. Becoming active does not reconcile it. The same day remains Free after restarting because the offer was persisted. Buying or restoring after selecting a Free offer exposes the same gap.

**Reproduction to execute.** Delay gateway initialization; choose a need and time while unresolved; resolve active before Start; inspect and restart Today. Repeat with inactive → purchase → active on the same date.

**Test gap.** Pre-resolved Premium overrides and next-day resubscription scenarios do not cover this ordering.

**Consequence.** A paid customer can see a weaker service on their first paid day or on a slow startup. This undermines both trust and the observed value of Premium.

**Smallest correction.** Preserve the distinction between unresolved access and confirmed Free when deciding how to finalize an unstarted offer. On verified activation, reconcile once or offer the intended paid composition explicitly. Do not overwrite a started session, an explicit owned-Circle choice or create a second daily Circle.

**Timing:** before Phase E. The founder should confirm the exact unstarted-offer behavior; this does not require changing the paid boundary.

### A2-03 — Kept Circles are not self-contained across catalogue revisions

**Severity:** MAJOR.  
**Evidence status:** source-verified storage dependency; code-derived future-update failure. No existing customer loss is alleged.

**Exact evidence.** kept_circle.dart:45–52 persists ID, name, need, part wires, creation time and source Circle ID. circle_elements.dart:779 resolves each part's definition from the current element library; 786–794 accepts only current enum IDs and authored lengths. CirclePlan.fromWire at 869–877 rejects the whole plan if any part fails. kept_circle.dart:96–103 omits individual parse failures. kept_circles_provider.dart:29–39 backs up only a wholly unreadable wrapper; 80–85 writes a new whole list from the surviving entries.

**Expected.** A user-kept Circle remains owned with the instructions and structure they kept. A later catalogue revision must not silently alter or discard it. Safety retirement can disable execution without erasing ownership or history.

**Actual.** Changing an element's instruction changes what an old kept Circle displays. Changing a supported duration can make its stored wire unreadable. A single unreadable Circle is silently left out, without triggering the wrapper backup. A later rename, keep or removal writes only survivors.

**Reproduction to execute.** Keep a Circle containing getItOut:4, which is valid in this catalogue. In a compatibility fixture for a later catalogue, remove that authored length while retaining the ID. Read the old collection, then rename another Circle and restart. Separately change instruction text without changing the ID. These are proposed fixtures, not edits made during this audit.

**Test gap.** Round-tripping against the same live catalogue demonstrates current parsing, not forward/backward compatibility. Stable-ID comments do not protect authored-length or wording changes.

**Consequence.** An update intended to improve content can mutate or remove something the customer owns. Export also retains wires rather than a fully independent instructional representation.

**Smallest correction.** Preserve owned content through an immutable snapshot or explicit version-resolvable catalogue representation, with compatibility handling. Retain unsupported individual records rather than dropping them on the next write. Storage/content versioning is an implementation mechanism, not a new user-facing routine-version feature. Keep execution safety checks independent from preservation.

**Timing:** resolve the ownership design before Phase E acceptance; implement and verify before public release or any incompatible catalogue update.

### A2-04 — Session persistence and deletion lack a shared consistency boundary

**Severity:** MAJOR.  
**Evidence status:** concrete code-derived crash/race windows; occurrence and frequency not measured.

**Exact evidence.** recommendation_provider.dart:565–574 serializes its own writes and swallows errors. _persistChoice:1494–1518 writes the new day first, then intention/activity/status and old lifecycle cleanup through separate awaited preference operations. Restoration:592–667 checks the day and timestamp ordering, but not that those timestamps belong to the newly published session. _persist:1644–1650 derives the day from the current clock instead of the captured recommendation identity. journal_data_controls.dart:152–160 clears history directly without joining the pending session queue. circle_journal.dart:1020–1077 can recreate an absent record through upsert.

**Expected.** Restart should observe one complete daily state. Delete history should prevent older in-flight writes from restoring deleted evidence. Journal and Plan progress should recover coherently after interruption.

**Actual failure windows.**

1. **Mixed-day restoration.** Yesterday has a valid closed record. Today's _persistChoice completes the new day-key write, then the process is interrupted before replacing yesterday's status and fields. Restoration can now accept yesterday's valid closed lifecycle under today's day key.
2. **Delete/write interleaving.** A pending lifecycle write is suspended. Delete clears the journal, then starts removing the other session keys. The old lifecycle write resumes while deletion is still awaiting those removals and upserts the old Circle. Delete does not clear the journal again or use an epoch that rejects the stale writer.
3. **Related recovery gap.** A queued _persist reads the day when it executes, while its captured state belongs to a particular Circle. A resume/day change can therefore publish a mismatched day. Close also advances Plan state through a separate persistence path; no general cross-store reconciliation was found.

**Reproduction to execute.** Use a controllable preference backend in an isolated test fixture: interrupt after each write boundary in a new-day choice; block a lifecycle write, confirm Delete, then release the write during deletion; interrupt Close between session/journal and Plan persistence. Verify both immediate state and a fresh-container restart.

These schedules were derived from the code, not executed. Ordinary fast writes may complete before a person reaches Delete; this does not establish the required invariant under delayed storage.

**Test gap.** Settled mock-preference tests and serial write ordering do not test atomic publication, process death or pending writes crossing deletion.

**Consequence.** The app can display an already-closed new day, lose agreement between surfaces, or contradict the statement that deleted history is gone.

**Smallest correction.** Store a complete versioned daily state atomically, or publish it only through an equivalent validated commit boundary. Use the session's captured identity. Make deletion a coordinated barrier that drains/cancels old operations and prevents them from repopulating evidence. Add bounded recovery for journal/Plan disagreement and surface persistence failures appropriately. This does not require a general cloud backend.

**Timing:** before Phase E.

### A2-05 — Insight 4's existing-Circle Keep action is incorrectly paid

**Severity:** MAJOR.  
**Evidence status:** source-verified entitlement guard and explicit contract conflict.

**Exact evidence.** PRODUCT_V2_CONTRACT.md:399 explicitly includes Keep from Insight 4 in “never gated.” ADR-024 §3 repeats the rule. insights_provider.dart:132–149 checks _premium before inspecting the application, including KeepCircleFromHistory. insights_page.dart:184–208 also hides the current ordinary actionable card when lapsed. The underlying kept-Circle service itself is ungated.

**Expected.** A valid previously generated I4 suggestion can keep the already-existing Circle after lapse, within the normal eight-Circle limit. Free need not generate a new Insight.

**Actual.** The general paid-application guard returns needsPremium before the Keep action reaches the ungated ownership service.

**Reproduction to execute.** Generate a current I4 snapshot pointing to an unkept historical Circle; lapse while the snapshot remains valid; invoke its existing Keep action through both UI and service.

**Test gap.** The B8 lapse script at 371–375 expects every Insight application to return needsPremium. That assumption masks the specific ownership exception instead of validating it.

**Consequence.** A narrow but explicit ownership promise is violated. This is a fairness and consistency defect, not evidence that all lapsed content is confiscated.

**Smallest correction.** Handle the valid existing-Circle Keep application under the ungated ownership rule, retaining staleness, safety and capacity checks. Preserve the paid boundary for new Insight generation and other service applications. Reconcile the contradictory generic wording.

**Timing:** before Phase E.

### A2-06 — Analytics disclosure understates transmitted Circle-related data

**Severity:** MAJOR.  
**Evidence status:** source-verified transmission path and copy; no live backend data inspected.

**Exact evidence.** you_data_card.dart:96–100 says “Share anonymous usage data” and “Your Circle history is never included.” recommendation_provider.dart:821–828 sends intention and activity ID; 1256–1289 sends attempt and usefulness responses. analytics_service.dart:60–68 includes tester_id, event type, timestamp, local date, app version, cohort and metadata. The service is consent-gated. Supabase documentation describes an insert-only app path; local Delete does not issue a remote deletion.

**Expected.** Opt-in copy should explain the material categories actually transmitted, and users should understand the scope of local history deletion and consent withdrawal.

**Actual.** The full journal document is not uploaded, but a dated, install-linked subset of its important facts is sent as events. An ordinary person can reasonably understand “history is never included” as excluding those choices and responses. The current wording does not explain that distinction or the persistence of previously sent events.

**Reproduction to execute.** With a configured test backend and explicit opt-in, record one recommendation, attempt and usefulness answer; inspect the permitted event payloads. Delete local history and verify what remains remotely. Repeat with consent off and verify no events are sent.

**Test gap.** Consent/no-send tests can pass while the disclosure remains misleading. Backend retention and deletion configuration were not verified here.

**Consequence.** Users cannot accurately assess what they are agreeing to share. A purely local deletion can be misunderstood as removing all related records.

**Smallest correction.** Describe the actual event fields and install-linked identifier in concise plain language, distinguish them from the full local journal, and state what deleting local history or turning sharing off does to prior events. Make an explicit bounded retention/deletion decision before measurement. Do not characterize this audit as a jurisdiction-specific legal conclusion.

**Timing:** before Phase E measurement or any external analytics use.

### A2-07 — Android device-transfer assumptions exceed the manifest's guarantee

**Severity:** MAJOR.  
**Evidence status:** source configuration plus official platform documentation; no transfer reproduced.

**Exact evidence.** AndroidManifest.xml:42–55 sets allowBackup=false and states that no data-extraction rules are needed because Android 12 device transfer is also disabled. No dataExtractionRules declaration was found. Android documents manufacturer-dependent cases where false disables cloud backup but not device-to-device transfer. [E2]

**Expected.** The configured backup/transfer behavior should support the promised device-local storage and restoration limits.

**Actual.** The manifest's blanket conclusion is not valid across Android manufacturers. The local journal and ownership/preferences storage is not explicitly excluded through the separate transfer rules.

**Reproduction to execute.** Build the final signed artifact, inspect its merged manifest and perform supported backup/restore and device-transfer tests across relevant Android versions/manufacturers. This audit has not demonstrated that any user's data was transferred.

**Consequence.** Data could move or remain restorable in ways the product says cannot happen. This is especially relevant to deletion and device-local assurances.

**Smallest correction.** Add appropriate explicit backup and device-transfer exclusions for sensitive local stores, retain allowBackup=false as applicable, and align the wording with behavior actually verified on the release artifact.

**Timing:** before public release. This is not, on its own, a reason to prohibit a properly scoped internal engineering test.

### A2-08 — I1's date range and denominator can refer to different records

**Severity:** MINOR.  
**Evidence status:** code-derived arithmetic/copy mismatch.

**Exact evidence.** insight_engine.dart:267–283 counts all Circles in a 28-day window as the denominator, but uses the first and last date of only the winning need. insight_copy.dart:20–21 combines them as one sentence.

**Expected / actual.** The dates should delimit the record set used by the denominator. Currently, other needs before/after the selected need's date span are counted without being covered by that span.

**Concrete fixture to execute.** Within 28 days, put five Energy Circles on days 5, 8, 12, 16 and 19; put five other-need Circles on days 1, 2, 22, 26 and 28, split three/two across the other needs. The top need and pattern gate qualify. The generated claim uses 5 of 10 but dates 5–19, although only five of those records lie in that interval.

**Consequence.** A small but real evidence-honesty error.

**Smallest correction.** Use the entire denominator window's actual date span, or reword the statement to identify the two scopes separately. Keep comparator evidence inspectable.

**Timing:** before public release.

### A2-09 — A malformed local date survives parsing and can break Insights

**Severity:** MINOR.  
**Evidence status:** code-derived malformed-input failure, not an observed corruption event.

**Exact evidence.** circle_journal.dart:486–503 checks localDate is a String, not a valid canonical date. insight_engine.dart:189–218 splits it and uses unchecked int.parse and component indexing.

**Expected / actual.** One malformed journal entry should be isolated. A record with otherwise valid fields and localDate equal to “bad” passes the first check and can throw during Insight evaluation.

**Reproduction/test gap.** Load a supported-schema journal containing one such record among valid entries; open Insights. Current parser tests that reject missing fields do not establish downstream date safety.

**Consequence.** A local data-format problem can affect a whole feature instead of one record. No attack or production corruption rate is asserted.

**Smallest correction.** Validate canonical calendar dates at the storage boundary and preserve/isolate unreadable data appropriately; do not silently normalize impossible dates into valid evidence.

**Timing:** before public release.

### A2-10 — “Material variety” counts possible roles instead of actual roles

**Severity:** MINOR.  
**Evidence status:** source-verified metric definition; independently executed recalculation.

**Exact evidence.** d2_review_pack_test.dart:47–65 and b8_product_simulation_test.dart:573–578 include every part whose definition supports main OR second. circle_elements.dart:522–575 gives lookFar second/settle roles and neckAndShoulders arrive/second roles. The production partRole function in circle_composer.dart:263–279 determines their actual role in a specific session.

**Expected.** A metric described as ignoring different arrivals and closes should exclude parts acting as arrival or close.

**Actual.** A neckAndShoulders arrival or lookFar close can create a different “material” key. For example, an arrival and settlement around the same substantive quietMusic/readPages pair can alter the published key without altering that pair.

**Executed check.** Independent enumeration matched all original shape and material counts, then substituted actual-role classification. Clearer Head/20 fell from 355 published combinations to 122; Gentler Pace/30 fell from 151 to 49. More Energy/10 remained 19. The exact results are in §5.1. The four year traces were also recounted.

**Consequence.** Some evidence overstates substantive breadth. This does not show that composition is invalid or that users dislike repetition. Even the corrected metric is not perceptual validation.

**Smallest correction.** Use actual main/second roles consistently, regenerate affected evidence and call the result structural variety. Do not use either number as proof of renewal value.

**Timing:** before relying on the metrics in acceptance or commercial claims.

### A2-11 — A continuously foreground app retains yesterday's day

**Severity:** MINOR.  
**Evidence status:** source-verified known limitation; not independently reproduced on a device.

**Exact evidence.** clock_provider.dart:7–17 caches DateTime.now per provider lifetime. thirty_app.dart:63–65 invalidates it on resumed. recommendation_provider.dart:560–564 explicitly acknowledges continuous foreground use across midnight.

**Expected / actual.** A new local day should permit a new daily decision. Without a resume or other explicit invalidation, the old day remains authoritative.

**Reproduction to execute.** Keep the app foreground across local midnight, with yesterday's Circle closed, and try to begin today without backgrounding it. Repeat with a session in progress and a time-zone change.

**Consequence.** A bounded late-night journey fails; background/foreground is a workaround.

**Smallest correction.** Recheck the local day at relevant user actions or an equally bounded lifecycle point. Explicitly define how an active session keeps its original identity; do not force-close or count it twice.

**Timing:** before public release; lower priority than billing, ownership and deletion.

## 7. Top priorities

### Five necessary actions

1. **Repair the billing entry path and paid-day timing (A2-01, A2-02).** Verify empty CustomerInfo, delayed activation, same-day purchase/restore and a clean real Play customer. This is the shortest path to a reviewable paid product.
2. **Make persistence and Delete history coherent under interruption (A2-04).** Test controlled delayed writes and restart boundaries, not just settled normal use.
3. **Make kept ownership resilient and honor Keep everywhere (A2-03, A2-05).** Preserve old content across catalogue changes and implement the already-promised I4 exception.
4. **Align privacy promises with actual data behavior (A2-06, A2-07).** Correct analytics disclosure before measurement; complete transfer exclusions and final-artifact verification before public release.
5. **Correct the acceptance evidence and then test the recurring job (A2-10, R-01, R-02).** Use actual-role variety and clearly labeled substitution analysis. Validate month-two paid value, without weakening Free or kept ownership.

The I1 range, malformed-date handling and foreground-day issue are bounded corrections before public release. They should not displace the higher-impact work.

### Optional improvements, only if evidence supports them

- Improve paid-value explanation if observed first-use sessions show confusion.
- Add a voice preview only if it materially helps people evaluate guidance.
- Deepen the specific content area that users find inadequate, after safety review.
- Simplify secondary information placement if Free users cannot find their history.

No new social system, streaks, points, collection mechanic, general AI layer, large content quota or routine-hostage paywall is recommended. These are not solutions to the defects or unknowns identified here.

## 8. Audit method and evidence index

### 8.1 Independent calculations

**Repository integrity.** The 937 included blobs were compared to the exact Git tree. The final pre-delivery repeat again found **937 matches, zero mismatches and zero added source files**. The audited snapshot remained unchanged.

**Catalogue enumeration.** Python extracted all 38 CircleElement definitions and their need, role, length, kind, setting and dependency metadata. It enumerated optional arrival → main → optional second → optional settle combinations under the source's baseline quality limits. Every published nine-cell shape count was matched, as was the original role-metadata metric. Actual session-role counting then produced the alternative counts. This is an independent calculation of the inspected rules, not an execution of Dart and not a replacement for production tests.

**Trace reanalysis.** The committed B8 daily text traces and Insight JSON logs were parsed. Ordinary families were separated from Plan reviews. Calendar weeks were seven-day blocks from the simulation's 5 January start, including the partial 53rd week. The recalculation matched the reported ordinary counts. Actual-role variety and first substantive-repeat days were calculated separately.

**Substitution counterfactual.** Collections were selected from the first 30 offers in the committed lapse profile. Later days retained the script's need and window. Coverage checked only need equality and stored minutes ≤ available minutes. No claim was made that the longer-run application would produce identical history under a changed subscription schedule.

**Audio.** Folder inventory, common-manifest availability and ffprobe container duration were checked. All 172 files were readable with positive durations, and all 172 matched the committed production SHA-1 list. The clips were not auditioned as part of this audit.

**Economics.** All rates other than the identified public pricing/fee references were explicitly hypothetical. Revenue and churn sensitivity is not a demand forecast.

### 8.2 Primary repository references

All repository links below are pinned to the audited SHA. Numeric line references throughout the findings identify the relevant functions; they are not references to a moving branch.

- [Product contract][contract] and [delivery tracker][tracker].
- [ADR-023: Personal Guided Circle][adr23] and [ADR-024: Plans, Insights and four tabs][adr24].
- [Brand Book][brand], [Design System][design] and [World System][world].
- [Recommendation engine][engine], [composer][composer], [StageBrief implementation][brief] and [Plan state/engine][plans].
- [Insight engine][insights] and [Insight application service][apply].
- [B8 simulation source][b8], [committed simulation summary][b8summary] and [coverage artifact][coverage].
- [B9 closure candidate][closure], including its claimed tests, device evidence and remaining release safety gate.
- [Gateway tests][gatewaytests] and [B7 entitlement matrix][matrix].

### 8.3 External primary sources

Checked on 21 October 2026. These support platform/SDK semantics and current public alternatives, not claims about THIRTY's measured customer behavior.

- **E1 — RevenueCat, CustomerInfo and subscription status:** [official documentation](https://www.revenuecat.com/docs/customers/customer-info). Empty customer entitlement data before purchase/sync; SDK cache and outbound-refresh behavior.
- **E2 — Android, Auto Backup:** [official documentation](https://developer.android.com/identity/data/autobackup). Manufacturer-dependent device-transfer behavior with allowBackup=false; extraction rules for newer targets.
- **E3 — Google Play, Service fees:** [official fee schedule](https://support.google.com/googleplay/android-developer/answer/112622?hl=en). Current subscription fee structure and regional rollout distinctions.
- **E4 — RevenueCat pricing:** [official pricing](https://www.revenuecat.com/pricing) and [billing definitions](https://www.revenuecat.com/docs/welcome/set-up-revenuecat/account-management). Threshold, tracked-revenue pricing and gross-revenue basis.
- **E5 — Insight Timer free offering:** [official support](https://help.insighttimer.com/support/solutions/articles/67000664579-how-much-does-insight-timer-cost-).
- **E6 — Insight Timer Member Plus:** [official product page](https://insighttimer.com/member-plus). US$60 annual offer at the time checked; not a localized euro quotation.
- **E7 — Headspace access model:** [official free-access explanation](https://help.headspace.com/hc/en-us/articles/115008192928-What-s-included-for-free) and [subscription instructions](https://help.headspace.com/hc/en-us/articles/215035998-How-do-I-purchase-a-subscription). No Headspace price estimate is used.

## 9. Independent audit decision

| Dimension | Decision | Reason |
|---|---|---|
| **Technical acceptance** | **FAIL** | Billing acquisition fails for normal empty CustomerInfo; paid initialization, persistence and ownership compatibility need correction |
| **Product acceptance** | **CONDITIONAL** | Core promise and calm daily model are coherent; actual usefulness and comprehension remain to be demonstrated |
| **Free/Premium acceptance** | **CONDITIONAL — current implementation not accepted** | Broad boundary is fair, but I4 Keep and paid-day delivery violate promised behavior |
| **Commercial viability** | **UNPROVEN / CONDITIONAL** | Plausible low serving cost and a real convenience job; no demonstrated sustainable paying demand, and strong kept substitution |
| **Safety/privacy acceptance** | **CONDITIONAL — public release not accepted** | Safety isolation exists; bounded safety review, accurate analytics disclosure and Android transfer validation remain necessary |
| **D2 independent audit gate** | **FAIL** | A material blocker exists at the immutable closure SHA |
| **Phase E readiness** | **HOLD** | Correct material findings, verify a new immutable candidate and repeat the independent gate under the project's rules |

This is a rejection of acceptance for this version, not a conclusion that THIRTY cannot become a useful product or sustainable business. The source supports continuing with bounded corrections. It does not support calling the commercial problem solved or beginning Phase E under the current gate.

The tracker states that a material blocker from either independent audit requires both audits to restart on a new immutable SHA. This report does not modify the target, perform those corrections or authorize that next phase.

**Required founder decisions**

1. Confirm the desired same-day behavior when verified Premium arrives after an unstarted Free offer, preserving the one-Circle rule and started/owned choices.
2. Require catalogue-compatible preservation of kept content, including safe retention of unreadable/retired material; this is fulfillment of ownership, not a new product feature.
3. Resolve the conflicting general Insight-application wording in favor of the explicit never-gated Keep guarantee.
4. Approve accurate analytics categories and retention/deletion scope before external measurement.
5. After repairs and a fresh positive audit gate, decide whether the existing recurring-service hypothesis merits a bounded paid validation at €5–7, with success/stop criteria defined before results are seen.

[contract]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/docs/product/PRODUCT_V2_CONTRACT.md
[contractkeep]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/docs/product/PRODUCT_V2_CONTRACT.md#L395-L404
[tracker]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/docs/product/THIRTY_V2_DELIVERY_TRACKER.md
[adr23]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/docs/product/adr/ADR-023-v2-recurring-premium-personal-guided-circle.md
[adr24]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/docs/product/adr/ADR-024-v2-circle-plans-insights-and-four-tab-product.md
[brand]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/docs/BRAND_BOOK.md
[design]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/docs/DESIGN_SYSTEM.md
[world]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/docs/worlds/WORLD_SYSTEM.md
[gateway]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/core/premium/revenue_cat_entitlement_gateway.dart#L64-L77
[paywall]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/features/premium/presentation/premium_offer_page.dart#L197-L213
[startup]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/main.dart#L71-L95
[premiumstate]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/core/premium/premium_access.dart#L29-L64
[choice]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/features/home/application/recommendation_provider.dart#L730-L819
[queue]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/features/home/application/recommendation_provider.dart#L565-L574
[persistchoice]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/features/home/application/recommendation_provider.dart#L1494-L1546
[delete]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/features/home/presentation/widgets/journal_data_controls.dart#L128-L160
[kept]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/features/personal_circle/domain/kept_circle.dart#L45-L103
[wire]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/features/personal_circle/domain/circle_elements.dart#L772-L877
[keptrepo]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/features/personal_circle/application/kept_circles_provider.dart#L29-L47
[apply]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/features/insights/application/insights_provider.dart#L130-L217
[datacopy]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/features/settings/presentation/widgets/you_data_card.dart#L92-L101
[telemetry]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/features/home/application/recommendation_provider.dart#L1256-L1289
[analytics]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/core/analytics/analytics_service.dart#L32-L103
[manifest]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/android/app/src/main/AndroidManifest.xml#L42-L55
[i1]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/features/insights/domain/insight_engine.dart#L266-L295
[i1copy]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/features/insights/domain/insight_copy.dart#L13-L21
[journalparse]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/features/home/application/circle_journal.dart#L486-L503
[dateparse]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/features/insights/domain/insight_engine.dart#L189-L218
[covermetric]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/test/features/personal_circle/d2_review_pack_test.dart#L37-L66
[b8metric]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/test/features/b8/b8_product_simulation_test.dart#L565-L578
[clock]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/core/providers/clock_provider.dart#L7-L26
[appresume]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/core/app/thirty_app.dart#L63-L80
[engine]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/features/home/domain/recommendation_engine.dart
[composer]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/features/personal_circle/domain/circle_composer.dart
[brief]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/features/personal_circle/domain/stage_brief.dart#L456-L576
[plans]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/features/plans/domain/circle_plan.dart
[insights]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/lib/features/insights/domain/insight_engine.dart
[b8]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/test/features/b8/b8_product_simulation_test.dart
[b8summary]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/artifacts/v2_phase_d2/b8/simulations/summary.json
[coverage]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/artifacts/v2_phase_d2/ELEMENT_COVERAGE.md
[closure]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/artifacts/v2_phase_d2/b9/D2_CLOSURE_CANDIDATE.md
[gatewaytests]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/test/core/premium/entitlement_gateway_test.dart#L49-L118
[matrix]: https://github.com/thirtyapp/Thirty/blob/8bfd42c16693b8f5040ebcf4761db0e9c439981c/test/features/premium/b7_entitlement_matrix_test.dart#L149-L157

**FINAL VERDICT: FAIL**

**PHASE E: HOLD**

**REQUIRED FOUNDER DECISIONS: same-day paid activation behavior; durable kept-content preservation; explicit ungated I4 Keep exception; truthful analytics and retention/deletion scope; bounded paid-demand validation only after corrections and a fresh positive audit gate.**



