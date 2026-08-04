import '../../activity_category.dart';
import '../place.dart';
import '../world_registry.dart';

/// THIRTY's first reference World: Walking's "Quiet Trail"
/// (WORLD_SYSTEM.md §15, "Walking World v1"; "World DNA").
///
/// This is data only — no rendering. THIRTY's current Home screen still
/// renders Walking directly via
/// `lib/features/home/presentation/illustrations/walking_illustration.dart`;
/// this Place exists so the World Engine has one real, non-hypothetical
/// identity to compose and test against while a concrete presentation
/// contract for it — introduced once Quiet Trail's Hero and Activity Card
/// rendering provides real implementation evidence — remains a future,
/// separate task.
const quietTrail = Place(
  category: ActivityCategory.walking,
  name: 'Quiet Trail',
  emotion: 'Invitation',
  primaryActivity: 'Walking',
  dominantShape: 'Winding path through rolling hills',
  heroFocus: 'One organic tree on a distant hill, path winding toward it',
  cardFocus: 'Same tree, same path, same horizon, simplified to line art',
  primaryLight: 'Diffuse morning light, soft sunrise atmosphere',
  movement:
      'Minimal — a few birds, subtle atmospheric drift; never game-like',
  growthElements: [
    'Flowers appearing along the path',
    'The tree becoming fuller',
    'A bench appearing over time',
  ],
);

/// THIRTY's production [WorldRegistry]. Walking → Quiet Trail is the only
/// entry today — WORLD_SYSTEM.md §16 names Meditation, Reading and
/// Stretching only as placeholders, with no approved Place yet. Adding a
/// future category means adding one more entry here; `WorldRegistry` and
/// `WorldComposer` stay unchanged.
final defaultWorldRegistry = WorldRegistry({
  ActivityCategory.walking: [quietTrail],
});
