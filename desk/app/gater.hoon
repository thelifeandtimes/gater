/-  *gater
/+  default-agent, server, web=gater-http, policy=gater-policy, actions=gater-actions, sources=gater-sources, wallet=gater-wallet
|%
+$  card  card:agent:gall
++  pull-azimuth
  |=  [input=state bowl=bowl:gall]
  ^-  state
  ?.  azimuth-auto.input  input
  ?.  =(%observed azimuth-status.input)  input
  ?.  .^(? %gu /(scot %p our.bowl)/azimuth/(scot %da now.bowl)/$)
    input(azimuth-watch |, azimuth-status %gap, azimuth-at ~2000.1.1)
  ::  Local %azimuth includes effective L2 ownership. This is an observed
  ::  snapshot, not a finality proof; the alpha transport stays preview-only.
  =/  index=owner-index:sources
    .^(owner-index:sources %gx /(scot %p our.bowl)/azimuth/(scot %da now.bowl)/own)
  =/  owners  (invert-owners:policy (owner-addresses:sources index))
  ?:  =(owners owners.input)  input(azimuth-at now.bowl)
  ::  A mismatch means event continuity is not demonstrated. Equal final
  ::  owners cannot validate claims during an unobserved ownership interval.
  input(owners owners, claims ~, azimuth-at now.bowl, revision +(revision.input))
++  ensure-source
  |=  [input=state bowl=bowl:gall]
  ^-  (quip card state)
  ?.  azimuth-auto.input
    :-  ?:(azimuth-watch.input ~[[%pass /azimuth %agent [our.bowl %azimuth] %leave ~]] ~)
    input(azimuth-watch |, azimuth-status %off)
  ?:  azimuth-watch.input  [~ input]
  ?.  .^(? %gu /(scot %p our.bowl)/azimuth/(scot %da now.bowl)/$)
    [~ input(azimuth-status %gap, azimuth-at ~2000.1.1)]
  :-  ~[[%pass /azimuth %agent [our.bowl %azimuth] %watch /event]]
  input(azimuth-watch &, azimuth-status %connecting, azimuth-at ~2000.1.1)
--
^-  agent:gall
=|  st=state
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this |) bowl)
++  on-init
  =.  wake.st  (add now.bowl ~m1)
  =.  azimuth-watch.st  &(azimuth-watch.st (~(has by wex.bowl) [/azimuth our.bowl %azimuth]))
  =^  cards  st  (ensure-source st bowl)
  :_  this
  %+  weld  cards
  ^-  (list card)
  :~  [%pass /eyre %arvo %e %connect [~ /gater] dap.bowl]
      [%pass /timer/(scot %da wake.st) %arvo %b %wait wake.st]
  ==
