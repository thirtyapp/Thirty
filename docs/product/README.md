# THIRTY — Productkennis

Dit is de productkennisbasis van THIRTY: waarom aanbevelingen worden gedaan zoals ze worden gedaan, wie de eerste gebruiker is, en welke onboarding-beslissingen zijn vastgesteld. Dit document is uitsluitend **navigatie** — het bevat zelf geen productbeslissingen.

## Leeswijzer

Lees in deze volgorde voor het volledige beeld:

1. **[VISION.md](../VISION.md)** *(root van `docs/`)* — waarom THIRTY bestaat en voor wie. De visie waar geen enkel ander document tegenin mag gaan.
2. **[BRAND_BOOK.md](../BRAND_BOOK.md)** *(root van `docs/`)* — hoe THIRTY voelt, klinkt en eruitziet: toon, emotionele reis, algemene UX-ontwerpprincipes.
3. **[CLAUDE.md](../../CLAUDE.md)** *(repository-root)* — hoe we werken: technische uitgangspunten, productprincipes, ontwikkelwerkwijze.
4. **[recommendation-philosophy.md](recommendation-philosophy.md)** — wát een aanbeveling van THIRTY moet zijn: de niet-onderhandelbare eisen en de informatiebronnen.
5. **[decision-framework.md](decision-framework.md)** — hóe die eisen en bronnen zich tot elkaar verhouden: prioriteit, conflictoplossing, onzekerheid.
6. **[product-discovery.md](product-discovery.md)** — wie de eerste gebruiker is, welke ervaring wordt nagestreefd, en welke vragen daarover nog open staan.
7. **[onboarding-principles.md](onboarding-principles.md)** — de vastgestelde, onboarding-specifieke principes die uit Product Discovery zijn gedestilleerd.
8. **[adr/](adr/)** — de losse, gedateerde beslissingen die aan bovenstaande documenten ten grondslag liggen.

## Wie is leidend bij overlap

| Vraag | Leidend document |
|---|---|
| Waarom bestaat THIRTY, voor wie? | [VISION.md](../VISION.md) |
| Hoe voelt, klinkt en ziet THIRTY eruit? | [BRAND_BOOK.md](../BRAND_BOOK.md) |
| Hoe werken we (proces, techniek, algemene productprincipes)? | [CLAUDE.md](../../CLAUDE.md) |
| Wat moet een aanbeveling waar maken? | [recommendation-philosophy.md](recommendation-philosophy.md) |
| Wat wint als twee geldige signalen botsen? | [decision-framework.md](decision-framework.md) |
| Wie is de eerste gebruiker, wat is nog onbeslist? | [product-discovery.md](product-discovery.md) |
| Wat is de vastgestelde onboarding-aanpak? | [onboarding-principles.md](onboarding-principles.md) |
| Waarom is een specifiek besluit genomen, en wanneer? | de betreffende [ADR](adr/) |

Bij elk conflict geldt: **[VISION.md](../VISION.md) wint altijd** — geen enkel ander document mag de visie tegenspreken. Voor toon en emotionele ervaring geldt hetzelfde voorrangsrecht voor [BRAND_BOOK.md](../BRAND_BOOK.md): de documenten in deze map herhalen de brand-principes niet, ze verwijzen ernaar.

## Hoe ADR's werken

Een ADR (Architecture/Product Decision Record) legt één specifieke, vaak onomkeerbare beslissing vast: wat is besloten, waarom, en welke alternatieven zijn overwogen. Elke ADR volgt hetzelfde sjabloon: **Status, Context, Beslissing, Reden, Consequenties, Gerelateerde documenten.**

- Een ADR beschrijft één beslissing — geen bredere filosofie. Bredere redenering hoort in `recommendation-philosophy.md` of `decision-framework.md`.
- Status is een van: `Proposed`, `Accepted`, `Superseded by ADR-00X`.
- Wanneer een latere beslissing een eerdere ADR tegenspreekt, wordt er een nieuwe ADR aangemaakt en wordt de oude expliciet gemarkeerd als `Superseded by ADR-00X` — een ADR wordt nooit stilzwijgend herschreven.
- Elke ADR verwijst terug naar het document (philosophy, framework, of discovery) waar de beslissing uit voortkomt.

## Huidige ADR's

- [ADR-001 — Best Investment of 30 Minutes](adr/ADR-001-best-investment-of-30-minutes.md)
- [ADR-002 — Recommendations Must Be Explainable](adr/ADR-002-recommendations-must-be-explainable.md)
- [ADR-003 — Success Over Theoretical Perfection](adr/ADR-003-success-over-theoretical-perfection.md)
- [ADR-004 — Optional Data Never Required](adr/ADR-004-optional-data-never-required.md)
- [ADR-005 — Intent Before Activity](adr/ADR-005-intent-before-activity.md)
- [ADR-006 — No Account Before First Value](adr/ADR-006-no-account-before-first-value.md)
- [ADR-007 — Premium Never Blocks the Core Loop](adr/ADR-007-premium-never-blocks-the-core-loop.md)
- [ADR-008 — Learning Without Judgment](adr/ADR-008-learning-without-judgment.md)
