::  Authorization, HTTP request guards, and host input validation.
=/  m  (strand ,vase)
=/  now  ~2026.10.25
=/  st  *state
=/  cfg=collection  ['Example' 8.453 0xabc %club %holder %dm 'Claim membership:' &]
=.  collections.st  (~(put by collections.st) %example cfg)
=/  req  *inbound-request:eyre
=.  request.req  [%'POST' '/gater/action' ~[['host' 'host.example'] ['origin' 'https://host.example'] ['x-gater' '1']] ~]
~|  %csrf-same-origin
?>  (csrf req)
~|  %csrf-cross-origin-rejected
?>  !(csrf req(header-list.request ~[['host' 'host.example'] ['origin' 'https://evil.example'] ['x-gater' '1']]))
~|  %csrf-missing-header-rejected
?>  !(csrf req(header-list.request ~[['host' 'host.example'] ['origin' 'https://host.example']]))
~|  %host-requires-authenticated-flag
?>  !(signed-in req(authenticated |) ~nec ~nec)
?>  (signed-in req(authenticated &) ~nec ~nec)
~|  %foreign-eauth-planet-does-not-require-local-auth-flag
?>  (signed-in req(authenticated |) ~zod ~nec)
~|  %anonymous-comet-denied
?>  !(signed-in req(authenticated |) (bex 100) ~nec)
~|  %foreign-ship-cannot-configure
=/  json  (need (de:json:html '{"action":"settings","baseUrl":"https://host.example"}'))
=/  result  (act st now ~zod ~nec json)
?>  ?=(%| -.result)
~|  %host-can-set-url
=/  result  (act st now ~nec ~nec json)
?>  ?=(%& -.result)
?>  =('https://host.example' base-url.p.result)
~|  %live-dispatch-stays-disabled
=/  result  (act st now ~nec ~nec (need (de:json:html '{"action":"settings","baseUrl":"https://host.example","live":true}')))
?>  ?=(%| -.result)
~|  %arbitrary-erc721-collection-defaults
=/  config  (need (de:json:html '{"action":"configure","id":"second","name":"Other collection","chain":"1","contract":"0x0000000000000000000000000000000000000123","group":"another","role":"collector"}'))
=/  result  (act st now ~nec ~nec config)
?>  ?=(%& -.result)
=/  added  (~(got by collections.p.result) %second)
?>  =(%dm recognition.added)
?>  kick.added
~|  %invalid-uint256-rejected
=/  json  (pairs:enjs:format ~[action+s+'claim' collection+s+'example' token+s+(crip (trip (scot %ud (bex 256)))) revision+s+'0'])
=/  result  (act st now ~nec ~nec json)
?>  ?=(%| -.result)
~|  %duplicate-ships-rejected
=/  json  (need (de:json:html '{"action":"owners","owners":[{"ship":"~zod","owner":"0x0000000000000000000000000000000000000001"},{"ship":"~zod","owner":"0x0000000000000000000000000000000000000001"}]}'))
=/  result  (act st now ~nec ~nec json)
?>  ?=(%| -.result)
~|  %empty-nft-snapshot-is-valid
=/  json  (need (de:json:html '{"action":"nfts","collection":"example","tokens":[]}'))
=/  result  (act st now ~nec ~nec json)
?>  ?=(%& -.result)
?>  fixtures.p.result
~|  %stale-rpc-snapshot-rejected
=/  json  (need (de:json:html '{"action":"snapshot","collection":"example","chain":"8453","contract":"0x0000000000000000000000000000000000000abc","observedAt":"0","block":"42","blockHash":"0x123","tokens":[]}'))
=/  result  (act st now ~nec ~nec json)
?>  ?=(%| -.result)
~|  %valid-rpc-checkpoint
=/  unix  (div (sub now ~1970.1.1) ~s1)
=/  timestamp  (crip (skim (trip (scot %ud unix)) |=(ch=@t !=(ch '.'))))
=/  snap
  %-  pairs:enjs:format
  :~  action+s+'snapshot'  collection+s+'example'  chain+s+'8453'
      contract+s+'0x0000000000000000000000000000000000000abc'
      'observedAt'^s+timestamp  block+s+'42'
      'blockHash'^s+'0x1111111111111111111111111111111111111111111111111111111111111111'
      epoch+s+'0x1'
      coverage+(pairs:enjs:format ~[method+s+'events-supply' 'fromBlock'^s+'1' supply+s+'0' 'codeHash'^s+'0xabc'])
      tokens+a+~
  ==
