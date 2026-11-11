# THIRTY PRE-RELEASE PRODUCT GAP REGISTER

## Status

**APPROVED by the founder on 2026-11-11 as planning authority only** (drafted 2026-11-11).

- It records the remaining gaps, their order and the open founder decisions.
- It does **not** amend the product contract. Contract changes, including the six-language amendment and the draft ADRs, still need separate, explicit founder approval.
- It does **not** authorize product development. Each workstream starts only on its own founder authorization.
- Every founder decision in §7 stays **OPEN** until it is decided and recorded.

**Authority and scope:**
- This is the canonical *planning* register for what THIRTY still needs before a full-product Google Play pre-release and a commercial launch.
- **It never overrides** [PRODUCT_V2_CONTRACT.md](PRODUCT_V2_CONTRACT.md), which defines *what* THIRTY is.
- Implementation *status* stays in [THIRTY_V2_DELIVERY_TRACKER.md](THIRTY_V2_DELIVERY_TRACKER.md).
- Where this register proposes a contract change, it says so, and the change takes effect only through a founder-approved amendment or ADR.
- **Supporting record, not a second source of truth:** the founder's memo `THIRTY_PRE_RELEASE_CRITICAL_GAPS_REGISTER_2026-11-11.md`, kept outside the tracked tree.

**Baseline:**

| | |
|---|---|
| Branch | `step5-billing-integration` |
| Accepted implementation | `c83543d5f40294c76532a4710b748d893320d245` (tree `efa19fdc450b079d7d082c791d3ad396ab141477`); L-1 Option B is ENGINEERING ACCEPTED, with a documented independent-runtime limitation |
| R8 engineering baseline | FROZEN at `d9369795a92aa24505c475fa1417d03132300c4a` |
| Phase E | HOLD |
| Commercial release | NOT AUTHORIZED |
| Deployment | NONE |

**Evidence labels:**

| Label | Meaning |
|---|---|
| **FROZEN** | Binding contract text |
| **FOUNDER** | Explicit founder direction that is not yet in the contract |
| **IMPL** | Verified in code at `c83543d5` |
| **RECORD** | Taken from a committed or founder-tree evidence record |
| **EST** | An estimate, with its assumptions stated |
| **PROPOSED** | Needs founder approval |
| **UNKNOWN** | Not established |

---

## 1. Product objective and testing sequence (FOUNDER)

1. Build the complete pre-release product, Free and Premium.
2. Complete genuine onboarding.
3. Complete all six launch languages: English, French, Dutch, Spanish (es-ES), German, Italian.
4. Complete the approved multilingual Premium voice experience.
5. Prepare the commercial systems, safety, privacy and measurement.
6. Test the **complete** product through Google Play.
7. Resolve the release blockers that testing demonstrates.
8. Launch only on explicit founder authorization.

**Test tiers.** These names are used throughout; only T2 is the full-product pre-release.

| Tier | What it is | Who | What it may contain | What it is *not* |
|---|---|---|---|---|
| **T0: engineering tests** | Automated tests, emulator, QA and debug builds, S25 device checks | engineering, founder | anything, including work in progress | never evidence of product readiness on its own |
| **T1: controlled pilot builds** | Signed builds for a bounded purpose (e.g. one language end to end, the onboarding flow, billing in the internal track with licence testers) | founder and named reviewers only | a subset of the product | **never a pre-release**, never "complete product" testing |
| **T2: full-product Play pre-release** | Google Play closed testing of the release candidate | external testers | all six languages, onboarding, the approved voice experience, real billing, measurement, privacy | not a public launch |
| **T3: commercial launch** | Production release | public | T2's release candidate after its blockers are resolved | — |

**Rule:** a two-language or partial build is never labelled a pre-release or complete-product test.

---

## 2. The gaps

### G-01: Genuine onboarding is missing

**Current state (IMPL):**
- **The name question.** The only first-use step is `/welcome/name` (`lib/core/routing/app_router.dart` `firstUseRedirect`; `lib/features/settings/presentation/first_name_question_page.dart`).
  - It is optional ("Skip for now"), shown until saved or skipped, and never again afterwards.
  - It replaces the navigation stack, so Back never returns to it.
- **Today.** Then come the closed Circle and "Begin today's Circle", need and time (three needs × 10/20/30 min), one activity, Start, the Circle, Close, and feedback (`lib/features/home/presentation/home_page.dart`).
- **Reminder invitation.** After the first closed Circle, inline. The OS permission is requested only after a time is chosen (`reminder_invitation_card.dart`).
- **Premium invitation.** One inline invitation after closed Circles on two distinct local dates, never stacked with the reminder (`lib/features/premium/application/premium_offer_provider.dart`).
- **Previews.** Plans and Insights show calm Free previews and never auto-open the offer (FROZEN, Navigation contract).
- **Analytics consent.** Off by default, only in You → Data & privacy (`lib/core/analytics/analytics_consent.dart`).

**What is missing (IMPL):**
- what THIRTY does, and what a Circle is;
- first-time guidance for Start, Pause and Close;
- a language choice;
- an onboarding visual language;
- defined behaviour for existing, reinstalling and returning users beyond the name flag.

**Authority:**
- The contract has no onboarding section. It protects the "first-name flow" as infrastructure, and the release gate requires "First session ≥ 7" (tracker).
- [onboarding-principles.md](onboarding-principles.md) still applies:
  - value-first;
  - no intake form;
  - no account before first value (ADR-006);
  - Premium never mentioned in the first session and never as an interruption (ADR-007).
- The voice choice is never an onboarding question (ADR-023 §6).
- [BRAND_BOOK.md](../BRAND_BOOK.md): the first impression is relief, not settings; one register of language across the app.

**Proposed minimum journey (PROPOSED; a candidate, not a contract):**

| # | Step | Required? | User action | Stores | Free/Premium | Re-entry |
|---|---|---|---|---|---|---|
| 1 | **Welcome.** Two or three sentences: THIRTY helps you choose one thing for today; a Circle is that one thing, up to about 30 minutes, which you can close whenever you like. A small language control shows the detected language. | pass-through, no input | Continue; optionally change the language | `onboarding_welcome_seen`; a language override only if changed | both; no Premium mention | shown until passed; **never** when existing-user evidence (a class A or B key) is present (see "Existing-user detection" below) |
| 2 | **Name** (the existing page, unchanged) | optional | type a name or Skip | the existing keys | both | existing rule |
| 3 | **Need + time** (existing) | the user's first real choice | choose | existing | both | — |
| 4 | **First Circle cues.** One short inline line, the first time only: "Pause whenever you need to. Close when you're done — however far you got." (copy to be approved) | shown once | none | `first_circle_cues_seen` | both | once, ever |
| 5 | **First Close and feedback** (existing), then the reminder invitation (existing) | optional | answer or skip; choose a time or Not now | existing | both | existing |
| 6 | **Premium introduction** (existing): the one invitation on a later day, plus the calm previews in Plans and Insights | optional | open the offer or ignore it | existing | Premium | existing |

- **Language (step 1):** detected from the system locale. An unsupported locale falls back to English, and the user can change the language at any time in You → Preferences. Language is never a separate required screen.
- **Interruption and restart:**
  - a kill before step 1 completes shows the welcome again;
  - after step 1, the name question;
  - after step 2, Today;
  - a first Circle interrupted mid-way follows the existing (R8) Circle recovery.
