#!/usr/bin/env bash
# R8.2 complete regression rerun driver (founder authorization, 2026-11-06).
# Copied from ../regression_final/drive_regression.sh, with these changes:
# - OUT is regression_rerun;
# - the memory guard needs 4.0 GB free (was 2.5); it waits up to 10 min, then stops;
# - the driver's PID and any dart/flutter_tester processes are logged before each batch.
# Sequential batches (one flutter process at a time), source fingerprints at start and end.
# Run from the repository root. Kills nothing; stops on low memory.
set -u
OUT=artifacts/r8_2_consolidated_remediation_2026-11-05/lifecycle_policy/regression_rerun
RUN="python -I $OUT/run_batches.py"
MIN_GB=4.0
fingerprint() {
  { ls analysis_options.yaml pubspec.yaml pubspec.lock; find lib test -type f | sort; } | LC_ALL=C sort | xargs -d '\n' sha256sum -b
}
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
echo "start $(date -Iseconds) driver pid $$" > $OUT/RUN_LOG.txt
: > $OUT/MEMORY_LOG.txt
for n in $(seq 1 17); do guard "$n"; $RUN run $n >> $OUT/RUN_LOG.txt 2>&1; done
for p in a b c d e; do guard "18$p"; $RUN runpart 18 $p >> $OUT/RUN_LOG.txt 2>&1; done
$RUN report > $OUT/REPORT_OUTPUT.txt 2>&1; echo "report exit $?" >> $OUT/RUN_LOG.txt
$RUN cases > $OUT/CASES_OUTPUT.txt 2>&1; echo "cases exit $?" >> $OUT/RUN_LOG.txt
fingerprint > $OUT/SOURCE_FINGERPRINT_end.sha256
cmp -s $OUT/SOURCE_FINGERPRINT_start.sha256 $OUT/SOURCE_FINGERPRINT_end.sha256 && echo "fingerprints identical" >> $OUT/RUN_LOG.txt || echo "FINGERPRINTS DIFFER" >> $OUT/RUN_LOG.txt
echo "end $(date -Iseconds)" >> $OUT/RUN_LOG.txt
