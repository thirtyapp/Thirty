# THIRTY Visual Pass — Phase C Plan (screen passes)

**Status:** In progress.
- **Button large-text foundation** — commit `56e8601` (ThirtyButton: 48/56pt minimum height, up to two label lines, tighter side inset at ≥ 130% text)
- **Reminder invitation actions** — commit `a43de44` (side by side when both labels fit, stacked when they would truncate; `ThirtyButton.labelFits`)
- **C1 · You** — complete, commit `3c3aa02` (see below)
- **Pending / confirmed-only purchases** — commit `18b68fe` (`PurchaseOutcome.pending` / `confirming`; success only once the entitlement is active)
- **C2 · Premium offer page** — complete, commit `526083e` (see below)
- **C3 · Plans** — complete, commit `30f01c6` (see below)
- **Insights contract correction** — commit `14637c3` (aged-out evidence withdrawn to a dated, read-only earlier Insight; "Observed on {date}"; Dismiss stored in the existing snapshot blob)
- **Circle History calendar accessibility** — commit `8461bba` (48×48pt date targets; 7-column grid from 336pt with the calendar's own inset narrowing to 12pt, a recorded-date list below that; numbers at the user's text size; spoken localized dates)
- **C4 · Insights** — complete, commit `184bdd7` (see below)
- **C5a · Dialog accessibility** — commit `7583d15` (see C5 below)
- **C5b · SnackBar polish** — commit `279016d`
- **C5c · AppBar scrolled edge** — complete, in the commit that records this entry

**Foundation:** Phase A and Phase B are complete and ratified (`PHASE_A_PLAN.md`, `PHASE_B_PLAN.md`).

## C1 · You

**Preserved:** data/privacy semantics; no THIRTY account; RevenueCat is the billing authority; restoring Premium entitlement never restores local history; no new backend or cloud state.

**Founder decisions (copy and structure):**
- Premium card title **THIRTY Premium**, value line **Plans, Coach and Insights**, free CTA **Become Premium**.
- Price: the live localized store / RevenueCat price only (`monthlyOfferProvider`), never a hardcoded value. The working launch price is verified against the store product, never displayed in its place.
- Group title **Preferences**. Restore explanation: **Restores Premium access only. Your Circle history stays on this device.**
- Your data: Copy as text, then Delete all as the final row in `errorText`. Circle history's own data-controls layout is not restyled (shared actions, separate presentation).

**Layout:** Premium card → billing footer (Restore purchases + explanation) → Preferences (one grouped card: reminder, appearance, analytics) → Your data (grouped card, Delete all last). Grouped rows share the Premium card's 24pt content inset, closing the 8pt mismatch recorded in A2.

**Billing-state matrix:**

| Status | Premium card | Price | Main action | Restore footer |
|---|---|---|---|---|
| `initializing` | "Checking your Premium status…" | — | none | hidden |
| `inactive` | value line | live `localizedPrice / month`; nothing while loading; "Pricing isn't available right now." with no offer | Become Premium → `/premium` | shown |
| `active` | "Premium is active" | — (offer never fetched) | Manage subscription (URL fetched once) or Play Store guidance | shown |
| `unavailable` | "temporarily unavailable" + reassurance | — | none | shown |

**Fixes folded in:** restore goes through `EntitlementNotifier.restore()` (the card updates at once); the manage URL is fetched once per mount, not on every rebuild; the offer page reads the same shared `monthlyOfferProvider`.

**Accessibility:** theme choice is a `SegmentedButton` only when every label fits its segment on one line, otherwise three single-choice rows (selection shown by a check, not colour alone). Measured: inside the Preferences card the segmented control splits "System" at every phone width from 360 to 412pt, so phones get the rows; wide screens keep the segments. Real-font 200% matrix at 320 / 360pt, light / dark, every billing state: nothing truncated, nothing overflows.

**Non-blocking polish note:** the Restore purchases link keeps its 48pt tap target, which leaves a visible gap above its explanation line. Revisit only as visual polish; the tap target is not to be reduced.

**Reminder invitation actions (`a43de44`) stay as committed:** side by side whenever both labels fit without truncation, which at normal text on 320 / 360pt means a two-line "Choose a time".

**Deferred:** Premium offer page redesign; AppBar scrolled-under separation; rounded / floating SnackBar; support contact and privacy link (no authoritative source); Coach banner's "Try lighter guidance today" at 320pt / 200% (Plans pass).

## C2 · Premium offer page

**Preserved:** one monthly auto-renewing subscription; live localized store / RevenueCat price only; Plans + Coach + Insights as the actual V1 value; Free stays complete; no trial / annual / offer matrix; no account; restore entitlement ≠ restore local history; RevenueCat as billing authority.

**Hierarchy (approved copy):** heading **Plans, Coach and Insights** → value card (**Circle Plans**: three guided Plans that remember your place · **Circle Coach**: contextual pacing and gentle resumption · **Circle Insights**: what your own choices tell you) → **{price} / month** → **Billed monthly. Renews automatically until you cancel.** → **Become Premium** (56pt hero, full width) → **Not now** (goes back) → **Free stays complete.** → shared restore footer (same component as You) → **You can cancel anytime in Google Play. Premium stays active until the end of your current billing period.**

