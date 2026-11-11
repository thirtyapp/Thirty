# Line-ending normalization of two L-1 test files (before staging)

## What was found

In the commit-precondition check, the raw bytes of two new test files did not equal the Git-blob manifest of `../regression_final/`:
- `test/features/l1/l1_delete_recovery_test.dart`
- `test/features/l1/l1_option_b_ui_test.dart`

**Cause.** Both files were written with uniform CRLF line endings. There were no lone CRs and no other difference. The driver's blob manifest uses `git hash-object` with the system's `core.autocrlf=true`, so it recorded the LF-normalized blobs, while the raw fingerprint covered CRLF bytes. Every other tested file, `l1_fixture.dart` included, was already LF.

**Why it mattered.** Neither way of committing the CRLF files would have stored exactly the tested bytes:
- committed normally, Git would have stored LF blobs that differ from the raw tested bytes;
- committed raw, they would have put CRLF source into an LF repository.

## The resolution

1. Only `\r\n` → `\n` was changed in those two files. Their bytes now equal the manifest's blobs (`eef5e1cf…` and `8ec20533…`).
2. Against the failing-before test bytes (`../after_fix/L1_TEST_FILES_sha256.txt`), the only difference apart from line endings is the D-2 word in `l1_fixture.dart`.
3. The L-1 suite was rerun on the LF bytes: 88/88 (`l1_suite_lf_normalized.jsonl`). `flutter analyze` is clean.
4. A fresh definitive full regression was run: **`../regression_definitive/` is AUTHORITATIVE**. Its raw fingerprint and Git-blob manifest both describe exactly the bytes committed.

## The earlier runs

- `../regression_final/` passed (3,143/0/0 on the CRLF bytes), but it is **superseded** by `regression_definitive/` purely because of line-ending normalization. It is kept as a record.
- `../regression/` (3,141 passed, 2 failed) is still the HOLD record and is **not a pass**.