- **What onboarding may and may not store:**
  - **Never fabricated or altered:** History and user-owned records: the journal (History and calendar), kept Circles, Plans, Insights, Memory and suggestion preferences. Onboarding creates no History entry, no "completed" record and no placeholder data.
  - **Never asked:** the voice choice.
  - **May persist explicit user choices and progress:**
    - a language override, only when the user changes it;
    - the first name, through the existing flow;
    - onboarding progress flags (`onboarding_welcome_seen`, `first_circle_cues_seen`).
  - All of these are local preferences, written with the existing confirmed-write discipline.
  - The first Circle itself is recorded by the normal Today flow, exactly as for any other Circle.
- **Existing-user detection (PROPOSED strategy; corrected 2026-11-11, C-FINAL-5):**
  - **When it runs.** Once, at start-up, after the existing bootstrap in `lib/main.dart` (`retireV1Premium`, `retirePhaseDPremium`, `completeInterruptedHistoryDeletion`), and only while `onboarding_welcome_seen` is absent.
  - **Why not "any key".** Those bootstrap migrations write markers on **every** install, a clean one included:
    - `v1_premium_retired` (`v1_premium_retirement.dart`);
    - `phase_d_premium_retired` (`phase_d_retirement.dart`).

    So the mere presence of keys does **not** prove an existing user.
  - **Method:**
    - It is **read-only and key-presence based**: only `containsKey` on an explicit, classified key list.
    - Values are never read, parsed, type-checked, migrated, repaired or rewritten. That is why an unreadable, newer-schema or wrong-type record is still counted safely, without inspecting it.
    - Every key belongs to exactly one class:

  | Class | Keys | Counts as an existing user? |
  |---|---|---|
  | **A. Durable user-owned or product records** (readable **or** not) | `circle_journal_v1`, `circle_journal_preserved_v1`, `circle_history_deletion_pending`; `toolkit_v1`, `toolkit_v1_unreadable`; `circle_plans_v2`, `circle_plans_v2_unreadable`; `insights_v2`, `insights_v2_unreadable`; `suggestion_preferences_v1` | **Yes** |
  | **B. Existing first-use evidence and explicit user choices** | `first_name_prompt_seen_v1` (**even if the name was skipped**); `user_first_name_v1`; `reminder_invitation_shown_v1`, `premium_offer_invitation_shown_v1`; settings the user chose explicitly (reminder, appearance, spoken guidance, voice, analytics consent); Today keys (`recommendation_*`) **only** where the key is written solely as the result of a user action | **Yes** |
  | **C. Bootstrap, migration and internal housekeeping** | `v1_premium_retired`, `phase_d_premium_retired`; any key the app writes without a user action (for example presentation or identity housekeeping); debug/QA-only keys (`qa_*`) | **No**, not on its own |
  | **D. Unknown keys** (SDK or third-party storage, keys not in the registry) | anything not classified A–C | **No**; origin is never guessed from presence |

  - **Rule:** welcome is suppressed **if and only if** at least one class A or class B key is present.
  - **One registry, guarded by tests.** The classification lives in one place. A guard test fails when any persisted-key constant declared in `lib/` is missing from the registry, so a future user-data key can't silently fall into class D.
  - **Where a key is ambiguous**, especially in class B, the real-bootstrap test below decides: any key that a clean install writes without a user action belongs in class C.
  - **The one write allowed.** On detecting an existing user, onboarding may write only its own progress flag (`onboarding_welcome_seen`), so that a later Delete of History can never bring the welcome back. Detection itself writes nothing. No user data is ever modified, rewritten or deleted, and first-name behaviour is unchanged.
  - **When no A or B key is present.** It is a first run, and the value-first journey applies: one pass-through welcome, an optional name, and a first Circle that is never delayed by extra questions.
  - **Required acceptance tests:**
    1. A genuinely clean install, run through the **real `main.dart` bootstrap sequence** → welcome appears.
    2. Only `v1_premium_retired` and `phase_d_premium_retired` present → welcome appears.
    3. An existing user who **skipped** the name question (`first_name_prompt_seen_v1` present, no name) → welcome does **not** reappear.
    4. Existing History, Plans, Insights, Memory/suggestion preferences or kept Circles, **each on its own** → no welcome.
    5. Unreadable or wrong-type existing user-owned records (including the `*_unreadable` keys) → no welcome, and the stored bytes are unchanged (no destructive inspection).
    6. Reinstall, cloud restore or device transfer → the result follows the keys actually persisted at launch, with no A2-07 assumption: restored A/B keys mean no welcome; only C/D keys mean welcome.
    7. Internal or SDK keys alone (class C/D) → welcome appears; they never imply a returning user.
    8. App restart and interrupted onboarding:
       - a kill before Continue shows the welcome again;
       - after a confirmed Continue, the welcome never repeats;
       - no History, journal entry or other user record is ever fabricated.
    9. The registry guard test: every declared persisted key is classified.
    10. In every case: zero bytes of class A/B user data change because of detection or onboarding.
- **Updating from an earlier build:** covered by the detection above. Existing users never see the welcome.
- **Reinstall, cloud restore and device transfer:**
  - **A2-07 is open.** `android:allowBackup="false"` is configured, but whether it also excludes cloud backup and device-to-device transfer on current Android versions is **not decided and not verified** on the signed release (tracker release gate; `dataExtractionRules` is not configured). It is **not** assumed to give a clean reinstall.
  - Onboarding therefore decides from the data **actually present at launch**, never from the install type. Restored or transferred class A/B keys mean an existing user with no welcome. Class C/D keys alone, or an empty store, mean a first run.
  - Premium is restored through Restore (to be verified under BIL-1 and SEC-1).
- **Lapse or resubscribe:** never replays onboarding.

**Privacy and medical lines (evaluation):**
- **No "not medical advice" line on the welcome screen by default.** The contract forbids medical claims, the welcome makes none, and a disclaimer there adds friction and implies a health product.
- Safety wording belongs where it matters: in the activity content (already required for Guided Steps and Paced), in the store listing and in the privacy/terms pages. The safety review (SAF-1) may require more; that decides it, not habit.
- **An optional privacy line** ("Your History stays on this phone.") is truthful today only if worded exactly. With usage data on, answers are sent per event, so "what you tell THIRTY stays on this phone" would be false. This is founder decision D-ON-2.

**Accessibility:**
- logical TalkBack order on every step;
- no mandatory animation or audio, with a reduced-motion equivalent;
- 200 % text without clipping;
- 48 dp targets;
- every step reachable and skippable by screen reader.

**Acceptance:**
1. Fresh install → first Circle closed with no blocking step beyond the welcome's Continue.
2. Kill and restart at every step resumes correctly.
3. Existing-user fixtures never see the welcome.
4. Zero bytes change in the user stores during onboarding.
5. TalkBack and 200 % text pass on the S25.
6. All copy is approved in all six languages.

### G-02: All six launch languages

**Authority:**
- **FOUNDER** direction (2026-11-03): English, French, Dutch, Spanish (es-ES), German and Italian, complete at the first commercial launch, with full Free/Premium parity and zero unapproved hard-coded user-facing text.
- **Not yet FROZEN.** The draft amendment `artifacts/launch_six_language_2026-11-03/DECISION_AMENDMENT_2026-11-03_DRAFT.md` (founder working tree, untracked) is **not applied**. The draft ADRs **025 (localization architecture), 026 (language-safe persistence), 027 (multilingual audio) and 028 (analytics v2)** are described in `MULTILINGUAL_ARCHITECTURE_CORRECTION_AND_FIRST_GATE.md` §2 and **do not exist as accepted ADRs**.

