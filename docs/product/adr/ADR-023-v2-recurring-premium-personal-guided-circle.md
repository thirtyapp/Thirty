# ADR-023 — V2 Recurring Premium / Personal Guided Circle

**Status:** Proposed.
- **History:** Phase D2 was implemented and S25-verified on 2026-10-11 (device QA and live TalkBack; `artifacts/v2_phase_d2/DEVICE_QA.md`). The founder correction pass followed the same day. The final hardening pass on 2026-10-12 added the last two copy fixes, the content freeze, Android background playback (S25-verified, including screen off and locked), and a review-only voice audition.
- **What Accepted still needs:** founder approval of the production voice, and all 42 production clips bundled and QA'd (§6). Without them, Phase D2 is not complete.

Product authority: [PRODUCT_V2_CONTRACT.md](../PRODUCT_V2_CONTRACT.md), as amended on 2026-10-11 ("Amendment — Recurring Premium (Phase D2)"). This ADR **supersedes the conflicting Premium portions of [ADR-022](ADR-022-v2-phase-d-paths-toolkit-and-maintenance.md)**: Premium's headline job, what Today does for a Premium user, the offer page, and the three defects in §10. ADR-022 stays the historical record of Phase D as built and accepted on 2026-10-10. Free V2 stays governed by the contract and ADR-020/021. Review pack: `artifacts/v2_phase_d2/`.

## Context

The post-V2 audits at d89a035 (`docs/audits/`) judged Phase D's Premium a weak fit for monthly recurring revenue. It sells a durable routine at a service price: the rational pattern is to subscribe, build two or three routines, keep them (as designed), and cancel. The founder decided on 2026-10-11:

- THIRTY must be able to support legitimate **monthly** recurring revenue. Lifetime or one-time Premium is not the target.
- The recurring job becomes the **Personal Guided Circle**: *"THIRTY turns the time I have today into a personal guided Circle built from what has worked for me, then guides me through it."*
- Build the strongest bounded version now. Validate the complete product with Google Play pre-release users after Phase E. There is no external validation round before implementation, so product–market fit is unproven and is labelled so.

## Decisions

1. **Two jobs, one Circle a day.**
   - **Free** chooses **one** good activity for today's need and time. Engine V2 is unchanged in capability.
   - **Premium** **creates and guides one coherent personal session** for today's need and time, made of a few small authored elements.
   - The Premium output is perishable: today's session is used today, and tomorrow THIRTY does the work again. That daily work is why a monthly charge can be legitimate.
   - Still one primary Circle per local day. The user still states only **need** and **time**: no questionnaire, mood log, planner or dashboard.

2. **The element model** (`personal_circle/domain/circle_elements.dart`). An element is one truthful thing to do for a few minutes, and every field serves runtime behaviour:
   - **Composition fields:** `needs`, `roles` (arrive / main / second / settle), `minutes` and an optional authored `shortMinutes`, `setting`, `effort`, `kind`, `after` and `leadsInto` decide what may be composed, in what order and at what length.
     - `kind`: no Circle holds two of one kind.
     - `after` (the part an element builds on): an element whose words refer to what an earlier part left behind ("Look over what you wrote") is composed only *directly* after that part, and skipping that part skips it too (§7). No part ever refers to something that didn't happen. Today: "Choose one thing" builds on "Get it out", and "Write the first step" on "Choose one thing". Words that only hold at the start ("before you begin") or the very end ("Finish with…") take only that role. All 38 elements were audited for this (correction pass, 2026-10-11); tests hold it for every shape the composer can make.
     - `leadsInto`: e.g. "A comfortable spot" only leads into listening, reading, writing or focus — never a walk, and never a drink that means getting up again.
   - **`from`** ties a piece of a live activity to that activity's safety status, the user's "Don't suggest" for it, and a rest after its "Not useful". `carriesEvidence` says whether the element is materially the same experience, so that the activity's explicit answers count for it; a fragment (a few stretches from a longer sequence) carries none.
   - **Display:** `name` and `instruction` are what the runtime shows, and what the voice says. `art` is presentation only.
   - **Physically compatible with the guide** (correction pass):
     - the phone is the guide, so an instruction may have it face down, in a pocket or silenced — never left behind, out of reach or out of earshot;
     - nothing asks the user to close anything that could lose unsaved work ("Minimise…", not "Close…");
     - no needless intensity ("louder", "quicker than usual", "livelier", "as many as you can");
     - no assumed context: THIRTY knows the need and the time, not the light or the weather. Outdoor parts offer an inside alternative where they can, and "Can't go outside" remains the user's control.
     - Content guards hold all four.
   - **The release library has 38 elements, all live:**
     - 21 are pieces of live Phase A activities (16 carrying their evidence); 17 are new small cues.
     - None breathes, paces or asks for exertion.
     - None comes from `briskStepBurst`, `activeMovementSnack`, `focusedBreathingCount`, `restfulBreathingPause` or the retired `energisingBreathReset`.
     - `isElementOfferable` is a hard limit, and tests hold all of this.
   - **Stable identity:** stored ids (`getItOut:4`) are stable; a made-up length never restores.
   - **No padding:** the library is not padded to a number. More Energy is the thinnest need, and the coverage report says so (§12).

