::  Observed Tlon delivery. Production requires current audited ownership,
::  automatic collection policy or an exact approval. Fake ships additionally
::  require a target allowlist so fixtures cannot contact unrelated ships.
/-  *gater
/+  tlon=gater-tlon, policy=gater-policy, j=gater-json
|%
+$  job
  $:  id=@ud
      requested=operation
      wire-op=operation
      at=@da
      phase=?(%waiting %acked %failed %uncertain)
      added=(set @tas)
      created=?
  ==
+$  receipt  [id=@ud op=operation at=@da result=?(%observed %submitted %preserved)]
+$  ledger-6
  $:  enabled=$~(| ?)
      targets=(set ship)
      active=(unit job)
      owned=(map seat (set @tas))
      history=(list receipt)
  ==
+$  ledger
  $:  enabled=$~(& ?)
      targets=(set ship)
      active=(unit job)
      owned=(map seat (set @tas))
      history=(list receipt)
      notices=(map @ud operation)
  ==
+$  controls-6  [automatic=$~(| ?) approvals=(set operation)]
+$  preferences
  $:  manual=$~(| ?)
      removal=$~('Your NFT membership link is no longer active, so access has been removed. Hold or reacquire an NFT from this collection, then link it to your ship to rejoin:' @t)
  ==
+$  controls  [automatic=$~(& ?) approvals=(set operation) communities=(map @tas preferences)]
++  migrate
  |=  old=ledger-6
  ^-  ledger
  [enabled.old targets.old active.old owned.old history.old ~]
++  manual
  |=  [st=state control=controls op=operation]
  ^-  ?
  %+  lien  ~(tap by collections.st)
  |=  [id=@tas cfg=collection]
  &(=(group.cfg group.seat.op) manual:(~(gut by communities.control) id *preferences))
++  preferences-json
  |=  p=preferences
  (pairs:enjs:format ~[['manualApproval' b+manual.p] ['removalMessage' s+removal.p]])
++  decorate
  |=  [view=json st=state control=controls]
  ^-  json
  ?>  ?=([%o *] view)
  =/  cols
    %+  turn  (array:j (get:j view 'collections'))
    |=  col=json
    ?>  ?=([%o *] col)
    =/  prefs  (preferences-json (~(gut by communities.control) (str:j col 'id') *preferences))
    ?>  ?=([%o *] prefs)
    col(p (~(uni by p.col) p.prefs))
  =/  outbox
    %+  turn  (array:j (get:j view 'outbox'))
    |=  row=json
    ?>  ?=([%o *] row)
    =/  needed
      %+  lien  ~(tap by collections.st)
      |=  [id=@tas cfg=collection]
      &(=(group.cfg (str:j row 'group')) manual:(~(gut by communities.control) id *preferences))
    row(p (~(put by p.row) 'manualApproval' b+needed))
  view(p (~(put by (~(put by p.view) 'collections' a+cols)) 'outbox' a+outbox))
++  pending
  ::  Policy rebuilds its outbox; durable post-removal notices have their own
  ::  queue. Cancel an unsent notice if access has since been claimed again.
  |=  [st=state log=ledger]
  ^-  [state ledger]
  =/  rows  ~(tap by notices.log)
  =/  want  (desired:policy st)
  |-
  ?~  rows  [st log]
  =/  id  p.i.rows
  =/  op  q.i.rows
  =/  in-flight  ?~(active.log | =(id id.u.active.log))
  =/  configured  (~(any by collections.st) |=(cfg=collection &(kick.cfg =(group.cfg group.seat.op))))
  ?:  &(!in-flight |(!configured (~(has by want) seat.op)))
    $(rows t.rows, notices.log (~(del by notices.log) id), effects.st (~(del by effects.st) id))
  =?  effects.st  !(~(has by effects.st) id)
    (~(put by effects.st) id [op %pending 0])
  $(rows t.rows)
