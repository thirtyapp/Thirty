import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/worlds/place.dart';

Place _place({
  String name = 'Quiet Trail',
  String emotion = 'Invitation',
  String cardFocus = 'Same tree, same path, same horizon',
  List<String> growthElements = const ['Flowers appearing along the path'],
}) {
  return Place(
    name: name,
    emotion: emotion,
    primaryActivity: 'Walking',
    dominantShape: 'Winding path through rolling hills',
    heroFocus: 'One organic tree on a distant hill',
    cardFocus: cardFocus,
    primaryLight: 'Diffuse morning light',
    movement: 'Minimal — a few birds, subtle atmospheric drift',
    growthElements: growthElements,
  );
}

void main() {
  group('Place', () {
    test('is equal to a Place with identical DNA', () {
      final a = _place(growthElements: ['Flowers appearing along the path']);
      final b = _place(growthElements: ['Flowers appearing along the path']);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('is not equal when only the name differs', () {
      expect(_place(), isNot(_place(name: 'Still Lake')));
    });

    test('is not equal when any other DNA field differs — the display name '
        'is not an identity key', () {
      expect(_place(), isNot(_place(emotion: 'Stillness')));
      expect(_place(), isNot(_place(cardFocus: 'A different focus')));
      expect(_place(), isNot(_place(growthElements: const [])));
    });
  });
}
