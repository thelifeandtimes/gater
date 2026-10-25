::  Pure reducers: no messages or group effects are dispatched by this suite.
=/  m  (strand ,vase)
=/  now  ~2026.10.25
=/  st  *state
=/  cfg=collection
  ['Example' 8.453 0xabc %club %holder %dm 'Claim membership:' &]
=.  collections.st  (~(put by collections.st) %example cfg)
=.  owners.st  (malt ~[[~zod 0x1] [~nec 0x1] [~bud 0x2]])
=.  tokens.st  (malt ~[[[%example 7] 0x1] [[%example 8] 0x1]])
=.  azimuth-at.st  now
=.  nft-at.st  (~(put by nft-at.st) %example now)
=.  base-url.st  'https://example.test'
~|  %dm-default
=/  planned  (reconcile st now)
?>  =(2 ~(wyt by effects.planned))
?>  (~(all by effects.planned) |=(ef=effect =(%dm kind.operation.ef)))
~|  %no-action
=/  silent  st(collections (~(put by collections.st) %example cfg(recognition %none)))
?>  =(~ effects:(reconcile silent now))
~|  %invite-all
=/  invites  st(collections (~(put by collections.st) %example cfg(recognition %invite)))
?>  (~(all by effects:(reconcile invites now)) |=(ef=effect =(%invite kind.operation.ef)))
~|  %claim-before-membership
=/  first  (claim-token st now ~zod [%example 7] 0)
?>  ?=(%& -.first)
=/  claimed  p.first
?>  =(%admit kind.operation:(~(got by effects:(reconcile claimed now)) 1))
~|  %sibling-takeover
=/  second  (claim-token claimed now ~nec [%example 7] 1)
?>  ?=(%& -.second)
=/  replaced  p.second
?>  =(who:(~(got by claims.replaced) [%example 7]) ~nec)
?>  =(1 ~(wyt by claims.replaced))
~|  %concurrent-revision-rejected
=/  rejected-1  (claim-token replaced now ~zod [%example 7] 1)
?>  ?=(%| -.rejected-1)
~|  %unrelated-wallet-rejected
=/  rejected-2  (claim-token replaced now ~bud [%example 7] 2)
?>  ?=(%| -.rejected-2)
~|  %one-token-per-ship
=/  third  (claim-token replaced now ~nec [%example 8] 2)
?>  ?=(%& -.third)
?>  =(1 ~(wyt by claims.p.third))
?>  !(~(has by claims.p.third) [%example 7])
~|  %sibling-cannot-release-others-claim
=/  rejected-3  (release p.third ~zod [%example 8] 3)
?>  ?=(%| -.rejected-3)
~|  %stale-data-freezes-new-claims
=/  rejected-4  (claim-token st (add now ~h1) ~zod [%example 7] 0)
?>  ?=(%| -.rejected-4)
?>  =(~ effects:(reconcile st (add now ~h1)))
~|  %sale-prunes-claim
=/  sold  claimed(tokens (~(put by tokens.claimed) [%example 7] 0x2))
?>  =(~ claims:(prune sold))
~|  %owner-change-prunes-claim
=/  moved  claimed(owners (~(put by owners.claimed) ~zod 0x2))
?>  =(~ claims:(prune moved))
~|  %default-revokes-role-and-membership
=.  applied.sold  (~(put by applied.sold) [%club ~zod] (silt ~[%holder]))
=.  managed.sold  (silt ~[[%club ~zod]])
=/  loss  (reconcile (prune sold) now)
?>  (~(any by effects.loss) |=(ef=effect =(%revoke kind.operation.ef)))
?>  (~(any by effects.loss) |=(ef=effect =(%kick kind.operation.ef)))
~|  %membership-retention-is-configurable
=.  collections.sold  (~(put by collections.sold) %example cfg(kick |))
=/  keep  (reconcile (prune sold) now)
?>  !(~(any by effects.keep) |=(ef=effect =(%kick kind.operation.ef)))
~|  %another-collection-supports-role
=.  collections.claimed  (~(put by collections.claimed) %other cfg(contract 0xdef))
=.  nft-at.claimed  (~(put by nft-at.claimed) %other now)
=.  tokens.claimed  (~(put by tokens.claimed) [%other 7] 0x1)
=.  claims.claimed  (~(put by claims.claimed) [%other 7] [~zod 0x1 2])
=.  claims.claimed  (~(del by claims.claimed) [%example 7])
=.  applied.claimed  (~(put by applied.claimed) [%club ~zod] (silt ~[%holder]))
=.  managed.claimed  (silt ~[[%club ~zod]])
=/  aggregate  (reconcile claimed now)
?>  !(~(any by effects.aggregate) |=(ef=effect |(=(%kick kind.operation.ef) =(%revoke kind.operation.ef))))
~|  %broadly-invited-member-loses-access-on-sale
=/  broad  st(tokens ~, managed (silt ~[[%club ~zod]]))
?>  (~(any by effects:(reconcile broad now)) |=(ef=effect =(%kick kind.operation.ef)))
~|  %broadly-invited-eligible-member-can-claim-later
=.  managed.st  (silt ~[[%club ~zod]])
?>  !(~(any by effects:(reconcile st now)) |=(ef=effect =(%kick kind.operation.ef)))
~|  %azimuth-index-retains-distinct-owner-addresses
=/  index  (malt ~[[0x1 (silt ~[~nec ~zod])] [0x2 (silt ~[~bud])] [0x0 (silt ~[~wes])]])
=/  owners  (invert-owners index)
?>  =(3 ~(wyt by owners))
?>  =(`0x1 (~(get by owners) ~nec))
?>  =(`0x2 (~(get by owners) ~bud))
?>  !(~(has by owners) ~wes)
(pure:m !>([%gater-policy-tests 18 %passed]))
