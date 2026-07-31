# Product Discovery — De Eerste Ervaring

Dit document beschrijft wie de eerste gebruiker van THIRTY is, welke ervaring hij nodig heeft, en welke vragen daarover nog open staan. Het is een **exploratief** document: de persona en aannames hierin zijn ontwerphypotheses, geen gevalideerd onderzoek — dat onderscheid wordt hieronder expliciet gehouden.

Dit document is de **source of truth** voor de redenering achter de eerste ervaring en voor open vragen die nog niet beslist zijn. Zodra een vraag hieronder is beantwoord, verhuist de beslissing naar [Onboarding Principles](onboarding-principles.md) of een [ADR](adr/) — dit document wordt dan bijgewerkt om er niet langer tegenstrijdig mee te zijn.

Voor de emotionele reis en toon die THIRTY app-breed nastreeft, is [BRAND_BOOK.md](../BRAND_BOOK.md) leidend (met name §5 Brand Promise en §9 Emotional Journey). Dit document herhaalt die principes niet, maar werkt uit wat ze specifiek betekenen voor een gebruiker die THIRTY voor het eerst opent.

---

## 1. Wie is de eerste gebruiker?

**Waarom downloadt hij THIRTY?**
Niet omdat hij "nog een gezondheidsapp" zoekt. Hij downloadt THIRTY op een moment van lichte frustratie: hij wíl iets doen voor zijn gezondheid, maar generieke programma's, trackingoverload of vage voornemens ("gezonder leven") hebben eerder niet gewerkt.

**Welk probleem probeert hij vandaag op te lossen?**
Niet "ik wil afvallen" of "ik wil fitter worden" — dat is het achterliggende verlangen. Het probleem van vandaag is: *"Ik heb geen idee wat ik vandaag concreet moet doen, en ik heb geen zin in nog een groot plan."* Hij zoekt richting en een startpunt zonder denkwerk.

**Wat voelt hij vóór hij de app opent?**
Een combinatie van lichte motivatie, vermoeidheid van eerdere pogingen, en een vleugje scepsis ("wordt dit ook weer een app die te veel van me vraagt?"). Weinig geduld voor frictie, weinig tolerantie voor nog een teleurstelling.

> **Status:** ontwerphypothese, niet gevalideerd met gebruikersonderzoek. Zie open vraag in §6.

## 2. De Opening→Home-overgang voor een eerste gebruiker

