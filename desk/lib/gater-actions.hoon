/-  *gater
/+  j=gater-json, policy=gater-policy
|%
++  act
  |=  [st=state now=@da who=ship host=ship jon=json]
  ^-  (each state @t)
  =/  action  (str:j jon 'action')
  ?:  |(=(action 'claim') =(action 'release'))
    ?~  col=(slaw %tas (str:j jon 'collection'))  [%| 'Invalid collection.']
    ?~  token=(uint:j jon 'token')  [%| 'Invalid token ID.']
    ?.  (lth u.token (bex 256))  [%| 'Invalid token ID.']
    ?~  revision=(uint:j jon 'revision')  [%| 'Missing state revision.']
    ?:  =(action 'claim')
      (claim-token:policy st now who [u.col u.token] u.revision)
    (release:policy st who [u.col u.token] u.revision)
  ?.  =(who host)  [%| 'This action is only available to the host.']
  =/  from-chain  =(action %snapshot)
  =?  action  from-chain  %nfts
  ?+  action  [%| 'Unknown action.']
      %configure
    ?~  id=(slaw %tas (str:j jon 'id'))  [%| 'Invalid collection ID.']
    ?~  chain=(uint:j jon 'chain')  [%| 'Invalid chain.']
    ?.  |(=(u.chain 1) =(u.chain 8.453))  [%| 'Use Ethereum mainnet (1) or Base (8453).']
    ?~  contract=(address:j (str:j jon 'contract'))  [%| 'Invalid contract address.']
    ?~  group=(slaw %tas (str:j jon 'group'))  [%| 'Invalid group name.']
    ?~  role=(slaw %tas (str:j jon 'role'))  [%| 'Invalid role ID.']
    ?:  =(u.role %admin)  [%| 'Use a dedicated non-admin role.']
    =/  action  (str:j jon 'recognition')
    =?  action  =(action '')  'dm'
    ?.  ?=(?(%dm %invite %none) action)  [%| 'Recognition must be dm, invite, or none.']
    =/  msg  (str:j jon 'message')
    ?:  (gth (met 3 msg) 2.048)  [%| 'Message is too long.']
    =?  msg  =(msg '')  'Claim your group membership:'
    =/  cfg=collection
      [(str:j jon 'name') u.chain u.contract u.group u.role action msg (bool:j jon 'removeMembership' &)]
    =/  duplicate=?
      %+  roll  ~(tap by collections.st)
      |=  [[key=@tas old=collection] yes=_|]
      |(yes &(!=(key u.id) =(chain.old u.chain) =(contract.old u.contract)))
    ?:  duplicate  [%| 'This chain/contract is already configured. Reuse its collection ID.']
    =/  conflict=?
      %+  roll  ~(tap by collections.st)
      |=  [[key=@tas old=collection] yes=_|]
      |(yes &(!=(key u.id) =(group.old group.cfg) !=(kick.old kick.cfg)))
    ?:  conflict  [%| 'Collections managing one group must use the same membership-loss policy.']
    ?^  old=(~(get by collections.st) u.id)
      ?.  =([chain contract group role]:u.old [chain contract group role]:cfg)
        [%| 'Asset and group identity are immutable in this alpha. Add a new configuration.']
      $(collections.st (~(del by collections.st) u.id))
    [%& st(collections (~(put by collections.st) u.id cfg), revision +(revision.st))]
      %settings
    =/  url  (str:j jon 'baseUrl')
    ?~  parsed=(de-purl:html url)  [%| 'Provide an absolute host URL.']
    ?:  (gth (met 3 url) 512)  [%| 'Host URL is too long.']
    ::  Sending remains disabled until ownership provenance and group-state
    ::  reconciliation have passed the deployment gate. Never pretend otherwise.
    ?:  (bool:j jon 'live' |)  [%| 'Live dispatch is not enabled in this first-pass desk. Inspect the outbox.']
    [%& st(base-url url, live |, azimuth-auto (bool:j jon 'azimuthAuto' azimuth-auto.st))]
      %owners
    ::  Explicit fixtures are useful for testing; they never enable dispatch.
    =/  rows  (get:j jon 'owners')
    ?.  ?=([%a *] rows)  [%| 'owners must be an array.']
    =/  old  owners.st
    =|  owners=(map ship @ux)
    =/  result=(each (map ship @ux) @t)
      |-
      ?~  p.rows  [%& owners]
      =/  row  i.p.rows
      ?~  person=(slaw %p (str:j row 'ship'))  [%| 'Invalid ship in ownership snapshot.']
      ?.  (lte u.person 0xffff.ffff)  [%| 'Only Azimuth points are supported.']
      ?~  addr=(address:j (str:j row 'owner'))  [%| 'Invalid owner address.']
      ?:  (~(has by owners) u.person)  [%| 'Duplicate ship in ownership snapshot.']
      $(p.rows t.p.rows, owners (~(put by owners) u.person u.addr))
    ?-  -.result
      %|  result
      %&  [%& (prune:policy st(owners p.result, azimuth-at now, azimuth-auto |, fixtures &, revision +(revision.st)))]
    ==
      %nfts
    ?~  col=(slaw %tas (str:j jon 'collection'))  [%| 'Invalid collection.']
    ?.  (~(has by collections.st) u.col)  [%| 'Unknown collection.']
    =/  observed=@da  now
    =/  height=@ud  0
    =/  block-hash=@ux  0x0
    =/  checked=(each [@da @ud @ux] @t)
      ?.  from-chain  [%& now 0 0x0]
      =/  cfg  (~(got by collections.st) u.col)
      ?.  =(`chain.cfg (uint:j jon 'chain'))  [%| 'Snapshot chain does not match this collection.']
      ?.  =(`contract.cfg (address:j (str:j jon 'contract')))  [%| 'Snapshot contract does not match this collection.']
      ?~  time=(uint:j jon 'observedAt')  [%| 'Snapshot requires an observation timestamp.']
      =/  stamp  (add ~1970.1.1 (mul u.time ~s1))
      ?.  &((lte stamp now) (lte (sub now stamp) ttl.st))  [%| 'Snapshot is stale or in the future.']
      ?~  block=(uint:j jon 'block')  [%| 'Snapshot requires a checkpoint.']
      ?.  =(66 (met 3 (str:j jon 'blockHash')))  [%| 'Checkpoint hash must be 32 bytes.']
      ?~  hash=(hex-number:j (crip (cass (trip (str:j jon 'blockHash')))))  [%| 'Invalid checkpoint hash.']
      ?.  &((gth u.hash 0) (lth u.hash (bex 256)))  [%| 'Invalid checkpoint hash.']
      ?^  previous=(~(get by checkpoints.st) u.col)
        ?:  (lth u.block height.u.previous)  [%| 'Checkpoint regression refused.']
        ?:  (lth stamp (~(gut by nft-at.st) u.col ~1970.1.1))  [%| 'Observation timestamp regression refused.']
        ?:  &(=(u.block height.u.previous) !=(u.hash hash.u.previous))  [%| 'Checkpoint hash changed. Reindex and investigate.']
        [%& stamp u.block u.hash]
      [%& stamp u.block u.hash]
    ?-  -.checked
      %|  checked
      %&  =.  observed  -.p.checked
          =.  height  +<.p.checked
          =.  block-hash  +>.p.checked
          (import-tokens st now u.col observed height block-hash from-chain jon)
    ==
      %suppress
    ?~  group=(slaw %tas (str:j jon 'group'))  [%| 'Invalid group.']
    ?~  person=(slaw %p (str:j jon 'ship'))  [%| 'Invalid ship.']
    =.  suppressed.st  (~(put in suppressed.st) [u.group u.person])
    [%& st(revision +(revision.st))]
      %unsuppress
    ?~  group=(slaw %tas (str:j jon 'group'))  [%| 'Invalid group.']
    ?~  person=(slaw %p (str:j jon 'ship'))  [%| 'Invalid ship.']
    [%& st(suppressed (~(del in suppressed.st) [u.group u.person]), revision +(revision.st))]
  ==
