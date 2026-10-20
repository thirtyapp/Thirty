# Phase E requirement — voice usage measurement

**Status:**
- **Requirement only.** It belongs to Phase E (MEASUREMENT-1). Nothing is implemented in D2.
- **Added:** 2026-10-13, from the founder's D2 voice brief.

**Goal:** after release, THIRTY must be able to judge whether each production voice is actually useful.

## Where it runs

- **The existing sink, nothing new:** the existing opt-in, insert-only Supabase `analytics_events` path.
  - Consent defaults off (ADR-011, ADR-017).
  - There is no new backend, table or SDK.
- **Wire names:** snake_case, added to `AnalyticsEventType` and to the table's `CHECK` constraint by the Phase E migration, as earlier batches did.
- **Analytics failure** never affects voice choice, playback or the Circle.
- **Missing telemetry is not evidence of non-use:** consent-off users are invisible.

## Events (aggregate product usage)

| Event | When | Voice fields |
|---|---|---|
| `voice_previewed` | A voice preview is played: You → Spoken guidance, or the offer page if a Free preview ships. | `voice_id` |
| `voice_selected` | The user confirms a voice while none was stored: the first explicit choice. | `voice_id` |
| `voice_changed` | The user switches from a stored voice to another one. | `from_voice_id`, `to_voice_id` |
| `guided_circle_started` | A Premium guided Circle starts. | `voice_id`: the voice in effect, or `none` when spoken guidance is off |
| `guided_circle_completed` | That Circle reaches its close cue: completed, not abandoned or left. | `voice_id`: as at its start |

**Allowed fields:** only the existing event envelope (pseudonymous `tester_id`, `local_date`, app version and cohort, as already defined) plus the fields above. There are no new identifiers.

## Stable voice IDs

| Voice ID | Display name (metadata) | Descriptor (metadata) |
|---|---|---|
| `voice_locke_v1` | Locke | Calm & gentle |
| `voice_milo_v1` | Milo (replaced Andre Leone) | *(finalised from the approved production output)* |
| `voice_brittney_v1` | Brittney (replaced Lunaria) | *(finalised from the approved production output)* |
| `voice_heather_v1` | Heather | Warm & textured |

- **What the ID is:** the voice's identity, used in analytics, in the stored preference (`spoken_guidance_voice_v1`) and in the asset folder.
- **Never gender:** the ID is never gender-based.
- **Display name and descriptor are metadata:** they may change without changing the ID.
- **When the ID changes:**
  - **It stays the same** for a re-master or a re-generation of the same voice, for new scripts, and for a new display name.
  - **It gets a new version** (`_v2`) only when the underlying voice identity changes.
- **Replaced before shipping (2026-10-13):** Andre Leone and Lunaria were replaced before release, so `voice_andre_v1` and `voice_lunaria_v1` never shipped. Their replacements get IDs named after the approved voices.
- **Launch set locked (founder, 2026-10-16):** Locke, Heather, Milo and Brittney. Voice selection is closed. Descriptors must not use ElevenLabs catalogue language (meditation, meditative, hypnosis, healing, manifestations, ASMR).
- **No migration needed:** the D2 placeholder slots (`female` / `male`) never shipped. The production pack uses these IDs from the start.

## Privacy boundary

**Never attached to any voice event:**
- Circle text;
- need;
- activity content;
- Memory or History contents;
- user-entered text;
- names;
- health inference.

**No profiling:** no per-user voice histories are built for profiling. The analysis is aggregate shares only.

**Disclosure in Phase E:** these events fall under the optional, consent-gated "app interactions" usage data. The privacy policy and the Play Data Safety form must describe them accurately before release.

## Future voice replacement rule

**Evidence, not taste:** a voice may be retired or replaced only on real usage evidence, never on preference or founder taste alone.

**What to evaluate, at least:**
- selection share;
- actual guided-Circle usage share (`guided_circle_started` by `voice_id`);
- completion share, where the sample makes it meaningful;
- switching away from the voice (`voice_changed`, `from_voice_id`);
- a sufficient observation period and sample size, stated before the decision.

**Least-used is not a reason:** the least-used voice is not removed automatically, since a small but loyal share is a valid outcome.

**If a voice is ever retired (not implemented now):**
- a stored preference for the retired ID migrates safely to a valid remaining voice, with no crash and no missing-asset state;
- the user always ends up with a working voice;
- analytics history stays attributable to the old stable ID, and IDs are never reused.
