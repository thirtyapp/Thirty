import json,sys
for line in open(sys.argv[1],encoding='utf-8',errors='replace'):
    i=line.find('INDEPENDENT-R834-EVIDENCE ')
    if i<0: continue
    d=json.loads(line[i+len('INDEPENDENT-R834-EVIDENCE '):])
    if d['test'].startswith('GATE'): print(d['test'],d['first'],d['second'],d['fresh'],len(d['kept'])); continue
    s=d['snapshotBeforeRestart'] or {}
    b=d['diskBeforeRestart']; a=d['diskAfterRestart']
    def kept(x):
        k=x.get('kept_circles_v1') or x.get('toolkit_v1')
        return k
    print(d['test'],'| apply',d['apply'],'| gate',d['gateBefore'],d['gateAfter'],'| intentDisk',d['intentBeforeReceipt'],'| appliedOn',s.get('appliedOn'),'attempt',s.get('attempt'),'| made',d['targetMade'],'| retry',d['retryAfterRestart'])
    print('   before keys',sorted(b.keys()))
    print('   after  keys',sorted(a.keys()))
    print('   pendingBefore',b.get('circle_history_deletion_pending'),'pendingAfter',a.get('circle_history_deletion_pending'))
