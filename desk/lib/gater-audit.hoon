::  Finalized effective Azimuth ownership from a pinned Urbit bootstrap plus
::  an RPC-audited complete log suffix. This is the same naive L2 interpreter
::  used by %azimuth; the independent worker checks every log and L2 input.
/-  *gater
/+  naive, ethereum, j=gater-json, policy=gater-policy
|%
+$  snapshot  [%0 id=[hash=@ux number=@ud] nas=^state:naive own=* spo=*]
+$  event  event-log:rpc:ethereum
+$  proof
  $:  enabled=$~(| ?)
      at=@da
      height=@ud
      hash=@ux
      anchor=@ux
      generations=(map ship @ux)
  ==
++  hex-width
  |=  [value=@ux width=@ud]
  ^-  @t
  =/  digits  (slag 2 (trip (hex:j value)))
  (crip (weld "0x" (weld (reap (sub (mul width 2) (lent digits)) '0') digits)))
++  fresh-proof
  |=  [p=proof now=@da]
  &(enabled.p (lte at.p now) (lte (sub now at.p) ~m15))
++  snapshot-now
  |=  b=bowl:gall
  ^-  snapshot
  .^(snapshot %gx /(scot %p our.b)/azimuth/(scot %da now.b)/last-snap/noun)
++  logs-through
  |=  [b=bowl:gall height=@ud]
  ^-  (list event)
  =/  logs  .^((list event) %gx /(scot %p our.b)/azimuth/(scot %da now.b)/logs/noun)
  %+  skim  logs
  |=(e=event ?~(mined.e | (lte block-number.u.mined.e height)))
++  digest
  |=  [snap=snapshot logs=(list event)]
  ^-  @ux
  (shax (jam [snap logs]))
++  material
  |=  [b=bowl:gall height=@ud]
  ^-  json
  =/  snap  (snapshot-now b)
  =/  logs  (logs-through b height)
  =/  rows=json
    :-  %a
    %+  turn  logs
    |=  e=event
    ?>  ?=(^ mined.e)
    =/  m  u.mined.e
    %-  pairs:enjs:format
    :~  address+s+(hex-width address.e 20)  data+s+data.e
        topics+a+(turn topics.e |=(t=@ux s+(hex-width t 32)))
        'blockNumber'^s+(decimal:j block-number.m)  'blockHash'^s+(hex-width block-hash.m 32)
        'logIndex'^s+(decimal:j log-index.m)  'transactionIndex'^s+(decimal:j transaction-index.m)
        'transactionHash'^s+(hex-width transaction-hash.m 32)  removed+b+removed.m
        input+?~(input.m ~ s+(scot %ux u.input.m))
    ==
  %-  pairs:enjs:format
  :~  height+s+(decimal:j height)  logs+rows
      'anchorHeight'^s+(decimal:j number.id.snap)  'anchorHash'^s+(hex-width hash.id.snap 32)
      'anchorDigest'^s+(hex-width (shax (jam snap)) 32)
      'materialDigest'^s+(hex-width (digest snap logs) 32)
  ==
