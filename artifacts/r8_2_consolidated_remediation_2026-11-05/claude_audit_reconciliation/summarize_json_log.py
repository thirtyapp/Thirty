import json,sys
names={};res={};prints={};errs={}
for line in open(sys.argv[1],encoding='utf-8'):
    try: e=json.loads(line)
    except: continue
    t=e.get('type')
    if t=='testStart': names[e['test']['id']]=e['test']['name']
    elif t=='testDone' and not e.get('hidden'): res[e['testID']]=e['result']
    elif t=='print': prints.setdefault(e['testID'],[]).append(e['message'])
    elif t=='error': errs.setdefault(e['testID'],[]).append(e['error'].split('\n')[0:3])
p=f=0
for i,r in res.items():
    if r=='success': p+=1
    else: f+=1
    print(('PASS ' if r=='success' else 'FAIL ')+names[i])
    for m in prints.get(i,[]): print('   print:',m)
    for m in errs.get(i,[]): print('   error:',' | '.join(m)[:400])
print(f'TOTAL pass={p} fail={f}')
