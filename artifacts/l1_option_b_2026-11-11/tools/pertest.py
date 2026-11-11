"""Per-test results from a flutter --reporter json log: the result and, for a
failure, its first concrete reason (an Expected/Actual pair, or the first
line naming what was not found) — L-1 Option B evidence tool."""
import json
import re
import sys
from collections import Counter

sys.stdout.reconfigure(encoding="utf-8")

tests, suites, res, why = {}, {}, {}, {}
CONCRETE = re.compile(r'(could not find|Bad state|No element|Null check|type .* is not a subtype|StateError|threw|Exception:)')

for line in open(sys.argv[1], encoding='utf-8'):
    try:
        d = json.loads(line)
    except ValueError:
        continue
    t = d.get('type')
    if t == 'suite':
        path = d['suite']['path'].replace(chr(92), '/')
        suites[d['suite']['id']] = 'test/' + path.split('/test/')[-1]
    elif t == 'testStart':
        tests[d['test']['id']] = (suites.get(d['test']['suiteID'], '?'), d['test']['name'])
    elif t == 'testDone' and not d.get('hidden'):
        res[d['testID']] = 'skipped' if d.get('skipped') else d['result']
    elif t in ('error', 'print'):
        tid = d['testID']
        if tid in why:
            continue
        text = d.get('error') or d.get('message') or ''
        m = re.search(r'Expected: (.*?)\n\s*Actual: (.*?)\n', text, re.S)
        if m:
            why[tid] = ('Expected: ' + ' '.join(m.group(1).split())[:110]
                        + ' | Actual: ' + ' '.join(m.group(2).split())[:110])
            continue
        for ln in text.splitlines():
            if CONCRETE.search(ln):
                why[tid] = ' '.join(ln.split())[:220]
                break

c = Counter(res.values())
print('TOTAL', sum(c.values()), dict(c))
for tid, (suite, name) in tests.items():
    if tid not in res:
        continue
    r = res[tid]
    out = f"{r.upper():8} {suite} :: {name}"
    if r != 'success':
        out += f"\n         -> {why.get(tid, '(no concrete reason in log)')}"
    print(out)
