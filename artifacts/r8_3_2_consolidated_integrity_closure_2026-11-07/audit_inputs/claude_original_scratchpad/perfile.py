import json,sys,os,collections
def per(paths):
    c=collections.Counter()
    for p in paths:
        suites={};tests={}
        for ln in open(p,encoding='utf-8',errors='replace'):
            try:e=json.loads(ln)
            except: continue
            if not isinstance(e,dict): continue
            t=e.get('type')
            if t=='suite': suites[e['suite']['id']]=(e['suite'].get('path') or '').replace(chr(92),'/').split('/test/')[-1]
            elif t=='testStart': tests[e['test']['id']]=e['test'].get('suiteID')
            elif t=='testDone' and not e.get('hidden') and e.get('result')=='success': c[suites.get(tests.get(e['testID']))]+=1
    return c
import glob
a=per(glob.glob(sys.argv[1]));b=per([sys.argv[2]])
for k in sorted(set(a)|set(b)):
    if a[k]!=b[k]: print(k,'impl',a[k],'mine',b[k])
