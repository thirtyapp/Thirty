# Onboarding Principles

Dit document bevat de **vastgestelde, duurzame** principes voor de eerste ervaring van THIRTY — de beslissingen uit [Product Discovery](product-discovery.md) die niet langer exploratief zijn. Wat hier staat, geldt totdat een nieuwe ADR het expliciet wijzigt.

Dit document herhaalt geen algemene merk- of UX-principes die al elders zijn vastgelegd:
- Voor toon, emotionele reis en algemene ontwerpprincipes (rust, eenvoud, één primaire actie): zie [BRAND_BOOK.md](../BRAND_BOOK.md) en [CLAUDE.md](../../CLAUDE.md#product-principles).
- Voor de eisen aan een aanbeveling: zie [Recommendation Philosophy](recommendation-philosophy.md).

Dit document bevat uitsluitend wat **specifiek is voor onboarding**: wanneer we wat vragen, wanneer een account nodig is, en wanneer Premium wordt genoemd.

Nog niet beslíste onderwerpen staan hier niet als principe — ze staan, expliciet als open vraag, in [Product Discovery §6](product-discovery.md#6-open-vragen).

---

## 1. Informatie-principe

**Vastgesteld:** vraag pas om informatie op het moment dat het antwoord een concrete, voelbare verbetering van de aanbeveling oplevert — nooit "voor later" of "voor het profiel".

- Absoluut noodzakelijk bij de start: geen persoonsgegevens; hoogstens een lichte, contextuele keuze die de intentie stuurt (zie [Decision Framework §4](decision-framework.md#4-intentie-versus-activiteit)).
- Verdere persoonlijke gegevens en voorkeuren worden gradueel gevraagd, alleen wanneer ze een specifieke aanbeveling aantoonbaar beter maken.
- Medische gegevens, verplichte lichaamsmetrics en demografische data zonder functioneel doel worden vermeden — consistent met "geen vervanging van medisch advies" ([VISION.md](../VISION.md)).

## 2. Account-strategie

**Vastgesteld:** value-first. De gebruiker doorloopt de eerste 30-minuten-ervaring zonder account. De account-uitnodiging komt pas op het moment dat continuïteit al bewust relevant is voor de gebruiker, en wordt geframed als *"bewaren"*, niet als *"registreren"*.

→ [ADR-006 — No Account Before First Value](adr/ADR-006-no-account-before-first-value.md)

**Nog open:** het exacte triggermoment. Zie [Product Discovery §6, vraag 3](product-discovery.md#6-open-vragen).

## 3. Premium-strategie

**Vastgesteld:**
- Premium wordt niet genoemd tijdens de eerste sessie en nooit als onderbreking van de dagelijkse kernactie.
- De gratis versie levert de volledige kernbelofte (dagelijkse aanbeveling + basisbegeleiding) zonder compromis.
- Premium voegt verdieping toe (bijvoorbeeld diepere personalisatie of inzicht in patronen); het ontgrendelt nooit de kern zelf.
- Premium wordt uitnodigend geïntroduceerd ("dit zou je ook kunnen"), nooit als gemis geframed ("dit mis je nu").

→ [ADR-007 — Premium Never Blocks the Core Loop](adr/ADR-007-premium-never-blocks-the-core-loop.md)

**Nog open:** het concrete, meetbare triggermoment waarop Premium voor het eerst getoond wordt. Zie [Product Discovery §6, vraag 5](product-discovery.md#6-open-vragen).

## 4. Anti-patronen die we bewust vermijden

Onderstaande zijn vastgestelde grenzen — geen open vragen. Waar een risico al is afgedekt door een bestaand principe elders, wordt daarnaar verwezen in plaats van het te herhalen.

- **Geen lang intake-formulier vóór de eerste waarde** — zie Informatie-principe hierboven.
- **Geen schaamte-gedreven voortgangsmechaniek** (bv. brekende streaks) — al vastgelegd in [BRAND_BOOK.md §8, The Circle Philosophy](../BRAND_BOOK.md#8-the-circle-philosophy): "geen streak die breekt... een half gevulde cirkel is geen mislukking, het is een status."
- **Geen vroege of agressieve paywall** — zie Premium-strategie hierboven.
- **Geen AI-content die zich voordoet als gepersonaliseerd terwijl ze generiek is** — al vastgelegd in [CLAUDE.md, AI Principles](../../CLAUDE.md#ai-principles): AI wordt alleen ingezet wanneer het aantoonbaar waarde toevoegt.
- **Geen sociale vergelijking of leaderboards** — direct uitgesloten door [VISION.md](../VISION.md) ("geen platform dat draait om vergelijken, competitie of vanity metrics") en door [Recommendation Philosophy §4](recommendation-philosophy.md#4-informatiebronnen) (sociale gezondheid is nooit een zelfstandige categorie).
- **Geen opdringerige notificaties** — toon is al vastgelegd in [BRAND_BOOK.md §5](../BRAND_BOOK.md#5-brand-promise) ("ze herinneren zacht, ze jagen niet op"); timing/frequentie van re-engagement is nog niet beslist, zie [Product Discovery §6, vraag 7](product-discovery.md#6-open-vragen).
- **Geen overclaimen van AI- of medische mogelijkheden** — zie [Recommendation Philosophy §2](recommendation-philosophy.md#2-vereisten-voor-een-aanbeveling): THIRTY mag nooit doen alsof het meer weet dan het werkelijk weet.

## 5. Open vragen (verwijzing)

De volgende onderwerpen zijn bewust **niet** als principe opgenomen omdat ze nog niet beslist zijn. Volledige context staat in [Product Discovery §6](product-discovery.md#6-open-vragen):

1. Bron/logica van de allereerste suggestie zonder gebruikersdata.
2. Of en hoe voortgang wordt bewaard vóór er een account is.
3. Exact triggermoment voor de account-uitnodiging.
4. Definitie van "afgeronde 30 minuten".
5. Concreet triggermoment voor het tonen van Premium.
6. Expliciete, benoembare lijst van wat onvoorwaardelijk gratis is.
7. Re-engagement/notificatie-timing en -frequentie.
8. Validatie van de persona uit Product Discovery.

Zodra een van deze vragen beantwoord is, wordt dit document bijgewerkt (en waar relevant een ADR toegevoegd) — niet product-discovery.md, dat exploratief blijft.
