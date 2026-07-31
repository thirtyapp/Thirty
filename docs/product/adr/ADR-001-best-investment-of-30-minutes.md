# ADR-001 — Best Investment of 30 Minutes

**Status:** Accepted

## Context

THIRTY's kernbelofte is dat de app gebruikers helpt dagelijks 30 minuten in hun gezondheid te investeren ([VISION.md](../../VISION.md), [CLAUDE.md](../../../CLAUDE.md)). Zodra er een aanbevelingslogica komt, ontstaat het risico dat individuele aanbevelingen — geoptimaliseerd op wetenschappelijke effectiviteit, personalisatie of engagement — geleidelijk buiten die 30-minuteneenheid gaan vallen (bijvoorbeeld door impliciet langere programma's of trainingsschema's voor te stellen).

## Beslissing

THIRTY beveelt altijd een invulling van ongeveer 30 minuten aan. Afwijken mag alleen met een expliciete, aan de gebruiker transparant gecommuniceerde reden — nooit stilzwijgend.

## Reden

De 30-minuteneenheid is niet een implementatiedetail maar de kern van de merkbelofte ("Your healthiest 30 minutes."). Een aanbevelingslogica die deze eenheid loslaat zonder dat expliciet te beslissen, verzwakt sluipenderwijs de reden waarom THIRTY bestaat.

## Consequenties

- Elke toekomstige uitbreiding van de aanbevelingslogica (nieuwe categorieën, nieuwe databronnen, nieuwe personalisatielagen) moet expliciet getoetst worden aan de vraag of de aanbeveling nog past binnen "ongeveer 30 minuten".
- Dit is een productprincipe, geen technische tijdslimiet — het schrijft niet voor hoe tijd technisch wordt vastgelegd.

## Gerelateerde documenten

- [Recommendation Philosophy §1](../recommendation-philosophy.md#1-kernbelofte-de-30-minuteninvestering)
- [Decision Framework §1](../decision-framework.md#1-kernbelofte)
