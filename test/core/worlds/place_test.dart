import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/activity_category.dart';
import 'package:thirty/core/worlds/place.dart';

const _samplePlace = Place(
  category: ActivityCategory.walking,
  name: 'Quiet Trail',
  emotion: 'Invitation',
  primaryActivity: 'Walking',
  dominantShape: 'Winding path through rolling hills',
  heroFocus: 'One organic tree on a distant hill',
  cardFocus: 'Same tree, same path, same horizon',
  primaryLight: 'Diffuse morning light',
  movement: 'Minimal — a few birds, subtle atmospheric drift',
  growthElements: ['Flowers appearing along the path'],
);

void main() {
  group('Place', () {
    test('is equal to another Place with the same category and name', () {
      const other = Place(
        category: ActivityCategory.walking,
        name: 'Quiet Trail',
        emotion: 'A different emotion string entirely',
        primaryActivity: 'Walking',
        dominantShape: 'A different shape',
        heroFocus: 'A different focus',
        cardFocus: 'A different focus',
        primaryLight: 'A different light',
        movement: 'A different movement',
        growthElements: [],
      );

      expect(_samplePlace, other);
      expect(_samplePlace.hashCode, other.hashCode);
    });

    test('is not equal to a Place with a different name', () {
      const other = Place(
        category: ActivityCategory.walking,
        name: 'Still Lake',
        emotion: 'Invitation',
        primaryActivity: 'Walking',
        dominantShape: 'Winding path through rolling hills',
        heroFocus: 'One organic tree on a distant hill',
        cardFocus: 'Same tree, same path, same horizon',
        primaryLight: 'Diffuse morning light',
        movement: 'Minimal — a few birds, subtle atmospheric drift',
        growthElements: ['Flowers appearing along the path'],
      );

      expect(_samplePlace, isNot(other));
    });
  });
}
