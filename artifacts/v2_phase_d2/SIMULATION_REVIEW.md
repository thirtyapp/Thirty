# THIRTY Phase D2 — long-horizon INTERNAL simulation review

**These are not user-validation results.** They are deterministic, scripted users run day by day through the production providers (composer, engine, journal, preferences, Toolkit) to catch architectural failure — repetition, degeneration, evidence that changes nothing, leaks of excluded content, broken lapse — before pre-release users see the product. They report behaviour only; no "value score" is derived. Real users are the only evidence of value.

Source: `test/features/personal_circle/personal_circle_simulation_test.dart` (tag `long`), traces in `simulations/`. Each profile runs 365 local days. Regenerated 2026-10-11 after the founder correction pass (14 profiles, all passing).

## Reading (behaviour only)

- **Every Premium day did the work:** 0 fallbacks in 14 × 365 days. The lapse profile composed nothing during its Free month and composed again from the day it resubscribed.
- **Not a loop** (p01–p13):
  - 96–269 unique sessions a year per profile;
  - no identical session within 15 days;
  - no main piece on more than 22 % of days;
  - the three most-used parts make up 19–25 % of all parts.
- **Relevant before varied:**
  - `p02` likes walking and tending and dislikes music. After day 60, liked kinds lead 186 of 305 Circles (61 %) and music leads none.
  - `p04` likes reading and listening and dislikes tidying and walking. Liked kinds lead 5 of 30 in the first month and 156 of 305 after day 60.
- **Honest time use:** the median is 80–100 % of the chosen window. The lowest is 60 %: a coherent shorter session when nothing longer fits honestly.
- **Truthful line:** sparse feedback (`p01`, `p11`) never earns "Built from things you've found useful".
- **Hard limits held all year, asserted day by day:**
  - no gated or retired part;
  - nothing left out ever returned;
  - nothing the user asked THIRTY not to suggest was composed;
  - since the correction pass, no part that builds on another appears without it, directly before it.
- **What these do not show:** whether anyone finds the sessions worth a subscription. Only pre-release users can.

## Correction pass (2026-10-11)

### What changed in the composer

**One rule only.** A part that builds on another ("Choose one thing" after "Get it out") must come *directly* after it. Ranges against the previous run (Month 12, p01–p13):

| Measure | Previous run | This run |
|---|---|---|
| Unique sessions | 97–251 | 96–269 |
| Materially distinct | 39–120 | 37–144 |
| Distinct mains | 13–18 | 13–18 |
| Median repeat | 30–72 | 30–72 |
| Shortest repeat | 15–20 | 15–24 |
| Top main | ≤ 0.22 | ≤ 0.22 |
| Top-3 parts | 0.19–0.25 | 0.19–0.25 |
| Fallbacks | 0 | 0 |

### More Energy attack — `p14_more_energy_dominant` (More Energy days only)

| | Day 30 | Month 3 | Month 6 | Month 12 |
|---|---|---|---|---|
| More Energy Circles | 24 | 71 | 141 | 284 |
| Fallbacks | 0 | 0 | 0 | 0 |
| Unique compositions | 23 | 48 | 61 | 79 |
| Materially distinct (main + second) | 18 | 24 | 25 | 31 |
| Distinct mains | 8 | 9 | 9 | 9 |
| Median / shortest repeat (days) | 17 / 17 | 25 / 15 | 32 / 15 | 39 / 15 |
| Top main share | 0.21 | 0.27 | 0.28 | 0.29 |
| Top-3 parts share | 0.34 | 0.36 | 0.34 | 0.34 |
| Median / lowest time use | 0.87 / 0.73 | 0.95 / 0.63 | 0.95 / 0.60 | 0.95 / 0.60 |
| "Found useful" basis | 12 | 54 | 122 | 264 |

**Evidence-driven adaptation:**
- Liked kinds (music, movement) lead 10 of 24 Circles in the first month and 154 of 237 after day 60 (42 % → 65 %).
- The kind found not useful (tidying) leads 6 of 24, then 15 of 237 (25 % → 6 %).

**Reading.**
- No degeneration: no fallbacks, no repeat within 15 days, and no main on more than 29 % of days.
- The thinnest need is visibly narrower than the others:
  - 9 mains, against 13–18 when needs are mixed;
  - 31 materially distinct sessions a year, against 37–144;
  - unique sessions a year: 79 of 284 here, against 96–269 for the mixed-need profiles. Each unique More Energy session returns about 3.6 times a year, at a median of 39 days.
- This is the content boundary already on record: More Energy's exertion and breathing content waits for its safety review. It is reported, not padded. Whether it is "enough" is a founder judgement.

**Why tidying still leads 15 Circles after day 60.** This was investigated, and it is not a degeneration.
- The scripted user also answered "Very useful" on days when tidying was the *second* piece behind a liked main.
- A composed answer credits main and second alike (ADR-023 §7), so tidying's evidence is mixed rather than negative.
- A composer change that kept net-negative mains out while anything else passes was tried. It changed nothing, so it was reverted: the pass stays bounded.
- **For the post-D2 audit:** one answer per session cannot separate a liked main from a disliked second. "Leave it out next time" is the user's precise control for that.

### Saved-Circle / lapse attack (`saved_circle_lapse_attack_test.dart`)

