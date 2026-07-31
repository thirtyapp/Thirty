# ADR-005 — Intent Before Activity

**Status:** Accepted

## Context

Een aanbevelingslogica kan direct naar een concrete activiteit springen (bijvoorbeeld "ga 5 km hardlopen") op basis van beschikbare signalen, zonder eerst vast te stellen wélk onderliggend doel die activiteit dient. Dat maakt aanbevelingen moeilijker uit te leggen en moeilijker aan te passen wanneer specifieke gegevens ontbreken.

## Beslissing

THIRTY kiest in de eerste plaats een intentie (bijvoorbeeld "meer bewegen", "beter herstellen", "hoofd leegmaken"). De concrete activiteit (wandelen, fietsen, yoga, mobiliteit) is een latere, persoonlijke invulling van die intentie.

## Reden

Dit onderscheid maakt aanbevelingen uitlegbaar op twee niveaus en maakt het mogelijk om sterk te zijn op intentieniveau, ook wanneer specifieke activiteitdata ontbreken (zie [Decision Framework §8, §9](../decision-framework.md#8-wanneer-heeft-thirty-onvoldoende-informatie-voor-een-sterke-aanbeveling)).

## Consequenties

- Geen toekomstige implementatie mag een activiteit rechtstreeks aanbevelen op basis van signalen (bijvoorbeeld externe data) zonder eerst een intentie te hebben vastgesteld.
- Bij onzekerheid over de juiste activiteit blijft THIRTY zeker over de intentie in plaats van te gokken op specificiteit.

## Gerelateerde documenten

- [Decision Framework §4, §8, §9](../decision-framework.md#4-intentie-versus-activiteit)
- [THIRTY Playbook — Hoofdstuk 4 §6, The AI Filter](../../playbook/04-product-decision-framework.md#6-the-ai-filter) — dit ADR is hier veralgemeend tot het toetsingskader voor elke toekomstige AI-feature.
