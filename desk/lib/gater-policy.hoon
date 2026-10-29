/-  *gater
/+  j=gater-json
|%
++  invert-owners
  |=  index=(map @ux (set ship))
  ^-  (map ship @ux)
  %+  roll  ~(tap by index)
  |=  [[addr=@ux ships=(set ship)] result=(map ship @ux)]
  ?.  &((lth addr (bex 160)) !=(addr 0))  result
  =/  people  ~(tap in ships)
  |-
  ?~  people  result
  ?.  (lte i.people 0xffff.ffff)  $(people t.people)
  $(people t.people, result (~(put by result) i.people addr))
++  fresh
  |=  [st=state now=@da col=@tas]
  ^-  ?
  =/  nft  (~(gut by nft-at.st) col ~2000.1.1)
  =/  source  (~(get by nft-sources.st) col)
  ?&  ?~(source & healthy.u.source)
      |(!azimuth-auto.st =(%observed azimuth-status.st))
      (gth azimuth-at.st ~2000.1.1)
      (lte azimuth-at.st now)
      (lte nft now)
      (lte (sub now azimuth-at.st) ttl.st)
      (lte (sub now nft) ttl.st)
  ==
++  eligible
  |=  [st=state who=ship key=asset]
  ^-  ?
  =/  own  (~(get by owners.st) who)
  =/  tok  (~(get by tokens.st) key)
  ?&  ?=(^ own)
      ?=(^ tok)
      !=(0 u.own)
      =(u.own u.tok)
      (lte who 0xffff.ffff)
  ==
++  holdings
  |=  [st=state who=ship col=@tas]
  ^-  (list asset)
  %+  skim  ~(tap in ~(key by tokens.st))
  |=  key=asset
  &(=(collection.key col) (eligible st who key))