- **Script:** Premium days 1–40 (keeps a Circle every fourth day, up to the limit of 8; sometimes uses one instead); lapsed days 41–100; Premium again days 101–120.
- **Verified:**
  - kept Circles stay owned through the lapse, ids unchanged, and can be renamed while Free;
  - a kept Circle is never on Today unless the user chose it;
  - "Use it today" works while Free;
  - one Circle a day: after Start nothing replaces it, and there is exactly one journal entry per date;
  - no composition on any lapsed day, and no "fallback" line on Free days;
  - composition again on the first day back;
  - every entry is attributed to what it was: a kept-Circle day carries its kept id and is composite, never an answer about one activity.
- **Lapse days:**
  - 60 lapsed days in all;
  - **40 served by a kept Circle the user chose** (whenever one for today's need fit today's time);
  - **20 served by Free's Today**;
  - 0 composed.
- **COMMERCIAL HYPOTHESIS for the post-D2 audit:** a user with 8 kept Circles across the three needs can replace most new composition after cancelling. Ownership was not weakened in response. Whether this erodes the subscription is unproven either way.


## Profiles

| Profile | Script |
|---|---|
| `p01_sparse_feedback` | Needs rotate, mixed time; answers one day in five. |
| `p02_frequent_feedback` | Answers every day: likes writing, walking, tending; dislikes music. |
| `p03_stable_positive` | Answers every day, always Very or Somewhat useful. |
| `p04_mixed` | Likes reading and listening; dislikes tidying and walking; skips disliked parts. |
| `p05_one_need_dominant` | Clearer Head four days in five; likes writing and focus. |
| `p06_all_three_needs` | All three needs evenly, always ≈20 minutes; likes movement. |
| `p07_mostly_10_minutes` | Mostly ≈10 minutes. |
| `p08_mostly_20_minutes` | Mostly ≈20 minutes. |
| `p09_mostly_30_minutes` | Mostly up to 30 minutes. |
| `p10_lapse_and_resubscribe` | Premium for three months, Free for one, then Premium again. |
| `p11_many_exclusions` | Leaves out six parts on first sight; asks THIRTY not to suggest two activities. |
| `p12_routine_owner` | Builds a routine with a Path in month one (Clearer Head), up to 30 minutes. |
| `p13_no_routine` | The same user without a routine. |
| `p14_more_energy_dominant` | Correction pass. More Energy on ~84 % of days (Clearer Head every 7th, Gentler Pace every 11th); ≈10 / ≈20 / up to 30 mixed 2:2:1; answers every day — likes music and movement, finds tidying not useful. Reported for its More Energy days only. |

## Month 12, every profile

| Profile | Circles | fallbacks | unique | material | mains | median repeat (d) | shortest repeat (d) | top-3 parts | top main | same first | "found useful" | median use | lowest use |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `p01_sparse_feedback` | 365 | 0 | 227 | 109 | 18 | 72 | 24 | 0.20 | 0.09 | 2 | 0 | 0.95 | 0.67 |
| `p02_frequent_feedback` | 365 | 0 | 132 | 37 | 14 | 36 | 15 | 0.23 | 0.18 | 0 | 357 | 0.90 | 0.77 |
| `p03_stable_positive` | 365 | 0 | 118 | 42 | 14 | 39 | 15 | 0.22 | 0.18 | 0 | 357 | 0.95 | 0.60 |
| `p04_mixed` | 365 | 0 | 189 | 88 | 18 | 48 | 15 | 0.19 | 0.20 | 2 | 229 | 0.95 | 0.63 |
| `p05_one_need_dominant` | 365 | 0 | 269 | 144 | 14 | 70 | 20 | 0.22 | 0.20 | 0 | 268 | 0.95 | 0.73 |
| `p06_all_three_needs` | 365 | 0 | 162 | 63 | 15 | 36 | 15 | 0.25 | 0.20 | 0 | 305 | 0.95 | 0.75 |
| `p07_mostly_10_minutes` | 365 | 0 | 96 | 38 | 13 | 30 | 15 | 0.25 | 0.22 | 0 | 339 | 1.00 | 0.80 |
| `p08_mostly_20_minutes` | 365 | 0 | 150 | 63 | 15 | 45 | 15 | 0.22 | 0.12 | 0 | 120 | 0.95 | 0.75 |
| `p09_mostly_30_minutes` | 365 | 0 | 120 | 60 | 14 | 33 | 18 | 0.24 | 0.22 | 0 | 338 | 0.93 | 0.63 |
| `p10_lapse_and_resubscribe` | 335 | 0 | 178 | 84 | 17 | 48 | 15 | 0.19 | 0.12 | 0 | 144 | 0.95 | 0.73 |
| `p11_many_exclusions` | 365 | 0 | 155 | 75 | 18 | 48 | 15 | 0.23 | 0.09 | 0 | 0 | 0.95 | 0.60 |
| `p12_routine_owner` | 354 | 0 | 163 | 69 | 14 | 45 | 15 | 0.20 | 0.22 | 1 | 132 | 0.80 | 0.60 |
| `p13_no_routine` | 365 | 0 | 153 | 64 | 13 | 54 | 15 | 0.21 | 0.22 | 1 | 119 | 0.80 | 0.60 |
| `p14_more_energy_dominant` (More Energy days) | 284 | 0 | 79 | 31 | 9 | 39 | 15 | 0.34 | 0.29 | 0 | 264 | 0.95 | 0.60 |

## Before → after the composer correction (Month 12)

The first full run exposed degeneration: answers about a whole Circle credited its arrival and close, evidence was a sum (so frequency compounded into dominance), nothing was ever tried that had no evidence yet, short sessions were barely penalised, and identical sessions could return within days. The correction (ADR-023 §3): confidence-weighted mean evidence; composed answers credit only the main and second piece; a modest bonus for a main piece not tried this month; a cost that grows below 80 % time use; no identical session within 7 days and any part at most 3 times a week (both relaxed only if nothing else passes).

