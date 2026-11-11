"""Builds the DISPOSABLE I1/I2 triage test (founder gate §3, R8.3.4.1).

Copies test/features/r833/r833_reproduction_test.dart from the repository
(unmodified there) and inserts triage_block.dart.txt just before the end of
its `R832-A01` group, so the block reuses that group's fixtures. Writes only
to the disposable tree given as argv[2].

Usage: python -I build_triage.py <repo_root> <disposable_tree_root>
"""
import os
import sys

repo, tree = sys.argv[1], sys.argv[2]
here = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(repo, 'test/features/r833/r833_reproduction_test.dart'),
           encoding='utf-8').read().replace('\r\n', '\n')
block = open(os.path.join(here, 'triage_block.dart.txt'), encoding='utf-8').read()
anchor = "\n  });\n\n  // =======================================================================\n  // R832-A02"
assert src.count(anchor) == 1, 'anchor not found exactly once'
out = src.replace(anchor, '\n' + block + anchor)
dest_dir = os.path.join(tree, 'test/features/r833_triage')
os.makedirs(dest_dir, exist_ok=True)
dest = os.path.join(dest_dir, 'r8341_i1i2_triage_test.dart')
open(dest, 'w', encoding='utf-8', newline='\n').write(out)
print('wrote', dest)
