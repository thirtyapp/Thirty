# THIRTY — Roadmap

Deze roadmap beschrijft de globale fasering van het project op hoofdlijnen. Het is geen gedetailleerde planning met deadlines, maar een leidraad voor de volgorde waarin THIRTY wordt opgebouwd.

Status van elke fase wordt bijgewerkt zodra deze start of afgerond is.

## Fase 0 — Projectfundament (huidig)

**Status: bezig**

Doel: een professionele, goed gedocumenteerde basis neerzetten voordat er functionaliteit wordt gebouwd.

- [x] Analyse van de Flutter-projectstructuur.
- [x] Documentatiebasis: `CLAUDE.md`, `README.md`, `docs/VISION.md`, `docs/ROADMAP.md`.
- [ ] Definitieve beslissing over te behouden platforms (mobile-first; overige platformmappen worden later bewust beoordeeld).
- [ ] Vastleggen van projectconventies (codestijl, commitconventies) indien nodig aanvullend op dit document.

## Fase 1 — Technisch fundament

Doel: de gekozen technische bouwstenen daadwerkelijk inrichten, nog zonder productfunctionaliteit.

- [x] Basis feature-first mapstructuur opzetten in `lib/`.
- [x] Riverpod als state management inrichten.
- [x] GoRouter als navigatieoplossing inrichten.
- [x] Supabase-project koppelen (configuratie, geen datamodel nog).
- [x] Basis theming en app-shell.

## Fase 2 — MVP: de eerste 30 minuten

Doel: de kernbelofte van THIRTY werkend krijgen voor een eerste groep gebruikers — geen volledige featureset, wel een samenhangende, bruikbare eerste ervaring.

- [ ] Gebruikersonboarding (wie is de gebruiker, wat is het startpunt).
- [ ] Dagelijkse "30 minuten"-invulling: het kernmechanisme van de app.
- [ ] Basale voortgangsweergave.
- [ ] Eerste versie van AI-ondersteuning bij de invulling van de 30 minuten.

## Fase 3 — Verdieping en personalisatie

Doel: de AI-companion-belofte verder waarmaken.

- [ ] Persoonlijkere aanbevelingen op basis van gedrag en voorkeuren.
- [ ] Inzicht in patronen over tijd, zonder overweldigende data-dumps.
- [ ] Verfijning van de begeleidende toon en interactie van de AI-companion.

## Fase 4 — Schaal en kwaliteit

Doel: het product klaarmaken voor een grotere en bredere gebruikersgroep.

- [ ] Prestatie-, stabiliteits- en toegankelijkheidsverbeteringen.
- [ ] CI/CD-opzet (bewust uitgesteld tot het project daar klaar voor is).
- [ ] Eventuele uitbreiding naar aanvullende platforms, indien de mobile-first-ervaring dit rechtvaardigt.

## Uitgangspunten die de hele roadmap doorkruisen

Zie [CLAUDE.md](../CLAUDE.md) voor de volledige werkwijze. Kernpunten die op elke fase van toepassing blijven:

- Eerst analyseren en plannen, dan pas bouwen.
- Kleine, veilige, goed te overziene wijzigingen.
- Geen overengineering: bouwen wat de huidige fase nodig heeft.
- Leesbare, onderhoudbare code boven snelle trucs.

Deze roadmap is een levend document en wordt bijgewerkt naarmate inzichten veranderen — niet in beton gegoten.
