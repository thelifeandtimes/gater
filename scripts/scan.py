#!/usr/bin/env python3
"""Legacy Transfer-only diagnostic reader; use index.py for agent imports.

This first reader deliberately uses full history on each run. A wrong start
block, silent provider truncation, or constructor-only minting can make a log
index incomplete: inspect the contract before treating it as authoritative.
"""
import argparse
from email.utils import parsedate_to_datetime
from http.client import HTTPException
import json
import math
import os
from pathlib import Path
import re
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import Request, urlopen

TRANSFER = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'
ZERO = '0x' + '0' * 40


def address(value):
    if not isinstance(value, str) or not re.fullmatch(r'0x[0-9a-fA-F]{40}', value):
        raise ValueError('Expected a 20-byte Ethereum address')
    return value.lower()


def quantity(value):
    if not isinstance(value, str) or not re.fullmatch(r'0x[0-9a-fA-F]+', value):
        raise ValueError('Expected a hexadecimal RPC quantity')
    return int(value, 16)


def hash32(value):
    if not isinstance(value, str) or not re.fullmatch(r'0x[0-9a-fA-F]{64}', value):
        raise ValueError('Expected a 32-byte hash or ABI word')
    return value.lower()


class Rpc:
    def __init__(self, url, attempts=3, sleep=time.sleep, min_interval=0, clock=time.monotonic):
        if not isinstance(url, str) or not url.startswith('https://'):
            raise ValueError('Use an HTTPS RPC endpoint')
        # Validate before urllib can include a credential-bearing URL in errors.
        if any(ord(char) <= 32 or ord(char) >= 127 for char in url):
            raise ValueError('RPC endpoint contains whitespace, control or non-ASCII characters')
        try:
            parsed = urlsplit(url)
            if not parsed.hostname:
                raise ValueError()
            parsed.port
        except ValueError:
            raise ValueError('Invalid RPC endpoint') from None
        if type(attempts) is not int or attempts < 1:
            raise ValueError('RPC attempts must be positive')
        if not math.isfinite(min_interval) or min_interval < 0:
            raise ValueError('RPC request interval must be finite and nonnegative')
        self.url = url
        self.serial = 0
        self.attempts = attempts
        self.sleep = sleep
        self.min_interval, self.clock, self.next_request = min_interval, clock, 0

    def __call__(self, method, params):
        for attempt in range(self.attempts):
            delay = self.next_request - self.clock()
            if delay > 0:
                self.sleep(delay)
            self.next_request = self.clock() + self.min_interval
            try:
                return self.request(method, params)
            except RpcError as error:
                if not error.retryable or attempt + 1 == self.attempts:
                    raise
                self.sleep(max(min(2 ** attempt, 30), error.retry_after))

    def request(self, method, params):
        self.serial += 1
        body = json.dumps({'jsonrpc': '2.0', 'id': self.serial, 'method': method, 'params': params}).encode()
        try:
            with urlopen(Request(self.url, body, {'Content-Type': 'application/json'}), timeout=30) as response:
                raw = response.read(32 * 1024 * 1024 + 1)
                if len(raw) > 32 * 1024 * 1024:
                    raise ValueError('RPC response too large; reduce the block range')
            result = json.loads(raw)
        except HTTPError as error:
            retry_after = 0
            value = (error.headers or {}).get('Retry-After', '')
            try:
                retry_after = float(value) if value.isdigit() else parsedate_to_datetime(value).timestamp() - time.time()
            except (ValueError, TypeError, OverflowError):
                pass
            error.close()
            raise RpcError(f'RPC {method} HTTP {error.code}',
                           retryable=error.code in (429, 502, 503, 504),
                           range_limit=error.code == 413,
                           retry_after=max(0, min(60, retry_after))) from None
        except (URLError, OSError):
            raise RpcError(f'RPC {method} transport failure', retryable=True) from None
        except json.JSONDecodeError:
            raise RpcError(f'RPC {method} invalid JSON') from None
        except (HTTPException, ValueError):
            raise RpcError(f'RPC {method} invalid request or response') from None
        if not isinstance(result, dict):
            raise RpcError(f'RPC {method} invalid envelope')
        if 'error' in result:
            # Provider URLs often contain API keys. Never echo the URL or body.
            code = result['error'].get('code') if isinstance(result['error'], dict) else None
            message = str(result['error'].get('message', '')).lower() if isinstance(result['error'], dict) else ''
            limited = code == 429 or (code == -32005 and any(term in message for term in ('rate limit', 'throughput', 'credits per second')))
            raise RpcError(f'RPC {method} rejected request', retryable=limited,
                           range_limit=not limited and code in (-32005, -32016))
        if result.get('jsonrpc') != '2.0' or result.get('id') != self.serial or 'result' not in result:
            raise RpcError(f'RPC {method} returned an invalid response')
        return result['result']


class RpcError(ValueError):
    def __init__(self, message, retryable=False, range_limit=False, retry_after=0):
        super().__init__(message)
        self.retryable, self.range_limit = retryable, range_limit
        self.retry_after = retry_after


