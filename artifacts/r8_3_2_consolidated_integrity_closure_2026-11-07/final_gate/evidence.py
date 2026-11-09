import json, sys
sys.stdout.reconfigure(encoding="utf-8")
pat = sys.argv[2:] 
for line in open(sys.argv[1], encoding="utf-8"):
    if '"type":"print"' not in line: continue
    m = json.loads(line)["message"]
    if not m.startswith("R832-EVIDENCE "): continue
    ev = json.loads(m[len("R832-EVIDENCE "):])
    if pat and not any(p in ev["test"] for p in pat): continue
    print(json.dumps(ev, ensure_ascii=False))
