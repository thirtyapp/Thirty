# THIRTY Visual Pass — Phase B Plan (Home composition)

**Status:** Approved (founder decisions B-D1–B-D4 below).
- **B1 implemented** (uncommitted; pending review)
- B2, B3 not started

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

### B3 · Below-hero composition and hardening
- `HomePage` becomes the single, **non-lazy** scroll owner (hero + reflection + Plan panel + invitations), so a card never shrinks the hero. Non-lazy is required: both invitation cards persist their "shown" flag from a post-frame callback during build.
- QA matrix: 320×568 / 360×640 / 412×915 × 100% / 200% text × light / dark × every Home state.

## 4. Deferred

- **Phase C:** greeting copy ("Good morning"), tagline, "Later today"-style list, activity icons, rounded/floating SnackBar, AppBar scrolled-under separation, You/Plans 200% text issues.
- **Rejected:** a counting progress arc/knob on Home — "the Circle breathes; it does not count."

## 5. Tests protecting the lifecycle

Existing (must stay green, assertions not weakened): `home_page_test` (incl. Ready → Circle Hero rect parity), `circle_ready_prompt_test`, `circle_hero_test`, `recommendation_provider_test`, `first_breath_provider_test`, `action_report_prompt_test`, `premium_offer_invitation_card_test`.

Added in B1 (`home_page_b1_test`, `thirty_button_test`): metrics values; halo rect = Circle rect in Ready and Circle Hero, light and dark; steady not-started track still transparent; 56pt only on the Home lifecycle CTA, direction choices 48pt, no icon on Begin; 56pt CTA still gated by the First Breath reveal; header hidden in Ready (incl. after Begin), hidden throughout First Breath, shown once settled / at once when already played / instantly under reduced motion; revealing the header never moves the Circle.
