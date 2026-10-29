#!/usr/bin/env python3
"""Real Tlon delivery on two disposable fake ships, using invented ownership.

Never use with livenet piers. The control helper checks Jael's fake flag before
every evaluation; all HTTP requests use the two explicitly selected loopbacks.
Test groups/messages remain as inspection evidence. Transport is disabled at exit.
"""
import argparse
import json
import time
from urllib.parse import urlsplit
from conn import evaluate
from eauth_smoke import client, local_login, request, start, approve


def poke(pier, agent, mark, noun):
    return evaluate(pier, f'''=/  m  (strand ,vase)
;<  b=bowl:spider  bind:m  get-bowl
;<  ~  bind:m  (poke [our.b %{agent}] %{mark} !>({noun}))
(pure:m !>(%accepted))''')


def control(pier, enabled, target, clear_failed=False):
    data = json.dumps({'action': 'test-transport', 'enabled': enabled, 'targets': [target], 'clearFailed': clear_failed}, separators=(',', ':'))
    poke(pier, 'gater', 'json', f"(need (de:json:html '{data}'))")


def get_json(browser, url):
    status, body, _ = request(browser, url)
    assert status == 200, f'Expected HTTP 200, got {status}: {urlsplit(url).path}'
    return json.loads(body)


def until(check, description, timeout=75):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        result = check()
        if result:
            print(description, flush=True)
            return result
        time.sleep(1)
    raise AssertionError('Timed out: ' + description)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('host_pier')
    parser.add_argument('remote_pier')
    parser.add_argument('--host', default='http://127.0.0.1:8190')
    parser.add_argument('--remote', default='http://127.0.0.1:8191')
    args = parser.parse_args()
    host, remote = args.host.rstrip('/'), args.remote.rstrip('/')
    for url in (host, remote):
        if urlsplit(url).hostname not in ('127.0.0.1', 'localhost', '::1'):
            parser.error('Only loopback test servers are supported')
    admin, member, remote_admin = client(), client(), client()
    local_login(admin, args.host_pier, host)
    local_login(member, args.remote_pier, remote)
    local_login(remote_admin, args.remote_pier, remote)
    # The run is deliberately tied to these two known fake identities.
    for pier, ship in ((args.host_pier, '~nec'), (args.remote_pier, '~zod')):
        evaluate(pier, f'''=/  m  (strand ,vase)
;<  b=bowl:spider  bind:m  get-bowl
?>  =(our.b {ship})
(pure:m !>(%expected-fake-ship))''')
    prior_delivery = get_json(admin, host + '/~/scry/gater/delivery.json')
    failed = (prior_delivery.get('active') or {}).get('phase') == 'failed'
    control(args.host_pier, False, '~zod', clear_failed=failed)
    approval = start(member, host, remote, '~zod')
    approve(member, host, remote, approval)
    assert get_json(member, host + '/gater/me')['ship'] == '~zod'
    old = get_json(admin, host + '/gater/config/state')
    name = 'gater-' + str(int(time.time()))
    marker = 'Gater local integration ' + name
    collection = {'action': 'configure', 'id': name, 'name': 'Local transport fixture',
                  'chain': '8453', 'contract': f'0x{int(time.time()):040x}',
                  'group': name, 'role': 'holder', 'recognition': 'dm',
                  'message': marker, 'removeMembership': True, 'removalMessage': marker + ' link ended. Hold an NFT and relink to rejoin:'}
    address = '0x0000000000000000000000000000000000000001'
    other = '0x0000000000000000000000000000000000000002'

    def action(data, browser=admin):
        path = '/gater/config/action' if browser is admin else '/gater/action'
        status, body, _ = request(browser, host + path, data)
        assert status == 200, f'{data["action"]} returned {status}: {body}'
        return json.loads(body)

    def tokens(owner=address):
        return action({'action': 'nfts', 'collection': name, 'tokens': [{'id': '1', 'owner': owner}]})

    def group():
        return get_json(admin, host + f'/~/scry/groups/v3/groups/~nec/{name}.json')

    def delivery():
        data = get_json(admin, host + '/~/scry/gater/delivery.json')
        data['receipts'] = [r for r in data['receipts'] if r['group'] == name]
        return data

    def claim():
        revision = get_json(member, host + '/gater/me')['revision']
        return action({'action': 'claim', 'collection': name, 'token': '1', 'revision': revision}, member)

    broad_registered = False
    try:
        poke(args.host_pier, 'groups', 'group-command', f"[%create [%{name} ['Gater integration fixture' '' '' ''] %private [~ ~] ~]]")
        poke(args.host_pier, 'groups', 'group-action-5', f"[%group [~nec %{name}] %role (silt `(list @tas)`~[%holder %manual]) %add ['Test role' '' '' '']]")
        action({'action': 'settings', 'baseUrl': host, 'azimuthAuto': False})
        action(collection)
        action({'action': 'owners', 'owners': [{'ship': '~zod', 'owner': address}, {'ship': '~nec', 'owner': address}]})
        tokens()
        control(args.host_pier, True, '~zod')
        until(lambda: any(r['action'] == 'dm' for r in delivery()['receipts']), 'DM submitted to Tlon with an observed local message')
        dm_url = remote + '/~/scry/chat/v4/dm/~nec/writs/newest/20/heavy.json'
        until(lambda: marker in request(remote_admin, dm_url)[1], 'Claim DM received on the other fake ship')
        baseline = len(delivery()['receipts'])
        control(args.host_pier, True, '~zod')
        assert len(delivery()['receipts']) == baseline, 'Recognition sent a duplicate'
        assert '~zod' not in group()['admissions']['pending'], 'DM recognition unexpectedly invited'
        claim()
        until(lambda: 'holder' in group()['admissions']['pending'].get('~zod', []), 'Claim created an invitation carrying the NFT role')
        poke(args.remote_pier, 'groups', 'group-foreign-2', f'[%foreign [~nec %{name}] %join ~]')
        until(lambda: 'holder' in group()['seats'].get('~zod', {}).get('roles', []), 'Invitation accepted; NFT role observed in actual group membership')
        until(lambda: any(r['action'] == 'admit' for r in delivery()['receipts']), 'Admission recorded after observing Tlon state')
        # Round-trip Gall's saved state while delivery is enabled.
        for operation in ('suspend', 'revive'):
            poke(args.host_pier, 'hood', 'kiln-' + operation, '%gater')
        until(lambda: delivery()['enabled'], 'Transport ledger survived Gall save/load')
        assert len(delivery()['receipts']) == baseline + 1
        # Release while the NFT remains eligible must remove the managed seat.
        revision = get_json(member, host + '/gater/me')['revision']
        action({'action':'release','collection':name,'token':'1','revision':revision}, member)
        until(lambda: '~zod' not in group()['seats'] and '~zod' not in group()['admissions']['pending'], 'Release revoked the role and removed membership while ownership stayed eligible')
        until(lambda: len([r for r in delivery()['receipts'] if r['action']=='dm']) == 2, 'Confirmed kick generated exactly one removal DM')
        until(lambda: marker+' link ended.' in request(remote_admin, dm_url)[1], 'Custom removal explanation and rejoin link received by remote ship')
        assert host+'/gater/'+name in request(remote_admin, dm_url)[1]
        for operation in ('suspend','revive'):
            poke(args.host_pier,'hood','kiln-'+operation,'%gater')
        control(args.host_pier,True,'~zod')
        assert len([r for r in delivery()['receipts'] if r['action']=='dm']) == 2, 'Reload repeated removal message'
        # Per-collection manual approval holds the next admission even with delivery enabled.
        action(dict(collection, manualApproval=True))
        claim()
        assert '~zod' not in group()['admissions']['pending'], 'Manual collection sent an unapproved invitation'
        outbox=get_json(admin, host+'/gater/config/state')['outbox']
        pending=next(e for e in outbox if e['group']==name and e['action']=='admit')
        assert pending['manualApproval'] is True
        control(args.host_pier,False,'~zod')
        assert request(admin, host+'/gater/config/action',{'action':'approve-effect','fingerprint':pending['fingerprint']})[0] == 409, 'Approval unexpectedly unpaused global delivery'
        control(args.host_pier,True,'~zod')
        action({'action':'approve-effect','fingerprint':pending['fingerprint']})
        until(lambda: 'holder' in group()['admissions']['pending'].get('~zod', []), 'Exact manual approval admitted the ship')
        until(lambda: delivery()['active'] is None, 'Manual action receipt observed')
        action(dict(collection, manualApproval=False))
        until(lambda: 'holder' in group()['admissions']['pending'].get('~zod', []), 'Released NFT can be claimed again')
        poke(args.remote_pier, 'groups', 'group-foreign-2', f'[%foreign [~nec %{name}] %join ~]')
        until(lambda: 'holder' in group()['seats'].get('~zod', {}).get('roles', []), 'Membership restored after a new claim')
        tokens(other)
        until(lambda: '~zod' not in group()['seats'] and '~zod' not in group()['admissions']['pending']
              and any(r['action'] == 'kick' for r in delivery()['receipts']), 'NFT transfer revoked role and removed managed membership')
        receipts = delivery()['receipts']
        assert any(r['action'] == 'revoke' for r in receipts)
        assert any(r['action'] == 'kick' for r in receipts)
        until(lambda: delivery()['active'] is None, 'Removal receipt completed before the next scenario')
        # A manual invitation/member and manual role are not owned by Gater.
        action(dict(collection, recognition='none'))
        tokens()
        poke(args.host_pier, 'groups', 'group-action-5', f'[%group [~nec %{name}] %entry %pending (silt ~[~zod]) %add (silt `(list @tas)`~[%holder %manual])]')
        poke(args.remote_pier, 'groups', 'group-foreign-2', f'[%foreign [~nec %{name}] %join ~]')
        until(lambda: 'manual' in group()['seats'].get('~zod', {}).get('roles', []), 'Manual membership and roles established')
        claim()
        tokens(other)
        control(args.host_pier, True, '~zod')
        roles = group()['seats']['~zod']['roles']
        assert 'holder' in roles and 'manual' in roles, 'Gater removed a manual role or membership'
        print('Manual roles and pre-existing membership preserved.', flush=True)
        # Exercise broad recognition separately: a fresh collection has no
        # recognition receipt that could mask a missing invite implementation.
        broad_name = name + '-invite'
        broad = dict(collection, id=broad_name, group=broad_name, recognition='invite',
                     contract=f'0x{int(collection["contract"], 16) + 1:040x}')
        poke(args.host_pier, 'groups', 'group-command', f"[%create [%{broad_name} ['Gater broad-invite fixture' '' '' ''] %private [~ ~] ~]]")
        poke(args.host_pier, 'groups', 'group-action-5', f"[%group [~nec %{broad_name}] %role (silt `(list @tas)`~[%holder %manual]) %add ['Test role' '' '' '']]")
        action(broad)
        broad_registered = True
        def broad_tokens(owner):
            action({'action':'nfts', 'collection':broad_name, 'tokens':[{'id':'1','owner':owner}]})
        def broad_group():
            return get_json(admin, host + f'/~/scry/groups/v3/groups/~nec/{broad_name}.json')
        broad_tokens(address)
        until(lambda: '~zod' in broad_group()['admissions']['pending'], 'Invite-all recognition produced an invitation without a claim')
        broad_tokens(other)
        until(lambda: '~zod' not in broad_group()['admissions']['pending'], 'Eligibility loss cancelled an unaccepted invitation')
        # This same managed seat can later acquire independent manual authority.
        broad_tokens(address)
        revision = get_json(member, host + '/gater/me')['revision']
        action({'action':'claim', 'collection':broad_name, 'token':'1', 'revision':revision}, member)
        until(lambda: 'holder' in broad_group()['admissions']['pending'].get('~zod', []), 'Reclaim restored the managed invitation and role')
        poke(args.remote_pier, 'groups', 'group-foreign-2', f'[%foreign [~nec %{broad_name}] %join ~]')
        until(lambda: '~zod' in broad_group()['seats'], 'Reclaimed membership accepted')
        poke(args.host_pier, 'groups', 'group-action-5', f'[%group [~nec %{broad_name}] %seat (silt ~[~zod]) %add-roles (silt ~[%manual])]')
        broad_tokens(other)
        until(lambda: broad_group()['seats'].get('~zod', {}).get('roles') == ['manual'], 'Later manual role preserved membership while the NFT role was revoked')
        until(lambda: any(r['group'] == broad_name and r['result'] == 'preserved'
                         for r in get_json(admin, host + '/~/scry/gater/delivery.json')['receipts']), 'Preserved membership recorded; Gater relinquished management')
        print('Tlon smoke passed. Test group: ~nec/' + name, flush=True)
    finally:
        control(args.host_pier, False, '~zod')
        if broad_registered:
            action(dict(broad, recognition='none'))
            action({'action':'nfts', 'collection':broad_name, 'tokens':[]})
        # Retire this run's fixture policy. Preserve the test group for inspection.
        action(dict(collection, recognition='none'))
        action({'action': 'nfts', 'collection': name, 'tokens': []})
        action({'action': 'settings', 'baseUrl': old['baseUrl'], 'azimuthAuto': old['azimuthAuto']})


if __name__ == '__main__':
    main()
