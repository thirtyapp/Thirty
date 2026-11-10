"""(R8.3.3 closure, 2026-11-10: copied unchanged from artifacts/r8_3_2_g1_closure_2026-11-09/regression/run_batches.py except OUT.)
(R832-G1 closure, 2026-11-09: copied unchanged from artifacts/r8_3_2_founder_scope_closure_2026-11-07/regression/run_batches.py except OUT.)
(R8.3.2 final founder scope, 2026-11-07: copied unchanged from artifacts/r8_3_2_consolidated_integrity_closure_2026-11-07/regression/run_batches.py except OUT.)
(R8.3.2, 2026-11-07: copied unchanged from artifacts/r8_3_1_founder_lifecycle_correction_2026-11-07/regression/run_batches.py except OUT.)
(R8.3.1, 2026-11-07: copied unchanged from artifacts/r8_3_bounded_integrity_hardening_2026-11-07/regression/run_batches.py except OUT.)
R8.3 bounded integrity hardening (2026-11-07): copied from
artifacts/r8_2_consolidated_remediation_2026-11-05/lifecycle_policy/regression_rerun/run_batches.py
(left exactly as committed). Changes, all listed in RUNNER_DIFF_vs_R8_2.txt:

- OUT is the R8.3 regression folder;
- E-1 residual (Astra post-R8.2 section 7): `report` and `cases` no longer
  trust the summaries alone. Every summary's own raw reporter log must
  exist, be non-empty and complete: it begins with the reporter's start
  event and has exactly one terminal `done` event, last, with success; every
  started test finishes exactly once; re-summarized, it gives exactly the
  summary's files, per-file counts, totals and test names; and, when the
  summary records it (every R8.3 run does), the log's SHA-256 matches.
  `cases` counts the year profiles from the raw logs themselves too, and
  requires them to agree with the summaries.
- `_execute` records the raw log's SHA-256 in its summary.

(The R8.2 header follows.)

(Copied unchanged from founder_decisions/regression_final/run_batches.py except OUT, for the R8.2 complete regression rerun authorized by the founder, 2026-11-06.)
Memory-bounded, sequential full-suite run for R8.2 consolidated remediation (2026-11-05).

Derived from the R8.1 runner
(artifacts/r8_1_consolidated_remediation_2026-11-05/regression_final/run_batches.py),
which is left exactly as committed.

R8.2 (Claude E-1): `report` used to accept whatever part summaries happened
to be present for a file split into name-filtered parts, so a missing part,
a part replaced by a copy of another, or an extra undeclared part could
still read EVIDENCE OK. Now:

- the parts are declared in the plan itself (`plan` writes them to
  batch_plan.json), and `runpart` refuses a label or pattern that isn't
  declared;
- `report` requires, for every batch, exactly the summaries it declares —
  the whole batch, or every declared part and nothing else — each naming its
  own identity (`batch`), run with its own declared command, complete
  (`done`, `doneSuccess`, exit 0, non-empty), and reporting exactly the
  plan's files for that batch;
- `report` itself checks that the declared parts ran each test the split
  file declares exactly once and nothing else (what `cases` checked
  separately before); `cases` still prints the same detail.

Any stray summary file for a batch, or a batch with neither its whole run
nor all its parts, is EVIDENCE MISMATCH (exit 1).

Usage (from the repository root):
  python -I artifacts/r8_2_consolidated_remediation_2026-11-05/lifecycle_policy/regression_rerun/run_batches.py plan
  python -I artifacts/r8_2_consolidated_remediation_2026-11-05/lifecycle_policy/regression_rerun/run_batches.py run <batch-number>
  python -I artifacts/r8_2_consolidated_remediation_2026-11-05/lifecycle_policy/regression_rerun/run_batches.py runpart <batch-number> <label>
  python -I artifacts/r8_2_consolidated_remediation_2026-11-05/lifecycle_policy/regression_rerun/run_batches.py report
  python -I artifacts/r8_2_consolidated_remediation_2026-11-05/lifecycle_policy/regression_rerun/run_batches.py cases
"""
import hashlib
import json
import os
import re
import subprocess
import sys
import time

OUT = os.path.join('artifacts', 'r8_3_3_consolidated_integrity_closure_2026-11-10', 'regression')
PLAN = os.path.join(OUT, 'batch_plan.json')
BATCH_SIZE = 12
# Tagged `long` (full-year simulations): each runs alone.
ALONE = {
    'test/features/b8/b8_product_simulation_test.dart',
    'test/features/personal_circle/personal_circle_simulation_test.dart',
}

