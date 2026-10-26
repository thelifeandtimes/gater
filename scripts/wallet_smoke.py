#!/usr/bin/env python3
"""Verify strict transfers through real EAuth and HTTP using public test key 1.

Requires eth-account (test only). Never reads a real wallet or signs a transaction.
Only loopback fake ships with the documented demo fixtures are supported.
"""
import argparse
import json
from pathlib import Path
from urllib.parse import urlsplit
from eth_account import Account
from eth_account.messages import encode_defunct
from eauth_smoke import client, local_login, request, start, approve
from index import import_payload


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('host_pier'); p.add_argument('remote_pier')
    p.add_argument('--host', default='http://127.0.0.1:8190')
    p.add_argument('--remote', default='http://127.0.0.1:8191')
    a = p.parse_args(); host, remote = a.host.rstrip('/'), a.remote.rstrip('/')
    for url in (host, remote):
        if urlsplit(url).hostname not in ('127.0.0.1','localhost','::1'): p.error('Use loopback fake ships')
    admin, sibling = client(), client()
    local_login(admin, a.host_pier, host); local_login(sibling, a.remote_pier, remote)
    approve(sibling, host, remote, start(sibling, host, remote, '~zod'))
    def state(who=admin):
        status, body, _ = request(who, host + '/gater/me')
        assert status == 200
        return json.loads(body)
    def action(who, name, **extra):
        return request(who, host + '/gater/action', dict(action=name, collection='demo', token='8',
                       revision=state(who)['revision'], **extra))
    def assert_ship(body, ship):
        view = json.loads(body)
        token = next(t for c in view['collections'] if c['id']=='demo' for t in c['tokens'] if t['id']=='8')
        assert token['ship'] == ship
    _, raw, _ = request(admin, host + '/gater/config/state')
    before = json.loads(raw)
    assert before['fixtures'] and not before['azimuthAuto'] and before['ship']=='~nec'
    original = {t['id']:t['ship'] for c in before['collections'] if c['id']=='demo' for t in c['tokens'] if t['ship']}
    assert all(v in ('~nec','~zod') for v in original.values())
    root = Path(__file__).resolve().parents[1]
    key = (1).to_bytes(32, 'big')  # Public test key, never fund this address.
    owner = Account.from_key(key).address.lower()
    try:
        import_payload(a.host_pier, {'action':'owners','owners':[{'ship':s,'owner':owner} for s in ('~nec','~zod')]})
        import_payload(a.host_pier, {'action':'nfts','collection':'demo','tokens':[{'id':i,'owner':owner} for i in ('7','8')]})
        assert action(admin, 'claim')[0] == 200
        assert action(sibling, 'claim', ship='~nec')[0] == 409
        assert action(sibling, 'reassign', target='~zod', ship='~nec')[0] == 409
        revision = state(sibling)['revision']
        status, raw, _ = request(sibling, host + '/gater/wallet-challenge',
                                {'collection':'demo','token':'8','revision':revision})
        assert status == 200, raw
        challenge = json.loads(raw)
        assert challenge['owner'] == owner and 'To ship: ~zod' in challenge['message']
        def signed(k): return '0x' + Account.sign_message(encode_defunct(text=challenge['message']), k).signature.hex()
        payload = dict(action='wallet-claim', collection='demo', token='8', revision=revision,
                       expires=challenge['expires'], signature=signed((2).to_bytes(32,'big')))
        assert request(sibling, host + '/gater/action', payload)[0] == 409
        assert state(sibling)['revision'] == revision
        payload['signature'] = signed(key)
        # Signature cannot authorize a different target, token or validity period.
        assert request(admin, host + '/gater/action', payload)[0] == 409
        assert request(sibling, host + '/gater/action', dict(payload, token='7'))[0] == 409
        assert request(sibling, host + '/gater/action', dict(payload, expires='1'))[0] == 409
        status, raw, _ = request(sibling, host + '/gater/action', dict(payload, ship='~nec'))
        assert status == 200, raw
        assert_ship(raw, '~zod')
        assert request(sibling, host + '/gater/action', payload)[0] == 409
        assert action(admin, 'claim')[0] == 409
        assert action(admin, 'reassign', target='~nec')[0] == 409
        status, raw, _ = action(sibling, 'reassign', target='~nec')
        assert status == 200, raw
        assert_ship(raw, '~nec')
        print('Wallet smoke passed: unsigned takeover denied, spoofed actor denied, wrong signer rejected, bound signature accepted, replay denied, linked-ship transfer, host has no bypass.')
    finally:
        for name in ('owners','nfts'):
            import_payload(a.host_pier, json.loads((root/f'tests/fixtures/{name}.json').read_text()))
        for token, ship in original.items():
            who = admin if ship=='~nec' else sibling
            status, raw, _ = request(who, host+'/gater/action', {'action':'claim','collection':'demo',
                                    'token':token,'revision':state(who)['revision']})
            assert status == 200, raw
        request(sibling, host + '/~/logout')


if __name__ == '__main__': main()
