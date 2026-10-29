#!/usr/bin/env python3
"""Operate the dedicated comet recorded in output/comet.local.json.

No test fixtures or Tlon messages are sent. `code` prints the login code only
to an interactive terminal; `check` uses it in memory and never prints it.
"""
import argparse
from http.cookiejar import CookieJar
import json
from pathlib import Path
import sys
from urllib.error import HTTPError
from urllib.parse import urlencode, urlsplit
from urllib.request import Request, build_opener, HTTPCookieProcessor, HTTPRedirectHandler

from conn import evaluate_target

ROOT = Path(__file__).resolve().parents[1]


def evaluate(config, expression):
    return evaluate_target(config['pier'], '''=/  m  (strand ,vase)
;<  b=bowl:spider  bind:m  get-bowl
''' + expression, live_comet=config['ship'])


def decode_tape(reply):
    raw = reply.removeprefix('[0 %avow 0 %noun ').removesuffix(']')
    numbers = [int(n) for n in raw.split()]
    if not numbers or numbers[-1] != 0:
        raise ValueError('Invalid text response from comet')
    return ''.join(chr(n) for n in numbers[:-1])


def login_code(config):
    return decode_tape(evaluate(config, '''(pure:m !>((trip (scot %p .^(@p %j /(scot %p our.b)/code/(scot %da now.b)/(scot %p our.b))))))''')).lstrip('~')


def state(config, endpoint='state'):
    if endpoint not in ('state', 'delivery'):
        raise ValueError('Invalid state endpoint')
    return json.loads(decode_tape(evaluate(config, f'''(pure:m !>((trip (en:json:html .^(json %gx /(scot %p our.b)/gater/(scot %da now.b)/{endpoint}/json)))))''')))


def summary(config):
    current = state(config)
    delivery = state(config, 'delivery')
    return {'ship': current['ship'], 'url': config['url'],
            'live': current['live'], 'azimuth': current['azimuthStatus'],
            'collections': [{k: c[k] for k in ('id', 'chain', 'contract', 'fresh', 'source', 'checkpoint')}
                            for c in current['collections']],
            'delivery': delivery, 'ownershipAudit': current.get('ownershipAudit'), 'automatic': current.get('automatic', False)}


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def check(config):
    # Identity/rank/fake checks happen before obtaining any credential.
    code = login_code(config)
    base = config['url'].rstrip('/')
    if urlsplit(base).hostname not in ('127.0.0.1', 'localhost', '::1'):
        raise ValueError('This check only accepts the local comet HTTP interface')
    anonymous = build_opener(HTTPCookieProcessor(CookieJar()), NoRedirect())
    host = build_opener(HTTPCookieProcessor(CookieJar()), NoRedirect())

    def request(client, path, body=None):
        headers = {'Content-Type': 'application/x-www-form-urlencoded'} if body else {}
        try:
            response = client.open(Request(base + path, body, headers), timeout=30)
        except HTTPError as error:
            response = error
        with response:
            return response.status, response.read().decode(), response.headers

    for path, expected in [('/gater', 200), ('/gater/config', 403),
                           ('/gater/config.js', 403), ('/gater/config/state', 403),
                           ('/gater/me', 401), ('/gater/claim', 303)]:
        status, _, _ = request(anonymous, path)
        assert status == expected, f'{path}: HTTP {status}, expected {expected}'
    print('Public page and anonymous access boundaries passed.')
    status, _, _ = request(host, '/~/login', urlencode({'password': code, 'redirect': '/gater/config'}).encode())
    del code
    assert status == 303, 'Host login failed'
    try:
        for path in ('/gater/config', '/gater/config.js', '/gater/claim'):
            assert request(host, path)[0] == 200, f'Host cannot access {path}'
        status, body, _ = request(host, '/gater/config/state')
        data = json.loads(body)
        assert status == 200 and data['admin'] and data['ship'] == config['ship']
        print('Comet host login and protected pages passed. Delivery is '+('enabled.' if data.get('delivery',{}).get('enabled') else 'paused.'))
    finally:
        request(host, '/~/logout')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=('status', 'check', 'code'))
    parser.add_argument('--deployment', type=Path, default=ROOT / 'output/comet.local.json')
    args = parser.parse_args()
    config = json.loads(args.deployment.read_text())
    if args.command == 'code':
        if not sys.stdout.isatty():
            parser.error('Run code directly in your terminal; it is not printed into logs or pipes.')
        print(login_code(config))
    elif args.command == 'check':
        check(config)
    else:
        print(json.dumps(summary(config), indent=2))


if __name__ == '__main__':
    main()
