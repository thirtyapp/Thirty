# THIRTY Signature Objects

**Version:** v0.2
**Status:** FUTURE EXPLORATION / NON-BINDING
**Date:** 2026-09-29 (updated 2026-10-01: `garden_window.tend` observations)
**Owner:** THIRTY Product Design

## Purpose of this document

Some props that already appear in the approved THIRTY World artwork could, over time, become recurring and recognisable *THIRTY objects*: first inside the Worlds, later perhaps as optional, user-chosen variants, and much later perhaps as real physical things.

This document records that idea carefully enough to guide future artwork, personalization, merchandise exploration, brand review and product review. It **decides nothing**. It is not a V1 requirement, not a Premium entitlement, not a paid Atmosphere feature, not a commerce or physical-product commitment, not a personalization promise and not a retention or reward mechanic.

**Related:** [THIRTY_FUTURE_RITUAL_PRODUCTS_AND_MERCHANDISE.md](../strategy/THIRTY_FUTURE_RITUAL_PRODUCTS_AND_MERCHANDISE.md) explores the *commercial* side of these objects: ritual products versus merchandise, the Garden Window `tend` basket, and an adult coloring ritual book. This document keeps the *visual and object* inventory and its design hypotheses. Both are FUTURE EXPLORATION / NON-BINDING, and neither creates V1, Premium or roadmap scope.

### How to read this document

Every claim below belongs to one of three kinds, marked where the difference matters:

| Marker | Meaning |
|---|---|
| **[OBSERVED]** | A fact about the approved artwork currently present under `artwork/worlds/`, verified by visual inspection (§3). |
| **[PROPOSED RULE]** | A future design rule suggested for review. It binds nothing until adopted through governance (§15). |
| **[HYPOTHESIS]** | A future commercial or product hypothesis. It is not an approval, a plan or a forecast. |

Where no marker is given, a section is framing or principle and carries no more authority than a [PROPOSED RULE].

### Why `docs/design/`

`docs/worlds/` holds the approved, authoritative World System and World reference documents; placing a non-binding exploration there would suggest it shares their authority. `docs/brand/` holds approved brand-mark specifications. `docs/product/` holds product strategy, the frozen Premium contract and ADRs, where a commercial-sounding document could be misread as scope. `docs/design/` already holds working design documents (the Phase plans) and is the least authoritative-looking home for a cross-cutting exploration that touches Worlds, brand and product at once.

---

## A note on authority

This document sits **below** every one of the following and overrides none of them:

- the [THIRTY Playbook](../playbook/README.md);
- [BRAND_BOOK.md](../BRAND_BOOK.md);
- [DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md);
- [WORLD_SYSTEM.md v1.1.0](../worlds/WORLD_SYSTEM.md) and the World reference documents in [`docs/worlds/reference/`](../worlds/reference/);
- [ILLUSTRATION_LANGUAGE.md](../illustration/ILLUSTRATION_LANGUAGE.md);
- [PREMIUM_STRATEGY.md](../product/PREMIUM_STRATEGY.md) and the byte-locked [RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md](../product/RECURRING_PREMIUM_ARCHITECTURE_AND_MONETIZATION_FREEZE.md);
- all accepted ADRs, in particular [ADR-007](../product/adr/ADR-007-premium-never-blocks-the-core-loop.md) and [ADR-018](../product/adr/ADR-018-v1-world-art-scene-roles-and-daypart.md);
- the current pre-release scope.

**Where this document conflicts with any of them, they win.** Nothing here amends them. Where making a proposal binding would require changing one of them, §15 names that as a separate future governance decision.

---

## 1. Purpose — why recurring objects could matter

Recurring objects could help THIRTY:

