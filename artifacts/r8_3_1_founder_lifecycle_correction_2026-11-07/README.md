# THIRTY — R8.3.1 founder lifecycle correction (2026-11-07)

**Founder decision on R83-F1: Option B.** The eligibility of a Circle's original valid Start decides its historical Plan credit. A later lifecycle change never makes an ineligible Start eligible.

- **Baseline:** HEAD `e744f505`, with the uncommitted R8.3 working tree on top. It was verified at the start against the R8.3 definitive regression's end fingerprint.
- **Git:** nothing was staged, committed or pushed. Phase E remains HOLD.

## Results

| Item | Result |
|---|---|
| R83-F1 reproduction (`repro_before_fix/`) | `r831_start_eligibility_test.dart` (24 tests): **R8.2 export: 13 pass / 11 fail; R8.3 tree: 13 pass / 11 fail**. The same tests fail on both, so the defect predates R8.3. Probe P1–P3: 1 credit on R8.2 |
| Root cause | `recordGuided` judged eligibility by the Plan's lifecycle at the moment it ran. Three paths re-run it after a Resume, and no durable fact recorded a Start made while paused: the restart catch-up `_mirrorInJournal`, the decision-A fold `_withEarnedCredits`, and the next-day overwrite safety net `_recordBeforeOverwrite`, which runs after the new day's serve has replaced `lastServed` |
| Fix (`source_diffs/r831_lib_vs_R8_3.diff`) | 3 production files; see the next section |
| After (`passing_after/`) | 98/98 R8.3 and R8.3.1 tests; probe P1–P5: 0 credits |
| **Final regression (`regression/`)** | **201/201 files, 2,872 passed, 0 failed, 0 skipped.** Batches 1–18 and 19a–e all exit 0, each with a terminal done of success. EVIDENCE OK and CASES OK, raw-log validated. 13/13 profiles, each exactly once. B8 6/6. INVENTORY OK: vs R8.3, only `r831_start_eligibility_test.dart` 0 → 24. Fingerprints and Git-blob manifests identical from preflight to end (380 files). Memory before each batch: 12.1–13.2 GB |
| Analyzer, audio | No issues; 172/172 + 8/8, 180 bundled files, no asset diff |
| Auditor controls (`auditor_controls/`) | Outcomes identical to R8.3: Astra Appendix B 7/7 and Claude AUD-N1/N2/N3 pass; only the 5 known obsolete R8.1 originals fail |
| L-1 (`l1_assessment/`) | **OPEN — PRE-RELEASE BLOCKER.** Verified, and deferred by the founder on 2026-11-07: not fixed, not waived (see `L1_ASSESSMENT.md` and `../r8_3_bounded_integrity_hardening_2026-11-07/FOUNDER_DECISIONS.md`) |
| R8.3 evidence | Preserved: every test result and raw log is unchanged. The only updates are documentation: the directed R83-F1 and L-1 entries in `ISSUE_REGISTER.json`; and, at the commit authorization, the README status, `LIMITATIONS_R8_3.md` L-1/L-4, `FOUNDER_DECISIONS.md` and `INDEPENDENT_AUDIT_HANDOFF_R8_3.md`. The 2,848-pass run stays valid pre-R8.3.1 evidence |

## The fix in the 3 production files

- **`circle_plan.dart`**
  - New optional field `PlanProgress.startedWhilePaused` (a circleId). It is a known field. A damaged value makes the Plan unreadable, and unknown fields are kept.
  - `noteStartedWhilePaused`.
  - `recordGuided` never credits that Circle.
- **`circle_plans_provider.dart`**
  - `noteStartWhilePaused`: a confirmed write.
  - `startNeedsNoWrite` is false when that write is needed, so the Start takes the waiting path (decision B).
- **`recommendation_provider.dart`**
  - `_startOnceSaved` writes the fact at the valid Start, then checks again the identity, status and day.
  - When the write is refused, the Start is refused.
- **Delete** removes the field with the other stage evidence.
