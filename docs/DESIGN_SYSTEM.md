# THIRTY — Design System

**Status:** v1.1 — Color system evolved for the Circle Sage palette (Playbook v1.0 alignment).
**Scope of this document:** what every design token **is**, and **why** it exists. It defines colors, and references (without redefining) the typography, spacing, radius, and shadow tokens already implemented in `lib/core/theme/`.

This document is referenced by [BRAND_BOOK.md §13](BRAND_BOOK.md#13-color-philosophy) and sits below the [THIRTY Playbook](playbook/README.md) in the documentation hierarchy: the Playbook governs *why* THIRTY's visual language takes the shape it does (see especially [Chapter 3 — Circle Design Language](playbook/03-circle-design-language.md)); this document governs *what* each token's exact value is, and the reasoning specific to that value. Where this document and the Playbook conflict, the Playbook wins. Where this document and the Flutter token files (`lib/core/theme/app_colors.dart`, `app_theme.dart`) conflict, the token files are the implementation source of truth — this document should be updated to match them, not the other way around.

This document deliberately separates two layers that are easy to collapse into one: THIRTY's stable **brand colors** and the **Flutter implementation tokens** derived from them. See ["Brand Identity vs. Implementation Tokens"](#brand-identity-vs-implementation-tokens) immediately below before reading §2 — it explains why `primary`'s rendered value is not always identical to the brand color it represents, and why that is by design, not drift.

---

## Brand Identity vs. Implementation Tokens

THIRTY's color system has two layers. Keeping them visibly distinct is the point of this section — collapsing them into "the color" is exactly the confusion this document exists to prevent.

**1. Brand Identity — what Circle Sage *is*.** Circle Sage (`#7C8B6D`) is THIRTY's official, approved brand color for the new emotional direction. It represents the Circle in the Playbook's sense — Chapter 1 §3: *"The Circle is not the app icon... it is the thing THIRTY is."* Circle Sage is the value to use for brand assets, marketing, illustration, product communication, and any static or non-interactive expression of THIRTY's visual identity. It does not change to satisfy a rendering engine's constraints. If it is ever revised, that is a deliberate brand decision (Playbook Ch.4, the Golden Product Question), not a side effect of engineering.

**2. Implementation Tokens — what `AppColors.primary` *is*.** `primary`, and every other field on `AppColors`, is a Flutter-specific implementation role: a name a widget reaches for at render time. Its value is *derived from* the brand color but is allowed to diverge from it — minimally, and only when documented — to satisfy constraints the brand color itself doesn't carry: a specific component's WCAG contrast requirement, a platform rendering quirk, a future technical limitation. Today, `primary`'s light-mode value (`#67735A`) diverges from Circle Sage by ~17% for exactly one documented reason (§4.2): `ThirtyButton`'s current architecture reuses the same token for both a filled background and an outline variant's text color, and only one of those two hex values can satisfy both roles' contrast requirements at once.

**Why this matters going forward:** the brand color is stable — it encodes an emotional decision about what THIRTY *is*. The implementation token is allowed to evolve — a future refactor that separates `ThirtyButton`'s fill color from its text color, for instance, could let `primary` return to the exact brand value with no accessibility compromise, without that being a brand change at all. Every hex value stated elsewhere in this document says explicitly which of these two layers it describes.

---

## 1. Why the palette changed

THIRTY's original palette (turquoise primary `#22B8A8`, cool blue-gray neutrals) was chosen before the [Playbook](playbook/README.md) existed. Once Chapter 1 named the Circle as *the product itself* — not a decoration on top of it — the turquoise/teal identity read as **energetic, technological, modern**: a fitness-app palette, not a calm daily ritual. It photographed like a productivity dashboard, not like the "rustige, deskundige vriend" (calm, capable friend) described in [Brand Book §7](BRAND_BOOK.md#7-personality).

The new palette is built around **Circle Sage** — a muted, natural green that reads as **calm, timeless, premium, restorative, human** — paired with warm neutrals (Cream, Warm Stone) instead of cool technical grays. This is a direct application of Playbook [Chapter 3 §6, Color Philosophy](playbook/03-circle-design-language.md#6-color-philosophy): *"A wide, expressive palette signals that a product wants to be noticed. A narrow, consistent one signals that a product already trusts what it's built."*

Nothing else changed. Typography, spacing, radius, shadows, component structure, and layout are untouched — this is a **token value and naming update only**, per this task's explicit scope.

---

## 2. Color tokens

Each token is documented as: **Name · Hex · Purpose · Usage · Emotional role.**

### 2.1 Circle Sage — brand color, with a documented implementation-token divergence in `primary`

**Brand color (stable):** `#7C8B6D`. This is the official, approved Circle Sage value — see ["Brand Identity vs. Implementation Tokens"](#brand-identity-vs-implementation-tokens) above. Use this exact value for brand assets, marketing, illustration, product communication, and any static or non-interactive expression of THIRTY's visual identity. It does not change for accessibility or implementation reasons; a future revision to it would be an explicit brand decision, not a side effect of engineering.

**Implementation token — `primary`** (may diverge from the brand color, minimally and only when documented):

| Mode | Rendered value | Divergence from brand color | Why |
|---|---|---|---|
| Light | `#67735A` | ~17% deepened | `ThirtyButton`'s outline variant reuses `primary` as both border and label text; the brand value fails WCAG AA as text on White/Cream. See §4.2. |
| Dark | `#869676` | ~8% lightened | Same dual-role constraint, mirrored for the dark surface. See §4.2. |

This divergence is an **implementation decision**, scoped to how `AppColors.primary` is currently consumed by one component's dual use of a single token — it is not a redefinition of THIRTY's brand color, and it is not a claim that Circle Sage "is" `#67735A`. Circle Sage *is* `#7C8B6D`; the `primary` token currently *renders as* a value close to it, for the one documented, component-specific reason above.

**Purpose:** THIRTY's single primary accent — "Eén primair accent" ([Brand Book §13](BRAND_BOOK.md#13-color-philosophy)).

**Usage:** The Circle's progress arc and fill, primary button backgrounds, the outline/border and label of secondary buttons, focus indication, any element marking the one primary action on a screen.

**Emotional role:** Represents life, renewal, calm and presence — the color of something growing quietly rather than performing. It is used sparingly and only where it means something, per Playbook Ch.3 §6: *"When a designer reaches for a new color, the right first question is not 'does this look good here,' it's 'what would the user misunderstand if this were left neutral instead.'"* This emotional role belongs to the brand color; the implementation token exists only to make that emotional role renderable and accessible in Flutter.

### 2.2 Mist Sage — `secondary`

| Mode | Hex |
|---|---|
| Light | `#E9EEE6` (exact, official) |
| Dark | `#525A49` (derived — see §3) |

**Purpose:** A soft, receded second tone in the same sage family as the primary accent — never a competing hue.

**Usage:** Low-emphasis fills that Material's `ColorScheme.secondary` role reaches for internally (e.g. a selected segment in a settings control). Not currently used directly by any THIRTY-authored widget — `ThirtyButton`, `ThirtyCard`, and `ThirtyProgressCircle` all reach for `primary`, `border`, `disabled`, `surface`, or the text tokens instead.

**Emotional role:** A hush of the primary — present without asking to be noticed. It embodies "Color supports attention. It never competes for attention": if `primary` is the Circle speaking, `secondary` is the room it speaks in.

### 2.3 Warm Stone — source for `border` and `disabled`

| Role | Light | Dark | Derivation |
|---|---|---|---|
| `border` | `#D8D8D6` | `#6E6F6A` | Warm Stone (`#8F8F8A`) blended 35% into White (light) / 70% into the dark surface (dark) |
| `disabled` | `#E6E6E5` | `#53544F` | Warm Stone blended 22% into White (light) / 45% into the dark surface (dark) |

Warm Stone itself is not used at full strength as a token value — its role in the official palette is structural (chrome, dividers, muted state), not a color meant to be seen at full saturation on its own. It is the *source* neutral for THIRTY's two structural gray tokens, tinted toward each mode's base surface so the same warm, stone-like character survives in both light and dark UI (see §3 for why this needed deriving rather than a given hex, and §4.3 for the accessibility numbers behind each weighting).

**Purpose (`border`):** A visible-but-quiet line — card edges, dividers, the progress ring's unfilled track (via `border.withValues(alpha: 0.6)` in `ThirtyProgressCircle`).

**Purpose (`disabled`):** The fill for an unavailable control, and its outline when outlined.

**Emotional role:** Structure without assertion — "Diepte via laag, niet via lawaai" ([Brand Book §11.4](BRAND_BOOK.md#11-design-principles)): depth through layer, not through noise. `border` is deliberately low-contrast against `surface`/`background` (as it always has been in this codebase) because card separation is carried primarily by elevation (`AppShadows`), not by a hard line — see §4.4 for why this is a deliberate, pre-existing pattern rather than a new gap.

### 2.4 Cream — `background`

`#FAF8F3` (exact, official, both modes reference the same warm-cream *feeling*; dark mode's background is a separate, deliberately dark value — see §3).

**Purpose:** The base surface behind everything — the "page" of the app.

**Usage:** `scaffoldBackgroundColor` in `AppTheme`.

**Emotional role:** A warm, soft page rather than a clinical white — closer to paper or linen than to a screen. It is the visual equivalent of the silence Playbook Ch.2 §6 describes: not empty, just quiet.

### 2.5 White — `surface`

`#FFFFFF` (exact, official, light mode only — dark mode has its own derived surface, see §3).

**Purpose:** The fill for content containers that sit *on* the background and need to read as a distinct layer — cards, sheets.

**Usage:** `ThirtyCard`'s fill.

**Emotional role:** Clean, but not cold — because it never appears without Cream immediately behind it and Warm-Stone-derived neutrals bordering it, White here reads as "clear space to think," not "sterile."

### 2.6 Primary Text — `textPrimary`

| Mode | Hex |
|---|---|
| Light | `#1F2320` (exact, official) |
| Dark | `#F0F2ED` (derived — see §3) |

**Purpose:** The color for anything that must be read first and clearly — titles, primary body copy, numbers.

**Usage:** `AppTypography`'s `displayLarge`, `headlineSmall`, `titleMedium`, `bodyLarge`, and `labelLarge` slots; `onSurface`; `onSecondary` (see §4.2).

**Emotional role:** Confident and legible without being stark black-on-white — a near-black with the faintest warmth, consistent with "never clinical."

### 2.7 Secondary Text — `textSecondary`

| Mode | Hex |
|---|---|
| Light | `#5F655D` (exact, official) |
| Dark | `#ADB4A7` (derived — see §3) |

**Purpose:** Supporting copy that should recede behind `textPrimary` — captions, durations, disabled labels.

**Usage:** `AppTypography`'s `bodyMedium` slot; the disabled foreground color in `ThirtyButton`.

**Emotional role:** A quieter voice in the same room as Primary Text — present, softer, never absent.

### 2.8 Semantic colors — `success` / `warning` / `error`

`#48C774` / `#F4B740` / `#E55A5A` — **unchanged**, both modes. See §5 for why these are explicitly out of scope for this pass.

---

## 3. Dark mode: a proposed extension, not an official spec

The palette given for this task (Circle Sage, Mist Sage, Warm Stone, Cream, White, Primary Text, Secondary Text) specifies **light mode only**. `AppColors.dark` is a mandatory, fully independent palette in this codebase, and [Brand Book §12](BRAND_BOOK.md#12-visual-language) requires dark mode to be *"een eersteklas ervaring, niet een omgekeerd kleurenschema"* — a first-class experience, not an inverted color scheme. Rather than invent unrelated dark colors or silently reuse the old turquoise dark palette, I derived a dark-mode counterpart in the same sage hue family (same hue angle as Circle Sage, pushed to very low lightness for background/surface, very high lightness for text), following standard practice for extending a light brand palette into dark mode. **This dark palette is a proposal, not a ratified brand asset** — treat `AppColors.dark`'s exact hex values as provisional until you sign off on them the way you did the light values.

| Token | Value | Derivation |
|---|---|---|
| `background` | `#141612` | Circle Sage's hue (≈90°) at ~10% saturation, ~8% lightness — a warm near-black, not a cool blue-black. |
| `surface` | `#21241E` | Same hue family, ~13% lightness — one visible step above background, mirroring how the old dark surface (`#1C2126`) sat above the old dark background (`#111417`). |
| `textPrimary` | `#F0F2ED` | Same hue family, ~94% lightness — a warm near-white. |
| `textSecondary` | `#ADB4A7` | Same hue family, ~68% lightness. |
| `secondary` | `#525A49` | Same hue family, ~32% lightness — Mist Sage's "soft, receded" role re-expressed for a dark base, since a literally light color would violate the "not inverted" rule. |
| `border` | `#6E6F6A` | Warm Stone blended 70% into the dark surface. |
| `disabled` | `#53544F` | Warm Stone blended 45% into the dark surface. |
| `primary` | `#869676` | See §4.2. |

---

## 4. Accessibility review

Every color relationship below was checked against WCAG 2.1 contrast ratios (4.5:1 for normal text, 3:1 for large text / UI-component boundaries), using the standard relative-luminance formula. This section states the method and result for every pairing that a user will actually see, not just the ones that happened to pass.

### 4.1 Text on background/surface — all pass without adjustment

| Pair | Ratio | Requirement | Result |
|---|---|---|---|
| Primary Text `#1F2320` on Cream `#FAF8F3` | 15.0:1 | 4.5:1 | Pass (AAA) |
| Primary Text on White `#FFFFFF` | 15.9:1 | 4.5:1 | Pass (AAA) |
| Secondary Text `#5F655D` on Cream | 5.64:1 | 4.5:1 | Pass |
| Secondary Text on White | 5.99:1 | 4.5:1 | Pass |
| Dark textPrimary `#F0F2ED` on dark surface `#21241E` | 13.9:1 | 4.5:1 | Pass (AAA) |
| Dark textPrimary on dark background `#141612` | 16.2:1 | 4.5:1 | Pass (AAA) |
| Dark textSecondary `#ADB4A7` on dark surface | 7.38:1 | 4.5:1 | Pass (AAA) |
| Dark textSecondary on dark background | 8.56:1 | 4.5:1 | Pass (AAA) |

None of these needed adjustment — the given Primary Text / Secondary Text values, and their derived dark counterparts, were accessible as specified.

### 4.2 Circle Sage as both a fill and a text color — the one objective failure, and the fix

*This section documents an implementation decision confined to the `primary` token — see ["Brand Identity vs. Implementation Tokens"](#brand-identity-vs-implementation-tokens). It does not redefine THIRTY's brand color, which remains `#7C8B6D`.*

`ThirtyButton`'s outline (secondary) variant reuses `colors.primary` for **both** the border **and** the label text (`thirty_button.dart:52-53`). This means Circle Sage has to independently satisfy two different WCAG rules at once:

- As a **fill** behind black/white text — needs only 3:1 (non-text UI component contrast, or effectively whatever makes the paired text pass 4.5:1).
- As **text itself**, sitting directly on Cream/White (light) or on the dark surface/background (dark) — needs the full 4.5:1 normal-text minimum, since THIRTY's `labelLarge` (15px/500) does not qualify for the 3:1 "large text" exemption (18pt regular / 14pt bold minimum).

At the **reference** value `#7C8B6D`, Circle Sage as *text* measures **3.64:1 on White and 3.43:1 on Cream** — both fail 4.5:1. This is an objective WCAG AA failure, not a preference. (For context: the *original* turquoise `#22B8A8` had the same latent bug at ~2.33:1 — this defect predates the new palette; auditing the new palette surfaced it.)

Because the task scope forbids touching `ThirtyButton`'s component code, the only compliant fix available at the token level was to adjust the `primary` value itself, sized to the minimum shift required:

- **Light mode:** deepened `#7C8B6D` → `#67735A` (~17% darker). As text: **5.02:1 on White, 4.73:1 on Cream** — both now pass. This darkening also *increases* the Circle's own visibility as a progress arc against light backgrounds (3.64→5.02, 3.43→4.73) — a pure improvement, not a trade-off. It does mean black text painted onto a *filled* primary button now measures 4.18:1 instead of 5.78:1 (darker background = less room above black), which drops it under 4.5:1 — so the companion fix is switching `onPrimary` from black to **white** in light mode (`app_theme.dart`), which measures **5.02:1** on the new fill. This is a theme-configuration change (which on-color pairs with which fill), not a component redesign.
- **Dark mode:** lightened `#7C8B6D` → `#869676` (~8% lighter), so it clears 4.5:1 as text against the dark surface specifically (the tightest case: 4.32:1 at the reference value, 4.97:1 after the adjustment) while keeping `onPrimary` = black at 6.64:1.

**This is the one place this task made a color adjustment beyond the given palette**, and it is exactly the case the brief anticipated: *"Only recommend changes if accessibility objectively requires them."* The brand color `#7C8B6D` is unaffected and remains documented in §2.1 for non-interactive, non-text brand use — only the `primary` implementation token's rendered value changed.

### 4.3 Buttons and interactive controls

| State | Pair | Ratio | Result |
|---|---|---|---|
| Primary button, light | white text on primary fill `#67735A` | 5.02:1 | Pass |
| Primary button, dark | black text on primary fill `#869676` | 6.64:1 | Pass |
| Secondary (outline) button, light | primary text/border `#67735A` on White | 5.02:1 | Pass |
| Secondary (outline) button, light | primary text/border on Cream | 4.73:1 | Pass |
| Secondary (outline) button, dark | primary text/border `#869676` on dark surface | 4.97:1 | Pass |
| Secondary (outline) button, dark | primary text/border on dark background | 5.76:1 | Pass |
| Disabled button, light | textSecondary `#5F655D` on disabled fill `#E6E6E5` | 4.80:1 | Pass (not required, but achieved) |
| Disabled button, dark | dark textSecondary `#ADB4A7` on dark disabled fill `#53544F` | 3.59:1 | Passes 3:1; WCAG does not require disabled controls to meet 4.5:1 — flagged for transparency, not a failure |

### 4.4 Borders, cards, and the progress track — intentionally soft, unchanged in character

`border` (`#D8D8D6` light / `#6E6F6A` dark) is deliberately low-contrast against `surface`/`background` (~1.1–1.4:1 in light mode) — this mirrors the *original* palette's border (`#E1E6E5` against `#F8FAF9`/`#FFFFFF`), which was equally soft. Card separation in this codebase has always been carried primarily by `AppShadows`, not by border contrast — Playbook Ch.3 §7 explicitly wants cards to look "soft, layered," not hard-edged. This is a pre-existing design pattern, not a regression introduced here. It is worth a note for future work: because shadow-driven separation can be hard for some low-vision users to perceive, a future (separate, non-color) task could consider whether `ThirtyCard` needs an additional non-color affordance — out of scope for this task since it would touch shadow/component values, not color tokens.

The progress ring's track color (`colors.border.withValues(alpha: 0.6)` in `ThirtyProgressCircle`) inherits this same soft quality by design — it reads as "not yet filled," recessed behind the primary-colored arc, consistent with Playbook Ch.3 §3's requirement that the Circle's fill never read as competing with its own track.

### 4.5 Focus indicators

No custom focus-ring color is defined in the current token set (`AppColors` has no `focus` token) — focus visibility currently relies on Flutter/Material's default platform focus treatment, unchanged by this task. This is a pre-existing gap, not something introduced here; flagging it because the task asked focus indicators to be evaluated. Recommend a dedicated `focus` token in a future pass if/when a custom focus treatment is designed — that is a new token addition, out of scope for "evolve existing tokens."

### 4.6 Semantic colors (success / warning / error)

Left **unchanged** — not part of the new palette, and not currently consumed by any shipped screen or component (confirmed via search: they exist only in `AppColors`'s definition and the internal design-system showcase page). For transparency, their contrast as plain text on White is weak (success 2.16:1, warning 1.80:1, error 3.54:1) — this is inherited unchanged from the original Brand Book §13 table and was never part of this task's scope. Flagging it now so it's addressed *when* these tokens are first used for real text, not retrofitted after the fact.

### 4.7 Summary

Every color in the given palette (Circle Sage, Mist Sage, Warm Stone, Cream, White, Primary Text, Secondary Text) passes WCAG AA as specified in every role it's used in **except** Circle Sage's dual role as both fill and text inside `ThirtyButton`, which required the minimal, documented adjustment in §4.2. No other color in the official palette needed any change.

---

## 5. Token-by-token decision log

| Token | Decision | Reasoning |
|---|---|---|
| `primary` | **Map to the Circle Sage brand color** (`#7C8B6D`); the *implementation token* diverges minimally per mode for accessibility (§4.2 — see ["Brand Identity vs. Implementation Tokens"](#brand-identity-vs-implementation-tokens)) | Circle Sage replaces the turquoise primary as THIRTY's one accent, per the new emotional direction. The token's rendered value is not the brand definition — it is what the brand value currently has to render as inside `ThirtyButton`'s dual-role constraint. |
| `secondary` | **Map to new color** (Mist Sage, light; derived dark counterpart) | Mist Sage preserves the original design intent of "secondary" being a lighter tint of the same hue as primary (the old teal secondary `#8FD9CF` was already just a lightened teal, not a separate hue) — now expressed with an official, exact palette color instead of an approximation. |
| `background` | **Map to new color** (Cream) | Direct 1:1 replacement — Cream is the explicit new page background. |
| `surface` | **Map to new color** (White) | Direct 1:1 replacement — White is the explicit new card/surface fill. |
| `textPrimary` | **Map to new color** (Primary Text) | Direct 1:1 replacement. |
| `textSecondary` | **Map to new color** (Secondary Text) | Direct 1:1 replacement. |
| `border` | **Map to derived color** (Warm Stone tint) | Not one of the seven given colors — Warm Stone's role in the palette is structural, so `border` is a deliberate tint derivation rather than an invented, unrelated hex. Kept intentionally soft, matching the pre-existing pattern (§4.4). |
| `disabled` | **Map to derived color** (Warm Stone tint, lighter than `border`) | Same reasoning as `border`, tinted further toward the base surface so it reads as more receded than a border. |
| `success` / `warning` / `error` | **Remain unchanged** | Not part of the new palette; not currently used anywhere in shipped code. Changing them would be inventing colors nobody specified. Flagged in §4.6 for a future, separate pass. |

### Naming

No token was renamed. `primary`, `secondary`, `background`, `surface`, `textPrimary`, `textSecondary`, `border`, `disabled`, `success`, `warning`, `error` are already semantic (role-based), not technical (`gray2`, `blue500`) — the thing the task's example warns against was never present here. Introducing brand-specific names (`circleSage`, `mistSage`, `warmStone`) as the actual field names on `AppColors` was considered and rejected: it would rename every call site (`colors.primary` → `colors.circleSage`) across `ThirtyButton`, `ThirtyCard`, `ThirtyProgressCircle`, `AppTheme`, and the showcase page — a mechanical but real breaking change with no functional benefit, since the *role* (`primary` = "the one accent") is what every call site actually depends on, not which specific hue currently fills that role. Brand names are used throughout this document's prose and section headers instead, so the "why" is fully documented without coupling code to a specific color's marketing name — consistent with the task's own instruction to *"avoid unnecessary breaking changes; only rename when it materially improves long-term clarity."* If Circle Sage is ever replaced by a future palette, `colors.primary` will not need to change again.

---

## 6. Playbook alignment

**Circle Manifesto (Ch.1).** §6, *Calm over Motivation*, and §10, *The Emotional Principles* ("Calm... Quiet confidence... through restraint, not through reassurance copy"), are why turquoise had to go: a bright, saturated technical color asks to be noticed the way THIRTY's philosophy explicitly refuses to. Circle Sage and Cream recede; they let the Circle itself — the shape, not the color — carry the meaning, as §3 requires: *"The Circle is not the app icon... it is the thing THIRTY is."*

This is also why this document keeps **brand identity** and **implementation tokens** visibly separate (see above). The Circle is the product, and Circle Sage is its color — an emotional, brand-level fact that does not change because one Flutter widget currently needs a slightly different rendered value to stay legible. Identity lives in the brand layer; accessibility lives in the implementation layer. Confusing the two would mean a future contributor could mistake a rendering workaround for a brand decision, or worse, treat a real brand decision as something a token diff can casually revert.

**Circle Experience System (Ch.2) §4, Motion Principles**, and by extension the same restraint applied to color: *"Restraint scales with importance."* The narrowest possible palette (one accent, two neutrals, two text tones) is the color equivalent of that rule — nothing is added that doesn't need to be there.

**Circle Design Language (Ch.3) §6, Color Philosophy**, is the section this task most directly implements: *"Meaning... Calm... Contrast exists to direct attention on purpose... Premium restraint... Accessibility is not a constraint layered on top of this philosophy — it is this philosophy applied honestly."* Every decision in §5 above and every check in §4 is a direct answer to that paragraph. §3, *The Circle*, calling for the Circle to eventually get "its own named color role, not a borrowed one," is *not* done by this task (that would be a component/architecture change) — but naming Circle Sage as the deliberate, sole, documented accent is the token-level groundwork that change would build on.

**Product Decision Framework (Ch.4).** The Calm Filter (§4): *"When unsure, choose the version with less in it"* — reflected in keeping the token *names* unchanged (§5) rather than adding brand-specific names that would ripple through every call site for no functional gain. The Longevity Filter (§9): *"Would this still make sense in ten years?"* — a natural, muted sage-and-stone palette is a longevity bet in exactly the way a trend-driven color (last year's gradient, this year's neon accent) would not be.

---

## 7. Future UI inheritance

Every color used anywhere in the shipped app is read from `Theme.of(context).extension<AppColors>()!` — confirmed by search: no screen, widget, or feature file references a literal `Color(0x...)` outside `lib/core/theme/`. This means:

- Any screen built today or in the future that uses `ThirtyButton`, `ThirtyCard`, `ThirtyProgressCircle`, or `Theme.of(context)` directly automatically renders in the new palette — including the still-unbuilt Home v2 — with no further code changes required.
- Light and dark mode both update together, since both are defined in the same `AppColors.light` / `AppColors.dark` pair consumed by the same `AppTheme._build`.
- No screen, layout, spacing, typography, radius, or shadow value was touched — this document and the token files behind it are strictly a recoloring.

---

## 8. Files changed by this task

| File | Change |
|---|---|
| `lib/core/theme/app_colors.dart` | `AppColors.light` and `AppColors.dark` hex values replaced per §2–§3. No fields added, removed, or renamed. |
| `lib/core/theme/app_theme.dart` | `_onAccent` (a single shared black constant) replaced with per-brightness `onPrimary` (white in light mode, black in dark mode) and `onSecondary` (= `textPrimary` of the active mode) — required by §4.2. No layout, component, or structural change. |
| `docs/DESIGN_SYSTEM.md` | Created (previously referenced but not written — see [playbook/README.md](playbook/README.md) §"Relationship with existing documentation"). |

No screen, widget layout, component structure, spacing, radius, shadow, or typography file was modified.

**Later clarification pass:** a follow-up documentation-only revision added the ["Brand Identity vs. Implementation Tokens"](#brand-identity-vs-implementation-tokens) section and reworded §2.1, §4.2, §5, and §6 to explicitly separate the stable Circle Sage brand color from the `primary` implementation token's accessibility-driven rendered value. That pass changed only this file — no Dart file, hex value, or WCAG conclusion was touched.