| Profile | unique | material | mains | shortest repeat | top-3 parts | same first | median use | lowest use |
|---|---|---|---|---|---|---|---|---|
| `p01_sparse_feedback` | 128 → 227 | 63 → 109 | 16 → 18 | 15 → 24 | 0.23 → 0.20 | 5 → 2 | 0.90 → 0.95 | 0.60 → 0.67 |
| `p02_frequent_feedback` | 37 → 132 | 27 → 37 | 12 → 14 | 3 → 15 | 0.24 → 0.23 | 0 → 0 | 0.80 → 0.90 | 0.60 → 0.77 |
| `p03_stable_positive` | 40 → 118 | 24 → 42 | 11 → 14 | 15 → 15 | 0.25 → 0.22 | 0 → 0 | 0.85 → 0.95 | 0.60 → 0.60 |
| `p04_mixed` | 77 → 189 | 41 → 88 | 16 → 18 | 3 → 15 | 0.23 → 0.19 | 0 → 2 | 0.85 → 0.95 | 0.60 → 0.63 |
| `p05_one_need_dominant` | 87 → 269 | 57 → 144 | 8 → 14 | 5 → 20 | 0.30 → 0.22 | 26 → 0 | 0.90 → 0.95 | 0.60 → 0.73 |
| `p06_all_three_needs` | 29 → 162 | 12 → 63 | 7 → 15 | 15 → 15 | 0.24 → 0.25 | 4 → 0 | 0.95 → 0.95 | 0.80 → 0.75 |
| `p07_mostly_10_minutes` | 32 → 96 | 12 → 38 | 6 → 13 | 15 → 15 | 0.23 → 0.25 | 0 → 0 | 1.00 → 1.00 | 0.90 → 0.80 |
| `p08_mostly_20_minutes` | 29 → 150 | 17 → 63 | 8 → 15 | 15 → 15 | 0.24 → 0.22 | 4 → 0 | 0.95 → 0.95 | 0.70 → 0.75 |
| `p09_mostly_30_minutes` | 32 → 120 | 26 → 60 | 9 → 14 | 15 → 18 | 0.28 → 0.24 | 0 → 0 | 0.83 → 0.93 | 0.60 → 0.63 |
| `p10_lapse_and_resubscribe` | 70 → 178 | 39 → 84 | 11 → 17 | 6 → 15 | 0.25 → 0.19 | 1 → 0 | 0.85 → 0.95 | 0.60 → 0.73 |
| `p11_many_exclusions` | 51 → 155 | 26 → 75 | 11 → 18 | 6 → 15 | 0.30 → 0.23 | 0 → 0 | 0.80 → 0.95 | 0.60 → 0.60 |
| `p12_routine_owner` | 32 → 163 | 22 → 69 | 10 → 14 | 15 → 15 | 0.25 → 0.20 | 3 → 1 | 0.80 → 0.80 | 0.60 → 0.60 |
| `p13_no_routine` | 30 → 153 | 19 → 64 | 8 → 13 | 15 → 15 | 0.28 → 0.21 | 0 → 1 | 0.83 → 0.80 | 0.63 → 0.60 |

## Checkpoints, per profile

### `p01_sparse_feedback`

| | Day 1 | Day 7 | Day 30 | Month 3 | Month 6 | Month 12 |
|---|---|---|---|---|---|---|
| days with a Circle | 1 | 7 | 30 | 90 | 180 | 365 |
| Premium days | 1 | 7 | 30 | 90 | 180 | 365 |
| Personal Guided Circles | 1 | 7 | 30 | 90 | 180 | 365 |
| fell back to Free | 0 | 0 | 0 | 0 | 0 | 0 |
| routine days | 0 | 0 | 0 | 0 | 0 | 0 |
| Path days | 0 | 0 | 0 | 0 | 0 | 0 |
| unique compositions (element sets) | 1 | 7 | 30 | 79 | 138 | 227 |
| materially distinct (main + second) | 1 | 7 | 27 | 56 | 77 | 109 |
| distinct main pieces | 1 | 7 | 18 | 18 | 18 | 18 |
| median repeat interval (days) | None | None | None | 36 | 36 | 72 |
| shortest repeat interval (days) | None | None | None | 24 | 24 | 24 |
| top-3 parts share | 0.75 | 0.25 | 0.19 | 0.18 | 0.19 | 0.20 |
| top main share | 1.00 | 0.14 | 0.10 | 0.11 | 0.10 | 0.09 |
| same first part as previous Circle | 0 | 0 | 0 | 0 | 1 | 2 |
| same last part as previous Circle | 0 | 0 | 0 | 0 | 1 | 4 |
| "found useful" basis | 0 | 0 | 0 | 0 | 0 | 0 |
| median time use | 1.00 | 1.00 | 1.00 | 0.95 | 0.95 | 0.95 |
| lowest time use | 1.00 | 1.00 | 0.80 | 0.75 | 0.75 | 0.67 |
| liked-kind mains, days 1–30 | None | None | None | None | None | None |
| liked-kind mains, after day 60 | None | None | None | None | None | None |
| disliked-kind mains, days 1–30 | None | None | None | None | None | None |
| disliked-kind mains, after day 60 | None | None | None | None | None | None |

### `p02_frequent_feedback`

