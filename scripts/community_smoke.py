#!/usr/bin/env python3
"""Exercise community management on an explicitly selected disposable fake pier.

Creates a private test group, its chat and a role; keeps those as evidence after
removing the test collection. No invitations, DMs or live ships are involved.
"""
import argparse
import json
import time
from urllib.parse import urlsplit
from eauth_smoke import client, local_login, request
from conn import evaluate


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('pier')
    parser.add_argument('--url', default='http://127.0.0.1:8190')
    args = parser.parse_args()
    url = args.url.rstrip('/')
    if urlsplit(url).hostname not in ('127.0.0.1', 'localhost', '::1'):
        parser.error('Use a loopback fake-ship interface')
    admin, public = client(), client()
    local_login(admin, args.pier, url)  # runtime fake guard before credentials

    def get(path, browser=admin):
        status, body, _ = request(browser, url + path)
        assert status == 200, (path, status)
        return json.loads(body)

    def action(body, expected=200, browser=admin):
        status, result, _ = request(browser, url + '/gater/config/action', body)
        assert status == expected, (body['action'], status, result[:300])
        return json.loads(result)

    def settle():
        for _ in range(65):
            state = get('/gater/config/state')
            job = state['provisioning']
            assert job['phase'] != 'failed', job['error']
            if job['phase'] == 'done':
                return state
            time.sleep(1)
        raise AssertionError('Tlon provisioning was not observed')

    before = get('/gater/config/state')
    host = before['host']
    name = 'ui-check-' + str(int(time.time()))
    create = {'action': 'create-group', 'group': name, 'name': 'Community UI test'}
    action(create, 403, public)
    # CSRF denial precedes any local Tlon operation.
    from urllib.request import Request
    from urllib.error import HTTPError
    try:
        admin.open(Request(url + '/gater/config/action', json.dumps(create).encode(),
                           {'Content-Type': 'application/json', 'X-Gater':'1', 'Origin':'https://unrelated.example'}))
        raise AssertionError('Cross-origin create was accepted')
    except HTTPError as error:
        assert error.code == 403
    action(create, 202); settle()
    path = f'/~/scry/groups/v3/groups/{host}/{name}.json'
    group = get(path)
    assert f'chat/{host}/{name}-chat' in group['channels'], group['channels'].keys()
    action(create, 409)
    print('Exact group slug, initial chat and duplicate/CSRF/anonymous guards passed.', flush=True)
    role = {'action':'create-role','group':name,'role':'holder','name':'Holder'}
    action(dict(role, role='admin'), 409)
    action(role, 202); state = settle()
    group = get(path)
    assert 'holder' in group['roles'] and 'holder' not in group['admins']
    assert any(g['id'] == name and {'id':'holder','name':'Holder'} in g['roles'] for g in state['groups'])
    action(role, 409)
    branding = {'title':'Nockmilio’s Only', 'subtitle':'Sovereign money deserves sovereign identity.',
                'claimTitle':'Choose your identity', 'claimSubtitle':'Link your membership.',
                'header':'https://example.com/banner.png','avatar':'https://example.com/avatar.png',
                'background':'#101820','surface':'#18232c','text':'#f4f2e9','muted':'#b0b9bd','accent':'#98c18d'}
    config = {'action':'configure','id':name,'name':'Branded community','chain':'8453',
              'contract':f'0x{int(time.time()):040x}','group':name,'role':'holder',
              'recognition':'none','removeMembership':True,'message':'Join us:', 'brand':branding}
    action(dict(config, role='missing'), 409)
    action(dict(config, brand={'header':'javascript:alert(1)'}), 409)
    action(config)
    info = get(f'/gater/{name}/info', public)
    assert set(info) == {'id','name','brand'} and info['brand'] == branding
    status, page, headers = request(public, url + f'/gater/{name}')
    assert status == 200 and "form-action 'self' http: https:" in headers['Content-Security-Policy']
    status, _, headers = request(public, url + f'/gater/{name}/claim')
    assert status == 303 and headers['Location'] == f'/gater/{name}'
    status, page, headers = request(admin, url + f'/gater/{name}/claim')
    assert status == 200 and headers['Content-Security-Policy'].endswith("form-action 'self'")
    assert '/~/logout' not in page
    assert request(public, url + f'/gater/{name}/config')[0] == 404
    assert request(public, url + '/gater/absent-collection/info')[0] == 404
    # New save envelope preserves branding and the observed provisioning result.
    for op in ('suspend','revive'):
        evaluate(args.pier, f'''=/  m  (strand ,vase)
;<  b=bowl:spider  bind:m  get-bowl
;<  ~  bind:m  (poke [our.b %hood] %kiln-{op} !>(%gater))
(pure:m !>(%done))''')
        time.sleep(1)
    assert get(f'/gater/{name}/info', public)['brand'] == branding
    print('Role creation, non-admin permissions, scoped pages, branding and save/load passed.', flush=True)
    state = get('/gater/config/state')
    action({'action':'delete-collection','id':name,'revision':'0'},409)
    action({'action':'delete-collection','id':name,'revision':state['revision']})
    assert request(public, url + f'/gater/{name}/info')[0] == 404
    assert request(public, url + f'/gater/{name}')[0] == 404
    group_after = get(path)
    for key in ('seats','roles','channels'):
        assert group_after[key] == group[key], key
    assert not get('/gater/config/state')['live']
    request(admin, url + '/~/logout')
    print('Deletion removed the public community and preserved Tlon members, roles and chat.', flush=True)
    print('Community smoke passed; evidence group:', host + '/' + name)


if __name__ == '__main__':
    main()
