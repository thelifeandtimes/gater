#!/usr/bin/env python3
"""Exercise native RPC configuration on a credential-free disposable fake ship."""
import argparse
import json
import time
from urllib.parse import urlsplit

from conn import evaluate
from eauth_smoke import client, local_login, request


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('pier')
    parser.add_argument('--url', default='http://127.0.0.1:8191')
    args = parser.parse_args()
    url = args.url.rstrip('/')
    if urlsplit(url).hostname not in ('127.0.0.1', 'localhost', '::1'):
        parser.error('Use a loopback fake ship')
    host, anonymous = client(), client()
    local_login(host, args.pier, url)  # Independently asserts Jael's fake flag.

    def state():
        status, body, _ = request(host, url + '/gater/config/state')
        assert status == 200
        return json.loads(body)

    before = state()
    assert not any(before['rpc'][key] for key in ('infuraConfigured', 'ethereumCustom', 'baseCustom')), 'Use a fake ship without saved RPC credentials'
    assert not before['collections'], 'Use a fake ship without configured communities'
    key = 'gaterSmokeSentinelKey'
    endpoint = 'https://rpc.invalid/gaterSmokeSentinelURL'

    def action(payload, expected=200):
        status, body, _ = request(host, url + '/gater/config/action', payload)
        assert status == expected, status
        assert key not in body and endpoint not in body, 'Credential echoed in response'
        return json.loads(body)

    try:
        for name in ('rpc-settings', 'rpc-bootstrap'):
            payload = {'action': name}
            assert request(anonymous, url + '/gater/config/action', payload)[0] == 403
            assert request(host, url + '/gater/action', payload)[0] == 403
        for invalid in ('http://rpc.invalid', 'https://rpc.invalid/\nsecret', 'https://rpc.invalid/#secret'):
            action({'action': 'rpc-settings', 'ethereumUrl': invalid}, 400)
        action({'action': 'rpc-bootstrap', 'height': '0', 'hash': '0x0', 'digest': '0x0'}, 409)
        action({'action': 'rpc-settings', 'infuraKey': key, 'ethereumUrl': endpoint, 'baseUrl': endpoint})
        saved = action({'action': 'rpc-settings', 'infuraKey': '', 'ethereumUrl': '', 'baseUrl': ''})
        assert all(saved['rpc'][k] for k in ('infuraConfigured', 'ethereumConfigured', 'baseConfigured', 'ethereumCustom', 'baseCustom'))
        for path in ('/gater/config/state', '/gater/me', '/gater', '/gater/config'):
            status, body, _ = request(host, url + path)
            assert status == 200 and key not in body and endpoint not in body
        for op in ('suspend', 'revive'):
            evaluate(args.pier, f'''=/  m  (strand ,vase)
;<  b=bowl:spider  bind:m  get-bowl
;<  ~  bind:m  (poke [our.b %hood] %kiln-{op} !>(%gater))
(pure:m !>(%done))''')
            time.sleep(.3)
        assert state()['rpc']['infuraConfigured'] and state()['rpc']['ethereumCustom']
        fallback = action({'action': 'rpc-settings', 'clearEthereum': True, 'clearBase': True})
        assert fallback['rpc']['ethereumConfigured'] and fallback['rpc']['baseConfigured']
        assert not fallback['rpc']['ethereumCustom'] and not fallback['rpc']['baseCustom']
        cleared = action({'action': 'rpc-settings', 'clearInfura': True})
        assert not any(cleared['rpc'][k] for k in ('infuraConfigured', 'ethereumConfigured', 'baseConfigured'))
        print('Native RPC HTTP smoke passed: host boundary, invalid credentials/anchor, write-only responses, blank preservation, custom override/fallback, Gall reload and explicit clear.')
    finally:
        try:
            action({'action': 'rpc-settings', 'clearInfura': True, 'clearEthereum': True, 'clearBase': True})
        finally:
            request(host, url + '/~/logout')


if __name__ == '__main__':
    main()
