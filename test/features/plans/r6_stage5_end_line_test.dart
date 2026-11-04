import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/plans/domain/circle_plan.dart';
import 'package:thirty/features/plans/domain/plan_copy.dart';
import 'package:thirty/features/plans/presentation/plan_view.dart';

/// Audit remediation R6 (Audit #1 m1): a cycle with no last Circle says
/// what actually happened to its stages. "None of these stages was useful"
/// only when every stage was answered Not useful; when THIRTY set some
/// aside (their parts left out, resting or not to be suggested) and the
/// rest were Not useful, it says so; all set aside keeps its own line. The
/// choice reads the cycle's own stage records — nothing assumed. No action
/// is added or removed.
void main() {
  StageRecord guided(int n) => StageRecord(
    stageNumber: n,
    outcome: StageOutcome.guided,
    localDate: '2026-10-0$n',
    circleId: '2026-10-0$n',
  );
  StageRecord setAside(int n) => StageRecord(
    stageNumber: n,
    outcome: StageOutcome.setAside,
    localDate: '2026-10-0$n',
  );
  PlanCycle ended(CycleEnd end, List<StageRecord> records) => PlanCycle(
    id: 'making_room#1',
    number: 1,
    startedOn: '2026-10-01',
    cursor: 5,
    records: records,
    endedOn: '2026-10-05',
    end: end,
  );

  test('every stage answered Not useful: the existing line', () {
    final cycle = ended(CycleEnd.allRejected, [
      for (var n = 1; n <= 4; n++) guided(n),
    ]);
    expect(endLine(cycle), PlanCopy.allRejected);
  });

  test('some Not useful, the others set aside: the mixed line — never '
      '"none of these stages was useful"', () {
    final cycle = ended(CycleEnd.allRejected, [
      guided(1),
      guided(2),
      setAside(3),
      setAside(4),
    ]);
    expect(endLine(cycle), PlanCopy.someNotUsefulOthersSetAside);
    expect(endLine(cycle), isNot(PlanCopy.allRejected));
  });

  test(
    'a stage set aside and later guided counts as guided, not set aside',
    () {
      final cycle = ended(CycleEnd.allRejected, [
        setAside(1),
        guided(1),
        guided(2),
        guided(3),
        guided(4),
      ]);
      expect(endLine(cycle), PlanCopy.allRejected);
    },
  );

  test('every stage set aside: its own line, unchanged', () {
    final cycle = ended(CycleEnd.allSetAside, [
      for (var n = 1; n <= 4; n++) setAside(n),
    ]);
    expect(endLine(cycle), PlanCopy.allSetAside);
  });

  test('the all-set-aside line names all three reasons, exactly', () {
    expect(
      PlanCopy.allSetAside,
      'Every stage of this Plan uses parts you’ve left out, asked THIRTY not '
      'to suggest, or that are resting for now.',
    );
  });

  test('the mixed line, exactly', () {
    expect(
      PlanCopy.someNotUsefulOthersSetAside,
      'Some stages didn’t feel useful, and THIRTY set the others aside. It '
      'hasn’t made a last Circle from them.',
    );
  });
}
