# THIRTY Wordmark — Construction Brief

**Version:** v0.1
**Status:** Draft. This document prepares manual vector reconstruction of the selected wordmark development candidate. It does not approve final geometry, a final font, or a production asset (§13, Non-Goals).

## Purpose and Status

[THIRTY_WORDMARK.md](THIRTY_WORDMARK.md) approved the wordmark-led First Breath *direction* (v1.0/v1.0.1) — uppercase, calm, humanist, legible, warm, editorial, timeless, restrained. It did not select a typeface, geometry, or production asset. A subsequent wordmark-only visual concept round explored that direction and produced two finalists.

- **Ownable Restraint is the selected development candidate.**
- **Terminal System is the reserve.**
- **Neither candidate is approved as final typography.** Selecting a development candidate is a narrowing of exploration, not an approval — it does not pass through, and is not equivalent to, [THIRTY_WORDMARK.md §13](THIRTY_WORDMARK.md#13-document-authority)'s Approval Pipeline stages 4–6.
- The reference images for both candidates are exploratory raster concepts, held outside this repository in a read-only reference directory. They are concept evidence, not production assets, and are not copied, traced, moved, renamed, or added to the repository by this document or any task that produced it.
- **Raster appearance must not be mistaken for exact geometry.** An image generator does not preserve consistent stem weight, corner radius, tracking, or optical spacing the way a constructed vector does — visual impression is a direction to work from, not a set of numbers to extract.
- The purpose of this document is to turn the selected visual direction into controlled, reproducible vector construction: a brief a designer or a future vector-construction pass can build from deliberately, letter by letter, rather than by tracing a generated image.
- **The future vector prototype remains subject to visual review and approval** — this document does not pre-approve its outcome.

Preserve, unchanged and load-bearing here as everywhere else in the brand-document system:

> "The Circle is not the logo.
> The Circle is the product."

---

## A note on authority

This document does not sit above [THIRTY_WORDMARK.md](THIRTY_WORDMARK.md), [THIRTY_SYMBOL.md](THIRTY_SYMBOL.md), [BRAND_BOOK.md](../BRAND_BOOK.md), [WORLD_SYSTEM.md](../worlds/WORLD_SYSTEM.md), [MOTION_LANGUAGE.md](../motion/MOTION_LANGUAGE.md), or [DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md). It is a construction brief operating entirely *inside* the boundaries [THIRTY_WORDMARK.md](THIRTY_WORDMARK.md) already set — it decides none of the direction, only how that already-approved direction gets built.

### Source Hierarchy

1. **[THIRTY_WORDMARK.md](THIRTY_WORDMARK.md)** governs the approved direction — what the wordmark must be and must never become. This document must never contradict it.
2. **This document, THIRTY_WORDMARK_CONSTRUCTION.md,** governs the reconstruction brief, once approved — the letter-by-letter, spacing, and test-matrix intent a manual vector pass is built from.
3. **The standalone Ownable Restraint image** is a visual concept reference only — evidence of a direction, not a source of geometry.
4. **Terminal System is a reserve reference only** — held in case Ownable Restraint does not survive vector construction or testing.
5. **Generated Circle-context images are validation evidence only** and must not define letter geometry — an image generator's rendering of a wordmark inside a Circle may alter letterforms, scale, spacing, and proportions in ways that do not reflect deliberate construction choices.
6. **A future approved master vector asset** becomes the implementation source of truth, once it exists and is separately approved (Approval Pipeline stage 5).

Stated explicitly, because it is easy to blur under time pressure:

- **No generated raster image is a production asset** — regardless of how close it looks to finished.
- **No automatic raster trace may become the master.** Tracing preserves generator artefacts (blur, anti-aliasing, inconsistent weight) as if they were deliberate geometry; they are not.
- **AI output may not redefine the approved direction.** This document, and any future AI-assisted step in constructing the wordmark, is checked against [THIRTY_WORDMARK.md](THIRTY_WORDMARK.md) — never the reverse.

## Table of contents

1. [Purpose and Status](#purpose-and-status)
2. [Selected Candidate](#2-selected-candidate)
3. [Qualities to Preserve](#3-qualities-to-preserve)
4. [Qualities to Correct](#4-qualities-to-correct)
5. [Construction Principles](#5-construction-principles)
6. [Letter-by-Letter Intent](#6-letter-by-letter-intent)
7. [Spacing and Word Shape](#7-spacing-and-word-shape)
8. [Circle Relationship](#8-circle-relationship)
9. [Required Test Matrix](#9-required-test-matrix)
10. [Accessibility](#10-accessibility)
11. [Colour](#11-colour)
12. [Reconstruction Rejections](#12-reconstruction-rejections)
13. [Non-Goals](#13-non-goals)
14. [Prototype Phase](#14-prototype-phase)
15. [Document Authority](#15-document-authority)

---

## 2. Selected Candidate

**Primary development candidate: Ownable Restraint.** Selected over Terminal System because it currently offers the strongest combination of:

- compact word shape;
- calm mobile readability;
- visual subordination to the Circle;
- restrained humanist character;
- subtle terminal consistency;
- a more ownable overall silhouette;
- credible First Breath presence.

**Reserve: Terminal System.** Retained rather than discarded — if Ownable Restraint fails vector construction, optical testing (§9), or a future review, Terminal System is the next candidate to attempt, not a restart from nothing.

This selection is developmental only. It authorises moving from "two rasters" to "one deliberate vector-construction attempt" — it does not authorise treating that attempt's first output as finished.

## 3. Qualities to Preserve

The selected candidate's intended qualities, to be preserved through vector construction rather than reinterpreted:

- uppercase THIRTY;
- calm humanist sans-serif construction;
- compact but breathable word shape;
- light-to-regular visual weight;
- moderate character width;
- strong mobile readability;
- open internal spaces;
- straight baseline;
- restrained tracking;
- subtle corner and terminal softening;
- warm editorial character;
- no decorative contrast;
- stable silhouette while completely still (a direct consequence of [THIRTY_WORDMARK.md §4](THIRTY_WORDMARK.md#4-motion-relationship)'s no-heartbeat requirement — a silhouette that reads as unstable at rest would undermine stillness before any animation is even added);
- monochrome compatibility.

The complete wordmark must feel like one coordinated alphabet — a shared logic across all six letters, not six letters that each happened to look acceptable on their own.

## 4. Qualities to Correct

Issues visible in the raster concept evidence that still require deliberate resolution during vector construction — not yet solved, and not to be treated as solved by this document:

- the generated tracking may still be too wide;
- the I may remain visually anonymous;
- the R leg may become too fluid or calligraphic — the Ownable Restraint reference shows a leg with a soft, curved terminal that reads as closer to a calligraphic flourish than a controlled, humanist terminal; this is exactly the risk to correct deliberately during construction, not to carry forward because it photographed well;
- the Y fork may remain too sharp or athletic;
- generated corner radii may be inconsistent — raster generation does not guarantee the same radius is used at every comparable corner;
- apparent stroke weight may vary because of raster generation, not because of a deliberate stem-weight system;
- mathematical centring may not equal optical centring — a raster's bounding-box centre and its perceived visual centre are frequently different, especially with an asymmetric letter like R or Y at either end;
- the wordmark must be validated at the real 236px minimum interior ([THIRTY_WORDMARK.md §6](THIRTY_WORDMARK.md#6-current-size-feasibility)) — nothing in the reference images was generated at, or tested against, that constraint;
- the reference image may contain soft edges, colour variation, or raster artefacts that must not enter the vector — anti-aliasing and generation noise are rendering side effects, not intended geometry.

None of these are claimed to be already solved. Construction is exactly the process that resolves them, deliberately and one at a time, checked against §6 below rather than inherited silently from either reference image.

## 5. Construction Principles

The future vector construction must be:

- outline-based;
- precise;
- monochrome;
- built on a consistent cap-height system;
- built with a coherent stem-weight system;
- optically spaced;
- free from raster texture;
- free from gradients;
- free from transparency;
- free from decorative atmosphere;
- independent from any installed font at runtime;
- suitable for exact rendering at multiple sizes.

This document does not decide the final SVG package or Flutter integration architecture — those are implementation decisions for a later technical pass, checked against the approved production asset rather than assumed here.

**No font is selected as the final source by this document.** A typeface may later be used only as a private construction scaffold — a starting skeleton a designer works from — when legally and technically appropriate (correct licence for the intended use, no redistribution of font files as-is). It must not silently become the approved wordmark: using a typeface as a scaffold is a construction technique, not an approval, and the resulting outlines still require the same deliberate letter-by-letter and optical work this document describes before anything is proposed for review.

## 6. Letter-by-Letter Intent

Construction logic, not final numeric geometry. Every value below is qualitative and intentionally unresolved until vector prototypes exist and are tested (§9).

**T**

- both T letters must use identical geometry;
- moderate crossbar width;
- no oversized or athletic top;
- calm vertical stem;
- subtle terminal treatment shared with the I;
- stable at small size.

**H**

- open and balanced;
- humanist crossbar placement;
- no industrial construction;
- consistent stem weight;
- sufficient inner space at 236px testing scale.

**I**

- narrow and simple;
- visibly intentional;
- coordinated with the T terminal system;
- not a serif I;
- not punctuation;
- no detached bars;
- must not disappear at reduced size.

**R**

- open, calm bowl;
- clear counter;
- restrained transition from bowl into leg;
- warm but controlled leg;
- no dramatic tail;
- no calligraphic sweep;
- no aggressive diagonal kick;
- must remain clear when reduced.

The R is the letter most at risk from the reference concept evidence (§4) — the reserve construction target here is a controlled, humanist leg, not the softer, more fluid curve visible in the Ownable Restraint raster.

**Y**

- moderately open fork;
- softened but controlled junction;
- centred lower stem;
- no athletic or sharp character;
- stable endpoint logic consistent with the alphabet.

No final numeric geometry (cap height, stem width, corner radius, junction angle) is invented by this document.

## 7. Spacing and Word Shape

Optical-spacing goals, per letter pair:

- **T–H** — compact but breathable, no visual gap that reads as a word break;
- **H–I** — enough space that the I reads as a distinct letter, not enough to isolate it;
- **I–R** — no oversized gap around the narrow I on either side;
- **R–T** — no collision between the R's leg/counter and the second T's crossbar or stem;
- **T–Y** — enough space for the Y's fork to open without touching the preceding T.

Requirements:

- compact but breathable spacing throughout;
- no mechanically equal tracking assumption — visual rhythm, not a single fixed unit repeated six times;
- no oversized gaps around the I;
- no collision between the R and second T;
- a stable left and right visual boundary — the word should read as one contained shape, not as loosely scattered letters;
- optical rather than purely mathematical centring, both for the whole word and letter-to-letter;
- a word shape sufficiently compact for the minimum Circle (§8, §9).

**The final tracking remains unresolved until vector prototypes are tested** — nothing in this section fixes a number.

## 8. Circle Relationship

Restated from [THIRTY_WORDMARK.md §5](THIRTY_WORDMARK.md#5-relationship-to-the-circle) as a construction constraint, not re-decided here. The future wordmark must:

- remain horizontal;
- remain on a straight baseline;
- be optically centred inside the Circle;
- be fully contained within the Circle;
- preserve generous inset;
- remain subordinate to the Circle;
- avoid contact with the Circle stroke;
- remain completely still while visible;
- fade out completely before the Circle opens.

It must not:

- follow Circle curvature;
- wrap around the Circle;
- reshape the Circle;
- become a circular lock-up;
- represent progress;
- represent completion.

This document does not define the final display percentage (how much of the Circle's interior the wordmark occupies) — that is a §9 testing outcome, not a number fixed in advance.

## 9. Required Test Matrix

Future vector prototypes must be rendered and reviewed at the Circle interior sizes below, grounded in the real, current `circle_hero.dart` implementation ([THIRTY_WORDMARK.md §6](THIRTY_WORDMARK.md#6-current-size-feasibility)):

- **236px** — minimum supported interior (the documented `_circleMinSize = 260` floor, less stroke);
- **320px** — typical mid-size interior;
- **416px** — maximum current interior (the documented `_circleMaxSize = 440` ceiling, less stroke).

For every size, test:

- full-word readability;
- I visibility;
- R counter clarity;
- R-leg stability;
- Y-junction clarity;
- safe horizontal inset;
- safe vertical inset;
- optical centring;
- Circle dominance (the Circle must still read as the larger, calmer object — the wordmark must not compete with it);
- monochrome edge quality;
- fade readiness (does the silhouette still read as calm and legible at the point fade-out would begin);
- absence of unintended sport, technology, luxury, or fashion associations.

All candidate renders must use identical Circle geometry and scaling logic, so results are comparable across sizes and across candidates.

**Generated context images do not satisfy this technical test matrix.** A single AI-generated Circle-context image, however convincing, is not a substitute for rendering an actual constructed vector at the three specified interior sizes and checking it against every item above.

## 10. Accessibility

The approved accessibility boundary from [THIRTY_WORDMARK.md §8](THIRTY_WORDMARK.md#8-accessibility) is unchanged and must be preserved by whatever the vector construction produces:

- the visible wordmark is decorative during First Breath;
- it is excluded from semantics;
- "THIRTY" is not separately announced;
- the Circle remains the single meaningful semantics owner;
- transition progress is not narrated;
- reduced motion preserves all content and access;
- Start Circle is not actionable before it is ready.

**The vector asset must not introduce hidden text semantics by itself.** Whether the final rendering approach is a vector outline or literal text, the exclusion pattern ([THIRTY_WORDMARK.md §8](THIRTY_WORDMARK.md#8-accessibility)) is what keeps it decorative — not the asset format.

## 11. Colour

The wordmark inherits **Circle Sage** from the Design System ([DESIGN_SYSTEM.md §2.1](../DESIGN_SYSTEM.md#brand-identity-vs-implementation-tokens)), exactly as [THIRTY_WORDMARK.md §7](THIRTY_WORDMARK.md#7-colour) already established. The Design System remains the sole authority for the colour value; this document does not define, own, or duplicate it, and introduces no new token.

The production wordmark must:

- work in one flat colour;
- remain identical across Worlds;
- remain identical for free and Premium users;
- contain no gradient;
- contain no texture;
- contain no shadow;
- contain no glow;
- contain no World or seasonal variation.

## 12. Reconstruction Rejections

Explicitly rejected as construction methods or outcomes:

- automatic image tracing as the master;
- vectorising raster noise;
- preserving generated blur or anti-aliasing as geometry;
- using hundreds of unnecessary control points;
- inconsistent corner radii;
- inconsistent stem weights without optical purpose;
- arbitrary per-letter quirks;
- a decorative R tail;
- a sharp athletic Y;
- excessive tracking;
- condensed compression;
- runtime live text as a substitute for an approved master asset;
- AI-generated output as final geometry;
- embedding a raster image inside an SVG;
- adding a symbol, gesture, Circle, underline, or ornament.

## 13. Non-Goals

This document does not decide or create:

- final vector paths;
- final cap height;
- final stem width;
- final corner radius;
- final tracking;
- final kerning;
- final wordmark dimensions;
- final SVG architecture;
- Flutter integration;
- production asset filename;
- font licensing solution;
- an app icon;
- a splash composition;
- a standalone symbol;
- animation timing;
- Premium variation.

These require later, separate design and implementation passes, checked against this document and [THIRTY_WORDMARK.md](THIRTY_WORDMARK.md) rather than assumed by either.

## 14. Prototype Phase

The next production steps, not executed by this document:

1. Establish a normalized construction grid.
2. Reconstruct the six letters as clean vector outlines.
3. Apply one coherent stem, terminal, and corner system.
4. Create a first optical-spacing pass.
5. Render at 236px, 320px, and 416px Circle interiors.
6. Review at native size and magnified size.
7. Make only deliberate, documented optical corrections.
8. Select one vector prototype for production-asset review.

This task does not execute those steps — it prepares the brief they will follow.

## 15. Document Authority

- **[THIRTY_WORDMARK.md](THIRTY_WORDMARK.md)** governs the approved wordmark direction; this document does not alter it.
- **This document, THIRTY_WORDMARK_CONSTRUCTION.md,** governs the reconstruction brief — construction principles, letter-by-letter intent, spacing goals, and the required test matrix.
- **[THIRTY_SYMBOL.md](THIRTY_SYMBOL.md)** remains the record of the superseded standalone-symbol direction; unaffected by this document.
- **[MOTION_LANGUAGE.md](../motion/MOTION_LANGUAGE.md)** and **[WORLD_SYSTEM.md](../worlds/WORLD_SYSTEM.md)** continue to govern motion and sequence respectively; nothing here changes either.
- **A later technical task or ADR** governs implementation — Flutter widget structure, asset pipeline, and rendering — checked against this document and [THIRTY_WORDMARK.md](THIRTY_WORDMARK.md) rather than deciding it here.

### Approval Pipeline

Active state, per [THIRTY_WORDMARK.md §13](THIRTY_WORDMARK.md#13-document-authority):

1. **Wordmark-led First Breath decision** — complete.
2. **THIRTY_WORDMARK.md direction approval** — complete.
3. **Wordmark-only visual concept round** — complete. Ownable Restraint and Terminal System produced as the two finalists.
4. **Select and manually refine one wordmark** — in progress.
   - Ownable Restraint selected as primary development candidate.
   - Terminal System retained as reserve.
   - No final geometry approved.
5. **Approve the production master vector wordmark asset** — not started.
6. **Implement First Breath v2** — not started.

**Stage 4 is not marked complete by this document.** This document is the brief stage 4's manual refinement work is checked against — it advances stage 4, it does not finish it.

## Version History

### v0.1 — 2026-08-06

- Initial draft.
- Prepares manual vector reconstruction of Ownable Restraint, the selected wordmark development candidate, with Terminal System retained as reserve.
- Records the source hierarchy governing which reference material may and may not define letter geometry.
- Defines qualities to preserve and qualities still requiring deliberate correction, grounded in the raster concept evidence rather than assumed solved.
- Defines letter-by-letter construction intent for T, H, I, R, Y and spacing goals for each adjacent letter pair — qualitative direction, no final numeric geometry.
- Defines the required 236px/320px/416px test matrix against the real `circle_hero.dart` implementation.
- Restates, without altering, the Circle-relationship, accessibility, and colour requirements already established in [THIRTY_WORDMARK.md](THIRTY_WORDMARK.md).
- Records an explicit reconstruction-rejection list and the eight-step prototype phase this document prepares but does not execute.
- Not yet reviewed or approved. No vector asset has been generated from this version.

---

## Ownership

**Owner**

THIRTY Brand Design

**Review Process**

- Construction-direction changes require Brand Design approval.
- Manual vector prototypes require visual review.
- Final optical spacing requires review at all required sizes (§9).
- The production master vector requires explicit approval, separate from this brief (Approval Pipeline stage 5).
- Implementation must use the approved production asset, not this brief or any prototype directly (stage 6).
- Flutter code, automatic tracing, or AI generation may not redefine the geometry.

This review process is separate from, and does not substitute for, final production-asset approval (Approval Pipeline stage 5) — completing this brief's construction principles does not itself approve anything past stage 4.

Once Approved, this document is never silently edited — only through an explicit, dated patch or amendment, in the same spirit as [THIRTY_WORDMARK.md](THIRTY_WORDMARK.md) and [THIRTY_SYMBOL.md](THIRTY_SYMBOL.md) already practice.

No image, icon, font, SVG, or code asset may be generated from this document until the remaining approval-pipeline stages (stages 5–6) are separately completed. Reaching Draft, and later Approved, status for this brief alone does not authorise asset generation.

---

*This is v0.1 of the THIRTY Wordmark Construction Brief, in Draft status. It builds on [THIRTY_WORDMARK.md](THIRTY_WORDMARK.md), [THIRTY_SYMBOL.md](THIRTY_SYMBOL.md), [BRAND_BOOK.md](../BRAND_BOOK.md), [WORLD_SYSTEM.md](../worlds/WORLD_SYSTEM.md), [MOTION_LANGUAGE.md](../motion/MOTION_LANGUAGE.md), and [DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md), and contradicts none of them. It governs the reconstruction brief for the selected wordmark development candidate — construction principles, letter-by-letter intent, spacing, and the required test matrix; final vector geometry and a production master asset remain separate, later approvals (§15, Approval Pipeline, stages 5–6). Future direction changes require explicit THIRTY Brand Design approval.*
