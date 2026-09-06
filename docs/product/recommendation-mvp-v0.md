# Recommendation MVP v0 — "A recommendation that could have been different"

Dit document is de **source of truth** voor de concrete inhoud en het mechanisme van Recommendation MVP v0: de drie Intentions, de goedgekeurde activiteiten per Intention, hoe THIRTY daaruit deterministisch kiest, en de regels voor de "Why This Today?"-uitleg. Het herhaalt geen bredere filosofie — dat blijft de rol van [Recommendation Philosophy](recommendation-philosophy.md) en [Decision Framework](decision-framework.md), waarvan dit document de eerste concrete, geïmplementeerde toepassing is.

---

## 1. Producthypothese

Recommendation MVP v0 test: **of gebruikers er waarde aan hechten om één kleine dagelijkse wellnessbeslissing aan THIRTY te delegeren, met zeer beperkte betrouwbare informatie.**

De gebruiker kiest de gewenste richting. THIRTY kiest daarbinnen één goedgekeurde activiteit.

v0 claimt **niet** dat THIRTY objectief de beste investering van vandaag kent. De kernbelofte ("de beste investering van ongeveer 30 minuten voor vandaag" — [Recommendation Philosophy §1](recommendation-philosophy.md#1-kernbelofte-de-30-minuteninvestering)) blijft het lange-termijndoel; v0 is één stap daarnaartoe, geen bewijs dat THIRTY er al is.

**Dit is geen nieuwe architectuur.** [Decision Framework §8–9](decision-framework.md#8-wanneer-heeft-thirty-onvoldoende-informatie-voor-een-sterke-aanbeveling) beschrijft precies dit geval: wanneer de intentie wél vaststaat maar er onvoldoende betrouwbare persoonlijke gegevens of context zijn om een specifieke activiteit te kiezen, blijft THIRTY zeker over de intentie en kiest binnen die intentie de breedst toepasbare, veilige activiteit. v0 is die laag, voor het eerst werkend.

## 2. De drie Intentions

Precies drie, elk een expliciet door de gebruiker gekozen richting — **geen afgeleide gezondheidstoestand**:

| Intention | Betekenis |
|---|---|
| **More Energy** | "I want to spend this half-hour being somewhat more active and engaged." |
| **Clearer Head** | "I want this half-hour to contain less competing input and more single-focus attention." |
| **Gentler Pace** | "I want to use this half-hour without turning it into another performance or productivity demand." |

### Daily Context Question

Vóór de aanbeveling op elke nieuwe lokale kalenderdag wordt gekozen, stelt THIRTY exact één vraag: **"What would help most today?"**, met precies deze drie keuzes, 1:1 gemapt op de Intentions hierboven. Geen inferentie, geen mood score, geen gezondheidstoestand-detectie. Zodra gekozen, ligt de dag-intentie vast. Dit beantwoordt [Product Discovery §6, vraag 1](product-discovery.md#6-open-vragen) — zie [ADR-009](adr/ADR-009-daily-intention-question.md).

## 3. Activiteiteninventaris

Elke canonieke activiteit (`ActivityId` in code — zie `lib/features/home/application/activity_catalog.dart`) hoort in deze versie bij precies één Intention-pool. **30-minute walk, Phone-free walk en Easy walk blijven drie afzonderlijke canonieke activiteiten**, ondanks hun conceptuele overlap; perceived repetition daartussen wordt gevalideerd met echte gebruikers, niet vooraf technisch opgelost. Het mechanisme ondersteunt nog steeds dat één canonieke activiteit in meerdere pools voorkomt — zie `ActivityId`'s eigen doc comment in code — maar heeft daar momenteel geen voorbeeld van: **Gentle mobility is uit v0 verwijderd**, omdat de concrete invulling ("move in ways you choose") ondanks veilige copy nog te veel aan de gebruiker overliet. v0 test specifiek of gebruikers waarde hechten aan één concrete dagelijkse keuze van THIRTY, dus blijft elke behouden activiteit concreet genoeg dat de gebruiker onmiddellijk weet welke actie gekozen is. Poolgroottes zijn daardoor bewust ongelijk (2/3/2) — er is geen vervangende activiteit toegevoegd om ze weer gelijk te maken.

### More Energy
| Activiteit | Productbasis | Veiligheid |
|---|---|---|
| 30-minute walk | Toegankelijke, zelfstandige beweging zonder workoutstructuur of prestatiedoel. | Geen tempo-, afstand-, stappen- of hartslagdoelen; geen claim dat wandelen medisch geschikt is voor iedereen. |
| Move to music | Zelfstandige beweging op eigen muziek en tempo. | Nooit geframed als workout, calorieverbranding of intensiteitsdoel. |

### Clearer Head
| Activiteit | Productbasis | Veiligheid |
|---|---|---|
| Phone-free walk | Een eenvoudige activiteit gecombineerd met bewust minder concurrerende input. | "Phone-free" betekent geen actieve content-consumptie, niet per se de telefoon achterlaten; geen stress-, angst-, concentratie-behandeling of medische claims. |
| Write it down | Concurrerende gedachten, herinneringen of taken één externe plek geven. | Geen therapeutisch journaling, emotionele diagnose, traumaprompts of mental-health claims. |
| Quiet reading | Eén volgehouden, zelfgekozen activiteit in plaats van gefragmenteerde input. | Geen cognitie-, mental-health-, stress- of slaapclaims. |

### Gentler Pace
| Activiteit | Productbasis | Veiligheid |
|---|---|---|
| Easy walk | Een bewust ongehaaste activiteit zonder prestatiedoelen. | Geen tempo-, afstand-, stappen- of medische geschiktheidsclaims. |
| Quiet music break | Eén zelfgekozen ontspanningsactiviteit zonder productiviteits- of fysieke-prestatiedoelen. | Geen zenuwstelsel-, stress-behandeling-, stemming-behandeling- of slaapclaims. |

Alle activiteiten zijn algemene wellness. Geen enkele activiteit personaliseert op, of houdt rekening met: pijn, blessure, revalidatie, symptomen, gediagnosticeerde aandoeningen, zwangerschap/postpartum, medicatie, mental-health-behandeling, slaapbehandeling, eetstoornissen, gewichtsverlies, voeding, supplementen, therapeutische ademhaling, intensiteitszones, hartslagdoelen, tempo-/afstandsdoelen, gewichten/belasting, sets/reps, voorgeschreven rekbereiken, correctieve oefening, of iets dat professionele beoordeling vereist. Beweging blijft comfortabel en zelf-getempood.

## 4. Selectielogica

Minimaal pad: **dagelijks antwoord → intentie → goedgekeurde activiteitenpool → deterministieke activiteit.**

- Dezelfde lokale datum + dezelfde intentie geeft altijd hetzelfde resultaat.
- Eenmaal gekozen voor die dag, ligt de aanbeveling vast.
- Een herstart van de app herstelt dezelfde aanbeveling.
- Geen scoring, geen AI, geen probabilistische rangschikking, geen verborgen personalisatie, geen claim van objectieve optimaliteit.

**Mechanisme:** een stabiel, kalender-afgeleid geheel getal per lokale dag (`epochDay`, gebouwd op `DateTime.utc` — nooit op een lokale-tijd-verschil, dus ongevoelig voor zomertijdovergangen) wordt modulo de lengte van de intentie-pool genomen om de "normale" kandidaat te bepalen. Zie `activity_catalog.dart`'s `epochDay()`/`selectActivityId()`.

### Anti-repetitie (herzien in Batch 2 — [ADR-012](adr/ADR-012-batch-2-recommendation-diversity.md))

v0's oorspronkelijke regel ("niet dezelfde activiteit als de vorige lokale dag") beschermde alleen tegen opeenvolgende dagen; een gebruiker die THIRTY om de dag (of onregelmatiger) opent, kon dezelfde activiteit binnen enkele dagen terugzien zodra de vorige-dag-vergelijking niet meer van toepassing was. Dit bleek de directe oorzaak van gerapporteerde herhaling bij een behouden tester.

**Huidige regel:** elke Intention houdt een begrensde geschiedenis bij van recent getoonde `ActivityId`'s uit haar eigen pool, met een maximum van `pool.length - 1` items. De normale deterministische kandidaat (`dayIndex % pool.length`, zie hierboven) wordt bepaald **na** het uitsluiten van die geschiedenis uit de pool. Dit garandeert geen herhaling totdat elke andere activiteit in de pool sinds de vorige keer is getoond — ongeacht hoeveel kalenderdagen daartussen zitten — en de cap (`pool.length - 1`) garandeert dat er altijd minstens één niet-uitgesloten kandidaat overblijft, dus nooit een impasse. Nog steeds geen scoring, geen AI, geen willekeur: exact dezelfde soort deterministische rotatie als voorheen, alleen toegepast op een kleinere, geschiedenis-bewuste subset van de pool. Zie `activity_catalog.dart`'s `selectActivityId()`.

## 5. Lokale opslag

Alleen `shared_preferences`. Supabase wordt sinds Batch 1 uitsluitend gebruikt voor het losstaande, insert-only analytics-sink (`supabase/README.md`) — nooit voor aanbevelings- of Circle-state.

**Vandaag:** lokale datum, gekozen Intention, geselecteerde ActivityId, bestaande Circle-lifecycle (status/started/closed timestamps).
**Anti-repetitiegeschiedenis (Batch 2 — [ADR-012](adr/ADR-012-batch-2-recommendation-diversity.md)):** per Intention één losse, begrensde lijst van recent getoonde `ActivityId`'s (`recommendationHistoryKeyFor` in `recommendation_provider.dart`), maximaal `pool.length - 1` items, bijgewerkt telkens die Intention daadwerkelijk wordt gekozen. Overleeft een normale app-herstart; een device-brede clear-storage zet deze geschiedenis terug naar leeg — hetzelfde veilige startpunt als eerste gebruik.

Een herstart op dezelfde dag herstelt dezelfde aanbeveling. Een nieuwe lokale dag start een nieuwe vraag/aanbevelingscyclus.

## 6. "Why This Today?"

Alleen deterministische, goedgekeurde copy. De uitleg mag uitsluitend verwijzen naar (1) de intentie die de gebruiker expliciet koos, en (2) een waarheidsgetrouw praktisch kenmerk van de gekozen activiteit. Nooit een claim van verborgen kennis — nooit iets equivalent aan "Your body needs...", "Based on your energy...", "This will reduce your stress...", of "This is what you need today...". De uitleg maakt THIRTY's keuze begrijpelijk, niet medisch gezaghebbend. Zie `activity_catalog.dart`'s `whyCopyFor()` voor de exacte, goedgekeurde teksten per (Intention, ActivityId)-paar.

## 7. Circle Closed ≠ Activity Completed

**Circle Closed** is een feitelijke app-interactie: de gebruiker startte de Circle en sloot die later expliciet af. **Activity Completed** is iets dat THIRTY in v0 objectief niet kan weten. Circle-afsluiting wordt nergens — in code, UI of analytics — voorgesteld als geverifieerde activiteitvoltooiing. Er is geen minimale verstreken-tijd-poort; het interval tussen Start en Close mag bestaan als feitelijk Circle-interval, maar wordt nooit geïnterpreteerd als geverifieerde trainings-/activiteitsduur. Zie [ADR-010](adr/ADR-010-circle-closed-not-completion.md).

## 8. Expliciet niet in scope

Geen AI/LLM-integratie, geen Supabase-aanbevelingslogica, geen accounts, geen authenticatie, geen onboardingsysteem, geen Premium, geen backend-gebruikersdata, geen weer, geen locatie, geen wearables, geen profielen, geen moeilijkheidsgraden, geen scoring-engines, geen personalisatie op gezondheidsaandoeningen, geen geschiedenis-UI, geen extra contextuele vragen. Geen nieuwe `ActivityCategory`-Werelden/Places — [ActivityCategory.generalWellness](../../lib/core/activity_category.dart) hergebruikt tijdelijk de bestaande Quiet Trail-illustratie voor elke niet-wandel-activiteit, zonder nieuw World/Place-werk.

## 9. Gerelateerde documenten

- [Recommendation Philosophy](recommendation-philosophy.md) en [Decision Framework](decision-framework.md) — de bredere, duurzame eisen en het raamwerk waarvan dit document de eerste concrete toepassing is.
- [ADR-009 — Daily Intention Question](adr/ADR-009-daily-intention-question.md)
- [ADR-010 — Circle Closed Is Not Verified Activity Completion](adr/ADR-010-circle-closed-not-completion.md)
- [ADR-012 — Batch 2 / Recommendation Diversity](adr/ADR-012-batch-2-recommendation-diversity.md)
- [Product Discovery §6](product-discovery.md#6-open-vragen) — open vraag 1 is door dit document beantwoord; vraag 4 blijft expliciet open.
