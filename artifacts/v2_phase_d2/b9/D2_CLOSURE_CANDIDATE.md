# THIRTY — D2 closure candidate (B9-A)

> **REVIEW ARTIFACT.** Prepared in B9-A for the founder's review. Nothing here has been staged, committed or pushed. B9-B executes it only after founder approval.

## 1. Governance transition required in the closure commit

From current authority, not invented:

| Item | Now | In the closure commit | Authority |
|---|---|---|---|
| ADR-024 | Proposed | **Accepted** | ADR-024 header: "accepted only together with the D2 closure"; Consequences: "becomes Accepted only in the single D2 closure commit" |
| ADR-023 | Proposed | **Accepted** | ADR-023 header: "What Accepted still needs: the ADR-024 implementation (batches B1–B9) and the complete D2 gate" — both met at closure |
| D2 (tracker) | NOT COMPLETE | **PASS — COMPLETE** | The governed completion state Phases A–D use (`**STATUS: PASS — COMPLETE**`). Phase E's gate then waits for the pushed closure SHA, two positive audits and founder approval |
| Post-D2 audits | Not started | Not started — **target: the closure SHA** (recorded after the push) | Tracker "POST-D2 AUDITS" row; ADR-024 Consequences |
| Phase E | HOLD | **HOLD** | Tracker Phase E: "ON HOLD until … both independent post-D2 audits of that SHA are positive, and the founder approves" |
| `docs/product/README.md` ADR index | 023/024 "Proposed (not accepted)" | 023/024 "Accepted" | Must match the ADR headers |

**Proposed exact edits:**
- **ADR-023 / ADR-024 status lines:** "**Status:** Accepted (D2 closure, 2026-10-xx)." Keep each ADR's history bullets.
- **Tracker header rows:**
  - `D2` → "PASS — COMPLETE (closure commit; ADR-023 Accepted, ADR-024 Accepted). Post-D2 audits pending on the closure SHA."
  - `CURRENT IMPLEMENTATION PHASE` → "PHASE D2 — PASS — COMPLETE; awaiting the two independent post-D2 audits of the closure SHA. Phase E on hold."
- **Tracker D2 section:** a "**STATUS: PASS — COMPLETE**" line, plus a log entry that names the founder approval of B9-A.
- **README index:** "— Accepted".
- **Three more lines that say "Proposed" until the closure** (found in the B9-A acceptance review), each flipped in the same commit:
  - `PRODUCT_V2_CONTRACT.md` Amendment 2: "realised by ADR-024 (Proposed)" → "(Accepted)";
  - ADR-022 header: "Superseded by ADR-024 (Proposed, founder decision 2026-10-17)" → "(Accepted …)";
  - ADR-023 history: "Amended by ADR-024 (Proposed, 2026-10-17)" → "(Accepted …)".
- **Corrected now, before closure** (stale wording, not acceptance): ADR-024 "Implementation", ADR-023 "What Accepted still needs", and the tracker's Phase D line ("Their removal is D2 batch B1, still pending"). At closure, ADR-024's "Implementation" line becomes "B1–B9 complete" and ADR-023's "What Accepted still needs" line is removed or marked met.

A material blocker from either audit reopens D2 under a new SHA, and both audits restart.

## 2. Full D2 contract gate

| Area | Requirement | Result | Evidence |
|---|---|---|---|
| **Core** | One primary daily Circle; one replacement a day; no browse/reroll; Free Today complete | **PASS** | S25 Round A ("Something different instead", no second Not this one); B7/B8 tests |
| **PGC** | Composition, hard gates, quality gate, deterministic, entitlement | **PASS** | B2 45/45 + 957/957 equivalence; B7 entitlement matrix (7 billing states); B8 sims (311/311 and 365/365 composed); S25 Round B |
| **Plans** | Exactly three; five stages; steering; Stage 5 A–D; wait / set aside / revisit; pause / leave / repeat; reviews; lapse | **PASS** | B3/B4 tests; B8 Stage 5 exhaustive (625×3, 1,827 composed); 40 adversarial cycles ×3; S25 (stage 2 → 3 by one; B9 top-up: review case A, review case D, Go through it again) |
| **Insights** | Six families; gates; evidence; 7-day cadence; 28-day same-claim; Not-now suppression; I5 exception; cap; delete invalidation | **PASS** | B5 suite + 12-month runs; B8 sims (0 cadence / same-claim / cap violations, one review per cycle after the fix); S25 (Not now → quiet; applied I2; B9 top-up: applied I3 Leave it out) |
| **Ownership** | Kept Circles; History/calendar; Memory; export/delete; lapse fairness | **PASS** | S25 Rounds C–E; Delete verified against storage (no Android backup; set-aside Plans/Insights records now deleted too, with a test); B8 lapse run (nothing lost; 111/120 days covered by kept Circles); B8 Delete longitudinal |
| **Voice** | Locke / Heather / Milo / Brittney; 172 files; entitlement; background; corrected Locke clip | **PASS** | 172/172 match `PRODUCTION_SHA1.txt`; S25 (foreground `GuidanceService`, player events, survives Home); four voices on You; voiceless on lapse |
| **IA** | Today \| Plans \| Insights \| You; Yours under You; History secondary; no Toolkit/Path/routine destination | **PASS** | B7 shell tests (25); S25, in the phone's system dark theme and at 1.6×; live-copy guard (no retired product) |
| **Safety / trust** | No medical claims; no inferred completion; no streaks; no causal Insight claims; gated content gated | **PASS** | B8 live-copy guards (7 guards, allowlist with reasons); Insight wording shows denominators and co-occurrence only; More Energy run (every part live and safe) |
| **Commercial** | Offer describes the working product; Free not crippled; no hostage retention; no annual/trial fiction | **PASS** | B7 offer guards; S25 offer at 1.6×; the B8 commercial attack |
| **Real-user validation** | Willingness to pay, conversion, voluntary retention, answer rate, kept-Circle substitution in practice, Plan uptake, Insight usefulness, voice value, More Energy thinness | **REAL-USER VALIDATION** | B8 README, "Commercial attack"; not code failures |

