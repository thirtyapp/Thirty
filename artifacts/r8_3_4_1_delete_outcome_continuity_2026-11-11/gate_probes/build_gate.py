"""Builds the DISPOSABLE R8.3.4.1 gate probe file (founder gate §4).

Copies the repository's test/features/r834/r8341_delete_outcome_continuity_test.dart
(unmodified there) and inserts gate_block.dart.txt at the end of its
per-family loop, so the block reuses that loop's helpers. Writes only to
the disposable tree given as argv[2].

Usage: python -I build_gate.py <repo_root> <disposable_tree_root>
"""
import os
import sys

repo, tree = sys.argv[1], sys.argv[2]
here = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(repo, 'test/features/r834/r8341_delete_outcome_continuity_test.dart'),
           encoding='utf-8').read().replace('\r\n', '\n')
block = open(os.path.join(here, 'gate_block.dart.txt'), encoding='utf-8').read()
tail = '    });\n  }\n}\n'
assert src.endswith(tail), 'unexpected file end'
out = src[:-len(tail)] + '    });\n' + block + '  }\n}\n'
dest_dir = os.path.join(tree, 'test/features/r8341_gate')
os.makedirs(dest_dir, exist_ok=True)
dest = os.path.join(dest_dir, 'r8341_gate_probes_test.dart')
open(dest, 'w', encoding='utf-8', newline='\n').write(out)
print('wrote', dest)