# Files run as name-filtered parts — the host can't hold one in memory in a
# single run — with the parts (label, --name pattern) and the source pattern
# naming every test the file declares.
SPLIT = {
    'test/features/personal_circle/personal_circle_simulation_test.dart': {
        'declared': r"name: '(p\d\d_[a-z0-9_]+)'",
        'parts': [('a', 'p0[1-3]_'), ('b', 'p0[4-6]_'), ('c', 'p0[7-9]_'),
                  ('d', 'p1[01]_'), ('e', 'p1[34]_')],
    },
}


def inventory():
    files = []
    for dp, _, fn in os.walk('test'):
        for f in fn:
            if f.endswith('_test.dart'):
                files.append(os.path.join(dp, f).replace(os.sep, '/'))
    return sorted(files)


def command(files, pattern=None):
    return ['flutter', 'test', '--concurrency=1', '--reporter', 'json',
            *(['--name', pattern] if pattern else []), *files]


def plan():
    files = inventory()
    normal = [f for f in files if f not in ALONE]
    batches = [normal[i:i + BATCH_SIZE] for i in range(0, len(normal), BATCH_SIZE)]
    batches += [[f] for f in sorted(ALONE)]
    parts = {}
    for n, batch in enumerate(batches, start=1):
        if len(batch) == 1 and batch[0] in SPLIT:
            parts[str(n)] = [list(p) for p in SPLIT[batch[0]]['parts']]
    with open(PLAN, 'w', encoding='utf-8') as fh:
        json.dump({'inventory': files, 'batches': batches, 'parts': parts}, fh, indent=1)
    print(f'{len(files)} test files in {len(batches)} batches -> {PLAN}; parts: {parts}')


def _execute(identity, files, pattern, log_name, summary_name):
    log = os.path.join(OUT, log_name)
    cmd = command(files, pattern)
    started = time.time()
    with open(log, 'w', encoding='utf-8') as fh:
        proc = subprocess.run(cmd, stdout=fh, stderr=subprocess.STDOUT, shell=(os.name == 'nt'))
    summary = summarize(log)
    summary.update({'batch': identity, 'exit': proc.returncode,
                    'seconds': round(time.time() - started), 'command': ' '.join(cmd),
                    'rawSha256': _sha256(log)})
    with open(os.path.join(OUT, summary_name), 'w', encoding='utf-8') as fh:
        json.dump(summary, fh, indent=1)
    t = summary['totals']
    print(f"batch {identity}: exit {proc.returncode}, {t['passed']} passed, {t['failed']} failed, "
          f"{t['skipped']} skipped, {len(summary['files'])}/{len(files)} files, {summary['seconds']} s, "
          f"done={summary['done']}")
    for f in summary['failures'][:20]:
        print('  FAIL', f)


def run(n):
    data = json.load(open(PLAN, encoding='utf-8'))
    if str(n) in data.get('parts', {}):
        sys.exit(f'batch {n} is declared in parts; run each with runpart')
    _execute(n, data['batches'][n - 1], None, f'batch_{n:02d}.jsonl', f'batch_{n:02d}.summary.json')


def run_part(n, label):
    data = json.load(open(PLAN, encoding='utf-8'))
    declared = dict(map(tuple, data.get('parts', {}).get(str(n), [])))
    if label not in declared:
        sys.exit(f'part {n}{label} is not declared in {PLAN}')
    _execute(f'{n}{label}', data['batches'][n - 1], declared[label],
             f'batch_{n:02d}{label}.jsonl', f'batch_{n:02d}{label}.summary.json')


def summarize(log):
    suites, tests, per_file, names = {}, {}, {}, {}
    failures, done, done_success = [], False, None
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
            done = True
            done_success = bool(e.get('success'))
    totals = {k: sum(v[k] for v in per_file.values()) for k in ('passed', 'failed', 'skipped')}
    return {'files': per_file, 'totals': totals, 'failures': failures, 'done': done,
            'doneSuccess': done_success, 'testNames': names}


