/-  *gater
/+  policy=gater-policy
|%
+$  owner-index
  (map [proxy=?(%own %spawn %manage %vote %transfer) address=@ux] (set ship))
++  owner-addresses
  |=  index=owner-index
  ^-  (map @ux (set ship))
  %+  roll  ~(tap by index)
  |=  [[key=[proxy=?(%own %spawn %manage %vote %transfer) address=@ux] ships=(set ship)] result=(map @ux (set ship))]
  ?.  =(%own proxy.key)  result
  (~(put by result) address.key ships)
++  migrate
  |=  old=state-0
  ^-  state
  =/  st  *state
  =.  st
    %_  st
      collections  collections.old
      owners  owners.old
      tokens  tokens.old
      claims  claims.old
      recognized  recognized.old
      suppressed  suppressed.old
      managed  managed.old
      applied  applied.old
      effects  effects.old
      revision  revision.old
      serial  serial.old
      azimuth-at  azimuth-at.old
      nft-at  nft-at.old
      checkpoints  checkpoints.old
      ttl  ttl.old
      base-url  base-url.old
      live  live.old
      fixtures  fixtures.old
      azimuth-auto  azimuth-auto.old
      wake  wake.old
    ==
  ::  Legacy real-source claims have no transfer provenance. Fixtures remain
  ::  usable; production-shaped claims require an explicit new association.
  ?.  fixtures.st
    st(claims ~, revision +(revision.st), azimuth-at ~2000.1.1, nft-at ~)
  ?:  =(~ checkpoints.st)  st
  ::  The fixture flag is global. A mixed state can also contain RPC imports;
  ::  preserve only claims whose collection has no legacy RPC checkpoint.
  =.  claims.st
    %-  ~(gas by *(map asset claim))
    %+  skim  ~(tap by claims.st)
    |=  [key=asset cl=claim]
    !(~(has by checkpoints.st) collection.key)
  =.  nft-at.st
    %-  ~(gas by *(map @tas @da))
    %+  skim  ~(tap by nft-at.st)
    |=  [col=@tas seen=@da]
    !(~(has by checkpoints.st) col)
  st(revision +(revision.st))
++  observe-owner
  |=  [st=state who=ship owner=@ux now=@da]
  ^-  state
  ?.  &((lte who 0xffff.ffff) (lth owner (bex 160)))  st
  ?:  =(`owner (~(get by owners.st) who))  st(azimuth-at now)
  =.  owners.st  ?:(=(owner 0) (~(del by owners.st) who) (~(put by owners.st) who owner))
  (prune:policy st(revision +(revision.st), azimuth-at now))
++  observe-snapshot
  |=  [st=state index=(map @ux (set ship)) now=@da]
  ^-  state
  ::  A new subscription has no proof of events during the gap. Reclaiming is
  ::  deliberate: equal final addresses cannot prove uninterrupted ownership.
  st(owners (invert-owners:policy index), claims ~, revision +(revision.st), azimuth-at now, azimuth-status %observed)
--