+$  card  card:agent:gall
++  observe
  |=  [bowl=bowl:gall key=seat]
  ^-  (unit observation:tlon)
  ?.  .^(? %gu /(scot %p our.bowl)/groups/(scot %da now.bowl)/groups/(scot %p our.bowl)/[group.key])
    ~
  =/  group=group-view:tlon
    .^(group-view:tlon %gx /(scot %p our.bowl)/groups/(scot %da now.bowl)/v3/groups/(scot %p our.bowl)/[group.key]/noun)
  `(observe:tlon group who.key our.bowl)
++  dm-present
  |=  [bowl=bowl:gall work=job]
  ^-  ?
  .^(? %gu /(scot %p our.bowl)/chat/(scot %da now.bowl)/dm/(scot %p who.seat.requested.work)/writs/writ/id/(scot %p our.bowl)/(scot %ud at.work))
++  finish
  |=  [st=state log=ledger now=@da control=controls]
  ^-  [state ledger]
  =/  work  (need active.log)
  =/  op  requested.work
  =/  key  seat.op
  =/  roles  (~(gut by applied.st) key *(set @tas))
  =/  owned  (~(gut by owned.log) key *(set @tas))
  =?  st  ?=(?(%dm %invite) kind.op)
    =/  cols  ~(tap by collections.st)
    |-
    ?~  cols  st
    =/  cfg  q.i.cols
    =/  text  (crip "{(trip message.cfg)} {(trip base-url.st)}/gater/{(trip p.i.cols)}")
    =?  recognized.st
      &((group-eligible:policy st key) =(group.cfg group.key) =(recognition.cfg kind.op) =(text text.op))
      (~(put in recognized.st) [p.i.cols who.key])
    $(cols t.cols)
  =?  st  &(created.work ?=(?(%invite %admit) kind.op))
    st(managed (~(put in managed.st) key))
  =?  st  =(kind.op %admit)
    st(applied (~(put by applied.st) key (~(uni in roles) roles.op)))
  =?  log  =(kind.op %admit)
    log(owned (~(put by owned.log) key (~(uni in owned) added.work)))
  =?  st  =(kind.op %revoke)
    st(applied (~(put by applied.st) key (~(dif in roles) roles.op)))
  =?  log  =(kind.op %revoke)
    log(owned (~(put by owned.log) key (~(dif in owned) roles.op)))
  =?  st  =(kind.op %kick)
    st(managed (~(del in managed.st) key), applied (~(del by applied.st) key))
  =?  log  =(kind.op %kick)
    log(owned (~(del by owned.log) key))
  =.  effects.st  (~(del by effects.st) id.work)
  =.  notices.log  (~(del by notices.log) id.work)
  ::  Notify once, only after an actual kick is observed. A preserved manual
  ::  membership or a failed kick must never produce a removal message.
  =^  st  log
    ?.  &(=(kind.op %kick) =(kind.wire-op.work %kick))  [st log]
    =/  cols  (sort ~(tap by collections.st) |=([a=[p=@tas q=collection] b=[p=@tas q=collection]] (aor p.a p.b)))
    |-
    ?~  cols  [st log]
    =/  cfg  q.i.cols
    =/  prefs  (~(gut by communities.control) p.i.cols *preferences)
    ?.  &(=(group.cfg group.key) kick.cfg !=('' removal.prefs))  $(cols t.cols)
    =.  serial.st  +(serial.st)
    =/  text  (crip "{(trip name.cfg)}: {(trip removal.prefs)} {(trip base-url.st)}/gater/{(trip p.i.cols)}")
    [st log(notices (~(put by notices.log) serial.st [%dm key ~ text]))]
  =/  result
    ?:  =(kind.op %dm)  %submitted
    ?:  &(=(kind.op %kick) =(kind.wire-op.work %revoke))  %preserved
    %observed
  =.  history.log  [[id.work op now result] (scag 99 history.log)]
  (pending (reconcile:policy st now) log(active ~))
++  ack
  |=  [log=ledger id=@ud ok=?]
  ^-  ledger
  ?~  active.log  log
  ?.  =(id id.u.active.log)  log
  log(active `u.active.log(phase ?:(ok %acked %failed)))
++  still-needed
  |=  [st=state now=@da op=operation]
  =/  current  (reconcile:policy st(effects ~) now)
  (~(any by effects.current) |=(ef=effect =(operation.ef op)))
++  authorized
  |=  [st=state log=ledger control=controls fake=? verified=? op=operation]
  ^-  ?
  ?&  enabled.log
      |(fake verified)
      |(!fake (~(has in targets.log) who.seat.op))
      |(&(automatic.control !(manual st control op)) (~(has in approvals.control) op))
  ==
++  removal-pending
  |=  [st=state group=@tas]
  ^-  ?
  (~(any by effects.st) |=(ef=effect &(=(group group.seat.operation.ef) ?=(?(%revoke %kick) kind.operation.ef))))
