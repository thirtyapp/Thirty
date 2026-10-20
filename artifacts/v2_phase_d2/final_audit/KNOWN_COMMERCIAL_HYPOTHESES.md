# Known commercial hypotheses and real-world unknowns — Phase D2

**Nothing below has been validated with real users or real money.** The internal simulations are architectural checks of the engine — variety, fallback, repetition, adaptation, time use — run with scripted answers. They are **not** evidence of willingness to pay, conversion, retention or acquisition.

## H1 — The recurring job is worth a monthly subscription

- **The hypothesis:** a newly composed, guided Circle every day — the Personal Guided Circle — is worth a monthly charge.
- **What exists:**
  - the product (ADR-023);
  - a true-on-day-one offer;
  - composition from day one;
  - adaptation to explicit answers: p14 liked-kind mains rose from 42 % in month one to 65 % after day 60;
  - spoken guidance architecture with Android background playback;
  - no production voice yet.
- **What does not exist:** any measurement of willingness to pay, conversion or retention. The €5–€9 price range is a guess.

## H2 — Kept Circles do not substitute for the subscription (the saved-Circle / lapse attack)

**Result, preserved deliberately:**
- **The attack:** in `saved_circle_lapse_attack_test.dart` (Premium days 1–40, lapsed days 41–100, back from day 101), the user keeps the maximum of 8 Circles.
- **Lapsed days:** **40 of 60** were served by a kept Circle the user chose with "Use it today", and 20 by ordinary Free Today.
- **Re-run after the guided-voice entitlement correction (2026-10-12):** unchanged at 40 and 20.
  - The 40 kept-Circle days ran visual and paced.
  - THIRTY spoken-guidance plays while lapsed: **0**. Background sessions while lapsed: **0**.
  - Every Premium day (60 of 60) was spoken.
  - TalkBack accessibility while lapsed: **PASS** — the same semantics tree and announcements as Premium (`guidance_entitlement_test.dart`), plus the S25 check.
- **What held:**
  - ownership was never weakened;
  - kept Circles were never offered unasked;
  - still one Circle a day;
  - no composition while lapsed;
  - composition returned on day 101.

**The question for the independent audit:** is the ongoing, newly composed and guided service strong enough to stay worth paying for when a user already owns several static Circles?

**What the product does not do about it — deliberately (founder brief §17):**
- reduce the ownership limit;
- disable "Use it today";
- auto-delete;
- degrade kept Circles.

**Owned Circles no longer keep THIRTY's voice (corrected 2026-10-12, founder decision):** a kept Circle used on Free runs complete on screen and through TalkBack, but without THIRTY's spoken guidance or its background service. The voice is a Premium service layer, so a lapsed user's owned alternative is the visual, paced Circle. Ownership itself is untouched.

**What differs between kept and new:**
- **Kept Circles are static.** They don't adapt to today's time beyond their own lengths, don't use new answers, don't vary, and don't respond to "Not this one today".
- **The subscription delivers** daily composition from current evidence and recency, with time fit for any window.

Whether users value that difference enough is unknown.

## H3 — More Energy is broad enough

- **The evidence:** `p14_more_energy_dominant` shows no structural degeneration, but **9 distinct mains** and **31 materially distinct sessions in a year**, against 13–18 mains and 37–144 sessions for mixed-need profiles. Top-main share is 0.29 at month 12.
- **The cause:** More Energy is the thinnest need, because its exertion and breathing content remains behind the safety gate.
- **What was deliberately not done:** content was **not** padded to improve this.
- **The honest route to widen it:** the separate safety review of the gated activities. It is not self-certified here.
- **The risk:** a user who mostly chooses More Energy may find Premium repetitive sooner than others.

## H4 — Spoken guidance raises the perceived value of Premium

- **What is unknown:** no production voice exists yet. Whether a bundled voice makes the daily Circle feel more "guided", and so more worth a subscription, is untested. It is also untested whether a recorded voice of the approved quality feels repetitive across months, since the same 42 clips recur.

## Real-user unknowns (cannot be resolved before users)

- day-30, month-3 and month-12 retention of Premium subscribers;
- how many users try Premium, and convert, from Free;
- whether users actually answer "Did you try it? / Was it useful?" often enough for adaptation to matter;
- whether auto-advancing parts suit real people, whose parts may take longer or shorter than authored;
- whether the background notification is acceptable to users or feels intrusive.

## Acquisition unknowns

- **Organic discovery:** how THIRTY is found at all (store search, word of mouth). Nothing in D2 addresses acquisition.
- **Store listing and paywall:** whether the listing and paywall copy convert. Live pricing is a Phase E decision.
