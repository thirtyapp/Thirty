"""R8.3.4 commit gate: verify the staged index before the commit.

Usage (from the repository root):
  python -I <this> [--final]

Without --final, the two records written after staging
(STAGED_VERIFICATION.txt, COMMIT_VERIFICATION_SHA256SUMS.txt) may be absent
from the index; with --final, the staged set must equal COMMIT_PATHS.txt
exactly.

Checks:
1. staged paths (against HEAD) == COMMIT_PATHS.txt;
2. every lib/, test/ and configuration blob in the index == the definitive
   tested manifest (regression/SOURCE_MANIFEST_git_blobs_end.txt), and
   nothing else under them is staged;
3. every staged evidence path's blob == its working file, byte for byte;
4. audit-input SHA-256 values, recomputed from the staged blobs, equal
   audit_inputs/AUDIT_INPUT_HASHES.txt;
5. EVIDENCE_SHA256SUMS.txt verifies from the staged blobs;
6. every regression summary's rawSha256 equals its staged raw log's.
Exit 1 on any failure.
"""
import glob
import hashlib
import json
import os
import subprocess
import sys

E = 'artifacts/r8_3_4_final_action_identity_closure_2026-11-10'
CV = f'{E}/commit_verification'
POST = {f'{CV}/STAGED_VERIFICATION.txt', f'{CV}/COMMIT_VERIFICATION_SHA256SUMS.txt'}
final = '--final' in sys.argv
sys.stdout.reconfigure(encoding='utf-8')
failures = []


def git(*args):
    return subprocess.run(['git', *args], capture_output=True, check=True).stdout


def staged(path):
    return git('show', f':{path}')


def sha(b):
    return hashlib.sha256(b).hexdigest()


def check(ok, label):
    print(('OK       ' if ok else 'MISMATCH ') + label)
    if not ok:
        failures.append(label)


# 1. Staged set.
listed = [p.strip() for p in open(f'{CV}/COMMIT_PATHS.txt', encoding='utf-8') if p.strip()]
names = git('diff', '--cached', '--name-only', '-z').decode('utf-8').split('\0')
staged_paths = {p for p in names if p}
expected = set(listed) if final else set(listed) - POST
check(staged_paths == expected,
      f'staged paths == COMMIT_PATHS.txt{"" if final else " (minus the 2 post-staging records)"}'
      f' — staged {len(staged_paths)}, expected {len(expected)};'
      f' extra {sorted(staged_paths - expected)}, missing {sorted(expected - staged_paths)}')
status = {}
for line in git('diff', '--cached', '--name-status').decode('utf-8').splitlines():
    s, p = line.split('\t', 1)
    status[p] = s
mods = sorted(p for p, s in status.items() if s == 'M')
check(mods == sorted([
    'lib/features/home/application/circle_history_deletion.dart',
    'lib/features/insights/application/insights_provider.dart',
    'lib/features/personal_circle/application/kept_circles_provider.dart',
    'test/features/r833/r833_identity_contract_test.dart',
]), f'exactly the 4 approved modifications — {mods}')
check(all(s in ('A', 'M') for s in status.values()), 'no deletion, rename or mode change')

# 2. Source and test blobs == tested manifest.
manifest = {}
for line in open(f'{E}/regression/SOURCE_MANIFEST_git_blobs_end.txt', encoding='utf-8'):
    line = line.rstrip('\r\n')
    if line:
        h, p = line.split(' ', 1)
        manifest[p] = h
index = {}
for line in git('ls-files', '-s', '--', 'lib', 'test', 'analysis_options.yaml',
                'pubspec.yaml', 'pubspec.lock').decode('utf-8').splitlines():
    meta, p = line.split('\t', 1)
    index[p] = meta.split()[1]
diff = sorted(p for p in set(manifest) | set(index) if manifest.get(p) != index.get(p))
check(not diff, f'index lib/test/config blobs == tested manifest ({len(manifest)} entries) — differ: {diff}')

# 3. Evidence bytes.
bad = [p for p in sorted(staged_paths) if p.startswith(E + '/') and staged(p) != open(p, 'rb').read()]
check(not bad, f'staged evidence == working bytes ({sum(p.startswith(E + "/") for p in staged_paths)} files) — differ: {bad}')

# 4. Audit-input hashes from staged blobs.
recorded = {}
for line in open(f'{E}/audit_inputs/AUDIT_INPUT_HASHES.txt', encoding='utf-8'):
    parts = line.split(' *', 1)
    if len(parts) == 2 and len(parts[0]) == 64:
        recorded[parts[1].strip()] = parts[0]
audit_ok = True
checked = 0
for p, h in recorded.items():
    if p.startswith(E + '/'):
        checked += 1
        audit_ok &= sha(staged(p)) == h
check(audit_ok and checked == 6, f'audit-input copies: staged SHA-256 == recorded ({checked} files)')
for p in ('docs/audits/THIRTY_INDEPENDENT_POST_R8_3_3_TARGETED_DELTA_AUDIT.md',
          'docs/audits/THIRTY_R833_INDEPENDENT_AUDIT_EVIDENCE.zip'):
    check(sha(open(p, 'rb').read()) == recorded[p] and p not in staged_paths,
          f'{p}: unchanged, not staged')
originals = {
    f'{E}/astra_probe_correction/r833_independent_adversarial_test_ORIGINAL.dart.txt':
        '7a0b7ae81d23f18aeb5e4fa4a99a7980f1e23497a355c348c23c0fc8e5e9c683',
    f'{E}/audit_inputs/claude_probe/audit_r833_delta_test.dart.txt':
        'f727ef8d9dfdccf25bcafedeea769849c50081b296b9dafe69b4829afb3080b5',
    f'{E}/audit_inputs/THIRTY_CLAUDE_INDEPENDENT_POST_R8_3_3_AUDIT_extracted.md':
        'a55f6d6e261ecdca4a49b283600209834a87dd0bc4975dde6c18102119617507',
}
for p, h in originals.items():
    check(sha(staged(p)) == h, f'original auditor bytes staged: {os.path.basename(p)} {h[:8]}')

# 5. Evidence register from staged blobs.
n = bad5 = 0
for line in open(f'{E}/EVIDENCE_SHA256SUMS.txt', encoding='utf-8'):
    h, p = line.rstrip('\r\n').split(' *', 1)
    n += 1
    bad5 += sha(staged(p)) != h
check(bad5 == 0 and n == 117, f'EVIDENCE_SHA256SUMS.txt from staged blobs: {n - bad5}/{n}')

# 6. Raw logs of the definitive run.
raw_bad = []
summaries = sorted(glob.glob(f'{E}/regression/batch_*.summary.json'))
for s in summaries:
    j = json.loads(staged(s.replace(os.sep, '/')))
    log = s.replace('.summary.json', '.jsonl').replace(os.sep, '/')
    if j.get('rawSha256') != sha(staged(log)):
        raw_bad.append(log)
check(not raw_bad and len(summaries) == 24,
      f'regression rawSha256 == staged raw logs ({len(summaries)} summaries) — differ: {raw_bad}')

print('STAGED OK' if not failures else f'{len(failures)} FAILED')
sys.exit(1 if failures else 0)
