# B5 — Insights domain (2026-10-18)

ADR-024 §11–§13, built as a domain only. There is no Insights UI, tab or calendar, and nothing in the live app calls the engine yet. Code is in `lib/features/insights/`, tests in `test/features/insights/`.

## How the authority was read

These are the points where the authority needed one consistent reading. No contradiction was found.

| Point | Reading used |
|---|---|
| **Pattern gate** (contract: "5 relevant records on 3 dates spanning 14 days, within the family's window") | A floor on each family's own records, after which the family adds its own condition. The records are: a need's choices (I1); the active Plan's stage offers (I2); composed Circles (I3, and I4's need); each window (I6). This lets I3's "3 of the last 4 Circles it was part of" coexist with the floor. I5 has no gate. |
| **Spanning 14 days** | Both end dates count: days 1–14 qualify, days 1–13 don't. |
| **Windows** | Today is day 1. "The last 28 days" is days 1–28, I6's earlier window is days 57–84, and I4's window is days 1–90. The ADR's example "From 1 to 28 July" lands on exactly those bounds. |
| **Subject** | What the claim is about: the need (I1), the Plan (I2), the part (I3), need + kind (I4), earlier → recent need (I6), and Plan + cycle (I5). It is used only to tell whether the same claim is still current; it never hides anything. |
| **"Not now" hides that evidence set** (corrected 2026-10-18, B5 closure) | The evidence set is the family's relevant Circles: the need's choices (I1), the Plan's untreated stage offers (I2), the part's last four Circles (I3), the need's composed Circles in the 90 days (I4), and both windows (I6). `insightFingerprint` is the subject plus those sorted ids (FNV-1a), never the wording. For 28 days, an ordinary candidate is hidden when a snapshot with the same subject that was set aside, applied or dismissed holds every Circle the candidate rests on: the same set, or what remains of it as older Circles leave the window. A new relevant Circle is new evidence and may qualify again under the 7-day cadence, the gate, priority and the no-duplicate rule. An irrelevant Circle (another need for I1, a Circle without the part for I3, an ordinary Circle for I2) changes nothing. Plan reviews are never hidden this way and can't be dismissed with "Not now". |
| **Still current vs stale** | I1, I2, I4 and I6 stay current while the family, evaluated today, makes the same claim from evidence overlapping what was shown; I2 also needs the same cycle. I3 is withdrawn after 2 unskipped appearances in a row, or once the part is left out. I5 is never stale while Plans keeps the review. A stale snapshot stays readable but can't be applied. |
| **I3 "Or Keep it"** | A dismissal exactly like "Not now": the snapshot gets `declinedOn`, nothing else changes (no preference, answer, ranking evidence or second exclusion), and only that evidence set is hidden. The bounded application is Leave it out alone; B6 should word this as a dismissal, not as a "Keep". |
| **I4 at 8 kept Circles** | If there was no room when it was shown, its application is "Nothing to change". If room ran out between showing and applying, the result is the kept-Circle limit, and nothing is replaced. |
| **I5** | A reference to the cycle B3 keeps and B4 shows. There is no second review engine and no copied review text. |

## New facts recorded

- **Journal:** `replacedFromPlanStage` holds the Plan stage of the Circle "Not this one today" replaced.
  - Without it, a stage offer replaced by an ordinary Circle would stop being a stage offer, and I2 couldn't count "Too much for today".
  - It is written only when present, so older JSON is byte-identical.
- **Stage provenance:** `gentler` marks a stage Circle composed under I2's setting. Such offers never count as evidence for I2.
- **Plan cycle:** `gentlerSince` is the setting. It ends with the cycle, can be turned off (never gated), and survives Delete history as a Plan setting.

## I2 on the composer

- **The setting:** the stage's brief with every part low-effort as well (`StageBrief.gentler()`), composed one size below today's time (`gentlerWindow`: up to 30 → ≈20, ≈20 → ≈10, ≈10 → ≈10).
- **Unchanged:** every gate, set aside / wait, and Not this one today (which stays gentler).
- **Feasibility:** all 45 stage × time cells pass. The lowest is Getting going stage 3 at ≈10, with 9 low-effort shapes.

## 12-month structural simulation

File: `b5_insights_12_months.json`.

| Profile | Month 1 | Month 3 | Month 6 | Month 12 | Max stored |
|---|---|---|---|---|---|
| Never answers | I1 1 · I5 1 | I1 3 · I5 3 | I1 6 · I5 6 | I1 12 · I5 12 | 24 |
| Moderate answerer | I1 1 · I5 1 | I4 1 · I1 3 · I5 3 | I4 4 · I1 6 · I5 5 | I4 9 · I1 12 · I5 12 | 33 |
| Frequent skipper | I3 1 · I1 1 · I5 1 | I3 5 · I1 3 · I5 2 | I3 9 · I1 5 · I5 5 | I3 9 · I1 12 · I5 11 | 32 |
| Active Plan user | I2 1 · I5 3 | I2 3 · I5 11 | I2 6 · I5 23 | I2 12 · I5 72 | 52 (cap) |
| Lapses, days 120–239 | I4 1 · I1 1 | I4 1 · I1 3 · I5 2 | nothing new while lapsed | I4 1 · I1 9 · I5 8 | 18 |
| One dominant need, always "Not now" | I1 1 | I1 3 | I1 6 | I1 12 | 12 |
| Needs change, starts every Plan | I1 1 · I5 1 | I1 3 · I5 3 | I4 1 · I1 6 · I6 2 · I5 8 | I4 1 · I1 12 · I6 4 · I5 16 | 33 |

Under the same-claim rule, the most one I1 claim was shown is 12 times a year, and the same for one I2 claim (previously 39 and 32). Weeks with nothing new and ordinary: 31–42 of 52 per profile. That silence is correct when nothing new is due.

**Asserted on every profile:**
- no pattern before the Circles span two weeks;
- at most one new ordinary Insight per 7 days;
- the cap of 52;
- no observation current twice at once;
- no causal or state wording;
- nothing generated while lapsed, with what was shown still readable.

**The same claim at most once in 28 days** (founder decision 2026-10-18, from this simulation):
- **The finding:** with the evidence-set rule alone, I1 reached 39 a year and I2 32, and I1 starved I6.
- **The rule:** an ordinary claim (family + subject) is now ineligible for 28 days after it was shown, whatever the user did. It is derived from the snapshots themselves; no store was added. The cap keeps every ordinary snapshot under 28 days old, at most four.
- **What stays the same:** "Not now" still hides that evidence set; I5 is outside both rules; nothing fills an empty week.

**Honest limit:** Insights get richer only with answers, skips and changes in need. This is structure only: retention and market value are unproven.
