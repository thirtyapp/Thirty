import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/domain/recommendation_engine.dart';
import 'package:thirty/features/plans/domain/plan_copy.dart';

/// ADR-024 B4 — Plans' live words never regress into a streak, a challenge,
/// a score or an outcome. Only string literals in the Plans feature are
/// checked — comments may name what the copy must never say.
void main() {
  const banned = [
    'complete your plan',
    'completed',
    'missed',
    'streak',
    'success rate',
    'improved',
    'works for you',
    'boosts',
    'reduces anxiety',
    'fixes focus',
    'five-day challenge',
    'daily plan',
    'stay on track',
    'well done',
    'congratulations',
    'achievement',
  ];

  /// Every single-quoted string literal outside comments.
  List<String> literals(String source) => [
    for (final line in source.split('\n'))
      if (!line.trimLeft().startsWith('//'))
        for (final m in RegExp(r"'((?:[^'\\]|\\.)*)'").allMatches(line))
          m.group(1)!,
  ];

  test('no Plan screen or Plan copy says any of it', () {
    final files = [
      for (final f in Directory('lib/features/plans').listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart')) f,
      File('lib/features/home/presentation/widgets/today_card.dart'),
    ];
    for (final file in files) {
      for (final text in literals(file.readAsStringSync())) {
        final lower = text.toLowerCase();
        for (final word in banned) {
          expect(lower, isNot(contains(word)), reason: '${file.path}: $text');
        }
      }
    }
  });

  test('the generated lines too', () {
    final generated = [
      PlanCopy.ready(Intention.moreEnergy),
      PlanCopy.next(Intention.clearerHead),
      PlanCopy.paused(3),
      PlanCopy.lapsed(3),
      PlanCopy.reachedEnd(4, 1),
      PlanCopy.reachedEnd(5, 0),
      PlanCopy.left(3, 0),
      PlanCopy.severalPositive(['Out of your head', 'Down to one']),
      PlanCopy.bothTimes('Room around you', PastUsefulness.veryUseful),
      PlanCopy.switchBody('Making room', 'Getting going', 3),
      PlanCopy.guidedOn('12 Oct'),
    ];
    for (final line in generated) {
      for (final word in [...banned, 'done', 'complete', '%']) {
        expect(line.toLowerCase(), isNot(contains(word)), reason: line);
      }
    }
    // "Guided", never "done": the five-stage end says so only when true.
    expect(PlanCopy.reachedEnd(5, 0), contains('All five stages guided'));
    expect(PlanCopy.reachedEnd(4, 1), isNot(contains('All five')));
  });
}