[BRAND_BOOK.md §9](../BRAND_BOOK.md#9-emotional-journey) legt de app-brede emotionele reis vast: Opening (nieuwsgierigheid) → Home (rust) → Focus (concentratie) → Activiteit (vertrouwen) → Afronding (voldoening) → Afsluiten (tevredenheid). Dat model is leidend voor elk scherm, ook het eerste.

Voor een gebruiker die THIRTY voor het eerst opent, weegt de overgang **Opening → Home** zwaarder dan op een gewone dag: er is nog geen vertrouwen opgebouwd, dus "rust" moet in dat eerste moment nog verdíénd worden, niet verondersteld. Concreet betekent dit dat de Opening-fase voor een eerste gebruiker een extra taak heeft die BRAND_BOOK niet expliciet noemt (omdat het daar over een terugkerende gebruiker gaat): **iets van het aanvankelijke wantrouwen wegnemen** voordat de rust van Home geloofwaardig aanvoelt. Dit sluit aan bij de Brand Promise-lijn "de eerste indruk van THIRTY is er één van opluchting" ([BRAND_BOOK.md §5](../BRAND_BOOK.md#5-brand-promise)).

Te vermijden bij een eerste gebruiker, expliciet: schuld, overweldiging, tijdsdruk/urgentie, vergelijking met anderen — dit volgt direct uit [VISION.md](../VISION.md) en [BRAND_BOOK.md](../BRAND_BOOK.md), niet uit een aparte regel hier.

## 3. Welke informatie hebben we écht nodig?

**Absoluut noodzakelijk (voor de eerste 30 minuten):** in principe geen persoonsgegevens. Het enige wat nodig is, is een lichte contextuele keuze in het moment — bijvoorbeeld "waar heb je nu behoefte aan?" met drie tastbare opties. Dit is geen profielvraag maar een keuze die de intentie (zie [Decision Framework §4](decision-framework.md#4-intentie-versus-activiteit)) direct stuurt.

**Later vragen:** ritme/voorkeuren, interesses/beperkingen die een activiteit-invulling verbeteren, patronen die pas zichtbaar worden na gebruik.

**Misschien nooit vragen:** medische gegevens, verplichte lichaamsmetrics, demografische data zonder direct functioneel doel. THIRTY is expliciet geen vervanging van medisch advies ([VISION.md](../VISION.md)).

**Vuistregel:** vraag pas om informatie op het moment dat het antwoord een concrete, voelbare verbetering oplevert — nooit "voor later" of "voor het profiel".

> **Status:** de vuistregel is vastgesteld, zie [Onboarding Principles](onboarding-principles.md#1-informatie-principe). De precieze grens van "misschien nooit" is nog open — zie §6.

## 4. Wanneer vragen we een account?

Overwogen opties: vóór elke waarde (signup-wall, verworpen — breekt vertrouwen voordat er iets is ervaren), nooit een account (onhoudbaar zodra sync/Premium nodig zijn), of ná de eerste echte waarde (value-first).

**Gekozen strategie:** value-first — de gebruiker doorloopt de eerste ervaring zonder account; de account-uitnodiging komt op het moment dat continuïteit er al bewust toe doet, geframed als *"bewaren"*, niet als *"registreren"*.

→ Zie [ADR-006 — No Account Before First Value](adr/ADR-006-no-account-before-first-value.md).

> **Status:** de strategie is vastgesteld. Het **exacte triggermoment** (altijd na de eerste sessie, of afhankelijk van gedrag) is nog open — zie §6.

## 5. Wanneer introduceren we Premium?

Premium wordt niet tijdens de eerste sessie genoemd, en niet als onderbreking van de kern-loop. De gratis versie levert de volledige kernbelofte zonder compromis; Premium voegt verdieping toe (personalisatie, patronen), het ontgrendelt nooit de kern.

→ Zie [ADR-007 — Premium Never Blocks the Core Loop](adr/ADR-007-premium-never-blocks-the-core-loop.md).

> **Status:** de strategie is vastgesteld. Het **concrete, meetbare triggermoment** waarop Premium voor het eerst getoond wordt, is nog open — zie §6.

## 6. Open vragen

Deze vragen zijn nog niet beslist. Zolang dat zo is, mag geen enkel ander document (inclusief [Onboarding Principles](onboarding-principles.md)) doen alsof ze al beantwoord zijn.

1. Wat is de bron/logica van de allereerste suggestie zonder gebruikersdata?
2. Bewaren we iets vóór er een account is — en zo ja, op basis van welk principe?
3. Wat is het exacte triggermoment voor de account-uitnodiging?
4. Wat telt precies als "afgeronde 30 minuten"?
5. Welk concreet, meetbaar signaal markeert het moment waarop Premium voor het eerst getoond mag worden?
6. Welke onderdelen van de kernbelofte zijn expliciet en onvoorwaardelijk gratis, als benoembare lijst?
7. Is er, ook zonder uitwerking, een principebeslissing nodig over re-engagement/notificaties? (Zie ook [BRAND_BOOK.md §5](../BRAND_BOOK.md#5-brand-promise) voor de bestaande notificatie-toon: "zacht herinneren, niet opjagen" — dat beantwoordt de tóón, niet de timing/frequentie.)
8. Is de persona in §1 gevalideerd met echte gebruikers, of blijft ze een ontwerphypothese?

## 7. Onboarding-overzicht (conceptueel)

Geen schermontwerp — alleen de high-level flow:

```
Open app
  ↓
Welkom (BRAND_BOOK Opening: nieuwsgierigheid)
  ↓
Eén lichte, contextuele vraag (intentie kiezen)
  ↓
Eerste echte 30-minuten-suggestie (kernervaring, zonder account)
  ↓
Afronding (BRAND_BOOK The THIRTY Moment: voldoening, zie BRAND_BOOK.md §10)
  ↓
Uitnodiging om te bewaren (account als dienst)
  ↓
Terugkeermoment (dag 2+)
```

## 8. Risico's

Zie [Onboarding Principles §Risico's](onboarding-principles.md) voor de vastgestelde tegenmaatregelen. Kernrisico's die de aanleiding vormden: lange intakeformulieren vóór eerste waarde, schaamte-gedreven streaks, vroege/agressieve paywalls, generieke content die zich voordoet als AI-personalisatie, sociale vergelijking, opdringerige notificaties, overclaimen van AI- of medische mogelijkheden.
