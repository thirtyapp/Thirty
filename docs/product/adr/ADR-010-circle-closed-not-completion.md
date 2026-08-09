# ADR-010 — Circle Closed Is Not Verified Activity Completion

**Status:** Accepted

## Context

Vanaf Recommendation MVP v0 ([recommendation-mvp-v0.md](../recommendation-mvp-v0.md)) heeft "Circle Closed" voor het eerst een echte, inhoudelijke aanbeveling erachter — daarmee groeit het risico dat toekomstige functionaliteit (analytics, streaks, "voltooid"-badges, inzichten) Circle Closed stilzwijgend gaat behandelen als bewijs dat de gebruiker de aanbevolen activiteit daadwerkelijk heeft uitgevoerd. Dat weet THIRTY niet, en kan het in v0 niet weten.

## Beslissing

**Circle Closed** is uitsluitend een feitelijke app-interactie: de gebruiker startte de Circle en sloot die later expliciet af. **Activity Completed** — dat de aanbevolen activiteit daadwerkelijk en volledig is uitgevoerd — is een aparte, in v0 onbeantwoorde vraag. Circle-afsluiting wordt nergens (code, UI-copy, semantics, analytics) voorgesteld, gelabeld of gebruikt als bewijs van voltooide activiteit. Het interval tussen Start en Close mag bestaan als feitelijk Circle-interval, maar wordt nooit geïnterpreteerd als geverifieerde trainings- of activiteitsduur. Er is geen minimale verstreken-tijd-poort die "Close" pas toestaat na een bepaalde duur.

## Reden

THIRTY mag nooit doen alsof het meer weet dan het werkelijk weet ([Recommendation Philosophy §2](../recommendation-philosophy.md#2-vereisten-voor-een-aanbeveling), [ADR-002](ADR-002-recommendations-must-be-explainable.md)). Een app kan vaststellen dát een scherm werd geopend en gesloten; ze kan niet vaststellen wát de gebruiker in de tussentijd in de fysieke wereld heeft gedaan. Deze grens wordt hier expliciet vastgelegd zodat toekomstige features die op Circle-data voortbouwen, haar niet per ongeluk overschrijden. Dit houdt ook [Product Discovery §6, vraag 4](../product-discovery.md#6-open-vragen) ("Wat telt precies als afgeronde 30 minuten?") bewust open — dit ADR beantwoordt die vraag nadrukkelijk niet, en voorkomt dat Circle Closed per ongeluk als impliciet antwoord gaat gelden.

## Consequenties

- Elke toekomstige implementatie die Circle-data toont, telt of erop voortbouwt (streaks, geschiedenis, inzichten, Premium-personalisatie) moet aantoonbaar het onderscheid tussen Circle Closed en Activity Completed intact laten.
- Wanneer THIRTY ooit wél activiteitvoltooiing wil vaststellen, vereist dat een nieuwe, expliciete beslissing (een nieuw ADR) — nooit een stilzwijgende herinterpretatie van bestaande Circle-data.
- Dit ADR introduceert zelf geen nieuwe data, meting of functionaliteit — het is een grens op interpretatie van reeds bestaande, feitelijke lifecycle-data ([`RecommendationState`](../../../lib/features/home/application/recommendation_provider.dart)).

## Gerelateerde documenten

- [recommendation-mvp-v0.md §7](../recommendation-mvp-v0.md#7-circle-closed--activity-completed)
- [Product Discovery §6, vraag 4](../product-discovery.md#6-open-vragen)
- [ADR-002 — Recommendations Must Be Explainable](ADR-002-recommendations-must-be-explainable.md)
