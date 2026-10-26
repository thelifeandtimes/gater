#!/usr/bin/env python3
"""Exercise real Eyre EAuth between two explicitly selected local fake ships.

Uses the normal login/approval/finalization flow over HTTP and Ames. No cookies
or ship codes are printed or persisted; never run against a real pier.
"""
import argparse
from http.cookiejar import CookieJar
import json
from urllib.error import HTTPError
from urllib.parse import urlencode, urlsplit, parse_qs, urljoin
from urllib.request import Request, build_opener, HTTPCookieProcessor, HTTPRedirectHandler
from conn import evaluate


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def client():
    return build_opener(HTTPCookieProcessor(CookieJar()), NoRedirect())


def request(browser, url, body=None, form=False):
    headers = {}
    if body is not None:
        headers = {'Content-Type': 'application/x-www-form-urlencoded' if form else 'application/json',
                   'Origin': f'{urlsplit(url).scheme}://{urlsplit(url).netloc}', 'X-Gater': '1'}
        body = (urlencode(body) if form else json.dumps(body)).encode()
    try:
        response = browser.open(Request(url, body, headers), timeout=58)
    except HTTPError as error:
        response = error
    with response:
        data = response.read().decode()
        return response.status, data, response.headers


def local_login(browser, pier, url):
    # Assert the selected pier is fake before retrieving its development code.
    reply = evaluate(pier, '''=/  m  (strand ,vase)
;<  b=bowl:spider  bind:m  get-bowl
~|  %only-disposable-fake-ships
?>  .^(? %j /(scot %p our.b)/fake/(scot %da now.b))
(pure:m !>((trip (scot %p .^(@p %j /(scot %p our.b)/code/(scot %da now.b)/(scot %p our.b))))))''')
    numbers = reply.removeprefix('[0 %avow 0 %noun ').removesuffix(']').split()
    code = ''.join(chr(int(value)) for value in numbers[:-1]).lstrip('~')
    status, _, _ = request(browser, url + '/~/login', {'password': code, 'redirect': '/gater'}, form=True)
    assert status == 303, 'Local fake-ship login failed'


def start(browser, host, remote, ship):
    status, _, headers = request(browser, host + '/~/login',
                                 {'name': ship, 'redirect': '/gater/claim?collection=demo', 'eauth': ''}, form=True)
    assert status == 303, f'EAuth endpoint discovery returned HTTP {status}'
    approval = headers['Location']
    assert approval.startswith(remote + '/~/eauth?'), 'Discovered endpoint does not match the selected fake ship'
    args = {key: values[0] for key, values in parse_qs(urlsplit(approval).query).items()}
    status, page, _ = request(browser, approval)
    assert status == 200 and 'name="grant"' in page, 'Remote approval form was not served'
    return args


def approve(browser, host, remote, args, grant=True):
    data = dict(args, **({'grant': 'grant'} if grant else {'reject': ''}))
    status, _, headers = request(browser, remote + '/~/eauth', data, form=True)
    assert status == 303, f'Remote approval returned HTTP {status}'
    callback = headers['Location']
    assert callback.startswith(host + '/~/eauth?'), 'Unexpected EAuth callback origin'
    status, _, headers = request(browser, callback)
    assert status == 303, f'EAuth finalization returned HTTP {status}'
    return headers['Location']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('host_pier')
    parser.add_argument('remote_pier')
    parser.add_argument('--host', default='http://127.0.0.1:8190')
    parser.add_argument('--remote', default='http://127.0.0.1:8191')
    parser.add_argument('--ship', default='~zod')
    args = parser.parse_args()
    host, remote = args.host.rstrip('/'), args.remote.rstrip('/')
    for url in (host, remote):
        if urlsplit(url).hostname not in ('127.0.0.1', 'localhost', '::1'):
            parser.error('Only loopback fake-ship servers are allowed')
    admin, browser = client(), client()
    local_login(admin, args.host_pier, host)
    local_login(browser, args.remote_pier, remote)
    assert request(browser, host + '/gater/me')[0] == 401
    print('Local fake-ship logins passed; discovering EAuth endpoint...', flush=True)
    approval = start(browser, host, remote, args.ship)
    target = approve(browser, host, remote, approval)
    assert urljoin(host, target) == host + '/gater/claim?collection=demo'
    status, page, _ = request(browser, host + '/gater/claim')
    assert status == 200 and 'id="collections"' in page
    status, body, _ = request(browser, host + '/gater/me')
    before = json.loads(body)
    assert status == 200 and before['ship'] == args.ship
    assert 'outbox' not in before and 'baseUrl' not in before
    for path in ('/gater/config', '/gater/config.js', '/gater/config/state'):
        assert request(browser, host + path)[0] == 403
    assert request(browser, host + '/gater/config/action', {'action': 'settings'})[0] == 403
    assert request(browser, host + '/gater/action', {'action': 'settings'})[0] == 403
    print('Real EAuth identity and host-only boundaries passed.', flush=True)
    # Exercise a real remote claim, then restore the original fixture association.
    demo = next(c for c in before['collections'] if c['id'] == 'demo')
    original = next(t for t in demo['tokens'] if t['id'] == '8')['ship']
    assert original in (None, before['host']), 'Use an unclaimed or host-owned fixture token 8'
    payload = {'action': 'claim', 'collection': 'demo', 'token': '8', 'revision': before['revision'], 'ship': before['host']}
    status, body, _ = request(browser, host + '/gater/action', payload)
    if original:
        assert status == 409, 'Unsigned sibling takeover must fail'
        status, body, _ = request(admin, host + '/gater/action', {'action': 'reassign',
            'collection': 'demo', 'token': '8', 'target': args.ship, 'revision': before['revision']})
    assert status == 200, body
    claimed = json.loads(body)
    assert next(t for c in claimed['collections'] if c['id'] == 'demo' for t in c['tokens'] if t['id'] == '8')['ship'] == args.ship
    # Even the host cannot bypass another ship's association through claim.
    assert request(admin, host + '/gater/action', dict(payload, revision=claimed['revision']))[0] == 409
    restore = {'action': 'reassign' if original else 'release', 'collection': 'demo',
               'token': '8', 'target': before['host'], 'revision': claimed['revision']}
    assert request(browser, host + '/gater/action', restore)[0] == 200
    request(browser, host + '/~/logout')
    assert request(browser, host + '/gater/me')[0] == 401
    assert request(browser, host + '/gater/claim')[0] == 303
    # A rejected login never creates a remote session.
    approval = start(browser, host, remote, args.ship)
    approve(browser, host, remote, approval, grant=False)
    assert request(browser, host + '/gater/me')[0] == 401
    print('EAuth smoke passed: discovery, approval, redirect, remote identity, protected configuration, unsigned takeover denial, linked-ship transfer, actor binding, restoration, logout, rejection.')


if __name__ == '__main__':
    main()