**Current state (IMPL / RECORD):**
- No `flutter_localizations`, no `intl`, no `l10n.yaml`, no ARB files, no `supportedLocales`, no language setting.
  - Founder approval in principle (2026-11-03) for adding `flutter_localizations` + `intl`, recorded in the planning folder. **Not yet an applied dependency decision.**
- Month and weekday names are hand-written in `circle_journal_entry_card.dart`, `insight_copy.dart`, `circle_history_calendar.dart` and `plan_copy.dart`.
- **Heuristic inventory at `c83543d5`:** 1,347 user-facing literal candidates in 86 files.
  - By kind: ui 1,107; ui-interpolated 191; accessibility 49.
  - The 2026-11-03 baseline was 1,299 in 82 files.
  - Tool: `artifacts/launch_six_language_2026-11-03/tools/hardcoded_inventory.py`.
  - Largest: `activity_catalog.dart` 230, `plan_copy.dart` 134, `circle_elements.dart` 105, `insight_copy.dart` 100.
- **Volume (EST):** about 7,000–7,500 English words (the 2026-11-03 count was about 7,200 words), not counting store listing, notification text, Play declarations or the privacy policy.
- **Known L-1 strings:** `artifacts/l1_option_b_2026-11-11/LOCALIZATION_INVENTORY_L1.md`.

**Workstreams (each with its own acceptance):**

| ID | Workstream | Acceptance |
|---|---|---|
| L-INF | Infrastructure: gen-l10n, ARB per locale, locale resolution and fallback (unsupported → English), ICU plurals and interpolation, locale date and time formatting replacing the hand-written arrays, a guard test that fails on any unapproved literal | guard green; every locale complete; missing key = build failure |
| L-SEL | Language choice: system-locale default; a manual override in You → Preferences, persisted locally; never in the export as a user record | switching six times changes **0 stored bytes** in the user stores |
| L-ID | Locale-aware content identity (draft ADR-026): **new** records carry origin, locale and revision metadata (optional fields; previous versions stay readable); internal IDs unchanged | legacy fixtures (schema 1, 2, R4.1 kept, unreadable) read identically in six locales |
| L-LEG | Legacy English content: journal titles, kept-Circle names and kept wording are shown **as saved**, never rewritten, translated or inferred from string equality; current-language labels for their IDs may appear as separate details | no legacy byte changes; no user-owned text is ever re-rendered |
| L-CNT | Content localization: all UI, activity and element content, Plans and StageBriefs, Insights, offer and billing, errors and recovery, L-1 texts, privacy, accessibility labels, notifications | complete per locale |
| L-QA | Human review: a six-language glossary; native review per language (tone per Brand Book, address forms vous/je/tú/du/tu); health-claim and safety-wording review; layout QA at 200 % text for German, French and Dutch length | a native reviewer signs off each language, then the founder approves |

**Frozen behaviour localization must not change:**
- activity, element, Plan, stage, Insight and voice IDs;
- kept-Circle ownership and the immutable wording snapshot (R4/R6);
- stored decisions and History;
- the export format (a new optional `exportVersion` and locale field needs the ADR);
- confirmed-write and Delete semantics;
- the kept-Circle voice rule: voiced only when every saved word equals the recorded words.

**Active Circle during a language switch (PROPOSED):** the running Circle keeps its language until Close, and the switch applies from the next screen. There is never a mixed-language spoken session.

**Glossary decisions still open:**
- whether to keep "Circle" untranslated (under evaluation; pronunciation risk in es-ES and it), or use Cercle / Kring / Círculo / Kreis / Cerchio;
- Plans in Italian (*Piano / Piani* recommended over *Percorsi*);
- the lockup tagline and slogan per language.

### G-03: Multilingual Premium voice strategy

**Authority and fixed rules:**
- **FROZEN:**
  - spoken guidance is bundled, pre-recorded and offline;
  - **no runtime TTS or voice API**;
  - TalkBack is entitlement-independent;
  - the **180 English files** (172 frozen + 8 framing) are preserved unchanged;
  - the kept-Circle voice rule (R6).
- **FOUNDER:** the Premium voice experience in every launch language; native quality; no mismatch presented as native guidance.

**Measured from the manifest (RECORD / IMPL):**
- **Per voice per language:** 42 cues (38 parts, 3 leads, 1 close) at 4,235 characters, + 1 preview (97–101 characters) + 2 framing lines (54 characters). That is **45 files, ≈ 4,388 characters**.
  - Sources: `artifacts/v2_phase_d2/voice_production/generation_log.json`, `previews/generation_log.json`, `framing_f02_f03/README.md`.
- **English bundle:** 180 files, ≈ 24.6 MB (Locke 5.7, Heather 6.0, Milo 5.8, Brittney 7.1 MB). That is ≈ 6.15 MB per voice-language.
- **Verified voice support on `eleven_multilingual_v2` (RECORD, 2026-11-03).** A provider's "multilingual" label does **not** count as native quality; only native listening approval does.

  | Language | Verified | Note |
  |---|---|---|
  | fr | 0/4 | |
  | nl | 0/4 | |
  | es | 4/4 | Latin-American accents only; es-ES is required, so effectively 0 |
  | de | 3/4 | |
  | it | 2/4 | |

**Options:**

| | A: four voices per additional language | **B: two native-quality voices per additional language** | C: one native-quality voice per additional language |
|---|---|---|---|
| New files (5 languages) | 900 | **450** | 225 |
| English-equivalent characters | 87,760 | **43,880** | 21,940 |
| Characters with expansion (EST ×1.10–1.25) | 96.5k–109.7k | **48.3k–54.9k** | 24.1k–27.4k |
| Credits, one take (EST at 0.40 cr/char) | 38.6k–43.9k | **19.3k–21.9k** | 9.7k–11.0k |
| Credits with 30 % retake reserve (EST) | 50.2k–57.0k | **25.1k–28.5k** | 12.5k–14.3k |
| Added bundle size (EST) | ≈ +123–154 MB | **≈ +62–77 MB** | ≈ +31–38 MB |
| Native-quality sourcing | needs 20 approved renditions; current personas cover almost none at native quality | **10 renditions; feasible via a per-language library search** | 5 renditions; easiest |
| Founder listening QA | 20 full packs | **10** | 5 |
| Upkeep per changed script line | ×20 (+4 English) | **×10 (+4)** | ×5 (+4) |
| Premium "Guidance" value | full choice | **a real choice of two** | no choice outside English |

**Assumptions** (kept apart from the facts):
1. **Expansion factor.** 1.10–1.25 is taken from French +22.6 % and Dutch +10.5 % on the 2026-11-03 sample. Spanish, German and Italian are unmeasured.
2. **Credit rate.** 0.40 credits per character is the **observed ledger rate** from the October production, not a current price. The money cost depends on the plan held when generating; no current ElevenLabs price is asserted.
3. **Retake reserve.** 30 % is a planning reserve, not a measurement.
4. **Size** scales with expansion. The base-module limit is 500 MB (Play Help 9859372, checked 2026-11-03), so every option fits a bundled AAB. The download grows for every user. Per-language delivery (asset packs) is optional and was evaluated as E-1, which never ran.
5. **Licensing.** The English pack was made under a paid ElevenLabs plan with commercial rights (FROZEN record). Rights for any **new library voices** must be confirmed for the account and plan at generation time; they are **not assumed**.
6. **Recurring cost.** Zero runtime cost. Upkeep is one-off regeneration whenever scripts change.