++  verifier
  ^-  ^verifier:naive
  |=  [dat=octs v=@ r=@ s=@]
  ?:  (gth v 3)  ~
  =/  result
    %-  mule
    |.
    =,  secp256k1:secp:crypto
    %-  address-from-pub:key:ethereum
    %-  serialize-point
    (ecdsa-raw-recover (keccak-256:keccak:crypto dat) v r s)
  ?-  -.result
    %|  ~
    %&  `p.result
  ==
++  replay
  |=  [snap=snapshot logs=(list event)]
  ^-  [owners=(map ship @ux) generations=(map ship @ux)]
  =/  nas  nas.snap
  =|  generations=(map ship @ux)
  =/  result=[nas=^state:naive generations=(map ship @ux)]
    |-
    ?~  logs  [nas generations]
    =/  e  i.logs
    ?>  ?=(^ mined.e)
    =/  m  u.mined.e
    ?>  !removed.m
    =/  input=^input:naive
      :-  block-number.m
      ?:  =(address.e 0x223c.067f.8cf2.8ae1.73ee.5caf.ea60.ca44.c335.fecb)
        [%log address.e ?:(|(=(data.e '') =(data.e '0x')) 0x0 (hex-to-num:ethereum data.e)) topics.e]
      ?>  =(address.e 0xeb70.029c.fb3c.53c7.78ea.f68c.d28d.e725.390a.1fe9)
      ?>  ?=(^ input.m)
      [%bat u.input.m]
    =^  effects  nas  (%*(. naive lac |) verifier 1 nas input)
    =.  generations
      %-  ~(gas by generations)
      %+  murn  effects
      |=  ef=diff:naive
      =/  who=(unit ship)
        ?:  ?=([%point @ %owner @] ef)  `ship.ef
        ?.  ?=([%tx *] ef)  ~
        ?^  err.ef  ~
        ?.  ?=([* %transfer-point *] tx.raw-tx.ef)  ~
        `ship.from.tx.raw-tx.ef
      ?~  who  ~
      `[u.who (shax (jam [block-hash.m log-index.m ef]))]
    $(logs t.logs)
  :-  %+  roll  ~(tap by points.nas.result)
      |=  [[who=ship point=point:naive] out=(map ship @ux)]
      ?:  |((gth who 0xffff.ffff) =(0 address.owner.own.point))  out
      (~(put by out) who address.owner.own.point)
  generations.result
++  accept
  |=  [st=state old=proof b=bowl:gall input=json]
  ^-  (each [state proof] @t)
  ?~  height=(uint:j input 'height')  [%| 'Missing finalized height.']
  ?~  hash=(hex-number:j (str:j input 'hash'))  [%| 'Missing finalized hash.']
  ?~  at=(uint:j input 'observedAt')  [%| 'Missing audit time.']
  =/  stamp  (add ~1970.1.1 (mul u.at ~s1))
  ?.  &((lte stamp now.b) (lte (sub now.b stamp) ~m15))  [%| 'Audit expired.']
  ?:  &(enabled.old (lth u.height height.old))  [%| 'Finality regression refused.']
  ?:  &(enabled.old =(u.height height.old) !=(u.hash hash.old))  [%| 'Finalized hash changed. Delivery paused for review.']
  =/  snap  (snapshot-now b)
  =/  logs  (logs-through b u.height)
  ?.  =(`(digest snap logs) (hex-number:j (str:j input 'materialDigest')))  [%| 'Azimuth audit material changed; audit again.']
  ?.  =(`(shax (jam snap)) (hex-number:j (str:j input 'anchorDigest')))  [%| 'Bootstrap anchor mismatch.']
  =/  result  (replay snap logs)
  =/  changed  |(!=(owners.st owners.result) !=(generations.old generations.result))
  =.  claims.st
    %-  ~(gas by *(map asset claim))
    %+  skim  ~(tap by claims.st)
    |=  [key=asset cl=claim]
    ::  Initial verified activation preserves only unchanged owners. Later
    ::  transitions also require uninterrupted ownership since the last audit.
    |(!enabled.old =((~(get by generations.old) who.cl) (~(get by generations.result) who.cl)))
  =.  st  (prune:policy st(owners owners.result, azimuth-at stamp, azimuth-status %observed, revision ?:(changed +(revision.st) revision.st)))
  [%& st [& stamp u.height u.hash (shax (jam snap)) generations.result]]
++  view
  |=  [p=proof now=@da]
  (pairs:enjs:format ~[verified+b+(fresh-proof p now) height+s+(decimal:j height.p) hash+s+(hex-width hash.p 32) anchor+s+(hex-width anchor.p 32) scope+s+'Urbit bootstrap snapshot plus complete finalized Ethereum log suffix'])
--
