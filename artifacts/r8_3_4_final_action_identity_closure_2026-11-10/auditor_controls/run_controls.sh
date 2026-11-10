#!/usr/bin/env bash
# R8.3.4: focused suites + preserved prior-auditor probe files, in the two
# disposable checkouts (red = exact 285b5c70 export, fixed = export + R8.3.4).
set -u
S=/c/Users/thoma/AppData/Local/Temp/claude/a9b5f32403779c05/b78a27f4-e84f-4146-9261-5fad041776c6/scratchpad
R="/c/Users/thoma/Desktop/THIRTY App/Development/Thirty-step5-billing-integration"
A32="$R/artifacts/r8_3_2_consolidated_integrity_closure_2026-11-07/audit_inputs/claude_original_scratchpad/zz_audit"
for t in red fixed; do
  mkdir -p "$S/$t/test/zz_audit/appb" "$S/$t/test/features/r832_gate"
  cp "$A32/audit_r82_adversarial_test.dart.txt" "$S/$t/test/zz_audit/audit_r82_adversarial_test.dart"
  cp "$A32/audit_r82_order_test.dart.txt" "$S/$t/test/zz_audit/audit_r82_order_test.dart"
  cp "$A32/audit_r83_delta_test.dart.txt" "$S/$t/test/zz_audit/audit_r83_delta_test.dart"
  cp "$A32/appb/astra_appendix_b_test.dart.txt" "$S/$t/test/zz_audit/appb/astra_appendix_b_test.dart"
  cp "$R/artifacts/r8_3_2_g1_closure_2026-11-09/gate/r832_final_gate_checks_test.dart.txt" "$S/$t/test/features/r832_gate/r832_final_gate_checks_test.dart"
  cp "$R/artifacts/r8_3_3_consolidated_integrity_closure_2026-11-10/audit_inputs/claude_audit_r832_delta_test.dart.txt" "$S/$t/test/zz_audit/audit_r832_delta_test.dart"
done
CONTROLS="test/zz_audit/audit_r82_adversarial_test.dart test/zz_audit/audit_r82_order_test.dart test/zz_audit/audit_r83_delta_test.dart test/zz_audit/appb/astra_appendix_b_test.dart test/features/r832_gate/r832_final_gate_checks_test.dart test/zz_audit/audit_r832_delta_test.dart"
for t in red fixed; do
  (cd "$S/$t" && flutter test --concurrency=1 --reporter json $CONTROLS > "$S/controls_on_$t.jsonl" 2> "$S/controls_on_$t.err"; echo "controls $t exit $?" >> "$S/controls_status.txt")
done
(cd "$S/fixed" && flutter test --concurrency=1 --reporter json test/features/r81 test/features/r82 test/features/r83 test/features/r832 test/features/r833 test/features/r834 > "$S/focused_on_fixed.jsonl" 2> "$S/focused_on_fixed.err"; echo "focused fixed exit $?" >> "$S/controls_status.txt")
echo DONE >> "$S/controls_status.txt"
