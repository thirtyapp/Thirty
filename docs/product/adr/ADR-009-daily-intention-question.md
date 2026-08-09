# ADR-009 — Daily Intention Question Is v0's Sole Personalization Signal

**Status:** Accepted

## Context

[Product Discovery §6, vraag 1](../product-discovery.md#6-open-vragen) stond open: "Wat is de bron/logica van de allereerste suggestie zonder gebruikersdata?" Recommendation MVP v0 ([recommendation-mvp-v0.md](../recommendation-mvp-v0.md)) is de eerste implementatie die deze vraag concreet moet beantwoorden — zonder account, zonder persoonlijke gegevens, zonder context, moet THIRTY toch een aanbeveling kunnen doen.

## Beslissing

De enige bron voor THIRTY's allereerste aanbeveling, zonder gebruikersdata, is één expliciete dagelijkse keuze van de gebruiker: de Daily Context Question ("What would help most today?"), met precies drie vaste opties (More Energy, Clearer Head, Gentler Pace), elk 1:1 gemapt op een Intention. Deze keuze wordt nooit afgeleid, geïnfereerd of voorspeld — alleen expliciet gegeven.

## Reden

Dit is de directe toepassing van [ADR-005 — Intent Before Activity](ADR-005-intent-before-activity.md) op het punt waar THIRTY nog geen enkele andere informatiebron heeft: [Decision Framework §8](../decision-framework.md#8-wanneer-heeft-thirty-onvoldoende-informatie-voor-een-sterke-aanbeveling) stelt dat THIRTY bij onvoldoende informatie voor een intentie hoogstens een breed toepasbare, veilige intentie biedt — de Daily Context Question is die intentie niet laten gokken, maar laten kiezen door de enige partij die het echt weet: de gebruiker zelf, in het moment. Dit sluit ook aan bij [Product Discovery §3](../product-discovery.md#3-welke-informatie-hebben-we-écht-nodig): "een lichte contextuele keuze in het moment... geen profielvraag maar een keuze die de intentie direct stuurt."

## Consequenties

- Product Discovery §6, vraag 1 is hiermee beantwoord; [product-discovery.md](../product-discovery.md) is bijgewerkt om ernaar te verwijzen in plaats van de vraag nog open te laten staan.
- Toekomstige personalisatie mag deze vraag verrijken (bijvoorbeeld door haar minder vaak te stellen naarmate er betrouwbaardere signalen zijn), maar mag de Daily Context Question nooit vervangen door een inferentie zonder expliciete gebruikersinput, zonder dat daar een nieuwe, expliciete beslissing over wordt genomen.
- Dit voegt geen nieuwe aanbevelingslaag toe aan [Decision Framework §5](../decision-framework.md#5-het-beslisproces-poorten-en-lagen) — het is Laag 2 ("Intentie"), voor het eerst technisch ingevuld.

## Gerelateerde documenten

- [recommendation-mvp-v0.md §2](../recommendation-mvp-v0.md#2-de-drie-intentions)
- [Product Discovery §6](../product-discovery.md#6-open-vragen)
- [ADR-005 — Intent Before Activity](ADR-005-intent-before-activity.md)
- [Decision Framework §8, §9](../decision-framework.md#8-wanneer-heeft-thirty-onvoldoende-informatie-voor-een-sterke-aanbeveling)
