#!/usr/bin/env python3
"""Check settings privacy and metadata boundaries on an explicitly selected fake ship."""
import argparse
import json
from conn import evaluate, hoon_cord
from eauth_smoke import client, local_login, request
from urllib.parse import urlsplit

p=argparse.ArgumentParser(description=__doc__);p.add_argument('pier');p.add_argument('--url',default='http://127.0.0.1:8190');a=p.parse_args()
if urlsplit(a.url).hostname not in ('127.0.0.1','localhost','::1'):p.error('Loopback fake ship required')
admin,public=client(),client();local_login(admin,a.pier,a.url)
def get(path,browser=admin):
    status,body,_=request(browser,a.url+path);assert status==200,(path,status);return json.loads(body)
def put(value=None):
    noun='[%del-entry %omarchy-urbit-theme %appearance %current]' if value is None else '[%put-entry %omarchy-urbit-theme %appearance %current %s '+hoon_cord(value)+']'
    evaluate(a.pier,f'''=/  m  (strand ,vase)
;<  b=bowl:spider  bind:m  get-bowl
;<  ~  bind:m  (poke [our.b %settings] %settings-event !>({noun}))
(pure:m !>(%settings-updated))''')
old=get('/~/scry/settings/desk/omarchy-urbit-theme.json')['desk'].get('appearance',{}).get('current')
assert old is None or isinstance(old,str)
profile={'schemaVersion':1,'colors':{'background':'#101820','foreground':'#f4f2e9','accent':'#98c18d','bright_red':'#ff8899','evil':'url(javascript:alert(1))'},'font':'JetBrainsMono Nerd Font','files':{'private':'not-for-public-page'},'shell':{'secret':'not-for-public-page'}}
try:
    put(json.dumps(profile))
    view=get('/gater/appearance',public)
    assert set(view)=={'colors','font'}
    assert view['colors']=={k:v for k,v in profile['colors'].items() if k!='evil'}
    assert view['font']==profile['font']
    assert 'not-for-public-page' not in json.dumps(view)
    payload={'action':'import-media','collection':'demo','contract':'0x000000000000000000000000000000000000000a','chain':'8453','tokens':[{'id':'7','name':'Fixture #7','image':'https://example.invalid/nft.png','uri':'https://example.invalid/7.json'}],'images':{}}
    assert request(public,a.url+'/gater/config/action',payload)[0]==403
    assert request(admin,a.url+'/gater/config/action',payload)[0]==403
    for browser in [public,admin]:
        assert request(browser,a.url+'/gater/demo/metadata')[0]==404
        assert request(browser,a.url+'/gater/images')[0]==404
    assert request(public,a.url+'/gater/artwork.js')[0]==401
    assert request(admin,a.url+'/gater/artwork.js')[0]==200
    assert request(public,a.url+'/~/scry/gater/audit/25.421.988.json')[0] in (401,403)
    print('Presentation smoke passed: shared settings, full safe palette, private-field exclusion, retired metadata routes/imports, authenticated artwork code and protected audit access.')
finally:
    put(old)
    request(admin,a.url+'/~/logout')
