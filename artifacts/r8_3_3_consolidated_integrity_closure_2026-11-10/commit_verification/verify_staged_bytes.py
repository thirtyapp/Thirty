"""R8.3.3 commit gate — every staged evidence or document file is committed
byte-exact (no line-ending conversion), so recorded SHA-256 values (raw
reporter logs, audit reports, hash lists) stay verifiable from the commit.

Usage (from the repository root): python -I <this> <path-list-file>
"""
import hashlib
import subprocess
import sys

bad = []
paths = [p.strip() for p in open(sys.argv[1], encoding='utf-8') if p.strip()]
for path in paths:
    blob = subprocess.run(['git', 'show', f':{path}'], capture_output=True, check=True).stdout
    work = open(path, 'rb').read()
    if blob != work:
        bad.append((path, work.count(b'\r'), blob.count(b'\r'),
                    hashlib.sha256(work).hexdigest()[:12], hashlib.sha256(blob).hexdigest()[:12]))
print('checked', len(paths))
for b in bad:
    print('DIFFERS', *b)
print('BYTES OK' if not bad else f'{len(bad)} DIFFER')
