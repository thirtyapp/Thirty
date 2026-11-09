These are the first failing-before runs of the R832-G1 test file on the unchanged working tree (fingerprint = the 2,944 run), before any production change. All three runs are kept.
- run1 (*_run1_R7_harness_artifact.*): R7 released the held write of the "dead" process after the restart. It then landed on the new disk through the shared platform store. That is a harness artifact, so R7 was redesigned.
- run2 (*_run2_R7_test_error.*): R7 expected a fresh tap after the restart, but the unsaved offer is gone after a restart. That is a test error, so R7 now asserts that nothing started.
- G1_on_pre_fix.* (run3, bytes 404cb077…, copied here as r832_g1_lifecycle_generation_test.dart.txt): 11 FAIL / 11 PASS.
The final file differs from run3 only by one unused import that was removed (analyzer warning). The definitive before/after on the final bytes is ../gate/GATE_AND_G1_on_prefix.* (14 FAIL = 3 final-gate Check A + 11 G1) and ../gate/GATE_AND_G1_on_fixed.* (32/32).
