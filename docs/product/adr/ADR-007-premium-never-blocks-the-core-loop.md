# ADR-007 — Premium Never Blocks the Core Loop

**Status:** Accepted

## Context

THIRTY krijgt een gratis en een betaalde versie ([CLAUDE.md](../../../CLAUDE.md), context bij eerdere missies). Zonder expliciete beslissing bestaat het risico dat de gratis versie geleidelijk wordt uitgekleed om Premium aantrekkelijker te maken — een bekend patroon in vergelijkbare apps dat het gevoel van "bait-and-switch" oproept.

## Beslissing

De gratis versie levert de volledige kernbelofte (dagelijkse aanbeveling van ongeveer 30 minuten, inclusief basisbegeleiding) zonder compromis. Premium voegt verdieping toe — bijvoorbeeld diepere personalisatie of inzicht in patronen over tijd — maar ontgrendelt nooit de kern zelf. Premium wordt niet tijdens de eerste sessie genoemd en nooit als onderbreking van de dagelijkse kernactie getoond.

## Reden

Dit sluit aan bij [VISION.md](../../VISION.md) ("vertrouwen boven groei-trucs" — "geen dark patterns, geen nep-urgentie") en voorkomt dat het verdienmodel de kernbelofte (zie [ADR-001](ADR-001-best-investment-of-30-minutes.md)) ondermijnt.

## Consequenties

- Er moet, vóórdat Premium daadwerkelijk wordt gebouwd, een expliciete, benoembare lijst komen van wat onvoorwaardelijk gratis blijft (zie [Product Discovery §6, open vraag 6](../product-discovery.md#6-open-vragen)).
- Het concrete, meetbare triggermoment waarop Premium voor het eerst getoond wordt, is nog open (zie [Product Discovery §6, open vraag 5](../product-discovery.md#6-open-vragen)) en moet beslist zijn vóór dit principe in een scherm wordt uitgewerkt.

## Gerelateerde documenten

- [Product Discovery §5](../product-discovery.md#5-wanneer-introduceren-we-premium)
- [Onboarding Principles §3](../onboarding-principles.md#3-premium-strategie)
