"""Summarise a `flutter test --reporter json` raw log.

Usage: python -I summarize.py LOG [--evidence]
Prints one line per test: RESULT | name | first error line.
PRECONDITION failures are reported as N/A.
"""
import json
import sys
sys.stdout.reconfigure(encoding="utf-8")

path = sys.argv[1]
show_evidence = "--evidence" in sys.argv
tests, errors, prints, done = {}, {}, {}, []
for line in open(path, encoding="utf-8"):
    line = line.strip()
    if not line.startswith("{"):
        continue
    e = json.loads(line)
    t = e.get("type")
    if t == "testStart":
        tests[e["test"]["id"]] = {"name": e["test"]["name"], "result": None}
    elif t == "error":
        errors.setdefault(e["testID"], []).append(e["error"])
    elif t == "print":
        prints.setdefault(e["testID"], []).append(e["message"])
    elif t == "testDone":
        if e.get("hidden"):
            tests.pop(e["testID"], None)
            continue
        tests[e["testID"]]["result"] = e["result"]
        tests[e["testID"]]["skipped"] = e.get("skipped", False)
    elif t == "done":
        done.append(e.get("success"))

counts = {}
for tid, info in tests.items():
    errs = errors.get(tid, [])
    first = errs[0].strip().splitlines()[0] if errs else ""
    if info.get("skipped"):
        verdict = "SKIP"
    elif info["result"] == "success":
        verdict = "PASS"
    elif "PRECONDITION" in " ".join(errs):
        verdict = "N/A"
    else:
        verdict = "FAIL"
    counts[verdict] = counts.get(verdict, 0) + 1
    name = info["name"].split(" — ")[-1] if False else info["name"]
    print(f"{verdict:4} | {name}")
    if verdict != "PASS" and first:
        reason = next((l.strip() for l in errs[0].splitlines() if "Expected" in l or "Actual" in l or "PRECONDITION" in l or "reason" in l.lower() or "Which" in l), first)
        print(f"     -> {first[:200]}")
        for l in errs[0].splitlines()[:8]:
            if l.strip().startswith(("Expected", "Actual", "Which")):
                print(f"        {l.strip()[:220]}")
    if show_evidence:
        for p in prints.get(tid, []):
            if p.startswith("R832-EVIDENCE"):
                print(f"     {p[:1500]}")
print("COUNTS", counts, "DONE", done)
