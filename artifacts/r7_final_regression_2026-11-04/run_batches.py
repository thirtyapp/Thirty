"""Memory-bounded, sequential full-suite run for R7 final regression (2026-11-04).

Derived from the R6 runner; R7 adds per-test names to every summary and a
`cases` check that filtered parts cover every test of the file they split.

The host stopped one monolithic `flutter test` for low memory, so the suite runs as
small batches, one after another, each with `--concurrency=1` and the JSON reporter.
Every batch writes its raw JSON log; `report` checks that the union of batches is
exactly the test-file inventory and totals passed / failed / skipped per file.

Usage (from the repository root):
  python -I artifacts/r7_final_regression_2026-11-04/run_batches.py plan
  python -I artifacts/r7_final_regression_2026-11-04/run_batches.py run <batch-number>
  python -I artifacts/r7_final_regression_2026-11-04/run_batches.py report
"""
import json
import os
import subprocess
import sys
import time

OUT = os.path.join('artifacts', 'r7_final_regression_2026-11-04')
PLAN = os.path.join(OUT, 'batch_plan.json')
BATCH_SIZE = 12
# Tagged `long` (full-year simulations): each runs alone.
ALONE = {
    'test/features/b8/b8_product_simulation_test.dart',
    'test/features/personal_circle/personal_circle_simulation_test.dart',
}


def inventory():
    files = []
    for dp, _, fn in os.walk('test'):
        for f in fn:
            if f.endswith('_test.dart'):
                files.append(os.path.join(dp, f).replace(os.sep, '/'))
    return sorted(files)


def plan():
    files = inventory()
    normal = [f for f in files if f not in ALONE]
    batches = [normal[i:i + BATCH_SIZE] for i in range(0, len(normal), BATCH_SIZE)]
    batches += [[f] for f in sorted(ALONE)]
    with open(PLAN, 'w', encoding='utf-8') as fh:
        json.dump({'inventory': files, 'batches': batches}, fh, indent=1)
    print(f'{len(files)} test files in {len(batches)} batches -> {PLAN}')


def run(n):
    batches = json.load(open(PLAN, encoding='utf-8'))['batches']
    files = batches[n - 1]
    log = os.path.join(OUT, f'batch_{n:02d}.jsonl')
    cmd = ['flutter', 'test', '--concurrency=1', '--reporter', 'json', *files]
    started = time.time()
    with open(log, 'w', encoding='utf-8') as fh:
        proc = subprocess.run(cmd, stdout=fh, stderr=subprocess.STDOUT, shell=(os.name == 'nt'))
    summary = summarize(log)
    summary.update({'batch': n, 'exit': proc.returncode, 'seconds': round(time.time() - started),
                    'command': ' '.join(cmd)})
    with open(os.path.join(OUT, f'batch_{n:02d}.summary.json'), 'w', encoding='utf-8') as fh:
        json.dump(summary, fh, indent=1)
    t = summary['totals']
    print(f"batch {n}: exit {proc.returncode}, {t['passed']} passed, {t['failed']} failed, "
          f"{t['skipped']} skipped, {len(summary['files'])}/{len(files)} files, {summary['seconds']} s, "
          f"done={summary['done']}")
    for f in summary['failures'][:20]:
        print('  FAIL', f)


def run_part(n, label, pattern):
    """One part of batch [n], by test-name regex — for a single file too long
    to run in one go within the host's memory (the parts must cover every
    test in it; `report` checks the counts)."""
    batches = json.load(open(PLAN, encoding='utf-8'))['batches']
    files = batches[n - 1]
    log = os.path.join(OUT, f'batch_{n:02d}{label}.jsonl')
    cmd = ['flutter', 'test', '--concurrency=1', '--reporter', 'json', '--name', pattern, *files]
    started = time.time()
    with open(log, 'w', encoding='utf-8') as fh:
        proc = subprocess.run(cmd, stdout=fh, stderr=subprocess.STDOUT, shell=(os.name == 'nt'))
    summary = summarize(log)
    summary.update({'batch': f'{n}{label}', 'exit': proc.returncode,
                    'seconds': round(time.time() - started), 'command': ' '.join(cmd)})
    with open(os.path.join(OUT, f'batch_{n:02d}{label}.summary.json'), 'w', encoding='utf-8') as fh:
        json.dump(summary, fh, indent=1)
    t = summary['totals']
    print(f"batch {n}{label}: exit {proc.returncode}, {t['passed']} passed, {t['failed']} failed, "
          f"{t['skipped']} skipped, {summary['seconds']} s, done={summary['done']}")
    for f in summary['failures'][:20]:
        print('  FAIL', f)


