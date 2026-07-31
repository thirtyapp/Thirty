# ADR-008 — Learning Without Judgment

**Status:** Accepted

## Context

Naarmate THIRTY leert van gebruikersgedrag om aanbevelingen te verbeteren, ontstaat het risico dat "leren" in de praktijk verschuift naar het scoren, rangschikken of impliciet beoordelen van de gebruiker (bijvoorbeeld: een gebruiker die vaak aanbevelingen negeert wordt als "minder gemotiveerd" behandeld).

## Beslissing

THIRTY leert van elke aanbeveling — of ze wordt opgevolgd, aangepast of genegeerd — om zichzelf te verbeteren. Dit leren is nooit een beoordeling van de gebruiker. Een genegeerde aanbeveling is informatie dat die intentie, activiteit, context-combinatie of framing niet paste, geen falen van de gebruiker.

## Reden

Dit sluit aan bij [BRAND_BOOK.md, Writing Guidelines](../../BRAND_BOOK.md#21-writing-guidelines) ("geen schuldgevoel-taal: vermijd woorden als 'gefaald', 'gemist', 'achterstand'") en bij de Circle Philosophy in [BRAND_BOOK.md §8](../../BRAND_BOOK.md#8-the-circle-philosophy): "geen falen, alleen voortgang."

## Consequenties

- Elke toekomstige implementatie van dit leerprincipe moet aantoonbaar de gebruiker niet scoren, rangschikken of "diagnosticeren" — ze optimaliseert de aanbeveling, niet het oordeel over de gebruiker.
- Dit leerprincipe is een architectuureigenschap van het besluitvormingsproces, geen nieuwe informatiebron en geen AI-feature op zich.

## Gerelateerde documenten

- [Decision Framework §10](../decision-framework.md#10-leerprincipe-thirty-leert-maar-beoordeelt-niet)
