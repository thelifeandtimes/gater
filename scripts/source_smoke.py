#!/usr/bin/env python3
"""Test source lifecycle on the local fake host, restoring the fixture afterward."""
import argparse
import json
from pathlib import Path
import time
from urllib.parse import urlsplit
from eauth_smoke import client, local_login, request
from index import import_payload
from conn import evaluate


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('pier'); p.add_argument('--url', default='http://127.0.0.1:8190')
    a = p.parse_args(); url = a.url.rstrip('/')
    if urlsplit(url).hostname not in ('127.0.0.1', 'localhost', '::1'): p.error('Use a loopback fake ship')
    browser = client(); local_login(browser, a.pier, url)
    def state():
        status, body, _ = request(browser, url + '/gater/config/state')
        assert status == 200
        return json.loads(body)
    def action(body):
        status, data, _ = request(browser, url + '/gater/config/action', body)
        assert status == 200, data
        return json.loads(data)
    before = state()
    assert before['fixtures'] and not before['azimuthAuto'], 'Use the documented ownership fixtures'
    demo = next(c for c in before['collections'] if c['id'] == 'demo')
    original = next((t['id'] for t in demo['tokens'] if t['ship'] == before['ship']), None)
    root = Path(__file__).resolve().parents[1]
    settings = {'action': 'settings', 'baseUrl': before['baseUrl'], 'azimuthAuto': True}
    try:
        action(settings)
        for _ in range(20):
            if state()['azimuthStatus'] == 'observed': break
            time.sleep(.1)
        assert state()['azimuthStatus'] == 'observed', 'Native initial snapshot was not received'
        # Force the observed-state reconciliation path immediately. A snapshot
        # alone does not exercise the periodic /own/noun Gall scry.
        action(settings)
        # The unconfigured fake ship has an empty native ownership index.
        assert not next(c for c in state()['collections'] if c['id'] == 'demo')['tokens']
        for op in ('suspend', 'revive'):
            evaluate(a.pier, f'''=/  m  (strand ,vase)
;<  b=bowl:spider  bind:m  get-bowl
;<  ~  bind:m  (poke [our.b %hood] %kiln-{op} !>(%gater))
(pure:m !>(%done))''')
            time.sleep(.3)
        assert state()['azimuthStatus'] == 'observed', 'Subscription did not resume'
        action(dict(settings, azimuthAuto=False))
        for name in ('owners', 'nfts'):
            import_payload(a.pier, json.loads((root / f'tests/fixtures/{name}.json').read_text()))
        # Verify the strict wire format used by the new indexer, including a
        # transfer away-and-back represented by a changed generation.
        snap = {'action': 'snapshot', 'collection': 'demo', 'chain': demo['chain'], 'contract': demo['contract'],
                'observedAt': str(int(time.time())), 'block': '100', 'blockHash': '0x'+'1'*64, 'epoch': '0x1',
                'coverage': {'method':'events-supply','fromBlock':'1','supply':'2','codeHash':'0xabc'},
                'tokens': [{'id': t, 'owner':'0x'+'0'*39+'1', 'generation':'1'} for t in ('7','8')]}
        import_payload(a.pier, snap)
        claimed = state()
        status, _, _ = request(browser, url + '/gater/action',
            {'action':'claim','collection':'demo','token':'8','revision':claimed['revision']})
        assert status == 200
        import_payload(a.pier, {'action':'source-error','collection':'demo'})
        failed = next(c for c in state()['collections'] if c['id']=='demo')
        assert not failed['fresh'] and not failed['source']['healthy']
        assert next(t for t in failed['tokens'] if t['id']=='8')['ship'] == before['ship']
        snap['block'] = '101'; snap['tokens'][1]['generation'] = '3'
        import_payload(a.pier, snap)
        recovered = next(c for c in state()['collections'] if c['id']=='demo')
        assert recovered['fresh'] and next(t for t in recovered['tokens'] if t['id']=='8')['ship'] is None
        print('Source smoke passed: real native subscription, Gall resume, verified snapshot import, failure pause, transfer-generation invalidation.')
    finally:
        action(dict(settings, azimuthAuto=False))
        for name in ('owners', 'nfts'):
            import_payload(a.pier, json.loads((root / f'tests/fixtures/{name}.json').read_text()))
        if original:
            restored = state()
            assert request(browser, url + '/gater/action', {'action':'claim','collection':'demo',
                'token':original,'revision':restored['revision']})[0] == 200


if __name__ == '__main__': main()
