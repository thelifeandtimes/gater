/-  *gater
/+  default-agent, server, web=gater-http, policy=gater-policy, actions=gater-actions, sources=gater-sources, wallet=gater-wallet, delivery=gater-delivery, j=gater-json, community=gater-community, presentation=gater-presentation, audit=gater-audit, rpc=gater-rpc
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
  ::  snapshot, not a finality proof; production delivery requires an audit.
  =/  index=owner-index:sources
    .^(owner-index:sources %gx /(scot %p our.bowl)/azimuth/(scot %da now.bowl)/own/noun)
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
=|  transport=ledger:delivery
=|  ui=settings:community
=|  proof=proof:audit
=|  control=controls:delivery
=|  native=store:rpc
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this |) bowl)
    admin-view
      =/  view  (decorate:community (config-view:web st now.bowl our.bowl our.bowl) ui (registry:community bowl) our.bowl)
      ?>  ?=([%o *] view)
      =.  p.view  (~(put by p.view) 'bootstrap' (bootstrap-info:rpc native bowl))
      =.  p.view  (~(put by p.view) 'rpc' (status-json:rpc native))
      =.  p.view  (~(put by p.view) 'hostUrls' (hosts:presentation bowl))
      =.  p.view  (~(put by p.view) 'ownershipAudit' (view:audit proof now.bowl))
      =.  p.view  (~(put by p.view) 'delivery' (view:delivery transport))
      =.  p.view  (~(put by p.view) 'automatic' b+automatic.control)
      =.  p.view  (~(put by p.view) 'targets' a+(turn ~(tap in targets.transport) |=(who=ship s+(scot %p who))))
      (decorate:delivery view st control)
    dispatch
      =^  st  transport  (pending:delivery st transport)
      =/  remaining  8
      |-
      =/  result=[cards=(list card) next=state log=ledger:delivery]
        (step:delivery st transport bowl &((fresh-proof:audit proof now.bowl) !fixtures.st azimuth-auto.st) control)
      =/  approvals  approvals.control
      =?  approvals  ?=(^ active.log.result)
        (~(del in approvals) requested.u.active.log.result)
      =/  old-receipts  (silt (turn history.transport |=(r=receipt:delivery id.r)))
      =.  approvals
        %+  roll  (skim history.log.result |=(r=receipt:delivery !(~(has in old-receipts) id.r)))
        |=  [receipt=receipt:delivery out=(set operation)]
        (~(del in out) op.receipt)
      =.  control  control(approvals approvals)
      ::  Continue observed completions immediately (revoke -> kick -> DM),
      ::  yielding as soon as a new command is issued or progress stops.
      ?:  &((gth remaining 0) =(~ cards.result) ?=(~ active.log.result) !=(history.transport history.log.result))
        $(remaining (dec remaining), st next.result, transport log.result)
      [cards.result this(st next.result, transport log.result)]
    native-wait
      ^-  (quip card _this)
      [~[[%pass /native-tick/(scot %da due.native) %arvo %b %wait due.native]] this]
    native-failed
      |=  message=@t
      ^-  (quip card _this)
      =/  current=store:rpc  native
      ?~  work.current  [~ this]
      =/  w  u.work.current
      =/  key  ?:(=(kind.w %azimuth) %azimuth col.w)
      =.  errors.native  (~(put by errors.native) key message)
      =?  at.proof  =(kind.w %azimuth)  ~2000.1.1
      ::  Keep the last committed checkpoint. A failed NFT read pauses claims;
      ::  no partial result can prune claims or refresh verification timestamps.
      =?  nft-sources.st  &(=(kind.w %nft) (~(has by nft-sources.st) col.w))
        =/  src  (~(got by nft-sources.st) col.w)
        (~(put by nft-sources.st) col.w src(healthy |))
      =.  this  this(native native(sent |, serial +(serial.native)))
      ?:  (gte attempts.w 5)
        =.  this  this(native native(work ~, due (add now.bowl ~s1)))
        native-wait
      =.  w  w(attempts +(attempts.w))
      =?  w  &(=(stage.w %logs) (gth window.w 1))
        (log-request:rpc w(window (max 1 (div window.w 2))))
      =.  this  this(native native(work `w, due (add now.bowl (mul ~s2 (bex attempts.w)))))
      native-wait
    native-pump
      ^-  (quip card _this)
      |-
      =/  current=store:rpc  native
      ?:  (lth now.bowl due.native)  native-wait
      ?:  sent.native
        =/  old-wire  /native-rpc/(scot %ud serial.native)
        =^  cards  this  (native-failed 'RPC timed out. Retrying with bounded backoff; check provider availability and limits.')
        [[[%pass old-wire %arvo %i %cancel-request ~] cards] this]
      ?~  work.current
        =/  todo=(list (unit @tas))
          ?~  queue.native  [~ (turn ~(tap by collections.st) |=([id=@tas c=collection] `id))]
          queue.native
        ?>  ?=(^ todo)
        =/  selected  i.todo
        =.  queue.native  t.todo
        =/  chain
          ?~  selected  1
          =/  c  (~(get by collections.st) u.selected)
          ?~  c  0
          chain.u.c
        ?:  |(=(chain 0) =((endpoint:rpc native chain) '') &(?=(~ selected) !azimuth-auto.st))
          =.  due.native  (add now.bowl ?:(?=(~ queue.native) ~m1 ~s1))
          native-wait
        =/  initialized
          %-  mule
          |.
          ?:  ?=(^ selected)  [(start:rpc native st selected now.bowl) bootstrap.native]
          =/  snap  ?~(bootstrap.native (snapshot-now:audit bowl) u.bootstrap.native)
          ?>  =([number.id.snap hash.id.snap (shax (jam snap))] [height.anchor.native hash.anchor.native digest.anchor.native])
          [(start:rpc native st selected now.bowl) `snap]
        ?-  -.initialized
          %|  =.  errors.native  (~(put by errors.native) ?~(selected %azimuth u.selected) 'Cannot initialize verification. Check collection configuration or the reviewed Azimuth bootstrap anchor.')
              =.  due.native  (add now.bowl ?:(?=(~ queue.native) ~m1 ~s1))
              native-wait
          %&  =.  this  this(native native(work `-.p.initialized, bootstrap +.p.initialized))
              $
        ==
      =/  w  u.work.current
      =/  outdated
        ?.  =(kind.w %nft)  |
        =/  c  (~(get by collections.st) col.w)
        ?~  c  &
        |(!=([chain.u.c contract.u.c] [chain.w contract.w]) !=(opts.w (~(gut by indexes.native) col.w (default-options:rpc u.c))))
      ?:  outdated
        =.  this  this(native native(work ~, sent |, due (add now.bowl ~s1)))
        native-wait
      ?:  =(stage.w %done)
        =/  committed
          %-  mule
          |.
          ?:  =(kind.w %nft)
            =/  result  (act:actions st now.bowl our.bowl our.bowl (snapshot-json:rpc w now.bowl))
            ?>  ?=(%& -.result)
            [p.result proof]
          =/  snap  (need bootstrap.native)
          ?>  =([number.id.snap hash.id.snap (shax (jam snap))] [height.anchor.native hash.anchor.native digest.anchor.native])
          =/  result  (commit:audit st proof (replay:audit snap logs.w) now.bowl height.target.w hash.target.w digest.anchor.native)
          ?>  ?=(%& -.result)
          p.result
        ?-  -.committed
          %|  (native-failed 'Verified state could not be committed. Check the bootstrap anchor, collection coverage and checkpoint continuity.')
          %&  =.  st  -.p.committed
              =.  proof  +.p.committed
              =?  caches.native  =(kind.w %nft)
                (~(put by caches.native) col.w [target.w epoch.w code.w bootstrap.w tokens.w ?:(|((gth now.bowl (add checked.w ~h6)) (lth now.bowl checked.w)) now.bowl checked.w)])
              =?  native  =(kind.w %azimuth)
                native(audit-point target.w, audit-logs logs.w)
              =.  errors.native  (~(del by errors.native) ?:(=(kind.w %azimuth) %azimuth col.w))
              =.  this  this(native native(work ~, due (add now.bowl ?:(?=(~ queue.native) ~m1 ~s1))))
              =.  st  (reconcile:policy st now.bowl)
              =^  cards  this  dispatch
              =^  waiting  this  native-wait
              [(weld cards waiting) this]
        ==
      =/  url  (endpoint:rpc native chain.w)
      ?:  =(url '')  (native-failed 'Configure an RPC endpoint for this network.')
      =.  this  this(native native(serial +(serial.native), sent &, due (add now.bowl ~s45)))
      =/  body  (en:json:html (envelope:rpc requests.w serial.native))
      =/  request=request:http  [%'POST' url ~[['Content-Type' 'application/json']] `[(met 3 body) body]]
      =^  cards  this  native-wait
      [[[%pass /native-rpc/(scot %ud serial.native) %arvo %i %request request [0 0]] cards] this]
    native-response
      |=  response=client-response:iris
      ^-  (quip card _this)
      =/  current=store:rpc  native
      ?~  work.current  [~ this]
      ?:  ?=(%progress -.response)
        ?:  (lte bytes-read.response 33.554.432)  [~ this]
        =/  wire  /native-rpc/(scot %ud serial.native)
        =^  cards  this  (native-failed 'RPC response exceeded the size limit. Use a smaller log range or a suitable provider.')
        [[[%pass wire %arvo %i %cancel-request ~] cards] this]
      ?:  ?=(%cancel -.response)  (native-failed 'RPC connection was cancelled. Retrying.')
      ?.  =(200 status-code.response-header.response)
        (native-failed 'RPC returned an HTTP error. Check credentials, supported networks and provider quotas.')
      ?~  full-file.response  (native-failed 'RPC returned an empty response.')
      ?:  (gth p.data.u.full-file.response 33.554.432)
        (native-failed 'RPC response exceeded the size limit.')
      =/  decoded  (de:json:html q.data.u.full-file.response)
      ?~  decoded  (native-failed 'RPC returned invalid JSON.')
      =/  issue  (provider-error:rpc u.decoded)
      ?^  issue  (native-failed u.issue)
      =/  parsed
        %-  mule
        |.
        =/  json  u.decoded
        =/  values  (results:rpc requests.u.work.current serial.native json)
        (advance:rpc u.work.current values now.bowl)
      ?-  -.parsed
        %|  (native-failed 'RPC verification failed. Check chain ID, finalized data, contract coverage and provider limits. No partial state was accepted.')
        %&  =.  this  this(native native(work `p.parsed, sent |, due (add now.bowl ~s1)))
            native-wait
      ==
