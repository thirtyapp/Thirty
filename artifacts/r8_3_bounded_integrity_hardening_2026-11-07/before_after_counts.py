"""R8.3 — per-file pass/fail of the R8.3 test files: on the R8.2 export
(repro_before_fix) and in the definitive regression (regression/).

Usage (from the repository root):
  python -I artifacts/r8_3_bounded_integrity_hardening_2026-11-07/before_after_counts.py
"""
import glob
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')
HERE = os.path.join('artifacts', 'r8_3_bounded_integrity_hardening_2026-11-07')


def per_file(logs):
    out = {}
    for log in logs:
        suites, tests = {}, {}
        for line in open(log, encoding='utf-8', errors='replace'):
            if not line.startswith('{'):
                continue
            try:
                e = json.loads(line)
            except ValueError:
                continue
            kind = e.get('type')
            if kind == 'suite':
                suites[e['suite']['id']] = e['suite']['path'].replace(chr(92), '/').split('/test/')[-1]
            elif kind == 'testStart':
                tests[e['test']['id']] = suites.get(e['test']['suiteID'], '')
            elif kind == 'testDone' and not e.get('hidden'):
                f = tests[e['testID']]
                if not f.startswith('features/r83/'):
                    continue
                counts = out.setdefault(f, [0, 0])
                counts[0 if e['result'] == 'success' else 1] += 1
    return out


before = per_file([os.path.join(HERE, 'repro_before_fix', 'r83_on_r82.jsonl')])
after = per_file(sorted(glob.glob(os.path.join(HERE, 'regression', 'batch_*.jsonl'))))
print(f"{'file':42s} {'R8.2 pass/fail':>15s} {'R8.3 pass/fail':>15s}")
tb, ta = [0, 0], [0, 0]
for f in sorted(set(before) | set(after)):
    b, a = before.get(f, [0, 0]), after.get(f, [0, 0])
    tb = [tb[0] + b[0], tb[1] + b[1]]
    ta = [ta[0] + a[0], ta[1] + a[1]]
    print(f'{f:42s} {b[0]:>7d}/{b[1]:<7d} {a[0]:>7d}/{a[1]:<7d}')
print(f"{'TOTAL':42s} {tb[0]:>7d}/{tb[1]:<7d} {ta[0]:>7d}/{ta[1]:<7d}")
