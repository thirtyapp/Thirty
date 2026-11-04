"""Summarizes the R8 reproducers run against the audited R7 source tree
(`33079135…`, commit 8ece26f6's code) — before any R8 fix.

Usage (repository root):
  python -I artifacts/r8_post_audit_remediation_2026-11-04/repro_on_r7_tree/summarize.py
Writes REPRO_ON_R7_TREE.json beside the logs.
"""
import glob
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
result = {}
for log in sorted(glob.glob(os.path.join(HERE, '*.jsonl'))):
    tests, outcome, compile_error = {}, {}, False
    for line in open(log, encoding='utf-8', errors='replace'):
        line = line.strip()
        if not line.startswith('{'):
            continue
        try:
            e = json.loads(line)
        except ValueError:
            continue
        if e.get('type') == 'testStart':
            tests[e['test']['id']] = e['test']['name']
        elif e.get('type') == 'testDone' and not e.get('hidden'):
            outcome[tests.get(e['testID'], '?')] = (
                'skipped' if e.get('skipped') else e.get('result'))
        elif e.get('type') == 'error' and 'loading' in tests.get(e.get('testID'), ''):
            compile_error = True
    name = os.path.basename(log)[:-len('.jsonl')]
    result[name] = {
        'tests': len(outcome),
        'failedOnR7': sorted(t for t, r in outcome.items() if r != 'success'),
        'passedOnR7': sorted(t for t, r in outcome.items() if r == 'success'),
        'compileError': compile_error,
    }
with open(os.path.join(HERE, 'REPRO_ON_R7_TREE.json'), 'w', encoding='utf-8') as fh:
    json.dump(result, fh, indent=1, ensure_ascii=False)
for name, r in result.items():
    print(f"{name}: {r['tests']} tests, {len(r['failedOnR7'])} fail on R7, "
          f"{len(r['passedOnR7'])} pass (guards), compileError={r['compileError']}")
