# THIRTY Visual Pass — Phase B Plan (Home composition)

**Status:** **Complete and ratified** (founder decisions B-D1–B-D4 below).
- **B1 complete** — commit `d15a9e1`
- **B2 complete** — commit `695f7fb` (see the B2 scope refinement below)
- **B3 complete** — commit `8d260a8` (see "B3 as implemented" below)
- **Invitation contract fix** — commit `a8a9ca5` (session-stable invitations; persisted "shown" only once meaningfully visible)
- **Reminder session-close fix** — commit `08bf3be` (enabling reminders closes the reminder invitation for the rest of the session)
- **Phase B complete and ratified.** Non-blocking follow-ups in §6.

**Baseline:** `step5-billing-integration` after Phase A (A5 `6ea5fe3`, plan `09f2b0e`).
**Foundation:** Phase A tokens and components (`docs/design/PHASE_A_PLAN.md`) are the ratified foundation.
**North-star:** the founder's Home mockup, used as *visual language only* — not an IA contract. Today | Plans | Insights | You stays; the mockup's 5-tab nav, profile bubble and "Later today" list are out of scope.

## 1. Frozen: Golden Home lifecycle

Phase B changes composition only. Unchanged, and protected by tests:
- Ready (no recommendation) → `Begin today's Circle` is **presentation-only** (no persistence).
- The Circle is the stable visual anchor: same rect across Ready → direction choice → assigned/active/closed.
- Compact direction choice appears below the same Circle; choosing a direction assigns the activity.
- The First Breath is canonical: timeline, wordmark beat, Circle release, reveal order and CTA gate unchanged.
- `Start Circle` is the actual lifecycle transition; active → `Close Circle` (confirmed); closed → "Done for today".
- Same-day restore unchanged.

No navigation, billing, Plans, Insights or You changes.

## 2. Founder decisions

| # | Decision |
|---|---|
| **B-D1** | **Crafted Circle work (uncommitted in the `main` checkout) is parked.** Not merged or folded into Phase B; Phase B builds on the tested `step5-billing-integration` implementation. Audit/reconcile separately once Home composition is stable. |
| **B-D2** | **Header wordmark never duplicates the in-Circle wordmark.** Hidden in Ready and throughout The First Breath; revealed only once the ritual has settled into the assigned Home state. First Breath timing and its in-Circle wordmark sequence are unchanged. |
| **B-D3** | **Ring roles:** keep the device-approved transparent track in steady not-started; add only the halo. Re-check the started-state 22% ring alpha in light/dark once the new hero composition exists; change it only if it is still too faint in context. |
| **B-D4** | **Trailing arrow on `Start Circle` only.** `Begin today's Circle` gets none. |

## 3. Steps

### B1 · Foundations shared by every Home state
- **`HomeCircleMetrics`** (`home_circle_metrics.dart`): one source for Circle size, stroke, text-column/CTA widths and outer padding, replacing the verbatim copies in `circle_ready_prompt.dart` and `circle_hero.dart`. Values unchanged (272 / 312 / 362.56pt at 320 / 360 / 412pt width).
- **Halo** (`HomeCircleHalo`, `AppShadows.haloLight` / `.haloDark`): a `surface` disc exactly the Circle's size with a wide soft shadow, identical in Ready and Circle Hero. Static — outside First Breath's `AnimatedBuilder`. Track colors untouched.
- **`ThirtyButtonSize.hero` (56pt)**, opt-in; applied only to Home's lifecycle CTA (Begin / Start / Close). Every other button stays 48pt; direction choices stay 48pt.
- **Header wordmark** (B-D2): `ThirtyWordmarkView` (96pt) replaces the AppBar's Inter "THIRTY" text; always laid out, faded in (400ms, instant under reduced motion) when `firstBreathProvider` turns false with a recommendation present. AppBar height and Circle position never change.
- Not in B1: trailing arrow, CTA width, `heroGap`/`xxxl` (no unused API or tokens — they arrive with their B2 consumers).

