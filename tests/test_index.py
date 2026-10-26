import copy
import json
import io
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
from urllib.error import HTTPError
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from index import update, run_once, replay, CONSECUTIVE, atomic_write, main
from scan import Rpc, RpcError, TRANSFER, ZERO

CONTRACT, ALICE, BOB = ('0x' + c * 40 for c in 'a12')
CONFIG = {'chain': 8453, 'contract': CONTRACT, 'collection': 'demo', 'discovery': 'events-supply',
          'deploymentBlock': 1, 'reviewedSource': 'fixture: standard ERC-721 Transfer and totalSupply'}


def word(n): return f'0x{n:064x}'
def block_hash(n): return word(n + 100)

def event(block, token=7, before=ZERO, after=ALICE, index=0):
    return {'blockNumber': hex(block), 'logIndex': hex(index), 'blockHash': block_hash(block),
            'transactionHash': word(99), 'address': CONTRACT, 'removed': False, 'data': '0x',
            'topics': [TRANSFER, word(int(before, 16)), word(int(after, 16)), word(token)]}


class Provider:
    def __init__(self):
        self.height = 5
        self.logs = [event(1)]
        self.owners = {'7': ALICE}
        self.calls = []
        self.hash_override = {}
        self.range_limit = None
        self.fail = False
        self.code = '0x6000'
        self.supply = None
        self.enumeration = True
        self.duplicate = False

    def __call__(self, method, params):
        self.calls.append((method, copy.deepcopy(params)))
        if self.fail: raise RpcError('provider offline')
        if method == 'eth_chainId': return hex(8453)
        if method == 'eth_getBlockByNumber':
            n = self.height if params[0] == 'finalized' else int(params[0], 16)
            return {'number': hex(n), 'hash': self.hash_override.get(n, block_hash(n)), 'timestamp': hex(999)}
        if method == 'eth_getCode': return self.code if int(params[1], 16) >= 1 else '0x'
        if method == 'eth_getLogs':
            lo, hi = int(params[0]['fromBlock'], 16), int(params[0]['toBlock'], 16)
            if self.range_limit and hi - lo + 1 > self.range_limit: raise RpcError('range limit', range_limit=True)
            return [copy.deepcopy(row) for row in self.logs if lo <= int(row['blockNumber'], 16) <= hi]
        if method == 'eth_call':
            data = params[0]['data']
            if data.startswith('0x01ffc9a7'):
                return word(int(self.enumeration)) if data[10:18] == '780e9d63' else word(1)
            if data == '0x18160ddd': return word(len(self.owners) if self.supply is None else self.supply)
            if data.startswith('0x4f6ccce7'):
                i = 0 if self.duplicate else int(data[10:], 16)
                return word(int(list(self.owners)[i]))
            if data.startswith('0x6352211e'): return word(int(self.owners[str(int(data[10:], 16))], 16))
        raise AssertionError(method)


