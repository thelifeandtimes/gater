#!/usr/bin/env python3
"""Exercise the fixture claim API on an explicitly selected local test pier."""
import argparse
from http.cookiejar import CookieJar
import json
import time
from urllib.error import HTTPError
from urllib.parse import urlencode, urlsplit
from urllib.request import Request, build_opener, HTTPCookieProcessor, HTTPRedirectHandler
from conn import evaluate

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('pier')
parser.add_argument('--url', default='http://127.0.0.1:8190')
args = parser.parse_args()
url = args.url.rstrip('/')
if urlsplit(url).hostname not in ('127.0.0.1', 'localhost', '::1'):
    parser.error('This test only accepts a loopback test server')
class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


anonymous = build_opener(HTTPCookieProcessor(CookieJar()), NoRedirect())
host = build_opener(HTTPCookieProcessor(CookieJar()))


def raw_request(client, path, body=None, origin=None, marker=True):
    headers = {}
    if body is not None:
        headers = {'Content-Type': 'application/json', 'Origin': origin or url}
        if marker:
            headers['X-Gater'] = '1'
        body = json.dumps(body).encode()
    try:
        with client.open(Request(url + path, body, headers), timeout=15) as response:
            return response.status, response.read().decode(), response.headers
    except HTTPError as error:
        return error.code, error.read().decode(), error.headers


def request(client, path, *args, **kwargs):
    status, body, headers = raw_request(client, path, *args, **kwargs)
    return status, json.loads(body) if headers.get_content_type() == 'application/json' else body


def member_view(data):
    assert not {'admin', 'outbox', 'baseUrl', 'azimuthAuto', 'fixtures', 'azimuthStatus'} & data.keys()
    for row in data['collections']:
        assert not {'contract', 'recognition', 'removeMembership', 'message', 'role', 'source', 'checkpoint'} & row.keys()


for path in ('/gater', '/gater/', '/gater?collection=demo'):
    status, page, headers = raw_request(anonymous, path)
    assert status == 200 and headers.get('Cache-Control') == 'no-store'
    assert 'id="login"' in page and 'value="/gater/claim"' in page
    assert 'name="eauth"' in page and 'id="configure"' not in page
    assert 'id="collections"' not in page and 'id="settings"' not in page
assert request(anonymous, '/gater/landing.js')[0] == 200
assert request(anonymous, '/gater/style.css')[0] == 200
status, _, headers = raw_request(anonymous, '/gater/claim?collection=demo')
assert status == 303 and headers.get('Location') == '/gater?collection=demo'
assert request(anonymous, '/gater/claim.js')[0] == 401
assert request(anonymous, '/gater/me')[0] == 401
assert request(anonymous, '/gater/action', {'action': 'claim'})[0] == 401
for path in ('/gater/config', '/gater/config/', '/gater/config.js', '/gater/config/state'):
    status, data = request(anonymous, path)
    assert status == 403 and set(data) == {'error'}
assert request(anonymous, '/gater/config/action', {'action': 'settings'})[0] == 403
aliases = ('/gater/app.js', '/gater/x/config', '/gater/config.json', '/gater/config.js.map', '/gater/action.json', '/gater/unknown')
for path in aliases:
    assert request(anonymous, path)[0] == 404
# Retrieve only this disposable test pier's code, never print it.
reply = evaluate(args.pier, """=/  m  (strand ,vase)
;<  b=bowl:spider  bind:m  get-bowl
~|  %only-disposable-fake-ships
?>  .^(? %j /(scot %p our.b)/fake/(scot %da now.b))
(pure:m !>((trip (scot %p .^(@p %j /(scot %p our.b)/code/(scot %da now.b)/(scot %p our.b))))))""")
numbers = reply.removeprefix('[0 %avow 0 %noun ').removesuffix(']').split()
code = ''.join(chr(int(value)) for value in numbers[:-1]).lstrip('~')
with host.open(Request(url + '/~/login', urlencode({'password': code, 'redirect': '/gater'}).encode()), timeout=15):
    pass
del code, numbers, reply
for path in aliases:
    assert request(host, path)[0] == 404
status, page = request(host, '/gater/claim')
assert status == 200 and 'id="collections"' in page
assert 'id="configure"' not in page and 'id="settings"' not in page and 'id="outbox"' not in page
status, page = request(host, '/gater/config')
assert status == 200 and 'id="settings"' in page and 'id="configure"' in page
assert 'id="collections"' not in page
assert request(host, '/gater/claim.js')[0] == 200
assert request(host, '/gater/config.js')[0] == 200
status, admin = request(host, '/gater/config/state')
assert status == 200 and admin['admin'] and not admin['live']
settings = {'action': 'settings', 'baseUrl': admin['baseUrl'], 'azimuthAuto': admin['azimuthAuto']}
assert request(host, '/gater/action', settings)[0] == 403
assert request(host, '/gater/config/action', settings, marker=False)[0] == 403
assert request(host, '/gater/config/action', settings, origin='https://unrelated.example')[0] == 403
assert request(host, '/gater/config/action', settings)[0] == 200
assert request(host, '/gater/config/action', {'action': 'claim'})[0] == 403
status, before = request(host, '/gater/me')
assert status == 200 and not before['live']
member_view(before)
collection = next(row for row in before['collections'] if row['id'] == 'demo')
previous = next((row['id'] for row in collection['tokens'] if row['ship'] == before['ship']), None)
claim = {'action': 'claim', 'collection': 'demo', 'token': '7', 'revision': before['revision']}
assert request(host, '/gater/action', claim, marker=False)[0] == 403
assert request(host, '/gater/action', claim, origin='https://unrelated.example')[0] == 403
assert request(host, '/gater/me')[1]['revision'] == before['revision']
status, after = request(host, '/gater/action', dict(claim, ship='~bud'))
assert status == 200
member_view(after)
demo = next(row for row in after['collections'] if row['id'] == 'demo')
assert next(row for row in demo['tokens'] if row['id'] == '7')['ship'] == before['ship']
assert sum(row['ship'] == before['ship'] for row in demo['tokens']) == 1
assert request(host, '/gater/action', claim)[0] == 409
outbox = request(host, '/gater/config/state')[1]['outbox']
assert any(row['action'] == 'admit' and row['ship'] == before['ship'] for row in outbox)
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
print('HTTP smoke passed: public landing, login redirect, protected pages/scripts/APIs, exact routes, separate member/configuration views and actions, host login, CSRF, atomic claim, actor binding, revision conflict, outbox, restoration, Gall save/load.')