3. **The composer** (`circle_composer.dart`, tunables in `composer_policy.dart`). It is pure, local and deterministic: it reads no clock, storage or randomness.
   - **Inputs:** need, window, the journal as `PastCircle`s (explicit answers, recency, skips), "Don't suggest", lifted rests, "Leave this out", and today's replacement constraint. It uses no profile, inferred mood, model or cloud.
   - **Hard limits, never relaxed:**
     - safety;
     - need fit;
     - "Leave this out";
     - "Don't suggest" for an element's activity;
     - a rest after "Not useful" on it (lifted by "Suggest again");
     - the window;
     - today's constraint;
     - never yesterday's main piece (consecutive repetition is not composed; Free decides instead).
   - **The quality gate** (`gatePassingShapes`) — Premium never composes merely because the user pays:
     - shape ARRIVE? → MAIN → SECOND? → SETTLE?, at least two parts;
     - at most four parts, or three on a ≈ 10-minute day;
     - the main piece holds ≥ 40 % of the minutes, and a second piece is never longer than the main;
     - no element or kind twice; `after` and `leadsInto` respected; outside never mixed with inside-only;
     - the whole fits the window and uses ≥ 60 % of it.
     - With nothing passing, the answer is `null` and Today is Free's activity (§4).
   - **Time use.** The composer aims for ≥ 80 % of the window when a coherent session exists.
     - Below that, a cost grows with what is left unused: 12 of 20 minutes costs about as much as a clearly better-liked main piece is worth, so a short session must earn its place.
     - It is still never stronger than content quality: an honest 17 of 20 minutes beats a padded 20, and parts are never stretched, repeated or invented to fill time.
   - **Ranking: relevant before varied.**
     - **Evidence:** an element's evidence is the *confidence-weighted mean* of its explicit answers, from −2 to 2 (`ElementStanding.evidence`): a mean, so how often a part was offered never compounds into how much it is liked. It counts ×3 — the main piece ×1.5, other parts ×0.5. A session is relevant when it holds something the user values, not when it stacks everything they value every day.
     - **Exploration:** a main piece not composed as the main for this need in 30 days earns a modest bonus — the composer's version of Free's honest exploration, never enough to beat clear evidence.
     - Then: time use, a settling close, an arrival, a second piece on longer days. Full lengths beat shorter forms.
     - Recency costs:
       - parts composed in the last 2 days;
       - a main piece offered twice in 7 days (excluded as main that week);
       - a part composed three times in 7 days (rests that week);
       - the identical element set within 7 days (not composed again) — these three relax only if nothing else passes;
       - the same main + second pair within 7 days;
       - the same element set within 14 days;
       - the same first or last part as last time;
       - a part whose activity was declined with "Not this one today" in the last 3 days.
     - Ties break on a date-seeded hash.
     - A part the user found very useful keeps its place; variety only chooses among sessions the evidence rates alike.
   - **What the one line may say** (`CompositionBasis`). "Built from things you've found useful, to fit your 20 minutes." appears only when a part has positive evidence for this need — including a "Very useful" answer — above the usefulness threshold. Otherwise: "Small parts, one after another, to fit your 20 minutes." Sparse evidence stays neutral.

