# Reading Nook — Illustration Reference

**World:** Reading Nook · World ID `reading_nook` · serves `quietFocus`
**Version:** v1.0
**Status:** Approved direction v1.0 — master artwork pending

## Purpose

This document defines the artistic direction for Reading Nook, THIRTY's V1 World for reading, writing, single-task focus and quiet listening. It governs the illustration, not its implementation.

## A note on authority

This document does not sit above [WORLD_SYSTEM.md](../WORLD_SYSTEM.md) or [ILLUSTRATION_LANGUAGE.md](../../illustration/ILLUSTRATION_LANGUAGE.md). Reading Nook's World DNA, World ID, served Category and Scenes are recorded in [World System §16](../WORLD_SYSTEM.md#16-v1-worlds-and-future-reference-worlds) and are not restated here. The shared V1 art rules in [World System §10a](../WORLD_SYSTEM.md#10a-shared-world-art-rules-v1) apply here in full.

No master illustration exists yet. Every future master and Scene artwork is checked against this document and requires explicit Product Design approval.

---

## 1. Place identity

These anchors must remain recognisable in every Scene and every Daypart:

1. A deep armchair in Circle Sage fabric.
2. A small-shaded reading lamp.
3. A low bookshelf whose spines are never legible.
4. One small window — secondary, showing sky or a single branch, never a garden.
5. The enclosed framing of the alcove: a wall corner or a curved niche.

The chair and the lamp stay constant across all three Scenes; what distinguishes the Scenes is the object and where it rests.

## 2. Scenes

### `reading_nook.read` — role `read`

**Activities:** quietReading.

**Emotional job:** sink into one thing.

**Hero composition:** the armchair in three-quarter view, an open book resting naturally on the armrest or adjacent side table, with no legible text and without implying a specific absent occupant; the lamp above it, the small window at the side.

**Card companion composition:** the armrest with the open book, lit by the scene's current light.

**Mandatory anchors:** the chair, the book, the lamp.

**Optional objects:** the throw, the shelf plant.

**Never:** readable text; e-readers or phones; reading glasses (a body trace); a cup (cups belong to Garden Window); piles that look like homework.

### `reading_nook.write` — role `write`

**Activities:** writeItDown, singleTaskFocus.

**Emotional job:** clear the head by putting one thing on paper.

**Hero composition:** a small writing desk tucked into the alcove under the window, with an open notebook, a pencil and the lamp over the desk. The chair or the shelf stays visible at the edge so the Scene reads unmistakably as the Nook.

**Card companion composition:** the notebook and pencil on the desk edge, under the scene's current light.

**Mandatory anchors:** the desk surface with the open notebook, the lamp; in the Hero, the chair or the shelf.

**Optional objects:** one closed book, the plant.

**Never:** laptops or phones; calendars or to-do lists with legible items; walls of sticky notes; clutter.

### `reading_nook.listen` — role `listen`

**Activities:** quietMusicBreak, quietAudioFocus.

**Emotional job:** let sound fill the room while you rest.

**Hero composition:** the armchair, with headphones resting on the armrest or a small, plain radio on the side table; the lamp and the window.

**Card companion composition:** the side table with the radio or headphones, lit by the scene's current light.

**Mandatory anchors:** the chair, the lamp, the listening object.

**Optional objects:** the throw, the plant.

**Never:** screens or speakers with lights; music notes or sound waves; record collections as clutter.

## 3. Daypart direction

- **Morning (05:00–11:59):** pale, cool window light dominates; the lamp is off; the chair is lit from the side.
- **Day (12:00–17:59):** a brighter window; the lamp is off; short, soft shadows.
- **Evening (18:00–04:59):** the lamp is the dominant light, making a warm pool. The window is deep blue-grey; a faint moon or one star may appear, provided the lamp remains clearly dominant. The edges of the room fall away into soft Warm Stone, never black. No sunset. Credible at 18:00, 02:00 and 04:59.

## 4. Dark-theme notes

In evening artwork, the edges of the room must dissolve to transparency rather than be painted dark, or they merge into the dark card surface. The lamp pool is the visible light mass.

## 5. Differentiation

- **From Quiet Trail:** interior, enclosed and lamp-lit instead of open landscape.
- **From Still Lake:** enclosed instead of an exposed horizon.
- **From Open Room:** furnished and close instead of empty and wide; the focus is the chair, not light on the floor.
- **From Garden Window:** a personal, seated alcove instead of a shared table; the window is small and secondary, with no garden view.

## 6. Hero ↔ Card continuity

Shared: the direction of the scene light — morning and day use the window direction with the lamp off; evening uses the lamp as the dominant light — the Scene object, the chair or desk surface, the palette and the Daypart. The Card may omit the shelf and the window.

---

## Non-goals

This document does not define Flutter, rendering techniques, file formats, asset paths, Season, Weather Mood, Personal Growth rendering or Premium Atmosphere.

*v1.0 — approved direction. Builds on [WORLD_SYSTEM.md v1.1.0](../WORLD_SYSTEM.md) and [ILLUSTRATION_LANGUAGE.md](../../illustration/ILLUSTRATION_LANGUAGE.md) and contradicts neither.*
