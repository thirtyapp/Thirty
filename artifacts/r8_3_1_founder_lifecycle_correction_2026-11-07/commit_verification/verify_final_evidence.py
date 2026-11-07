"""R8.3 commit authorization — independent re-verification of the definitive
R8.3.1 regression, from its raw reporter logs, without using the runner's
own code (artifacts/r8_3_1_founder_lifecycle_correction_2026-11-07/regression).

Usage (from the repository root):
  python -I artifacts/r8_3_1_founder_lifecycle_correction_2026-11-07/commit_verification/verify_final_evidence.py
"""
import glob
import hashlib
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
OUT = os.path.join('artifacts', 'r8_3_1_founder_lifecycle_correction_2026-11-07', 'regression')
problems = []


def bad(msg):
    problems.append(msg)
    print('PROBLEM', msg)


plan = json.load(open(os.path.join(OUT, 'batch_plan.json'), encoding='utf-8'))
on_disk = sorted(p.replace(os.sep, '/') for p in glob.glob('test/**/*_test.dart', recursive=True))
if sorted(plan['inventory']) != on_disk:
    bad('plan inventory != *_test.dart on disk')
expected = []
for n, files in enumerate(plan['batches'], start=1):
    parts = plan.get('parts', {}).get(str(n))
    for label in ([p[0] for p in parts] if parts else ['']):
        expected.append((f'batch_{n:02d}{label}', files))
present = sorted(os.path.basename(p)[:-6] for p in glob.glob(os.path.join(OUT, 'batch_*.jsonl')))
if present != sorted(e[0] for e in expected):
    bad(f'raw logs present {present} != expected {[e[0] for e in expected]}')

totals = {'success': 0, 'failure': 0, 'error': 0, 'skipped': 0}
pairs, per_file = {}, {}
for name, files in expected:
    raw = os.path.join(OUT, name + '.jsonl')
    summ = json.load(open(os.path.join(OUT, name + '.summary.json'), encoding='utf-8'))
    if summ.get('exit') != 0:
        bad(f'{name}: exit {summ.get("exit")}')
    digest = hashlib.sha256(open(raw, 'rb').read()).hexdigest()
    if summ.get('rawSha256') != digest:
        bad(f'{name}: raw log SHA-256 differs from its summary')
    events = []
    for line in open(raw, encoding='utf-8', errors='replace'):
        if line.startswith('{'):
            try:
                events.append(json.loads(line))
            except ValueError:
                bad(f'{name}: malformed event')
    if not events or events[0].get('type') != 'start':
        bad(f'{name}: no start event first')
    dones = [i for i, e in enumerate(events) if e.get('type') == 'done']
    if dones != [len(events) - 1] or events[-1].get('success') is not True:
        bad(f'{name}: terminal done missing, repeated, not last or not success')
    suites, tests, started, finished = {}, {}, set(), set()
    for e in events:
        t = e.get('type')
        if t == 'suite':
            p = e['suite']['path'].replace('\\', '/')
            suites[e['suite']['id']] = p[p.index('test/'):]
        elif t == 'testStart':
            tests[e['test']['id']] = (suites.get(e['test']['suiteID']), e['test']['name'])
            started.add(e['test']['id'])
        elif t == 'testDone':
            if e['testID'] in finished:
                bad(f'{name}: a test finished twice')
            finished.add(e['testID'])
            if e.get('hidden'):
                continue
            f, test = tests[e['testID']]
            key = 'skipped' if e.get('skipped') else e['result']
            totals[key] = totals.get(key, 0) + 1
            per_file[f] = per_file.get(f, 0) + 1
            pairs[(f, test)] = pairs.get((f, test), 0) + 1
    if started != finished:
        bad(f'{name}: started and finished tests differ')
    if set(suites.values()) != set(files):
        bad(f'{name}: suites {sorted(set(suites.values()))} != planned {files}')

dups = [k for k, v in pairs.items() if v > 1]
if dups:
    bad(f'{len(dups)} duplicate (file, test) pairs')
if set(per_file) != set(on_disk):
    bad('files with results != test files on disk')
profiles = sorted(re.match(r'(p\d\d_[a-z0-9_]+)', t).group(1)
                  for (f, t) in pairs if f.endswith('personal_circle_simulation_test.dart'))
b8 = sorted(t for (f, t) in pairs if f.endswith('b8/b8_product_simulation_test.dart'))
r83 = {f: n for f, n in per_file.items() if '/r83/' in f}
print(f'raw logs: {len(expected)} (batches 1-{len(plan["batches"])}, parts of 19: '
      f'{[p[0] for p in plan["parts"]["19"]]})')
print(f'test files with results: {len(per_file)} / on disk {len(on_disk)}')
print(f'results: {totals}')
print(f'duplicate (file, test) pairs: {len(dups)}')
print(f'year profiles ({len(profiles)}): {profiles}')
print(f'profiles each once: {len(profiles) == len(set(profiles)) == 13}')
print(f'B8 cases ({len(b8)}), all success (no failures counted above)')
print('R8.3/R8.3.1 files:', json.dumps(dict(sorted(r83.items())), indent=0))
ok = (not problems and totals['success'] == 2872 and totals['failure'] == 0
      and totals['error'] == 0 and totals['skipped'] == 0 and len(per_file) == 201
      and len(set(profiles)) == 13 and len(profiles) == 13 and len(b8) == 6)
print('FINAL EVIDENCE VERIFIED' if ok else 'FINAL EVIDENCE NOT VERIFIED')
sys.exit(0 if ok else 1)