**Not applicable:** none.

**Known, non-blocking findings carried to the audits:**
- More Energy is thin (WEAK).
- The Samsung speech engine garbles one label (§G4 of the closure sheet).
- Apostrophes are mixed.
- The legacy "Your routine" label is reachable only from development data.
- The older Free activity wording on the release-audit list.

## 3. Public-release safety review

**REQUIRED — NOT A D2 IMPLEMENTATION BLOCKER.**
- The tracker's Phase E release gate lists "The safety review completed for every live breathing and exertion activity".
- Safety-gated activities (pending exertion and breathing content) stay disabled in release builds: `safetyPendingContentAllowed` is false outside internal debug, and the B8 More Energy run used only live, safe parts.
- B9 activated nothing and approved nothing.

## 4. Proposed closure commit

- **Branch:** `step5-billing-integration`.
- **Base HEAD:** `27e840a19309767cc10a770b9032ddc6c5f283de`.
- **Origin:** `origin/step5-billing-integration` = `d89a03512b2f95f7bed3180f40e2451f0737edd8`. Local is **13 commits ahead, 0 behind**, so the push carries 13 + 1 commits.
- **Staging:** exact paths in `closure_stage_tracked.txt` (modified + deleted) and `closure_stage_untracked.txt`. Exclusions with reasons are in `closure_exclude.txt`.
  - Tracked: 91 paths (25 deletions), i.e. every tracked change except the line-ending-only `quiet_trail_hero_asset_view.dart`.
  - **B9-B amendment (founder-approved, 2026-10-21):** plus `.gitattributes`, which gains `artifacts/v2_phase_d2/b8/** text eol=lf` so the B8 pack test passes on a Windows checkout (`core.autocrlf=true`). That makes 92 tracked paths.
  - Untracked: 399 paths, made up of 172 audio files, 169 D2 text artifacts, 54 `lib/` and `test/` files, 2 `docs/audits/` files, ADR-024 and `PHASE_E_VOICE_USAGE_MEASUREMENT.md`.
  - Cross-checked in B9-A: every untracked file is either listed or excluded. A `git add --dry-run` of both lists resolves all 490 paths, with nothing staged.
- **Commands for B9-B** (no wildcards):
  - `git add --pathspec-from-file=artifacts/v2_phase_d2/b9/closure_stage_tracked.txt`
  - `git add --pathspec-from-file=artifacts/v2_phase_d2/b9/closure_stage_untracked.txt`
  - then `git status` must show nothing staged outside those lists.

**Proposed commit message:**

```
feat(v2-d2): D2 closure — Circle Plans, Insights and the four-tab product

Closes Phase D2 (ADR-023 and ADR-024, both Accepted in this commit):
- B1 pre-release removal: Paths, routines, tune-ups and the Toolkit
  retired; kept Circles are the only owned object, in Yours under You.
- B2 StageBrief composer seam (45/45 feasibility, 957/957 equivalence).
- B3 Plan domain and runtime; B4 Plans tab.
- B5 Insights domain (six families, cadence, 28-day claim cooldown);
  B6 Insights tab with the restored calendar.
- B7 final shell Today | Plans | Insights | You, offer copy, Leave-it-out
  entitlement fix, You hierarchy.
- B8 whole-product simulations, live-copy guards, content review pack;
  fix: a Plan review dropped by the 52-snapshot cap is never re-created.
- Delete history also removes a Plans or Insights record set aside as
  unreadable.
- Production voice: 4 voices, 172 files (PASS — FROZEN), now committed.
- B9-A final S25 device QA and TalkBack, QA scenarios D4-B and D4-C
  (Plan review cases A and D); founder content closure.

Tests 2,074/0; analyze clean. Post-D2 audits #1 (Claude) and #2 (GPT-6
Astra) to run on this exact SHA; Phase E stays on hold.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
```

## 5. Immutable audit protocol (B9-B onward — not executed)

1. B9-B makes the one closure commit, from the manifests above, with the governance edits in §1.
2. **Clean verification first.** Make a worktree of the new commit at a short path (`../Thirty-verify-<sha7>`), then run `flutter pub get`, `flutter analyze` and `flutter test` there. This proves the commit is self-contained: audio, artifacts the tests read, every new file.
3. Push to `origin/step5-billing-integration`.
4. Verify that local `HEAD` equals `origin/step5-billing-integration`, with ahead/behind `0 0`.
5. Record the full 40-character SHA in the B9-B report and the audit hand-off, **not** in a new commit, so that `HEAD` stays the audited SHA.
6. **Audit #1 — Claude:** repository, implementation, product and commercial audit of exactly that SHA.
7. **Audit #2 — GPT-6 Astra:** independent product and business audit of the same SHA, ideally blind to Audit #1.
8. Any material code or doc fix after either audit means a new commit and push. Both earlier audit results become invalid for closure, and **both audits restart** on the new SHA.
9. The loose working tree is never audited.
