"""R8.3 — the 180 frozen audio files: every bundled .m4a under
assets/audio/guidance matches its SHA-1 in the production (172) or framing
(8) manifest, and the bundled set is exactly their union.

Usage (from the repository root):
  python -I artifacts/r8_3_bounded_integrity_hardening_2026-11-07/verify_audio.py
"""
import hashlib
import os
import subprocess
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.join('assets', 'audio', 'guidance')
MANIFESTS = {
    'production': os.path.join('artifacts', 'v2_phase_d2', 'voice_production', 'PRODUCTION_SHA1.txt'),
    'framing': os.path.join('artifacts', 'v2_phase_d2', 'voice_production', 'framing_f02_f03', 'FRAMING_SHA1.txt'),
}


def read(path):
    out = {}
    for line in open(path, encoding='utf-8'):
        line = line.strip()
        if line:
            sha, name = line.split(' ', 1)
            out[name.lstrip('*')] = sha
    return out


ok = True
union = {}
for label, path in MANIFESTS.items():
    entries = read(path)
    bad = [n for n, sha in entries.items()
           if hashlib.sha1(open(os.path.join(ROOT, n), 'rb').read()).hexdigest() != sha]
    print(f'{label} manifest: {len(entries) - len(bad)} / {len(entries)} match')
    ok &= not bad
    union.update(entries)
bundled = sorted(os.path.relpath(os.path.join(dp, f), ROOT).replace(os.sep, '/')
                 for dp, _, fs in os.walk(ROOT) for f in fs if f.endswith('.m4a'))
print(f'bundled m4a: {len(bundled)}; union of manifests: {len(union)}')
same = set(bundled) == set(union)
print('bundled set == union of manifests' if same else 'BUNDLED SET DIFFERS')
diff = subprocess.run(['git', 'diff', '--stat', 'HEAD', '--', 'assets'],
                      capture_output=True, text=True).stdout.strip()
print(f'git diff --stat HEAD -- assets: [{diff}]')
ok &= same and not diff
print('AUDIO OK' if ok else 'AUDIO MISMATCH')
sys.exit(0 if ok else 1)
