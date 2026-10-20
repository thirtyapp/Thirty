# THIRTY Phase D2 — final content review pack (final hardening, 2026-10-12)

This pack has three parts:

1. **§0: what the final hardening pass changed since the founder-reviewed pack (2026-10-11).** Written by hand, with a machine diff below it.
2. **§1–3: the founder correction pass (2026-10-11).** Unchanged from the pack the founder reviewed.
3. **§4: the complete content as it ships.** Generated from the code (`d2_review_pack_test.dart --dart-define=EXPORT_REVIEW=true`), so it cannot drift.

**Content is frozen after this pass.** It changes again only for a truth defect a test exposes, a usability defect device QA exposes, an objectively awkward or misleading sentence heard in spoken playback, or a safety issue.

**Founder approval is required before release:** for this copy, and separately for the production voice.

## 0. Final hardening pass — what changed since the founder-reviewed pack

### Copy (2 elements)

| Element | Founder-reviewed (2026-10-11) | Final (2026-10-12) | Why |
|---|---|---|---|
| `phoneFaceDown` | “Silence your notifications, and keep your phone face down or in your pocket for the rest of this Circle.” | “Silence your notifications, then keep your phone face down or in your pocket unless a part asks you to use it.” | A later part may ask you to start music or a recording on the phone, so "for the rest of this Circle" was too broad (founder correction #1). |
| `lookFar` | “Look out of a window, or outside, at the furthest thing you can see, and let your eyes rest there.” | “Let your eyes settle on the furthest thing you can comfortably see — through a window, or across the room.” | The old wording assumed a window or the outdoors (founder correction #2). |

**`lookFar` is tighter than the founder's suggested wording, which was "…— through a window if there is one, or across the room."**
- **Why:** the S25 geometry test (`home_cta_nav_layout_test.dart`, "a running composed Circle keeps Close Circle fully on the first screen… every element") failed with the longer sentence: Close Circle no longer fit on the first screen.
- **Meaning kept:** "or across the room" keeps the no-window alternative, so the sentence assumes nothing.
- **Founder check:** confirm this wording.

### Spoken manifest

- **Re-recordings:** the two changed instructions get new fingerprints, so a recording made from the old script can never play.
  - `part_phoneFaceDown_93dd8e60.m4a` → `part_phoneFaceDown_312eb0f5.m4a`
  - `part_lookFar_7111a86e.m4a` → `part_lookFar_d2e2c311.m4a`
- **Everything else:** the other 40 clips and their fingerprints are unchanged.
- **Source of truth:** the regenerated `SPOKEN_GUIDANCE_MANIFEST.csv` is the recording source of truth.

### New functional strings: the background notification (required by founder decision E)

- **Context:** while a voiced Circle runs, Android requires a notification for the media-playback foreground service (ADR-023 §6).
- **The strings:** `Circle running` / `Circle paused`, the name of the part on show, and the buttons `Pause` / `Resume` / `Next`.
- **Under the guards:** they are listed in §4 and run through the content guards.
- **What they are not:** these are labels, not new instructions. They add no score, praise or progress.

### Drift proof: the full machine diff of the generated content

Prior founder-reviewed §4 against this §4:
- 5 lines removed and 13 added.
- Nothing else in the generated content changed, and no other element, sheet, offer, Memory, Toolkit or You string drifted.

```diff
-- **Phone face down** (`phoneFaceDown`; Clearer Head, Gentler Pace; 1 min; new cue): “Silence your notifications, and keep your phone face down or in your pocket for the rest of this Circle.”
+- **Phone face down** (`phoneFaceDown`; Clearer Head, Gentler Pace; 1 min; new cue): “Silence your notifications, then keep your phone face down or in your pocket unless a part asks you to use it.”
-- **Look far away** (`lookFar`; Clearer Head, Gentler Pace; 2 min; new cue): “Look out of a window, or outside, at the furthest thing you can see, and let your eyes rest there.”
+- **Look far away** (`lookFar`; Clearer Head, Gentler Pace; 2 min; new cue): “Let your eyes settle on the furthest thing you can comfortably see — through a window, or across the room.”
+### Notification while a voiced Circle runs (Android; the part on show is its text)
+
+- “Circle running”
+- “Circle paused”
+- “Pause”
+- “Resume”
+- “Next”
+
-| `part_phoneFaceDown` | `part_phoneFaceDown_93dd8e60.m4a` | Phone face down. Silence your notifications, and keep your phone face down or in your pocket for the rest of this Circle. |
+| `part_phoneFaceDown` | `part_phoneFaceDown_312eb0f5.m4a` | Phone face down. Silence your notifications, then keep your phone face down or in your pocket unless a part asks you to use it. |
-| `part_lookFar` | `part_lookFar_7111a86e.m4a` | Look far away. Look out of a window, or outside, at the furthest thing you can see, and let your eyes rest there. |
+| `part_lookFar` | `part_lookFar_d2e2c311.m4a` | Look far away. Let your eyes settle on the furthest thing you can comfortably see — through a window, or across the room. |
-- “First. Phone face down. Silence your notifications, and keep your phone face down or in your pocket for the rest of this Circle.”
+- “First. Phone face down. Silence your notifications, then keep your phone face down or in your pocket unless a part asks you to use it.”
```


### 0.1 Guided-voice entitlement correction (2026-10-12) — Premium copy only

Founder decision: THIRTY's voice is Premium; accessibility is not. No element, step or spoken script changed: all 42 scripts and fingerprints are identical (only the manifest's `file` column dropped its folder, now one per voice). The machine diff of §4:

```diff
-- “Made each day: tell THIRTY what would help most and how much time you have, and it puts together one Circle for today, sized to that time”
-- “Guided through: one part at a time, moving on when each part’s time is up — nothing to plan or keep track of”
+- “Made for you: tell THIRTY what would help most and how much time you have, and it puts together a new Circle for today, sized to that time”
+- “Guided for you: one part at a time, moving on when each part’s time is up — nothing to plan or keep track of”
+- “With THIRTY’s voice bundled — Guided for you: THIRTY’s own voice tells you when each part begins, so you needn’t keep watching the screen”
+- “With THIRTY’s voice bundled: You can cancel anytime in Google Play. Premium stays active until the end of your current billing period. After that, Today goes back to one good thing a day, and everything you kept stays yours — its parts and timing on screen, without THIRTY’s voice.”
-### You — spoken guidance (shown only when the recordings are bundled)
+### You — spoken guidance (Premium only, when the recordings are bundled)
+- “Voice”
+- “Female voice”
+- “Male voice”
-Founder decision: bundled, pre-generated recordings. **No recording exists yet** — the voice and every clip need founder approval. 42 clips: three leads, one per element, and the close. When a part begins the voice plays its lead (“First.” for the first part, “And last.” for the last, otherwise “Next.”), then the part’s own clip; after the last part, the close. Each file name carries a fingerprint of its script: changing a line makes its clip missing, and the voice stays silent until the whole set is complete again.
+Founder decision: bundled, pre-generated recordings. **No recording exists yet** — the voice and every clip need founder approval. 42 clips: three leads, one per element, and the close. When a part begins the voice plays its lead (“First.” for the first part, “And last.” for the last, otherwise “Next.”), then the part’s own clip; after the last part, the close. Each file name carries a fingerprint of its script: changing a line makes its clip missing, and the voice stays silent until the whole set is complete again. Each of THIRTY’s two voices records the whole set in its own folder: `assets/audio/guidance/<voice>/<file>`, with <voice> one of female, male.
-
```

## 1. What changed

### Reasons, by correction

| Correction | Elements |
|---|---|
| **Semantic dependencies.** A part never refers to something that didn't happen. | `chooseOne` and `firstStep` keep their references and now come only *directly* after the part they build on; skipping that part skips them too. `putThingsBack` ("what you used") was rewritten to stand alone and made inside-only. `comfortableSpot` no longer leads into a warm drink, which would mean getting up again. |
| **Phone / guidance.** The phone is the guide: face down, in a pocket or silenced — never left behind, out of reach or out of earshot. | `phoneFaceDown`, `phoneFreeWalk` (renamed "Screen-free walk"), `warmDrink`, `listenOne`, `sitOutside` |
| **Unsaved work.** | `closeWhatsOpen` (renamed "Set screens aside": "Minimise…", "nothing needs closing"), `oneTask` ("put everything else out of sight") |
| **Needless intensity.** | `songOn` (no "louder"), `moveToMusic` (no "each song livelier"), `activeJob` (no "quicker than usual"), `quickClearUp` (no "as many as you can"). `briskWalk` keeps "briskly", because that is the element, bounded by "at a pace you can still talk at". |
| **Assumed context.** | `daylight`, renamed "Some fresh air" (no "daylight"; the window alternative stays). Outdoor parts stay governed by "Can't go outside". No weather, location or new question. |
| **Safety manual pass (§3 below).** | `standAndReach` and `oneLongReach` ("as far as is comfortable"), `gentleStretch` ("come up slowly", as in its source), `neckAndShoulders` ("Gently"), `shakeOut` (no longer assumes standing) |

### Element copy, before → after (20 of 38 changed)

| Element | Before | After |
|---|---|---|
| `phoneFaceDown` | **Phone face down** — “Silence your notifications and put your phone face down for the rest of this Circle.” | **Phone face down** — “Silence your notifications, and keep your phone face down or in your pocket for the rest of this Circle.” |
| `standAndReach` | **Stand and reach** — “Stand up, reach both arms overhead and stretch tall, then lower them slowly. Three or four times.” | **Stand and reach** — “Stand up and reach both arms overhead, only as high as is comfortable, then lower them slowly. Three or four times.” |
| `songOn` | **Put a song on** — “Put on a song you really like, a little louder than usual, and let it play while you start.” | **Put a song on** — “Put on a song you really like, and let it play while you start.” |
| `comfortableSpot` | **A comfortable spot** — “Find somewhere comfortable to sit or lie, and let your shoulders drop.” | **A comfortable spot** — “Find somewhere comfortable to sit or lie, and let your shoulders drop.” *(leads into: listening, reading, writing, focus)* |
| `moveToMusic` | **Move to music** — “Put on songs you like and move however feels good — sway, step, walk around the room. Let each song be a little livelier.” | **Move to music** — “Put on songs with a bit of life in them, and move however feels good — sway, step, walk around the room.” |
| `activeJob` | **One active job** — “One job that keeps you on your feet — sweeping, hoovering, carrying — a little quicker than usual.” | **One active job** — “One job that keeps you on your feet — sweeping, hoovering, carrying things — at a pace that feels comfortable.” |
| `briskWalk` | **A brisk walk** — “Head out. Start easy, then walk a little quicker — brisk, but still able to talk. Turn back about halfway.” | **A brisk walk** — “Head out. Start easy, then walk briskly — at a pace you can still talk at. Turn back about halfway.” |
| `quickClearUp` | **Quick clear-up** — “Pick one room and put away as many things as you can. Don’t sort — just put things back where they live.” | **Quick clear-up** — “Pick one room and put things back where they live. Don’t sort — just put away what’s out.” |
| `daylight` | **Into the daylight** — “Step outside, or stand at an open door or window, and spend a few minutes in the daylight.” | **Some fresh air** — “Step outside, or stand at an open door or window, for a few minutes. Look around and take in what’s there.” |
| `oneTask` | **One task, no switching** — “Pick one task on your mind and close everything else. Stay with it until the time’s up — finished or not.” | **One task, no switching** — “Pick one task on your mind and put everything else out of sight. Stay with it until the time’s up — finished or not.” |
| `listenOne` | **Listen to one thing** — “Put on one album, episode or recording. Phone face down, and nothing else to do but listen.” | **Listen to one thing** — “Put on one album, episode or recording, then put your phone face down. Nothing else to do but listen.” |
| `phoneFreeWalk` | **Phone-free walk** — “Phone on silent and out of sight. Walk easily, and notice three things you haven’t noticed before.” | **Screen-free walk** — “Silence your notifications and keep your phone in your pocket. Walk easily, and look around you rather than at a screen.” |
| `closeWhatsOpen` | **Close what’s open** — “Close every tab, window and app you don’t need right now. Leave only what the next thing needs.” | **Set screens aside** — “Minimise what you don’t need on your screens — nothing needs closing. Keep in view only what comes next.” |
| `warmDrink` | **A slow warm drink** — “Make a warm drink you’d enjoy. Hold the cup in both hands, and drink it slowly, phone out of reach.” | **A slow warm drink** — “Make a warm drink you’d enjoy. Hold the cup in both hands, and drink it slowly, with your phone face down.” |
| `gentleStretch` | **Gentle stretch** — “Slowly: neck, shoulders, open the chest, a seated twist, then fold forward. Only what’s comfortable.” | **Gentle stretch** — “Slowly: neck, shoulders, open the chest, a seated twist, then fold forward and come up slowly. Only what’s comfortable.” |
| `neckAndShoulders` | **Neck and shoulders** — “Tip your head slowly towards each shoulder. Then lift your shoulders to your ears and let them drop.” | **Neck and shoulders** — “Gently tip your head towards each shoulder. Then lift your shoulders to your ears and let them drop.” |
| `sitOutside` | **Sit outside** — “Find somewhere outside to sit, phone left inside. Listen to what you can hear, near and far.” | **Sit outside** — “Find somewhere outside to sit, with your phone in your pocket. Listen to what you can hear, near and far.” |
| `putThingsBack` | **Put things back** — “Put away what you used, and leave the space ready for later.” | **Put things back** — “Put back anything that’s out of place nearby, and leave your space ready for later.” *(now indoor only; was either)* |
| `shakeOut` | **Shake it out** — “Shake out your hands and arms loosely, then stand easy for a moment.” | **Shake it out** — “Shake out your hands and arms loosely, then let them rest.” |
| `oneLongReach` | **One long reach** — “Finish with one long reach overhead, then let your arms drop.” | **One long reach** — “Finish with one long reach overhead, as far as is comfortable, then let your arms drop.” |

### Premium offer, before → after

| Where | Before | After |
|---|---|---|
| Offer promise | "Each day, THIRTY turns the time you have into one guided Circle — a few small parts, built from what you've found useful — and takes you through it." | "From your first day, THIRTY turns the time you have into one guided Circle — a few small parts, one after another — and takes you through it." |
| Offer, Free line | "Free stays complete: THIRTY chooses one good thing for today, and learns from what you tell it." | "With Free, THIRTY still gives you one good thing for today, and learns from what you tell it." |
| Offer, "Shaped by your answers" | "what you find useful comes back, and what you leave out stays out — all of it visible in What THIRTY remembers" | "tell THIRTY what was useful and later Circles can bring it back; what you leave out stays out — all of it visible in What THIRTY remembers" |
| You, Premium card | "A guided Circle made for your day, from the time you have and what you've found useful." | "A guided Circle made for your day, from the time you have — and shaped by your answers over time." |
| Toolkit, Premium card | "…one guided Circle of a few small parts, built from what you've found useful. …" / "…Free stays complete: THIRTY still chooses one thing for today." | "…one guided Circle of a few small parts, shaped by your answers over time. …" / "…With Free, THIRTY still gives you one good thing for today." |

- "Built from things you've found useful" now appears only on Today, and only with evidence. This was already the case and is unchanged.
- A new content guard keeps the offer and the Toolkit card free of "found useful", "stays complete" and "knows what".

### New copy

- **Skip sheet, when later parts build on the part being skipped:**
  - "“Choose one thing” builds on this part, so it's skipped too. Nothing is recorded against either."
  - With two such parts: "… build on this part, so they're skipped too. Nothing is recorded against any of them."
- **You → Preferences** (shown only when the recordings are bundled): "Spoken guidance" — "A voice tells you when each part of your Circle begins, so you needn't watch the screen."

## 2. Semantic-dependency audit (all 38 elements)

| Element | Refers to | Holds because |
|---|---|---|
| Choose one thing | "what you wrote" | It is composed only directly after Get it out and is skipped with it. Name what's on can't precede it: no Circle holds two writing parts. |
| Write the first step | "the thing you circled" | It is composed only directly after Choose one thing and is skipped with it. |
| Put things back | (was "what you used") | Rewritten to stand alone, and made inside-only, so it never closes a Circle spent outside. |
| One long reach | "Finish with…" | Its only role is settle, the last part. |
| Sit for a minute, A glass of water | "before you move on / carry on" | Their only role is settle. |
| Open a window, Put a song on, Phone face down | "before you begin", "while you start", "for the rest of this Circle" | Their only role is arrive. |
| A comfortable spot | sitting or lying | It leads only into listening, reading, writing or focus (no longer a warm drink). |
| Set screens aside | "what comes next" | It is arrive-only, and leads only into focus, writing, reading or listening. |
| The other 26 | nothing earlier in the Circle | They are independent. |

Tests prove that, for every shape the composer can make, a part that builds on another follows it directly, and never appears without it. Tests also prove that skipping a part skips its dependants.

## 3. Movement, exertion and sensory safety — manual pass

Reviewed by hand against each source activity's own steps and safety note. **No instruction needed the separate safety review, so none was gated. No safety-pending content was reactivated.**

- **standAndReach, oneLongReach, standingStretch** — from *A quick standing stretch* (live; "Move only as far as is comfortable. Skip anything that hurts."). Each now says "only as high / as far as is comfortable". standingStretch already says "Only as far as is comfortable"; its march is the source's own.
- **neckAndShoulders, gentleStretch** — from *Gentle stretch pause* (live; "Stay well within what feels comfortable."). The neck tilts are now "Gently". The forward fold now ends "and come up slowly", as its source does: rising quickly is the one real risk in it.
- **moveToMusic** — "move however feels good". The escalation is removed.
- **activeJob** — "at a pace that feels comfortable". "Carrying things" is the source's own example.
- **briskWalk** — from *A brisk walk* (live). "Start easy", then brisk "at a pace you can still talk at" — a self-limiting bound, not a target.
- **shakeOut** — loose hands and arms, then rest. It no longer assumes standing.
- **Sensory:** songOn and moveToMusic set no volume. quietMusic says "something quiet". sitOutside asks only to listen.
- A composed Circle's how-to carries the first applicable source safety note, as before.
- **Outside this bounded pass, flagged for the founder:** the live **Free activities** these elements come from (and the Phase D routine modules) still say "a little quicker than usual" (*A brisk walk*, *One active household task*), "turn it up a little" and "Let the next song be a bit livelier" (*Move to music*), and "Phone on silent, out of sight" (*Phone-free walk*). They have no spoken guidance, so the phone conflict does not apply to them; the intensity wording is the founder's call.

---

## 4. The complete content as it ships

### Elements (38)

### Arrive

- **Phone face down** (`phoneFaceDown`; Clearer Head, Gentler Pace; 1 min; new cue): “Silence your notifications, then keep your phone face down or in your pocket unless a part asks you to use it.”
- **Name what’s on** (`nameWhatsOn`; Clearer Head; 1 min; new cue): “In a few words, jot down what’s taking up the most room in your head right now.”
- **Open a window** (`openWindow`; More Energy, Clearer Head; 1 min; new cue): “Open a window or a door, and take a moment to look outside before you begin.”
- **Stand and reach** (`standAndReach`; More Energy, Clearer Head; 1 min; from A quick standing stretch): “Stand up and reach both arms overhead, only as high as is comfortable, then lower them slowly. Three or four times.”
- **Put a song on** (`songOn`; More Energy; 1 min; from Move to music): “Put on a song you really like, and let it play while you start.”
- **A comfortable spot** (`comfortableSpot`; Gentler Pace, Clearer Head; 1 min; new cue): “Find somewhere comfortable to sit or lie, and let your shoulders drop.”
- **Look around** (`lookAround`; Gentler Pace, Clearer Head; 1 min; new cue): “Look slowly around you, and find three things you hadn’t noticed before.”
- **Set screens aside** (`closeWhatsOpen`; Clearer Head; 3 min; new cue): “Minimise what you don’t need on your screens — nothing needs closing. Keep in view only what comes next.”
- **Neck and shoulders** (`neckAndShoulders`; Gentler Pace, Clearer Head, More Energy; 2 min; from Gentle stretch pause): “Gently tip your head towards each shoulder. Then lift your shoulders to your ears and let them drop.”

### Main

- **Move to music** (`moveToMusic`; More Energy; 8 or 5 min; from Move to music, carries its evidence): “Put on songs with a bit of life in them, and move however feels good — sway, step, walk around the room.”
- **Standing stretch** (`standingStretch`; More Energy, Clearer Head; 5 min; from A quick standing stretch, carries its evidence): “Reach up, bend to each side, roll your shoulders, twist gently, then march on the spot. Only as far as is comfortable.”
- **One active job** (`activeJob`; More Energy; 12 or 8 min; from One active household task, carries its evidence): “One job that keeps you on your feet — sweeping, hoovering, carrying things — at a pace that feels comfortable.”
- **A brisk walk** (`briskWalk`; More Energy; 20 or 15 min; from A brisk walk, carries its evidence): “Head out. Start easy, then walk briskly — at a pace you can still talk at. Turn back about halfway.”
- **Round the block** (`roundTheBlock`; More Energy, Clearer Head, Gentler Pace; 10 min; from Easy walk): “Step outside and walk once round the block, at whatever pace feels right today.”
- **Quick clear-up** (`quickClearUp`; More Energy, Clearer Head; 5 min; new cue): “Pick one room and put things back where they live. Don’t sort — just put away what’s out.”
- **Get it out** (`getItOut`; Clearer Head, Gentler Pace; 6 or 4 min; from Write it down, carries its evidence): “Write down everything on your mind, without sorting. When you run dry, ask what else is nagging at you.”
- **Clear one corner** (`clearCorner`; Clearer Head, More Energy; 8 or 5 min; from Tidy one surface, carries its evidence): “One corner of a desk, one drawer or one shelf: take everything off, then put back only what belongs there.”
- **One task, no switching** (`oneTask`; Clearer Head; 15 or 10 min; from One task, full attention, carries its evidence): “Pick one task on your mind and put everything else out of sight. Stay with it until the time’s up — finished or not.”
- **Listen to one thing** (`listenOne`; Clearer Head, Gentler Pace; 12 or 8 min; from Listen to one thing, carries its evidence): “Put on one album, episode or recording, then put your phone face down. Nothing else to do but listen.”
- **Read a few pages** (`readPages`; Clearer Head, Gentler Pace; 10 or 6 min; from Quiet reading, carries its evidence): “Read what you’re reading, or anything nearby. If your mind wanders, reread the last line.”
- **Screen-free walk** (`phoneFreeWalk`; Clearer Head, Gentler Pace, More Energy; 15 or 10 min; from Phone-free walk, carries its evidence): “Silence your notifications and keep your phone in your pocket. Walk easily, and look around you rather than at a screen.”
- **A slow warm drink** (`warmDrink`; Gentler Pace, Clearer Head; 10 min; from A slow warm drink, carries its evidence): “Make a warm drink you’d enjoy. Hold the cup in both hands, and drink it slowly, with your phone face down.”
- **Gentle stretch** (`gentleStretch`; Gentler Pace, Clearer Head, More Energy; 8 min; from Gentle stretch pause, carries its evidence): “Slowly: neck, shoulders, open the chest, a seated twist, then fold forward and come up slowly. Only what’s comfortable.”
- **Quiet music** (`quietMusic`; Gentler Pace, Clearer Head; 10 or 6 min; from Quiet music break, carries its evidence): “Somewhere comfortable, put on something quiet. Close your eyes if you like, and let one song run into the next.”
- **Easy walk** (`easyWalk`; Gentler Pace, Clearer Head; 15 or 10 min; from Easy walk, carries its evidence): “Step outside without picking a route. Walk slower than usual, and stop for anything that catches your eye.”
- **Sit outside** (`sitOutside`; Gentler Pace, Clearer Head; 10 or 5 min; from Sitting outside, unhurried, carries its evidence): “Find somewhere outside to sit, with your phone in your pocket. Listen to what you can hear, near and far.”
- **Tend to one thing** (`tendOne`; Gentler Pace, Clearer Head; 8 or 5 min; from Tend to one small thing, carries its evidence): “Pick one small thing to look after — a plant, a bedside table, a shelf — and go slower than you would in a hurry.”

### Second

- **Some fresh air** (`daylight`; More Energy, Clearer Head, Gentler Pace; 4 min; new cue): “Step outside, or stand at an open door or window, for a few minutes. Look around and take in what’s there.”
- **Look far away** (`lookFar`; Clearer Head, Gentler Pace; 2 min; new cue): “Let your eyes settle on the furthest thing you can comfortably see — through a window, or across the room.”
- **Choose one thing** (`chooseOne`; Clearer Head; 1 min; new cue): “Look over what you wrote, and circle the one thing that matters most next.”

### Settle

- **Write the first step** (`firstStep`; Clearer Head; 2 min; new cue): “For the thing you circled, write the very first small step — small enough to start with.”
- **Sit for a minute** (`sitAMinute`; Gentler Pace, Clearer Head, More Energy; 2 min; new cue): “Sit still for a minute or two before you move on. There’s nothing to do.”
- **Put things back** (`putThingsBack`; Gentler Pace, Clearer Head, More Energy; 2 min; new cue): “Put back anything that’s out of place nearby, and leave your space ready for later.”
- **A glass of water** (`glassOfWater`; More Energy, Clearer Head; 2 min; new cue): “Pour a glass of water and drink it before you carry on.”
- **Shake it out** (`shakeOut`; More Energy; 1 min; new cue): “Shake out your hands and arms loosely, then let them rest.”
- **Choose what’s next** (`whatsNext`; More Energy, Clearer Head; 1 min; new cue): “Decide the one thing you’ll do next, and go to it.”
- **Note one thing** (`noteOneThing`; Gentler Pace, Clearer Head; 1 min; new cue): “Note down one small thing from today you’d like to remember.”
- **One long reach** (`oneLongReach`; More Energy, Clearer Head; 1 min; from A quick standing stretch): “Finish with one long reach overhead, as far as is comfortable, then let your arms drop.”

### Today — before Start

- “Your Circle”
- “Here’s your Circle for today.”
- “Built from things you’ve found useful, to fit your 10 minutes.”
- “Built from things you’ve found useful, to fit your 20 minutes.”
- “Built from things you’ve found useful, to fit your 30 minutes.”
- “Small parts, one after another, to fit your 10 minutes.”
- “Small parts, one after another, to fit your 20 minutes.”
- “Small parts, one after another, to fit your 30 minutes.”
- “A Circle you kept.”
- “Today, one activity fits better than a mix.”
- “See the parts”
- “See the parts · Not this one?”
- “See the parts, or not this one today”

### Today — running

- “Part 2 of 4 · next: Get it out”
- “Part 4 of 4 · the last part”
- “About 1 minute”
- “About 6 minutes”
- “That’s your Circle. Take a moment before you move on.”
- “A few small parts, one after another. When a part’s time is up, the next one begins — or move on whenever you’re ready.”
- “Skip”

### Skip sheet

- “Skip this part?”
- “Skip it for today”
- “The next part begins. Nothing is recorded against this one.”
- ““Choose one thing” builds on this part, so it’s skipped too. Nothing is recorded against either.”
- ““Choose one thing” and “Write the first step” build on this part, so they’re skipped too. Nothing is recorded against any of them.”
- “Leave it out next time”
- “THIRTY won’t put it in your Circles again. You can bring it back in What THIRTY remembers.”
- “Keep going”

### After Close — keep this Circle

- “Keep this Circle to use again on a day you choose.”
- “Keep it”
- “Kept as My clear-head Circle. It’s in your Toolkit.”
- “You keep 8 Circles already. Remove one in Toolkit to keep this one.”
- “My energy Circle”
- “My clear-head Circle”
- “My gentle Circle”

### Use it today (routine and kept Circle pages)

- “Use it today”
- “It’s your Circle for today.”
- “Today’s Circle has already begun — one a day. You can use it tomorrow.”
- “Your Circle for today is closed. You can use it tomorrow.”
- “It can’t be used today.”
- “Turn it on to use it today.”
- “THIRTY never offers a kept Circle unasked. It stays yours, with or without Premium.”

### Memory

- “Left out of your Circles”
- “You asked THIRTY to leave it out”
- “Put it back”
- “THIRTY will forget which activities you asked it not to suggest, any rests you lifted, and any parts you left out of your Circles. Your Circle history and your answers stay.”

### Premium offer

- “A Circle made for your day”
- “From your first day, THIRTY turns the time you have into one guided Circle — a few small parts, one after another — and takes you through it.”
- “Made for you: tell THIRTY what would help most and how much time you have, and it puts together a new Circle for today, sized to that time”
- “Guided for you: one part at a time, moving on when each part’s time is up — nothing to plan or keep track of”
- “Shaped by your answers: tell THIRTY what was useful and later Circles can bring it back; what you leave out stays out — all of it visible in What THIRTY remembers”
- “Yours to keep: keep a Circle you like, or build a routine with a Path — what you keep stays yours, with or without Premium”
- “With THIRTY’s voice bundled — Guided for you: THIRTY’s own voice tells you when each part begins, so you needn’t keep watching the screen”
- “With Free, THIRTY still gives you one good thing for today, and learns from what you tell it.”
- “What you keep stays yours, with or without Premium.”
- “You can cancel anytime in Google Play. Premium stays active until the end of your current billing period. After that, Today goes back to one good thing a day, and everything you kept stays yours.”
- “With THIRTY’s voice bundled: You can cancel anytime in Google Play. Premium stays active until the end of your current billing period. After that, Today goes back to one good thing a day, and everything you kept stays yours — its parts and timing on screen, without THIRTY’s voice.”
- “THIRTY Premium makes you a guided Circle each day, around the time you have.”
- “A guided Circle made for your day, from the time you have — and shaped by your answers over time.”

### You — spoken guidance (Premium only, when the recordings are bundled)

- “Spoken guidance”
- “A voice tells you when each part of your Circle begins, so you needn’t watch the screen.”
- “Voice”
- “Female voice”
- “Male voice”

### Notification while a voiced Circle runs (Android; the part on show is its text)

- “Circle running”
- “Circle paused”
- “Pause”
- “Resume”
- “Next”

### Toolkit (repositioned)

- “Routines and Circles that are yours.”
- “A Circle made for your day”
- “With Premium, THIRTY turns the time you have each day into one guided Circle of a few small parts, shaped by your answers over time. Along the way, Paths can help you build routines of your own.”
- “What you build or keep stays yours, with or without Premium. With Free, THIRTY still gives you one good thing for today.”
- “Build a routine — if you like”
- “Optional: your Circle on Today doesn’t need it. A Path tries a few pieces with you and ends with a routine you keep.”
- “Circles you kept”

### Parts that build on another

Composed only directly after the part they build on; skipping that part skips them too (the Skip sheet says so).

- **Choose one thing** builds on **Get it out**: “Look over what you wrote, and circle the one thing that matters most next.”
- **Write the first step** builds on **Choose one thing**: “For the thing you circled, write the very first small step — small enough to start with.”

### Spoken guidance — the recording manifest

Founder decision: bundled, pre-generated recordings. **No recording exists yet** — the voice and every clip need founder approval. 42 clips: three leads, one per element, and the close. When a part begins the voice plays its lead (“First.” for the first part, “And last.” for the last, otherwise “Next.”), then the part’s own clip; after the last part, the close. Each file name carries a fingerprint of its script: changing a line makes its clip missing, and the voice stays silent until the whole set is complete again. Each of THIRTY’s two voices records the whole set in its own folder: `assets/audio/guidance/<voice>/<file>`, with <voice> one of female, male.

| Clip | File | Script |
|---|---|---|
| `lead_first` | `lead_first_d97b30dd.m4a` | First. |
| `lead_next` | `lead_next_df1d69d2.m4a` | Next. |
| `lead_last` | `lead_last_7663f978.m4a` | And last. |
| `part_phoneFaceDown` | `part_phoneFaceDown_312eb0f5.m4a` | Phone face down. Silence your notifications, then keep your phone face down or in your pocket unless a part asks you to use it. |
| `part_nameWhatsOn` | `part_nameWhatsOn_c2ce8f3b.m4a` | Name what’s on. In a few words, jot down what’s taking up the most room in your head right now. |
| `part_openWindow` | `part_openWindow_b52c68ca.m4a` | Open a window. Open a window or a door, and take a moment to look outside before you begin. |
| `part_standAndReach` | `part_standAndReach_1e75d975.m4a` | Stand and reach. Stand up and reach both arms overhead, only as high as is comfortable, then lower them slowly. Three or four times. |
| `part_songOn` | `part_songOn_6017657f.m4a` | Put a song on. Put on a song you really like, and let it play while you start. |
| `part_comfortableSpot` | `part_comfortableSpot_d138bce1.m4a` | A comfortable spot. Find somewhere comfortable to sit or lie, and let your shoulders drop. |
| `part_lookAround` | `part_lookAround_53849d95.m4a` | Look around. Look slowly around you, and find three things you hadn’t noticed before. |
| `part_moveToMusic` | `part_moveToMusic_efb5ed3a.m4a` | Move to music. Put on songs with a bit of life in them, and move however feels good — sway, step, walk around the room. |
| `part_standingStretch` | `part_standingStretch_7ca4a0a2.m4a` | Standing stretch. Reach up, bend to each side, roll your shoulders, twist gently, then march on the spot. Only as far as is comfortable. |
| `part_activeJob` | `part_activeJob_5b1bb959.m4a` | One active job. One job that keeps you on your feet — sweeping, hoovering, carrying things — at a pace that feels comfortable. |
| `part_briskWalk` | `part_briskWalk_e3125526.m4a` | A brisk walk. Head out. Start easy, then walk briskly — at a pace you can still talk at. Turn back about halfway. |
| `part_roundTheBlock` | `part_roundTheBlock_b1fa45f9.m4a` | Round the block. Step outside and walk once round the block, at whatever pace feels right today. |
| `part_quickClearUp` | `part_quickClearUp_2a4514d1.m4a` | Quick clear-up. Pick one room and put things back where they live. Don’t sort — just put away what’s out. |
| `part_daylight` | `part_daylight_bc82cf74.m4a` | Some fresh air. Step outside, or stand at an open door or window, for a few minutes. Look around and take in what’s there. |
| `part_getItOut` | `part_getItOut_a239320e.m4a` | Get it out. Write down everything on your mind, without sorting. When you run dry, ask what else is nagging at you. |
| `part_clearCorner` | `part_clearCorner_3f1dd71d.m4a` | Clear one corner. One corner of a desk, one drawer or one shelf: take everything off, then put back only what belongs there. |
| `part_oneTask` | `part_oneTask_80701d4c.m4a` | One task, no switching. Pick one task on your mind and put everything else out of sight. Stay with it until the time’s up — finished or not. |
| `part_listenOne` | `part_listenOne_afb9c607.m4a` | Listen to one thing. Put on one album, episode or recording, then put your phone face down. Nothing else to do but listen. |
| `part_readPages` | `part_readPages_16d663c3.m4a` | Read a few pages. Read what you’re reading, or anything nearby. If your mind wanders, reread the last line. |
| `part_phoneFreeWalk` | `part_phoneFreeWalk_9179d803.m4a` | Screen-free walk. Silence your notifications and keep your phone in your pocket. Walk easily, and look around you rather than at a screen. |
| `part_closeWhatsOpen` | `part_closeWhatsOpen_a811d003.m4a` | Set screens aside. Minimise what you don’t need on your screens — nothing needs closing. Keep in view only what comes next. |
| `part_lookFar` | `part_lookFar_d2e2c311.m4a` | Look far away. Let your eyes settle on the furthest thing you can comfortably see — through a window, or across the room. |
| `part_warmDrink` | `part_warmDrink_db4bc51f.m4a` | A slow warm drink. Make a warm drink you’d enjoy. Hold the cup in both hands, and drink it slowly, with your phone face down. |
| `part_gentleStretch` | `part_gentleStretch_052b8910.m4a` | Gentle stretch. Slowly: neck, shoulders, open the chest, a seated twist, then fold forward and come up slowly. Only what’s comfortable. |
| `part_neckAndShoulders` | `part_neckAndShoulders_4c3958ac.m4a` | Neck and shoulders. Gently tip your head towards each shoulder. Then lift your shoulders to your ears and let them drop. |
| `part_quietMusic` | `part_quietMusic_c6fced49.m4a` | Quiet music. Somewhere comfortable, put on something quiet. Close your eyes if you like, and let one song run into the next. |
| `part_easyWalk` | `part_easyWalk_9be95142.m4a` | Easy walk. Step outside without picking a route. Walk slower than usual, and stop for anything that catches your eye. |
| `part_sitOutside` | `part_sitOutside_ba8e7ce2.m4a` | Sit outside. Find somewhere outside to sit, with your phone in your pocket. Listen to what you can hear, near and far. |
| `part_tendOne` | `part_tendOne_47f1e257.m4a` | Tend to one thing. Pick one small thing to look after — a plant, a bedside table, a shelf — and go slower than you would in a hurry. |
| `part_chooseOne` | `part_chooseOne_4b2d1044.m4a` | Choose one thing. Look over what you wrote, and circle the one thing that matters most next. |
| `part_firstStep` | `part_firstStep_84eb44d5.m4a` | Write the first step. For the thing you circled, write the very first small step — small enough to start with. |
| `part_sitAMinute` | `part_sitAMinute_c80c3b07.m4a` | Sit for a minute. Sit still for a minute or two before you move on. There’s nothing to do. |
| `part_putThingsBack` | `part_putThingsBack_68f00ead.m4a` | Put things back. Put back anything that’s out of place nearby, and leave your space ready for later. |
| `part_glassOfWater` | `part_glassOfWater_cd436c4b.m4a` | A glass of water. Pour a glass of water and drink it before you carry on. |
| `part_shakeOut` | `part_shakeOut_d58bb0f4.m4a` | Shake it out. Shake out your hands and arms loosely, then let them rest. |
| `part_whatsNext` | `part_whatsNext_59b13e7d.m4a` | Choose what’s next. Decide the one thing you’ll do next, and go to it. |
| `part_noteOneThing` | `part_noteOneThing_721bafd4.m4a` | Note one thing. Note down one small thing from today you’d like to remember. |
| `part_oneLongReach` | `part_oneLongReach_804e9b30.m4a` | One long reach. Finish with one long reach overhead, as far as is comfortable, then let your arms drop. |
| `close` | `close_3b06cf13.m4a` | That’s your Circle. Take a moment before you move on. |

### One Circle, as it would be heard (Phone face down · Listen to one thing · Get it out · Choose what’s next)

- “First. Phone face down. Silence your notifications, then keep your phone face down or in your pocket unless a part asks you to use it.”
- “Next. Listen to one thing. Put on one album, episode or recording, then put your phone face down. Nothing else to do but listen.”
- “Next. Get it out. Write down everything on your mind, without sorting. When you run dry, ask what else is nagging at you.”
- “And last. Choose what’s next. Decide the one thing you’ll do next, and go to it.”
- “That’s your Circle. Take a moment before you move on.”
