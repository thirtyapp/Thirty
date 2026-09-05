import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/utils/date_key.dart';

void main() {
  group('dateKey', () {
    test('formats a date as zero-padded YYYY-MM-DD', () {
      expect(dateKey(DateTime(2026, 8, 2)), '2026-08-02');
    });

    test('ignores the time-of-day component', () {
      expect(dateKey(DateTime(2026, 8, 2, 23, 59, 59)), '2026-08-02');
    });

    test('pads single-digit month and day', () {
      expect(dateKey(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });
}