| | Day 1 | Day 7 | Day 30 | Month 3 | Month 6 | Month 12 |
|---|---|---|---|---|---|---|
| days with a Circle | 1 | 7 | 30 | 90 | 180 | 365 |
| Premium days | 1 | 7 | 30 | 90 | 180 | 365 |
| Personal Guided Circles | 1 | 7 | 30 | 90 | 180 | 365 |
| fell back to Free | 0 | 0 | 0 | 0 | 0 | 0 |
| routine days | 0 | 0 | 0 | 0 | 0 | 0 |
| Path days | 0 | 0 | 0 | 0 | 0 | 0 |
| unique compositions (element sets) | 1 | 7 | 30 | 59 | 97 | 132 |
| materially distinct (main + second) | 1 | 7 | 21 | 30 | 37 | 37 |
| distinct main pieces | 1 | 7 | 14 | 14 | 14 | 14 |
| median repeat interval (days) | None | None | None | 27 | 36 | 36 |
| shortest repeat interval (days) | None | None | None | 15 | 15 | 15 |
| top-3 parts share | 0.75 | 0.26 | 0.26 | 0.26 | 0.24 | 0.23 |
| top main share | 1.00 | 0.14 | 0.13 | 0.16 | 0.17 | 0.18 |
| same first part as previous Circle | 0 | 0 | 0 | 0 | 0 | 0 |
| same last part as previous Circle | 0 | 0 | 0 | 2 | 3 | 5 |
| "found useful" basis | 0 | 0 | 22 | 82 | 172 | 357 |
| median time use | 1.00 | 1.00 | 0.95 | 0.93 | 0.93 | 0.90 |
| lowest time use | 1.00 | 0.80 | 0.80 | 0.77 | 0.77 | 0.77 |
| liked-kind mains, days 1–30 | 0/1 | 2/7 | 13/30 | 13/30 | 13/30 | 13/30 |
| liked-kind mains, after day 60 | None | None | None | 17/30 | 73/120 | 186/305 |
| disliked-kind mains, days 1–30 | 1/1 | 1/7 | 1/30 | 1/30 | 1/30 | 1/30 |
| disliked-kind mains, after day 60 | None | None | None | 0/30 | 0/120 | 0/305 |

### `p03_stable_positive`

| | Day 1 | Day 7 | Day 30 | Month 3 | Month 6 | Month 12 |
|---|---|---|---|---|---|---|
| days with a Circle | 1 | 7 | 30 | 90 | 180 | 365 |
| Premium days | 1 | 7 | 30 | 90 | 180 | 365 |
| Personal Guided Circles | 1 | 7 | 30 | 90 | 180 | 365 |
| fell back to Free | 0 | 0 | 0 | 0 | 0 | 0 |
| routine days | 0 | 0 | 0 | 0 | 0 | 0 |
| Path days | 0 | 0 | 0 | 0 | 0 | 0 |
| unique compositions (element sets) | 1 | 7 | 29 | 68 | 92 | 118 |
| materially distinct (main + second) | 1 | 7 | 19 | 36 | 39 | 42 |
| distinct main pieces | 1 | 7 | 12 | 13 | 14 | 14 |
| median repeat interval (days) | None | None | 18 | 36 | 45 | 39 |
| shortest repeat interval (days) | None | None | 18 | 15 | 15 | 15 |
| top-3 parts share | 0.75 | 0.25 | 0.26 | 0.21 | 0.21 | 0.22 |
| top main share | 1.00 | 0.14 | 0.20 | 0.19 | 0.19 | 0.18 |
| same first part as previous Circle | 0 | 0 | 0 | 0 | 0 | 0 |
| same last part as previous Circle | 0 | 0 | 0 | 0 | 0 | 1 |
| "found useful" basis | 0 | 0 | 22 | 82 | 172 | 357 |
| median time use | 1.00 | 1.00 | 1.00 | 0.95 | 0.95 | 0.95 |
| lowest time use | 1.00 | 0.80 | 0.67 | 0.63 | 0.60 | 0.60 |
| liked-kind mains, days 1–30 | None | None | None | None | None | None |
| liked-kind mains, after day 60 | None | None | None | None | None | None |
| disliked-kind mains, days 1–30 | None | None | None | None | None | None |
| disliked-kind mains, after day 60 | None | None | None | None | None | None |

### `p04_mixed`

| | Day 1 | Day 7 | Day 30 | Month 3 | Month 6 | Month 12 |
|---|---|---|---|---|---|---|
| days with a Circle | 1 | 7 | 30 | 90 | 180 | 365 |
| Premium days | 1 | 7 | 30 | 90 | 180 | 365 |
| Personal Guided Circles | 1 | 7 | 30 | 90 | 180 | 365 |
| fell back to Free | 0 | 0 | 0 | 0 | 0 | 0 |
| routine days | 0 | 0 | 0 | 0 | 0 | 0 |
| Path days | 0 | 0 | 0 | 0 | 0 | 0 |
| unique compositions (element sets) | 1 | 7 | 30 | 81 | 141 | 189 |
| materially distinct (main + second) | 1 | 7 | 26 | 54 | 77 | 88 |
| distinct main pieces | 1 | 7 | 17 | 17 | 18 | 18 |
| median repeat interval (days) | None | None | None | 36 | 36 | 48 |
| shortest repeat interval (days) | None | None | None | 24 | 15 | 15 |
| top-3 parts share | 0.75 | 0.25 | 0.23 | 0.18 | 0.17 | 0.19 |
| top main share | 1.00 | 0.14 | 0.13 | 0.17 | 0.19 | 0.20 |
| same first part as previous Circle | 0 | 0 | 0 | 0 | 1 | 2 |
| same last part as previous Circle | 0 | 0 | 0 | 0 | 0 | 1 |
| "found useful" basis | 0 | 0 | 11 | 46 | 106 | 229 |
| median time use | 1.00 | 1.00 | 1.00 | 0.95 | 0.95 | 0.95 |
| lowest time use | 1.00 | 0.80 | 0.80 | 0.63 | 0.63 | 0.63 |
| liked-kind mains, days 1–30 | 0/1 | 1/7 | 5/30 | 5/30 | 5/30 | 5/30 |
| liked-kind mains, after day 60 | None | None | None | 10/30 | 55/120 | 156/305 |
| disliked-kind mains, days 1–30 | 0/1 | 2/7 | 11/30 | 11/30 | 11/30 | 11/30 |
| disliked-kind mains, after day 60 | None | None | None | 5/30 | 16/120 | 34/305 |

