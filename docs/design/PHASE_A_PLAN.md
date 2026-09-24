# THIRTY Visual Pass — Phase A Plan (Foundations)

**Status:** Approved (founder decisions D1–D4 recorded below). A1 approved and committed. A2 implemented, awaiting founder review. Next: record-detail accessibility fix, then A3.
**Baseline:** `step5-billing-integration` @ `372dd30` (1.7.0+14).
**Parent document:** THIRTY Visual Gap Analysis, §6 Phase A.
**Scope:** design tokens, shared core widgets, and app-wide component themes only. No screen recomposition, no IA or Circle-lifecycle change — Home composition is Phase B.

Hierarchy note: the Playbook governs *why*, `lib/core/theme/` governs *what a value is* (see `docs/DESIGN_SYSTEM.md`). This plan changes token values deliberately and step by step; every step updates the relevant documentation alongside the code.

---

## 1. Audit findings (why Phase A is needed)

1. **Half the type scale is undesigned.** `AppTypography` defined 6 `TextTheme` slots; screens use 11. `bodySmall` (22 call sites), `titleSmall` (6), `titleLarge` (1 + every AppBar title), `labelSmall` (1) fell through to Material 3 defaults. One hand-set `fontSize: 13` existed in `circle_hero.dart`.
2. **Material letter-spacing leaks into every style.** Defined slots left `letterSpacing` null, so Material 3's geometry (e.g. `bodyLarge` +0.5, `bodySmall` +0.4) was merged in underneath — the loose, "default Flutter" tracking visible across the app.
3. **No component themes.** `app_theme.dart` sets only ColorScheme + TextTheme: AppBars render white (`surface`) over the cream `background`; `ColorScheme.fromSeed` tonal roles (`surfaceContainer*`, `secondaryContainer`) leak into NavigationBar, Switch, SegmentedButton and dialogs.
4. **Surface language is small and hard-edged** relative to the vision: card radius 12 + 1px border, card padding 16, button radius 8 / height 48 / leading icon only, stock full-width NavigationBar.
5. **The Circle has no color role of its own** (Playbook Ch.3 §3): its ring borrows `primary` and `border @ 0.6`.

## 2. Founder decisions

| # | Decision |
|---|---|
| **D1** | **One serif/editorial-display moment per screen, hero only.** Inter remains the functional typeface. `BRAND_BOOK.md` §14 is updated narrowly to document the existing Newsreader editorial-display exception — serif usage is not broadened. |
| **D2** | **Fully rounded pill buttons.** |
| **D3** | **No warm/gold accent token in Phase A.** The restrained sage/stone palette stays. |
| **D4** | **A5 is the bounded light/dark QA that ratifies the current dark palette.** `AppColors.dark` is not called final until that review passes. |

### Guardrail — semantic token changes

Before changing any semantic spacing or radius token globally, **inventory every call site.** If a change (e.g. `AppSpacing.card` 16 → 24) would unintentionally enlarge compact surfaces, introduce a **separate semantic token** for the new role instead of forcing every consumer to change.

## 3. Steps

Each step is small, independently reviewable, and gated on `flutter analyze` + full `flutter test`, with before/after renders of the showcase and the four destinations (light and dark) before the next step starts.

### A1 · Typography — `app_typography.dart`, `circle_hero.dart` (eyebrow only), `BRAND_BOOK.md` §14
- Define every slot screens actually use (`titleLarge`, `titleSmall`, `bodySmall`, `labelSmall`), keeping the six existing slots' size/weight/height.
- Set an explicit `letterSpacing` on every defined slot so Material geometry no longer leaks in.
- Give undefined fallback slots THIRTY's text colors (`TextTheme.apply(bodyColor/displayColor)`) instead of the default seed scheme's.
- `labelSmall` becomes the quiet **eyebrow** role; `circle_hero.dart`'s hand-set eyebrow migrates to it.
- `editorialDisplay` value unchanged. Its hero-size tuning moves to **B1** (Circle hero composition), where the actual hero layout is decided.
- A dedicated **numeric** style (Playbook Ch.3 §4) is deferred until a screen places a number that needs it (Phase B) — no unused API in A1.
- Brand Book §14: narrow documentation of the Newsreader exception (D1).

