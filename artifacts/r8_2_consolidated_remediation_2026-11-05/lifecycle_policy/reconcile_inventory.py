"""Independent reconciliation of a regression run's test inventory against
its raw `flutter test --reporter json` logs (R8.2 lifecycle policy, 2026-11-06).

Usage (from the repository root):
  python -I <this> <run_dir> [<previous_run_dir>]

Checks, each printed with OK / MISMATCH:
- every *_test.dart file under test/ is in the run's plan inventory, and vice versa;
- every planned file appears as a suite in the raw logs;
- no (file, test name) pair ran twice; every visible test's result is success;
- with a previous run: per-file test counts, and which files changed count.
Exit 1 on any mismatch.
"""
import glob
import json
import os
import sys
from collections import Counter, defaultdict

sys.stdout.reconfigure(encoding='utf-8')


def raw(run_dir):
    pairs = Counter()
    results = Counter()
    per_file = defaultdict(int)
    suites = set()
    for log in sorted(glob.glob(os.path.join(run_dir, 'batch_*.jsonl'))):
        suite_paths, tests = {}, {}
        for line in open(log, encoding='utf-8'):
            try:
                e = json.loads(line)
            except ValueError:
                continue
            t = e.get('type')
            if t == 'suite':
                p = e['suite']['path'].replace('\\', '/')
                p = p[p.index('test/'):] if 'test/' in p else p
                suite_paths[e['suite']['id']] = p
                suites.add(p)
            elif t == 'testStart':
                tests[e['test']['id']] = (e['test']['suiteID'], e['test']['name'])
            elif t == 'testDone' and not e.get('hidden'):
                sid, name = tests[e['testID']]
                f = suite_paths[sid]
                pairs[(f, name)] += 1
                results[e['result']] += 1
                per_file[f] += 1
    return pairs, results, per_file, suites


def main():
    run_dir = sys.argv[1]
    prev = sys.argv[2] if len(sys.argv) > 2 else None
    ok = True

    def check(label, cond, detail=''):
        nonlocal ok
        ok &= bool(cond)
        print(('OK       ' if cond else 'MISMATCH ') + label + (f' — {detail}' if detail else ''))

    on_disk = sorted(
        p.replace('\\', '/') for p in glob.glob('test/**/*_test.dart', recursive=True)
    )
    plan = json.load(open(os.path.join(run_dir, 'batch_plan.json'), encoding='utf-8'))
    inventory = sorted(plan['inventory'])
    check('inventory == *_test.dart files under test/', inventory == on_disk,
          f'{len(inventory)} planned, {len(on_disk)} on disk')
    pairs, results, per_file, suites = raw(run_dir)
    check('every planned file ran (suite in raw logs)', set(inventory) <= suites,
          f'missing: {sorted(set(inventory) - suites)}')
    check('no suite outside the plan', suites <= set(inventory),
          f'extra: {sorted(suites - set(inventory))}')
    dup = [k for k, n in pairs.items() if n > 1]
    check('no (file, test) pair ran twice', not dup, f'{len(dup)} repeated')
    check('every result is success', set(results) <= {'success'}, dict(results))
    print(f'TOTAL tests {sum(results.values())} in {len(per_file)} files; results {dict(results)}')
    if prev:
        _, _, before, _ = raw(prev)
        changed = {f: (before.get(f, 0), per_file.get(f, 0))
                   for f in set(before) | set(per_file)
                   if before.get(f, 0) != per_file.get(f, 0)}
        print(f'vs {prev}: {sum(before.values())} → {sum(per_file.values())} tests')
        for f, (a, b) in sorted(changed.items()):
            print(f'  count changed: {f}: {a} → {b}')
    print('INVENTORY OK' if ok else 'INVENTORY MISMATCH')
    sys.exit(0 if ok else 1)


main()
