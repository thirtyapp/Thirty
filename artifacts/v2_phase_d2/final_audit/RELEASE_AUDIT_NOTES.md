# Release-audit notes — wording in older Free / routine content (carried forward, not fixed in D2)

**Status:** open. These lines must be reviewed before the final public release.
- **Why not in D2:** they are outside the bounded D2 scope (founder brief §19), and none of them is an active release-safety or truth defect in the experience shipping today. The reasons are below.
- **Do not lose them:** this note is the reminder. It is not permission to widen D2.

The D2 correction pass already removed this wording from the 38 **Personal Guided Circle elements**: needless intensity, and phone wording that conflicts with spoken guidance. The same kinds of phrase remain in the **source Free activities** (Phase A catalog) and the **routine modules** (Phase D module library). Those run on the older runtimes without spoken guidance.

| File | Content | Live line | Kind |
|---|---|---|---|
| `lib/features/home/application/activity_catalog.dart` | Free activity `thirtyMinuteWalk` ("A brisk walk"), a step | "Start easy, then walk a little quicker than usual — brisk, but still able to talk." | intensity, bounded by "still able to talk" |
| same | Free activity `moveToMusic`, first action | "Put on a song you really like and turn it up a little." | intensity / volume |
| same | Free activity `moveToMusic`, a step | "Let the next song be a bit livelier." | escalation |
| same | Free activity `phoneFreeWalk`, first action | "Put your phone on silent, out of sight in a pocket or bag, and start walking." | phone out of reach ("bag") |
| `lib/features/toolkit/domain/module_library.dart` | routine module `musicMove`, full instruction | "Put on a song you really like. Start small, and let the next one be a bit livelier." | escalation |
| same | routine module `activeTask`, a version | "One job that keeps you on your feet, done a little quicker than usual. Music on if it helps." | intensity |
| same | routine module `briskWalk`, short version | "A shorter loop: start easy, then walk a little quicker than usual." | intensity |
| same | routine module `phoneFreeWalk`, both versions | "Phone on silent and out of sight. …" | phone out of reach |

## Why none of these is an active defect today

- **Spoken guidance plays only in a composed Personal Guided Circle** (ADR-023 §6). Free activities and routines never use the voice, so "out of sight in a … bag" cannot cut the user off from a guide they rely on.
- **The intensity lines are bounded.**
  - "still able to talk" limits the walk.
  - Each activity carries its own safety note and stop guidance.
  - All of them shipped in founder-approved Phase A/D content.
- **None is gated content:** briskStepBurst, activeMovementSnack, focusedBreathingCount and restfulBreathingPause stay gated, and energisingBreathReset stays retired. Nothing here was reactivated.

## Before final public release

- **Review for consistency:** check whether these lines should match the D2 element wording, e.g. "at a pace you can still talk at" and "with your phone in your pocket".
- **Content approval:** any change is a founder-approved content change in its own phase. It also invalidates no voice clip, because none of these strings is in the spoken manifest.