def _sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def raw_problems(summary_name, summary):
    """R8.3 (E-1 residual): what is wrong with [summary_name]'s own raw
    reporter log, judged from the raw events alone and against the summary.
    An empty list means the raw log is complete and says exactly what the
    summary says."""
    log = os.path.join(OUT, summary_name.replace('.summary.json', '.jsonl'))
    if not os.path.exists(log):
        return ['raw log missing']
    if os.path.getsize(log) == 0:
        return ['raw log empty']
    out = []
    if 'rawSha256' in summary and summary['rawSha256'] != _sha256(log):
        out.append('raw log is not the one summarized (SHA-256 differs)')
    events, starts, dones = [], {}, {}
    for line in open(log, encoding='utf-8', errors='replace'):
        line = line.strip()
        if not line.startswith('{'):
            continue
        try:
            e = json.loads(line)
        except ValueError:
            out.append('malformed reporter event')
            continue
        if not isinstance(e, dict) or 'type' not in e:
            continue
        events.append(e)
        if e['type'] == 'testStart':
            tid = e['test']['id']
            starts[tid] = starts.get(tid, 0) + 1
        elif e['type'] == 'testDone':
            dones[e['testID']] = dones.get(e['testID'], 0) + 1
    if not events:
        return out + ['no reporter events']
    if events[0]['type'] != 'start':
        out.append('reporter stream does not begin with its start event')
    terminal = [i for i, e in enumerate(events) if e['type'] == 'done']
    if len(terminal) != 1:
        out.append(f'{len(terminal)} terminal done events')
    elif terminal[0] != len(events) - 1:
        out.append('events after the terminal done event')
    elif events[-1].get('success') is not True:
        out.append('terminal done is not success')
    if any(v != 1 for v in starts.values()):
        out.append('a test started more than once')
    if any(v != 1 for v in dones.values()):
        out.append('a test finished more than once')
    if set(starts) != set(dones):
        out.append('started and finished tests differ (truncated or extra)')
    again = summarize(log)
    for field in ('files', 'totals', 'done', 'doneSuccess'):
        if again[field] != summary.get(field):
            out.append(f'raw {field} differ from the summary')
    names = {f: sorted(v) for f, v in again['testNames'].items()}
    if names != {f: sorted(v) for f, v in summary.get('testNames', {}).items()}:
        out.append('raw test names differ from the summary')
    return out


def _case_coverage(path, ran):
    declared = re.findall(SPLIT[path]['declared'], open(path, encoding='utf-8').read())
    matched = {d: sum(1 for r in ran if r.startswith(d + ' ')) for d in declared}
    unmatched = [r for r in ran if not any(r.startswith(d + ' ') for d in declared)]
    return {'declared': len(declared), 'ran': len(ran),
            'eachExactlyOnce': all(v == 1 for v in matched.values()),
            'notRun': [d for d, v in matched.items() if v == 0],
            'repeated': [d for d, v in matched.items() if v > 1],
            'undeclared': unmatched}