**States:**

| Entitlement | Offer | Shows | Action |
|---|---|---|---|
| checking | — | "Checking your Premium status…" | none; no restore |
| unavailable | — | truthful status + reassurance | none (AppBar back); restore shown |
| inactive | loading | "Checking the current price…" | Become Premium disabled; Not now |
| inactive | none | "Pricing isn't available right now." | no CTA; Not now |
| inactive | available | price + disclosure | Become Premium; Not now |
| purchasing | — | same | CTA loading; Not now and Restore disabled |
| purchased (confirmed active) | — | active block + "You now have Premium." | Manage, Done |
| confirming | — | "Your purchase is being confirmed. Premium unlocks as soon as Google Play confirms it." | — |
| pending | — | "Your payment is pending with Google Play. Premium unlocks when it completes." | unlocks later via the status stream |
| active | — | "Premium is active" | Manage subscription, Done; no price, no CTA |

**Shared with You:** `PremiumRestoreFooter` and `ManageSubscription` now live in `premium/presentation/widgets/` (You unchanged visually). Each value point is its own semantics node; the check mark is decorative.

**Accessibility:** real-font 200% matrix at 320 / 360pt, light / dark, every state (incl. a long `US$ 4.99` price): nothing truncated or overflowing; CTA ≥ 56pt.

**Deferred (not in C2):** trials, annual pricing, urgency, testimonials, sticky CTA, comparison tables; paywall analytics; iOS / App Store wording.

## C3 · Plans

**Preserved:** one active Plan; three saved positions; five stages; matching-direction session behaviour; other directions stay Free; same-day assignment frozen; closing advances guidance once without proving completion; Premium expiry keeps user state; no streak or guilt framing. No Plan, entitlement, cursor, revisit, cycle or recommendation logic changed.

**Changes:**
- **Free:** the pinned "Open Premium" bar (which sliced the card behind it at 200%) is replaced by an in-list card *after* the three previews: **THIRTY Premium** / **Guided Plans are part of THIRTY Premium.** / **Become Premium** (full width).
- **Premium cards:** one full-width main action per card (Activate / Resume / Repeat this cycle); Activate / Resume is **secondary** on other Plans while one is active. Management (Queue a revisit of the last stage / Clear queued revisit / Pause this plan) is a quiet `ThirtyTextAction` — full copy kept, never truncated.
- **Active marker:** a small tinted tag (`selection`), still announced as "Active plan".
- **Coach:** shortcuts are quiet `ThirtyTextAction`s (full copy); on Plans the sentence is left-aligned and the revisit shortcut is suppressed where the card already offers the same revisit; Home keeps its centred presentation, both shortcuts and unchanged semantics / state (regression-covered at 200%). The Home shortcuts' change from outlined buttons to centred text actions is accepted as a calmer secondary-action treatment.
- **Rhythm:** 16pt between Plan cards.
- **New shared component:** `lib/core/widgets/thirty_text_action.dart` (48pt target, wraps freely, primary colour). C1/C2's Restore / Not now / Done are not migrated in C3.

**Accessibility:** real-font 200% matrix at 320 / 360pt, light / dark, for Free, Free with a saved position, none active, active, revisit queued, completed, Coach with both shortcuts, and Home's Coach banner — nothing truncated or overflowing, the Free upsell reachable by scroll. Against pre-C3 code the same matrix fails (pinned bar, truncated revisit / Coach labels).

**Deferred:** ordering the active Plan first; Insights' "Open Premium to apply this"; a Plan detail / stage list; Home Plan session panel beyond the shared Coach text actions; AppBar scrolled-under separation.

## C4 · Insights

**Preserved:** the Insight engine, thresholds, weekly reassessment cadence, dismissal semantics, stale-evidence rules and Plan / Coach application logic (`14637c3`), and the calendar's behaviour (`8461bba`). The only application-layer change: `InsightNotifier.applyCurrent()` returns whether the existing bounded application actually happened, so the page can confirm it truthfully.

**Hierarchy:** **Your history** + calendar first; then a second section under its own **Insights** heading (32pt section spacing, no divider), showing exactly one of the states below. Headings are semantic headers on the page's 24pt left edge.

| State | Shows |
|---|---|
| Premium · current Insight | observation (primary body colour) → muted evidence ("Based on … between {date} and {date}.") and "Observed on {date}" → the one application as the full-width primary `ThirtyButton`, naming its change → quiet **Dismiss** |
| Just applied | **Applied. Your Plan is updated.** (card, live region) instead of the empty state, until a new Insight appears; page state only, never persisted |
| Free · retained current Insight | same readable observation / evidence / date (never a locked look) → quiet **Become Premium to apply this** (`/premium`) → **Dismiss**; no Premium card beneath |
| Earlier (aged-out) Insight | "An earlier Insight from {date}", no "recent", no application, no Premium CTA — Free and Premium alike |
| Premium · no Insight | **Nothing to show yet. Pattern Insights need at least 5 relevant Circle records across 3 different days, spanning at least 14 days.** (numbers from the engine constants); no sales CTA |
| Free · no Insight | compact left-aligned card: **THIRTY Premium** / **Premium can turn patterns in your recorded Circles into one clear next step for your Plan.** / full-width **Become Premium** |