4. **Today: precedence and fallback** (`recommendation_provider.dart`). With Premium, in order:
   1. a Path step that claims today (ADR-022, unchanged);
   2. else the user's own routine, when Free's choice is a routine with positive evidence for this need — Premium never crowds out what the user built and found useful, and routines keep exactly Free's frequency (no bonus either way);
   3. else today's Personal Guided Circle;
   4. else Free's activity, with the plain line "Today, one activity fits better than a mix."
   - Free is unchanged.
   - "Not this one today" on a composed Circle recomposes once under the constraint:
     - "Can't go outside": nothing outside;
     - "Too much": low effort and shorter;
     - "Not feeling it": another main piece of another kind.
     - Only if nothing honest fits does the engine pick one activity.
   - A composed Circle is persisted whole (`recommendation_composed`) and restored exactly, never recomposed.

5. **The guided composed runtime** (Phase C's shell; `SessionBody.composed`).
   - One part at a time, each for its authored time. THIRTY holds the structure: when a part's time is up the next one begins by itself.
   - `partMomentFor` derives the part on show purely from the anchor (`recommendation_guided_position` + `recommendation_part_anchor_ms`) and the active elapsed time. A resume or restart lands exactly there.
   - **Controls:**
     - Next and Back (re-anchor);
     - Pause and Resume (Phase C);
     - Skip (§7).
   - **Heading:** the part's name, then "Part 2 of 4 · next: Get it out" or "· the last part" — context, never a countdown.
   - **The finish:** past the last part, "To finish" and the composed ending, and Close leads. The ring still shows the time set aside; nothing claims a part was done.
   - **Accessibility:**
     - the part text is one TalkBack stop and a live region, so a part that begins by itself is announced. On the S25 (2026-10-12) TalkBack spoke it at one timed change; at another, right after TalkBack had restarted, no speech was logged. A live founder listen is part of the voice QA, and an explicit announcement per part is the fix if it recurs;
     - every control is ≥ 48 pt;
     - reduced motion swaps parts without movement;
     - no overflow at 130 % or at 200 % on a 320 pt screen (tested).
   - **Auto-advance rule** (reviewed in the correction pass): a part runs for its authored time, then the next begins by itself — for every kind of part, with no per-kind exceptions. This is safe for writing, tidying, walking and reading too, because:
     - the runtime holds no user input (writing is on paper), so moving on never loses anything;
     - Next and Pause stay on every running part, and while paused nothing moves on;
     - the change is perceptible without the screen: a live TalkBack announcement, and the voice's lead ("Next." / "And last.") once the recordings ship (§6);
     - a part's time includes its natural finish (a walk's time includes the way back; "Stay with it until the time's up — finished or not").
   - The how-to sheet lists the parts with their times and says how the Circle runs.
   - Today's card shows "YOUR CIRCLE · 16 MIN", the need, and the session's substance — its main and second piece ("Clear one corner · Get it out"), guarded to two lines so Start Circle keeps its place on the S25. It opens "See the parts", where every part is listed with its time. The card carries the one basis line, without the decorative art: the text needs the full width. History shows every part.

