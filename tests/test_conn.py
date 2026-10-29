import sys
from pathlib import Path
import unittest
from unittest.mock import patch, call
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import conn


class ControlEncodingTests(unittest.TestCase):
    def test_incomplete_frame_never_reaches_socket(self):
        for encoded in (b'', b'\x00\x10\x00\x00\x00short', b'\x01\x01\x00\x00\x00x'):
            with self.subTest(encoded=encoded), patch.object(Path, 'is_socket', return_value=True), \
                 patch.object(conn, '_run_eval', return_value=encoded), patch.object(conn.socket, 'socket') as sock:
                with self.assertRaisesRegex(RuntimeError, 'complete control request frame'):
                    conn._evaluate('/tmp/test', 'mutation')
                sock.assert_not_called()

    def test_encoder_writes_to_a_file_not_a_pipe(self):
        payload = b'x' * 200000
        def encode(*args, **kwargs):
            self.assertEqual(kwargs['stdin'].read(),b'input')
            kwargs['stdout'].write(payload)
        with patch.object(conn.subprocess, 'run', side_effect=encode):
            self.assertEqual(conn._run_eval('-jn', b'input'), payload)

    def test_response_reads_entire_frame_without_half_close(self):
        payload=b'x'*200000
        frame=b'\0'+len(payload).to_bytes(4,'little')+payload
        with patch.object(Path,'is_socket',return_value=True), patch.object(conn,'_run_eval',side_effect=[b'\0\1\0\0\0x',b'[0 %avow 0 %noun %ok]']) as run, patch.object(conn.socket,'socket') as sock:
            client=sock.return_value.__enter__.return_value
            client.recv.side_effect=[frame[:2],frame[2:10000],frame[10000:]]
            self.assertEqual(conn._evaluate('/tmp/test','safe'),'[0 %avow 0 %noun %ok]')
            client.shutdown.assert_not_called()
            self.assertEqual(run.call_args.args,('-cn',frame))

    def test_truncated_response_is_not_decoded(self):
        with patch.object(Path,'is_socket',return_value=True), patch.object(conn,'_run_eval',return_value=b'\0\1\0\0\0x') as run, patch.object(conn.socket,'socket') as sock:
            sock.return_value.__enter__.return_value.recv.side_effect=[b'\0\5\0\0\0x',b'']
            with self.assertRaisesRegex(RuntimeError,'Incomplete control response'):
                conn._evaluate('/tmp/test','safe')
            self.assertEqual(run.call_count,1)


class FakePierGuardTests(unittest.TestCase):
    def test_refusal_never_evaluates_requested_code(self):
        with patch.object(conn, '_evaluate', side_effect=RuntimeError('not fake')) as run:
            with self.assertRaises(RuntimeError): conn.evaluate('/tmp/test', 'mutation', ('dependency',))
        self.assertEqual(run.call_count, 1)
        self.assertIn('%gater-refuses-livenet-pier', run.call_args.args[1])
        self.assertNotIn('mutation', run.call_args.args[1])

    def test_guard_runs_before_each_request(self):
        with patch.object(conn, '_evaluate', side_effect=['fake', 'result', 'fake', 'second']) as run:
            self.assertEqual(conn.evaluate('/tmp/test', 'first', ('dep',)), 'result')
            self.assertEqual(conn.evaluate('/tmp/test', 'next'), 'second')
        self.assertEqual(run.call_args_list[1], call('/tmp/test', 'first', ('dep',)))
        self.assertEqual(run.call_args_list[3], call('/tmp/test', 'next', ()))


class LiveCometGuardTests(unittest.TestCase):
    def test_default_deployment_path_still_checks_fake_flag(self):
        with patch.object(conn, '_evaluate', side_effect=RuntimeError('not fake')) as run:
            with self.assertRaises(RuntimeError): conn.evaluate_target('/tmp/test', 'mutation')
        self.assertEqual(run.call_count, 1)
        self.assertIn('%gater-refuses-livenet-pier', run.call_args.args[1])
        self.assertNotIn('mutation', run.call_args.args[1])

    def test_live_guard_is_in_same_thread_as_operation_and_keeps_dependencies(self):
        with patch.object(conn, '_evaluate', return_value='result') as run:
            self.assertEqual(conn.evaluate_target('/tmp/test', 'mutation', ('dep',), live_comet='~sampel-palnet'), 'result')
        self.assertEqual(run.call_count, 1)
        pier, code, dependencies = run.call_args.args
        self.assertEqual((pier, dependencies), ('/tmp/test', ('dep',)))
        self.assertIn("=('~sampel-palnet' (scot %p our.gater-b))", code)
        self.assertIn('(gte our.gater-b (bex 64))', code)
        self.assertIn('(lth our.gater-b (bex 128))', code)
        self.assertIn('?<  .^(? %j', code)
        self.assertTrue(code.endswith('mutation'))

    def test_ship_name_cannot_inject_hoon(self):
        for ship in ("~nec' ?> &", '~nec\n', '', 'nec', '~' + 'a' * 151, 7):
            with self.subTest(ship=ship), patch.object(conn, '_evaluate') as run:
                with self.assertRaises(ValueError): conn.evaluate_target('/tmp/test', 'mutation', live_comet=ship)
                run.assert_not_called()


class LiveShipGuardTests(unittest.TestCase):
    def test_named_moon_is_checked_in_same_thread_before_operation(self):
        with patch.object(conn, '_evaluate', return_value='result') as run:
            self.assertEqual(conn.evaluate_target('/tmp/moon', 'mutation', ('dep',),
                             live_ship='~dister-dozzod-sarlev'), 'result')
        run.assert_called_once()
        pier, code, deps = run.call_args.args
        self.assertEqual((pier, deps), ('/tmp/moon', ('dep',)))
        self.assertIn("=('~dister-dozzod-sarlev' (scot %p our.gater-b))", code)
        self.assertIn('%gater-live-ship-identity-mismatch', code)
        self.assertIn('%gater-live-ship-refuses-fake', code)
        self.assertNotIn('comet-rank-required', code)
        self.assertLess(code.index('?<  .^(? %j'), code.index('mutation'))

    def test_invalid_or_ambiguous_live_target_never_reaches_control_socket(self):
        for kwargs in ({'live_ship': "~nec' ?> &"}, {'live_ship': '~nec\n'},
                       {'live_ship': 7}, {'live_ship': ''},
                       {'live_ship': '~nec', 'live_comet': '~nec'}):
            with self.subTest(kwargs=kwargs), patch.object(conn, '_evaluate') as run:
                with self.assertRaises(ValueError):
                    conn.evaluate_target('/tmp/test', 'mutation', **kwargs)
                run.assert_not_called()
