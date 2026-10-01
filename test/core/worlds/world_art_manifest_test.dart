import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/worlds/catalog/garden_window.dart';
import 'package:thirty/core/worlds/catalog/quiet_trail.dart';
import 'package:thirty/core/worlds/registered_world_art.dart';
import 'package:thirty/core/worlds/registered_worlds.dart';
import 'package:thirty/core/worlds/world.dart';
import 'package:thirty/core/worlds/world_art_manifest.dart';
import 'package:thirty/core/worlds/world_definition.dart';
import 'package:thirty/core/worlds/world_registry.dart';

/// The one production path shape (ADR-018; WORLD_SYSTEM.md §10).
final _productionPath = RegExp(
  r'^assets/worlds/([a-z][a-z0-9_]*)/([a-z][a-z0-9_]*)/'
  r'(hero|card)_(morning|day|evening)\.webp$',
);

WorldSceneArt _artIn(String folder) => WorldSceneArt(
  heroMorning: '$folder/hero_morning.webp',
  heroDay: '$folder/hero_day.webp',
  heroEvening: '$folder/hero_evening.webp',
  cardMorning: '$folder/card_morning.webp',
  cardDay: '$folder/card_day.webp',
  cardEvening: '$folder/card_evening.webp',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('V1 World art — completeness (ADR-018: 9 × 2 × 3 = 54)', () {
    test('there are exactly 9 registered Scenes and each has artwork', () {
      expect(worldRegistry.scenes, hasLength(9));
      expect(
        v1WorldArtManifest.sceneIds.toSet(),
        worldRegistry.scenes.map((scene) => scene.id).toSet(),
      );
    });

    test('exactly 54 distinct asset paths are mapped', () {
      final all = [
        for (final id in v1WorldArtManifest.sceneIds)
          ...v1WorldArtManifest.art(id).assets,
      ];
      expect(all, hasLength(54));
      expect(all.toSet(), hasLength(54));
    });

    test('every Scene has exactly one Hero and one Card per Daypart, named '
        'for its own World, Scene, expression and Daypart', () {
      for (final scene in worldRegistry.scenes) {
        final art = v1WorldArtManifest.art(scene.id);
        final identities = <String>{};
        for (final daypart in Daypart.values) {
          final suffix = daypartArtworkSuffix(daypart);
          for (final (expression, path) in [
            ('hero', art.hero(daypart)),
            ('card', art.card(daypart)),
          ]) {
            final match = _productionPath.firstMatch(path);
            expect(match, isNotNull, reason: path);
            expect(match!.group(1), scene.id.world.value, reason: path);
            expect(match.group(2), scene.id.name, reason: path);
            expect(match.group(3), expression, reason: path);
            expect(match.group(4), suffix, reason: path);
            identities.add('$expression/$suffix');
          }
        }
        expect(identities, hasLength(6), reason: '${scene.id}');
      }
    });

    test('every mapped asset exists on disk', () {
      for (final id in v1WorldArtManifest.sceneIds) {
        for (final path in v1WorldArtManifest.art(id).assets) {
          expect(File(path).existsSync(), isTrue, reason: path);
        }
      }
    });

    test('every mapped asset is in the Flutter asset bundle, and no source '
        'or exploration artwork is', () async {
      final bundled = (await AssetManifest.loadFromAssetBundle(
        rootBundle,
      )).listAssets().toSet();
      for (final id in v1WorldArtManifest.sceneIds) {
        for (final path in v1WorldArtManifest.art(id).assets) {
          expect(bundled, contains(path));
        }
      }
      for (final asset in bundled) {
        expect(asset, isNot(startsWith('artwork/')));
        expect(asset, isNot(contains('_exploration')));
      }
      // Besides the 54, only the Quiet Trail master (debug preview route)
      // ships from assets/worlds/ — no older preview PNG.
      expect(
        bundled.where((asset) => asset.startsWith('assets/worlds/')).toSet(),
        {
          for (final id in v1WorldArtManifest.sceneIds)
            ...v1WorldArtManifest.art(id).assets,
          'assets/worlds/quiet_trail/quiet_trail_hero_master_v1.png',
        },
      );
    });

    test('no mapped asset is exploration, source or legacy artwork', () {
      for (final id in v1WorldArtManifest.sceneIds) {
        for (final path in v1WorldArtManifest.art(id).assets) {
          expect(path, isNot(contains('_exploration')));
          expect(path, isNot(startsWith('artwork/')));
          expect(path, isNot(endsWith('.png')));
        }
      }
    });
  });

  group('daypartArtworkSuffix', () {
    test('afternoon artwork is named "day"', () {
      expect(daypartArtworkSuffix(Daypart.morning), 'morning');
      expect(daypartArtworkSuffix(Daypart.afternoon), 'day');
      expect(daypartArtworkSuffix(Daypart.evening), 'evening');
    });
  });

  group('WorldArtManifest — validation', () {
    final registry = WorldRegistry([quietTrailWorld, gardenWindowWorld]);
    WorldSceneArt art(WorldSceneId id) =>
        _artIn('assets/worlds/${id.world}/${id.name}');

    test('accepts artwork for every registered Scene', () {
      expect(
        () => WorldArtManifest(registry, {
          for (final scene in registry.scenes) scene.id: art(scene.id),
        }),
        returnsNormally,
      );
    });

    test('a registered Scene without artwork fails — no fallback', () {
      expect(
        () => WorldArtManifest(registry, {
          QuietTrailScenes.walk: art(QuietTrailScenes.walk),
          GardenWindowScenes.comfort: art(GardenWindowScenes.comfort),
        }),
        throwsArgumentError,
      );
    });

    test('artwork for an unregistered Scene fails', () {
      const unknown = WorldSceneId(WorldId('forest_path'), 'walk');
      expect(
        () => WorldArtManifest(registry, {
          for (final scene in registry.scenes) scene.id: art(scene.id),
          unknown: art(unknown),
        }),
        throwsArgumentError,
      );
    });

    test('one asset mapped twice fails — never duplicated to fill a gap', () {
      expect(
        () => WorldArtManifest(registry, {
          QuietTrailScenes.walk: art(QuietTrailScenes.walk),
          GardenWindowScenes.tend: art(GardenWindowScenes.comfort),
          GardenWindowScenes.comfort: art(GardenWindowScenes.comfort),
        }),
        throwsArgumentError,
      );
    });

    test('art() for a Scene without artwork throws', () {
      final manifest = WorldArtManifest(WorldRegistry([quietTrailWorld]), {
        QuietTrailScenes.walk: art(QuietTrailScenes.walk),
      });
      expect(() => manifest.art(GardenWindowScenes.tend), throwsStateError);
    });
  });
}