6. **Spoken guidance: bundled pre-generated recordings** (founder decision, 2026-10-11; architecture approved 2026-10-12; `domain/spoken_cues.dart`, `application/guidance_voice.dart`, `application/guidance_conductor.dart`, `application/guidance_session.dart`, Android `GuidanceAudio.kt` and `GuidanceService.kt`).
   - **Decision:** fixed, high-quality recordings bundled with the app. No runtime generative AI, no voice API or other recurring cost, and no device text-to-speech as the intended Premium experience.
   - **Deterministic lookup:** when a part begins, the voice plays a lead — "First." for the first part, "And last." for the last, otherwise "Next." — then that element's own clip: its name and instruction, exactly the words on the screen. After the last part it plays the close ("That's your Circle…"). `spokenGuidanceManifest` is the complete recording list: 3 leads, 1 clip per offerable element and the close (42). It is exported as `SPOKEN_GUIDANCE_MANIFEST.csv`, the recording source of truth (regenerated 2026-10-12).
   - **Never stale:** each clip's file name carries a fingerprint of its script (`part_getItOut_<fnv32>.m4a`), so changing an instruction makes its clip missing.
   - **All or nothing:** the voice is available only when every manifest clip is bundled. A partial set is silent, never patchy. This is checked once at start-up (`spokenGuidanceBundled`, overridden into `spokenGuidanceAvailableProvider` by `main.dart` and the QA harness).
   - **Who decides what is said: `GuidanceConductor`** (final hardening, 2026-10-12). One application-level conductor, kept alive by `main.dart`, speaks a running composed Circle. It replaces the voice code in Today's widget, so the voice never depends on which screen is built, or on the UI being in front.
     - **It keeps no time of its own.** Every second while a voiced Circle runs, it reads the part on show from the Circle's stored facts and the wall clock (`partMomentAt`).
     - A cue is due exactly when a part begins, however long THIRTY was out of sight, and a return or a restart lands on the right part.
     - **Each part is spoken once.** Lifecycle changes, returns and rebuilds never repeat a cue.
     - **Never on a first look** into a Circle already under way, and never the ending on a first look past the last part.
     - **Nothing while paused.** It stops at Pause and Close; resuming the same part says nothing new.
     - **Defect found and fixed:** before this pass, a Circle's first part was never spoken at Start, because the voice had already "seen" part 1 before Start. "First." now plays at Start (tested, and S25-verified).
   - **Android background playback** (founder decision E, 2026-10-12; `GuidanceService.kt`).
     - **Service lifecycle:**
       - **Architecture:** while a voiced Circle runs, THIRTY runs a **foreground service of type `mediaPlayback`** holding a **partial wake lock**. Android then neither freezes THIRTY (the S25's cached-app freezer froze it within a minute of switching apps) nor sleeps the CPU between cues.
       - **Timeout:** the wake lock is held with a timeout of the Circle's remaining time plus one minute, refreshed at each part. It is released while paused and when the session ends.
       - **Start:** only from THIRTY in front, after the user's Start (or on reopening a voiced Circle under way).
       - **End:** after the ending has been spoken (it waits for the voice to fall idle, at most 30 s), at Close, when the voice is turned off, when Flutter goes away, or when THIRTY is removed from Recents (`stopWithTask`).
       - **Scope:** `START_NOT_STICKY`. No permanent service, no tracking, no data, no other work.
     - **Why not Media3 / MediaSessionService:**
       - **A session takes the media buttons:** a media session would become the target of headset and lock-screen media buttons after each cue. During "Move to music" or "Listen to one thing" the user's own player would lose its play/pause buttons to THIRTY — exactly the hijacking the founder brief rules out.
       - **Wrong model:** a Circle is a timed sequence of short cues with long silences, not a seekable media item.
       - **No new dependency:** the platform service needs none.
       - **The cost:** the notification shows as an ordinary notification, not in Samsung's media "Now Bar".
     - **Notification:** the notification Android requires for the service, on a low-importance channel named "Spoken guidance".
       - **Content:** "Circle running" or "Circle paused", the name of the part on show, and **Pause/Resume** and **Next**. Tapping it opens THIRTY.
       - **What it never shows:** no score, progress or congratulation.
       - **Not Close:** closing is a confirmed, irreversible step taken in THIRTY.
       - **Not "stop voice":** Pause silences at once, and the switch is in You.
       - **The controls do exactly what the Circle's own controls do:** Next moves one part, and the skip and journal semantics are unchanged.
       - **Without notification permission:** Android still runs the service, so the voice continues, but the controls are hidden. THIRTY asks for no new permission.
     - **Timing ownership:** Dart, from stored facts, as above. The service plays and times nothing.
     - **Back at the first screen:**
       - **The defect:** it used to finish the activity — Flutter's default, and on Android 16 the platform's default finish callback — which ended Flutter and the voiced Circle with it.
       - **The fix:** Back at the root now moves THIRTY to the background, as Android 12+ does for launcher apps. Flutter's own back callback stays on top whenever there is something in THIRTY to go back to (S25-verified: sheets and pushed pages unchanged).
   - **Offline playback** goes through a small platform player over a method channel (`com.thirty.app/guidance_audio`). On Android it plays Flutter assets with **transient, duckable audio focus** (`USAGE_ASSISTANCE_NAVIGATION_GUIDANCE`, `CONTENT_TYPE_SPEECH`).
     - **S25-verified with Chrome playing media:** Chrome received `LOSS_TRANSIENT_CAN_DUCK` at the cue and `GAIN` when it ended, and kept playing throughout. Nothing is paused or taken over.
     - **Spoken content:** a podcast-type player may choose to pause during a cue, as Android's focus rules intend for speech.
     - Without a player (iOS today) or a playable clip, the voice is silent, never an error.
   - **Accessibility stays independent:** the visual runtime and its live TalkBack announcements are complete without audio.
     - **In front, with a screen reader on:** the live announcement speaks and the voice stays silent — never two voices at once.
     - **Out of sight:** the voice speaks, because nothing is on screen to announce.
     - **How it decides:** the platform player checks the screen reader itself (Android: touch exploration). Flutter's `accessibleNavigation` is not used: on the S25 it was true with TalkBack off, because an unrelated accessibility service (a cleaner app) was enabled.
   - **User control:** You → Preferences → "Spoken guidance", on by default, shown only in a build that bundles the recordings. Turning it off ends the background session.
   - **Owned Circles keep their voice:** a kept Circle used on Free ("Use it today") runs on the same guided runtime and is voiced too (S25-verified). This follows from ownership, and it is part of the substitution hypothesis (Consequences).
   - **State on 2026-10-12:** the architecture, background playback, manifest and tests are complete, but **no production recording exists**. The build bundles none, so the voice is silent.
     - **Audition:** a review-only audition — 3 candidate voices × 5 representative clips, generated once through the vidIQ voiceover tool (ElevenLabs premade voices) — is in `artifacts/v2_phase_d2/voice_audition/`. It is not bundled.
     - **Founder gate:** the production voice, its licence and every clip remain a gate (`final_audit/VOICE_PRODUCTION_REQUIREMENTS.md`).

7. **Element controls and evidence boundaries.**
   - **"Skip this step"** (Skip → sheet: "Skip it for today" / "Leave it out next time" / "Keep going"):
     - records the skipped element on the day's journal session (`skipped`) as a fact;
     - the parts that build on it (`after`) are skipped with it and recorded as skipped too; the sheet names them;
     - the next part begins;
     - a skip is never a usefulness answer: it only keeps that part from sharing the day's positive answer, and never counts against it.
   - **"Leave it out next time":**
     - an explicit preference (`elementsLeftOut` in suggestion preferences), for every need;
     - a hard limit for the composer;
     - shown in Memory under "Left out of your Circles" with "Put it back";
     - survives Delete Circle history (like "Don't suggest") and is cleared by "Reset suggestion preferences".
   - **A composed Circle's answer:**
     - composite: never evidence about an activity, and never a rest on one;
     - it counts at half weight for the session's *substance* only — its main and second piece, unskipped — for that need only;
     - an arrival or a close never takes credit for a day's answer.
   - **A routine:** its positive answers count at half weight for the elements of its pieces' activities. Its "Not useful" never does (it may be about the combination, ADR-022 §5).
   - Evidence never crosses needs.

8. **Ownership and lapse.**
   - **"Use it today"** (`useOwnedToday`; on a routine's page and a kept Circle's page) — Free:
     - only before today's Circle starts; still one Circle a day, replacing today's not-started choice;
     - today's need stays the one chosen (before any choice, the routine's own);
     - today's time picks the routine version that fits (the shorter version on a shorter day), else the active one;
     - it is the user's choice, not a decline: nothing is recorded as replaced, and no replacement is offered after it;
     - never a list on Home.
   - **"Keep this Circle"** (one quiet row below the Circle after Close):
     - keeps today's composed Circle as the user's own (`KeptCircle`, at most 8);
     - never gated; kept once per day;
     - named by need until renamed;
     - THIRTY never offers a kept Circle unasked;
     - its page has "Use it today", Rename and Remove;
     - stored additively in the Toolkit record (schema unchanged); export includes it.
   - **On lapse the user keeps:** routines, versions, names, kept Circles, History, Memory, preferences, export and delete, ordinary Free Today, and "Use it today".
   - **The user loses:** new Personal Guided Circle composition. Today is Free's one activity again.
   - **The offer says this:** "After that, Today goes back to one good thing a day, and everything you kept stays yours."
   - Resubscribing restores composition at once (tested in the provider tests and simulation p10).

