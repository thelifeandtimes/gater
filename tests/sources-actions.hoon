::  Ownership continuity, failure health, and compatible saved-state migration.
=/  m  (strand ,vase)
=/  now  ~2026.10.25
~|  %native-owner-index-excludes-proxy-authority
=/  index=owner-index
  (~(gas by *owner-index) ~[[[%own 0x1] (silt ~[~nec])] [[%manage 0x2] (silt ~[~nec])] [[%transfer 0x3] (silt ~[~zod])] [[%spawn 0x4] (silt ~[~bud])] [[%vote 0x5] (silt ~[~wes])]])
?>  =((malt ~[[~nec 0x1]]) (invert-owners (owner-addresses index)))
=/  cfg=collection  ['Example' 8.453 0xabc %club %holder %dm 'Claim:' &]
=/  old  *state-0
=.  collections.old  (malt ~[[%example cfg]])
=.  owners.old  (malt ~[[~nec 0x1] [~zod 0x1]])
=.  tokens.old  (malt ~[[[%example 7] 0x1]])
=.  claims.old  (malt ~[[[%example 7] [~nec 0x1 0]]])
=.  azimuth-at.old  now
=.  nft-at.old  (malt ~[[%example now]])
~|  %migrate-fixtures-preserves-association
=/  st  (migrate old(fixtures &))
?>  =(1 ~(wyt by claims.st))
?>  (fresh st now %example)
~|  %migrate-real-input-requires-reclaim
=/  migrated  (migrate old(fixtures |))
?>  =(~ claims.migrated)
?>  !(fresh migrated now %example)
~|  %mixed-fixture-state-does-not-preserve-legacy-rpc-claim
=/  mixed  (migrate old(fixtures &, checkpoints (malt ~[[%example [42 0xabc]]])))
?>  =(~ claims.mixed)
?>  !(fresh mixed now %example)
~|  %azimuth-snapshot-gap-requires-reclaim
=/  initial  (observe-snapshot st (malt ~[[0x1 (silt ~[~nec ~zod])]]) now)
?>  =(~ claims.initial)
?>  =(%observed azimuth-status.initial)
~|  %azimuth-transfer-away-and-back-does-not-restore-claim
=/  moved  (observe-owner st ~nec 0x2 now)
=/  returned  (observe-owner moved ~nec 0x1 now)
?>  =(~ claims.returned)
~|  %unchanged-owner-preserves-claim
?>  =(claims.st claims:(observe-owner st ~nec 0x1 now))
~|  %azimuth-reconnecting-pauses-claims
?>  !(fresh st(azimuth-auto &, azimuth-status %connecting) now %example)
=/  unix  (div (sub now ~1970.1.1) ~s1)
=/  dec-text  |=(n=@ud (crip (skim (trip (scot %ud n)) |=(ch=@t !=(ch '.')))))
=/  make-snap
  |=  [height=@ud gen=@ud epoch=@t supply=@ud]
  %-  pairs:enjs:format
  :~  action+s+'snapshot'  collection+s+'example'  chain+s+'8453'
      contract+s+'0x0000000000000000000000000000000000000abc'
      'observedAt'^s+(dec-text unix)  block+s+(dec-text height)
      'blockHash'^s+'0x1111111111111111111111111111111111111111111111111111111111111111'
      epoch+s+epoch
      coverage+(pairs:enjs:format ~[method+s+'events-supply' 'fromBlock'^s+'1' supply+s+(dec-text supply) 'codeHash'^s+'0xabc'])
      tokens+a+~[(pairs:enjs:format ~[id+s+'7' owner+s+'0x0000000000000000000000000000000000000001' generation+s+(dec-text gen)])]
  ==
~|  %unverified-coverage-is-rejected
=/  bare  (make-snap 42 1 '0x1' 1)
?>  ?=([%o *] bare)
=/  rejected  (act st now ~nec ~nec bare(p (~(del by p.bare) 'coverage')))
?>  ?=(%| -.rejected)
~|  %supply-count-mismatch-is-rejected
=/  bad-supply  (act st now ~nec ~nec (make-snap 42 1 '0x1' 2))
?>  ?=(%| -.bad-supply)
~|  %zero-generation-is-rejected
=/  bad-generation  (act st now ~nec ~nec (make-snap 42 0 '0x1' 1))
?>  ?=(%| -.bad-generation)
~|  %first-verified-epoch-clears-legacy-claim
=/  first  (act st now ~nec ~nec (make-snap 42 1 '0x1' 1))
?>  ?=(%& -.first)
?>  =(~ claims.p.first)
=/  claim  (claim-token p.first now ~nec [%example 7] revision.p.first)
?>  ?=(%& -.claim)
=/  claimed  p.claim
~|  %same-generation-preserves-claim-on-next-checkpoint
=/  second  (act claimed now ~nec ~nec (make-snap 43 1 '0x1' 1))
?>  ?=(%& -.second)
?>  =(1 ~(wyt by claims.p.second))
~|  %transfer-generation-change-clears-same-owner-claim
=/  changed  (act claimed now ~nec ~nec (make-snap 43 3 '0x1' 1))
?>  ?=(%& -.changed)
?>  =(~ claims.p.changed)
~|  %rebuild-epoch-clears-unchanged-token-claim
=/  rebuilt  (act claimed now ~nec ~nec (make-snap 43 1 '0x2' 1))
?>  ?=(%& -.rebuilt)
?>  =(~ claims.p.rebuilt)
~|  %explicit-rebuild-can-replace-divergent-checkpoint
=/  rebuilt-snap  (make-snap 41 1 '0x2' 1)
=/  reorg  (act claimed now ~nec ~nec rebuilt-snap)
?>  ?=(%& -.reorg)
?>  =(41 height:(~(got by checkpoints.p.reorg) %example))
?>  =(~ claims.p.reorg)
~|  %same-checkpoint-cannot-change-token-generation
=/  same-block  (act claimed now ~nec ~nec (make-snap 42 3 '0x1' 1))
?>  ?=(%| -.same-block)
~|  %provider-error-preserves-ownership-and-claim-but-pauses-actions
=/  failure  (pairs:enjs:format ~[action+s+'source-error' collection+s+'example'])
=/  failed  (act claimed now ~nec ~nec failure)
?>  ?=(%& -.failed)
?>  =(tokens.claimed tokens.p.failed)
?>  =(claims.claimed claims.p.failed)
?>  !(fresh p.failed now %example)
?>  =(~ effects:(reconcile p.failed now))
~|  %provider-recovery-keeps-uninterrupted-claim
=/  recovered  (act p.failed now ~nec ~nec (make-snap 43 1 '0x1' 1))
?>  ?=(%& -.recovered)
?>  (fresh p.recovered now %example)
?>  =(claims.claimed claims.p.recovered)
~|  %remote-ship-cannot-fail-a-source
=/  foreign  (act claimed now ~zod ~nec failure)
?>  ?=(%| -.foreign)
~|  %source-failure-is-not-a-revocation
=/  managed  p.failed(managed (silt ~[[%club ~nec]]), applied (malt ~[[[%club ~nec] (silt ~[%holder])]]))
?>  =(~ effects:(reconcile managed now))
(pure:m !>([%gater-sources-tests 21 %passed]))