### `p05_one_need_dominant`

| | Day 1 | Day 7 | Day 30 | Month 3 | Month 6 | Month 12 |
|---|---|---|---|---|---|---|
| days with a Circle | 1 | 7 | 30 | 90 | 180 | 365 |
| Premium days | 1 | 7 | 30 | 90 | 180 | 365 |
| Personal Guided Circles | 1 | 7 | 30 | 90 | 180 | 365 |
| fell back to Free | 0 | 0 | 0 | 0 | 0 | 0 |
| routine days | 0 | 0 | 0 | 0 | 0 | 0 |
| Path days | 0 | 0 | 0 | 0 | 0 | 0 |
| unique compositions (element sets) | 1 | 7 | 30 | 81 | 150 | 269 |
| materially distinct (main + second) | 1 | 7 | 28 | 63 | 101 | 144 |
| distinct main pieces | 1 | 6 | 14 | 14 | 14 | 14 |
| median repeat interval (days) | None | None | None | 30 | 35 | 70 |
| shortest repeat interval (days) | None | None | None | 22 | 20 | 20 |
| top-3 parts share | 0.75 | 0.28 | 0.25 | 0.25 | 0.23 | 0.22 |
| top main share | 1.00 | 0.29 | 0.20 | 0.20 | 0.20 | 0.20 |
| same first part as previous Circle | 0 | 0 | 0 | 0 | 0 | 0 |
| same last part as previous Circle | 0 | 0 | 0 | 0 | 0 | 0 |
| "found useful" basis | 0 | 0 | 12 | 55 | 123 | 268 |
| median time use | 1.00 | 1.00 | 0.95 | 0.95 | 0.95 | 0.95 |
| lowest time use | 1.00 | 0.90 | 0.77 | 0.75 | 0.75 | 0.73 |
| liked-kind mains, days 1–30 | 0/1 | 2/7 | 8/30 | 8/30 | 8/30 | 8/30 |
| liked-kind mains, after day 60 | None | None | None | 9/30 | 32/120 | 88/305 |
| disliked-kind mains, days 1–30 | None | None | None | None | None | None |
| disliked-kind mains, after day 60 | None | None | None | None | None | None |

### `p06_all_three_needs`

| | Day 1 | Day 7 | Day 30 | Month 3 | Month 6 | Month 12 |
|---|---|---|---|---|---|---|
| days with a Circle | 1 | 7 | 30 | 90 | 180 | 365 |
| Premium days | 1 | 7 | 30 | 90 | 180 | 365 |
| Personal Guided Circles | 1 | 7 | 30 | 90 | 180 | 365 |
| fell back to Free | 0 | 0 | 0 | 0 | 0 | 0 |
| routine days | 0 | 0 | 0 | 0 | 0 | 0 |
| Path days | 0 | 0 | 0 | 0 | 0 | 0 |
| unique compositions (element sets) | 1 | 7 | 30 | 60 | 102 | 162 |
| materially distinct (main + second) | 1 | 6 | 19 | 33 | 48 | 63 |
| distinct main pieces | 1 | 7 | 13 | 14 | 15 | 15 |
| median repeat interval (days) | None | None | None | 33 | 33 | 36 |
| shortest repeat interval (days) | None | None | None | 15 | 15 | 15 |
| top-3 parts share | 0.75 | 0.25 | 0.25 | 0.24 | 0.24 | 0.25 |
| top main share | 1.00 | 0.14 | 0.20 | 0.20 | 0.20 | 0.20 |
| same first part as previous Circle | 0 | 0 | 0 | 0 | 0 | 0 |
| same last part as previous Circle | 0 | 0 | 0 | 0 | 0 | 0 |
| "found useful" basis | 0 | 0 | 12 | 71 | 158 | 305 |
| median time use | 1.00 | 1.00 | 0.95 | 0.95 | 0.95 | 0.95 |
| lowest time use | 1.00 | 0.85 | 0.75 | 0.75 | 0.75 | 0.75 |
| liked-kind mains, days 1–30 | 0/1 | 1/7 | 5/30 | 5/30 | 5/30 | 5/30 |
| liked-kind mains, after day 60 | None | None | None | 4/30 | 17/120 | 54/305 |
| disliked-kind mains, days 1–30 | None | None | None | None | None | None |
| disliked-kind mains, after day 60 | None | None | None | None | None | None |

### `p07_mostly_10_minutes`