9. **Paths, Toolkit and maintenance, repositioned.**
   - **Paths** stay: discovery, calibration, building a routine you keep.
     - The first-Path card reads "Build a routine — if you like · Optional: your Circle on Today doesn't need it."
     - A new Premium user gets the Personal Guided Circle on day one, from whatever Free evidence exists.
     - Path length stays 7 Circles: nothing in D2 depends on it.
   - **The Toolkit** ("Routines and Circles that are yours.") holds what the user owns — routines, then "Circles you kept" — with the one maintenance offer or check. It is supporting, never an administration dashboard.
   - **Maintenance review — no new trigger was added:**
     - **Time misfit and fading** stay. They read owned use (Free picks after lapse, "Use it today", proven-routine days). The composer already handles daily time fit on Premium days, so misfit offers become rarer — by design, not by suppression.
     - **The gap** reads only Free's own picks, never composed, routine or Path answers. On Premium days the composer is doing the daily work, so the gap goes quiet then; it can still fire from Free days (before subscribing, or during a lapse).
     - **Tune, Shorter** and the **"nothing to change"** check stay.

10. **Truth fixes carried from the audits.**
    - **The hidden routine rest** (`pastCirclesFrom`, `RecommendationMemory._aboutRoutine`):
      - a Path Circle of a kept routine's pieces is that routine's *trial* (`PastCircle.builtRoutineId`), never its use (`routineId`);
      - keeping a routine is the user's own answer to its trial: positive trial answers stand as its first evidence, and a negative one is superseded by the decision to keep, so it never rests or down-ranks the routine;
      - a rest comes only from real use; the routine's standing ("it used to suit") still reads the trial;
      - history and export are unchanged.
      - Tested: `hidden_routine_rest_test.dart`.
    - **The Toolkit check** names only the routines its answers cover: "My reset is working well. Still learning how the others fit." It says "Your routines are working well — nothing to change." only when every routine has answers behind it.
    - **The time misfit** says exactly what was seen: "On 4 of your last 6 Clearer Head days, you had less than the 30 minutes My reset takes." The offer reads "for days with about 20 minutes".
    - **Fading** reads "Your recent answers about My reset have been less positive than before."
    - **The gap** reads "You chose Clearer Head on 6 of the last 28 days, …".