**Scope refinement (deliberate, approved with A1).** The original draft of this plan had A1 also *retune* the existing six-slot scale (e.g. a larger screen-title and hero size). A1 instead made the more conservative change: define the missing Material roles and remove Material's letter-spacing and color leakage, leaving the six existing slots' size, weight and line height unchanged. This is intentional, not an omission: size changes to titles and the hero can only be judged in real composition, so larger editorial/hero typography moves to **Phase B** (B1 Circle hero composition). A1 is approved as implemented.

### A2 · Spacing — `app_spacing.dart`
- Inventory all `AppSpacing.card` / `AppSpacing.section` call sites first (guardrail).
- Add `xxxl = 64` and a `heroGap` role. Roomier card padding / section rhythm is introduced as **new semantic tokens** where compact surfaces would otherwise grow unintentionally.

**Scope refinement (deliberate, approved after the A2 inventory).**
- The inventory found `AppSpacing.card` has a single consumer — `ThirtyCard`'s default padding — used by all 12 card call sites with no overrides. A global 16 → 24 would have enlarged compact surfaces: the two Home-stack invitation cards (which share fixed height with the Circle hero), the journal entry card, and You's three control-row cards.
- **`AppSpacing.card`, `.section` and `.page` keep their values.** `section`'s product consumers are Home hero composition (Phase B); `page` also sizes the Circle (`maxWidth - page * 2`).
- **One opt-in token added: `AppSpacing.featuredCard = l` (24)**, named as a sibling of the existing role-noun `card` token. Applied only to the five audited featured/standalone cards: Plan card, free-preview Plan card, Premium offer card, Insight card, Premium card in You. Home-stack cards, control rows, journal cards and showcase cards are unchanged.
- **`xxxl` and `heroGap` are deferred to Phase B**, where the hero composition consumes them — no unused tokens.
- You's group rhythm (currently `m` between groups) is a Phase C You-pass concern. Known consequence to resolve there: the featured Premium card's content now sits 8pt further in than the compact control-row cards directly beneath it.
- The pre-existing record-detail overflow at 200% text (found by the inventory) is handled as a **separate bounded accessibility change after A2, before A3** — not inside A2.

### A3 · Surfaces — `app_radius.dart`, `app_shadows.dart`, `thirty_card.dart`, `thirty_button.dart`, `app_shell.dart`, `app_theme.dart`
- Inventory radius call sites first (guardrail). Add `xl = 24` (cards, nav container); button shape = pill (D2).
- Layered soft shadow tokens; a `halo` token for the Circle (consumed in Phase B).
- `ThirtyCard`: borderless in light (radius 24, soft shadow); hairline border retained in dark, where shadows don't read (`DESIGN_SYSTEM.md` §4.4).
- `ThirtyButton`: height 56, pill, optional `trailingIcon`; existing pressed/disabled accessibility logic unchanged.
- Component themes: `appBarTheme` (cream, no tint/elevation), `navigationBarTheme`, `switchTheme`, `segmentedButtonTheme`, `dividerTheme`; pin `surfaceContainer*` / `secondaryContainer` so seed tones stop leaking.
- Floating, rounded nav container in `AppShell` — same four destinations, same `goBranch` behavior.

### A4 · Light palette — `app_colors.dart`, `DESIGN_SYSTEM.md`
- New tokens: `surfaceMuted`, `divider`, `ringTrack`, `ringProgress` (Circle color role, wired as `ThirtyProgressCircle` defaults with no visual change at first).
- Tune `background` / `border` / `secondary` toward the vision within the existing sage/stone family (D3). Re-verify every AA pair in `DESIGN_SYSTEM.md` §4.

### A5 · Dark parity + ratification QA — `app_colors.dart`, `app_shadows.dart`, `DESIGN_SYSTEM.md` §3
- Mirror all new tokens; a raised-surface step so cards/nav separate by tone rather than invisible shadow.
- Bounded light/dark QA across showcase + all destinations; contrast pass. On pass, `DESIGN_SYSTEM.md` §3 moves from "proposal" to ratified (D4).

## 4. Out of scope for Phase A

Screen recomposition (Phase B/C), illustration (Phase D), IA, Circle lifecycle, reminder logic, premium gating, RevenueCat/Supabase architecture, any new color outside the sage/stone family.