| | Day 1 | Day 7 | Day 30 | Month 3 | Month 6 | Month 12 |
|---|---|---|---|---|---|---|
| days with a Circle | 1 | 7 | 30 | 90 | 180 | 365 |
| Premium days | 1 | 7 | 30 | 90 | 180 | 365 |
| Personal Guided Circles | 1 | 7 | 30 | 90 | 180 | 365 |
| fell back to Free | 0 | 0 | 0 | 0 | 0 | 0 |
| routine days | 0 | 0 | 0 | 0 | 0 | 0 |
| Path days | 0 | 0 | 0 | 0 | 0 | 0 |
| unique compositions (element sets) | 1 | 7 | 29 | 59 | 83 | 96 |
| materially distinct (main + second) | 1 | 7 | 22 | 33 | 38 | 38 |
| distinct main pieces | 1 | 7 | 13 | 13 | 13 | 13 |
| median repeat interval (days) | None | None | 21 | 27 | 27 | 30 |
| shortest repeat interval (days) | None | None | 21 | 15 | 15 | 15 |
| top-3 parts share | 1.00 | 0.27 | 0.21 | 0.23 | 0.24 | 0.25 |
| top main share | 1.00 | 0.14 | 0.20 | 0.21 | 0.22 | 0.22 |
| same first part as previous Circle | 0 | 0 | 0 | 0 | 0 | 0 |
| same last part as previous Circle | 0 | 0 | 0 | 1 | 1 | 1 |
| "found useful" basis | 0 | 0 | 7 | 64 | 154 | 339 |
| median time use | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |
| lowest time use | 1.00 | 0.90 | 0.80 | 0.80 | 0.80 | 0.80 |
| liked-kind mains, days 1–30 | 0/1 | 2/7 | 14/30 | 14/30 | 14/30 | 14/30 |
| liked-kind mains, after day 60 | None | None | None | 18/30 | 73/120 | 186/305 |
| disliked-kind mains, days 1–30 | None | None | None | None | None | None |
| disliked-kind mains, after day 60 | None | None | None | None | None | None |

### `p08_mostly_20_minutes`

| | Day 1 | Day 7 | Day 30 | Month 3 | Month 6 | Month 12 |
|---|---|---|---|---|---|---|
| days with a Circle | 1 | 7 | 30 | 90 | 180 | 365 |
| Premium days | 1 | 7 | 30 | 90 | 180 | 365 |
| Personal Guided Circles | 1 | 7 | 30 | 90 | 180 | 365 |
| fell back to Free | 0 | 0 | 0 | 0 | 0 | 0 |
| routine days | 0 | 0 | 0 | 0 | 0 | 0 |
| Path days | 0 | 0 | 0 | 0 | 0 | 0 |
| unique compositions (element sets) | 1 | 7 | 29 | 70 | 99 | 150 |
| materially distinct (main + second) | 1 | 6 | 23 | 38 | 48 | 63 |
| distinct main pieces | 1 | 7 | 15 | 15 | 15 | 15 |
| median repeat interval (days) | None | None | 18 | 30 | 48 | 45 |
| shortest repeat interval (days) | None | None | 18 | 15 | 15 | 15 |
| top-3 parts share | 0.75 | 0.25 | 0.24 | 0.23 | 0.22 | 0.22 |
| top main share | 1.00 | 0.14 | 0.17 | 0.12 | 0.12 | 0.12 |
| same first part as previous Circle | 0 | 0 | 0 | 0 | 0 | 0 |
| same last part as previous Circle | 0 | 0 | 0 | 0 | 0 | 0 |
| "found useful" basis | 0 | 1 | 8 | 28 | 58 | 120 |
| median time use | 1.00 | 1.00 | 0.95 | 0.95 | 0.95 | 0.95 |
| lowest time use | 1.00 | 0.85 | 0.75 | 0.75 | 0.75 | 0.75 |
| liked-kind mains, days 1–30 | 0/1 | 2/7 | 5/30 | 5/30 | 5/30 | 5/30 |
| liked-kind mains, after day 60 | None | None | None | 7/30 | 27/120 | 68/305 |
| disliked-kind mains, days 1–30 | None | None | None | None | None | None |
| disliked-kind mains, after day 60 | None | None | None | None | None | None |

### `p09_mostly_30_minutes`

| | Day 1 | Day 7 | Day 30 | Month 3 | Month 6 | Month 12 |
|---|---|---|---|---|---|---|
| days with a Circle | 1 | 7 | 30 | 90 | 180 | 365 |
| Premium days | 1 | 7 | 30 | 90 | 180 | 365 |
| Personal Guided Circles | 1 | 7 | 30 | 90 | 180 | 365 |
| fell back to Free | 0 | 0 | 0 | 0 | 0 | 0 |
| routine days | 0 | 0 | 0 | 0 | 0 | 0 |
| Path days | 0 | 0 | 0 | 0 | 0 | 0 |
| unique compositions (element sets) | 1 | 7 | 29 | 60 | 88 | 120 |
| materially distinct (main + second) | 1 | 7 | 24 | 37 | 44 | 60 |
| distinct main pieces | 1 | 7 | 13 | 13 | 13 | 14 |
| median repeat interval (days) | None | None | 18 | 33 | 33 | 33 |
| shortest repeat interval (days) | None | None | 18 | 18 | 18 | 18 |
| top-3 parts share | 0.75 | 0.23 | 0.23 | 0.23 | 0.23 | 0.24 |
| top main share | 1.00 | 0.14 | 0.20 | 0.21 | 0.22 | 0.22 |
| same first part as previous Circle | 0 | 0 | 0 | 0 | 0 | 0 |
| same last part as previous Circle | 0 | 0 | 0 | 1 | 8 | 11 |
| "found useful" basis | 0 | 0 | 20 | 77 | 164 | 338 |
| median time use | 0.80 | 0.90 | 0.93 | 0.93 | 0.93 | 0.93 |
| lowest time use | 0.80 | 0.63 | 0.63 | 0.63 | 0.63 | 0.63 |
| liked-kind mains, days 1–30 | 0/1 | 2/7 | 14/30 | 14/30 | 14/30 | 14/30 |
| liked-kind mains, after day 60 | None | None | None | 17/30 | 73/120 | 188/305 |
| disliked-kind mains, days 1–30 | None | None | None | None | None | None |
| disliked-kind mains, after day 60 | None | None | None | None | None | None |