- **make Worlds more recognisable** — a user may recognise *the* mat or *the* throw before consciously reading the scene;
- **create continuity between Scenes** — Reading Nook's three Scenes already share one chair, lamp, throw and cushion, and differ only in the object resting on them;
- **create subtle brand memory** — a quiet, repeated material detail rather than a mark;
- **make THIRTY feel like one coherent place** — the same care visible in every room of the product;
- **potentially bridge the digital and the physical brand, much later** — [Brand Book §24](../BRAND_BOOK.md#24-future-brand-evolution) already allows "aanvullende merkuitingen buiten de app", tested against the Golden Rule: *does this make THIRTY calmer, simpler and more human, or only bigger?*

Recurring objects must **not**:

- become logo spam;
- overpower the World or compete with its [one primary focus](../worlds/WORLD_SYSTEM.md#10a-shared-world-art-rules-v1);
- turn THIRTY into a lifestyle store;
- make Scenes look staged for merchandising;
- replace the World's emotional role — the user should still think *"I would like to be there"*, not *"I would like to buy that"* ([World System §1](../worlds/WORLD_SYSTEM.md#1-why-worlds-exist));
- become gamified collectibles, by default or otherwise (§13).

---

## 2. Core principle

> **First a believable object in the World. Only later, potentially, a THIRTY object.**

**[PROPOSED RULE]** A prop earns its place in a Scene by serving the Scene — its activity or its emotion — and must make complete sense even if merchandise never exists. **No object is ever inserted, enlarged, repositioned or made more distinctive solely because it could later be sold.**

A corollary: the World does not exist to display objects. If a Scene would feel emptier, flatter or less inviting without a prop, the prop serves the World. If it would feel exactly the same, the prop is incidental, and should stay that way.

---

## 3. Current object audit — [OBSERVED]

### 3.1 Scope and method

- **Source:** the approved artwork under `artwork/worlds/` in this working tree. ADR-018 scopes 54 production artworks (9 Scenes × {Hero, Card} × {morning, day, evening}). The v0.1 audit (2026-09-29) covered the 48 then present, across 8 of the 9 Scenes. All 54 are now present: `garden_window.tend` was authored and approved on 2026-09-30, and its six files were added to this audit on 2026-10-01. See the file inventory below.
- **Method:** every production file was inspected visually, as per-Scene contact sheets (Hero and Card × three dayparts) and as full-resolution detail crops of every portable object named below. Nothing was inferred from filenames alone. No artwork was modified; inspection copies were made outside the repository.
- **Excluded:** `_exploration/still_lake/still_lake_breathe_hero_sunset_exploration_v1.png` (moved and renamed from `still_lake/…_v1.png.png` on 2026-09-29) — an exploration, not a production daypart asset (it shows a sunset, which [World System §10](../worlds/WORLD_SYSTEM.md#10-daypart-and-weather-mood) excludes from evening artwork). It contains no portable objects.
- **`garden_window.tend` (added 2026-10-01):** all six files (Hero and Card × three dayparts) were inspected visually, using the runtime WebPs under `assets/worlds/garden_window/tend/`, which were converted from these masters without edits ([reconciliation §12](WORLD_ART_ASSET_FREEZE_RECONCILIATION_2026-09-29.md#12-step-b--production-integration-2026-09-30)). The basket, folded cloth and watering can named in the [Garden Window reference](../worlds/reference/GARDEN_WINDOW_REFERENCE.md) are now **observed**. In v0.1 they were hypothetical.

**File inventory [OBSERVED]:**

| World | Scene (ID) | Filename stem | Production files |
|---|---|---|---|
| Quiet Trail | `quiet_trail.walk` | `quiet_trail_walk_*` | 6 |
| Still Lake | `still_lake.breathe` | `still_lake_breathe_*` | 6 (+1 exploration, excluded) |
| Open Room | `open_room.move` | `open_room_move_*` | 6 |
| Open Room | `open_room.stretch` | `open_room_stretch_*` | 6 |
| Reading Nook | `reading_nook.read` | `reading_nook_read_*` | 6 |
| Reading Nook | `reading_nook.write` | `reading_nook_write_*` | 6 |
| Reading Nook | `reading_nook.listen` | `reading_nook_listen_*` | 6 |
| Garden Window | `garden_window.comfort` | `garden_window_comfort_*` | 6 |
| Garden Window | `garden_window.tend` | `garden_window_tend_*` | 6 (authored and approved 2026-09-30) |

54 production files in total; with the exploration, 55 files. "6/6" below means the object is present in all three Hero and all three Card dayparts of that Scene.

### 3.2 A. Environment identity — not merchandise

These carry the *Place*. They are World anchors or furniture, and an environmental anchor is **not** automatically a merchandise candidate.

| World | Observed environment identity |
|---|---|
| Quiet Trail | Leaning tree on the hillside; sandy winding path; grey boulders; white wildflowers; lake, islands and layered mountains beyond. |
| Still Lake | Flat shore rock with reeds (Hero); level water and low far shore; in the Cards, a small wooden jetty, rounded shore stones, pines and cattails. |
| Open Room | Floor-to-ceiling glass wall with a lake-and-mountain view; pale wooden floorboards; light and leaf shadows on the floor; a potted tree in a large white stone pot (Hero) and a broad-leaf plant in a speckled white pot (Card). |
| Reading Nook | Cream upholstered armchair; white ceramic table lamp with cream shade; round wooden pedestal side table; shelves with blue, unlettered book spines and trailing ivy; framed landscape picture (Hero); large multi-pane window onto trees, lake and mountains; woven rug; small leafy plant in a white vase (Hero) or white daisies in a white jug (Card). |
| Garden Window | Window seat with a long cushion; open casement window onto a garden (trees, lavender, flower beds, distant houses); small round wooden stool-table; trailing pothos in a cream pot; tall plants in woven baskets; wall shelf; woven pouf (Hero only); a small lantern on the shelf (evening). |

### 3.3 B. Portable / manufacturable objects — audit matrix

Consistency counts are Hero + Card across three dayparts for the Scene(s) named.

| World | Scene role | Visible object | Current role in composition | Consistency | Scene-defining or incidental | Signature-object suitability | Personalization suitability | Physical-product suitability | Risks / notes |
|---|---|---|---|---|---|---|---|---|---|
| Open Room | stretch | **Mat** — plain, unpatterned, sage-grey (reads slightly more teal in Cards), laid diagonally in the light | Primary activity cue; the Scene's defining object; reference-mandated anchor | 6/6, stable form and colour family | **Scene-defining** | High | High (colourway) | Strong for exploration | Must never drift toward fitness/studio aesthetic ([§10a](../worlds/WORLD_SYSTEM.md#10a-shared-world-art-rules-v1): no fitness equipment or performance aesthetic). Colour already sits near the brand's Sage family. |
| Open Room | stretch | **Reusable bottle** — sage/grey body, warm copper- or wood-toned cap with a carry loop, standing at the mat's far end | Secondary supporting prop | 6/6, stable | Incidental-to-supporting | Medium | Medium (colourway) | Plausible | The Open Room reference lists water bottles under *Never* for `move`; it is silent for `stretch`. Presence in `stretch` is an unresolved reference question (§3.4). Bottles are the most generic merchandise category — highest "logo on a product" risk. |
| Open Room | stretch | **Towel** — cream, rolled, beside the bottle | Supporting prop | 6/6, stable | Incidental | Low | Low | Weak | Generic object; reference offers "a folded blanket" as optional, which this approximates. |
| Open Room | move | *(no portable object)* | — | — | — | — | — | — | The reference's optional speaker is not present in any file. The Scene is carried by empty floor and light — as the reference intends. |
| Reading Nook | read / write / listen | **Throw** — blue-and-white, fringed; striped in Heroes, blue check in Cards; draped over the chair arm | Comfort and continuity across all three Scenes | 18/18 (pattern varies Hero ↔ Card) | Scene-supporting (not a cue) | Medium–High | High (colourway, weave) | Plausible | Its clear blue is outside the brand palette ([§10a Palette](../worlds/WORLD_SYSTEM.md#10a-shared-world-art-rules-v1)); identity is not yet stable (stripe vs check). The World DNA lists "a knitted throw appearing on the chair" as a **Growth Element** — it is already present from day one. |
| Reading Nook | read / write / listen | **Cushions** — one large blue patterned, one small cream | Comfort | 18/18 | Incidental | Low–Medium | Medium | Weak | Decorative; varies by World. |
| Reading Nook | read / write / listen | **Mug** — cream with a blue speckle/floral pattern, on the side table | Warmth, domestic detail | 18/18 | Incidental | Blocked (see risk) | Medium | Plausible *only* via Garden Window | [World System §10a](../worlds/WORLD_SYSTEM.md#10a-shared-world-art-rules-v1) assigns "cups and drinks" as a **World-exclusive motif of Garden Window**, and the Reading Nook reference lists "a cup" under *Never* for `read`. The approved art contradicts both (§3.4). |
| Reading Nook | read | **Book** — blue hardcover; *closed* on the side table in all 3 Heroes, *open* on the seat in all 3 Cards | Activity cue | 6/6 present; state differs Hero ↔ Card | Scene-defining in Cards; weak in Heroes | Medium | Low | Weak (a book is content, not a THIRTY object) | The same closed blue book also sits on the table in the day and evening `write` Heroes, so it does not uniquely signal reading in the Hero. |
| Reading Nook | write | **Notebook + pen** — notebook with blue cover (Heroes: bound; open in morning, closed in day/evening) / spiral-bound and open (Cards); navy pen with gold-toned trim | Activity cue | 6/6 present; notebook form differs Hero ↔ Card | Scene-defining | Medium–High (notebook) / Low (pen) | High (cover colour; initials only off-screen — §8) | Notebook: plausible. Pen: weak | Notebook identity is unstable (bound vs spiral). The pen's gold trim sits awkwardly with the Playbook's "never gold / no metallic accents" instinct ([Ch.3 §12](../playbook/03-circle-design-language.md#12-premium-design), scoped to Premium design but indicative). No desk is present, although the reference calls for one. |
| Reading Nook | listen | **Headphones** — cream/tan over-ear, soft wood-toned accents; on the armrest (Heroes) or seat (Cards) | Activity cue | 6/6, stable | Scene-defining | Medium | Low | Weak | Electronics: high manufacturing and quality bar, strong existing brands, easily read as tech product placement. Function cue must stay primary. |
| Reading Nook | listen | **Small round speaker** — pale blue-grey puck on the side table | Secondary cue | Heroes only (3/6) | Incidental | Low | None | Weak | Can read as a smart speaker; the reference permits "a small, plain radio" and forbids "speakers with lights". Should remain incidental. |
| Garden Window | comfort | **Mug** — cream, lightly speckled, with a warm drink, on a round wooden coaster | Primary activity cue; reference-mandated anchor ("the cup") | 6/6, stable | **Scene-defining** | High within Garden Window | Medium (glaze colourway) | Plausible | Reference expects visible steam; none is clearly visible at inspected scale. "Branded mug" is the most clichéd merchandise form — the design, not a mark, would have to carry it. |
| Garden Window | comfort, tend | **Throw** — sage-green knitted, fringed, over the window-seat end (reads blue-grey in evening light); in `tend`, over the window seat (Heroes) or beside the basket (Cards) | Comfort, warmth | 12/12 (`comfort` 6/6, `tend` 6/6), stable | Scene-supporting | Medium–High | High (colourway, knit) | Plausible | Sits within the brand's Sage family, unlike Reading Nook's blue throw. Two different throws across two Worlds: the *category* recurs, the *object* does not (yet). Within Garden Window, the same throw now recurs across both Scenes. |
| Garden Window | comfort | **Cushions** — cream, sage, peach knit | Comfort | 6/6 | Incidental | Low–Medium | Medium | Weak | Decorative. |
| Garden Window | comfort | **Coaster** — round, wooden | Detail under the mug | 6/6 | Incidental | Low | Low | Weak | — |
| Garden Window | comfort | **Pouf** — woven, round | Foreground mass | Heroes only (3/6) | Incidental | Low | Low | Weak | Furniture. |
| Garden Window | comfort | **Lantern** — small, on the wall shelf | Evening light accent | Evening Hero and Card only | Incidental | None | None | Weak | Daypart detail. |
| Garden Window | tend | **Utility basket / caddy** — rectangular, soft-sided, woven in a sage/straw tone, with tan leather tab handles fixed by small metal rivets; holds the other tending objects | Primary activity cue; the focal object of all three Cards; on the floor at the left in the Heroes | 6/6, stable | **Scene-defining** | Medium–High | Medium (weave colourway) | Plausible | The reference lists "a small wicker basket" as *optional* and places it on the table; the approved art makes it the Scene's clearest cue and places it on the floor or step. Commercial view: [Future Ritual Products §3](../strategy/THIRTY_FUTURE_RITUAL_PRODUCTS_AND_MERCHANDISE.md#3-garden-window-tend--utility-basket--caddy) (hypothesis only). |
| Garden Window | tend | **Watering can** — small, sage-green, long spout, leather-wrapped handle; stands inside the basket | Activity cue | 6/6, stable | Scene-supporting | Medium | Low | Plausible (niche) | Reference-optional. Reads as tending without any text or brand. |
| Garden Window | tend | **Folded cloth** — cream, draped over the basket edge; sage stripes in the day Hero and all three Cards, a sage/cream check in the morning and evening Heroes | Domestic detail | 6/6 present; pattern varies Hero ↔ Card | Incidental-to-supporting | Low | Low | Weak alone | Reference-optional. Identity not stable (stripe vs check). |
| Garden Window | tend | **Hand tool and small potted plant** — wooden-handled hand tool; small pot of daisies or greenery, both inside the basket | Supporting detail | 6/6 | Incidental | Low | None | Weak | — |
| Garden Window | tend | **Mug** — cream with a green leaf pattern, on the right-hand shelf | Domestic detail | Heroes only (3/6) | Incidental | Low | Low | — | Cups belong to Garden Window under §10a; no conflict. |
| Garden Window | tend | **Books** — one open book on the window seat; a closed stack on the round stool-table | Domestic detail | Heroes only (3/6) | Incidental | None | None | — | Books are a Reading Nook-exclusive motif under §10a. Recorded as a divergence (§3.4 item 10), not resolved here. |
| Open Room / Reading Nook / Garden Window | several | **Plant pots** — white stone, white ceramic, cream, woven basket, terracotta | Environment and life | Recur across three Worlds, but a different pot almost every time | Environmental | Low | Low | Weak | Environment, not a signature object. The Garden Window terracotta pot is a reference focal point and approved pigment, but in the approved art it sits secondary at the window edge. |
| Quiet Trail | walk | *(none)* | — | — | — | — | — | — | Legitimately object-free. The environment is the whole identity. |
| Still Lake | breathe | *(none)* | — | — | — | — | — | — | Legitimately object-free. The reference forbids towels, mats and cushions here. The jetty (Cards) is environment, not a portable object. |

### 3.4 Observed divergences between approved artwork and existing references

Recorded because they affect which objects can be treated as stable. **This document does not resolve them, and no artwork is changed because of them.** They are listed for a later art-direction or governance decision.

1. **Cups outside Garden Window.** Reading Nook shows a mug in all 18 files; §10a makes "cups and drinks" a Garden Window-exclusive motif, and the Reading Nook reference forbids a cup in `read`.
2. **Bottle in Open Room.** The reference forbids water bottles in `move`; `stretch` has one in all 6 files, and the reference is silent there.
3. **Reading Nook palette and chair.** The reference calls for a Circle Sage armchair; the approved chair is cream, and the recurring textiles, book and notebook covers are a clear blue outside the brand palette and approved pigments.
4. **Read vs write Heroes.** All three Reading Nook Heroes share one base composition. The `read` Heroes show only a closed book on the side table; the `write` day/evening Heroes show a closed notebook with pen. Activity cues are clearer in the Cards than in the Heroes.
5. **Notebook form.** Bound in Heroes, spiral-bound in Cards.
6. **Hero ↔ Card object continuity.** Still Lake Cards introduce a jetty and shore stones absent from the Heroes (§10a: the Card may not introduce objects the Hero does not contain); the jetty is also a listed Growth Element. Open Room's Hero and Card show different plants.
7. **Open water beyond Still Lake.** Open Room, Reading Nook and Quiet Trail artwork show lakes, although §10a lists open water as Still Lake-exclusive and the Open Room reference says its windows show "only sky".
8. **Reference status lag.** All four newer reference documents still read "master artwork pending", while approved artwork now exists.
9. **Asset housekeeping (organizational only).** At the time of this audit, Reading Nook filenames used `reading/writing/listening` while Scene IDs use `read/write/listen`, and the Still Lake exploration file had a doubled `.png.png` extension; both were normalized by filename only on 2026-09-29 (see [WORLD_ART_ASSET_FREEZE_RECONCILIATION_2026-09-29.md](WORLD_ART_ASSET_FREEZE_RECONCILIATION_2026-09-29.md)). Dimensions vary (for example `open_room_move_hero_evening_v1.png` is 1402×1122 while its siblings are 1254×1254; Garden Window `comfort` Heroes are about 720 px and carry a baked rounded paper frame the other Heroes do not, while the `tend` Heroes are 1536×1024). The `artwork/` directory is currently untracked in git.
10. **Books in Garden Window `tend` (added 2026-10-01).** All three `tend` Heroes show an open book on the window seat and a closed stack of books on the round stool-table. [§10a](../worlds/WORLD_SYSTEM.md#10a-shared-world-art-rules-v1) lists "armchair, reading lamp, bookshelf, books" as Reading Nook-exclusive. The `tend` Cards show no books. This is **observed, non-blocking and awaiting founder review**. It is not resolved here: the artwork, World System §10a and Reading Nook's exclusivity are all unchanged.

---

## 4. Signature object levels

A descriptive maturity model. **It is not a release roadmap.** Moving up a level is never automatic, never scheduled and never a goal in itself.

| Level | Name | Definition |
|---|---|---|
| **0** | Incidental prop | Appears naturally; no brand-system significance. |
| **1** | Recurring World prop | Appears repeatedly within one Scene or World with stable design language. |
| **2** | THIRTY signature object | Recognisable across multiple approved expressions (Hero, Card, dayparts, and ideally more than one Scene) without feeling inserted. |
| **3** | Personalization-capable object | Has a controlled set of variants that preserve its core identity (§5, §8). Requires a separate product decision. |
| **4** | Physical-product candidate | The digital object is recognisable and coherent enough to *explore* as a real product. Requires a separate commercial decision. |

**Current observed placement [OBSERVED + assessment]:**

| Object | Current level | Why not higher |
|---|---|---|
| Open Room mat | **1**, closest to 2 | Stable across 6/6 but appears in one Scene only. |
| Reading Nook throw | **1** | Stable across 18/18 and three Scenes, but its pattern changes Hero ↔ Card and its colour is off-palette. |
| Garden Window throw | **1** | Stable across 12/12 and both Garden Window Scenes (since 2026-10-01); one World; different object from the Reading Nook throw. Its level was not re-assessed in the 2026-10-01 sync. |
| Garden Window basket / caddy | **1** | Stable 6/6 and Scene-defining, but one Scene only. |
| Garden Window watering can | **1** | Stable 6/6; one Scene. |
| Garden Window mug | **1** | Stable 6/6; its cross-World recurrence (Reading Nook) is in conflict with §10a. |
| Reading Nook notebook + pen | **1** (pen: 0–1) | Notebook form differs Hero ↔ Card. |
| Reading Nook headphones | **1** | Stable; one Scene. |
| Open Room bottle | **1** | Stable; one Scene; reference question open. |
| Reading Nook book, cushions; Open Room towel; Garden Window cushions, coaster, pouf, lantern; `tend` cloth, hand tool, mug and books; speaker; plant pots | **0** | Incidental by role. |

**No object is at Level 3 or 4.** Nothing in this document promotes one.

---

## 5. Object identity contract — [PROPOSED RULE]

For any object that is later deliberately treated as a Signature Object, the following would stay **stable**:

- **silhouette** — the outline a user recognises at Card scale;
- **proportions** — including thickness, roll or fold behaviour;
- **core material** — cotton knit, felted rubber, stoneware, paper;
- **visual weight** — never heavier than the Scene's primary focus;
- **restrained palette** — rooted in Circle Sage, Mist Sage, Warm Stone and Cream, plus the World's approved pigment; no new brand colours, no saturated accents;
- **placement logic** — where the object naturally rests in its Scene (the mat in the light patch; the throw over the arm);
- **scale range** — believable, human scale; never enlarged for visibility;
- **relationship to the World** — it belongs to its Place and obeys §10a's World-exclusive motifs;
- **no oversized logos, and no text-first branding** — in artwork this is absolute ([§10a](../worlds/WORLD_SYSTEM.md#10a-shared-world-art-rules-v1): no brands, logos or legible text).

And the following **may vary**, provided the object stays recognisable:

- colourway, from a tiny THIRTY-authored set;
- fabric, knit or surface texture detail;
- seasonal treatment, once Season rendering exists ([§9](../worlds/WORLD_SYSTEM.md#9-seasons));
- a small blind-embossed or tonal mark — **physical objects only**; never visible in artwork;
- initials, **only** if explicitly chosen by the user, and **only** on a physical object (§8);
- wear, age and environmental lighting;
- daypart lighting (as already happens: the Garden Window throw reads blue-grey at evening).

Test: *if the variant were shown without any context, would someone who knows the Scene still say "that's the mat from THIRTY"?* If not, the variant has broken the identity.

---

## 6. World-specific guidance

Candidates are drawn only from §3. No new props are proposed.

**Quiet Trail — `walk`.** No portable objects, and none should be added. The tree, path and open landscape are the identity. *Environment only.*

**Still Lake — `breathe`.** No portable objects; the reference explicitly forbids mats, cushions and towels because they turn stillness into "practice". The rock is an environmental anchor, not a product. *Environment only.*

**Open Room — `move`.** No portable objects. The emptiness *is* the Scene ("room to move"). Do not bring the mat or bottle into `move` for continuity's sake; that would erase the Move vs Stretch distinction the reference defines.

**Open Room — `stretch`.** The **mat** is the clearest Signature Object candidate in the whole V1 pack: activity cue, mandatory anchor, stable, plain, near-palette, no marks. The **bottle** is a stable secondary prop but carries an unresolved reference question and the highest generic-merchandise risk. The **towel** should stay incidental.

**Reading Nook — `read`.** The **book** is a function cue, not a brand object — a book is its content, and a "THIRTY book" is not meaningful. The shared **throw** is the stronger recurring candidate for this World. A bookmark is *not* observed and remains a hypothesis only.

**Reading Nook — `write`.** The **notebook** is a genuine candidate (writing is intrinsic to THIRTY's reflective side), but its form is not yet stable. The **pen** should stay incidental.

**Reading Nook — `listen`.** The **headphones** are a clear, stable function cue and should remain one. They are a weak brand-object candidate: electronics invite tech-product comparison and a product quality bar outside THIRTY's domain. The speaker puck should stay incidental.

**Garden Window — `comfort`.** The **mug** is the Scene's defining activity cue and a natural Level 1 object. The sage **knitted throw** is palette-true and a strong recurring-textile candidate.

**Garden Window — `tend`.** Authored and approved on 2026-09-30, and added to this audit on 2026-10-01. The woven **basket / caddy** is the Scene's clearest activity cue and its most distinctive object. The **watering can** supports the cue. The **folded cloth** stays incidental while its pattern varies. The sage **knitted throw** is shared with `comfort`. That an object appears here does not make it a Signature Object (§4). The books in the Heroes are an open divergence (§3.4 item 10).

---

## 7. Activity cue vs brand object

An **activity cue** tells the user, before any words are read, what today's activity is. A **Signature Object** creates recurring THIRTY identity. The same object *may* do both — never automatically.

| Object | Primary job today | May also become a brand object? |
|---|---|---|
| Mat | Cue: stretching | Yes, carefully |
| Notebook + pen | Cue: writing | Notebook possibly; pen no |
| Headphones | Cue: listening | Unlikely |
| Book | Cue: reading | No |
| Mug (Garden Window) | Cue: a small comfort ritual | Possibly |
| Throws | Comfort and continuity | Yes — the least cue-bound candidates |

**[PROPOSED RULE] Function comes first.** Branding an object must never reduce how quickly the activity is understood. Concretely:

- a cue object's silhouette stays generic enough to read instantly (a mat looks like any calm mat; headphones look like headphones);
- distinctiveness comes from material, colour and care — never from shape changes that slow recognition;
- where the cue is currently weak (§3.4, item 4: the Reading Nook Heroes), the fix belongs to art direction for clarity, **not** to making the object more branded.

---

## 8. Personalization — [PROPOSED RULE]

A future, optional, explicitly user-chosen layer. **No implementation, promise or scope is created here.**

**Conceptually allowed:**

- choosing an object's colour from a tiny, THIRTY-authored set;
- choosing an approved material treatment;
- optional initials — **on a physical object only**, never rendered in the World (§10a forbids legible text in artwork);
- choosing among a small number of THIRTY-authored object variants.

**Not allowed:**

- inferred mood, health state, gender, personality or purchasing power;
- behavioural targeting presented as personalization;
- variants that change automatically, making the World feel inconsistent from day to day;
- personalization that changes the meaning of the activity or weakens its cue;
- anything that requires additional personal data ([ADR-004](../product/adr/ADR-004-optional-data-never-required.md): optional data is never required).

**The World must feel complete without personalization.** An un-personalized World is the full World, not a default waiting to be upgraded.

**Existing constraints any future proposal must reconcile with:**

- ADR-018 introduces "no rotation, randomisation, user World choice, purchasable Worlds or cosmetic editions";
- the frozen Premium contract excludes per-user art production in V1;
- V1 artwork is authored per Scene × Daypart × expression only ([§3](../worlds/WORLD_SYSTEM.md#3-world-structure)). Per-object variants would multiply this matrix, and would need an explicit production and architecture decision of their own.

**Most plausible future personalization candidates [HYPOTHESIS]:** mat colourway; throw colourway or knit (Reading Nook and Garden Window); notebook cover colour; Garden Window mug glaze. **Not candidates:** headphones, book, pen, speaker, plant pots, furniture.

---

## 9. Merchandise principles — [PROPOSED RULE] and [HYPOTHESIS]

### 9.1 Principles

A THIRTY physical object, if one ever exists, should:

- **originate from an established in-app object** — never designed first as a product and then placed into a World;
- **be genuinely useful** in the life of someone doing their thirty minutes;
- **match THIRTY's calm material and visual language** — narrow palette, natural materials, soft texture;
- **work without a large THIRTY logo** — recognisable by form, colour and material; at most a small tonal or embossed mark;
- **feel premium through restraint, material and detail**, not through status signals ("never gold" — [Playbook Ch.3 §12](../playbook/03-circle-design-language.md#12-premium-design));
- **not rely on novelty drops, limited editions or artificial scarcity** ([Playbook Ch.4 §12](../playbook/04-product-decision-framework.md#12-things-thirty-will-probably-never-build): artificial urgency, FOMO);
- **never turn the product into a commerce funnel** — no shop surfaces in the daily ritual, no product prompts at Circle Closed, no product links from inside a World.

**The test:** *would the physical object feel as if it came out of the World — or as if a logo was printed on generic merchandise?*

### 9.2 Candidate classification — [HYPOTHESIS]

Classifications are for *later exploration only*. None is approved as a product. No sales or revenue is estimated.

| Candidate | Artwork presence | Recognisability | Usefulness | Brand fit | Natural in a World | Conceptual manufacturability | Classification |
|---|---|---|---|---|---|---|---|
| Mat | Open Room `stretch`, 6/6 | High, stable | High | High, if kept soft and non-athletic | Yes (mandatory anchor) | Straightforward | **Strong candidate for later exploration** |
| Throw / blanket | Reading Nook 18/18; Garden Window 6/6 | Medium — two different throws | High | High (Garden Window sage especially) | Yes | Straightforward | **Plausible candidate** (strong once one throw identity is settled) |
| Notebook / journal | Reading Nook `write`, 6/6 | Medium — form varies | High | High | Yes | Straightforward | **Plausible candidate** |
| Mug | Garden Window 6/6; Reading Nook 18/18 (in conflict with §10a) | Medium | High | Medium — highest cliché risk | Yes in Garden Window | Straightforward | **Plausible candidate** (Garden Window only) |
| Reusable bottle | Open Room `stretch`, 6/6 | Medium | High | Medium — generic-merch and fitness-adjacent risk | Contested (reference question) | Straightforward | **Plausible candidate**, conditional on §3.4 item 2 |
| Cushion | Reading Nook, Garden Window | Low — varies | Medium | Medium | Yes | Straightforward | **Weak candidate** |
| Pen | Reading Nook `write`, 6/6 | Low | Medium | Low (gold trim) | Yes | Straightforward | **Weak candidate** |
| Headphones | Reading Nook `listen`, 6/6 | Medium | High | Low — electronics, tech-brand territory | Yes | Demanding | **Weak candidate** |
| Towel | Open Room `stretch`, 6/6 | Low | Medium | Medium | Yes | Straightforward | **Weak candidate** |
| Bookmark | **Not observed** in any artwork | — | Medium | Medium | — | Straightforward | **Weak candidate — hypothetical only** |

Environmental anchors (tree, rock, jetty, armchair, lamp, window seat, plant pots, furniture) are excluded from merchandise classification by design.

The `tend` objects (§3.3) arrived after this table was written and are not classified here. Their commercial view is explored only as a hypothesis, along with ritual products in general, in [THIRTY_FUTURE_RITUAL_PRODUCTS_AND_MERCHANDISE.md](../strategy/THIRTY_FUTURE_RITUAL_PRODUCTS_AND_MERCHANDISE.md). No product is approved there or here.

---

## 10. Artwork rule — [PROPOSED RULE, consistent with current practice]

- **The approved artwork is frozen for the current integration step.** It is used as-is.
- **No image is altered to make a prop more merchandisable** — not recoloured, enlarged, repositioned, marked or cleaned up for that purpose.
- Future artwork *may* gradually standardise an already-approved recurring prop (for example, settling one throw design, or one notebook form). That is a **later art-direction decision**, made for the World's sake and reviewed against the World System — never a merchandising task.
- The divergences in §3.4 are for art direction and governance to resolve on their own merits. Their resolution must not be driven by merchandise potential.

---

## 11. World System compatibility

Signature Objects belong to **visual identity**, not to the core activity architecture. The conceptual chain stays exactly as [World System §3 and §17](../worlds/WORLD_SYSTEM.md#17-architectural-implications) define it:

```
Activity
  → Scene Role
    → compatible World
      → Scene
        → Daypart
          → artwork
```

**[PROPOSED RULE]**

- Objects are never hard-wired to a Category, Scene Role or activity. A future World implementing the same role (for example a Forest Path `walk` Scene, or another `stretch` Scene) does **not** automatically need the same objects. It may use them if they belong to that Place.
- No object introduces a new dimension into the World structure, the resolver, the manifest or the recommendation logic.
- World-exclusive motifs (§10a) outrank object recurrence: a Signature Object may not carry a motif into a World that does not own it.

---

## 12. Free / Premium safety

- Nothing in this document classifies Signature Objects, their personalization or any merchandise as **Premium**.
- **Base Worlds remain complete.** The objects already in the approved artwork are part of the shared World and stay Free, as World identity, normal daypart artwork and the full visual identity already are ([World System §12](../worlds/WORLD_SYSTEM.md#12-free-and-premium), [ADR-018](../product/adr/ADR-018-v1-world-art-scene-roles-and-daypart.md)).
- **No object may be removed from, dimmed in, or withheld from the Free World** to create a paid version of it.
- Any future commercial decision — paid personalization, a physical product, or any bundling with Premium — needs its own explicit product approval, checked against the [Premium Filter](../playbook/04-product-decision-framework.md#5-the-premium-filter), [PREMIUM_STRATEGY.md](../product/PREMIUM_STRATEGY.md) and the frozen Premium contract.

---

## 13. Anti-gamification

Signature Objects must **never** become:

- streak rewards;
- loot;
- badges;
- collectible pressure;
- scarcity mechanics;
- "complete the set" systems;
- objects that can be lost, faded or withdrawn when the user is absent.

If an object ever changes through World growth, it obeys the existing rule without exception:

> **"The world grows through return, not perfection."** — [World System §11](../worlds/WORLD_SYSTEM.md#11-personal-growth)

Growth is cumulative, permanent, unannounced and non-competitive. An object may quietly appear; it is never unlocked, awarded or taken away. Physical merchandise is never tied to Circle counts, milestones or any in-app behaviour.

---

## 14. Design review checklist

For any future object proposal — in artwork, personalization or merchandise:

- [ ] Does the object make sense in the Scene without any branding?
- [ ] Does it support the activity or the Scene's emotional intent?
- [ ] Would the World still work if this object were removed?
- [ ] Is it visually restrained, and quieter than the Scene's primary focus?
- [ ] Does it fit the THIRTY palette and material language?
- [ ] Is it recognisable without a logo?
- [ ] Is it becoming product-placement-like?
- [ ] Does the World remain the primary emotional experience?
- [ ] Could it work digitally before anyone discusses physical merchandise?
- [ ] Would a physical version feel authentic rather than promotional?
- [ ] Is any personalization explicit and user-controlled, and is the World complete without it?
- [ ] Does it avoid Premium, streak and commerce coupling?
- [ ] Does it respect §10a — World-exclusive motifs, no legible text or logos, no fitness or performance aesthetic?
- [ ] Does it keep the activity cue at least as clear as before?

---

## 15. Status, authority and future governance decisions

**Status: FUTURE EXPLORATION / NON-BINDING.** This document does not override the Playbook, the Brand Book, the Design System, the World System and references, the Illustration Language, the approved Premium strategy and freeze, accepted ADRs, or the current pre-release scope. Where they conflict, they win.

Making any part of this binding would require **separate, explicit decisions**, none of which is taken here:

1. **Art direction / World System** — whether to recognise "Signature Objects" as a World System concept at all; and resolving the §3.4 divergences (cups in Reading Nook, bottle in Open Room, palette, Hero ↔ Card continuity, reference status).
2. **Brand** — whether physical brand expressions outside the app are pursued at all, under [Brand Book §24](../BRAND_BOOK.md#24-future-brand-evolution).
3. **Product** — whether user-chosen object personalization exists at all, reconciled with ADR-018's "no cosmetic editions", ADR-004, and per-user art production limits.
4. **Commercial** — whether any merchandise is explored, through a dedicated product review and, if Premium is touched, an ADR reconciled against the byte-locked Premium freeze.

---

## Open questions

1. Should Reading Nook's mug stay, given §10a's Garden Window cup exclusivity — or should §10a be amended to reflect the approved art?
2. Is the Open Room `stretch` bottle intended? The reference forbids bottles only in `move`.
3. Should one throw identity eventually be settled per World — and are two different throws in two Worlds a feature (each Place its own) or a missed continuity?
4. Should Reading Nook's recurring blue be reconciled with the brand palette, or recorded as an approved exception?
5. Which notebook form (bound or spiral) is canonical?
6. Is the `read` activity cue in the Reading Nook Heroes sufficient, given the near-identical `read` and `write` Hero compositions?
7. Should the reference documents' "master artwork pending" status be updated now that approved artwork exists?
8. Should the asset housekeeping items in §3.4 item 9 be tidied in a separate, purely organizational task?
9. **Founder review:** should the open book and closed books in the Garden Window `tend` Heroes stay, given that §10a makes books Reading Nook-exclusive (§3.4 item 10)? Non-blocking; unresolved.

---

## Version history

### v0.2 — 2026-10-01

- Synchronized the audit with the delivered `garden_window.tend` artwork (authored and approved 2026-09-30): file inventory 54/54; `tend` objects observed (basket / caddy, watering can, folded cloth, hand tool, mug, books); the sage throw recorded across both Garden Window Scenes; the Garden Window Hero dimension note corrected to `comfort` only.
- Recorded the books in the `tend` Heroes as divergence §3.4 item 10 and open question 9, for founder review. Not resolved.
- Added a cross-reference to [THIRTY_FUTURE_RITUAL_PRODUCTS_AND_MERCHANDISE.md](../strategy/THIRTY_FUTURE_RITUAL_PRODUCTS_AND_MERCHANDISE.md).
- Status unchanged: FUTURE EXPLORATION / NON-BINDING. No artwork, code, asset, World System, Premium or freeze document changed. No object level was raised above 1.

### v0.1 — 2026-09-29

- Initial exploration. Audit of the 48 production files under `artwork/worlds/` (the Still Lake sunset exploration excluded; `garden_window.tend` not yet authored). Levels, identity contract, personalization and merchandise principles recorded as non-binding proposals and hypotheses. No artwork, code, asset manifest, Premium or freeze document changed.
