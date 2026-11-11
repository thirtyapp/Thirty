"""Per-file pass/fail summary of flutter `--reporter json` logs (R8.3.4.1)."""
import collections
import json
import os
import sys

for path in sys.argv[1:]:
    tests, suites, notpass, done = {}, {}, [], None
    res = collections.defaultdict(collections.Counter)
    for line in open(path, encoding='utf-8', errors='replace'):
        line = line.strip()
        if not line.startswith('{'):
            continue
        try:
            o = json.loads(line)
        except ValueError:
            continue
        t = o.get('type')
        if t == 'suite':
            p = o['suite']['path'].replace(chr(92), '/')
            suites[o['suite']['id']] = p.split('/test/')[-1]
        elif t == 'testStart':
            tests[o['test']['id']] = (o['test']['name'], o['test']['suiteID'])
        elif t == 'testDone' and not o.get('hidden'):
            name, sid = tests[o['testID']]
            r = 'skipped' if o.get('skipped') else o['result']
            res[suites[sid]][r] += 1
            if r != 'success':
                notpass.append(f'{suites[sid]} :: {name}')
        elif t == 'done':
            done = o.get('success')
    print('==', os.path.basename(path), 'done.success=', done)
    total = collections.Counter()
    for k in sorted(res):
        print(' ', k, dict(res[k]))
        total += res[k]
    print('  TOTAL', dict(total))
    for n in notpass:
        print('  NOT-PASS', n)
