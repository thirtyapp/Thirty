import 'catalog/garden_window.dart';
import 'catalog/open_room.dart';
import 'catalog/quiet_trail.dart';
import 'catalog/reading_nook.dart';
import 'catalog/still_lake.dart';
import 'registered_worlds.dart';
import 'world_art_manifest.dart';

/// The V1 Scene × Daypart artwork pack (ADR-018): 9 Scenes × Hero and Card
/// × 3 Dayparts = 54 assets, derived from the approved sources under
/// `artwork/worlds/` (WORLD_ART_ASSET_FREEZE_RECONCILIATION_2026-09-29.md).
/// Adding a World means adding its Scenes' artwork here.
final v1WorldArtManifest = WorldArtManifest(worldRegistry, {
  QuietTrailScenes.walk: const WorldSceneArt(
    heroMorning: 'assets/worlds/quiet_trail/walk/hero_morning.webp',
    heroDay: 'assets/worlds/quiet_trail/walk/hero_day.webp',
    heroEvening: 'assets/worlds/quiet_trail/walk/hero_evening.webp',
    cardMorning: 'assets/worlds/quiet_trail/walk/card_morning.webp',
    cardDay: 'assets/worlds/quiet_trail/walk/card_day.webp',
    cardEvening: 'assets/worlds/quiet_trail/walk/card_evening.webp',
  ),
  StillLakeScenes.breathe: const WorldSceneArt(
    heroMorning: 'assets/worlds/still_lake/breathe/hero_morning.webp',
    heroDay: 'assets/worlds/still_lake/breathe/hero_day.webp',
    heroEvening: 'assets/worlds/still_lake/breathe/hero_evening.webp',
    cardMorning: 'assets/worlds/still_lake/breathe/card_morning.webp',
    cardDay: 'assets/worlds/still_lake/breathe/card_day.webp',
    cardEvening: 'assets/worlds/still_lake/breathe/card_evening.webp',
  ),
  OpenRoomScenes.move: const WorldSceneArt(
    heroMorning: 'assets/worlds/open_room/move/hero_morning.webp',
    heroDay: 'assets/worlds/open_room/move/hero_day.webp',
    heroEvening: 'assets/worlds/open_room/move/hero_evening.webp',
    cardMorning: 'assets/worlds/open_room/move/card_morning.webp',
    cardDay: 'assets/worlds/open_room/move/card_day.webp',
    cardEvening: 'assets/worlds/open_room/move/card_evening.webp',
  ),
  OpenRoomScenes.stretch: const WorldSceneArt(
    heroMorning: 'assets/worlds/open_room/stretch/hero_morning.webp',
    heroDay: 'assets/worlds/open_room/stretch/hero_day.webp',
    heroEvening: 'assets/worlds/open_room/stretch/hero_evening.webp',
    cardMorning: 'assets/worlds/open_room/stretch/card_morning.webp',
    cardDay: 'assets/worlds/open_room/stretch/card_day.webp',
    cardEvening: 'assets/worlds/open_room/stretch/card_evening.webp',
  ),
  ReadingNookScenes.read: const WorldSceneArt(
    heroMorning: 'assets/worlds/reading_nook/read/hero_morning.webp',
    heroDay: 'assets/worlds/reading_nook/read/hero_day.webp',
    heroEvening: 'assets/worlds/reading_nook/read/hero_evening.webp',
    cardMorning: 'assets/worlds/reading_nook/read/card_morning.webp',
    cardDay: 'assets/worlds/reading_nook/read/card_day.webp',
    cardEvening: 'assets/worlds/reading_nook/read/card_evening.webp',
  ),
  ReadingNookScenes.write: const WorldSceneArt(
    heroMorning: 'assets/worlds/reading_nook/write/hero_morning.webp',
    heroDay: 'assets/worlds/reading_nook/write/hero_day.webp',
    heroEvening: 'assets/worlds/reading_nook/write/hero_evening.webp',
    cardMorning: 'assets/worlds/reading_nook/write/card_morning.webp',
    cardDay: 'assets/worlds/reading_nook/write/card_day.webp',
    cardEvening: 'assets/worlds/reading_nook/write/card_evening.webp',
  ),
  ReadingNookScenes.listen: const WorldSceneArt(
    heroMorning: 'assets/worlds/reading_nook/listen/hero_morning.webp',
    heroDay: 'assets/worlds/reading_nook/listen/hero_day.webp',
    heroEvening: 'assets/worlds/reading_nook/listen/hero_evening.webp',
    cardMorning: 'assets/worlds/reading_nook/listen/card_morning.webp',
    cardDay: 'assets/worlds/reading_nook/listen/card_day.webp',
    cardEvening: 'assets/worlds/reading_nook/listen/card_evening.webp',
  ),
  GardenWindowScenes.tend: const WorldSceneArt(
    heroMorning: 'assets/worlds/garden_window/tend/hero_morning.webp',
    heroDay: 'assets/worlds/garden_window/tend/hero_day.webp',
    heroEvening: 'assets/worlds/garden_window/tend/hero_evening.webp',
    cardMorning: 'assets/worlds/garden_window/tend/card_morning.webp',
    cardDay: 'assets/worlds/garden_window/tend/card_day.webp',
    cardEvening: 'assets/worlds/garden_window/tend/card_evening.webp',
  ),
  GardenWindowScenes.comfort: const WorldSceneArt(
    heroMorning: 'assets/worlds/garden_window/comfort/hero_morning.webp',
    heroDay: 'assets/worlds/garden_window/comfort/hero_day.webp',
    heroEvening: 'assets/worlds/garden_window/comfort/hero_evening.webp',
    cardMorning: 'assets/worlds/garden_window/comfort/card_morning.webp',
    cardDay: 'assets/worlds/garden_window/comfort/card_day.webp',
    cardEvening: 'assets/worlds/garden_window/comfort/card_evening.webp',
    // The comfort Heroes carry a baked paper frame (up to ~4% of
    // their width) that would otherwise show at the Circle's edge.
    heroScale: 1.1,
  ),
});
