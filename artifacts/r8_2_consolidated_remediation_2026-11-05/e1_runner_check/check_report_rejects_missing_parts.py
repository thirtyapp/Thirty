"""R8.2 — Claude E-1: does a regression runner's `report` reject evidence
with a declared batch part missing or incomplete?

Runs the given runner's `report` (and, when it has one, its part check)
against disposable copies of the committed R8.1 `regression_final`
evidence, each copy damaged one way. The historical evidence is only read,
never changed.

Usage (from the repository root):
  python -I artifacts/r8_2_consolidated_remediation_2026-11-05/e1_runner_check/check_report_rejects_missing_parts.py <runner.py>

Prints one line per scenario — ACCEPTED (exit 0) or REJECTED (non-zero) —
and exits 0 only when every damaged copy is REJECTED and the intact copy is
ACCEPTED.
"""
import contextlib
import importlib.util
import io
import json
import os
import shutil
import sys
import tempfile

SOURCE = os.path.join('artifacts', 'r8_1_consolidated_remediation_2026-11-05', 'regression_final')


def load(runner_path):
    spec = importlib.util.spec_from_file_location('runner_under_check', runner_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def evidence_copy(module):
    tmp = tempfile.mkdtemp(prefix='r82_e1_')
    for name in os.listdir(SOURCE):
        if name.endswith('.summary.json') or name == 'batch_plan.json':
            shutil.copy(os.path.join(SOURCE, name), tmp)
    # A runner that declares its parts in the plan (R8.2) reads them from
    # there: the copy's plan gets the same declarations its own `plan` would
    # write. The R8.1 runner has none and ignores the field.
    split = getattr(module, 'SPLIT', {})
    if any(isinstance(v, dict) and 'parts' in v for v in split.values()):
        path = os.path.join(tmp, 'batch_plan.json')
        data = json.load(open(path, encoding='utf-8'))
        data['parts'] = {
            str(n): [list(p) for p in split[b[0]]['parts']]
            for n, b in enumerate(data['batches'], start=1)
            if len(b) == 1 and b[0] in split
        }
        with open(path, 'w', encoding='utf-8') as fh:
            json.dump(data, fh)
    return tmp


def verdict(module, out):
    module.OUT = out
    module.PLAN = os.path.join(out, 'batch_plan.json')
    buffer = io.StringIO()
    code = 0
    with contextlib.redirect_stdout(buffer):
        try:
            module.report()
        except SystemExit as stop:
            code = stop.code or 0
    return ('ACCEPTED' if code == 0 else 'REJECTED'), buffer.getvalue()


def edit(out, name, change):
    path = os.path.join(out, name)
    data = json.load(open(path, encoding='utf-8'))
    change(data)
    with open(path, 'w', encoding='utf-8') as fh:
        json.dump(data, fh)


def scenarios():
    def missing_part(out):
        os.remove(os.path.join(out, 'batch_17c.summary.json'))

    def incomplete_part(out):
        def stop(d):
            d['done'] = False
            d['doneSuccess'] = None
        edit(out, 'batch_17d.summary.json', stop)

    def wrong_identity(out):
        # The 17c part's log replaced by a second copy of 17b.
        shutil.copy(os.path.join(out, 'batch_17b.summary.json'),
                    os.path.join(out, 'batch_17c.summary.json'))

    def undeclared_part(out):
        shutil.copy(os.path.join(out, 'batch_17e.summary.json'),
                    os.path.join(out, 'batch_17f.summary.json'))
        edit(out, 'batch_17f.summary.json', lambda d: d.update({'batch': '17f'}))

    def missing_whole_batch(out):
        os.remove(os.path.join(out, 'batch_09.summary.json'))

    def wrong_files(out):
        def swap(d):
            files = d['files']
            first = sorted(files)[0]
            files['test/not_in_this_batch_test.dart'] = files.pop(first)
        edit(out, 'batch_03.summary.json', swap)

    return {
        'intact (control)': None,
        'year-simulation part 17c missing': missing_part,
        'year-simulation part 17d incomplete': incomplete_part,
        'part 17c is a copy of 17b': wrong_identity,
        'an undeclared part 17f': undeclared_part,
        'whole batch 9 missing': missing_whole_batch,
        'batch 3 reports a file it was not given': wrong_files,
    }


def main():
    runner = sys.argv[1]
    module = load(runner)
    ok = True
    print(f'runner: {runner}')
    for name, damage in scenarios().items():
        out = evidence_copy(module)
        try:
            if damage:
                damage(out)
            result, _ = verdict(module, out)
        finally:
            shutil.rmtree(out, ignore_errors=True)
        expected = 'ACCEPTED' if damage is None else 'REJECTED'
        ok = ok and result == expected
        print(f'{result:8}  (expected {expected})  {name}')
    print('E-1 CHECK PASS' if ok else 'E-1 CHECK FAIL')
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
