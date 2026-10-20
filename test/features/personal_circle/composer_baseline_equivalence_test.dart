import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/composer_baseline.dart';

/// ADR-024 B2 — the hard gate: without a StageBrief, the Personal Guided
/// Circle composer gives exactly the Circle it gave in B1, for every
/// representative day in [composerBaselineLines] — the same parts, basis,
/// score and trace.
///
/// The fixture was recorded from the B1 composer before the StageBrief seam
/// existed. Regenerate it (`UPDATE_COMPOSER_BASELINE=1 flutter test <this
/// file>`) only for a composer change the founder has approved.
void main() {
  const fixture =
      'test/features/personal_circle/fixtures/composer_b1_baseline.txt';

  test('no StageBrief: the composer is unchanged from B1', () {
    final lines = composerBaselineLines();
    final file = File(fixture);
    if (Platform.environment['UPDATE_COMPOSER_BASELINE'] == '1') {
      file.writeAsStringSync('${lines.join('\n')}\n');
    }
    final expected = file.readAsLinesSync();
    expect(lines.length, expected.length);
    for (var i = 0; i < lines.length; i++) {
      expect(lines[i], expected[i], reason: 'line ${i + 1}');
    }
  });
}
