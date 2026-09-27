# ADR-018 — V1 World Art / Scene Roles, Five Worlds, Static Daypart Artwork

**Status:** Accepted (documentation and product decision) / implementation
pending (architecture step A1, artwork pack, Home integration)

## Context

The Circle Hero and the planned Today card must both reflect the assigned
activity, in the same World, Scene and Daypart. Until now every
recommendation rendered the single approved Quiet Trail illustration, and
non-walking activities were grouped under a technical `generalWellness`
category with no World of its own.

The controlling frozen document
[`RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md`](../RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md)
defers daypart delivery in three places:

- §11 (line 223): "Seasons, daypart evolution and permanent World Growth
  remain deferred where the existing contract deferred implementation, and
  remain Free in commercial classification when delivered."
- §17 (line 329): "Normal seasons/daypart and permanent Personal Growth
  retain their source-authorized Free classification and the existing
  deferred delivery scope."
- §19 (line 373): "Normal seasons/daypart and permanent Growth —
  POST-LAUNCH; remain FREE."

That document is byte-locked: its SHA-256
(`1d4bb7aab996a5e01b8b9b3961275110d54a2da9315407feb639304149ca5e0d`) was
recorded when it was incorporated (commit `b39879f`), and `.gitattributes`
keeps it reproducible. Like ADR-013 to ADR-017, this ADR reconciles against
it without editing it.

## Decision

### 1. Static daypart artwork ships in V1, Free/shared

The founder approves static daypart artwork (morning / day / evening) as
part of the shared, pre-release visual pass. For static daypart artwork
only, this supersedes the deferral quoted above from freeze §11, §17 and
§19. Everything else in those passages stands:

- Season rendering, Weather Mood and Personal Growth rendering remain
  deferred.
- Premium Atmosphere remains post-launch (freeze §11, §19 line 372,
  unchanged). No motion, sound or new motion system is added.
- Daypart artwork is Free/shared; it is not a Premium feature and not a
  subscription promise.

Daypart boundaries (device-local time) are recorded in
[WORLD_SYSTEM.md v1.1.0 §10](../../worlds/WORLD_SYSTEM.md#10-daypart-and-weather-mood):
morning 05:00–11:59, afternoon 12:00–17:59 (artwork suffix `day`),
evening 18:00–04:59.

### 2. Five V1 Worlds

Quiet Trail, Still Lake, Open Room, Reading Nook and Garden Window are the
V1 Worlds — the first content pack of an expandable system, not a closed
set ([WORLD_SYSTEM.md §15–§16](../../worlds/WORLD_SYSTEM.md#16-v1-worlds-and-future-reference-worlds)).
All five are Free/shared World identities. Open Meadow remains a future
reference.

### 3. Scene Roles and modular Worlds

Activities name a Scene Role, never a World. Each World is self-contained
(World ID, Place DNA, served Categories, Scenes), and a selection policy
maps a role to a concrete Scene. V1 uses one approved default Scene per
role:

| Role | Default Scene |
|---|---|
| walk | `quiet_trail.walk` |
| breathe | `still_lake.breathe` |
| move | `open_room.move` |
| stretch | `open_room.stretch` |
| read | `reading_nook.read` |
| write | `reading_nook.write` |
| listen | `reading_nook.listen` |
| tend | `garden_window.tend` |
| comfort | `garden_window.comfort` |

No rotation, randomisation, user World choice, purchasable Worlds or
cosmetic editions are introduced.

### 4. Internal categories

The technical `generalWellness` category is replaced by internal
activity/World compatibility categories: `walking`, `stillness`,
`movement`, `quietFocus`, `homeCare` (`briskStepBurst` becomes `walking`).
Category is a compatibility axis — a World declares the Categories it
serves — not a one-to-one Place lookup.

## Consequences

- No user-facing contract changes: the three directions, recommendation
  selection, one assigned activity per local day, same-day restoration,
  activity copy, the Circle lifecycle, Plans, Coach, Insights,
  entitlements, reminders and analytics are unchanged.
- The artwork scope grows to five Worlds and nine Scenes, each with Hero
  and Card × three dayparts (54 production artworks), plus an approved
  master per new World. Missing artwork must fail the completeness check
  before any UI swap.
- Implementation follows in separate steps: A1 (architecture only, no UI
  change), B (artwork manifest and completeness tests), C (Home
  integration and Today card).
- The frozen Premium document remains byte-identical.

## Related documents

- [RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md](../RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md) — the controlling frozen Premium document; authoritative above this ADR for Premium product scope, amended here only for static daypart artwork
- [WORLD_SYSTEM.md v1.1.0](../../worlds/WORLD_SYSTEM.md)
- [ILLUSTRATION_LANGUAGE.md v1.0.1](../../illustration/ILLUSTRATION_LANGUAGE.md)
- [Quiet Trail](../../worlds/reference/QUIET_TRAIL_REFERENCE.md), [Still Lake](../../worlds/reference/STILL_LAKE_REFERENCE.md), [Open Room](../../worlds/reference/OPEN_ROOM_REFERENCE.md), [Reading Nook](../../worlds/reference/READING_NOOK_REFERENCE.md), [Garden Window](../../worlds/reference/GARDEN_WINDOW_REFERENCE.md) reference documents
- [ADR-007 — Premium Never Blocks the Core Loop](ADR-007-premium-never-blocks-the-core-loop.md)