### `p10_lapse_and_resubscribe`

| | Day 1 | Day 7 | Day 30 | Month 3 | Month 6 | Month 12 |
|---|---|---|---|---|---|---|
| days with a Circle | 1 | 7 | 30 | 90 | 180 | 365 |
| Premium days | 1 | 7 | 30 | 90 | 150 | 335 |
| Personal Guided Circles | 1 | 7 | 30 | 90 | 150 | 335 |
| fell back to Free | 0 | 0 | 0 | 0 | 0 | 0 |
| routine days | 0 | 0 | 0 | 0 | 0 | 0 |
| Path days | 0 | 0 | 0 | 0 | 0 | 0 |
| unique compositions (element sets) | 1 | 7 | 29 | 72 | 112 | 178 |
| materially distinct (main + second) | 1 | 7 | 24 | 41 | 62 | 84 |
| distinct main pieces | 1 | 7 | 15 | 17 | 17 | 17 |
| median repeat interval (days) | None | None | 24 | 36 | 48 | 48 |
| shortest repeat interval (days) | None | None | 24 | 21 | 15 | 15 |
| top-3 parts share | 0.75 | 0.25 | 0.24 | 0.22 | 0.19 | 0.19 |
| top main share | 1.00 | 0.14 | 0.13 | 0.13 | 0.12 | 0.12 |
| same first part as previous Circle | 0 | 0 | 0 | 0 | 0 | 0 |
| same last part as previous Circle | 0 | 0 | 0 | 0 | 0 | 0 |
| "found useful" basis | 0 | 0 | 0 | 5 | 38 | 144 |
| median time use | 1.00 | 1.00 | 1.00 | 1.00 | 0.95 | 0.95 |
| lowest time use | 1.00 | 0.80 | 0.80 | 0.75 | 0.75 | 0.73 |
| liked-kind mains, days 1–30 | 0/1 | 0/7 | 0/30 | 0/30 | 0/30 | 0/30 |
| liked-kind mains, after day 60 | None | None | None | 1/30 | 9/90 | 32/275 |
| disliked-kind mains, days 1–30 | None | None | None | None | None | None |
| disliked-kind mains, after day 60 | None | None | None | None | None | None |

### `p11_many_exclusions`

| | Day 1 | Day 7 | Day 30 | Month 3 | Month 6 | Month 12 |
|---|---|---|---|---|---|---|
| days with a Circle | 1 | 7 | 30 | 90 | 180 | 365 |
| Premium days | 1 | 7 | 30 | 90 | 180 | 365 |
| Personal Guided Circles | 1 | 7 | 30 | 90 | 180 | 365 |
| fell back to Free | 0 | 0 | 0 | 0 | 0 | 0 |
| routine days | 0 | 0 | 0 | 0 | 0 | 0 |
| Path days | 0 | 0 | 0 | 0 | 0 | 0 |
| unique compositions (element sets) | 1 | 7 | 29 | 69 | 104 | 155 |
| materially distinct (main + second) | 1 | 7 | 27 | 41 | 54 | 75 |
| distinct main pieces | 1 | 7 | 17 | 18 | 18 | 18 |
| median repeat interval (days) | None | None | 15 | 36 | 36 | 48 |
| shortest repeat interval (days) | None | None | 15 | 15 | 15 | 15 |
| top-3 parts share | 0.75 | 0.26 | 0.25 | 0.25 | 0.24 | 0.23 |
| top main share | 1.00 | 0.14 | 0.10 | 0.09 | 0.09 | 0.09 |
| same first part as previous Circle | 0 | 0 | 0 | 0 | 0 | 0 |
| same last part as previous Circle | 0 | 0 | 0 | 3 | 7 | 11 |
| "found useful" basis | 0 | 0 | 0 | 0 | 0 | 0 |
| median time use | 1.00 | 1.00 | 1.00 | 0.95 | 0.95 | 0.95 |
| lowest time use | 1.00 | 0.87 | 0.80 | 0.73 | 0.73 | 0.60 |
| liked-kind mains, days 1–30 | None | None | None | None | None | None |
| liked-kind mains, after day 60 | None | None | None | None | None | None |
| disliked-kind mains, days 1–30 | None | None | None | None | None | None |
| disliked-kind mains, after day 60 | None | None | None | None | None | None |

### `p12_routine_owner`

