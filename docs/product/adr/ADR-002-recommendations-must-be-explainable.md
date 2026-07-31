# ADR-002 — Recommendations Must Be Explainable

**Status:** Accepted

## Context

THIRTY is een AI Health Companion. Naarmate de aanbevelingslogica complexer wordt (meer databronnen, meer personalisatie), groeit het risico dat aanbevelingen ontstaan die THIRTY zelf niet in eenvoudige taal aan de gebruiker kan uitleggen — vooral wanneer een toekomstige implementatie op een model leunt.

## Beslissing

Een aanbeveling die niet in eenvoudige taal uit te leggen is aan de gebruiker, wordt niet getoond. Transparantie is een poort op het tónen van de aanbeveling, niet een eigenschap die achteraf wordt toegevoegd.

## Reden

Vertrouwen is een kernwaarde van THIRTY ([VISION.md](../../VISION.md): "vertrouwen boven groei-trucs"). Een aanbeveling die de gebruiker moet vertrouwen zonder te begrijpen waarom, ondermijnt dat vertrouwen — ook als de aanbeveling inhoudelijk goed is.

## Consequenties

- Elke toekomstige technische implementatie (regelset, model, of anders) moet zo gebouwd worden dat het waaróm van een aanbeveling herleidbaar is vóórdat ze getoond wordt, niet achteraf geconstrueerd om een uitkomst te rechtvaardigen.
- Precisie of personalisatie mag nooit ten koste gaan van uitlegbaarheid.

## Gerelateerde documenten

- [Recommendation Philosophy §2](../recommendation-philosophy.md#2-vereisten-voor-een-aanbeveling)
- [Decision Framework §5, §7](../decision-framework.md#5-het-beslisproces-poorten-en-lagen)
- [THIRTY Playbook — Hoofdstuk 4 §6, The AI Filter](../../playbook/04-product-decision-framework.md#6-the-ai-filter) — dit ADR is hier veralgemeend tot het toetsingskader voor elke toekomstige AI-feature.
