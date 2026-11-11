#!/usr/bin/env bash
# R8.3.4.1: R8.3.4 adversarial suites, preserved prior-auditor probes and
# focused earlier controls, in two disposable trees:
#   red   = exact dd9000cd export (git archive, core.autocrlf=false)
#   fixed = the same export + the two R8.3.4.1 production files + the new
#           permanent test file.
# Every probe is copied byte for byte from where it is preserved.
set -u
S=/c/Users/thoma/AppData/Local/Temp/claude/a9b5f32403779c05/392e102b-26d8-4014-8fa5-8ed0e276c2a6/scratchpad
R="/c/Users/thoma/Desktop/THIRTY App/Development/Thirty-step5-billing-integration"
E="$R/artifacts/r8_3_4_1_delete_outcome_continuity_2026-11-11"
OUT="$E/controls"
A32="$R/artifacts/r8_3_2_consolidated_integrity_closure_2026-11-07/audit_inputs/claude_original_scratchpad/zz_audit"
P8="$R/artifacts/r8_3_4_final_action_identity_closure_2026-11-10"
CL834=/c/Users/thoma/AppData/Local/Temp/claude/b7fd4c17e92f619e/fb8ede49-7c3e-4112-b879-89d56ac06d0e/scratchpad/p834/test/zz_audit
declare -A TREE=([red]="$S/pristine_dd9000cd" [fixed]="$S/export_dd9000cd")
: > "$OUT/controls_status.txt"
for t in red fixed; do
  T="${TREE[$t]}"
  mkdir -p "$T/test/zz_audit/appb" "$T/test/features/r832_gate" "$T/test/features/r833_independent" "$T/test/features/r834_gate" "$T/test/features/r834_independent"
  # Earlier auditor controls (as in R8.3.4 auditor_controls/run_controls.sh).
  cp "$A32/audit_r82_adversarial_test.dart.txt" "$T/test/zz_audit/audit_r82_adversarial_test.dart"
  cp "$A32/audit_r82_order_test.dart.txt" "$T/test/zz_audit/audit_r82_order_test.dart"
  cp "$A32/audit_r83_delta_test.dart.txt" "$T/test/zz_audit/audit_r83_delta_test.dart"
  cp "$A32/appb/astra_appendix_b_test.dart.txt" "$T/test/zz_audit/appb/astra_appendix_b_test.dart"
  cp "$R/artifacts/r8_3_2_g1_closure_2026-11-09/gate/r832_final_gate_checks_test.dart.txt" "$T/test/features/r832_gate/r832_final_gate_checks_test.dart"
  cp "$R/artifacts/r8_3_3_consolidated_integrity_closure_2026-11-10/audit_inputs/claude_audit_r832_delta_test.dart.txt" "$T/test/zz_audit/audit_r832_delta_test.dart"
  # R8.3.4 adversarial suites: Astra R833 original + disclosed corrected copy,
  # Claude post-R8.3.3 probe, R8.3.4 commit-gate probes, Claude R8.3.4
  # acceptance probe, Astra R8.3.4 acceptance probe (original bytes).
  cp "$P8/astra_probe_correction/r833_independent_adversarial_test_ORIGINAL.dart.txt" "$T/test/features/r833_independent/r833_independent_adversarial_test.dart"
  cp "$P8/astra_probe_correction/r833_independent_adversarial_test_CORRECTED.dart.txt" "$T/test/features/r833_independent/zz_corrected_test.dart"
  cp "$P8/audit_inputs/claude_probe/audit_r833_delta_test.dart.txt" "$T/test/zz_audit/audit_r833_delta_test.dart"
  cp "$P8/commit_verification/gate_probes/r834_gate_probes_test.dart.txt" "$T/test/features/r834_gate/r834_gate_probes_test.dart"
  cp "$CL834/audit_r834_final_test.dart" "$T/test/zz_audit/audit_r834_final_test.dart"
  cp "$E/audit_inputs/r834_acceptance_boundary_test.ORIGINAL.dart.txt" "$T/test/features/r834_independent/r834_acceptance_boundary_test.dart"
done
CONTROLS="test/zz_audit/audit_r82_adversarial_test.dart test/zz_audit/audit_r82_order_test.dart test/zz_audit/audit_r83_delta_test.dart test/zz_audit/appb/astra_appendix_b_test.dart test/features/r832_gate/r832_final_gate_checks_test.dart test/zz_audit/audit_r832_delta_test.dart"
PROBES834="test/features/r833_independent/r833_independent_adversarial_test.dart test/features/r833_independent/zz_corrected_test.dart test/zz_audit/audit_r833_delta_test.dart test/features/r834_gate/r834_gate_probes_test.dart test/zz_audit/audit_r834_final_test.dart test/features/r834_independent/r834_acceptance_boundary_test.dart"
for t in red fixed; do
  (cd "${TREE[$t]}" && flutter test --concurrency=1 --reporter json $CONTROLS > "$OUT/controls_on_$t.jsonl" 2> "$OUT/controls_on_$t.err"; echo "controls $t exit $?" >> "$OUT/controls_status.txt")
  (cd "${TREE[$t]}" && flutter test --concurrency=1 --reporter json $PROBES834 > "$OUT/probes834_on_$t.jsonl" 2> "$OUT/probes834_on_$t.err"; echo "probes834 $t exit $?" >> "$OUT/controls_status.txt")
done
(cd "${TREE[fixed]}" && flutter test --concurrency=1 --reporter json test/features/r81 test/features/r82 test/features/r83 test/features/r832 test/features/r833 test/features/r834 > "$OUT/focused_on_fixed.jsonl" 2> "$OUT/focused_on_fixed.err"; echo "focused fixed exit $?" >> "$OUT/controls_status.txt")
echo DONE >> "$OUT/controls_status.txt"