| | Day 1 | Day 7 | Day 30 | Month 3 | Month 6 | Month 12 |
|---|---|---|---|---|---|---|
| days with a Circle | 1 | 7 | 30 | 90 | 180 | 365 |
| Premium days | 1 | 7 | 30 | 90 | 180 | 365 |
| Personal Guided Circles | 1 | 7 | 21 | 79 | 169 | 354 |
| fell back to Free | 0 | 0 | 0 | 0 | 0 | 0 |
| routine days | 0 | 0 | 2 | 4 | 4 | 4 |
| Path days | 0 | 0 | 7 | 7 | 7 | 7 |
| unique compositions (element sets) | 1 | 7 | 21 | 65 | 107 | 163 |
| materially distinct (main + second) | 1 | 7 | 19 | 38 | 55 | 69 |
| distinct main pieces | 1 | 7 | 11 | 14 | 14 | 14 |
| median repeat interval (days) | None | None | None | 36 | 36 | 45 |
| shortest repeat interval (days) | None | None | None | 18 | 15 | 15 |
| top-3 parts share | 0.75 | 0.22 | 0.24 | 0.21 | 0.20 | 0.20 |
| top main share | 1.00 | 0.14 | 0.19 | 0.22 | 0.22 | 0.22 |
| same first part as previous Circle | 0 | 0 | 0 | 1 | 1 | 1 |
| same last part as previous Circle | 0 | 0 | 0 | 0 | 0 | 1 |
| "found useful" basis | 0 | 0 | 5 | 36 | 70 | 132 |
| median time use | 0.80 | 0.93 | 0.80 | 0.80 | 0.80 | 0.80 |
| lowest time use | 0.80 | 0.63 | 0.63 | 0.60 | 0.60 | 0.60 |
| liked-kind mains, days 1–30 | 1/1 | 1/7 | 4/21 | 4/21 | 4/21 | 4/21 |
| liked-kind mains, after day 60 | None | None | None | 6/30 | 26/120 | 68/305 |
| disliked-kind mains, days 1–30 | None | None | None | None | None | None |
| disliked-kind mains, after day 60 | None | None | None | None | None | None |

### `p13_no_routine`

| | Day 1 | Day 7 | Day 30 | Month 3 | Month 6 | Month 12 |
|---|---|---|---|---|---|---|
| days with a Circle | 1 | 7 | 30 | 90 | 180 | 365 |
| Premium days | 1 | 7 | 30 | 90 | 180 | 365 |
| Personal Guided Circles | 1 | 7 | 30 | 90 | 180 | 365 |
| fell back to Free | 0 | 0 | 0 | 0 | 0 | 0 |
| routine days | 0 | 0 | 0 | 0 | 0 | 0 |
| Path days | 0 | 0 | 0 | 0 | 0 | 0 |
| unique compositions (element sets) | 1 | 7 | 28 | 70 | 99 | 153 |
| materially distinct (main + second) | 1 | 7 | 24 | 36 | 51 | 64 |
| distinct main pieces | 1 | 7 | 13 | 13 | 13 | 13 |
| median repeat interval (days) | None | None | 18 | 33 | 36 | 54 |
| shortest repeat interval (days) | None | None | 18 | 18 | 15 | 15 |
| top-3 parts share | 0.75 | 0.22 | 0.22 | 0.22 | 0.21 | 0.21 |
| top main share | 1.00 | 0.14 | 0.20 | 0.21 | 0.22 | 0.22 |
| same first part as previous Circle | 0 | 0 | 0 | 0 | 0 | 1 |
| same last part as previous Circle | 0 | 0 | 0 | 0 | 1 | 1 |
| "found useful" basis | 0 | 0 | 7 | 27 | 57 | 119 |
| median time use | 0.80 | 0.93 | 0.80 | 0.80 | 0.80 | 0.80 |
| lowest time use | 0.80 | 0.63 | 0.60 | 0.60 | 0.60 | 0.60 |
| liked-kind mains, days 1–30 | 1/1 | 1/7 | 6/30 | 6/30 | 6/30 | 6/30 |
| liked-kind mains, after day 60 | None | None | None | 6/30 | 26/120 | 68/305 |
| disliked-kind mains, days 1–30 | None | None | None | None | None | None |
| disliked-kind mains, after day 60 | None | None | None | None | None | None |

### `p14_more_energy_dominant`

| | Day 1 | Day 7 | Day 30 | Month 3 | Month 6 | Month 12 |
|---|---|---|---|---|---|---|
| days with a Circle | 1 | 6 | 24 | 71 | 141 | 284 |
| Premium days | 1 | 6 | 24 | 71 | 141 | 284 |
| Personal Guided Circles | 1 | 6 | 24 | 71 | 141 | 284 |
| fell back to Free | 0 | 0 | 0 | 0 | 0 | 0 |
| routine days | 0 | 0 | 0 | 0 | 0 | 0 |
| Path days | 0 | 0 | 0 | 0 | 0 | 0 |
| unique compositions (element sets) | 1 | 6 | 23 | 48 | 61 | 79 |
| materially distinct (main + second) | 1 | 6 | 18 | 24 | 25 | 31 |
| distinct main pieces | 1 | 6 | 8 | 9 | 9 | 9 |
| median repeat interval (days) | None | None | 17 | 25 | 32 | 39 |
| shortest repeat interval (days) | None | None | 17 | 15 | 15 | 15 |
| top-3 parts share | 0.75 | 0.29 | 0.34 | 0.36 | 0.34 | 0.34 |
| top main share | 1.00 | 0.17 | 0.21 | 0.27 | 0.28 | 0.29 |
| same first part as previous Circle | 0 | 0 | 0 | 0 | 0 | 0 |
| same last part as previous Circle | 0 | 0 | 0 | 0 | 0 | 0 |
| "found useful" basis | 0 | 0 | 12 | 54 | 122 | 264 |
| median time use | 1.00 | 0.80 | 0.87 | 0.95 | 0.95 | 0.95 |
| lowest time use | 1.00 | 0.80 | 0.73 | 0.63 | 0.60 | 0.60 |
| liked-kind mains, days 1–30 | 1/1 | 2/6 | 10/24 | 10/24 | 10/24 | 10/24 |
| liked-kind mains, after day 60 | None | None | None | 16/24 | 61/94 | 154/237 |
| disliked-kind mains, days 1–30 | 0/1 | 3/6 | 6/24 | 6/24 | 6/24 | 6/24 |
| disliked-kind mains, after day 60 | None | None | None | 0/24 | 5/94 | 15/237 |

