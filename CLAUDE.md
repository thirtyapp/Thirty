# CLAUDE.md — Ontwikkelhandboek THIRTY

Dit document is het naslagwerk voor iedereen (en elke AI-assistent) die aan **THIRTY** werkt. Het beschrijft hoe we werken, niet alleen wat we bouwen.

## 1. Product in het kort

- **Naam:** THIRTY
- **Positionering:** AI Health Companion
- **Slogan:** "Your healthiest 30 minutes."
- **Kernidee:** THIRTY helpt gebruikers om dagelijks 30 minuten te investeren in hun gezondheid, ondersteund door AI-gedreven inzichten en begeleiding.

Zie [docs/VISION.md](docs/VISION.md) voor de volledige productvisie en [docs/ROADMAP.md](docs/ROADMAP.md) voor de fasering.

## Product Principles

Kort, ter oriëntatie: THIRTY voelt rustig en eenvoudig aan, motiveert zonder schuldgevoel, toont één primaire actie per scherm, en is consistent in design en interactie.

Dit is een samenvatting, geen normatieve definitie. [docs/BRAND_BOOK.md](docs/BRAND_BOOK.md) is de source of truth voor merk-, emotionele en UX-principes — zie met name [The Golden Rule](docs/BRAND_BOOK.md#1-the-golden-rule) ("voelt dit rustiger, eenvoudiger en menselijker dan het alternatief?"), [Core Values](docs/BRAND_BOOK.md#6-core-values) en [Design Principles](docs/BRAND_BOOK.md#11-design-principles). Raadpleeg dat document bij elke ontwerp-, product- of communicatiebeslissing; wijzig deze samenvatting niet zonder BRAND_BOOK.md eerst bij te werken.

Responsiviteit is een technische kwaliteitseis, geen apart merkprincipe. Vloeiende beweging/animatie is normatief uitgewerkt in [docs/BRAND_BOOK.md, Motion](docs/BRAND_BOOK.md#16-motion).

## AI Principles

Voeg alleen AI-functionaliteit toe die een duidelijk gebruikersprobleem oplost — nooit omdat het technisch mogelijk is. Dit is een grens voor engineeringbeslissingen, in dezelfde lijn als "geen overengineering" (zie [Manier van werken](#4-manier-van-werken)).

Voor hoe de AI-companion zich vervolgens gedraagt en klinkt — terughoudend, alleen spreken waar het waarde toevoegt, nooit om aanwezig te lijken — is [docs/BRAND_BOOK.md, Brand Promise](docs/BRAND_BOOK.md#5-brand-promise) leidend. Voor de aanbevelingslogica zelf (wat een aanbeveling moet zijn en hoe ze tot stand komt) is [docs/product/](docs/product/README.md) leidend.

## 2. Technische uitgangspunten

| Onderdeel | Keuze |
|---|---|
| Framework | Flutter + Dart |
| Platformfocus | Mobile-first |
| State management | Riverpod |
| Navigatie | GoRouter |
| Backend | Supabase |
| Architectuur | Feature-first |

Deze keuzes liggen vast. Wijzig ze niet impliciet via een losse taak — een architectuur- of dependencywijziging is een expliciete beslissing, geen bijvangst van een feature.

## 3. Architectuurprincipe: feature-first

Code wordt georganiseerd rond features, niet rond technische lagen op het hoogste niveau. Een feature bundelt zijn eigen data-, domein- en presentatiecode. Gedeelde bouwstenen (theming, routing, netwerklaag, utilities) horen in een `core`/`shared`-achtige plek, niet verspreid over features.

Concrete mapstructuur wordt pas vastgelegd op het moment dat de eerste feature wordt gebouwd — niet vooraf uit voorzorg aangemaakt.

## Development Philosophy

Bouw eerst een werkende oplossing.

Verbeter daarna de structuur.

Optimaliseer pas als daar een duidelijke reden voor is.

Voorkom premature optimization.

## 4. Manier van werken

- **Eerst analyseren en plannen, dan pas wijzigen.** Geen code schrijven voordat de aanpak helder is en waar relevant is afgestemd.
- **Kleine, veilige wijzigingen.** Liever meerdere kleine, goed te overzien stappen dan één grote wijziging.
- **Geen overengineering.** Bouw wat nodig is voor de huidige stap. Geen abstracties, configuratie of flexibiliteit voor hypothetische toekomstige behoeften.
- **Leesbare, onderhoudbare code.** Duidelijke namen boven commentaar. Commentaar alleen waar de *waarom* niet vanzelfsprekend is.
- **Geen ongevraagde scope-uitbreiding.** Een bugfix blijft een bugfix; een taak wordt niet stilzwijgend een refactor.
- **Wijzigingen zijn traceerbaar.** Wat is aangemaakt, wat is gewijzigd, en waarom — dat wordt na afloop van een taak samengevat.

## Definition of Done

Een taak is pas afgerond wanneer:

- flutter analyze succesvol is.
- flutter test succesvol is (indien van toepassing).
- Geen debug-code of tijdelijke TODO's achterblijven.
- De code leesbaar en onderhoudbaar is.
- De wijzigingen kort zijn samengevat.

## 5. Wat hier (nog) niet gebeurt

Dit is een document uit de opstartfase van het project. Op dit moment geldt nog:

- Geen functionaliteit/appcode.
- Geen packages/dependencies installeren buiten wat al in `pubspec.yaml` staat.
- Geen platformmappen verwijderen of toevoegen.
- Geen CI/CD-opzet.

Deze beperkingen worden losgelaten naarmate het project vordert, in overleg en stap voor stap — niet automatisch.

## 6. Documentatie-overzicht

- [README.md](README.md) — introductie voor iedereen die het project voor het eerst opent.
- [docs/VISION.md](docs/VISION.md) — waarom THIRTY bestaat en voor wie.
- [docs/BRAND_BOOK.md](docs/BRAND_BOOK.md) — hoe THIRTY voelt, klinkt en eruitziet.
- [docs/playbook/README.md](docs/playbook/README.md) — de THIRTY Playbook: de volledige merk-, ervarings-, ontwerp- en besluitvormingsfilosofie, voortbouwend op BRAND_BOOK.md.
- [docs/ROADMAP.md](docs/ROADMAP.md) — de globale fasering van het project.
- [docs/product/README.md](docs/product/README.md) — de productkennisbasis: aanbevelingsfilosofie, decision framework, onboarding-principes en ADR's.
