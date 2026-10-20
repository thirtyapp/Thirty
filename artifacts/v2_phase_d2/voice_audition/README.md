# Spoken guidance — voice audition (REVIEW ONLY)

> **Founder decision, 2026-10-12:** these vidIQ-generated files are **audition only** and will never be bundled. Once a voice is chosen, the 42 production clips are generated directly under a **paid ElevenLabs plan with commercial rights**. The founder keeps the evidence: account/plan, generation date, terms reference, voice, exact scripts. Points 2 and 3 under "Founder decisions this needs" below are superseded by this.

**These files are not production audio.** They are not bundled, not referenced by the app, and not named with the manifest's fingerprinted filenames. The app cannot play them. The spoken-guidance gate stays open until the founder approves a voice and the full 42-clip pack is recorded and mastered from `SPOKEN_GUIDANCE_MANIFEST.csv`.

## What this is

Five representative clips, chosen by the founder brief (§14), in three candidate voices. Each clip uses the canonical script from the regenerated manifest (2026-10-12).

| # | Clip | Covers | Script |
|---|---|---|---|
| 01 | `lead_first` | transition | "First." |
| 02 | `part_getItOut` | writing | "Get it out. Write down everything on your mind, without sorting. When you run dry, ask what else is nagging at you." |
| 03 | `part_briskWalk` | movement | "A brisk walk. Head out. Start easy, then walk briskly — at a pace you can still talk at. Turn back about halfway." |
| 04 | `part_warmDrink` | gentle pace | "A slow warm drink. Make a warm drink you’d enjoy. Hold the cup in both hands, and drink it slowly, with your phone face down." |
| 05 | `close` | closing | "That’s your Circle. Take a moment before you move on." |

### Candidate voices

All three are premade ElevenLabs voices, used through the vidIQ voiceover tool already connected to the founder's account.

| Label | Voice (provider's description) | Why it's a candidate |
|---|---|---|
| `sarah` | Sarah — "Mature, Reassuring, Confident" (female, American) | warm, adult, reassuring |
| `river` | River — "Relaxed, Neutral, Informative" | calm and neutral; the least "announcer" on paper |
| `eric` | Eric — "Smooth, Trustworthy" (male tenor, 40s) | adult, conversational |

**Voices left out:**
- "storyteller", "broadcaster", "energetic", "social media" and "character" voices — they work against the brief's "not announcer-like, not motivational";
- strongly regional accents — they make the English less internationally understandable.

## Files

- `<voice>_00_full_take.mp3`: the five clips as one generated take, as delivered. Integrated loudness: Sarah −13.9 LUFS, River −19.5, Eric −18.3.
- `<voice>_00_full_take_loudness_matched.mp3`: the same take normalised to about −18 LUFS. **Compare the voices with these files:** a louder take sounds "better" for no good reason.
- `<voice>_01…05_*.mp3`: the take split into the five clips.
  - **How it was split:** at the midpoint of the pause nearest each expected boundary, detected by ffmpeg `silencedetect` at −35 dB.
  - **No processing:** nothing else was done to these files (no loudness or EQ change).
  - Listen in order to check the splits.

## How it was made, and what it cost

- **Generation:** one request per voice, via `vidiq_voiceover_generate`, on 2026-10-12.
- **Cost:** 14 credits each, so **42 vidIQ add-on credits** in all; the account went from 666 to 624 (confirmed with the balance check).
- **No runtime part:** nothing at runtime uses any voice service. This was a one-off, pre-generated audition.
- **Pauses:** the script asked for 2-second pauses between clips (`<break time="2.0s" />`). The service ignored them: the takes have natural gaps of 0.5–1 s. The tags were not read aloud — the durations fit the speech alone. **Check this by listening.**

## What Claude could not judge

**I could not listen to these files.**
- **Measured:** durations, pauses and loudness.
- **Not judged:** warmth, naturalness, pronunciation, clipped phonemes, or whether a voice sounds clinical, sleepy, salesy or announcer-like. That is the founder's audition.

## Founder decisions this needs

1. **Which voice, if any.** The production pack is generated only after this approval (brief §14). Rejecting all three is a valid outcome.
2. **Licence.** Confirm that ElevenLabs output, generated through vidIQ, may be bundled in a commercial mobile app. Check vidIQ's and ElevenLabs' terms for the plan in use. **This was not verified.** If it isn't cleared, use a voice actor, or a provider whose licence is confirmed.
3. **The full pack.** About 2,900 characters, one clip per request, so the cost depends on how vidIQ rounds per request. At 14 credits per request rounded up per 1,000 characters, it would be 42 × 14 = 588 credits. Generating the pack as a few long takes and splitting them would cost far less.
   - **Cost trade-off:** fewer, longer takes also keep the voice more consistent from clip to clip.
   - **Splitting risk:** every split must be checked by ear.

## After approval

- **Requirements:** see `../final_audit/VOICE_PRODUCTION_REQUIREMENTS.md` for format, loudness, silence handling, filenames and QA.
- **The app's check:** the app activates the voice only when all 42 fingerprinted files are bundled.