def report():
    data = json.load(open(PLAN, encoding='utf-8'))
    batches, declared_parts = data['batches'], data.get('parts', {})
    inventory_files = set(data['inventory'])
    covered, totals = {}, {'passed': 0, 'failed': 0, 'skipped': 0}
    problems = {'missing': [], 'stray': [], 'wrongIdentity': [], 'wrongCommand': [],
                'wrongFiles': [], 'incomplete': [], 'emptyRuns': [], 'nonZeroExit': [],
                'doneNotSuccess': [], 'caseCoverage': [], 'rawLog': []}
    present = {f for f in os.listdir(OUT) if f.endswith('.summary.json')}
    expected_all = set()
    case_detail = {}
    for n, files in enumerate(batches, start=1):
        parts = declared_parts.get(str(n))
        if parts:
            expected = {f'batch_{n:02d}{label}.summary.json': (f'{n}{label}', pattern)
                        for label, pattern in parts}
        else:
            expected = {f'batch_{n:02d}.summary.json': (n, None)}
        expected_all |= set(expected)
        for name in sorted(f for f in present if re.match(rf'batch_{n:02d}([a-z]*)\.summary\.json$', f)):
            if name not in expected:
                problems['stray'].append(name)
        ran_names = []
        for name, (identity, pattern) in sorted(expected.items()):
            if name not in present:
                problems['missing'].append(name)
                continue
            s = json.load(open(os.path.join(OUT, name), encoding='utf-8'))
            if s.get('batch') != identity:
                problems['wrongIdentity'].append(f"{name}: {s.get('batch')!r} != {identity!r}")
            if s.get('command') != ' '.join(command(files, pattern)):
                problems['wrongCommand'].append(name)
            reported = {f for f in s['files'] if f}
            if reported != set(files):
                problems['wrongFiles'].append(name)
            if not s['done']:
                problems['incomplete'].append(name)
            if sum(s['totals'].values()) == 0:
                problems['emptyRuns'].append(name)
            if s['exit'] != 0:
                problems['nonZeroExit'].append(name)
            if s.get('doneSuccess') is not True:
                problems['doneNotSuccess'].append(name)
            for problem in raw_problems(name, s):
                problems['rawLog'].append(f'{name}: {problem}')
            for f, c in s['files'].items():
                if f:
                    prev = covered.setdefault(f, {'passed': 0, 'failed': 0, 'skipped': 0})
                    for k in prev:
                        prev[k] += c[k]
            for k in totals:
                totals[k] += s['totals'][k]
            for f in files:
                ran_names += s['testNames'].get(f, [])
        if parts:
            detail = _case_coverage(files[0], ran_names)
            case_detail[files[0]] = detail
            if not (detail['eachExactlyOnce'] and not detail['undeclared']
                    and detail['ran'] == detail['declared']):
                problems['caseCoverage'].append(files[0])
    for name in sorted(present - expected_all):
        if name not in problems['stray']:
            problems['stray'].append(name)
    not_run = sorted(inventory_files - set(covered))
    extra = sorted(set(covered) - inventory_files)
    manifest = {'inventoryFiles': len(inventory_files), 'coveredFiles': len(covered),
                'notRun': not_run, 'unexpected': extra, 'declaredParts': declared_parts,
                **problems, 'caseDetail': case_detail, 'totals': totals,
                'perFile': dict(sorted(covered.items()))}
    with open(os.path.join(OUT, 'COVERAGE_MANIFEST.json'), 'w', encoding='utf-8') as fh:
        json.dump(manifest, fh, indent=1)
    print(json.dumps({k: v for k, v in manifest.items() if k != 'perFile'}, indent=1))
    ok = not (not_run or extra or any(problems.values()) or totals['failed'] or totals['skipped'])
    print('EVIDENCE OK' if ok else 'EVIDENCE MISMATCH')
    sys.exit(0 if ok else 1)


def cases():
    data = json.load(open(PLAN, encoding='utf-8'))
    result = {}
    for n, parts in data.get('parts', {}).items():
        path = data['batches'][int(n) - 1][0]
        ran, found, raw_ran, raw_bad = [], [], [], []
        for label, _ in parts:
            name = os.path.join(OUT, f'batch_{int(n):02d}{label}.summary.json')
            if os.path.exists(name):
                found.append(os.path.basename(name))
                ran += json.load(open(name, encoding='utf-8'))['testNames'].get(path, [])
            # R8.3 (E-1 residual): the profiles are counted from the raw
            # logs themselves too, and must agree with the summaries.
            log = name.replace('.summary.json', '.jsonl')
            if os.path.exists(log) and os.path.getsize(log) > 0:
                raw = summarize(log)
                if not raw['done'] or raw['doneSuccess'] is not True:
                    raw_bad.append(os.path.basename(log))
                raw_ran += raw['testNames'].get(path, [])
            else:
                raw_bad.append(os.path.basename(log))
        result[path] = {**_case_coverage(path, ran), 'parts': found,
                        'declaredParts': [f'{n}{label}' for label, _ in parts],
                        'rawAgrees': sorted(raw_ran) == sorted(ran) and not raw_bad,
                        'rawProblems': raw_bad}
    with open(os.path.join(OUT, 'CASE_COVERAGE.json'), 'w', encoding='utf-8') as fh:
        json.dump(result, fh, indent=1)
    print(json.dumps(result, indent=1))
    ok = all(r['eachExactlyOnce'] and not r['undeclared'] and r['ran'] == r['declared']
             and len(r['parts']) == len(r['declaredParts']) and r['rawAgrees']
             for r in result.values())
    print('CASES OK' if ok else 'CASES MISMATCH')
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    {'plan': lambda: plan(), 'run': lambda: run(int(sys.argv[2])),
     'runpart': lambda: run_part(int(sys.argv[2]), sys.argv[3]),
     'report': lambda: report(), 'cases': lambda: cases()}[sys.argv[1]]()
