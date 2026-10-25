#!/usr/bin/env python3
"""Exercise the fixture claim API on an explicitly selected local test pier."""
import argparse
from http.cookiejar import CookieJar
import json
import time
from urllib.error import HTTPError
from urllib.parse import urlencode, urlsplit
from urllib.request import Request, build_opener, HTTPCookieProcessor
from conn import evaluate

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('pier')
parser.add_argument('--url', default='http://127.0.0.1:8190')
args = parser.parse_args()
url = args.url.rstrip('/')
if urlsplit(url).hostname not in ('127.0.0.1', 'localhost', '::1'):
    parser.error('This test only accepts a loopback test server')
anonymous = build_opener(HTTPCookieProcessor(CookieJar()))
host = build_opener(HTTPCookieProcessor(CookieJar()))


def request(client, path, body=None, origin=None, marker=True):
    headers = {}
    if body is not None:
        headers = {'Content-Type': 'application/json', 'Origin': origin or url}
        if marker:
            headers['X-Gater'] = '1'
        body = json.dumps(body).encode()
    try:
        with client.open(Request(url + path, body, headers), timeout=15) as response:
            return response.status, json.loads(response.read())
    except HTTPError as error:
        return error.code, json.loads(error.read())


assert request(anonymous, '/gater/me')[0] == 401
assert request(anonymous, '/gater/action', {'action': 'claim'})[0] == 403
# Retrieve only this disposable test pier's code, never print it.
reply = evaluate(args.pier, """=/  m  (strand ,vase)
;<  b=bowl:spider  bind:m  get-bowl
(pure:m !>((trip (scot %p .^(@p %j /(scot %p our.b)/code/(scot %da now.b)/(scot %p our.b))))))""")
numbers = reply.removeprefix('[0 %avow 0 %noun ').removesuffix(']').split()
code = ''.join(chr(int(value)) for value in numbers[:-1]).lstrip('~')
with host.open(Request(url + '/~/login', urlencode({'password': code, 'redirect': '/gater'}).encode()), timeout=15):
    pass
del code, numbers, reply
status, before = request(host, '/gater/me')
assert status == 200 and before['admin'] and not before['live']
collection = next(row for row in before['collections'] if row['id'] == 'demo')
previous = next((row['id'] for row in collection['tokens'] if row['ship'] == before['ship']), None)
claim = {'action': 'claim', 'collection': 'demo', 'token': '7', 'revision': before['revision']}
assert request(host, '/gater/action', claim, marker=False)[0] == 403
assert request(host, '/gater/action', claim, origin='https://unrelated.example')[0] == 403
assert request(host, '/gater/me')[1]['revision'] == before['revision']
status, after = request(host, '/gater/action', dict(claim, ship='~bud'))
assert status == 200
demo = next(row for row in after['collections'] if row['id'] == 'demo')
assert next(row for row in demo['tokens'] if row['id'] == '7')['ship'] == before['ship']
assert sum(row['ship'] == before['ship'] for row in demo['tokens']) == 1
assert request(host, '/gater/action', claim)[0] == 409
assert any(row['action'] == 'admit' and row['ship'] == before['ship'] for row in after['outbox'])
restore = {'action': 'claim' if previous else 'release', 'collection': 'demo',
           'token': previous or '7', 'revision': after['revision']}
assert request(host, '/gater/action', restore)[0] == 200
saved = request(host, '/gater/me')[1]
for action in ('suspend', 'revive'):
    evaluate(args.pier, f"""=/  m  (strand ,vase)
;<  b=bowl:spider  bind:m  get-bowl
;<  ~  bind:m  (poke [our.b %hood] %kiln-{action} !>(%gater))
(pure:m !>(%done))""")
    time.sleep(1)
loaded = request(host, '/gater/me')[1]
assert loaded['revision'] == saved['revision']
assert loaded['collections'] == saved['collections']
print('HTTP smoke passed: anonymous access, host login, CSRF, atomic claim, actor binding, revision conflict, outbox, restoration, Gall save/load.')
