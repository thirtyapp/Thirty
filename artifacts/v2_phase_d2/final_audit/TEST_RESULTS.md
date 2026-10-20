# Tests and analyze — final hardening pass (2026-10-12)

All runs were on Windows, from the worktree on branch `step5-billing-integration`.

| Run | Command | Result |
|---|---|---|
| Analyze | `flutter analyze` | **No issues found** |
| Full regular suite (final) | `flutter test --exclude-tags long` | **1,681 passed, 0 failed** |
| Long-horizon simulations | `flutter test --tags long` | **14 profiles passed** (p01–p13 plus `p14_more_energy_dominant`; day 1 → month 12, production providers) |
| Focused: composed runtime, voice, background session | `test/features/personal_circle/composed_ui_test.dart` | 30 passed |
| Focused: the platform session channel | `test/features/personal_circle/guidance_session_test.dart` | 2 passed (new) |
| Focused: content pack and guards (with export) | `d2_review_pack_test.dart --dart-define=EXPORT_REVIEW=true` | 4 passed |
| Focused: semantic dependencies, composer, elements, Premium Today, lapse attack | `test/features/personal_circle/` | all passed in the full run |
| S25 geometry: every element as the part on show | `test/features/home/home_cta_nav_layout_test.dart` | passed — after it caught the long "Look far away" sentence, which was then tightened |

## New regression tests in this pass

- **Start speaks "First."** and opens the session, which keeps the device awake for the rest of the Circle.
- **Out of sight**, the next part is spoken on time and once — by the voice, not deferred to a screen reader — and the return shows the right part without repeating the cue (with Android lifecycle transitions driven).
- **The notification's controls:**
  - Pause holds the Circle's time and lets the device sleep;
  - Resume carries on where it was;
  - Next moves exactly once and records nothing as skipped.
- **The ending** is spoken once after the last part, and the session ends after it.
- **First look:** a first look past the last part says nothing, not even the ending.
- **Close and the voice switch** end the session at once; turning the voice back on reopens it.
- **Without the voice** there is no session at all.
- **Channel ownership:** an older platform session going away never silences the current one (S25 defect A).

## Failures seen and fixed during the pass (not dismissed)

**`home_cta_nav_layout_test`:**
- **Failure:** the S25 first-screen geometry failed for `lookFar` with the founder's longer wording.
- **Fix:** the copy was tightened, keeping its meaning (CONTENT_REVIEW §0).

**`composed_ui_test` — "this build bundles none":**
- **Failure:** it failed while the temporary test tones were in `pubspec.yaml`. That is expected, and is the guard against committing recordings.
- **Fix:** it passes again with pubspec restored.

**`composed_ui_test` / `phase_c_session_ui_test` — "A Timer is still pending":**
- **Cause:** a voiced Circle left the conductor's one-second check running past the widget tree, and an `autoDispose` conductor left Riverpod's disposal timer pending when a test swapped containers.
- **Fix:** voiced tests now end their container explicitly, and the conductor is a plain provider that lives exactly as long as its container.

## The previously flaky test

- **The test:** `qa_scenario_test.dart` "the same scenario and reference date always build the same store" failed once under full-suite load in the correction pass.
- **This pass:** it **passed in all three full runs** (1680+1, 1681, 1681).
- **What was checked:** the store build reads no wall clock, no timers and no randomness. The replay helper's `_settle()` is a zero-delay turn, and the persistence chain is microtask-only.
- **Not reproduced:** no root cause was found. It stays on watch.

## Long-horizon runs on the committed HEAD

The 14 long-horizon simulations were run twice:
- once during the pass;
- **again on the committed HEAD `27e840a`**: 14 passed.

The two copy fixes changed words, not element ids, needs, roles, minutes or settings, so composition is unchanged. The `SIMULATION_REVIEW.md` figures from the correction pass stand: p14 More Energy has 9 mains and 31 materially distinct sessions at month 12; the lapse attack served 40 of 60 lapsed days from kept Circles.

---

# Tests and analyze — production voice pass (2026-10-16)

Run from the worktree on `step5-billing-integration`, with the **168 production clips bundled** (`assets/audio/guidance/voice_*_v1/`). Nothing is committed yet.

| Run | Command | Result |
|---|---|---|
| Manifest drift | `d2_review_pack_test.dart --dart-define=EXPORT_REVIEW=true` → `build/d2_spoken_guidance_manifest.csv` | 4 passed. The CSV is **byte-identical** to `SPOKEN_GUIDANCE_MANIFEST.csv` |
| Analyze | `flutter analyze` | **No issues found** (re-run after the temporary QA log line was removed) |
| Full regular suite | `flutter test --exclude-tags long` | **1,723 passed, 0 failed** |
| Long-horizon simulations | `flutter test --tags long` | **14 passed** (p01–p14, day 1 → month 12) |
| Focused: voice, entitlement, session, lapse attack, You | `guidance_entitlement_test`, `composed_ui_test`, `guidance_session_test`, `saved_circle_lapse_attack_test`, `you_c1_test` | **63 passed** (re-run on the final code) |

## New or changed tests

**`composed_ui_test.dart`:**
- **Inverted:** "this build bundles none" became "this build bundles the four production voices, each complete". It checks exactly the 4 × 42 manifest assets in the real asset bundle, nothing stale and nothing else.
- **All or nothing:** one missing clip, or one recorded for an older script, silences that voice and no other (`completeGuidanceVoices`).
- **Identities:** stable and neutral (`voice_*_v1`), never gender; the display names are Locke, Heather, Milo and Brittney.

**`guidance_entitlement_test.dart`:**
- **Rewritten for four voices:** the female/male slots became the named voices.
- **New preview test:** the four voices are offered by name, and the preview plays the chosen voice's own production recordings ("First." plus "Phone face down"), all of them clips the Circle itself plays.
- **New:** with spoken guidance off there is no voice to choose or hear.
- **New:** a stored choice no voice answers to (the pre-release `female` placeholder) speaks in the first voice and is not erased.