++  on-init
  =.  this  this(native native(sent |, serial +(serial.native), due (add now.bowl ~s1)))
  =.  wake.st  (add now.bowl ?:(enabled.transport ~s5 ~m1))
  =.  azimuth-watch.st  &(azimuth-watch.st (~(has by wex.bowl) [/azimuth our.bowl %azimuth]))
  =^  cards  st  (ensure-source st bowl)
  =?  cards  ?=(^ work.ui)
    [[%pass /community-check/(scot %ud id.u.work.ui) %arvo %b %wait (add now.bowl ~s1)] cards]
  :_  this
  %+  weld  cards
  ^-  (list card)
  :~  [%pass /native-tick/(scot %da due.native) %arvo %b %wait due.native]
      [%pass /eyre %arvo %e %connect [~ /gater] dap.bowl]
      [%pass /timer/(scot %da wake.st) %arvo %b %wait wake.st]
  ==
++  on-save  !>([%9 st transport ui proof control native])
++  on-load
  |=  old=vase
  =/  raw  !<(* old)
  ?:  ?=([%9 *] raw)
    =+  !<([tag=%9 saved=state saved-transport=ledger:delivery saved-ui=settings:community saved-proof=proof:audit saved-control=controls:delivery saved-native=store:rpc] old)
    =.  st  saved
    =.  transport  saved-transport
    =.  ui  saved-ui
    =.  proof  saved-proof
    =.  control  saved-control
    =.  native  saved-native
    on-init
  ?:  ?=([%8 *] raw)
    =+  !<([tag=%8 saved=state saved-transport=ledger:delivery saved-ui=settings:community saved-proof=proof:audit saved-control=controls:delivery saved-native=store-0:rpc] old)
    =.  st  saved
    =.  transport  saved-transport
    =.  ui  saved-ui
    =.  proof  saved-proof
    =.  control  saved-control
    =.  native  (migrate-store:rpc saved-native)
    on-init
  ?:  ?=([%7 *] raw)
    =+  !<([tag=%7 saved=state saved-transport=ledger:delivery saved-ui=settings:community saved-proof=proof:audit saved-control=controls:delivery] old)
    =.  st  saved
    =.  transport  saved-transport
    =.  ui  saved-ui
    =.  proof  saved-proof
    =.  control  saved-control
    on-init
  ?:  ?=([%6 *] raw)
    =+  !<([tag=%6 saved=state saved-transport=ledger-6:delivery saved-ui=settings:community saved-proof=proof:audit saved-control=controls-6:delivery] old)
    =.  st  saved
    =.  transport  (migrate:delivery saved-transport)
    =.  ui  saved-ui
    =.  proof  saved-proof
    =.  control  control(approvals approvals.saved-control)
    on-init
  ?:  ?=([%5 *] raw)
    =+  !<([tag=%5 saved=state saved-transport=ledger-6:delivery saved-ui=settings:community saved-media=cache:presentation saved-proof=proof:audit saved-control=controls-6:delivery] old)
    =.  st  saved
    =.  transport  (migrate:delivery saved-transport)
    =.  ui  saved-ui
    ::  Discard legacy display metadata; artwork now stays in the browser.
    =.  proof  ?:(=(0 height.saved-proof) saved-proof(enabled |) saved-proof)
    =.  control  control(approvals approvals.saved-control)
    on-init
  ?:  ?=([%4 *] raw)
    =+  !<([tag=%4 saved=state saved-transport=ledger-6:delivery saved-ui=settings:community saved-media=cache:presentation] old)
    =.  st  saved
    =.  transport  (migrate:delivery saved-transport)
    =.  ui  saved-ui
    on-init
  ?:  ?=([%3 *] raw)
    =+  !<([tag=%3 saved=state saved-transport=ledger-6:delivery saved-ui=settings-3:community] old)
    =.  st  saved
    =.  transport  (migrate:delivery saved-transport)
    =.  ui  (migrate-settings:community saved-ui)
    on-init
  ?:  ?=([%2 *] raw)
    =+  !<([tag=%2 saved=state saved-transport=ledger-6:delivery] old)
    =.  st  saved
    =.  transport  (migrate:delivery saved-transport)
    on-init
  =.  st  ?:(?=([%0 *] raw) (migrate:sources !<(state-0 old)) !<(state old))
  on-init
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+  mark  ~|(unsupported-gater-poke+mark !!)
      %json
    =/  input  !<(json vase)
    ?:  =('test-transport' (str:j input 'action'))
      ?>  =(src.bowl our.bowl)
      ~|  %transport-requires-fake-ship
      ?>  .^(? %j /(scot %p our.bowl)/fake/(scot %da now.bowl))
      =?  this  &((bool:j input 'clearFailed' |) ?=(^ active.transport))
        =/  work  (need active.transport)
        ~|  %only-negative-acknowledgments-can-be-cleared
        ?>  =(phase.work %failed)
        this(st st(effects (~(del by effects.st) id.work)), transport transport(active ~))
      =/  targets
        %+  turn  (array:j (get:j input 'targets'))
        |=(item=json ?>(?=([%s *] item) (slav %p p.item)))
      ?>  !(lien targets |=(who=ship =(who our.bowl)))
      =.  transport  transport(enabled (bool:j input 'enabled' |), targets (silt targets))
      =^  sent  this  dispatch
      =.  wake.st  (add now.bowl ?:(enabled.transport ~s5 ~m1))
      [[[%pass /timer/(scot %da wake.st) %arvo %b %wait wake.st] sent] this]
    =/  result  (act:actions st now.bowl src.bowl our.bowl input)
    ?>  ?=(%& -.result)
    =^  cards  st  (ensure-source p.result bowl)
    =.  st  (reconcile:policy ?:(enabled.proof st (pull-azimuth st bowl)) now.bowl)
    =^  sent  this  dispatch
    [(weld cards sent) this]
      %handle-http-request
    =+  !<([id=@ta req=inbound-request:eyre] vase)
    =/  target  (route:web url.request.req)
    =/  selected  (collection-id:web url.request.req)
    ?:  ?~(selected | !(~(has by collections.st) u.selected))
      [(give-simple-payload:app:server id (error:web 404 'This community is not configured.')) this]
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
        %config-state  (response:web 200 admin-view)
        %info          (response:web 200 (public-info:community st ui (need selected)))
        %landing       (static:web bowl 'text/html' /web/index/html)
        %claim         (static:web bowl 'text/html' /web/claim/html)
        %config        (static:web bowl 'text/html' /web/config/html)
        %community-js  (static:web bowl 'text/javascript' /web/community/js)
        %landing-js    (static:web bowl 'text/javascript' /web/landing/js)
        %claim-js      (static:web bowl 'text/javascript' /web/claim/js)
        %artwork-js    (static:web bowl 'text/javascript' /web/artwork/js)
        %config-js     (static:web bowl 'text/javascript' /web/config/js)
        %appearance    (response:web 200 (appearance:presentation bowl))
        %favicon       (static:web bowl 'image/svg+xml' /web/favicon/svg)
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
    =/  action  (str:j u.jon 'action')
    ?:  =(action %rpc-bootstrap)
      =/  existing=(map asset claim)  claims.st
      ?:  ?=(^ existing)
        [(give-simple-payload:app:server id (error:web 409 'Release existing NFT claims before changing the Azimuth bootstrap trust anchor.')) this]
      =/  checked
        %-  mule
        |.
        =/  snap  (snapshot-now:audit bowl)
        ?>  &((gth number.id.snap 0) (gth hash.id.snap 0))
        ?>  =(u.jon (pairs:enjs:format ~[action+s+'rpc-bootstrap' height+s+(decimal:j number.id.snap) hash+s+(hex-width:audit hash.id.snap 32) digest+s+(hex-width:audit (shax (jam snap)) 32)]))
        snap
      ?-  -.checked
        %|  [(give-simple-payload:app:server id (error:web 409 'The displayed bootstrap changed or is unavailable. Refresh and review it again.')) this]
        %&  =/  snap  p.checked
            =/  cancel=(list card)
              ?:(sent.native ~[[%pass /native-rpc/(scot %ud serial.native) %arvo %i %cancel-request ~]] ~)
            =.  native  native(bootstrap `snap, anchor [number.id.snap hash.id.snap (shax (jam snap))], audit-point *header:rpc, audit-logs ~, work ~, queue ~, sent |, serial +(serial.native), due now.bowl)
            =.  proof  *proof:audit
            =^  cards  this  native-pump
            [(weld cancel (weld cards (give-simple-payload:app:server id (response:web 200 admin-view)))) this]
      ==
    ?:  =(action %rpc-settings)
      =/  result  (configure:rpc native u.jon now.bowl)
      ?-  -.result
        %|  [(give-simple-payload:app:server id (error:web 400 p.result)) this]
        %&  =/  cancel=(list card)
              ?:(sent.native ~[[%pass /native-rpc/(scot %ud serial.native) %arvo %i %cancel-request ~]] ~)
            =.  native  p.result
            =.  st  st(azimuth-auto &, fixtures |)
            =.  at.proof  ~2000.1.1
            =.  nft-sources.st  (~(urn by nft-sources.st) |=([key=@tas src=source] src(healthy |)))
            =^  cards  this  native-pump
            [(weld cancel (weld cards (give-simple-payload:app:server id (response:web 200 admin-view)))) this]
      ==
    ?:  =(action %audit-azimuth)
      =/  result  (accept:audit st proof bowl u.jon)
      ?-  -.result
        %|  [(give-simple-payload:app:server id (error:web 409 p.result)) this]
        %&  =.  st  -.p.result
            =.  proof  +.p.result
            =.  st  (reconcile:policy st now.bowl)
            =^  cards  this  dispatch
            [(weld cards (give-simple-payload:app:server id (response:web 200 admin-view))) this]
      ==
    ?:  =(action %recheck-delivery)
      =^  cards  this  dispatch
      [(weld cards (give-simple-payload:app:server id (response:web 200 admin-view))) this]
    ?:  =(action %retry-delivery)
      =/  current=(unit job:delivery)  active.transport
      ?~  current
        [(give-simple-payload:app:server id (error:web 409 'No delivery needs recovery.')) this]
      =/  work  u.current
      ?.  =(phase.work %failed)
        [(give-simple-payload:app:server id (error:web 409 'Only a rejected action can be retried manually. Recheck an uncertain result first.')) this]
      ?.  (fresh-proof:audit proof now.bowl)
        [(give-simple-payload:app:server id (error:web 409 'Wait for current verified ownership before retrying.')) this]
      =.  effects.st  (~(del by effects.st) id.work)
      =.  this  this(transport transport(active ~))
      =.  st  (reconcile:policy st now.bowl)
      =.  approvals.control  (~(put in approvals.control) requested.work)
      =^  cards  this  dispatch
      [(weld cards (give-simple-payload:app:server id (response:web 200 admin-view))) this]
    ?:  ?=(?(%delivery-settings %approve-effect) action)
      ?.  |(!(bool:j u.jon 'enabled' &) .^(? %j /(scot %p our.bowl)/fake/(scot %da now.bowl)) (fresh-proof:audit proof now.bowl))
        [(give-simple-payload:app:server id (error:web 409 'Verified ownership must be current before sending.')) this]
      =/  next-control  control
      =/  next-log  transport
      =/  result=(each [controls:delivery ledger:delivery] @t)
        ?:  =(action %delivery-settings)
          =/  rows  (array:j (get:j u.jon 'targets'))
          =/  ships=(list ship)
            %+  murn  rows
            |=  row=json
            ?.  ?=([%s *] row)  ~
            (slaw %p p.row)
          ?.  &((lte (lent rows) 50) =((lent rows) (lent ships)) !(lien ships |=(who=ship =(who our.bowl))))
            [%| 'Provide up to 50 valid target ships, excluding the host.']
          [%& next-control(automatic (bool:j u.jon 'automatic' &), approvals ~) next-log(enabled (bool:j u.jon 'enabled' |), targets (silt ships))]
        ?.  enabled.transport  [%| 'Enable delivery before approving an action.']
        =/  fingerprint  (str:j u.jon 'fingerprint')
        =/  matching
          %+  skim  ~(tap by effects.st)
          |=  [key=@ud ef=effect]
          =((hex:j (shax (jam operation.ef))) fingerprint)
        ?~  matching  [%| 'That action is no longer needed. Refresh the delivery list.']
        =/  op  operation.q.i.matching
        [%& next-control(approvals (~(put in approvals.next-control) op)) next-log(targets (~(put in targets.next-log) who.seat.op))]
      ?-  -.result
        %|  [(give-simple-payload:app:server id (error:web 409 p.result)) this]
        %&  =.  control  -.p.result
            =.  transport  +.p.result
            =^  cards  this  dispatch
            =.  wake.st  (add now.bowl ~s5)
            [(weld ~[[%pass /timer/(scot %da wake.st) %arvo %b %wait wake.st]] (weld cards (give-simple-payload:app:server id (response:web 200 admin-view)))) this]
      ==
    ?:  ?=(?(%create-group %create-role) action)
      ?.  .^(? %gu /(scot %p our.bowl)/groups/(scot %da now.bowl)/$)
        [(give-simple-payload:app:server id (error:web 409 'Tlon groups is not running on this host.')) this]
      ?.  .^(? %gu /(scot %p our.bowl)/channels/(scot %da now.bowl)/$)
        [(give-simple-payload:app:server id (error:web 409 'Tlon channels is not running on this host.')) this]
      =/  result  (begin:community ui (registry:community bowl) our.bowl now.bowl u.jon)
      ?-  -.result
        %|  [(give-simple-payload:app:server id (error:web 409 p.result)) this]
        %&  =.  ui  p.result
            =/  w  (need work.ui)
            =/  nest  /v1/chat/(scot %p our.bowl)/(cat 3 group.w '-chat')
            ?:  &(=(kind.w %group) .^(? %gu (weld /(scot %p our.bowl)/channels/(scot %da now.bowl) nest)))
              [(give-simple-payload:app:server id (error:web 409 'A channel with this collection ID already exists. Choose a different ID.')) this(ui ui(work ~))]
            :-  (weld ~[(command:community w our.bowl) [%pass /community-check/(scot %ud id.w) %arvo %b %wait (add now.bowl ~s1)]] (give-simple-payload:app:server id (response:web 202 admin-view)))
            this
      ==
    ?:  &(?=(?(%configure %delete-collection) action) ?=(^ active.transport))
      [(give-simple-payload:app:server id (error:web 409 'Wait for the in-flight Tlon action to finish before editing collections.')) this]
    =/  binding-error=(unit @t)
      ?.  =(action %configure)  ~
      =/  old  (~(get by collections.st) (str:j u.jon 'id'))
      =/  group  (str:j u.jon 'group')
      =/  role  (str:j u.jon 'role')
      ?:  ?~(old | =([group role] [group role]:u.old))  ~
      =/  all  (registry:community bowl)
      ?~  g=(~(get by all) [our.bowl group])  `'Choose a group hosted by this ship, or create one first.'
      ?.  (~(has by roles.u.g) role)  `'Choose an existing role, or create one first.'
      ?:  (~(has in admins.u.g) role)  `'Use a role without administrative permissions.'
      ~
    ?^  binding-error
      [(give-simple-payload:app:server id (error:web 409 u.binding-error)) this]
    =/  indexed-collection  (~(get by collections.st) (str:j u.jon 'id'))
    =/  old-index  (~(gut by indexes.native) (str:j u.jon 'id') ?~(indexed-collection [%enumerable 0 ''] (default-options:rpc u.indexed-collection)))
    =/  index-options  (parse-options:rpc (get:j u.jon 'indexing') old-index)
    ?:  &(=(action %configure) ?=(%| -.index-options))
      [(give-simple-payload:app:server id (error:web 400 p.index-options)) this]
    ?:  &(=(action %configure) (~(has by caches.native) (str:j u.jon 'id')) ?=(%& -.index-options) !=(old-index p.index-options))
      [(give-simple-payload:app:server id (error:web 409 'Index coverage is locked after verification. Create a new collection to review a different history.')) this]
    =/  branding  (get:j u.jon 'brand')
    =/  parsed  (parse-brand:community branding)
    ?:  &(=(action %configure) ?=(%| -.parsed))
      [(give-simple-payload:app:server id (error:web 409 p.parsed)) this]
    ?:  &(=(action %configure) (gth (met 3 (str:j u.jon 'removalMessage')) 2.048))
      [(give-simple-payload:app:server id (error:web 409 'Keep the removal DM under 2048 bytes.')) this]
    =/  result  (act:actions st now.bowl src.bowl our.bowl u.jon)
    ?-  -.result
      %|  [(give-simple-payload:app:server id (error:web 409 p.result)) this]
      %&  =?  indexes.native  &(=(action %configure) ?=(%& -.index-options) ?=(^ (get:j u.jon 'indexing')))
            (~(put by indexes.native) (str:j u.jon 'id') p.index-options)
          =?  native  =(action %delete-collection)
            native(indexes (~(del by indexes.native) (str:j u.jon 'id')), caches (~(del by caches.native) (str:j u.jon 'id')), errors (~(del by errors.native) (str:j u.jon 'id')))
          =?  control  =(action %configure)
            =/  prefs  (~(gut by communities.control) (str:j u.jon 'id') *preferences:delivery)
            =.  prefs  prefs(manual (bool:j u.jon 'manualApproval' manual.prefs))
            =?  removal.prefs  ?=([%s *] (get:j u.jon 'removalMessage'))
              (str:j u.jon 'removalMessage')
            control(communities (~(put by communities.control) (str:j u.jon 'id') prefs))
          =?  control  =(action %delete-collection)
            control(communities (~(del by communities.control) (str:j u.jon 'id')))
          =?  ui  &(=(action %configure) ?=(^ branding) ?=(%& -.parsed))
            ui(brands (~(put by brands.ui) (str:j u.jon 'id') p.parsed))
          =?  ui  =(action %delete-collection)
            ui(brands (~(del by brands.ui) (str:j u.jon 'id')))
          =?  owned.transport  ?=(?(%configure %delete-collection) action)
            %-  ~(urn by owned.transport)
            |=  [key=seat roles=(set @tas)]
            (~(int in roles) (~(gut by applied.p.result) key *(set @tas)))
          =.  st  (reconcile:policy ?:(enabled.proof p.result (pull-azimuth p.result bowl)) now.bowl)
          =^  cards  st  (ensure-source st bowl)
          =^  sent  this  dispatch
          =/  view  ?:(=(target %config-action) admin-view (claim-view:web st now.bowl src.bowl our.bowl))
          [(weld sent (weld cards (give-simple-payload:app:server id (response:web 200 view)))) this]
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
    [%x %state ~]  ``json+!>(admin-view)
    [%x %delivery ~]  ``json+!>((view:delivery transport))
    [%x %audit @ ~]  ``json+!>((material:audit bowl (slav %ud i.t.t.path)))
  ==
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?:  =(/native-tick/(scot %da due.native) wire)  native-pump
  ?:  ?=([%native-rpc @ ~] wire)
    ?.  &(sent.native =(i.t.wire (scot %ud serial.native)))  [~ this]
    ?.  ?=(%http-response +<.sign-arvo)  [~ this]
    (native-response client-response.sign-arvo)
  ?:  ?=([%community-check @ ~] wire)
    ?~  work.ui  [~ this]
    ?.  =((scot %ud id.u.work.ui) i.t.wire)  [~ this]
    =/  next  (confirm:community ui (registry:community bowl) our.bowl now.bowl)
    ?~  work.next  [~ this(ui next)]
    ?:  ?=(?(%done %failed) phase.u.work.next)  [~ this(ui next)]
    [[[%pass wire %arvo %b %wait (add now.bowl ~s1)] ~] this(ui next)]
  ?:  =(/timer/(scot %da wake.st) wire)
    =.  st  (reconcile:policy ?:(enabled.proof st (pull-azimuth st bowl)) now.bowl)
    =^  cards  st  (ensure-source st bowl)
    =^  sent  this  dispatch
    =.  cards  (weld sent cards)
    =.  wake.st  (add now.bowl ?:(enabled.transport ~s5 ~m1))
    [[[%pass /timer/(scot %da wake.st) %arvo %b %wait wake.st] cards] this]
  [~ this]
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card agent:gall)
  ?:  ?=([%community @ @ ~] wire)
    ?.  ?=(%poke-ack -.sign)  [~ this]
    ?~  work.ui  [~ this]
    =/  w  u.work.ui
    ?.  &(=(i.t.wire (scot %ud id.w)) =(i.t.t.wire phase.w))  [~ this]
    ?^  p.sign
      [~ this(ui ui(work `w(phase %failed, error 'Tlon rejected this request. A partial group may exist; inspect it before retrying.')))]
    ?:  =(phase.w %group)
      =.  ui  ui(work `w(phase %channel))
      [~[(command:community (need work.ui) our.bowl)] this]
    =.  ui  ui(work `w(phase %confirm))
    [[[%pass /community-check/(scot %ud id.w) %arvo %b %wait (add now.bowl ~s1)] ~] this]
  ?:  ?=([%gater-delivery @ ~] wire)
    ?.  ?=(%poke-ack -.sign)  [~ this]
    =.  transport  (ack:delivery transport (slav %ud i.t.wire) ?=(~ p.sign))
    dispatch
  ?.  =(/azimuth wire)  (on-agent:def wire sign)
  ?:  enabled.proof  [~ this]
  ?.  azimuth-auto.st  [~ this]
  ?:  |(?=(%kick -.sign) &(?=(%watch-ack -.sign) ?=(^ p.sign)))
    [~ this(st st(azimuth-watch |, azimuth-status %gap, azimuth-at ~2000.1.1))]
  ?.  ?=(%fact -.sign)  [~ this]
  ?:  =(%naive-state p.cage.sign)
    =+  !<([nas=* own=owner-index:sources spo=*] q.cage.sign)
    =.  st  (observe-snapshot:sources st (owner-addresses:sources own) now.bowl)
    =.  st  (reconcile:policy st now.bowl)
    dispatch
  ?.  &(=(%naive-diffs p.cage.sign) =(%observed azimuth-status.st))  [~ this]
  =/  event  !<(* q.cage.sign)
  ?.  ?=([%point @ %owner @] event)  [~ this]
  =/  [tag=@tas who=ship kind=@tas owner=@ux]  event
  =.  st  (observe-owner:sources st who owner now.bowl)
  =.  st  (reconcile:policy st now.bowl)
  dispatch
++  on-leave  on-leave:def
++  on-fail  on-fail:def
--
