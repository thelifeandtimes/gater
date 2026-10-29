import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import host_import


class Response(io.BytesIO):
    def __init__(self, status, value=b''):
        super().__init__(value)
        self.status = status


class HostImportTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.pier = Path(self.temp.name)
        (self.pier / '.http.ports').write_text('12326 insecure loopback\n8192 insecure public\n')
        self.payload = {'action': 'snapshot', 'tokens': []}
        self.reply = '[0 %avow 0 %noun ' + ' '.join(str(ord(c)) for c in '~test-code') + ' 0]'

    def test_identity_guard_failure_prevents_http_or_credential_use(self):
        with patch.object(host_import, 'evaluate_target', side_effect=RuntimeError('identity mismatch')), \
             patch.object(host_import, 'build_opener') as opener:
            with self.assertRaisesRegex(RuntimeError, 'identity mismatch'):
                host_import.import_snapshot(self.pier, self.payload, live_comet='~sampel-palnet')
        opener.assert_not_called()

    def test_large_snapshot_uses_csrf_headers_and_closes_temporary_session(self):
        self.payload['padding'] = 'x' * 130000
        with patch.object(host_import, 'evaluate_target', return_value=self.reply) as control, \
             patch.object(host_import, 'build_opener') as opener:
            client = opener.return_value
            client.open.side_effect = [Response(303), Response(200, json.dumps({'admin': True, 'ship': '~sampel-palnet'}).encode()), Response(303)]
            host_import.import_snapshot(self.pier, self.payload, live_comet='~sampel-palnet')
        self.assertEqual(control.call_args.kwargs, {'live_comet': '~sampel-palnet', 'live_ship': None})
        self.assertNotIn('padding', control.call_args.args[1])
        requests = [c.args[0] for c in client.open.call_args_list]
        self.assertEqual([r.full_url for r in requests], ['http://127.0.0.1:8192/~/login', 'http://127.0.0.1:8192/gater/config/action', 'http://127.0.0.1:8192/~/logout'])
        self.assertEqual(json.loads(requests[1].data), self.payload)
        self.assertEqual(requests[1].get_header('Origin'), 'http://127.0.0.1:8192')
        self.assertEqual(requests[1].get_header('X-gater'), '1')
        self.assertTrue(any(isinstance(arg, host_import.NoRedirect) for arg in opener.call_args.args))

    def test_rejected_import_logs_out_and_does_not_report_success(self):
        with patch.object(host_import, 'evaluate_target', return_value=self.reply), \
             patch.object(host_import, 'build_opener') as opener:
            opener.return_value.open.side_effect = [Response(303), Response(409), Response(303)]
            with self.assertRaisesRegex(RuntimeError, 'HTTP 409'):
                host_import.import_snapshot(self.pier, self.payload)
            self.assertEqual(opener.return_value.open.call_args.args[0].full_url, 'http://127.0.0.1:8192/~/logout')

    def test_oversize_snapshot_rejected_before_opening_a_session(self):
        with patch.object(host_import, 'evaluate_target') as control:
            with self.assertRaises(ValueError):
                host_import.import_snapshot(self.pier, {'action': 'snapshot', 'padding': 'x' * 2_000_000})
        control.assert_not_called()

    def test_audit_material_is_read_only_and_uses_urbit_decimal_path(self):
        with patch.object(host_import,'evaluate_target',return_value=self.reply), patch.object(host_import,'build_opener') as opener:
            opener.return_value.open.side_effect=[Response(303),Response(200,b'{"logs":[]}'),Response(303)]
            self.assertEqual(host_import.audit_material(self.pier,25421988),{'logs':[]})
            req=opener.return_value.open.call_args_list[1].args[0]
            self.assertEqual(req.full_url,'http://127.0.0.1:8192/~/scry/gater/audit/25.421.988.json')
            self.assertEqual(req.get_method(),'GET')

    def test_audit_path_cannot_be_injected(self):
        with patch.object(host_import,'evaluate_target') as control:
            for height in ['../state',True,-1,0,10**20]:
                with self.assertRaises(ValueError):host_import.audit_material(self.pier,height)
            control.assert_not_called()

    def test_named_ship_receipt_must_match_and_always_logs_out(self):
        for received in ('~dister-dozzod-sarlev', '~nec'):
            with self.subTest(received=received), patch.object(host_import, 'evaluate_target', return_value=self.reply) as control, patch.object(host_import, 'build_opener') as opener:
                opener.return_value.open.side_effect = [Response(303), Response(200, json.dumps({'admin': True, 'ship': received}).encode()), Response(303)]
                if received == '~nec':
                    with self.assertRaisesRegex(RuntimeError, 'Unexpected host identity'):
                        host_import.import_snapshot(self.pier, self.payload, live_ship='~dister-dozzod-sarlev')
                else:
                    host_import.import_snapshot(self.pier, self.payload, live_ship='~dister-dozzod-sarlev')
                self.assertEqual(control.call_args.kwargs, {'live_comet': None, 'live_ship': '~dister-dozzod-sarlev'})
                self.assertEqual(opener.return_value.open.call_args.args[0].full_url, 'http://127.0.0.1:8192/~/logout')
