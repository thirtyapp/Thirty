"""R8.3.3 commit gate — line endings of the staged source and test blobs.

For each path: the staged blob's CR count, the working file's CR count, and
whether the working file with CRLF turned into LF is byte-identical to the
staged blob (the core.autocrlf=true clean conversion, nothing else).

Usage (from the repository root): python -I <this> <path>...
"""
import subprocess
import sys

ok = True
for path in sys.argv[1:]:
    blob = subprocess.run(['git', 'show', f':{path}'], capture_output=True, check=True).stdout
    work = open(path, 'rb').read()
    same = work.replace(b'\r\n', b'\n') == blob
    ok &= same and blob.count(b'\r') == 0
    print(f'{path}: staged CR={blob.count(b"\r")} worktree CR={work.count(b"\r")} '
          f'worktree(CRLF->LF)==staged: {same}')
print('EOL OK' if ok else 'EOL MISMATCH')
