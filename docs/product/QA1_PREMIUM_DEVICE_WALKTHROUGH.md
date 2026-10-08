# QA-1 — Premium device walkthrough (Samsung S25)

**Purpose:** walk Premium Plans, Coach and Insights on a real device before
live Google Play / RevenueCat billing exists, including the R5
continuing-value and low-data cases. Debug builds only — the harness does
not exist in profile or release builds.

## Launch

1. Connect the S25 with USB debugging on; `flutter devices` lists it.
2. From the repository root:

   ```
   flutter run --debug --dart-define=THIRTY_QA_PREMIUM=true
   ```

   No RevenueCat or Supabase values are needed or used.
3. A pink marker sits at the top of every screen. It starts as
   **QA PREMIUM · OFF / REAL DATA** — nothing is simulated yet.
4. Tap the marker to open the QA panel. Choose an **Entitlement** and a
   **Scenario**, then **Apply**. The app reopens on Today in that state.
   **Reset to real** returns to the device's own data and normal
   entitlement.

Synthetic history is dated back from the day you apply it and never
includes today, so today's Circle is always open to walk live.

## Before you start — note your real data

On a normal launch (or with the marker on **OFF**), note what Insights'
calendar and You → Data show. You will compare against this at the end.

## Scenarios

Use **Entitlement: ACTIVE** unless stated.

### 1. New user — `new_user`

- Today offers the three directions; no Plan Session, no Coach cue.
- Plans: all three Plans available to start; none in progress.
- Insights: calendar empty; no Insight card and no invented pattern or
  confidence.
- Start a Plan and walk today's Circle: Stage 1 is assigned.

### 2. Plan in progress — `plan_in_progress`

- Plans: More Energy Path in progress, three stages done.
- Choose More Energy on Today: the Circle is Stage 4 of the Path.
- Coach cue appears and reflects the last Circle.
- Insights: five past Circles in the calendar; no Insight yet (too little
  history), stated calmly.

### 3. Month two — `month_two` (R5 continuing value)

- Plans: Gentler Pace Path shows one completed cycle and cycle 2 under way.
- Opening Insights produces an Insight about the repeatedly revisited
  stage, with its evidence dates and usefulness figure; applying it queues
  the revisit.
- Coach on Today/Plans speaks to the current stage of cycle 2.
- Judge: does Premium still feel useful after the first cycle, not only
  new?

### 4. Never reflects — `never_reflects` (R5 low data)

- Calendar shows ten closed Circles; none has reflection answers.
- Plans: Clearer Head Path three stages in; Coach gives no feedback-based
  advice.
- Insights: an observation about More Energy based on closed Circles only,
  with **no** usefulness figure.
- Nothing asks or pressures you to reflect.

### 5. Lapsed, retained snapshots — `lapsed_retained_snapshots`

The panel fixes Entitlement to **INACTIVE** for this scenario.

- Today: choosing More Energy gives a normal Free Circle, not a Plan
  Session; Free works completely.
- Plans: More Energy Path keeps its saved position (three stages) but does
  not continue; the calm Free preview / offer is shown.
- Insights: the calendar shows all history including the last three Free
  days; the retained Insight stays readable as already defined, and its
  application is not available.
- No new Insight appears, however often Insights is opened.

Optionally repeat 2 with **INACTIVE** and **UNAVAILABLE**: Premium pauses
the same way and the unavailable state stays truthful (fail-closed).

## Every scenario

- [ ] The QA marker is visible on Today, Plans, Insights, You and pushed
      pages (Plan detail, Premium offer, Circle record).
- [ ] The marker names the entitlement and scenario actually applied.
- [ ] No purchase can be made; the offer shows no price.

## Finish

- [ ] **Reset to real**: the marker returns to **QA PREMIUM · OFF / REAL
      DATA**.
- [ ] Insights' calendar and You → Data match what you noted before you
      started — nothing added, nothing removed.
- [ ] Your daily reminder is unchanged (the harness never touches it).
- [ ] Relaunch without `THIRTY_QA_PREMIUM`: no marker anywhere.

Screenshots taken with the marker visible are QA material only, never store
or marketing material.