def apply_logs(tokens, logs, contract, first, last, seen):
    if not isinstance(logs, list):
        raise ValueError('eth_getLogs did not return a list')
    rows = sorted(logs, key=lambda row: (quantity(row['blockNumber']), quantity(row['logIndex'])))
    for row in rows:
        block = quantity(row['blockNumber'])
        position = (block, quantity(row['logIndex']))
        if row.get('removed') is not False or not first <= block <= last:
            raise ValueError('Removed or out-of-range log in finalized history')
        if address(row['address']) != contract or position in seen:
            raise ValueError('Unexpected contract or duplicate log position')
        hash32(row['blockHash'])
        hash32(row['transactionHash'])
        topics = row['topics']
        if len(topics) != 4 or topics[0].lower() != TRANSFER:
            raise ValueError('Expected an ERC-721 Transfer with three indexed arguments')
        previous, target, token = (quantity(hash32(word)) for word in topics[1:])
        if previous >= 2**160 or target >= 2**160:
            raise ValueError('Malformed indexed address')
        key = str(token)
        before = f'0x{previous:040x}'
        after = f'0x{target:040x}'
        if (before != ZERO and tokens.get(key) != before) or (before == ZERO and key in tokens):
            raise ValueError('Incomplete or inconsistent history; check the deployment block and mint events')
        seen.add(position)
        if after == ZERO:
            tokens.pop(key, None)
        else:
            tokens[key] = after


def scan(rpc, chain, contract, first, window=2000, now=None):
    contract = address(contract)
    if chain not in (1, 8453) or quantity(rpc('eth_chainId', [])) != chain:
        raise ValueError('RPC chain does not match the configured Ethereum or Base chain')
    if first < 0 or window < 1 or contract == ZERO:
        raise ValueError('Invalid start block, range, or contract')
    final = rpc('eth_getBlockByNumber', ['finalized', False])
    if not final:
        raise ValueError('Provider has no finalized checkpoint; refusing to fall back to latest')
    height, block_hash = quantity(final['number']), hash32(final['hash'])
    timestamp = quantity(final['timestamp'])
    now = int(time.time()) if now is None else now
    if not 0 <= now - timestamp <= 3600:
        raise ValueError('Finalized checkpoint is stale or in the future')
    if first > height:
        raise ValueError('Start block is beyond finalized history')
    code = rpc('eth_getCode', [contract, hex(height)])
    if not isinstance(code, str) or code in ('0x', '0x0'):
        raise ValueError('No contract code at the finalized checkpoint')
    supports721 = rpc('eth_call', [{'to': contract, 'data': '0x01ffc9a780ac58cd' + '0' * 56}, hex(height)])
    if quantity(supports721) != 1:
        raise ValueError('Collection does not report ERC-721 support; an adapter is required')
    tokens, seen = {}, set()
    for lower in range(first, height + 1, window):
        upper = min(lower + window - 1, height)
        logs = rpc('eth_getLogs', [{'address': contract, 'topics': [TRANSFER], 'fromBlock': hex(lower), 'toBlock': hex(upper)}])
        apply_logs(tokens, logs, contract, lower, upper, seen)
    # Verify every currently held token against ownerOf at the same checkpoint.
    for token, owner in tokens.items():
        owner_word = rpc('eth_call', [{'to': contract, 'data': '0x6352211e' + f'{int(token):064x}'}, hex(height)])
        if quantity(hash32(owner_word)) != int(owner, 16):
            raise ValueError('ownerOf disagrees with Transfer history')
    final_again = rpc('eth_getBlockByNumber', [hex(height), False])
    if not final_again or hash32(final_again['hash']) != block_hash:
        raise ValueError('Finalized block changed while scanning; discard this run')
    # Timestamp is the start of collection so a long scan never looks newer.
    return {'action': 'snapshot', 'chain': str(chain), 'contract': contract,
            'observedAt': str(now), 'block': str(height), 'blockHash': block_hash,
            'tokens': [{'id': token, 'owner': owner} for token, owner in sorted(tokens.items(), key=lambda item: int(item[0]))]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rpc-env', default='GATER_RPC_URL')
    parser.add_argument('--chain', type=int, choices=[1, 8453], required=True)
    parser.add_argument('--contract', required=True)
    parser.add_argument('--collection', required=True)
    parser.add_argument('--from-block', type=int, required=True, help='Verified deployment block; 0 scans all history')
    parser.add_argument('--window', type=int, default=2000)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    print('Legacy diagnostic output only: the agent requires index.py coverage and generations for RPC imports.')
    if not re.fullmatch('[a-z][a-z0-9-]*', args.collection):
        parser.error('Invalid collection ID')
    endpoint = os.environ.get(args.rpc_env)
    if not endpoint:
        parser.error(f'Set {args.rpc_env} privately; do not pass API keys on the command line')
    try:
        result = scan(Rpc(endpoint), args.chain, args.contract, args.from_block, args.window)
    except (ValueError, KeyError, TypeError) as error:
        parser.exit(1, f'Scan rejected: {error}\n')
    result['collection'] = args.collection
    args.output.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.output.with_suffix(args.output.suffix + '.tmp')
    temporary.write_text(json.dumps(result, indent=2) + '\n')
    temporary.replace(args.output)
    print(f"Wrote {len(result['tokens'])} held tokens at finalized block {result['block']} to {args.output}")


if __name__ == '__main__':
    main()
