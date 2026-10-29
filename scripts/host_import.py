"""Import complete snapshots over local Eyre without compiling JSON as Hoon.

The control socket verifies the selected ship before reading its login code.
The code and cookies are held only in memory and the temporary session is closed.
"""
from http.cookiejar import CookieJar
import json
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, build_opener, HTTPCookieProcessor, HTTPRedirectHandler

from conn import evaluate_target


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def import_snapshot(pier, payload, *, live_comet=None, live_ship=None):
    if payload.get('action') != 'snapshot':
        raise ValueError('Expected a snapshot')
    return host_action(pier, payload, live_comet=live_comet, live_ship=live_ship)


def host_action(pier, payload, *, live_comet=None, live_ship=None):
    data = json.dumps(payload, separators=(',', ':'), ensure_ascii=True).encode()
    if payload.get('action') not in ('snapshot', 'audit-azimuth') or len(data) > 2_000_000:
        raise ValueError('Expected a snapshot within Eyre\'s 2 MB import limit')
    return _host_request(pier, '/gater/config/action', data, live_comet=live_comet, live_ship=live_ship, identity=True)


def audit_material(pier, height, *, live_comet=None, live_ship=None):
    if type(height) is not int or not 0 < height < 10**15:
        raise ValueError('Invalid audit height')
    return _host_request(pier, f"/~/scry/gater/audit/{format(height, ',').replace(',', '.')}.json", None, live_comet=live_comet, live_ship=live_ship)


def _host_request(pier, path, data, *, live_comet=None, live_ship=None, identity=False):
    ports = [row.split() for row in (Path(pier) / '.http.ports').read_text().splitlines()]
    ports = [int(row[0]) for row in ports if len(row) == 3 and row[1:] == ['insecure', 'public'] and row[0].isdigit()]
    if len(ports) != 1 or not 1 <= ports[0] <= 65535:
        raise RuntimeError('Could not identify the selected pier\'s HTTP port')
    base = f'http://127.0.0.1:{ports[0]}'
    reply = evaluate_target(pier, '''=/  m  (strand ,vase)
;<  b=bowl:spider  bind:m  get-bowl
(pure:m !>((trip (scot %p .^(@p %j /(scot %p our.b)/code/(scot %da now.b)/(scot %p our.b))))))''', live_comet=live_comet, live_ship=live_ship)
    numbers = reply.removeprefix('[0 %avow 0 %noun ').removesuffix(']').split()
    if not numbers or numbers[-1] != '0':
        raise RuntimeError('Invalid credential response from selected pier')
    code = ''.join(chr(int(n)) for n in numbers[:-1]).lstrip('~')
    client = build_opener(HTTPCookieProcessor(CookieJar()), NoRedirect())

    def request(path, body=None, headers=None):
        try:
            response = client.open(Request(base + path, body, headers or {}), timeout=45)
        except HTTPError as error:
            response = error
        except (URLError, OSError):
            raise RuntimeError('Local host connection failed') from None
        with response:
            return response.status, response.read()

    status, _ = request('/~/login', urlencode({'password': code, 'redirect': '/gater/config'}).encode(),
                        {'Content-Type': 'application/x-www-form-urlencoded'})
    del code, reply, numbers
    if status != 303:
        raise RuntimeError(f'Local host login failed (HTTP {status})')
    try:
        status, result = request(path, data,
                                 {'Content-Type': 'application/json', 'Origin': base, 'X-Gater': '1'})
        if status != 200:
            raise RuntimeError(f'Host rejected snapshot (HTTP {status})')
        state = json.loads(result)
        expected = live_ship if live_ship is not None else live_comet
        if identity and (not state.get('admin') or (expected is not None and state.get('ship') != expected)):
            raise RuntimeError('Unexpected host identity in snapshot receipt')
        return state
    finally:
        request('/~/logout')
