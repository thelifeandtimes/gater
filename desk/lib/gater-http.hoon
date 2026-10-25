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
++  static
  |=  [bowl=bowl:gall ct=@t pax=path]
  ^-  simple-payload:http
  =/  dat=@  .^(@ %cx :(weld /(scot %p our.bowl)/[dap.bowl]/(scot %da now.bowl) pax))
  [[200 ~[['content-type' ct] ['cache-control' 'no-store'] ['x-content-type-options' 'nosniff'] ['content-security-policy' (crip "default-src 'self'; script-src 'self'; style-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'")]]] `[(met 3 dat) dat]]
++  view
  |=  [st=state now=@da who=ship host=ship]
  ^-  json
  =/  cols=json
    :-  %a
    %+  turn  ~(tap by collections.st)
    |=  [id=@tas cfg=collection]
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
        'removeMembership'^b+kick.cfg  tokens+tokens
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
      'baseUrl'^s+base-url.st
  ==
--