++  on-save  !>(st)
++  on-load
  |=  old=vase
  =/  raw  !<(* old)
  =.  st  ?:(?=([%0 *] raw) (migrate:sources !<(state-0 old)) !<(state old))
  on-init
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+  mark  ~|(unsupported-gater-poke+mark !!)
      %json
    =/  result  (act:actions st now.bowl src.bowl our.bowl !<(json vase))
    ?>  ?=(%& -.result)
    =^  cards  st  (ensure-source p.result bowl)
    [cards this(st (reconcile:policy (pull-azimuth st bowl) now.bowl))]
      %handle-http-request
    =+  !<([id=@ta req=inbound-request:eyre] vase)
    =/  target  (route:web url.request.req)
    =/  access  (access:web target req src.bowl our.bowl)
    ?.  =(access 200)
      :_  this
      %+  give-simple-payload:app:server  id
      ?:  &(=(access 401) =(target %claim) =(method.request.req %'GET'))
        (redirect:web (landing-url:web url.request.req))
      (error:web access ?:(=(access 403) 'Configuration is only available to the authenticated host.' ?:(=(access 401) 'Sign in with EAuth to claim membership.' 'Unknown endpoint.')))
    ?:  =(method.request.req %'GET')
      :_  this
      %+  give-simple-payload:app:server  id
      ?+  target  (error:web 404 'Unknown endpoint.')
        %me            (response:web 200 (claim-view:web st now.bowl src.bowl our.bowl))
        %config-state  (response:web 200 (config-view:web st now.bowl src.bowl our.bowl))
        %landing       (static:web bowl 'text/html' /web/index/html)
        %claim         (static:web bowl 'text/html' /web/claim/html)
        %config        (static:web bowl 'text/html' /web/config/html)
        %landing-js    (static:web bowl 'text/javascript' /web/landing/js)
        %claim-js      (static:web bowl 'text/javascript' /web/claim/js)
        %config-js     (static:web bowl 'text/javascript' /web/config/js)
        %style         (static:web bowl 'text/css' /web/style/css)
      ==
    ?.  &(=(method.request.req %'POST') ?=(?(%action %config-action %wallet-challenge) target))
      [(give-simple-payload:app:server id (error:web 404 'Unknown endpoint.')) this]
    ?.  (csrf:web req)
      [(give-simple-payload:app:server id (error:web 403 'Use an authenticated same-origin request.')) this]
    ?~  body.request.req
      [(give-simple-payload:app:server id (error:web 400 'Missing JSON body.')) this]
    ?:  (gth p.u.body.request.req 2.000.000)
      [(give-simple-payload:app:server id (error:web 413 'Request too large.')) this]
    ?~  jon=(de:json:html q.u.body.request.req)
      [(give-simple-payload:app:server id (error:web 400 'Invalid JSON.')) this]
    ?:  =(target %wallet-challenge)
      =/  challenge  (challenge:wallet st now.bowl src.bowl our.bowl u.jon)
      :_  this
      %+  give-simple-payload:app:server  id
      ?-  -.challenge
        %|  (error:web 409 p.challenge)
        %&  (response:web 200 p.challenge)
      ==
    ?.  (allowed-action:web target u.jon)
      [(give-simple-payload:app:server id (error:web 403 'This action is not available at this endpoint.')) this]
    =/  result  (act:actions st now.bowl src.bowl our.bowl u.jon)
    ?-  -.result
      %|  [(give-simple-payload:app:server id (error:web 409 p.result)) this]
      %&  =.  st  (reconcile:policy (pull-azimuth p.result bowl) now.bowl)
          =^  cards  st  (ensure-source st bowl)
          =/  view  ?:(=(target %config-action) config-view:web claim-view:web)
          [(weld cards (give-simple-payload:app:server id (response:web 200 (view st now.bowl src.bowl our.bowl)))) this]
    ==
  ==
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?>  ?=([%http-response *] path)
  [~ this]
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?>  =(src.bowl our.bowl)
  ?+  path  [~ ~]
    [%x %state ~]  ``json+!>((config-view:web st now.bowl our.bowl our.bowl))
  ==
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?:  =(/timer/(scot %da wake.st) wire)
    =.  st  (reconcile:policy (pull-azimuth st bowl) now.bowl)
    =^  cards  st  (ensure-source st bowl)
    =.  wake.st  (add now.bowl ~m1)
    [[[%pass /timer/(scot %da wake.st) %arvo %b %wait wake.st] cards] this]
  [~ this]
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card agent:gall)
  ?.  =(/azimuth wire)  (on-agent:def wire sign)
  ?.  azimuth-auto.st  [~ this]
  ?:  |(?=(%kick -.sign) &(?=(%watch-ack -.sign) ?=(^ p.sign)))
    [~ this(st st(azimuth-watch |, azimuth-status %gap, azimuth-at ~2000.1.1))]
  ?.  ?=(%fact -.sign)  [~ this]
  ?:  =(%naive-state p.cage.sign)
    =+  !<([nas=* own=owner-index:sources spo=*] q.cage.sign)
    =.  st  (observe-snapshot:sources st (owner-addresses:sources own) now.bowl)
    [~ this(st (reconcile:policy st now.bowl))]
  ?.  &(=(%naive-diffs p.cage.sign) =(%observed azimuth-status.st))  [~ this]
  =/  event  !<(* q.cage.sign)
  ?.  ?=([%point @ %owner @] event)  [~ this]
  =/  [tag=@tas who=ship kind=@tas owner=@ux]  event
  =.  st  (observe-owner:sources st who owner now.bowl)
  [~ this(st (reconcile:policy st now.bowl))]
++  on-leave  on-leave:def
++  on-fail  on-fail:def
--