11. **Offer and billing boundary.**
    - The offer, the Home invitation and You's Premium card lead with the recurring job:
      - "A Circle made for your day";
      - points: Made each day · Guided through · Shaped by your answers · Yours to keep.
    - **Offer truth** (correction pass): the offer is true on a subscriber's first day.
      - It says the guided Circle exists from day one, that answers can shape later Circles, and that what is left out stays out.
      - It never says THIRTY already knows what the user found useful. Only Today's own line says "Built from things you've found useful", and only with evidence.
      - Free is described in consumer words ("With Free, THIRTY still gives you one good thing for today"), never as "Free stays complete".
      - A content guard holds this.
    - Routines are a supporting benefit; "Upkeep" is no reason to subscribe.
    - No efficacy claim.
    - Billing stays the existing monthly auto-renewing subscription, with no lifetime product. No price is hard-coded in domain logic; live pricing is a Phase E decision. All copy is a draft for founder review.

12. **QA, internal simulations, content review.**
    - **Tests:**
      - `personal_circle/*` — the element library, composer, Premium Today through the providers, the composed UI with TalkBack labels, enlarged text and reduced motion, the review pack, and the long-horizon simulations;
      - the hidden-rest regression;
      - maintenance truth tests.
    - **QA scenarios** D2-A first Premium Today, D2-B a month of Circles, D2-C composed Circle running, D2-D lapsed with kept Circle and routine, D2-E back on Premium.
    - **Phase D's 14 eight-week simulations** now run under D2 semantics: routine days via "Use it today" or proven-routine days; gap evidence only from Free days.
    - **Correction-pass attacks:**
      - `p14_more_energy_dominant`: More Energy on most days, mixed times, explicit positive and negative answers;
      - the saved-Circle / lapse attack (`saved_circle_lapse_attack_test.dart`): keep up to the limit, use, lapse, keep using, resubscribe.
    - **13 long-horizon INTERNAL simulations** (day 1 → month 12, production providers) report behaviour only: Circles composed, fallbacks, unique and materially distinct sessions, repeat intervals, concentration, edges and time use. They are architectural checks, **not user validation**. Results: `artifacts/v2_phase_d2/SIMULATION_REVIEW.md`.
    - **Coverage report and founder content pack:** `ELEMENT_COVERAGE.md` and `CONTENT_REVIEW.md` (guards for medical claims, diagnosis, guarantees, invented personalisation, guilt, pressure, achievement and unsafe instructions run in the suite).