**Recommendation:**
- **Option B**, preceded by a bounded native pilot per language before any full pack.
- **Why B:**
  - It keeps a genuine Premium voice choice.
  - It halves production, QA and upkeep against A.
  - It doesn't force personas that don't speak a language natively.
- **What stays with the founder:** the final voice counts, personas, language variants and budget.
- **Persona model (draft C4).** The UI never claims "the same voice" across languages. "Hear <name>" plays that language's own recording.
- **Mismatch rule (PROPOSED).** A voiced session speaks exactly one language: the language of the words on screen.
  - A legacy English kept Circle is voiced in English, only where the fingerprints match (2026-11-03 option D-A (a)). Otherwise it runs unvoiced with the existing R6 line.
  - A language with no approved voice shows Premium as unvoiced in that language, and the offer must say so.
- **Not authorized:** no audio production, pilot or spending.

### G-04: First value, retention and Free/Premium viability

**Boundary (FROZEN, Amendment 2):**
- **Premium** is four continuing jobs: Today (composition), Direction (Plans), Understanding (Insights) and Guidance (voice).
- **After a lapse,** nothing owned is confiscated.
- **Free** keeps the full core: Today, the three modes, Memory, History and the calendar, Keep, kept Circles, Export and Delete, reminders, Worlds, accessibility, and the Plan previews.
- **Commercial terms are not frozen:** price, trial, cadence and annual.

**Current state (IMPL):**
- **Offer page** (`premium_offer_page.dart`):
  - the store's localized **monthly** price only;
  - a renewal disclosure;
  - no trial or annual plan;
  - voiced or unvoiced bullet points depending on the build;
  - a line stating what Free keeps.
- **Billing** is not proven in Play: no RevenueCat configuration exists in the working tree (only `config/revenuecat.example.json`), and by design a release build fails without it.
- **Invitations:** one Premium invitation (day 2 or later); "Make today's Circle" only after Premium is verified.
- **UNKNOWN:** whether Free users can play the "Hear <name>" preview.

**Assessment:**
- **Strengths:**
  - Trust: no hostage mechanics.
  - Near-zero variable cost per subscriber: local-first, bundled audio, no server compute.
  - The recurring logic is sound: the value is new daily work, not access.
- **Risks:**

  | # | Risk | Effect |
  |---|---|---|
  | R-a | Premium can't be experienced before paying (no trial or sample), while the offer is the only sales surface | conversion |
  | R-b | Understanding (Insights) needs weeks of evidence; B8 simulations show 24–42 of 53 weeks without a new Insight | early perceived value |
  | R-c | Content depth (see CD-1) limits month-2 variety, especially More Energy | retention, churn |
  | R-d | Guidance loses value in languages without approved voices | conversion outside English |
  | R-e | Monthly only | cash flow; no annual commitment option |
- **Must stay Free:** ownership (kept Circles, History, Export, Delete), Memory, accessibility, reminders, basic trust. Moving any of these would break frozen rules and user trust.
- **No boundary change is recommended.** The levers are commercial hypotheses: trial or introductory offer, annual plan, regional pricing (D-C-1 to D-C-3). They are decided in Phase E on evidence.

**Cost structure** (verify before using in a business case):

| Kind | Items |
|---|---|
| Variable | Play service fee on subscriptions (verify the current rate); RevenueCat free up to US$2.5k monthly tracked revenue, then 1 % (RECORD, 2026-11-03) |
| Fixed | Play developer account; telemetry and dashboard hosting (Supabase plan, about US$25/month Pro, RECORD 2026-11-03, to verify); privacy and legal pages |
| One-off | voice production (G-03); translation and native review (G-02); safety review (SAF-1) |
| Recurring upkeep | translation and voice regeneration for every content change, multiplied by languages × voices |

### G-05: UX and design completeness

**Reference images:**
- **`Design vision.png` (2026-09-08):** the current V2 Today (emulator captures 2026-10-22, `THIRTY App/Social/captures/v2_2026-10-22/`) matches its visual language closely: watercolour Circle hero, sage palette, lockup, Today card, Start Circle.
  - Its five tabs (Home / Explore / Circle / Progress / You) are **superseded** by the FROZEN four tabs. **That is not a gap.**
- **`huidige status.jpeg` (2026-09-08):** a V1 dark screen, obsolete; not a reference.

**Gaps:**

| Gap | Class |
|---|---|
| No onboarding visual language (G-01) | missing essential state |
| Six-language layout: pill buttons, letter-spaced caps ("TODAY · 20 MIN"), the lockup tagline, the offer bullet points | genuine UX risk |
| No in-app privacy policy or support links (`you_about_card.dart`: they "appear only once real") | missing essential state |
| Slogan and tagline: Brand Book "Your healthiest 30 minutes." vs lockup "A brighter you in small steps"; Phase E slogan decision open | founder decision |
| L-1 surfaces have had no visual, TalkBack or device review | gap in validation evidence |

- **Not reviewed in this assessment:** fresh screenshots of `c83543d5`. A visual pass of the release candidate belongs to DEV-1.

### G-06: Technical and commercial release gates

The full table is §4. Statuses there are verified against the records; old accepted findings are not reopened.

### CD-1: Content-depth acceptance (founder product-acceptance gate)

**External catalogue (IMPL, `lib/features/home/application/activity_catalog.dart`):**
- 21 activities: **16 live**, **4 `safetyReviewPending`** (Stairs or a slope, Movement snack, Counted breathing, Slow breathing pause), **1 retired** (Standing breath reset).
- **Paced mode:** every Paced activity is gated or retired, so **Paced is never offered in an external build**, although the contract lists three modes.

**Free coverage, live activities that fit each time** (P = primary, S = secondary; IMPL; minimum minutes):

| Need | ≈10 min | ≈20 min | up to 30 min |
|---|---|---|---|
| More Energy | P 3 · S 2 | P 4 · S 4 | P 4 · S 4 |
| Clearer Head | P 2 · S 8 | P 6 · S 10 | P 6 · S 10 |
| Gentler Pace | P 5 · S 2 | P 6 · S 5 | P 6 · S 5 |

**Premium composition evidence (RECORD):**
- 38 composer elements: the `CircleElement` definitions in `elementLibrary` (`circle_elements.dart`).
- **B8 12-month simulations**, run with safety-pending content **disabled** (`test/features/b8/b8_product_simulation_test.dart`, `safetyPendingAllowedProvider` overridden to false):
  - **More Energy at ≈10:** 365/365 composed, no stall; 6 mains, 19 materially distinct and 52 exact sessions; first exact repeat on day 23, never on consecutive days. Rated **WEAK**: a real-user risk (tracker; `artifacts/v2_phase_d2/b9/FOUNDER_CONTENT_CLOSURE.md`).
  - **Insights:** 24–42 of 53 weeks silent.
  - **Lapse:** a kept Circle could stand in on 111 of 120 lapsed days.
- **Earlier founder decision:** on 2026-10-20 the founder accepted More Energy WEAK as **non-blocking for D2 closure**. That decision was about D2 closure, not about commercial launch adequacy.

