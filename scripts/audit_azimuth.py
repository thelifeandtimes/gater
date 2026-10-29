#!/usr/bin/env python3
"""Audit the complete effective-Azimuth log suffix against finalized Ethereum.

Trust anchor: the explicitly pinned Urbit bootstrap snapshot in config. All
subsequent L1 logs and L2 rollup transaction inputs are checked against RPC.
The agent rechecks the material hash atomically and runs Urbit's naive VM.
No signing, invitations or changes to %azimuth are performed by this worker.
"""
import argparse
import json
import os
from pathlib import Path
import time

from scan import Rpc, RpcError, quantity, hash32, address
from index import header
from host_import import host_action, audit_material

AZIMUTH='0x223c067f8cf28ae173ee5cafea60ca44c335fecb'
ROLLUP='0xeb70029cfb3c53c778eaf68cd28de725390a1fe9'


class AuditRpc(Rpc):
    def __call__(self, method, params):
        # Log queries cost more provider credits than block/input checks.
        self.min_interval = 1.0 if method == 'eth_getLogs' else .15
        return super().__call__(method, params)


def normalize(row, native=False):
    number = int if native else quantity
    return (number(row['blockNumber']), number(row['transactionIndex']), number(row['logIndex']),
            hash32(row['blockHash']), hash32(row['transactionHash']), address(row['address']),
            row['data'].lower(), tuple(hash32(t) for t in row['topics']), row['removed'])


def logs(rpc, first, last):
    try:
        result = rpc('eth_getLogs',[{'address':[AZIMUTH,ROLLUP],'fromBlock':hex(first),'toBlock':hex(last)}])
    except RpcError as error:
        if not error.range_limit or first==last: raise
        middle=(first+last)//2
        return logs(rpc,first,middle)+logs(rpc,middle+1,last)
    if not isinstance(result,list):raise ValueError('Missing log array')
    for row in result:
        if row.get('removed') is not False or not first<=quantity(row['blockNumber'])<=last or address(row['address']) not in (AZIMUTH,ROLLUP):
            raise ValueError('Foreign, removed or out-of-range log')
    return result


def verify(rpc, material, anchor, previous=None, *, now=None, progress=None):
    fixed_now=now
    now=int(time.time()) if now is None else now
    if quantity(rpc('eth_chainId',[])) != 1:raise ValueError('Ethereum mainnet required')
    if (int(material['anchorHeight']),material['anchorHash'],material['anchorDigest']) != (anchor['height'],anchor['hash'],anchor['digest']):
        raise ValueError('Unrecognized Urbit bootstrap; review and pin it before delivery')
    if header(rpc,hex(anchor['height']))['hash']!=anchor['hash']:raise ValueError('Bootstrap is not canonical')
    final=header(rpc,'finalized');height=int(material['height'])
    if not anchor['height']<=height<=final['number']:raise ValueError('Audit target is not finalized')
    target=header(rpc,hex(height))
    if not 0<=now-target['timestamp']<=3600:raise ValueError('Finalized target is stale')
    native=material['logs'];normalized=[normalize(r,True) for r in native]
    if normalized != sorted(normalized) or len({(r[0],r[2]) for r in normalized})!=len(normalized):
        raise ValueError('Native history is unordered or duplicated')
    if any(r[-1] is not False or not anchor['height']<r[0]<=height or r[5] not in (AZIMUTH,ROLLUP) for r in normalized):
        raise ValueError('Invalid native suffix')
    covered=anchor['height'];saved=[]
    if previous:
        if previous.get('anchor')!=anchor or previous['checkpoint']['number']>height:raise ValueError('Audit cache/height changed; review required')
        if header(rpc,hex(previous['checkpoint']['number']))['hash']!=previous['checkpoint']['hash']:raise ValueError('Finalized history diverged')
        covered=previous['checkpoint']['number'];saved=previous['logs']
    canonical=saved[:]
    for start in range(covered+1,height+1,10000):
        end=min(start+9999,height);canonical.extend(logs(rpc,start,end))
        if progress:progress(end,height)
    expected=sorted(normalize(r) for r in canonical)
    if expected!=normalized:raise ValueError('Native Azimuth suffix is incomplete or differs from canonical logs')
    # Verify canonical hashes and L2 transaction input, including tx destination.
    # Reuse input observations only under an unchanged finalized block hash.
    inputs=dict(previous.get('inputs',{})) if previous else {}
    blocks=dict(previous.get('blocks',{})) if previous else {}
    for position,row in enumerate(native):
        if progress and position % 250 == 0: print(f'Checking canonical blocks and rollup inputs: {position}/{len(native)}',flush=True)
        block=str(row['blockNumber']);block_hash=row['blockHash'];tx=row['transactionHash']
        if blocks.get(block)!=block_hash:
            if header(rpc,hex(int(block)))['hash']!=block_hash:raise ValueError('Log block hash mismatch')
            blocks[block]=block_hash
        if row['address'].lower()!=ROLLUP:continue
        if tx not in inputs:
            data=rpc('eth_getTransactionByHash',[tx])
            if not data or data.get('hash','').lower()!=tx or data.get('blockHash','').lower()!=block_hash or quantity(data['blockNumber'])!=int(block) or address(data['to'])!=ROLLUP:
                raise ValueError('Rollup transaction mismatch')
            inputs[tx]=hex(quantity(data['input']))
        if row.get('input') is None or int(row['input'].replace('.',''),16)!=quantity(inputs[tx]):raise ValueError('Rollup calldata mismatch')
    if header(rpc,hex(height))!=target:raise ValueError('Finalized checkpoint changed during audit')
    completed=int(time.time()) if fixed_now is None else fixed_now
    if not 0<=completed-target['timestamp']<=3600:raise ValueError('Finalized target became stale during audit')
    return {'anchor':anchor,'checkpoint':target,'logs':canonical,'inputs':inputs,'blocks':blocks}


