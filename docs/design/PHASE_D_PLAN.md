# THIRTY Visual Pass — Phase D Plan (Home visual pass)

**Status:** In progress.
- **D1a · Home header** — complete (see below)

**Foundation:** Phases A–C are complete and ratified (`PHASE_A_PLAN.md`, `PHASE_B_PLAN.md`, `PHASE_C_PLAN.md`).

## Source and founder decisions

The founder supplied `Design vision.png` (Home, today's Circle assigned) with the instruction "visually, I want it to look like that". This reopens the Home composition that Phase C listed as out of scope. Decisions (2026-09-26):

- **Illustration:** reuse the existing Quiet Trail artwork in the Circle and the Today card for now; new green / figure artwork may replace it later. No new illustration work in D1.
- **Copy:** use the mockup's copy — a time-of-day greeting ("Good morning / afternoon / evening"), "Ready to close today's Circle?" and the tagline "A brighter you in small steps" under the wordmark (recorded in `BRAND_BOOK.md` §21 as an in-app supporting line; the primary slogan is unchanged).
- **Feature-shaped elements:** style only, real content. The approved 4-tab IA stays (Today · Plans · Insights · You); no Explore / Progress / Reflection features, no locked-Insights row. The mockup's profile button is a shortcut to You, never an account.
- **Ring:** a real 30-minute timer. While today's Circle is started, the sage arc fills with the time since Start Circle, full at 30 minutes. **This deliberately overrides** the earlier rule "The active Circle breathes; it does not count" (Playbook / Motion Language, as applied in `circle_hero.dart`). Nothing fills before Start Circle.

## D1 scope (one commit each)

| # | Change | Where |
|---|---|---|
| D1a | Header: small wordmark + two-line tagline lockup top-left; round 48pt profile button top-right (opens You) | Home |
| D1b | Circle: visible soft track with a start dot; the started arc is the 30-minute timer; First Breath unchanged | Home |
| D1c | Greeting + subline; left-aligned Today card (TODAY eyebrow, serif direction, activity with icon, divider, reason, small illustration); full-width Start Circle | Home |
| D1d | LATER TODAY: the Premium invitation as a row; the answer-in-place follow-ups (report, Plan session, reminder) stay cards, restyled to match | Home |
| D1e | Bottom nav: no pill; selected tab = sage label + filled icon; Today uses a ring icon | All screens |

## D1a · Home header

- **Lockup** (`HomeBrandLockup`): the existing THIRTY wordmark SVG (96pt) with "A BRIGHTER YOU / IN SMALL STEPS" beneath it (9.5pt, 2.2 letter-spacing, `textSecondary`). A logotype, so it keeps one fixed size at every text scale (WCAG 1.4.4 logotype exception); that keeps the header a fixed 72pt. Announced as the header "THIRTY", then the tagline as plain text. It still fades in only once First Breath has settled, so it never duplicates the in-Circle wordmark.
- **Profile button** (`HomeProfileButton`): 48pt `surface` circle with the card shadow and a person icon; "Open You" button semantics; `go('/settings')`, so the You tab is selected exactly as from the nav. Visible in every Home state, including Ready.
- The whole Home composition moves down 16pt (56 → 72pt header) in every state, so the Circle still never jumps between states.
- **Tests:** `home_page_d1_test.dart` — semantics, gutter alignment, 48pt target in Ready, 320 / 360pt × 200% × light / dark fit, and the tap opening You in the real router.
