import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/worlds/daypart.dart';
import 'package:thirty/core/worlds/world.dart';

DateTime _at(int hour, int minute) => DateTime(2026, 9, 27, hour, minute);

void main() {
  group('daypartAt', () {
    const cases = {
      (0, 0): Daypart.evening,
      (2, 0): Daypart.evening,
      (4, 59): Daypart.evening,
      (5, 0): Daypart.morning,
      (11, 59): Daypart.morning,
      (12, 0): Daypart.afternoon,
      (17, 59): Daypart.afternoon,
      (18, 0): Daypart.evening,
      (23, 59): Daypart.evening,
    };

    cases.forEach((time, expected) {
      final (hour, minute) = time;
      final label =
          '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')}';
      test('$label is ${expected.name}', () {
        expect(daypartAt(_at(hour, minute)), expected);
      });
    });
  });
}
