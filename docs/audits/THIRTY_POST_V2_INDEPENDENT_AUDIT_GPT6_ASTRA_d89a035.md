# THIRTY POST-V2 INDEPENDENT AUDIT — GPT-6 ASTRA

Datum: 10 oktober 2026. Onafhankelijke product- en commerciële beoordeling. Strikt read-only.

## AUDIT TARGET

| Onderdeel | Beoordeeld |
|---|---|
| Repository | [thirtyapp/Thirty](https://github.com/thirtyapp/Thirty) |
| Branch | `step5-billing-integration` |
| Vast checkpoint | [`d89a03512b2f95f7bed3180f40e2451f0737edd8`](https://github.com/thirtyapp/Thirty/commit/d89a03512b2f95f7bed3180f40e2451f0737edd8) |
| Commitbericht | `feat(v2): add Paths, Toolkit and routine maintenance` |
| Productstatus | A–D: PASS — COMPLETE volgens de actuele tracker; E: NOT STARTED |
| Auditmethode | Contract, actuele broncode, ADR's, testcode, scenariofixtures en gerapporteerde QA; daarna historische vergelijking |
| Uitvoering | Geen productbestanden gewijzigd; geen stage, commit, push, fixes of Phase E uitgevoerd |

De branch en volledige commitidentiteit zijn via GitHub gecontroleerd. Alle actuele broncodebevindingen verwijzen naar dit vaste checkpoint, niet naar een latere branchstand. Het PRODUCT_V2_CONTRACT is leidend; oudere Plans/Coach/Insights-documenten bepalen V2 niet.

## BLIND VERDICT

**A — READY TO ENTER PRE-RELEASE / COMMERCIAL VALIDATION**

THIRTY is concreet en samenhangend genoeg om de pre-release af te werken en vervolgens het volledige product en betaalde gedrag te toetsen. Dat is geen vrijgave voor publieke lancering, acquisitieschaal of een bewezen doorlopend abonnementsbedrijf.

De 31 scores, hoofdrisico's en dit oordeel zijn vóór de historische vergelijking vastgelegd. Een voorlopige beoordeling zonder GitHub-toegang is vóór Pass 2 vervangen door de definitieve blinde beoordeling met broncode. Historische kritiek heeft de vastgelegde scores niet gewijzigd. Claude's afzonderlijke audit van deze V2 is niet ingezien.

## EXECUTIVE CONCLUSION

**THIRTY is nu een goed opgebouwd product met een geloofwaardige eerste betaaltaak en een zwakke betaalreden voor langdurig stabiele gebruikers.** Productkwaliteit: **7/10**. Commercieel ontwerp: **5/10**. Geschiktheid voor een doorlopend abonnement: **3/10**.

Free doet daadwerkelijk iets bruikbaars: één haalbare activiteit kiezen, de uitvoering ondersteunen en expliciete antwoorden onthouden en laten corrigeren. Premium maakt daar een concreet proces van: onderdelen proberen, een routine samenstellen en die later veranderen. Dat is substantieel meer dan decoratie of losse programmatekst.

De economische spanning zit in wat er ná dat werk overblijft. Routines blijven bruikbaar zonder Premium. Ook onderhoudssignalering en de Toolkit-check blijven toegankelijk. Een gebruiker met twee passende routines en korte varianten krijgt dus veel van de dagelijkse waarde zonder te blijven betalen. Dat is een eerlijke productkeuze, maar maakt het verdienmodel eerder periodieke hulp bij verandering dan vanzelfsprekend permanent onderhoud.

De Week-7-demonstratie toont een echte verbetering van 30 naar 20 minuten. Zij bewijst niet dat zulke verbeteringen vaak voorkomen: de fixture verwerpt eerder expliciet de korte variant die een Path normaal al kan opleveren. De Month-2-fixture toont opgebouwde betaalde waarde, geen bewijs dat een actief abonnement nodig blijft om die waarde te gebruiken.

Meer Paths, AI, visuele perks of meldingen lossen dit bewijsprobleem niet op. De volgende informatie moet komen uit vrijwillig gebruik, concrete betaalkeuzes en later heractivering. Er is geen aangetoonde materiële productreden om daarvoor eerst nog een nieuwe ontwerpronde te eisen.

## EVIDENCE LIMITS

De labels betekenen in dit rapport:

| Label | Betekenis en toepassing |
|---|---|
| **IMPLEMENTED / DIRECTLY VERIFIED** | Aanwezig en statisch gecontroleerd in de code van de exacte commit. Dit betekent hier niet automatisch zelfstandig op een toestel uitgevoerd. |
| **DOCUMENTED / REPORTED** | In tracker/ADR/opdracht gerapporteerd: 1567 tests geslaagd, 0 gefaald/overgeslagen, analyze clean, S25-acceptatie, TalkBack en 14 simulaties met menselijke review. Niet door mij opnieuw uitgevoerd. |
| **DESIGNED / INTENDED** | Normatieve product- of ontwerpkeuze; geen bewijs van werking of gebruikerswaarde. |
| **COMMERCIAL HYPOTHESIS** | Oordeel over vraag, ervaren waarde, terugkeer, betalen, onderhoudsfrequentie of economie. Geen gemeten resultaat. |
| **UNKNOWN** | Actuele gebruikerscohorten, echte betaalbereidheid, conversie, vrijwillige verlenging, heractivering, acquisitiekosten en operationele marge. |

De twee afbeeldingen zijn bekeken als oudere visuele referenties. Geen van beide is herleid tot de volledige V2-flow op deze commit. De in ADR-022 genoemde devicebeelden en reviewpacks staan niet in de geraadpleegde repositorytree. De score voor emotionele ervaring/toegankelijkheid heeft daarom lage zekerheid; dit is geen volledige visuele of toegankelijkheidscertificering.

Paced heeft een runtime en interne QA, maar geen live, goedgekeurd pacingpatroon in de onderzochte catalogus. De catalogus telt 21 definities: 16 live, vier safety-pending en één retired. De safety-pending inhoud mag niet als geleverd voordeel worden opgevoerd. Dynamische seizoenen, persoonlijke World-groei en Premium Atmosphere tellen evenmin als bestaande V2-retentiewaarde.

Een gescripte QA-gebruiker bewijst dat een toestand bereikbaar is. Hij bewijst niet hoe vaak echte mensen daar terechtkomen. Een gesloten Circle bewijst geen uitgevoerde activiteit; een ontbrekend antwoord is geen negatief resultaat.

**Bronregister voor actuele bevindingen** — alle GitHub-links zijn vastgezet op dezelfde commit:

| Ref. | Bron |
|---|---|
| S1 | [PRODUCT_V2_CONTRACT](https://github.com/thirtyapp/Thirty/blob/d89a03512b2f95f7bed3180f40e2451f0737edd8/docs/product/PRODUCT_V2_CONTRACT.md) |
| S2 | [THIRTY_V2_DELIVERY_TRACKER](https://github.com/thirtyapp/Thirty/blob/d89a03512b2f95f7bed3180f40e2451f0737edd8/docs/product/THIRTY_V2_DELIVERY_TRACKER.md) |
| S3 | [ADR-020: aanbevelingen](https://github.com/thirtyapp/Thirty/blob/d89a03512b2f95f7bed3180f40e2451f0737edd8/docs/product/adr/ADR-020-v2-phase-b-recommendation-engine.md), [ADR-021: Circle/Memory](https://github.com/thirtyapp/Thirty/blob/d89a03512b2f95f7bed3180f40e2451f0737edd8/docs/product/adr/ADR-021-v2-phase-c-circle-experience-and-memory.md), [ADR-022: Premium](https://github.com/thirtyapp/Thirty/blob/d89a03512b2f95f7bed3180f40e2451f0737edd8/docs/product/adr/ADR-022-v2-phase-d-paths-toolkit-and-maintenance.md) |
| S4 | [Recommendation engine](https://github.com/thirtyapp/Thirty/blob/d89a03512b2f95f7bed3180f40e2451f0737edd8/lib/features/home/domain/recommendation_engine.dart), [policy](https://github.com/thirtyapp/Thirty/blob/d89a03512b2f95f7bed3180f40e2451f0737edd8/lib/features/home/domain/recommendation_policy.dart), [activity catalog](https://github.com/thirtyapp/Thirty/blob/d89a03512b2f95f7bed3180f40e2451f0737edd8/lib/features/home/application/activity_catalog.dart) |
| S5 | [Path catalog](https://github.com/thirtyapp/Thirty/blob/d89a03512b2f95f7bed3180f40e2451f0737edd8/lib/features/toolkit/domain/path_catalog.dart), [module library](https://github.com/thirtyapp/Thirty/blob/d89a03512b2f95f7bed3180f40e2451f0737edd8/lib/features/toolkit/domain/module_library.dart), [Path engine](https://github.com/thirtyapp/Thirty/blob/d89a03512b2f95f7bed3180f40e2451f0737edd8/lib/features/toolkit/domain/path_engine.dart) |
| S6 | [Maintenance](https://github.com/thirtyapp/Thirty/blob/d89a03512b2f95f7bed3180f40e2451f0737edd8/lib/features/toolkit/domain/maintenance.dart), [Toolkit policy](https://github.com/thirtyapp/Thirty/blob/d89a03512b2f95f7bed3180f40e2451f0737edd8/lib/features/toolkit/domain/toolkit_policy.dart) |
| S7 | [Toolkit provider](https://github.com/thirtyapp/Thirty/blob/d89a03512b2f95f7bed3180f40e2451f0737edd8/lib/features/toolkit/application/toolkit_provider.dart), [Toolkit page](https://github.com/thirtyapp/Thirty/blob/d89a03512b2f95f7bed3180f40e2451f0737edd8/lib/features/toolkit/presentation/toolkit_page.dart), [routine detail](https://github.com/thirtyapp/Thirty/blob/d89a03512b2f95f7bed3180f40e2451f0737edd8/lib/features/toolkit/presentation/routine_detail_page.dart) |
| S8 | [QA-scenario's](https://github.com/thirtyapp/Thirty/blob/d89a03512b2f95f7bed3180f40e2451f0737edd8/lib/core/qa/qa_scenario.dart), [Premium-simulatietests](https://github.com/thirtyapp/Thirty/blob/d89a03512b2f95f7bed3180f40e2451f0737edd8/test/features/toolkit/premium_simulation_test.dart), [maintenance-tests](https://github.com/thirtyapp/Thirty/blob/d89a03512b2f95f7bed3180f40e2451f0737edd8/test/features/toolkit/domain/maintenance_test.dart) |
| S9 | [Premium offer page](https://github.com/thirtyapp/Thirty/blob/d89a03512b2f95f7bed3180f40e2451f0737edd8/lib/features/premium/presentation/premium_offer_page.dart) |
| H1 | THIRTY V1 PRODUCTIZATION + COMMERCIAL REVIEW, 6 september 2026; relevante delen van §§1, 4, 7–8, 26–27 en 41–43 na de blinde lock gelezen |
| H2 | Aangeleverde recurring-Premium-freeze van 6 september, met addendum 8 september; vooral §§1, 3, 5, 13–20, 23–27, 31–33 en 38 |
| H3 | Aangeleverde Product Direction & Scope Delta, V1 Pre-release Tracker en Premium Strategy; historische context |

## SCORECARD

Schaal: 0 = afwezig/onhoudbaar; 5 = bruikbaar maar beperkt; 10 = uitzonderlijk sterk onderbouwd. Scores beoordelen het huidige ontwerp en beschikbare bewijs. Vooral commerciële scores zijn geen voorspelde conversiepercentages. HIGH/MEDIUM/LOW geeft zekerheid van het oordeel weer, niet de kwaliteit van de documentatie. Geen totaalgemiddelde maskeert de zwakke abonnementswaarde.

| # | Dimensie | Score | Zekerheid | Reden |
|---|---|---:|---|---|
| 1 | Core problem clarity | 8 | HIGH | Eén concrete taak: kiezen wat helpt en ermee beginnen; doelgroep nog breed. |
| 2 | Core problem importance | 5 | LOW | Herkenbare frictie; ernst en installatiemotivatie onbekend. |
| 3 | Free product value | 7 | MEDIUM | Selectie, uitvoering en corrigeerbaar geheugen vormen een geheel. |
| 4 | Day-1 value | 6 | MEDIUM | Directe keuzehulp; nog weinig persoonlijk. |
| 5 | Day-7 value | 7 | LOW | Feedback kan merkbaar helpen; weinig data bij intermitterend gebruik. |
| 6 | Day-30 value | 6 | LOW | Bruikbaar ritueel mogelijk; ook makkelijk te vervangen of vergeten. |
| 7 | Recommendation quality | 7 | MEDIUM | Verdedigbare tijdsfit en selectie; relevantie niet gemeten bij gebruikers. |
| 8 | Personalization credibility | 7 | MEDIUM | Expliciete signalen; enkele teksten suggereren breder begrip. |
| 9 | Simplicity | 6 | MEDIUM | Eenvoudige dagflow, meer begrippen in Premium. |
| 10 | Emotional experience | 7 | LOW | Rustige intentie en interactie; volledige actuele visuele ervaring niet getest. |
| 11 | Trust | 7 | MEDIUM | Goede controle/eigendom; beperkte overclaim bij persoonlijke resultaten en checks. |
| 12 | Accessibility / robustness | 7 | LOW | Concrete gerapporteerde QA; niet zelfstandig herhaald op apparaat. |
| 13 | Differentiation | 6 | MEDIUM | Herkenbare combinatie, kopieerbare onderdelen. |
| 14 | Free retention potential | 6 | LOW | Vrijwillige terugkeer plausibel; geen cohortbewijs. |
| 15 | Premium value | 6 | MEDIUM | Begeleide routinevorming en verandering zijn echte extra taken. |
| 16 | Premium differentiation | 6 | MEDIUM | Bouwen/aanpassen is extra; signalering en gebruik blijven Free. |
| 17 | Path value | 6 | MEDIUM | Concreet resultaat; inspanning en tijdsvensters kunnen te groot zijn. |
| 18 | Toolkit value | 6 | MEDIUM | Eigen combinaties kunnen waarde hebben; meerwaarde boven favorieten onbewezen. |
| 19 | Routine ownership value | 9 | HIGH | Bruikbaar bezit en controle blijven na opzegging. |
| 20 | Maintenance value | 5 | MEDIUM | Werkelijke maar smalle herstelmechanismen; frequentie onbekend. |
| 21 | Week-7 paid value | 6 | MEDIUM | Concrete 30→20-minutenverbetering; geselecteerde situatie. |
| 22 | Month-2 paid value | 6 | MEDIUM | Betaalde opbouw zichtbaar; daarna is dagelijks gebruik ook Free. |
| 23 | Month-6 paid value | 2 | MEDIUM | Bij passende routines is weinig nieuw betaald werk aannemelijk. |
| 24 | Stable-user proposition | 2 | HIGH | Ook gebruik, signalering en checks vereisen geen actief Premium. |
| 25 | Subscription-worthiness | 3 | MEDIUM | Periodieke betaalde hulp overtuigt meer dan continu verlengen. |
| 26 | Commercial differentiation | 4 | MEDIUM | Gemak mogelijk verkoopbaar; geen bewezen betaalvoorsprong. |
| 27 | Content scalability | 8 | HIGH | Herbruikbare modules, geen productie per gebruiker. |
| 28 | Founder-labor scalability | 6 | LOW | Product schaalt; acquisitie/support/platformwerk onbewezen. |
| 29 | Pre-release readiness | 7 | MEDIUM | Gereed om te valideren; bestaande releasepoorten blijven open. |
| 30 | Overall product quality | 7 | MEDIUM | Coherent product met echte implementatie; geen runtimecertificaat. |
| 31 | Overall commercial design strength | 5 | MEDIUM | Eerste betaaltaak geloofwaardig, herhaaleconomie zwak. |

## CORE PROBLEM

**MODERATE PROBLEM.** Vermoeidheid, een vol hoofd en behoefte aan rust zijn herkenbaar. Het nauwere probleem dat THIRTY kan oplossen is de beslissing op dat moment: wat zal ik nu doen, hoe begin ik en wat paste eerder?

Die frictie kan dagelijks terugkomen zonder dat iemand dagelijks een aparte app nodig heeft. Een vertrouwde wandeling, een eigen notitie of niets doen kan al voldoende zijn. Installatie vraagt dus méér dan herkenning van het ongemak: iemand moet het prettig vinden om de keuze herhaaldelijk uit te besteden.

De meest plausibele eerste doelgroep is een toetsbare hypothese: mensen die wél iets willen doen, maar bij kleine welzijnskeuzes vastlopen en weinig zelfzorgadministratie willen. Voor iemand die zijn werkende routine al kent, is het probleem veel zwakker. Eén passende activiteit kan helpen; gezondheidseffecten en effectgrootte zijn niet aangetoond.

## FREE PRODUCT

Free is een serieus zelfstandig product. De extra waarde zit in de koppeling van kiezen, uitvoeren en corrigeren. De gebruiker kiest behoefte en tijd; de app kiest de activiteit en geeft praktische begeleiding. Een mismatch heeft één herstelroute, geen eindeloze catalogus. [S1, S3–S4]

De selector gebruikt expliciete antwoorden, meerdere passende behoeften, tijdsgrenzen, recent gebruik en begrensde negatieve informatie. Negatieve evidence vervalt; een tijdelijke rust is iets anders dan het blijvende Don't suggest. Memory laat fouten herstellen. Dat kan daadwerkelijk betere keuzes opleveren dan willekeurige rotatie. Het blijft een beperkte, zelfgerapporteerde voorkeurshistorie.

De natuurlijke duur is een wezenlijke verbetering tegenover een universeel halfuur. De gebruiker hoeft niet te betalen om een haalbare activiteit of behoorlijke uitleg te krijgen. World-beelden en het rustige Circle-ritueel ondersteunen herkenning, maar zijn geen bewijs van actie of terugkeer.

**Als Premium verdween, zou Free voor een geschikte groep het bewaren waard zijn.** Of die groep groot genoeg is en werkelijk blijft terugkomen, is onbekend.

### Day 1

**6/10.** De echte waarde is directe keuzevermindering: een concrete handeling binnen de gekozen tijd, een eerste stap en een rustig begin/einde. Zonder geschiedenis is de inhoud noodzakelijk grotendeels generiek. Betere verpakking verandert dat niet in persoonlijke kennis.

**Wat zou ik missen als THIRTY na dag 1 verdween?** Een gemakkelijke overgang van “ik wil iets doen” naar één uitvoerbare keuze. Nog nauwelijks iets dat alleen deze app voor mij kan bewaren.

### Day 7

**7/10 als ontwerppotentieel, met lage zekerheid.** Zeven kalenderdagen kunnen slechts drie bezoeken en één antwoord per behoefte betekenen. Dan is een grote leerclaim onterecht. Bij enkele duidelijke antwoorden kunnen voorkeurskeuzes, tijdelijke rust en begrijpelijke redenen wel zichtbaar veranderen.

Memory is waardevol wanneer iemand een concrete vergissing corrigeert of herkent wat is onthouden. Een informatiescherm op zichzelf bewijst geen ervaren personalisering.

**Wat zou ik missen?** De paar bruikbare ervaringen en afwijzingen die THIRTY al voor mij meeneemt, plus het ritueel. Bij weinig feedback kan het nog steeds voelen als willekeurige welzijnstips.

### Day 30

**6/10.** Er kan voldoende bewijs zijn voor betere herhaling, maar alleen bij werkelijk gebruik en antwoorden. De app kent geen breed persoonlijk profiel. Minder besliswerk kan duurzaam waardevol zijn, ook als de activiteiten bekend worden.

Het grootste risico is dat de gebruiker de paar passende activiteiten leert en de app niet meer nodig heeft. Geen streaks betekent minder kunstmatige terugkeerdruk. Dat is verdedigbaar; THIRTY moet daardoor sterker op ervaren nut en een vrijwillig gekozen reminder steunen. Dertig dagen verstreken zijn geen bewijs van dertig dagen waarde.

## PREMIUM PRODUCT

De grens is inhoudelijk echt:

- Free helpt vandaag kiezen en uitvoeren.
- Premium begeleidt het bouwen en veranderen van persoonlijke routines.

Die grens is duidelijker dan de oude drie pijlers Plans, Coach en Insights. De offer page beschrijft zeven Circles, eigen routines en upkeep. [S9]

Een belangrijke precisering: **Premium verkoopt vooral het uitvoeren van verandering.** In de onderzochte code zijn bestaande routines, eigendomscontroles, onderhoudsaanbiedingen en de Toolkit-check niet aan een actieve entitlement gebonden. Alleen “de app blijft opletten” is daarom geen onderscheidende betaalreden. [S6–S7]

## USEFUL / PREMIUM-WORTHY / SUBSCRIPTION-WORTHY

| Vraag | Oordeel | Waarom |
|---|---|---|
| USEFUL? | **JA** | Begeleide experimenten en een passende combinatie kunnen besliswerk besparen. |
| PREMIUM-WORTHY? | **PLAUSIBEL JA, voor een subset** | Het opbouwen of verbeteren van een concrete routine kan een betaalde taak zijn. |
| SUBSCRIPTION-WORTHY? | **ZWAK voor continu gebruik; plausibel tijdens veranderperiodes** | Een passende Toolkit vermindert de noodzaak van verder betaald werk. |

Geen van deze oordelen bewijst de grootte van de betalende groep of rendabele acquisitie.

## INITIAL PURCHASE REASON

De sterkste koopreden is: **“Deze situatie komt steeds terug; ik wil dat THIRTY met mij iets opbouwt dat ik dan kan gebruiken.”** Bijvoorbeeld een werkbare reset voor een vol hoofd. Het gewenste eindresultaat komt vóór het productwoord Path.

“Ik wil een Path” is eerder nieuwsgierigheid. “THIRTY moet zich aanpassen” is te abstract vóór iemand het verschil ziet. Steun aan het product kan voorkomen, maar is geen solide commerciële basis.

De huidige startpagina's noemen het resultaat en de tijd. Dat maakt de belofte concreter. De onzekere vraag is of de gebruiker zeven ontmoetingen nodig en aantrekkelijk vindt voor iets wat ook in enkele minuten zelf te ontwerpen lijkt.

## PATHS

Alle zes gebruiken dezelfde basismethode en een pool van drie bestaande modules. Feedback verandert de volgorde, behandeling of combinatie binnen die kleine pool. Het is begrensde aanpassing, geen open zoektocht naar een unieke persoonlijke methode. [S5]

Onderstaande voltooiingsinschattingen zijn relatief en hypothetisch, geen gemeten percentages.

| Path | Job en aantrekkelijkheid | Gedragsverschil en aanpassing | Zeven Circles, verwachte afronding en resultaatwaarde |
|---|---|---|---|
| **A lift at home** | Heldere, laagdrempelige behoefte aan beweging thuis. | Rekken, bewegen op muziek en een actieve taak verschillen merkbaar. Feedback kan een andere combinatie rechtvaardigen. | Relatief beste afrondingskans; lage opstartfrictie. Zeven is nog steeds veel voor een eenvoudige combinatie. Waarde middelmatig tot goed als de gekozen mix prettig blijkt. |
| **Out the door** | Naar buiten gaan is helder; een eigen brisk-walk-routine minder noodzakelijk voor wie al wandelt. | Brisk walk, korte stretch en telefoonvrij wandelen. Overlap met bestaand Free-wandelen. | Afronding waarschijnlijk afhankelijk van gelegenheid en tijd. Zeven sessies lijken relatief zwaar. Resultaatwaarde middelmatig; “ga wandelen” blijft een sterke goedkope vervanger. |
| **Clear the decks** | Het concreetste probleem en resultaat: gedachten op papier, één ruimte op orde. | Schrijven en opruimen zijn complementair; stretch is alternatief. De volgorde kan een betekenisvolle reset vormen. | Zeven heeft hier de beste verdedigbare testfunctie, nog onbewezen. Middelmatige afrondingskans; relatief sterkste reden om de routine te bewaren. |
| **Away from the screen** | Relevante aanleiding, maar “minder input” wordt niet automatisch waargemaakt door luisteren. | Telefoonvrij wandelen, één ding luisteren en schrijven; overlap met andere Paths. | Laagste verwachte afronding onder tijdsdruk: elke tweedelige combinatie vraagt minstens 25 minuten. Zeven is moeilijk te verkopen voor zo'n herkenbare oplossing. Resultaatwaarde onzeker. |
| **A soft landing** | Rust thuis is eenvoudig te begrijpen en gemakkelijk te organiseren. | Warme drank, zacht rekken, rustige muziek. Aangenaam, maar veel gebruikers kennen deze middelen al. | Redelijke afrondingskans bij voldoende tijd. Meerdere herhalingen kunnen voorkeur tonen; zeven kan als omweg voelen. Middelmatige waarde, beperkt onderscheid van een eigen avondritueel. |
| **Easy time outdoors** | Naar buiten zonder prestatiedoel is begrijpelijk. | Rustig wandelen, buiten zitten en zacht rekken. Verschilt in tempo van Out the door, maar overlapt in context en middelen. | Tijd en buitenmogelijkheid beperken afronding. Zeven zwak gerechtvaardigd voor ervaren wandelaars. Middelmatige waarde voor beginners, lage extra waarde voor zelfstandige gebruikers. |

**STRONGEST:** Clear the decks. **WEAKEST:** Away from the screen. **MOST DISTINCT:** Clear the decks. **MOST REDUNDANT:** Easy time outdoors ten opzichte van andere wandel-/buitenopties. Dit beoordeelt de productlogica, niet individuele smaak.

Een concreet spanningspunt is de tijd. De zes poolminima voor een combinatie van twee verschillende onderdelen zijn respectievelijk **10, 20, 15, 25, 20 en 20 minuten**, afgeleid uit de authored short-duren. Alleen A lift at home kan een tweedelige combinatie binnen 10 minuten maken. De centrale schrijf-plus-opruimcombinatie van Clear the decks vraagt minstens 20 minuten.

Away from the screen past als combinatie nooit in het standaardvenster van 20 minuten. Met 10/20/30 als keuzes betekent dit een dag met 30 minuten kiezen. De UI noemt benodigde tijd en de engine wacht terecht in plaats van kunstmatig af te snijden. Het is dus geen bewezen verborgen blokkade, wel een belangrijke frictiehypothese: Premium kan méér tijd vragen dan de Free-waarde waarmee iemand binnenkwam.

Aanpassing kan ook de oorspronkelijke job vervagen wanneer een karakteristiek onderdeel vervangen wordt. Controleer of de gebruiker de uiteindelijke routine nog herkent als wat hij wilde bouwen; voeg daarvoor geen extra Paths toe.

## SEVEN-CIRCLE QUESTION

**Zeven is verdedigbaar als experimentopzet, niet bewezen als juiste lengte.**

| Circle | Informatiewaarde |
|---|---|
| 1–2 | Onderdelen apart en kort proberen. |
| 3 | Een beter passend onderdeel volledig proberen, of een alternatief. |
| 4 | Een combinatie ervaren. |
| 5 | Bevestigen of na negatieve feedback de partner veranderen. |
| 6 | Een kortere vorm of andere combinatie proberen. |
| 7 | De uiteindelijke vorm nogmaals ervaren en beoordelen. |

[S5] Niet iedere Circle voegt een nieuw onderdeel toe. Herhaling kan variatie tussen dagen onderscheiden van een eenmalige reactie, maar de engine verricht geen wetenschappelijk experiment. Zonder antwoord ontstaat geen extra bewijs van nuttigheid.

Progressie volgt gesloten Path-Circles; geen zeven verplichte dagen en geen bewijs van zeven daadwerkelijk uitgevoerde activiteiten. Ook zonder antwoorden kan een routine ontstaan. Dan is het resultaat vooral een voorgestelde compositie, niet een aangetoond passend persoonlijk recept.

De gebruiker hoeft de routine niet te “verdienen”. De maatstaf is of elke vervolgstap de moeite waard voelt. De huidige opzet kan werken zonder gamification, mits het doel van het volgende experiment begrijpelijk blijft. Verander de lengte nog niet op basis van deze desk-audit; onderzoek waar mensen afhaken en of zij het resultaat dan al voldoende vinden.

## MODULE LIBRARY

**13 modules zijn voldoende om deze beperkte hypothese te testen.** Beweging, wandelen, schrijven, opruimen, luisteren, warm drinken en buiten zitten bieden betekenisvolle verschillen. Er is overlap en het bereik blijft algemeen welzijn. [S5]

Short/full/combined is meer dan een andere timer: er zijn authored kortere behandelingen, vaste vormen waar verkorten niet eerlijk kan, en gecombineerde uitvoering. Een kortere routine bewaart alle onderdelen in dezelfde volgorde. Dit beschermt haar identiteit.

Premium bundelt echter wel degelijk Free-inhoud. De extra waarde moet komen uit proberen, kiezen, samenvoegen en onthouden. De oefeningen zelf zijn geen exclusief bezit. Repetitie wordt herkenbaar; voor werkende routines is dat normaal. Voor iemand die betaalde ontdekking verwacht, wordt het snel mager.

Zes maanden zonder nieuwe modules kunnen echte gebruikswaarde opleveren. Zes maanden onafgebroken betaald werk volgen daar niet uit.

## TOOLKIT

**Waarom zou ik om mijn Toolkit geven?** Omdat daar een paar combinaties staan waarvan ik uit ervaring weet wanneer ze passen, inclusief een korte variant en de mogelijkheid terug te keren naar een eerdere versie.

Dat gaat verder dan een favoriet als samenstelling, volgorde, duur en eigen ervaring verschil maken. Zonder betekenisvolle feedback of herhaald gebruik blijft het dicht bij een opgeslagen standaardcombinatie. Een eigen naam maakt iets herkenbaar, niet automatisch waardevol.

Twee à drie routines kunnen de drie brede behoeften al ruim bedienen. Dat is goed voor de gebruiker en beperkt de verdere bouwmarkt. Zes à acht kunnen keuze- en onderhoudsrommel veroorzaken. Het gap-mechanisme stopt onder andere bij zes bestaande routines; dat is geen bewijs dat zes het ideale aantal is.

Versies zijn nuttig als herstelmogelijkheid: “de vorige werkte beter”. Een versienummer op zichzelf is implementatiedetail. Het emotionele moment zit in het herkennen en bewaren van een bruikbaar resultaat, niet in het beheren van objecten.

## ROUTINE OWNERSHIP

**Een sterke, commercieel verdedigbare keuze: 9/10 gebruikerswaarde.** [S7] Routines blijven na afloop leesbaar, aanpasbaar via eigendomscontroles en bruikbaar in Free-aanbevelingen. Dat verlaagt aankooprisico en vermijdt afhankelijkheid door verliesdreiging.

Het retentienadeel is echt: iemand kan klaar zijn, opzeggen en de waarde blijven gebruiken. Het mogelijke conversie- en heractiveringsvoordeel is ook echt als hypothese. Welke kant economisch overheerst is onbekend.

Dit is verstandig voor een dienst die opnieuw verdiende betaalmomenten accepteert. Het is ongemakkelijk voor een bedrijfsplan dat brede, ononderbroken maandelijkse betaling nodig heeft. Verander de eigendomsbelofte niet om die spanning te verbergen.

## ROUTINE FREQUENCY

**CLOSED-TEST QUESTION.**

Routines krijgen terecht geen betaalbonus in de selector. De ongeveer wekelijkse frequentie bij veel passende kandidaten komt uit gerapporteerde simulaties, niet uit een echte gebruikersverdeling. [S3–S4]

Er is een plausibele verwachtingbotsing: zeven Circles investeren en het resultaat vervolgens weinig zien. De tegenovergestelde uitleg kan ook werken: THIRTY kiest de routine wanneer die werkelijk past. De routinepagina heeft in de onderzochte flow geen vrij startmenu; de normale uitvoering blijft via Today. De gebruiker kan de instructies wel lezen en zelfstandig uitvoeren.

Meet zowel kansen als verwachtingen: hoeveel dagen paste behoefte én tijd, hoe vaak werd de routine aangeboden, en vond de eigenaar dat voldoende? Weinig verschijningen in een weinig passende week is iets anders dan het structureel passeren van een passende, gewaardeerde routine. Voeg vooraf geen frequentieschuif of rankingbonus toe.

## MAINTENANCE

Onderhoud is geïmplementeerd en terughoudend: één aanbieding, voorrang voor tijdsmisfit, daarna fading en gap; geen nieuwe aanbieding zolang een Path openstaat; 21 dagen rust na afwijzen. De waarden zijn tunables, geen empirisch optimale drempels. [S6]

De commerciële beoordeling moet drie stappen uit elkaar houden: een geldig signaal, een nuttige voorgestelde verandering en bereidheid daarvoor te betalen. Code kan het eerste onderbouwen, soms het tweede demonstreren, en het derde niet bewijzen.

### Fading

De code zoekt expliciete verslechtering na eerdere positieve antwoorden. Er zijn minstens drie relevante beoordelingen nodig. De laatste drie gebruiksantwoorden met totaalscore ≤0, de laatste twee ≤−1, of een laatste Not useful na minstens twee positieve antwoorden kunnen een signaal geven. De scores zijn Very +2, Somewhat +1, Not −2.

De actuele broncode maakt een relevante nuance: bouwantwoorden kunnen aantonen dat een versie eerder paste en tellen mee in de brede bewijsset; het recente verslechteringsvenster gebruikt routinegebruik buiten het bouw-Path. De korte ADR-samenvatting dat bouw-Circles niet meetellen is dus niet de volledige uitleg. [S6, routineStanding]

Een tune-up van drie Circles vervangt een onderdeel en laat het resultaat proberen. Dat kan als service voelen voor iemand die merkt dat een bekende combinatie niet meer helpt en zelf niet wil puzzelen. Eén minder goede dag kan ook stemming, context of toeval weerspiegelen; de app weet de oorzaak niet.

De frequentie is vermoedelijk beperkt: de routine moet verschijnen, worden geprobeerd, beoordeeld en voldoende duidelijke verslechtering tonen. Zelden gebruikte routines leveren weinig onderhoudsbewijs. **Werkelijk mechanisme, onbewezen terugkerende betaaltaak.**

### Time misfit

**Het sterkste begrijpelijke onderhoudsmechanisme.** Minstens vier van de laatste zes dagen voor dezelfde behoefte binnen 28 dagen hebben minder tijd dan de routine nodig heeft; geen bestaande korte versie dekt dat; een eerlijke kortere combinatie moet mogelijk zijn. [S6]

De verbetering is concreet: dezelfde routine past weer. Alle onderdelen blijven behouden, met authored verkortingen. Dit is beter dan willekeurig een deel schrappen en dezelfde naam laten staan.

De begrenzing is eveneens concreet. Een Path levert vaak al een korte versie. Sommige modules kunnen niet korter. Een tweedelige routine kan nog steeds te lang zijn voor tien minuten. Het systeem kent tijdkeuzes op bezoekdagen, niet iemands volledige weekplanning.

De formulering “most days lately” is daardoor breder dan het bewijs: het gaat om waargenomen dagen voor deze behoefte. Dit is een gerichte nauwkeurigheidskwestie in de copy. De betalingsvraag blijft of behoud van beide onderdelen plus een begeleide proef voldoende beter is dan vandaag gewoon één passende Free-activiteit doen.

### Gap

De trigger is zinvol strenger dan “hier staat nog geen routine”: minstens vijf gekozen dagen voor een behoefte in 28 dagen, minstens drie expliciete antwoorden op gewone Free-keuzes, een gewogen gemiddelde onder 0,5, geen passende toegestane routine en een uitvoerbaar Path. Very telt 1, Somewhat 0,7, Not 0. Minder dan zes routines is een extra begrenzing. [S6]

Dit voorkomt dat stilte of redelijke tevredenheid als verkoopkans wordt behandeld. Het bewijst echter niet dat het combineren van dezelfde middelen de zwakke Free-uitkomst oplost. Misschien passen de activiteiten zelf niet, is de behoefte verkeerd vertaald of wil iemand iets buiten de catalogus.

Een nieuw zeven-Circle-Path is dan een relatief grote interventie. Gap-building lijkt vooral waardevol tijdens vroege uitbreiding naar een tweede of derde behoefte. Met enkele passende routines neemt de ruimte structureel af. **Meer een vroege bouwreden dan een dragende onderhoudsmotor op lange termijn.**

### User initiated

Tune en Make shorter kunnen een concrete behoefte direct bedienen zonder op detectiedrempels te wachten. Dat is potentieel waardevoller dan passief wachten op een algoritmisch signaal. [S5, S7]

“Refresh” is geen zelfstandig derde proces in de onderzochte implementatie; de acties zijn tune-up en korter, telkens als een begrensd drie-Circle-proces. Ze bieden geen vrije editor of onbeperkte inhoud.

Voor iemand die begeleiding wil, kan dit een heractivering rechtvaardigen. Wie al weet welk onderdeel hij wil weglaten of hoe hij korter wil oefenen, kan het zelf sneller doen. Direct onderhoud kan episodische Premium-waarde dragen; het maakt de behoefte niet automatisch maandelijks.

### Stable check

De check komt ongeveer elke 28 dagen, zonder actief Path. Met voldoende positieve antwoorden en geen Not useful kan hij zeggen: “Your routines are working well — nothing to change.” [S6]

**Er is een concrete bewijsgrens in de code:** de check telt minimaal drie beoordeelde routinegebruiken samen over de Toolkit. Hij vraagt niet per routine of per huidige versie om voldoende bewijs. Met twee routines en drie positieve antwoorden over slechts één routine kan de tekst dus over “your routines” spreken. Dat is statisch afleidbaar; het scenario is niet op een toestel door mij gereproduceerd.

Het principe “geen werk verzinnen” is goed. Deze formulering is ruimer dan gerechtvaardigd en verdient een kleine bewijs- of copycorrectie in de bestaande afwerking. Zij is geen reden om een nieuw onderhoudssysteem te ontwerpen of de gehele validatie uit te stellen.

Commercieel is het zowel A als B: eerlijkheid kan de relatie versterken, én duidelijk maken dat Premium momenteel weinig te doen heeft. Bovendien is de check ook na lapse beschikbaar. Hij kan daarom niet overtuigend als exclusief betaald toezicht gelden.

## WEEK 7

**Wat Premium precies doet:** een bestaande Clear the decks-routine van 30 minuten krijgt een versie van 20 minuten met dezelfde twee onderdelen: Write it down en Clear one surface, elk van 15 naar 10 minuten. Drie Circles laten deze kortere vorm proberen, waarna de gebruiker haar kan bewaren en Free haar opnieuw kan aanbieden. [S8, Week-7-fixture en SIM 3]

De fixture bouwt eerst een routine op dagen met 30 minuten. De korte proef in Circle 6 wordt expliciet als Not useful beoordeeld. Daardoor wordt die korte versie niet meteen behouden. Later worden herhaaldelijk 20-minutenkeuzes ingevoerd; dan ontstaat de onderhoudsaanbieding.

Dit is een goede functiedemonstratie en een selectief commercieel voorbeeld. De uitzondering — de korte versie eerder afwijzen — is relevant, omdat het bouw-Path anders vaak meteen een korte variant bewaart. Het scenario mag niet worden gelezen als “rond week zeven ontstaat vanzelf betaalde waarde”.

**Zou de gebruiker het merken?** Waarschijnlijk wel als die combinatie belangrijk voor hem is: hij hoeft haar niet meer over te slaan. **Zou Free het bijna even goed oplossen?** Mogelijk: Free kan een passende schrijf- of opruimactiviteit kiezen. Het verschil is het behouden van beide onderdelen als eigen routine, plus begeleide verificatie.

**Betaalde scenario-waarde: 6/10.** Een plausibel betaalmoment, zonder bewijs van voldoende frequentie of bereidheid drie proeven te doen voor deze relatief eenvoudige aanpassing.

## MONTH 2

De werkelijke fixture bevat opgebouwde Free-historie, een eerste A lift at home-routine, zwakke Free-antwoorden voor Clearer Head, een gap-build naar een tweede routine en vervolgens een kortere versie na herhaalde keuzes van 20 minuten. Een oude comment noemt tien minuten; de relevante code gebruikt twintig. [S8, _monthTwo]

| Onderdeel | Wat de fixture toont | Wat een actief abonnement toevoegt |
|---|---|---|
| Twee routines | Resultaten van eerder betaald bouwwerk. | Nieuwe opbouw vereiste Premium; bezit en gebruik nu niet. |
| Dagelijks aanbod | Voorbeelden van gewone en korte routines in Today. | Geen Premium-rangbonus of exclusieve toegang. Dit bewijst geen dagelijks organisch gebruik. |
| Tune-up | Geen afzonderlijke lopende tune-up aangetoond in deze toestand. | Niet als extra maand-2-waarde meetellen. |
| Kortere variant | Concrete betaalde wijziging van de tweede routine. | Wel extra werk tijdens het maakproces; daarna blijvend Free bruikbaar. |
| Gap-build | Een tweede behoefte werd eerder via een nieuw Path bediend. | Echte extra bouwtaak, waarschijnlijk vooral vroege uitbreiding. |
| Stable check | Onderdeel van de beschikbare logica. | Geen exclusief Premium-voordeel; niet elk denkbaar checkresultaat zit in deze fixture. |

Een deel van de geschiedenis wordt rechtstreeks in de QA-toestand ingevoerd. Dit is een samengestelde demonstratie van bereikbare toestanden, geen organisch twee maanden gevolgd cohort.

**Zichtbaar?** Ja, de routines en kortere variant. **Belangrijk?** Mogelijk, als beide combinaties echt helpen. **Terugkerend?** Niet bewezen; veel waarde is reeds opgebouwd. **Eenvoudig uit te leggen?** “Premium hielp een tweede routine bouwen en korter maken” is duidelijker dan “Premium blijft je elke maand beter begrijpen”.

**6/10 voor de betaalde waarde in dit traject.** Dat is geen 6/10 voor een nieuwe maand huur zodra alles past. Dan levert Free vrijwel dezelfde bestaande dagelijkse gebruikswaarde.

## MONTH 6

**WEAK — 2/10.**

Onder de opgelegde aannames — geen nieuwe inhoud, routines passen redelijk goed, gebruiker kent de app — heeft Premium weinig vanzelfsprekend werk. Het kan een nieuw Path, tune-up of korte variant begeleiden wanneer de gebruiker dat nodig heeft. Die aanleiding mag niet worden verzonnen.

Bij volledige stabiliteit kan de actuele extra betaalde waarde voor een individuele gebruiker **NONE** zijn. Dagelijkse selectie, routinegebruik en signalering blijven bestaan zonder actief Premium. Een blijvende positieve relatie met THIRTY is iets anders dan blijvende vraag naar betaald werk.

## STABLE USER

Voor maandenlange stabiliteit is er geen overtuigende algemene verlengreden. Een gebruiker kan uit waardering of voor beschikbaarheid blijven betalen; de omvang en prijsgevoeligheid van die groep zijn onbekend.

| Model | Structurele fit voor deze gebruiker |
|---|---|
| MONTHLY FIT | Zwak wanneer er geen nieuw werk is. |
| ANNUAL FIT | Alleen plausibel als toekomstige veranderingen of gemak het jaarbedrag echt waard zijn; vooruitbetaling creëert geen nut. |
| PAUSE/RESUME FIT | Sterk qua waardelogica: opnieuw betalen wanneer hulp nodig is. |
| INTERMITTENT PREMIUM FIT | Het beste natuurlijke patroon voor een gebruiker met een passende Toolkit. |

Het stabiele-gebruikerprobleem is **structureel gevaarlijk voor een businesscase met veel continue verlenging**, maar acceptabel voor een rendabel model met losse betaalperiodes en echte heractivering. Het laatste vereist bewijs dat gebruikers terugkomen én dat de acquisitie- en servicekosten over die betaalperiodes gedekt worden.

## SUBSCRIPTION CADENCE FIT

**C — intermittent monthly / pause-resume.**

A, altijd-aan maandelijks, past het minst bij succesvolle afronding zonder verdere veranderbehoefte. B, jaarlijks onderhoud, kan een voorkeur zijn maar is geen oplossing voor weinig werkzaamheden. D, een eindige aankoop, beschrijft de eerste bouwtaak goed, maar mist mogelijke latere begeleide veranderingen. E blijft een mogelijke uiteindelijke verpakking, zonder dat die onduidelijkheid de huidige waardecadans verbergt.

Dit is een structureel oordeel, geen prijs- of billingbesluit. De onderzochte betaalflow gebruikt nog maandelijkse aankoop; een aparte native abonnementspauze of geïmplementeerd jaarplan is hier niet vastgesteld. “Pause/resume” betekent in de economische redenering ook kunnen opzeggen en later opnieuw activeren.

## LAPSE / CANCELLATION

De onderzochte afhandeling beschermt de gebruiker: bestaande routines blijven, eigendomscontroles blijven, een lopend Path bewaart zijn plaats en Free Today werkt door. Nieuwe betaalde Path-stappen vereisen weer actieve Premium-toegang; het vastleggen van een reeds begonnen Circle en bewaren van een afgerond voorstel mogen doorgaan. [S7]

Dit maakt terugkomen eenvoudig en voorkomt dat opzegging verlies wordt. Het maakt ook helder dat het abonnement voor extra werk is. De economische consequentie moet worden geaccepteerd en gemeten.

Een opgeslagen Path pauzeert het abonnement niet automatisch. Billing restore en herstel van lokale routinegeschiedenis zijn eveneens verschillende zaken. Live aankoop, entitlementherstel en commerciële presentatie blijven onderdeel van de bestaande Phase-E-poort; die zijn hier niet opnieuw bewezen.

## FREE / PREMIUM BOUNDARY

“Current” volgt gecontroleerde broncode waar gelezen, anders het huidige contract/ADR. Export, History, reminders en Worlds zijn hier geen volledig opnieuw uitgevoerde end-to-end-controle. [S1, S3–S7]

| CAPABILITY | CURRENT | VERDICT | WHY |
|---|---|---|---|
| Dagelijkse aanbeveling | Free | CORRECTLY FREE | De kerntaak moet zelfstandig werken. |
| Tijdkeuze en tijdsfit | Free | CORRECTLY FREE | Haalbaarheid is basiswaarde. |
| Feedbackleren | Free | CORRECTLY FREE | Geen kunstmatig domme Free-versie. |
| Memory en correctie | Free | CORRECTLY FREE | Gebruiker moet verkeerde aannames herstellen. |
| Aanbevelingsredenen | Free | CORRECTLY FREE | Vertrouwen in de gekozen handeling. |
| Eén replacement | Free | CORRECTLY FREE | Een ongeschikte keuze kunnen herstellen. |
| Circle-uitleg en guidance | Free | CORRECTLY FREE | De activiteit moet uitvoerbaar zijn. |
| Bestaande Worlds | Shared | CORRECTLY FREE | Identiteit en rust zijn geen schaars betaalmiddel. |
| History | Free | CORRECTLY FREE | Eigen gegevens toegankelijk houden. |
| Export/delete | Free | CORRECTLY FREE | Geen datagijzeling. |
| Gewone reminder | Free | CORRECTLY FREE | Ondersteunt de zelfstandige kern. |
| Bestaande routine gebruiken | Free, ook na lapse | CORRECTLY FREE | Betaald resultaat blijft bruikbaar. |
| Routine rename/off/delete/versiekeuze | Free | CORRECTLY FREE | Eigendom omvat normale controle. |
| Nieuw Path starten en doorlopen | Premium | CORRECTLY PREMIUM | Afzonderlijk begeleid bouwproces. |
| Nieuwe routine creëren | Premium-proces | CORRECTLY PREMIUM | Een concreet te leveren resultaat. |
| Nieuwe korte versie maken | Premium-proces | CORRECTLY PREMIUM | Gestructureerde aanpassing, met bestaand gebruik daarna Free. |
| Tune-up uitvoeren | Premium | CORRECTLY PREMIUM | Een routine opnieuw passend maken. |
| Gap-build uitvoeren | Premium | CORRECTLY PREMIUM | Nieuwe bouwtaak, mits behoefte en mogelijke oplossing worden begrepen. |
| Onderhoud detecteren/aanbieden | Ook zonder Premium | CORRECTLY FREE | Een eerlijk signaal en aanleiding voor eventuele heractivering. |
| Onderhoudsverandering uitvoeren | Premium | CORRECTLY PREMIUM | Hier wordt het extra werk verricht. |
| Toolkit check | Ook zonder Premium | CORRECTLY FREE | Geen sterk zelfstandig betaalvoordeel; bereik van de claim moet kloppen. |

**Geen duidelijke verhuizing naar Free of Premium nodig.** De spanning zit in waarde en frequentie, niet in een verkeerd geplaatste basisfunctie. Paywall detectie of routinegebruik niet achteraf om verlenging af te dwingen.

## CHATGPT + NOTES TEST

Het alternatief is serieus. Een gebruiker kan drie routines laten voorstellen, ze aanpassen met eigen feedback, bewaren en reminders zetten. THIRTY heeft geen monopolie op combineren, onthouden in een gesprek of korter maken. Voor een zelfstandige gebruiker kan dit alternatief al genoeg zijn.

THIRTY's voordeel is de geïntegreerde werkwijze: geen terugkerende prompt formuleren, geen losse feedbackadministratie, één dagkeuze, een vaste bewijslogica, corrigeerbaar Memory, begeleide uitvoering en herkenbare routine-identiteit. Worlds kunnen het moment aantrekkelijker maken. Deze samenhang kan betekenisvol zijn voor wie juist van keuzes en administratie af wil.

Veel van dat voordeel zit echter in **Free**. De vergelijking voor Premium is daarom streng: wat voegt het betaalde drie- of zeven-Circle-proces toe boven THIRTY Free plus een zelfbedachte combinatie? Voor sommige mensen begeleide zekerheid en minder denkwerk; voor anderen te weinig.

Andere categorieën bieden elk een alternatief voor een deel van de taak. Habit trackers ondersteunen wat iemand al gekozen heeft; meditatieapps leveren meer diepte in één methode; workoutplanners passen bij een gerichter trainingsdoel; journaling helpt verwoorden; routineplanners organiseren uitvoering; een reminder herinnert aan iets dat al vaststaat. Dit zijn categorieverschillen, geen claims dat iedere app hetzelfde werkt.

Een beperkte controle van primaire bronnen voorkomt overdreven uniekheidsclaims: [Routinery](https://www.routinery.app/features) beschrijft stapsgewijze routinetimers, widgets en startlinks. [Finch](https://help.finchcare.com/hc/en-us/articles/37935669335309-Our-Approach-to-Self-Care) positioneert zich eveneens als een zachte zelfzorgcompanion, met kleine stappen en game-elementen. THIRTY kan zich onderscheiden door zijn combinatie en afwezigheid van prestatiedruk; begeleiding en zachtheid op zichzelf zijn niet uniek. Bronnen geraadpleegd op 10 oktober 2026; geen effectiviteit of marktaandeel uit deze marketingpagina's afgeleid.

## DIFFERENTIATION

| Onderdeel | Classificatie | Beoordeling |
|---|---|---|
| Eén gekozen dagelijkse actie | CORE DIFFERENTIATOR | Consequent beslissingen uit handen nemen. |
| Geen browsecatalogus | CORE DIFFERENTIATOR | Ondersteunt die delegatie; bewust minder keuze. |
| Circle met natuurlijke duur | GENERIC GOOD DESIGN | Goed passend uitvoeringsontwerp; geen verdedigbare voorsprong. |
| Worlds | SUPPORTING DIFFERENTIATOR | Visuele herkenning en sfeer, geen bewezen betaalmotor. |
| Geen druk/streaks | SUPPORTING DIFFERENTIATOR | Belangrijke voorkeur voor een doelgroep, geen unieke claim. |
| Deterministisch leren | NOT DIFFERENTIATING op zichzelf | De techniek merkt de gebruiker niet; betrouwbare resultaten kunnen wel helpen. |
| Editable Memory | SUPPORTING DIFFERENTIATOR | Maakt beperkte personalisering controleerbaar. |
| Routine-eigendom | SUPPORTING DIFFERENTIATOR | Tastbaar vertrouwen en laag aankoopsrisico. |
| Paths | SUPPORTING DIFFERENTIATOR | De route naar een eigen resultaat kan verschillen; guided programs bestaan elders. |
| Onderhoud | CORE DIFFERENTIATOR binnen de Premium-propositie | Concreet bewijs → voorstel → test → aangepaste routine; commerciële sterkte nog onbewezen. |
| Eerlijke opzegging | GENERIC GOOD DESIGN | Hoort te kloppen; de blijvende routine maakt het tastbaar. |

**De werkelijke moat vandaag: geen aangetoonde verdedigbare voorsprong.** De consistente productkeuzes, content en merkidentiteit zijn vroege assets. Er is geen aangetoond netwerkvoordeel, exclusieve distributie of moeilijk kopieerbare persoonlijke technologie. Waardevol en kopieerbaar kunnen tegelijk waar zijn.

## SIMPLICITY

**CALM: grotendeels ja. UNDERSTANDABLE: aannemelijk in Today, nog te testen in Premium. SMALL: alleen in de dagflow.**

Today kan aanvoelen als behoefte → tijd → één activiteit. Memory is secundair en hoeft niet dagelijks geopend te worden. Dat is een goede verdeling.

Premium voegt Path, routine, Toolkit, versie, korte variant, tune-up, offer en check toe. Het systeem is niet meer klein zodra iemand de hele machine moet begrijpen. Progressive disclosure kan dat beperken, maar er is geen gebruikersbewijs dat mensen “een Path loopt”, “een routine is bewaard” en “een onderhoudsaanbieding staat klaar” spontaan onderscheiden.

De toets is de taak in eigen woorden, niet of de documentatie alle begrippen netjes definieert. Een normale gebruiker moet kunnen zeggen wat hij vandaag probeert en wat hij uiteindelijk overhoudt.

## TRUST

**7/10.** Sterk zijn de scheiding tussen Close en werkelijk uitvoeren, optionele antwoorden, aflopende negatieve evidence, tijdelijke rust, harde Don't suggest, correctie via Memory en blijvend routine-eigendom. [S3–S7]

De risico's zitten in impliciete kennisclaims. Een afgerond Path zonder nuttigheidsantwoorden levert geen bewezen persoonlijke routine. “Most days lately” vat slechts geregistreerde behoefte-dagen samen. De stabiele Toolkit-check kan meerdere routines goedkeuren met feedback over maar één.

Dit zijn geen verborgen diagnoseclaims, maar ze kunnen alsnog meer begrip suggereren dan bestaat. Behoud per situatie het onderscheid tussen geprobeerd, zelf nuttig gevonden en nog onvoldoende bekend. Test vooral wat mensen uit de formuleringen afleiden.

## EMOTIONAL EXPERIENCE

Today blijft het meest overtuigende companion-moment: weinig keuze, een haalbare handeling, rustige afronding. De Circle ondersteunt uitvoeren en weggaan van het scherm. Het ontbreken van een prestatiedashboard helpt.

Toolkit kan warm aanvoelen wanneer hij laat zien “dit werkt voor mij”. Hij kan ook welzijnsadministratie worden wanneer versies, onderhoud en volgende stappen domineren. De Premium-pagina is concreter dan de oude pijlers, maar “upkeep” is geen emotioneel aantrekkelijk doel op zichzelf.

Het eindoordeel blijft voorlopig doordat de volledige actuele V2-flow niet op een toestel of in de genoemde screenshotreeks is gecontroleerd. Oudere beelden bewijzen geen geleverde V2-beleving.

## CALMNESS VS COMMERCIAL URGENCY

**Ja, weinig druk kan DAU/WAU, conversie en verlenging verlagen.** Dat is een hypothese met een duidelijke oorzaak: er is weinig verlies, schuld of onafgerond werk dat iemand terugtrekt.

De afweging is overleefbaar als terugkeer op de juiste momenten echte verlichting geeft. Dagelijks gebruik is niet voor iedereen het doel. Meet betekenisvolle vrijwillige terugkeer over weken en rond hernieuwde behoefte, met reminders en persoonlijk testercontact apart zichtbaar.

Rust is geen bewijs van retentie; meer druk is evenmin een passende oplossing. Als alleen aansporen het product levend houdt, faalt de onderliggende waardepropositie voor die groep.

## CONTENT-TREADMILL TEST

**PARTLY.**

Zonder nieuwe Paths, modules, Worlds of Premium-content kan de bestaande engine routines bouwen en veranderen wanneer context of expliciete feedback verandert. Dat is reëel werk uit dezelfde bibliotheek.

Bij stabiele routines blijven vooral Free-gebruik en opgebouwd bezit over. Het systeem kan dus zonder contentproductie blijven functioneren én te weinig nieuwe betaalde waarde leveren. “Geen contenttreadmill” is een schaalvoordeel, geen bewijs dat maand zes verkoopbaar is.

## FOUNDER-LABOR SCALABILITY

Voor 1.000 of 10.000 gebruikers vraagt de kern geen evenredig aantal door de founder gemaakte aanbevelingen, routineaanpassingen of persoonlijke gesprekken. Lokale regels en herbruikbare inhoud zijn daarin sterk. [S4–S7]

| Werk | Schaalbaarheid |
|---|---|
| Content | Goed: één bibliotheek, gerichte batchcorrecties. |
| Routine-onderhoud | Goed: software voert dezelfde begrensde taken uit. |
| Support | Onbekend in productie; billing, lokale data en begripsproblemen kunnen volume geven. |
| QA | Geen werk per gebruiker, wel per release, toestelklasse en platformverandering. |
| Billing | Beheersbaar in principe; live lifecycle nog te bewijzen in Phase E. |
| Acquisitie | Grootste founder-afhankelijkheid: bereik en vertrouwen ontstaan niet uit lokale automatisering. |

**6/10 totaal.** Technische schaalbaarheid garandeert geen schaalbare onderneming. Intermitterende betalingen kunnen bovendien meer eerste aankopen en heractiveringen nodig maken om hetzelfde omzetniveau te dragen.

## ACQUISITION / POSITIONING RISK

“Een app die zegt dat ik moet wandelen” is een geloofwaardige eerste reactie. De activiteit is herkenbaar; de waarde van selectie, herinnerde voorkeuren en begeleide combinatie wordt pas later zichtbaar.

Dat maakt de uitleg subtiel en de acquisitie mogelijk duur. Een aantrekkelijke World kan aandacht trekken zonder betaalde noodzaak uit te leggen. Een laag abonnementstarief zou dat niet automatisch oplossen.

De eerste boodschap moet de concrete beslisfrictie en een zichtbaar resultaat kunnen dragen. Dit rapport schrijft geen campagne. Het commerciële experiment moet aantonen dat mensen buiten de bestaande founderkring die waarde begrijpen, gebruiken en eventueel kopen.

## TOP 7 FAILURE MODES

Waarschijnlijkheden zijn kwalitatieve auditinschattingen, geen statistische voorspellingen.

| Rang | RISK | PROBABILITY | IMPACT | WHY | WHAT WOULD DISPROVE IT |
|---|---|---|---|---|---|
| 1 | Na een passende Toolkit valt betaald werk weg. | HIGH | HIGH | Routines, gebruik, detectie en checks blijven Free; korte varianten ontstaan vaak al bij de bouw. | Werkelijke nieuwe betaalde taken of vrijwillige heractivering, met voldoende opbrengst over complete betaalperiodes. |
| 2 | Mensen waarderen de tip, maar keren niet zelfstandig terug. | MEDIUM | HIGH | Het probleem is klein en alternatieven zijn direct beschikbaar. | Vrijwillige terugkeer en ervaren hulp zonder herhaald foundercontact, ook nadat de nieuwigheid weg is. |
| 3 | Zeven Circles voelen te duur in inspanning. | MEDIUM | HIGH | Het resultaat bestaat uit bekende handelingen; meerdere combinaties vragen 20–30 minuten. | Mensen vervolgen uit eigen beweging, begrijpen de proefstappen en gebruiken het resultaat later. |
| 4 | De eigen routine verschijnt te weinig om belangrijk te worden. | MEDIUM | MEDIUM | Geen rankingbonus, veel alternatieven, tijdsfit en beperkte behoefte-dagen. | Eigenaars zien voldoende passend gebruik, herkennen het nut en vragen niet structureel waar hun routine blijft. |
| 5 | Onderhoud is technisch correct, maar weinig waard om voor te betalen. | HIGH | HIGH | Free kan vandaag al een haalbare activiteit kiezen; korte aanpassingen zijn zelf eenvoudig. | Gebruikers met echte misfit kiezen bewust voor betaald onderhoud en benutten de aangepaste versie. |
| 6 | Het persoonlijke systeem voelt administratief of overclaimt begrip. | MEDIUM | MEDIUM | Veel begrippen; weinig feedback kan toch een persoonlijk ogend resultaat opleveren. | Gebruikers begrijpen grenzen en volgende stap, zonder versies/Memory als extra taak te ervaren. |
| 7 | Acquisitie en support kosten meer dan intermitterende betaling oplevert. | MEDIUM | HIGH | Subtiele propositie, beperkte continue betaalreden en onbekende kanalen. | Rijpe cohorten met positieve bijdrage na daadwerkelijke kosten en herhaalbaar bereik buiten foundercontacten. |

## PRE-RELEASE BLOCKERS

**NONE.**

Er is geen nieuwe materiële productblokkade aangetoond die een extra bouw- of strategieronde vóór het ingaan van pre-releasevalidatie rechtvaardigt.

Dit oordeel heft de bestaande releasepoorten niet op. Phase E is nog niet begonnen: meetinrichting, productieconfiguratie, privacy/support, Data Safety, commerciële voorwaarden, live billing/restore, storepresentatie en releasebewijs staan nog open volgens S2. Public launch is dus niet gereed. Alleen daadwerkelijk vrijgegeven content mag in externe builds worden gebruikt.

De tracker vraagt voor publieke release bovendien hogere productbeoordelingen dan meerdere blinde scores in dit rapport. Deze audit verklaart die founderpoort **niet gehaald**. De lagere scores worden niet kunstmatig verhoogd om bij de tracker te passen.

De te brede stable-checktekst en tijdsbewijsformulering zijn gerichte afwerkingspunten. Ze zijn offline te verbeteren, maar vormen op de huidige evidence geen reden voor een nieuwe productfase of uitstel van het hele validatietraject.

## VALIDATION QUESTIONS

De wezenlijke onzekerheden zijn gedrag, geen ontbrekende features:

1. Vermindert THIRTY merkbaar besliswerk én helpt het iemand werkelijk beginnen?
2. Keren mensen vrijwillig terug nadat ze de bekende activiteiten kennen?
3. Herkennen zij betere selectie door feedback en kunnen ze verkeerd Memory herstellen?
4. Is de opbrengst van een Path de zeven Circles waard, ook bij beperkte tijd?
5. Voelt een opgebouwde routine persoonlijk, bruikbaar en vaak genoeg aanwezig?
6. Is een echte onderhoudsverandering beter genoeg dan Free of zelf aanpassen om betaling te rechtvaardigen?
7. Komen tevreden opzeggers terug wanneer hun omstandigheden veranderen?
8. Kan de opbrengst van die betaalperiodes acquisitie, support en overige kosten dragen?

## POST-LAUNCH / LATER

Pas na relevante evidence: aanpassing van Path-lengte, onderhoudsdrempels of routinefrequentie; eventuele extra inhoud voor een aantoonbaar onbediende situatie; rijkere World-beleving; extra distributiekanalen; bredere platformondersteuning.

Dit is geen toegezegde roadmap. Een terugkerend probleem is een aanleiding voor een begrensde beslissing, niet automatisch voor meer product. De reeds geplande Phase-E-releaseverplichtingen zijn nadrukkelijk geen post-launchwerk.

## TESTER RESEARCH

Gebruik één samenhangende near-releasecohort zodra het volledige product en de benodigde releasevoorzieningen klaarstaan. Herhaal de eerdere conceptvalidatie niet na elke wijziging. Neem mensen op voor wie de beslisfrictie werkelijk bestaat, waaronder mensen met weinig tijd en mensen die zelden feedback geven. Een uitsluitend door de founder begeleide groep overschat zelfstandige waarde.

Zes korte onderzoeksmomenten zijn genoeg:

| Moment | Minimale vraag/taak | Gedrag dat zwaarder weegt |
|---|---|---|
| Eerste waarde | “Wat verwacht je dat THIRTY nu voor je doet? Wat zou je anders hebben gedaan?” | Zonder hulp een keuze begrijpen en werkelijk proberen; Close alleen telt niet. |
| Terugkeer | “Waarom opende je de app deze keer? Was de gekozen activiteit passend?” | Terugkomen zonder persoonlijk duwtje; relevantie en actie op meerdere eigen momenten. |
| Memory | Laat één onthouden antwoord uitleggen en zo nodig corrigeren. | Zelfstandig herstel en later merkbaar passende selectie. Geen verplicht Memory-gebruik. |
| Path | “Wat houd je hieraan over, en waarom zou je doorgaan?” | Zelf starten/vervolgen, waar tijdsfit blokkeert, vrijwillig bewaren en later gebruiken. |
| Routine/onderhoud | “Kwam je routine vaak genoeg? Wat lost deze voorgestelde verandering voor jou op?” | Routineaanbod per passende kans; onderhoud alleen bij echte behoefte; aangepaste versie daarna benutten. |
| Betalen/lapse | “Wat krijg je erbij, wat blijft na opzegging, en zou je dit nu kopen?” | Werkelijke betaling tegen duidelijke echte voorwaarden; later bewust verlengen, stoppen of opnieuw activeren. |

Een gesimuleerde Week-7-situatie kan begrip testen, maar telt niet als spontaan ontstane onderhoudsbehoefte. Geef niet iedereen een kunstmatige misfit om vervolgens te concluderen dat maintenance vaak nodig is.

Rapporteer aantallen, cohortleeftijd, toepasselijke kansen en antwoorddekking. Scheid app-open, Circle-close, zelfgerapporteerde uitvoering, ervaren nut, aankoop en verlenging. Niet antwoorden betekent ontbrekende informatie. Segmenteer testbetalingen, reminders en persoonlijk contact. Een vraag “zou je betalen?” is veel zwakker dan een daadwerkelijk begrepen aankoop.

Zes maanden aan betaalwaarde kunnen niet met een kort onderzoek worden bewezen. De eerste cohort kan wel tonen of de basis werkt en of verder volgen gerechtvaardigd is.

## KILL SIGNALS

| Besluit | SIGNAL | WHAT FAILED | APPROPRIATE RESPONSE |
|---|---|---|---|
| CONTINUE | Mensen keren zelfstandig terug, proberen suggesties en kunnen concrete verlichting benoemen. | De Free-hypothese houdt voorlopig stand. | Volg dezelfde cohort; verbeter alleen aangetoonde frictie. |
| CONTINUE | Mensen betalen voor begrepen bouwwerk, gebruiken het resultaat en vragen later vrijwillig om passend onderhoud. | De betaaltaak bestaat; frequentie/economie nog volgen. | Voorzichtig verder valideren met echte betaalperiodes en kosten. |
| ADJUST | Free werkt, maar mensen willen na het bouwen bewust stoppen. | Continue cadans past onvoldoende; het product kan wel waardevol zijn. | Beoordeel periodieke betaalmomenten of een eindige propositie voordat acquisitie groeit; verzwak Free niet. |
| ADJUST | Mensen willen hun routine gebruiken maar begrijpen Today, wachttijd of Path-stappen niet. | Interactie of verwachting faalt. | Eén gerichte correctie en dezelfde taak opnieuw observeren. |
| ADJUST | Een onderhoudsaanbieding is begrijpelijk maar levert geen merkbaar beter resultaat. | De gekozen interventie voegt te weinig toe. | Herzie die concrete interventie of stop haar betaalclaim; geen extra featurepakket. |
| STOP SCALING | Na begrijpelijke eerste ervaringen blijft zelfstandige terugkeer en ervaren nut zwak. | De dagelijkse kern is niet nodig genoeg voor de onderzochte doelgroep. | Stop groei-uitgaven; alleen een afgebakende doelgroep- of probleemhypothese rechtvaardigt verder werk. |
| STOP SCALING | Mensen begrijpen Premium, gebruiken Free graag en zien herhaaldelijk geen betaalde noodzaak; echte transacties ondersteunen dat. | De betaalde propositie is te zwak. | Begrens Premium-investering en heroverweeg het model; geen catalogusuitbreiding als standaardreactie. |
| STOP SCALING | Rijpe cohorten dekken de werkelijke acquisitie- en servicekosten niet binnen de betaalbare kasperiode. | Het kanaal/model kan zichzelf niet dragen. | Stop het betreffende kanaal of aanbod; toets alleen een specifieke herstelhypothese. |
| STOP SCALING | Verlengen blijkt vooral vergeten facturering of misbegrepen verlies van routines. | Schijnretentie en vertrouwensprobleem. | Corrigeer aanbod en beheer vóór verdere verkoop; tel de ontvangsten niet als bewijs van waarde. |

Geen willekeurige conversie- of retentiedrempels. De beslisgrens volgt uit werkelijk geleverde waarde, voldoende herhaalde observatie, cohortmaturiteit en de kosten/ambitie die de founder moet dragen. Een kleine groep enthousiaste testers kan een ernstige fout vinden, maar bewijst geen marktvolume.

## DO NOT BUILD

Bouw vóór validatie geen extra Paths of modules voor aantallen, social, streaks, AI-chat, gezondheidsdashboard, wearables, routinefrequentiecontrols, Premium-World-perks, extra meldingen, integraties of een contentproductieprogramma.

Er is geen bewijs dat deze zaken de primaire onzekerheid oplossen. Voeg ook geen ingewikkelder personaliseringslogica toe enkel omdat de huidige grenzen zichtbaar worden. Bewijs eerst dat mensen de bestaande keuzehulp, routines en gerichte veranderingen willen gebruiken en kopen.

## PREVIOUS AUDIT DELTA

Na de blinde lock is de historische **THIRTY V1 PRODUCTIZATION + COMMERCIAL REVIEW van 6 september 2026** teruggevonden en zijn de relevante kritieksecties gelezen. De aangeleverde recurring-Premium-freeze en septemberaddenda zijn daarna als aanvullende historische bronnen gebruikt.

Er is geen afzonderlijke eerdere onafhankelijke audit met een vergelijkbare 31-dimensiescorekaart geïdentificeerd in de onderzochte bestanden. H1 is een historische productization/commercial review van een veel eerder checkpoint (`daf6804`), geen stilzwijgende vervanging voor zo'n ontbrekende audit. De vergelijking hieronder is dus controleerbaar kwalitatief. **Vorige numerieke scores en score-delta's: UNKNOWN.**

| Eerdere kritiek/kwestie | Classificatie | Wat V2 werkelijk verandert of openlaat |
|---|---|---|
| Een activiteitstitel geeft te weinig hulp om te beginnen. | RESOLVED op implementatieniveau | First action, uitleg en Open/Guided-uitvoering zijn concreet aanwezig. Of meer mensen handelen blijft te meten. |
| Kleine pools en ID-rotatie voelen oppervlakkig/repetitief. | PARTLY RESOLVED | Grotere live-inventaris, semantische spreiding, multi-fit en feedbackselectie; ervaren variatie is geen broncodefeit. |
| Selectie onthoudt vooral blootstelling in plaats van wat hielp. | RESOLVED op implementatieniveau | Expliciete nuttigheidsinformatie, tijdelijke rust en corrigeerbaar Memory beïnvloeden selectie. |
| Een halfuur kan een onnodige drempel zijn. | PARTLY RESOLVED | Natuurlijke duren en 10/20/30-keuze verbeteren Free sterk; sommige Path-combinaties blijven lang. |
| Premium Pass is vooral visuele kwaliteit, geen betaalproduct. | RESOLVED op implementatieniveau | Paths produceren routines; onderhoud kan ze werkelijk veranderen. Betaalbereidheid niet opgelost. |
| Na een eindig programma kan de betaalreden verdwijnen. | UNCHANGED | Onderhoud bestaat nu, maar frequentie en increment blijven onbewezen. Blijvend eigendom maakt afronding duidelijker. |
| Herhaalde betaalde begeleiding zou stabiele maanden vullen. | WORSE voor continue contractfit | V2 laat bestaand gebruik én signalering Free doorgaan. Dat is eerlijker, maar minder dragend voor permanente betaling dan de oude servicebelofte suggereerde; geen geobserveerde churnvergelijking. |
| Plans/Coach/Insights moeten als drie pijlers worden gerealiseerd. | NO LONGER RELEVANT | Het V2-contract vervangt ze; geen opdracht om oude pijlers terug te brengen. |
| Een gesloten Circle kan met echte actie worden verward. | PARTLY RESOLVED | Betekenis en optionele verslaglegging zijn beschermd; het risico op verkeerde interpretatie van Path-progressie blijft te toetsen. |
| Eén bezoek/positief conceptantwoord bewijst geen retentie of betaling. | UNCHANGED | Geen actueel gedrags- of betaalcohort beschikbaar. |
| Acquisitie kan een permanent founderproductieproces worden. | UNCHANGED | Lokale automatisering lost distributie niet op. |
| Het oude /plans-entitlementprobleem. | NO LONGER RELEVANT in die vorm | De oude pijlers/routes zijn vervangen. Huidige betaaloperaties zijn in de gelezen grenzen gecontroleerd; live billing blijft een afzonderlijke poort. |

Nieuwe risico's zijn vooral de verwachting rond eigen routinefrequentie, de tijd die gecombineerde Paths vragen, automatische oplevering van korte varianten die later onderhoud overbodig maakt en een Toolkit-check die over meer routines kan spreken dan beoordeeld zijn.

| Belangrijke score | PREVIOUS | CURRENT | DELTA | WHY |
|---|---|---:|---|---|
| Free product value | UNKNOWN | 7 | UNKNOWN | Andere en concreter geïmplementeerde kern; geen oude vergelijkbare score. |
| Premium value | UNKNOWN | 6 | UNKNOWN | Routinevorming en wijziging zijn aantoonbaar, behoefte nog onbewezen. |
| Trust | UNKNOWN | 7 | UNKNOWN | Sterk eigendom/correctie, beperkte copy-overclaim. |
| Subscription-worthiness | UNKNOWN | 3 | UNKNOWN | Stabiele betaalreden zwak ondanks geïmplementeerd onderhoud. |
| Overall product quality | UNKNOWN | 7 | UNKNOWN | Vastgelegde blinde score. |
| Overall commercial design strength | UNKNOWN | 5 | UNKNOWN | Vastgelegde blinde score. |

Geen numerieke vooruitgang afgeleid uit het enthousiasme of de classificaties van oude reviews. Ook de oude kwalificatie “plausibly subscription-worthy” is een eerdere hypothese, geen bewijs dat V2 betaald zal worden.

## FIVE BIGGEST IMPROVEMENTS

1. **Natuurlijke duur en echte tijdsfit.** De handeling kan beter bij de beschikbare tijd passen; dat verlaagt een praktische drempel.
2. **Expliciet leren met herstelmogelijkheid.** Feedback, rust en Memory maken bruikbare aanpassing mogelijk zonder verborgen profiel.
3. **Een concreet Premium-resultaat.** Een Path levert een routine op die iemand kan bewaren en gebruiken, in plaats van alleen voortgang door een programma.
4. **Onderhoud dat iets verandert.** De 30→20-minutenroutine toont een controleerbare verandering met behoud van onderdelen.
5. **Werkelijk bruikbaar eigendom na opzegging.** Dit maakt de aankoop eerlijker en verlaagt het risico van afhankelijkheid.

Dit zijn verbeteringen in productwaarde of vertrouwen. Zij verdienen geen automatische pluspunten voor conversie, retentie of omzet.

## TOP FIVE REMAINING RISKS

| RISK | WHY IT MATTERS | CURRENT EVIDENCE | WHAT WOULD DISPROVE IT | WHEN WE CAN KNOW |
|---|---|---|---|---|
| Continue betaling past niet bij afgerond werk. | Ondergraven van de abonnementsbusinesscase. | Free behoudt routines, checks en detectie; korte varianten vaak al aanwezig. | Vrijwillig herhaald betaald werk/heractivering met houdbare bijdrage. | Na echte bouw-, stabiele en veranderperiodes; niet in een korte demo. |
| De Free-taak is niet belangrijk genoeg om terug te komen. | Zonder terugkeer weinig betaalmomenten. | Plausibele frictie, geen actuele cohortuitkomsten. | Zelfstandige herhaalde actie en ervaren verlichting. | Eerste weken en maand, met voldoende antwoorddekking. |
| Path-inspanning en tijd wegen zwaarder dan het resultaat. | Mensen bereiken het betaalde resultaat niet. | Zeven gesloten Circles; beperkte korte combinaties. | Vrijwillige voortzetting en later gebruik van het resultaat. | Tijdens een echte Path en de weken erna. |
| Routine/maintenance worden te weinig benut. | Eigendom voelt abstract en betaald onderhoud blijft theoretisch. | Geen rankingbonus, smalle triggers, optionele feedback. | Passende aanbiedingen worden herkend, aanvaard en leiden tot gebruikt beter resultaat. | Over meerdere routinegebruiken en echte verandergevallen. |
| Distributie en founderwerk maken de economie te klein. | Goed product kan alsnog onvoldoende onderneming opleveren. | Geen actueel kanaal-, kost- of betaalcohortbewijs. | Herhaalbaar bereik en positieve bijdrage na acquisitie en operationele kosten. | Zodra cohorten voldoende betalingen/kosten hebben opgebouwd. |

## FOUNDER DECISIONS

**NO MATERIAL FOUNDER DECISION REQUIRED BEFORE PHASE E.**

De bevroren productarchitectuur hoeft voor de volgende fase niet opnieuw open. De bestaande Phase E bevat al beslissingen over de daadwerkelijk verkochte cadence, prijs/voorwaarden, consent en slogan. Die moeten vóór hun configuratie/publicatie genomen worden, maar vormen geen nieuwe strategische voorfase.

Mijn aanbeveling voor die bestaande commerciële afweging is om intermitterend betaald gebruik als mogelijk correct gedrag te behandelen. Een maandelijkse aankoop kan dat gedrag al zichtbaar maken; een nieuwe pauzefunctie is niet vooraf noodzakelijk. Dit rapport kiest geen prijs, configureert geen jaarplan en autoriseert geen billingwijziging.

## FINAL 35 ANSWERS

| # | Vraag | Direct antwoord |
|---|---|---|
| 1 | Is THIRTY now a good product? | **Ja**, als huidige productopzet: 7/10. Geen bewijs van marktfit. |
| 2 | Is the underlying problem important enough? | **Voor een gerichte groep plausibel; in het algemeen middelmatig.** |
| 3 | Is Free strong enough to stand alone? | **Ja**, de dagelijkse keuze-/uitvoeringslus is zelfstandig bruikbaar. |
| 4 | Will Free plausibly create repeated voluntary use? | **Plausibel, onbewezen.** Niet verwarren met algemene interesse in zelfzorg. |
| 5 | Is Premium meaningfully better than Free? | **Ja voor bouwen en veranderen; weinig extra bij stabiel gebruik.** |
| 6 | Is Premium useful? | **Ja**, de processen verrichten echte extra taken. |
| 7 | Is Premium Premium-worthy? | **Plausibel voor mensen die begeleide routinevorming waarderen.** |
| 8 | Is Premium plausibly subscription-worthy? | **Als periodiek geactiveerde hulp wel; als brede permanente maandlast zwak.** |
| 9 | Why would someone first pay? | Een terugkerende situatie laten vertalen naar een bruikbare eigen routine. |
| 10 | Why would someone renew in Month 2? | Een tweede routine, nog lopend bouwwerk of een echte noodzakelijke aanpassing. Bestaand bezit alleen is geen sterke reden. |
| 11 | Why would someone renew in Month 6? | Concrete nieuwe veranderbehoefte of aantoonbaar gewaardeerde begeleiding. Zonder dat weinig reden. |
| 12 | Is Month-6 value strong enough? | **Nee voor de veronderstelde stabiele gebruiker: 2/10.** |
| 13 | Is the stable-user problem acceptable or structurally dangerous? | **Gevaarlijk voor continue verlenging; acceptabel bij rendabele intermitterende betaalperiodes.** |
| 14 | Does keeping routines after cancellation improve trust more than it hurts retention? | Vertrouwen verbetert structureel; de netto economische balans is **UNKNOWN**. De keuze behouden. |
| 15 | Is pause/resume structurally a better fit than continuous monthly use? | **Ja.** Dat vereist nog geen native billingpauze. |
| 16 | Does Premium still work with no new content for six months? | **PARTLY:** echte veranderingen blijven mogelijk, stabiele behoefte blijft zwak. |
| 17 | Are the six Paths enough? | **Ja voor validatie.** Meer aantallen zijn nu niet gerechtvaardigd. |
| 18 | Are seven Circles per Path justified? | **Verdedigbaar als proefopzet, nog niet bewezen proportioneel.** |
| 19 | Is the module library enough? | **Ja voor het begrensde huidige experiment; geen brede dekking of zes maanden betaling bewezen.** |
| 20 | Are routines meaningfully more than saved activities? | **Soms:** combinatie, duurvarianten en eigen ervaring voegen toe. Zonder feedback/gebruik nauwelijks. |
| 21 | Are routines likely to be offered often enough? | **CLOSED-TEST QUESTION.** Geen rankingingreep vooraf. |
| 22 | Is maintenance likely to happen often enough? | **Onvoldoende basis om dat aan te nemen**, zeker na enkele passende routines met korte varianten. |
| 23 | Is THIRTY differentiated enough from ChatGPT + Notes + reminders? | **Voor minder denk- en beheerwerk plausibel; niet automatisch genoeg om extra te betalen.** |
| 24 | Is THIRTY too complex now? | **Today niet; Premium loopt dat risico.** Begrip moet zonder systeemuitleg blijken. |
| 25 | Does the calm philosophy materially hurt commercial urgency? | **Waarschijnlijk wel.** Overleefbaar als nut vrijwillige terugkeer en betaalmomenten draagt. |
| 26 | Is anything Premium that should clearly be Free? | **Geen duidelijke verhuizing gevonden.** Basale begeleiding en eigendom zijn al Free. |
| 27 | Is anything Free that should clearly be Premium? | **Nee.** Free verzwakken lost de noodzaak niet op. |
| 28 | Is current Premium scope enough for launch? | **Productscope voldoende voor een begrensde launch-validatie; huidige build niet vrijgegeven voor publieke launch.** Phase E en releasepoorten blijven. |
| 29 | Should KEYBRACE build anything else before testing? | **Geen nieuwe productfeatures.** Bestaande releasevoorzieningen en gerichte afwerking voltooien. |
| 30 | What is the single biggest unknown now? | Of echt nieuw betaald werk vaak en waardevol genoeg terugkomt voor een rendabele groep. |
| 31 | What is the strongest reason this business could succeed? | Een herkenbare groep wil keuzes uitbesteden en betaalt op relevante momenten voor een concrete routine of verbetering, zonder menselijke levering per klant. |
| 32 | What is the strongest reason it could fail? | Gebruikers vinden Free prettig, leren enkele routines, en hebben te weinig verdere betaalde behoefte. |
| 33 | Is the current subscription model structurally aligned with delivered value? | **Gedeeltelijk:** maandelijkse toegang tijdens werk past; vanzelfsprekende continue vernieuwing niet. |
| 34 | From a rational product-value standpoint, would Premium be worth paying for to a meaningful subset of users? | **Plausibel ja voor concrete bouw-/veranderperiodes.** Of die subset commercieel groot genoeg is blijft onbekend. |
| 35 | Should THIRTY move to pre-release validation now? | **Ja.** Pre-release afwerken en de complete propositie toetsen; geen extra conceptcyclus. |

## FINAL VERDICT

**READY FOR PRE-RELEASE VALIDATION**

**IS THERE ANYTHING MATERIAL WE CAN STILL LEARN OR FIX WITHOUT REAL USERS THAT JUSTIFIES DELAYING PRE-RELEASE? NO.**

THIRTY heeft genoeg concrete Free- en Premium-functionaliteit om de volgende leerstap te verdienen. De bekende beperkte copykwesties horen bij gerichte afwerking. De open Phase-E-verplichtingen en publieke releasepoorten blijven gelden; dit oordeel is geen toestemming om ze over te slaan of Phase E binnen deze audit uit te voeren.

De zwaarste onzekerheid is of routinevorming en onderhoud voldoende extra betaalde behoefte creëren. Meer redeneren, simulaties of content kunnen het bestaan van die behoefte niet bewijzen. Een selectief Week-7-voorbeeld is een goede demonstratie, geen abonnementsprognose.

Behoud de zelfstandige Free-ervaring en het routine-eigendom. Toets het volledige product, observeer bewuste betaling én bewuste opzegging, en laat echte heractivering aantonen of de intermitterende waardecadans een houdbare onderneming kan dragen.