def summarize(log):
    suites, tests, per_file, names = {}, {}, {}, {}
    failures, done = [], False
    for line in open(log, encoding='utf-8', errors='replace'):
        line = line.strip()
        if not line.startswith('{'):
            continue
        try:
            e = json.loads(line)
        except ValueError:
            continue
        kind = e.get('type')
        if kind == 'suite':
            path = e['suite'].get('path') or ''
            rel = os.path.relpath(path).replace(os.sep, '/') if path else ''
            suites[e['suite']['id']] = rel
            per_file.setdefault(rel, {'passed': 0, 'failed': 0, 'skipped': 0})
        elif kind == 'testStart':
            t = e['test']
            tests[t['id']] = (suites.get(t.get('suiteID'), ''), t.get('name', ''))
        elif kind == 'testDone':
            if e.get('hidden'):
                continue
            path, name = tests.get(e['testID'], ('', ''))
            bucket = per_file.setdefault(path, {'passed': 0, 'failed': 0, 'skipped': 0})
            names.setdefault(path, []).append(name)
            if e.get('skipped'):
                bucket['skipped'] += 1
            elif e.get('result') == 'success':
                bucket['passed'] += 1
            else:
                bucket['failed'] += 1
                failures.append(f'{path}: {name}')
        elif kind == 'done':
            done = bool(e.get('success')) or done
            done = True
    totals = {k: sum(v[k] for v in per_file.values()) for k in ('passed', 'failed', 'skipped')}
    return {'files': per_file, 'totals': totals, 'failures': failures, 'done': done,
            'testNames': names}


# R7: files split into name-filtered parts, with the source pattern that names
# every test the file declares. `cases` checks the parts ran each declared test
# exactly once and nothing else, so a filter can't silently drop a test.
SPLIT = {
    'test/features/personal_circle/personal_circle_simulation_test.dart':
        r"name: '(p\d\d_[a-z0-9_]+)'",
}


def cases():
    import re
    data = json.load(open(PLAN, encoding='utf-8'))
    result = {}
    for path, pattern in SPLIT.items():
        declared = re.findall(pattern, open(path, encoding='utf-8').read())
        n = next(i + 1 for i, b in enumerate(data['batches']) if b == [path])
        whole = os.path.join(OUT, f'batch_{n:02d}.summary.json')
        parts = sorted(f for f in os.listdir(OUT) if f.startswith(f'batch_{n:02d}')
                       and f.endswith('.summary.json') and f != f'batch_{n:02d}.summary.json')
        ran = []
        for p in parts:
            ran += json.load(open(os.path.join(OUT, p), encoding='utf-8'))['testNames'].get(path, [])
        if not parts and os.path.exists(whole):
            ran = json.load(open(whole, encoding='utf-8'))['testNames'].get(path, [])
        matched = {d: sum(1 for r in ran if r.startswith(d + ' ')) for d in declared}
        unmatched = [r for r in ran if not any(r.startswith(d + ' ') for d in declared)]
        result[path] = {'declared': len(declared), 'ran': len(ran), 'parts': parts,
                        'eachExactlyOnce': all(v == 1 for v in matched.values()),
                        'notRun': [d for d, v in matched.items() if v == 0],
                        'repeated': [d for d, v in matched.items() if v > 1],
                        'undeclared': unmatched}
    with open(os.path.join(OUT, 'CASE_COVERAGE.json'), 'w', encoding='utf-8') as fh:
        json.dump(result, fh, indent=1)
    print(json.dumps(result, indent=1))


def report():
    data = json.load(open(PLAN, encoding='utf-8'))
    inventory_files = set(data['inventory'])
    covered, totals, missing_batches = {}, {'passed': 0, 'failed': 0, 'skipped': 0}, []
    empty_runs, nonzero_exit = [], []
    for n in range(1, len(data['batches']) + 1):
        whole = os.path.join(OUT, f'batch_{n:02d}.summary.json')
        parts = sorted(
            os.path.join(OUT, f) for f in os.listdir(OUT)
            if f.startswith(f'batch_{n:02d}') and f.endswith('.summary.json')
            and f != f'batch_{n:02d}.summary.json'
        )
        # A batch stopped by the host counts only through its completed parts.
        sources = [whole] if os.path.exists(whole) and json.load(
            open(whole, encoding='utf-8'))['done'] else parts
        if not sources:
            missing_batches.append(n)
            continue
        for p in sources:
            s = json.load(open(p, encoding='utf-8'))
            if not s['done']:
                missing_batches.append(s['batch'])
            # R7: an empty run or a non-zero exit is never a success.
            ran = sum(s['totals'].values())
            if ran == 0:
                empty_runs.append(s['batch'])
            if s['exit'] != 0:
                nonzero_exit.append(s['batch'])
            for f, c in s['files'].items():
                if f:
                    prev = covered.setdefault(f, {'passed': 0, 'failed': 0, 'skipped': 0})
                    for k in prev:
                        prev[k] += c[k]
            for k in totals:
                totals[k] += s['totals'][k]
    not_run = sorted(inventory_files - set(covered))
    extra = sorted(set(covered) - inventory_files)
    manifest = {'inventoryFiles': len(inventory_files), 'coveredFiles': len(covered), 'notRun': not_run,
                'unexpected': extra, 'incompleteBatches': missing_batches,
                'emptyRuns': empty_runs, 'nonZeroExit': nonzero_exit, 'totals': totals,
                'perFile': dict(sorted(covered.items()))}
    with open(os.path.join(OUT, 'COVERAGE_MANIFEST.json'), 'w', encoding='utf-8') as fh:
        json.dump(manifest, fh, indent=1)
    print(json.dumps({k: v for k, v in manifest.items() if k != 'perFile'}, indent=1))


if __name__ == '__main__':
    {'plan': lambda: plan(), 'run': lambda: run(int(sys.argv[2])),
     'runpart': lambda: run_part(int(sys.argv[2]), sys.argv[3], sys.argv[4]),
     'report': lambda: report(), 'cases': lambda: cases()}[sys.argv[1]]()
