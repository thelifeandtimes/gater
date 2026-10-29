import copy
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
import audit_azimuth as audit

H=lambda n:'0x'+f'{n:064x}'
class AuditTests(unittest.TestCase):
    def setUp(self):
        self.anchor={'height':10,'hash':H(10),'digest':H(123)}
        self.row={'blockNumber':'0xc','transactionIndex':'0x0','logIndex':'0x0','blockHash':H(12),'transactionHash':H(99),'address':audit.ROLLUP,'data':'0x','topics':[H(1)],'removed':False}
        native={**self.row,'blockNumber':'12','transactionIndex':'0','logIndex':'0','input':'0x1234'}
        self.material={'anchorHeight':'10','anchorHash':H(10),'anchorDigest':H(123),'height':'15','logs':[native]}
    def rpc(self,method,params):
        if method=='eth_chainId':return '0x1'
        if method=='eth_getBlockByNumber':
            n=15 if params[0]=='finalized' else int(params[0],16)
            return {'number':hex(n),'hash':H(n),'timestamp':'0x3e8'}
        if method=='eth_getLogs':return [self.row]
        if method=='eth_getTransactionByHash':return {'hash':H(99),'blockHash':H(12),'blockNumber':'0xc','to':audit.ROLLUP,'input':'0x1234'}
        raise AssertionError(method)
    def test_large_calldata_remains_json_serializable(self):
        import json
        calldata='0x'+'12'*3000
        self.material['logs'][0]['input']=calldata
        def rpc(method,params):
            result=self.rpc(method,params)
            if method=='eth_getTransactionByHash': result['input']=calldata
            return result
        result=audit.verify(rpc,self.material,self.anchor,now=1010)
        self.assertEqual(json.loads(json.dumps(result))['inputs'][H(99)],calldata)

    def test_complete_suffix_and_rollup_input(self):
        result=audit.verify(self.rpc,self.material,self.anchor,now=1010)
        self.assertEqual(result['checkpoint']['number'],15);self.assertEqual(result['inputs'][H(99)],'0x1234')
    def test_unrecognized_bootstrap(self):
        self.material['anchorDigest']=H(456)
        with self.assertRaisesRegex(ValueError,'bootstrap'):audit.verify(self.rpc,self.material,self.anchor,now=1010)
    def test_missing_native_log(self):
        self.material['logs']=[]
        with self.assertRaisesRegex(ValueError,'incomplete'):audit.verify(self.rpc,self.material,self.anchor,now=1010)
    def test_unfinalized_target(self):
        self.material['height']='16'
        with self.assertRaisesRegex(ValueError,'not finalized'):audit.verify(self.rpc,self.material,self.anchor,now=1010)
    def test_mismatched_rollup_input(self):
        self.material['logs'][0]['input']='0x5678'
        with self.assertRaisesRegex(ValueError,'calldata'):audit.verify(self.rpc,self.material,self.anchor,now=1010)
    def test_duplicate_log(self):
        self.material['logs']*=2
        with self.assertRaisesRegex(ValueError,'duplicated'):audit.verify(self.rpc,self.material,self.anchor,now=1010)
    def test_stale_finality(self):
        with self.assertRaisesRegex(ValueError,'stale'):audit.verify(self.rpc,self.material,self.anchor,now=10000)
    def test_cached_suffix_must_still_match_native(self):
        previous=audit.verify(self.rpc,self.material,self.anchor,now=1010)
        self.material['logs'][0]['data']='0x1234'
        with self.assertRaisesRegex(ValueError,'incomplete'):audit.verify(self.rpc,self.material,self.anchor,previous,now=1010)
    def test_reorg_of_cached_checkpoint(self):
        previous=audit.verify(self.rpc,self.material,self.anchor,now=1010);previous['checkpoint']['hash']=H(999)
        with self.assertRaisesRegex(ValueError,'diverged'):audit.verify(self.rpc,self.material,self.anchor,previous,now=1010)

    def test_sync_preserves_the_selected_target_for_read_and_import(self):
        for live_ship in (None, '~dister-dozzod-sarlev'):
            ship = live_ship or '~sampel-palnet'
            deployment = {'pier': '/tmp/test-pier', 'ship': ship}
            target = {'live_ship': live_ship} if live_ship else {'live_comet': ship}
            with self.subTest(live_ship=live_ship), tempfile.TemporaryDirectory() as directory:
                anchor = Path(directory)/'anchor.json'; anchor.write_text(json.dumps(self.anchor))
                cache = Path(directory)/'cache.json'
                material = {**self.material, 'materialDigest': H(1234)}
                verified = {'checkpoint': {'number': 15, 'hash': H(15)}}
                with patch.object(audit, 'audit_material', return_value=material) as read, patch.object(audit, 'host_action') as write, patch.object(audit, 'verify', return_value=verified):
                    result = audit.sync(deployment, self.rpc, anchor, cache, live_ship=live_ship)
                self.assertTrue(result['verified'])
                self.assertEqual(read.call_args.kwargs, target)
                self.assertEqual(write.call_args.kwargs, target)
                self.assertEqual(write.call_args.args[0], deployment['pier'])
                self.assertEqual(json.loads(cache.read_text()), verified)

    def test_mismatched_explicit_ship_is_rejected_before_rpc_or_files(self):
        with patch.object(audit, 'header') as rpc:
            with self.assertRaisesRegex(ValueError, 'identity does not match'):
                audit.sync({'pier': '/tmp/moon', 'ship': '~nec'}, None, '/missing', '/missing', live_ship='~dister-dozzod-sarlev')
            rpc.assert_not_called()

    def test_pier_and_ship_are_required_together_before_access(self):
        for options in (['--pier', '/missing'], ['--live-ship', '~dister-dozzod-sarlev']):
            with self.subTest(options=options), patch.object(sys, 'argv', ['audit_azimuth.py', *options]), patch.object(audit, 'AuditRpc') as rpc, patch('sys.stderr', new_callable=io.StringIO):
                with self.assertRaises(SystemExit) as error: audit.main()
                self.assertEqual(error.exception.code, 2)
                rpc.assert_not_called()

if __name__=='__main__':unittest.main()
