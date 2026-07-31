# ADR-004 — Optional Data Never Required

**Status:** Accepted

## Context

Externe databronnen (bijvoorbeeld een smartwatch) kunnen een aanbeveling aanzienlijk verrijken. Zonder expliciete beslissing bestaat het risico dat een toekomstige implementatie zulke data geleidelijk als vereiste gaat behandelen — bijvoorbeeld door een minder goede ervaring te bieden aan gebruikers zonder gekoppeld apparaat.

## Beslissing

Externe databronnen verrijken een aanbeveling waar beschikbaar, maar zijn nooit een vereiste om een aanbeveling te kunnen doen. Ze mogen nooit een aanbeveling initiëren — alleen de precisie ervan verhogen.

## Reden

THIRTY moet voor elke gebruiker werken, ongeacht welke apparaten hij bezit of koppelt. Een basisaanbeveling die afhankelijk is van externe data zou drempels invoeren die niet passen bij "eenvoudig en toegankelijk" ([VISION.md](../../VISION.md), [CLAUDE.md](../../../CLAUDE.md)).

## Consequenties

- Geen toekomstige databron-integratie (nieuwe sensor, nieuwe wearable) mag ooit een vereiste worden voor een basisaanbeveling.
- Bij het ontbreken van externe data valt het systeem terug op laag 1–3 van het beslisproces, nooit op een foutmelding of gedegradeerde kernervaring.

## Gerelateerde documenten

- [Recommendation Philosophy §4](../recommendation-philosophy.md#4-informatiebronnen)
- [Decision Framework §5, §7](../decision-framework.md#5-het-beslisproces-poorten-en-lagen)
