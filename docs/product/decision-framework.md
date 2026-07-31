# Decision Framework

Dit document beschrijft **hoe** THIRTY een aanbeveling samenstelt uit de bronnen en eisen die in [Recommendation Philosophy](recommendation-philosophy.md) zijn vastgelegd — welke signalen voorrang krijgen, welke elkaar mogen overrulen, en hoe wordt omgegaan met onvoldoende informatie of onzekerheid.

Dit is een architectuurdocument, geen algoritme: het beschrijft prioriteit en samenhang tussen beslissingen, niet een berekening, scoringsformule of technische implementatie. Dit document is de **source of truth** voor prioriteit en conflictoplossing tussen signalen. Voor de eisen zelf (wat een aanbeveling moet zijn) geldt [Recommendation Philosophy](recommendation-philosophy.md) als source of truth.

---

## 1. Kernbelofte

Alles in dit document opereert binnen de kernbelofte uit [Recommendation Philosophy §1](recommendation-philosophy.md#1-kernbelofte-de-30-minuteninvestering): de beste investering van ongeveer 30 minuten voor vandaag. Geen laag of poort in dit framework mag daarvan afwijken zonder expliciete, transparante reden.

## 2. Definitie: "Positief Succesmoment"

Deze term wordt in dit hele document gebruikt en heeft daarom één vaste betekenis. Een aanbeveling is een **positief succesmoment** wanneer ze:

- **veilig** is;
- **uitvoerbaar** is (inclusief zelfstandig uitvoerbaar);
- door de gebruiker **als haalbaar wordt ervaren**, op het moment van aanbieden;
- een **positieve ervaring** oplevert bij uitvoering;
- bijdraagt aan **duurzame gezondheidsgewoonten**, niet aan een eenmalige piekprestatie.

De eerste twee punten zijn direct ontleend aan de vereisten in [Recommendation Philosophy §2](recommendation-philosophy.md#2-vereisten-voor-een-aanbeveling); de laatste drie zijn specifiek voor dit begrip. Elke verwijzing naar "succesmoment" of "grootste kans op succes" elders in de productdocumentatie verwijst naar exact deze definitie.

## 3. Informatiebronnen (operationeel)

De bronnen zelf, hun aard en hun voorwaarden zijn vastgelegd in [Recommendation Philosophy §4](recommendation-philosophy.md#4-informatiebronnen). Dit framework gebruikt ze in de volgende lagen (zie §5).

## 4. Intentie versus Activiteit

- **Intentie** is de onderliggende richting die THIRTY voor de gebruiker kiest — bijvoorbeeld *meer bewegen*, *beter herstellen*, *hoofd leegmaken*. De intentie wordt in de eerste plaats bepaald door persoonlijke doelen, binnen de ruimte die de wetenschappelijke basis toelaat.
- **Activiteit** is de concrete, persoonlijke invulling van die intentie — bijvoorbeeld *wandelen*, *fietsen*, *yoga*, *mobiliteitsoefeningen* als invulling van "meer bewegen". De activiteit wordt bepaald door persoonlijke gegevens, context en eventueel externe data.

**Ontwerpprincipe:** THIRTY kiest in de eerste plaats de juiste *intentie*. De activiteit is een latere, meer variabele verfijning daarvan. Dit heeft directe consequenties voor hoe THIRTY omgaat met onvoldoende informatie en onzekerheid (§8, §9): THIRTY kan sterk zijn op intentieniveau, ook wanneer ze dat nog niet is op activiteitniveau.

→ Zie [ADR-005 — Intent Before Activity](adr/ADR-005-intent-before-activity.md).

## 5. Het beslisproces: poorten en lagen

Het beslisproces bestaat uit **lagen**, niet uit één strikt lineaire keten. Persoonlijke gegevens en context beïnvloeden elkaar in de praktijk wederzijds — een voorkeur is vaak alleen relevant gegeven een bepaalde context, en context bepaalt soms welke persoonlijke gegevens ertoe doen. Die twee als vaste, eenrichtingsvolgorde beschrijven zou een precisie suggereren die niet bestaat.

- **Laag 0 — Poorten (doorlopend, geen stap).** Veiligheid, uitvoerbaarheid, transparantie en afwezigheid van schuldgevoel — ontleend aan de vereisten in [Recommendation Philosophy §2](recommendation-philosophy.md#2-vereisten-voor-een-aanbeveling). Deze gelden niet op één punt in het proces, maar continu, op elk moment dat een optie wordt overwogen, getoond of aangepast.
- **Laag 1 — Vaste basis.** Wetenschappelijke gezondheidsprincipes. Blijft vast eerst, omdat het de enige bron is die niet per gebruiker of moment verandert — ze bepaalt de ruimte van mogelijke intenties, niet een concrete keuze.
- **Laag 2 — Intentie.** Persoonlijke doelen bepalen, binnen die ruimte, de intentie (§4).
- **Laag 3 — Wederkerige verfijning.** Persoonlijke gegevens en context vertalen de intentie samen naar een concrete activiteit. Geen vaste volgorde tussen deze twee — ze informeren elkaar.
- **Laag 4 — Verrijking.** Externe databronnen verfijnen de precisie waar beschikbaar, zonder ooit een eerdere laag te initiëren of te vereisen.
- **Laag 5 — Versterking.** Sociale signalen versterken, als laatste, een aanbeveling die op de voorgaande lagen al geldig is.

## 6. Welke signalen mogen elkaar overrulen?

- **Persoonlijke doelen mogen de theoretisch beste wetenschappelijke optie overrulen** — de intentie wordt gekozen op basis van de grootste kans op een positief succesmoment (§2), niet op abstracte optimaliteit.
- **Context en persoonlijke gegevens mogen elkaar wederzijds overrulen** bij het vertalen van intentie naar activiteit (laag 3), zolang de poorten uit laag 0 gerespecteerd blijven.
- **Actuele persoonlijke gegevens mogen verouderde persoonlijke gegevens overrulen** binnen dezelfde bron.
- **Externe databronnen mogen de precisie van een activiteit overrulen** (verfijnen), maar nooit de intentie zelf initiëren of forceren.

## 7. Welke signalen mogen elkaar nooit overrulen?

- **Niets overrult de poorten van laag 0** — geen doel, geen context, geen externe data, geen sociaal signaal.
- **Niets overrult zelfstandige uitvoerbaarheid** tot een niet-uitvoerbare aanbeveling, ongeacht hoe sterk de doelmatch is.
- **Externe databronnen initiëren nooit een intentie of activiteit.** Ze verrijken een keuze die ook zonder hen al geldig zou zijn.
- **Sociale gezondheid geeft nooit de doorslag** — alleen versterking van iets dat al op andere gronden geldig is.
- **Activiteit overrult nooit intentie.** Een aantrekkelijke activiteit die niet bij de gekozen intentie past, mag niet worden aanbevolen enkel omdat de activiteit zelf goed scoort.
- **Precisie overrult nooit transparantie**, en **niets overrult de eis van geen schuldgevoel.**

## 8. Wanneer heeft THIRTY onvoldoende informatie voor een sterke aanbeveling?

- **Onvoldoende voor een intentie:** wanneer er geen persoonlijke doelen én geen bruikbare context beschikbaar zijn. THIRTY biedt dan hoogstens een breed toepasbare, veilige intentie — geen aanbeveling die als persoonlijk sterk mag gelden.
- **Onvoldoende voor een specifieke activiteit:** wanneer de intentie wél vaststaat, maar er onvoldoende betrouwbare persoonlijke gegevens of context zijn om een specifieke activiteit te kiezen. THIRTY blijft dan zeker over de intentie en kiest een brede, veilige activiteit binnen die intentie.
- **Onvoldoende zekerheid per optie:** wanneer voor een specifieke optie niet met voldoende zekerheid kan worden vastgesteld dat ze een van de poorten doorstaat. Die optie valt dan af, los van de rest.

## 9. Hoe gaat THIRTY om met onzekerheid?

- Onzekerheid wordt nooit gemaskeerd door schijnzekerheid.
- Bij onzekerheid over de **activiteit** blijft THIRTY zeker over de **intentie**, en kiest binnen die intentie de breedst toepasbare, veilige activiteit.
- De mate van specificiteit van een aanbeveling beweegt mee met de hoeveelheid betrouwbare informatie: meer betrouwbare informatie geeft ruimte voor een specifiekere activiteit; minder informatie houdt de aanbeveling op het niveau van intentie.
- Onzekerheid is nooit een reden om géén aanbeveling te doen — wel om haar behoudender te maken.

## 10. Leerprincipe: THIRTY leert, maar beoordeelt niet

- Iedere aanbeveling — of ze wordt opgevolgd, aangepast of genegeerd — levert nieuwe informatie op over wat voor déze gebruiker, en in het algemeen, tot een positief succesmoment leidt.
- THIRTY leert van deze ervaringen om toekomstige aanbevelingen beter te maken: preciezer, passender, met een grotere kans op een positief succesmoment.
- **Dit leren is nooit een beoordeling van de gebruiker.** Een genegeerde of niet-afgeronde aanbeveling is geen falen van de gebruiker — het is informatie dat déze specifieke intentie, activiteit, context-combinatie of framing kennelijk niet paste.
- Het systeem leert om **zichzelf** te verbeteren, niet om de gebruiker te profileren, scoren of diagnosticeren.
- Dit is een **architectuurprincipe**: een eigenschap van het besluitvormingsproces dat zijn eigen toekomstige toepassing van de bestaande lagen en poorten verbetert. Het is geen nieuwe informatiebron, geen AI-feature en geen implementatie — en het mag nooit de poorten uit laag 0 aantasten of omzeilen.

→ Zie [ADR-008 — Learning Without Judgment](adr/ADR-008-learning-without-judgment.md).

## 11. Ontwerpprincipes om toekomstige AI-implementaties te beschermen tegen afwijking

1. **Poorten zijn niet optimaliseerbaar** en gelden doorlopend (laag 0), niet als eenmalige stap.
2. **Optionele bronnen blijven altijd optioneel** — geen toekomstige databron mag een vereiste worden voor een basisaanbeveling. Zie [ADR-004](adr/ADR-004-optional-data-never-required.md).
3. **Sociale gezondheid krijgt nooit een eigen aanbevelingskanaal.**
4. **Het optimalisatiedoel blijft het positieve succesmoment (§2), nooit theoretische optimaliteit.** Zie [ADR-003](adr/ADR-003-success-over-theoretical-perfection.md).
5. **Uitlegbaarheid is een ontwerprandvoorwaarde, geen nabewerking.** Zie [ADR-002](adr/ADR-002-recommendations-must-be-explainable.md).
6. **Onzekerheid moet herkenbaar en hanteerbaar blijven**, ongeacht het onderliggende mechanisme.
7. **Personalisatie mag nooit sneller groeien dan de betrouwbare informatie die ze rechtvaardigt.**
8. **De niet-onderhandelbare eisen zijn productbeslissingen, geen technische parameters.**
9. **De kernbelofte (§1) mag nooit stilzwijgend verwateren.** Zie [ADR-001](adr/ADR-001-best-investment-of-30-minutes.md).
10. **Leren mag nooit verworden tot beoordelen.** Zie [ADR-008](adr/ADR-008-learning-without-judgment.md).
11. **Intentie blijft altijd de eerste beslissing, activiteit altijd de tweede.** Zie [ADR-005](adr/ADR-005-intent-before-activity.md).

## 12. Gerelateerde documenten

- [Recommendation Philosophy](recommendation-philosophy.md) — de eisen en bronnen waarop dit framework opereert.
- [docs/product/adr/](adr/) — de individuele, gedateerde beslissingen die uit dit framework voortvloeien.
