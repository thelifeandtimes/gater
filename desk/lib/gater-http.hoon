/-  *gater
/+  server, j=gater-json, policy=gater-policy, community=gater-community
|%
++  response
  |=  [code=@ud jon=json]
  ^-  simple-payload:http
  [[code ~[['content-type' 'application/json'] ['cache-control' 'no-store'] ['x-content-type-options' 'nosniff']]] `(as-octs:mimes:html (en:json:html jon))]
++  error
  |=  [code=@ud text=@t]
  (response code (pairs:enjs:format ~[error+s+text]))
++  header
  |=  [key=@t heads=header-list:http]
  ^-  (unit @t)
  ?~  heads  ~
  ?:  =((cass (trip key)) (cass (trip key.i.heads)))  `value.i.heads
  $(heads t.heads)
++  csrf
  |=  req=inbound-request:eyre
  ^-  ?
  =/  heads  header-list.request.req
  ?.  =(`'1' (header 'x-gater' heads))  |
  ?~  host=(header 'host' heads)  |
  ?~  origin=(header 'origin' heads)  |
  |(=(u.origin (cat 3 'https://' u.host)) =(u.origin (cat 3 'http://' u.host)))
++  signed-in
  |=  [req=inbound-request:eyre who=ship host=ship]
  ^-  ?
  ::  Eyre's authenticated flag is only true for the local host. EAuth
  ::  delivers the verified remote ship as src.bowl. Anonymous sessions get
  ::  a comet-sized identity. This app admits only Azimuth-sized identities.
  ?:  =(who host)  authenticated.req
  (lte who 0xffff.ffff)
++  host-session
  |=  [req=inbound-request:eyre who=ship host=ship]
  ^-  ?
  &(=(who host) authenticated.req)
++  route
  |=  url=@t
  ^-  @tas
  ::  Match the entire path, not its last segment or extension-stripped name.
  =/  chars  (trip url)
  =/  target  (crip (scag (fall (find "?" chars) (lent chars)) chars))
  ?+  target
    ?~  id=(collection-id url)  %missing
    ?:  =(target (cat 3 '/gater/' u.id))  %landing
    ?:  =(target (cat 3 (cat 3 '/gater/' u.id) '/'))  %landing
    ?:  =(target (cat 3 (cat 3 '/gater/' u.id) '/claim'))  %claim
    ?:  =(target (cat 3 (cat 3 '/gater/' u.id) '/claim/'))  %claim
    ?:  =(target (cat 3 (cat 3 '/gater/' u.id) '/info'))  %info
    %missing
    %'/gater'                %landing
    %'/gater/'               %landing
    %'/gater/claim'          %claim
    %'/gater/claim/'         %claim
    %'/gater/config'         %config
    %'/gater/config/'        %config
    %'/gater/community.js'   %community-js
    %'/gater/landing.js'     %landing-js
    %'/gater/claim.js'       %claim-js
    %'/gater/artwork.js'     %artwork-js
    %'/gater/config.js'      %config-js
    %'/gater/appearance'     %appearance
    %'/gater/favicon.svg'    %favicon
    %'/gater/style.css'      %style
    %'/gater/me'             %me
    %'/gater/action'         %action
    %'/gater/wallet-challenge'  %wallet-challenge
    %'/gater/config/state'   %config-state
    %'/gater/config/action'  %config-action
  ==
++  collection-id
  |=  url=@t
  ^-  (unit @tas)
  =/  chars  (trip url)
  =/  target  (crip (scag (fall (find "?" chars) (lent chars)) chars))
  ?.  =('/gater/' (end [3 7] target))  ~
  =/  rest  (slag 7 (trip target))
  =/  id  (crip (scag (fall (find "/" rest) (lent rest)) rest))
  ?.  (valid-id:community id)  ~
  (slaw %tas id)
++  access
  |=  [target=@tas req=inbound-request:eyre who=ship host=ship]
  ^-  @ud
  ?:  ?=(?(%landing %landing-js %community-js %style %info %appearance %favicon) target)  200
  ?:  ?=(?(%config %config-js %config-state %config-action) target)
    ?:((host-session req who host) 200 403)
  ?:  ?=(?(%claim %claim-js %artwork-js %me %action %wallet-challenge) target)
    ?:((signed-in req who host) 200 401)
  404
++  allowed-action
  |=  [target=@tas jon=json]
  ^-  ?
  =/  action  (str:j jon 'action')
  ?:  =(target %action)  ?=(?(%claim %release %wallet-claim) action)
  &(=(target %config-action) ?=(?(%rpc-settings %rpc-bootstrap %audit-azimuth %retry-delivery %recheck-delivery %delivery-settings %approve-effect %configure %delete-collection %create-group %create-role %settings %owners %nfts %snapshot %source-error %suppress %unsuppress) action))
++  redirect
  |=  location=@t
  ^-  simple-payload:http
  [[303 ~[['location' location] ['cache-control' 'no-store']]] ~]
++  landing-url
  |=  url=@t
  ^-  @t
  ?^  id=(collection-id url)  (cat 3 '/gater/' u.id)
  =/  args  args:(parse-request-line:server url)
  |-
  ?~  args  '/gater'
  ?.  =('collection' key.i.args)  $(args t.args)
  ?~  col=(slaw %tas value.i.args)  '/gater'
  (cat 3 '/gater?collection=' u.col)
++  content-security-policy
  |=  pax=path
  ^-  @t
  =/  base
    (cat 3 ?:(=(pax /web/claim/html) (crip "default-src 'self'; script-src 'self'; connect-src 'self' https:;") (crip "default-src 'self'; script-src 'self'; connect-src 'self' https://api.fxtwitter.com;")) (crip " style-src 'self'; font-src 'self' http: https:; img-src 'self' http: https:; frame-ancestors 'none'; base-uri 'none'; form-action 'self'"))
  ::  Eyre redirects the login POST to the claimant's discovered HTTP(S)
  ::  endpoint. Browsers also check form-action on that redirect. Only the
  ::  public login document needs foreign form navigation; authenticated
  ::  claim/configuration documents keep the same-origin restriction.
  ?:  =(pax /web/index/html)  (cat 3 base ' http: https:')
  base
++  static
  |=  [bowl=bowl:gall ct=@t pax=path]
  ^-  simple-payload:http
  =/  dat=@  .^(@ %cx :(weld /(scot %p our.bowl)/[dap.bowl]/(scot %da now.bowl) pax))
  [[200 ~[['content-type' ct] ['cache-control' 'no-store'] ['x-content-type-options' 'nosniff'] ['content-security-policy' (content-security-policy pax)]]] `[(met 3 dat) dat]]
++  claim-view
  |=  [st=state now=@da who=ship host=ship]
  ^-  json
  =/  cols=json
    :-  %a
    %+  turn  ~(tap by collections.st)
    |=  [id=@tas cfg=collection]
    =/  tokens=json
      :-  %a
      %+  turn  (holdings:policy st who id)
      |=  key=asset
      =/  cl  (~(get by claims.st) key)
      (pairs:enjs:format ~[id+s+(decimal:j token.key) ship+?~(cl ~ s+(scot %p who.u.cl)) owner+s+(scot %ux (~(got by tokens.st) key)) generation+s+(decimal:j (~(gut by token-generations.st) key 0)) revision+s+(decimal:j (claim-revision:policy st who key))])
    =/  checkpoint  (~(get by checkpoints.st) id)
    %-  pairs:enjs:format
    :~  id+s+id  name+s+name.cfg  chain+s+(decimal:j chain.cfg)
        contract+s+(addr:j contract.cfg)
        checkpoint+?~(checkpoint ~ s+(decimal:j height.u.checkpoint))
        group+s+group.cfg  fresh+b+(fresh:policy st now id)  tokens+tokens
    ==
  %-  pairs:enjs:format
  :~  ship+s+(scot %p who)  host+s+(scot %p host)
      revision+s+(decimal:j revision.st)  live+b+live.st  collections+cols
  ==
++  config-view
  |=  [st=state now=@da who=ship host=ship]
  ^-  json
  =/  cols=json
    :-  %a
    %+  turn  ~(tap by collections.st)
    |=  [id=@tas cfg=collection]
    =/  source  (~(get by nft-sources.st) id)
    =/  checkpoint  (~(get by checkpoints.st) id)
    =/  provenance=json
      ?~  source  ~
      %-  pairs:enjs:format
      :~  healthy+b+healthy.u.source  method+s+method.u.source
          epoch+s+(hex:j epoch.u.source)  'fromBlock'^s+(decimal:j start.u.source)
          supply+s+(decimal:j supply.u.source)
      ==
    =/  owned  (holdings:policy st who id)
    =/  tokens=json
      :-  %a
      %+  turn  owned
      |=  key=asset
      =/  cl  (~(get by claims.st) key)
      (pairs:enjs:format ~[id+s+(decimal:j token.key) ship+?~(cl ~ s+(scot %p who.u.cl))])
    %-  pairs:enjs:format
    :~  id+s+id  name+s+name.cfg  chain+s+(decimal:j chain.cfg)
        contract+s+(addr:j contract.cfg)  group+s+group.cfg  role+s+role.cfg
        fresh+b+(fresh:policy st now id)  recognition+s+recognition.cfg
        'removeMembership'^b+kick.cfg  message+s+message.cfg  tokens+tokens
        source+provenance  checkpoint+?~(checkpoint ~ s+(decimal:j height.u.checkpoint))
    ==
  =/  out=json
    ?.  =(who host)  [%a ~]
    :-  %a
    %+  turn  ~(tap by effects.st)
    |=  [id=@ud ef=effect]
    =/  op  operation.ef
    %-  pairs:enjs:format
    :~  id+s+(decimal:j id)  fingerprint+s+(hex:j (shax (jam op)))  action+s+kind.op  group+s+group.seat.op
        ship+s+(scot %p who.seat.op)  roles+a+(turn ~(tap in roles.op) |=(r=@tas s+r))
        text+s+text.op  status+s+status.ef
    ==
  %-  pairs:enjs:format
  :~  ship+s+(scot %p who)  host+s+(scot %p host)  admin+b+=(who host)
      revision+s+(decimal:j revision.st)  live+b+live.st  fixtures+b+fixtures.st
      collections+cols  outbox+out  'azimuthAuto'^b+azimuth-auto.st
      'baseUrl'^s+base-url.st  'azimuthStatus'^s+azimuth-status.st
  ==
--
