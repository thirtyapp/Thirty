"""R8.3.3 commit gate — strict, independent check of the definitive run's raw
`flutter test --reporter json` logs (run 2, regression/), without trusting
any summary total.

For every batch_*.jsonl: first event is `start`; exactly one `done`, last,
with success true; every visible testStart has exactly one testDone; no
skipped or failed result; no test name repeated within a suite. The log's
SHA-256 must equal the one its own summary records. Prints the totals.

Usage (from the repository root): python -I <this> <regression_dir>
"""
import collections
import hashlib
import json
import os
import sys

run = sys.argv[1]
problems = []
files = set()
results = collections.Counter()
logs = sorted(f for f in os.listdir(run) if f.startswith('batch_') and f.endswith('.jsonl'))
for name in logs:
    path = os.path.join(run, name)
    raw = open(path, 'rb').read()
    summary = json.load(open(path[:-len('.jsonl')] + '.summary.json', encoding='utf-8'))
    recorded = summary.get('rawSha256') or summary.get('logSha256') or summary.get('sha256')
    if recorded != hashlib.sha256(raw).hexdigest():
        problems.append(f'{name}: raw SHA-256 differs from its summary ({recorded})')
    events = [json.loads(l) for l in raw.decode('utf-8').splitlines() if l.startswith('{')]
    events = [e for e in events if 'type' in e]
    if not events or events[0]['type'] != 'start':
        problems.append(f'{name}: first event is not start')
    dones = [i for i, e in enumerate(events) if e['type'] == 'done']
    if dones != [len(events) - 1] or events[-1].get('success') is not True:
        problems.append(f'{name}: not exactly one final successful done')
    suites, started, finished, seen = {}, {}, collections.Counter(), set()
    for e in events:
        if e['type'] == 'suite':
            suites[e['suite']['id']] = e['suite']['path'].replace(chr(92), '/').split('/test/')[-1]
        elif e['type'] == 'testStart':
            started[e['test']['id']] = e['test']
        elif e['type'] == 'testDone':
            # Every start finishes exactly once; hidden ones (setUpAll,
            # tearDownAll, loading) are not results.
            finished[e['testID']] += 1
            if e.get('hidden'):
                continue
            t = started.get(e['testID'])
            if t is None:
                problems.append(f'{name}: testDone without testStart')
                continue
            key = (suites[t['suiteID']], t['name'])
            if key in seen:
                problems.append(f'{name}: repeated {key}')
            seen.add(key)
            files.add(key[0])
            results['skipped' if e.get('skipped') else e['result']] += 1
    for tid, t in started.items():
        if finished[tid] != 1:
            problems.append(f'{name}: {t["name"]} finished {finished[tid]} times')
print('logs', len(logs))
print('files', len(files))
print('results', dict(results))
print('problems', problems if problems else 'none')
print('RAW OK' if not problems and set(results) == {'success'} else 'RAW MISMATCH')
