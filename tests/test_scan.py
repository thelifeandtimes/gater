import copy
import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from scan import scan, apply_logs, TRANSFER, ZERO

CONTRACT = '0x' + 'a' * 40
ALICE = '0x' + '1' * 40
BOB = '0x' + '2' * 40
HASH = '0x' + '3' * 64
OTHER_HASH = '0x' + '4' * 64


def word(value):
    return f'0x{value:064x}'


def transfer(block, token, before=ZERO, after=ALICE, index=0):
    return {'blockNumber': hex(block), 'logIndex': hex(index), 'removed': False,
            'address': CONTRACT, 'blockHash': HASH, 'transactionHash': OTHER_HASH,
            'topics': [TRANSFER, word(int(before, 16)), word(int(after, 16)), word(token)]}


class Provider:
    def __init__(self, logs=None):
        self.logs = logs if logs is not None else [transfer(1, 7)]
        self.chain = 8453
        self.block = {'number': '0x5', 'hash': HASH, 'timestamp': hex(999)}
        self.reorg = False
        self.owner = ALICE
        self.code = '0x6000'
        self.supports = True
        self.calls = []

    def __call__(self, method, params):
        self.calls.append((method, params))
        if method == 'eth_chainId': return hex(self.chain)
        if method == 'eth_getBlockByNumber':
            result = copy.deepcopy(self.block)
            if self.reorg and params[0] != 'finalized': result['hash'] = OTHER_HASH
            return result
        if method == 'eth_getCode': return self.code
        if method == 'eth_call':
            if params[0]['data'].startswith('0x01ffc9a7'): return word(int(self.supports))
            return word(int(self.owner, 16))
        if method == 'eth_getLogs':
            low, high = int(params[0]['fromBlock'], 16), int(params[0]['toBlock'], 16)
            return [row for row in self.logs if low <= int(row['blockNumber'], 16) <= high]
        raise AssertionError(method)


class ScanTests(unittest.TestCase):
    def scan(self, provider): return scan(provider, 8453, CONTRACT, 0, window=2, now=1000)

    def test_finalized_pagination_and_owner_checks(self):
        rpc = Provider()
        result = self.scan(rpc)
        self.assertEqual(result['tokens'], [{'id': '7', 'owner': ALICE}])
        self.assertEqual(result['blockHash'], HASH)
        ranges = [p[0] for method, p in rpc.calls if method == 'eth_getLogs']
        self.assertEqual([(p['fromBlock'], p['toBlock']) for p in ranges], [('0x0','0x1'),('0x2','0x3'),('0x4','0x5')])
        self.assertFalse(any('latest' in p for _, p in rpc.calls))

    def test_chain_mismatch(self):
        rpc = Provider(); rpc.chain = 1
        with self.assertRaisesRegex(ValueError, 'chain'): self.scan(rpc)

    def test_finality_required(self):
        rpc = Provider(); rpc.block = None
        with self.assertRaisesRegex(ValueError, 'finalized'): self.scan(rpc)

    def test_stale_checkpoint(self):
        rpc = Provider(); rpc.block['timestamp'] = '0x0'
        with self.assertRaisesRegex(ValueError, 'stale'): scan(rpc, 8453, CONTRACT, 0, now=4000)

    def test_no_contract(self):
        rpc = Provider(); rpc.code = '0x'
        with self.assertRaisesRegex(ValueError, 'code'): self.scan(rpc)

    def test_unsupported_standard(self):
        rpc = Provider(); rpc.supports = False
        with self.assertRaisesRegex(ValueError, 'ERC-721'): self.scan(rpc)

    def test_reorg_discards_snapshot(self):
        rpc = Provider(); rpc.reorg = True
        with self.assertRaisesRegex(ValueError, 'changed'): self.scan(rpc)

    def test_owner_mismatch(self):
        rpc = Provider(); rpc.owner = BOB
        with self.assertRaisesRegex(ValueError, 'ownerOf'): self.scan(rpc)

    def test_transfer_and_burn(self):
        rpc = Provider([transfer(1, 7), transfer(2, 7, ALICE, BOB), transfer(3, 7, BOB, ZERO)])
        self.assertEqual(self.scan(rpc)['tokens'], [])

    def test_zero_and_uint256_token_ids(self):
        rpc = Provider([transfer(1, 0), transfer(2, 2**256-1)])
        self.assertEqual([t['id'] for t in self.scan(rpc)['tokens']], ['0', str(2**256-1)])

    def test_duplicate_log(self):
        rpc = Provider([transfer(1, 7), transfer(1, 7)])
        with self.assertRaisesRegex(ValueError, 'duplicate'): self.scan(rpc)

    def test_missing_mint(self):
        rpc = Provider([transfer(2, 7, ALICE, BOB)])
        with self.assertRaisesRegex(ValueError, 'Incomplete'): self.scan(rpc)

    def test_removed_log(self):
        rpc = Provider(); rpc.logs[0]['removed'] = True
        with self.assertRaisesRegex(ValueError, 'Removed'): self.scan(rpc)

    def test_wrong_contract(self):
        rpc = Provider(); rpc.logs[0]['address'] = BOB
        with self.assertRaisesRegex(ValueError, 'contract'): self.scan(rpc)

    def test_erc20_shaped_event_rejected(self):
        rpc = Provider(); rpc.logs[0]['topics'].pop()
        with self.assertRaisesRegex(ValueError, 'ERC-721'): self.scan(rpc)

    def test_out_of_range_log(self):
        with self.assertRaisesRegex(ValueError, 'out-of-range'):
            apply_logs({}, [transfer(3, 7)], CONTRACT, 0, 2, set())


if __name__ == '__main__': unittest.main()