class IndexTests(unittest.TestCase):
    def read(self, rpc, previous=None, config=CONFIG, **kw):
        return update(rpc, config, previous, now=1000, **kw)

    def test_bootstrap_coverage_and_generation(self):
        result = self.read(Provider())
        self.assertEqual(result['snapshot']['coverage']['supply'], '1')
        self.assertGreater(int(result['tokens']['7']['generation']), 0)
        self.assertTrue(result['health']['ok'])

    def test_restart_only_requests_new_history(self):
        rpc = Provider(); first = self.read(rpc); rpc.calls.clear(); rpc.height = 8
        result = self.read(rpc, json.loads(json.dumps(first)))
        ranges = [p[0] for method, p in rpc.calls if method == 'eth_getLogs']
        self.assertEqual([(p['fromBlock'], p['toBlock']) for p in ranges], [('0x6', '0x8')])
        self.assertEqual(result['epoch'], first['epoch'])
        self.assertEqual(result['tokens'], first['tokens'])

    def test_transfer_away_and_back_changes_generation(self):
        rpc = Provider(); first = self.read(rpc); rpc.height = 8
        rpc.logs += [event(6, before=ALICE, after=BOB), event(7, before=BOB, after=ALICE)]
        result = self.read(rpc, first)
        self.assertEqual(result['tokens']['7']['owner'], ALICE)
        self.assertNotEqual(result['tokens']['7']['generation'], first['tokens']['7']['generation'])
        self.assertEqual(first['checkpoint']['number'], 5)

    def test_self_transfer_keeps_generation(self):
        rpc = Provider(); first = self.read(rpc); rpc.height = 8
        rpc.logs += [event(6, before=ALICE, after=ALICE)]
        self.assertEqual(self.read(rpc, first)['tokens'], first['tokens'])

    def test_burn_and_mint(self):
        rpc = Provider(); first = self.read(rpc); rpc.height = 8
        rpc.logs += [event(6, before=ALICE, after=ZERO), event(7, after=BOB)]
        rpc.owners['7'] = BOB
        result = self.read(rpc, first)
        self.assertEqual(result['tokens']['7']['owner'], BOB)

    def test_erc2309_constructor_range(self):
        rpc = Provider(); row = event(1)
        row['topics'] = [CONSECUTIVE, word(10), word(0), word(int(ALICE, 16))]
        row['data'] = word(12); rpc.logs = [row]; rpc.owners = {str(i): ALICE for i in range(10, 13)}
        self.assertEqual(len(self.read(rpc)['tokens']), 3)

    def test_erc2309_bound(self):
        row = event(1); row['topics'] = [CONSECUTIVE, word(0), word(0), word(int(ALICE,16))]; row['data'] = word(2**256-1)
        with self.assertRaisesRegex(ValueError, 'range'):
            replay({}, [row], CONTRACT, 0, 3, 1000)

    def test_constructor_mints_without_logs_rejected_by_supply(self):
        rpc = Provider(); rpc.logs = []
        with self.assertRaisesRegex(ValueError, 'coverage'): self.read(rpc)

    def test_enumeration_supports_constructor_mints_and_sparse_ids(self):
        rpc = Provider(); rpc.logs = []; rpc.owners = {'0': ALICE, str(2**256-1): BOB}
        config = dict(CONFIG, discovery='enumerable')
        result = self.read(rpc, config=config)
        self.assertEqual(len(result['tokens']), 2)
        self.assertFalse(any(m == 'eth_getLogs' for m, _ in rpc.calls))

    def test_duplicate_enumeration_rejected(self):
        rpc = Provider(); rpc.owners['8'] = ALICE; rpc.duplicate = True
        with self.assertRaisesRegex(ValueError, 'Duplicate'): self.read(rpc, config=dict(CONFIG, discovery='enumerable'))

    def test_unsupported_enumeration_rejected(self):
        rpc = Provider(); rpc.enumeration = False
        with self.assertRaisesRegex(ValueError, 'enumeration'): self.read(rpc, config=dict(CONFIG, discovery='enumerable'))

    def test_wrong_deployment_rejected(self):
        with self.assertRaisesRegex(ValueError, 'already existed'): self.read(Provider(), config=dict(CONFIG, deploymentBlock=2))

    def test_missing_source_review_rejected(self):
        with self.assertRaisesRegex(ValueError, 'reviewed'): self.read(Provider(), config=dict(CONFIG, reviewedSource=''))

    def test_provider_range_limits_shrink_without_skipping(self):
        rpc = Provider(); rpc.range_limit = 2
        result = self.read(rpc, window=8)
        self.assertEqual(result['checkpoint']['number'], 5)
        ranges = [p[0] for m,p in rpc.calls if m == 'eth_getLogs']
        self.assertEqual(ranges[-1]['toBlock'], '0x5')
        self.assertEqual(len(result['tokens']), 1)

    def test_cursor_divergence_refuses_incremental_use(self):
        rpc = Provider(); first = self.read(rpc); rpc.height = 8; rpc.hash_override[5] = word(888)
        with self.assertRaisesRegex(ValueError, 'divergence'): self.read(rpc, first)

    def test_noncanonical_log_rejected(self):
        rpc = Provider(); rpc.logs[0]['blockHash'] = word(999)
        with self.assertRaisesRegex(ValueError, 'canonical'): self.read(rpc)

    def test_wrong_block_number_rejected(self):
        rpc = Provider()
        def wrong(method, params):
            value = rpc(method, params)
            if method == 'eth_getBlockByNumber' and params[0] != 'finalized': value['number'] = '0x999'
            return value
        with self.assertRaisesRegex(ValueError, 'wrong block'): self.read(wrong)

    def test_code_change_requires_review(self):
        rpc = Provider(); first = self.read(rpc); rpc.code = '0x6001'
        with self.assertRaisesRegex(ValueError, 'bytecode changed'): self.read(rpc, first)

    def test_failed_run_preserves_cursor_and_snapshot_and_can_recover(self):
        rpc = Provider()
        with tempfile.TemporaryDirectory() as d:
            path = Path(d)/'state.json'
            first = run_once(rpc, CONFIG, path, now=1000)
            rpc.fail = True
            with self.assertRaises(RpcError): run_once(rpc, CONFIG, path, now=1000)
            failed = json.loads(path.read_text())
            self.assertEqual(failed['snapshot'], first['snapshot'])
            self.assertEqual(failed['checkpoint'], first['checkpoint'])
            self.assertFalse(failed['health']['ok'])
            rpc.fail = False; rpc.height = 8
            self.assertTrue(run_once(rpc, CONFIG, path, now=1000)['health']['ok'])

    def test_first_run_failure_is_recoverable(self):
        rpc = Provider(); rpc.fail = True
        with tempfile.TemporaryDirectory() as d:
            path = Path(d)/'state.json'
            with self.assertRaises(RpcError): run_once(rpc, CONFIG, path, now=1000)
            rpc.fail = False
            self.assertEqual(len(run_once(rpc, CONFIG, path, now=1000)['tokens']), 1)

    def test_explicit_rebuild_changes_epoch(self):
        rpc = Provider()
        with tempfile.TemporaryDirectory() as d:
            path = Path(d)/'state.json'; first = run_once(rpc, CONFIG, path, now=1000)
            second = run_once(rpc, CONFIG, path, now=1000, rebuild=True)
            self.assertNotEqual(first['epoch'], second['epoch'])

    def test_atomic_replace_failure_preserves_old_file(self):
        with tempfile.TemporaryDirectory() as d:
            path = Path(d)/'state.json'; atomic_write(path, {'old': True})
            with patch('index.os.replace', side_effect=OSError('disk failure')):
                with self.assertRaises(OSError): atomic_write(path, {'new': True})
            self.assertEqual(json.loads(path.read_text()), {'old': True})
            self.assertEqual(list(Path(d).iterdir()), [path])

    def test_rpc_rate_limit_retries_without_leaking_url(self):
        waits = []; rpc = Rpc('https://provider.example/private-key', sleep=waits.append)
        errors = [RpcError('rate limited', retryable=True), RpcError('rate limited', retryable=True), '0x2105']
        with patch.object(rpc, 'request', side_effect=errors): self.assertEqual(rpc('eth_chainId', []), '0x2105')
        self.assertEqual(waits, [1, 2])
        with patch('scan.urlopen', side_effect=HTTPError(rpc.url, 403, 'private-key', {}, None)):
            with self.assertRaises(RpcError) as ctx: rpc('eth_chainId', [])
        self.assertNotIn('private-key', str(ctx.exception))

    def test_rpc_connection_reset_retries_and_is_redacted(self):
        waits = []; rpc = Rpc('https://provider.example/private-key', sleep=waits.append)
        with patch('scan.urlopen', side_effect=ConnectionResetError('private-key')):
            with self.assertRaises(RpcError) as ctx: rpc('eth_chainId', [])
        self.assertEqual(waits, [1, 2])
        self.assertNotIn('private-key', str(ctx.exception))

    def test_watch_import_failure_then_provider_failure_then_recovery(self):
        with tempfile.TemporaryDirectory() as d:
            config, state, output = (Path(d)/name for name in ('config.json','state.json','out.json'))
            config.write_text(json.dumps(CONFIG))
            result = self.read(Provider())
            argv = ['index.py','--config',str(config),'--state',str(state),'--output',str(output),
                    '--pier','/tmp/fake','--watch','--interval','60']
            with patch.object(sys, 'argv', argv), patch.dict(os.environ, {'GATER_RPC_URL':'https://provider.example/key'}), \
                 patch('index.run_once', side_effect=[result, RpcError('offline'), result]), \
                 patch('index.import_payload', side_effect=[RuntimeError('host offline'), None, None]) as imports, \
                 patch('index.time.sleep', side_effect=[None, None, KeyboardInterrupt]) as waits, \
                 patch('sys.stdout', new_callable=io.StringIO):
                with self.assertRaises(KeyboardInterrupt): main()
            self.assertEqual([c.args[1]['action'] for c in imports.call_args_list], ['snapshot','source-error','snapshot'])
            self.assertEqual([c.args[0] for c in waits.call_args_list], [120,240,60])
            self.assertEqual(json.loads(output.read_text()), result['snapshot'])

    def test_failed_cli_replaces_export_with_failure_signal(self):
        with tempfile.TemporaryDirectory() as d:
            config, state, output = (Path(d)/name for name in ('config.json','state.json','out.json'))
            config.write_text(json.dumps(CONFIG)); output.write_text('{"action":"snapshot"}')
            argv = ['index.py','--config',str(config),'--state',str(state),'--output',str(output)]
            with patch.object(sys, 'argv', argv), patch.dict(os.environ, {'GATER_RPC_URL':'https://provider.example/key'}), \
                 patch('index.run_once', side_effect=RpcError('offline')), patch('sys.stdout', new_callable=io.StringIO):
                with self.assertRaises(SystemExit) as ctx: main()
            self.assertEqual(ctx.exception.code, 1)
            self.assertEqual(json.loads(output.read_text()), {'action':'source-error','collection':'demo'})


if __name__ == '__main__': unittest.main()
