#!/usr/bin/env python3
"""Persistent finalized ERC-721 index. Reads only; no signing or transactions.

One JSON state file atomically stores the cursor, ownership, transfer generations,
coverage and the exact snapshot to import. A failed run preserves the last good
snapshot and marks health failed. Reorg recovery requires an explicit --rebuild.
"""
import argparse
import copy
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time
import uuid

from scan import Rpc, RpcError, TRANSFER, ZERO, address, quantity, hash32

CONSECUTIVE = '0xdeaa91b6123d068f5821d0fb0678463d1a8a6079fe8af5de3ce5e896dcf9133d'


def digest(value):
    return '0x' + hashlib.sha256(value.encode()).hexdigest()


def config_checked(config):
    result = dict(config)
    result['contract'] = address(result['contract'])
    if result['contract'] == ZERO or result['chain'] not in (1, 8453):
        raise ValueError('Invalid chain or contract')
    if not re.fullmatch('[a-z][a-z0-9-]*', result['collection']):
        raise ValueError('Invalid collection ID')
    if result['discovery'] not in ('enumerable', 'events-supply'):
        raise ValueError('Choose enumerable or events-supply discovery')
    if result['discovery'] == 'events-supply':
        if type(result.get('deploymentBlock')) is not int or result['deploymentBlock'] < 1:
            raise ValueError('Events require an explicit deploymentBlock')
        if not result.get('reviewedSource'):
            raise ValueError('Record the reviewed contract source for event coverage')
    return result


def header(rpc, tag):
    block = rpc('eth_getBlockByNumber', [tag, False])
    if not block:
        raise ValueError('Missing finalized block; latest is never a fallback')
    result = {'number': quantity(block['number']), 'hash': hash32(block['hash']), 'timestamp': quantity(block['timestamp'])}
    if tag != 'finalized' and result['number'] != quantity(tag):
        raise ValueError('RPC returned the wrong block number')
    return result


def call(rpc, contract, height, data):
    return quantity(hash32(rpc('eth_call', [{'to': contract, 'data': data}, hex(height)])))


def supports(rpc, contract, height, interface):
    return call(rpc, contract, height, '0x01ffc9a7' + interface + '0' * 56) == 1


def owner_of(rpc, contract, height, token):
    owner = call(rpc, contract, height, '0x6352211e' + f'{int(token):064x}')
    if not 0 < owner < 2 ** 160:
        raise ValueError('Invalid ownerOf address')
    return f'0x{owner:040x}'


def replay(tokens, logs, contract, lower, upper, max_tokens):
    if not isinstance(logs, list):
        raise ValueError('Logs must be an array')
    seen, blocks = set(), {}
    for row in sorted(logs, key=lambda r: (quantity(r['blockNumber']), quantity(r['logIndex']))):
        block, index = quantity(row['blockNumber']), quantity(row['logIndex'])
        block_hash = hash32(row['blockHash'])
        hash32(row['transactionHash'])
        if row.get('removed') is not False or not lower <= block <= upper or address(row['address']) != contract:
            raise ValueError('Removed, foreign or out-of-range finalized log')
        if (block, index) in seen or blocks.get(block, block_hash) != block_hash:
            raise ValueError('Duplicate log or inconsistent block hash')
        seen.add((block, index)); blocks[block] = block_hash
        topics = row['topics']
        if len(topics) != 4:
            raise ValueError('Expected four ERC-721 event topics')
        event = hash32(topics[0])
        if event == TRANSFER:
            before, after, first = [quantity(hash32(t)) for t in topics[1:]]
            last = first
            if row.get('data', '0x') != '0x':
                raise ValueError('Unexpected Transfer data')
        elif event == CONSECUTIVE:
            first, before, after = [quantity(hash32(t)) for t in topics[1:]]
            last = quantity(hash32(row['data']))
        else:
            raise ValueError('Unexpected event signature')
        if before >= 2 ** 160 or after >= 2 ** 160 or before == after == 0:
            raise ValueError('Invalid transfer addresses')
        if last < first or last - first + 1 > max_tokens:
            raise ValueError('ConsecutiveTransfer range exceeds the configured limit')
        before, after = f'0x{before:040x}', f'0x{after:040x}'
        for token in range(first, last + 1):
            key = str(token)
            old = tokens.get(key)
            if (before == ZERO and old is not None) or (before != ZERO and (old is None or old['owner'] != before)):
                raise ValueError('Incomplete or inconsistent transfer history')
            if after == ZERO:
                tokens.pop(key)
            elif before != after:
                tokens[key] = {'owner': after, 'generation': str(int(digest(f'{block_hash}:{index}:{token}'), 16))}
            if len(tokens) > max_tokens:
                raise ValueError('Collection exceeds the configured token limit')
    return blocks


