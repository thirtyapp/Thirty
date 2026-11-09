import json,sys,glob,os,re
def parse(path):
    tests={};suites={};res={'pass':0,'fail':0,'skip':0,'error':0};dones=[];lines=0;bad=0
    for ln in open(path,encoding='utf-8',errors='replace'):
        ln=ln.strip()
        if not ln: continue
        lines+=1
        try: e=json.loads(ln)
        except Exception: bad+=1; continue
        if not isinstance(e,dict): continue
        t=e.get('type')
        if t=='suite': suites[e['suite']['id']]=e['suite'].get('path')
        elif t=='testStart':
            tt=e['test']; tests[tt['id']]=(tt['name'],tt.get('suiteID'),tt.get('url') is None and tt['name'].startswith('loading'))
        elif t=='testDone':
            name,sid,_= tests.get(e['testID'],('?',None,False))
            if e.get('hidden'): continue
            if e.get('skipped'): res['skip']+=1
            elif e['result']=='success': res['pass']+=1
            else: res['fail']+=1
        elif t=='error': res['error']+=1
        elif t=='done': dones.append(e.get('success'))
    files=set(p for p in suites.values() if p)
    return res,dones,files,lines,bad
if __name__=='__main__':
    tot={'pass':0,'fail':0,'skip':0,'error':0};allfiles=set()
    for p in sorted(sys.argv[1:]):
        r,d,f,l,b=parse(p)
        for k in tot: tot[k]+=r[k]
        allfiles|=set(os.path.normpath(x).replace(chr(92),'/').split('/test/')[-1] for x in f)
        print(os.path.basename(p),r,'done=',d,'files=',len(f),'bad=',b)
    print('TOTAL',tot,'distinct files',len(allfiles))
    open(os.environ.get('OUTF','files.txt'),'w').write('\n'.join(sorted(allfiles)))
