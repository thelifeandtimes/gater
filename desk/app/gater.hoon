/-  *gater
/+  default-agent, server, web=gater-http, policy=gater-policy, actions=gater-actions
|%
+$  card  card:agent:gall
++  pull-azimuth
  |=  [input=state bowl=bowl:gall]
  ^-  state
  ?.  azimuth-auto.input  input
  ?.  .^(? %gu /(scot %p our.bowl)/azimuth/$)  input
  ::  Local %azimuth includes effective L2 ownership. This is an observed
  ::  snapshot, not a finality proof; the alpha transport stays preview-only.
  =/  index=(map @ux (set ship))
    .^((map @ux (set ship)) %gx /(scot %p our.bowl)/azimuth/own)
  =/  owners  (invert-owners:policy index)
  (prune:policy input(owners owners, azimuth-at now.bowl, revision (add revision.input ?:(=(owners owners.input) 0 1))))
--
^-  agent:gall
=|  st=state
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this |) bowl)
++  on-init
  =.  wake.st  (add now.bowl ~m1)
  :_  this
  :~  [%pass /eyre %arvo %e %connect [~ /gater] dap.bowl]
      [%pass /timer/(scot %da wake.st) %arvo %b %wait wake.st]
  ==
++  on-save  !>(st)
++  on-load
  |=  old=vase
  =.  st  !<(state old)
  on-init
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+  mark  ~|(unsupported-gater-poke+mark !!)
      %json
    =/  result  (act:actions st now.bowl src.bowl our.bowl !<(json vase))
    ?>  ?=(%& -.result)
    [~ this(st (reconcile:policy (pull-azimuth p.result bowl) now.bowl))]
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
    ?.  &(=(method.request.req %'POST') ?=(?(%action %config-action) target))
      [(give-simple-payload:app:server id (error:web 404 'Unknown endpoint.')) this]
    ?.  (csrf:web req)
      [(give-simple-payload:app:server id (error:web 403 'Use an authenticated same-origin request.')) this]
    ?~  body.request.req
      [(give-simple-payload:app:server id (error:web 400 'Missing JSON body.')) this]
    ?:  (gth p.u.body.request.req 2.000.000)
      [(give-simple-payload:app:server id (error:web 413 'Request too large.')) this]
    ?~  jon=(de:json:html q.u.body.request.req)
      [(give-simple-payload:app:server id (error:web 400 'Invalid JSON.')) this]
    ?.  (allowed-action:web target u.jon)
      [(give-simple-payload:app:server id (error:web 403 'This action is not available at this endpoint.')) this]
    =/  result  (act:actions st now.bowl src.bowl our.bowl u.jon)
    ?-  -.result
      %|  [(give-simple-payload:app:server id (error:web 409 p.result)) this]
      %&  =.  st  (reconcile:policy (pull-azimuth p.result bowl) now.bowl)
          =/  view  ?:(=(target %config-action) config-view:web claim-view:web)
          [(give-simple-payload:app:server id (response:web 200 (view st now.bowl src.bowl our.bowl))) this]
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
    =.  wake.st  (add now.bowl ~m1)
    [[[%pass /timer/(scot %da wake.st) %arvo %b %wait wake.st] ~] this]
  [~ this]
++  on-agent  on-agent:def
++  on-leave  on-leave:def
++  on-fail  on-fail:def
--