def sync(deployment,rpc,anchor_path,cache_path, *, live_ship=None):
    if live_ship is not None and live_ship != deployment['ship']:
        raise ValueError('Deployment identity does not match --live-ship')
    target = {'live_ship': live_ship} if live_ship is not None else {'live_comet': deployment['ship']}
    anchor=json.loads(Path(anchor_path).read_text());cache_path=Path(cache_path)
    previous=json.loads(cache_path.read_text()) if cache_path.exists() else None
    final=header(rpc,'finalized')
    if previous and final['number']<previous['checkpoint']['number']:
        if header(rpc,hex(previous['checkpoint']['number']))['hash']!=previous['checkpoint']['hash']:raise ValueError('Finalized checkpoint divergence')
        raise ValueError('Provider finalized head is temporarily behind the audited checkpoint')
    material=audit_material(deployment['pier'], final['number'], **target)
    verified=verify(rpc,material,anchor,previous,progress=lambda n,h:print(f'Checking Ethereum log coverage: {n}/{h}',flush=True))
    payload={'action':'audit-azimuth','height':str(final['number']),'hash':verified['checkpoint']['hash'],'observedAt':str(int(time.time())),
             'materialDigest':material['materialDigest'],'anchorDigest':material['anchorDigest']}
    # Canonical evidence can be cached even if the host must retry its import.
    cache_path.parent.mkdir(parents=True,exist_ok=True);tmp=cache_path.with_suffix('.tmp');tmp.write_text(json.dumps(verified));tmp.replace(cache_path)
    host_action(deployment['pier'],payload,**target)
    return {'verified':True,'height':final['number'],'logs':len(material['logs']),'anchor':anchor['height']}


def main():
    p=argparse.ArgumentParser(description=__doc__)
    target=p.add_mutually_exclusive_group()
    target.add_argument('--deployment',help='Legacy named-comet deployment JSON (default: output/comet.local.json)')
    target.add_argument('--pier',help='Local running pier; requires --live-ship')
    p.add_argument('--live-ship',help='Opt in to this exact livenet ship identity; requires --pier')
    p.add_argument('--anchor',default='config/azimuth-anchor.json')
    p.add_argument('--cache',default='output/azimuth-audit.local.json')
    p.add_argument('--rpc-env',default='ETHEREUM_RPC_URL')
    p.add_argument('--watch',action='store_true')
    args=p.parse_args()
    if bool(args.pier) != bool(args.live_ship):
        p.error('--pier and --live-ship must be supplied together')
    deployment=({'pier': args.pier, 'ship': args.live_ship} if args.pier else
                json.loads(Path(args.deployment or 'output/comet.local.json').read_text()))
    endpoint=os.environ.get(args.rpc_env)
    if not endpoint: p.error(f'Set {args.rpc_env} privately')
    rpc=AuditRpc(endpoint,attempts=6)
    while True:
        try: print(json.dumps(sync(deployment,rpc,args.anchor,args.cache,live_ship=args.live_ship)),flush=True)
        except Exception as error:
            print('Azimuth audit unavailable: '+str(error) if isinstance(error,(ValueError,RuntimeError)) else 'Azimuth audit unavailable: '+type(error).__name__,flush=True)
            if not args.watch: raise SystemExit(1)
        if not args.watch:break
        time.sleep(120)

if __name__=='__main__':main()
