# Recommendation Philosophy

Dit document beschrijft **wat** een aanbeveling van THIRTY moet zijn en waarom — de niet-onderhandelbare eisen en de bronnen waarop een aanbeveling zich mag baseren. Het beschrijft niet hoe deze eisen zich tot elkaar verhouden wanneer ze botsen; dat is de rol van [Decision Framework](decision-framework.md).

Dit document is de **source of truth** voor de vereisten aan een aanbeveling en voor welke informatiebronnen bestaan. Bij twijfel of iets een eis is, telt dit document.

---

## 1. Kernbelofte: de 30-minuteninvestering

THIRTY helpt de gebruiker elke dag **de beste investering van ongeveer 30 minuten voor vandaag** te kiezen. Elke aanbeveling moet binnen deze belofte passen, tenzij daar een expliciete, transparant gecommuniceerde reden voor bestaat.

Dit is een **productprincipe**, geen technische beperking — het schrijft voor wat THIRTY belooft te zijn (een dagelijkse investering van ongeveer 30 minuten), niet hoe tijd technisch wordt vastgelegd of gemeten.

→ Zie [ADR-001 — Best Investment of 30 Minutes](adr/ADR-001-best-investment-of-30-minutes.md).

## 2. Vereisten voor een aanbeveling

Elke aanbeveling die THIRTY doet, moet zijn:

- **Veilig.** Geen aanbeveling die risico op letsel of gezondheidsschade met zich meebrengt.
- **Uitvoerbaar, en zelfstandig uitvoerbaar.** De gebruiker moet de aanbeveling alleen kunnen uitvoeren — zonder dat een tweede persoon, specifieke uitrusting of toegang gegarandeerd aanwezig moet zijn.
- **Een positieve ervaring opleverend.** De aanbeveling moet, bij uitvoering, prettig aanvoelen — niet enkel effectief zijn op papier.
- **Vrij van schuldgevoel.** Zowel de keuze zelf als de manier waarop ze wordt gepresenteerd, mag nooit schuld oproepen. Dit sluit aan bij de Brand Promise in [BRAND_BOOK.md](../BRAND_BOOK.md#5-brand-promise): elke interactie moet de gebruiker rustiger achterlaten dan ervoor.
- **Transparant en uitlegbaar.** Als een aanbeveling niet in eenvoudige taal uit te leggen is aan de gebruiker, wordt ze niet getoond.

Daarnaast geldt, als grondhouding achter elke aanbeveling: **THIRTY mag nooit doen alsof het meer weet dan het werkelijk weet.** Zekerheid wordt nooit geveinsd.

→ Zie [ADR-002 — Recommendations Must Be Explainable](adr/ADR-002-recommendations-must-be-explainable.md).

## 3. Succes boven theoretische perfectie

THIRTY kiest niet de theoretisch beste activiteit, maar de aanbeveling met de grootste kans op een **positief succesmoment** — een formeel gedefinieerde term, zie [Decision Framework](decision-framework.md#2-definitie-positief-succesmoment). Een wetenschappelijk optimale aanbeveling die de gebruiker niet haalt, is geen goede aanbeveling.

→ Zie [ADR-003 — Success Over Theoretical Perfection](adr/ADR-003-success-over-theoretical-perfection.md).

## 4. Informatiebronnen

Een aanbeveling wordt gevoed door de volgende bronnen. Ze verschillen fundamenteel in beschikbaarheid, en dat verschil is net zo belangrijk als hun inhoud:

| Bron | Aard | Beschikbaarheid |
|---|---|---|
| Wetenschappelijke gezondheidsprincipes | Vaste, niet-persoonlijke kennisbasis | Altijd aanwezig |
| Persoonlijke doelen | Expliciet door de gebruiker aangegeven | Groeit gradueel |
| Persoonlijke gegevens | Voorkeuren, beperkingen, geschiedenis | Groeit gradueel |
| Context | Tijdstip, dag, weer, seizoen | Variabel, buiten de gebruiker om |
| Externe databronnen (bv. smartwatch) | Verrijkende meetgegevens | **Optioneel, nooit verplicht** |
| Sociale gezondheid | Geen zelfstandige bron | Alleen aanwezig als eigenschap ván een andere bron |

**Externe databronnen** verrijken een aanbeveling waar beschikbaar, maar zijn nooit een vereiste om een aanbeveling te kunnen doen.

→ Zie [ADR-004 — Optional Data Never Required](adr/ADR-004-optional-data-never-required.md).

**Sociale gezondheid** is expliciet **geen eigen aanbevelingscategorie**. Het is geen bron waaruit een aanbeveling kan ontstaan, maar een eigenschap die een aanbeveling — gebaseerd op een van de bronnen hierboven — kan versterken.

## 5. Verder lezen

- [Decision Framework](decision-framework.md) — hoe deze eisen en bronnen zich tot elkaar verhouden, inclusief prioriteit bij conflicten, intentie versus activiteit, en omgaan met onzekerheid.
- [Product Discovery](product-discovery.md) — wie de eerste gebruiker is en welke ervaring wordt nagestreefd.
- [BRAND_BOOK.md](../BRAND_BOOK.md) — hoe THIRTY voelt, klinkt en communiceert; leidend voor toon en emotionele ervaring in elke aanbeveling.