++  prune
  |=  st=state
  ^-  state
  =.  claims.st
    %-  ~(gas by *(map asset claim))
    %+  skim  ~(tap by claims.st)
    |=  [key=asset cl=claim]
    ?&  (~(has by collections.st) collection.key)
        (eligible st who.cl key)
        =(`owner.cl (~(get by owners.st) who.cl))
    ==
  st
++  claim-revision
  ::  CAS token for just this ship/collection/NFT intent. Background imports
  ::  elsewhere cannot invalidate it; ownership, provenance and claims do.
  |=  [st=state who=ship key=asset]
  ^-  @ud
  =/  existing
    %+  skim  ~(tap by claims.st)
    |=  [asset=asset cl=claim]
    &(=(collection.asset collection.key) =(who.cl who))
  %-  shax
  %-  jam
  :*  who  key  existing
      (~(get by collections.st) collection.key)
      (~(get by owners.st) who)
      (~(get by tokens.st) key)
      (~(get by token-generations.st) key)
      (~(get by claims.st) key)
      suppressed.st
  ==
++  expected-revision
  |=  [st=state who=ship key=asset expected=@ud]
  |(=(expected revision.st) =(expected (claim-revision st who key)))
++  claim-token
  |=  [st=state now=@da who=ship key=asset expected=@ud]
  ^-  (each state @t)
  ?^  cl=(~(get by claims.st) key)
    ?.  =(who who.u.cl)
      [%| 'This NFT is already linked. Ask the linked ship to release it, or authorize with the owner wallet.']
    (assign-token st now who key expected)
  (assign-token st now who key expected)
++  reassign
  |=  [st=state now=@da actor=ship target=ship key=asset expected=@ud]
  ^-  (each state @t)
  ?~  cl=(~(get by claims.st) key)  [%| 'There is no association to transfer.']
  ?.  &(=(actor who.u.cl) (eligible st actor key))
    [%| 'Only the currently linked eligible ship can transfer this association.']
  ?.  (levy ~(tap by claims.st) |=([old=asset cl=claim] |(!=(collection.old collection.key) !=(target who.cl) =(actor target))))
    [%| 'The receiving ship must release its existing claim before accepting a transfer.']
  (assign-token st now target key expected)
++  assign-token
  ::  Internal commit gate. Call only after claim/reassignment authorization.
  |=  [st=state now=@da who=ship key=asset expected=@ud]
  ^-  (each state @t)
  ?.  (expected-revision st who key expected)  [%| 'State changed. Refresh and try again.']
  ?.  (~(has by collections.st) collection.key)  [%| 'Unknown collection.']
  ?.  (fresh st now collection.key)  [%| 'Ownership data is stale. Try again after synchronization.']
  ?.  (eligible st who key)  [%| 'This ship and NFT must have the same owner.']
  =/  cfg  (~(got by collections.st) collection.key)
  ?:  (~(has in suppressed.st) [group.cfg who])  [%| 'Membership is suppressed by the host.']
  ::  Remove the destination ship's previous token in the same transition.
  =.  claims.st
    %-  ~(gas by *(map asset claim))
    %+  skim  ~(tap by claims.st)
    |=  [old=asset cl=claim]
    ?!  &(=(collection.old collection.key) =(who.cl who))
  =.  revision.st  +(revision.st)
  =.  claims.st
    (~(put by claims.st) key [who (~(got by owners.st) who) revision.st])
  [%& st]
++  release
  |=  [st=state who=ship key=asset expected=@ud]
  ^-  (each state @t)
  ?.  (expected-revision st who key expected)  [%| 'State changed. Refresh and try again.']
  ?~  cl=(~(get by claims.st) key)  [%& st]
  ?.  =(who who.u.cl)  [%| 'Only the associated ship can release this claim.']
  [%& st(claims (~(del by claims.st) key), revision +(revision.st))]
++  desired
  |=  st=state
  ^-  (map seat (set @tas))
  =|  result=(map seat (set @tas))
  =/  rows  ~(tap by claims.st)
  |-
  ?~  rows  result
  =/  cfg  (~(got by collections.st) collection.p.i.rows)
  =/  key=seat  [group.cfg who.q.i.rows]
  ?:  (~(has in suppressed.st) key)  $(rows t.rows)
  =/  roles  (~(gut by result) key *(set @tas))
  $(rows t.rows, result (~(put by result) key (~(put in roles) role.cfg)))
++  enqueue
  |=  [st=state op=operation]
  ^-  state
  ::  Stable operations remain in the outbox until observed, not just acked.
  ?:  (~(any by effects.st) |=(ef=effect &(=(operation.ef op) !=(status.ef %failed))))  st
  =.  serial.st  +(serial.st)
  st(effects (~(put by effects.st) serial.st [op %pending 0]))
++  group-fresh
  |=  [st=state now=@da group=@tas]
  ^-  ?
  %+  roll  ~(tap by collections.st)
  |=  [[id=@tas cfg=collection] ok=?]
  &(ok |(!=(group.cfg group) (fresh st now id)))
++  group-eligible
  |=  [st=state key=seat]
  ^-  ?
  %+  roll  ~(tap by collections.st)
  |=  [[id=@tas cfg=collection] yes=_|]
  |(yes &(=(group.cfg group.key) !=(~ (holdings st who.key id))))
++  detach-collection
  ::  Stop managing this binding, preserving actual Tlon access. Other
  ::  collections retain their shared roles and management accounting.
  |=  [st=state id=@tas]
  ^-  state
  =/  old  (~(got by collections.st) id)
  =/  remaining  (~(del by collections.st) id)
  =/  same-role  (~(any by remaining) |=(cfg=collection =([group.cfg role.cfg] [group.old role.old])))
  =.  claims.st
    (~(gas by *(map asset claim)) (skim ~(tap by claims.st) |=([key=asset cl=claim] !=(collection.key id))))
  =.  recognized.st
    (silt (skim ~(tap in recognized.st) |=([col=@tas who=ship] !=(col id))))
  =.  applied.st
    %-  ~(urn by applied.st)
    |=  [key=seat roles=(set @tas)]
    ?:  |(!=(group.key group.old) same-role)  roles
    (~(del in roles) role.old)
  =.  managed.st
    %-  silt
    %+  skim  ~(tap in managed.st)
    |=  key=seat
    ?|  !=(group.key group.old)
        !=(~ (~(gut by applied.st) key *(set @tas)))
        %+  lien  ~(tap by remaining)
        |=  [col=@tas cfg=collection]
        &(=(group.cfg group.key) =(recognition.cfg %invite) (~(has in recognized.st) [col who.key]))
    ==
  =.  effects.st
    (~(gas by *(map @ud effect)) (skim ~(tap by effects.st) |=([key=@ud ef=effect] !=(group.seat.operation.ef group.old))))
  st
++  delete-collection
  |=  [st=state id=@tas]
  ^-  state
  =.  st  (detach-collection st id)
  =.  collections.st  (~(del by collections.st) id)
  =.  tokens.st
    (~(gas by *(map asset @ux)) (skim ~(tap by tokens.st) |=([key=asset owner=@ux] !=(collection.key id))))
  =.  token-generations.st
    (~(gas by *(map asset @ud)) (skim ~(tap by token-generations.st) |=([key=asset gen=@ud] !=(collection.key id))))
  st(nft-at (~(del by nft-at.st) id), checkpoints (~(del by checkpoints.st) id), nft-sources (~(del by nft-sources.st) id), revision +(revision.st))
++  reconcile
  |=  [st=state now=@da]
  ^-  state
  =/  want  (desired st)
  ::  Clear obsolete not-yet-dispatched effects before recalculating. Keep
  ::  sent operations until the transport reconciles their actual outcome.
  =.  effects.st
    %-  ~(gas by *(map @ud effect))
    %+  skim  ~(tap by effects.st)
    |=  [id=@ud ef=effect]
    =(%sent status.ef)
  =/  old=(list [p=seat q=(set @tas)])
    %+  turn  ~(tap in (~(uni in managed.st) ~(key by applied.st)))
    |=(key=seat [key (~(gut by applied.st) key *(set @tas))])
  =.  st
    |-
    ?~  old  st
    =/  key  p.i.old
    ?.  (group-fresh st now group.key)  $(old t.old)
    =/  wanted  (~(gut by want) key *(set @tas))
    =/  removed  (~(dif in q.i.old) wanted)
    =?  st  !=(~ removed)
      (enqueue st [%revoke key removed ''])
    =/  kick=?
      (~(any by collections.st) |=(cfg=collection &(=(group.cfg group.key) kick.cfg)))
    =?  st  &(kick =(wanted ~) (~(has in managed.st) key) |((~(has by applied.st) key) !(group-eligible st key) (~(has in suppressed.st) key)))
      (enqueue st [%kick key ~ ''])
    $(old t.old)
  =/  additions  ~(tap by want)
  =.  st
    |-
    ?~  additions  st
    =/  key  p.i.additions
    ?.  (group-fresh st now group.key)  $(additions t.additions)
    =/  missing  (~(dif in q.i.additions) (~(gut by applied.st) key *(set @tas)))
    =?  st  !=(~ missing)
      (enqueue st [%admit key missing ''])
    $(additions t.additions)
  =/  cols  ~(tap by collections.st)
  |-
  ?~  cols  st
  =/  id  p.i.cols
  =/  cfg  q.i.cols
  ?:  ?=(%none recognition.cfg)  $(cols t.cols)
  ?.  (fresh st now id)  $(cols t.cols)
  ::  Build the collection's holder set once. Scanning all NFTs for each
  ::  Azimuth point makes real-world ownership snapshots prohibitively slow.
  =/  wallets=(set @ux)
    %+  roll  ~(tap by tokens.st)
    |=  [[key=asset owner=@ux] result=(set @ux)]
    ?.  &(=(collection.key id) !=(owner 0))  result
    (~(put in result) owner)
  =/  people=(list ship)
    %+  murn  ~(tap by owners.st)
    |=  [who=ship owner=@ux]
    ?.  &((lte who 0xffff.ffff) (~(has in wallets) owner))  ~
    `who
  =.  st
    |-
    ?~  people  st
    =/  who  i.people
    ?:  |((~(has in suppressed.st) [group.cfg who]) (~(has in recognized.st) [id who]))
      $(people t.people)
    =/  text=@t
      (crip "{(trip message.cfg)} {(trip base-url.st)}/gater/{(trip id)}")
    =.  st
      (enqueue st [recognition.cfg [group.cfg who] ~ text])
    $(people t.people)
  $(cols t.cols)
--
