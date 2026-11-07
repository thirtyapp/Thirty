"""R8.3 — E-1 residual (Astra post-R8.2 audit, section 7): does a regression
runner's `report` / `cases` reject damaged raw reporter logs while the
summaries stay intact — and still reject damaged summaries?

Runs the given runner's `report` and `cases` against disposable copies of
the committed R8.2 definitive evidence
(artifacts/r8_2_consolidated_remediation_2026-11-05/lifecycle_policy/regression_rerun),
each copy damaged one way. The historical evidence is only read, never
changed (its files are hashed before and after).

Usage (from the repository root):
  python -I artifacts/r8_3_bounded_integrity_hardening_2026-11-07/e1_raw_validation/check_raw_evidence.py <runner.py>

Prints one line per scenario — ACCEPTED or REJECTED by report and by cases —
and exits 0 only when the intact copy is accepted by both and every damaged
copy is rejected by report (and, for the split file's parts, by cases).
"""
import contextlib
import hashlib
import importlib.util
import io
import json
import os
import shutil
import sys
import tempfile

sys.stdout.reconfigure(encoding='utf-8')
SOURCE = os.path.join('artifacts', 'r8_2_consolidated_remediation_2026-11-05',
                      'lifecycle_policy', 'regression_rerun')


def load(runner_path):
    spec = importlib.util.spec_from_file_location('runner_under_check', runner_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def fingerprint():
    out = {}
    for name in sorted(os.listdir(SOURCE)):
        path = os.path.join(SOURCE, name)
        if os.path.isfile(path):
            out[name] = hashlib.sha256(open(path, 'rb').read()).hexdigest()
    return out


def evidence_copy():
    tmp = tempfile.mkdtemp(prefix='r83_e1_')
    for name in os.listdir(SOURCE):
        if name.endswith(('.summary.json', '.jsonl')) or name == 'batch_plan.json':
            shutil.copy(os.path.join(SOURCE, name), tmp)
    return tmp


def run(module, out, mode):
    module.OUT = out
    module.PLAN = os.path.join(out, 'batch_plan.json')
    buffer = io.StringIO()
    code = 0
    with contextlib.redirect_stdout(buffer):
        try:
            getattr(module, mode)()
        except SystemExit as stop:
            code = stop.code or 0
    return code


def edit_json(path, change):
    data = json.load(open(path, encoding='utf-8'))
    change(data)
    with open(path, 'w', encoding='utf-8') as fh:
        json.dump(data, fh, indent=1)


def lines(path):
    return open(path, encoding='utf-8').read().splitlines(keepends=True)


def write(path, content):
    with open(path, 'w', encoding='utf-8', newline='') as fh:
        fh.write(content)


def flip_first_success(path):
    out, done = [], False
    for line in lines(path):
        if not done and '"type":"testDone"' in line and '"result":"success"' in line \
                and '"hidden":false' in line:
            line = line.replace('"result":"success"', '"result":"failure"')
            done = True
        out.append(line)
    write(path, ''.join(out))


def duplicate_a_test_done(path):
    out, done = [], False
    for line in lines(path):
        out.append(line)
        if not done and '"type":"testDone"' in line and '"hidden":false' in line:
            out.append(line)
            done = True
    write(path, ''.join(out))


def p(out, name):
    return os.path.join(out, name)


SCENARIOS = {
    'intact': lambda out: None,
    # Summary-level damage (the R8.2 E-1 fix; Astra's challenges).
    'summary: declared part 18c missing': lambda out: [
        os.remove(p(out, 'batch_18c.summary.json')), os.remove(p(out, 'batch_18c.jsonl'))],
    'summary: 18c replaced by a copy of 18b': lambda out: shutil.copy(
        p(out, 'batch_18b.summary.json'), p(out, 'batch_18c.summary.json')),
    'summary: undeclared extra part 18f': lambda out: [
        shutil.copy(p(out, 'batch_18e.summary.json'), p(out, 'batch_18f.summary.json')),
        shutil.copy(p(out, 'batch_18e.jsonl'), p(out, 'batch_18f.jsonl'))],
    'summary: terminal success set false': lambda out: edit_json(
        p(out, 'batch_05.summary.json'), lambda d: d.update(doneSuccess=False)),
    'summary: a test file left out': lambda out: edit_json(
        p(out, 'batch_05.summary.json'),
        lambda d: d['files'].pop(sorted(d['files'])[0])),
    'summary: command changed': lambda out: edit_json(
        p(out, 'batch_05.summary.json'),
        lambda d: d.update(command=d['command'] + ' --plain-name x')),
    # Raw-level damage, summaries intact (the R8.3 E-1 residual).
    'raw: 18c emptied (Astra)': lambda out: write(p(out, 'batch_18c.jsonl'), ''),
    'raw: 18c deleted': lambda out: os.remove(p(out, 'batch_18c.jsonl')),
    'raw: 05 emptied': lambda out: write(p(out, 'batch_05.jsonl'), ''),
    'raw: 05 truncated before its done event': lambda out: write(
        p(out, 'batch_05.jsonl'), ''.join(lines(p(out, 'batch_05.jsonl'))[:-1])),
    'raw: 05 truncated to half': lambda out: write(
        p(out, 'batch_05.jsonl'),
        ''.join(lines(p(out, 'batch_05.jsonl'))[:len(lines(p(out, 'batch_05.jsonl'))) // 2])),
    'raw: 18c replaced by 18b\'s raw log': lambda out: shutil.copy(
        p(out, 'batch_18b.jsonl'), p(out, 'batch_18c.jsonl')),
    'raw: 05 replaced by 06\'s raw log': lambda out: shutil.copy(
        p(out, 'batch_06.jsonl'), p(out, 'batch_05.jsonl')),
    'raw: one passed test flipped to failure': lambda out: flip_first_success(
        p(out, 'batch_05.jsonl')),
    'raw: a test reported done twice': lambda out: duplicate_a_test_done(
        p(out, 'batch_05.jsonl')),
    'raw: a second done event appended': lambda out: write(
        p(out, 'batch_05.jsonl'),
        open(p(out, 'batch_05.jsonl'), encoding='utf-8').read()
        + '{"success":true,"type":"done","time":1}\n'),
}

# Damage that touches the split file's parts, which `cases` judges too.
CASES_SCENARIOS = {'summary: declared part 18c missing', 'raw: 18c emptied (Astra)',
                   'raw: 18c deleted', 'raw: 18c replaced by 18b\'s raw log'}


def main():
    module = load(sys.argv[1])
    before = fingerprint()
    ok = True
    for name, damage in SCENARIOS.items():
        out = evidence_copy()
        try:
            damage(out)
            report = run(module, out, 'report')
            cases = run(module, out, 'cases')
        finally:
            shutil.rmtree(out, ignore_errors=True)
        verdict = lambda code: 'ACCEPTED' if code == 0 else 'REJECTED'
        print(f'{name:48s} report {verdict(report):8s}  cases {verdict(cases)}')
        if name == 'intact':
            ok &= report == 0 and cases == 0
        else:
            ok &= report != 0
            if name in CASES_SCENARIOS:
                ok &= cases != 0
    unchanged = fingerprint() == before
    print(f'historical evidence unchanged: {unchanged}')
    print('ALL AS REQUIRED' if ok and unchanged else 'NOT AS REQUIRED')
    sys.exit(0 if ok and unchanged else 1)


if __name__ == '__main__':
    main()
