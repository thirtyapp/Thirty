# Open Room — Illustration Reference

**World:** Open Room · World ID `open_room` · serves `movement`
**Version:** v1.0
**Status:** Approved direction v1.0 — V1 Scene × Daypart artwork authored and approved for integration (2026-09-29)

## Purpose

This document defines the artistic direction for Open Room, THIRTY's V1 World for stretching and free movement. It governs the illustration, not its implementation.

## A note on authority

This document does not sit above [WORLD_SYSTEM.md](../WORLD_SYSTEM.md) or [ILLUSTRATION_LANGUAGE.md](../../illustration/ILLUSTRATION_LANGUAGE.md). Open Room's World DNA, World ID, served Category and Scenes are recorded in [World System §16](../WORLD_SYSTEM.md#16-v1-worlds-and-future-reference-worlds) and are not restated here. The shared V1 art rules in [World System §10a](../WORLD_SYSTEM.md#10a-shared-world-art-rules-v1) apply here in full. Open Room is the V1 movement World; Open Meadow remains a future reference only.

V1 Scene × Daypart artwork for `open_room.move` and `open_room.stretch` (Hero and Card, morning / day / evening) has been authored and visually approved by the founder for integration (2026-09-29). No separate World master illustration exists. Every future master and Scene artwork is checked against this document and requires explicit Product Design approval.

**Reconciliation note (2026-09-29).** The approved artwork differs from some rules in this document. Those differences are recorded in the [World Art Asset Freeze Reconciliation](../../design/WORLD_ART_ASSET_FREEZE_RECONCILIATION_2026-09-29.md) and are pending founder decision. The design rules below are unchanged; the approval of the artwork does not amend them.

---

## 1. Place identity

These anchors must remain recognisable in every Scene and every Daypart:

1. Two or three tall, multi-pane windows on one wall. They show only sky and pale light — never a garden.
2. Bare wooden floorboards receding into the room.
3. The shape of light on the floor — the World's focal point.
4. One tall, leafy plant in a corner.
5. Emptiness: at least half of the floor stays open.

## 2. Scenes

### `open_room.move` — role `move`

**Activities:** moveToMusic, activeMovementSnack.

**Emotional job:** permission to move freely — energy without performance.

**Hero composition:** a wide view of the room at standing eye height. The windows sit in the left third, the floor is open, the light patch falls centre-right. A small speaker rests on the windowsill as the music cue; a slightly lifted curtain suggests air and movement.

**Card companion composition:** floorboards and the pane of light, with the speaker at the edge of the sill.

**Mandatory anchors:** the floor, the light patch, the windows.

**Optional objects:** the speaker, the lifted curtain, the plant.

**Never:** gym equipment, weights, trainers or shoes; mirrors; fitness trackers or water bottles; disco lights; music notes.

### `open_room.stretch` — role `stretch`

**Activities:** energisingStretchFlow, gentleStretchPause.

**Emotional job:** a slow, unhurried space for the body to lengthen.

**Hero composition:** a closer, lower vantage with more floor and less wall. A soft mat is rolled out in the light patch, with the windows as backdrop. Calmer than `open_room.move`.

**Card companion composition:** the end of the mat in the light, with the lines of the floorboards.

**Mandatory anchors:** the mat, the light patch, the floorboards.

**Optional objects:** a folded blanket, the plant, the curtain.

**Never:** figures in poses; blocks and straps arranged like a studio class; mirrors; instruction posters.

**Move vs. Stretch:** Move is a wide, standing-height view with a speaker and a hint of air; Stretch is a low, still view with a mat.

## 3. Daypart direction

- **Morning (05:00–11:59):** broad, diffuse morning window light from the left, forming a soft elongated light field on the floor; cool walls, a warm light patch. Window-bar shadows may be suggested faintly but are never graphic, dramatic or high-contrast.
- **Day (12:00–17:59):** a shorter, steeper light patch; the room evenly lit and at its brightest.
- **Evening (18:00–04:59):** the windows turn deep blue, with a faint moon or simply dark sky. A single warm floor lamp becomes the dominant light and takes over the pool of light on the floor, so the focal point is preserved. No sunset. Credible at 18:00, 02:00 and 04:59.

## 4. Dark-theme notes

Large light floor areas can glare on the dark card surface. Paint the floor in a mid Warm Stone tone rather than paper white; the shared paper backing handles the feathered edges.

## 5. Differentiation

- **From Quiet Trail:** an interior, with the geometric window grid instead of organic landscape; the focus is light, not a tree.
- **From Still Lake:** vertical windows and a floor plane instead of a level water horizon.
- **From Reading Nook:** empty and wide, with nothing to sit in; bright and cool instead of an enclosed, warm lamp.
- **From Garden Window:** no table and no domestic objects; the windows show only sky, never a garden.

## 6. Hero ↔ Card continuity

Shared: the floor, the light shape, the direction of the window light (or lamp light in the evening), the Scene object (speaker or mat), the palette and the Daypart. The Card may omit the windows — the light shape implies them — and the plant.

---

## Non-goals

This document does not define Flutter, rendering techniques, file formats, asset paths, Season, Weather Mood, Personal Growth rendering or Premium Atmosphere.

*v1.0 — approved direction. Builds on [WORLD_SYSTEM.md v1.1.0](../WORLD_SYSTEM.md) and [ILLUSTRATION_LANGUAGE.md](../../illustration/ILLUSTRATION_LANGUAGE.md) and contradicts neither.*