++  import-tokens
  |=  [st=state now=@da col=@tas observed=@da height=@ud block-hash=@ux from-chain=? jon=json]
  ^-  (each state @t)
    =/  rows  (get:j jon 'tokens')
    ?.  ?=([%a *] rows)  [%| 'tokens must be an array.']
    =/  kept
      %-  ~(gas by *(map asset @ux))
      %+  skim  ~(tap by tokens.st)
      |=  [key=asset owner=@ux]
      !=(collection.key col)
    =/  result=(each (map asset @ux) @t)
      |-
      ?~  p.rows  [%& kept]
      =/  row  i.p.rows
      ?~  id=(uint:j row 'id')  [%| 'Invalid token ID.']
      ?.  (lth u.id (bex 256))  [%| 'Invalid token ID.']
      ?~  owner=(address:j (str:j row 'owner'))  [%| 'Invalid NFT owner.']
      ?:  (~(has by kept) [col u.id])  [%| 'Duplicate token ID.']
      $(p.rows t.p.rows, kept (~(put by kept) [col u.id] u.owner))
    ?-  -.result
      %|  result
      %&  =?  checkpoints.st  from-chain  (~(put by checkpoints.st) col [height block-hash])
          [%& (prune:policy st(tokens p.result, nft-at (~(put by nft-at.st) col observed), fixtures |(fixtures.st !from-chain), revision +(revision.st)))]
    ==
--