++  step
  |=  [st=state log=ledger bowl=bowl:gall verified=? control=controls]
  ^-  (quip card [state ledger])
  =/  fake  .^(? %j /(scot %p our.bowl)/fake/(scot %da now.bowl))
  ::  Observe outstanding results even while sources are temporarily stale.
  ?^  active.log
    =/  work  u.active.log
    =/  op  requested.work
    =/  ob  (observe bowl seat.op)
    ?~  ob  [~ st log]
    =/  done
      ?:  =(kind.op %dm)  (dm-present bowl work)
      ?:  =(kind.op %admit)
        &(|(member.u.ob pending.u.ob) =(~ (~(dif in roles.op) roles.u.ob)))
      (observed:tlon wire-op.work u.ob)
    ?:  done  [~ (finish st log now.bowl control)]
    ?:  (lth now.bowl (add at.work ~s30))  [~ st log]
    =/  ef  (~(get by effects.st) id.work)
    ::  Only idempotent group commands are retried, and only while still
    ::  authorized by current policy. DMs retain their submitted/uncertain
    ::  result; we never fabricate a remote read receipt or a new message ID.
    ?:  ?&  enabled.log
            |(fake verified)
            !=(kind.op %dm)
            !=(phase.work %failed)
            ?~(ef | (lth attempts.u.ef 3))
            (group-fresh:policy st now.bowl group.seat.op)
            (still-needed st now.bowl op)
            (allowed:tlon op u.ob)
        ==
      =/  updated  (need ef)
      =.  effects.st  (~(put by effects.st) id.work updated(attempts +(attempts.updated)))
      =.  log  log(active `work(at now.bowl, phase %waiting))
      =+  [agent=@tas cage]=(command:tlon wire-op.work u.ob our.bowl at.work)
      [~[[%pass /gater-delivery/(scot %ud id.work) %agent [our.bowl agent] %poke cage]] st log]
    [~ st log(active `work(phase ?:(=(phase.work %failed) %failed %uncertain)))]
  ?.  &(enabled.log |(fake verified))  [~ st log]
  ::  Read the latest policy every time. Removals block grants in their group;
  ::  unavailable groups must not stall independent communities.
  =/  candidates
    %+  sort
      %+  skim  ~(tap by effects.st)
      |=  [id=@ud ef=effect]
      (authorized st log control fake verified operation.ef)
    |=  [a=[p=@ud q=effect] b=[p=@ud q=effect]]
    =/  ar  ?:(?=(?(%revoke %kick) kind.operation.q.a) 0 1)
    =/  br  ?:(?=(?(%revoke %kick) kind.operation.q.b) 0 1)
    ?:  =(ar br)  (lth p.a p.b)
    (lth ar br)
  |-
  ?~  candidates  [~ st log]
  =/  id  p.i.candidates
  =/  ef  q.i.candidates
  =/  op  operation.ef
  ?:  &(!?=(?(%revoke %kick) kind.op) (removal-pending st group.seat.op))
    $(candidates t.candidates)
  ?.  (group-fresh:policy st now.bowl group.seat.op)
    $(candidates t.candidates)
  ?~  ob=(observe bowl seat.op)  $(candidates t.candidates)
  ?.  (allowed:tlon op u.ob)  $(candidates t.candidates)
  =/  actual  op
  =/  added  (~(dif in roles.op) roles.u.ob)
  =?  actual  =(kind.op %revoke)
    op(roles (~(int in roles.op) (~(gut by owned.log) seat.op *(set @tas))))
  ::  A manual role is independent authority to remain. Relinquish management
  ::  instead of deleting a seat that now carries an unrelated role.
  =?  actual
    &(=(kind.op %kick) !=(~ (~(dif in roles.u.ob) (~(gut by owned.log) seat.op *(set @tas)))))
    op(kind %revoke, roles ~)
  =/  created  &(!member.u.ob !pending.u.ob)
  =/  work=job  [id op actual now.bowl %waiting added created]
  =.  effects.st  (~(put by effects.st) id ef(status %sent, attempts +(attempts.ef)))
  =/  log=ledger  log
  =.  active.log  `work
  ?:  (observed:tlon actual u.ob)  [~ (finish st log now.bowl control)]
  =+  [agent=@tas cage]=(command:tlon actual u.ob our.bowl at.work)
  [~[[%pass /gater-delivery/(scot %ud id) %agent [our.bowl agent] %poke cage]] st log]
++  view
  |=  log=ledger
  ^-  json
  %-  pairs:enjs:format
  :~  ['enabled' b+enabled.log]
      ['scope' s+'collection-policy']
      ['active' ?~(active.log ~ (pairs:enjs:format ~[['id' s+(decimal:j id.u.active.log)] ['phase' s+phase.u.active.log] ['action' s+kind.requested.u.active.log] ['ship' s+(scot %p who.seat.requested.u.active.log)]]))]
      ['receipts' a+(turn history.log |=([id=@ud op=operation at=@da result=?(%observed %submitted %preserved)] (pairs:enjs:format ~[['id' s+(decimal:j id)] ['action' s+kind.op] ['ship' s+(scot %p who.seat.op)] ['group' s+group.seat.op] ['result' s+result]])))]
  ==
--
