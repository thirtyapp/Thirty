# ADR-007 — Premium Never Blocks the Core Loop

**Status:** Accepted

## Context

THIRTY krijgt een gratis en een betaalde versie ([CLAUDE.md](../../../CLAUDE.md), context bij eerdere missies). Zonder expliciete beslissing bestaat het risico dat de gratis versie geleidelijk wordt uitgekleed om Premium aantrekkelijker te maken — een bekend patroon in vergelijkbare apps dat het gevoel van "bait-and-switch" oproept.

## Beslissing

De gratis versie levert de volledige kernbelofte (dagelijkse aanbeveling van ongeveer 30 minuten, inclusief basisbegeleiding) zonder compromis. Premium voegt verdieping toe — bijvoorbeeld diepere personalisatie of inzicht in patronen over tijd — maar ontgrendelt nooit de kern zelf. Premium wordt niet tijdens de eerste sessie genoemd en nooit als onderbreking van de dagelijkse kernactie getoond.

## Reden

Dit sluit aan bij [VISION.md](../../VISION.md) ("vertrouwen boven groei-trucs" — "geen dark patterns, geen nep-urgentie") en voorkomt dat het verdienmodel de kernbelofte (zie [ADR-001](ADR-001-best-investment-of-30-minutes.md)) ondermijnt.

## Consequenties

- **Vastgesteld (2026-08-04):** de expliciete, benoembare lijst van wat onvoorwaardelijk gratis blijft. Onvoorwaardelijk, voor elke gebruiker, voor altijd: het kern-cirkelritueel; The First Breath, in zijn geheel; een betekenisvolle dagelijkse aanbeveling; het starten en afronden van een Circle; de basis World-ervaring; normale seizoensexpressie van die World; permanente Personal Growth; geen streak-druk; geen schuldmechanieken; een volledige en respectvolle dagelijkse ervaring. Volledige redenering en bronverwijzingen: [PREMIUM_STRATEGY.md §1, Free Product Promise](../PREMIUM_STRATEGY.md#1-free-product-promise). Dit beantwoordt de voormalige open vraag in [Product Discovery §6](../product-discovery.md#6-open-vragen) over de vrije-kernlijst.
- Het concrete, meetbare triggermoment waarop Premium voor het eerst getoond wordt, is nog open (zie [Product Discovery §6, open vraag 5](../product-discovery.md#6-open-vragen)) en moet beslist zijn vóór dit principe in een scherm wordt uitgewerkt.

## Gerelateerde documenten

- [Product Discovery §5](../product-discovery.md#5-wanneer-introduceren-we-premium)
- [Onboarding Principles §3](../onboarding-principles.md#3-premium-strategie)
- [PREMIUM_STRATEGY.md](../PREMIUM_STRATEGY.md) — de commerciële strategie en prioritering achter Premium; deze ADR blijft het besluit van record voor de gratis/Premium-grens, PREMIUM_STRATEGY.md bouwt erop voort zonder het te herhalen.
- [THIRTY Playbook — Hoofdstuk 4 §5, The Premium Filter](../../playbook/04-product-decision-framework.md#5-the-premium-filter) — dit ADR is hier veralgemeend tot het volledige toetsingskader voor elk toekomstig Premium-idee.
