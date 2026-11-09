import json, sys, re
sys.stdout.reconfigure(encoding="utf-8")
def load(path):
    tests, errs, out = {}, {}, {}
    for line in open(path, encoding="utf-8"):
        if not line.startswith("{"): continue
        e = json.loads(line)
        if e.get("type") == "testStart": tests[e["test"]["id"]] = e["test"]["name"]
        elif e.get("type") == "error": errs.setdefault(e["testID"], []).append(e["error"])
        elif e.get("type") == "testDone" and not e.get("hidden"):
            n = tests[e["testID"]]
            if e.get("skipped"): v = "SKIP"
            elif e["result"] == "success": v = "PASS"
            elif "PRECONDITION" in " ".join(errs.get(e["testID"], [])): v = "N/A"
            else: v = "FAIL"
            out[n] = v
    return out
cols = [(name, load(path)) for name, path in zip(sys.argv[1::2], sys.argv[2::2])]
names = list(cols[-1][1].keys())
print("| Test | " + " | ".join(c[0] for c in cols) + " |")
print("|---|" + "---|" * len(cols))
for n in names:
    short = re.sub(r"^(Plans — Start identity and historical eligibility |Group D — Astra R83-N03 and Insight idempotence |The paused-Start record's stored form )", "", n)
    print(f"| {short} | " + " | ".join(c[1].get(n, "—") for c in cols) + " |")
