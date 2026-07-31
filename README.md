# THIRTY

**AI Health Companion**
*"Your healthiest 30 minutes."*

THIRTY helpt gebruikers om dagelijks 30 gerichte minuten in hun gezondheid te investeren, ondersteund door AI-gedreven inzichten en begeleiding.

Voor de volledige productvisie, zie [docs/VISION.md](docs/VISION.md).
Voor de merk-, ervarings-, ontwerp- en besluitvormingsfilosofie, zie de [THIRTY Playbook](docs/playbook/README.md).
Voor de fasering van het project, zie [docs/ROADMAP.md](docs/ROADMAP.md).
Voor de ontwikkelwerkwijze en technische uitgangspunten, zie [CLAUDE.md](CLAUDE.md).

## Status

Dit project bevindt zich in de fundamentfase: er is nog geen productfunctionaliteit gebouwd. Zie [docs/ROADMAP.md](docs/ROADMAP.md) voor de huidige fase.

## Techstack

- **Framework:** Flutter + Dart
- **Platformfocus:** Mobile-first
- **State management:** Riverpod
- **Navigatie:** GoRouter
- **Backend:** Supabase
- **Architectuur:** Feature-first

## Aan de slag

Vereisten: een werkende Flutter-installatie die overeenkomt met de SDK-constraint in `pubspec.yaml`.

```bash
flutter pub get
flutter run
```

## Projectstructuur

```
lib/            Applicatiecode (feature-first, wordt ingericht in Fase 1)
test/           Tests
docs/           Productdocumentatie (visie, roadmap)
android/ ios/   Platformspecifieke projecten
web/ ...        Overige platformmappen (mobile-first; scope wordt later bevestigd)
```

## Werkwijze

Dit project werkt met kleine, veilige wijzigingen: eerst analyseren en plannen, dan pas implementeren. Geen overengineering — er wordt gebouwd wat de huidige fase nodig heeft. Zie [CLAUDE.md](CLAUDE.md) voor de volledige werkwijze en conventies.

## Licentie

Nog niet vastgesteld.