### B2 · Hero hierarchy and state-specific composition
- Text-column rhythm (eyebrow / serif intent / activity / why) with `heroGap`.
- CTA: `trailingIcon` on `ThirtyButton`; arrow on Start Circle only (B-D4); CTA width decision (text-column width vs current 70%).
- Closed "Done for today" rhythm.
- Started-ring 22% alpha re-check in context (B-D3).
- New elements join existing First Breath phases only; no new controllers; total timeline unchanged.

**B2 scope refinement (founder-frozen, implemented).**
- **CTA width:** Begin / Start / Close fill the bounded content column (`textMaxWidth`, 85% of the Circle), never the screen; 56pt. `minWidth`, so a label that genuinely needs more room at large text grows instead of overflowing. The 70% `buttonWidth` metric is removed.
- **Arrow:** `ThirtyButton.trailingIcon` (decorative; the label alone carries semantics). `Icons.arrow_forward_rounded` on Start Circle only; Begin and Close stay text-only. Start stays inside the reveal-gated `IgnorePointer`.
- **Arrow placement (review correction):** the arrow is pinned to the button's trailing edge, with an equal empty slot (icon + gap, 28pt) reserved on the leading edge, so the label stays optically centered on the button and the Circle axis. Both slots are laid out, not overlaid: at 200% text the label ellipsizes inside its own space and never collides with the arrow. `IntrinsicWidth` keeps the trailing-icon button's sizing identical to every other button (content width, or the column width the Home CTA asks for).
- **Text rhythm** (Home-local constants on `HomeCircleMetrics`, existing spacing tokens): Circle → content 32 (was 24 in Circle Hero; now equal to Ready's 32), eyebrow → hero line 8 (unchanged), hero line → activity 16 (was 4), activity → support 8 (unchanged), support → CTA 32 (unchanged). No global `heroGap`/`xxxl` token was needed.
- **Circle** size/position unchanged; First Breath timeline unchanged (6500ms, pinned by test).
- **Started-ring re-check (B-D3):** in context the 22% ring reads as a soft sage-grey band on the light halo disc and a quiet sage band in dark; the Close Circle CTA carries the state. Not a readability problem — alpha unchanged.

### B3 · Below-hero composition and hardening
- `HomePage` becomes the single, **non-lazy** scroll owner (hero + reflection + Plan panel + invitations), so a card never shrinks the hero. Non-lazy is required: both invitation cards persist their "shown" flag from a post-frame callback during build.
- QA matrix: 320×568 / 360×640 / 412×915 × 100% / 200% text × light / dark × every Home state.

**B3 as implemented (approved).**
- **Scroll architecture:** one vertical scroll owner per state. `CircleHero`'s existing `SingleChildScrollView` now holds `Column[hero, ...footer]`; `HomePage` passes `ActionReportPrompt`, `PlanSessionPanel`, `ReminderInvitationCard`, `PremiumOfferInvitationCard` as that `footer` (same order, same widgets). Ready (no below-hero cards) keeps `CircleReadyPrompt`'s own scroll. The Ready → Circle Hero swap mounts a fresh scroll view, so First Breath always starts with the Circle at its normal position. No nested scrollables; still non-lazy, so the invitation "shown" flags are written on first build exactly as before.
- **Not changed:** copy, lifecycle, recommendation logic, persistence, First Breath, Circle geometry, CTA styling, ring colours, card widgets and their gating. Existing test harnesses unchanged (`CircleHero()` without a footer is the pre-B3 widget).
- **Fixed by B3:** before, the cards were laid out beneath an `Expanded` hero outside its scroll, so a card took height from the hero and, at 320×568 / 200% text with the reminder invitation, the page overflowed.
- **Found, pre-existing, not changed:** (1) on device the reminder invitation writes its "shown" flag on first build and can then disappear within the same session when its eligibility provider recomputes at startup — reproduced identically on the pre-B3 build — **fixed by the separate invitation-semantics correction committed after B3** (session slot `home_invitation_slot.dart`; persisted "shown" only once meaningfully visible via `ViewportVisibility`; eligibility watches only reminder `enabled`); (2) the Premium invitation's fixed "Learn more" label only overflows under flutter_test's square-glyph font, not with real Inter (verified with real fonts loaded).
- **Accessibility check of record:** the real-font 200% matrix (`test/features/home/home_page_b3_real_font_test.dart`, Inter + Newsreader loaded) is the authoritative 200% check for the Premium invitation; the default-font group in `home_page_b3_test.dart` deliberately omits that one case.
- **Home composition review item — reflection below the fold:** before B3 the reflection question ("Did you try this activity?") was pinned at the bottom of the viewport; on a Pixel 7 it now peeks below the fold behind the floating nav and its answers need a scroll. Correct per B3's single-scroll rule, but it may lower reflection response. Resolve as a composition decision (spacing / placement), not a layout bug.
- **Deferred to Phase C — AppBar hard edge:** with scrolling now common on Home, content visibly cuts off against the page-coloured AppBar (e.g. the illustration). Part of the existing Phase C "AppBar scrolled-under separation" item.

## 4. Deferred

- **Phase C:** greeting copy ("Good morning"), tagline, "Later today"-style list, activity icons, rounded/floating SnackBar, AppBar scrolled-under separation, You/Plans 200% text issues.
- **Rejected:** a counting progress arc/knob on Home — "the Circle breathes; it does not count."

## 5. Tests protecting the lifecycle

Existing (must stay green, assertions not weakened): `home_page_test` (incl. Ready → Circle Hero rect parity), `circle_ready_prompt_test`, `circle_hero_test`, `recommendation_provider_test`, `first_breath_provider_test`, `action_report_prompt_test`, `premium_offer_invitation_card_test`.

Added in B2 (`home_page_b2_test`, `thirty_button_test`): Circle rect identical across Ready → Directions → assigned on one tap-driven `HomePage`; hero CTAs 56pt and exactly the content-column width (360 / 412pt); only the hero CTA is 56pt; Start alone has the arrow (decorative for semantics); Start label centered on the button and Circle axis with the arrow in the trailing slot; no label/arrow overlap at 320pt and 360pt at 200% text; Start inside the reveal-gated `IgnorePointer` and still the real Start transition; First Breath total 6500ms; text-rhythm gaps; no overflow at 320×568 and 360×640 at 200% text for Ready (+ Directions), assigned, started and closed.

Added in B1 (`home_page_b1_test`, `thirty_button_test`): metrics values; halo rect = Circle rect in Ready and Circle Hero, light and dark; steady not-started track still transparent; 56pt only on the Home lifecycle CTA, direction choices 48pt, no icon on Begin; 56pt CTA still gated by the First Breath reveal; header hidden in Ready (incl. after Begin), hidden throughout First Breath, shown once settled / at once when already played / instantly under reduced motion; revealing the header never moves the Circle.

## 6. Phase B closure — non-blocking follow-ups

| Item | Disposition |
|---|---|
| **Reflection below the fold** (B3: the reflection question now peeks below the fold on a Pixel 7 and its answers need a scroll) | **Accepted for now.** Revisit only during later Home polish if real use shows its discoverability is too low. |
| **AppBar scrolled-under hard edge** (content cuts off against the page-coloured AppBar while scrolling) | **Phase C**, as part of the existing AppBar scrolled-under separation item. |
| **Started-state ring alpha 22%** (B-D3) | **Reviewed and retained** — re-checked in the completed B2 composition, light and dark. |
| **Crafted Circle work** (uncommitted in the `main` checkout) | **Remains parked** (B-D1). Requires a separate reconciliation audit against the Phase A/B Home implementation before any future Circle-geometry merge. |