**Assessment:**
- **Structurally adequate:** no stalls, the safety gate holds, variety holds within the limits measured.
- **Perceived adequacy is unproven:** first-session variety, repeat value over weeks, and month-2 value, especially for More Energy at ≈10 and ≈20 and Clearer Head at ≈10.
- **The biggest single lever is SAF-1.** The safety review decides whether the four gated activities (two energy, two Paced) can be offered. **This register does not authorize ungating anything.**
- **The second lever** is the contract's OPTIONAL additions (Daylight minutes, Screen-break reset, Reach out to someone). Each needs authoring, founder approval and translation into six languages.
- **Ordering consequence:** any content added after translation and voice production multiplies cost. **The content-depth decision must come before the copy freeze for translation and voice scripts.**

**Gate:**
- **Decision D-CD-1, before the copy freeze:** accept the current depth for T2, or require more (via SAF-1 and/or optional additions).
- **Re-check after T2** on real-use evidence: feedback response, repeat and replacement rates, and early retention.

### G-07: Safety proportionality review (PROPOSED pre-release product-safety assessment)

- **Source:** raised separately by the founder on 2026-11-11 as a pre-release product-safety assessment for the **current** app. It did not originate in the G-08 ecosystem addendum, which only refers to it. Its original wording was not available when this register was drafted, so it is recorded here as a proposed assessment, not reconstructed.
- **Founder concern (2026-11-11, recorded explicitly):** the current safety restrictions may be **disproportionate** to THIRTY's actual risks. The current posture:
  - 4 activities withheld from every external build;
  - Paced mode absent externally;
  - More Energy left WEAK.
- **Risk statement:**
  - **If** a restriction turns out to exceed the actual risk, it would reduce variety, Premium depth and possibly retention without a matching safety benefit.
  - **If** a restriction is lifted without adequate review, it could expose users to avoidable harm and undermine trust.
  - **Neither has been established.** Whether any current restriction is disproportionate is exactly what the assessment must determine from actual risks, existing safeguards and comparable activities.
- **Question:** is the current safety posture proportionate to THIRTY's approved promise (everyday wellbeing, no medical claims), its intended general adult audience, its content and its actual risks?
  - **The judgement runs both ways:** not more restrictive than the risks justify, and no more advanced exercise or breathing content than the promise needs.
- **Required: a risk-based, per-activity assessment, on one consistent standard.** Each **gated** activity is assessed **side by side with comparable live activities**, so like is judged like:

  | Gated (`safetyReviewPending`) | Comparable live activities |
  |---|---|
  | Stairs or a slope (`briskStepBurst`, Guided Steps, moderate) | A brisk walk (`thirtyMinuteWalk`, moderate); Easy walk |
  | Movement snack (`activeMovementSnack`, Guided Steps, moderate, indoor) | Move to music (`moveToMusic`, moderate); A quick standing stretch (`energisingStretchFlow`); One active household task (`activeHouseholdTask`, moderate) |
  | Counted breathing (`focusedBreathingCount`, Paced) | Listen to one thing (`quietAudioFocus`); Gentle stretch pause (`gentleStretchPause`); no live breathing activity exists |
  | Slow breathing pause (`restfulBreathingPause`, Paced) | Sitting outside, unhurried (`quietSittingOutside`); A slow warm drink (`smallComfortRitual`); Gentle stretch pause |

  - **Per activity, the review records:** the realistic hazard; who could be affected; likelihood and severity; whether the existing content (preparation, lighter version, stop and safety wording, reduced-motion equivalent) already mitigates it; any wording change needed; and one outcome: **clear as is / clear with a wording change / keep gated / retire.**
  - **The same standard applies to the live comparables.** If a live activity carries the same risk as a gated one, the two are treated the same, in whichever direction the evidence points.
  - Breathing content stays inside the existing contract limits: no long or brisk breathing (the retired Standing breath reset is not revived), and no medical claims.
- **Relation to SAF-1:** SAF-1 is the FROZEN, contract-required review (Safety gate). G-07 sets its scope and standard. It does not replace SAF-1, and **it authorizes no ungating**.
- **Condition for clearance:** an activity may appear in **any external build** (T2 included) only once:
  1. an appropriate safety review has been **completed** and supports the clearance; and
  2. the founder has **approved** it.

  Until both are true, it stays gated.
- **Timing (founder, 2026-11-11):** **every decision that changes launch content is made before the English copy freeze, and therefore before the translation and audio freezes.**
  - A cleared activity changes catalogue content, composer elements, voice scripts and translations.
  - Clearing it after the freeze would force retranslation and new recordings in six languages, so these decisions are **not** deferred until after the T2 pre-release.
- **Verification, before every external build:** each external build is checked against the review: the shipped content, the gating status and the safety wording must be exactly what the review cleared.
- **The release record:** the formal SAF-1 record for the release gate may be completed later. It documents the review and verification above and **never substitutes for them**.
- **Out of bounds:** future specialist apps (G-08) are **not** a reason to tighten or loosen the current app's gates, nor to add advanced content to it.
- **Priority:** **P0.** Its scope (D-SAF-1) and per-activity outcomes (D-SAF-2) are decided before the copy freeze, and they feed CD-1.

### G-08: Long-term ecosystem and brand expansion

**Classification: STRATEGIC CONTEXT / POST-LAUNCH OPPORTUNITY. Not a current release blocker, not P0/P1/P2, not in the current THIRTY backlog.**

- **Principle (FOUNDER, approved):** **First prove THIRTY. Then expand the system.**
- **Direction (FOUNDER, long-term):**
  - **KEYBRACE** as a possible umbrella brand. Its legal and final brand status are open.
  - **THIRTY** stays the flagship and keeps its positioning.
  - **Possible specialist apps:** THIRTY Fit (training, strength, movement), THIRTY Meditation (guided meditation and breathing, audio-first), THIRTY Yoga (flows, mobility, stretching). Each would complement THIRTY, not replace it.
  - **Possible THIRTY Pass:** a combined subscription. Unpriced, not designed, not approved.
  - **Possible ritual products and merchandise:** no supplier, inventory, store or fulfilment approved. Not a launch requirement.
  - **A possible shared THIRTY core** later: Circle engine, design system, personalization, Plans, reminders, journal/History, Worlds, billing/entitlements, accessibility standards.
- **Not authorized now:**
  - no specialist-app work;
  - no multi-app framework or shared-core extraction;
  - no rewrite of the accepted R8/L-1 architecture;
  - no Pass, and no change to the current RevenueCat entitlement, subscription identity or billing architecture;
  - no merchandise infrastructure;
  - no rebranding.
- **What current work may do:** build THIRTY well and avoid needless incompatibilities, but **add no abstraction without a present need**.
- **Clarifications:**
  - **KEYBRACE OS is discontinued** and is unrelated to this brand direction.
  - Existing meditation-like content in THIRTY is not a Meditation app.
  - The 0.85× English pacing test is not approved for future Meditation content.
- **Expansion gate (FOUNDER sequence):**
  1. launch THIRTY;
  2. acquire real users;
  3. validate retention, perceived value and recurring revenue;
  4. evaluate operating cost and profitability;
  5. only then consider a specialist app, the Pass, a shared core or merchandise.
  - Decide on real interest, retention, willingness to pay, revenue, build and upkeep cost, reuse and operational complexity.
  - **No numerical GO thresholds are approved.**
