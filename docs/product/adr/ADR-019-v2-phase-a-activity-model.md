# ADR-019 — V2 Phase A / Activity model, natural duration and safety gate

**Status:** Accepted — founder approved, S25 accepted (2026-10-09)

Product authority: [PRODUCT_V2_CONTRACT.md](../PRODUCT_V2_CONTRACT.md). This ADR records only how Phase A realises it.

## Decisions

1. **One catalogue, one entry per activity.**
   - `ActivityDefinition` (`lib/features/home/application/activity_catalog.dart`) now carries:
     - need fit per need: `NeedFit.primary / secondary / none`;
     - `minMinutes` and `typicalMinutes` (≤ 30);
     - `CircleMode` (open / guidedSteps / paced);
     - `ActivityStatus` (live / safetyReviewPending / retired);
     - the V1 → V2 `LearningCompatibility`;
     - mode-specific content: reasons per PRIMARY need, first action, preparation, while-you're-there ideas, guided steps, lighter version, safety note, ending.
   - There are no numeric weights.

2. **Stable identities.**
   - `ActivityId` values are never removed or renamed.
   - A concept leaving the catalogue becomes `retired`, so history, today's restored Circle and V1 Plans keep resolving.
   - `energisingBreathReset` is retired and never offerable.

3. **History is never dropped for catalogue reasons.** The journal loader and today's restore now validate *identity* (a known `ActivityId`), no longer V1 pool membership. Before this, re-placing an activity's need fit would have silently deleted history.

4. **Learning compatibility.**
   - `catalogVersion` is now **2**, and new entries record it.
   - `historicalEvidenceEligible(activityId, recordedCatalogVersion)` is the single rule for Phase B:
     - retired activity → never eligible;
     - V2 entry → eligible;
     - V1 entry → eligible only if `LEARNING_COMPATIBLE`.
   - History itself is untouched.
   - `thirtyMinuteWalk` (A brisk walk) is `LEARNING_RESET`: V1 was a natural-pace half hour, V2 asks for a brisk pace (founder decision). Its V1 entries stay in history and export.

5. **Safety gate.**
   - `safetyPendingContentAllowed = kDebugMode`, a compile-time constant.
   - `safetyReviewPending` activities are offerable only in internal debug builds, never in profile or release builds.
   - Every Paced and breathing activity must be non-live until reviewed; tests enforce this.
   - Pace parameters are deliberately absent until the review supplies them.

6. **Interim selector (temporary, Phase B replaces it).**
   - `selectActivityId` keeps V1 rotation behaviour over `legacySelectorPool(need)`: offerable activities with a PRIMARY fit, in catalogue order.
   - `activityPools` remains only as the *historical* V1 constant for V1 Plans and fixtures.

7. **Duration source.** The Circle ring and its spoken value use `activityTypicalMinutes(activityId)`. A retired activity restored from history falls back to its V1 half hour.
   - A quick standing stretch is **5 minutes** (minimum 5): the length follows the authored sequence, which is never padded to fill a longer Circle. Its lighter version stays as written.

8. **Interim Circle (Phase C replaces it).**
   - The Today card shows the length on its label line ("TODAY · 15 MIN").
   - Before Start it shows the reason; once started, the first action.
   - The activity row opens the full how-to in a bottom sheet (progressive disclosure). Guided steps appear there as a numbered list.
   - The row's touch padding replaces the gaps around it, so the card is no taller and Start Circle keeps its place.
   - The reason and the first action are never cut off. At normal text the copy is held to two lines (reason) and three (first action) beside the World art; enlarged text grows the card instead (S25 founder-review pass).
   - The how-to sheet's last line scrolls clear of the system navigation bar.
   - **Start Circle on short screens** (founder decision, S25 with 3-button navigation). Home's near-fit rhythm stops at the first step that puts Start Circle fully on the first screen, at least 8pt above the tab bar: (1) the three gaps 16 → 8pt; (2) also the Today card's top/bottom padding 16 → 8pt; (3) only then, at normal text size and before Start, the Circle trimmed by exactly the remaining shortfall, at most 4%. If 4% is not enough, nothing is trimmed and the page scrolls. The trim eases in with First Breath's opening and is held through Start and Close, so the Circle never jumps. The CTA keeps its hero height. Roomier screens, gesture navigation and one-line activities keep the full Circle; on the S25 with 3-button navigation only the two-line activity titles are trimmed (3.4%).

9. **Copy fixes.**
   - The pre-start subline no longer asks to close: "Here's one thing for today." before Start; "Close it whenever you're ready." once running.
   - Journal records read as memory: human dates, "Started at 09:05, closed at 09:22.", "Did you try it? — Not answered". No completion claims.

10. **Optional additions not built.** Daylight minutes, Screen-break reset and Reach out to someone stay OPTIONAL. Without them, every need still has at least 4 releasable PRIMARY activities and at least 3 releasable options of about 10 minutes, all tested.

## Consequences

- V1 Plans (Phase D) still reference `energisingBreathReset` and gated activities internally. No external build is allowed before Phase D replaces them.
- Phase B must use `historicalEvidenceEligible` for every historical answer, and must replace `legacySelectorPool` / `selectActivityId`.