=/  result  (act st now ~nec ~nec snap)
?>  ?=(%& -.result)
=/  indexed  p.result
?>  =(42 height:(~(got by checkpoints.indexed) %example))
?>  !fixtures.indexed
?>  ?=([%o *] snap)
~|  %checkpoint-regression-rejected
=/  result  (act indexed now ~nec ~nec snap(p (~(put by p.snap) 'block' s+'41')))
?>  ?=(%| -.result)
~|  %checkpoint-hash-change-rejected
=/  result  (act indexed now ~nec ~nec snap(p (~(put by p.snap) 'blockHash' s+'0x2222222222222222222222222222222222222222222222222222222222222222')))
?>  ?=(%| -.result)
~|  %wrong-chain-snapshot-rejected
=/  result  (act st now ~nec ~nec snap(p (~(put by p.snap) 'chain' s+'1')))
?>  ?=(%| -.result)
~|  %full-uint256-token-import
=/  maximum  (dec (bex 256))
=/  token-text  (crip (skim (trip (scot %ud maximum)) |=(ch=@t !=(ch '.'))))
=/  row  (pairs:enjs:format ~[id+s+token-text owner+s+'0x0000000000000000000000000000000000000001'])
=/  json  (pairs:enjs:format ~[action+s+'nfts' collection+s+'example' tokens+a+~[row]])
=/  result  (act st now ~nec ~nec json)
?>  ?=(%& -.result)
?>  (~(has by tokens.p.result) [%example maximum])
~|  %public-routes-are-open
?>  (levy `(list @tas)`~[%landing %landing-js %style] |=(target=@tas =(200 (access target req(authenticated |) (bex 100) ~nec))))
~|  %configuration-routes-reject-anonymous
?>  (levy `(list @tas)`~[%config %config-js %config-state %config-action] |=(target=@tas =(403 (access target req(authenticated |) (bex 100) ~nec))))
~|  %configuration-routes-reject-remote-ships
?>  (levy `(list @tas)`~[%config %config-js %config-state %config-action] |=(target=@tas &(=(403 (access target req(authenticated |) ~zod ~nec)) =(403 (access target req(authenticated &) ~zod ~nec)))))
~|  %configuration-routes-require-host-session
?>  (levy `(list @tas)`~[%config %config-js %config-state %config-action] |=(target=@tas =(403 (access target req(authenticated |) ~nec ~nec))))
~|  %configuration-routes-allow-authenticated-host
?>  (levy `(list @tas)`~[%config %config-js %config-state %config-action] |=(target=@tas =(200 (access target req(authenticated &) ~nec ~nec))))
~|  %claims-require-a-verified-ship
?>  (levy `(list @tas)`~[%claim %claim-js %me %action %wallet-challenge] |=(target=@tas &(=(401 (access target req(authenticated |) (bex 100) ~nec)) =(401 (access target req(authenticated |) ~nec ~nec)) =(200 (access target req(authenticated |) ~zod ~nec)) =(200 (access target req(authenticated &) ~nec ~nec)))))
~|  %path-and-extension-aliases-are-not-routes
?>  (levy `(list @t)`~['/gater/x/config' '/gater/config.json' '/gater/config.js.map' '/gater/action.json' '/gater/app.js' '/gater/missing' '/gater/claim.js/anything' '/gater/config//state'] |=(url=@t =(%missing (route url))))
?>  =(404 (access %missing req(authenticated &) ~nec ~nec))
~|  %exact-routes-with-query-parameters
?>  =(%landing (route '/gater?collection=example'))
?>  =(%claim (route '/gater/claim/?collection=example'))
?>  =(%config (route '/gater/config/'))
?>  =(%config-state (route '/gater/config/state?ignored=yes'))
~|  %login-return-accepts-only-a-collection-hint
?>  =('/gater?collection=example' (landing-url '/gater/claim?collection=example&redirect=https://evil.example'))
?>  =('/gater' (landing-url '/gater/claim?collection=https://evil.example'))
?>  =('/gater' (landing-url '/gater/claim?redirect=https://evil.example'))
~|  %claim-endpoint-rejects-host-actions
?>  (levy `(list @t)`~['claim' 'release' 'reassign' 'wallet-claim'] |=(action=@t (allowed-action %action (pairs:enjs:format ~[action+s+action]))))
?>  (levy `(list @t)`~['configure' 'settings' 'owners' 'nfts' 'snapshot' 'suppress' 'unsuppress' 'source-error'] |=(action=@t !(allowed-action %action (pairs:enjs:format ~[action+s+action]))))
~|  %configuration-endpoint-rejects-claim-actions
?>  (levy `(list @t)`~['configure' 'settings' 'owners' 'nfts' 'snapshot' 'suppress' 'unsuppress' 'source-error'] |=(action=@t (allowed-action %config-action (pairs:enjs:format ~[action+s+action]))))
?>  (levy `(list @t)`~['claim' 'release' 'reassign' 'wallet-claim'] |=(action=@t !(allowed-action %config-action (pairs:enjs:format ~[action+s+action]))))
?>  !(allowed-action %action ~)
~|  %member-view-has-no-configuration-even-for-host
=/  member  (claim-view st now ~nec ~nec)
?>  ?=([%o *] member)
?>  (levy `(list @t)`~['outbox' 'baseUrl' 'azimuthAuto' 'fixtures' 'admin' 'azimuthStatus'] |=(key=@t !(~(has by p.member) key)))
=/  cols  (~(got by p.member) 'collections')
?>  ?=([%a *] cols)
?>  ?=(^ p.cols)
=/  col  i.p.cols
?>  ?=([%o *] col)
?>  (levy `(list @t)`~['contract' 'recognition' 'removeMembership' 'message' 'role' 'source' 'checkpoint'] |=(key=@t !(~(has by p.col) key)))
~|  %configuration-view-retains-host-data
=/  admin  (config-view st now ~nec ~nec)
?>  ?=([%o *] admin)
?>  (levy `(list @t)`~['outbox' 'baseUrl' 'azimuthAuto' 'collections'] |=(key=@t (~(has by p.admin) key)))
(pure:m !>([%gater-actions-tests 32 %passed]))
