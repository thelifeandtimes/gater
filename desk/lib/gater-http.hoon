/-  *gater
/+  server, j=gater-json, policy=gater-policy
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
  ?+  target  %missing
    %'/gater'                %landing
    %'/gater/'               %landing
    %'/gater/claim'          %claim
    %'/gater/claim/'         %claim
    %'/gater/config'         %config
    %'/gater/config/'        %config
    %'/gater/landing.js'     %landing-js
    %'/gater/claim.js'       %claim-js
    %'/gater/config.js'      %config-js
    %'/gater/style.css'      %style
    %'/gater/me'             %me
    %'/gater/action'         %action
    %'/gater/wallet-challenge'  %wallet-challenge
    %'/gater/config/state'   %config-state
    %'/gater/config/action'  %config-action
  ==
++  access
  |=  [target=@tas req=inbound-request:eyre who=ship host=ship]
  ^-  @ud
  ?:  ?=(?(%landing %landing-js %style) target)  200
  ?:  ?=(?(%config %config-js %config-state %config-action) target)
    ?:((host-session req who host) 200 403)
  ?:  ?=(?(%claim %claim-js %me %action %wallet-challenge) target)
    ?:((signed-in req who host) 200 401)
  404
++  allowed-action
  |=  [target=@tas jon=json]
  ^-  ?
  =/  action  (str:j jon 'action')
  ?:  =(target %action)  ?=(?(%claim %release %reassign %wallet-claim) action)
  &(=(target %config-action) ?=(?(%configure %settings %owners %nfts %snapshot %source-error %suppress %unsuppress) action))
++  redirect
  |=  location=@t
  ^-  simple-payload:http
  [[303 ~[['location' location] ['cache-control' 'no-store']]] ~]
++  landing-url
  |=  url=@t
  ^-  @t
  =/  args  args:(parse-request-line:server url)
  |-
  ?~  args  '/gater'
  ?.  =('collection' key.i.args)  $(args t.args)
  ?~  col=(slaw %tas value.i.args)  '/gater'
  (cat 3 '/gater?collection=' u.col)
++  static
  |=  [bowl=bowl:gall ct=@t pax=path]
  ^-  simple-payload:http
  =/  dat=@  .^(@ %cx :(weld /(scot %p our.bowl)/[dap.bowl]/(scot %da now.bowl) pax))
  [[200 ~[['content-type' ct] ['cache-control' 'no-store'] ['x-content-type-options' 'nosniff'] ['content-security-policy' (crip "default-src 'self'; script-src 'self'; style-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'")]]] `[(met 3 dat) dat]]
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
      (pairs:enjs:format ~[id+s+(decimal:j token.key) ship+?~(cl ~ s+(scot %p who.u.cl))])
    %-  pairs:enjs:format
    :~  id+s+id  name+s+name.cfg  chain+s+(decimal:j chain.cfg)
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
    :~  id+s+(decimal:j id)  action+s+kind.op  group+s+group.seat.op
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