## Consequences

- Phase D's history, data and Path/Toolkit behaviour are preserved; nothing the user built is migrated away.
- **Content is frozen** after the final hardening pass (2026-10-12). The founder approved the corrected content in principle; the final two fixes and the drift proof are in `CONTENT_REVIEW.md` §0.
- **Open before D2 can pass:** founder approval of a production voice, and all 42 clips produced, bundled and QA'd (§6). The decision and the architecture are approved; the recordings don't exist yet.
- **S25 device QA and live TalkBack passed** after six device findings were fixed (Today card height, Memory showing composite answers, Toolkit order and wording, the running Close clearance, Skip-sheet overflow at 130 %, orphaned words).
- **More Energy is thin**: the thinnest need, with 9 mains against 13–18 for mixed needs (p14, `SIMULATION_REVIEW.md`). The cause is its gated exertion and breathing content. Widening it honestly needs the separate safety review, never invented content.
- **Older source wording** (Free activities, routine modules) still has "a little quicker than usual", "turn it up a little", "livelier" and "out of sight". It is listed for the final release audit (`final_audit/RELEASE_AUDIT_NOTES.md`). It is not an active defect, because none of it is spoken.
- **Every composer value is a hypothesis** (`ComposerPolicy`). Read them against pre-release behaviour.
- **Commercial hypothesis, unproven:** whether a personal guided Circle each day is worth a monthly subscription. No willingness to pay, conversion, retention or acquisition has been measured. The simulations are architectural checks, not user evidence. The €5–€9 range is a hypothesis, not a finding.
- **Commercial hypothesis — substitution (post-D2 audit):** up to 8 kept Circles, used free with "Use it today", can stand in for new composition after a lapse (40 of 60 lapsed days in the attack). Ownership is deliberately not weakened. Whether this erodes the subscription is for the post-D2 audit to judge.
- Phase E stays on hold until Phase D2 passes.