- **Canonical home (single source of truth):** the founder-approved [THIRTY_PRODUCT_FAMILY_STRATEGY.md](../strategy/THIRTY_PRODUCT_FAMILY_STRATEGY.md) (v1.1, 2026-10-07) and [THIRTY_FUTURE_RITUAL_PRODUCTS_AND_MERCHANDISE.md](../strategy/THIRTY_FUTURE_RITUAL_PRODUCTS_AND_MERCHANDISE.md) (non-binding). They already hold this direction: brand architecture, the Fit / Meditation / Yoga candidates, a cross-product pass, technical reuse, the standalone-product gate and sequencing.
  - New ecosystem decisions (for example the "THIRTY Pass" name, the KEYBRACE OS discontinuation note, KEYBRACE as an umbrella brand) go there as dated additions, with founder approval.
  - This register only points to them.

---

## 3. Measurement and analytics (MEA)

**Current state (IMPL / RECORD):**
- **Six V1-era event types are sent, consent-gated** (`lib/core/analytics/`): `app_opened`, `recommendation_shown` (need, activity id), `circle_started`, `circle_closed`, `circle_attempt_reported` and `circle_usefulness_reported` (answer).
  - *This corrects the earlier draft of this assessment, which said three.*
- Each event carries the date and time, app version, cohort label and a random ID made on the phone (`tester_identity_provider.dart`).
- The table is the Supabase `analytics_events`, insert-only (`supabase/migrations/`).
- **Consent:**
  - off by default;
  - only in You;
  - the in-app disclosure copy "Share usage data" **was applied in R6 final (2026-11-03)**: it names the events, their fields and the random ID, and says what turning it off does.
- **Not implemented (RECORD, tracker Phase E):**
  - MEASUREMENT-1 for the V2 funnel;
  - voice events (`PHASE_E_VOICE_USAGE_MEASUREMENT.md`);
  - Plan and Insight events (ADR-024 §14);
  - a production Supabase project;
  - the Founder Dashboard (a separate project; KEYBRACE OS is discontinued).
- **A2-06 is still open** for the server side: the retention schedule, server-side deletion, the privacy policy and verification of Supabase data handling (tracker 2026-11-03).
  - The draft ADR-028 proposes a consent-created random installation ID, raw events kept 45 days and aggregates 25 months. **Proposed, not accepted.**

**Gate MEA-1 (before T2):**
- the founder approves the event set, identity, retention and hosting;
- V2 funnel events are implemented consent-gated: onboarding completion, first Circle closed, offer viewed, purchase and restore outcome, Plan and Insight events, voice events;
- nothing is sent before opt-in, and no Circle content, user text or health inference is ever sent;
- the privacy policy and Data Safety match the code exactly.

**Why before T2:** the release gate requires closed-test evidence, including feedback response rate and early retention. Without MEA-1, T2 can't produce that evidence.

---

## 4. Release gates by tier

| ID | Gate | Verified status at `c83543d5` | Authority | T1 | T2 | T3 |
|---|---|---|---|---|---|---|
| BIL-1 | Real Google Play + RevenueCat billing: products, purchase, restore, cancel and lapse on a signed build | **OPEN.** No configuration in the tree; a release build is impossible without it (by design) | ADR-017; tracker Phase E | needed for a billing pilot | **required** | required |
| BIL-2 | Subscription lifecycle: grace, account hold, refund, resubscribe, phone change | **OPEN** | tracker Phase E; security review | — | required for testers' real cases | **required** |
| PRV-1 | Privacy policy, GDPR basis, support contact, in-app links | **OPEN.** None exists (`you_about_card.dart`) | tracker Phase E | — | **required** | required |
| PRV-2 | Play Data Safety + foreground-service declaration (`FOREGROUND_SERVICE_MEDIA_PLAYBACK`, with video evidence) | **OPEN** | tracker Phase E | — | **required** (Play Console enforces declarations before a release can roll out; confirm per track) | required |
| MEA-1 | Consent-gated V2 measurement + A2-06 server side | **OPEN** (the in-app copy is done) | tracker Phase E; §3 | — | **required** | required |
| SAF-1 | Safety review of live breathing and exertion content, and of any gated activity proposed (with the G-07 proportionality standard) | **OPEN.** Gated content stays gated until cleared | FROZEN Safety gate; release gate | — | **clearance decisions that affect launch content: completed review + founder approval before the English copy freeze** (so before T2); uncleared content stays gated; each external build verified against the review | formal record **required** (documents the review and verification; never substitutes for them) |
| A2-07 | Android backup and device transfer: decision, configuration (`dataExtractionRules`), test on the signed release | **OPEN.** Only `allowBackup="false"` | tracker release gate (R6b) | — | not required (tracker: closed tests may proceed) | **required** |
| SEC-1 | Premium security & local device migration review | **REGISTERED, NOT STARTED** | tracker 2026-11-01 | — | recommended before T2 for APK tampering and QA-override removal | **required** |
| RL-4 | Offset-free timestamps: founder chooses option 1 or 2 | **ACCEPTED limitation;** the pre-commercial decision is owed | `artifacts/r8_1_consolidated_remediation_2026-11-05/LIMITATION_RL4_OFFSET_FREE_TIMESTAMPS.md` | — | decision before the export-format freeze (L-ID) | **required** |
| DEV-1 | Signed-build device validation: S25 TalkBack, 200 % text, process kill, real storage, offline, performance and start-up, background voice | **PARTIAL.** D2-era S25 and TalkBack PASS (B4/B6/B7/B9-A); R8.x and L-1 automated or simulated only | tracker; `artifacts/l1_option_b_2026-11-11/LIMITATIONS_L1.md` | smoke | **required** on the T2 candidate | full matrix **required** |
| SIG-1 | Release signing and Play App Signing | `android/key.properties` present locally; enrolment **UNKNOWN** | `android/app/build.gradle.kts` | required for the Play tracks | required | required |
| AUD-1 | Final independent release audit, bounded to the release candidate | **NOT STARTED** | tracker release gate | — | — | **required** |
| STO-1 | Store listing in six languages, screenshots, ASO, slogan; no "AI" positioning | **OPEN** | tracker Phase E; release gate | — | a minimal closed-test listing | **required** |
| GOV-1 | The tracker reflects R8.1 → L-1 and this register | **OPEN.** The tracker log ends at R8 (2026-11-04) | CLAUDE.md §0 | required | required | required |

**Not reopened (accepted or resolved):**
- the R8–R8.3.4.1 integrity findings (baseline FROZEN);
- L-1 (ENGINEERING ACCEPTED, with its documented limitation);
- the A2-06 in-app copy (applied R6);
- the D2 audio findings (resolved 2026-11-02);
- More Energy WEAK *as a D2 closure item*. It is reconsidered here only as a launch-acceptance question (CD-1).

---

## 5. Prioritized register

- **P0** = blocks the T2 full-product Play pre-release.
- **P1** = blocks the T3 commercial launch only.
- **P2** = may follow launch.

Priority is not order; see §6.