def update(rpc, config, previous=None, *, window=2000, max_tokens=100000, now=None):
    config = config_checked(config)
    if window < 1 or max_tokens < 1:
        raise ValueError('Invalid range or token limit')
    if quantity(rpc('eth_chainId', [])) != config['chain']:
        raise ValueError('RPC chain mismatch')
    now = int(time.time()) if now is None else now
    final = header(rpc, 'finalized')
    height, contract = final['number'], config['contract']
    if not 0 <= now - final['timestamp'] <= 3600:
        raise ValueError('Finalized checkpoint is stale or in the future')
    code = rpc('eth_getCode', [contract, hex(height)])
    if not isinstance(code, str) or not re.fullmatch(r'0x(?:[0-9a-fA-F]{2})+', code):
        raise ValueError('Missing or invalid contract bytecode')
    code_hash = digest(code.lower())
    if not supports(rpc, contract, height, '80ac58cd'):
        raise ValueError('ERC-721 support required')
    if previous:
        if previous.get('version') != 1 or previous['config'] != config:
            raise ValueError('Index configuration changed; explicit rebuild required')
        saved = previous['checkpoint']
        if saved['number'] > height or header(rpc, hex(saved['number']))['hash'] != saved['hash']:
            raise ValueError('Checkpoint divergence; explicit rebuild required')
        if previous['codeHash'] != code_hash:
            raise ValueError('Contract bytecode changed; review and rebuild required')
        tokens = copy.deepcopy(previous['tokens'])
        epoch, lower = previous['epoch'], saved['number'] + 1
        bootstrap = previous['bootstrap']
    else:
        tokens, epoch = {}, '0x' + uuid.uuid4().hex.rjust(64, '0')
        bootstrap = height
        lower = height + 1
        if config['discovery'] == 'enumerable':
            if not supports(rpc, contract, height, '780e9d63'):
                raise ValueError('Collection does not implement ERC-721 enumeration')
            supply = call(rpc, contract, height, '0x18160ddd')
            if supply > max_tokens:
                raise ValueError('Collection exceeds the configured token limit')
            for i in range(supply):
                token = str(call(rpc, contract, height, '0x4f6ccce7' + f'{i:064x}'))
                if token in tokens:
                    raise ValueError('Duplicate token from enumeration')
                tokens[token] = {'owner': owner_of(rpc, contract, height, token),
                                 'generation': str(int(digest(f'{final["hash"]}:bootstrap:{token}'), 16))}
        else:
            lower = bootstrap = config['deploymentBlock']
            if lower > height:
                raise ValueError('Deployment block is beyond finality')
            if rpc('eth_getCode', [contract, hex(lower - 1)]) not in ('0x', '0x0'):
                raise ValueError('Contract already existed before declared deployment')
            if rpc('eth_getCode', [contract, hex(lower)]) in ('0x', '0x0'):
                raise ValueError('Contract absent at declared deployment')
    step = window
    while lower <= height:
        upper = min(height, lower + step - 1)
        try:
            logs = rpc('eth_getLogs', [{'address': contract, 'topics': [[TRANSFER, CONSECUTIVE]],
                                       'fromBlock': hex(lower), 'toBlock': hex(upper)}])
        except RpcError as error:
            if not error.range_limit or step == 1:
                raise
            step = max(1, step // 2)
            continue
        blocks = replay(tokens, logs, contract, lower, upper, max_tokens)
        for block, block_hash in blocks.items():
            if header(rpc, hex(block))['hash'] != block_hash:
                raise ValueError('Log block is not canonical')
        lower = upper + 1
    # Count is independent of discovery, catching missing constructor mints.
    supply = call(rpc, contract, height, '0x18160ddd')
    if supply != len(tokens):
        raise ValueError('totalSupply disagrees with index coverage; use enumeration or a collection adapter')
    for token, data in tokens.items():
        if owner_of(rpc, contract, height, token) != data['owner']:
            raise ValueError('ownerOf disagrees with index')
    if header(rpc, hex(height)) != final:
        raise ValueError('Finalized checkpoint changed during scan')
    snapshot = {'action': 'snapshot', 'collection': config['collection'], 'chain': str(config['chain']),
                'contract': contract, 'observedAt': str(now), 'block': str(height), 'blockHash': final['hash'],
                'epoch': epoch, 'coverage': {'method': config['discovery'], 'fromBlock': str(bootstrap),
                'supply': str(supply), 'codeHash': code_hash},
                'tokens': [dict(id=token, **tokens[token]) for token in sorted(tokens, key=int)]}
    return {'version': 1, 'config': config, 'checkpoint': final, 'codeHash': code_hash, 'epoch': epoch,
            'bootstrap': bootstrap, 'tokens': tokens, 'snapshot': snapshot,
            'health': {'ok': True, 'attemptedAt': now, 'lastSuccess': now}}


def atomic_write(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp = tempfile.mkstemp(prefix=path.name + '.', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as out:
            json.dump(value, out, indent=2); out.write('\n'); out.flush(); os.fsync(out.fileno())
        os.replace(temp, path)
        directory = os.open(path.parent, os.O_RDONLY)
        try: os.fsync(directory)
        finally: os.close(directory)
    finally:
        if os.path.exists(temp): os.unlink(temp)


def run_once(rpc, config, state_path, *, rebuild=False, **options):
    path = Path(state_path)
    previous = json.loads(path.read_text()) if path.exists() else None
    try:
        seed = previous if previous and 'snapshot' in previous else None
        result = update(rpc, config, None if rebuild else seed, **options)
    except (ValueError, KeyError, TypeError) as error:
        failed = copy.deepcopy(previous) if previous else {'version': 1, 'config': config}
        failed['health'] = {'ok': False, 'attemptedAt': int(time.time()),
                            'lastSuccess': (previous or {}).get('health', {}).get('lastSuccess'),
                            'reason': type(error).__name__}
        atomic_write(path, failed)
        raise
    atomic_write(path, result)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path, required=True)
    parser.add_argument('--state', type=Path, required=True)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--rpc-env', default='GATER_RPC_URL')
    parser.add_argument('--window', type=int, default=2000)
    parser.add_argument('--max-tokens', type=int, default=100000)
    parser.add_argument('--watch', action='store_true', help='Poll continuously with bounded failure backoff')
    parser.add_argument('--interval', type=int, default=60)
    parser.add_argument('--rebuild', action='store_true', help='Discard cursor, establish a new epoch, and require new claims')
    parser.add_argument('--pier', type=Path, help='Import success or failure into this explicitly selected local host pier')
    args = parser.parse_args()
    paths = [args.config.resolve(), args.state.resolve()]
    if args.output: paths.append(args.output.resolve())
    if len(paths) != len(set(paths)): parser.error('Config, state and output must be different files')
    if args.interval < 5: parser.error('Polling interval must be at least five seconds')
    endpoint = os.environ.get(args.rpc_env)
    if not endpoint: parser.error(f'Set {args.rpc_env} privately')
    config = config_checked(json.loads(args.config.read_text()))
    args.state.parent.mkdir(parents=True, exist_ok=True)
    with args.state.with_suffix(args.state.suffix + '.lock').open('a') as lock:
        try: fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError: parser.exit(1, 'Another indexer owns this state file\n')
        if args.rebuild and args.pier:
            import_payload(args.pier, {'action': 'source-error', 'collection': config['collection']})
        rebuild, delay = args.rebuild, args.interval
        while True:
            good = False
            try:
                result = run_once(Rpc(endpoint), config, args.state, rebuild=rebuild,
                                  window=args.window, max_tokens=args.max_tokens)
                payload = result['snapshot']
                rebuild = False
                good = True
            except (ValueError, KeyError, TypeError):
                payload = {'action': 'source-error', 'collection': config['collection']}
                print('Index rejected; last good state preserved and source health marked failed. Check provider, coverage and checkpoint before rebuilding.', flush=True)
            if args.output: atomic_write(args.output, payload)
            if args.pier:
                try:
                    import_payload(args.pier, payload)
                except (RuntimeError, OSError, subprocess.SubprocessError):
                    good = False
                    print('Host import failed; local index is saved and the next poll will retry delivery.', flush=True)
            if good:
                print(f"Verified {len(payload['tokens'])} tokens at block {payload['block']}; cursor and snapshot saved atomically.", flush=True)
            if not args.watch:
                if not good: parser.exit(1)
                return
            delay = args.interval if good else max(args.interval, min(delay * 2, 300))
            time.sleep(delay)



def import_payload(pier, payload):
    from conn import evaluate
    encoded = json.dumps(payload, separators=(',', ':')).replace('\\', '\\\\').replace("'", "\\'")
    evaluate(pier, f"""=/  m  (strand ,vase)
;<  b=bowl:spider  bind:m  get-bowl
;<  ~  bind:m  (poke [our.b %gater] %json !>((need (de:json:html '{encoded}'))))
(pure:m !>(%imported))""")


if __name__ == '__main__':
    main()
