# THIRTY Visual Pass — Phase C Plan (screen passes)

**Status:** In progress.
- **Button large-text foundation** — commit `56e8601` (ThirtyButton: 48/56pt minimum height, up to two label lines, tighter side inset at ≥ 130% text)
- **Reminder invitation actions** — commit `a43de44` (side by side when both labels fit, stacked when they would truncate; `ThirtyButton.labelFits`)
- **C1 · You** — complete, commit `3c3aa02` (see below)
- **Pending / confirmed-only purchases** — commit `18b68fe` (`PurchaseOutcome.pending` / `confirming`; success only once the entitlement is active)
- **C2 · Premium offer page** — complete (see below; commit recorded in the next plan update)

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

