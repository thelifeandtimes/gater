/-  *gater
/+  j=gater-json, policy=gater-policy, wallet=gater-wallet, community=gater-community
|%
++  act
  |=  [st=state now=@da who=ship host=ship jon=json]
  ^-  (each state @t)
  =/  action  (str:j jon 'action')
  ?:  ?=(?(%claim %release %reassign %wallet-claim) action)
    ?~  col=(slaw %tas (str:j jon 'collection'))  [%| 'Invalid collection.']
    ?~  token=(uint:j jon 'token')  [%| 'Invalid token ID.']
    ?.  (lth u.token (bex 256))  [%| 'Invalid token ID.']
    ?~  revision=(uint:j jon 'revision')  [%| 'Missing state revision.']
    ?:  =(action 'claim')
      (claim-token:policy st now who [u.col u.token] u.revision)
    ?:  =(action 'reassign')
      ?~  target=(slaw %p (str:j jon 'target'))  [%| 'Provide the receiving ship.']
      (reassign:policy st now who u.target [u.col u.token] u.revision)
    ?:  =(action 'wallet-claim')
      ?~  expires=(uint:j jon 'expires')  [%| 'Missing signature expiry.']
      (claim:wallet st now who host [u.col u.token] u.revision u.expires (str:j jon 'signature'))
    (release:policy st who [u.col u.token] u.revision)
  ?.  =(who host)  [%| 'This action is only available to the host.']
  ?:  &(?=(?(%configure %delete-collection) action) (~(any by effects.st) |=(ef=effect =(status.ef %sent))))
    [%| 'Wait for the in-flight Tlon action to finish before editing collections.']
  =/  from-chain  =(action %snapshot)
  =?  action  from-chain  %nfts
  ?+  action  [%| 'Unknown action.']
      %configure
    ?.  (valid-id:community (str:j jon 'id'))  [%| 'Use a collection ID of up to 64 lowercase letters, digits and hyphens; reserved route names are unavailable.']
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
    =/  old  (~(get by collections.st) u.id)
    ?.  ?~(old & =([chain contract]:u.old [chain contract]:cfg))
      [%| 'The network and contract cannot change. Create a new community for a different asset.']
    =?  st  ?~(old | !=([group role]:u.old [group role]:cfg))
      (detach-collection:policy st u.id)
    [%& st(collections (~(put by collections.st) u.id cfg), revision +(revision.st))]
      %delete-collection
    ?~  id=(slaw %tas (str:j jon 'id'))  [%| 'Invalid collection ID.']
    ?.  (~(has by collections.st) u.id)  [%| 'Unknown collection.']
    ?.  =(`revision.st (uint:j jon 'revision'))  [%| 'State changed. Refresh before deleting.']
    [%& (delete-collection:policy st u.id)]
      %settings
    =/  url  (str:j jon 'baseUrl')
    ?~  parsed=(de-purl:html url)  [%| 'Provide an absolute host URL.']
    ?:  (gth (met 3 url) 512)  [%| 'Host URL is too long.']
    ::  Sending remains disabled until ownership provenance and group-state
    ::  reconciliation have passed the deployment gate. Never pretend otherwise.
    ?:  (bool:j jon 'live' |)  [%| 'Live dispatch is not enabled in this first-pass desk. Inspect the outbox.']
    [%& st(base-url url, live |, azimuth-auto (bool:j jon 'azimuthAuto' azimuth-auto.st))]
      %source-error
    ?~  col=(slaw %tas (str:j jon 'collection'))  [%| 'Invalid collection.']
    ?.  (~(has by collections.st) u.col)  [%| 'Unknown collection.']
    =/  src  (~(gut by nft-sources.st) u.col *source)
    [%& st(nft-sources (~(put by nft-sources.st) u.col src(healthy |)), revision +(revision.st))]
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
        ?:  (lth stamp (~(gut by nft-at.st) u.col ~1970.1.1))  [%| 'Observation timestamp regression refused.']
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
    =/  checked=(each source @t)
      ?.  from-chain  [%& *source]
      =/  coverage  (get:j jon 'coverage')
      =/  method  (str:j coverage 'method')
      ?.  ?=(?(%enumerable %events-supply) method)  [%| 'Snapshot requires verified discovery coverage.']
      ?~  epoch=(hex-number:j (str:j jon 'epoch'))  [%| 'Snapshot requires a source epoch.']
      ?.  &((gth u.epoch 0) (lth u.epoch (bex 256)))  [%| 'Invalid source epoch.']
      ?~  start=(uint:j coverage 'fromBlock')  [%| 'Snapshot requires a bootstrap block.']
      ?.  (lte u.start height)  [%| 'Bootstrap is beyond the checkpoint.']
      ?~  supply=(uint:j coverage 'supply')  [%| 'Snapshot requires a verified supply.']
      ?.  =(u.supply (lent p.rows))  [%| 'Snapshot supply does not match token count.']
      ?~  code=(hex-number:j (str:j coverage 'codeHash'))  [%| 'Snapshot requires a code fingerprint.']
      ?.  &((gth u.code 0) (lth u.code (bex 256)))  [%| 'Invalid code fingerprint.']
      ?^  old=(~(get by nft-sources.st) col)
        ?:  &(=(epoch.u.old u.epoch) !=(code-hash.u.old u.code))
          [%| 'Code changed within a source epoch. Review and rebuild.']
        [%& & method u.epoch u.start u.supply u.code]
      [%& & method u.epoch u.start u.supply u.code]
    ?-  -.checked
      %|  checked
      %&  (commit-tokens st now col observed height block-hash from-chain p.checked p.rows)
    ==
++  commit-tokens
  |=  [st=state now=@da col=@tas observed=@da height=@ud block-hash=@ux from-chain=? src=source rows=(list json)]
  ^-  (each state @t)
    =/  kept
      %-  ~(gas by *(map asset @ux))
      %+  skim  ~(tap by tokens.st)
      |=  [key=asset owner=@ux]
      !=(collection.key col)
    =/  generations
      %-  ~(gas by *(map asset @ud))
      %+  skim  ~(tap by token-generations.st)
      |=  [key=asset generation=@ud]
      !=(collection.key col)
    =/  result=(each [kept=(map asset @ux) generations=(map asset @ud)] @t)
      |-
      ?~  rows  [%& kept generations]
      =/  row  i.rows
      ?~  id=(uint:j row 'id')  [%| 'Invalid token ID.']
      ?.  (lth u.id (bex 256))  [%| 'Invalid token ID.']
      ?~  owner=(address:j (str:j row 'owner'))  [%| 'Invalid NFT owner.']
      ?:  (~(has by kept) [col u.id])  [%| 'Duplicate token ID.']
      =/  generation  (uint:j row 'generation')
      ?:  &(from-chain ?=(~ generation))  [%| 'Snapshot tokens require transfer generations.']
      =/  gen  ?~(generation (~(gut by token-generations.st) [col u.id] 0) u.generation)
      ?.  (lth gen (bex 256))  [%| 'Invalid transfer generation.']
      ?:  &(from-chain =(gen 0))  [%| 'Transfer generation must be nonzero.']
      $(rows t.rows, kept (~(put by kept) [col u.id] u.owner), generations (~(put by generations) [col u.id] gen))
    ?-  -.result
      %|  result
      %&  =/  old-source  (~(get by nft-sources.st) col)
          =/  same-epoch  &(?=(^ old-source) from-chain =(epoch.u.old-source epoch.src))
          =/  new-epoch  ?:(from-chain !same-epoch ?=(^ old-source))
          ?^  checkpoint=(~(get by checkpoints.st) col)
            ?:  &(from-chain same-epoch (lth height height.u.checkpoint))
              [%| 'Checkpoint regression refused.']
            ?:  &(from-chain same-epoch =(height height.u.checkpoint) !=(block-hash hash.u.checkpoint))
              [%| 'Checkpoint hash changed. Review and rebuild in a new source epoch.']
            ?:  &(from-chain same-epoch =(height height.u.checkpoint) |(!=(tokens.st kept.p.result) !=(token-generations.st generations.p.result)))
              [%| 'Ownership changed at an unchanged checkpoint.']
            $(checkpoints.st (~(del by checkpoints.st) col))
          =/  changed  |(new-epoch !=(tokens.st kept.p.result) !=(token-generations.st generations.p.result))
          =.  claims.st
            %-  ~(gas by *(map asset claim))
            %+  skim  ~(tap by claims.st)
            |=  [key=asset cl=claim]
            |(!=(collection.key col) &(!new-epoch =((~(gut by token-generations.st) key 0) (~(gut by generations.p.result) key 0))))
          =?  checkpoints.st  from-chain  (~(put by checkpoints.st) col [height block-hash])
          =.  nft-sources.st  ?:(from-chain (~(put by nft-sources.st) col src) (~(del by nft-sources.st) col))
          [%& (prune:policy st(tokens kept.p.result, token-generations generations.p.result, nft-at (~(put by nft-at.st) col observed), fixtures |(fixtures.st !from-chain), revision ?:(changed +(revision.st) revision.st)))]
    ==
--
