# World Art — Asset Freeze Reconciliation (2026-09-29)

**Status:** PRE-INTEGRATION RECONCILIATION — NOT A NEW PRODUCT SCOPE DOCUMENT
**Branch:** `step5-billing-integration`
**Revalidated:** 2026-09-30 — final asset-freeze validation after the `garden_window.tend` set was delivered (§11).
**Sits between:** approval of the V1 World artwork and Step B (artwork manifest and completeness tests, [ADR-018](../product/adr/ADR-018-v1-world-art-scene-roles-and-daypart.md#consequences)).

## Purpose and authority

This report brings the approved World artwork under `artwork/worlds/` and the documentation that describes it into a consistent, integration-ready state. It changes **filenames and stale status lines only**. It does not change any image, any design rule, any product scope or any Premium classification, and it amends no authoritative document. [WORLD_SYSTEM.md v1.1.0](../worlds/WORLD_SYSTEM.md), the World reference documents, [ADR-018](../product/adr/ADR-018-v1-world-art-scene-roles-and-daypart.md), [PREMIUM_STRATEGY.md](../product/PREMIUM_STRATEGY.md) and the frozen [Premium architecture](../product/RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md) keep their authority. Where the approved artwork and those documents disagree, the disagreement is recorded here, not resolved.

Findings fall into exactly three categories, kept separate:

| Category | Meaning |
|---|---|
| **A. MUST FIX BEFORE STEP B** | Anything that would cause wrong or ambiguous asset resolution, accidental inclusion of exploration art, impossible deterministic manifest generation, broken paths, duplicate candidate identities, invalid extensions, or a missing required production asset. |
| **B. SAFE DOC RECONCILIATION** | Objectively outdated facts only. |
| **C. FOUNDER DECISION REQUIRED** | Visual identity, allowed props, colour language, composition, World uniqueness, water in multiple Worlds, source-art version-control policy, and any merchandise or personalization implication. |

---

## 1. Production candidate matrix

**Production filename pattern:** `artwork/worlds/<world>/<world>_<scene>_<expression>_<daypart>_v1.png`, where `<scene>` is the canonical Scene Role vocabulary (`walk, breathe, move, stretch, read, write, listen, tend, comfort`), `<expression>` is `hero` or `card`, and `<daypart>` is `morning`, `day` or `evening` ([World System §10](../worlds/WORLD_SYSTEM.md#daypart-boundaries)). A file is a production candidate only if it sits directly in its World folder and matches this pattern with its own World ID and a Scene Role that World implements.

**Expected, per the authoritative documents:** 9 Scenes × 2 expressions × 3 dayparts = **54** ([ADR-018, Consequences](../product/adr/ADR-018-v1-world-art-scene-roles-and-daypart.md#consequences); [World System §16](../worlds/WORLD_SYSTEM.md#v1-roles-and-default-scenes)).
**Present on disk (revalidated 2026-09-30):** **54** production candidates, 1 excluded exploration, 55 files in total.
**Missing:** none. The 6 `garden_window.tend` files were delivered and founder-approved on 2026-09-30 (rows 50–55; §5 A-1, §11).
**Duplicates:** none. Each of the 54 (Scene, expression, daypart) combinations has exactly one candidate.

*At the original 2026-09-29 pass, 48 candidates were present and the six `tend` files were missing.*

Hashes are SHA-256 of the file bytes. Rows 1–49 are identical before and after the 2026-09-29 task and at the 2026-09-30 revalidation; rows 50–55 are the baseline recorded on 2026-09-30.

| # | World | Scene role | Expression | Daypart | Filename | Ext | Pixels | Mode | Alpha | Production candidate | SHA-256 (first 12) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | _exploration (still_lake) | breathe | hero | (none: exploration) | `still_lake_breathe_hero_sunset_exploration_v1.png` | .png | 1254x1254 | RGB | no | no | 8b8dd2f4bda5 |
| 2 | garden_window | comfort | card | day | `garden_window_comfort_card_day_v1.png` | .png | 846x941 | RGBA | yes (used) | yes | 0c558c8e643b |
| 3 | garden_window | comfort | card | evening | `garden_window_comfort_card_evening_v1.png` | .png | 830x941 | RGBA | yes (used) | yes | 3ab42f2a5077 |
| 4 | garden_window | comfort | card | morning | `garden_window_comfort_card_morning_v1.png` | .png | 938x941 | RGBA | yes (used) | yes | 82e5d339d5f3 |
| 5 | garden_window | comfort | hero | day | `garden_window_comfort_hero_day_v1.png` | .png | 722x708 | RGB | no | yes | 8fc8a16a97fb |
| 6 | garden_window | comfort | hero | evening | `garden_window_comfort_hero_evening_v1.png` | .png | 717x724 | RGB | no | yes | 321e0cfa0d44 |
| 7 | garden_window | comfort | hero | morning | `garden_window_comfort_hero_morning_v1.png` | .png | 728x724 | RGB | no | yes | 636e55846ca4 |
| 8 | open_room | move | card | day | `open_room_move_card_day_v1.png` | .png | 1254x1254 | RGBA | yes (used) | yes | 938a9ea003d5 |
| 9 | open_room | move | card | evening | `open_room_move_card_evening_v1.png` | .png | 1254x1254 | RGBA | yes (used) | yes | ffcb78084f3e |
| 10 | open_room | move | card | morning | `open_room_move_card_morning_v1.png` | .png | 1254x1254 | RGBA | yes (used) | yes | 0ce8d45d6688 |
| 11 | open_room | move | hero | day | `open_room_move_hero_day_v1.png` | .png | 1254x1254 | RGB | no | yes | c0827c2d3ad6 |
| 12 | open_room | move | hero | evening | `open_room_move_hero_evening_v1.png` | .png | 1402x1122 | RGB | no | yes | 813dc3c95d46 |
| 13 | open_room | move | hero | morning | `open_room_move_hero_morning_v1.png` | .png | 1254x1254 | RGB | no | yes | 1ff0c6d736fc |
| 14 | open_room | stretch | card | day | `open_room_stretch_card_day_v1.png` | .png | 1254x1254 | RGBA | yes (used) | yes | ec3e4bb0b941 |
| 15 | open_room | stretch | card | evening | `open_room_stretch_card_evening_v1.png` | .png | 1254x1254 | RGBA | yes (used) | yes | 9031f85ae161 |
| 16 | open_room | stretch | card | morning | `open_room_stretch_card_morning_v1.png` | .png | 1254x1254 | RGBA | yes (used) | yes | 64967a0c9a9e |
| 17 | open_room | stretch | hero | day | `open_room_stretch_hero_day_v1.png` | .png | 1254x1254 | RGB | no | yes | 5ecced0721f3 |
| 18 | open_room | stretch | hero | evening | `open_room_stretch_hero_evening_v1.png` | .png | 1254x1254 | RGB | no | yes | a750cbdd56f8 |
| 19 | open_room | stretch | hero | morning | `open_room_stretch_hero_morning_v1.png` | .png | 1254x1254 | RGB | no | yes | f7a15fedfb92 |
| 20 | quiet_trail | walk | card | day | `quiet_trail_walk_card_day_v1.png` | .png | 1254x1254 | RGBA | yes (used) | yes | bc97510cda86 |
| 21 | quiet_trail | walk | card | evening | `quiet_trail_walk_card_evening_v1.png` | .png | 1254x1254 | RGBA | yes (used) | yes | 9073bbf492d4 |
| 22 | quiet_trail | walk | card | morning | `quiet_trail_walk_card_morning_v1.png` | .png | 1254x1254 | RGBA | yes (used) | yes | a002a1d6920d |
| 23 | quiet_trail | walk | hero | day | `quiet_trail_walk_hero_day_v1.png` | .png | 1254x1254 | RGB | no | yes | f97b0f0193ab |
| 24 | quiet_trail | walk | hero | evening | `quiet_trail_walk_hero_evening_v1.png` | .png | 1254x1254 | RGB | no | yes | bc705afdc44f |
| 25 | quiet_trail | walk | hero | morning | `quiet_trail_walk_hero_morning_v1.png` | .png | 1254x1254 | RGB | no | yes | 7dfb4f463f24 |
| 26 | reading_nook | listen | card | day | `reading_nook_listen_card_day_v1.png` | .png | 717x719 | RGBA | yes (used) | yes | eb2c6c6babd3 |
| 27 | reading_nook | listen | card | evening | `reading_nook_listen_card_evening_v1.png` | .png | 719x724 | RGBA | yes (used) | yes | 9fb982922b23 |
| 28 | reading_nook | listen | card | morning | `reading_nook_listen_card_morning_v1.png` | .png | 733x718 | RGBA | yes (used) | yes | dd3ad0ebdc13 |
| 29 | reading_nook | listen | hero | day | `reading_nook_listen_hero_day_v1.png` | .png | 1254x1254 | RGB | no | yes | 13d8177a5db8 |
| 30 | reading_nook | listen | hero | evening | `reading_nook_listen_hero_evening_v1.png` | .png | 1254x1254 | RGB | no | yes | 2a02ea83a65c |
| 31 | reading_nook | listen | hero | morning | `reading_nook_listen_hero_morning_v1.png` | .png | 1254x1254 | RGB | no | yes | 6b0815587fa3 |
| 32 | reading_nook | read | card | day | `reading_nook_read_card_day_v1.png` | .png | 843x818 | RGBA | yes (used) | yes | 16cecea0faee |
| 33 | reading_nook | read | card | evening | `reading_nook_read_card_evening_v1.png` | .png | 1254x1254 | RGBA | yes (used) | yes | ef457cc03e96 |
| 34 | reading_nook | read | card | morning | `reading_nook_read_card_morning_v1.png` | .png | 1254x1254 | RGBA | yes (used) | yes | f2b8d433cf1d |
| 35 | reading_nook | read | hero | day | `reading_nook_read_hero_day_v1.png` | .png | 1254x1254 | RGB | no | yes | a60a5fa93586 |
| 36 | reading_nook | read | hero | evening | `reading_nook_read_hero_evening_v1.png` | .png | 1254x1254 | RGB | no | yes | baab9843bfb8 |
| 37 | reading_nook | read | hero | morning | `reading_nook_read_hero_morning_v1.png` | .png | 1254x1254 | RGB | no | yes | b96b49856477 |
| 38 | reading_nook | write | card | day | `reading_nook_write_card_day_v1.png` | .png | 869x832 | RGBA | yes (used) | yes | 3cefc5be6148 |
| 39 | reading_nook | write | card | evening | `reading_nook_write_card_evening_v1.png` | .png | 1254x1254 | RGBA | yes (used) | yes | 5d0054a5a262 |
| 40 | reading_nook | write | card | morning | `reading_nook_write_card_morning_v1.png` | .png | 1312x1199 | RGBA | yes (used) | yes | d06641f10cf9 |
| 41 | reading_nook | write | hero | day | `reading_nook_write_hero_day_v1.png` | .png | 1254x1254 | RGB | no | yes | 597360099e5d |
| 42 | reading_nook | write | hero | evening | `reading_nook_write_hero_evening_v1.png` | .png | 1254x1254 | RGB | no | yes | e1956f89ea37 |
| 43 | reading_nook | write | hero | morning | `reading_nook_write_hero_morning_v1.png` | .png | 1254x1254 | RGB | no | yes | a64538b1ff96 |
| 44 | still_lake | breathe | card | day | `still_lake_breathe_card_day_v1.png` | .png | 1254x1254 | RGBA | yes (used) | yes | f24c65857542 |
| 45 | still_lake | breathe | card | evening | `still_lake_breathe_card_evening_v1.png` | .png | 1254x1254 | RGBA | yes (used) | yes | e87fb3782f3d |
| 46 | still_lake | breathe | card | morning | `still_lake_breathe_card_morning_v1.png` | .png | 1254x1254 | RGBA | yes (used) | yes | 9aafb68fa6b4 |
| 47 | still_lake | breathe | hero | day | `still_lake_breathe_hero_day_v1.png` | .png | 1254x1254 | RGB | no | yes | df5d81b814b8 |
| 48 | still_lake | breathe | hero | evening | `still_lake_breathe_hero_evening_v1.png` | .png | 1254x1254 | RGB | no | yes | f3a6d387c5c1 |
| 49 | still_lake | breathe | hero | morning | `still_lake_breathe_hero_morning_v1.png` | .png | 1254x1254 | RGB | no | yes | f98f710a5639 |
| 50 | garden_window | tend | card | day | `garden_window_tend_card_day_v1.png` | .png | 1254x1254 | RGBA | yes (used) | yes | 45afe1394452 |
| 51 | garden_window | tend | card | evening | `garden_window_tend_card_evening_v1.png` | .png | 1254x1254 | RGBA | yes (used) | yes | 35fe78f1beb5 |
| 52 | garden_window | tend | card | morning | `garden_window_tend_card_morning_v1.png` | .png | 1124x1023 | RGBA | yes (used) | yes | ebadf617802a |
| 53 | garden_window | tend | hero | day | `garden_window_tend_hero_day_v1.png` | .png | 1536x1024 | RGB | no | yes | 182ff07d9aa4 |
| 54 | garden_window | tend | hero | evening | `garden_window_tend_hero_evening_v1.png` | .png | 1536x1024 | RGB | no | yes | 66cf282a2060 |
| 55 | garden_window | tend | hero | morning | `garden_window_tend_hero_morning_v1.png` | .png | 1536x1024 | RGB | no | yes | b3d110bbadc4 |

**Observations for Step B's technical checks (not blockers, not changed):**

- Hero files are RGB (no alpha) and Card files are RGBA with a used alpha channel, as [§10a](../worlds/WORLD_SYSTEM.md#10a-shared-world-art-rules-v1) expects for feathered Cards.
- Dimensions vary. Most files are 1254×1254. Exceptions: `open_room_move_hero_evening_v1.png` is 1402×1122 (non-square); the Garden Window Heroes are about 720 px square and include a baked, rounded paper frame the other Heroes do not have; several Reading Nook and Garden Window Cards are between 717 and 1312 px and not square. Step B should check each of these at its rendered size and density (for example, Hero cover-crop inside the Circle at 3×) before choosing export sizes. None of this prevents deterministic resolution.
- The `garden_window.tend` Heroes (rows 53–55) are 1536×1024 (3:2, non-square), and `garden_window_tend_card_morning_v1.png` is 1124×1023. The `tend` Heroes therefore differ in size and aspect from the roughly 720 px square `comfort` Heroes in the same World. The same Step B render check applies; this is not a blocker.

---

## 2. Safe filename changes performed

All changes are filesystem renames (`mv`) of untracked files. No image was opened for writing, re-encoded, re-exported, cropped or resized. Every file's SHA-256 was recorded before and after, and all 49 are byte-identical (§9).

**Scene vocabulary: `reading/writing/listening` → `read/write/listen`** (18 files, `artwork/worlds/reading_nook/`)

| Before | After |
|---|---|
| `reading_nook_reading_{hero,card}_{morning,day,evening}_v1.png` | `reading_nook_read_{hero,card}_{morning,day,evening}_v1.png` |
| `reading_nook_writing_{hero,card}_{morning,day,evening}_v1.png` | `reading_nook_write_{hero,card}_{morning,day,evening}_v1.png` |
| `reading_nook_listening_{hero,card}_{morning,day,evening}_v1.png` | `reading_nook_listen_{hero,card}_{morning,day,evening}_v1.png` |

**Double extension fixed and exploration moved out of the production namespace** (1 file)

| Before | After |
|---|---|
| `artwork/worlds/still_lake/still_lake_breathe_hero_sunset_exploration_v1.png.png` | `artwork/worlds/_exploration/still_lake/still_lake_breathe_hero_sunset_exploration_v1.png` |

**`_v1` suffixes:** checked. Every Open Room file, and every other file, already ended in `_v1.png`. **No change was needed.**

**References updated:** before this task, the old filenames appeared only in [THIRTY_SIGNATURE_OBJECTS.md](THIRTY_SIGNATURE_OBJECTS.md): its §3.1 exclusion note, its inventory table and §3.4 item 9. Those references were updated. That document's status (FUTURE EXPLORATION / NON-BINDING) and content are otherwise unchanged. No Dart source, `pubspec.yaml`, asset manifest or test references `artwork/`.

---

## 3. Exploration files excluded

| File | Why excluded |
|---|---|
| `artwork/worlds/_exploration/still_lake/still_lake_breathe_hero_sunset_exploration_v1.png` | An exploration, not a daypart asset. It shows a sunset, which [World System §10](../worlds/WORLD_SYSTEM.md#daypart-boundaries) excludes from evening artwork. |

**Convention used:** `artwork/worlds/_exploration/<world>/`. No existing project convention contradicted it. A leading underscore can never be a World ID, and the folder is outside every `<world>/` folder. The file's name also cannot match the production pattern, because `sunset_exploration` is not a daypart. It is kept, not deleted.

No reference images, superseded images or accidental duplicates were found under `artwork/worlds/`.

---

## 4. Stale documentation updated (Category B)

Only the four newer World references were stale. Each still said "master artwork pending" and "No master illustration exists yet", although the V1 Scene × Daypart artwork for those Worlds now exists and is founder-approved.

| Document | Change |
|---|---|
| [OPEN_ROOM_REFERENCE.md](../worlds/reference/OPEN_ROOM_REFERENCE.md) | Status line and the authority-note sentence updated; bounded reconciliation note added |
| [READING_NOOK_REFERENCE.md](../worlds/reference/READING_NOOK_REFERENCE.md) | Same |
| [STILL_LAKE_REFERENCE.md](../worlds/reference/STILL_LAKE_REFERENCE.md) | Same |
| [GARDEN_WINDOW_REFERENCE.md](../worlds/reference/GARDEN_WINDOW_REFERENCE.md) | Same, and it states that `garden_window.tend` artwork has not been authored. *Corrected during Step B (2026-09-30): the reference now records the `tend` set as authored and approved.* |

The new wording states that the V1 Scene × Daypart artwork has been authored and approved for integration, that **no separate World master illustration exists**, that the approved artwork differs from some of the document's rules, and that **the design rules are unchanged** pending founder decision. No emotion, composition, prop, colour, Scene or activity rule was edited.

Deliberately **not** changed:

- [QUIET_TRAIL_REFERENCE.md](../worlds/reference/QUIET_TRAIL_REFERENCE.md). Its "Draft — not yet frozen or approved" status is a governance status, not an objectively stale fact, and its master exists. It also says the Scene × Daypart pack "is a separate artistic deliverable requiring its own explicit Product Design approval". Whether the founder's visual approval should now be recorded there is a small documentation question for the founder (C-10).
- WORLD_SYSTEM.md, ADR-018, the Design System, the Brand Book and all Premium documents.

---

## 5. Integration blockers (Category A)

### A-1 — `garden_window.tend` has no artwork — **RESOLVED 2026-09-30**

> **Resolution.** The founder chose option 1: the six `garden_window.tend` artworks were authored and approved. They are present under `artwork/worlds/garden_window/` with canonical names (§1 rows 50–55). The matrix is 54/54. The text below is the original 2026-09-29 finding, kept for the record.


- **Fact.** The role `tend` is registered: `WorldSceneRole.tend` → `GardenWindowScenes.tend` in `lib/core/worlds/registered_worlds.dart`. Three catalogued activities use it: `activeHouseholdTask`, `tidyOneSurface` and `unhurriedTidyPause` (`lib/features/home/application/activity_catalog.dart`). No `garden_window_tend_*` file exists anywhere under `artwork/`.
- **Authority.** [ADR-018](../product/adr/ADR-018-v1-world-art-scene-roles-and-daypart.md#consequences) scopes "five Worlds and nine Scenes, each with Hero and Card × three dayparts (54 production artworks)" and states: "**Missing artwork must fail the completeness check before any UI swap.**" [World System §16](../worlds/WORLD_SYSTEM.md#v1-roles-and-default-scenes) lists `tend` as a V1 role with default Scene `garden_window.tend`.
- **Note on the task brief.** The brief's list of V1 Scene Roles and expected matrix omit `tend`. The repository's authoritative documents and code do not. This report does not assume either reading is intended.
- **Why it is Category A.** It is a missing required production asset. A deterministic manifest cannot give three live activities any artwork, and a Step B completeness check written to ADR-018 would fail.
- **Why it cannot be fixed here.** Creating artwork, placeholders or aliases is out of scope, and remapping roles is a product and architecture decision. `DefaultWorldScenePolicy` also rejects a default Scene that implements a different role, so `tend` cannot simply point at `garden_window.comfort` without a code change.
- **Smallest decisions available to the founder (choose one):**
  1. Author and approve the six `garden_window.tend` artworks, then run Step B against 54.
  2. Approve an explicit, recorded V1 amendment to ADR-018 / World System §16 that serves `tend` differently (for example, reusing the comfort artwork for `tend` in V1). This needs its own ADR and a Step A-level code change.
  3. Explicitly split Step B: build the manifest and completeness test against 54 now, with `tend` reported as incomplete, and keep the UI swap (Step C) blocked until the artwork exists. This follows ADR-018 as written, but Step B would not finish green.

### A-2 — stale duplicate of one Quiet Trail Card in `assets/` (a Step B entry condition, not a naming blocker) — **SOURCE CONFIRMED 2026-09-30**

> **Founder confirmation (2026-09-30).** The canonical Quiet Trail source is the approved file under `artwork/worlds/quiet_trail/`. The older differing copy under `assets/worlds/quiet_trail/` (`quiet_trail_walk_card_morning_v1.png`, SHA-256 `c1c7f9d35962…`) is **not authoritative and must not be used as the Step B source**. The revalidation pass neither deleted nor overwrote it; replacing it is left to Step B.


- **Fact.** `assets/worlds/quiet_trail/quiet_trail_walk_card_morning_v1.png` exists in `assets/` (untracked, pre-existing, not touched by this task) with **different pixels** from the approved `artwork/worlds/quiet_trail/quiet_trail_walk_card_morning_v1.png` (SHA-256 `c1c7f9d35962…` vs `a002a1d6920d…`; both 1254×1254 RGBA; the `assets/` copy is about 10 minutes older). The matching Hero, `quiet_trail_walk_hero_morning_v1.png`, is byte-identical in both places.
- **Consequence.** Two files share one candidate identity. Step B must take `artwork/worlds/` as its only source and replace or regenerate the `assets/` copy. It must not treat the older preview copy as canonical. The founder should confirm that the `artwork/` version is the approved one; the audit inspected the `artwork/` version.

No other Category A issue remains after the renames in §2: the 54 candidates (48 at the original pass, plus the 6 `tend` files delivered 2026-09-30) have unique, deterministic, canonical names; no `.png.png` remains; no exploration file matches the production pattern; no path is broken.

---

## 6. Non-blocking visual variances

These are consistent with the current contracts, or allowed by them, and need no decision to integrate.

| # | Variance | Contract check | Classification |
|---|---|---|---|
| V-1 | **Notebook binding.** `write` Heroes show a bound notebook (open in morning; closed with the pen on top in day and evening). Cards show an open spiral-bound notebook. | [§10a Hero ↔ Card](../worlds/WORLD_SYSTEM.md#10a-shared-world-art-rules-v1) requires shared Scene *anchors* and forbids *introducing objects* the Hero lacks. The [Reading Nook reference §6](../worlds/reference/READING_NOOK_REFERENCE.md#6-hero--card-continuity) requires a shared "Scene object". Neither requires identical prop construction; the notebook is the same object in both. | Non-blocking variance. The Hero's open-versus-closed state is covered by C-4. |
| V-2 | **Open Room plant.** The Hero shows a small tree in a large white stone pot; Cards show a broad-leaf plant in a speckled white pot. | [Open Room reference §6](../worlds/reference/OPEN_ROOM_REFERENCE.md#6-hero--card-continuity): "The Card may omit … the plant." Place identity §1 asks only for "one tall, leafy plant in a corner", which both satisfy. A strict reading of §10a ("may not introduce objects the Hero does not contain") could treat a *different* plant as a new object. | Non-blocking variance; the founder may confirm the lenient reading. |
| V-3 | **Throw pattern.** Reading Nook throws are striped in Heroes and checked in Cards. | Not an anchor; no identity rule applies. | Non-blocking. |
| V-4 | **Garden Window throw.** It reads sage by day and blue-grey in evening. | Daypart lighting ([§10](../worlds/WORLD_SYSTEM.md#10-daypart-and-weather-mood)). | Non-blocking. |
| V-5 | **Speaker in `listen`.** A small round speaker appears in the Heroes only. | The Card may omit optional objects. | Non-blocking. |
| V-6 | **No speaker in `move`.** None of the six files shows the speaker. | The speaker is listed as optional. | Non-blocking. |
| V-7 | **Technical dimension and frame differences** (§1). | No contract states pixel dimensions. | Non-blocking; Step B render check. |

---

## 7. Founder decisions required (Category C)

None of these blocks Step B: none affects deterministic asset resolution. Each quotes the source rule and gives the smallest decision that would close it. The artwork stays as approved until a decision is made.

### C-1 — Reading Nook mug

- **Observed.** All 18 Reading Nook files (three Scenes × Hero and Card × three dayparts) show a cream mug with a blue pattern on the side table.
- **Conflicting rules.**
  - [World System §10a](../worlds/WORLD_SYSTEM.md#10a-shared-world-art-rules-v1), World-exclusive motifs: "A garden seen through a window; **cups and drinks**; the table — Garden Window."
  - [Reading Nook reference](../worlds/reference/READING_NOOK_REFERENCE.md#reading_nookread--role-read), `read` → Never: "**a cup (cups belong to Garden Window)**".
  - For context, §10a also says generically: "Ordinary single scene objects — one book, one chair, **one cup**, one radio — are allowed." The motif table is the more specific rule.
- **Blocks Step B?** No.
- **Smallest decision.** Either (a) keep the rule, accept the mug as a known V1 art deviation, and revisit it in a later art pass; or (b) amend §10a and the Reading Nook reference so that a cup may appear in Reading Nook as a secondary prop while remaining Garden Window's *focal* motif.

### C-2 — Open Room `stretch` bottle

- **Observed.** A sage bottle with a copper-toned cap and a rolled cream towel stand at the end of the mat in all six `stretch` files. No bottle appears in `move`.
- **What the documents say.**
  - `move` → Never: "gym equipment, weights, trainers or shoes; mirrors; fitness trackers or **water bottles**; disco lights; music notes."
  - `stretch` → Never: "figures in poses; blocks and straps arranged like a studio class; mirrors; instruction posters." There is **no bottle prohibition** for `stretch`.
  - `stretch` → Optional objects: "a folded blanket, the plant, the curtain." The bottle is not listed; the document does not say whether optional lists are exhaustive.
  - [§10a](../worlds/WORLD_SYSTEM.md#10a-shared-world-art-rules-v1), in every World: "fitness equipment or any performance aesthetic" is never allowed.
- **Conclusion.** There is **no direct textual conflict**; `move` rules do not carry over to `stretch`. **Founder clarification is needed** on two open readings: whether optional-object lists are exhaustive, and whether a reusable bottle counts as "fitness equipment / performance aesthetic" under §10a. The explicit bottle ban in `move` shows the reference author read bottles as a fitness cue, at least there.
- **Blocks Step B?** No.
- **Smallest decision.** Confirm that the bottle (and towel) are acceptable in `stretch`, or record them as a deviation for a later art pass.

### C-3 — Reading Nook colours (and palette breadth generally)

- **Observed.** The armchair is cream. The throw, large cushion, book and notebook covers, shelf spines and mug pattern repeat a clear blue.
- **Conflicting rules.**
  - [Reading Nook reference §1](../worlds/reference/READING_NOOK_REFERENCE.md#1-place-identity), anchor 1: "A deep armchair in **Circle Sage** fabric."
  - [World DNA](../worlds/WORLD_SYSTEM.md#reading-nook): Primary Colours "Warm Stone, Cream, **Circle Sage (armchair fabric)**; illustration-only pigment: restrained warm lamp glow."
  - [§10a Palette](../worlds/WORLD_SYSTEM.md#10a-shared-world-art-rules-v1): Worlds are painted from Circle Sage, Mist Sage, Warm Stone, Cream and paper white, plus **at most one approved pigment**. Reading Nook's approved pigment is the lamp glow, not blue.
  - Related, observed but outside this item: several day skies (the Open Room Heroes; Quiet Trail and Still Lake Cards) are a clear, fairly saturated blue. [§6](../worlds/WORLD_SYSTEM.md#6-illustration-language) says to avoid "saturated colours", and [§8](../worlds/WORLD_SYSTEM.md#8-colour-and-light) asks for "a narrow colour range".
- **Blocks Step B?** No. Colour does not affect resolution; dark-theme legibility is a normal Step B review item under §10a.
- **Smallest decision.** Either (a) record the Reading Nook blues and the sky blues as approved V1 illustration exceptions, or (b) keep the rules and schedule palette alignment for a later art pass.

### C-4 — Reading Nook Hero cues (`read` and `write`)

- **Observed.** All nine Reading Nook Heroes share one base composition. The `read` Heroes show only a closed blue book on the side table; no Hero shows an open book. In the `write` Heroes the notebook is open only in morning; in day and evening it is closed with the pen on top. **No writing desk appears in any `write` file.** The pen is a pen, not a pencil. The Card cues are clear.
- **Contract text.**
  - [`read`](../worlds/reference/READING_NOOK_REFERENCE.md#reading_nookread--role-read) Hero: "an **open book** resting naturally on the armrest or adjacent side table". Mandatory anchors: "the chair, the book, the lamp". The book is present, but not open.
  - [`write`](../worlds/reference/READING_NOOK_REFERENCE.md#reading_nookwrite--role-write) Hero: "a small **writing desk** tucked into the alcove under the window, with an **open notebook, a pencil** and the lamp over the desk". Mandatory anchors: "**the desk surface with the open notebook**, the lamp; in the Hero, the chair or the shelf".
- **Assessment.** The reference does specify stronger Hero differentiation. The `write` mandatory anchor (desk surface) is absent, and the open-notebook anchor is absent in two of three dayparts. This is a composition and art-direction question, not a technical one.
- **Blocks Step B?** No. The files resolve deterministically.
- **Smallest decision.** Either (a) accept the chair-based `write` composition and closed-book `read` Heroes for V1 (and, if wanted, amend the reference to match), or (b) keep the reference and schedule a later Hero revision.

### C-5 — Still Lake jetty (Hero ↔ Card continuity)

- **Observed.** The Still Lake Heroes show the flat shore rock, reeds, level water and a low far shore. All three Cards show a wooden jetty, rounded shore stones, cattails, prominent pines and a mountain, none of which appears in the Heroes, and no single flat focal rock.
- **Contract text.**
  - [§10a Hero ↔ Card](../worlds/WORLD_SYSTEM.md#10a-shared-world-art-rules-v1): "The Card **may not introduce objects the Hero does not contain**."
  - [Still Lake reference §6](../worlds/reference/STILL_LAKE_REFERENCE.md#6-hero--card-continuity): "Shared: **the rock**, the water, the level horizon …"
  - [World DNA](../worlds/WORLD_SYSTEM.md#still-lake): "a small wooden jetty appearing over time" is listed as a **Personal Growth element** (deferred), not a base-state object.
- **Assessment.** The contract asks for shared anchors and forbids new objects; it does not ask for identical geometry. The jetty and mountain are new objects, so this is a **true conflict** with an explicit rule. It also overlaps with deferred Growth content.
- **Blocks Step B?** No.
- **Smallest decision.** Either (a) accept the Still Lake Cards as a recorded V1 exception to the no-new-objects rule, noting the jetty is not yet the Growth-stage jetty; or (b) schedule a Card revision.

### C-6 — Open water outside Still Lake (major, World uniqueness)

- **Observed.** Lakes appear in Quiet Trail (Hero and Card, all dayparts), in the Open Room windows (all 12 files), in the Reading Nook window (all 18 files) and in Still Lake. Garden Window shows a garden and no lake.
- **Rule texts.**
  - [§10a World-exclusive motifs](../worlds/WORLD_SYSTEM.md#10a-shared-world-art-rules-v1): "**Open water and reflections** — Still Lake"; "An empty floor under tall windows; **windows showing only sky** — Open Room".
  - [Open Room reference §1](../worlds/reference/OPEN_ROOM_REFERENCE.md#1-place-identity): tall windows that "show **only sky and pale light**".
  - [Reading Nook reference §1](../worlds/reference/READING_NOOK_REFERENCE.md#1-place-identity): "**One small window** — secondary, showing sky or a single branch".
- **The two readings. This report does not choose between them.**
  1. *"Only Still Lake may contain open water."* Then Quiet Trail, Open Room and Reading Nook all deviate.
  2. *"Still Lake is the World where still, open water is the dominant emotional and focal identity; other Worlds may include water as contextual scenery."* Then the art is consistent, but §10a's motif table and the Open Room and Reading Nook window rules would need a clarifying amendment.
- **Blocks Step B?** No.
- **Smallest decision.** Choose reading 1 or reading 2, and record it in the World System (by amendment or ADR).

### C-7 — Open Room evening light source

- **Observed.** The Open Room evening Heroes and Cards are lit by the moon through the glass. No floor lamp is visible.
- **Rule texts.** [Open Room reference §3](../worlds/reference/OPEN_ROOM_REFERENCE.md#3-daypart-direction), evening: "A single warm **floor lamp becomes the dominant light** and takes over the pool of light on the floor". [§10a](../worlds/WORLD_SYSTEM.md#10a-shared-world-art-rules-v1): "Every evening Scene has one clearly dominant light source — the moon outdoors, **a lamp indoors**."
- **Blocks Step B?** No.
- **Smallest decision.** Accept the moonlit interior as a V1 exception, or schedule a later evening revision.

### C-8 — Other reference-composition divergences (for completeness)

Recorded briefly; the same "accept or revise later" decision applies to each.

- **Garden Window.** The DNA Hero Focus is "the terracotta potted plant on the sill". In the art, a pot sits secondary at the right window edge, and the focus is the window seat, cushions, mug and throw. The anchor "a wooden table beneath the window" appears as a small round stool-table beside the seat.
- **Quiet Trail.** The DNA Hero Focus is "one organic tree **on a distant hill**". In the art, the tree is on the near left hillside.
- **Reading Nook.** The shelf is visible, but "the enclosed framing of the alcove" reads as an open room with a large window.

### C-9 — World master illustrations

- **Fact.** [ADR-018](../product/adr/ADR-018-v1-world-art-scene-roles-and-daypart.md#consequences) scopes the 54 production artworks "**plus an approved master per new World**". No separate master file exists for Still Lake, Open Room, Reading Nook or Garden Window; Quiet Trail's master exists in `assets/`.
- **Blocks Step B?** No. Masters are not resolved by the Scene × Daypart manifest.
- **Smallest decision.** Confirm whether the approved Scene artwork satisfies the "master" requirement, or whether separate masters are still owed.

### C-10 — Quiet Trail reference status

- **Fact.** The reference still reads "Draft — not yet frozen or approved" and says the Scene × Daypart pack requires "its own explicit Product Design approval".
- **Blocks Step B?** No.
- **Smallest decision.** Whether to record the founder's approval of the Quiet Trail daypart pack in that reference.

### C-11 — Artwork source version control

See §8.

**Future-facing implications.** Nothing here promotes any object from [THIRTY_SIGNATURE_OBJECTS.md](THIRTY_SIGNATURE_OBJECTS.md) into V1, and no decision above has a merchandise or personalization dimension in V1.

---

## 8. Version control and artwork source

**Current state.**

- `artwork/` is **untracked**: not committed and not listed in `.gitignore`. It is about 98 MB of PNG files.
- The existing tracked production World asset is `assets/worlds/quiet_trail/quiet_trail_hero_master_v1.png`, committed in `567d243` ("feat(worlds): integrate Quiet Trail Hero master v1.0"). It is declared per folder in `pubspec.yaml` (`assets/worlds/quiet_trail/`).
- Two further untracked preview copies exist in `assets/worlds/quiet_trail/` (see A-2).

**Existing repository convention found.** Production, app-bundled World assets live under `assets/worlds/<world>/` and are tracked in git, by the precedent of the Quiet Trail master. There is **no existing convention, document or ADR for source or review artwork** (the high-resolution approved originals under `artwork/`). The repository does not record whether source art is tracked, ignored, kept elsewhere or stored with Git LFS.

**Recommendation, supported by the repository.** Step B should place its production derivatives in `assets/worlds/<world>/`, using the canonical names from §1 and following the tracked Quiet Trail precedent, and should treat `artwork/worlds/` as its only input.

**OWNER DECISION REQUIRED.** What happens to `artwork/` itself — track the source art, keep it outside production git, track only derivatives, use LFS, or another policy — is not governed. This report does not decide it and commits nothing.

---

## 9. No artwork pixels changed

- 49 files under `artwork/` were hashed (SHA-256) before and after this task. **All 49 hashes are identical**, mapped through the 19 renames and moves listed in §2.
- No image was opened for writing, converted (PNG → WebP belongs to Step B), resized, cropped, recoloured, regenerated or replaced. No file was deleted.
- `assets/`, `pubspec.yaml` and all Dart code are unchanged.

---

## 10. Readiness verdict for Step B

**Technical integration readiness (revalidated 2026-09-30): READY.** A-1 is resolved (54/54), and the founder has confirmed the A-2 source. See §11.

*Original 2026-09-29 verdict: NOT READY, solely because of A-1.*

Technically ready:

- the 54 candidates have unique, deterministic, canonical filenames;
- no `.png.png` remains;
- no exploration file matches the production pattern or sits in a World folder;
- no candidate identity is duplicated inside `artwork/worlds/`;
- A-2 is an entry condition that Step B satisfies by sourcing only from `artwork/worlds/`, as the founder has confirmed.

The naming and documentation are ready for Step B. Every Category C item is a **post-integration / art-direction follow-up**, explicitly non-blocking, and none was silently resolved.

---

## Premium and scope safety

- The Premium freeze is unchanged: its SHA-256 is still `1d4bb7aab996a5e01b8b9b3961275110d54a2da9315407feb639304149ca5e0d`, as recorded in ADR-018.
- No V1 scope is expanded. No Signature Object, merchandise, personalized prop or visual correction is classified as Premium or as a V1 commitment.
- The daypart artwork remains Free/shared, per ADR-018.

---

## 11. Final asset-freeze revalidation (2026-09-30)

**Scope.** Validation only, after the six `garden_window.tend` files were delivered. No file under `artwork/` or `assets/` was renamed, moved, deleted or created. No Flutter, Dart, `pubspec.yaml` or test file was changed, and nothing was committed. Only this report was edited.

| Check | Result |
|---|---|
| Production matrix | **54/54**: 9 registered Scenes × Hero and Card × morning, day and evening. The registered roles were checked against `lib/core/worlds/registered_worlds.dart`: walk, breathe, move, stretch, read, write, listen, tend and comfort. |
| Every Scene has exactly one Hero and one Card for each of the three dayparts | **Pass** for all 9 Scenes. |
| Duplicate production identities in `artwork/worlds/` | **None.** No two files share an identity, and no two production files share bytes. |
| Exploration files matching the production pattern | **None.** One exploration is excluded: `_exploration/still_lake/still_lake_breathe_hero_sunset_exploration_v1.png`. |
| Canonical Scene Role vocabulary in filenames | **Pass.** All 54 match `<world>_<scene>_<hero or card>_<daypart>_v1.png`, with the World's own ID and a role that World implements. No `.png.png` remains. |
| Artwork pixels unchanged | **Pass.** All 49 previously recorded files have the same SHA-256 as in §1. The 6 new files' hashes are recorded as the baseline (§1 rows 50–55). The `assets/worlds/quiet_trail/` hashes are also unchanged. |
| Flutter integration | **Not started.** |
| Quiet Trail source | Founder-confirmed: `artwork/worlds/quiet_trail/` is canonical, and the older differing `assets/` copy is not authoritative (§5 A-2). The `assets/` copy was left in place. |

**Step B readiness: READY.** Step B must take its source only from `artwork/worlds/`. The remaining items do not block it:

- the Category C founder art-direction questions (§7), none of which was resolved here;
- ~~the stale `tend` clause in GARDEN_WINDOW_REFERENCE.md (§4)~~ — corrected in Step B;
- the `artwork/` version-control policy (§8);
- the Step B render check of non-uniform dimensions (§1).

---

## 12. Step B — production integration (2026-09-30)

**Status: integrated, 54/54.** Not committed. Final state: §13.

**Production assets.** Every source under `artwork/worlds/<world>/` becomes `assets/worlds/<world>/<scene>/<hero|card>_<morning|day|evening>.webp`. The runtime names carry no `_v1`, and `Daypart.afternoon` uses the `day` suffix. Each Scene folder is declared in `pubspec.yaml`, since folder entries are not recursive. `artwork/` and `_exploration/` are not bundled. The older `assets/worlds/quiet_trail/*.png` preview copies (§5 A-2) are not a source and are not referenced by the manifest.

| Item | Value |
|---|---|
| Tool | Pillow 12.3.0 / libwebp 1.6.0 |
| Settings | lossy, `quality=90`, `method=6`, `alpha_quality=100` (lossless alpha), `exact=True` |
| Geometry | Unchanged: every output has its source's pixel dimensions, with no resize, crop or matte |
| Alpha | 27 Cards are RGBA → RGBA with alpha byte-identical (max difference 0). 27 Heroes are RGB → RGB, with no alpha added |
| Fidelity | Minimum alpha-weighted PSNR is 32.9 dB (`garden_window/tend/card_evening`). A 1:1 visual comparison showed no visible difference |
| Size | 116,676,894 B of source → 18,575,646 B of production (−84.1%) |
| Sources | Byte-identical before and after (SHA-256 checked for each file) |

**Manifest and resolution.**

- `lib/core/worlds/world_art_manifest.dart` defines `WorldSceneArt`, which requires six explicit paths per Scene, and `WorldArtManifest`. The manifest checks itself against the registry: a registered Scene without artwork, artwork for an unknown Scene, or an asset mapped twice is an error.
- `lib/core/worlds/registered_world_art.dart` holds `v1WorldArtManifest`, the 54 paths.
- `resolveWorldArt()` in `world_scene_resolution.dart` builds one immutable `ResolvedWorldArt`: activity → Scene Role → policy Scene → compatible World → Daypart → Hero and Card together. It has no fallback.
- `resolvedWorldArtProvider` resolves from `nowProvider`, which is also the moment Home's greeting uses and is refreshed only on a foreground resume. `CircleHero` holds its snapshot through First Breath. A re-resolution that arrives mid-ritual waits until the ritual completes, and one that arrives later crossfades both Hero and Card together.

**Presentation.**

- The Hero is drawn with `BoxFit.cover`, centred inside the existing `ClipOval`.
- The `comfort` Heroes are enlarged 1.1× for presentation only, so their baked paper frame (§1) never reaches the Circle's edge.
- The Today card shows its snapshot's `cardAsset` with its existing treatment unchanged: `contain`, bottom-right, decorative, and hidden at text scale ≥1.3 or card width <300. *Superseded by the approved V1 treatment in §13.*

**Device QA (Pixel 7 emulator, API 37).**

- Checked all 27 Scene × Daypart states in light mode, 18 in dark mode, 200% text in light and dark, and a live First Breath on `tend`.
- Every Hero and Card pair matched its Scene and Daypart. Nothing was stretched, and no frame showed at the Circle.
- Card alpha was clean and text was unobscured, with no overflow and no runtime errors.

**Art follow-ups for founder review (category B, not changed).**

- The Still Lake Heroes dissolve into paper white along their bottom edge (an authored watercolor vignette). Inside the Circle this reads as a pale lower arc, most visibly in the evening.
- The `garden_window.comfort` Heroes carry a baked frame. It is handled by the 1.1× presentation zoom; a frameless re-export would remove the need for it.

---

## 13. Step B — final state (2026-09-30)

**Status: implemented and validated.** Not committed. [ADR-018](../product/adr/ADR-018-v1-world-art-scene-roles-and-daypart.md) now reads "Implemented and validated"; its decision is unchanged.

### Today card art — APPROVED / FROZEN FOR V1

This treatment was approved by the founder on 2026-09-30 from `artifacts/world_art_qa/card_viewport_v2/comparisons/_overview.png`. It is not iterated further unless a regression is found. It lives in `lib/features/home/presentation/widgets/today_card.dart` (`_TodayArt`).

| Aspect | Frozen value |
|---|---|
| Viewport | Right side of the card, starting exactly at the text-safe boundary: where the text column's content ends (75% of the card width minus the card's `featuredCard` padding). On Pixel 7 this is about 32% of the card width. It is not widened to 38–42%, because that would overlap the text. |
| Scale | The art is drawn at 112% of the card height, keeps its aspect ratio, is never stretched, and is anchored right. |
| Clipping | The top, right and bottom overscan is clipped by the viewport and the card's rounded boundary. |
| Left edge | A soft alpha fade from the viewport's left edge, fully transparent there, across the first 45% of the viewport's width. It is relative to the viewport, not to the image. |
| Dark mode | Art opacity 0.85, with a paper backing of the art's own silhouette in Cream at 0.12 (§10a), inside the same fade. Light mode draws the art alone at full opacity. |
| Geometry | Identical in light and dark mode. The crossfade fills the viewport and never re-centres the art (this fixes a Step B side effect). |
| Unchanged | The art is decorative (`ExcludeSemantics`), hidden at text scale ≥1.3 or card width <300, and has no tap handling. Text, typography and card size are unchanged. |
| Accepted | The irregular watercolor edge still visible on the art's left side. |

The treatment is locked by these tests:
- `home_page_d1_test` ("never overlaps the text");
- `today_card_test`: the light and dark treatment values, one art box in both themes starting at the text edge, the 112% height and overscan, decorative semantics, and the large-text hide rule.

### Cleanup

- **Dev preview:** the debug-only Quiet Trail preview (`QuietTrailHeroAssetView`, route `/dev/quiet-trail-hero-preview`) had an uncommitted "TEMP preview" edit pointing it at an older preview PNG, so its test failed. The edit was reverted to the committed master path; the view and its test agree again. Production World resolution never used it.
- **Legacy PNGs:** `pubspec.yaml` no longer declares the whole `assets/worlds/quiet_trail/` folder. It lists only the tracked `quiet_trail_hero_master_v1.png` that the debug preview uses.
  - The older, non-authoritative `quiet_trail_walk_card_morning_v1.png` and `quiet_trail_walk_hero_morning_v1.png` (§5 A-2) **remain on disk, untracked, but are no longer bundled or referenced**. Deleting them is left to the founder.
- **Bundle lock:** `world_art_manifest_test` asserts that `assets/worlds/` ships exactly the 54 production WebPs plus that master, and nothing from `artwork/` or `_exploration/`.

### Validation

- `dart format`: no changes needed. `flutter analyze`: no issues.
- `flutter test`: **1226 passed, 0 failed**.
- Device QA: Pixel 7 emulator, API 37.
  - Step B: all 27 Scene × Daypart states, dark mode and 200% text (`artifacts/world_art_qa/step_b/`).
  - The dark-card polish and viewport experiments (`dark_card_polish/`, `card_viewport_v2/`).
  - 12 true full-Home captures through the normal app entry (`full_home_final/`).

### Still open (unchanged, not resolved here)

- The founder art-direction questions C-1 to C-11 (§7).
- The Still Lake pale lower arc and the comfort Heroes' baked frame (§12).
- The visual similarity of the Reading Nook `read` and `write` Heroes (C-4).
- The artwork source version-control policy (§8).
- Whether to delete the debug preview route and the unbundled legacy PNGs.
- ~~Pre-existing layout, for review: Start Circle vs the floating navigation on tall Today cards.~~ **Resolved 2026-09-30 with a near-fit compact rhythm** (an earlier "keep scrolling" decision was superseded after founder visual review). Home stays one scroll document in its normal order (header → Circle → greeting → support line → Today card → Start Circle → secondary content), and the nav never covers it. When the usual gaps would leave Start Circle just below the first screen, the three hero gaps above it (Circle → greeting, greeting → card, card → CTA) tighten from `m` (16) to `s` (8), 24dp at most, so it sits fully on screen at least `s` above the fold. This is `HomeRhythmColumn`, decided in a single layout pass. Layouts that already fit are pixel-identical. Larger overflow (360×740 phones, 200% text) keeps the usual rhythm and scrolls. The change is spacing only: no size, typography, card, CTA or nav change. Locked by `test/features/home/home_cta_nav_layout_test.dart`, which covers Pixel 7 tend, Quiet Trail, Reading Nook dark, a Plan day, a small phone and 200% text. Evidence: `artifacts/world_art_qa/home_spacing_refinement/`.