**Other changes:** the card's "Insight" eyebrow is dropped (the section heading names it); visible dates are localized short dates (evidence previously showed raw `YYYY-MM-DD` keys), kept on one line with non-breaking spaces while the spoken form keeps ordinary spaces.

**ThirtyButton:** new optional `maxLabelLines` (default **2**, unchanged everywhere). Only the Insight application passes `null`, because no wording of the longer applications fits two lines at 200% ("Use lighter guidance as this Plan's default" needs 4 at 320pt). Labels rendering in 1–2 lines keep the pill; once a label actually renders in 3+ lines the button uses the card's 24pt radius (`AppRadius.xl`) instead of an oval. Buttons with the 2-line limit are laid out exactly as before; a trailing-icon button keeps the 2-line limit (asserted).

**Accessibility:** real-font matrix at 320 / 360pt × 200%, light / dark: Free / no Insight, Free / retained Insight (every family), Premium / no Insight, Premium / current Insight (every family, incl. the plain current-place fact), just applied, dismissed, earlier aged-out (Free and Premium) — nothing truncated or overflowing, Premium application full width, one sales surface at most, Dismiss ≥ 48pt, observation readable Free. Component tests cover the pill / 24pt switch, the unchanged default, semantics and loading size. Against the pre-C4 presentation 52 of the 60 matrix cases fail.

**Kept as is:** the 48pt targets (and resulting gap) between "Become Premium to apply this" and "Dismiss".

## C5 · Shared polish

**Scope:** only shared presentation deferred from C1–C4. No screen composition, copy, product logic or billing behaviour changed.

**C5a — confirmation dialogs (`ThirtyConfirmDialog`, `lib/core/widgets/`).** The audit found the only blocking defect: at 320pt / 200% text the dialog bodies were silently clipped with no scroll (the Delete-history warning showed "This permanently", 92 of 462pt; Alarms & reminders 176 of 378pt), and labels broke mid-word ("permanentl / y", "reminder / s"). The shared dialog is still an `AlertDialog`: `scrollable: true` (title and body scroll, actions stay below); at text scale ≥ 130% the side inset narrows from 40 to 16pt and stacked actions get 8pt between them; destructive confirm uses `errorText`; cancel → `false`, confirm → `true`, barrier / back → `null`. At ordinary text the geometry is identical to before (tested against the pre-C5 dialog), which is why the 8pt stacked spacing applies only at large text — the Delete dialog already stacks its actions at 360pt / 100%. Migrated: Delete history (`journal_data_controls.dart`), Close Circle (`circle_hero.dart`, dialog builder only), Alarms & reminders (`you_preferences_card.dart`).

**C5b — SnackBars (theme only).** Floating, `AppRadius.xl`, 16pt side / 8pt bottom margins (aligned with the floating nav and 8pt above it; 8pt above the screen edge where there is no nav, e.g. Circle history), elevation 0, inverseSurface colours kept. Copy, 4s duration, action behaviour and live region unchanged. The only call site is "Copy as text".

**C5c — AppBar scrolled edge (`ThirtyAppBar`, `lib/core/widgets/`).** A 1pt bottom edge in `divider` while the page's own vertical scroll view (depth 0) is scrolled away from its top; none at the top; no elevation, tint or background change; horizontal and nested scrolling never trigger it; the AppBar's height never changes. Used on You (Settings), Plans, Insights, Premium offer, Circle history and Circle record detail.

**Decisions recorded:**
- **Restore explanation spacing accepted as is.** Measured on You: the "Restore purchases" label sits 19pt below the Premium card and 15pt above its explanation, so it still reads as one pair; the 48pt target stays (same decision as C4's Become Premium / Dismiss).
- **Home's AppBar is intentionally excluded** from `ThirtyAppBar`: its fading wordmark header is accepted Home composition.
- **Circle history's raw `YYYY-MM-DD` record dates remain deferred** (Insights' dates were localized in C4; Circle history is screen-specific, not shared polish).

**Accessibility:** real-font tests — dialogs at 320 / 360pt × 200% × light / dark for all three (laid out in full, body end reachable, no mid-word breaks, actions ≥ 48pt and on screen, 8pt stacked spacing, 16pt inset); SnackBar in the real app at 320 / 360pt × 200% × light / dark on You (with the nav) and Circle history (no nav): position, no overlap, no truncation.

**Still deferred:** dialog title size (`headlineSmall`, fine at 100%); the time picker at 200% (Material's own layout, themed in A5); support contact and privacy link (no authoritative source).
