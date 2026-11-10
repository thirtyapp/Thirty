#!/usr/bin/env bash
# R8.3.3 closure (2026-11-10): copied unchanged from the R832-G1 closure driver except OUT.
# R832-G1 closure (2026-11-09): copied unchanged from the R8.3.2 final founder scope driver except OUT.
# R8.3.2 (2026-11-07): copied unchanged from the R8.3.1 driver except OUT.
# R8.3 complete regression driver (founder directive, 2026-11-07).
# Derived from artifacts/r8_2_consolidated_remediation_2026-11-05/lifecycle_policy/regression_rerun/drive_regression.sh:
# - OUT is the R8.3 regression folder;
# - the batches and parts are read from the plan itself (R8.3 adds 7 test
#   files, so the long files are no longer batches 17 and 18);
# - a Git-blob manifest of the tested source is written at start and end;
# - the memory guard needs 4.0 GB free between batches (as R8.2); it waits up
#   to 10 min, then stops. The driver's PID and any live test processes are
#   logged before each batch.
# Sequential batches (one flutter process at a time). Kills nothing; stops on
# low memory. Run from the repository root.
# Fix after run 1 (regression_run1_INCOMPLETE): Python prints CRLF on Windows, so
# the step labels are stripped of '\r' (parts 19a-d had been refused as undeclared).
set -u
OUT=artifacts/r8_3_3_consolidated_integrity_closure_2026-11-10/regression
RUN="python -I $OUT/run_batches.py"
MIN_GB=4.0
sources() { { ls analysis_options.yaml pubspec.yaml pubspec.lock; find lib test -type f; } | LC_ALL=C sort; }
fingerprint() { sources | xargs -d '\n' sha256sum -b; }
blobs() { sources | xargs -d '\n' git hash-object | paste -d ' ' - <(sources); }
free_gb() { powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,2)" | tr ',' '.' | tr -d '\r'; }
testers() { powershell -NoProfile -Command "(Get-CimInstance Win32_Process | Where-Object { \$_.Name -eq 'flutter_tester.exe' -or (\$_.Name -eq 'dart.exe' -and \$_.CommandLine -match ' test ') } | Measure-Object).Count" | tr -d '\r'; }
guard() {
  for i in $(seq 1 60); do
    f=$(free_gb); if awk "BEGIN{exit !($f >= $MIN_GB)}"; then echo "$(date +%H:%M:%S) free before $1: $f GB; test processes alive: $(testers)" >> $OUT/MEMORY_LOG.txt; return 0; fi
    echo "$(date +%H:%M:%S) waiting before $1: $f GB" >> $OUT/MEMORY_LOG.txt
    sleep 10
  done
  echo "MEMORY STOP before $1: $(free_gb) GB" | tee -a $OUT/MEMORY_LOG.txt $OUT/RUN_LOG.txt; exit 3
}
$RUN plan > $OUT/PLAN_OUTPUT.txt 2>&1
fingerprint > $OUT/SOURCE_FINGERPRINT_start.sha256
blobs > $OUT/SOURCE_MANIFEST_git_blobs_start.txt
echo "start $(date -Iseconds) driver pid $$" > $OUT/RUN_LOG.txt
: > $OUT/MEMORY_LOG.txt
STEPS=$(python -I -c "
import json
d = json.load(open('$OUT/batch_plan.json', encoding='utf-8'))
for n in range(1, len(d['batches']) + 1):
    parts = d.get('parts', {}).get(str(n))
    if parts:
        for label, _ in parts: print(f'runpart {n} {label}')
    else:
        print(f'run {n}')
" | tr -d '\r')
echo "$STEPS" > $OUT/STEPS.txt
while read -r mode n label; do
  [ -z "$mode" ] && continue
  guard "$n$label"
  $RUN $mode $n $label >> $OUT/RUN_LOG.txt 2>&1
done <<< "$STEPS"
$RUN report > $OUT/REPORT_OUTPUT.txt 2>&1; echo "report exit $?" >> $OUT/RUN_LOG.txt
$RUN cases > $OUT/CASES_OUTPUT.txt 2>&1; echo "cases exit $?" >> $OUT/RUN_LOG.txt
fingerprint > $OUT/SOURCE_FINGERPRINT_end.sha256
blobs > $OUT/SOURCE_MANIFEST_git_blobs_end.txt
cmp -s $OUT/SOURCE_FINGERPRINT_start.sha256 $OUT/SOURCE_FINGERPRINT_end.sha256 && echo "fingerprints identical" >> $OUT/RUN_LOG.txt || echo "FINGERPRINTS DIFFER" >> $OUT/RUN_LOG.txt
cmp -s $OUT/SOURCE_MANIFEST_git_blobs_start.txt $OUT/SOURCE_MANIFEST_git_blobs_end.txt && echo "blob manifests identical" >> $OUT/RUN_LOG.txt || echo "BLOB MANIFESTS DIFFER" >> $OUT/RUN_LOG.txt
echo "end $(date -Iseconds)" >> $OUT/RUN_LOG.txt