| ID | Gap | Current state | Authority | Pri | Impact (user / business) | Depends on | Acceptance | Founder decision | Parallel? | Blocks |
|---|---|---|---|---|---|---|---|---|---|---|
| GOV-1 | Tracker and register reconciled | tracker stale after R8 | CLAUDE.md §0 | P0 | planning integrity | approval of this register | tracker states the live baseline and links the register | approve | yes | T2 |
| CD-1 | Content-depth acceptance | 16 live; Paced absent; More Energy WEAK | contract Catalogue (optional additions); founder | P0 (decision) | first-session and month-2 value / retention, churn | SAF-1 scope; before the copy freeze | decision recorded; any additions approved and in the catalogue before translation | **D-CD-1** | yes | T2 (decision) |
| G-01 | Onboarding journey | name question only | onboarding-principles; ADR-006/007; founder | P0 | activation, trust / conversion funnel | D-ON-1/2; L-INF for copy | §2 G-01 acceptance 1–6 | **D-ON-1, D-ON-2** | design yes; build after L-INF | T2 |
| L-INF | Localization infrastructure | none | founder (amendment pending) | P0 | prerequisite for all localized copy | D-L-1, dependency approval | guard green; fallback; locale formats | **D-L-1** | yes, first | T2 |
| L-SEL | Language choice + switching | none | founder | P0 | language trust | L-INF | 0 stored bytes change across six switches | — | yes | T2 |
| L-ID / L-LEG | Locale-aware identity + legacy rule | not implemented | draft ADR-026 | P0 | data integrity / trust | ADR-026 acceptance; RL-4 decision (export format) | legacy fixtures unchanged in six locales | **D-L-5** (accept ADR-026) | yes | T2 |
| L-CNT + L-QA | Content in fr, nl, es-ES, de, it + native review | none | founder | P0 | reach, conversion in five markets | content freeze (CD-1, G-01 copy); glossary | native and founder sign-off per language; layout pass | **D-L-3** glossary, **D-L-4** reviewers | per language in parallel | T2 |
| G-03a | Voice strategy + truthful offer and settings copy per language | undecided | founder; FROZEN voice rules | P0 | Premium value / conversion | D-V-1…5 | offer and You never promise an unavailable voice | **D-V-1…5** | yes | T2 |
| G-03b | Voice pilots → production → listening QA → S25 | none | founder | P0 (for the chosen languages) | Premium value | G-03a; voice-script freeze; budget | listening PASS per rendition; manifest integrity; no mixed-language session | budget approval per batch | per language | T2 |
| BIL-1 | Real billing in the Play tracks | not configured | ADR-017 | P0 | revenue path | Play Console + RevenueCat setup (founder); SIG-1 | purchase, restore, cancel and lapse proven on a signed build | **D-C-1** price and cadence for the test products | yes | T2 |
| MEA-1 | Consent-gated V2 measurement + A2-06 server side | six V1 events; V2 not built | tracker Phase E | P0 | founder decisions on evidence | **D-M-1** | §3 gate | **D-M-1** | yes | T2 |
| PRV-1/2 | Privacy policy, support, Data Safety, foreground-service declaration | none | tracker Phase E | P0 | trust, store compliance | MEA-1 definition | published URLs; console forms match the code | **D-P-1** controller and support channel | yes | T2 |
| DEV-1 (T2) | Signed release-candidate device pass | partial | tracker | P0 | quality | all P0 build items | S25 + one other device: TalkBack, 200 %, kill, offline, background voice | — | at the end | T2 |
| SEC-1 | Premium security & migration review (T2 subset: QA-override removal, APK tampering) | not started | tracker | P0 subset / P1 full | revenue protection | BIL-1 | review report; findings fixed or accepted | — | yes | T2 subset; T3 |
| SAF-1 | Safety review: the content-affecting clearance decisions | not started | FROZEN | **P0** (before the copy freeze) | safety, trust; depth, retention | an external reviewer; G-07 standard | each activity cleared, cleared with wording, kept gated or retired; founder-approved | **D-SAF-1** reviewer and scope; **D-SAF-2** per-activity outcomes | **start first** | T2 (via the copy freeze) |
| SAF-1 (verify) | Each external build's content, gating and safety wording = what the review cleared | — | FROZEN Safety gate | P0 | safety | the decisions above | verified per external build (T1 pilots outside the team, T2) | — | per build | T2 |
| SAF-1 (record) | Formal release-gate record of the review and its verification; documents them, never substitutes for them | — | release gate | P1 | release assurance | the review and verification | signed record | — | yes | T3 |
| G-07 | Safety proportionality review (standard for SAF-1; the founder's concern about disproportionate restriction) | proposed | founder (2026-11-11) | **P0** | avoids over- and under-restriction; depth | — | per-activity risk assessment of the 4 gated activities against their live comparables, one standard; no ungating without SAF-1 | **D-SAF-1, D-SAF-2** | yes | T2 (via the copy freeze) |
| A2-07 | Backup and transfer | not decided | tracker | P1 | data trust | SIG-1, signed release | per tracker gate | **D-B** | yes | T3 |
| RL-4 | Timestamp disposition | accepted limitation | R8.1 record | P1 (decide early: affects export) | edge-case correctness | — | decision recorded; implemented if option 1 | **D-RL4** | yes | T3 |
| BIL-2 | Full lifecycle | not proven | tracker | P1 | revenue, support | BIL-1 | evidence per case | — | yes | T3 |
| STO-1 | Six-language listing, slogan, ASO | none | tracker | P1 | acquisition | G-02 copy; **D-S** | listing approved per language | **D-S** | yes | T3 |
| DEV-1 (T3) | Full device matrix + performance | partial | tracker | P1 | quality | T2 fixes | recorded evidence | — | — | T3 |
| AUD-1 | Final release audit | not started | tracker | P1 | release assurance | all T3 items | positive bounded audit on one SHA | launch | last | T3 |
| COM-1 | Trial, annual, regional pricing | not decided | commercial hypotheses | P1 if decided, else P2 | conversion and cash | BIL-1, MEA-1 | decision recorded | **D-C-2, D-C-3** | yes | T3 if adopted |
| CNT-2 | Further content, beyond the CD-1 decision | — | contract optional | P2 | retention | T2/T3 evidence | coverage review | later | — | — |

**Deliberately not in this table:** G-08 (specialist apps, THIRTY Pass, shared core, merchandise). It is long-term strategy, gated by real post-launch evidence (§2 G-08), and none of it runs alongside the current onboarding, localization, safety or billing work.

### Classification at a glance

| Class | Items |
|---|---|
| **Current THIRTY launch requirements** | every P0 and P1 row above |
| **Open founder decisions** | §7 |
| **Post-launch product hypotheses** | COM-1 (if not adopted before T3); CNT-2; MEASUREMENT-driven tuning (TUNABLE parameters) |
| **Long-term ecosystem strategy** | G-08, held in `docs/strategy/` |

---

## 6. Dependency-aware roadmap

**Stage 0: decisions and governance.** Not code.
- Approve this register (GOV-1).
- Decide D-L-1 (apply the six-language amendment as FROZEN, edited), D-L-5 (ADR-026), D-ON-1/2, D-CD-1, D-V-1…5, D-M-1, D-RL4, D-SAF-1, D-P-1.

**Stage 1: foundations, in parallel:**

| Track | Contents |
|---|---|
| Engineering | L-INF and L-SEL; English extraction behind the guard (no behaviour change); L-ID/L-LEG per ADR-026 |
| Content | SAF-1 with the G-07 standard, **started first**; CD-1 outcome (any approved additions authored); onboarding copy (English) |
| Commercial (founder) | Play Console, RevenueCat products, licence testers, SIG-1 enrolment; privacy policy and support drafting |
| Measurement | MEA-1 design → implementation |

**Stage 2: build the complete product in English:**
- G-01 onboarding on localized strings;
- G-03a offer and settings copy rules;
- BIL-1 proven in a **T1 billing pilot** (internal track, licence testers);
- **English copy freeze**, the input to translation, which is also the voice-script freeze.

**Stage 3: languages and voices, parallel per language:**
- glossary → translation → native review → layout QA (L-CNT, L-QA);
- in parallel, per language: G-03b native pilot → founder listening → full renditions → listening QA → integration;
- **T1 language pilot builds** are optional, for the founder and named reviewers. They are never called a pre-release.

**Stage 4: release candidate:**
- full integration of six languages, voices, onboarding, billing and measurement;
- PRV-1/2 published and declared;
- SEC-1 T2 subset;
- DEV-1 on the signed candidate.

**→ T2: full-product Google Play pre-release** (closed testing). Collect evidence through MEA-1 and fix the blockers it demonstrates.

**Stage 5: commercial gates:** the SAF-1 formal release record (the review, the founder approvals and the per-build verification were completed earlier; the record documents them and never replaces them); A2-07; SEC-1 full; RL-4 implemented if option 1; BIL-2; STO-1; DEV-1 full; AUD-1.

**→ T3: commercial launch,** on explicit founder authorization only.

---

## 7. Founder decision register

| ID | Decision | Needed before |
|---|---|---|
| D-ON-1 | Approve the onboarding journey (§2 G-01), or amend it | Stage 2 |
| D-ON-2 | Welcome copy; whether a privacy line appears (truthful wording) | Stage 2 |
| D-L-1 | Apply the six-language contract amendment (from the 2026-11-03 draft) and approve the `flutter_localizations` + `intl` dependency | Stage 1 |
| D-L-3 | Glossary: Circle untranslated or translated; the Plans term; address forms | Stage 3 |
| D-L-4 | Native reviewers per language (who, budget) | Stage 3 |
| D-L-5 | Accept ADR-026 (origin and locale metadata; legacy shown as saved) | Stage 1 |
| D-CD-1 | Content depth for T2: accept as is, or require additions or SAF-1 outcomes first | before the copy freeze |
| D-V-1 | Voice option A / B / C (recommended B) | Stage 2 |
| D-V-2 | Persona model: same names with per-language renditions, or per-language names | Stage 3 |
| D-V-3 | Mismatch and legacy rule (one spoken language per session; D-A (a)) | Stage 2 |
| D-V-4 | Credit budget, ceilings, pilot first | Stage 3 |
| D-V-5 | Licence confirmation for new voices | Stage 3 |
| D-M-1 | Event set, identity, retention, hosting (draft ADR-028) | Stage 1 |
| D-P-1 | Data controller details, support channel, privacy policy owner | Stage 1 |
| D-SAF-1 | Safety reviewer and scope, including the G-07 proportionality standard | Stage 1 |
| D-SAF-2 | Per-activity clearance outcome (clear / clear with wording / keep gated / retire) for the 4 gated activities and their live comparables | **before the English copy freeze** (Stage 2) |
| D-RL4 | RL-4 option 1 (UTC or offset + versioned export) or option 2 (accept) | Stage 1 (it affects the export format) |
| D-B | A2-07 backup and transfer behaviour | Stage 5 |
| D-C-1 | Price and cadence for the test products | BIL-1 |
| D-C-2 / D-C-3 | Trial or introductory offer; annual; regional pricing | before T3 |
| D-S | Slogan and tagline across languages. The Brand Book holds the flagship slogan; the Product Family Strategy §D defers specialist-app slogans | STO-1 |

*Not a current decision:* G-08 ecosystem steps. They are taken after launch evidence, in `docs/strategy/`.

---

## 8. Evidence strength and open unknowns

| Strength | What |
|---|---|
| **Verified in code (`c83543d5`)** | the first-use route; invitation rules; consent default and copy; six analytics events; zero localization infrastructure; the inventory count; activity statuses and the coverage matrix; offer copy and price handling; `allowBackup="false"` and no `dataExtractionRules`; the audio manifest counts and sizes; the release-build billing guard |
| **From records** | B8 simulations; voice verification (2026-11-03); Play limits; the credit rate; RevenueCat and Supabase pricing (2026-11-03); founder decisions cited |
| **Estimates** | word volume; expansion factors; credits; bundle growth |
| **Unknown** | Free access to the voice preview; Play App Signing enrolment; a production Supabase project; L-1 surfaces on a device; current ElevenLabs prices and library-voice terms |

## 9. Sources

**Contract and governance:**
- [PRODUCT_V2_CONTRACT.md](PRODUCT_V2_CONTRACT.md): Status, Amendments 1–2, Free / Premium / after lapse, Catalogue status, Safety gate, Navigation contract, Frozen vs tunable vs commercial hypotheses.
- [THIRTY_V2_DELIVERY_TRACKER.md](THIRTY_V2_DELIVERY_TRACKER.md): Current state, Phase E, Release gate, log 2026-10-20 (B8/B9), 2026-11-01 (security review), 2026-11-03 (R6, R6b, A2-06), 2026-11-04 (R8).
- [ADR-023](adr/ADR-023-v2-recurring-premium-personal-guided-circle.md), [ADR-024](adr/ADR-024-v2-circle-plans-insights-and-four-tab-product.md), [ADR-006](adr/ADR-006-no-account-before-first-value.md), [ADR-007](adr/ADR-007-premium-never-blocks-the-core-loop.md).
- [onboarding-principles.md](onboarding-principles.md), [PHASE_E_VOICE_USAGE_MEASUREMENT.md](PHASE_E_VOICE_USAGE_MEASUREMENT.md).
- [../BRAND_BOOK.md](../BRAND_BOOK.md), [../DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md), [../worlds/WORLD_SYSTEM.md](../worlds/WORLD_SYSTEM.md).
- Strategy (G-08): [../strategy/THIRTY_PRODUCT_FAMILY_STRATEGY.md](../strategy/THIRTY_PRODUCT_FAMILY_STRATEGY.md), [../strategy/THIRTY_FUTURE_RITUAL_PRODUCTS_AND_MERCHANDISE.md](../strategy/THIRTY_FUTURE_RITUAL_PRODUCTS_AND_MERCHANDISE.md).

**Evidence:**
- `artifacts/v2_phase_d2/b8/`, `artifacts/v2_phase_d2/b9/FOUNDER_CONTENT_CLOSURE.md`
- `artifacts/v2_phase_d2/voice_production/`
- `artifacts/r8_1_consolidated_remediation_2026-11-05/LIMITATION_RL4_OFFSET_FREE_TIMESTAMPS.md`
- `artifacts/l1_option_b_2026-11-11/`

**Founder working tree (untracked):**
- `artifacts/launch_six_language_2026-11-03/`: the plan, `MULTILINGUAL_ARCHITECTURE_CORRECTION_AND_FIRST_GATE.md`, `DECISION_AMENDMENT_2026-11-03_DRAFT.md`, `UNIVERSAL_CIRCLE_BRANDING_AND_EXECUTION_GATE.md`, the inventory tool and the CSV.

**Code:**
- `lib/core/routing/app_router.dart`
- `lib/features/settings/presentation/first_name_question_page.dart`
- `lib/features/home/presentation/home_page.dart`
- `lib/features/premium/application/premium_offer_provider.dart`
- `lib/features/premium/presentation/premium_offer_page.dart`
- `lib/core/analytics/`
- `lib/features/home/application/activity_catalog.dart`
- `lib/features/personal_circle/domain/spoken_cues.dart`, `circle_elements.dart`
- `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts`
