#!/usr/bin/env bash
# R8.2 full regression driver: sequential batches (one flutter process at a
# time), a memory guard before each, source fingerprints at start and end.
# Run from the repository root. Kills nothing; stops on low memory.
set -u
OUT=artifacts/r8_2_consolidated_remediation_2026-11-05/regression_final
RUN="python -I $OUT/run_batches.py"
fingerprint() {
  { ls analysis_options.yaml pubspec.yaml pubspec.lock; find lib test -type f | sort; } | LC_ALL=C sort | xargs -d '\n' sha256sum -b
}
free_gb() { powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,2)" | tr ',' '.' | tr -d '\r'; }
guard() {
  for i in $(seq 1 60); do
    f=$(free_gb); if awk "BEGIN{exit !($f >= 2.5)}"; then echo "free before $1: $f GB" >> $OUT/MEMORY_LOG.txt; return 0; fi
    sleep 10
  done
  echo "MEMORY STOP before $1: $(free_gb) GB" | tee -a $OUT/MEMORY_LOG.txt $OUT/RUN_LOG.txt; exit 3
}
fingerprint > $OUT/SOURCE_FINGERPRINT_start.sha256
echo "start $(date -Iseconds)" > $OUT/RUN_LOG.txt
: > $OUT/MEMORY_LOG.txt
for n in $(seq 1 17); do guard "$n"; $RUN run $n >> $OUT/RUN_LOG.txt 2>&1; done
for p in a b c d e; do guard "18$p"; $RUN runpart 18 $p >> $OUT/RUN_LOG.txt 2>&1; done
$RUN report > $OUT/REPORT_OUTPUT.txt 2>&1; echo "report exit $?" >> $OUT/RUN_LOG.txt
$RUN cases > $OUT/CASES_OUTPUT.txt 2>&1; echo "cases exit $?" >> $OUT/RUN_LOG.txt
fingerprint > $OUT/SOURCE_FINGERPRINT_end.sha256
cmp -s $OUT/SOURCE_FINGERPRINT_start.sha256 $OUT/SOURCE_FINGERPRINT_end.sha256 && echo "fingerprints identical" >> $OUT/RUN_LOG.txt || echo "FINGERPRINTS DIFFER" >> $OUT/RUN_LOG.txt
echo "end $(date -Iseconds)" >> $OUT/RUN_LOG.txt
