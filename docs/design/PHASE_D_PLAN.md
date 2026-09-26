# THIRTY Visual Pass — Phase D Plan (Home visual pass)

**Status:** In progress.
- **D1a · Home header** — complete, commit `dc81884` (see below)
- **D1b · Circle ring and timer** — complete, commit `7cac0cf` (see below)
- **D1c · Greeting, Today card, CTA** — complete (see below)

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

## D1b · Circle ring and timer

- **Shared `HomeCircle`** (`home_circle_metrics.dart`), used by Ready and every assigned state so the Circle never jumps: the halo disc, a 6pt ring inset 8pt inside it, a 4pt band of halo surface, then the illustration (`circleSize − 36`). The wordmark keeps its validated pre-D1 scale (`interiorSize = circleSize − 20`).
- **`ThirtyProgressCircle.thumbDiameter`** (optional, off by default): a 14pt dot in the progress colour at the arc's leading end — at the top when progress is 0.
- **States:** Ready keeps the closed sage Circle with the wordmark (no dot). Assigned: soft `ringTrack` + sage arc + dot. Not started: empty arc, dot at the top (First Breath still opens the Circle from closed to empty). Started: the arc is `(now − startedAt) / 30 min`, full from 30 minutes on, repainted once a second (`eventClockProvider`). Closed: the arc keeps the time the Circle actually ran (`closedAt − startedAt`).
- **Removed:** the ambient breathing of the started Circle (its rule is overridden by the timer; see the founder decisions).
- **Semantics:** started now announces "Circle in progress. N of 30 minutes." so the timer is never visual-only; not started / closed are unchanged.
- **Tests:** `circle_hero_test.dart`'s old "Circle color lifecycle" group (transparent ready track, breathing) is replaced by the D1 ring group (colours and dot in every state, First Breath sweep, 12 / 15 / 45-minute progress and semantics, closed duration, the ticker never blocking `pumpAndSettle`); thumb painter tests; B1 / B2 geometry updated to the inset ring.

## D1c · Greeting, Today card, full-width CTA

- **Greeting** (`homeGreeting`, `today_card.dart`): "Good morning" 05:00–11:59, "Good afternoon" 12:00–17:59, "Good evening" otherwise; Newsreader 34pt, centred, a semantic header. The subline "Ready to close today's Circle?" shows while the Circle is not yet closed; closed keeps "Done for today / Your next Circle opens tomorrow." in the CTA's place. It replaces the "Today's Circle" eyebrow as First Breath's heading beat.
- **`TodayCard`**: full content width, left-aligned, 24pt padding — "TODAY" eyebrow (read as "Today"), the direction in the editorial serif, a 40pt Mist Sage chip with the activity's category icon (walking → walk, general wellness → leaf) beside the activity in sage, a divider, and the reason. A slice of Quiet Trail (the tree on its hill) fades in at the card's right edge; it is decorative and shown only below 130% text on a card ≥ 300pt wide, so large text is never squeezed. Reveal order is unchanged: card + direction with the intent beat, then activity + reason.
- **CTA**: Start / Close Circle span the full content width (the card's width). Ready's "Begin today's Circle" stays in its bounded column — Ready is outside the mockup.
- **Rhythm:** Circle → greeting 32pt, greeting → subline 8pt, subline → card 24pt, card → CTA 16pt. The pre-D1 column constants (eyebrow / hero / activity / support / CTA gaps) are removed.
- **Tests:** greeting boundaries, header semantics and subline per state; card alignment, icon and divider; art at 100% without overlapping the text; 320 / 360pt × 200% × light / dark × assigned / started / closed — text only, nothing truncated, full-width card and ≥ 56pt CTA. B2 / hero tests updated from the eyebrow / centred column to the greeting / card.
